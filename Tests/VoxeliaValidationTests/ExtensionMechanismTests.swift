// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCPU
import VoxeliaCore
import VoxeliaExecution

@testable import VoxeliaValidation

/// The `ADR-0379` witnesses: a third-party implementation defined
/// entirely inside this suite — no core module changed — registers
/// beside the standard entries, and identity collisions refuse typed.
@Suite("ExtensionMechanism")
struct ExtensionMechanismTests {
    /// A third-party entry under its own reverse-DNS namespace.
    private func thirdPartyEntry() throws -> RegisteredImplementation {
        RegisteredImplementation(
            operationID: try DerivationOperationToken(
                rawValue: "com.example.op.vesselness"
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            implementation: DerivationImplementationReference(
                identifier: try DerivationOperationToken(
                    rawValue: "com.example.impl.vesselness.cpu"
                ),
                version: try SemanticVersion(major: 1, minor: 0, patch: 0)
            ),
            backend: try ExecutionClaimToken(rawValue: "com.example.backend.cpu"),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.precision.binary64-strict"
            ),
            approximationStatus: .exact,
            evidence: try #require(
                ValidationEvidenceID(rawValue: "com-example-vesselness-1")
            ),
            declaredContract: try DeclaredImplementationContract(
                domain: .image(
                    ranks: .range(3...3),
                    scalars: .scalars([.float32]),
                    geometry: .requiresAffine
                ),
                qualityProfiles: [
                    try ExecutionClaimToken(rawValue: "org.voxelia.quality.full")
                ],
                capabilityRequirements: []
            )
        )
    }

    @Test("[Unit][VOX-EXT-002] a third-party entry registers without core changes")
    func aThirdPartyEntryRegistersWithoutCoreChanges() throws {
        // The host composes one registry from the built-in entries plus
        // the extension's: registration is data, not a patch.
        let standard = try CPUBackendRegistrations.standard()
        let extended = try ImplementationRegistry(
            implementations: standard.implementations + [try thirdPartyEntry()]
        )
        #expect(extended.implementations.count == standard.implementations.count + 1)

        let found = extended.implementations(
            for: try DerivationOperationToken(rawValue: "com.example.op.vesselness")
        )
        #expect(found.count == 1)
        #expect(
            found[0].implementation.identifier.rawValue
                == "com.example.impl.vesselness.cpu"
        )
        // The built-in entries are untouched beside it.
        #expect(
            extended.implementations(
                for: try DerivationOperationToken(
                    rawValue: LevelSelectOperation.operationIdentifier
                )
            ).count == 1
        )
    }

    @Test("[Unit][VOX-EXT-004] a duplicate identity pair refuses typed")
    func aDuplicateIdentityPairRefusesTyped() throws {
        let entry = try thirdPartyEntry()
        #expect(throws: RegistrationError.duplicateImplementation) {
            _ = try ImplementationRegistry(implementations: [entry, entry])
        }
    }
}
