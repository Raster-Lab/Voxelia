// SPDX-License-Identifier: MIT

/// An error raised while validating a provenance warning value.
///
/// Cases deliberately carry no payload so diagnostics never disclose the
/// rejected code text or count.
public enum ProvenanceWarningError: Error, Sendable, Equatable {
    case invalidCode
    case codeByteLimitExceeded
    case invalidOccurrenceCount
}

/// One bounded, descriptive provenance warning code.
///
/// The code names a condition in a governed vocabulary using the bounded
/// lowercase ASCII reverse-domain grammar with byte-limit-before-grammar
/// precedence, as its own nominal authority per `ADR-0052`. It is never
/// free text and never executable.
public struct ProvenanceWarningCode: Sendable, Hashable {
    /// The hard inclusive complete-code byte ceiling.
    public static let maximumCodeUTF8ByteCount: UInt64 = 255
    /// The hard inclusive per-label byte ceiling.
    public static let maximumCodeLabelByteCount: UInt64 = 63

    public let rawValue: String

    /// Creates a validated code with fixed byte-limit-before-grammar
    /// precedence: the complete byte count is checked first, each label
    /// length next, and grammar rules only then.
    public init(rawValue: String) throws {
        try Self.validateCode(rawValue)
        self.rawValue = rawValue
    }

    /// Compares the exact ASCII code bytes.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.utf8.elementsEqual(rhs.rawValue.utf8)
    }

    /// Hashes the exact ASCII code bytes.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.utf8.count)
        for byte in rawValue.utf8 {
            hasher.combine(byte)
        }
    }

    private static func isLabelAlphanumeric(_ byte: UInt8) -> Bool {
        (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
            || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
    }

    static func validateCode(_ code: String) throws {
        // Precedence step one: the complete byte ceiling, stopping at the
        // first byte past the maximum.
        var totalByteCount: UInt64 = 0
        for _ in code.utf8 {
            totalByteCount += 1
            if totalByteCount > Self.maximumCodeUTF8ByteCount {
                throw ProvenanceWarningError.codeByteLimitExceeded
            }
        }

        // Precedence step two: each label length.
        var labelByteCount: UInt64 = 0
        for byte in code.utf8 {
            if byte == UInt8(ascii: ".") {
                labelByteCount = 0
                continue
            }
            labelByteCount += 1
            if labelByteCount > Self.maximumCodeLabelByteCount {
                throw ProvenanceWarningError.codeByteLimitExceeded
            }
        }

        // Precedence step three: empty labels, characters, first/last
        // characters and the label count.
        var labelCount: UInt64 = 0
        var previousByte: UInt8?
        for byte in code.utf8 {
            if byte == UInt8(ascii: ".") {
                guard let last = previousByte, isLabelAlphanumeric(last) else {
                    throw ProvenanceWarningError.invalidCode
                }
                labelCount += 1
                previousByte = byte
                continue
            }
            let isHyphen = byte == UInt8(ascii: "-")
            guard isLabelAlphanumeric(byte) || isHyphen else {
                throw ProvenanceWarningError.invalidCode
            }
            let startsLabel = previousByte == nil || previousByte == UInt8(ascii: ".")
            if startsLabel && isHyphen {
                throw ProvenanceWarningError.invalidCode
            }
            previousByte = byte
        }
        guard let last = previousByte, isLabelAlphanumeric(last) else {
            throw ProvenanceWarningError.invalidCode
        }
        labelCount += 1
        guard labelCount >= 2 else {
            throw ProvenanceWarningError.invalidCode
        }
    }
}

/// The exact major/minor version of the governed vocabulary defining a
/// warning code, pinning the code's meaning to one published revision.
public struct ProvenanceWarningSchemaVersion: Sendable, Hashable {
    public let major: UInt32
    public let minor: UInt32

    public init(major: UInt32, minor: UInt32) {
        self.major = major
        self.minor = minor
    }
}

/// The closed severity of one provenance warning claim.
///
/// Exactly three cases exist; any extension requires its own decision
/// record per `ADR-0052`.
public enum ProvenanceWarningSeverity: Sendable, Hashable {
    /// Asserts the condition had no output effect.
    case informational
    /// Asserts output quality was affected.
    case qualityAffecting
    /// Asserts the result may be unusable for its stated purpose.
    case integrityAffecting
}

/// One immutable aggregated provenance warning claim per `ADR-0052`.
///
/// The claim binds one governed code, its schema version, one severity
/// and a checked occurrence count; repetition is counted, never repeated
/// as entries. There is no message, reason, path or parameter field, so
/// free text is structurally impossible in the Core identity; richer
/// diagnostics belong to host-side rendering of the governed vocabulary.
/// The stable coding is owned by the future canonical provenance-record
/// projection decision.
public struct ProvenanceWarning: Sendable, Hashable {
    public let code: ProvenanceWarningCode
    public let schemaVersion: ProvenanceWarningSchemaVersion
    public let severity: ProvenanceWarningSeverity
    public let occurrenceCount: UInt64

    /// Creates an aggregated warning claim.
    ///
    /// - Throws: ``ProvenanceWarningError/invalidOccurrenceCount`` when
    ///   the count is zero.
    public init(
        code: ProvenanceWarningCode,
        schemaVersion: ProvenanceWarningSchemaVersion,
        severity: ProvenanceWarningSeverity,
        occurrenceCount: UInt64
    ) throws {
        guard occurrenceCount >= 1 else {
            throw ProvenanceWarningError.invalidOccurrenceCount
        }
        self.code = code
        self.schemaVersion = schemaVersion
        self.severity = severity
        self.occurrenceCount = occurrenceCount
    }
}
