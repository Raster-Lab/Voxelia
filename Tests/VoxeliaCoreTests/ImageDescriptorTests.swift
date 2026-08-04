// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("ImageDescriptor")
struct ImageDescriptorTests {
    private func axis(_ id: String) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: id) else {
            throw ImageDescriptorError.duplicateAxisIdentifier
        }
        return try AxisDescriptor(
            id: axisID,
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func descriptor(
        semantic: ImageSemantic = .intensity,
        componentInterpretation: ComponentInterpretation = .scalar,
        componentCount: Int = 1,
        geometry: SpatialGeometry? = nil,
        units: MeasurementUnit? = nil,
        axisIDs: [String] = ["x", "y"]
    ) throws -> ImageDescriptor {
        try ImageDescriptor(
            shape: try ImageShape(extents: [4, 3]),
            scalarFormat: try ScalarFormat(
                type: .uint16,
                validBitCount: nil,
                byteOrder: .littleEndian
            ),
            components: try ComponentDescriptor(
                count: componentCount,
                interpretation: componentInterpretation,
                layout: .interleaved,
                componentNames: nil
            ),
            semantic: semantic,
            axes: ContiguousArray(try axisIDs.map { try axis($0) }),
            spatialGeometry: geometry,
            valueTransform: nil,
            units: units
        )
    }

    @Test("[Unit][CDMS-19.2][VOX-IMG-001] invariants admit and reject exactly")
    func invariantsAdmitAndRejectExactly() throws {
        // A valid intensity descriptor admits without storage access.
        let descriptor = try descriptor()
        #expect(descriptor.axes.count == 2)

        // Axis count must equal shape rank.
        do {
            _ = try self.descriptor(axisIDs: ["x"])
            #expect(Bool(false), "Expected an axis-count mismatch to reject.")
        } catch ImageDescriptorError.axisCountMismatch {}

        // Axis identifiers must be unique.
        do {
            _ = try self.descriptor(axisIDs: ["x", "x"])
            #expect(Bool(false), "Expected a duplicate axis ID to reject.")
        } catch ImageDescriptorError.duplicateAxisIdentifier {}

        // Colour semantics require RGB/RGBA; non-colour semantics
        // reject colour interpretations.
        _ = try self.descriptor(
            semantic: .colour,
            componentInterpretation: .rgb,
            componentCount: 3
        )
        do {
            _ = try self.descriptor(semantic: .colour)
            #expect(Bool(false), "Expected colour without RGB to reject.")
        } catch ImageDescriptorError.semanticComponentMismatch {}
        do {
            _ = try self.descriptor(
                semantic: .intensity,
                componentInterpretation: .rgb,
                componentCount: 3
            )
            #expect(Bool(false), "Expected RGB intensity to reject.")
        } catch ImageDescriptorError.semanticComponentMismatch {}

        requireSendable(ImageDescriptor.self)
        requireSendable(ImageDescriptorError.self)
    }

    @Test("[Unit][CDMS-19.2][VOX-IMG-002] geometry and unit rules bind")
    func geometryAndUnitRulesBind() throws {
        // A geometry referencing only valid image axes admits; an
        // out-of-rank reference rejects.
        guard let spaceID = CoordinateSpaceID(rawValue: "patient") else {
            #expect(Bool(false), "Expected a valid space identifier.")
            return
        }
        let space = try CoordinateSpaceDescriptor(
            id: spaceID,
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
        let valid = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
            indexToWorld: .identity,
            coordinateSpace: space
        )
        _ = try descriptor(geometry: .affine(valid))

        let outOfRank = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 2]),
            indexToWorld: .identity,
            coordinateSpace: space
        )
        do {
            _ = try descriptor(geometry: .affine(outOfRank))
            #expect(Bool(false), "Expected an out-of-rank axis reference to reject.")
        } catch ImageDescriptorError.invalidGeometryAxisReference {}

        // Sample units describe sample values: a length unit is a
        // spatial-coordinate unit and rejects; a non-spatial unit admits.
        _ = try descriptor(
            units: try MeasurementUnit(namespace: "UCUM", code: "HU")
        )
        do {
            _ = try descriptor(
                units: try MeasurementUnit(
                    namespace: "UCUM",
                    code: "mm",
                    dimension: .length
                )
            )
            #expect(Bool(false), "Expected a length sample unit to reject.")
        } catch ImageDescriptorError.nonSampleUnit {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
