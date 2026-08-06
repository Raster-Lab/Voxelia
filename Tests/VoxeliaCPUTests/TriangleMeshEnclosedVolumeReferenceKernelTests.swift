// SPDX-License-Identifier: MIT

import CryptoKit
import Synchronization
import Testing
import VoxeliaCore
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU triangle-mesh enclosed-volume reference kernel")
struct TriangleMeshEnclosedVolumeReferenceKernelTests {
    private struct Fixture: Sendable {
        let name: String
        let positions: ContiguousArray<Double>
        let indices: ContiguousArray<UInt64>
    }

    private final class CheckpointLog: Sendable {
        private let recorded = Mutex(
            [CPUTriangleMeshEnclosedVolumeCancellationCheckpoint]()
        )

        func record(
            _ checkpoint: CPUTriangleMeshEnclosedVolumeCancellationCheckpoint
        ) {
            recorded.withLock { $0.append(checkpoint) }
        }

        typealias Checkpoint =
            CPUTriangleMeshEnclosedVolumeCancellationCheckpoint

        var checkpoints: [Checkpoint] {
            recorded.withLock { $0 }
        }
    }

    @Test(
        "[Oracle][VOX-GEO-010][VOX-NUM-001] all ALG-0032 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var aggregateBytes = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let result = try measure(mesh: mesh(for: fixture))
                records.append(
                    "\(fixture.name)|facets=\(result.facetCount)"
                        + "|bits="
                        + hexadecimal(result.volume.bitPattern, width: 16)
                )
                aggregateBytes.append(
                    contentsOf: littleEndianBytes(result.volume.bitPattern)
                )
            } catch let error as TriangleMeshEnclosedVolumeError {
                records.append("\(fixture.name)|error=\(errorName(error))")
            }
        }

        #expect(records.count == 16)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "7f3c73ceb34815bc3bb4af7d5bc3e957c992d9670a7a9841c105a945992ab90e"
        )
        #expect(
            sha256(aggregateBytes)
                == "c313f1c0b8e59fa267541313abfc0d314df0bb7cb5711a4f29616f604296ae71"
        )
    }

    @Test(
        "[Unit][VOX-GEO-010][VOX-NUM-001] certified surfaces reduce exactly and deterministically"
    )
    func certifiedSurfacesReduceExactlyAndDeterministically() throws {
        let unitCube = try mesh(shell: cube(origin: (0, 0, 0), side: 1))
        let first = try measure(mesh: unitCube)
        let second = try measure(mesh: unitCube)
        #expect(first.volume == 1)
        #expect(first.volume.bitPattern == second.volume.bitPattern)
        #expect(first.facetCount == 12)

        // Doubling every length multiplies the volume by exactly eight.
        #expect(
            try measure(mesh: try mesh(shell: cube(origin: (0, 0, 0), side: 2)))
                .volume == 8
        )

        // The reference origin is part of the identity. Both answers are
        // correct outputs of the frozen model; neither is a defect.
        let translated = try measure(
            mesh: try mesh(shell: cube(origin: (0.1, 0.2, 0.3), side: 1))
        )
        #expect(translated.volume == 1.0000000000000004)
        #expect(translated.volume != 1)

        // Disconnection is admitted and each shell contributes its own volume.
        #expect(
            try measure(
                mesh: try mesh(
                    shells: [
                        cube(origin: (0, 0, 0), side: 1, base: 0),
                        cube(origin: (4, 0, 0), side: 2, base: 8),
                    ]
                )
            ).volume == 9
        )

        // Cavities are defined by orientation, never by nesting geometry.
        #expect(
            try measure(
                mesh: try mesh(
                    shells: [
                        cube(origin: (0, 0, 0), side: 4, base: 0),
                        cube(
                            origin: (1, 1, 1),
                            side: 2,
                            base: 8,
                            outward: false
                        ),
                    ]
                )
            ).volume == 56
        )

        // A pinch point is edge-manifold but not vertex-manifold. It
        // certifies, because the divergence identity does not need a
        // single-cycle vertex link.
        let pinch = try measure(mesh: try mesh(for: pinchPointFixture()))
        #expect(pinch.volume == 2.0 / 6.0)
        #expect(pinch.facetCount == 8)

        // An empty mesh is vacuously closed and encloses positive zero.
        let empty = try measure(
            mesh: try mesh(positions: [], indices: [])
        )
        #expect(empty.volume.bitPattern == (0.0).bitPattern)
        #expect(empty.facetCount == 0)

        // One facet and its reverse certify and enclose positive zero.
        let doubleSided = try measure(
            mesh: try mesh(
                positions: [0, 0, 0, 1, 0, 0, 0, 1, 1],
                indices: [0, 1, 2, 0, 2, 1]
            )
        )
        #expect(doubleSided.volume.bitPattern == (0.0).bitPattern)
        #expect(doubleSided.facetCount == 2)

        // Serial topology order is part of the algorithm identity.
        let order = orderSensitiveFixture()
        let ordered = try measure(mesh: try mesh(for: order))
        var rotated = ContiguousArray(order.indices[12...])
        rotated.append(contentsOf: order.indices[..<12])
        let reordered = try measure(
            mesh: try mesh(positions: order.positions, indices: rotated)
        )
        #expect(ordered.volume != reordered.volume)
    }

    @Test(
        "[Unit][VOX-GEO-010][VOX-ERR-001] certification rejects every uncertifiable surface"
    )
    func certificationRejectsEveryUncertifiableSurface() throws {
        // A cube missing one facet leaves boundary edges.
        let shell = cube(origin: (0, 0, 0), side: 1)
        #expect(throws: TriangleMeshEnclosedVolumeError.openSurface) {
            try measure(
                mesh: try mesh(
                    positions: shell.positions,
                    indices: ContiguousArray(shell.indices.dropFirst(3))
                )
            )
        }

        // A repeated facet traverses each of its directed edges twice. There
        // is no separate duplicate-facet case; this discharge is the reason.
        var duplicated = shell.indices
        duplicated.append(contentsOf: shell.indices[0..<3])
        #expect(
            throws: TriangleMeshEnclosedVolumeError.nonManifoldOrientation
        ) {
            try measure(
                mesh: try mesh(positions: shell.positions, indices: duplicated)
            )
        }

        // Two facets traversing one edge the same way are non-manifold.
        #expect(
            throws: TriangleMeshEnclosedVolumeError.nonManifoldOrientation
        ) {
            try measure(
                mesh: try mesh(
                    positions: tetrahedronPositions,
                    indices: [0, 1, 2, 0, 1, 3]
                )
            )
        }

        // A repeated index is rejected before any edge bookkeeping, so it
        // wins over the open surface the same mesh would otherwise report.
        #expect(throws: TriangleMeshEnclosedVolumeError.degenerateFacet) {
            try measure(
                mesh: try mesh(
                    positions: tetrahedronPositions,
                    indices: [0, 0, 1, 0, 1, 2]
                )
            )
        }
        for degenerate: ContiguousArray<UInt64> in [
            [0, 0, 1], [0, 1, 1], [0, 1, 0], [2, 2, 2],
        ] {
            #expect(throws: TriangleMeshEnclosedVolumeError.degenerateFacet) {
                try measure(
                    mesh: try mesh(
                        positions: tetrahedronPositions,
                        indices: degenerate
                    )
                )
            }
        }

        // A consistently inward surface certifies, but its algebraic volume
        // is negative and is named rather than silently absolutised.
        #expect(throws: TriangleMeshEnclosedVolumeError.invertedOrientation) {
            try measure(
                mesh: try mesh(
                    shell: cube(origin: (0, 0, 0), side: 1, outward: false)
                )
            )
        }

        // An extreme but finite mesh overflows the frozen expression.
        #expect(
            throws: TriangleMeshEnclosedVolumeError.volumeNotRepresentable
        ) {
            try measure(
                mesh: try mesh(
                    shell: tetrahedron(
                        apexes: [
                            (0, 0, 0),
                            (1e200, 0, 0),
                            (0, 1e200, 0),
                            (0, 0, 1e200),
                        ]
                    )
                )
            )
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-001] admission precedence is exact")
    func admissionPrecedenceIsExact() throws {
        let shell = cube(origin: (0, 0, 0), side: 1)
        let simple = try mesh(shell: shell)
        let identity = try sourceIdentity(objectID: "volume-admission-source")
        let mismatched = try sourceProvenance(
            subjectObjectID: try #require(DataObjectID(rawValue: "unmatched"))
        )

        // Cancellation precedes zero ceilings.
        #expect(throws: TriangleMeshEnclosedVolumeError.cancelled) {
            try measure(
                mesh: simple,
                limits: limits(
                    maximumVertexCount: 0,
                    maximumTriangleCount: 0,
                    maximumAdditionalLogicalByteCount: 0
                ),
                cancellation: { $0 == .admission }
            )
        }

        // Zero ceilings precede a mismatched source claim.
        for zeroed in [
            limits(maximumVertexCount: 0),
            limits(maximumTriangleCount: 0),
            limits(maximumAdditionalLogicalByteCount: 0),
        ] {
            #expect(throws: TriangleMeshEnclosedVolumeError.invalidLimits) {
                try measure(
                    mesh: simple,
                    limits: zeroed,
                    identity: identity,
                    provenance: mismatched
                )
            }
        }

        // A mismatched source claim precedes the count ceilings.
        #expect(throws: TriangleMeshEnclosedVolumeError.invalidSource) {
            try measure(
                mesh: simple,
                limits: limits(
                    maximumVertexCount: 1,
                    maximumTriangleCount: 1,
                    maximumAdditionalLogicalByteCount: 1
                ),
                identity: identity,
                provenance: mismatched
            )
        }

        // Each ceiling is inclusive and rejects one past itself. Twelve
        // facets need exactly 12 * 3 * 16 = 576 logical bytes.
        #expect(
            throws: TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        ) {
            try measure(mesh: simple, limits: limits(maximumVertexCount: 7))
        }
        #expect(
            throws: TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        ) {
            try measure(mesh: simple, limits: limits(maximumTriangleCount: 11))
        }
        #expect(
            throws: TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        ) {
            try measure(
                mesh: simple,
                limits: limits(maximumAdditionalLogicalByteCount: 575)
            )
        }
        #expect(
            try measure(
                mesh: simple,
                limits: limits(
                    maximumVertexCount: 8,
                    maximumTriangleCount: 12,
                    maximumAdditionalLogicalByteCount: 576
                )
            ).volume == 1
        )

        // The registered one-past logical-byte boundary.
        let maximumTriangleCount = UInt64.max / 48
        let counts =
            try TriangleMeshEnclosedVolumeReferenceKernel
            .checkedLogicalByteCounts(
                triangleCount: maximumTriangleCount,
                maximumAdditionalLogicalByteCount: UInt64.max
            )
        #expect(maximumTriangleCount == 384_307_168_202_282_325)
        #expect(counts.directedEdgeCount == maximumTriangleCount * 3)
        #expect(counts.additionalLogicalByteCount == maximumTriangleCount * 48)
        #expect(
            throws: TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        ) {
            _ =
                try TriangleMeshEnclosedVolumeReferenceKernel
                .checkedLogicalByteCounts(
                    triangleCount: maximumTriangleCount + 1,
                    maximumAdditionalLogicalByteCount: UInt64.max
                )
        }
    }

    @Test(
        "[Unit][VOX-CON-006][VOX-CON-007] cancellation polls exactly the frozen ordinals"
    )
    func cancellationPollsExactlyTheFrozenOrdinals() throws {
        // Sixteen disjoint cubes give 192 facets: poll ordinals 0, 64 and 128
        // in each of the three cancellable traversals.
        let manyFacets = try mesh(
            shells: (0..<16).map { index in
                cube(
                    origin: (Double(index) * 4, 0, 0),
                    side: 1,
                    base: UInt64(index) * 8
                )
            }
        )
        let log = CheckpointLog()
        let result = try measure(
            mesh: manyFacets,
            cancellation: { checkpoint in
                log.record(checkpoint)
                return false
            }
        )
        #expect(result.facetCount == 192)
        #expect(result.volume == 16)
        #expect(
            log.checkpoints == [
                .admission,
                .certification(0), .certification(64), .certification(128),
                .closure(0), .closure(64), .closure(128),
                .volume(0), .volume(64), .volume(128),
                .final,
            ]
        )

        for checkpoint: CPUTriangleMeshEnclosedVolumeCancellationCheckpoint
            in [
                .admission,
                .certification(0), .certification(128),
                .closure(0), .closure(128),
                .volume(0), .volume(128),
                .final,
            ]
        {
            #expect(throws: TriangleMeshEnclosedVolumeError.cancelled) {
                try measure(mesh: manyFacets, cancellation: { $0 == checkpoint })
            }
        }

        // A non-poll ordinal is never observed, so it cannot cancel.
        #expect(
            try measure(
                mesh: manyFacets,
                cancellation: { $0 == .volume(1) }
            ).facetCount == 192
        )

        // No arithmetic runs for an uncertified surface, so a certification
        // failure can never be masked by a representability failure.
        let overflowingButOpen = try mesh(
            positions: [
                0, 0, 0,
                1e200, 0, 0,
                0, 1e200, 0,
                0, 0, 1e200,
            ],
            indices: [0, 2, 1]
        )
        #expect(throws: TriangleMeshEnclosedVolumeError.openSurface) {
            try measure(mesh: overflowingButOpen)
        }

        // The final checkpoint is suppressed for the public operation, which
        // owns its own final check.
        #expect(
            try TriangleMeshEnclosedVolumeReferenceKernel.measure(
                request: try request(mesh: manyFacets),
                cancellation: { $0 == .final },
                checksFinalCancellation: false
            ).facetCount == 192
        )
    }

    // MARK: - Fixtures

    private let tetrahedronPositions: ContiguousArray<Double> = [
        0, 0, 0,
        1, 0, 0,
        0, 1, 0,
        0, 0, 1,
    ]

    private struct Shell: Sendable {
        let positions: ContiguousArray<Double>
        let indices: ContiguousArray<UInt64>
    }

    private func cube(
        origin: (Double, Double, Double),
        side: Double,
        base: UInt64 = 0,
        outward: Bool = true
    ) -> Shell {
        let (x, y, z) = origin
        let corners: [(Double, Double, Double)] = [
            (x, y, z),
            (x + side, y, z),
            (x + side, y + side, z),
            (x, y + side, z),
            (x, y, z + side),
            (x + side, y, z + side),
            (x + side, y + side, z + side),
            (x, y + side, z + side),
        ]
        var positions = ContiguousArray<Double>()
        positions.reserveCapacity(24)
        for corner in corners {
            positions.append(corner.0)
            positions.append(corner.1)
            positions.append(corner.2)
        }
        let outwardTriangles: [(UInt64, UInt64, UInt64)] = [
            (0, 3, 2), (0, 2, 1),
            (4, 5, 6), (4, 6, 7),
            (0, 1, 5), (0, 5, 4),
            (1, 2, 6), (1, 6, 5),
            (2, 3, 7), (2, 7, 6),
            (3, 0, 4), (3, 4, 7),
        ]
        var indices = ContiguousArray<UInt64>()
        indices.reserveCapacity(36)
        for triangle in outwardTriangles {
            indices.append(base + triangle.0)
            indices.append(base + (outward ? triangle.1 : triangle.2))
            indices.append(base + (outward ? triangle.2 : triangle.1))
        }
        return Shell(positions: positions, indices: indices)
    }

    private func tetrahedron(
        apexes: [(Double, Double, Double)],
        base: UInt64 = 0
    ) -> Shell {
        var positions = ContiguousArray<Double>()
        positions.reserveCapacity(12)
        for apex in apexes {
            positions.append(apex.0)
            positions.append(apex.1)
            positions.append(apex.2)
        }
        let triangles: [(UInt64, UInt64, UInt64)] = [
            (0, 2, 1), (0, 1, 3), (0, 3, 2), (1, 2, 3),
        ]
        var indices = ContiguousArray<UInt64>()
        indices.reserveCapacity(12)
        for triangle in triangles {
            indices.append(base + triangle.0)
            indices.append(base + triangle.1)
            indices.append(base + triangle.2)
        }
        return Shell(positions: positions, indices: indices)
    }

    private func joined(_ shells: [Shell]) -> Shell {
        var positions = ContiguousArray<Double>()
        var indices = ContiguousArray<UInt64>()
        for shell in shells {
            positions.append(contentsOf: shell.positions)
            indices.append(contentsOf: shell.indices)
        }
        return Shell(positions: positions, indices: indices)
    }

    /// Two closed tetrahedra sharing exactly one vertex index. The second is
    /// the first rotated by `(x, y) -> (-x, -y)`, which preserves handedness.
    private func pinchPointFixture() -> Fixture {
        Fixture(
            name: "pinch-point-vertex",
            positions: [
                0, 0, 0,
                1, 0, 0,
                0, 1, 0,
                0, 0, 1,
                -1, 0, 0,
                0, -1, 0,
                0, 0, 1,
            ],
            indices: [
                0, 2, 1, 0, 1, 3, 0, 3, 2, 1, 2, 3,
                0, 5, 4, 0, 4, 6, 0, 6, 5, 4, 5, 6,
            ]
        )
    }

    private func orderSensitiveFixture() -> Fixture {
        let shell = joined([
            tetrahedron(
                apexes: [(0, 0, 0), (0x1p53, 0, 0), (0, 1, 0), (0, 0, 1)]
            ),
            tetrahedron(
                apexes: [(0, 0, 0), (0.75, 0, 0), (0, 1, 0), (0, 0, 1)],
                base: 4
            ),
            tetrahedron(
                apexes: [(0, 0, 0), (1, 0, 0), (0, 0.75, 0), (0, 0, 1)],
                base: 8
            ),
        ])
        return Fixture(
            name: "accumulation-order-sensitive",
            positions: shell.positions,
            indices: shell.indices
        )
    }

    private func analyticalFixtures() -> [Fixture] {
        let unitCube = cube(origin: (0, 0, 0), side: 1)
        var duplicated = unitCube.indices
        duplicated.append(contentsOf: unitCube.indices[0..<3])
        let overflow = tetrahedron(
            apexes: [(0, 0, 0), (1e200, 0, 0), (0, 1e200, 0), (0, 0, 1e200)]
        )
        return [
            fixture(
                "unit-tetrahedron",
                tetrahedron(
                    apexes: [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)]
                )
            ),
            fixture("unit-cube", unitCube),
            fixture(
                "translated-cube",
                cube(origin: (0.1, 0.2, 0.3), side: 1)
            ),
            fixture("scaled-cube", cube(origin: (0, 0, 0), side: 2)),
            Fixture(name: "empty", positions: [], indices: []),
            fixture(
                "disjoint-shells",
                joined([
                    cube(origin: (0, 0, 0), side: 1, base: 0),
                    cube(origin: (4, 0, 0), side: 2, base: 8),
                ])
            ),
            fixture(
                "nested-cavity",
                joined([
                    cube(origin: (0, 0, 0), side: 4, base: 0),
                    cube(origin: (1, 1, 1), side: 2, base: 8, outward: false),
                ])
            ),
            pinchPointFixture(),
            Fixture(
                name: "double-sided-facet",
                positions: [0, 0, 0, 1, 0, 0, 0, 1, 1],
                indices: [0, 1, 2, 0, 2, 1]
            ),
            orderSensitiveFixture(),
            Fixture(
                name: "open-surface",
                positions: unitCube.positions,
                indices: ContiguousArray(unitCube.indices.dropFirst(3))
            ),
            Fixture(
                name: "duplicate-facet",
                positions: unitCube.positions,
                indices: duplicated
            ),
            Fixture(
                name: "same-direction-shared-edge",
                positions: tetrahedronPositions,
                indices: [0, 1, 2, 0, 1, 3]
            ),
            Fixture(
                name: "index-degenerate-facet",
                positions: tetrahedronPositions,
                indices: [0, 0, 1, 0, 1, 2]
            ),
            fixture(
                "inverted-orientation",
                cube(origin: (0, 0, 0), side: 1, outward: false)
            ),
            fixture("triple-product-overflow", overflow),
        ]
    }

    private func fixture(_ name: String, _ shell: Shell) -> Fixture {
        Fixture(name: name, positions: shell.positions, indices: shell.indices)
    }

    // MARK: - Helpers

    private func mesh(for fixture: Fixture) throws -> TriangleMesh {
        try mesh(positions: fixture.positions, indices: fixture.indices)
    }

    private func mesh(shell: Shell) throws -> TriangleMesh {
        try mesh(positions: shell.positions, indices: shell.indices)
    }

    private func mesh(shells: [Shell]) throws -> TriangleMesh {
        try mesh(shell: joined(shells))
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

    @discardableResult
    private func measure(
        mesh: TriangleMesh,
        limits: TriangleMeshEnclosedVolumeLimits? = nil,
        identity: DataIdentity? = nil,
        provenance: ProvenanceRecord? = nil,
        cancellation: CPUTriangleMeshEnclosedVolumeCancellationProbe = { _ in
            false
        }
    ) throws -> (volume: Double, facetCount: UInt64) {
        try TriangleMeshEnclosedVolumeReferenceKernel.measure(
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
        limits: TriangleMeshEnclosedVolumeLimits? = nil,
        identity: DataIdentity? = nil,
        provenance: ProvenanceRecord? = nil
    ) throws -> TriangleMeshEnclosedVolumeRequest {
        let sourceIdentity = try identity ?? self.sourceIdentity()
        return TriangleMeshEnclosedVolumeRequest(
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
        maximumAdditionalLogicalByteCount: UInt64 = 1_000_000
    ) -> TriangleMeshEnclosedVolumeLimits {
        TriangleMeshEnclosedVolumeLimits(
            maximumVertexCount: maximumVertexCount,
            maximumTriangleCount: maximumTriangleCount,
            maximumAdditionalLogicalByteCount:
                maximumAdditionalLogicalByteCount
        )
    }

    private func sourceIdentity(
        objectID: String = "volume-kernel-source"
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
                ProvenanceID(rawValue: "volume-kernel-source-record")
            ),
            kind: .source,
            createdAt: try CanonicalInstant(
                utcString: "2026-08-06T10:00:00Z"
            ),
            subject: .object(subjectObjectID),
            software: try SoftwareIdentity(
                name: "Voxelia Volume Kernel Test Source",
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
            id: try #require(
                CoordinateSpaceID(rawValue: "volume-kernel-space")
            ),
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
        _ error: TriangleMeshEnclosedVolumeError
    ) -> String {
        switch error {
        case .invalidLimits: "invalidLimits"
        case .invalidSource: "invalidSource"
        case .resourceLimitExceeded: "resourceLimitExceeded"
        case .degenerateFacet: "degenerateFacet"
        case .openSurface: "openSurface"
        case .nonManifoldOrientation: "nonManifoldOrientation"
        case .invertedOrientation: "invertedOrientation"
        case .volumeNotRepresentable: "volumeNotRepresentable"
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
