// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("ExecutionProvenanceClaim")
struct ExecutionProvenanceClaimTests {
    private func token(_ rawValue: String) throws -> ExecutionClaimToken {
        try ExecutionClaimToken(rawValue: rawValue)
    }

    private func component(
        _ identifier: String,
        _ major: Int = 1
    ) throws -> ExecutionComponentReference {
        try ExecutionComponentReference(
            identifier: token(identifier),
            version: try SemanticVersion(major: major, minor: 0, patch: 0)
        )
    }

    @Test("[Unit][VOX-EXE-011][VOX-SEC-011] token limits precede grammar")
    func tokenLimitsPrecedeGrammar() throws {
        for valid in ["a.b", "org.voxelia.precision.binary64-strict", "0a.b-1.c2"] {
            _ = try token(valid)
        }
        for invalid in ["", "org", "Org.b", "a..b", "-a.b", "a-.b", "a_b.c"] {
            do {
                _ = try token(invalid)
                #expect(Bool(false), "Expected an invalid token to be rejected.")
            } catch ExecutionClaimError.invalidToken {}
        }

        // Byte ceilings are checked before grammar: oversized input with
        // grammar violations still fails as a byte-limit error.
        let label63 = String(repeating: "a", count: 63)
        _ = try token("\(label63).b")
        do {
            _ = try token(String(repeating: "A", count: 64) + ".b")
            #expect(Bool(false), "Expected the label ceiling to precede grammar.")
        } catch ExecutionClaimError.tokenByteLimitExceeded {}
        let total255 = [String](repeating: label63, count: 4).joined(separator: ".")
        _ = try token(total255)
        do {
            _ = try token("_" + total255)
            #expect(Bool(false), "Expected the total ceiling to precede grammar.")
        } catch ExecutionClaimError.tokenByteLimitExceeded {}

        // Rejection never discloses the token text.
        do {
            _ = try token("Patient Sentinel")
            #expect(Bool(false), "Expected an invalid token to be rejected.")
        } catch let error as ExecutionClaimError {
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("Patient"))
        }
    }

    @Test("[Unit][VOX-EXE-012][VOX-ERR-001] claims are exact identity-bearing values")
    func claimsAreExactIdentityBearingValues() throws {
        // Build metadata does not participate in SemanticVersion equality,
        // so a component reference rejects it typed.
        do {
            _ = try ExecutionComponentReference(
                identifier: token("org.voxelia.backend.cpu"),
                version: try SemanticVersion(
                    major: 1,
                    minor: 0,
                    patch: 0,
                    buildMetadata: "build7"
                )
            )
            #expect(Bool(false), "Expected build metadata to be rejected.")
        } catch ExecutionClaimError.inexactVersion {}
        _ = try ExecutionComponentReference(
            identifier: token("org.voxelia.backend.cpu"),
            version: try SemanticVersion(major: 1, minor: 0, patch: 0, prerelease: "rc1")
        )

        // Every field participates in claim identity.
        let base = ExecutionProvenanceClaim(
            profile: try component("org.voxelia.profile.default"),
            backend: try component("org.voxelia.backend.cpu"),
            precisionPolicy: try token("org.voxelia.precision.binary64-strict"),
            qualityPolicy: try token("org.voxelia.quality.full"),
            approximationStatus: .exact,
            capabilityClass: nil,
            kernel: nil
        )
        let same = ExecutionProvenanceClaim(
            profile: try component("org.voxelia.profile.default"),
            backend: try component("org.voxelia.backend.cpu"),
            precisionPolicy: try token("org.voxelia.precision.binary64-strict"),
            qualityPolicy: try token("org.voxelia.quality.full"),
            approximationStatus: .exact,
            capabilityClass: nil,
            kernel: nil
        )
        #expect(base == same)
        #expect(Set([base, same]).count == 1)

        let variants = [
            ExecutionProvenanceClaim(
                profile: try component("org.voxelia.profile.default", 2),
                backend: base.backend,
                precisionPolicy: base.precisionPolicy,
                qualityPolicy: base.qualityPolicy,
                approximationStatus: .exact,
                capabilityClass: nil,
                kernel: nil
            ),
            ExecutionProvenanceClaim(
                profile: base.profile,
                backend: try component("org.voxelia.backend.metal"),
                precisionPolicy: base.precisionPolicy,
                qualityPolicy: base.qualityPolicy,
                approximationStatus: .exact,
                capabilityClass: nil,
                kernel: nil
            ),
            ExecutionProvenanceClaim(
                profile: base.profile,
                backend: base.backend,
                precisionPolicy: try token("org.voxelia.precision.binary32"),
                qualityPolicy: base.qualityPolicy,
                approximationStatus: .exact,
                capabilityClass: nil,
                kernel: nil
            ),
            ExecutionProvenanceClaim(
                profile: base.profile,
                backend: base.backend,
                precisionPolicy: base.precisionPolicy,
                qualityPolicy: try token("org.voxelia.quality.preview"),
                approximationStatus: .exact,
                capabilityClass: nil,
                kernel: nil
            ),
            ExecutionProvenanceClaim(
                profile: base.profile,
                backend: base.backend,
                precisionPolicy: base.precisionPolicy,
                qualityPolicy: base.qualityPolicy,
                approximationStatus: .approximate,
                capabilityClass: nil,
                kernel: nil
            ),
            ExecutionProvenanceClaim(
                profile: base.profile,
                backend: base.backend,
                precisionPolicy: base.precisionPolicy,
                qualityPolicy: base.qualityPolicy,
                approximationStatus: .exact,
                capabilityClass: try token("org.voxelia.capability.compute"),
                kernel: nil
            ),
            ExecutionProvenanceClaim(
                profile: base.profile,
                backend: base.backend,
                precisionPolicy: base.precisionPolicy,
                qualityPolicy: base.qualityPolicy,
                approximationStatus: .exact,
                capabilityClass: nil,
                kernel: try component("org.voxelia.kernel.window-level")
            ),
        ]
        for variant in variants {
            #expect(variant != base)
        }
        #expect(Set(variants + [base]).count == variants.count + 1)

        requireSendable(ExecutionProvenanceClaim.self)
        requireSendable(ExecutionComponentReference.self)
        requireSendable(ExecutionApproximationStatus.self)
        requireSendable(ExecutionClaimToken.self)
        requireSendable(ExecutionClaimError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
