// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("MetadataEntry")
struct MetadataEntryTests {
    private let allClasses: [MetadataPrivacyClass] = [
        .publicData, .technical, .potentiallyIdentifying, .sensitive, .hostDefined,
    ]

    private func key(_ namespace: String, _ name: String) throws -> AnyMetadataKey {
        try AnyMetadataKey(namespace: namespace, name: name)
    }

    private func sortedKeysEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    @Test("[Unit][CDMS-34.4][VOX-META-001] every class constructs an explicit entry")
    func everyClassConstructsAnExplicitEntry() throws {
        // The initializer requires all three inputs; this is also the API
        // compile check that no default, optional or two-argument overload
        // exists.
        let entryKey = try key("example", "field")
        for privacyClass in allClasses {
            let entry = MetadataEntry(
                key: entryKey,
                value: .string("x"),
                privacyClass: privacyClass
            )
            #expect(entry.key == entryKey)
            #expect(entry.value == .string("x"))
            #expect(entry.privacyClass == privacyClass)
        }

        requireSendable(MetadataEntry.self)
    }

    @Test("[Unit][CDMS-34.6][VOX-META-001] identity includes the exact declared class")
    func identityIncludesTheExactDeclaredClass() throws {
        let entryKey = try key("example", "field")
        let entries = allClasses.map {
            MetadataEntry(key: entryKey, value: .string("x"), privacyClass: $0)
        }

        // Equal key/value pairs under distinct classes are unequal and are
        // never collapsed by set or deduplication behaviour.
        #expect(Set(entries).count == allClasses.count)
        #expect(entries[0] != entries[1])

        let duplicate = MetadataEntry(
            key: entryKey,
            value: .string("x"),
            privacyClass: .publicData
        )
        #expect(entries[0] == duplicate)
        #expect(Set([entries[0], duplicate]).count == 1)

        // Semantic value identity from ADR-0031 participates unchanged: the
        // NFC and NFD spellings remain distinct entries under one class.
        let composed = MetadataEntry(
            key: entryKey,
            value: .string("caf\u{E9}"),
            privacyClass: .technical
        )
        let decomposed = MetadataEntry(
            key: entryKey,
            value: .string("cafe\u{301}"),
            privacyClass: .technical
        )
        #expect(composed != decomposed)
    }

