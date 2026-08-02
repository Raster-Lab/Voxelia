// SPDX-License-Identifier: MIT

/// An error raised while validating a codec identifier.
public enum CodecIdentifierError: Error, Sendable, Equatable {
    case emptyNamespace
    case emptyName
}

/// An opaque namespaced identity for a codec, version, and optional profile.
///
/// All accepted strings are preserved exactly. This value identifies a codec
/// declaration; it does not advertise capabilities, interoperability, or
/// content-digest semantics.
public struct CodecIdentifier: Sendable, Hashable, Codable {
    /// The case-sensitive namespace that defines the codec.
    public let namespace: String
    /// The case-sensitive codec name within `namespace`.
    public let name: String
    /// An optional namespace-specific version spelling.
    public let version: String?
    /// An optional namespace-specific codec profile spelling.
    public let profile: String?

    /// Creates an identifier while preserving every accepted string exactly.
    ///
    /// Optional version and profile strings, including empty strings, are
    /// preserved rather than normalized to nil.
    ///
    /// - Throws: ``CodecIdentifierError/emptyNamespace`` or
    ///   ``CodecIdentifierError/emptyName`` when the corresponding required
    ///   field is empty or contains only Unicode whitespace.
    public init(
        namespace: String,
        name: String,
        version: String? = nil,
        profile: String? = nil
    ) throws {
        guard namespace.contains(where: { !$0.isWhitespace }) else {
            throw CodecIdentifierError.emptyNamespace
        }
        guard name.contains(where: { !$0.isWhitespace }) else {
            throw CodecIdentifierError.emptyName
        }

        self.namespace = namespace
        self.name = name
        self.version = version
        self.profile = profile
    }

    /// Compares the exact UTF-8 spellings of all four fields.
    public static func == (lhs: CodecIdentifier, rhs: CodecIdentifier) -> Bool {
        lhs.namespace.utf8.elementsEqual(rhs.namespace.utf8)
            && lhs.name.utf8.elementsEqual(rhs.name.utf8)
            && optionalCodecUTF8Equal(lhs.version, rhs.version)
            && optionalCodecUTF8Equal(lhs.profile, rhs.profile)
    }

    /// Hashes the exact UTF-8 spellings of all four fields.
    public func hash(into hasher: inout Hasher) {
        hashCodecUTF8(namespace, into: &hasher)
        hashCodecUTF8(name, into: &hasher)
        hashOptionalCodecUTF8(version, into: &hasher)
        hashOptionalCodecUTF8(profile, into: &hasher)
    }

    /// Decodes the exact four-field representation and revalidates identity.
    public init(from decoder: any Decoder) throws {
        let namespaceKey = CodecIdentifierCodingKey("namespace")
        let nameKey = CodecIdentifierCodingKey("name")
        let versionKey = CodecIdentifierCodingKey("version")
        let profileKey = CodecIdentifierCodingKey("profile")
        let container = try decoder.container(keyedBy: CodecIdentifierCodingKey.self)
        let expectedKeys = Set([
            namespaceKey.stringValue,
            nameKey.stringValue,
            versionKey.stringValue,
            profileKey.stringValue,
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                        "A codec identifier requires namespace, name, version, and profile."
                )
            )
        }

        let namespace = try container.decode(String.self, forKey: namespaceKey)
        let name = try container.decode(String.self, forKey: nameKey)
        let version = try container.decodeIfPresent(String.self, forKey: versionKey)
        let profile = try container.decodeIfPresent(String.self, forKey: profileKey)
        do {
            try self.init(
                namespace: namespace,
                name: name,
                version: version,
                profile: profile
            )
        } catch let error as CodecIdentifierError {
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
                    debugDescription: "A codec identity field cannot be blank.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all four declared fields, including explicit null optionals.
    public func encode(to encoder: any Encoder) throws {
        let namespaceKey = CodecIdentifierCodingKey("namespace")
        let nameKey = CodecIdentifierCodingKey("name")
        let versionKey = CodecIdentifierCodingKey("version")
        let profileKey = CodecIdentifierCodingKey("profile")
        var container = encoder.container(keyedBy: CodecIdentifierCodingKey.self)
        try container.encode(namespace, forKey: namespaceKey)
        try container.encode(name, forKey: nameKey)
        try container.encode(version, forKey: versionKey)
        try container.encode(profile, forKey: profileKey)
    }
}

private struct CodecIdentifierCodingKey: CodingKey {
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

private func optionalCodecUTF8Equal(_ lhs: String?, _ rhs: String?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        true
    case (.some(let lhs), .some(let rhs)):
        lhs.utf8.elementsEqual(rhs.utf8)
    default:
        false
    }
}

private func hashCodecUTF8(_ value: String, into hasher: inout Hasher) {
    hasher.combine(value.utf8.count)
    for byte in value.utf8 {
        hasher.combine(byte)
    }
}

private func hashOptionalCodecUTF8(_ value: String?, into hasher: inout Hasher) {
    if let value {
        hasher.combine(true)
        hashCodecUTF8(value, into: &hasher)
    } else {
        hasher.combine(false)
    }
}
