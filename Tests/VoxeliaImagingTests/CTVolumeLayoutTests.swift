// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaImaging

/// Verifies `ct-volume-layout/v1` against every frozen fixture of
/// `VOXELIA-ALG-0050`.
@Suite("CTVolumeLayout")
struct CTVolumeLayoutTests {
    private func format(_ type: ScalarType) throws -> ScalarFormat {
        try ScalarFormat(type: type, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func layout(
        rows: Int,
        columns: Int,
        slices: Int,
        type: ScalarType = .int16
    ) throws -> CTVolumeLayout {
        try CTVolumeLayout(
            rows: rows,
            columns: columns,
            sliceCount: slices,
            scalarFormat: try format(type)
        )
    }

    // MARK: - L1, L2: admitted volumes

    @Test("[Unit] L1 a typical 512 x 512 x 200 int16 volume")
    func l1Typical() throws {
        let volume = try layout(rows: 512, columns: 512, slices: 200)

        #expect(volume.samplesPerSlice == 262_144)
        #expect(volume.sampleCount == 52_428_800)
        #expect(volume.byteCount == 104_857_600)
        // The layout exactly covers the volume: no gaps, no overlap.
        #expect(
            volume.sampleOffset(sliceIndex: 199, row: 511, column: 511)
                == volume.sampleCount - 1
        )
    }

    @Test("[Unit] L2 the smallest possible volume")
    func l2Smallest() throws {
        let volume = try layout(rows: 1, columns: 1, slices: 1)

        #expect(volume.sampleCount == 1)
        #expect(volume.byteCount == 2)
        #expect(volume.sampleOffset(sliceIndex: 0, row: 0, column: 0) == 0)
        #expect(volume.sampleOffset(sliceIndex: 1, row: 0, column: 0) == nil)
    }

    // MARK: - L3, L4, L6: the overflow boundaries

    @Test("[Unit] L3 an overflowing sample count is refused")
    func l3SampleCountOverflow() throws {
        #expect(throws: CTVolumeLayoutError.sampleCountOverflow) {
            try layout(rows: Int.max, columns: 2, slices: 1)
        }
    }

