// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaStorage

@testable import VoxeliaExecution

private struct FailingStorage: ImageStorageContract {
    let snapshot: StorageSnapshotHandle

    func read(region: ImageRegion) throws -> RegionReadResult {
        throw StorageContractError.providerFailure
    }
}

@Suite("StorageReadCoordinator")
struct StorageReadCoordinatorTests {
    private func storage() throws -> ContiguousImageStorage {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 2
        )
        return try ContiguousImageStorage(binding: binding, bytes: Array(0..<24))
    }

    @Test("[Unit][VOX-EXE-002][VOX-SEC-001] budgets charge and release exactly")
    func budgetsChargeAndReleaseExactly() async throws {
        let storage = try storage()
        let coordinator = StorageReadCoordinator(maximumRetainedResultByteCount: 24)

        // A committed read retains exactly its expected bytes until the
        // token is explicitly released.
        let full = try await coordinator.read(
            from: storage,
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        )
        #expect(full.result.bytes == Array(0..<24))
        #expect(await coordinator.currentChargedByteCount == 24)

        // A second read over the remaining budget is rejected before the
        // provider runs, leaving the ledger unchanged.
        do {
            _ = try await coordinator.read(
                from: storage,
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [1, 1])
            )
            #expect(Bool(false), "Expected an over-budget read to be rejected.")
        } catch StorageContractError.resourceLimitExceeded {}
        #expect(await coordinator.currentChargedByteCount == 24)

        // Explicit release frees the charge exactly once.
        try await coordinator.release(full.retention)
        #expect(await coordinator.currentChargedByteCount == 0)
        do {
            try await coordinator.release(full.retention)
            #expect(Bool(false), "Expected a double release to be rejected.")
        } catch StorageContractError.contractViolation {}

        // After release the budget admits new work again.
        let again = try await coordinator.read(
            from: storage,
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [1, 1])
        )
        #expect(again.result.bytes == [0, 1])
        try await coordinator.release(again.retention)
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] failures release the reservation")
    func failuresReleaseTheReservation() async throws {
        let healthy = try storage()
        let coordinator = StorageReadCoordinator(maximumRetainedResultByteCount: 100)

        // A provider failure releases the reservation and surfaces typed.
        let failing = FailingStorage(snapshot: healthy.snapshot)
        do {
            _ = try await coordinator.read(
                from: failing,
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [1, 1])
            )
            #expect(Bool(false), "Expected a provider failure to surface typed.")
        } catch StorageContractError.providerFailure {}
        #expect(await coordinator.currentChargedByteCount == 0)

        // Pre-admission rejection touches neither budget nor provider.
        do {
            _ = try await coordinator.read(
                from: healthy,
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [9, 9])
            )
            #expect(Bool(false), "Expected an invalid region to be rejected.")
        } catch StorageContractError.invalidRegion {}
        #expect(await coordinator.currentChargedByteCount == 0)

        // Cancellation before provider work throws typed and releases.
        let task = Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return try await coordinator.read(
                from: healthy,
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [1, 1])
            )
        }
        task.cancel()
        do {
            _ = try await task.value
            #expect(Bool(false), "Expected a cancelled read to throw typed.")
        } catch is CancellationError {
            // Task.sleep observed cancellation before the read began.
        } catch StorageContractError.cancelled {}
        #expect(await coordinator.currentChargedByteCount == 0)

        // Concurrent reads within budget account exactly.
        async let first = coordinator.read(
            from: healthy,
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 3])
        )
        async let second = coordinator.read(
            from: healthy,
            region: try ImageRegion(lowerBounds: [2, 0], upperBounds: [4, 3])
        )
        let (a, b) = try await (first, second)
        #expect(await coordinator.currentChargedByteCount == 24)
        try await coordinator.release(a.retention)
        try await coordinator.release(b.retention)
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    @Test("[Unit][VOX-EXE-006][VOX-PER-007] identical concurrent reads coalesce")
    func identicalConcurrentReadsCoalesce() async throws {
        let storage = try storage()
        let coordinator = StorageReadCoordinator(maximumRetainedResultByteCount: 24)
        let region = try ImageRegion(lowerBounds: [0, 0], upperBounds: [3, 2])

        // Sixteen identical concurrent reads share provider executions
        // and charge the copy-on-write result bytes once per shared
        // execution, never once per waiter.
        let results = try await withThrowingTaskGroup(
            of: CoordinatedReadResult.self
        ) { group in
            for _ in 0..<16 {
                group.addTask {
                    try await coordinator.read(from: storage, region: region)
                }
            }
            var collected = [CoordinatedReadResult]()
            for try await result in group {
                collected.append(result)
            }
            return collected
        }
        #expect(results.count == 16)
        for result in results {
            #expect(result.result.bytes == results[0].result.bytes)
        }
        let started = await coordinator.startedSharedReadCount
        #expect(started >= 1)
        #expect(started < 16)
        let charged = await coordinator.currentChargedByteCount
        #expect(charged == UInt64(started) * 12)

        // Every waiter holds its own token; the shared charge frees only
        // after the last release, and each token releases exactly once.
        for (index, result) in results.enumerated() {
            try await coordinator.release(result.retention)
            if index < results.count - 1 {
                #expect(await coordinator.currentChargedByteCount > 0 || started > 1)
            }
        }
        #expect(await coordinator.currentChargedByteCount == 0)
        do {
            try await coordinator.release(results[0].retention)
            #expect(Bool(false), "Expected a double release to be rejected.")
        } catch StorageContractError.contractViolation {}
    }
}
