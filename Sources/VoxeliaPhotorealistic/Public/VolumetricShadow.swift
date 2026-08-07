// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The frozen `shadow-transmittance/binary64-v1` model, specified by
/// `VOXELIA-ALG-0077` and accepted by `ADR-0387`: the fraction of
/// light surviving a walk toward a light.
///
/// The same Beer-Lambert absorption as the `VOXELIA-ALG-0076`
/// integrator, restated for the light path — shadows attenuate lights,
/// they do not paint darkness. Exact extinction is the only early
/// exit; the empty ray transmits exactly one.
public enum VolumetricShadowWalk {
    /// Folds one shadow ray's transmittance.
    ///
    /// - Throws: ``VolumetricIlluminationError/nonFiniteComponent`` or
    ///   ``VolumetricIlluminationError/invalidOpacity``.
    public static func transmittance(
        opacities: ContiguousArray<Double>
    ) throws -> Double {
        var surviving = 1.0
        for opacity in opacities {
            guard opacity.isFinite else {
                throw VolumetricIlluminationError.nonFiniteComponent
            }
            guard opacity >= 0, opacity <= 1 else {
                throw VolumetricIlluminationError.invalidOpacity
            }
            surviving = surviving * (1 - opacity)
            if surviving == 0 { break }
        }
        return surviving
    }
}
