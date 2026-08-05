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
        let x = min(extents[0] - 1, max(0, Int(continuous[0].rounded())))
        let y = min(extents[1] - 1, max(0, Int(continuous[1].rounded())))
        let z = min(extents[2] - 1, max(0, Int(continuous[2].rounded())))
        return bytes[x + width * (y + height * z)]
    }
}
