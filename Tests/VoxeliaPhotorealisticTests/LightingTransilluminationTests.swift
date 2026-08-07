// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

@Suite("LightingTransillumination")
struct LightingTransilluminationTests {
    private func light(
        _ r: Double, _ g: Double, _ b: Double,
        weight: Double,
        transmittance: Double
    ) throws -> LightSample {
        try LightSample(
            radianceRed: r,
            radianceGreen: g,
            radianceBlue: b,
            weight: weight,
            transmittance: transmittance
        )
    }

    @Test("[Unit][VOX-PRR-006] declared light samples accumulate exactly")
    func declaredLightSamplesAccumulateExactly() throws {
        let dyadic = LightingComposition.accumulate(lights: [
            try light(1, 0.5, 0.25, weight: 0.5, transmittance: 0.5),
            try light(0.25, 1, 0, weight: 0.25, transmittance: 1),
        ])
        #expect(dyadic.red == 0.3125)
        #expect(dyadic.green == 0.375)
        #expect(dyadic.blue == 0.0625)

        // A fully shadowed light contributes exactly nothing.
        let shadowed = LightingComposition.accumulate(lights: [
            try light(9, 9, 9, weight: 1, transmittance: 0)
        ])
        #expect(shadowed.red == 0 && shadowed.green == 0 && shadowed.blue == 0)

        let irrational = LightingComposition.accumulate(lights: [
            try light(0.1, 0.2, 0.3, weight: 0.7, transmittance: 0.9),
            try light(0.4, 0.5, 0.6, weight: 0.3, transmittance: 0.2),
        ])
        #expect(irrational.red == 0x1.645a1cac08312p-4)
        #expect(irrational.green == 0x1.3f7ced916872bp-3)
        #expect(irrational.blue == 0x1.ccccccccccccdp-3)

        let empty = LightingComposition.accumulate(lights: [])
        #expect(empty.red == 0 && empty.green == 0 && empty.blue == 0)
    }

    @Test("[Unit][VOX-PRR-008] transillumination composes radiance over background")
    func transilluminationComposesRadianceOverBackground() throws {
        let dyadic = try LightingComposition.transilluminate(
            radiance: RadianceSample(red: 0.25, green: 0.5, blue: 0.125, opacity: 0.75),
            backgroundRed: 1,
            backgroundGreen: 0.5,
            backgroundBlue: 0.25
        )
        #expect(dyadic.red == 0.5)
        #expect(dyadic.green == 0.625)
        #expect(dyadic.blue == 0.1875)

        // An exactly opaque foreground admits exactly nothing.
        let opaque = try LightingComposition.transilluminate(
            radiance: RadianceSample(red: 0.1, green: 0.2, blue: 0.3, opacity: 1),
            backgroundRed: 9,
            backgroundGreen: 9,
            backgroundBlue: 9
        )
        #expect(opaque.red == 0.1)
        #expect(opaque.green == 0.2)
        #expect(opaque.blue == 0.3)

        let irrational = try LightingComposition.transilluminate(
            radiance: RadianceSample(red: 0.1, green: 0.2, blue: 0.3, opacity: 0.7),
            backgroundRed: 0.9,
            backgroundGreen: 0.8,
            backgroundBlue: 0.7
        )
        #expect(irrational.red == 0x1.7ae147ae147b0p-2)
        #expect(irrational.green == 0x1.c28f5c28f5c2ap-2)
        #expect(irrational.blue == 0x1.051eb851eb852p-1)
    }

    @Test("[Unit][VOX-PRR-006][VOX-PRR-008] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: LightingError.negativeValue) {
            _ = try LightSample(
                radianceRed: -1,
                radianceGreen: 0,
                radianceBlue: 0,
                weight: 1,
                transmittance: 1
            )
        }
        #expect(throws: LightingError.invalidTransmittance) {
            _ = try LightSample(
                radianceRed: 0,
                radianceGreen: 0,
                radianceBlue: 0,
                weight: 1,
                transmittance: 2
            )
        }
        #expect(throws: LightingError.nonFiniteComponent) {
            _ = try LightingComposition.transilluminate(
                radiance: RadianceSample(red: 0, green: 0, blue: 0, opacity: 0),
                backgroundRed: .infinity,
                backgroundGreen: 0,
                backgroundBlue: 0
            )
        }
    }
}
