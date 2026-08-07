// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCPU
import VoxeliaCore
import VoxeliaExecution

@testable import VoxeliaValidation

@Suite("DiagnosticSelection")
struct DiagnosticSelectionTests {
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
            ),
            // The provider string CLAIMS to be first-party: approval
            // must key on the distribution's registry, not this string.
            provider: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(major: 0, minor: 2, patch: 0),
                commit: nil,
                buildIdentifier: nil
            )
        )
    }

    @Test("[Unit][VOX-EXT-006] an unapproved third-party entry refuses typed")
    func anUnapprovedThirdPartyEntryRefusesTyped() throws {
        let distribution = try CPUBackendRegistrations.standard()
        let approvals = DiagnosticApprovalSet(
            distributionApproved: distribution,
            hostApproved: []
        )
        // A spoofed provider name gains nothing.
        #expect(throws: DiagnosticSelectionError.unapprovedThirdPartyImplementation) {
            try DiagnosticSelection.requireDiagnostic(
                try thirdPartyEntry(),
                approvals: approvals
            )
        }
        // Every distribution entry passes the same seam.
        for entry in distribution.implementations {
            try DiagnosticSelection.requireDiagnostic(entry, approvals: approvals)
        }
    }

    @Test("[Unit][VOX-EXT-006] explicit host approval admits, exactly by reference")
    func explicitHostApprovalAdmitsExactlyByReference() throws {
        let distribution = try CPUBackendRegistrations.standard()
        let entry = try thirdPartyEntry()
        let approvals = DiagnosticApprovalSet(
            distributionApproved: distribution,
            hostApproved: [entry.implementation]
        )
        try DiagnosticSelection.requireDiagnostic(entry, approvals: approvals)

        // Approval never survives a version change silently: the same
        // identifier at a new version is a different reference.
        let upgraded = RegisteredImplementation(
            operationID: entry.operationID,
            operationVersion: entry.operationVersion,
            implementation: DerivationImplementationReference(
                identifier: entry.implementation.identifier,
                version: try SemanticVersion(major: 1, minor: 1, patch: 0)
            ),
            backend: entry.backend,
            precisionPolicy: entry.precisionPolicy,
            approximationStatus: entry.approximationStatus,
            evidence: entry.evidence,
            declaredContract: entry.declaredContract,
            provider: entry.provider
        )
        #expect(throws: DiagnosticSelectionError.unapprovedThirdPartyImplementation) {
            try DiagnosticSelection.requireDiagnostic(upgraded, approvals: approvals)
        }
    }

    @Test("[Unit][VOX-EXT-006] the diagnostic candidate list excludes the unapproved")
    func theDiagnosticCandidateListExcludesTheUnapproved() throws {
        let distribution = try CPUBackendRegistrations.standard()
        let combined = try ImplementationRegistry(
            implementations: distribution.implementations + [try thirdPartyEntry()]
        )
        let approvals = DiagnosticApprovalSet(
            distributionApproved: distribution,
            hostApproved: []
        )
        let candidates = DiagnosticSelection.implementationsForDiagnosticUse(
            in: combined,
            approvals: approvals
        )
        #expect(candidates.count == distribution.implementations.count)
        #expect(
            !candidates.contains {
                $0.implementation.identifier.rawValue
                    == "com.example.impl.vesselness.cpu"
            }
        )
    }
}
