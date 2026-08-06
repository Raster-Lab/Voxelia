// SPDX-License-Identifier: MIT

import VoxeliaGeometry
import VoxeliaSpatial

/// The closed failure family for surface vertex projection.
///
/// Cases carry no payload so diagnostics disclose no coordinates, transforms,
/// camera parameters or counts. There is deliberately no resource case: this
/// stage is an intermediate over a mesh the caller already owns, and a budget
/// belongs to the renderer that owns the whole pipeline.
enum SurfaceProjectionError: Error, Sendable, Equatable {
    /// The camera declares a projection version one does not implement.
    case unsupportedProjection

    /// A required ordered binary64 intermediate was NaN or infinite.
    case positionNotRepresentable

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled
}

/// Internal cancellation sites frozen by `ADR-0199` and `ALG-0033`.
///
/// There is no final checkpoint: this stage publishes nothing.
enum SurfaceVertexProjectionCheckpoint: Sendable, Equatable {
    case admission
    case vertex(UInt64)
}

typealias SurfaceVertexProjectionProbe =
    @Sendable (SurfaceVertexProjectionCheckpoint) -> Bool

/// One vertex projected to continuous viewport coordinates and view depth.
///
/// Coordinates are continuous with a top-left origin: pixel `(i, j)` covers
/// `[i, i+1) x [j, j+1)` and its centre is `(i + 0.5, j + 0.5)`. Nothing is
/// rounded, floored or clamped — mapping a coordinate to a covered pixel
/// belongs to the visibility contract.
struct ProjectedVertex: Sendable, Equatable {
    /// The continuous viewport column, increasing right.
    let column: Double

    /// The continuous viewport row, increasing down.
    let row: Double

    /// The view depth along the camera forward axis, increasing away from the
    /// camera. A vertex behind the camera has a negative depth and is
    /// admitted: an orthographic projection has no eye point.
    let depth: Double

    /// The vertex's world position, published so clipping can interpolate it
    /// rather than invert the projection.
    ///
    /// `ADR-0204` adds these additively: the registered `ALG-0033` fixture
    /// entries and byte payload cover only column, row and depth, so
    /// publishing the world position changes no digest. Reconstructing it by
    /// inverting the projection would introduce a second rounding path for a
    /// value this stage already computed.
    let worldX: Double
    let worldY: Double
    let worldZ: Double
}

/// The exact `surface-vertex-orthographic-projection/binary64-v1` reference.
///
/// This stateless internal projector composes the accepted admissions of
/// `Matrix4x4Double`, `SurfaceLayer`, `RenderCamera`, `ViewportSize` and
/// `TriangleMesh` rather than restating them. Because `SurfaceLayer`
/// guarantees an affine bottom row, the homogeneous `w` of every transformed
/// point is exactly one and no divide by `w` occurs anywhere.
///
/// It publishes nothing: no image, no identity and no provenance.
enum SurfaceVertexProjector {
    private struct Vector3: Sendable {
        let x: Double
        let y: Double
        let z: Double
    }

    /// The camera's right, true-up and forward unit axes.
    private struct Basis: Sendable {
        let right: Vector3
        let trueUp: Vector3
        let forward: Vector3
    }

    /// Projects every vertex of one layer's mesh.
    ///
    /// `SurfaceRenderRequest` is what guarantees the layer's world space is
    /// the camera's declared space, so callers pass a layer drawn from that
    /// request's own scene.
    static func project(
        layer: SurfaceLayer,
        camera: RenderCamera,
        viewport: ViewportSize,
        cancellation: SurfaceVertexProjectionProbe
    ) throws -> ContiguousArray<ProjectedVertex> {
        if cancellation(.admission) {
            throw SurfaceProjectionError.cancelled
        }
        // The projection check precedes the basis so a perspective camera
        // costs no arithmetic.
        guard case .orthographic(let planeHeight) = camera.projection else {
            throw SurfaceProjectionError.unsupportedProjection
        }

        let basis = try cameraBasis(camera)
        let origin = Vector3(
            x: camera.position.x,
            y: camera.position.y,
            z: camera.position.z
        )
        let worldPerPixel = try checkedDivide(
            planeHeight,
            Double(viewport.height)
        )
        let halfWidth = try checkedDivide(Double(viewport.width), 2)
        let halfHeight = try checkedDivide(Double(viewport.height), 2)

        let matrix = layer.objectToWorld.elements
        let components = layer.mesh.positions.components
        var projected = ContiguousArray<ProjectedVertex>()
        projected.reserveCapacity(layer.mesh.positions.vertexCount)

        for vertexOrdinal in 0..<layer.mesh.positions.vertexCount {
            let ordinal = UInt64(vertexOrdinal)
            if ordinal.isMultiple(of: 4_096), cancellation(.vertex(ordinal)) {
                throw SurfaceProjectionError.cancelled
            }
            let offset = vertexOrdinal * 3
            let world = try objectToWorld(
                matrix,
                x: components[offset],
                y: components[offset + 1],
                z: components[offset + 2]
            )
            let delta = Vector3(
                x: try checkedSubtract(world.x, origin.x),
                y: try checkedSubtract(world.y, origin.y),
                z: try checkedSubtract(world.z, origin.z)
            )
            let viewX = try dot(delta, basis.right)
            let viewY = try dot(delta, basis.trueUp)
            let depth = try dot(delta, basis.forward)
            projected.append(
                ProjectedVertex(
                    column: try checkedAdd(
                        halfWidth,
                        try checkedDivide(viewX, worldPerPixel)
                    ),
                    row: try checkedSubtract(
                        halfHeight,
                        try checkedDivide(viewY, worldPerPixel)
                    ),
                    depth: depth,
                    worldX: world.x,
                    worldY: world.y,
                    worldZ: world.z
                )
            )
        }
        return projected
    }

