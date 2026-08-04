// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("ProvenanceClaims")
struct ProvenanceClaimsTests {
    private func version(
        buildMetadata: String? = nil
    ) throws -> SemanticVersion {
        try SemanticVersion(
            major: 1,
            minor: 2,
            patch: 3,
            buildMetadata: buildMetadata
        )
    }

    private func parameterDigest() throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )
    }

    @Test("[Unit][VOX-META-003][VOX-SEC-006] leaf fields validate with limit precedence")
    func leafFieldsValidateWithLimitPrecedence() throws {
        // Software identity fields use the identity field profile with
        // the ceiling checked before content rules.
        _ = try SoftwareIdentity(
            name: "Voxelia",
            version: try version(),
            commit: "0abc123",
            buildIdentifier: nil
        )
        let long255 = String(repeating: "a", count: 255)
        _ = try SoftwareIdentity(
            name: long255,
            version: try version(),
            commit: nil,
            buildIdentifier: nil
        )
        do {
            _ = try SoftwareIdentity(
                name: "\u{0007}" + long255,
                version: try version(),
                commit: nil,
                buildIdentifier: nil
            )
            #expect(Bool(false), "Expected the ceiling to precede content rules.")
        } catch ProvenanceClaimError.fieldByteLimitExceeded {}
        for invalid in ["", "  ", "a\u{0000}b"] {
            do {
                _ = try SoftwareIdentity(
                    name: "Voxelia",
                    version: try version(),
                    commit: invalid,
                    buildIdentifier: nil
                )
                #expect(Bool(false), "Expected an invalid field to be rejected.")
            } catch ProvenanceClaimError.invalidField {}
        }

        // Roles use the single-label grammar with limit precedence, and
        // occurrence ordinals start at one.
        for valid in ["input", "frame-0", "a"] {
            _ = try ProvenanceInputRole(rawValue: valid)
        }
        for invalid in ["", "-a", "a-", "Input", "a.b"] {
            do {
                _ = try ProvenanceInputRole(rawValue: invalid)
                #expect(Bool(false), "Expected an invalid role to be rejected.")
            } catch ProvenanceClaimError.invalidRole {}
        }
        do {
            _ = try ProvenanceInputRole(
                rawValue: String(repeating: "A", count: 64)
            )
            #expect(Bool(false), "Expected the role ceiling to precede grammar.")
        } catch ProvenanceClaimError.roleByteLimitExceeded {}
        do {
            _ = try ProvenanceInput(
                role: try ProvenanceInputRole(rawValue: "input"),
                occurrence: 0,
                identity: .object(try #require(DataObjectID(rawValue: "series-7"))),
                parent: nil
            )
            #expect(Bool(false), "Expected a zero occurrence to be rejected.")
        } catch ProvenanceClaimError.invalidOccurrence {}

        // A foreign digest tuple can never masquerade as parameters, and
        // rejection stays payload-free.
        do {
            _ = try OperationProvenance(
                operationID: try DerivationOperationToken(
                    rawValue: "org.voxelia.op.window-level"
                ),
                operationVersion: try version(),
                implementationID: try DerivationOperationToken(
                    rawValue: "org.voxelia.impl.window-level.cpu"
                ),
                implementationVersion: try version(),
                parameterDigest: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [1, 2]
                )
            )
            #expect(Bool(false), "Expected a foreign digest tuple to be rejected.")
        } catch let error as ProvenanceClaimError {
            #expect(error == .unsupportedParameterProjection)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("sample"))
        }
    }

    @Test("[Unit][VOX-META-005][VOX-META-007] claims compare exactly including builds")
    func claimsCompareExactlyIncludingBuilds() throws {
        // Software identities distinguishable only by version build
        // metadata compare distinct while their versions compare equal.
        let base = try SoftwareIdentity(
            name: "Voxelia",
            version: try version(buildMetadata: "build7"),
            commit: "0abc123",
            buildIdentifier: "ci-42"
        )
        let same = try SoftwareIdentity(
            name: "Voxelia",
            version: try version(buildMetadata: "build7"),
            commit: "0abc123",
            buildIdentifier: "ci-42"
        )
        let otherBuild = try SoftwareIdentity(
            name: "Voxelia",
            version: try version(buildMetadata: "build8"),
            commit: "0abc123",
            buildIdentifier: "ci-42"
        )
        let noCommit = try SoftwareIdentity(
            name: "Voxelia",
            version: try version(buildMetadata: "build7"),
            commit: nil,
            buildIdentifier: "ci-42"
        )
        #expect(base == same)
        #expect(base.version == otherBuild.version)
        #expect(base != otherBuild)
        #expect(base != noCommit)
        #expect(Set([base, same, otherBuild, noCommit]).count == 3)

        // Operation claims compare implementation versions exactly.
        func operation(
            implementationBuild: String?
        ) throws -> OperationProvenance {
            try OperationProvenance(
                operationID: try DerivationOperationToken(
                    rawValue: "org.voxelia.op.window-level"
                ),
                operationVersion: try version(),
                implementationID: try DerivationOperationToken(
                    rawValue: "org.voxelia.impl.window-level.cpu"
                ),
                implementationVersion: try version(
                    buildMetadata: implementationBuild
                ),
                parameterDigest: try parameterDigest()
            )
        }
        let left = try operation(implementationBuild: "build7")
        let right = try operation(implementationBuild: "build8")
        #expect(left.implementationVersion == right.implementationVersion)
        #expect(left != right)

        // Validation claims carry exact evidence identity, and parent
        // references compare by exact node identity.
        let evidence = try #require(ValidationEvidenceID(rawValue: "évidence-7"))
        let evidenceAlias = try #require(
            ValidationEvidenceID(rawValue: "e\u{0301}vidence-7")
        )
        #expect(
            ProvenanceValidationClaim.validated(evidence)
                != ProvenanceValidationClaim.validated(evidenceAlias)
        )
        #expect(
            ProvenanceValidationClaim.validated(evidence)
                != ProvenanceValidationClaim.diagnosticReady(evidence)
        )
        #expect(
            Set<ProvenanceValidationClaim>([
                .unknown, .experimental, .preview, .validated(evidence),
                .diagnosticReady(evidence), .deprecated,
            ]).count == 6
        )
        let parent = ProvenanceParentReference.graphNode(
            try #require(ProvenanceID(rawValue: "node-1"))
        )
        #expect(
            parent
                == ProvenanceParentReference.graphNode(
                    try #require(ProvenanceID(rawValue: "node-1"))
                )
        )

        requireSendable(SoftwareIdentity.self)
        requireSendable(OperationProvenance.self)
        requireSendable(ProvenanceInputRole.self)
        requireSendable(ProvenanceInput.self)
        requireSendable(ProvenanceParentReference.self)
        requireSendable(ProvenanceValidationClaim.self)
        requireSendable(ValidationEvidenceID.self)
        requireSendable(ProvenanceClaimError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
