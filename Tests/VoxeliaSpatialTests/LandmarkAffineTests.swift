// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

@Suite("LandmarkAffine")
struct LandmarkAffineTests {
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

    @Test("[Unit][VOX-REG-005] fixture A: consistent pairs pin the frozen rounding")
    func fixtureAConsistentPairsPinTheFrozenRounding() throws {
        let matrix = try LandmarkAffineEstimation.estimate(
            moving: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 1)]),
            fixed: try points([(1, 2, 3), (3, 2, 3), (1, 5, 3), (1, 2, 7), (3, 5, 7)])
        )
        #expect(
            matrix.elements == [
                2, 0, 0, 1,
                0, 3, 0, 2,
                -0x1.0p-51, -0x1.5555555555555p-52, 0x1.0000000000001p+2, 3,
                0, 0, 0, 1,
            ]
        )
    }

    @Test("[Unit][VOX-REG-005] fixture B: coplanar landmarks refuse as degenerate")
    func fixtureBCoplanarLandmarksRefuseAsDegenerate() throws {
        #expect(throws: LandmarkEstimationError.degenerateLandmarks) {
            _ = try LandmarkAffineEstimation.estimate(
                moving: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 0)]),
                fixed: try points([(0, 0, 0), (2, 0, 0), (0, 2, 0), (2, 2, 0)])
            )
        }
    }

    @Test("[Unit][VOX-REG-005] fixture C: an inconsistent point yields the least squares")
    func fixtureCAnInconsistentPointYieldsTheLeastSquares() throws {
        let matrix = try LandmarkAffineEstimation.estimate(
            moving: try points([(0, 0, 0), (2, 0, 0), (0, 2, 0), (0, 0, 2), (2, 2, 2)]),
            fixed: try points([(0, 0, 0), (2, 0, 0), (0, 2, 0), (0, 0, 2), (3, 2, 2)])
        )
        #expect(
            matrix.elements == [
                1.1875, 0.1875, 0.1875, -0.25,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]
        )
    }

    @Test("[Unit][VOX-REG-005] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: LandmarkEstimationError.countMismatch) {
            _ = try LandmarkAffineEstimation.estimate(
                moving: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)]),
                fixed: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0)])
            )
        }
        #expect(throws: LandmarkEstimationError.insufficientLandmarks) {
            _ = try LandmarkAffineEstimation.estimate(
                moving: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0)]),
                fixed: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0)])
            )
        }
    }
}
