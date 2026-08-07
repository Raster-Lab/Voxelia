// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("RegistrationQuality")
struct RegistrationQualityTests {
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

    private func affineTransform() throws -> RegistrationTransform {
        RegistrationTransform(
            sourceSpace: try space("subject"),
            destinationSpace: try space("atlas"),
            category: .affine(
                try AffineRegistrationTransform(
                    matrix: try Matrix4x4Double(elements: [
                        2, 0, 0, 1,
                        0, 3, 0, 2,
                        0, 0, 4, 3,
                        0, 0, 0, 1,
                    ])
                )
            )
        )
    }

    private func rigidTransform() throws -> RegistrationTransform {
        RegistrationTransform(
            sourceSpace: try space("subject"),
            destinationSpace: try space("atlas"),
            category: .rigid(
                try RigidMotion(
                    quaternionW: 1,
                    quaternionX: 1,
                    quaternionY: 1,
                    quaternionZ: 1,
                    translationX: 1,
                    translationY: 2,
                    translationZ: 3
                )
            )
        )
    }

    @Test("[Unit][VOX-REG-009] fixture A: exact correspondences report zero everywhere")
    func fixtureAExactCorrespondencesReportZeroEverywhere() throws {
        let report = try RegistrationQuality.evaluate(
            transform: try affineTransform(),
            moving: try points(
                [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 1)],
                space: "subject"
            ),
            fixed: try points(
                [(1, 2, 3), (3, 2, 3), (1, 5, 3), (3, 5, 7)],
                space: "atlas"
            )
        )
        #expect(report.residuals == [0, 0, 0, 0])
        #expect(report.rootMeanSquare == 0)
        #expect(report.maximum == 0)
    }

    @Test("[Unit][VOX-REG-009] fixture B: perturbed correspondences pin the bits")
    func fixtureBPerturbedCorrespondencesPinTheBits() throws {
        let report = try RegistrationQuality.evaluate(
            transform: try rigidTransform(),
            moving: try points(
                [(0, 0, 0), (1, 0, 0), (0, 1, 0)],
                space: "subject"
            ),
            fixed: try points(
                [(1, 2, 3), (1.5, 3, 3), (1, 2, 4.25)],
                space: "atlas"
            )
        )
        #expect(report.residuals == [0, 0.5, 0.25])
        #expect(report.rootMeanSquare == 0x1.4a7e9cb8a3491p-2)
        #expect(report.maximum == 0.5)
    }

    @Test("[Unit][VOX-REG-009] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: RegistrationQualityError.countMismatch) {
            _ = try RegistrationQuality.evaluate(
                transform: try affineTransform(),
                moving: try points([(0, 0, 0)], space: "subject"),
                fixed: try points([], space: "atlas")
            )
        }
        #expect(throws: RegistrationQualityError.emptyLandmarks) {
            _ = try RegistrationQuality.evaluate(
                transform: try affineTransform(),
                moving: try points([], space: "subject"),
                fixed: try points([], space: "atlas")
            )
        }
        #expect(throws: RegistrationQualityError.spaceMismatch) {
            _ = try RegistrationQuality.evaluate(
                transform: try affineTransform(),
                moving: try points([(0, 0, 0)], space: "somewhere-else"),
                fixed: try points([(1, 2, 3)], space: "atlas")
            )
        }
    }
}
