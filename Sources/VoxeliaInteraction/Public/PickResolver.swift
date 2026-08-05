// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaRendering

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

    init(layers: ContiguousArray<RenderLayer>, sourceX: Int, sourceY: Int) {
        self.layers = layers
        self.sourceX = sourceX
        self.sourceY = sourceY
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
        return PickResolution(
            layers: presentation.layers,
            sourceX: sourceX,
            sourceY: sourceY
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
