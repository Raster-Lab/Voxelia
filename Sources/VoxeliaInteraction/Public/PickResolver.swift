// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaRendering
import VoxeliaSpatial

/// One resolved pick per `ADR-0125` (`VOX-INT-006`).
///
/// The resolution carries every claimed layer in order — a composited
/// pixel blends all of them — with the shared resolved source index
/// in the presented image's index space; physical position arrives
/// with geometry-bearing presentation through its own decisions.
public struct PickResolution: Sendable, Hashable {
    public let layers: ContiguousArray<RenderLayer>
    public let sourceX: Int
    public let sourceY: Int
    /// The exact physical position per `ADR-0129` when the claim
    /// carries an affine; an uncalibrated presentation returns none
    /// rather than a fabricated position.
    public let worldPosition: Point3D?

    init(
        layers: ContiguousArray<RenderLayer>,
        sourceX: Int,
        sourceY: Int,
        worldPosition: Point3D?
    ) {
        self.layers = layers
        self.sourceX = sourceX
        self.sourceY = sourceY
        self.worldPosition = worldPosition
    }
}

/// The pure index-space pick resolver per `ADR-0125`.
///
/// The presentation claims are the map: the resolver inverts the
/// scaling claim — the exact `VOXELIA-ALG-0008` inverse for
/// nearest-neighbour, the frozen dominant-tap rule for bilinear — and
/// applies the claimed crop offset, because cropping ran before
/// scaling.
public enum PickResolver {
    /// Resolves one pick target through one presentation claim.
    ///
    /// - Throws: ``InteractionError/pickOutsideViewport``.
    public static func resolve(
        _ target: PickTarget,
        in presentation: PresentationProvenance
    ) throws -> PickResolution {
        guard
            target.viewportX < presentation.viewport.width,
            target.viewportY < presentation.viewport.height
        else {
            throw InteractionError.pickOutsideViewport
        }

        let presentedX: Int
        let presentedY: Int
        switch presentation.scaling {
        case .identity:
            presentedX = target.viewportX
            presentedY = target.viewportY
        case .nearestNeighbour(let sourceWidth, let sourceHeight):
            presentedX = Self.nearestSourceIndex(
                target.viewportX,
                inputCount: sourceWidth,
                outputCount: presentation.viewport.width
            )
            presentedY = Self.nearestSourceIndex(
                target.viewportY,
                inputCount: sourceHeight,
                outputCount: presentation.viewport.height
            )
        case .bilinear(let sourceWidth, let sourceHeight):
            presentedX = Self.dominantTapIndex(
                target.viewportX,
                inputCount: sourceWidth,
                outputCount: presentation.viewport.width
            )
            presentedY = Self.dominantTapIndex(
                target.viewportY,
                inputCount: sourceHeight,
                outputCount: presentation.viewport.height
            )
        }

        // A claimed crop ran before scaling, so its lower bounds
        // offset the presented index into the stored image.
        let sourceX = presentedX + (presentation.crop?.lowerX ?? 0)
        let sourceY = presentedY + (presentation.crop?.lowerY ?? 0)

        // The ADR-0129 physical position: the claimed geometry is the
        // final object's, so its indices are viewport indices — the
        // frozen translation-plus-ascending-products evaluation maps
        // the target directly, and an uncalibrated claim maps to none.
        var worldPosition: Point3D?
        if case .affine(let affine)? = presentation.geometry {
            let elements = affine.indexToWorld.elements
            let indices = [Double(target.viewportX), Double(target.viewportY)]
            // A viewport supplies exactly two indices, and `SpatialAxisMapping` admits up
            // to three axes, so a claim naming a third has no index to read. This refuses
            // that rather than reading out of range, which is what it did before
            // `ADR-0292`.
            guard affine.spatialAxes.imageAxes.allSatisfy({ $0 < indices.count })
            else {
                throw InteractionError.presentationGeometryNotPlanar
            }
            var world = [0.0, 0.0, 0.0]
            for row in 0..<3 {
                var component = elements[4 * row + 3]
                for (slot, imageAxis) in affine.spatialAxes.imageAxes.enumerated() {
                    component = component + (elements[4 * row + slot] * indices[imageAxis])
                }
                world[row] = component
            }
            worldPosition = try Point3D(
                x: world[0],
                y: world[1],
                z: world[2],
                coordinateSpace: affine.coordinateSpace.id
            )
        }
        return PickResolution(
            layers: presentation.layers,
            sourceX: sourceX,
            sourceY: sourceY,
            worldPosition: worldPosition
        )
    }

    /// Maps one world point back to the viewport pixel whose claimed
    /// final-object geometry contains it, per `ADR-0139`.
    ///
    /// The claimed geometry is the final object's, so its indices are
    /// viewport indices — the frozen `ADR-0138` composition recovers
    /// the slot values and the geometry's own axis mapping assigns
    /// them to the two presented axes. Out-of-plane slot components
    /// do not gate admission because they do not select the pixel —
    /// each viewport presents its own plane's projection of a shared
    /// crosshair. Rounding is ties-to-even per the accepted
    /// `ADR-0130` rule with a double-domain range check, and a pixel
    /// that left the view rejects typed — a nearest pixel would
    /// misreport where the crosshair is.
    ///
    /// - Throws: ``InteractionError`` and the world-to-index map's
    ///   typed errors.
    public static func viewportTarget(
        for point: Point3D,
        in presentation: PresentationProvenance
    ) throws -> PickTarget {
        guard case .affine(let affine)? = presentation.geometry else {
            throw InteractionError.presentationNotCalibrated
        }
        let map = try AffineWorldToIndexMap(geometry: affine)
        let slots = try map.continuousSlotIndices(of: point)
        var continuousX: Double?
        var continuousY: Double?
        for (slot, imageAxis) in map.spatialAxes.imageAxes.enumerated() {
            if imageAxis == 0 {
                continuousX = slots[slot]
            }
            if imageAxis == 1 {
                continuousY = slots[slot]
            }
        }
        guard let continuousX, let continuousY else {
            throw InteractionError.viewportAxisNotMapped
        }
        let roundedX = continuousX.rounded(.toNearestOrEven)
        let roundedY = continuousY.rounded(.toNearestOrEven)
        guard
            roundedX >= 0,
            roundedX < Double(presentation.viewport.width),
            roundedY >= 0,
            roundedY < Double(presentation.viewport.height)
        else {
            throw InteractionError.crosshairOutsideViewport
        }
        return try PickTarget(
            viewportX: Int(roundedX),
            viewportY: Int(roundedY)
        )
    }

    /// The exact inverse of the registered `VOXELIA-ALG-0008` forward
    /// map: the source sample the displayed pixel came from.
    static func nearestSourceIndex(
        _ position: Int,
        inputCount: Int,
        outputCount: Int
    ) -> Int {
        let scale = Double(inputCount) / Double(outputCount)
        let centre = (Double(position) + 0.5) * scale
        return min(inputCount - 1, max(0, Int(centre.rounded(.down))))
    }

    /// The frozen `ADR-0125` dominant-tap rule for bilinear claims:
    /// the source centre nearest the pixel-centre-aligned coordinate.
    static func dominantTapIndex(
        _ position: Int,
        inputCount: Int,
        outputCount: Int
    ) -> Int {
        let scale = Double(inputCount) / Double(outputCount)
        let source = ((Double(position) + 0.5) * scale) - 0.5
        let nearest = floor(source + 0.5)
        return min(inputCount - 1, max(0, Int(nearest)))
    }
}
