// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaImaging

/// Verifies `series-geometry-validation/binary64-v1` against every frozen
/// fixture of `VOXELIA-ALG-0048`, all under `CTGeometryTolerance.exact`.
/// Expected measurements are the oracle's exact binary64 results, written as
/// hexadecimal float literals.
@Suite("CTGeometryValidator")
struct CTGeometryValidatorTests {
    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func identity(_ identifier: String) throws -> SourceIdentity {
        try SourceIdentity(
            namespace: "dicom",
            identifier: identifier,
            version: nil,
            contentID: nil
        )
    }

    private func frame(
        _ ident: String,
        rows: Int = 512,
        columns: Int = 512,
        row: (Double, Double, Double) = (1, 0, 0),
        column: (Double, Double, Double) = (0, 1, 0),
        rowSpacing: Double = 0.7,
        columnSpacing: Double = 0.7,
        rescaleSlope: Double = 1.0,
        interpretation: MonochromeInterpretation = .monochrome2
    ) throws -> CTFrameDescription {
        let coordinateSpace = try space()
        return try CTFrameDescription(
            sourceIdentity: try identity(ident),
            seriesIdentity: try identity("series.A"),
            rows: rows,
            columns: columns,
            scalarFormat: try ScalarFormat(
                type: .int16,
                validBitCount: nil,
                byteOrder: .littleEndian
            ),
            photometricInterpretation: interpretation,
            rowSpacingMillimetres: rowSpacing,
            columnSpacingMillimetres: columnSpacing,
            rowDirection: try Vector3D(
                x: row.0,
                y: row.1,
                z: row.2,
                coordinateSpace: coordinateSpace
            ),
            columnDirection: try Vector3D(
                x: column.0,
                y: column.1,
                z: column.2,
                coordinateSpace: coordinateSpace
            ),
            imagePosition: try Point3D(
                x: 0,
                y: 0,
                z: 0,
                coordinateSpace: coordinateSpace
            ),
            frameOfReference: nil,
            rescaleSlope: rescaleSlope,
            rescaleIntercept: -1024.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    /// Builds a series directly, so a fixture's projections and observations are
    /// exactly the specification's inputs rather than a by-product of assembly.
    private func series(
        _ pairs: [(CTFrameDescription, Double)],
        observations: Set<CTSeriesObservation> = [],
        normal: CTReferenceNormal = CTReferenceNormal(x: 0, y: 0, z: 1)
    ) throws -> CTSeries {
        CTSeries(
            key: CTSeriesKey(
                seriesIdentity: try identity("series.A"),
                coordinateSpace: try space(),
                frameOfReference: nil
            ),
            referenceNormal: normal,
            observations: observations,
            members: pairs.map { CTSeriesMember(frame: $0.0, projection: $0.1) }
        )
    }

    private func assess(_ series: CTSeries) -> CTGeometryAssessment {
        CTGeometryValidator.assess(series, tolerance: .exact)
    }

    // MARK: - G1: the regular case

    @Test("G1 a perfectly regular three-slice axial series is representable")
    func g1Regular() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2"), 2.5),
                (try frame("g3"), 5.0),
            ])
        )

        #expect(result.verdict == .representable)
        #expect(result.findings.isEmpty)
        #expect(result.measurement.memberCount == 3)
        #expect(result.measurement.minimumSliceSpacing == 0x1.4p+1)
        #expect(result.measurement.maximumSliceSpacing == 0x1.4p+1)
        #expect(result.measurement.sliceSpacingSpread == 0x0.0p+0)
        #expect(result.measurement.maximumOrientationDeviation == 0x0.0p+0)
        #expect(result.measurement.maximumInPlaneSpacingDeviation == 0x0.0p+0)
        #expect(result.measurement.rowColumnDotProduct == 0x0.0p+0)
        #expect(result.measurement.rowMagnitudeResidual == 0x0.0p+0)
        #expect(result.measurement.columnMagnitudeResidual == 0x0.0p+0)
        #expect(!result.measurement.hasDuplicateProjections)
        #expect(result.measurement.hasUniformGrid)
    }

    // MARK: - G2, G3: spacing irregularity

    @Test("G2 a spacing short by 1e-4 mm is rejected under exact tolerance")
    func g2NearlyRegular() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2"), 2.5),
                (try frame("g3"), 4.9999),
            ])
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.sliceSpacingIrregular])
        // The spread is a difference of two binary64 values, so it is not
        // exactly 1e-4 -- and the exactness of that number is the point.
        #expect(result.measurement.sliceSpacingSpread == 0x1.a36e2eb1c0000p-14)
        #expect(result.measurement.minimumSliceSpacing == 0x1.3ffcb923a29c8p+1)
        #expect(result.measurement.maximumSliceSpacing == 0x1.4p+1)
    }

    @Test("G3 a missing slice doubles a gap and is rejected")
    func g3MissingSlice() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2"), 2.5),
                (try frame("g3"), 7.5),
            ])
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.sliceSpacingIrregular])
        #expect(result.measurement.sliceSpacingSpread == 0x1.4p+1)
        #expect(result.measurement.maximumSliceSpacing == 0x1.4p+2)
    }

    // MARK: - G4: duplicates

    @Test("G4 two co-located slices are detected as duplicates")
    func g4Duplicate() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2"), 2.5),
                (try frame("g3"), 2.5),
            ])
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.duplicateProjections, .sliceSpacingIrregular])
        #expect(result.measurement.hasDuplicateProjections)
        #expect(result.measurement.minimumSliceSpacing == 0x0.0p+0)
        #expect(result.measurement.sliceSpacingSpread == 0x1.4p+1)
    }

    // MARK: - G5: the grid

    @Test("G5 a mixed grid cannot be one array and is rejected")
    func g5MixedGrid() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2", rows: 256), 2.5),
            ])
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.nonUniformGrid])
        #expect(!result.measurement.hasUniformGrid)
    }

    // MARK: - G6, G13: the exact-tolerance boundary

    @Test("G6 orientation differing by one ULP is rejected")
    func g6OneULP() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2", row: (1.0, 0, 0)), 2.5),
                (try frame("g3", row: (1.0.nextUp, 0, 0)), 5.0),
            ])
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.orientationDisagreement])
        #expect(result.measurement.maximumOrientationDeviation == 0x1.0p-52)
    }

    @Test("G13 two decimal spellings of one double are accepted")
    func g13Respelling() throws {
        // 0.99999999999999999 and 1.0 are different decimal strings naming the
        // same binary64 value. Exact tolerance forgives re-spelling; it refuses
        // only values landing on genuinely different doubles, which is G6.
        let result = assess(
            try series([
                (try frame("g1", row: (1.0, 0, 0)), 0.0),
                (try frame("g2", row: (0.999_999_999_999_999_99, 0, 0)), 2.5),
            ])
        )

        #expect(result.verdict == .representable)
        #expect(result.findings.isEmpty)
        #expect(result.measurement.maximumOrientationDeviation == 0x0.0p+0)
    }

    // MARK: - G7, G8: orthonormality

    @Test("G7 non-orthogonal anchor directions are rejected")
    func g7NonOrthogonal() throws {
        let result = assess(
            try series([
                (try frame("g1", column: (0.5, 0.5, 0)), 0.0),
                (try frame("g2", column: (0.5, 0.5, 0)), 2.5),
            ])
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.nonOrthogonalDirections, .nonUnitDirections])
        #expect(result.measurement.rowColumnDotProduct == 0x1.0p-1)
        #expect(result.measurement.columnMagnitudeResidual == -0x1.0p-1)
        #expect(result.measurement.rowMagnitudeResidual == 0x0.0p+0)
    }

    @Test("G8 a non-unit row direction is rejected")
    func g8NonUnit() throws {
        let result = assess(
            try series([
                (try frame("g1", row: (3, 0, 0)), 0.0),
                (try frame("g2", row: (3, 0, 0)), 2.5),
            ])
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.nonUnitDirections])
        #expect(result.measurement.rowMagnitudeResidual == 0x1.0p+3)
        #expect(result.measurement.rowColumnDotProduct == 0x0.0p+0)
    }

    // MARK: - G9, G12: warnings rather than rejections

    @Test("G9 a single-member series warns rather than rejecting")
    func g9SingleMember() throws {
        let result = assess(try series([(try frame("g1"), 0.0)]))

        #expect(result.verdict == .representableWithWarnings)
        #expect(result.findings == [.singleMemberSeries])
        #expect(result.measurement.minimumSliceSpacing == nil)
        #expect(result.measurement.maximumSliceSpacing == nil)
        #expect(result.measurement.sliceSpacingSpread == nil)
    }

    @Test("G12 contradictory rescale warns rather than rejecting geometry")
    func g12PresentationDisagreement() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2", rescaleSlope: 2.0), 2.5),
            ])
        )

        #expect(result.verdict == .representableWithWarnings)
        #expect(result.findings == [.presentationDisagreement])
        // Every geometry measurement is clean; only the value terms disagree.
        #expect(result.measurement.sliceSpacingSpread == 0x0.0p+0)
        #expect(result.measurement.maximumOrientationDeviation == 0x0.0p+0)
    }

    @Test("A differing photometric interpretation is the same warning")
    func photometricDisagreement() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2", interpretation: .monochrome1), 2.5),
            ])
        )

        #expect(result.verdict == .representableWithWarnings)
        #expect(result.findings == [.presentationDisagreement])
    }

    // MARK: - G10: observations are inherited, not recomputed

    @Test("G10 an assembly observation is inherited and spacings stay absent")
    func g10InheritedObservation() throws {
        // The members share a projection, so a validator that recomputed
        // spacings over the identity-order fallback would report an irregular
        // spacing and a duplicate. The correct result reports neither.
        let result = assess(
            try series(
                [(try frame("g1"), 0.0), (try frame("g2"), 0.0)],
                observations: [.degenerateReferenceNormal],
                normal: CTReferenceNormal(x: 0, y: 0, z: 0)
            )
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.degenerateReferenceNormal])
        #expect(result.measurement.minimumSliceSpacing == nil)
        #expect(result.measurement.sliceSpacingSpread == nil)
        #expect(!result.measurement.hasDuplicateProjections)
    }

    @Test(
        "Each assembly observation maps to its own inherited finding",
        arguments: [
            (
                CTSeriesObservation.degenerateReferenceNormal,
                CTGeometryFinding.degenerateReferenceNormal
            ),
            (
                CTSeriesObservation.nonFiniteReferenceNormal,
                CTGeometryFinding.nonFiniteReferenceNormal
            ),
            (CTSeriesObservation.nonFiniteProjection, CTGeometryFinding.nonFiniteProjection),
        ]
    )
    func observationMapping(
        _ observation: CTSeriesObservation,
        _ expected: CTGeometryFinding
    ) throws {
        let result = assess(
            try series(
                [(try frame("g1"), 0.0), (try frame("g2"), 2.5)],
                observations: [observation]
            )
        )

        #expect(result.findings == [expected])
        #expect(result.verdict == .rejected)
    }

    // MARK: - G11: in-plane spacing

    @Test("G11 in-plane spacing disagreement is rejected")
    func g11InPlaneDisagreement() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2", rowSpacing: 0.71), 2.5),
            ])
        )

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.inPlaneSpacingDisagreement])
        #expect(
            result.measurement.maximumInPlaneSpacingDeviation
                == 0x1.47ae147ae1480p-7
        )
    }

    // MARK: - Beyond the fixtures

    @Test("An empty series is rejected rather than falling through")
    func emptySeries() throws {
        // Unreachable through CTSeriesAssembler, but CTSeries has a public
        // initialiser. Without its own finding this would report no findings and
        // so read as representable.
        let result = assess(try series([]))

        #expect(result.verdict == .rejected)
        #expect(result.findings == [.emptySeries])
        #expect(result.measurement.memberCount == 0)
    }

    @Test("A supplied permissive tolerance admits what exact rejects")
    func permissiveToleranceIsHonoured() throws {
        // The project defines no permissive tolerance, but a caller holding its
        // own evidence can supply one, which is the point of decision 6.
        let assembled = try series([
            (try frame("g1"), 0.0),
            (try frame("g2"), 2.5),
            (try frame("g3"), 4.9999),
        ])

        #expect(assess(assembled).verdict == .rejected)

        let permissive = CTGeometryTolerance(
            orientationComponent: 0,
            inPlaneSpacingMillimetres: 0,
            sliceSpacingMillimetres: 0.001,
            orthonormalityResidual: 0
        )
        let result = CTGeometryValidator.assess(assembled, tolerance: permissive)
        #expect(result.verdict == .representable)
        #expect(result.findings.isEmpty)
        // The measurement is unchanged; only the judgement moved.
        #expect(result.measurement.sliceSpacingSpread == 0x1.a36e2eb1c0000p-14)
    }

    @Test("Exactly one finding warns, and the rest reject")
    func findingClassification() throws {
        let warnings = CTGeometryFinding.allCases.filter { !$0.rejects }
        #expect(Set(warnings) == [.singleMemberSeries, .presentationDisagreement])
        #expect(CTGeometryFinding.allCases.count == 13)
    }

    @Test("A rejection and a warning together still reject")
    func rejectionDominatesWarning() throws {
        let result = assess(
            try series([
                (try frame("g1"), 0.0),
                (try frame("g2", rows: 256, rescaleSlope: 2.0), 2.5),
            ])
        )

        #expect(result.findings == [.nonUniformGrid, .presentationDisagreement])
        #expect(result.verdict == .rejected)
    }
}