    @Test("[Unit] L4 a representable sample count with an overflowing byte count")
    func l4ByteCountOverflow() throws {
        // Two bytes per sample: the sample count is exactly Int.max and the byte
        // count is not representable. An implementation that checked only the
        // sample count admits this.
        #expect(throws: CTVolumeLayoutError.byteCountOverflow) {
            try layout(rows: Int.max, columns: 1, slices: 1, type: .int16)
        }
    }

    @Test("[Unit] L6 the same extents at one byte per sample are admitted")
    func l6ByteCountBoundary() throws {
        let volume = try layout(rows: Int.max, columns: 1, slices: 1, type: .uint8)

        #expect(volume.sampleCount == Int.max)
        #expect(volume.byteCount == Int.max)
        #expect(
            volume.sampleOffset(sliceIndex: 0, row: Int.max - 1, column: 0)
                == Int.max - 1
        )
    }

    @Test("[Unit] L4 and L6 differ only in the scalar format's width")
    func byteCountRuleIsAboutWidth() throws {
        // The pair, asserted together, so the rule cannot be satisfied by
        // accident on one side alone.
        #expect(throws: CTVolumeLayoutError.byteCountOverflow) {
            try layout(rows: Int.max, columns: 1, slices: 1, type: .int16)
        }
        #expect(throws: Never.self) {
            try layout(rows: Int.max, columns: 1, slices: 1, type: .uint8)
        }
    }

    @Test(
        "A non-positive extent is refused by its own case",
        arguments: [
            (0, 5, 2, CTVolumeLayoutError.nonPositiveRowCount),
            (-1, 5, 2, CTVolumeLayoutError.nonPositiveRowCount),
            (3, 0, 2, CTVolumeLayoutError.nonPositiveColumnCount),
            (3, -1, 2, CTVolumeLayoutError.nonPositiveColumnCount),
            (3, 5, 0, CTVolumeLayoutError.nonPositiveSliceCount),
            (3, 5, -1, CTVolumeLayoutError.nonPositiveSliceCount),
        ]
    )
    func nonPositiveExtents(
        _ rows: Int,
        _ columns: Int,
        _ slices: Int,
        _ expected: CTVolumeLayoutError
    ) throws {
        #expect(throws: expected) {
            try layout(rows: rows, columns: columns, slices: slices)
        }
    }

    // MARK: - L5, L7: the index order

    @Test("[Unit] L5 a 3 x 5 x 2 volume reproduces the frozen offset table")
    func l5OffsetTable() throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2)
        #expect(volume.sampleCount == 30)
        #expect(volume.byteCount == 60)

        var table: [[Int]] = []
        for slice in 0..<2 {
            for row in 0..<3 {
                var line: [Int] = []
                for column in 0..<5 {
                    line.append(
                        try #require(
                            volume.sampleOffset(
                                sliceIndex: slice,
                                row: row,
                                column: column
                            )
                        )
                    )
                }
                table.append(line)
            }
        }

        #expect(
            table == [
                [0, 1, 2, 3, 4],
                [5, 6, 7, 8, 9],
                [10, 11, 12, 13, 14],
                [15, 16, 17, 18, 19],
                [20, 21, 22, 23, 24],
                [25, 26, 27, 28, 29],
            ]
        )
    }

    @Test("[Unit] L7 a row advances by columns, not by rows")
    func l7RowStride() throws {
        // For a 3-row, 5-column frame the correct offset is 5. An implementation
        // writing `row * rows` gives 3, and the two agree only when the frame is
        // square -- so every square fixture passes either way.
        let volume = try layout(rows: 3, columns: 5, slices: 2)
        #expect(volume.sampleOffset(sliceIndex: 0, row: 1, column: 0) == 5)
        #expect(volume.sampleOffset(sliceIndex: 0, row: 1, column: 0) != 3)
    }

    @Test("[Unit] A slice is one contiguous span, which is what direct-write needs")
    func sliceSpansAreContiguous() throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2)

        #expect(volume.sliceSampleOffset(0) == 0)
        #expect(volume.sliceSampleOffset(1) == 15)
        #expect(volume.sliceByteOffset(1) == 30)
        #expect(volume.sliceSampleOffset(2) == nil)
        // The span begins where the slice's first sample is.
        #expect(
            volume.sliceSampleOffset(1)
                == volume.sampleOffset(sliceIndex: 1, row: 0, column: 0)
        )
    }

    @Test("[Unit] Byte offsets scale sample offsets by the format's width")
    func byteOffsets() throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2)
        #expect(volume.byteOffset(sliceIndex: 1, row: 2, column: 4) == 58)
        #expect(volume.byteOffset(sliceIndex: 2, row: 0, column: 0) == nil)
    }

    // MARK: - L8: index admission

    @Test(
        "L8 an index at or beyond its extent is refused",
        arguments: [
            (1, 2, 4, true),
            (2, 0, 0, false),
            (0, 3, 0, false),
            (0, 0, 5, false),
            (-1, 0, 0, false),
            (0, -1, 0, false),
            (0, 0, -1, false),
        ]
    )
    func l8Bounds(_ slice: Int, _ row: Int, _ column: Int, _ admitted: Bool) throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2)
        #expect(
            volume.contains(sliceIndex: slice, row: row, column: column) == admitted
        )
        #expect(
            (volume.sampleOffset(sliceIndex: slice, row: row, column: column) != nil)
                == admitted
        )
    }

    // MARK: - CTFramePlacement

    private func frame(
        rows: Int = 3,
        columns: Int = 5,
        type: ScalarType = .int16
    ) throws -> CTFrameDescription {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let identifier = try SourceIdentity(
            namespace: "dicom",
            identifier: "f1",
            version: nil,
            contentID: nil
        )
        return try CTFrameDescription(
            sourceIdentity: identifier,
            seriesIdentity: identifier,
            rows: rows,
            columns: columns,
            scalarFormat: try format(type),
            photometricInterpretation: .monochrome2,
            rowSpacingMillimetres: 0.7,
            columnSpacingMillimetres: 0.8,
            rowDirection: try Vector3D(x: 1, y: 0, z: 0, coordinateSpace: space),
            columnDirection: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
            imagePosition: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
            frameOfReference: nil,
            rescaleSlope: 1.0,
            rescaleIntercept: -1024.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    @Test("[Unit] A placement admits a matching frame and exposes its span")
    func placementAdmitsMatchingFrame() throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2)
        let placement = try CTFramePlacement(
            frame: try frame(),
            sliceIndex: 1,
            layout: volume
        )

        #expect(placement.sliceIndex == 1)
        #expect(placement.sampleOffset == 15)
        #expect(placement.byteOffset == 30)
    }

    @Test("[Unit] A placement refuses a slice index out of range")
    func placementRefusesSliceIndex() throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2)
        for index in [-1, 2, 99] {
            #expect(throws: CTFramePlacementError.sliceIndexOutOfRange) {
                try CTFramePlacement(
                    frame: try frame(),
                    sliceIndex: index,
                    layout: volume
                )
            }
        }
    }

    @Test("[Unit] A placement refuses mismatched extents")
    func placementRefusesExtents() throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2)
        #expect(throws: CTFramePlacementError.extentsMismatch) {
            try CTFramePlacement(
                frame: try frame(rows: 4, columns: 5),
                sliceIndex: 0,
                layout: volume
            )
        }
        // Transposed extents are a mismatch too, not a silent reinterpretation.
        #expect(throws: CTFramePlacementError.extentsMismatch) {
            try CTFramePlacement(
                frame: try frame(rows: 5, columns: 3),
                sliceIndex: 0,
                layout: volume
            )
        }
    }

    @Test("[Unit] A placement refuses a mismatched scalar format")
    func placementRefusesFormat() throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2, type: .int16)
        #expect(throws: CTFramePlacementError.scalarFormatMismatch) {
            try CTFramePlacement(
                frame: try frame(type: .uint16),
                sliceIndex: 0,
                layout: volume
            )
        }
    }

    @Test("[Unit] Extent admission precedes format admission")
    func admissionOrder() throws {
        let volume = try layout(rows: 3, columns: 5, slices: 2, type: .int16)
        #expect(throws: CTFramePlacementError.extentsMismatch) {
            try CTFramePlacement(
                frame: try frame(rows: 4, columns: 5, type: .uint16),
                sliceIndex: 0,
                layout: volume
            )
        }
    }
}
