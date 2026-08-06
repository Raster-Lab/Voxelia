// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// The closed failure family for surface clipping.
///
/// There is no representability failure: a covered sample's weights are
/// non-negative and sum to the projected area, so the interpolated position is
/// a convex combination of three finite world positions and is bounded by
/// them, and the comparisons cannot overflow.
enum SurfaceClipError: Error, Sendable, Equatable {
    /// The clip region is not declared in the scene's world space.
    case coordinateSpaceMismatch

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled
}

/// One fragment's interpolated world position and its retention decision.
struct ClipDecision: Sendable, Equatable {
    let worldX: Double
    let worldY: Double
    let worldZ: Double
    let retained: Bool
}

/// The exact `surface-world-box-clipping/binary64-v1` reference.
///
/// Clipping is a **predicate**, not a cut: no geometry is cut, no vertex is
/// created and no topology is changed. Section views are consequently
/// uncapped, and the cut is legible because the diagnostic material is
/// two-sided — a property `ADR-0202` established for open extracted surfaces,
/// which this record composes rather than duplicates.
enum SurfaceClipper {
    /// Interpolates one fragment's world position and applies the clip box.
    ///
    /// An absent clip retains every fragment, so the unclipped path is the
    /// same code with no branch to diverge.
    static func decide(
        first: ProjectedVertex,
        second: ProjectedVertex,
        third: ProjectedVertex,
        weightA: Double,
        weightB: Double,
        weightC: Double,
        swapped: Bool,
        bounds: VolumeClipBounds?
    ) -> ClipDecision {
        // The weights arrive in the coverage rule's canonicalised order, so
        // the swap flag maps them back exactly as it does for shading and
        // colour. A consumer ignoring it would clip the wrong fragments on
        // every mirrored facet.
        let originalB = swapped ? weightC : weightB
        let originalC = swapped ? weightB : weightC

        let worldX = interpolate(
            weightA, first.worldX, originalB, second.worldX, originalC,
            third.worldX)
        let worldY = interpolate(
            weightA, first.worldY, originalB, second.worldY, originalC,
            third.worldY)
        let worldZ = interpolate(
            weightA, first.worldZ, originalB, second.worldZ, originalC,
            third.worldZ)

        return ClipDecision(
            worldX: worldX,
            worldY: worldY,
            worldZ: worldZ,
            retained: retained(
                worldX: worldX,
                worldY: worldY,
                worldZ: worldZ,
                bounds: bounds
            )
        )
    }

    /// The frozen inclusive axis-aligned world-box test.
    ///
    /// The boundary belongs to the box: it is a closed region, and
    /// `VolumeClipBounds` uses strict inequalities only to reject a degenerate
    /// box, not to describe an open one.
    static func retained(
        worldX: Double,
        worldY: Double,
        worldZ: Double,
        bounds: VolumeClipBounds?
    ) -> Bool {
        guard let bounds else {
            return true
        }
        return worldX >= bounds.minimum.x && worldX <= bounds.maximum.x
            && worldY >= bounds.minimum.y && worldY <= bounds.maximum.y
            && worldZ >= bounds.minimum.z && worldZ <= bounds.maximum.z
    }

    /// Checks the one admission the surface path adds to `ADR-0179`'s.
    ///
    /// `VolumeClipBounds` already admits a finite non-degenerate box whose two
    /// corners share a coordinate space; the surface path additionally
    /// requires that space to be the scene's world space.
    static func admit(
        bounds: VolumeClipBounds?,
        worldSpace: CoordinateSpaceID?
    ) throws {
        guard let bounds, let worldSpace else {
            return
        }
        guard bounds.minimum.coordinateSpace == worldSpace else {
            throw SurfaceClipError.coordinateSpaceMismatch
        }
    }

    /// The frozen `((a * b + c * d) + e * f)` interpolation grouping, shared
    /// with shading and colour mapping.
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
