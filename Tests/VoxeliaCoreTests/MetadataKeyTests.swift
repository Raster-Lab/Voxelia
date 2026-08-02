// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("MetadataKey")
struct MetadataKeyTests {
    @Test("[Unit][VOX-API-003] typed keys preserve opaque pair identity")
    func typedKeysPreservePairIdentity() throws {
        let namespace = "  org.Example.元数据  "
        let name = "  WindowΔ  "
        let key = try MetadataKey<Double>(namespace: namespace, name: name)
        let differentlyCased = try MetadataKey<Double>(
            namespace: "  org.example.元数据  ",
            name: name
        )
        let otherValueType = try MetadataKey<String>(
            namespace: namespace,
            name: name
        )

        #expect(Array(key.namespace.utf8) == Array(namespace.utf8))
        #expect(Array(key.name.utf8) == Array(name.utf8))
        #expect(key != differentlyCased)
        #expect(Set([key, differentlyCased]).count == 2)
        requireTypedKey(key)
        requireTypedKey(otherValueType)
        requireSendable(MetadataKey<Double>.self)
    }

    @Test("[Unit][VOX-API-003] erased key identity is exact and case-sensitive")
    func erasedKeyIdentityIsPairBased() throws {
        let original = try AnyMetadataKey(
            namespace: "org.voxelia",
            name: "Window"
        )
        let namespaceCase = try AnyMetadataKey(
            namespace: "ORG.voxelia",
            name: "Window"
        )
        let nameCase = try AnyMetadataKey(
            namespace: "org.voxelia",
            name: "window"
        )

        #expect(Set([original, namespaceCase, nameCase]).count == 3)
        requireSendable(AnyMetadataKey.self)
    }

    @Test("[Unit][VOX-META-001][VOX-API-004] key identity preserves exact UTF-8 spelling")
    func keyIdentityPreservesExactUTF8Spelling() throws {
        let composedNamespace = "org.voxelia.m\u{00E9}tadata"
        let decomposedNamespace = "org.voxelia.me\u{301}tadata"
        let composedName = "valu\u{00E9}"
        let decomposedName = "value\u{301}"

        let typedComposed = try MetadataKey<String>(
            namespace: composedNamespace,
            name: composedName
        )
        let typedNamespaceVariant = try MetadataKey<String>(
            namespace: decomposedNamespace,
            name: composedName
        )
        let typedNameVariant = try MetadataKey<String>(
            namespace: composedNamespace,
            name: decomposedName
        )
        #expect(typedComposed != typedNamespaceVariant)
        #expect(typedComposed != typedNameVariant)
        #expect(
            Set([
                typedComposed,
                typedNamespaceVariant,
                typedNameVariant,
            ]).count == 3
        )

        let erasedComposed = try AnyMetadataKey(
            namespace: composedNamespace,
            name: composedName
        )
        let erasedNamespaceVariant = try AnyMetadataKey(
            namespace: decomposedNamespace,
            name: composedName
        )
        let erasedNameVariant = try AnyMetadataKey(
            namespace: composedNamespace,
            name: decomposedName
        )
        #expect(erasedComposed != erasedNamespaceVariant)
        #expect(erasedComposed != erasedNameVariant)
        #expect(
            Set([
                erasedComposed,
                erasedNamespaceVariant,
                erasedNameVariant,
            ]).count == 3
        )

        for original in [erasedComposed, erasedNamespaceVariant, erasedNameVariant] {
            let decoded = try JSONDecoder().decode(
                AnyMetadataKey.self,
                from: JSONEncoder().encode(original)
            )
            #expect(Array(decoded.namespace.utf8) == Array(original.namespace.utf8))
            #expect(Array(decoded.name.utf8) == Array(original.name.utf8))
        }
    }

    @Test("[Unit][VOX-ERR-001] both key forms reject Unicode-blank fields")
    func rejectsBlankFields() {
        for blank in ["", " \t\n", "\u{2003}\u{00A0}"] {
            #expect(throws: MetadataKeyError.emptyNamespace) {
                try MetadataKey<Double>(namespace: blank, name: "window")
            }
            #expect(throws: MetadataKeyError.emptyName) {
                try MetadataKey<Double>(namespace: "org.voxelia", name: blank)
            }
            #expect(throws: MetadataKeyError.emptyNamespace) {
                try AnyMetadataKey(namespace: blank, name: "window")
            }
            #expect(throws: MetadataKeyError.emptyName) {
                try AnyMetadataKey(namespace: "org.voxelia", name: blank)
            }
        }
    }

    @Test("[Unit][VOX-API-004] erased Codable uses the strict two-field shape")
    func erasedCodableRoundTrip() throws {
        let key = try AnyMetadataKey(
            namespace: "org.voxelia",
            name: "window"
        )
        let data = try JSONEncoder().encode(key)

        #expect(try JSONDecoder().decode(AnyMetadataKey.self, from: data) == key)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(Set(object.keys) == ["namespace", "name"])
        #expect(object["namespace"] as? String == key.namespace)
        #expect(object["name"] as? String == key.name)
    }

    @Test("[Unit][VOX-API-004] erased decoding is strict and contextual")
    func erasedDecodingIsStrictAndContextual() {
        let malformedValues = [
            #"{"namespace":"org.voxelia"}"#,
            #"{"namespace":"org.voxelia","name":"window","extra":true}"#,
            #"[]"#,
        ]
        for malformedValue in malformedValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    AnyMetadataKey.self,
                    from: Data(malformedValue.utf8)
                )
            }
        }

        expectBlankDecoding(
            json: #"{"namespace":" ","name":"window"}"#,
            field: "namespace",
            underlyingError: .emptyNamespace
        )
        expectBlankDecoding(
            json: #"{"namespace":"org.voxelia","name":" "}"#,
            field: "name",
            underlyingError: .emptyName
        )
    }

    private func expectBlankDecoding(
        json: String,
        field: String,
        underlyingError: MetadataKeyError
    ) {
        do {
            _ = try JSONDecoder().decode(
                AnyMetadataKey.self,
                from: Data(json.utf8)
            )
            #expect(Bool(false), "Expected blank metadata key field to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == field)
            #expect(context.underlyingError as? MetadataKeyError == underlyingError)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    private func requireTypedKey<Value: Sendable>(_ key: MetadataKey<Value>) {}

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