    @Test("[Unit][VOX-API-004] three-field wire round trips for all five classes")
    func threeFieldWireRoundTripsForAllFiveClasses() throws {
        let entryKey = try key("example", "field")
        for privacyClass in allClasses {
            let entry = MetadataEntry(
                key: entryKey,
                value: .string("x"),
                privacyClass: privacyClass
            )
            let decoded = try JSONDecoder().decode(
                MetadataEntry.self,
                from: try JSONEncoder().encode(entry)
            )
            // The Codable round trip is the library's one-to-one
            // transformation: it preserves the exact declared class.
            #expect(decoded == entry)
            #expect(decoded.privacyClass == privacyClass)
        }

        // The documented wire fixture is byte-exact under sorted keys.
        let fixture = MetadataEntry(
            key: entryKey,
            value: .string("x"),
            privacyClass: .potentiallyIdentifying
        )
        let encoded = String(
            decoding: try sortedKeysEncoder().encode(fixture),
            as: UTF8.self
        )
        #expect(
            encoded == #"{"key":{"name":"field","namespace":"example"},"#
                + #""privacyClass":"potentiallyIdentifying","value":{"string":"x"}}"#
        )
    }

    @Test("[Unit][CDMS-34.8][VOX-SEC-006] hostDefined survives without resolution")
    func hostDefinedSurvivesWithoutResolution() throws {
        // A declared hostDefined round-trips exactly; no generic library
        // step resolves, upgrades or downgrades the unresolved declaration.
        let entry = MetadataEntry(
            key: try key("example", "field"),
            value: .boolean(true),
            privacyClass: .hostDefined
        )
        let decoded = try JSONDecoder().decode(
            MetadataEntry.self,
            from: try JSONEncoder().encode(entry)
        )
        #expect(decoded.privacyClass == .hostDefined)
        #expect(decoded == entry)
    }

    @Test("[Unit][CDMS-34.8][VOX-META-001] one class scopes the whole entry record")
    func oneClassScopesTheWholeEntryRecord() throws {
        // The single declared class governs key text, array elements, nested
        // object-member keys and values, and presentation strings retained
        // inside code and unit leaves.
        let nested = try MetadataObject(members: [
            .init(key: try key("inner", "code"), value: .code(codedConcept())),
            .init(
                key: try key("inner", "list"),
                value: .array(try MetadataArray(values: [.string("a"), .string("b")]))
            ),
        ])
        let entry = MetadataEntry(
            key: try key("outer", "record"),
            value: .object(nested),
            privacyClass: .sensitive
        )

        let encoded = String(
            decoding: try sortedKeysEncoder().encode(entry),
            as: UTF8.self
        )
        // Whole-entry scope on the wire: exactly one classification field
        // exists, on the outer entry; privacy-neutral members carry none.
        #expect(encoded.components(separatedBy: "privacyClass").count == 2)

        let decoded = try JSONDecoder().decode(
            MetadataEntry.self,
            from: Data(encoded.utf8)
        )
        #expect(decoded == entry)
        #expect(decoded.privacyClass == .sensitive)
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects malformed field sets")
    func decodingRejectsMalformedFieldSets() throws {
        let keyJSON = #"{"namespace":"example","name":"field"}"#
        let malformedDocuments = [
            // Missing classification never defaults.
            #"{"key":\#(keyJSON),"value":{"string":"x"}}"#,
            // Null is not a classification.
            #"{"key":\#(keyJSON),"value":{"string":"x"},"privacyClass":null}"#,
            // A distinct extra field is rejected.
            #"{"key":\#(keyJSON),"value":{"string":"x"},"#
                + #""privacyClass":"technical","extra":true}"#,
            // An unknown token is rejected, never coerced to hostDefined.
            #"{"key":\#(keyJSON),"value":{"string":"x"},"privacyClass":"unknown"}"#,
            // A wrong-shaped classification is rejected.
            #"{"key":\#(keyJSON),"value":{"string":"x"},"privacyClass":["technical"]}"#,
            // A wrong-shaped key is rejected.
            #"{"key":"example.field","value":{"string":"x"},"privacyClass":"technical"}"#,
            // A wrong-shaped value is rejected.
            #"{"key":\#(keyJSON),"value":"x","privacyClass":"technical"}"#,
            // A non-object entry is rejected.
            #""entry""#,
        ]

        for document in malformedDocuments {
            do {
                _ = try JSONDecoder().decode(
                    MetadataEntry.self,
                    from: Data(document.utf8)
                )
                #expect(Bool(false), "Expected a malformed entry to fail decoding.")
            } catch DecodingError.dataCorrupted {
                // Expected value-redacted model rejection.
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-006] entry failures redact values and paths")
    func entryFailuresRedactValuesAndPaths() throws {
        // A rejected classification token decoded beneath an arbitrary caller
        // dictionary key names only the fixed field and leaks neither the
        // caller key nor the rejected token.
        let sentinelDocument =
            #"{"patient-sentinel":{"key":{"namespace":"example","name":"field"},"#
            + #""value":{"string":"x"},"privacyClass":"patient-secret-class"}}"#
        do {
            _ = try JSONDecoder().decode(
                [String: MetadataEntry].self,
                from: Data(sentinelDocument.utf8)
            )
            #expect(Bool(false), "Expected an unknown class token to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["privacyClass"])
            #expect(context.underlyingError == nil)
            var rendered = ""
            dump(context, to: &rendered)
            #expect(!rendered.contains("patient-sentinel"))
            #expect(!rendered.contains("patient-secret-class"))
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        // A value-field container violation retains only the audited
        // payload-free project error and the fixed value field.
        let duplicateDocument =
            #"{"patient-sentinel":{"key":{"namespace":"example","name":"field"},"#
            + #""value":{"object":["#
            + #"{"key":{"namespace":"inner","name":"member"},"value":{"boolean":true}},"#
            + #"{"key":{"namespace":"inner","name":"member"},"value":{"boolean":false}}"#
            + #"]},"privacyClass":"technical"}}"#
        do {
            _ = try JSONDecoder().decode(
                [String: MetadataEntry].self,
                from: Data(duplicateDocument.utf8)
            )
            #expect(Bool(false), "Expected a duplicate member key to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["value"])
            #expect(
                context.underlyingError as? MetadataValueError == .duplicateObjectKey
            )
            var rendered = ""
            dump(context, to: &rendered)
            #expect(!rendered.contains("patient-sentinel"))
            #expect(!rendered.contains("inner"))
            #expect(!rendered.contains("member"))
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        // A blank key field retains only the audited typed key error.
        let blankKeyDocument =
            #"{"key":{"namespace":"","name":"field"},"#
            + #""value":{"string":"x"},"privacyClass":"technical"}"#
        do {
            _ = try JSONDecoder().decode(
                MetadataEntry.self,
                from: Data(blankKeyDocument.utf8)
            )
            #expect(Bool(false), "Expected a blank key namespace to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["key"])
            #expect(context.underlyingError as? MetadataKeyError == .emptyNamespace)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}

    private func codedConcept() throws -> CodedConcept {
        try CodedConcept(
            scheme: "scheme",
            value: "value",
            meaning: "presentation text",
            version: "1"
        )
    }
}
