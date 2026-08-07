// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by ray-sample admission.
public enum VolumetricIlluminationError: Error, Sendable, Equatable {
    /// A component was NaN or infinite.
    case nonFiniteComponent
    /// An emission component was negative.
    case negativeEmission
    /// An opacity was outside `[0, 1]`.
    case invalidOpacity
}

/// One admitted ray sample: an emission triple and an opacity.
public struct RaySample: Sendable, Hashable {
    public let emissionRed: Double
    public let emissionGreen: Double
    public let emissionBlue: Double
    public let opacity: Double

    /// Creates a validated sample.
    ///
    /// - Throws: ``VolumetricIlluminationError``.
    public init(
        emissionRed: Double,
        emissionGreen: Double,
        emissionBlue: Double,
        opacity: Double
    ) throws {
        for component in [emissionRed, emissionGreen, emissionBlue, opacity]
        where !component.isFinite {
            throw VolumetricIlluminationError.nonFiniteComponent
        }
        for component in [emissionRed, emissionGreen, emissionBlue]
        where component < 0 {
            throw VolumetricIlluminationError.negativeEmission
        }
        guard opacity >= 0, opacity <= 1 else {
            throw VolumetricIlluminationError.invalidOpacity
        }
        self.emissionRed = emissionRed
        self.emissionGreen = emissionGreen
        self.emissionBlue = emissionBlue
        self.opacity = opacity
    }
}

/// One integrated radiance result.
public struct RadianceSample: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
}

/// The frozen `emission-absorption/binary64-v1` model, specified by
/// `VOXELIA-ALG-0076` and accepted by `ADR-0386`: the physically based
/// foundation of `VOX-PRR-004`.
///
/// The integrator is the numerical core, not a renderer: sampling —
/// volume interpolation, transfer functions, step sizes — is the
/// caller's seam, which is what keeps the fixtures exact. An empty ray
/// is exactly transparent; accumulated opacity saturating at exactly
/// one occludes every later sample, with no epsilon deciding
/// visibility.
public enum VolumetricIlluminationIntegrator {
    /// Integrates one ordered front-to-back ray.
    public static func integrate(
        samples: ContiguousArray<RaySample>
    ) -> RadianceSample {
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var accumulated = 0.0
        for sample in samples {
            let weight = (1 - accumulated) * sample.opacity
            red = red + weight * sample.emissionRed
            green = green + weight * sample.emissionGreen
            blue = blue + weight * sample.emissionBlue
            accumulated = accumulated + weight
            if accumulated == 1 { break }
        }
        return RadianceSample(
            red: red,
            green: green,
            blue: blue,
            opacity: accumulated
        )
    }
}
