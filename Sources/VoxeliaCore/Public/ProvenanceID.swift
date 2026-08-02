// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// A stable identity for a provenance record or graph node.
///
/// This identifier does not itself establish record validity, graph
/// consistency, or evidence authenticity.
public struct ProvenanceID: VoxeliaStringIdentifier {
    /// The preserved case-sensitive identifier spelling.
    public let rawValue: String

    /// Creates an identifier unless `rawValue` is empty or Unicode-whitespace-only.
    public init?(rawValue: String) {
        guard rawValue.contains(where: { !$0.isWhitespace }) else { return nil }
        self.rawValue = rawValue
    }
}
