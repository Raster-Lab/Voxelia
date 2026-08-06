// SPDX-License-Identifier: MIT

import CryptoKit
import Synchronization
import Testing
import VoxeliaCore
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU triangle-mesh total-facet-area reference kernel")
struct TriangleMeshTotalFacetAreaReferenceKernelTests {
    private struct Fixture: Sendable {
        let name: String
        let positions: ContiguousArray<Double>
        let indices: ContiguousArray<UInt64>
    }

    private final class CheckpointLog: Sendable {
        private let recorded = Mutex(
            [CPUTriangleMeshTotalFacetAreaCancellationCheckpoint]()
        )

        func record(
            _ checkpoint: CPUTriangleMeshTotalFacetAreaCancellationCheckpoint
        ) {
            recorded.withLock { $0.append(checkpoint) }
        }

        var checkpoints: [CPUTriangleMeshTotalFacetAreaCancellationCheckpoint] {
            recorded.withLock { $0 }
        }
    }

    @Test(
        "[Oracle][VOX-GEO-010][VOX-NUM-001] all ALG-0031 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var aggregateBytes = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let result = try measure(mesh: mesh(for: fixture))
                records.append(
                    "\(fixture.name)|facets=\(result.facetCount)"
                        + "|bits=\(hexadecimal(result.total.bitPattern, width: 16))"
                )
                aggregateBytes.append(
                    contentsOf: littleEndianBytes(result.total.bitPattern)
                )
            } catch let error as TriangleMeshTotalFacetAreaError {
                records.append("\(fixture.name)|error=\(errorName(error))")
            }
        }

        #expect(records.count == 13)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "38bad8cfd458b0dca99df2522e34124d51fe607f7fa428fa9f7a586c661d6feb"
        )
        #expect(
            sha256(aggregateBytes)
                == "8a8af5729b9008d759b9886eb757b31a85cf6dab22d07696b06062f3df668605"
        )
    }

    @Test(
        "[Unit][VOX-GEO-010][VOX-NUM-001] the quantity is unsigned, multiplicity-retaining and deterministic"
    )
    func quantityIsUnsignedMultiplicityRetainingAndDeterministic() throws {
        let rightTriangle = try mesh(
            positions: rightTrianglePositions,
            indices: [0, 1, 2]
        )
        let first = try measure(mesh: rightTriangle)
        let second = try measure(mesh: rightTriangle)
        #expect(first.total == 3)
        #expect(first.total.bitPattern == second.total.bitPattern)
        #expect(first.facetCount == 1)

        // Winding cannot move an unsigned magnitude.
        let reversed = try measure(
            mesh: try mesh(
                positions: rightTrianglePositions,
                indices: [0, 2, 1]
            )
        )
        #expect(reversed.total.bitPattern == first.total.bitPattern)

        // Repeated facets keep their multiplicity; nothing is deduplicated.
        let tripled = try measure(
            mesh: try mesh(
                positions: rightTrianglePositions,
                indices: [0, 1, 2, 0, 1, 2, 0, 1, 2]
            )
        )
        #expect(tripled.total == 9)
        #expect(tripled.facetCount == 3)

        // A degenerate facet contributes positive zero and stays counted.
        let withDegenerate = try measure(
            mesh: try mesh(
                positions: rightTrianglePositions,
                indices: [0, 0, 1, 0, 1, 2]
            )
        )
        #expect(withDegenerate.total == 3)
        #expect(withDegenerate.facetCount == 2)

        // Empty and wholly degenerate meshes total positive, never negative,
        // zero. Neither is a failure.
        let empty = try measure(mesh: try mesh(positions: [], indices: []))
        #expect(empty.total.bitPattern == (0.0).bitPattern)
        #expect(empty.facetCount == 0)
        let allDegenerate = try measure(
            mesh: try mesh(
                positions: rightTrianglePositions,
                indices: [0, 0, 1, 2, 2, 2]
            )
        )
        #expect(allDegenerate.total.bitPattern == (0.0).bitPattern)
        #expect(allDegenerate.facetCount == 2)

        // A facet whose doubled area is the least subnormal halves to
        // positive zero; the model publishes that zero rather than inferring
        // geometric nondegeneracy outside its own arithmetic.
        let subnormal = try measure(
            mesh: try mesh(
                positions: [
                    0, 0, 0,
                    Double.leastNonzeroMagnitude, 0, 0,
                    0, 1, 0,
                ],
                indices: [0, 1, 2]
            )
        )
        #expect(subnormal.total.bitPattern == (0.0).bitPattern)
        #expect(subnormal.facetCount == 1)

        // Serial topology order is part of the algorithm identity.
        let ordered = try measure(
            mesh: try mesh(
                positions: orderSensitivePositions,
                indices: [0, 1, 2, 0, 3, 2, 0, 3, 2]
            )
        )
        let reordered = try measure(
            mesh: try mesh(
                positions: orderSensitivePositions,
                indices: [0, 3, 2, 0, 3, 2, 0, 1, 2]
            )
        )
        #expect(ordered.total.bitPattern == 0x4340_0000_0000_0000)
        #expect(reordered.total.bitPattern == 0x4340_0000_0000_0001)
        #expect(ordered.total != reordered.total)
    }

    @Test(
        "[Unit][VOX-ERR-001][VOX-SEC-001] admission precedence is exact"
    )
    func admissionPrecedenceIsExact() throws {
        let simple = try mesh(
            positions: rightTrianglePositions,
            indices: [0, 1, 2]
        )
        let identity = try sourceIdentity(objectID: "area-admission-source")
        let mismatched = try sourceProvenance(
            subjectObjectID: try #require(DataObjectID(rawValue: "unmatched"))
        )

        // Cancellation precedes zero ceilings.
        #expect(throws: TriangleMeshTotalFacetAreaError.cancelled) {
            try measure(
                mesh: simple,
                limits: limits(maximumVertexCount: 0, maximumTriangleCount: 0),
                cancellation: { $0 == .admission }
            )
        }

        // Zero ceilings precede a mismatched source claim.
        for zeroed in [
            limits(maximumVertexCount: 0),
            limits(maximumTriangleCount: 0),
            limits(maximumVertexCount: 0, maximumTriangleCount: 0),
        ] {
            #expect(throws: TriangleMeshTotalFacetAreaError.invalidLimits) {
                try measure(
                    mesh: simple,
                    limits: zeroed,
                    identity: identity,
                    provenance: mismatched
                )
            }
        }

        // A mismatched source claim precedes the count ceilings.
        #expect(throws: TriangleMeshTotalFacetAreaError.invalidSource) {
            try measure(
                mesh: simple,
                limits: limits(
                    maximumVertexCount: 1,
                    maximumTriangleCount: 1
                ),
                identity: identity,
                provenance: mismatched
            )
        }

        // Each count ceiling is inclusive and rejects one past itself.
        #expect(throws: TriangleMeshTotalFacetAreaError.resourceLimitExceeded) {
            try measure(
                mesh: simple,
                limits: limits(maximumVertexCount: 2)
            )
        }
        #expect(throws: TriangleMeshTotalFacetAreaError.resourceLimitExceeded) {
            try measure(
                mesh: try mesh(
                    positions: rightTrianglePositions,
                    indices: [0, 1, 2, 0, 1, 2]
                ),
                limits: limits(maximumTriangleCount: 1)
            )
        }
        #expect(
            try measure(
                mesh: simple,
                limits: limits(
                    maximumVertexCount: 3,
                    maximumTriangleCount: 1
                )
            ).total == 3
        )

        // The counts helper is the sole admission arithmetic: there is no
        // payload product to overflow, only the two ceiling comparisons.
        let counts =
            try TriangleMeshTotalFacetAreaReferenceKernel
            .checkedSourceCounts(
                vertexCount: 3,
                triangleCount: 1,
                limits: limits()
            )
        #expect(counts.vertexCount == 3)
        #expect(counts.triangleCount == 1)
        #expect(throws: TriangleMeshTotalFacetAreaError.resourceLimitExceeded) {
            _ =
                try TriangleMeshTotalFacetAreaReferenceKernel
                .checkedSourceCounts(
                    vertexCount: 3,
                    triangleCount: 1,
                    limits: TriangleMeshTotalFacetAreaLimits(
                        maximumVertexCount: 2,
                        maximumTriangleCount: 1
                    )
                )
        }
    }

    @Test(
        "[Unit][VOX-NUM-001][VOX-ERR-001] every non-finite ordered intermediate fails closed"
    )
    func everyNonFiniteOrderedIntermediateFailsClosed() throws {
        // Edge subtraction overflow fails before any geometric conclusion.
        #expect(
            throws: TriangleMeshTotalFacetAreaError.areaNotRepresentable
        ) {
            try measure(
                mesh: try mesh(
                    positions: edgeOverflowPositions,
                    indices: [0, 1, 2]
                )
            )
        }

        // A finite doubled-area vector whose scaled magnitude overflows fails
        // rather than being rescaled by an alternative formulation.
        #expect(
            throws: TriangleMeshTotalFacetAreaError.areaNotRepresentable
        ) {
            try measure(
                mesh: try mesh(
                    positions: magnitudeOverflowPositions,
                    indices: [0, 1, 2]
                )
            )
        }

        // One such facet on its own is finite; three of them overflow the
        // serial accumulation.
        let accumulating = try mesh(
            positions: accumulationOverflowPositions,
            indices: [0, 1, 2]
        )
        #expect(try measure(mesh: accumulating).total.isFinite)
        #expect(
            throws: TriangleMeshTotalFacetAreaError.areaNotRepresentable
        ) {
            try measure(
                mesh: try mesh(
                    positions: accumulationOverflowPositions,
                    indices: [0, 1, 2, 0, 1, 2, 0, 1, 2]
                )
            )
        }
    }

    @Test(
        "[Unit][VOX-CON-006][VOX-CON-007] cancellation polls exactly the frozen ordinals"
    )
    func cancellationPollsExactlyTheFrozenOrdinals() throws {
        let manyFacets = try repeatedFacetMesh(facetCount: 200)
        let log = CheckpointLog()
        let result = try measure(
            mesh: manyFacets,
            cancellation: { checkpoint in
                log.record(checkpoint)
                return false
            }
        )
        #expect(result.facetCount == 200)
        #expect(
            log.checkpoints == [
                .admission,
                .triangle(0),
                .triangle(64),
                .triangle(128),
                .triangle(192),
                .final,
            ]
        )

        for ordinal in [UInt64(0), 64, 128, 192] {
            #expect(throws: TriangleMeshTotalFacetAreaError.cancelled) {
                try measure(
                    mesh: manyFacets,
                    cancellation: { $0 == .triangle(ordinal) }
                )
            }
        }
        // A non-poll ordinal is never observed, so it cannot cancel.
        #expect(
            try measure(
                mesh: manyFacets,
                cancellation: { $0 == .triangle(1) }
            ).facetCount == 200
        )

        // Cancellation at a poll precedes the facet at that ordinal: the
        // overflowing facet sits at ordinal 64 and never evaluates.
        let overflowAt64 = try repeatedFacetMesh(
            facetCount: 200,
            overflowingFacetOrdinal: 64
        )
        #expect(
            throws: TriangleMeshTotalFacetAreaError.areaNotRepresentable
        ) {
            try measure(mesh: overflowAt64)
        }
        #expect(throws: TriangleMeshTotalFacetAreaError.cancelled) {
            try measure(
                mesh: overflowAt64,
                cancellation: { $0 == .triangle(64) }
            )
        }

        // The final checkpoint runs after the complete total exists, and is
        // suppressed for the public operation which owns its own final check.
        #expect(throws: TriangleMeshTotalFacetAreaError.cancelled) {
            try measure(
                mesh: manyFacets,
                cancellation: { $0 == .final }
            )
        }
        #expect(
            try TriangleMeshTotalFacetAreaReferenceKernel.measure(
                request: try request(mesh: manyFacets),
                cancellation: { $0 == .final },
                checksFinalCancellation: false
            ).facetCount == 200
        )
    }

    // MARK: - Fixtures

    private let rightTrianglePositions: ContiguousArray<Double> = [
        0, 0, 0,
        2, 0, 0,
        0, 3, 0,
    ]

    private let orderSensitivePositions: ContiguousArray<Double> = [
        0, 0, 0,
        0x1p54, 0, 0,
        0, 1, 0,
        1.5, 0, 0,
    ]

    private let edgeOverflowPositions: ContiguousArray<Double> = [
        Double.greatestFiniteMagnitude, 0, 0,
        -Double.greatestFiniteMagnitude, 0, 0,
        0, 1, 0,
    ]

    private let magnitudeOverflowPositions: ContiguousArray<Double> = [
        0, 0, 0,
        1.5e200, 1.5e200, 0,
        0, 0, 1e108,
    ]

    private let accumulationOverflowPositions: ContiguousArray<Double> = [
        0, 0, 0,
        1.78e200, 0, 0,
        0, 1e108, 0,
    ]

    private func analyticalFixtures() -> [Fixture] {
        let obliquePositions: ContiguousArray<Double> = [
            0, 0, 0,
            1, 0, 0,
            0, 1, 1,
        ]
        let contractionValue = 0x1.0000002p0
        let contractionPositions: ContiguousArray<Double> = [
            0, 0, 0,
            contractionValue, 1, 0,
            1, contractionValue, 0,
        ]
        let subnormalPositions: ContiguousArray<Double> = [
            0, 0, 0,
            Double.leastNonzeroMagnitude, 0, 0,
            0, 1, 0,
        ]
        return [
            Fixture(
                name: "right-triangle",
                positions: rightTrianglePositions,
                indices: [0, 1, 2]
            ),
            Fixture(
                name: "reversed-winding",
                positions: rightTrianglePositions,
                indices: [0, 2, 1]
            ),
            Fixture(
                name: "duplicate-multiplicity",
                positions: rightTrianglePositions,
                indices: [0, 1, 2, 0, 1, 2, 0, 1, 2]
            ),
            Fixture(
                name: "degenerate-plus-valid",
                positions: rightTrianglePositions,
                indices: [0, 0, 1, 0, 1, 2]
            ),
            Fixture(name: "empty", positions: [], indices: []),
            Fixture(
                name: "all-degenerate",
                positions: rightTrianglePositions,
                indices: [0, 0, 1, 2, 2, 2]
            ),
            Fixture(
                name: "oblique-scaled",
                positions: obliquePositions,
                indices: [0, 1, 2]
            ),
            Fixture(
                name: "accumulation-order-sensitive",
                positions: orderSensitivePositions,
                indices: [0, 1, 2, 0, 3, 2, 0, 3, 2]
            ),
            Fixture(
                name: "contraction-sensitive",
                positions: contractionPositions,
                indices: [0, 1, 2]
            ),
            Fixture(
                name: "subnormal-underflow",
                positions: subnormalPositions,
                indices: [0, 1, 2]
            ),
            Fixture(
                name: "edge-overflow",
                positions: edgeOverflowPositions,
                indices: [0, 1, 2]
            ),
            Fixture(
                name: "magnitude-overflow",
                positions: magnitudeOverflowPositions,
                indices: [0, 1, 2]
            ),
            Fixture(
                name: "accumulation-overflow",
                positions: accumulationOverflowPositions,
                indices: [0, 1, 2, 0, 1, 2, 0, 1, 2]
            ),
        ]
    }

    // MARK: - Helpers

    private func mesh(for fixture: Fixture) throws -> TriangleMesh {
        try mesh(positions: fixture.positions, indices: fixture.indices)
    }

    private func mesh(
        positions: ContiguousArray<Double>,
        indices: ContiguousArray<UInt64>
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
            vertexAttributes: []
        )
    }

    /// A mesh of `facetCount` unit facets, optionally with one overflowing
    /// facet planted at an exact ordinal so poll precedence can be proven.
    private func repeatedFacetMesh(
        facetCount: Int,
        overflowingFacetOrdinal: Int? = nil
    ) throws -> TriangleMesh {
        var positions: ContiguousArray<Double> = [
            0, 0, 0,
            1, 0, 0,
            0, 1, 0,
            Double.greatestFiniteMagnitude, 0, 0,
            -Double.greatestFiniteMagnitude, 0, 0,
        ]
        positions.reserveCapacity(15)
        var indices = ContiguousArray<UInt64>()
        indices.reserveCapacity(facetCount * 3)
        for ordinal in 0..<facetCount {
            if ordinal == overflowingFacetOrdinal {
                indices.append(contentsOf: [3, 4, 2])
            } else {
                indices.append(contentsOf: [0, 1, 2])
            }
        }
        return try mesh(positions: positions, indices: indices)
    }

    @discardableResult
    private func measure(
        mesh: TriangleMesh,
        limits: TriangleMeshTotalFacetAreaLimits? = nil,
        identity: DataIdentity? = nil,
        provenance: ProvenanceRecord? = nil,
        cancellation: CPUTriangleMeshTotalFacetAreaCancellationProbe = { _ in
            false
        }
    ) throws -> (total: Double, facetCount: UInt64) {
        try TriangleMeshTotalFacetAreaReferenceKernel.measure(
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
        limits: TriangleMeshTotalFacetAreaLimits? = nil,
        identity: DataIdentity? = nil,
        provenance: ProvenanceRecord? = nil
    ) throws -> TriangleMeshTotalFacetAreaRequest {
        let sourceIdentity = try identity ?? self.sourceIdentity()
        return TriangleMeshTotalFacetAreaRequest(
            source: mesh,
            sourceIdentity: sourceIdentity,
            sourceProvenance: try provenance
                ?? sourceProvenance(subjectObjectID: sourceIdentity.objectID),
            limits: limits ?? self.limits()
        )
    }

    private func limits(
        maximumVertexCount: UInt64 = 10_000,
        maximumTriangleCount: UInt64 = 10_000
    ) -> TriangleMeshTotalFacetAreaLimits {
        TriangleMeshTotalFacetAreaLimits(
            maximumVertexCount: maximumVertexCount,
            maximumTriangleCount: maximumTriangleCount
        )
    }

    private func sourceIdentity(
        objectID: String = "area-kernel-source"
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
                ProvenanceID(rawValue: "area-kernel-source-record")
            ),
            kind: .source,
            createdAt: try CanonicalInstant(
                utcString: "2026-08-06T09:00:00Z"
            ),
            subject: .object(subjectObjectID),
            software: try SoftwareIdentity(
                name: "Voxelia Area Kernel Test Source",
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
            id: try #require(CoordinateSpaceID(rawValue: "area-kernel-space")),
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

    private func littleEndianBytes(_ bitPattern: UInt64) -> [UInt8] {
        (0..<8).map { byteIndex in
            UInt8(truncatingIfNeeded: bitPattern >> UInt64(byteIndex * 8))
        }
    }

    private func errorName(
        _ error: TriangleMeshTotalFacetAreaError
    ) -> String {
        switch error {
        case .invalidLimits: "invalidLimits"
        case .invalidSource: "invalidSource"
        case .resourceLimitExceeded: "resourceLimitExceeded"
        case .areaNotRepresentable: "areaNotRepresentable"
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
