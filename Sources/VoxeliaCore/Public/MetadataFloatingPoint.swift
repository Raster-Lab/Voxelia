// SPDX-License-Identifier: MIT

/// An error raised while validating floating-point metadata.
///
/// The single case carries no payload so diagnostics never disclose the
/// rejected value.
public enum MetadataFloatingPointError: Error, Sendable, Equatable {
    case nonFiniteValue
}

/// One finite IEEE 754 binary64 metadata value.
///
/// NaN of any sign or payload and both infinities are rejected, either
/// signed zero is stored as positive zero and every other finite bit
/// pattern, including subnormals, is preserved exactly. Equality and
/// hashing use the stored canonical binary64 identity and never a
/// tolerance, so every constructible value has reflexive equality and
/// coherent set behaviour. The type deliberately conforms to no comparison,
/// literal, presentation or arithmetic protocol, and defines no NaN,
/// infinity, missing or unavailable sentinel.
public struct MetadataFloatingPoint: Sendable, Hashable {
    /// The stored finite canonical value.
    public let value: Double

    /// Creates a validated finite metadata value.
    ///
    /// Classification and zero canonicalisation are exact bit-level work;
    /// no rounding, clamping, denormal flushing or arithmetic conversion
    /// occurs, so subnormal preservation does not depend on an arithmetic
    /// result.
    ///
    /// - Throws: ``MetadataFloatingPointError/nonFiniteValue`` for NaN of
    ///   any sign or payload and for positive or negative infinity.
    public init(value: Double) throws {
        guard value.isFinite else {
            throw MetadataFloatingPointError.nonFiniteValue
        }
        self.value = value.bitPattern == (-0.0).bitPattern ? 0 : value
    }
}

extension MetadataFloatingPoint: Codable {
    /// Decodes one floating-point scalar and revalidates it so serialized
    /// input, including configured non-conforming float strings, cannot
    /// create a non-finite wrapper. The rejected value is never echoed by
    /// the wrapper's own error.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValue = try container.decode(Double.self)

        do {
            try self.init(value: decodedValue)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "The floating-point metadata value is invalid.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes the finite stored value as one scalar number.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