    /// Builds the frozen orthonormal basis once per request.
    ///
    /// `trueUp` is normalised even though `right` and `forward` are unit and
    /// orthogonal in exact arithmetic: in binary64 their cross product is only
    /// near unit length, and normalising states the rule instead of assuming
    /// it is close enough.
    private static func cameraBasis(_ camera: RenderCamera) throws -> Basis {
        let forwardRaw = Vector3(
            x: try checkedSubtract(camera.target.x, camera.position.x),
            y: try checkedSubtract(camera.target.y, camera.position.y),
            z: try checkedSubtract(camera.target.z, camera.position.z)
        )
        let forward = try normalise(forwardRaw)
        let up = Vector3(x: camera.up.x, y: camera.up.y, z: camera.up.z)
        let right = try normalise(try cross(forward, up))
        let trueUp = try normalise(try cross(right, forward))
        return Basis(right: right, trueUp: trueUp, forward: forward)
    }

    /// The ordered cross product shared with `VOXELIA-ALG-0030`.
    private static func cross(
        _ lhs: Vector3,
        _ rhs: Vector3
    ) throws -> Vector3 {
        Vector3(
            x: try checkedSubtract(
                try checkedMultiply(lhs.y, rhs.z),
                try checkedMultiply(lhs.z, rhs.y)
            ),
            y: try checkedSubtract(
                try checkedMultiply(lhs.z, rhs.x),
                try checkedMultiply(lhs.x, rhs.z)
            ),
            z: try checkedSubtract(
                try checkedMultiply(lhs.x, rhs.y),
                try checkedMultiply(lhs.y, rhs.x)
            )
        )
    }

    /// The maximum-component-scaled Euclidean normalisation of `ALG-0030`.
    ///
    /// There is deliberately no zero-scale branch. `RenderCamera` admits only
    /// a non-degenerate view direction and a view-up cross product at or above
    /// `Double.leastNormalMagnitude`, but normalising `forward` first can in
    /// principle shrink that cross product below the representable range, so
    /// the case is not provably unreachable. A zero scale makes the scaling
    /// division `0 / 0`, which the checked division rejects as
    /// `positionNotRepresentable` — a defined outcome reached without carrying
    /// an untestable branch.
    private static func normalise(_ vector: Vector3) throws -> Vector3 {
        let scale = max(
            max(abs(vector.x), abs(vector.y)),
            abs(vector.z)
        )
        let scaledX = try checkedDivide(vector.x, scale)
        let scaledY = try checkedDivide(vector.y, scale)
        let scaledZ = try checkedDivide(vector.z, scale)
        let squaredSum = try checkedAdd(
            try checkedAdd(
                try checkedMultiply(scaledX, scaledX),
                try checkedMultiply(scaledY, scaledY)
            ),
            try checkedMultiply(scaledZ, scaledZ)
        )
        let length = try checkedSquareRoot(squaredSum)
        return Vector3(
            x: canonicalPositiveZero(try checkedDivide(scaledX, length)),
            y: canonicalPositiveZero(try checkedDivide(scaledY, length)),
            z: canonicalPositiveZero(try checkedDivide(scaledZ, length))
        )
    }

    /// The frozen `((a0*b0 + a1*b1) + a2*b2)` grouping.
    private static func dot(_ lhs: Vector3, _ rhs: Vector3) throws -> Double {
        try checkedAdd(
            try checkedAdd(
                try checkedMultiply(lhs.x, rhs.x),
                try checkedMultiply(lhs.y, rhs.y)
            ),
            try checkedMultiply(lhs.z, rhs.z)
        )
    }

    /// Row-major affine application in the frozen `((a + b) + c) + d` order.
    ///
    /// The object-to-world and world-to-view transforms are deliberately NOT
    /// pre-multiplied into one matrix: folding them is the conventional
    /// optimisation and changes the published bits, so `ALG-0033` forbids it.
    private static func objectToWorld(
        _ matrix: ContiguousArray<Double>,
        x: Double,
        y: Double,
        z: Double
    ) throws -> Vector3 {
        func component(row: Int) throws -> Double {
            let base = row * 4
            let accumulated = try checkedAdd(
                try checkedAdd(
                    try checkedMultiply(matrix[base], x),
                    try checkedMultiply(matrix[base + 1], y)
                ),
                try checkedMultiply(matrix[base + 2], z)
            )
            return try checkedAdd(accumulated, matrix[base + 3])
        }
        return Vector3(
            x: try component(row: 0),
            y: try component(row: 1),
            z: try component(row: 2)
        )
    }

    private static func canonicalPositiveZero(_ value: Double) -> Double {
        value == 0 ? 0 : value
    }

    // Keeping each primitive out of line prevents contraction and
    // reassociation across the operation boundaries frozen by ALG-0033.
    @inline(never)
    private static func checkedSubtract(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs - rhs
        guard value.isFinite else {
            throw SurfaceProjectionError.positionNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedAdd(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs + rhs
        guard value.isFinite else {
            throw SurfaceProjectionError.positionNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedMultiply(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs * rhs
        guard value.isFinite else {
            throw SurfaceProjectionError.positionNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedDivide(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs / rhs
        guard value.isFinite else {
            throw SurfaceProjectionError.positionNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedSquareRoot(_ value: Double) throws -> Double {
        let result = value.squareRoot()
        guard result.isFinite else {
            throw SurfaceProjectionError.positionNotRepresentable
        }
        return result
    }
}
