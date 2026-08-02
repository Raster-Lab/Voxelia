// SPDX-License-Identifier: MIT

/// A metadata privacy classification used to support logging and export policy.
///
/// Classification does not replace host privacy controls.
public enum MetadataPrivacyClass: String, Sendable, Hashable, Codable {
    case publicData
    case technical
    case potentiallyIdentifying
    case sensitive
    case hostDefined

    /// Decodes one exact classification token with value-redacted failures.
    ///
    /// The decoder deliberately does not retain its incoming coding path or an
    /// underlying decoder error because either may contain patient-identifying
    /// source text supplied by an enclosing keyed representation.
    public init(from decoder: any Decoder) throws {
        let rawValue: String
        do {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(String.self)
        } catch {
            throw metadataPrivacyClassDecodingError()
        }

        guard let value = Self(rawValue: rawValue) else {
            throw metadataPrivacyClassDecodingError()
        }
        self = value
    }

    /// Encodes the exact stable raw-string classification token.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

private func metadataPrivacyClassDecodingError() -> DecodingError {
    .dataCorrupted(
        .init(
            codingPath: [],
            debugDescription: "A recognised metadata privacy classification is required."
        )
    )
}
