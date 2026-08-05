// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaStorage

/// An error raised by brick request admission or publication.
///
/// Cases deliberately carry no payload; a cancelled awaiter surfaces
/// the standard cancellation error and a failed computation propagates
/// its own audited typed error.
public enum BrickRequestError: Error, Sendable, Equatable {
    /// The request's issued generation is no longer the broker's
    /// current generation — at admission or at publish.
    case staleGeneration
}

/// The actor-isolated brick request broker per `ADR-0150`.
///
/// In-flight work is keyed by brick identity and representation: the
/// first request starts the caller-supplied computation and every
/// concurrent duplicate awaits the same result — deduplication is safe
/// only because the computation must be a pure function of its key,
/// per the design contract. A cancelled awaiter releases cleanly while
/// the computation completes for its followers, and a result whose
/// awaiter's issued generation is no longer current rejects typed and
/// is never returned to that awaiter.
public actor BrickRequestBroker {
    private struct RequestKey: Hashable {
        let identity: BrickIdentity
        let representation: ExecutionClaimToken
    }

    private struct Waiter {
        let generation: UInt64
        let continuation: CheckedContinuation<ContiguousArray<UInt8>, any Error>
    }

    private var currentGeneration: UInt64 = 0
    private var inFlight: [RequestKey: [UInt64: Waiter]] = [:]
    private var nextWaiterID: UInt64 = 0

    /// The number of computations ever started; suite evidence that
    /// deduplication held, per the content-cache counter precedent.
    private(set) var startedComputationCount = 0

    public init() {}

    /// The broker's current generation.
    public func generation() -> UInt64 {
        currentGeneration
    }

    /// Advances and returns the new current generation; requests
    /// issued under earlier generations reject typed from here on.
    public func advanceGeneration() -> UInt64 {
        currentGeneration += 1
        return currentGeneration
    }

    /// The number of registered waiters for one key; suite evidence.
    func waiterCount(
        for identity: BrickIdentity,
        representation: ExecutionClaimToken
    ) -> Int {
        inFlight[RequestKey(identity: identity, representation: representation)]?
            .count ?? 0
    }

    /// Resolves one brick request through the deduplicated in-flight
    /// table.
    ///
    /// - Throws: ``BrickRequestError/staleGeneration``,
    ///   `CancellationError` for a cancelled awaiter, or the
    ///   computation's own audited typed error propagated identically
    ///   to every current awaiter.
    public func result(
        for identity: BrickIdentity,
        representation: ExecutionClaimToken,
        generation: UInt64,
        compute: @escaping @Sendable () async throws -> ContiguousArray<UInt8>
    ) async throws -> ContiguousArray<UInt8> {
        guard generation == currentGeneration else {
            throw BrickRequestError.staleGeneration
        }
        let key = RequestKey(identity: identity, representation: representation)
        let waiterID = nextWaiterID
        nextWaiterID += 1
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                register(
                    key: key,
                    waiterID: waiterID,
                    generation: generation,
                    continuation: continuation,
                    compute: compute
                )
            }
        } onCancel: {
            Task {
                await self.cancelWaiter(key: key, waiterID: waiterID)
            }
        }
    }

    /// Registers one waiter synchronously — before any suspension —
    /// starting the computation exactly once per in-flight key, so a
    /// completion can never race past a joining request.
    private func register(
        key: RequestKey,
        waiterID: UInt64,
        generation: UInt64,
        continuation: CheckedContinuation<ContiguousArray<UInt8>, any Error>,
        compute: @escaping @Sendable () async throws -> ContiguousArray<UInt8>
    ) {
        if inFlight[key] == nil {
            inFlight[key] = [:]
            startedComputationCount += 1
            Task {
                let outcome: Result<ContiguousArray<UInt8>, any Error>
                do {
                    outcome = .success(try await compute())
                } catch {
                    outcome = .failure(error)
                }
                await self.complete(key: key, outcome: outcome)
            }
        }
        inFlight[key]?[waiterID] = Waiter(
            generation: generation,
            continuation: continuation
        )
    }

    /// Publishes one outcome: every current-generation waiter receives
    /// it identically, every stale waiter rejects typed, and the
    /// in-flight entry is released.
    private func complete(
        key: RequestKey,
        outcome: Result<ContiguousArray<UInt8>, any Error>
    ) {
        guard let waiters = inFlight.removeValue(forKey: key) else {
            return
        }
        for waiter in waiters.values {
            guard waiter.generation == currentGeneration else {
                waiter.continuation.resume(
                    throwing: BrickRequestError.staleGeneration
                )
                continue
            }
            switch outcome {
            case .success(let bytes):
                waiter.continuation.resume(returning: bytes)
            case .failure(let error):
                waiter.continuation.resume(throwing: error)
            }
        }
    }

    /// Removes and resumes exactly the cancelled waiter; the shared
    /// computation continues for its followers.
    private func cancelWaiter(key: RequestKey, waiterID: UInt64) {
        guard let waiter = inFlight[key]?.removeValue(forKey: waiterID) else {
            return
        }
        waiter.continuation.resume(throwing: CancellationError())
    }
}
