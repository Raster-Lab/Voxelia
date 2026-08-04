// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("DataObjectID")
struct DataObjectIDTests {
    @Test("[Unit][VOX-ARC-003][VOX-API-003] preserves valid identifier spelling")
    func preservesValidSpellingAndIdentity() throws {
        let rawValue = "  org.voxelia.object.Δ  "
        let identifier = try DataObjectID(validating: rawValue)
        let differentlyCased = try DataObjectID(
            validating: "  ORG.voxelia.object.Δ  "
        )

        #expect(identifier.rawValue == rawValue)
        #expect(Array(identifier.rawValue.utf8) == Array(rawValue.utf8))
        #expect(identifier != differentlyCased)
        #expect(Set([identifier, differentlyCased]).count == 2)
        requireIdentifier(identifier)
        requireSendable(DataObjectID.self)

        let coordinateSpace = try CoordinateSpaceID(validating: rawValue)
        #expect(type(of: identifier) == DataObjectID.self)
        #expect(type(of: coordinateSpace) == CoordinateSpaceID.self)
    }

    @Test("[Unit][VOX-ERR-001] both initializers reject Unicode-blank values")
    func rejectsBlankValues() {
        for blank in ["", " \t\n", "\u{2003}\u{00A0}"] {
            #expect(DataObjectID(rawValue: blank) == nil)
            #expect(throws: VoxeliaStringIdentifierError.emptyOrWhitespaceOnly) {
                try DataObjectID(validating: blank)
            }
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] Codable uses the strict keyed identifier shape")
    func codableRoundTripAndValidation() throws {
        let identifier = try DataObjectID(
            validating: "org.voxelia.object.example"
        )
        let data = try JSONEncoder().encode(identifier)

        #expect(try JSONDecoder().decode(DataObjectID.self, from: data) == identifier)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(Set(object.keys) == ["rawValue"])
        #expect(object["rawValue"] as? String == identifier.rawValue)

        do {
            _ = try JSONDecoder().decode(
                DataObjectID.self,
                from: Data(#"{"rawValue":" "}"#.utf8)
            )
            #expect(Bool(false), "Expected a blank raw value to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["rawValue"])
            #expect(
                context.underlyingError as? VoxeliaStringIdentifierError
                    == .emptyOrWhitespaceOnly
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        for wrongKeyValue in [#"{}"#, #"{"rawValue":"object","extra":true}"#] {
            do {
                _ = try JSONDecoder().decode(
                    DataObjectID.self,
                    from: Data(wrongKeyValue.utf8)
                )
                #expect(Bool(false), "Expected a wrong-keyed object to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        for wrongShape in [#""object""#, #"[]"#] {
            do {
                _ = try JSONDecoder().decode(
                    DataObjectID.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped value to fail decoding.")
            } catch DecodingError.typeMismatch {
                // The keyed-container request rejects non-object shapes.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }

    private func requireIdentifier<Value: VoxeliaStringIdentifier>(_ value: Value) {}

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
