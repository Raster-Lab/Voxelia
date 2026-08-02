// SPDX-License-Identifier: MIT

/// The broad logical form of a geometry object.
///
/// This taxonomy describes scientific geometry independently of its storage or
/// rendering representation.
public enum GeometryKind: String, Sendable, Hashable, Codable {
    /// An unordered collection of points.
    case pointSet

    /// A collection of independent line segments.
    case lineSet

    /// A collection of connected polylines.
    case polylineSet

    /// A centre-line representation.
    case centreLine

    /// A surface represented by triangles.
    case triangleMesh

    /// A surface represented by polygons.
    case polygonMesh

    /// A geometry object describing a spatial bound.
    case boundingVolume
}
