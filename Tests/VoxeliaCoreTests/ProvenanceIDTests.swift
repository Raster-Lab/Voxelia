// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("ProvenanceID")
struct ProvenanceIDTests {
    @Test("[Unit][VOX-ARC-003][VOX-API-003] preserves valid identifier spelling")
    func preservesValidSpellingAndIdentity() throws {
        let rawValue = "  org.voxelia.provenance.Δ  "
        let identifier = try ProvenanceID(validating: rawValue)
        let differentlyCased = try ProvenanceID(
            validating: "  ORG.voxelia.provenance.Δ  "
        )

        #expect(Array(identifier.rawValue.utf8) == Array(rawValue.utf8))
        #expect(identifier != differentlyCased)
        #expect(Set([identifier, differentlyCased]).count == 2)
        requireIdentifier(identifier)
        requireSendable(ProvenanceID.self)

        let objectID = try DataObjectID(validating: rawValue)
        #expect(type(of: identifier) == ProvenanceID.self)
        #expect(type(of: objectID) == DataObjectID.self)
    }

    @Test("[Unit][VOX-ERR-001] both initializers reject Unicode-blank values")
    func rejectsBlankValues() {
        for blank in ["", " \t\n", "\u{2003}\u{00A0}"] {
            #expect(ProvenanceID(rawValue: blank) == nil)
            #expect(throws: VoxeliaStringIdentifierError.emptyOrWhitespaceOnly) {
                try ProvenanceID(validating: blank)
            }
        }
    }

    @Test("[Unit][VOX-API-004] Codable uses the strict keyed identifier shape")
    func codableRoundTripAndValidation() throws {
        let identifier = try ProvenanceID(
            validating: "org.voxelia.provenance.example"
        )
        let data = try JSONEncoder().encode(identifier)

        #expect(try JSONDecoder().decode(ProvenanceID.self, from: data) == identifier)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(Set(object.keys) == ["rawValue"])
        #expect(object["rawValue"] as? String == identifier.rawValue)

        let invalidValues = [
            #"{"rawValue":" "}"#,
            #"{}"#,
            #"{"rawValue":"provenance","extra":true}"#,
            #""provenance""#,
            #"[]"#,
        ]
        for invalidValue in invalidValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    ProvenanceID.self,
                    from: Data(invalidValue.utf8)
                )
            }
        }
    }

    private func requireIdentifier<Value: VoxeliaStringIdentifier>(_ value: Value) {}

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
