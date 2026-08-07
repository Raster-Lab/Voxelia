// SPDX-License-Identifier: MIT

import DICOMCore
import DICOMKit
import Foundation
import Testing
import VoxeliaCore
import VoxeliaImaging
import VoxeliaSpatial

@testable import VoxeliaDICOMKit

@Suite("DICOMFrameTransfer")
struct DICOMFrameTransferTests {
    private func element(
        _ tag: DICOMCore.Tag,
        _ vr: VR,
        _ value: String
    ) -> DataElement {
        let padded = value.utf8.count % 2 == 0 ? value : value + " "
        let data = Data(padded.utf8)
        return DataElement(tag: tag, vr: vr, length: UInt32(data.count), valueData: data)
    }

    /// Two explicit little-endian bytes; see `ADR-0287`.
    private func unsigned16(_ tag: DICOMCore.Tag, _ value: UInt16) -> DataElement {
        let data = Data([
            UInt8(truncatingIfNeeded: value),
            UInt8(truncatingIfNeeded: value >> 8),
        ])
        return DataElement(tag: tag, vr: .US, length: 2, valueData: data)
    }

    /// A 2x3 int16 CT frame whose sample bytes are a recognisable ramp.
    private func dataSet(payload: [UInt8]) -> DataSet {
        var elements: [DataElement] = [
            element(DICOMCore.Tag(group: 0x0008, element: 0x0018), .UI, "1.2.840.instance.1"),
            element(DICOMCore.Tag(group: 0x0020, element: 0x000E), .UI, "1.2.840.series.A"),
            element(DICOMCore.Tag(group: 0x0020, element: 0x0032), .DS, "0\\0\\0"),
            element(DICOMCore.Tag(group: 0x0020, element: 0x0037), .DS, "1\\0\\0\\0\\1\\0"),
            element(DICOMCore.Tag(group: 0x0028, element: 0x0004), .CS, "MONOCHROME2"),
            unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0010), 2),
            unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0011), 3),
            element(DICOMCore.Tag(group: 0x0028, element: 0x0030), .DS, "0.7\\0.8"),
            unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0100), 16),
            // Bits Stored and High Bit are required by DICOMKit's pixel-data
            // descriptor even though this adapter does not read High Bit. Real CT
            // files carry both; the first version of this fixture omitted them
            // and pixelData() returned nil, which is a fair reminder that a
            // hand-built fixture is only as complete as its author remembered.
            unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0101), 16),
            unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0102), 15),
            unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0103), 1),
        ]
        let pixels = Data(payload)
        elements.append(
            DataElement(
                tag: DICOMCore.Tag(group: 0x7FE0, element: 0x0010),
                vr: .OW,
                length: UInt32(pixels.count),
                valueData: pixels
            )
        )
        return DataSet(elements: elements)
    }

    private func context() throws -> (CTFrameDescription, CTVolumeLayout) {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let frame = try DICOMFrameAdapter.frameDescription(
            from: dataSet(payload: Array(repeating: 0, count: 12)),
            coordinateSpace: space
        )
        let layout = try CTVolumeLayout(
            rows: frame.rows,
            columns: frame.columns,
            sliceCount: 2,
            scalarFormat: frame.scalarFormat
        )
        return (frame, layout)
    }

    @Test("[Unit] A frame's sample bytes land in its slice, byte for byte")
    func transfersBytes() throws {
        let (frame, layout) = try context()
        var buffer = CTVolumeByteBuffer(layout: layout)
        let payload: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        let placement = try CTFramePlacement(frame: frame, sliceIndex: 1, layout: layout)

        try DICOMFrameTransfer.transfer(
            from: dataSet(payload: payload),
            to: placement,
            in: &buffer
        )

        // Byte-level: no endianness or signedness interpretation happened.
        #expect(Array(try #require(buffer.sliceBytes(1))) == payload)
        #expect(Array(try #require(buffer.sliceBytes(0))) == Array(repeating: 0, count: 12))
        #expect(buffer.writtenSlices == [1])
        #expect(!buffer.isComplete)
    }

    @Test("[Unit] Filling every slice completes the volume")
    func fillsVolume() throws {
        let (frame, layout) = try context()
        var buffer = CTVolumeByteBuffer(layout: layout)
        for index in 0..<layout.sliceCount {
            let payload = [UInt8](repeating: UInt8(index + 1), count: 12)
            try DICOMFrameTransfer.transfer(
                from: dataSet(payload: payload),
                to: try CTFramePlacement(frame: frame, sliceIndex: index, layout: layout),
                in: &buffer
            )
        }
        #expect(buffer.isComplete)
        #expect(Array(try #require(buffer.sliceBytes(0))) == Array(repeating: 1, count: 12))
        #expect(Array(try #require(buffer.sliceBytes(1))) == Array(repeating: 2, count: 12))
    }

    @Test("[Unit] A data set without pixel data is refused")
    func missingPixelData() throws {
        let (frame, layout) = try context()
        var buffer = CTVolumeByteBuffer(layout: layout)
        let bare = DataSet(elements: [
            element(DICOMCore.Tag(group: 0x0008, element: 0x0018), .UI, "1.2.840.instance.1")
        ])
        #expect(throws: DICOMFrameTransferError.missingPixelData) {
            try DICOMFrameTransfer.transfer(
                from: bare,
                to: try CTFramePlacement(frame: frame, sliceIndex: 0, layout: layout),
                in: &buffer
            )
        }
    }

    @Test("[Unit] A frame index beyond the pixel data is refused")
    func missingFrame() throws {
        let (frame, layout) = try context()
        var buffer = CTVolumeByteBuffer(layout: layout)
        #expect(throws: DICOMFrameTransferError.missingFrame) {
            try DICOMFrameTransfer.transfer(
                from: dataSet(payload: [UInt8](repeating: 7, count: 12)),
                frameIndex: 5,
                to: try CTFramePlacement(frame: frame, sliceIndex: 0, layout: layout),
                in: &buffer
            )
        }
    }

    @Test("[Unit] A truncated pixel payload is caught by DICOMKit, before Voxelia sees it")
    func truncatedPayload() throws {
        let (frame, layout) = try context()
        var buffer = CTVolumeByteBuffer(layout: layout)
        // Eight bytes where a 2x3 int16 frame needs twelve. This was expected to
        // reach Voxelia's volume admission; it does not. DICOMKit's own frame
        // bounds check refuses it first, which is the better outcome and makes
        // rejectedByVolumeAdmission harder to reach than assumed.
        #expect(throws: DICOMFrameTransferError.missingFrame) {
            try DICOMFrameTransfer.transfer(
                from: dataSet(payload: [UInt8](repeating: 3, count: 8)),
                to: try CTFramePlacement(frame: frame, sliceIndex: 0, layout: layout),
                in: &buffer
            )
        }
        #expect(buffer.writtenSliceCount == 0)
    }

    @Test("[Unit] A placement from another layout is refused by volume admission")
    func layoutMismatchIsRefused() throws {
        let (frame, layout) = try context()
        var buffer = CTVolumeByteBuffer(layout: layout)
        // Valid pixel data, and a placement admitted against a different volume.
        // This is the reachable route to rejectedByVolumeAdmission.
        let other = try CTVolumeLayout(
            rows: frame.rows,
            columns: frame.columns,
            sliceCount: 5,
            scalarFormat: frame.scalarFormat
        )
        #expect(throws: DICOMFrameTransferError.rejectedByVolumeAdmission) {
            try DICOMFrameTransfer.transfer(
                from: dataSet(payload: [UInt8](repeating: 3, count: 12)),
                to: try CTFramePlacement(frame: frame, sliceIndex: 0, layout: other),
                in: &buffer
            )
        }
        #expect(buffer.writtenSliceCount == 0)
    }
}
