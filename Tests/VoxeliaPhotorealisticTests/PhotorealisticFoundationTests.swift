// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

@Suite("PhotorealisticFoundation")
struct PhotorealisticFoundationTests {
    @Test("[Unit][VOX-PRR-001][VOX-PRR-003] the module carries the closed mode triad")
    func theModuleCarriesTheClosedModeTriad() throws {
        // The VOX-PRR-003 triad, verbatim; a fourth case would fail
        // this exhaustive witness at compile time.
        let modes: [PhotorealisticQualityMode] = [
            .interactive, .progressive, .reference,
        ]
        for mode in modes {
            switch mode {
            case .interactive, .progressive, .reference:
                continue
            }
        }
        #expect(PhotorealisticQualityMode(rawValue: "automatic") == nil)
    }

    @Test("[Unit][VOX-PRR-002] the host's disable refuses typed at the gate")
    func theHostsDisableRefusesTypedAtTheGate() throws {
        try PhotorealisticGate.requireEnabled(.enabled)
        #expect(throws: PhotorealisticActivationError.disabledByHost) {
            try PhotorealisticGate.requireEnabled(.disabledByHost)
        }
        // Conventional rendering is untouched by construction: this
        // module does not import VoxeliaRendering at all, and the
        // conventional suites in VoxeliaRenderingTests keep passing
        // with this module absent from their dependency graphs.
    }
}
