// SPDX-License-Identifier: MIT

/// Transport `Codable` conformances for the identity tokens the
/// `ADR-0401` distributed job descriptions carry. Every decode
/// revalidates through the same throwing admission as construction —
/// the standing frame-geometry precedent.

extension ExecutionClaimToken: Codable {
    /// Decodes and revalidates the token spelling.
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        try self.init(rawValue: raw)
    }

    /// Encodes the exact token spelling.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension DerivationOperationToken: Codable {
    /// Decodes and revalidates the token spelling.
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        try self.init(rawValue: raw)
    }

    /// Encodes the exact token spelling.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension DerivationImplementationReference: Codable {
    private enum CodingKeys: String, CodingKey {
        case identifier
        case version
    }

    /// Decodes and revalidates both members.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            identifier: try container.decode(
                DerivationOperationToken.self,
                forKey: .identifier
            ),
            version: try container.decode(SemanticVersion.self, forKey: .version)
        )
    }

    /// Encodes both members.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(version, forKey: .version)
    }
}
