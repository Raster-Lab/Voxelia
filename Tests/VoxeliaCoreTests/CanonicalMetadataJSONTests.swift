// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("CanonicalMetadataJSON")
struct CanonicalMetadataJSONTests {
    private let emptyEnvelope =
        #"{"documentSchema":{"identifier":"org.voxelia.metadata-document","#
        + #""version":{"major":1,"minor":0}},"multiplicitySchema":null,"#
        + #""payload":{"entries":[]}}"#

    private func envelope(entries: String) -> String {
        #"{"documentSchema":{"identifier":"org.voxelia.metadata-document","#
            + #""version":{"major":1,"minor":0}},"multiplicitySchema":null,"#
            + #""payload":{"entries":[\#(entries)]}}"#
    }

    private func entryJSON(value: String) -> String {
        #"{"key":{"name":"n","namespace":"s"},"privacyClass":"technical","#
            + #""value":\#(value)}"#
    }

    private func key(_ namespace: String, _ name: String) throws -> AnyMetadataKey {
        try AnyMetadataKey(namespace: namespace, name: name)
    }

    private func entry(
        _ namespace: String,
        _ name: String,
        value: MetadataValue,
        privacyClass: MetadataPrivacyClass = .technical
    ) throws -> MetadataEntry {
        MetadataEntry(
            key: try key(namespace, name),
            value: value,
            privacyClass: privacyClass
        )
    }

    private func generousLimits(
        rawDocument: UInt64 = 10_000_000,
        rawToken: UInt64 = 1_000_000,
        decodedString: UInt64 = 1_000_000,
        encodedBinary: UInt64 = 1_000_000,
        decodedBinary: UInt64 = 1_000_000,
        directMembers: UInt64 = 1_000_000,
        rawDepth: UInt64 = 198
    ) -> CanonicalMetadataIngressLimits {
        CanonicalMetadataIngressLimits(
            maximumRawDocumentByteCount: rawDocument,
            maximumRawTokenByteCount: rawToken,
            maximumDecodedStringByteCount: decodedString,
            maximumEncodedBinaryByteCount: encodedBinary,
            maximumDecodedBinaryByteCount: decodedBinary,
            maximumDirectMemberCount: directMembers,
            maximumRawNestingDepth: rawDepth
        )
    }

    private func decode(
        _ document: String,
        limits: CanonicalMetadataIngressLimits? = nil,
        context: CanonicalMultiplicityContext? = nil
    ) throws -> CanonicalMetadataDocument {
        try CanonicalMetadataJSON.decodeDocument(
            canonicalBytes: Array(document.utf8),
            limits: limits ?? generousLimits(),
            multiplicityContext: context
        )
    }

    @Test("[Unit][CDMS-55.2][VOX-API-004] the empty envelope is byte-exact")
    func emptyEnvelopeIsByteExact() throws {
        let empty = try MetadataCollection(entries: [MetadataEntry]())
        let encoded = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: empty,
            maximumOutputByteCount: 4_096
        )
        #expect(String(decoding: encoded, as: UTF8.self) == emptyEnvelope)

