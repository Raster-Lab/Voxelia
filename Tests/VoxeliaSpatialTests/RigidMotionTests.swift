// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

@Suite("RigidMotion")
struct RigidMotionTests {
    @Test("[Unit][VOX-REG-001] fixture A: equal components derive the permutation")
    func fixtureAEqualComponentsDeriveThePermutation() throws {
        let motion = try RigidMotion(
            quaternionW: 1,
            quaternionX: 1,
            quaternionY: 1,
            quaternionZ: 1,
            translationX: 3,
            translationY: -4,
            translationZ: 0.5
        )
        #expect(motion.quaternion == [0.5, 0.5, 0.5, 0.5])
        let matrix = try motion.matrix()
        #expect(
            matrix.elements == [
                0, 0, 1, 3,
                1, 0, 0, -4,
                0, 1, 0, 0.5,
                0, 0, 0, 1,
            ]
        )
    }

    @Test("[Unit][VOX-REG-001] fixture B: normalisation and the canonical sign flip")
    func fixtureBNormalisationAndTheCanonicalSignFlip() throws {
        let motion = try RigidMotion(
            quaternionW: 0,
            quaternionX: 0,
            quaternionY: 0,
            quaternionZ: -2,
            translationX: 0,
            translationY: 0,
            translationZ: 0
        )
        #expect(motion.quaternion == [0, 0, 0, 1])
        // Positive zero exactly: the negative zeros the derivation
        // produces are normalised away.
        #expect(motion.quaternion[0].sign == .plus)
        let matrix = try motion.matrix()
        #expect(
            matrix.elements == [
                -1, 0, 0, 0,
                0, -1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]
        )
    }

    @Test("[Unit][VOX-REG-001] fixture C: the irrational norm rounds as the oracle")
    func fixtureCTheIrrationalNormRoundsAsTheOracle() throws {
        let motion = try RigidMotion(
            quaternionW: 2,
            quaternionX: 1,
            quaternionY: 0,
            quaternionZ: 0,
            translationX: 0,
            translationY: 0,
            translationZ: 0
        )
        #expect(
            motion.quaternion == [
                0x1.c9f25c5bfedd9p-1, 0x1.c9f25c5bfedd9p-2, 0, 0,
            ]
        )
        let matrix = try motion.matrix()
        #expect(
            matrix.elements == [
                1, 0, 0, 0,
                0, 0x1.3333333333334p-1, -0x1.9999999999999p-1, 0,
                0, 0x1.9999999999999p-1, 0x1.3333333333334p-1, 0,
                0, 0, 0, 1,
            ]
        )
    }

    @Test("[Unit][VOX-REG-001] q and negated q admit to one stored form")
    func qAndNegatedQAdmitToOneStoredForm() throws {
        let positive = try RigidMotion(
            quaternionW: 1,
            quaternionX: 1,
            quaternionY: 1,
            quaternionZ: 1,
            translationX: 0,
            translationY: 0,
            translationZ: 0
        )
        let negated = try RigidMotion(
            quaternionW: -1,
            quaternionX: -1,
            quaternionY: -1,
            quaternionZ: -1,
            translationX: 0,
            translationY: 0,
            translationZ: 0
        )
        #expect(positive == negated)
    }

    @Test("[Unit][VOX-REG-001] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: RigidMotionError.zeroQuaternion) {
            _ = try RigidMotion(
                quaternionW: 0,
                quaternionX: 0,
                quaternionY: 0,
                quaternionZ: 0,
                translationX: 0,
                translationY: 0,
                translationZ: 0
            )
        }
        #expect(throws: RigidMotionError.nonFiniteComponent) {
            _ = try RigidMotion(
                quaternionW: .nan,
                quaternionX: 0,
                quaternionY: 0,
                quaternionZ: 1,
                translationX: 0,
                translationY: 0,
                translationZ: 0
            )
        }
        #expect(throws: RigidMotionError.nonFiniteComponent) {
            _ = try RigidMotion(
                quaternionW: 1,
                quaternionX: 0,
                quaternionY: 0,
                quaternionZ: 0,
                translationX: .infinity,
                translationY: 0,
                translationZ: 0
            )
        }
    }
}
