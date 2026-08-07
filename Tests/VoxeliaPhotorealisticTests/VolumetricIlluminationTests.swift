// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

@Suite("VolumetricIllumination")
struct VolumetricIlluminationTests {
    private func sample(
        _ r: Double, _ g: Double, _ b: Double, _ a: Double
    ) throws -> RaySample {
        try RaySample(
            emissionRed: r,
            emissionGreen: g,
            emissionBlue: b,
            opacity: a
        )
    }

    @Test("[Unit][VOX-PRR-004] fixture A: dyadic samples integrate exactly")
    func fixtureADyadicSamplesIntegrateExactly() throws {
        let result = VolumetricIlluminationIntegrator.integrate(samples: [
            try sample(1, 0.5, 0.25, 0.5),
            try sample(0.5, 1, 0, 0.5),
        ])
        #expect(result.red == 0.625)
        #expect(result.green == 0.5)
        #expect(result.blue == 0.125)
        #expect(result.opacity == 0.75)
    }

    @Test("[Unit][VOX-PRR-004] fixture B: exact saturation occludes what follows")
    func fixtureBExactSaturationOccludesWhatFollows() throws {
        let result = VolumetricIlluminationIntegrator.integrate(samples: [
            try sample(0.25, 0.5, 0.75, 1),
            try sample(9, 9, 9, 1),
        ])
        #expect(result.red == 0.25)
        #expect(result.green == 0.5)
        #expect(result.blue == 0.75)
        #expect(result.opacity == 1)
    }

    @Test("[Unit][VOX-PRR-004] the empty ray is exactly transparent")
    func theEmptyRayIsExactlyTransparent() throws {
        let result = VolumetricIlluminationIntegrator.integrate(samples: [])
        #expect(result == RadianceSample(red: 0, green: 0, blue: 0, opacity: 0))
    }

    @Test("[Unit][VOX-PRR-004] fixture D: irrational weights pin the frozen rounding")
    func fixtureDIrrationalWeightsPinTheFrozenRounding() throws {
        let result = VolumetricIlluminationIntegrator.integrate(samples: [
            try sample(0.1, 0.2, 0.3, 0.1),
            try sample(0.4, 0.5, 0.6, 0.7),
            try sample(0.7, 0.8, 0.9, 0.9),
        ])
        #expect(result.red == 0x1.ba786c226809ep-2)
        #expect(result.green == 0x1.0f0d844d013aap-1)
        #expect(result.blue == 0x1.40ded288ce704p-1)
        #expect(result.opacity == 0x1.f22d0e5604189p-1)
    }

    @Test("[Unit][VOX-PRR-004] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: VolumetricIlluminationError.nonFiniteComponent) {
            _ = try RaySample(
                emissionRed: .nan,
                emissionGreen: 0,
                emissionBlue: 0,
                opacity: 0.5
            )
        }
        #expect(throws: VolumetricIlluminationError.negativeEmission) {
            _ = try RaySample(
                emissionRed: -1,
                emissionGreen: 0,
                emissionBlue: 0,
                opacity: 0.5
            )
        }
        #expect(throws: VolumetricIlluminationError.invalidOpacity) {
            _ = try RaySample(
                emissionRed: 0,
                emissionGreen: 0,
                emissionBlue: 0,
                opacity: 1.5
            )
        }
    }
}
