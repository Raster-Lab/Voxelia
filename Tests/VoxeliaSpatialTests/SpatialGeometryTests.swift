// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

@Suite("SpatialGeometry")
struct SpatialGeometryTests {
    private func spaceID(_ raw: String) throws -> CoordinateSpaceID {
        guard let id = CoordinateSpaceID(rawValue: raw) else {
            throw CoordinateSpaceError.nonLengthUnit
        }
        return id
    }

    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try spaceID("patient"),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    @Test("[Unit][CDMS-21.6][VOX-SPA-002] coordinate spaces admit fail-closed")
    func coordinateSpacesAdmitFailClosed() throws {
        _ = try space()

        // Non-length and missing unit dimensions are rejected.
        for dimension in [UnitDimension.time, nil] {
            do {
                _ = try CoordinateSpaceDescriptor(
                    id: try spaceID("s"),
                    convention: .cartesianRightHanded,
                    handedness: .unspecified,
                    unit: try MeasurementUnit(
                        namespace: "UCUM",
                        code: "s",
                        dimension: dimension
                    ),
                    externalReferences: []
                )
                #expect(Bool(false), "Expected a non-length unit to be rejected.")
            } catch CoordinateSpaceError.nonLengthUnit {}
        }

        // Duplicate exact external references are rejected.
        let reference = try ExternalFrameReference(
            namespace: "dicom",
            identifier: "frame-1"
        )
        do {
            _ = try CoordinateSpaceDescriptor(
                id: try spaceID("s"),
                convention: .cartesianRightHanded,
                handedness: .unspecified,
                unit: try MeasurementUnit(
                    namespace: "UCUM",
                    code: "mm",
                    dimension: .length
                ),
                externalReferences: [reference, reference]
            )
            #expect(Bool(false), "Expected a duplicate reference to be rejected.")
        } catch CoordinateSpaceError.duplicateExternalReference {}

        // A declared handedness contradicting the convention rejects;
        // agreement and unspecified both admit.
        do {
            _ = try CoordinateSpaceDescriptor(
                id: try spaceID("s"),
                convention: .cartesianRightHanded,
                handedness: .leftHanded,
                unit: try MeasurementUnit(
                    namespace: "UCUM",
                    code: "mm",
                    dimension: .length
                ),
                externalReferences: []
            )
            #expect(Bool(false), "Expected a handedness contradiction to reject.")
        } catch CoordinateSpaceError.handednessContradiction {}
        _ = try CoordinateSpaceDescriptor(
            id: try spaceID("s"),
            convention: .cartesianRightHanded,
            handedness: .rightHanded,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )

        // Blank identifiers are rejected by the existing leaf.
        #expect(CoordinateSpaceID(rawValue: " ") == nil)

        requireSendable(CoordinateSpaceDescriptor.self)
        requireSendable(SpatialGeometry.self)
    }

    @Test("[Unit][CDMS-24.1][VOX-SPA-003] affine admission follows the exact rule")
    func affineAdmissionFollowsTheExactRule() throws {
        let space = try space()
        let axes = try SpatialAxisMapping(imageAxes: [0, 1, 2])

        // A translated identity admits.
        let translated = try Matrix4x4Double(elements: [
            1, 0, 0, 10,
            0, 1, 0, 20,
            0, 0, 1, 30,
            0, 0, 0, 1,
        ])
        let geometry = try AffineGridGeometry(
            spatialAxes: axes,
            indexToWorld: translated,
            coordinateSpace: space
        )
        _ = SpatialGeometry.affine(geometry)

        // A perturbed bottom row is not affine.
        let projective = try Matrix4x4Double(elements: [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0.5, 1,
        ])
        do {
            _ = try AffineGridGeometry(
                spatialAxes: axes,
                indexToWorld: projective,
                coordinateSpace: space
            )
            #expect(Bool(false), "Expected a projective bottom row to reject.")
        } catch SpatialGeometryError.nonAffineBottomRow {}

        // Zero and subnormal determinants are singular; the exact
        // least-normal boundary admits.
        for scale in [0.0, Double.leastNormalMagnitude / 2] {
            let singular = try Matrix4x4Double(elements: [
                scale, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ])
            do {
                _ = try AffineGridGeometry(
                    spatialAxes: axes,
                    indexToWorld: singular,
                    coordinateSpace: space
                )
                #expect(Bool(false), "Expected a singular transform to reject.")
            } catch SpatialGeometryError.singularTransform {}
        }
        let boundary = try Matrix4x4Double(elements: [
            Double.leastNormalMagnitude, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ])
        _ = try AffineGridGeometry(
            spatialAxes: axes,
            indexToWorld: boundary,
            coordinateSpace: space
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
