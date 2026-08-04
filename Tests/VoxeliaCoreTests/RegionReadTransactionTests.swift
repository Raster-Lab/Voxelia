// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

private final class OwnerToken: Sendable {}

@Suite("RegionReadTransaction")
struct RegionReadTransactionTests {
    private func handle() throws -> StorageSnapshotHandle {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 2
        )
        let packed = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: .native,
            locality: .processLocalOwned
        )
        return try StorageSnapshotHandle.admit(
            binding: binding,
            representation: .decodedStrided(packed),
            owner: OwnerToken(),
            generation: 1
        )
    }

    @Test("[Unit][VOX-STO-005][VOX-API-004] monotonic fill commits exactly once")
    func monotonicFillCommitsExactlyOnce() throws {
        let handle = try handle()
        let region = try ImageRegion(lowerBounds: [1, 0], upperBounds: [3, 2])
        let transaction = try RegionReadTransaction(handle: handle, region: region)
        #expect(transaction.expectedByteCount == 8)

        // Fill in two monotonic writes and commit the owned result.
        try transaction.fill { fill in
            try fill.write([1, 2, 3, 4])
            try fill.write([5, 6, 7, 8])
        }
        let result = try transaction.commit()
        #expect(result.bytes == [1, 2, 3, 4, 5, 6, 7, 8])
        #expect(result.binding.shape.extents == [2, 2])
        #expect(result.binding.logicalByteCount == 8)

        // A committed transaction is a tombstone: no second commit, no
        // further fill.
        do {
            _ = try transaction.commit()
            #expect(Bool(false), "Expected a second commit to be rejected.")
        } catch StorageContractError.contractViolation {}
        do {
            try transaction.fill { _ in }
            #expect(Bool(false), "Expected fill after commit to be rejected.")
        } catch StorageContractError.contractViolation {}

        requireSendable(RegionReadResult.self)
    }

    @Test("[Unit][VOX-STO-005][VOX-ERR-001] admission rejects before any provider")
    func admissionRejectsBeforeAnyProvider() throws {
        let handle = try handle()

        // Rank mismatch, empty region and out-of-bounds regions reject.
        for (lower, upper) in [([0], [2]), ([0, 0], [0, 2]), ([0, 0], [5, 2])] {
            do {
                _ = try RegionReadTransaction(
                    handle: handle,
                    region: try ImageRegion(lowerBounds: lower, upperBounds: upper)
                )
                #expect(Bool(false), "Expected an invalid region to be rejected.")
            } catch StorageContractError.invalidRegion {}
        }

        // Opaque representations have no admitted read operation.
        let opaqueHandle = try StorageSnapshotHandle.admit(
            binding: handle.binding,
            representation: .opaque(
                try OpaqueRepresentation(formatTag: "org.example.brick", knownByteCount: nil)
            ),
            owner: OwnerToken(),
            generation: 1
        )
        do {
            _ = try RegionReadTransaction(
                handle: opaqueHandle,
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [1, 1])
            )
            #expect(Bool(false), "Expected an opaque read to be unsupported.")
        } catch StorageContractError.unsupportedOperation {}
    }

    @Test("[Unit][VOX-STO-005][VOX-SEC-011] violations poison and fail closed")
    func violationsPoisonAndFailClosed() throws {
        let handle = try handle()
        let region = try ImageRegion(lowerBounds: [0, 0], upperBounds: [1, 1])

        // Overrun writes poison the fill; commit then fails closed.
        let overrun = try RegionReadTransaction(handle: handle, region: region)
        do {
            try overrun.fill { fill in
                try fill.write([1, 2, 3])
            }
            #expect(Bool(false), "Expected an overrun write to be rejected.")
        } catch StorageContractError.contractViolation {}
        do {
            _ = try overrun.commit()
            #expect(Bool(false), "Expected a poisoned commit to fail closed.")
        } catch StorageContractError.contractViolation {}

        // Incomplete coverage fails closed at commit.
        let incomplete = try RegionReadTransaction(handle: handle, region: region)
        try incomplete.fill { fill in
            try fill.write([1])
        }
        do {
            _ = try incomplete.commit()
            #expect(Bool(false), "Expected incomplete coverage to fail closed.")
        } catch StorageContractError.contractViolation {}

        // Cancellation blocks commit immediately and permanently.
        let cancelled = try RegionReadTransaction(handle: handle, region: region)
        try cancelled.fill { fill in
            try fill.write([1, 2])
        }
        cancelled.cancel()
        do {
            _ = try cancelled.commit()
            #expect(Bool(false), "Expected a cancelled commit to be rejected.")
        } catch StorageContractError.cancelled {}

        // A throwing provider terminalises as failed without retaining
        // the provider's own error.
        struct ProviderError: Error {}
        let failed = try RegionReadTransaction(handle: handle, region: region)
        do {
            try failed.fill { _ in
                throw ProviderError()
            }
            #expect(Bool(false), "Expected a throwing provider to fail typed.")
        } catch StorageContractError.providerFailure {}
        do {
            _ = try failed.commit()
            #expect(Bool(false), "Expected a failed transaction to stay terminal.")
        } catch StorageContractError.contractViolation {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
