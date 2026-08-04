// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by content-tier cache admission, lookup or removal.
///
/// Cases deliberately carry no payload: no identity, digest, byte count,
/// budget value or cached content is retained in diagnostics.
public enum ContentResultCacheError: Error, Sendable, Equatable {
    case identityMismatch
    case resourceLimitExceeded
    case unknownEntry
}

/// The actor-isolated content-tier result cache selected by `ADR-0050`.
///
/// Only the content tier of the `ADR-0037` admission order exists:
/// admission recomputes the supplied record's digest under its own
/// registered tuple and compares timing-safe before anything is
/// published, and every hit revalidates the stored bytes before
/// returning them. Budgets are explicit inclusive ceilings with no
/// permissive defaults, duplicate admission of a cached identity is an
/// idempotent success, removal is explicit, and no implicit eviction
/// policy exists. Digest verification runs outside the actor's
/// isolation.
public actor ContentResultCache {
    /// The inclusive cached-entry-count ceiling.
    public let maximumEntryCount: UInt64
    /// The inclusive total retained-byte ceiling.
    public let maximumTotalByteCount: UInt64

    private var entries: [ContentID: ContiguousArray<UInt8>] = [:]
    private var totalByteCount: UInt64 = 0

    /// The number of lookup revalidation failures ever observed;
    /// evidence that published bytes were always digest-verified.
    private(set) var revalidationFailureCount = 0

    /// Creates a cache with two explicit inclusive budgets; there are no
    /// permissive defaults.
    public init(maximumEntryCount: UInt64, maximumTotalByteCount: UInt64) {
        self.maximumEntryCount = maximumEntryCount
        self.maximumTotalByteCount = maximumTotalByteCount
    }

    /// The currently cached entry count.
    public var currentEntryCount: Int {
        entries.count
    }

    /// The currently retained total byte count.
    public var currentTotalByteCount: UInt64 {
        totalByteCount
    }

    /// Admits one verified byte result under its registered identity.
    ///
    /// The digest is recomputed under the record's own registered tuple
    /// and compared timing-safe before the bytes are published; a
    /// mismatch publishes nothing. Admitting an already-cached identity
    /// is an idempotent success.
    ///
    /// - Throws: ``ContentResultCacheError/identityMismatch`` when the
    ///   digest does not certify the bytes,
    ///   ``ContentResultCacheError/resourceLimitExceeded`` when either
    ///   ceiling would be exceeded, or the typed `ContentIdentityError`
    ///   cause of a failed or cancelled verification.
    public nonisolated func admit(
        bytes: [UInt8],
        as identity: ContentID
    ) async throws {
        guard try identity.matchesDigest(ofCanonicalBytes: bytes) else {
            throw ContentResultCacheError.identityMismatch
        }
        try await insertVerified(bytes: bytes, identity: identity)
    }

    /// Returns the revalidated bytes for one identity, or `nil` for a
    /// miss.
    ///
    /// A hit recomputes the stored bytes' digest before returning them;
    /// a revalidation failure purges the entry, counts the evidence and
    /// reports a miss rather than returning unverified bytes.
    ///
    /// - Throws: the typed `ContentIdentityError` cause of a failed or
    ///   cancelled revalidation.
    public nonisolated func lookup(
        _ identity: ContentID
    ) async throws -> [UInt8]? {
        guard let bytes = await storedBytes(for: identity) else {
            return nil
        }
        guard try identity.matchesDigest(ofCanonicalBytes: bytes) else {
            await purgeAfterRevalidationFailure(identity)
            return nil
        }
        return bytes
    }

    /// Removes one cached entry, returning its bytes to the budget.
    ///
    /// - Throws: ``ContentResultCacheError/unknownEntry`` when the
    ///   identity is not cached.
    public func remove(_ identity: ContentID) throws {
        guard let stored = entries.removeValue(forKey: identity) else {
            throw ContentResultCacheError.unknownEntry
        }
        totalByteCount -= min(UInt64(stored.count), totalByteCount)
    }

    private func insertVerified(bytes: [UInt8], identity: ContentID) throws {
        if entries[identity] != nil {
            return
        }
        guard UInt64(entries.count) < maximumEntryCount else {
            throw ContentResultCacheError.resourceLimitExceeded
        }
        let (candidate, overflow) = totalByteCount.addingReportingOverflow(
            UInt64(bytes.count)
        )
        guard !overflow, candidate <= maximumTotalByteCount else {
            throw ContentResultCacheError.resourceLimitExceeded
        }
        entries[identity] = ContiguousArray(bytes)
        totalByteCount = candidate
    }

    private func storedBytes(for identity: ContentID) -> [UInt8]? {
        guard let stored = entries[identity] else {
            return nil
        }
        return Array(stored)
    }

    private func purgeAfterRevalidationFailure(_ identity: ContentID) {
        if let stored = entries.removeValue(forKey: identity) {
            totalByteCount -= min(UInt64(stored.count), totalByteCount)
        }
        revalidationFailureCount += 1
    }
}
