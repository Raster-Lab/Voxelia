// SPDX-License-Identifier: MIT

/// An error raised while validating a transfer function.
public enum TransferFunctionError: Error, Sendable, Equatable {
    /// The table did not contain exactly two hundred fifty-six
    /// entries.
    case invalidTableSize
}

/// One transfer-function entry per `ADR-0167`: four structurally
/// valid eight-bit components.
public struct TransferFunctionEntry: Sendable, Hashable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let opacity: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, opacity: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
}

/// The one-dimensional transfer function per `ADR-0167`
/// (`VOX-DVR-005`, `VOX-DVR-007`).
///
/// The table carries exactly one entry per eight-bit display sample
/// and stays integer — the compositing model that consumes it owns
/// the binary64 conversion. Everything this vocabulary feeds is
/// presentation, never a source of authoritative quantitative
/// measurement, per the arc's binding rule.
public struct TransferFunction1D: Sendable, Hashable {
    /// The exact table size.
    public static let tableSize = 256

    /// The two hundred fifty-six entries, one per display sample.
    public let entries: ContiguousArray<TransferFunctionEntry>

    /// Creates a validated table.
    ///
    /// - Throws: ``TransferFunctionError/invalidTableSize``.
    public init(entries: ContiguousArray<TransferFunctionEntry>) throws {
        guard entries.count == Self.tableSize else {
            throw TransferFunctionError.invalidTableSize
        }
        self.entries = entries
    }

    /// The entry for one integer index under the declared clamp rule
    /// `clamp(index, 0, 255)` — the identity for the eight-bit
    /// domain, and the pre-frozen behaviour for wider adapter-borne
    /// domains.
    public func entry(at index: Int) -> TransferFunctionEntry {
        entries[min(Self.tableSize - 1, max(0, index))]
    }
}
