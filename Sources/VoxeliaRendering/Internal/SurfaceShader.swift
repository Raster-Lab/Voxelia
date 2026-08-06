// SPDX-License-Identifier: MIT

import VoxeliaGeometry

/// The closed failure family for surface diagnostic shading.
///
/// There is no representability failure: every input is a unit normal or a
/// barycentric weight, every intermediate is bounded, and the clamped output
/// lies in `[0, 1]`.
enum SurfaceShadingError: Error, Sendable, Equatable {
    /// The source mesh carries no built-in normal attribute.
    case normalsMissing

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled
}

/// One unit direction used by shading.
struct ShadingDirection: Sendable, Equatable {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// The exact `surface-diagnostic-shading/binary64-v1` reference.
///
/// This stateless internal shader interpolates a fragment's vertex normals and
/// produces one intensity in `[0, 1]`. It produces no colour: a colour
/// representation is the scalar-colour-map contract's to settle, and it must
/// settle one regardless.
enum SurfaceShader {
    /// Shades one fragment with a two-sided Lambert headlight.
    ///
    /// The three normals are supplied in the mesh's **original** vertex order.
    /// The weights arrive in the coverage rule's canonicalised order, so
    /// `swapped` is what maps them back — a consumer that ignored it would
    /// attribute the second vertex's normal to the third on every mirrored
    /// facet.
    ///
    /// This method does not throw: `ADR-0202` decision 10 proved there is no
    /// reachable representability failure, so the signature says so rather
    /// than carrying an error a caller could never observe.
    static func intensity(
        first: ShadingDirection,
        second: ShadingDirection,
        third: ShadingDirection,
        weightA: Double,
        weightB: Double,
        weightC: Double,
        swapped: Bool,
        forward: ShadingDirection
    ) -> Double {
        // Map the canonicalised weights back to original vertex order.
        let originalB = swapped ? weightC : weightB
        let originalC = swapped ? weightB : weightC

        let x = interpolate(
            weightA, first.x, originalB, second.x, originalC, third.x)
        let y = interpolate(
            weightA, first.y, originalB, second.y, originalC, third.y)
        let z = interpolate(
            weightA, first.z, originalB, second.z, originalC, third.z)

        let scale = max(max(abs(x), abs(y)), abs(z))
        guard scale != 0 else {
            // The interpolated direction is genuinely undefined. Shading is
            // presentation, not measurement, so this yields positive zero
            // rather than failing an entire render. `ADR-0193` rejects an
            // undefined PUBLISHED normal; the contrast is deliberate.
            return 0
        }

        let scaledX = x / scale
        let scaledY = y / scale
        let scaledZ = z / scale
        let squaredSum =
            (scaledX * scaledX + scaledY * scaledY) + scaledZ * scaledZ
        let length = squaredSum.squareRoot()
        let unitX = scaledX / length
        let unitY = scaledY / length
        let unitZ = scaledZ / length

        let projection =
            (unitX * forward.x + unitY * forward.y) + unitZ * forward.z
        // The absolute value is what makes the material two-sided, and that is
        // required: extraction publishes open surfaces and the coverage rule
        // deliberately does not cull back faces, so a one-sided rule would
        // render every open interior black.
        let magnitude = abs(projection)
        // An exact clamp, not an epsilon. Rounding in the renormalisation and
        // the dot product can carry the magnitude just above one.
        return magnitude < 1 ? magnitude : 1
    }

    /// Reads the three normals of one facet from a mesh's normal attribute.
    ///
    /// - Throws: ``SurfaceShadingError/normalsMissing`` when the mesh carries
    ///   no built-in normal attribute. There is deliberately no fallback to a
    ///   facet normal: it would shade two meshes differing only in whether
    ///   they carry normals differently, and `ADR-0193` already provides an
    ///   accepted operation to generate them.
    static func normals(
        of mesh: TriangleMesh,
        facetOrdinal: Int
    ) throws -> (ShadingDirection, ShadingDirection, ShadingDirection) {
        guard
            let attribute = mesh.vertexAttributes.first(where: {
                $0.descriptor.semantic == .normal
            })
        else {
            throw SurfaceShadingError.normalsMissing
        }
        let indices = mesh.topology.indices
        let offset = facetOrdinal * 3
        return (
            direction(attribute, vertex: Int(indices[offset])),
            direction(attribute, vertex: Int(indices[offset + 1])),
            direction(attribute, vertex: Int(indices[offset + 2]))
        )
    }

    private static func direction(
        _ attribute: TriangleMeshVertexAttribute,
        vertex: Int
    ) -> ShadingDirection {
        let base = vertex * 24
        return ShadingDirection(
            x: component(attribute.bytes, at: base),
            y: component(attribute.bytes, at: base + 8),
            z: component(attribute.bytes, at: base + 16)
        )
    }

    /// Decodes one explicit little-endian binary64 component, matching the
    /// serialisation `ADR-0193` froze for the normal attribute.
    private static func component(
        _ bytes: ContiguousArray<UInt8>,
        at offset: Int
    ) -> Double {
        var pattern: UInt64 = 0
        for byteIndex in 0..<8 {
            pattern |=
                UInt64(bytes[offset + byteIndex]) << UInt64(byteIndex * 8)
        }
        return Double(bitPattern: pattern)
    }

    /// The frozen `((a * b + c * d) + e * f)` interpolation grouping.
    private static func interpolate(
        _ weightA: Double,
        _ a: Double,
        _ weightB: Double,
        _ b: Double,
        _ weightC: Double,
        _ c: Double
    ) -> Double {
        (weightA * a + weightB * b) + weightC * c
    }
}
