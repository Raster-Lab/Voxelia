// SPDX-License-Identifier: MIT

/// The canonical category of a spatial transform.
public enum SpatialTransformKind: String, Sendable, Hashable, Codable {
    case identity
    case rigid
    case similarity
    case affine
    case composite
    case deformationField
}
