// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

/// The `ADR-0389` witness: the documented single-scattering
/// approximation composes only pinned pieces — shadow transmittance
/// into light accumulation into the emission-absorption integral — so
/// the expected values are exact by construction.
@Suite("ScatteringApproximation")
struct ScatteringApproximationTests {
    @Test("[Integration][VOX-PRR-007] one bounce composes from pinned pieces exactly")
    func oneBounceComposesFromPinnedPiecesExactly() throws {
        let lightRadiance = (red: 1.0, green: 1.0, blue: 1.0)

        // Sample one: half-shadowed, albedo (1, 0.5, 0.25).
        let firstShadow = try VolumetricShadowWalk.transmittance(opacities: [0.5])
        #expect(firstShadow == 0.5)
        let firstLight = LightingComposition.accumulate(lights: [
            try LightSample(
                radianceRed: lightRadiance.red,
                radianceGreen: lightRadiance.green,
                radianceBlue: lightRadiance.blue,
                weight: 1,
                transmittance: firstShadow
            )
        ])
        let firstSample = try RaySample(
            emissionRed: 1 * firstLight.red,
            emissionGreen: 0.5 * firstLight.green,
            emissionBlue: 0.25 * firstLight.blue,
            opacity: 0.5
        )

        // Sample two: unshadowed, albedo (1, 1, 1).
        let secondShadow = try VolumetricShadowWalk.transmittance(opacities: [])
        #expect(secondShadow == 1)
        let secondLight = LightingComposition.accumulate(lights: [
            try LightSample(
                radianceRed: lightRadiance.red,
                radianceGreen: lightRadiance.green,
                radianceBlue: lightRadiance.blue,
                weight: 1,
                transmittance: secondShadow
            )
        ])
        let secondSample = try RaySample(
            emissionRed: 1 * secondLight.red,
            emissionGreen: 1 * secondLight.green,
            emissionBlue: 1 * secondLight.blue,
            opacity: 0.5
        )

        // Light to medium to eye: the emission-absorption integral
        // carries the one bounce, and every number is exact.
        let result = VolumetricIlluminationIntegrator.integrate(samples: [
            firstSample, secondSample,
        ])
        #expect(result.red == 0.5)
        #expect(result.green == 0.375)
        #expect(result.blue == 0.3125)
        #expect(result.opacity == 0.75)
    }
}
