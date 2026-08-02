// SPDX-License-Identifier: MIT

/// An error raised while validating a neutral coded concept.
public enum CodedConceptError: Error, Sendable, Equatable {
    case emptyScheme
    case emptyValue
}

/// A terminology-neutral scheme/value concept.
///
/// Identity uses the exact accepted UTF-8 spellings of `scheme`, `value`, and
/// `version`. Human-readable ``meaning`` is preserved but excluded from equality
/// and hashing. Scheme-specific aliases, version compatibility, and ontology
/// equivalence require an explicit resolver outside this canonical value.
public struct CodedConcept: Sendable, Hashable, Codable {
    /// The case-sensitive terminology or ontology scheme.
    public let scheme: String
    /// The case-sensitive code within `scheme`.
    public let value: String
    /// Optional human-readable text that does not define identity.
    public let meaning: String?
    /// An optional scheme-specific version spelling that participates in identity.
    public let version: String?

    /// Creates a concept while preserving every accepted string exactly.
    ///
    /// Optional meaning and version strings, including empty strings, are
    /// preserved rather than normalized to nil.
    ///
    /// - Throws: ``CodedConceptError/emptyScheme`` or
    ///   ``CodedConceptError/emptyValue`` when the corresponding identity field
    ///   is empty or contains only Unicode whitespace.
    public init(
        scheme: String,
        value: String,
        meaning: String? = nil,
        version: String? = nil
    ) throws {
        guard scheme.contains(where: { !$0.isWhitespace }) else {
            throw CodedConceptError.emptyScheme
        }
        guard value.contains(where: { !$0.isWhitespace }) else {
            throw CodedConceptError.emptyValue
        }

        self.scheme = scheme
        self.value = value
        self.meaning = meaning
        self.version = version
    }

    /// Compares exact identity spellings while ignoring display meaning.
    public static func == (lhs: CodedConcept, rhs: CodedConcept) -> Bool {
        lhs.scheme.utf8.elementsEqual(rhs.scheme.utf8)
            && lhs.value.utf8.elementsEqual(rhs.value.utf8)
            && optionalUTF8Equal(lhs.version, rhs.version)
    }

    /// Hashes exact identity spellings while ignoring display meaning.
    public func hash(into hasher: inout Hasher) {
        hashUTF8(scheme, into: &hasher)
        hashUTF8(value, into: &hasher)
        if let version {
            hasher.combine(true)
            hashUTF8(version, into: &hasher)
        } else {
            hasher.combine(false)
        }
    }

    /// Decodes the exact four-field representation and revalidates identity.
    public init(from decoder: any Decoder) throws {
        let schemeKey = CodedConceptCodingKey("scheme")
        let valueKey = CodedConceptCodingKey("value")
        let meaningKey = CodedConceptCodingKey("meaning")
        let versionKey = CodedConceptCodingKey("version")
        let container = try decoder.container(keyedBy: CodedConceptCodingKey.self)
        let expectedKeys = Set([
            schemeKey.stringValue,
            valueKey.stringValue,
            meaningKey.stringValue,
            versionKey.stringValue,
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                        "A coded concept requires scheme, value, meaning, and version."
                )
            )
        }

        let scheme = try container.decode(String.self, forKey: schemeKey)
        let value = try container.decode(String.self, forKey: valueKey)
        let meaning = try container.decodeIfPresent(String.self, forKey: meaningKey)
        let version = try container.decodeIfPresent(String.self, forKey: versionKey)
        do {
            try self.init(
                scheme: scheme,
                value: value,
                meaning: meaning,
                version: version
            )
        } catch let error as CodedConceptError {
            let invalidKey =
                switch error {
                case .emptyScheme:
                    schemeKey
                case .emptyValue:
                    valueKey
                }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [invalidKey],
                    debugDescription: "A coded-concept identity field cannot be blank.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all four declared fields, including explicit null optionals.
    public func encode(to encoder: any Encoder) throws {
        let schemeKey = CodedConceptCodingKey("scheme")
        let valueKey = CodedConceptCodingKey("value")
        let meaningKey = CodedConceptCodingKey("meaning")
        let versionKey = CodedConceptCodingKey("version")
        var container = encoder.container(keyedBy: CodedConceptCodingKey.self)
        try container.encode(scheme, forKey: schemeKey)
        try container.encode(value, forKey: valueKey)
        try container.encode(meaning, forKey: meaningKey)
        try container.encode(version, forKey: versionKey)
    }
}

private struct CodedConceptCodingKey: CodingKey {
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

private func optionalUTF8Equal(_ lhs: String?, _ rhs: String?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        true
    case (.some(let lhs), .some(let rhs)):
        lhs.utf8.elementsEqual(rhs.utf8)
    default:
        false
    }
}

private func hashUTF8(_ value: String, into hasher: inout Hasher) {
    hasher.combine(value.utf8.count)
    for byte in value.utf8 {
        hasher.combine(byte)
    }
}
