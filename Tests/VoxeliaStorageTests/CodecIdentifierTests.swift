// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaStorage

@Suite("CodecIdentifier")
struct CodecIdentifierTests {
    @Test("[Unit][VOX-API-003] preserves opaque codec fields")
    func preservesOpaqueFields() throws {
        let namespace = "  org.Codec.编解码  "
        let name = "  JP3D-Δ  "
        let version = ""
        let profile = "  lossless-A  "
        let identifier = try CodecIdentifier(
            namespace: namespace,
            name: name,
            version: version,
            profile: profile
        )

        #expect(Array(identifier.namespace.utf8) == Array(namespace.utf8))
        #expect(Array(identifier.name.utf8) == Array(name.utf8))
        #expect(Array(try #require(identifier.version).utf8) == Array(version.utf8))
        #expect(Array(try #require(identifier.profile).utf8) == Array(profile.utf8))
        requireSendable(CodecIdentifier.self)
    }

    @Test("[Unit][VOX-ERR-001] rejects Unicode-blank required fields")
    func rejectsBlankIdentity() {
        for blank in ["", " \t\n", "\u{2003}\u{00A0}"] {
            #expect(throws: CodecIdentifierError.emptyNamespace) {
                try CodecIdentifier(namespace: blank, name: "codec")
            }
            #expect(throws: CodecIdentifierError.emptyName) {
                try CodecIdentifier(namespace: "org.example", name: blank)
            }
        }
    }

    @Test("[Unit][VOX-API-003] every identity field uses exact UTF-8 spelling")
    func identityUsesExactUTF8Spelling() throws {
        let composed = try CodecIdentifier(
            namespace: "nam\u{00E9}space",
            name: "cod\u{00E9}c",
            version: "v\u{00E9}",
            profile: "profil\u{00E9}"
        )
        let decomposedNamespace = try CodecIdentifier(
            namespace: "name\u{301}space",
            name: "cod\u{00E9}c",
            version: "v\u{00E9}",
            profile: "profil\u{00E9}"
        )
        let decomposedName = try CodecIdentifier(
            namespace: "nam\u{00E9}space",
            name: "code\u{301}c",
            version: "v\u{00E9}",
            profile: "profil\u{00E9}"
        )
        let decomposedVersion = try CodecIdentifier(
            namespace: "nam\u{00E9}space",
            name: "cod\u{00E9}c",
            version: "ve\u{301}",
            profile: "profil\u{00E9}"
        )
        let decomposedProfile = try CodecIdentifier(
            namespace: "nam\u{00E9}space",
            name: "cod\u{00E9}c",
            version: "v\u{00E9}",
            profile: "profile\u{301}"
        )

        #expect(
            Set([
                composed,
                decomposedNamespace,
                decomposedName,
                decomposedVersion,
                decomposedProfile,
            ]).count == 5
        )
        let absentVersion = try CodecIdentifier(
            namespace: "example",
            name: "codec"
        )
        let emptyVersion = try CodecIdentifier(
            namespace: "example",
            name: "codec",
            version: "",
            profile: ""
        )
        #expect(absentVersion != emptyVersion)
    }

    @Test("[Unit][VOX-API-004] Codable preserves exact fields and explicit nulls")
    func codableRoundTripAndShape() throws {
        let withOptionals = try CodecIdentifier(
            namespace: "org.example",
            name: "codec",
            version: "1.0",
            profile: "lossless"
        )
        let withoutOptionals = try CodecIdentifier(
            namespace: "org.example",
            name: "codec"
        )
        let emptyOptionals = try CodecIdentifier(
            namespace: "org.example",
            name: "codec",
            version: "",
            profile: ""
        )

        for identifier in [withOptionals, withoutOptionals, emptyOptionals] {
            let data = try JSONEncoder().encode(identifier)
            let decoded = try JSONDecoder().decode(CodecIdentifier.self, from: data)
            #expect(Array(decoded.namespace.utf8) == Array(identifier.namespace.utf8))
            #expect(Array(decoded.name.utf8) == Array(identifier.name.utf8))
            #expect(decoded.version == identifier.version)
            #expect(decoded.profile == identifier.profile)
            let object = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            #expect(Set(object.keys) == ["namespace", "name", "version", "profile"])
            if let version = identifier.version {
                #expect(object["version"] as? String == version)
            } else {
                #expect(object["version"] is NSNull)
            }
            if let profile = identifier.profile {
                #expect(object["profile"] as? String == profile)
            } else {
                #expect(object["profile"] is NSNull)
            }
        }
    }

    @Test("[Unit][VOX-API-004] decoding is strict and contextual")
    func decodingIsStrictAndContextual() {
        let malformedValues = [
            #"{"namespace":"org.example","name":"codec"}"#,
            #"{"namespace":"org.example","name":"codec","version":null,"profile":null,"extra":true}"#,
            #"[]"#,
        ]
        for malformedValue in malformedValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    CodecIdentifier.self,
                    from: Data(malformedValue.utf8)
                )
            }
        }

        expectBlankDecoding(
            json: #"{"namespace":" ","name":"codec","version":null,"profile":null}"#,
            field: "namespace",
            underlyingError: .emptyNamespace
        )
        expectBlankDecoding(
            json: #"{"namespace":"org.example","name":" ","version":null,"profile":null}"#,
            field: "name",
            underlyingError: .emptyName
        )
    }

    private func expectBlankDecoding(
        json: String,
        field: String,
        underlyingError: CodecIdentifierError
    ) {
        do {
            _ = try JSONDecoder().decode(
                CodecIdentifier.self,
                from: Data(json.utf8)
            )
            #expect(Bool(false), "Expected blank codec identity field to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == field)
            #expect(context.underlyingError as? CodecIdentifierError == underlyingError)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
