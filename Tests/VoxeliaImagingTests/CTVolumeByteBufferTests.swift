// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaImaging

@Suite("CTVolumeByteBuffer")
struct CTVolumeByteBufferTests {
    private func format(_ type: ScalarType = .int16) throws -> ScalarFormat {
        try ScalarFormat(type: type, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func layout(
        rows: Int = 2,
        columns: Int = 3,
        slices: Int = 2,
        type: ScalarType = .int16
    ) throws -> CTVolumeLayout {
        try CTVolumeLayout(
            rows: rows,
            columns: columns,
            sliceCount: slices,
            scalarFormat: try format(type)
        )
    }

    private func frame(
        _ layout: CTVolumeLayout,
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
            rows: layout.rows,
            columns: layout.columns,
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

    @Test("[Unit] A new buffer is zero-filled, sized from the layout, and incomplete")
    func newBuffer() throws {
        let volume = try layout()
        let buffer = CTVolumeByteBuffer(layout: volume)

        #expect(buffer.bytes.count == volume.byteCount)
        #expect(buffer.bytes.count == 24)
        #expect(buffer.bytesPerSlice == 12)
        #expect(buffer.bytes.allSatisfy { $0 == 0 })
        #expect(buffer.writtenSliceCount == 0)
        #expect(!buffer.isComplete)
    }

    @Test("[Unit] Writing a frame places its bytes at exactly the layout's offset")
    func writePlacesBytes() throws {
        let volume = try layout()
        var buffer = CTVolumeByteBuffer(layout: volume)
        let placement = try CTFramePlacement(
            frame: try frame(volume),
            sliceIndex: 1,
            layout: volume
        )
        let payload = ContiguousArray<UInt8>(1...12)

        try buffer.write(frameBytes: payload, at: placement)

        #expect(buffer.writtenSlices == [1])
        #expect(!buffer.isComplete)
        // Slice 1 begins at byte 12 and holds the payload; slice 0 stays zero.
        #expect(Array(try #require(buffer.sliceBytes(1))) == Array(payload))
        #expect(Array(try #require(buffer.sliceBytes(0))) == Array(repeating: 0, count: 12))
    }

    @Test("[Unit] Filling every slice reports completeness")
    func completeness() throws {
        let volume = try layout()
        var buffer = CTVolumeByteBuffer(layout: volume)
        for index in 0..<volume.sliceCount {
            let placement = try CTFramePlacement(
                frame: try frame(volume),
                sliceIndex: index,
                layout: volume
            )
            try buffer.write(
                frameBytes: ContiguousArray<UInt8>(repeating: UInt8(index + 1), count: 12),
                at: placement
            )
        }
        #expect(buffer.writtenSliceCount == 2)
        #expect(buffer.isComplete)
        #expect(Array(try #require(buffer.sliceBytes(0))) == Array(repeating: 1, count: 12))
        #expect(Array(try #require(buffer.sliceBytes(1))) == Array(repeating: 2, count: 12))
    }

    @Test("[Unit] Re-writing a slice overwrites and is not an error")
    func rewriteOverwrites() throws {
        let volume = try layout()
        var buffer = CTVolumeByteBuffer(layout: volume)
        let placement = try CTFramePlacement(
            frame: try frame(volume),
            sliceIndex: 0,
            layout: volume
        )
        try buffer.write(frameBytes: ContiguousArray<UInt8>(repeating: 9, count: 12), at: placement)
        try buffer.write(frameBytes: ContiguousArray<UInt8>(repeating: 4, count: 12), at: placement)

        #expect(buffer.writtenSlices == [0])
        #expect(Array(try #require(buffer.sliceBytes(0))) == Array(repeating: 4, count: 12))
    }

    @Test("[Unit] A wrong frame byte count is refused")
    func wrongByteCount() throws {
        let volume = try layout()
        var buffer = CTVolumeByteBuffer(layout: volume)
        let placement = try CTFramePlacement(
            frame: try frame(volume),
            sliceIndex: 0,
            layout: volume
        )
        for count in [0, 11, 13, 24] {
            #expect(throws: CTVolumeByteBufferError.frameByteCountMismatch) {
                try buffer.write(
                    frameBytes: ContiguousArray<UInt8>(repeating: 1, count: count),
                    at: placement
                )
            }
        }
        #expect(buffer.writtenSliceCount == 0)
    }

    @Test("[Unit] A placement from another layout is refused")
    func layoutMismatch() throws {
        let volume = try layout()
        let other = try layout(slices: 3)
        var buffer = CTVolumeByteBuffer(layout: volume)
        let placement = try CTFramePlacement(
            frame: try frame(other),
            sliceIndex: 0,
            layout: other
        )
        #expect(throws: CTVolumeByteBufferError.layoutMismatch) {
            try buffer.write(
                frameBytes: ContiguousArray<UInt8>(repeating: 1, count: 12),
                at: placement
            )
        }
    }

    @Test("[Unit] A differing scalar format is a layout mismatch, not a silent reinterpretation")
    func scalarFormatIsPartOfTheLayout() throws {
        let volume = try layout(type: .int16)
        let other = try layout(type: .uint16)
        var buffer = CTVolumeByteBuffer(layout: volume)
        let placement = try CTFramePlacement(
            frame: try frame(other, type: .uint16),
            sliceIndex: 0,
            layout: other
        )
        #expect(throws: CTVolumeByteBufferError.layoutMismatch) {
            try buffer.write(
                frameBytes: ContiguousArray<UInt8>(repeating: 1, count: 12),
                at: placement
            )
        }
    }

    @Test("[Unit] A single-byte format halves the slice size")
    func singleByteFormat() throws {
        let volume = try layout(type: .uint8)
        var buffer = CTVolumeByteBuffer(layout: volume)
        #expect(buffer.bytes.count == 12)
        #expect(buffer.bytesPerSlice == 6)
        let placement = try CTFramePlacement(
            frame: try frame(volume, type: .uint8),
            sliceIndex: 1,
            layout: volume
        )
        try buffer.write(frameBytes: ContiguousArray<UInt8>(1...6), at: placement)
        #expect(Array(try #require(buffer.sliceBytes(1))) == [1, 2, 3, 4, 5, 6])
    }

    @Test("[Unit] Slice bytes are absent for an out-of-range index")
    func sliceBytesBounds() throws {
        let buffer = CTVolumeByteBuffer(layout: try layout())
        #expect(buffer.sliceBytes(0) != nil)
        #expect(buffer.sliceBytes(1) != nil)
        #expect(buffer.sliceBytes(2) == nil)
        #expect(buffer.sliceBytes(-1) == nil)
    }
}
