// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("DerivationIdentity")
struct DerivationIdentityTests {
    private func parameterDigest() throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )
    }

    private func input(_ role: String, _ objectName: String) throws -> DerivationInput {
        DerivationInput(
            role: try DerivationInputRole(rawValue: role),
            identity: .object(try #require(DataObjectID(rawValue: objectName)))
        )
    }

    @Test("[Unit][VOX-DAT-014][VOX-ERR-001] construction enforces the closed contract")
    func constructionEnforcesTheClosedContract() throws {
        let operation = try DerivationOperationToken(
            rawValue: "org.voxelia.op.window-level"
        )
        let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
        let digest = try parameterDigest()

        // Role grammar: single lowercase label with the ceiling checked
        // before the grammar.
        for valid in ["input", "minuend", "frame-0", "a"] {
            _ = try DerivationInputRole(rawValue: valid)
        }
        for invalid in ["", "-a", "a-", "Input", "a.b", "a_b"] {
            do {
                _ = try DerivationInputRole(rawValue: invalid)
                #expect(Bool(false), "Expected an invalid role to be rejected.")
            } catch DerivationIdentityError.invalidRole {}
        }
        _ = try DerivationInputRole(rawValue: String(repeating: "a", count: 63))
        do {
            _ = try DerivationInputRole(
                rawValue: String(repeating: "A", count: 64)
            )
            #expect(Bool(false), "Expected the role ceiling to precede grammar.")
        } catch DerivationIdentityError.roleByteLimitExceeded {}

        // Operation tokens use the reverse-domain grammar with limit
        // precedence.
        do {
            _ = try DerivationOperationToken(rawValue: "windowlevel")
            #expect(Bool(false), "Expected a single-label token to be rejected.")
        } catch DerivationIdentityError.invalidToken {}
        do {
            _ = try DerivationOperationToken(
                rawValue: String(repeating: "A", count: 64) + ".b"
            )
            #expect(Bool(false), "Expected the token ceiling to precede grammar.")
        } catch DerivationIdentityError.tokenByteLimitExceeded {}

        // An empty input sequence needs the explicit declaration, and the
        // declaration rejects inputs.
        do {
            _ = try DerivationIdentity(
                operationID: operation,
                operationVersion: version,
                implementation: nil,
                inputs: [],
                parameterDigest: digest,
                declaresZeroInputGenerator: false
            )
            #expect(Bool(false), "Expected an undeclared empty sequence to be rejected.")
        } catch DerivationIdentityError.emptyInputSequence {}
        do {
            _ = try DerivationIdentity(
                operationID: operation,
                operationVersion: version,
                implementation: nil,
                inputs: [try input("input", "series-7")],
                parameterDigest: digest,
                declaresZeroInputGenerator: true
            )
            #expect(Bool(false), "Expected a declared generator with inputs to be rejected.")
        } catch DerivationIdentityError.unexpectedInputSequence {}
        _ = try DerivationIdentity(
            operationID: operation,
            operationVersion: version,
            implementation: nil,
            inputs: [],
            parameterDigest: digest,
            declaresZeroInputGenerator: true
        )

        // Foreign digest tuples can never masquerade as parameters.
        for foreign in [
            try ContentID.completeMetadataRecordIdentity(overCanonicalBytes: [1, 2]),
            try ContentID.sampleBytesIdentity(overCanonicalPackedBytes: [1, 2]),
        ] {
            do {
                _ = try DerivationIdentity(
                    operationID: operation,
                    operationVersion: version,
                    implementation: nil,
                    inputs: [try input("input", "series-7")],
                    parameterDigest: foreign,
                    declaresZeroInputGenerator: false
                )
                #expect(Bool(false), "Expected a foreign digest tuple to be rejected.")
            } catch DerivationIdentityError.unsupportedParameterProjection {}
        }

        // Rejections stay payload-free.
        do {
            _ = try DerivationOperationToken(rawValue: "Patient Sentinel")
            #expect(Bool(false), "Expected an invalid token to be rejected.")
        } catch let error as DerivationIdentityError {
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("Patient"))
        }
    }

    @Test("[Unit][VOX-CCH-004][VOX-RGN-007] identity is exact including build metadata")
    func identityIsExactIncludingBuildMetadata() throws {
        let operation = try DerivationOperationToken(
            rawValue: "org.voxelia.op.window-level"
        )
        let implementationToken = try DerivationOperationToken(
            rawValue: "org.voxelia.impl.window-level.cpu"
        )
        let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
        let digest = try parameterDigest()

        func identity(
            buildMetadata: String?,
            inputs: ContiguousArray<DerivationInput>
        ) throws -> DerivationIdentity {
            try DerivationIdentity(
                operationID: operation,
                operationVersion: version,
                implementation: DerivationImplementationReference(
                    identifier: implementationToken,
                    version: try SemanticVersion(
                        major: 2,
                        minor: 1,
                        patch: 0,
                        buildMetadata: buildMetadata
                    )
                ),
                inputs: inputs,
                parameterDigest: digest,
                declaresZeroInputGenerator: false
            )
        }

        let single: ContiguousArray = [try input("input", "series-7")]
        let base = try identity(buildMetadata: "build7", inputs: single)
        let same = try identity(buildMetadata: "build7", inputs: single)
        #expect(base == same)
        #expect(Set([base, same]).count == 1)

        // Implementations distinguishable only by build metadata compare
        // distinct, while their semantic versions compare equal.
        let otherBuild = try identity(buildMetadata: "build8", inputs: single)
        let noBuild = try identity(buildMetadata: nil, inputs: single)
        #expect(
            base.implementation?.version == otherBuild.implementation?.version
        )
        #expect(base != otherBuild)
        #expect(base != noBuild)
        #expect(Set([base, otherBuild, noBuild]).count == 3)

        // Repeats and order are preserved and participate in identity.
        let repeated = try identity(
            buildMetadata: "build7",
            inputs: [
                try input("input", "series-7"), try input("input", "series-7"),
            ]
        )
        let reordered = try identity(
            buildMetadata: "build7",
            inputs: [
                try input("mask", "series-8"), try input("input", "series-7"),
            ]
        )
        let ordered = try identity(
            buildMetadata: "build7",
            inputs: [
                try input("input", "series-7"), try input("mask", "series-8"),
            ]
        )
        #expect(repeated != base)
        #expect(reordered != ordered)

        // Roles participate in input identity.
        let renamed = try identity(
            buildMetadata: "build7",
            inputs: [try input("mask", "series-7")]
        )
        #expect(renamed != base)

        requireSendable(DerivationIdentity.self)
        requireSendable(DerivationInput.self)
        requireSendable(DerivationInputRole.self)
        requireSendable(DerivationOperationToken.self)
        requireSendable(DerivationImplementationReference.self)
        requireSendable(DerivationIdentityError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
