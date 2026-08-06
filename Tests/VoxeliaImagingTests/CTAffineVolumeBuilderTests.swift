// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaImaging

/// Verifies `ct-affine-volume/binary64-v1` against every frozen fixture of
/// `VOXELIA-ALG-0049`. Expected matrix elements and residuals are the oracle's
/// exact binary64 results, written as hexadecimal float literals.
///
/// Every fixture uses `rowSpacing = 0.7` and `columnSpacing = 0.8`, so an
/// implementation that pairs `rowSpacing` with `rowDirection` transposes the
/// in-plane steps and fails.
@Suite("CTAffineVolumeBuilder")
struct CTAffineVolumeBuilderTests {
    private static let patient = "patient"

    private func space(_ raw: String = patient) throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: raw))
    }

    private func identity(_ identifier: String) throws -> SourceIdentity {
        try SourceIdentity(
            namespace: "dicom",
            identifier: identifier,
            version: nil,
            contentID: nil
        )
    }

    private func descriptor(
        _ raw: String = patient,
        references: [ExternalFrameReference] = []
    ) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try space(raw),
            convention: .dicomPatientLPS,
            handedness: .rightHanded,
            unit: try MeasurementUnit(
                namespace: "ucum",
                code: "mm",
                displayName: "millimetre",
                dimension: .length,
                scaleToCanonical: nil,
                offsetToCanonical: nil
            ),
            externalReferences: ContiguousArray(references)
        )
    }

    private func frame(
        _ ident: String,
        position: (Double, Double, Double),
        row: (Double, Double, Double) = (1, 0, 0),
        column: (Double, Double, Double) = (0, 1, 0),
        rowSpacing: Double = 0.7,
        columnSpacing: Double = 0.8,
        rescaleSlope: Double = 1.0,
        space raw: String = patient
    ) throws -> CTFrameDescription {
        let coordinateSpace = try space(raw)
        return try CTFrameDescription(
            sourceIdentity: try identity(ident),
            seriesIdentity: try identity("series.A"),
            rows: 512,
            columns: 512,
            scalarFormat: try ScalarFormat(
                type: .int16,
                validBitCount: nil,
                byteOrder: .littleEndian
            ),
            photometricInterpretation: .monochrome2,
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
                x: position.0,
                y: position.1,
                z: position.2,
                coordinateSpace: coordinateSpace
            ),
            frameOfReference: nil,
            rescaleSlope: rescaleSlope,
            rescaleIntercept: -1024.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    /// Assembles through the real pipeline, so a fixture's verdict is the one
    /// `CTGeometryValidator` actually produces rather than one asserted here.
    private func build(
        _ frames: [CTFrameDescription],
        descriptor override: CoordinateSpaceDescriptor? = nil
    ) throws -> (CTVolumeConstruction, CTGeometryAssessment) {
        let series = try #require(CTSeriesAssembler.assemble(frames).first)
        let assessment = CTGeometryValidator.assess(series, tolerance: .exact)
        let construction = try CTAffineVolumeBuilder.build(
            series: series,
            assessment: assessment,
            coordinateSpace: try override ?? descriptor()
        )
        return (construction, assessment)
    }

    private func elements(_ construction: CTVolumeConstruction) -> [Double] {
        Array(construction.geometry.indexToWorld.elements)
    }

    // MARK: - D1: the regular case, and the axis crossing

    @Test("D1 a regular axial series builds the frozen matrix")
    func d1Regular() throws {
        let (construction, assessment) = try build([
            try frame("d1", position: (-175.5, -175.5, 0.0)),
            try frame("d2", position: (-175.5, -175.5, 2.5)),
            try frame("d3", position: (-175.5, -175.5, 5.0)),
        ])

        #expect(assessment.verdict == .representable)
        #expect(
            elements(construction) == [
                0x1.999999999999ap-1, 0, 0, -0x1.5fp+7,
                0, 0x1.6666666666666p-1, 0, -0x1.5fp+7,
                0, 0, 0x1.4p+1, 0,
                0, 0, 0, 1,
            ]
        )
        #expect(construction.fidelityResidual == 0x0.0p+0)
        #expect(construction.carriedWarnings.isEmpty)
    }

    @Test("D1 the in-plane steps cross: columnSpacing scales rowDirection")
    func d1AxisCrossing() throws {
        let (construction, _) = try build([
            try frame("d1", position: (0, 0, 0.0)),
            try frame("d2", position: (0, 0, 2.5)),
        ])
        let m = elements(construction)

        // iStep.x is columnSpacing (0.8) along rowDirection; jStep.y is
        // rowSpacing (0.7) along columnDirection. Pairing row with row yields
        // these two transposed.
        #expect(m[0] == 0x1.999999999999ap-1)
        #expect(m[5] == 0x1.6666666666666p-1)
        #expect(m[0] != m[5])
    }

    // MARK: - D2: oblique

    @Test("D2 an oblique series builds the frozen matrix")
    func d2Oblique() throws {
        let (construction, assessment) = try build([
            try frame("d1", position: (1, 2, 3), row: (0, 1, 0), column: (0, 0, 1)),
            try frame("d2", position: (4, 2, 3), row: (0, 1, 0), column: (0, 0, 1)),
        ])

        #expect(assessment.verdict == .representable)
        #expect(
            elements(construction) == [
                0, 0, 0x1.8p+1, 0x1.0p+0,
                0x1.999999999999ap-1, 0, 0, 0x1.0p+1,
                0, 0x1.6666666666666p-1, 0, 0x1.8p+1,
                0, 0, 0, 1,
            ]
        )
        #expect(construction.fidelityResidual == 0x0.0p+0)
    }

    // MARK: - D3: a validated series that cannot be constructed

    @Test("D3 an approved series whose determinant underflows is singular")
    func d3DeterminantUnderflow() throws {
        let frames = [
            try frame("d1", position: (0, 0, 0), rowSpacing: 1e-160, columnSpacing: 1e-160),
            try frame("d2", position: (0, 0, 1), rowSpacing: 1e-160, columnSpacing: 1e-160),
        ]
        let series = try #require(CTSeriesAssembler.assemble(frames).first)
        let assessment = CTGeometryValidator.assess(series, tolerance: .exact)

        // The validator approves it completely: uniform positive finite spacings
        // and exactly orthonormal directions.
        #expect(assessment.verdict == .representable)
        #expect(assessment.findings.isEmpty)

        // Construction still fails, because the determinant underflows. The
        // rejection comes from AffineGridGeometry's ADR-0043 admission.
        #expect(throws: CTVolumeConstructionError.singularTransform) {
            try CTAffineVolumeBuilder.build(
                series: series,
                assessment: assessment,
                coordinateSpace: try descriptor()
            )
        }
    }

    // MARK: - D4: the single-member series

    @Test("D4 a single member leaves the slice step undefined")
    func d4SingleMember() throws {
        let series = try #require(
            CTSeriesAssembler.assemble([try frame("d1", position: (0, 0, 0))]).first
        )
        let assessment = CTGeometryValidator.assess(series, tolerance: .exact)

        // A warning, not a rejection -- and still not constructible.
        #expect(assessment.verdict == .representableWithWarnings)
        #expect(assessment.findings == [.singleMemberSeries])
        #expect(throws: CTVolumeConstructionError.sliceStepUndefined) {
            try CTAffineVolumeBuilder.build(
                series: series,
                assessment: assessment,
                coordinateSpace: try descriptor()
            )
        }
    }

    // MARK: - D5 and D6: the fidelity residual

    @Test("D5 an exactly regular series still drifts from its own lattice")
    func d5Drift() throws {
        let frames = [
            try frame("d1", position: (0, 0, -21.779939649890252)),
            try frame("d2", position: (0, 0, -15.460854058197997)),
            try frame("d3", position: (0, 0, -9.141768466505741)),
            try frame("d4", position: (0, 0, -2.822682874813486)),
        ]
        let (construction, assessment) = try build(frames)

        // Every consecutive gap is bit-identical, so the exact tolerance admits
        // it outright.
        #expect(assessment.verdict == .representable)
        #expect(assessment.measurement.sliceSpacingSpread == 0x0.0p+0)

        // And the uniform affine still misplaces a slice.
        #expect(construction.fidelityResidual == 0x1.0p-49)
        let m = elements(construction)
        #expect(m[10] == 0x1.946be5f93c5aep+2)
        #expect(m[11] == -0x1.5c7aa1ff921e0p+4)
    }

    @Test("D6 a dyadic spacing reproduces every position exactly")
    func d6Exact() throws {
        let (construction, _) = try build([
            try frame("d1", position: (0, 0, 0.0)),
            try frame("d2", position: (0, 0, 2.5)),
            try frame("d3", position: (0, 0, 5.0)),
            try frame("d4", position: (0, 0, 7.5)),
        ])

        #expect(construction.fidelityResidual == 0x0.0p+0)
        #expect(elements(construction)[10] == 0x1.4p+1)
    }

    // MARK: - Verdict handling

    @Test("A rejected series is refused")
    func rejectedSeriesRefused() throws {
        let frames = [
            try frame("d1", position: (0, 0, 0.0)),
            try frame("d2", position: (0, 0, 2.5)),
            try frame("d3", position: (0, 0, 4.9999)),
        ]
        let series = try #require(CTSeriesAssembler.assemble(frames).first)
        let assessment = CTGeometryValidator.assess(series, tolerance: .exact)

        #expect(assessment.verdict == .rejected)
        #expect(throws: CTVolumeConstructionError.seriesRejected) {
            try CTAffineVolumeBuilder.build(
                series: series,
                assessment: assessment,
                coordinateSpace: try descriptor()
            )
        }
    }

    @Test("A warned series builds and carries its warnings forward")
    func warningsCarriedForward() throws {
        let (construction, assessment) = try build([
            try frame("d1", position: (0, 0, 0.0)),
            try frame("d2", position: (0, 0, 2.5), rescaleSlope: 2.0),
        ])

        #expect(assessment.verdict == .representableWithWarnings)
        #expect(construction.carriedWarnings == [.presentationDisagreement])
        // The geometry is sound, so refusing would discard a valid affine over a
        // value-comparability fact this stage has no authority over.
        #expect(elements(construction)[10] == 0x1.4p+1)
    }

    // MARK: - The coordinate-space contract

    @Test("A descriptor naming another space is refused")
    func coordinateSpaceMismatch() throws {
        #expect(throws: CTVolumeConstructionError.coordinateSpaceMismatch) {
            try build(
                [
                    try frame("d1", position: (0, 0, 0.0)),
                    try frame("d2", position: (0, 0, 2.5)),
                ],
                descriptor: try descriptor("table")
            )
        }
    }

    @Test("A series frame-of-reference the descriptor omits is refused")
    func frameOfReferenceNotPreserved() throws {
        let reference = try ExternalFrameReference(
            namespace: "dicom",
            identifier: "1.2.840.frame.1"
        )
        let series = CTSeries(
            key: CTSeriesKey(
                seriesIdentity: try identity("series.A"),
                coordinateSpace: try space(),
                frameOfReference: reference
            ),
            referenceNormal: CTReferenceNormal(x: 0, y: 0, z: 1),
            observations: [],
            members: [
                CTSeriesMember(frame: try frame("d1", position: (0, 0, 0)), projection: 0),
                CTSeriesMember(
                    frame: try frame("d2", position: (0, 0, 2.5)),
                    projection: 2.5
                ),
            ]
        )
        let assessment = CTGeometryValidator.assess(series, tolerance: .exact)

        #expect(throws: CTVolumeConstructionError.frameOfReferenceNotPreserved) {
            try CTAffineVolumeBuilder.build(
                series: series,
                assessment: assessment,
                coordinateSpace: try descriptor()
            )
        }

        // Listing it in the descriptor is what preserves it, per VOX-DCM-007.
        let construction = try CTAffineVolumeBuilder.build(
            series: series,
            assessment: assessment,
            coordinateSpace: try descriptor(references: [reference])
        )
        #expect(construction.geometry.coordinateSpace.externalReferences.count == 1)
    }

    // MARK: - The accepted geometry surface

    @Test("The constructed geometry carries the supplied space and axis mapping")
    func geometrySurface() throws {
        let (construction, _) = try build([
            try frame("d1", position: (0, 0, 0.0)),
            try frame("d2", position: (0, 0, 2.5)),
        ])

        #expect(construction.geometry.coordinateSpace.convention == .dicomPatientLPS)
        #expect(construction.geometry.spatialAxes.imageAxes == [0, 1, 2])
        // The bottom row is the literal the ADR-0043 admission requires, so
        // nonAffineBottomRow is unreachable by construction.
        let m = elements(construction)
        #expect([m[12], m[13], m[14], m[15]] == [0, 0, 0, 1])
    }
}
