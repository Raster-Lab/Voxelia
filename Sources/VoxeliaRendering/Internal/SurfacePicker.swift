// SPDX-License-Identifier: MIT

/// The closed failure family for authoritative surface picking.
///
/// There is deliberately no representability failure: every value a pick
/// returns was already computed and admitted by an earlier accepted stage. There
/// is no cancellation case either, because a pick is a bounded lookup over one
/// pixel's candidates rather than a traversal.
enum SurfacePickError: Error, Sendable, Equatable {
    /// The requested pixel lies outside the viewport.
    ///
    /// "Nothing is there" and "you asked wrongly" are different answers, and
    /// conflating them would let a caller silently mis-index a viewport
    /// forever.
    case pixelOutOfBounds
}

/// One covering fragment at the requested pixel, already judged by the clip
/// predicate.
///
/// The vertex indices are the facet's three indices in the mesh's **original**
/// topology order. The coverage rule's canonicalisation swap is a coverage
/// detail and never reaches an identifier.
struct SurfacePickCandidate: Sendable, Equatable {
    let depth: Double
    let layerIndex: Int
    let facetOrdinal: Int
    let worldX: Double
    let worldY: Double
    let worldZ: Double

    /// Whether the clip predicate retained this fragment.
    let retained: Bool

    let firstVertexIndex: Int
    let secondVertexIndex: Int
    let thirdVertexIndex: Int
}

/// The authoritative geometry the user picked and its physical position.
///
/// The position is physical by construction: `SurfaceLayer` carries a full
/// `CoordinateSpaceDescriptor`, and that type admits only a
/// `UnitDimension.length` unit, so a surface scene always has a length-bearing
/// world space. The `PickResolver` honesty rule — never fabricate a position —
/// is therefore honoured structurally, and this model deliberately carries no
/// optional-position case, because it could never fire.
struct SurfacePick: Sendable, Equatable {
    let layerIndex: Int
    let facetOrdinal: Int
    let firstVertexIndex: Int
    let secondVertexIndex: Int
    let thirdVertexIndex: Int
    let worldX: Double
    let worldY: Double
    let worldZ: Double
}

/// The exact `surface-picking/binary64-v1` reference.
///
/// Picking **composes** the accepted coverage rules; it does not re-intersect.
/// `ALG-0034` already decides exactly which facet covers a pixel and where, and
/// `ALG-0033` already published each vertex's world position. An independent ray
/// cast would introduce a second geometric predicate that could disagree with
/// the one that drew the image, and a pick that disagrees with what the user is
/// looking at is worse than no pick at all.
enum SurfacePicker {
    /// Picks the authoritative geometry at one viewport pixel.
    ///
    /// Clipping is applied **before** the nearest-surface decision, and that
    /// ordering is this model's central obligation: a clipped-away fragment must
    /// not occlude what is behind it. If the nearest fragment were chosen first
    /// and then tested against the clip, a clipped surface would swallow the
    /// pick while the renderer, which discards clipped fragments during
    /// coverage, would be drawing the surface behind it.
    ///
    /// - Returns: The picked geometry, or `nil` when nothing was picked —
    ///   either because nothing covered the pixel or because everything
    ///   covering it was clipped away. Both are the same outcome by the same
    ///   rule rather than two special cases.
    /// - Throws: ``SurfacePickError/pixelOutOfBounds``.
    static func pick(
        candidates: [SurfacePickCandidate],
        column: Int,
        row: Int,
        viewport: ViewportSize
    ) throws -> SurfacePick? {
        // The bound is inclusive at zero and exclusive at the dimension.
        guard
            column >= 0, column < viewport.width,
            row >= 0, row < viewport.height
        else {
            throw SurfacePickError.pixelOutOfBounds
        }

        // Step 2 precedes step 4: discard first, then order.
        let surviving = candidates.filter(\.retained)
        guard !surviving.isEmpty else {
            return nil
        }
        // The same strict total order the visibility and compositing records
        // use. It is inherited, not restated, so a pick can never disagree with
        // what the renderer drew. A negative depth is pickable: there is no near
        // plane, so a visible fragment behind the camera is still authoritative
        // geometry.
        let nearest = surviving.sorted { lhs, rhs in
            if lhs.depth != rhs.depth {
                return lhs.depth < rhs.depth
            }
            if lhs.layerIndex != rhs.layerIndex {
                return lhs.layerIndex < rhs.layerIndex
            }
            return lhs.facetOrdinal < rhs.facetOrdinal
        }[0]

        return SurfacePick(
            layerIndex: nearest.layerIndex,
            facetOrdinal: nearest.facetOrdinal,
            firstVertexIndex: nearest.firstVertexIndex,
            secondVertexIndex: nearest.secondVertexIndex,
            thirdVertexIndex: nearest.thirdVertexIndex,
            worldX: nearest.worldX,
            worldY: nearest.worldY,
            worldZ: nearest.worldZ
        )
    }
}
