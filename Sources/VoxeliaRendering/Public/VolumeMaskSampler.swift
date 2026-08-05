// SPDX-License-Identifier: MIT

/// The nearest-neighbour segmentation-label sampler per `ADR-0180`,
/// realising the frozen `VOXELIA-ALG-0026` model.
///
/// Restated rather than composed with the trilinear oblique-slice
/// sampling authority or the nearest-neighbour resampling operation's
/// shifted-floor rule: interpolating label identifiers is
/// meaningless — averaging label one and label two produces neither —
/// and the resampling operation's rule assumes a continuous
/// output-pixel-space grid, a different convention from the
/// centres-at-integers index space every volume sample already uses.
public enum VolumeMaskSampler {
    /// The nearest voxel index for one axis: round half-away-from-
    /// zero, clamped to `[0, extent - 1]` — the shared authority
    /// `ADR-0182`'s brick lookup composes rather than restates.
    public static func nearestVoxelIndex(_ continuous: Double, extent: Int) -> Int {
        min(extent - 1, max(0, Int(continuous.rounded())))
    }

    /// Samples one label at a continuous index-space position.
    ///
    /// Each axis rounds half-away-from-zero to the nearest voxel
    /// index, clamped to the volume's extent; a position outside any
    /// axis's `[-0.5, extent - 0.5]` support returns label zero,
    /// mirroring the trilinear sampler's out-of-support sentinel and
    /// flat-indexing form.
    public static func sample(
        _ continuous: [Double],
        extents: ContiguousArray<Int>,
        bytes: [UInt8]
    ) -> UInt8 {
        for axis in 0...2 {
            let upper = Double(extents[axis]) - 0.5
            guard continuous[axis] >= -0.5, continuous[axis] <= upper else {
                return 0
            }
        }
        let width = extents[0]
        let height = extents[1]
        let x = Self.nearestVoxelIndex(continuous[0], extent: extents[0])
        let y = Self.nearestVoxelIndex(continuous[1], extent: extents[1])
        let z = Self.nearestVoxelIndex(continuous[2], extent: extents[2])
        return bytes[x + width * (y + height * z)]
    }
}
