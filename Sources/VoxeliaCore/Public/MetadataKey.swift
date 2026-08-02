// SPDX-License-Identifier: MIT

/// An error raised while validating a metadata key.
public enum MetadataKeyError: Error, Sendable, Equatable {
    case emptyNamespace
    case emptyName
}

/// A strongly typed metadata key identified by an opaque namespace/name pair.
///
/// The generic parameter identifies the expected value type at compile time; it
/// is not stored or serialized. Namespace and name preserve all accepted
/// spelling, case, Unicode, and surrounding nonblank whitespace.
public struct MetadataKey<Value: Sendable>: Sendable, Hashable {
    /// The case-sensitive namespace that owns the key.
    public let namespace: String
    /// The case-sensitive name within `namespace`.
    public let name: String

    /// Creates a typed key while preserving both strings exactly.
    ///
    /// - Throws: ``MetadataKeyError/emptyNamespace`` or
    ///   ``MetadataKeyError/emptyName`` when the corresponding field is empty
    ///   or contains only Unicode whitespace.
    public init(namespace: String, name: String) throws {
        try validateMetadataKey(namespace: namespace, name: name)
        self.namespace = namespace
        self.name = name
    }
}

/// A serializable metadata key identified by an opaque namespace/name pair.
public struct AnyMetadataKey: Sendable, Hashable, Codable {
    /// The case-sensitive namespace that owns the key.
    public let namespace: String
    /// The case-sensitive name within `namespace`.
    public let name: String

    /// Creates a serializable key while preserving both strings exactly.
    ///
    /// - Throws: ``MetadataKeyError/emptyNamespace`` or
    ///   ``MetadataKeyError/emptyName`` when the corresponding field is empty
    ///   or contains only Unicode whitespace.
    public init(namespace: String, name: String) throws {
        try validateMetadataKey(namespace: namespace, name: name)
        self.namespace = namespace
        self.name = name
    }

    /// Decodes the exact keyed representation and revalidates both fields.
    public init(from decoder: any Decoder) throws {
        let namespaceKey = MetadataKeyCodingKey("namespace")
        let nameKey = MetadataKeyCodingKey("name")
        let container = try decoder.container(keyedBy: MetadataKeyCodingKey.self)
        let expectedKeys = Set([namespaceKey.stringValue, nameKey.stringValue])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "A metadata key requires namespace and name."
                )
            )
        }

        let namespace = try container.decode(String.self, forKey: namespaceKey)
        let name = try container.decode(String.self, forKey: nameKey)
        do {
            try self.init(namespace: namespace, name: name)
        } catch let error as MetadataKeyError {
            let invalidKey =
                switch error {
                case .emptyNamespace:
                    namespaceKey
                case .emptyName:
                    nameKey
                }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [invalidKey],
                    debugDescription: "A metadata key field cannot be blank.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes exactly the namespace and name fields.
    public func encode(to encoder: any Encoder) throws {
        let namespaceKey = MetadataKeyCodingKey("namespace")
        let nameKey = MetadataKeyCodingKey("name")
        var container = encoder.container(keyedBy: MetadataKeyCodingKey.self)
        try container.encode(namespace, forKey: namespaceKey)
        try container.encode(name, forKey: nameKey)
    }
}

private struct MetadataKeyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

private func validateMetadataKey(namespace: String, name: String) throws {
    guard namespace.contains(where: { !$0.isWhitespace }) else {
        throw MetadataKeyError.emptyNamespace
    }
    guard name.contains(where: { !$0.isWhitespace }) else {
        throw MetadataKeyError.emptyName
    }
}
