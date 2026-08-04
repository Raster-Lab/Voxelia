// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaStorage

@Suite("ContiguousImageStorage")
struct ContiguousImageStorageTests {
    private func storage() throws -> ContiguousImageStorage {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 2
        )
        return try ContiguousImageStorage(
            binding: binding,
            bytes: Array(0..<24)
        )
    }

    @Test("[Unit][VOX-STO-006][VOX-API-004] region reads copy exact packed runs")
    func regionReadsCopyExactPackedRuns() throws {
        let storage = try storage()

        // The full region returns the complete backing.
        let full = try storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        )
        #expect(full.bytes == Array(0..<24))

        // A sub-region copies exactly the addressed interleaved runs:
        // x in [1,3), y in [0,2) over a 4-wide row of 2-byte elements.
        let sub = try storage.read(
            region: try ImageRegion(lowerBounds: [1, 0], upperBounds: [3, 2])
        )
        #expect(sub.bytes == [2, 3, 4, 5, 10, 11, 12, 13])
        #expect(sub.binding.shape.extents == [2, 2])

        // A mismatched backing length is an incompatible binding.
        do {
            _ = try ContiguousImageStorage(
                binding: storage.snapshot.binding,
                bytes: Array(0..<23)
            )
            #expect(Bool(false), "Expected a short backing to be rejected.")
        } catch StorageContractError.incompatibleBinding {}

        requireSendable(ContiguousImageStorage.self)
        requireSendable(AnyImageStorage.self)
    }

    @Test("[Unit][VOX-STO-007][VOX-API-004] erasure dispatches with checked unerase")
    func erasureDispatchesWithCheckedUnerase() throws {
        let storage = try storage()
        let erased = AnyImageStorage(erasing: storage)

        // The erased handle forwards snapshot identity and reads exactly.
        #expect(erased.snapshot.authority === storage.snapshot.authority)
        let read = try erased.read(
            region: try ImageRegion(lowerBounds: [0, 1], upperBounds: [4, 2])
        )
        #expect(read.bytes == Array(8..<16))

        // Checked unerase recovers exactly the erased type and fails
        // typed for any other, with no fallback.
        let recovered = try erased.unerased(as: ContiguousImageStorage.self)
        #expect(recovered.snapshot.authority === storage.snapshot.authority)

        struct OtherStorage: ImageStorageContract {
            let snapshot: StorageSnapshotHandle
            func read(region: ImageRegion) throws -> RegionReadResult {
                throw StorageContractError.unsupportedOperation
            }
        }
        let other = AnyImageStorage(
            erasing: OtherStorage(snapshot: storage.snapshot)
        )
        do {
            _ = try other.unerased(as: ContiguousImageStorage.self)
            #expect(Bool(false), "Expected a foreign unerase to fail typed.")
        } catch StorageContractError.incompatibleBinding {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
