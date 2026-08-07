// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaCore
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU triangle-mesh vertex-normal reference kernel")
struct TriangleMeshVertexNormalReferenceKernelTests {
    private struct Fixture: Sendable {
        let name: String
        let positions: ContiguousArray<Double>
        let indices: ContiguousArray<UInt64>
    }

    @Test(
        "[Oracle][VOX-GEO-009][VOX-NUM-001] all ALG-0030 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var aggregateBytes = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let result = try generate(mesh: mesh(for: fixture))
                let bytes = try #require(result.vertexAttributes.last?.bytes)
                records.append(
                    "\(fixture.name)|bits=\(bitTokens(in: bytes).joined(separator: ","))"
                )
                aggregateBytes.append(contentsOf: bytes)
            } catch let error as TriangleMeshVertexNormalGenerationError {
                records.append("\(fixture.name)|error=\(errorName(error))")
            }
        }

        #expect(records.count == 12)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "1306df51656d104cfacc9cafc5f2fd7910bbe0104e10a435326310d94d6c94fc"
        )
        #expect(
            sha256(aggregateBytes)
                == "076b11f527589e716986a14a99ff86590b592b95f948ca6b6309627baff96d17"
        )
    }

    @Test(
        "[Kernel][VOX-GEO-009][VOX-NUM-001] output is deterministic, source-preserving, and exactly described"
    )
    func outputIsDeterministicAndSourcePreserving() throws {
        let sourceAttribute = try attribute(
            semantic: .custom(
                namespace: "org.voxelia.normal.test",
                name: "normal-source"
            )
        )
        let source = try mesh(
            positions: [-0.0, 0, 0, 2, 0, 0, 0, 3, 0],
            indices: [0, 1, 2],
            attributes: [sourceAttribute]
        )
        let first = try generate(mesh: source)
        let second = try generate(mesh: source)

        #expect(first.positions.components == source.positions.components)
        #expect(
            first.positions.components.map(\.bitPattern)
                == source.positions.components.map(\.bitPattern)
        )
        #expect(first.positions.coordinateSpace == source.positions.coordinateSpace)
        #expect(first.topology == source.topology)
        #expect(first.vertexAttributes.count == 2)
        #expect(
            first.vertexAttributes[0].descriptor == sourceAttribute.descriptor
        )
        #expect(first.vertexAttributes[0].bytes == sourceAttribute.bytes)
        #expect(
            first.vertexAttributes[1].bytes == second.vertexAttributes[1].bytes
        )

        let normal = first.vertexAttributes[1]
        #expect(normal.descriptor.semantic == .normal)
        #expect(normal.descriptor.scalarFormat.type == .float64)
        #expect(normal.descriptor.scalarFormat.validBitCount == nil)
        #expect(normal.descriptor.scalarFormat.byteOrder == .littleEndian)
        #expect(normal.descriptor.components.count == 3)
        #expect(normal.descriptor.components.interpretation == .vector)
        #expect(normal.descriptor.components.layout == .interleaved)
        #expect(normal.descriptor.components.componentNames == nil)
        #expect(normal.descriptor.elementCount == 3)
        #expect(
            bitPatterns(in: normal.bytes)
                == [
                    0, 0, 0x3ff0_0000_0000_0000,
                    0, 0, 0x3ff0_0000_0000_0000,
                    0, 0, 0x3ff0_0000_0000_0000,
                ]
        )
    }

    @Test(
        "[Kernel][VOX-GEO-009][VOX-NUM-001] topology order remains numerically observable"
    )
    func topologyOrderRemainsObservable() throws {
        let large = 0x1.1c37937e08000p+53
        let positions: ContiguousArray<Double> = [
            0, 0, 0,
            1, 0, 0,
            0, large, 0,
            1, 0, 0,
            0, -large, 0,
            1, 0, 0,
            0, 1, 0,
            1, 0, 0,
            0, 0, -1,
        ]
        let frozen = try generate(
            mesh: try mesh(
                positions: positions,
                indices: [0, 1, 2, 0, 3, 4, 0, 5, 6, 0, 7, 8]
            )
        )
        let reordered = try generate(
            mesh: try mesh(
                positions: positions,
                indices: [0, 1, 2, 0, 5, 6, 0, 3, 4, 0, 7, 8]
            )
        )
        let frozenBits = bitPatterns(
            in: try #require(frozen.vertexAttributes.last).bytes
        )
        let reorderedBits = bitPatterns(
            in: try #require(reordered.vertexAttributes.last).bytes
        )
        #expect(
            Array(frozenBits.prefix(3))
                == [0, 0x3fe6_a09e_667f_3bcc, 0x3fe6_a09e_667f_3bcc]
        )
        #expect(
            Array(reorderedBits.prefix(3))
                == [0, 0x3ff0_0000_0000_0000, 0]
        )
    }

    @Test(
        "[Kernel][VOX-SEC-001][VOX-ERR-001] admission limits and failure precedence are fail-closed"
    )
    func admissionAndFailurePrecedenceAreFailClosed() throws {
        let simple = try mesh(
            positions: [0, 0, 0, 1, 0, 0, 0, 1, 0],
            indices: [0, 1, 2]
        )
        let ordinary = limits()
        let zeroLimits = [
            limits(maximumVertexCount: 0),
            limits(maximumTriangleCount: 0),
            limits(maximumExistingVertexAttributeCount: 0),
            limits(maximumAdditionalLogicalByteCount: 0),
        ]
        for invalid in zeroLimits {
            #expect(throws: TriangleMeshVertexNormalGenerationError.invalidLimits) {
                try generate(mesh: simple, limits: invalid)
            }
        }
        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try generate(
                mesh: simple,
                limits: zeroLimits[0],
                cancellation: { $0 == .admission }
            )
        }

        let normalBearing = try mesh(
            positions: simple.positions.components,
            indices: simple.topology.indices,
            attributes: [
                try attribute(semantic: .normal, elementCount: 3, byteCount: 3)
            ]
        )
        let identity = try sourceIdentity(objectID: "normal-admission-source")
        let mismatchedProvenance = try sourceProvenance(
            subjectObjectID: try #require(DataObjectID(rawValue: "other-source"))
        )
        #expect(throws: TriangleMeshVertexNormalGenerationError.invalidSource) {
            try generate(
                mesh: normalBearing,
                limits: ordinary,
                identity: identity,
                provenance: mismatchedProvenance
            )
        }
        #expect(throws: TriangleMeshVertexNormalGenerationError.resourceLimitExceeded) {
            try generate(
                mesh: normalBearing,
                limits: limits(maximumVertexCount: 2)
            )
        }
        #expect(throws: TriangleMeshVertexNormalGenerationError.normalAlreadyPresent) {
            try generate(
                mesh: normalBearing,
                limits: limits(maximumAdditionalLogicalByteCount: 1)
            )
        }
        let twoTriangles = try mesh(
            positions: simple.positions.components,
            indices: [0, 1, 2, 0, 1, 2]
        )
        #expect(throws: TriangleMeshVertexNormalGenerationError.resourceLimitExceeded) {
            try generate(
                mesh: twoTriangles,
                limits: limits(maximumTriangleCount: 1)
            )
        }
        #expect(throws: TriangleMeshVertexNormalGenerationError.resourceLimitExceeded) {
            try generate(
                mesh: simple,
                limits: limits(maximumAdditionalLogicalByteCount: 143)
            )
        }

        let twoAttributes = try mesh(
            positions: simple.positions.components,
            indices: simple.topology.indices,
            attributes: [
                try attribute(semantic: .confidence),
                try attribute(semantic: .scalarValue),
            ]
        )
        #expect(throws: TriangleMeshVertexNormalGenerationError.resourceLimitExceeded) {
            try generate(
                mesh: twoAttributes,
                limits: limits(maximumExistingVertexAttributeCount: 1)
            )
        }
    }

    @Test(
        "[Kernel][VOX-SEC-001] fixed logical-byte accounting accepts the registered maximum only"
    )
    func logicalByteBoundaryIsCheckedWithoutAllocation() throws {
        let maximumVertexCount = UInt64.max / 48
        let accepted =
            try TriangleMeshVertexNormalReferenceKernel
            .checkedLogicalByteCounts(
                vertexCount: maximumVertexCount,
                maximumAdditionalLogicalByteCount: UInt64.max
            )
        #expect(accepted.componentCount == maximumVertexCount * 3)
        #expect(accepted.oneBufferByteCount == maximumVertexCount * 24)
        #expect(accepted.additionalLogicalByteCount == maximumVertexCount * 48)
        #expect(accepted.oneBufferByteCount <= UInt64(Int.max))

        #expect(
            throws: TriangleMeshVertexNormalGenerationError
                .resourceLimitExceeded
        ) {
            try TriangleMeshVertexNormalReferenceKernel
                .checkedLogicalByteCounts(
                    vertexCount: maximumVertexCount + 1,
                    maximumAdditionalLogicalByteCount: UInt64.max
                )
        }
        #expect(
            throws: TriangleMeshVertexNormalGenerationError
                .resourceLimitExceeded
        ) {
            try TriangleMeshVertexNormalReferenceKernel
                .checkedLogicalByteCounts(
                    vertexCount: 3,
                    maximumAdditionalLogicalByteCount: 143
                )
        }
    }

    @Test(
        "[Kernel][VOX-GEO-009] empty mesh succeeds and appends an exact empty normal stream"
    )
    func emptyMeshSucceeds() throws {
        let result = try generate(mesh: try mesh(positions: [], indices: []))
        let normal = try #require(result.vertexAttributes.last)
        #expect(result.positions.vertexCount == 0)
        #expect(result.topology.triangleCount == 0)
        #expect(normal.descriptor.semantic == .normal)
        #expect(normal.descriptor.elementCount == 0)
        #expect(normal.bytes.isEmpty)
    }

    @Test(
        "[Kernel][VOX-CON-001][VOX-ERR-001] every frozen cancellation cadence wins at its checkpoint"
    )
    func frozenCancellationCadenceWins() throws {
        let normalBearing = try mesh(
            positions: [0, 0, 0, 1, 0, 0, 0, 1, 0],
            indices: [0, 1, 2],
            attributes: [
                try attribute(semantic: .normal, elementCount: 3, byteCount: 3)
            ]
        )
        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try generate(
                mesh: normalBearing,
                cancellation: { $0 == .attribute(0) }
            )
        }

        let overflowingDifference = try mesh(
            positions: [
                Double.greatestFiniteMagnitude, 0, 0,
                -Double.greatestFiniteMagnitude, 0, 0,
                0, 1, 0,
            ],
            indices: [0, 1, 2]
        )
        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try generate(
                mesh: overflowingDifference,
                cancellation: { $0 == .triangle(0) }
            )
        }

        let undefinedAtFirstVertex = try mesh(
            positions: [0, 0, 0, 1, 0, 0, 0, 1, 0],
            indices: [0, 1, 2, 0, 2, 1]
        )
        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try generate(
                mesh: undefinedAtFirstVertex,
                cancellation: { $0 == .vertex(0) }
            )
        }

        let sixtyFiveTriangles = try mesh(
            positions: [0, 0, 0, 1, 0, 0, 0, 1, 0],
            indices: ContiguousArray(
                (0..<65).flatMap { _ in [UInt64(0), 1, 2] }
            )
        )
        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try generate(
                mesh: sixtyFiveTriangles,
                cancellation: { $0 == .triangle(64) }
            )
        }

        let attributeBoundary = try meshWithNormalAtAttribute4096()
        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try generate(
                mesh: attributeBoundary,
                limits: limits(
                    maximumExistingVertexAttributeCount: 4_097
                ),
                cancellation: { $0 == .attribute(4_096) }
            )
        }

        let vertexBoundary = try meshWithIsolatedVertexAt4096()
        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try generate(
                mesh: vertexBoundary,
                limits: limits(
                    maximumVertexCount: 5_000,
                    maximumTriangleCount: 2_000,
                    maximumAdditionalLogicalByteCount: 300_000
                ),
                cancellation: { $0 == .vertex(4_096) }
            )
        }

        let simple = try mesh(
            positions: [0, 0, 0, 1, 0, 0, 0, 1, 0],
            indices: [0, 1, 2]
        )
        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try generate(mesh: simple, cancellation: { $0 == .final })
        }
    }

    @Test(
        "[Kernel][VOX-CON-001] non-cadence ordinals are not probed and optional final check is exact"
    )
    func nonCadenceOrdinalsAreNotProbed() throws {
        let source = try mesh(
            positions: [0, 0, 0, 1, 0, 0, 0, 1, 0],
            indices: [0, 1, 2],
            attributes: [try attribute(semantic: .confidence)]
        )
        _ = try generate(
            mesh: source,
            cancellation: {
                $0 == .attribute(1) || $0 == .triangle(1)
                    || $0 == .vertex(1)
            }
        )
        let request = try request(mesh: source)
        _ = try TriangleMeshVertexNormalReferenceKernel.generate(
            request: request,
            cancellation: { $0 == .final },
            checksFinalCancellation: false
        )
    }

    private func analyticalFixtures() -> [Fixture] {
        let simplePositions: ContiguousArray<Double> = [
            0, 0, 0,
            2, 0, 0,
            0, 3, 0,
        ]
        let simpleIndices: ContiguousArray<UInt64> = [0, 1, 2]
        let weightedPositions: ContiguousArray<Double> = [
            0, 0, 0,
            1, 0, 0,
            0, 1, 0,
            0, 0, 2,
        ]
        let large = 0x1.1c37937e08000p+53
        let topologyPositions: ContiguousArray<Double> = [
            0, 0, 0,
            1, 0, 0,
            0, large, 0,
            1, 0, 0,
            0, -large, 0,
            1, 0, 0,
            0, 1, 0,
            1, 0, 0,
            0, 0, -1,
        ]
        let contraction = 0x1.0000002000000p+0
        let accumulationEdge = (8.0e307).squareRoot()
        return [
            Fixture(
                name: "simple",
                positions: simplePositions,
                indices: simpleIndices
            ),
            Fixture(
                name: "weighted",
                positions: weightedPositions,
                indices: [0, 1, 2, 0, 3, 1]
            ),
            Fixture(
                name: "topology-order-sensitive",
                positions: topologyPositions,
                indices: [0, 1, 2, 0, 3, 4, 0, 5, 6, 0, 7, 8]
            ),
            Fixture(
                name: "contraction-sensitive",
                positions: [
                    0, 0, 0,
                    contraction, 1, 0,
                    1, contraction, 1,
                ],
                indices: simpleIndices
            ),
            Fixture(
                name: "reverse",
                positions: simplePositions,
                indices: [0, 2, 1]
            ),
            Fixture(
                name: "degenerate-plus-valid",
                positions: simplePositions,
                indices: [0, 0, 1, 0, 1, 2]
            ),
            Fixture(
                name: "subnormal",
                positions: [
                    0, 0, 0,
                    Double.leastNonzeroMagnitude, 0, 0,
                    0, 1, 0,
                ],
                indices: simpleIndices
            ),
            Fixture(
                name: "positive-zero",
                positions: [0, 0, 0, 0, 2, 0, 0, 0, 3],
                indices: simpleIndices
            ),
            Fixture(
                name: "opposite-cancellation",
                positions: simplePositions,
                indices: [0, 1, 2, 0, 2, 1]
            ),
            Fixture(
                name: "isolated",
                positions: simplePositions + [4, 4, 4],
                indices: simpleIndices
            ),
            Fixture(
                name: "difference-overflow",
                positions: [
                    Double.greatestFiniteMagnitude, 0, 0,
                    -Double.greatestFiniteMagnitude, 0, 0,
                    0, 1, 0,
                ],
                indices: simpleIndices
            ),
            Fixture(
                name: "accumulation-overflow",
                positions: [
                    0, 0, 0,
                    accumulationEdge, 0, 0,
                    0, accumulationEdge, 0,
                ],
                indices: [0, 1, 2, 0, 1, 2, 0, 1, 2]
            ),
        ]
    }

    private func mesh(for fixture: Fixture) throws -> TriangleMesh {
        try mesh(positions: fixture.positions, indices: fixture.indices)
    }

    private func mesh(
        positions: ContiguousArray<Double>,
        indices: ContiguousArray<UInt64>,
        attributes: ContiguousArray<TriangleMeshVertexAttribute> = []
    ) throws -> TriangleMesh {
        let domain = try TriangleMeshPositionDomain(
            coordinateSpace: coordinateSpace(),
            components: positions
        )
        return try TriangleMesh(
            positions: domain,
            topology: try TriangleMeshTopology(
                vertexCount: domain.vertexCount,
                indices: indices
            ),
            vertexAttributes: attributes
        )
    }

    private func meshWithNormalAtAttribute4096() throws -> TriangleMesh {
        var attributes = ContiguousArray<TriangleMeshVertexAttribute>()
        attributes.reserveCapacity(4_097)
        for ordinal in 0..<4_096 {
            attributes.append(
                try attribute(
                    semantic: .custom(
                        namespace: "org.voxelia.cancellation",
                        name: String(ordinal)
                    ),
                    elementCount: 0,
                    byteCount: 0
                )
            )
        }
        attributes.append(
            try attribute(
                semantic: .normal,
                elementCount: 0,
                byteCount: 0
            )
        )
        return try mesh(positions: [], indices: [], attributes: attributes)
    }

    private func meshWithIsolatedVertexAt4096() throws -> TriangleMesh {
        var positions = ContiguousArray<Double>()
        var indices = ContiguousArray<UInt64>()
        positions.reserveCapacity(4_099 * 3)
        indices.reserveCapacity(1_366 * 3)
        for triangle in 0..<1_365 {
            positions.append(contentsOf: [0, 0, 0, 1, 0, 0, 0, 1, 0])
            let base = UInt64(triangle * 3)
            indices.append(contentsOf: [base, base + 1, base + 2])
        }
        positions.append(contentsOf: [0, 0, 0])
        positions.append(contentsOf: [9, 9, 9])
        positions.append(contentsOf: [1, 0, 0, 0, 1, 0])
        indices.append(contentsOf: [4_095, 4_097, 4_098])
        return try mesh(positions: positions, indices: indices)
    }

    private func attribute(
        semantic: GeometryAttributeSemantic,
        elementCount: Int = 3,
        byteCount: Int? = nil
    ) throws -> TriangleMeshVertexAttribute {
        try TriangleMeshVertexAttribute(
            descriptor: try GeometryAttributeDescriptor(
                semantic: semantic,
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                elementCount: elementCount
            ),
            bytes: ContiguousArray(
                repeating: 7,
                count: byteCount ?? elementCount
            )
        )
    }

    private func generate(
        mesh: TriangleMesh,
        limits: TriangleMeshVertexNormalGenerationLimits? = nil,
        identity: DataIdentity? = nil,
        provenance: ProvenanceRecord? = nil,
        cancellation: CPUTriangleMeshVertexNormalCancellationProbe = { _ in
            false
        }
    ) throws -> TriangleMesh {
        try TriangleMeshVertexNormalReferenceKernel.generate(
            request: try request(
                mesh: mesh,
                limits: limits,
                identity: identity,
                provenance: provenance
            ),
            cancellation: cancellation
        )
    }

    private func request(
        mesh: TriangleMesh,
        limits: TriangleMeshVertexNormalGenerationLimits? = nil,
        identity: DataIdentity? = nil,
        provenance: ProvenanceRecord? = nil
    ) throws -> TriangleMeshVertexNormalGenerationRequest {
        let sourceIdentity = try identity ?? self.sourceIdentity()
        return TriangleMeshVertexNormalGenerationRequest(
            source: mesh,
            sourceIdentity: sourceIdentity,
            sourceProvenance: try provenance
                ?? sourceProvenance(subjectObjectID: sourceIdentity.objectID),
            limits: limits ?? self.limits()
        )
    }

    private func limits(
        maximumVertexCount: UInt64 = 10_000,
        maximumTriangleCount: UInt64 = 10_000,
        maximumExistingVertexAttributeCount: UInt64 = 10_000,
        maximumAdditionalLogicalByteCount: UInt64 = 1_000_000
    ) -> TriangleMeshVertexNormalGenerationLimits {
        TriangleMeshVertexNormalGenerationLimits(
            maximumVertexCount: maximumVertexCount,
            maximumTriangleCount: maximumTriangleCount,
            maximumExistingVertexAttributeCount:
                maximumExistingVertexAttributeCount,
            maximumAdditionalLogicalByteCount:
                maximumAdditionalLogicalByteCount
        )
    }

    private func sourceIdentity(
        objectID: String = "normal-kernel-source"
    ) throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(DataObjectID(rawValue: objectID)),
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: [1]
            ),
            sourceIdentities: [],
            derivation: nil
        )
    }

    private func sourceProvenance(
        subjectObjectID: DataObjectID
    ) throws -> ProvenanceRecord {
        try ProvenanceRecord(
            id: try #require(
                ProvenanceID(rawValue: "normal-kernel-source-record")
            ),
            kind: .source,
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T18:00:00Z"
            ),
            subject: .object(subjectObjectID),
            software: try SoftwareIdentity(
                name: "Voxelia Normal Kernel Test Source",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: nil,
                buildIdentifier: nil
            ),
            activity: .origin,
            inputs: [],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    private func coordinateSpace() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "normal-kernel-space")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
    }

    private func bitPatterns(
        in bytes: ContiguousArray<UInt8>
    ) -> [UInt64] {
        stride(from: 0, to: bytes.count, by: 8).map { offset in
            var value: UInt64 = 0
            for byteIndex in 0..<8 {
                value |=
                    UInt64(bytes[offset + byteIndex])
                    << UInt64(byteIndex * 8)
            }
            return value
        }
    }

    private func bitTokens(in bytes: ContiguousArray<UInt8>) -> [String] {
        bitPatterns(in: bytes).map { hexadecimal($0, width: 16) }
    }

    private func errorName(
        _ error: TriangleMeshVertexNormalGenerationError
    ) -> String {
        switch error {
        case .invalidLimits: "invalidLimits"
        case .invalidSource: "invalidSource"
        case .normalAlreadyPresent: "normalAlreadyPresent"
        case .resourceLimitExceeded: "resourceLimitExceeded"
        case .normalNotRepresentable: "normalNotRepresentable"
        case .undefinedNormal: "undefinedNormal"
        case .cancelled: "cancelled"
        case .publicationFailed: "publicationFailed"
        }
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: bytes).map {
            hexadecimal(UInt64($0), width: 2)
        }.joined()
    }

    private func hexadecimal(_ value: UInt64, width: Int) -> String {
        let text = String(value, radix: 16)
        return String(repeating: "0", count: width - text.count) + text
    }
}
