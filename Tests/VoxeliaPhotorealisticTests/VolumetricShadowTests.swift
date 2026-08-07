// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

@Suite("VolumetricShadow")
struct VolumetricShadowTests {
    @Test("[Unit][VOX-PRR-005] the transmittance walk reproduces the oracle")
    func theTransmittanceWalkReproducesTheOracle() throws {
        #expect(try VolumetricShadowWalk.transmittance(opacities: [0.5, 0.5]) == 0.25)
        // Exact extinction stops the walk; nothing restores light.
        #expect(try VolumetricShadowWalk.transmittance(opacities: [1, 0.25]) == 0)
        // The unobstructed light transmits exactly one.
        #expect(try VolumetricShadowWalk.transmittance(opacities: []) == 1)
        #expect(
            try VolumetricShadowWalk.transmittance(opacities: [0.1, 0.7, 0.9])
                == 0x1.ba5e353f7ced9p-6
        )
    }

    @Test("[Unit][VOX-PRR-005] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: VolumetricIlluminationError.nonFiniteComponent) {
            _ = try VolumetricShadowWalk.transmittance(opacities: [.nan])
        }
        #expect(throws: VolumetricIlluminationError.invalidOpacity) {
            _ = try VolumetricShadowWalk.transmittance(opacities: [1.5])
        }
    }
}
