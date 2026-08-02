// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("ExternalFrameReference")
struct ExternalFrameReferenceTests {
    @Test("[Unit][VOX-API-003] preserves opaque external values exactly")
    func preservesOpaqueValues() throws {
        let namespace = "  org.Example.座標  "
        let identifier = "  1.2.840.Δ  "
        let reference = try ExternalFrameReference(
            namespace: namespace,
            identifier: identifier
        )

        #expect(reference.namespace == namespace)
        #expect(reference.identifier == identifier)
        #expect(Array(reference.namespace.utf8) == Array(namespace.utf8))
        #expect(Array(reference.identifier.utf8) == Array(identifier.utf8))
    }

    @Test("[Unit][VOX-ERR-001] rejects empty and Unicode-whitespace fields")
    func rejectsBlankFields() {
        for blank in ["", " \t\n", "\u{2003}\u{00A0}"] {
            #expect(throws: ExternalFrameReferenceError.emptyNamespace) {
                try ExternalFrameReference(namespace: blank, identifier: "frame")
            }
            #expect(throws: ExternalFrameReferenceError.emptyIdentifier) {
                try ExternalFrameReference(namespace: "namespace", identifier: blank)
            }
        }
    }

    @Test("[Unit][VOX-API-003] pair identity is exact and case-sensitive")
    func pairIdentityIsExact() throws {
        let original = try ExternalFrameReference(
            namespace: "org.example",
            identifier: "Frame"
        )
        let namespaceCase = try ExternalFrameReference(
            namespace: "ORG.example",
            identifier: "Frame"
        )
        let identifierCase = try ExternalFrameReference(
            namespace: "org.example",
            identifier: "frame"
        )

        #expect(original != namespaceCase)
        #expect(original != identifierCase)
        #expect(Set([original, namespaceCase, identifierCase]).count == 3)
    }

    @Test("[Unit][VOX-API-003][VOX-API-004] Unicode spellings remain distinct")
    func unicodeSpellingsRemainDistinct() throws {
        let composedNamespace = "org.ex\u{00E9}mple"
        let decomposedNamespace = "org.exe\u{301}mple"
        let composed = try ExternalFrameReference(
            namespace: composedNamespace,
            identifier: "frame"
        )
        let decomposed = try ExternalFrameReference(
            namespace: decomposedNamespace,
            identifier: "frame"
        )

        #expect(Array(composedNamespace.utf8) != Array(decomposedNamespace.utf8))
        #expect(composed != decomposed)
        #expect(Set([composed, decomposed]).count == 2)

        for reference in [composed, decomposed] {
            let data = try JSONEncoder().encode(reference)
            let decoded = try JSONDecoder().decode(
                ExternalFrameReference.self,
                from: data
            )
            #expect(
                Array(decoded.namespace.utf8)
                    == Array(reference.namespace.utf8)
            )
            #expect(
                Array(decoded.identifier.utf8)
                    == Array(reference.identifier.utf8)
            )
        }
    }

    @Test("[Unit][VOX-API-004] Codable preserves the exact keyed shape")
    func codableRoundTrip() throws {
        let reference = try ExternalFrameReference(
            namespace: "org.example",
            identifier: "Frame-1"
        )
        let data = try JSONEncoder().encode(reference)

        #expect(
            try JSONDecoder().decode(ExternalFrameReference.self, from: data)
                == reference
        )
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(Set(object.keys) == ["namespace", "identifier"])
        #expect(object["namespace"] as? String == reference.namespace)
        #expect(object["identifier"] as? String == reference.identifier)
    }

    @Test("[Unit][VOX-API-004] decoding is strict and reports the blank field")
    func decodingIsStrictAndContextual() {
        let malformedValues = [
            #"{"namespace":"org.example"}"#,
            #"{"namespace":"org.example","identifier":"frame","extra":true}"#,
            #"[]"#,
        ]
        for malformedValue in malformedValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    ExternalFrameReference.self,
                    from: Data(malformedValue.utf8)
                )
            }
        }

        expectBlankDecoding(
            json: #"{"namespace":" ","identifier":"frame"}"#,
            field: "namespace",
            underlyingError: .emptyNamespace
        )
        expectBlankDecoding(
            json: #"{"namespace":"org.example","identifier":" "}"#,
            field: "identifier",
            underlyingError: .emptyIdentifier
        )
    }

    private func expectBlankDecoding(
        json: String,
        field: String,
        underlyingError: ExternalFrameReferenceError
    ) {
        do {
            _ = try JSONDecoder().decode(
                ExternalFrameReference.self,
                from: Data(json.utf8)
            )
            #expect(Bool(false), "Expected blank external frame field to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == field)
            #expect(context.underlyingError as? ExternalFrameReferenceError == underlyingError)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }
}
