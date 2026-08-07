// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

@Suite("RigidMotionComposition")
struct RigidMotionCompositionTests {
    private func motion(
        _ w: Double, _ x: Double, _ y: Double, _ z: Double,
        translation: (Double, Double, Double) = (0, 0, 0)
    ) throws -> RigidMotion {
        try RigidMotion(
            quaternionW: w,
            quaternionX: x,
            quaternionY: y,
            quaternionZ: z,
            translationX: translation.0,
            translationY: translation.1,
            translationZ: translation.2
        )
    }

    @Test("[Unit][VOX-REG-004] fixture A: rotated inner translation adds exactly")
    func fixtureARotatedInnerTranslationAddsExactly() throws {
        let composed = try RigidMotion.composed(
            try motion(1, 1, 1, 1, translation: (10, 20, 30)),
            after: try motion(1, 0, 0, 0, translation: (1, 2, 3))
        )
        #expect(composed.quaternion == [0.5, 0.5, 0.5, 0.5])
        #expect(composed.translation == [13, 21, 32])
    }

    @Test("[Unit][VOX-REG-004] fixture B: the product re-admits to the canonical form")
    func fixtureBTheProductReAdmitsToTheCanonicalForm() throws {
        let permutation = try motion(1, 1, 1, 1)
        let composed = try RigidMotion.composed(permutation, after: permutation)
        // The Hamilton product lands at (-0.5, 0.5, 0.5, 0.5); the
        // canonical sign flips it at re-admission.
        #expect(composed.quaternion == [0.5, -0.5, -0.5, -0.5])
        #expect(composed.translation == [0, 0, 0])
    }

    @Test("[Unit][VOX-REG-004] fixture C: irrational operands round as the oracle")
    func fixtureCIrrationalOperandsRoundAsTheOracle() throws {
        let composed = try RigidMotion.composed(
            try motion(2, 1, 0, 0, translation: (1, 0, 0)),
            after: try motion(1, 1, 1, 1, translation: (0, 1, 0))
        )
        #expect(
            composed.quaternion == [
                0x1.c9f25c5bfedd9p-3, 0x1.5775c544ff263p-1,
                0x1.c9f25c5bfedd9p-3, 0x1.5775c544ff263p-1,
            ]
        )
        #expect(
            composed.translation == [
                1, 0x1.3333333333334p-1, 0x1.9999999999999p-1,
            ]
        )
    }
}
