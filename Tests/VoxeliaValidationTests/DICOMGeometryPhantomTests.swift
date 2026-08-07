// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaImaging
import VoxeliaInteraction
import VoxeliaSpatial
import VoxeliaValidation

/// `ADR-0298` (`VOX-VAL-012`): DICOM-derived spatial geometry validated with known datasets
/// and phantoms.
///
/// `CTAffineVolumeBuilder` already has its own suite against `VOXELIA-ALG-0049`'s frozen
/// fixtures. That checks the matrix. This checks the **consequence** of the matrix: a
/// phantom placed by a geometry the real ingest path derived lands where its closed form
/// says it should, and the physical distances between its endpoints are the known ones.
///
/// The datasets are synthetic by construction. No test in this repository reads patient data.
@Suite("DICOMGeometryPhantom")
struct DICOMGeometryPhantomTests {
    private static let patient = "patient"

    private func spaceID(_ raw: String = patient) throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: raw))
    }

    private func descriptor() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try spaceID(),
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
            externalReferences: []
        )
    }

    /// One synthetic CT frame. Every value here is chosen, not measured.
    private func frame(
        _ identifier: String,
        position: (Double, Double, Double),
        row: (Double, Double, Double) = (1, 0, 0),
        column: (Double, Double, Double) = (0, 1, 0),
        rowSpacing: Double,
        columnSpacing: Double
    ) throws -> CTFrameDescription {
        let space = try spaceID()
        return try CTFrameDescription(
            sourceIdentity: try SourceIdentity(
                namespace: "dicom", identifier: identifier, version: nil, contentID: nil),
            seriesIdentity: try SourceIdentity(
                namespace: "dicom", identifier: "series.phantom", version: nil,
                contentID: nil),
            rows: 16,
            columns: 16,
            scalarFormat: try ScalarFormat(
                type: .int16, validBitCount: nil, byteOrder: .littleEndian),
            photometricInterpretation: .monochrome2,
            rowSpacingMillimetres: rowSpacing,
            columnSpacingMillimetres: columnSpacing,
            rowDirection: try Vector3D(
                x: row.0, y: row.1, z: row.2, coordinateSpace: space),
            columnDirection: try Vector3D(
                x: column.0, y: column.1, z: column.2, coordinateSpace: space),
            imagePosition: try Point3D(
                x: position.0, y: position.1, z: position.2, coordinateSpace: space),
            frameOfReference: nil,
            rescaleSlope: 1.0,
            rescaleIntercept: -1024.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    /// Drives the real ingest path — assembly, then validation, then construction — so the
    /// geometry under test is the one the product derives rather than one written here.
    private func derive(_ frames: [CTFrameDescription]) throws -> CTVolumeConstruction {
        let series = try #require(CTSeriesAssembler.assemble(frames).first)
        let assessment = CTGeometryValidator.assess(series, tolerance: .exact)
        #expect(assessment.verdict != .rejected)
        return try CTAffineVolumeBuilder.build(
            series: series,
            assessment: assessment,
            coordinateSpace: try descriptor()
        )
    }

    /// Six axial frames stepping two millimetres in patient Z, with **distinct** in-plane
    /// spacings so a transposed axis pairing cannot pass unnoticed.
    private func axialSeries(
        rowSpacing: Double,
        columnSpacing: Double,
        origin: (Double, Double, Double) = (10, 0, 0)
    ) throws -> [CTFrameDescription] {
        try (0..<6).map { index in
            try frame(
                "frame.\(index)",
                position: (origin.0, origin.1, origin.2 + 2.0 * Double(index)),
                rowSpacing: rowSpacing,
                columnSpacing: columnSpacing
            )
        }
    }

    // MARK: - The derived geometry places the ramp phantom

    @Test("[Unit][VOX-VAL-012] a DICOM-derived geometry samples the ramp at its closed form")
    func dicomDerivedGeometrySamplesTheRampAtItsClosedForm() throws {
        // Column spacing 1 and row spacing 2 are deliberately not in the ratio the ramp's
        // own weights would hide: the derived value is 10 + i + 4j - k, where a transposed
        // pairing would give 10 + 2i + 2j - k. See the falsification below.
        let construction = try derive(
            try axialSeries(rowSpacing: 2.0, columnSpacing: 1.0))
        let phantom = try PhysicalRampPhantom(
            columns: 4,
            rows: 3,
            slices: 3,
            indexToPatient: construction.geometry.indexToWorld,
            coordinateSpace: construction.geometry.coordinateSpace.id
        )

        // The closed form is derived from the DICOM inputs, not read back from the matrix:
        // the patient position is origin + i*columnSpacing*rowDirection
        // + j*rowSpacing*columnDirection + k*sliceStep, and the ramp is x + 2y - 0.5z.
        for slice in 0..<3 {
            for row in 0..<3 {
                for column in 0..<4 {
                    let expected = 10 + column + 4 * row - slice
                    #expect(
                        try phantom.value(column: column, row: row, slice: slice)
                            == Int16(expected)
                    )
                }
            }
        }
        #expect(try phantom.value(column: 0, row: 0, slice: 0) == 10)
        #expect(try phantom.value(column: 3, row: 2, slice: 0) == 21)
    }

    @Test("[Unit][VOX-VAL-012] a transposed in-plane pairing changes the sampled values")
    func transposedInPlanePairingChangesTheSampledValues() throws {
        // The falsification. `CTAffineVolumeBuilder` crosses the axes — column spacing scales
        // the row direction — and its own comment warns that reading it backwards transposes
        // the volume silently. Swapping the two spacings in the dataset produces a different
        // phantom, so the test above cannot pass for a builder that paired them the other way.
        let straight = try derive(try axialSeries(rowSpacing: 2.0, columnSpacing: 1.0))
        let swapped = try derive(try axialSeries(rowSpacing: 1.0, columnSpacing: 2.0))

        let straightPhantom = try PhysicalRampPhantom(
            columns: 4, rows: 3, slices: 3,
            indexToPatient: straight.geometry.indexToWorld,
            coordinateSpace: straight.geometry.coordinateSpace.id)
        let swappedPhantom = try PhysicalRampPhantom(
            columns: 4, rows: 3, slices: 3,
            indexToPatient: swapped.geometry.indexToWorld,
            coordinateSpace: swapped.geometry.coordinateSpace.id)

        // 10 + i + 4j - k against 10 + 2i + 2j - k: equal only where i equals 2j.
        #expect(try straightPhantom.value(column: 1, row: 0, slice: 0) == 11)
        #expect(try swappedPhantom.value(column: 1, row: 0, slice: 0) == 12)
        #expect(try straightPhantom.value(column: 0, row: 1, slice: 0) == 14)
        #expect(try swappedPhantom.value(column: 0, row: 1, slice: 0) == 12)
    }

    @Test("[Unit][VOX-VAL-012] an oblique DICOM series derives the crossed in-plane steps")
    func obliqueDICOMSeriesDerivesTheCrossedInPlaneSteps() throws {
        // The plan's oblique stack. Three-four-five direction cosines keep the expected
        // elements exactly statable: the column step is columnSpacing times the row
        // direction, and the row step is rowSpacing times the column direction.
        let frames = try (0..<4).map { index in
            try frame(
                "oblique.\(index)",
                position: (0, 0, 2.0 * Double(index)),
                row: (0.6, 0.8, 0),
                column: (-0.8, 0.6, 0),
                rowSpacing: 2.0,
                columnSpacing: 1.0
            )
        }
        let construction = try derive(frames)
        let elements = Array(construction.geometry.indexToWorld.elements)

        #expect(elements[0] == 1.0 * 0.6)
        #expect(elements[4] == 1.0 * 0.8)
        #expect(elements[8] == 0.0)
        #expect(elements[1] == 2.0 * -0.8)
        #expect(elements[5] == 2.0 * 0.6)
        #expect(elements[9] == 0.0)
        #expect(elements[2] == 0.0)
        #expect(elements[6] == 0.0)
        #expect(elements[10] == 2.0)

        // And the phantom placed by it agrees with that geometry sample for sample, so the
        // oblique path composes rather than merely producing a plausible matrix.
        let phantom = try PhysicalRampPhantom(
            columns: 3, rows: 3, slices: 3,
            indexToPatient: construction.geometry.indexToWorld,
            coordinateSpace: construction.geometry.coordinateSpace.id)
        for slice in 0..<3 {
            for row in 0..<3 {
                for column in 0..<3 {
                    let position = try phantom.patientPosition(
                        column: column, row: row, slice: slice)
                    let ramp = (position.x + 2.0 * position.y) - 0.5 * position.z
                    #expect(
                        try phantom.value(column: column, row: row, slice: slice)
                            == Int16(ramp.rounded(.toNearestOrEven))
                    )
                }
            }
        }
    }

    // MARK: - The derived geometry carries physical distance

    @Test("[Unit][VOX-VAL-012] distances measured in a DICOM-derived geometry are exact")
    func distancesMeasuredInADICOMDerivedGeometryAreExact() throws {
        // A realistic acquisition: half-millimetre pixels, two-millimetre slices. That is
        // exactly `DistancePhantom`'s admitted configuration, so the phantom can be placed
        // by the derived geometry and its known lengths measured through the shipped
        // `MeasurementConstruction`.
        let construction = try derive(
            try axialSeries(rowSpacing: 0.5, columnSpacing: 0.5))
        let elements = Array(construction.geometry.indexToWorld.elements)

        // Read the spacing and origin out of what the ingest path derived rather than
        // restating the dataset's numbers.
        let phantom = try DistancePhantom(
            columns: 8,
            rows: 11,
            slices: 6,
            columnSpacing: elements[0],
            rowSpacing: elements[5],
            sliceSpacing: elements[10],
            origin: try Point3D(
                x: elements[3],
                y: elements[7],
                z: elements[11],
                coordinateSpace: construction.geometry.coordinateSpace.id
            )
        )
        #expect(elements[0] == 0.5)
        #expect(elements[5] == 0.5)
        #expect(elements[10] == 2.0)

        for segment in phantom.segments {
            let measured = try MeasurementConstruction(points: [segment.start, segment.end])
            #expect(measured.derivedLength == segment.exactLength)
        }
        #expect(phantom.segments.map(\.exactLength) == [5.0, 3.0, 7.0, 9.0])
    }

    @Test("[Unit][VOX-VAL-012] a coarser dataset moves the samples but not the distances")
    func coarserDatasetMovesTheSamplesButNotTheDistances() throws {
        // The patient-space claim, made from the DICOM side: a different acquisition grid
        // changes every index separation and leaves the physical lengths alone.
        let fine = try derive(try axialSeries(rowSpacing: 0.5, columnSpacing: 0.5))
        let coarse = try derive(try axialSeries(rowSpacing: 1.0, columnSpacing: 1.0))

        let finePhantom = try DistancePhantom(
            columns: 8, rows: 11, slices: 6,
            columnSpacing: Array(fine.geometry.indexToWorld.elements)[0],
            rowSpacing: Array(fine.geometry.indexToWorld.elements)[5],
            sliceSpacing: Array(fine.geometry.indexToWorld.elements)[10],
            origin: try Point3D(
                x: 10, y: 0, z: 0,
                coordinateSpace: fine.geometry.coordinateSpace.id))
        let coarsePhantom = try DistancePhantom(
            columns: 8, rows: 11, slices: 6,
            columnSpacing: Array(coarse.geometry.indexToWorld.elements)[0],
            rowSpacing: Array(coarse.geometry.indexToWorld.elements)[5],
            sliceSpacing: Array(coarse.geometry.indexToWorld.elements)[10],
            origin: try Point3D(
                x: 10, y: 0, z: 0,
                coordinateSpace: coarse.geometry.coordinateSpace.id))

        let pairs = zip(finePhantom.segments, coarsePhantom.segments)
        for (fineSegment, coarseSegment) in pairs {
            #expect(fineSegment.exactLength == coarseSegment.exactLength)
            #expect(fineSegment.endIndex != coarseSegment.endIndex)
            let fineMeasured = try MeasurementConstruction(points: [
                fineSegment.start, fineSegment.end,
            ])
            let coarseMeasured = try MeasurementConstruction(points: [
                coarseSegment.start, coarseSegment.end,
            ])
            #expect(fineMeasured.derivedLength == coarseMeasured.derivedLength)
        }
    }

    // MARK: - The dataset has to be one the ingest path actually accepts

    @Test("[Unit][VOX-VAL-012] the phantom datasets pass geometry validation unwarned")
    func phantomDatasetsPassGeometryValidationUnwarned() throws {
        // A phantom placed by a geometry the validator only tolerated would be validating
        // against a dataset the product would flag, so the verdict is asserted rather than
        // assumed. `.exact` is used deliberately: these datasets are constructed, so there is
        // no acquisition noise for a looser tolerance to forgive.
        for spacing in [(2.0, 1.0), (0.5, 0.5), (1.0, 1.0)] {
            let frames = try axialSeries(rowSpacing: spacing.0, columnSpacing: spacing.1)
            let series = try #require(CTSeriesAssembler.assemble(frames).first)
            let assessment = CTGeometryValidator.assess(series, tolerance: .exact)
            #expect(assessment.verdict == .representable)
            #expect(assessment.findings.isEmpty)
        }
    }
}
