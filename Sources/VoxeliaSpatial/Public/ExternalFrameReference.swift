// SPDX-License-Identifier: MIT

/// An error raised while validating an external frame reference.
public enum ExternalFrameReferenceError: Error, Sendable, Equatable {
    case emptyNamespace
    case emptyIdentifier
}

/// An opaque identifier for a coordinate frame owned by an external namespace.
///
/// Spelling, Unicode, case, and surrounding nonblank whitespace are preserved.
/// Namespace-specific equivalence and syntax belong to the owning adapter or
/// host rather than this canonical value.
public struct ExternalFrameReference: Sendable, Hashable, Codable {
    /// The case-sensitive external namespace.
    public let namespace: String
    /// The case-sensitive identifier within `namespace`.
    public let identifier: String

    /// Creates a reference while preserving both supplied strings exactly.
    ///
    /// - Throws: ``ExternalFrameReferenceError/emptyNamespace`` or
    ///   ``ExternalFrameReferenceError/emptyIdentifier`` when the corresponding
    ///   value is empty or contains only Unicode whitespace.
    public init(namespace: String, identifier: String) throws {
        guard containsNonWhitespace(namespace) else {
            throw ExternalFrameReferenceError.emptyNamespace
        }
        guard containsNonWhitespace(identifier) else {
            throw ExternalFrameReferenceError.emptyIdentifier
        }

        self.namespace = namespace
        self.identifier = identifier
    }

    /// Compares the preserved UTF-8 spellings of both fields exactly.
    public static func == (
        lhs: ExternalFrameReference,
        rhs: ExternalFrameReference
    ) -> Bool {
        lhs.namespace.utf8.elementsEqual(rhs.namespace.utf8)
            && lhs.identifier.utf8.elementsEqual(rhs.identifier.utf8)
    }

    /// Hashes the preserved UTF-8 spellings of both fields exactly.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(namespace.utf8.count)
        for byte in namespace.utf8 {
            hasher.combine(byte)
        }
        hasher.combine(identifier.utf8.count)
        for byte in identifier.utf8 {
            hasher.combine(byte)
        }
    }

    /// Decodes the exact keyed representation and revalidates both fields.
    public init(from decoder: any Decoder) throws {
        let namespaceKey = ExternalFrameCodingKey("namespace")
        let identifierKey = ExternalFrameCodingKey("identifier")
        let container = try decoder.container(keyedBy: ExternalFrameCodingKey.self)
        let expectedKeys = Set([namespaceKey.stringValue, identifierKey.stringValue])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                        "An external frame reference requires namespace and identifier."
                )
            )
        }

        let namespace = try container.decode(String.self, forKey: namespaceKey)
        let identifier = try container.decode(String.self, forKey: identifierKey)
        do {
            try self.init(namespace: namespace, identifier: identifier)
        } catch let error as ExternalFrameReferenceError {
            let fieldKey =
                switch error {
                case .emptyNamespace:
                    namespaceKey
                case .emptyIdentifier:
                    identifierKey
                }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [fieldKey],
                    debugDescription: "An external frame field cannot be blank.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes exactly the namespace and identifier fields.
    public func encode(to encoder: any Encoder) throws {
        let namespaceKey = ExternalFrameCodingKey("namespace")
        let identifierKey = ExternalFrameCodingKey("identifier")
        var container = encoder.container(keyedBy: ExternalFrameCodingKey.self)
        try container.encode(namespace, forKey: namespaceKey)
        try container.encode(identifier, forKey: identifierKey)
    }
}

private struct ExternalFrameCodingKey: CodingKey {
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

private func containsNonWhitespace(_ value: String) -> Bool {
    value.contains(where: { !$0.isWhitespace })
}
