// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

@testable import VoxeliaCPU

@Suite("CPU scalar-surface reference kernel")
struct ScalarSurfaceReferenceKernelTests {
    @Test(
        "[Kernel][VOX-GEO-006][VOX-ERR-001] every admitted scalar and byte order matches the golden",
        arguments: [
            ScalarType.int8, .uint8, .int16, .uint16, .int32, .uint32,
            .float16, .float32, .float64,
        ],
        [ByteOrder.native, .littleEndian, .bigEndian]
    )
    func admittedScalarAndByteOrder(
        scalarType: ScalarType,
        byteOrder: ByteOrder
    ) async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture(
            scalarType: scalarType,
            byteOrder: byteOrder
        )
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let mesh = try await CPUScalarSurfaceExtractionOperation.extractMesh(
            request: ScalarSurfaceTestSupport.request(fixture: fixture),
            coordinator: coordinator
        )

        #expect(
            mesh.positions.components
                == ScalarSurfaceTestSupport.singleCornerPositions
        )
        #expect(
            mesh.topology.indices
                == ScalarSurfaceTestSupport.singleCornerIndices
        )
        #expect(fixture.owner.readCount == 1)
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    @Test(
        "[Kernel][VOX-GEO-006] signed and floating negative samples decode exactly",
        arguments: [
            ScalarType.int8, .int16, .int32, .float16, .float32, .float64,
        ],
        [ByteOrder.native, .littleEndian, .bigEndian]
    )
    func signedNegativeDecoding(
        scalarType: ScalarType,
        byteOrder: ByteOrder
    ) async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture(
            scalarType: scalarType,
            byteOrder: byteOrder,
            values: [1, -1, -1, -1, -1, -1, -1, -1]
        )
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let mesh = try await CPUScalarSurfaceExtractionOperation.extractMesh(
            request: ScalarSurfaceTestSupport.request(
                fixture: fixture,
                isovalue: 0
            ),
            coordinator: coordinator
        )
        #expect(
            mesh.positions.components
                == ScalarSurfaceTestSupport.singleCornerPositions
        )
        #expect(
            mesh.topology.indices
                == ScalarSurfaceTestSupport.singleCornerIndices
        )
    }

    @Test("[Oracle][VOX-GEO-006] all 256 masks match rational and binary64 digests")
    func everyBinaryCubeMaskMatchesIndependentOracle() async throws {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        var records = [String]()
        var binary64Records = [String]()
        var maximumVertexCount = 0
        var maximumTriangleCount = 0

        for mask in 0..<256 {
            let values = (0..<8).map {
                mask & (1 << $0) == 0 ? 0.0 : 1.0
            }
            let fixture = try ScalarSurfaceTestSupport.fixture(values: values)
            let mesh = try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(fixture: fixture),
                coordinator: coordinator
            )
            maximumVertexCount = max(
                maximumVertexCount,
                mesh.positions.vertexCount
            )
            maximumTriangleCount = max(
                maximumTriangleCount,
                mesh.topology.triangleCount
            )
            for offset in stride(
                from: 0,
                to: mesh.topology.indices.count,
                by: 3
            ) {
                let triangle = mesh.topology.indices[offset..<(offset + 3)]
                #expect(Set(triangle).count == 3)
            }
            records.append(
                try oracleRecord(mask: mask, mesh: mesh)
            )
            binary64Records.append(
                binary64Record(mask: mask, mesh: mesh)
            )
        }

        let document = "[" + records.joined(separator: ",") + "]"
        #expect(
            sha256(document)
                == "4bed958ac7d25a4539de8a0cea28524271a89303c3e9e3fb0de0d311e5c6931d"
        )
        let binary64Document =
            "[" + binary64Records.joined(separator: ",") + "]"
        #expect(
            sha256(binary64Document)
                == "154f1d57f1fe6491f9fe6267109fa46074ffba860d16f7284736388a434536aa"
        )
        #expect(maximumVertexCount == 13)
        #expect(maximumTriangleCount == 12)
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    @Test("[Kernel][VOX-GEO-006] equality collapse, empty cells, and shared seams are exact")
    func equalityEmptyAndSharedSeamFixtures() async throws {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 4_096
        )
        let equality = try ScalarSurfaceTestSupport.fixture(
            values: [0.5, 0, 0, 0, 0, 0, 0, 0]
        )
        let equalityMesh = try await extract(
            fixture: equality,
            coordinator: coordinator
        )
        #expect(equalityMesh.positions.components.isEmpty)
        #expect(equalityMesh.topology.indices.isEmpty)

        let noCells = try ScalarSurfaceTestSupport.fixture(
            extents: [1, 2, 2],
            values: [0, 0, 0, 0]
        )
        let emptyMesh = try await extract(
            fixture: noCells,
            coordinator: coordinator
        )
        #expect(emptyMesh.positions.components.isEmpty)
        #expect(emptyMesh.topology.indices.isEmpty)

        let seam = try ScalarSurfaceTestSupport.fixture(
            extents: [3, 2, 2],
            values: [
                0, 0, 0,
                1, 1, 1,
                2, 2, 2,
                3, 3, 3,
            ]
        )
        let seamMesh = try await extract(
            fixture: seam,
            isovalue: 0.75,
            coordinator: coordinator
        )
        let positions = positionTriples(seamMesh)
        #expect(positions.contains { $0[0] == 1 })
        #expect(Set(positions.map(positionKey)).count == positions.count)
        #expect(
            sha256(binary64Record(mask: nil, mesh: seamMesh))
                == "348948097129d59454615bae09372c8ff16b5564ac0db7f95433b168cb05f86e"
        )
    }

    @Test("[Kernel][VOX-GEO-006] reflected and permuted spaces preserve physical winding")
    func reflectedAndPermutedGeometry() async throws {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let reflected = try ScalarSurfaceTestSupport.fixture(
            matrixElements: [
                -1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]
        )
        let reflectedMesh = try await extract(
            fixture: reflected,
            coordinator: coordinator
        )
        var expectedReflected = ContiguousArray<Double>()
        for offset in stride(
            from: 0,
            to: ScalarSurfaceTestSupport.singleCornerPositions.count,
            by: 3
        ) {
            expectedReflected.append(
                -ScalarSurfaceTestSupport.singleCornerPositions[offset]
            )
            expectedReflected.append(
                ScalarSurfaceTestSupport.singleCornerPositions[offset + 1]
            )
            expectedReflected.append(
                ScalarSurfaceTestSupport.singleCornerPositions[offset + 2]
            )
        }
        #expect(reflectedMesh.positions.components == expectedReflected)
        #expect(
            reflectedMesh.topology.indices
                == reversedWinding(
                    ScalarSurfaceTestSupport.singleCornerIndices
                )
        )

        let permuted = try ScalarSurfaceTestSupport.fixture(
            spatialAxes: [1, 0, 2]
        )
        let permutedMesh = try await extract(
            fixture: permuted,
            coordinator: coordinator
        )
        var expectedPermuted = ContiguousArray<Double>()
        for offset in stride(
            from: 0,
            to: ScalarSurfaceTestSupport.singleCornerPositions.count,
            by: 3
        ) {
            expectedPermuted.append(
                ScalarSurfaceTestSupport.singleCornerPositions[offset + 1]
            )
            expectedPermuted.append(
                ScalarSurfaceTestSupport.singleCornerPositions[offset]
            )
            expectedPermuted.append(
                ScalarSurfaceTestSupport.singleCornerPositions[offset + 2]
            )
        }
        #expect(permutedMesh.positions.components == expectedPermuted)
        #expect(
            permutedMesh.topology.indices
                == reversedWinding(
                    ScalarSurfaceTestSupport.singleCornerIndices
                )
        )
    }

    @Test("[Kernel][VOX-ERR-001] interpolation and position failures never regularize")
    func numericalFailuresAreTyped() async throws {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let extreme = try ScalarSurfaceTestSupport.fixture(
            scalarType: .float64,
            values: [
                -Double.greatestFiniteMagnitude,
                Double.greatestFiniteMagnitude,
                Double.greatestFiniteMagnitude,
                Double.greatestFiniteMagnitude,
                Double.greatestFiniteMagnitude,
                Double.greatestFiniteMagnitude,
                Double.greatestFiniteMagnitude,
                Double.greatestFiniteMagnitude,
            ]
        )
        await #expect(
            throws: ScalarSurfaceExtractionError
                .interpolationNotRepresentable
        ) {
            try await extract(
                fixture: extreme,
                isovalue: 0,
                coordinator: coordinator
            )
        }

        let maximum = Double.greatestFiniteMagnitude
        let overflowingPosition = try ScalarSurfaceTestSupport.fixture(
            matrixElements: [
                maximum, 0, 0, maximum,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]
        )
        await #expect(
            throws: ScalarSurfaceExtractionError.positionNotRepresentable
        ) {
            try await extract(
                fixture: overflowingPosition,
                coordinator: coordinator
            )
        }
    }

    @Test("[Kernel][VOX-SEC-001][VOX-ERR-001] vertex and triangle ceilings fail atomically")
    func resourceLimitsFailBeforeMutation() async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture()
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        for request in [
            ScalarSurfaceTestSupport.request(
                fixture: fixture,
                maximumVertexCount: 6
            ),
            ScalarSurfaceTestSupport.request(
                fixture: fixture,
                maximumTriangleCount: 5
            ),
        ] {
            await #expect(
                throws: ScalarSurfaceExtractionError.resourceLimitExceeded
            ) {
                try await CPUScalarSurfaceExtractionOperation.extractMesh(
                    request: request,
                    coordinator: coordinator
                )
            }
        }
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    private func extract(
        fixture: ScalarSurfaceFixture,
        isovalue: Double = 0.5,
        coordinator: StorageReadCoordinator
    ) async throws -> TriangleMesh {
        try await CPUScalarSurfaceExtractionOperation.extractMesh(
            request: ScalarSurfaceTestSupport.request(
                fixture: fixture,
                isovalue: isovalue
            ),
            coordinator: coordinator
        )
    }

    private func oracleRecord(mask: Int, mesh: TriangleMesh) throws -> String {
        let vertices = try positionTriples(mesh).map { position in
            let components = try position.map(oracleFraction)
            return "[\"\(components[0])\",\"\(components[1])\",\"\(components[2])\"]"
        }.joined(separator: ",")
        var triangles = [String]()
        for offset in stride(
            from: 0,
            to: mesh.topology.indices.count,
            by: 3
        ) {
            triangles.append(
                "[\(mesh.topology.indices[offset]),\(mesh.topology.indices[offset + 1]),\(mesh.topology.indices[offset + 2])]"
            )
        }
        return
            "{\"mask\":\(mask),\"triangles\":[\(triangles.joined(separator: ","))],\"vertices\":[\(vertices)]}"
    }

    private func binary64Record(mask: Int?, mesh: TriangleMesh) -> String {
        let vertices = positionTriples(mesh).map { position in
            let components = position.map { component in
                "\"\(hexadecimal(component.bitPattern, width: 16))\""
            }
            return "[\(components.joined(separator: ","))]"
        }.joined(separator: ",")
        var triangles = [String]()
        for offset in stride(
            from: 0,
            to: mesh.topology.indices.count,
            by: 3
        ) {
            triangles.append(
                "[\(mesh.topology.indices[offset]),\(mesh.topology.indices[offset + 1]),\(mesh.topology.indices[offset + 2])]"
            )
        }
        let maskField = mask.map { "\"mask\":\($0)," } ?? ""
        return
            "{\(maskField)\"triangles\":[\(triangles.joined(separator: ","))],\"vertexBits\":[\(vertices)]}"
    }

    private func sha256(_ text: String) -> String {
        SHA256.hash(data: Array(text.utf8)).map { byte in
            hexadecimal(UInt64(byte), width: 2)
        }.joined()
    }

    private func hexadecimal(_ value: UInt64, width: Int) -> String {
        let text = String(value, radix: 16)
        return String(repeating: "0", count: width - text.count) + text
    }

    private func oracleFraction(_ value: Double) throws -> String {
        switch value {
        case 0: "0/1"
        case 0.5: "1/2"
        case 1: "1/1"
        default: throw FixtureError.unexpectedOracleCoordinate
        }
    }

    private func positionTriples(_ mesh: TriangleMesh) -> [[Double]] {
        stride(from: 0, to: mesh.positions.components.count, by: 3).map {
            [
                mesh.positions.components[$0],
                mesh.positions.components[$0 + 1],
                mesh.positions.components[$0 + 2],
            ]
        }
    }

    private func positionKey(_ position: [Double]) -> String {
        position.map { String($0.bitPattern, radix: 16) }.joined(separator: ":")
    }

    private func reversedWinding(
        _ indices: ContiguousArray<UInt64>
    ) -> ContiguousArray<UInt64> {
        var reversed = ContiguousArray<UInt64>()
        for offset in stride(from: 0, to: indices.count, by: 3) {
            reversed.append(indices[offset])
            reversed.append(indices[offset + 2])
            reversed.append(indices[offset + 1])
        }
        return reversed
    }

    private enum FixtureError: Error {
        case unexpectedOracleCoordinate
    }
}
