// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaImaging

@Suite("CTVolumeDescriptorBuilder")
struct CTVolumeDescriptorBuilderTests {
    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func format(_ type: ScalarType = .uint16, _ bits: Int? = nil) throws
        -> ScalarFormat
    {
        try ScalarFormat(type: type, validBitCount: bits, byteOrder: .littleEndian)
    }

    private func frame(
        rows: Int = 512,
        columns: Int = 384,
        type: ScalarType = .uint16,
        storedBits: Int? = nil,
        slope: Double = 1.0,
        intercept: Double = -8192.0
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
            scalarFormat: try format(type, storedBits),
            photometricInterpretation: .monochrome2,
            rowSpacingMillimetres: 0.7,
            columnSpacingMillimetres: 0.8,
            rowDirection: try Vector3D(x: 1, y: 0, z: 0, coordinateSpace: coordinateSpace),
            columnDirection: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: coordinateSpace),
            imagePosition: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: coordinateSpace),
            frameOfReference: nil,
            rescaleSlope: slope,
            rescaleIntercept: intercept,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    private func geometry(axes: [Int] = [0, 1, 2]) throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: axes),
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

    private func layout(
        rows: Int = 512,
        columns: Int = 384,
        slices: Int = 40,
        type: ScalarType = .uint16,
        storedBits: Int? = nil
    ) throws -> CTVolumeLayout {
        try CTVolumeLayout(
            rows: rows,
            columns: columns,
            sliceCount: slices,
            scalarFormat: try format(type, storedBits)
        )
    }

    // MARK: - The shape and axis order

    @Test("Axis 0 is the column index, so extents are columns, rows, slices")
    func axisOrder() throws {
        // Distinct extents in all three, so a transposition changes an assertion.
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(rows: 512, columns: 384),
            layout: try layout(rows: 512, columns: 384, slices: 40),
            geometry: try geometry()
        )

        #expect(descriptor.shape.extents == [384, 512, 40])
        #expect(descriptor.shape.rank == 3)
        #expect(descriptor.axes.map(\.id.rawValue) == ["column", "row", "slice"])
        #expect(descriptor.axes.map(\.semantic) == [.spatialX, .spatialY, .spatialZ])
    }

    @Test("Axis sampling is index-only, because the affine carries the spacing")
    func axisSamplingIsIndexOnly() throws {
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(),
            layout: try layout(),
            geometry: try geometry()
        )
        // Declaring a regular sampling too would state one fact twice.
        #expect(descriptor.axes.allSatisfy { $0.sampling == .indexOnly })
        #expect(descriptor.axes.allSatisfy { $0.unit == nil })
    }

    // MARK: - The geometry and value transform slots

    @Test("The affine geometry is carried in the descriptor's own slot")
    func carriesGeometry() throws {
        let built = try geometry()
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(),
            layout: try layout(),
            geometry: built
        )
        guard case .affine(let affine) = try #require(descriptor.spatialGeometry) else {
            Issue.record("expected an affine geometry")
            return
        }
        #expect(affine == built)
    }

    @Test("The rescale becomes a linear value transform")
    func carriesRescale() throws {
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(slope: 1.0, intercept: -8192.0),
            layout: try layout(),
            geometry: try geometry()
        )
        guard case .linear(let linear) = try #require(descriptor.valueTransform) else {
            Issue.record("expected a linear transform")
            return
        }
        #expect(linear.scale == 1.0)
        #expect(linear.offset == -8192.0)
    }

    @Test("A non-unit slope is carried faithfully")
    func nonUnitSlope() throws {
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(slope: 2.5, intercept: -1024.0),
            layout: try layout(),
            geometry: try geometry()
        )
        guard case .linear(let linear) = try #require(descriptor.valueTransform) else {
            Issue.record("expected a linear transform")
            return
        }
        #expect(linear.scale == 2.5)
        #expect(linear.offset == -1024.0)
    }

    @Test("A unit slope with a zero intercept is published as identity")
    func identityTransform() throws {
        // VOXELIA-ALG-0003 states scale 1, offset 0 is bit-identical to no
        // mapping, so the two declarations are equivalent and identity spares
        // every consumer a multiplication that cannot change a value.
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(slope: 1.0, intercept: 0.0),
            layout: try layout(),
            geometry: try geometry()
        )
        #expect(descriptor.valueTransform == .identity)
    }

    @Test("The transform helper agrees at the identity boundary")
    func transformHelper() throws {
        #expect(try CTVolumeDescriptorBuilder.valueTransform(slope: 1, intercept: 0) == .identity)
        // A hair off unity is linear, not identity.
        guard
            case .linear = try CTVolumeDescriptorBuilder.valueTransform(
                slope: 1.0.nextUp,
                intercept: 0
            )
        else {
            Issue.record("expected linear")
            return
        }
        guard
            case .linear = try CTVolumeDescriptorBuilder.valueTransform(
                slope: 1,
                intercept: 1e-300
            )
        else {
            Issue.record("expected linear")
            return
        }
    }

    // MARK: - ADR-0239: the published format drops the narrowing

    @Test("A narrowed stored-bit count is not published, because normalisation removes it")
    func publishesNormalisedFormat() throws {
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(type: .int16, storedBits: 12),
            layout: try layout(type: .int16, storedBits: 12),
            geometry: try geometry()
        )
        // ADR-0239: declaring nil is truthful only because the samples were
        // normalised to full-width containers.
        #expect(descriptor.scalarFormat.validBitCount == nil)
        #expect(descriptor.scalarFormat.type == .int16)
    }

    @Test("A full-width format is published unchanged")
    func fullWidthFormat() throws {
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(type: .uint16),
            layout: try layout(type: .uint16),
            geometry: try geometry()
        )
        #expect(descriptor.scalarFormat.validBitCount == nil)
        #expect(descriptor.scalarFormat.type == .uint16)
    }

    // MARK: - Semantics and components

    @Test("A CT volume is scalar intensity with one interleaved component")
    func semanticsAndComponents() throws {
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(),
            layout: try layout(),
            geometry: try geometry()
        )
        #expect(descriptor.semantic == .intensity)
        #expect(descriptor.components.count == 1)
        #expect(descriptor.components.interpretation == .scalar)
        #expect(descriptor.components.layout == .interleaved)
    }

    // MARK: - Admission

    @Test("A frame whose extents disagree with the layout is refused")
    func refusesExtentMismatch() throws {
        #expect(throws: CTVolumeDescriptorError.frameLayoutMismatch) {
            try CTVolumeDescriptorBuilder.descriptor(
                frame: try frame(rows: 256, columns: 384),
                layout: try layout(rows: 512, columns: 384),
                geometry: try geometry()
            )
        }
        // Transposed extents are a mismatch, not a reinterpretation.
        #expect(throws: CTVolumeDescriptorError.frameLayoutMismatch) {
            try CTVolumeDescriptorBuilder.descriptor(
                frame: try frame(rows: 384, columns: 512),
                layout: try layout(rows: 512, columns: 384),
                geometry: try geometry()
            )
        }
    }

    @Test("A frame whose scalar format disagrees with the layout is refused")
    func refusesFormatMismatch() throws {
        #expect(throws: CTVolumeDescriptorError.frameLayoutMismatch) {
            try CTVolumeDescriptorBuilder.descriptor(
                frame: try frame(type: .int16),
                layout: try layout(type: .uint16),
                geometry: try geometry()
            )
        }
    }

    @Test("An affine mapping other than the three axes in order is refused")
    func refusesUnexpectedAxisMapping() throws {
        #expect(throws: CTVolumeDescriptorError.unexpectedAxisMapping) {
            try CTVolumeDescriptorBuilder.descriptor(
                frame: try frame(),
                layout: try layout(),
                geometry: try geometry(axes: [2, 1, 0])
            )
        }
        #expect(throws: CTVolumeDescriptorError.unexpectedAxisMapping) {
            try CTVolumeDescriptorBuilder.descriptor(
                frame: try frame(),
                layout: try layout(),
                geometry: try geometry(axes: [0, 1])
            )
        }
    }

    @Test("A length unit for the samples is refused as a category error")
    func refusesLengthSampleUnit() throws {
        // A present unit describes sample values; a millimetre would claim the
        // Hounsfield numbers are lengths.
        #expect(throws: CTVolumeDescriptorError.unsupportedSampleUnit) {
            try CTVolumeDescriptorBuilder.descriptor(
                frame: try frame(),
                layout: try layout(),
                geometry: try geometry(),
                sampleUnits: try MeasurementUnit(
                    namespace: "ucum",
                    code: "mm",
                    displayName: "millimetre",
                    dimension: .length,
                    scaleToCanonical: nil,
                    offsetToCanonical: nil
                )
            )
        }
    }

    @Test("Sample units are absent by default, because Rescale Type is not read")
    func unitsAbsentByDefault() throws {
        // The corpus does declare Rescale Type HU, but the adapter does not read
        // it, so the builder declines to assert a unit it has not seen.
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: try frame(),
            layout: try layout(),
            geometry: try geometry()
        )
        #expect(descriptor.units == nil)
    }
}
