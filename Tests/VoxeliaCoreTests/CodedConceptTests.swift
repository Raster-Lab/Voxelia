// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("CodedConcept")
struct CodedConceptTests {
    @Test("[Unit][VOX-META-001][VOX-API-003] preserves neutral opaque fields")
    func preservesOpaqueFields() throws {
        let scheme = "  SNOMED-座標  "
        let value = "  12345-Δ  "
        let meaning = ""
        let version = "  2026-A  "
        let concept = try CodedConcept(
            scheme: scheme,
            value: value,
            meaning: meaning,
            version: version
        )

        #expect(Array(concept.scheme.utf8) == Array(scheme.utf8))
        #expect(Array(concept.value.utf8) == Array(value.utf8))
        #expect(Array(try #require(concept.meaning).utf8) == Array(meaning.utf8))
        #expect(Array(try #require(concept.version).utf8) == Array(version.utf8))
        requireSendable(CodedConcept.self)
    }

    @Test("[Unit][VOX-ERR-001] rejects Unicode-blank identity fields")
    func rejectsBlankIdentity() {
        for blank in ["", " \t\n", "\u{2003}\u{00A0}"] {
            #expect(throws: CodedConceptError.emptyScheme) {
                try CodedConcept(scheme: blank, value: "123")
            }
            #expect(throws: CodedConceptError.emptyValue) {
                try CodedConcept(scheme: "SNOMED", value: blank)
            }
        }
    }

    @Test("[Unit][VOX-API-003] identity excludes meaning and includes version")
    func identityExcludesMeaningAndIncludesVersion() throws {
        let firstMeaning = try CodedConcept(
            scheme: "SNOMED",
            value: "123",
            meaning: "First meaning",
            version: "2026"
        )
        let secondMeaning = try CodedConcept(
            scheme: "SNOMED",
            value: "123",
            meaning: "Second meaning",
            version: "2026"
        )
        let absentVersion = try CodedConcept(
            scheme: "SNOMED",
            value: "123",
            version: nil
        )
        let emptyVersion = try CodedConcept(
            scheme: "SNOMED",
            value: "123",
            version: ""
        )
        let otherVersion = try CodedConcept(
            scheme: "SNOMED",
            value: "123",
            version: "2027"
        )
        let otherCase = try CodedConcept(
            scheme: "snomed",
            value: "123",
            version: "2026"
        )

        #expect(firstMeaning == secondMeaning)
        #expect(Set([firstMeaning, secondMeaning]).count == 1)
        #expect(absentVersion != emptyVersion)
        #expect(firstMeaning != otherVersion)
        #expect(firstMeaning != otherCase)
    }

    @Test("[Unit][VOX-API-003] Unicode identity spellings remain distinct")
    func unicodeIdentitySpellingsRemainDistinct() throws {
        let composed = try CodedConcept(
            scheme: "sch\u{00E9}me",
            value: "valu\u{00E9}",
            version: "v\u{00E9}"
        )
        let decomposedScheme = try CodedConcept(
            scheme: "sche\u{301}me",
            value: "valu\u{00E9}",
            version: "v\u{00E9}"
        )
        let decomposedValue = try CodedConcept(
            scheme: "sch\u{00E9}me",
            value: "value\u{301}",
            version: "v\u{00E9}"
        )
        let decomposedVersion = try CodedConcept(
            scheme: "sch\u{00E9}me",
            value: "valu\u{00E9}",
            version: "ve\u{301}"
        )

        #expect(composed != decomposedScheme)
        #expect(composed != decomposedValue)
        #expect(composed != decomposedVersion)
        #expect(
            Set([
                composed,
                decomposedScheme,
                decomposedValue,
                decomposedVersion,
            ]).count == 4
        )
    }

    @Test("[Unit][VOX-API-004] Codable preserves all fields and explicit nulls")
    func codableRoundTripAndShape() throws {
        let withOptionals = try CodedConcept(
            scheme: "SNOMED",
            value: "123",
            meaning: "Example",
            version: "2026"
        )
        let withoutOptionals = try CodedConcept(
            scheme: "UCUM",
            value: "mm"
        )
        let emptyOptionals = try CodedConcept(
            scheme: "example",
            value: "empty-optionals",
            meaning: "",
            version: ""
        )

        for concept in [withOptionals, withoutOptionals, emptyOptionals] {
            let data = try JSONEncoder().encode(concept)
            let decoded = try JSONDecoder().decode(CodedConcept.self, from: data)
            #expect(Array(decoded.scheme.utf8) == Array(concept.scheme.utf8))
            #expect(Array(decoded.value.utf8) == Array(concept.value.utf8))
            #expect(decoded.meaning == concept.meaning)
            #expect(decoded.version == concept.version)
            let object = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            #expect(Set(object.keys) == ["scheme", "value", "meaning", "version"])
            if let meaning = concept.meaning {
                #expect(object["meaning"] as? String == meaning)
            } else {
                #expect(object["meaning"] is NSNull)
            }
            if let version = concept.version {
                #expect(object["version"] as? String == version)
            } else {
                #expect(object["version"] is NSNull)
            }
        }
    }

    @Test("[Unit][VOX-API-004] decoding is strict and contextual")
    func decodingIsStrictAndContextual() {
        let malformedValues = [
            #"{"scheme":"SNOMED","value":"123"}"#,
            #"{"scheme":"SNOMED","value":"123","meaning":null,"version":null,"extra":true}"#,
            #"[]"#,
        ]
        for malformedValue in malformedValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    CodedConcept.self,
                    from: Data(malformedValue.utf8)
                )
            }
        }

        expectBlankDecoding(
            json: #"{"scheme":" ","value":"123","meaning":null,"version":null}"#,
            field: "scheme",
            underlyingError: .emptyScheme
        )
        expectBlankDecoding(
            json: #"{"scheme":"SNOMED","value":" ","meaning":null,"version":null}"#,
            field: "value",
            underlyingError: .emptyValue
        )
    }

    private func expectBlankDecoding(
        json: String,
        field: String,
        underlyingError: CodedConceptError
    ) {
        do {
            _ = try JSONDecoder().decode(
                CodedConcept.self,
                from: Data(json.utf8)
            )
            #expect(Bool(false), "Expected blank coded-concept field to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == field)
            #expect(context.underlyingError as? CodedConceptError == underlyingError)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
