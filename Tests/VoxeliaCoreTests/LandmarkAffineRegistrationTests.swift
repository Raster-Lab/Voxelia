// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("LandmarkAffineRegistration")
struct LandmarkAffineRegistrationTests {
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

    @Test("[Unit][VOX-REG-005] the face returns an admitted affine transform with spaces")
    func theFaceReturnsAnAdmittedAffineTransformWithSpaces() throws {
        let transform = try LandmarkAffineRegistration.register(
            moving: try points(
                [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 1)],
                space: "subject"
            ),
            fixed: try points(
                [(1, 2, 3), (3, 2, 3), (1, 5, 3), (1, 2, 7), (3, 5, 7)],
                space: "atlas"
            ),
            sourceSpace: try space("subject"),
            destinationSpace: try space("atlas")
        )
        #expect(transform.sourceSpace.id.rawValue == "subject")
        #expect(transform.destinationSpace.id.rawValue == "atlas")
        guard case .affine(let affine) = transform.category else {
            Issue.record("the landmark estimate is not the affine category")
            return
        }
        #expect(affine.matrix.elements[0] == 2)
        #expect(affine.matrix.elements[3] == 1)
    }

    @Test("[Unit][VOX-REG-005] a landmark expressed elsewhere refuses typed")
    func aLandmarkExpressedElsewhereRefusesTyped() throws {
        #expect(throws: LandmarkRegistrationError.spaceMismatch) {
            _ = try LandmarkAffineRegistration.register(
                moving: try points(
                    [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)],
                    space: "somewhere-else"
                ),
                fixed: try points(
                    [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)],
                    space: "atlas"
                ),
                sourceSpace: try space("subject"),
                destinationSpace: try space("atlas")
            )
        }
    }
}
