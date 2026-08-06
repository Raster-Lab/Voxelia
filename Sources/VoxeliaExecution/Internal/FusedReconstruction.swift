// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// The closed failure family for fused reconstruction.
///
/// The three cases are distinct on purpose: a caller that mismatched coordinate
/// spaces has a different problem from one that mismatched extents, and
/// collapsing them would hide which.
///
/// Cases carry no payload so diagnostics disclose no geometry, extents or
/// samples.
enum FusedReconstructionError: Error, Sendable, Equatable {
    /// The two reconstructions declare different coordinate spaces.
    case coordinateSpaceMismatch

    /// The two reconstructions declare different index-to-world grids.
    case gridMismatch

    /// The two reconstructions have different sample counts.
    case extentMismatch
}

/// The fused reconstruction reference for `VOX-MPR-011`.
///
/// **Registration is structural, not computed.** `ObliqueSliceOperation` takes
/// an output grid and rejects a coordinate-space mismatch typed, so
/// reconstructing the *same* grid from two volumes yields co-registered images
/// by construction: every output sample of both images is the same physical
/// position. What was missing — and what this type adds — is the check that two
/// *reconstructions* really do share that grid, which nothing performed.
///
/// The admission is **exact value equality, never a tolerance**. Two grids that
/// differ by any amount are not the same plane, and deciding how much
/// difference is acceptable is a clinical judgement no accepted record
/// supplies.
///
/// This type computes no registration. "Spatially registered" means the inputs
/// already share a coordinate space; rigid or deformable registration is a
/// different problem with its own arc.
enum FusedReconstruction {
    /// Admits two reconstructions as registered.
    ///
    /// - Throws: ``FusedReconstructionError``.
    static func admit(
        base: AffineGridGeometry,
        overlay: AffineGridGeometry,
        baseSampleCount: Int,
        overlaySampleCount: Int
    ) throws {
        guard base.coordinateSpace.id == overlay.coordinateSpace.id else {
            throw FusedReconstructionError.coordinateSpaceMismatch
        }
        guard
            base.indexToWorld == overlay.indexToWorld,
            base.spatialAxes == overlay.spatialAxes
        else {
            throw FusedReconstructionError.gridMismatch
        }
        guard baseSampleCount == overlaySampleCount else {
            throw FusedReconstructionError.extentMismatch
        }
    }

    /// Fuses one greyscale base reconstruction with one colour-mapped overlay.
    ///
    /// The arithmetic is entirely ``OverlayCompositing``'s, reused rather than
    /// reimplemented, so a fused image and a composited overlay cannot disagree.
    /// The overlay's colour comes from the accepted palette mapping and its
    /// alpha from the supplied opacity.
    ///
    /// - Throws: ``FusedReconstructionError``, ``PaletteColourError`` or
    ///   ``OverlayCompositingError``.
    static func fuse(
        baseSamples: [UInt8],
        overlaySamples: [UInt8],
        baseGrid: AffineGridGeometry,
        overlayGrid: AffineGridGeometry,
        red: LookupTableDescriptor,
        green: LookupTableDescriptor,
        blue: LookupTableDescriptor,
        opacity: Double
    ) throws -> [DisplayPixelRGBA8] {
        try admit(
            base: baseGrid,
            overlay: overlayGrid,
            baseSampleCount: baseSamples.count,
            overlaySampleCount: overlaySamples.count
        )

        var fused = [DisplayPixelRGBA8]()
        fused.reserveCapacity(baseSamples.count)
        for index in baseSamples.indices {
            // The base is greyscale and opaque: one stored value replicated
            // across three channels, which is what an eight-bit greyscale
            // presentation already means.
            let grey = baseSamples[index]
            let colour = try PaletteColour.map(
                stored: Int64(overlaySamples[index]),
                red: red,
                green: green,
                blue: blue
            )
            fused.append(
                try OverlayCompositing.composite(
                    base: DisplayPixelRGBA8(
                        red: grey,
                        green: grey,
                        blue: grey,
                        alpha: 255
                    ),
                    overlays: [
                        Overlay(
                            source: .image(
                                OverlayEntry(
                                    red: colour.red,
                                    green: colour.green,
                                    blue: colour.blue,
                                    alpha: colour.alpha
                                )
                            ),
                            opacity: opacity
                        )
                    ]
                )
            )
        }
        return fused
    }
}
