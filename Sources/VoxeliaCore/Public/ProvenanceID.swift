// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// A stable identity for a provenance record or graph node.
///
/// This identifier does not itself establish record validity, graph
/// consistency, or evidence authenticity.
public struct ProvenanceID: VoxeliaStringIdentifier {
    /// The preserved case-sensitive identifier spelling.
    public let rawValue: String

    /// The hard inclusive raw-value byte ceiling selected by `ADR-0044`.
    public static let maximumUTF8ByteCount = 255

    /// Creates an identifier unless `rawValue` is empty,
    /// Unicode-whitespace-only or over the persistent byte ceiling.
    public init?(rawValue: String) {
        guard rawValue.contains(where: { !$0.isWhitespace }),
            rawValue.utf8.count <= Self.maximumUTF8ByteCount
        else { return nil }
        self.rawValue = rawValue
    }

    /// Compares the exact accepted UTF-8 bytes: canonically equivalent
    /// but byte-distinct spellings are distinct identifiers.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.utf8.elementsEqual(rhs.rawValue.utf8)
    }

    /// Hashes the exact accepted UTF-8 bytes.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.utf8.count)
        for byte in rawValue.utf8 {
            hasher.combine(byte)
        }
    }
}
