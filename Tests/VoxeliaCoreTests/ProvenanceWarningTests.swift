// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("ProvenanceWarning")
struct ProvenanceWarningTests {
    @Test("[Unit][VOX-SEC-006][VOX-SEC-011] code limits precede grammar")
    func codeLimitsPrecedeGrammar() throws {
        for valid in ["a.b", "org.voxelia.warning.partial-input", "0a.b-1.c2"] {
            _ = try ProvenanceWarningCode(rawValue: valid)
        }
        for invalid in ["", "org", "Org.b", "a..b", "-a.b", "a-.b", "a_b.c"] {
            do {
                _ = try ProvenanceWarningCode(rawValue: invalid)
                #expect(Bool(false), "Expected an invalid code to be rejected.")
            } catch ProvenanceWarningError.invalidCode {}
        }

        // Byte ceilings are checked before grammar.
        let label63 = String(repeating: "a", count: 63)
        _ = try ProvenanceWarningCode(rawValue: "\(label63).b")
        do {
            _ = try ProvenanceWarningCode(
                rawValue: String(repeating: "A", count: 64) + ".b"
            )
            #expect(Bool(false), "Expected the label ceiling to precede grammar.")
        } catch ProvenanceWarningError.codeByteLimitExceeded {}
        let total255 = [String](repeating: label63, count: 4).joined(separator: ".")
        _ = try ProvenanceWarningCode(rawValue: total255)
        do {
            _ = try ProvenanceWarningCode(rawValue: "_" + total255)
            #expect(Bool(false), "Expected the total ceiling to precede grammar.")
        } catch ProvenanceWarningError.codeByteLimitExceeded {}

        // Rejection never discloses the code text.
        do {
            _ = try ProvenanceWarningCode(rawValue: "Patient Sentinel")
            #expect(Bool(false), "Expected an invalid code to be rejected.")
        } catch let error as ProvenanceWarningError {
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("Patient"))
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-ERR-002] warnings aggregate as exact free-text-less values")
    func warningsAggregateAsExactValues() throws {
        let code = try ProvenanceWarningCode(
            rawValue: "org.voxelia.warning.partial-input"
        )
        let version = ProvenanceWarningSchemaVersion(major: 1, minor: 0)

        // A zero occurrence count is rejected typed.
        do {
            _ = try ProvenanceWarning(
                code: code,
                schemaVersion: version,
                severity: .informational,
                occurrenceCount: 0
            )
            #expect(Bool(false), "Expected a zero count to be rejected.")
        } catch ProvenanceWarningError.invalidOccurrenceCount {}

        // Every field participates in warning identity.
        let base = try ProvenanceWarning(
            code: code,
            schemaVersion: version,
            severity: .qualityAffecting,
            occurrenceCount: 3
        )
        let same = try ProvenanceWarning(
            code: try ProvenanceWarningCode(
                rawValue: "org.voxelia.warning.partial-input"
            ),
            schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
            severity: .qualityAffecting,
            occurrenceCount: 3
        )
        #expect(base == same)
        #expect(Set([base, same]).count == 1)

        let variants = [
            try ProvenanceWarning(
                code: try ProvenanceWarningCode(
                    rawValue: "org.voxelia.warning.clipped-output"
                ),
                schemaVersion: version,
                severity: .qualityAffecting,
                occurrenceCount: 3
            ),
            try ProvenanceWarning(
                code: code,
                schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 1),
                severity: .qualityAffecting,
                occurrenceCount: 3
            ),
            try ProvenanceWarning(
                code: code,
                schemaVersion: version,
                severity: .integrityAffecting,
                occurrenceCount: 3
            ),
            try ProvenanceWarning(
                code: code,
                schemaVersion: version,
                severity: .qualityAffecting,
                occurrenceCount: 4
            ),
        ]
        for variant in variants {
            #expect(variant != base)
        }
        #expect(Set(variants + [base]).count == variants.count + 1)

        // The shape holds no free-text member: its children are exactly
        // the code, schema version, severity and count.
        let mirror = Mirror(reflecting: base)
        #expect(
            mirror.children.map(\.label) == [
                "code", "schemaVersion", "severity", "occurrenceCount",
            ]
        )

        requireSendable(ProvenanceWarning.self)
        requireSendable(ProvenanceWarningCode.self)
        requireSendable(ProvenanceWarningSchemaVersion.self)
        requireSendable(ProvenanceWarningSeverity.self)
        requireSendable(ProvenanceWarningError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
