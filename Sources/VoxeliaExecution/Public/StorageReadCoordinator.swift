// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The retention token for one coordinated read's retained result bytes.
///
/// Identity-based and minted only by the coordinator; releasing it
/// exactly once returns the retained charge to the budget.
public final class ReadRetentionToken: Sendable {
    init() {}
}

/// One coordinated, budgeted region read result.
public struct CoordinatedReadResult: Sendable {
    /// The complete owned read result.
    public let result: RegionReadResult
    /// The token whose explicit release frees the retained charge.
    public let retention: ReadRetentionToken

    init(result: RegionReadResult, retention: ReadRetentionToken) {
        self.result = result
        self.retention = retention
    }
}

/// The actor-isolated Execution read coordinator selected by `ADR-0046`.
///
/// The actor owns only the active-plus-retained byte ledger and token
/// state: reservation is charged after Core admission and before any
/// provider invocation, provider fill and commit run outside the actor's
/// isolation, failure or cancellation releases the reservation exactly
/// once, and a committed result's charge is retained until its token is
/// explicitly released. Single-flight deduplication, caching, lazy
/// identity and provenance capture remain later M2 increments.
public actor StorageReadCoordinator {
    /// The inclusive active-plus-retained result-byte ceiling.
    public let maximumRetainedResultByteCount: UInt64

    private var chargedByteCount: UInt64 = 0
    private var retainedTokens: [ObjectIdentifier: UInt64] = [:]

    /// Creates a coordinator with one explicit inclusive budget; there is
    /// no permissive default.
    public init(maximumRetainedResultByteCount: UInt64) {
        self.maximumRetainedResultByteCount = maximumRetainedResultByteCount
    }

    /// The currently charged active-plus-retained byte count.
    public var currentChargedByteCount: UInt64 {
        chargedByteCount
    }

    private func reserve(_ byteCount: UInt64) throws {
        let (candidate, overflow) = chargedByteCount.addingReportingOverflow(byteCount)
        guard !overflow, candidate <= maximumRetainedResultByteCount else {
            throw StorageContractError.resourceLimitExceeded
        }
        chargedByteCount = candidate
    }

    private func releaseReservation(_ byteCount: UInt64) {
        chargedByteCount -= min(byteCount, chargedByteCount)
    }

    private func convertReservationToRetention(
        _ byteCount: UInt64
    ) -> ReadRetentionToken {
        let token = ReadRetentionToken()
        retainedTokens[ObjectIdentifier(token)] = byteCount
        return token
    }

    /// Releases one retained result charge exactly once.
    ///
    /// - Throws: ``StorageContractError/contractViolation`` for an
    ///   unknown or already released token.
    public func release(_ token: ReadRetentionToken) throws {
        guard
            let byteCount = retainedTokens.removeValue(
                forKey: ObjectIdentifier(token)
            )
        else {
            throw StorageContractError.contractViolation
        }
        releaseReservation(byteCount)
    }

    /// Performs one coordinated, budgeted, cancellable region read.
    ///
    /// The Core transaction is admitted first, the budget is charged
    /// before the provider is invoked, and the synchronous provider work
    /// runs outside the actor's isolation.
    public nonisolated func read(
        from storage: some ImageStorageContract,
        region: ImageRegion
    ) async throws -> CoordinatedReadResult {
        // Core admission before any budget or provider work.
        let transaction = try RegionReadTransaction(
            handle: storage.snapshot,
            region: region
        )
        let expected = UInt64(transaction.expectedByteCount)

        // Reservation before provider invocation.
        try await reserve(expected)

        // Cancellation observed before provider work cancels the
        // transaction and releases the reservation.
        if Task.isCancelled {
            transaction.cancel()
            await releaseReservation(expected)
            throw StorageContractError.cancelled
        }

        // Provider fill and commit run outside the actor's isolation.
        let result: RegionReadResult
        do {
            result = try storage.read(region: region)
        } catch let error as StorageContractError {
            await releaseReservation(expected)
            throw error
        } catch {
            await releaseReservation(expected)
            throw StorageContractError.providerFailure
        }
        guard UInt64(result.bytes.count) == expected else {
            await releaseReservation(expected)
            throw StorageContractError.contractViolation
        }

        let token = await convertReservationToRetention(expected)
        return CoordinatedReadResult(result: result, retention: token)
    }
}
