// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

private final class OwnerToken: Sendable {}

@Suite("StorageSnapshotHandle")
struct StorageSnapshotHandleTests {
    private func binding() throws -> LogicalSampleBinding {
        try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .int16,
            componentCount: 2
        )
    }

    @Test("[Unit][VOX-STO-003][VOX-SEC-011] admission mints nonforgeable authority")
    func admissionMintsNonforgeableAuthority() throws {
        let binding = try binding()
        let packed = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: .littleEndian,
            locality: .processLocalOwned
        )
        let handle = try StorageSnapshotHandle.admit(
            binding: binding,
            representation: .decodedStrided(packed),
            owner: OwnerToken(),
            generation: 1
        )
        #expect(handle.binding == binding)
        #expect(handle.generation == 1)

        // Two admissions of even identical content are distinct lineages:
        // no cross-admission authority aliasing.
        let second = try StorageSnapshotHandle.admit(
            binding: binding,
            representation: .decodedStrided(packed),
            owner: OwnerToken(),
            generation: 1
        )
        #expect(handle.authority !== second.authority)

        // A decoded representation carrying a different binding rejects.
        let other = try LogicalSampleBinding(
            shape: try ImageShape(extents: [2, 2]),
            scalarType: .uint8,
            componentCount: 1
        )
        do {
            _ = try StorageSnapshotHandle.admit(
                binding: other,
                representation: .decodedStrided(packed),
                owner: OwnerToken(),
                generation: 1
            )
            #expect(Bool(false), "Expected a foreign decoded binding to reject.")
        } catch StorageContractError.incompatibleBinding {}

        requireSendable(StorageSnapshotHandle.self)
        requireSendable(StorageReadAuthority.self)
    }

    @Test("[Unit][VOX-STO-003][VOX-API-004] successors co-retain the authority")
    func successorsCoRetainTheAuthority() throws {
        let binding = try binding()
        let packed = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: .littleEndian,
            locality: .processLocalOwned
        )
        let first = try StorageSnapshotHandle.admit(
            binding: binding,
            representation: .decodedStrided(packed),
            owner: OwnerToken(),
            generation: 1
        )
        let next = try first.successor(
            representation: .decodedStrided(packed),
            owner: OwnerToken(),
            generation: 2
        )

        // Same lineage, same co-retained authority, immutable original.
        #expect(next.authority === first.authority)
        #expect(next.generation == 2)
        #expect(first.generation == 1)

        // Non-increasing generations are stale, never relabelled.
        for stale: UInt64 in [2, 1, 0] {
            do {
                _ = try next.successor(
                    representation: .decodedStrided(packed),
                    owner: OwnerToken(),
                    generation: stale
                )
                #expect(Bool(false), "Expected a non-increasing generation to reject.")
            } catch StorageContractError.staleSnapshot {}
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