        let document = try decode(emptyEnvelope)
        #expect(document.payload.entries.isEmpty)
        #expect(document.multiplicitySchema == nil)
        #expect(
            document.documentSchema.identifier
                == CanonicalMetadataJSON.documentSchemaIdentifier
        )
        #expect(
            document.documentSchema.version
                == CanonicalMetadataJSON.documentSchemaVersion
        )

        requireSendable(CanonicalMetadataDocument.self)
        requireSendable(MetadataSchemaReference.self)
        requireSendable(MetadataJSONIngressError.self)
        requireSendable(MetadataJSONEmissionError.self)
    }

    @Test("[Unit][CDMS-55.3][VOX-API-004] a golden document round trips exactly")
    func goldenDocumentRoundTripsExactly() throws {
        let nested = try MetadataObject(members: [
            .init(key: try key("inner", "flag"), value: .boolean(false)),
            .init(
                key: try key("inner", "list"),
                value: .array(
                    try MetadataArray(values: [
                        .string("caf\u{E9}"), .string("cafe\u{301}"),
                    ])
                )
            ),
        ])
        let collection = try MetadataCollection(entries: [
            try entry("t", "boolean", value: .boolean(true), privacyClass: .publicData),
            try entry("t", "signed", value: .signedInteger(Int64.min)),
            try entry("t", "unsigned", value: .unsignedInteger(UInt64.max)),
            try entry(
                "t",
                "floating",
                value: .floatingPoint(try MetadataFloatingPoint(value: 0.001))
            ),
            try entry("t", "escapes", value: .string("a\"b\\c\u{0B}d\ne")),
            try entry(
                "t",
                "binary",
                value: .binary(MetadataBinary(bytes: [0x66] as [UInt8]))
            ),
            try entry(
                "t",
                "instant",
                value: .instant(try CanonicalInstant(utcString: "2026-08-04T00:00:00Z"))
            ),
            try entry(
                "t",
                "unit",
                value: .unit(
                    try MeasurementUnit(
                        namespace: "UCUM",
                        code: "mm",
                        displayName: "millimetre",
                        dimension: .length,
                        scaleToCanonical: 0.001
                    )
                )
            ),
            try entry(
                "t",
                "code",
                value: .code(try CodedConcept(scheme: "s", value: "v")),
                privacyClass: .hostDefined
            ),
            try entry("t", "object", value: .object(nested), privacyClass: .sensitive),
        ])

        let encoded = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: collection,
            maximumOutputByteCount: 1_000_000
        )
        let text = String(decoding: encoded, as: UTF8.self)

        // Spot-check the exact canonical token spellings.
        #expect(text.contains(#"{"signedInteger":"-9223372036854775808"}"#))
        #expect(text.contains(#"{"unsignedInteger":"18446744073709551615"}"#))
        #expect(text.contains(#"{"floatingPoint":0.001}"#))
        #expect(text.contains(#"{"string":"a\"b\\c\u000bd\ne"}"#))
        #expect(text.contains(#"{"binary":"Zg=="}"#))
        #expect(
            text.contains(
                #"{"unit":{"code":"mm","dimension":"length","displayName":"millimetre","#
                    + #""namespace":"UCUM","offsetToCanonical":null,"#
                    + #""scaleToCanonical":0.001}}"#
            )
        )
        #expect(
            text.contains(
                #"{"code":{"meaning":null,"scheme":"s","value":"v","version":null}}"#
            )
        )

        // Decode, compare semantically, re-encode byte-identically.
        let document = try decode(text)
        #expect(document.payload == collection)
        let reencoded = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: document.payload,
            maximumOutputByteCount: 1_000_000
        )
        #expect(reencoded == encoded)

        // Exact UTF-8 identity survives: the NFC and NFD spellings stay
        // byte-distinct through the round trip.
        guard case .object(let decodedNested) = document.payload.entries[9].value
        else {
            #expect(Bool(false), "Expected the nested object entry.")
            return
        }
        guard case .array(let list) = decodedNested.members[1].value else {
            #expect(Bool(false), "Expected the nested list.")
            return
        }
        #expect(list.values[0] == .string("caf\u{E9}"))
        #expect(list.values[1] == .string("cafe\u{301}"))
        #expect(document.payload.entries[8].privacyClass == .hostDefined)
    }

    @Test("[Unit][CDMS-55.3][VOX-VAL-011] number tokens match the RFC 8785 profile")
    func numberTokensMatchRFC8785Profile() throws {
        let vectors: [(Double, String)] = [
            (0.0, "0"),
            (-0.0, "0"),
            (1.0, "1"),
            (-1.5, "-1.5"),
            (0.001, "0.001"),
            (1e-6, "0.000001"),
            (1e-7, "1e-7"),
            (1e20, "100000000000000000000"),
            (1e21, "1e+21"),
            (Double(bitPattern: 0x444B_1AE4_D6E2_EF50), "1e+21"),
            (9_007_199_254_740_992.0, "9007199254740992"),
            (Double.leastNonzeroMagnitude, "5e-324"),
            (-Double.leastNonzeroMagnitude, "-5e-324"),
            (Double.greatestFiniteMagnitude, "1.7976931348623157e+308"),
            (333_333_333.333_333_2, "333333333.3333332"),
        ]
        for (value, expected) in vectors {
            let token = CanonicalMetadataJSON.canonicalNumberToken(value)
            #expect(token.map { String(decoding: $0, as: UTF8.self) } == expected)
        }
        #expect(CanonicalMetadataJSON.canonicalNumberToken(.infinity) == nil)
        #expect(CanonicalMetadataJSON.canonicalNumberToken(.nan) == nil)

        // Deterministic random-bit self-consistency: every finite pattern
        // re-parses to the identical value and stays within the analytic
        // 25-byte canonical maximum.
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        var checked = 0
        while checked < 512 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let value = Double(bitPattern: state)
            guard value.isFinite else {
                continue
            }
            checked += 1
            guard let token = CanonicalMetadataJSON.canonicalNumberToken(value) else {
                #expect(Bool(false), "Expected a finite value to produce a token.")
                return
            }
            #expect(token.count <= 25)
            let reparsed = Double(String(decoding: token, as: UTF8.self))
            #expect(reparsed == value || (value == 0 && reparsed == 0))
        }
    }

    @Test("[Unit][CDMS-55.3][VOX-ERR-001] strict ingress rejects noncanonical bytes")
    func strictIngressRejectsNoncanonicalBytes() throws {
        let invalidDocuments: [String] = [
            // UTF-8 BOM.
            "\u{FEFF}" + emptyEnvelope,
            // Insignificant whitespace.
            " " + emptyEnvelope,
            emptyEnvelope + "\n",
            emptyEnvelope.replacingOccurrences(
                of: #""multiplicitySchema":null"#,
                with: #""multiplicitySchema": null"#
            ),
            // Trailing data.
            emptyEnvelope + "{}",
            // Reordered envelope members.
            #"{"multiplicitySchema":null,"documentSchema":{"identifier":"#
                + #""org.voxelia.metadata-document","version":{"major":1,"minor":0}},"#
                + #""payload":{"entries":[]}}"#,
            // Escape-equivalent spelling of a fixed member name.
            emptyEnvelope.replacingOccurrences(
                of: #""payload""#,
                with: #""\u0070ayload""#
            ),
            // Wrong document identifier.
            emptyEnvelope.replacingOccurrences(of: "org.voxelia", with: "org.example"),
            // Malformed version alias.
            emptyEnvelope.replacingOccurrences(of: #""major":1"#, with: #""major":01"#),
            // Unknown value tag.
            envelope(entries: entryJSON(value: #"{"double":1}"#)),
            // Reordered entry members.
            envelope(
                entries: #"{"privacyClass":"technical","#
                    + #""key":{"name":"n","namespace":"s"},"value":{"boolean":true}}"#
            ),
            // Duplicate raw entry member.
            envelope(
                entries: #"{"key":{"name":"n","namespace":"s"},"#
                    + #""key":{"name":"o","namespace":"s"},"privacyClass":"technical","#
                    + #""value":{"boolean":true}}"#
            ),
            // Unknown privacy token never becomes hostDefined.
            envelope(
                entries: #"{"key":{"name":"n","namespace":"s"},"#
                    + #""privacyClass":"secret","value":{"boolean":true}}"#
            ),
            // Numeric integer payloads are ordinary Codable, not VCMJ-1.
            envelope(entries: entryJSON(value: #"{"signedInteger":-1}"#)),
            // Integer string aliases.
            envelope(entries: entryJSON(value: #"{"signedInteger":"+1"}"#)),
            envelope(entries: entryJSON(value: #"{"signedInteger":"-0"}"#)),
            envelope(entries: entryJSON(value: #"{"unsignedInteger":"01"}"#)),
            envelope(
                entries: entryJSON(value: #"{"signedInteger":"9223372036854775808"}"#)
            ),
            envelope(
                entries: entryJSON(value: #"{"unsignedInteger":"18446744073709551616"}"#)
            ),
            // Floating aliases of canonical tokens.
            envelope(entries: entryJSON(value: #"{"floatingPoint":-0}"#)),
            envelope(entries: entryJSON(value: #"{"floatingPoint":1.0}"#)),
            envelope(entries: entryJSON(value: #"{"floatingPoint":1e0}"#)),
            // Noncanonical string escapes: escaped solidus, escaped
            // ordinary letter, uppercase hexadecimal and an unpaired
            // surrogate spelling.
            envelope(entries: entryJSON(value: #"{"string":"\/"}"#)),
            envelope(entries: entryJSON(value: #"{"string":"\u0041"}"#)),
            envelope(entries: entryJSON(value: #"{"string":"\u000B"}"#)),
            envelope(entries: entryJSON(value: #"{"string":"\ud800"}"#)),
            // Base64 aliases and pad-bit violations.
            envelope(entries: entryJSON(value: #"{"binary":"Zh=="}"#)),
            envelope(entries: entryJSON(value: #"{"binary":"Zg"}"#)),
            envelope(entries: entryJSON(value: #"{"binary":"-g=="}"#)),
            // Unsorted and duplicate recursive object members.
            envelope(
                entries: entryJSON(
                    value: #"{"object":["#
                        + #"{"key":{"name":"b","namespace":"s"},"value":{"boolean":true}},"#
                        + #"{"key":{"name":"a","namespace":"s"},"value":{"boolean":true}}]}"#
                )
            ),
            envelope(
                entries: entryJSON(
                    value: #"{"object":["#
                        + #"{"key":{"name":"a","namespace":"s"},"value":{"boolean":true}},"#
                        + #"{"key":{"name":"a","namespace":"s"},"value":{"boolean":false}}]}"#
                )
            ),
            // Repeated entry key without a policy.
            envelope(
                entries: entryJSON(value: #"{"boolean":true}"#) + ","
                    + entryJSON(value: #"{"boolean":false}"#)
            ),
            // Blank semantic identity field.
            envelope(
                entries: #"{"key":{"name":" ","namespace":"s"},"#
                    + #""privacyClass":"technical","value":{"boolean":true}}"#
            ),
        ]
        for document in invalidDocuments {
            do {
                _ = try decode(document)
                #expect(Bool(false), "Expected a noncanonical document to be rejected.")
            } catch MetadataJSONIngressError.invalidDocument {
                // Expected.
            }
        }

        // Malformed UTF-8 inside a string payload: raw control, overlong,
        // surrogate and truncated sequences.
        let head =
            #"{"documentSchema":{"identifier":"org.voxelia.metadata-document","#
            + #""version":{"major":1,"minor":0}},"multiplicitySchema":null,"#
            + #""payload":{"entries":[{"key":{"name":"n","namespace":"s"},"#
            + #""privacyClass":"technical","value":{"string":""#
        let tail = #""}}]}}"#
        for malformed: [UInt8] in [[0x01], [0xC0, 0xAF], [0xED, 0xA0, 0x80], [0xC2]] {
            do {
                _ = try CanonicalMetadataJSON.decodeDocument(
                    canonicalBytes: Array(head.utf8) + malformed + Array(tail.utf8),
                    limits: generousLimits(),
                    multiplicityContext: nil
                )
                #expect(Bool(false), "Expected malformed UTF-8 to be rejected.")
            } catch MetadataJSONIngressError.invalidDocument {
                // Expected.
            }
        }

        // Unsupported versions short-circuit after the canonical prefix.
        for versioned in [
            emptyEnvelope.replacingOccurrences(of: #""minor":0"#, with: #""minor":1"#),
            emptyEnvelope.replacingOccurrences(of: #""major":1"#, with: #""major":2"#),
        ] {
            do {
                _ = try decode(versioned)
                #expect(Bool(false), "Expected an unsupported version to be rejected.")
            } catch MetadataJSONIngressError.unsupportedSchemaVersion {
                // Expected.
            }
        }

        // Valid Unicode noncharacters are deliberately preserved: the
        // point where VCMJ-1 extends beyond I-JSON.
        let noncharacter = envelope(
            entries: entryJSON(value: #"{"string":"\#("\u{FFFF}")"}"#)
        )
        let decoded = try decode(noncharacter)
        #expect(decoded.payload.entries[0].value == .string("\u{FFFF}"))
    }

    @Test("[Unit][CDMS-55.3][VOX-SEC-003] multiplicity binding fails closed")
    func multiplicityBindingFailsClosed() throws {
        let repeatable = try key("dup", "k")
        let policy = try MetadataMultiplicityPolicy(repeatableKeys: [repeatable])
        let profile = try MetadataSchemaReference(
            identifier: "org.example.metadata-profile",
            version: MetadataSchemaVersion(major: 1, minor: 0)
        )
        let context = CanonicalMultiplicityContext(
            expectedSchema: profile,
            multiplicityPolicy: policy,
            maximumRetainedPolicyKeyCount: 16,
            maximumRetainedPolicyKeyByteCount: 4_096
        )
        let duplicateRich = try MetadataCollection(
            entries: [
                MetadataEntry(key: repeatable, value: .string("a"), privacyClass: .technical),
                MetadataEntry(key: repeatable, value: .string("b"), privacyClass: .sensitive),
            ],
            multiplicityPolicy: policy
        )

        // Configured emission binds the exact reference; the policy is
        // absent from the wire.
        let encoded = try CanonicalMetadataJSON.encodeConfiguredDocument(
            payload: duplicateRich,
            multiplicityContext: context,
            maximumOutputByteCount: 100_000
        )
        let text = String(decoding: encoded, as: UTF8.self)
        #expect(text.contains(#""multiplicitySchema":{"identifier":"#))
        #expect(text.contains("org.example.metadata-profile"))
        #expect(!text.lowercased().contains("policy"))
        #expect(!text.lowercased().contains("repeatable"))

        // The matching context round trips with every occurrence and
        // class preserved in order.
        let document = try decode(text, context: context)
        #expect(document.payload == duplicateRich)
        #expect(document.multiplicitySchema == profile)
        #expect(document.payload.entries[1].privacyClass == .sensitive)

        // Missing context, unexpected context and mismatched references
        // all fail closed as invalidDocument.
        do {
            _ = try decode(text)
            #expect(Bool(false), "Expected a missing trusted context to fail.")
        } catch MetadataJSONIngressError.invalidDocument {}
        do {
            _ = try decode(emptyEnvelope, context: context)
            #expect(Bool(false), "Expected unexpected context on null to fail.")
        } catch MetadataJSONIngressError.invalidDocument {}
        let mismatched = CanonicalMultiplicityContext(
            expectedSchema: try MetadataSchemaReference(
                identifier: "org.example.metadata-profile",
                version: MetadataSchemaVersion(major: 2, minor: 0)
            ),
            multiplicityPolicy: policy,
            maximumRetainedPolicyKeyCount: 16,
            maximumRetainedPolicyKeyByteCount: 4_096
        )
        do {
            _ = try decode(text, context: mismatched)
            #expect(Bool(false), "Expected a mismatched reference to fail.")
        } catch MetadataJSONIngressError.invalidDocument {}

        // The retained-policy context preflight rejects before any input
        // byte is interpreted: even a garbage document reports the
        // resource failure.
        let tinyContext = CanonicalMultiplicityContext(
            expectedSchema: profile,
            multiplicityPolicy: policy,
            maximumRetainedPolicyKeyCount: 0,
            maximumRetainedPolicyKeyByteCount: 4_096
        )
        do {
            _ = try CanonicalMetadataJSON.decodeDocument(
                canonicalBytes: [0xFF],
                limits: generousLimits(),
                multiplicityContext: tinyContext
            )
            #expect(Bool(false), "Expected the context preflight to fail first.")
        } catch MetadataJSONIngressError.resourceLimitExceeded {}
    }

    @Test("[Unit][CDMS-55.3][VOX-ERR-001] emission preflights before publishing")
    func emissionPreflightsBeforePublishing() throws {
        let repeatable = try key("dup", "k")
        let policy = try MetadataMultiplicityPolicy(repeatableKeys: [repeatable])
        let duplicateRich = try MetadataCollection(
            entries: [
                MetadataEntry(key: repeatable, value: .string("a"), privacyClass: .technical),
                MetadataEntry(key: repeatable, value: .string("b"), privacyClass: .technical),
            ],
            multiplicityPolicy: policy
        )

        // A repeat-bearing collection has no unique-only canonical bytes.
        do {
            _ = try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: duplicateRich,
                maximumOutputByteCount: 100_000
            )
            #expect(Bool(false), "Expected unique emission of repeats to fail.")
        } catch MetadataJSONEmissionError.invalidValue {}

        // A narrower configured snapshot fails preflight before output.
        let narrowContext = CanonicalMultiplicityContext(
            expectedSchema: try MetadataSchemaReference(
                identifier: "org.example.metadata-profile",
                version: MetadataSchemaVersion(major: 1, minor: 0)
            ),
            multiplicityPolicy: .uniqueKeysOnly,
            maximumRetainedPolicyKeyCount: 16,
            maximumRetainedPolicyKeyByteCount: 4_096
        )
        do {
            _ = try CanonicalMetadataJSON.encodeConfiguredDocument(
                payload: duplicateRich,
                multiplicityContext: narrowContext,
                maximumOutputByteCount: 100_000
            )
            #expect(Bool(false), "Expected a narrower snapshot to fail preflight.")
        } catch MetadataJSONEmissionError.invalidValue {}

        // The inclusive output ceiling is exact: the envelope's own byte
        // count succeeds and one less fails without publishing.
        let empty = try MetadataCollection(entries: [MetadataEntry]())
        let exact = UInt64(emptyEnvelope.utf8.count)
        let published = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: empty,
            maximumOutputByteCount: exact
        )
        #expect(UInt64(published.count) == exact)
        for ceiling in [exact - 1, 0] {
            do {
                _ = try CanonicalMetadataJSON.encodeUniqueDocument(
                    payload: empty,
                    maximumOutputByteCount: ceiling
                )
                #expect(Bool(false), "Expected the output ceiling to be inclusive.")
            } catch MetadataJSONEmissionError.resourceLimitExceeded {}
        }
    }

    @Test("[Unit][CDMS-55.3][VOX-SEC-001] ingress limits charge exactly")
    func ingressLimitsChargeExactly() throws {
        // The raw document ceiling is inclusive and charged per byte.
        let exact = UInt64(emptyEnvelope.utf8.count)
        _ = try decode(emptyEnvelope, limits: generousLimits(rawDocument: exact))
        do {
            _ = try decode(emptyEnvelope, limits: generousLimits(rawDocument: exact - 1))
            #expect(Bool(false), "Expected the raw document ceiling to be exact.")
        } catch MetadataJSONIngressError.resourceLimitExceeded {}

        // The decoded-string ceiling covers the 29-byte fixed identifier.
        do {
            _ = try decode(emptyEnvelope, limits: generousLimits(decodedString: 28))
            #expect(Bool(false), "Expected the decoded-string ceiling to bind.")
        } catch MetadataJSONIngressError.resourceLimitExceeded {}

        // The raw depth ceiling binds the envelope at three open frames.
        _ = try decode(emptyEnvelope, limits: generousLimits(rawDepth: 3))
        do {
            _ = try decode(emptyEnvelope, limits: generousLimits(rawDepth: 2))
            #expect(Bool(false), "Expected the raw depth ceiling to bind.")
        } catch MetadataJSONIngressError.resourceLimitExceeded {}

        // Direct member counts bind recursive containers.
        let three = envelope(
            entries: entryJSON(
                value: #"{"array":[{"boolean":true},{"boolean":true},{"boolean":true}]}"#
            )
        )
        _ = try decode(three, limits: generousLimits(directMembers: 3))
        do {
            _ = try decode(three, limits: generousLimits(directMembers: 2))
            #expect(Bool(false), "Expected the direct member ceiling to bind.")
        } catch MetadataJSONIngressError.resourceLimitExceeded {}
    }

    @Test("[Unit][CDMS-55.3][VOX-SEC-001] the depth-198 chain is exact")
    func depth198ChainIsExact() throws {
        // A 64-level nested-object chain with a unit leaf reaches the
        // grammar-derived raw maximum of exactly 198 frames while staying
        // at the semantic ceiling of 64.
        var value: MetadataValue = .unit(try MeasurementUnit(namespace: "UCUM", code: "mm"))
        for _ in 0..<64 {
            value = .object(
                try MetadataObject(members: [
                    .init(key: try key("n", "m"), value: value)
                ])
            )
        }
        let collection = try MetadataCollection(entries: [
            try entry("t", "deep", value: value)
        ])
        let encoded = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: collection,
            maximumOutputByteCount: 1_000_000
        )
        let text = String(decoding: encoded, as: UTF8.self)

        let document = try decode(text, limits: generousLimits(rawDepth: 198))
        #expect(document.payload == collection)
        do {
            _ = try decode(text, limits: generousLimits(rawDepth: 197))
            #expect(Bool(false), "Expected raw depth 198 to require 198 frames.")
        } catch MetadataJSONIngressError.resourceLimitExceeded {}

        // A 65-level chain is rejected during descent by the semantic
        // container guard even under a permissive raw-depth limit.
        var nestedText =
            #"{"unit":{"code":"mm","dimension":null,"displayName":null,"#
            + #""namespace":"UCUM","offsetToCanonical":null,"scaleToCanonical":null}}"#
        for _ in 0..<65 {
            nestedText =
                #"{"object":[{"key":{"name":"m","namespace":"n"},"value":\#(nestedText)}]}"#
        }
        let sixtyFive = envelope(entries: entryJSON(value: nestedText))
        do {
            _ = try decode(sixtyFive, limits: generousLimits(rawDepth: 250))
            #expect(Bool(false), "Expected semantic depth 65 to be rejected.")
        } catch MetadataJSONIngressError.resourceLimitExceeded {}
    }

    @Test("[Unit][CDMS-34.1][VOX-META-002] the frozen whitespace oracle is exact")
    func frozenWhitespaceOracleIsExact() throws {
        // The documented pre-1.0 broadening: these edge strings contain a
        // scalar outside the frozen set and are now accepted, in both the
        // Core identity constructors and Spatial's MeasurementUnit.
        _ = try AnyMetadataKey(namespace: " \u{0301}", name: "x")
        _ = try CodedConcept(scheme: "\u{2003}\u{FE0F}", value: "v")
        _ = try MeasurementUnit(namespace: "\u{2003}\u{FE0F}", code: " \u{0301}")

        // Every frozen scalar alone, and all of them together, remain
        // blank in every constructor.
        var frozenScalars: [Unicode.Scalar] = [
            "\u{0009}", "\u{000A}", "\u{000B}", "\u{000C}", "\u{000D}", "\u{0020}",
            "\u{0085}", "\u{00A0}", "\u{1680}", "\u{2028}", "\u{2029}", "\u{202F}",
            "\u{205F}", "\u{3000}",
        ]
        for value in 0x2000...0x200A {
            frozenScalars.append(Unicode.Scalar(value)!)
        }
        let allFrozen = String(String.UnicodeScalarView(frozenScalars))
        for blank in frozenScalars.map({ String($0) }) + [allFrozen] {
            do {
                _ = try AnyMetadataKey(namespace: blank, name: "x")
                #expect(Bool(false), "Expected a frozen-whitespace namespace to fail.")
            } catch MetadataKeyError.emptyNamespace {}
            do {
                _ = try MeasurementUnit(namespace: blank, code: "mm")
                #expect(Bool(false), "Expected a frozen-whitespace unit field to fail.")
            } catch MeasurementUnitError.emptyNamespace {}
        }
        do {
            _ = try CodedConcept(scheme: allFrozen, value: "v")
            #expect(Bool(false), "Expected a frozen-whitespace scheme to fail.")
        } catch CodedConceptError.emptyScheme {}
    }

    @Test("[Unit][CDMS-55.3][VOX-API-004] schema references are bounded ASCII")
    func schemaReferencesAreBoundedASCII() throws {
        let version = MetadataSchemaVersion(major: 1, minor: 0)
        for valid in [
            "org.voxelia.metadata-document", "org.example.metadata-profile", "a.b",
            "0a.b-1.c2",
        ] {
            _ = try MetadataSchemaReference(identifier: valid, version: version)
        }
        for invalid in [
            "", "org", "Org.example", "org..example", "-a.b", "a-.b", "a_b.c",
            "a. b", "a.b.", ".a.b", "\u{00F6}rg.example",
        ] {
            do {
                _ = try MetadataSchemaReference(identifier: invalid, version: version)
                #expect(Bool(false), "Expected an invalid identifier to be rejected.")
            } catch MetadataSchemaReferenceError.invalidIdentifier {}
        }

        // The 63-byte label and 255-byte total ceilings are inclusive.
        let label63 = String(repeating: "a", count: 63)
        _ = try MetadataSchemaReference(identifier: "\(label63).b", version: version)
        do {
            let label64 = String(repeating: "a", count: 64)
            _ = try MetadataSchemaReference(identifier: "\(label64).b", version: version)
            #expect(Bool(false), "Expected the label ceiling to be exact.")
        } catch MetadataSchemaReferenceError.identifierByteLimitExceeded {}
        let total255 = [String](repeating: label63, count: 4).joined(separator: ".")
        #expect(total255.utf8.count == 255)
        _ = try MetadataSchemaReference(identifier: total255, version: version)
        do {
            let total256 =
                "\(label63)a."
                + [String](
                    repeating: label63,
                    count: 3
                ).joined(separator: ".")
            #expect(total256.utf8.count == 256)
            _ = try MetadataSchemaReference(identifier: total256, version: version)
            #expect(Bool(false), "Expected the total ceiling to be exact.")
        } catch MetadataSchemaReferenceError.identifierByteLimitExceeded {}

        // Equality and hashing compare exact bytes plus version.
        let left = try MetadataSchemaReference(identifier: "a.b", version: version)
        let right = try MetadataSchemaReference(
            identifier: "a.b",
            version: MetadataSchemaVersion(major: 1, minor: 1)
        )
        #expect(left != right)
        #expect(left == (try MetadataSchemaReference(identifier: "a.b", version: version)))
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-006] codec failures stay payload-free")
    func codecFailuresStayPayloadFree() throws {
        let sentinelDocument = emptyEnvelope.replacingOccurrences(
            of: #""entries":[]"#,
            with: #""entries":[{"key":{"name":"patient-name","namespace":"patient-ns"},"#
                + #""privacyClass":"patient-secret","value":{"boolean":true}}]"#
        )
        do {
            _ = try decode(sentinelDocument)
            #expect(Bool(false), "Expected the sentinel document to be rejected.")
        } catch let error as MetadataJSONIngressError {
            #expect(error == .invalidDocument)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient"))
        }

        do {
            _ = try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: [
                    try entry("patient-ns", "patient-name", value: .boolean(true))
                ]),
                maximumOutputByteCount: 3
            )
            #expect(Bool(false), "Expected the output ceiling to be enforced.")
        } catch let error as MetadataJSONEmissionError {
            #expect(error == .resourceLimitExceeded)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
