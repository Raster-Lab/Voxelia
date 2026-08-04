// SPDX-License-Identifier: MIT

/// One owned, immutable binary metadata value.
///
/// Identity is the exact byte count followed by the exact ordered byte
/// sequence; source storage class, allocation, Foundation bridging and
/// textual encoding are not identity. Empty bytes are valid and differ from
/// an absent metadata entry. The type deliberately conforms to no literal,
/// collection, mutation or presentation protocol, and Swift's
/// process-randomised hash is only an in-memory collection aid, never a
/// content digest.
public struct MetadataBinary: Sendable, Hashable {
    /// The owned ordered bytes.
    public let bytes: ContiguousArray<UInt8>

    /// Creates an owned snapshot of the observed byte sequence.
    ///
    /// The initialiser materialises one canonical `ContiguousArray<UInt8>`
    /// and retains neither the source collection nor externally managed
    /// memory, so later mutation of a caller-managed backing cannot change
    /// the stored value.
    public init<Bytes: Collection>(bytes: Bytes) where Bytes.Element == UInt8 {
        self.bytes = ContiguousArray(bytes)
    }
}

extension MetadataBinary: Codable {
    /// The checked decoded byte count for one padded standard-Base64 string,
    /// or nil when the shape or arithmetic is invalid.
    static func decodedByteCount(encodedUTF8Count: Int, paddingCount: Int) -> Int? {
        guard encodedUTF8Count >= 0, (0...2).contains(paddingCount) else {
            return nil
        }
        if encodedUTF8Count == 0 {
            return paddingCount == 0 ? 0 : nil
        }
        guard encodedUTF8Count % 4 == 0 else {
            return nil
        }
        let quartets = encodedUTF8Count / 4
        let (grouped, overflow) = quartets.multipliedReportingOverflow(by: 3)
        guard !overflow, grouped >= paddingCount else {
            return nil
        }
        return grouped - paddingCount
    }

    /// The checked encoded UTF-8 count for one byte count, or nil when the
    /// arithmetic overflows.
    static func encodedUTF8Count(byteCount: Int) -> Int? {
        guard byteCount >= 0 else {
            return nil
        }
        let groups = byteCount / 3 + (byteCount % 3 == 0 ? 0 : 1)
        let (encoded, overflow) = groups.multipliedReportingOverflow(by: 4)
        return overflow ? nil : encoded
    }

    private static let alphabet: [UInt8] = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8
    )

    private static func sextet(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 0x41...0x5A: byte - 0x41
        case 0x61...0x7A: byte - 0x61 + 26
        case 0x30...0x39: byte - 0x30 + 52
        case 0x2B: 62
        case 0x2F: 63
        default: nil
        }
    }

    /// Decodes one strict padded standard-Base64 semantic string, or nil for
    /// every alias, alphabet, padding, whitespace or unused-bit violation.
    static func decodeCanonicalBase64(_ encoded: [UInt8]) -> ContiguousArray<UInt8>? {
        if encoded.isEmpty {
            return []
        }
        guard encoded.count % 4 == 0 else {
            return nil
        }

        var paddingCount = 0
        if encoded[encoded.count - 1] == 0x3D {
            paddingCount = encoded[encoded.count - 2] == 0x3D ? 2 : 1
        }
        guard
            let decodedCount = decodedByteCount(
                encodedUTF8Count: encoded.count,
                paddingCount: paddingCount
            )
        else {
            return nil
        }

        var decoded = ContiguousArray<UInt8>()
        decoded.reserveCapacity(decodedCount)
        for quartetStart in stride(from: 0, to: encoded.count, by: 4) {
            let isFinalQuartet = quartetStart + 4 == encoded.count
            let dataCharacterCount = isFinalQuartet ? 4 - paddingCount : 4
            var accumulator = 0
            for offset in 0..<4 {
                let byte = encoded[quartetStart + offset]
                if offset < dataCharacterCount {
                    guard let value = Self.sextet(byte) else {
                        return nil
                    }
                    accumulator = accumulator << 6 | Int(value)
                } else {
                    guard byte == 0x3D else {
                        return nil
                    }
                    accumulator <<= 6
                }
            }

            if isFinalQuartet {
                // Reject non-zero unused bits so one byte sequence has
                // exactly one accepted string: with two pads the second
                // sextet's low four bits occupy accumulator bits 12-15,
                // and with one pad the third sextet's low two bits occupy
                // accumulator bits 6-7.
                if paddingCount == 2, accumulator & 0xF000 != 0 {
                    return nil
                }
                if paddingCount == 1, accumulator & 0xC0 != 0 {
                    return nil
                }
            }
            decoded.append(UInt8(truncatingIfNeeded: accumulator >> 16))
            if !isFinalQuartet || paddingCount < 2 {
                decoded.append(UInt8(truncatingIfNeeded: accumulator >> 8))
            }
            if !isFinalQuartet || paddingCount < 1 {
                decoded.append(UInt8(truncatingIfNeeded: accumulator))
            }
        }
        return decoded
    }

    /// Encodes the stored bytes as the one canonical padded standard-Base64
    /// string.
    static func encodeCanonicalBase64(_ bytes: ContiguousArray<UInt8>) -> String {
        var encoded = [UInt8]()
        encoded.reserveCapacity(Self.encodedUTF8Count(byteCount: bytes.count) ?? 0)
        for groupStart in stride(from: 0, to: bytes.count, by: 3) {
            let remaining = bytes.count - groupStart
            var accumulator = Int(bytes[groupStart]) << 16
            if remaining > 1 {
                accumulator |= Int(bytes[groupStart + 1]) << 8
            }
            if remaining > 2 {
                accumulator |= Int(bytes[groupStart + 2])
            }

            encoded.append(Self.alphabet[accumulator >> 18 & 0x3F])
            encoded.append(Self.alphabet[accumulator >> 12 & 0x3F])
            encoded.append(remaining > 1 ? Self.alphabet[accumulator >> 6 & 0x3F] : 0x3D)
            encoded.append(remaining > 2 ? Self.alphabet[accumulator & 0x3F] : 0x3D)
        }
        return String(decoding: encoded, as: UTF8.self)
    }

    /// Decodes one strict padded standard-Base64 JSON string. Malformed
    /// semantic strings become one value-redacted `dataCorrupted` failure
    /// that contains neither the source string, its bytes nor its length.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encodedString = try container.decode(String.self)

        guard let decoded = Self.decodeCanonicalBase64(Array(encodedString.utf8)) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "The binary metadata string is invalid."
                )
            )
        }
        self.bytes = decoded
    }

    /// Encodes the one canonical padded standard-Base64 string.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Self.encodeCanonicalBase64(bytes))
    }
}
