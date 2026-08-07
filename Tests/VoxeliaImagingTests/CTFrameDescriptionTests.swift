// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaImaging

@Suite("CTFrameDescription")
struct CTFrameDescriptionTests {
    private static let patientSpace = "patient"
    private static let otherSpace = "table"

    private func space(_ raw: String) throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: raw))
    }

    private func identity() throws -> SourceIdentity {
        try SourceIdentity(
            namespace: "dicom",
            identifier: "1.2.840.113619.2.55.3.1",
            version: nil,
            contentID: nil
        )
    }

    private func series() throws -> SourceIdentity {
        try SourceIdentity(
            namespace: "dicom",
            identifier: "1.2.840.113619.2.55.3.1.series",
            version: nil,
            contentID: nil
        )
    }

    private func format(_ type: ScalarType) throws -> ScalarFormat {
        try ScalarFormat(type: type, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func vector(
        _ x: Double,
        _ y: Double,
        _ z: Double,
        space raw: String = patientSpace
    ) throws -> Vector3D {
        try Vector3D(x: x, y: y, z: z, coordinateSpace: try space(raw))
    }

    private func point(
        _ x: Double,
        _ y: Double,
        _ z: Double,
        space raw: String = patientSpace
    ) throws -> Point3D {
        try Point3D(x: x, y: y, z: z, coordinateSpace: try space(raw))
    }

    /// Builds an admissible description, overriding one field per test.
    private func make(
        rows: Int = 512,
        columns: Int = 512,
        scalarType: ScalarType = .int16,
        interpretation: MonochromeInterpretation = .monochrome2,
        rowSpacing: Double = 0.7,
        columnSpacing: Double = 0.7,
        rowDirection: Vector3D? = nil,
        columnDirection: Vector3D? = nil,
        imagePosition: Point3D? = nil,
        frameOfReference: ExternalFrameReference? = nil,
        rescaleSlope: Double = 1.0,
        rescaleIntercept: Double = -1024.0,
        pixelPadding: PixelPaddingDescriptor? = nil
    ) throws -> CTFrameDescription {
        try CTFrameDescription(
            sourceIdentity: try identity(),
            seriesIdentity: try series(),
            rows: rows,
            columns: columns,
            scalarFormat: try format(scalarType),
            photometricInterpretation: interpretation,
            rowSpacingMillimetres: rowSpacing,
            columnSpacingMillimetres: columnSpacing,
            rowDirection: try rowDirection ?? vector(1, 0, 0),
            columnDirection: try columnDirection ?? vector(0, 1, 0),
            imagePosition: try imagePosition ?? point(-175.5, -175.5, 42.0),
            frameOfReference: frameOfReference,
            rescaleSlope: rescaleSlope,
            rescaleIntercept: rescaleIntercept,
            pixelPadding: pixelPadding,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    // MARK: - Acceptance

    @Test("[Unit] An admissible description preserves every supplied field")
    func preservesFields() throws {
        let reference = try ExternalFrameReference(
            namespace: "dicom",
            identifier: "1.2.840.10008.3.1.2.3.4"
        )
        let description = try make(
            rows: 512,
            columns: 384,
            interpretation: .monochrome1,
            rowSpacing: 0.7,
            columnSpacing: 0.9,
            frameOfReference: reference,
            rescaleSlope: 2.0,
            rescaleIntercept: -1024.0,
            pixelPadding: PixelPaddingDescriptor(value: -2000)
        )

        #expect(description.sourceIdentity == (try identity()))
        #expect(description.seriesIdentity == (try series()))
        #expect(description.rows == 512)
        #expect(description.columns == 384)
        #expect(description.photometricInterpretation == .monochrome1)
        #expect(description.rowSpacingMillimetres == 0.7)
        #expect(description.columnSpacingMillimetres == 0.9)
        #expect(description.frameOfReference == reference)
        #expect(description.rescaleSlope == 2.0)
        #expect(description.rescaleIntercept == -1024.0)
        #expect(description.pixelPadding == PixelPaddingDescriptor(value: -2000))
        #expect(description.sourceMetadata.entries.isEmpty)
        #expect(description.sampleCount == 196_608)
        #expect(description.coordinateSpace == (try space(Self.patientSpace)))
    }

    @Test("[Unit] A single-sample frame is admitted")
    func admitsSmallestFrame() throws {
        let description = try make(rows: 1, columns: 1)
        #expect(description.sampleCount == 1)
    }

    @Test("[Unit] An absent frame of reference and padding stay absent")
    func admitsAbsentOptionals() throws {
        let description = try make()
        #expect(description.frameOfReference == nil)
        #expect(description.pixelPadding == nil)
    }

    // MARK: - The transcription principle

    @Test("[Unit] Directions far from orthogonal are admitted, not judged")
    func admitsNonOrthogonalDirections() throws {
        let description = try make(
            rowDirection: try vector(1, 0, 0),
            columnDirection: try vector(0.5, 0.5, 0.0)
        )
        #expect(description.columnDirection == (try vector(0.5, 0.5, 0.0)))
    }

    @Test("[Unit] Directions that are not unit length are admitted, not normalised")
    func admitsNonUnitDirections() throws {
        let description = try make(rowDirection: try vector(3, 0, 0))
        #expect(description.rowDirection.x == 3)
    }

    @Test("[Unit] A zero rescale slope is admitted per ADR-0227 decision 5")
    func admitsZeroRescaleSlope() throws {
        let description = try make(rescaleSlope: 0.0)
        #expect(description.rescaleSlope == 0.0)
    }

    @Test("[Unit] A scalar format wider than the first vertical slice is admitted")
    func admitsUnnarrowedScalarFormat() throws {
        let description = try make(scalarType: .float32)
        #expect(description.scalarFormat.type == .float32)
    }

    // MARK: - Extent admission

    @Test(
        "[Unit] A non-positive extent is rejected by its own case",
        arguments: [
            (0, 512, CTFrameDescriptionError.nonPositiveRowCount),
            (-1, 512, CTFrameDescriptionError.nonPositiveRowCount),
            (512, 0, CTFrameDescriptionError.nonPositiveColumnCount),
            (512, -1, CTFrameDescriptionError.nonPositiveColumnCount),
        ]
    )
    func rejectsNonPositiveExtents(
        rows: Int,
        columns: Int,
        expected: CTFrameDescriptionError
    ) throws {
        #expect(throws: expected) {
            try make(rows: rows, columns: columns)
        }
    }

    @Test("[Unit] Extents whose product overflows are rejected")
    func rejectsSampleCountOverflow() throws {
        #expect(throws: CTFrameDescriptionError.sampleCountOverflow) {
            try make(rows: Int.max, columns: 2)
        }
    }

    @Test("[Unit] The largest non-overflowing product is admitted")
    func admitsBoundaryProduct() throws {
        let description = try make(rows: Int.max, columns: 1)
        #expect(description.sampleCount == Int.max)
    }

    // MARK: - Spacing admission

    @Test(
        "[Unit] A row spacing that is not positive and finite is rejected",
        arguments: [0.0, -0.7, Double.infinity, -Double.infinity, Double.nan]
    )
    func rejectsRowSpacing(_ spacing: Double) throws {
        #expect(throws: CTFrameDescriptionError.rowSpacingNotPositiveFinite) {
            try make(rowSpacing: spacing)
        }
    }

    @Test(
        "[Unit] A column spacing that is not positive and finite is rejected",
        arguments: [0.0, -0.7, Double.infinity, -Double.infinity, Double.nan]
    )
    func rejectsColumnSpacing(_ spacing: Double) throws {
        #expect(throws: CTFrameDescriptionError.columnSpacingNotPositiveFinite) {
            try make(columnSpacing: spacing)
        }
    }

    @Test("[Unit] The smallest positive spacing is admitted")
    func admitsSubnormalSpacing() throws {
        let description = try make(rowSpacing: Double.leastNonzeroMagnitude)
        #expect(description.rowSpacingMillimetres == Double.leastNonzeroMagnitude)
    }

    // MARK: - Direction admission

    @Test("[Unit] An exactly zero row direction is rejected")
    func rejectsZeroRowDirection() throws {
        #expect(throws: CTFrameDescriptionError.zeroRowDirection) {
            try make(rowDirection: try vector(0, 0, 0))
        }
    }

    @Test("[Unit] An exactly zero column direction is rejected")
    func rejectsZeroColumnDirection() throws {
        #expect(throws: CTFrameDescriptionError.zeroColumnDirection) {
            try make(columnDirection: try vector(0, 0, 0))
        }
    }

    @Test("[Unit] A negative zero direction is rejected, since it canonicalises to zero")
    func rejectsNegativeZeroDirection() throws {
        #expect(throws: CTFrameDescriptionError.zeroRowDirection) {
            try make(rowDirection: try vector(-0.0, -0.0, -0.0))
        }
    }

    @Test("[Unit] A direction with one subnormal component is admitted")
    func admitsSubnormalDirection() throws {
        let description = try make(
            rowDirection: try vector(0, 0, Double.leastNonzeroMagnitude)
        )
        #expect(description.rowDirection.z == Double.leastNonzeroMagnitude)
    }

    // MARK: - Coordinate space admission

    @Test("[Unit] A row direction in another space is rejected")
    func rejectsRowDirectionSpace() throws {
        #expect(throws: CTFrameDescriptionError.coordinateSpaceMismatch) {
            try make(rowDirection: try vector(1, 0, 0, space: Self.otherSpace))
        }
    }

    @Test("[Unit] A column direction in another space is rejected")
    func rejectsColumnDirectionSpace() throws {
        #expect(throws: CTFrameDescriptionError.coordinateSpaceMismatch) {
            try make(columnDirection: try vector(0, 1, 0, space: Self.otherSpace))
        }
    }

    @Test("[Unit] A description entirely in another space is admitted")
    func admitsAlternativeSharedSpace() throws {
        let description = try make(
            rowDirection: try vector(1, 0, 0, space: Self.otherSpace),
            columnDirection: try vector(0, 1, 0, space: Self.otherSpace),
            imagePosition: try point(0, 0, 0, space: Self.otherSpace)
        )
        #expect(description.coordinateSpace == (try space(Self.otherSpace)))
    }

    // MARK: - Rescale admission

    @Test(
        "[Unit] A non-finite rescale slope is rejected",
        arguments: [Double.infinity, -Double.infinity, Double.nan]
    )
    func rejectsNonFiniteSlope(_ slope: Double) throws {
        #expect(throws: CTFrameDescriptionError.rescaleSlopeNotFinite) {
            try make(rescaleSlope: slope)
        }
    }

    @Test(
        "[Unit] A non-finite rescale intercept is rejected",
        arguments: [Double.infinity, -Double.infinity, Double.nan]
    )
    func rejectsNonFiniteIntercept(_ intercept: Double) throws {
        #expect(throws: CTFrameDescriptionError.rescaleInterceptNotFinite) {
            try make(rescaleIntercept: intercept)
        }
    }

    // MARK: - Pixel padding admission

    @Test(
        "[Unit] A padding value outside the declared container is rejected",
        arguments: [
            (ScalarType.int16, Int64(32_768)),
            (ScalarType.int16, Int64(-32_769)),
            (ScalarType.uint16, Int64(-1)),
            (ScalarType.uint16, Int64(65_536)),
            (ScalarType.uint8, Int64(256)),
        ]
    )
    func rejectsPaddingOutsideFormat(_ type: ScalarType, _ value: Int64) throws {
        #expect(throws: CTFrameDescriptionError.pixelPaddingNotRepresentable) {
            try make(scalarType: type, pixelPadding: PixelPaddingDescriptor(value: value))
        }
    }

    @Test(
        "[Unit] A padding value at a container boundary is admitted",
        arguments: [
            (ScalarType.int16, Int64(32_767)),
            (ScalarType.int16, Int64(-32_768)),
            (ScalarType.uint16, Int64(0)),
            (ScalarType.uint16, Int64(65_535)),
        ]
    )
    func admitsPaddingAtBoundary(_ type: ScalarType, _ value: Int64) throws {
        let description = try make(
            scalarType: type,
            pixelPadding: PixelPaddingDescriptor(value: value)
        )
        #expect(description.pixelPadding?.value == value)
    }

    @Test("[Unit] A padding value beyond exact double precision is rejected for float32")
    func rejectsInexactFloatPadding() throws {
        // Inside `Float.greatestFiniteMagnitude`, but not exactly representable
        // as a `Double`, so containment alone would have admitted it.
        #expect(throws: CTFrameDescriptionError.pixelPaddingNotRepresentable) {
            try make(
                scalarType: .float32,
                pixelPadding: PixelPaddingDescriptor(value: (1 << 53) + 1)
            )
        }
    }

    @Test("[Unit] A padding value beyond a narrower float range is rejected")
    func rejectsPaddingBeyondFloat16() throws {
        #expect(throws: CTFrameDescriptionError.pixelPaddingNotRepresentable) {
            try make(
                scalarType: .float16,
                pixelPadding: PixelPaddingDescriptor(value: 100_000)
            )
        }
    }

    @Test("[Unit] A padding value representable as a uint64 is admitted")
    func admitsWidePadding() throws {
        let description = try make(
            scalarType: .uint64,
            pixelPadding: PixelPaddingDescriptor(value: Int64.max)
        )
        #expect(description.pixelPadding?.value == Int64.max)
    }

    // MARK: - Rule ordering

    @Test("[Unit] Extent admission precedes spacing admission")
    func extentPrecedesSpacing() throws {
        #expect(throws: CTFrameDescriptionError.nonPositiveRowCount) {
            try make(rows: 0, rowSpacing: -1.0)
        }
    }

    @Test("[Unit] Direction admission precedes coordinate-space admission")
    func directionPrecedesSpace() throws {
        #expect(throws: CTFrameDescriptionError.zeroRowDirection) {
            try make(rowDirection: try vector(0, 0, 0, space: Self.otherSpace))
        }
    }

    // MARK: - Supporting types

    @Test("[Unit] Every monochrome interpretation round-trips through its raw value")
    func monochromeRawValues() throws {
        #expect(MonochromeInterpretation.allCases.count == 2)
        for interpretation in MonochromeInterpretation.allCases {
            #expect(
                MonochromeInterpretation(rawValue: interpretation.rawValue) == interpretation
            )
        }
    }

    @Test("[Unit] Descriptions with differing fields are unequal")
    func equalityDistinguishesFields() throws {
        let base = try make()
        #expect(try base == make())
        #expect(try base != make(rows: 256))
        #expect(try base != make(interpretation: .monochrome1))
        #expect(try base != make(rescaleIntercept: 0.0))
    }
}
