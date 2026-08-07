// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("LandmarkRigidRegistration")
struct LandmarkRigidRegistrationTests {
    private func space(_ id: String) throws -> CoordinateSpaceDescriptor {
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
        space: String
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

    @Test("[Unit][VOX-REG-005] the face returns a rigid-category transform with spaces")
    func theFaceReturnsARigidCategoryTransformWithSpaces() throws {
        let transform = try LandmarkRigidRegistration.register(
            moving: try points(
                [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 2)],
                space: "subject"
            ),
            fixed: try points(
                [(1, 2, 3), (1, 3, 3), (1, 2, 4), (3, 2, 3)],
                space: "atlas"
            ),
            sourceSpace: try space("subject"),
            destinationSpace: try space("atlas")
        )
        #expect(transform.sourceSpace.id.rawValue == "subject")
        #expect(transform.destinationSpace.id.rawValue == "atlas")
        guard case .rigid(let motion) = transform.category else {
            Issue.record("the landmark rigid estimate is not the rigid category")
            return
        }
        #expect(motion.translation == [1, 2, 3])
    }

    @Test("[Unit][VOX-REG-005] a landmark expressed elsewhere refuses typed")
    func aLandmarkExpressedElsewhereRefusesTyped() throws {
        #expect(throws: LandmarkRegistrationError.spaceMismatch) {
            _ = try LandmarkRigidRegistration.register(
                moving: try points(
                    [(0, 0, 0), (1, 0, 0), (0, 1, 0)],
                    space: "subject"
                ),
                fixed: try points(
                    [(0, 0, 0), (1, 0, 0), (0, 1, 0)],
                    space: "somewhere-else"
                ),
                sourceSpace: try space("subject"),
                destinationSpace: try space("atlas")
            )
        }
    }
}
