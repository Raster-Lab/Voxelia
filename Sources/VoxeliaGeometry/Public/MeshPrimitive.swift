// SPDX-License-Identifier: MIT

/// The primitive topology described by a mesh.
public enum MeshPrimitive: String, Sendable, Hashable, Codable {
    /// Independent points.
    case points

    /// Independent line segments.
    case lines

    /// A connected line strip.
    case lineStrip

    /// Independent triangles.
    case triangles

    /// A connected triangle strip.
    case triangleStrip

    /// General polygons.
    case polygons
}
