// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaImaging

@Suite("CTVolumeStorageBuilder")
struct CTVolumeStorageBuilderTests {
    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func format(_ type: ScalarType = .uint16) throws -> ScalarFormat {
        try ScalarFormat(type: type, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func frame(
        rows: Int,
        columns: Int,
        type: ScalarType = .uint16
    ) throws -> CTFrameDescription {
        let coordinateSpace = try space()
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
            rowDirection: try Vector3D(x: 1, y: 0, z: 0, coordinateSpace: coordinateSpace),
            columnDirection: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: coordinateSpace),
            imagePosition: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: coordinateSpace),
            frameOfReference: nil,
            rescaleSlope: 1.0,
            rescaleIntercept: -8192.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    private func geometry() throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: [
                0.8, 0, 0, 0,
                0, 0.7, 0, 0,
                0, 0, 2.5, 0,
                0, 0, 0, 1,
            ]),
            coordinateSpace: try CoordinateSpaceDescriptor(
                id: try space(),
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
        )
    }

    /// A complete 3x2x2 uint16 volume, and its descriptor.
    private func filled(
        rows: Int = 3,
        columns: Int = 2,
        slices: Int = 2,
        type: ScalarType = .uint16,
        fillEverySlice: Bool = true
    ) throws -> (CTVolumeByteBuffer, ImageDescriptor) {
        let anchor = try frame(rows: rows, columns: columns, type: type)
        let layout = try CTVolumeLayout(
            rows: rows,
            columns: columns,
            sliceCount: slices,
            scalarFormat: try format(type)
        )
        var buffer = CTVolumeByteBuffer(layout: layout)
        let sliceBytes = buffer.bytesPerSlice
        let upper = fillEverySlice ? slices : slices - 1
        for index in 0..<upper {
            try buffer.write(
                frameBytes: ContiguousArray<UInt8>(
                    repeating: UInt8(index + 1),
                    count: sliceBytes
                ),
                at: try CTFramePlacement(frame: anchor, sliceIndex: index, layout: layout)
            )
        }
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: anchor,
            layout: layout,
            geometry: try geometry()
        )
        return (buffer, descriptor)
    }

    // MARK: - The happy path

    @Test("A complete volume binds to storage whose snapshot matches the descriptor")
    func bindsCompleteVolume() throws {
        let (buffer, descriptor) = try filled()
        let storage = try CTVolumeStorageBuilder.storage(
            buffer: buffer,
            descriptor: descriptor
        )

        let binding = storage.snapshot.binding
        #expect(binding.shape == descriptor.shape)
        #expect(binding.scalarType == descriptor.scalarFormat.type)
        #expect(binding.componentCount == descriptor.components.count)
        #expect(binding.logicalByteCount == buffer.bytes.count)
        // 2 columns x 3 rows x 2 slices x 2 bytes.
        #expect(buffer.bytes.count == 24)
    }

    @Test("The bound storage composes into a validated ImageData shape check")
    func satisfiesImageDataShapeInvariants() throws {
        // ImageData's admission compares the descriptor against the snapshot
        // binding, so agreement here is what makes publication possible later.
        let (buffer, descriptor) = try filled()
        let storage = try CTVolumeStorageBuilder.storage(
            buffer: buffer,
            descriptor: descriptor
        )
        #expect(descriptor.shape == storage.snapshot.binding.shape)
        #expect(descriptor.scalarFormat.type == storage.snapshot.binding.scalarType)
        #expect(
            descriptor.components.count == storage.snapshot.binding.componentCount
        )
    }

    @Test("A read of the whole volume returns the transferred bytes")
    func readsBackBytes() throws {
        let (buffer, descriptor) = try filled()
        let storage = try CTVolumeStorageBuilder.storage(
            buffer: buffer,
            descriptor: descriptor
        )
        let region = try ImageRegion(
            lowerBounds: [0, 0, 0],
            extents: descriptor.shape
        )
        let result = try storage.read(region: region)
        #expect(result.bytes.count == buffer.bytes.count)
        #expect(Array(result.bytes) == Array(buffer.bytes))
    }

    // MARK: - Admission

    @Test("An incomplete volume is refused rather than published with gaps")
    func refusesIncompleteVolume() throws {
        let (buffer, descriptor) = try filled(fillEverySlice: false)
        #expect(!buffer.isComplete)
        // The missing slice would read as zeros -- plausible bytes, wrong volume.
        #expect(throws: CTVolumeStorageError.incompleteVolume) {
            try CTVolumeStorageBuilder.storage(buffer: buffer, descriptor: descriptor)
        }
    }

    @Test("A descriptor from a different volume is refused")
    func refusesMismatchedDescriptor() throws {
        let (buffer, _) = try filled(rows: 3, columns: 2, slices: 2)
        let (_, otherDescriptor) = try filled(rows: 3, columns: 2, slices: 4)
        #expect(throws: CTVolumeStorageError.descriptorBufferMismatch) {
            try CTVolumeStorageBuilder.storage(
                buffer: buffer,
                descriptor: otherDescriptor
            )
        }
    }

    @Test("A descriptor with a wider scalar type is refused")
    func refusesWiderScalarType() throws {
        let (buffer, _) = try filled(type: .uint8)
        let (_, wideDescriptor) = try filled(type: .uint16)
        // Same extents, twice the bytes: the byte-count check catches it.
        #expect(throws: CTVolumeStorageError.descriptorBufferMismatch) {
            try CTVolumeStorageBuilder.storage(
                buffer: buffer,
                descriptor: wideDescriptor
            )
        }
    }

    @Test("A single-slice volume binds, since one slice is the whole volume")
    func singleSliceVolume() throws {
        let (buffer, descriptor) = try filled(slices: 1)
        #expect(buffer.isComplete)
        let storage = try CTVolumeStorageBuilder.storage(
            buffer: buffer,
            descriptor: descriptor
        )
        #expect(storage.snapshot.binding.shape.extents == [2, 3, 1])
    }
}
