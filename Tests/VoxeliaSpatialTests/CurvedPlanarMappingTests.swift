// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

@Suite("CurvedPlanarMapping")
struct CurvedPlanarMappingTests {
    private func space(_ id: String = "patient") throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func points(
        _ coordinates: [(Double, Double, Double)],
        space: String = "patient"
    ) throws -> ContiguousArray<Point3D> {
        var out = ContiguousArray<Point3D>()
        for (x, y, z) in coordinates {
            out.append(
                try Point3D(
                    x: x,
                    y: y,
                    z: z,
                    coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
                )
            )
        }
        return out
    }

    private func vector(
        _ x: Double, _ y: Double, _ z: Double,
        space: String = "patient"
    ) throws -> Vector3D {
        try Vector3D(
            x: x,
            y: y,
            z: z,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
        )
    }

    private func elbowMapping() throws -> CurvedPlanarMapping {
        try CurvedPlanarMapping(
            centreline: try CurvedCentreline(
                coordinateSpace: try space(),
                points: try points([(0, 0, 0), (3, 0, 0), (3, 4, 0)])
            ),
            referenceDirection: try vector(0, 0, 1)
        )
    }

    @Test("[Unit][VOX-MPR-013] elbow output positions map back exactly")
    func elbowOutputPositionsMapBackExactly() throws {
        let mapping = try elbowMapping()
        let first = try mapping.patientPosition(atArcLength: 1.5, lateralOffset: 2)
        #expect(first.x == 1.5 && first.y == 0 && first.z == 2)
        let second = try mapping.patientPosition(atArcLength: 5.5, lateralOffset: -1)
        #expect(second.x == 3 && second.y == 2.5 && second.z == -1)
        // The far endpoint stays exact by the ALG-0074 rule, with the
        // last segment's frame.
        let end = try mapping.patientPosition(atArcLength: 7, lateralOffset: 0.5)
        #expect(end.x == 3 && end.y == 4 && end.z == 0.5)
    }

    @Test("[Unit][VOX-MPR-013] the diagonal pins the honest rounding residual")
    func theDiagonalPinsTheHonestRoundingResidual() throws {
        let mapping = try CurvedPlanarMapping(
            centreline: try CurvedCentreline(
                coordinateSpace: try space(),
                points: try points([(0, 0, 0), (1, 1, 0)])
            ),
            referenceDirection: try vector(1, 0, 0)
        )
        let position = try mapping.patientPosition(atArcLength: 1, lateralOffset: 1)
        #expect(position.x == 0x1.6a09e667f3bcdp+0)
        #expect(position.y == 0x1.0p-53)
        #expect(position.z == 0)
    }

    @Test("[Unit][VOX-MPR-013] admissions reject typed")
    func admissionsRejectTyped() throws {
        let centreline = try CurvedCentreline(
            coordinateSpace: try space(),
            points: try points([(0, 0, 0), (3, 0, 0), (3, 4, 0)])
        )
        #expect(throws: CurvedPlanarMappingError.spaceMismatch) {
            _ = try CurvedPlanarMapping(
                centreline: centreline,
                referenceDirection: try vector(0, 0, 1, space: "somewhere-else")
            )
        }
        #expect(throws: CurvedPlanarMappingError.zeroReferenceDirection) {
            _ = try CurvedPlanarMapping(
                centreline: centreline,
                referenceDirection: try vector(0, 0, 0)
            )
        }
        // Exactly parallel to the first segment: the lateral direction
        // would be undefined there.
        #expect(throws: CurvedPlanarMappingError.referenceParallelToSegment) {
            _ = try CurvedPlanarMapping(
                centreline: centreline,
                referenceDirection: try vector(2, 0, 0)
            )
        }
        let mapping = try elbowMapping()
        #expect(throws: CurvedPlanarMappingError.invalidLateralOffset) {
            _ = try mapping.patientPosition(atArcLength: 1, lateralOffset: .nan)
        }
        #expect(throws: CurvedCentrelineError.arcLengthOutOfRange) {
            _ = try mapping.patientPosition(atArcLength: 8, lateralOffset: 0)
        }
    }
}
