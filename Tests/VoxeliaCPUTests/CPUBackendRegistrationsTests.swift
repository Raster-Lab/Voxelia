// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution

@testable import VoxeliaCPU

@Suite("CPUBackendRegistrations")
struct CPUBackendRegistrationsTests {
    @Test("[Unit][VOX-ARC-010][VOX-ERR-001] the standard registry names every implementation")
    func standardRegistryNamesEveryImplementation() throws {
        // All eleven CPU implementations register with tokens
        // structurally equal to the operations' own constants, the
        // pinned current contract versions, and the CPU backend
        // claim.
        let registry = try CPUBackendRegistrations.standard()
        #expect(registry.implementations.count == 11)
        #expect(
            registry.implementations.allSatisfy {
                $0.backend.rawValue == "org.voxelia.backend.cpu"
            }
        )
        let windowEntries = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: WindowLevelOperation.operationIdentifier
            )
        )
        #expect(windowEntries.count == 1)
        #expect(
            windowEntries[0].operationVersion
                == (try SemanticVersion(major: 1, minor: 5, patch: 0))
        )
        #expect(
            windowEntries[0].implementation.identifier.rawValue
                == WindowLevelOperation.implementationIdentifier
        )
        #expect(
            windowEntries[0].precisionPolicy.rawValue
                == "org.voxelia.precision.binary64-strict"
        )
        let operationTokens = Set(registry.implementations.map(\.operationID.rawValue))
        #expect(
            operationTokens == [
                RegionExtractionOperation.operationIdentifier,
                WindowLevelOperation.operationIdentifier,
                ResampleNearestOperation.operationIdentifier,
                CompositeLayersOperation.operationIdentifier,
                InvertDisplayOperation.operationIdentifier,
                TransposeAxesOperation.operationIdentifier,
                SqueezeAxesOperation.operationIdentifier,
                ResampleLinearOperation.operationIdentifier,
                ObliqueSliceOperation.operationIdentifier,
                ProjectIntensityOperation.operationIdentifier,
                ResampleCubicOperation.operationIdentifier,
            ]
        )

        // Duplicate registration rejects typed.
        do {
            _ = try ImplementationRegistry(
                implementations: [
                    registry.implementations[0], registry.implementations[0],
                ]
            )
            #expect(Bool(false), "Expected a duplicate registration to be rejected.")
        } catch RegistrationError.duplicateImplementation {}

        requireSendable(ImplementationRegistry.self)
        requireSendable(RegisteredImplementation.self)
        requireSendable(RegistrationError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
