// SPDX-License-Identifier: MIT

/// One annotation's anchor, already projected by ``SurfaceVertexProjector``.
///
/// Version one models an annotation as an anchor and nothing else — a world
/// position under a pose. There is deliberately no text, glyph, style, size or
/// identifier: those are presentation concerns with no consumer yet, and a
/// vocabulary invented without one becomes canonical by default.
struct AnnotationAnchor: Sendable, Equatable {
    /// The continuous viewport column, increasing right.
    let column: Double

    /// The continuous viewport row, increasing down.
    let row: Double

    /// The view depth along the camera forward axis, increasing away from the
    /// camera. A negative depth is admitted: an orthographic projection has no
    /// eye point.
    let depth: Double
}

/// Where one annotation landed under one camera pose, and whether geometry
/// hides it.
struct AnnotationRegistration: Sendable, Equatable {
    let column: Int
    let row: Int
    let depth: Double

    /// Whether retained geometry strictly nearer than the anchor hides it.
    let occluded: Bool
}

/// The exact `annotation-registration/binary64-v1` reference.
///
/// **Registration is achieved by statelessness, and that is the whole claim.**
/// The outcome is a pure function of the anchor, the pose and the occluder
/// depths, with nothing carried between poses. Smoothing, hysteresis or a
/// cached previous pixel would make the answer depend on the path the camera
/// travelled rather than on where it now is, which is exactly the drift
/// `VOX-SUR-008` forbids.
///
/// The anchor arrives already projected, so this stage adds no second transform
/// that could disagree with the one that drew the image — the same composition
/// rule ``SurfacePicker`` follows.
///
/// This stage has no failure family: see ``register(anchor:viewport:occluder:)``
/// for why the model is total.
enum SurfaceAnnotationRegistrar {
    /// Registers one annotation under one camera pose.
    ///
    /// The viewport bound is tested on the **continuous** coordinate, before
    /// any integer conversion, and that ordering is what makes the model total:
    /// a coordinate that survives the test is inside the viewport, so its floor
    /// is representable. Testing after conversion would first have to convert
    /// an arbitrary finite double to an integer, which is the operation that
    /// traps. There is consequently no representability failure, no
    /// unsupported-projection case — `ALG-0033` already rejected one — and no
    /// cancellation checkpoint, because registering one annotation is `O(1)`
    /// rather than a traversal.
    ///
    /// - Parameter occluder: The nearest **retained** depth at the anchor's own
    ///   pixel, or `nil` when nothing retained covers it. Retained means the
    ///   clip predicate already ran, so a clipped-away surface cannot hide an
    ///   annotation any more than it may swallow a pick.
    /// - Returns: The registration, or `nil` when the anchor is off-viewport.
    ///   Off-viewport is reported rather than thrown, because ordinary panning
    ///   moves anchors off screen constantly, and it is never clamped to the
    ///   rim, because a marker drawn at the edge claims a physical place the
    ///   anchor does not occupy.
    static func register(
        anchor: AnnotationAnchor,
        viewport: ViewportSize,
        occluder: Double?
    ) -> AnnotationRegistration? {
        // The bound is inclusive at zero and exclusive at the dimension, on
        // both axes. Negative zero needs no special case: it compares equal to
        // zero and floors to zero.
        guard
            let placed = pixel(
                column: anchor.column,
                row: anchor.row,
                viewport: viewport
            )
        else {
            return nil
        }

        return AnnotationRegistration(
            column: placed.column,
            row: placed.row,
            depth: anchor.depth,
            // Occlusion is STRICT: only geometry strictly nearer than the
            // anchor hides it, so an exactly equal depth leaves it visible.
            // This is the same strict-less comparison the visibility record
            // uses for its own tie-break, and an anchor placed on the surface
            // it annotates must not be hidden by that surface. There is no
            // depth bias and no epsilon: a bias is a magic number no accepted
            // record supplies, and its effect would change with the scene's
            // scale.
            occluded: occluder.map { $0 < anchor.depth } ?? false
        )
    }

    /// The pixel one continuous coordinate pair falls in, or `nil` when it is
    /// off-viewport.
    ///
    /// The **same** pixel rule serves the placement and the caller's occlusion
    /// lookup, so the two cannot disagree about which pixel is being asked
    /// about. A caller holding a clipped nearest-depth buffer uses this to
    /// select the depth it then supplies to
    /// ``register(anchor:viewport:occluder:)``.
    ///
    /// There is deliberately no overload taking a ``SurfaceVisibilityBuffer``
    /// directly. That buffer is resolved without a clip, so consuming it here
    /// would silently let a clipped-away surface hide an annotation — the exact
    /// ordering `ADR-0205` decision 3 forbids. The caller composes the clip, as
    /// it does for picking.
    static func pixel(
        column: Double,
        row: Double,
        viewport: ViewportSize
    ) -> (column: Int, row: Int)? {
        guard
            column >= 0, column < Double(viewport.width),
            row >= 0, row < Double(viewport.height)
        else {
            return nil
        }
        return (pixel(column), pixel(row))
    }

    /// The frozen pixel rule: the floor of the continuous coordinate.
    ///
    /// `ALG-0033` publishes continuous top-left coordinates and `ALG-0034`
    /// samples at pixel centres, so pixel `k` covers `[k, k+1)`. Rounding would
    /// move every anchor past the half-pixel into its neighbour, and would put
    /// an anchor at a pixel centre exactly on the rounding boundary.
    private static func pixel(_ coordinate: Double) -> Int {
        Int(coordinate.rounded(.down))
    }
}
