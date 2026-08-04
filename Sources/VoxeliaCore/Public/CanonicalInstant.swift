// SPDX-License-Identifier: MIT

/// An error raised while validating a canonical instant.
///
/// Cases deliberately carry no payload so diagnostics never disclose the
/// supplied timestamp, which can itself be sensitive context.
public enum CanonicalInstantError: Error, Sendable, Equatable {
    case invalidLength
    case invalidSyntax
    case yearOutOfRange
    case monthOutOfRange
    case dayOutOfRange
    case hourOutOfRange
    case minuteOutOfRange
    case secondOutOfRange
    case unsupportedLeapSecond
    case nonCanonicalFraction
}

/// One canonical zero-offset UTC instant spelling.
///
/// The version-one profile is `full-date "T" clock-time [fraction] "Z"` with
/// uppercase `T` and `Z`, ASCII digits, Common Era years 0001-9999 on the
/// proleptic Gregorian calendar, mandatory seconds, no offsets and an
/// optional one-to-nine-digit fraction whose last digit is non-zero. Every
/// value on this leap-unaware 86,400-second-per-day grid has exactly one
/// spelling, so exact stored-string equality and hashing are identity within
/// the profile. The value deliberately does not conform to `Comparable`:
/// variable fractional width makes lexical order chronologically wrong, and
/// a future ordering must compare validated components instead.
public struct CanonicalInstant: Sendable, Hashable {
    /// The intrinsic maximum accepted UTF-8 byte count.
    public static let maximumUTF8ByteCount = 30

    /// The accepted canonical ASCII spelling, preserved exactly.
    public let utcString: String

    /// Creates a validated canonical instant.
    ///
    /// Validation inspects UTF-8 directly with no locale, time zone
    /// database, leap-second table or formatter, and materialises at most
    /// 31 candidate bytes. Errors follow the documented precedence and
    /// never contain the supplied text.
    ///
    /// - Throws: ``CanonicalInstantError`` describing the first defect in
    ///   the documented precedence order.
    public init(utcString: String) throws {
        var bytes = [UInt8]()
        bytes.reserveCapacity(31)
        for byte in utcString.utf8 {
            bytes.append(byte)
            if bytes.count == 31 { break }
        }
        guard bytes.count == 20 || (22...30).contains(bytes.count) else {
            throw CanonicalInstantError.invalidLength
        }

        func isDigit(_ byte: UInt8) -> Bool {
            (0x30...0x39).contains(byte)
        }
        func digits(_ range: Range<Int>) -> Bool {
            range.allSatisfy { isDigit(bytes[$0]) }
        }
        func value(_ range: Range<Int>) -> Int {
            range.reduce(0) { $0 * 10 + Int(bytes[$1] - 0x30) }
        }

        let structureIsValid =
            digits(0..<4) && bytes[4] == 0x2D
            && digits(5..<7) && bytes[7] == 0x2D
            && digits(8..<10) && bytes[10] == 0x54
            && digits(11..<13) && bytes[13] == 0x3A
            && digits(14..<16) && bytes[16] == 0x3A
            && digits(17..<19)
            && bytes[bytes.count - 1] == 0x5A
            && (bytes.count == 20
                || (bytes[19] == 0x2E && digits(20..<(bytes.count - 1))))
        guard structureIsValid else {
            throw CanonicalInstantError.invalidSyntax
        }

        let year = value(0..<4)
        guard year >= 1 else {
            throw CanonicalInstantError.yearOutOfRange
        }
        let month = value(5..<7)
        guard (1...12).contains(month) else {
            throw CanonicalInstantError.monthOutOfRange
        }
        let day = value(8..<10)
        guard (1...Self.dayCount(year: year, month: month)).contains(day) else {
            throw CanonicalInstantError.dayOutOfRange
        }
        guard value(11..<13) <= 23 else {
            throw CanonicalInstantError.hourOutOfRange
        }
        guard value(14..<16) <= 59 else {
            throw CanonicalInstantError.minuteOutOfRange
        }
        let second = value(17..<19)
        if second == 60 {
            throw CanonicalInstantError.unsupportedLeapSecond
        }
        guard second <= 59 else {
            throw CanonicalInstantError.secondOutOfRange
        }
        if bytes.count > 20, bytes[bytes.count - 2] == 0x30 {
            throw CanonicalInstantError.nonCanonicalFraction
        }

        self.utcString = utcString
    }

    /// The proleptic Gregorian day count for one month.
    private static func dayCount(year: Int, month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12:
            31
        case 4, 6, 9, 11:
            30
        default:
            (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28
        }
    }
}

extension CanonicalInstant: Codable {
    /// Decodes one JSON string and revalidates it so serialized input cannot
    /// bypass the canonical profile. The rejected text is never echoed.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedString = try container.decode(String.self)

        do {
            try self.init(utcString: decodedString)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "The canonical instant is invalid.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes exactly the accepted canonical spelling.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(utcString)
    }
}
