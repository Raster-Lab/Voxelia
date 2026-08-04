// SPDX-License-Identifier: MIT

/// One exact major/minor schema version used inside `VCMJ-1` documents.
///
/// The type gains no standalone `Codable` in version one; its stable role
/// is inside the dedicated canonical codec.
public struct MetadataSchemaVersion: Sendable, Hashable {
    public let major: UInt32
    public let minor: UInt32

    public init(major: UInt32, minor: UInt32) {
        self.major = major
        self.minor = minor
    }
}

/// An error raised while validating a schema-reference identifier.
///
/// Cases deliberately carry no payload so diagnostics never disclose the
/// rejected identifier text.
public enum MetadataSchemaReferenceError: Error, Sendable, Equatable {
    case invalidIdentifier
    case identifierByteLimitExceeded
}

/// One bounded, immutable schema reference: a lowercase ASCII
/// reverse-domain identifier plus an exact version.
///
/// The identifier grammar is two or more dot-separated labels; each label
/// is 1 through 63 bytes, begins and ends with `a` through `z` or `0`
/// through `9`, and otherwise contains only those characters or `-`. The
/// complete identifier is at most 255 ASCII bytes. There is no case
/// folding, percent decoding, IDNA, DNS resolution or aliasing, and the
/// reference is an opaque name, never a network operation. The type gains
/// no standalone `Codable` in version one.
public struct MetadataSchemaReference: Sendable, Hashable {
    /// The hard inclusive complete-identifier byte ceiling.
    public static let maximumIdentifierUTF8ByteCount: UInt64 = 255
    /// The hard inclusive per-label byte ceiling.
    public static let maximumIdentifierLabelByteCount: UInt64 = 63

    public let identifier: String
    public let version: MetadataSchemaVersion

    /// Creates a validated reference.
    ///
    /// - Throws: ``MetadataSchemaReferenceError/invalidIdentifier`` on a
    ///   grammar failure, or
    ///   ``MetadataSchemaReferenceError/identifierByteLimitExceeded`` when
    ///   a hard byte ceiling is crossed by an otherwise valid character.
    public init(identifier: String, version: MetadataSchemaVersion) throws {
        try Self.validateIdentifier(identifier)
        self.identifier = identifier
        self.version = version
    }

    /// Compares the exact ASCII identifier bytes and the exact version.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier.utf8.elementsEqual(rhs.identifier.utf8)
            && lhs.version == rhs.version
    }

    /// Hashes the exact ASCII identifier bytes and the exact version.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier.utf8.count)
        for byte in identifier.utf8 {
            hasher.combine(byte)
        }
        hasher.combine(version)
    }

    private static func isLabelAlphanumeric(_ byte: UInt8) -> Bool {
        (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
            || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
    }

    /// Validates the grammar incrementally: each character is validated
    /// before its label/total byte charge, so an invalid character at a
    /// limit boundary reports the grammar failure.
    static func validateIdentifier(_ identifier: String) throws {
        var labelByteCount: UInt64 = 0
        var totalByteCount: UInt64 = 0
        var labelCount: UInt64 = 0
        var previousByte: UInt8?

        for byte in identifier.utf8 {
            if byte == UInt8(ascii: ".") {
                guard let last = previousByte, isLabelAlphanumeric(last) else {
                    throw MetadataSchemaReferenceError.invalidIdentifier
                }
                totalByteCount += 1
                guard totalByteCount <= Self.maximumIdentifierUTF8ByteCount else {
                    throw MetadataSchemaReferenceError.identifierByteLimitExceeded
                }
                labelCount += 1
                labelByteCount = 0
                previousByte = byte
                continue
            }

            let isHyphen = byte == UInt8(ascii: "-")
            guard isLabelAlphanumeric(byte) || isHyphen else {
                throw MetadataSchemaReferenceError.invalidIdentifier
            }
            let startsLabel = previousByte == nil || previousByte == UInt8(ascii: ".")
            if startsLabel && isHyphen {
                throw MetadataSchemaReferenceError.invalidIdentifier
            }
            labelByteCount += 1
            totalByteCount += 1
            guard labelByteCount <= Self.maximumIdentifierLabelByteCount else {
                throw MetadataSchemaReferenceError.identifierByteLimitExceeded
            }
            guard totalByteCount <= Self.maximumIdentifierUTF8ByteCount else {
                throw MetadataSchemaReferenceError.identifierByteLimitExceeded
            }
            previousByte = byte
        }

        guard let last = previousByte, isLabelAlphanumeric(last) else {
            throw MetadataSchemaReferenceError.invalidIdentifier
        }
        labelCount += 1
        guard labelCount >= 2 else {
            throw MetadataSchemaReferenceError.invalidIdentifier
        }
    }
}
