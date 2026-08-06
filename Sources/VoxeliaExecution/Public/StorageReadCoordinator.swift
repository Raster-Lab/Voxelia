// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The retention token for one coordinated read's retained result bytes.
///
/// Identity-based and minted only by the coordinator; releasing it
/// exactly once returns this waiter's share of the retained charge.
public final class ReadRetentionToken: Sendable {
    init() {}
}

/// One coordinated, budgeted region read result.
public struct CoordinatedReadResult: Sendable {
    /// The complete owned read result.
    public let result: RegionReadResult
    /// The token whose explicit release frees this waiter's retention.
    public let retention: ReadRetentionToken

    init(result: RegionReadResult, retention: ReadRetentionToken) {
        self.result = result
        self.retention = retention
    }
}

/// The actor-isolated Execution read coordinator selected by `ADR-0046`
/// and extended with single-flight deduplication by `ADR-0048`.
///
/// Concurrent identical reads — same admitted authority, snapshot
/// generation and exact region — coalesce onto one shared provider
/// execution whose copy-on-write result bytes are charged once. Every
/// successful waiter receives its own retention token; the shared charge
/// is freed when the last token is released and the last waiter has
/// finished. Reservation is charged after Core admission and before any
/// provider invocation, provider work runs outside the actor's
/// isolation, and failures release the shared reservation exactly once.
public actor StorageReadCoordinator {
    private struct ReadKey: Hashable {
        let authority: ObjectIdentifier
        let generation: UInt64
        let lowerBounds: ContiguousArray<Int>
        let upperBounds: ContiguousArray<Int>
    }

    private final class ChargeGroup {
        let byteCount: UInt64
        var refCount = 0
        var detached = false

        init(byteCount: UInt64) {
            self.byteCount = byteCount
        }
    }

    private final class InFlightRead {
        let id: UInt64
        let task: Task<(RegionReadResult, UInt64), any Error>
        var waiterCount = 0

        init(id: UInt64, task: Task<(RegionReadResult, UInt64), any Error>) {
            self.id = id
            self.task = task
        }
    }

    /// The inclusive active-plus-retained result-byte ceiling.
    public let maximumRetainedResultByteCount: UInt64

    private var chargedByteCount: UInt64 = 0
    private var chargeGroups: [UInt64: ChargeGroup] = [:]
    private var tokenGroups: [ObjectIdentifier: UInt64] = [:]
    private var inFlightReads: [ReadKey: InFlightRead] = [:]
    private var nextIdentifier: UInt64 = 0

    /// The number of shared provider executions ever started; evidence
    /// for single-flight coalescing.
    private(set) var startedSharedReadCount = 0

    /// Creates a coordinator with one explicit inclusive budget; there is
    /// no permissive default.
    public init(maximumRetainedResultByteCount: UInt64) {
        self.maximumRetainedResultByteCount = maximumRetainedResultByteCount
    }

    /// The currently charged active-plus-retained byte count.
    public var currentChargedByteCount: UInt64 {
        chargedByteCount
    }

    // MARK: - Ledger

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

    private func registerGroup(_ byteCount: UInt64) -> UInt64 {
        nextIdentifier += 1
        chargeGroups[nextIdentifier] = ChargeGroup(byteCount: byteCount)
        return nextIdentifier
    }

    private func freeGroupIfUnreferenced(_ identifier: UInt64) {
        guard let group = chargeGroups[identifier], group.detached,
            group.refCount == 0
        else {
            return
        }
        chargeGroups.removeValue(forKey: identifier)
        releaseReservation(group.byteCount)
    }

    /// Releases one waiter's retained share exactly once.
    ///
    /// - Throws: `StorageContractError.contractViolation` for an
    ///   unknown or already released token.
    public func release(_ token: ReadRetentionToken) throws {
        guard
            let groupIdentifier = tokenGroups.removeValue(
                forKey: ObjectIdentifier(token)
            ),
            let group = chargeGroups[groupIdentifier]
        else {
            throw StorageContractError.contractViolation
        }
        group.refCount -= 1
        freeGroupIfUnreferenced(groupIdentifier)
    }

    // MARK: - Single-flight coordination

    private func joinOrStart(
        key: ReadKey,
        storage: some ImageStorageContract,
        region: ImageRegion
    ) -> (id: UInt64, task: Task<(RegionReadResult, UInt64), any Error>) {
        if let existing = inFlightReads[key] {
            existing.waiterCount += 1
            return (existing.id, existing.task)
        }
        startedSharedReadCount += 1
        nextIdentifier += 1
        let identifier = nextIdentifier
        let shared = Task.detached {
            () throws -> (RegionReadResult, UInt64) in
            let transaction = try RegionReadTransaction(
                handle: storage.snapshot,
                region: region
            )
            let expected = UInt64(transaction.expectedByteCount)
            try await self.reserve(expected)
            let result: RegionReadResult
            do {
                result = try storage.read(region: region)
            } catch let error as StorageContractError {
                await self.releaseReservation(expected)
                throw error
            } catch {
                await self.releaseReservation(expected)
                throw StorageContractError.providerFailure
            }
            guard UInt64(result.bytes.count) == expected else {
                await self.releaseReservation(expected)
                throw StorageContractError.contractViolation
            }
            let group = await self.registerGroup(expected)
            return (result, group)
        }
        let entry = InFlightRead(id: identifier, task: shared)
        entry.waiterCount = 1
        inFlightReads[key] = entry
        return (identifier, shared)
    }

    /// One waiter finishes: it either keeps a minted token or converts
    /// charge-neutrally; the last waiter detaches the entry so the group
    /// can be freed once every token is released.
    private func finishWaiter(
        key: ReadKey,
        entryIdentifier: UInt64,
        groupIdentifier: UInt64?,
        keepToken: Bool
    ) -> ReadRetentionToken? {
        var token: ReadRetentionToken?
        if let groupIdentifier, let group = chargeGroups[groupIdentifier],
            keepToken
        {
            let minted = ReadRetentionToken()
            tokenGroups[ObjectIdentifier(minted)] = groupIdentifier
            group.refCount += 1
            token = minted
        }
        if let entry = inFlightReads[key], entry.id == entryIdentifier {
            entry.waiterCount -= 1
            if entry.waiterCount <= 0 {
                inFlightReads.removeValue(forKey: key)
                if let groupIdentifier, let group = chargeGroups[groupIdentifier] {
                    group.detached = true
                    freeGroupIfUnreferenced(groupIdentifier)
                }
            }
        }
        return token
    }

    /// Performs one coordinated, budgeted, cancellable region read,
    /// coalescing concurrent identical requests onto one shared provider
    /// execution.
    public nonisolated func read(
        from storage: some ImageStorageContract,
        region: ImageRegion
    ) async throws -> CoordinatedReadResult {
        let key = ReadKey(
            authority: ObjectIdentifier(storage.snapshot.authority),
            generation: storage.snapshot.generation,
            lowerBounds: region.lowerBounds,
            upperBounds: region.upperBounds
        )
        let (identifier, shared) = await joinOrStart(
            key: key,
            storage: storage,
            region: region
        )

        let outcome: (RegionReadResult, UInt64)
        do {
            outcome = try await shared.value
        } catch {
            _ = await finishWaiter(
                key: key,
                entryIdentifier: identifier,
                groupIdentifier: nil,
                keepToken: false
            )
            throw error
        }

        // A caller cancelled after shared completion converts
        // charge-neutrally: the shared work stays valid for other
        // waiters and nothing leaks.
        if Task.isCancelled {
            _ = await finishWaiter(
                key: key,
                entryIdentifier: identifier,
                groupIdentifier: outcome.1,
                keepToken: false
            )
            throw StorageContractError.cancelled
        }
        guard
            let token = await finishWaiter(
                key: key,
                entryIdentifier: identifier,
                groupIdentifier: outcome.1,
                keepToken: true
            )
        else {
            throw StorageContractError.contractViolation
        }
        return CoordinatedReadResult(result: outcome.0, retention: token)
    }
}
