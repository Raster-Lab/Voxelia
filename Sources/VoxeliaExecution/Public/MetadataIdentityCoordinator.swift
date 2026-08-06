// SPDX-License-Identifier: MIT

import VoxeliaCore

/// One atomically published canonical-bytes/identity pair.
public struct CoordinatedMetadataIdentity: Sendable {
    /// The exact canonical `VCMJ-1` document bytes.
    public let canonicalBytes: [UInt8]
    /// The framed complete-record identity of exactly those bytes.
    public let identity: ContentID

    init(canonicalBytes: [UInt8], identity: ContentID) {
        self.canonicalBytes = canonicalBytes
        self.identity = identity
    }
}

/// The actor-isolated single-flight metadata identity coordinator
/// selected by `ADR-0047`.
///
/// Concurrent requests for the same immutable collection value and
/// output ceiling coalesce onto one shared computation; the pair is
/// published atomically or not at all. The in-process coalescing key is
/// never persisted, and a cancelled caller receives the typed outcome
/// without cancelling shared work another waiter still needs.
public actor MetadataIdentityCoordinator {
    private struct WorkKey: Hashable {
        let payload: MetadataCollection
        let maximumOutputByteCount: UInt64
    }

    private var inFlight: [WorkKey: Task<CoordinatedMetadataIdentity, any Error>] = [:]

    /// The number of computations ever started; evidence for
    /// single-flight coalescing.
    private(set) var startedComputationCount = 0

    public init() {}

    /// The currently in-flight request count.
    public var currentInFlightCount: Int {
        inFlight.count
    }

    /// Computes or joins the unique-only canonical identity pair for one
    /// immutable collection value.
    ///
    /// - Throws: the typed `MetadataJSONEmissionError` or
    ///   `ContentIdentityError` cause of the shared computation, or
    ///   `MetadataJSONEmissionError.cancelled` for a cancelled caller.
    public func identity(
        for payload: MetadataCollection,
        maximumOutputByteCount: UInt64
    ) async throws -> CoordinatedMetadataIdentity {
        let key = WorkKey(
            payload: payload,
            maximumOutputByteCount: maximumOutputByteCount
        )
        let shared: Task<CoordinatedMetadataIdentity, any Error>
        if let existing = inFlight[key] {
            shared = existing
        } else {
            startedComputationCount += 1
            let started = Task.detached {
                let canonicalBytes = try CanonicalMetadataJSON.encodeUniqueDocument(
                    payload: payload,
                    maximumOutputByteCount: maximumOutputByteCount
                )
                let identity = try ContentID.completeMetadataRecordIdentity(
                    overCanonicalBytes: canonicalBytes
                )
                return CoordinatedMetadataIdentity(
                    canonicalBytes: canonicalBytes,
                    identity: identity
                )
            }
            inFlight[key] = started
            shared = started
        }

        // A cancelled caller receives the typed outcome; the shared
        // detached task continues for other waiters.
        if Task.isCancelled {
            throw MetadataJSONEmissionError.cancelled
        }
        do {
            let value = try await shared.value
            inFlight.removeValue(forKey: key)
            if Task.isCancelled {
                throw MetadataJSONEmissionError.cancelled
            }
            return value
        } catch {
            inFlight.removeValue(forKey: key)
            throw error
        }
    }
}
