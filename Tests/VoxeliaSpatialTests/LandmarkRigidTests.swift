// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

@Suite("LandmarkRigid")
struct LandmarkRigidTests {
    private func points(
        _ coordinates: [(Double, Double, Double)]
    ) throws -> ContiguousArray<Point3D> {
        var out = ContiguousArray<Point3D>()
        for (x, y, z) in coordinates {
            out.append(
                try Point3D(
                    x: x,
                    y: y,
                    z: z,
                    coordinateSpace: try #require(CoordinateSpaceID(rawValue: "patient"))
                )
            )
        }
        return out
    }

    @Test("[Unit][VOX-REG-005] fixture A: an exact motion recovers to the pinned bits")
    func fixtureAAnExactMotionRecoversToThePinnedBits() throws {
        let motion = try LandmarkRigidEstimation.estimate(
            moving: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 2)]),
            fixed: try points([(1, 2, 3), (1, 3, 3), (1, 2, 4), (3, 2, 3)])
        )
        #expect(
            motion.quaternion == [
                0x1.0000000000001p-1, 0x1.ffffffffffffep-2,
                0x1.0000000000001p-1, 0x1.0p-1,
            ]
        )
        #expect(motion.translation == [1, 2, 3])
    }

    @Test("[Unit][VOX-REG-005] fixture B: collinear landmarks refuse as degenerate")
    func fixtureBCollinearLandmarksRefuseAsDegenerate() throws {
        #expect(throws: LandmarkEstimationError.degenerateLandmarks) {
            _ = try LandmarkRigidEstimation.estimate(
                moving: try points([(0, 0, 0), (1, 1, 1), (2, 2, 2)]),
                fixed: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0)])
            )
        }
        // The fixed side refuses too: a collinear target leaves the
        // rotation about its line just as unconstrained.
        #expect(throws: LandmarkEstimationError.degenerateLandmarks) {
            _ = try LandmarkRigidEstimation.estimate(
                moving: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0)]),
                fixed: try points([(0, 0, 0), (1, 1, 1), (2, 2, 2)])
            )
        }
    }

    @Test("[Unit][VOX-REG-005] fixture C: an inconsistent set pins the least squares")
    func fixtureCAnInconsistentSetPinsTheLeastSquares() throws {
        let motion = try LandmarkRigidEstimation.estimate(
            moving: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 2)]),
            fixed: try points([(1, 2, 3), (1, 3, 3), (1, 2, 4), (3, 2, 3.5)])
        )
        #expect(
            motion.quaternion == [
                0x1.18ab5ea74e54ep-1, 0x1.c07327f978064p-2,
                0x1.d26cad16a8adcp-2, 0x1.188acbe01a483p-1,
            ]
        )
        #expect(
            motion.translation == [
                0x1.108c69592eec2p+0, 0x1.fc9070a609b39p+0, 0x1.8464197ceb530p+1,
            ]
        )
    }

    @Test("[Unit][VOX-REG-005] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: LandmarkEstimationError.countMismatch) {
            _ = try LandmarkRigidEstimation.estimate(
                moving: try points([(0, 0, 0), (1, 0, 0), (0, 1, 0)]),
                fixed: try points([(0, 0, 0), (1, 0, 0)])
            )
        }
        #expect(throws: LandmarkEstimationError.insufficientLandmarks) {
            _ = try LandmarkRigidEstimation.estimate(
                moving: try points([(0, 0, 0), (1, 0, 0)]),
                fixed: try points([(0, 0, 0), (1, 0, 0)])
            )
        }
    }
}
