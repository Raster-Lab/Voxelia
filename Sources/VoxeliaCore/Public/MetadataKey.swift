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
/// spelling, case, Unicode, and surrounding nonblank whitespace. Pair identity
/// compares those accepted UTF-8 spellings exactly; namespace-specific aliases
/// require an explicit schema or adapter policy. Future canonical-digest string
/// normalization is a separate serialization-layer decision.
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

    /// Compares the exact accepted UTF-8 spellings of both identity fields.
    public static func == (
        lhs: MetadataKey<Value>,
        rhs: MetadataKey<Value>
    ) -> Bool {
        metadataKeyStringEqual(lhs.namespace, rhs.namespace)
            && metadataKeyStringEqual(lhs.name, rhs.name)
    }

    /// Hashes the exact accepted UTF-8 spellings of both identity fields.
    public func hash(into hasher: inout Hasher) {
        hashMetadataKeyString(namespace, into: &hasher)
        hashMetadataKeyString(name, into: &hasher)
    }
}

/// A serializable metadata key identified by an exact opaque namespace/name pair.
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

    /// Compares the exact accepted UTF-8 spellings of both identity fields.
    public static func == (lhs: AnyMetadataKey, rhs: AnyMetadataKey) -> Bool {
        metadataKeyStringEqual(lhs.namespace, rhs.namespace)
            && metadataKeyStringEqual(lhs.name, rhs.name)
    }

    /// Hashes the exact accepted UTF-8 spellings of both identity fields.
    public func hash(into hasher: inout Hasher) {
        hashMetadataKeyString(namespace, into: &hasher)
        hashMetadataKeyString(name, into: &hasher)
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
    guard !metadataIdentityFieldIsBlank(namespace) else {
        throw MetadataKeyError.emptyNamespace
    }
    guard !metadataIdentityFieldIsBlank(name) else {
        throw MetadataKeyError.emptyName
    }
}

private func metadataKeyStringEqual(_ lhs: String, _ rhs: String) -> Bool {
    lhs.utf8.elementsEqual(rhs.utf8)
}

private func hashMetadataKeyString(_ value: String, into hasher: inout Hasher) {
    hasher.combine(value.utf8.count)
    for byte in value.utf8 {
        hasher.combine(byte)
    }
}
