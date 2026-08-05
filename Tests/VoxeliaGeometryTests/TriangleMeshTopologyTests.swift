// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaGeometry

@Suite("TriangleMeshTopology")
struct TriangleMeshTopologyTests {
    @Test("[Unit][VOX-GEO-003][VOX-GEO-005] admits empty and complete topology")
    func admitsEmptyAndCompleteTopology() throws {
        let empty = try TriangleMeshTopology(vertexCount: 0, indices: [])
        #expect(empty.vertexCount == 0)
        #expect(empty.indices.isEmpty)
        #expect(empty.triangleCount == 0)

        let indices: ContiguousArray<UInt64> = [0, 1, 2, 2, 3, 0]
        let topology = try TriangleMeshTopology(
            vertexCount: 4,
            indices: indices
        )
        #expect(topology.vertexCount == 4)
        #expect(topology.indices == indices)
        #expect(topology.triangleCount == 2)
    }

    @Test("[Unit][VOX-ERR-001] negative vertex count rejects first")
    func rejectsNegativeVertexCountFirst() {
        #expect(throws: TriangleMeshTopologyError.negativeVertexCount) {
            try TriangleMeshTopology(vertexCount: -1, indices: [UInt64.max])
        }
        #expect(throws: TriangleMeshTopologyError.negativeVertexCount) {
            try TriangleMeshTopology(vertexCount: Int.min, indices: [0, 1, 2])
        }
    }

    @Test("[Unit][VOX-ERR-001] incomplete triangle rejects before index bounds")
    func rejectsIncompleteTriangleBeforeBounds() {
        for indices: ContiguousArray<UInt64> in [
            [UInt64.max],
            [0, UInt64.max],
            [0, 1, 2, UInt64.max],
        ] {
            #expect(throws: TriangleMeshTopologyError.incompleteTriangle) {
                try TriangleMeshTopology(vertexCount: 0, indices: indices)
            }
        }
    }

    @Test("[Unit][VOX-GEO-005][VOX-ERR-001] every index is bounds checked")
    func rejectsOutOfBoundsIndices() {
        let fixtures: [(vertexCount: Int, indices: ContiguousArray<UInt64>)] = [
            (0, [0, 0, 0]),
            (3, [0, 1, 3]),
            (3, [UInt64.max, 0, 0]),
        ]
        for fixture in fixtures {
            #expect(throws: TriangleMeshTopologyError.indexOutOfBounds) {
                try TriangleMeshTopology(
                    vertexCount: fixture.vertexCount,
                    indices: fixture.indices
                )
            }
        }
    }

    @Test("[Unit][VOX-GEO-003] preserves order, multiplicity, and degeneracy")
    func preservesExactTopology() throws {
        let indices: ContiguousArray<UInt64> = [2, 2, 2, 1, 0, 2, 2, 2, 2]
        let topology = try TriangleMeshTopology(
            vertexCount: 3,
            indices: indices
        )

        #expect(topology.indices == indices)
        #expect(topology.triangleCount == 3)
    }

    @Test("[Unit][VOX-GEO-005] admits the host vertex-domain boundary")
    func admitsHostVertexDomainBoundary() throws {
        let greatestValidIndex = UInt64(Int.max - 1)
        let topology = try TriangleMeshTopology(
            vertexCount: Int.max,
            indices: [greatestValidIndex, 0, greatestValidIndex]
        )

        #expect(topology.indices[0] == greatestValidIndex)
        #expect(topology.vertexCount == Int.max)
    }

    @Test("[Unit][VOX-API-003] remains Sendable, Hashable, and payload-free")
    func remainsSendableAndHashable() throws {
        requireSendable(TriangleMeshTopology.self)
        requireSendable(TriangleMeshTopologyError.self)

        let first = try TriangleMeshTopology(vertexCount: 3, indices: [0, 1, 2])
        let equal = try TriangleMeshTopology(vertexCount: 3, indices: [0, 1, 2])
        let reordered = try TriangleMeshTopology(vertexCount: 3, indices: [2, 1, 0])

        #expect(first == equal)
        #expect(first != reordered)
        #expect(Set([first, equal, reordered]).count == 2)
        #expect(
            TriangleMeshTopologyError.indexOutOfBounds
                == TriangleMeshTopologyError.indexOutOfBounds
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
