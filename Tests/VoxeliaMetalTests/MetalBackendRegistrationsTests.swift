// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution

@testable import VoxeliaMetal

@Suite("MetalBackendRegistrations")
struct MetalBackendRegistrationsTests {
    @Test("[Unit][VOX-ARC-011][VOX-ERR-001] the device registrations state their contracts")
    func deviceRegistrationsStateTheirContracts() throws {
        // The three device implementations register with their honest
        // split versions and claims.
        let registry = try MetalBackendRegistrations.standard()
        #expect(registry.implementations.count == 3)
        #expect(
            registry.implementations.allSatisfy {
                $0.backend.rawValue == "org.voxelia.backend.metal"
            }
        )
        let window = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: WindowLevelOperation.operationIdentifier
            )
        )
        #expect(window.count == 1)
        #expect(
            window[0].operationVersion
                == (try SemanticVersion(major: 1, minor: 4, patch: 0))
        )
        #expect(
            window[0].implementation.version
                == (try SemanticVersion(major: 1, minor: 1, patch: 0))
        )
        #expect(window[0].approximationStatus == .approximate)
        let invert = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: InvertDisplayOperation.operationIdentifier
            )
        )
        #expect(invert.count == 1)
        #expect(invert[0].precisionPolicy.rawValue == "org.voxelia.precision.exact")
        #expect(invert[0].approximationStatus == .exact)

    }
}
