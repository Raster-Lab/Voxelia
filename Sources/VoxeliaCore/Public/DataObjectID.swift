// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// A stable identity for one immutable Voxelia object instance or published
/// object record.
///
/// Object identity is not a substitute for content equality, derivation
/// identity, or a verified cache key.
public struct DataObjectID: VoxeliaStringIdentifier {
    /// The preserved case-sensitive identifier spelling.
    public let rawValue: String

    /// Creates an identifier unless `rawValue` is empty or Unicode-whitespace-only.
    public init?(rawValue: String) {
        guard rawValue.contains(where: { !$0.isWhitespace }) else { return nil }
        self.rawValue = rawValue
    }
}
