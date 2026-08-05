// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCPU
import VoxeliaCore
import VoxeliaExecution
import VoxeliaMetal

@testable import VoxeliaValidation

@Suite("CombinedRegistry")
struct CombinedRegistryTests {
    @Test("[Unit][VOX-CCH-001][VOX-ARC-010] both backends register into one registry")
    func bothBackendsRegisterIntoOneRegistry() throws {
        // The combined CPU-plus-metal registry constructs without
        // collision: fifteen implementations across two backends, with
        // dual-implementation operations listing both.
        let combined = try ImplementationRegistry(
            implementations: try CPUBackendRegistrations.standard().implementations
                + (try MetalBackendRegistrations.standard().implementations)
        )
        #expect(combined.implementations.count == 15)
        let windowEntries = combined.implementations(
            for: try DerivationOperationToken(
                rawValue: WindowLevelOperation.operationIdentifier
            )
        )
        #expect(windowEntries.count == 2)
        #expect(
            Set(windowEntries.map(\.backend.rawValue)) == [
                "org.voxelia.backend.cpu", "org.voxelia.backend.metal",
            ]
        )
    }
}
