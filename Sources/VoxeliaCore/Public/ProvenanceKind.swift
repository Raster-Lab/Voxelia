// SPDX-License-Identifier: MIT

/// The canonical category of a provenance record.
///
/// This vocabulary does not itself provide record identity, graph
/// relationships, validation status, or a processing guarantee.
public enum ProvenanceKind: String, Sendable, Hashable, Codable {
    case source
    case imported
    case decoded
    case viewed
    case transformed
    case processed
    case segmented
    case registered
    case rendered
    case materialised
    case cached
}
