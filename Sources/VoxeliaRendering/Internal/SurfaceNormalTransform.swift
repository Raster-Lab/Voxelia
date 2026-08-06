// SPDX-License-Identifier: MIT

import VoxeliaGeometry
import VoxeliaSpatial

/// Supplies a facet's vertex normals in **world space**, per `ADR-0285` (`VOX-SUR-004`).
///
/// ## The defect this corrects
///
/// `VOXELIA-ALG-0033` transforms vertex **positions** through `SurfaceLayer.objectToWorld`,
/// and `VOXELIA-ALG-0036` dots vertex **normals** against the camera's forward axis — which
/// is built from world-space camera vectors. The normals were read straight from the mesh,
/// so they were in **object** space, and nothing transformed them between.
///
/// `ADR-0280` quantified the result at `1.000000` where `0.000000` is correct, under a pure
/// rotation: the maximum possible error for a value bounded in `[0, 1]`. A facet squarely
/// facing the camera would shade as fully unlit.
///
/// **Neither specification was wrong.** `ALG-0036`'s input domain names three unit vertex
/// normals and the camera's forward unit axis and gives **neither a space**; its arithmetic
/// is correct for same-space inputs. The defect was in what reached it, so the correction
/// lives here and `ADR-0202` and `ALG-0036` are unedited.
///
/// ## Why each normal is normalised before it is returned
///
/// A transformed normal is no longer unit, and `ALG-0036` states its inputs are unit "by
/// construction" and does not re-admit them. Restoring that is not cosmetic: `ADR-0285`
/// measured interpolating the raw transformed normals against normalising each first at
/// **22.37 degrees apart**, with shading intensities differing by `0.29873328108119157` —
/// nearly thirty per cent of the full range.
///
/// The normalisation is `VOXELIA-ALG-0030`'s, composed rather than restated.
enum SurfaceNormalTransform {
    /// Reads a facet's three vertex normals and returns them in world space, unit length.
    ///
    /// The inverse is computed **once** and applied three times, rather than recomputed per
    /// direction: a renderer shades many facets under one `objectToWorld`, and
    /// `VOXELIA-ALG-0016`'s adjugate is not cheap enough to repeat needlessly.
    ///
    /// - Throws: ``SurfaceShadingError/normalsMissing`` when the mesh carries no normal
    ///   attribute, or ``AffineSpatialInverseError/singularMatrix`` when the transform's
    ///   spatial block is not invertible. No case is added: both are inherited from the
    ///   operations this composes.
    static func worldNormals(
        of mesh: TriangleMesh,
        facetOrdinal: Int,
        objectToWorld: Matrix4x4Double
    ) throws -> (ShadingDirection, ShadingDirection, ShadingDirection) {
        guard AffineTransformAlgebra.isAffine(objectToWorld) else {
            throw AffineTransformError.nonAffineOperand
        }
        let object = try SurfaceShader.normals(of: mesh, facetOrdinal: facetOrdinal)
        let inverse = try AffineSpatialInverse(spatialPartOf: objectToWorld)
        return (
            worldNormal(object.0, inverse),
            worldNormal(object.1, inverse),
            worldNormal(object.2, inverse)
        )
    }

    private static func worldNormal(
        _ direction: ShadingDirection,
        _ inverse: AffineSpatialInverse
    ) -> ShadingDirection {
        let transformed = AffineTransformAlgebra.transformNormal(
            usingInverseOf: inverse,
            x: direction.x,
            y: direction.y,
            z: direction.z
        )
        return normalised(x: transformed[0], y: transformed[1], z: transformed[2])
    }

    /// `VOXELIA-ALG-0030`'s scaled normalisation, in its frozen order.
    ///
    /// A zero scale yields the zero direction rather than failing. `ALG-0030` fails the
    /// whole operation for an undefined *published* vertex normal, but `ADR-0202` chose the
    /// opposite for presentation — "shading is presentation, not measurement, so this
    /// yields positive zero rather than failing an entire render" — and this is
    /// presentation. `ALG-0036` already returns intensity zero for an interpolated zero
    /// direction, so the case is handled downstream rather than needing a branch here.
    private static func normalised(x: Double, y: Double, z: Double) -> ShadingDirection {
        let scale = max(max(abs(x), abs(y)), abs(z))
        guard scale != 0 else {
            return ShadingDirection(x: 0, y: 0, z: 0)
        }
        let sx = x / scale
        let sy = y / scale
        let sz = z / scale
        let sum = (sx * sx + sy * sy) + sz * sz
        let length = sum.squareRoot()
        return ShadingDirection(x: sx / length, y: sy / length, z: sz / length)
    }
}
