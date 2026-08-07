// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by light-sample or background admission.
public enum LightingError: Error, Sendable, Equatable {
    /// A component was NaN or infinite.
    case nonFiniteComponent
    /// A radiance component or weight was negative.
    case negativeValue
    /// A transmittance was outside `[0, 1]`.
    case invalidTransmittance
}

/// One declared light sample, per `ADR-0388`: an area light is the
/// samples the caller drew over its surface, an environment light its
/// directional samples — one mechanism, differing only in what the
/// caller declares.
public struct LightSample: Sendable, Hashable {
    public let radianceRed: Double
    public let radianceGreen: Double
    public let radianceBlue: Double
    public let weight: Double
    /// The admitted shadow transmittance toward this light, produced
    /// by a `VOXELIA-ALG-0077` walk or the caller's occlusion model.
    public let transmittance: Double

    /// Creates a validated light sample.
    ///
    /// - Throws: ``LightingError``.
    public init(
        radianceRed: Double,
        radianceGreen: Double,
        radianceBlue: Double,
        weight: Double,
        transmittance: Double
    ) throws {
        for component in [
            radianceRed, radianceGreen, radianceBlue, weight, transmittance,
        ]
        where !component.isFinite {
            throw LightingError.nonFiniteComponent
        }
        for component in [radianceRed, radianceGreen, radianceBlue, weight]
        where component < 0 {
            throw LightingError.negativeValue
        }
        guard transmittance >= 0, transmittance <= 1 else {
            throw LightingError.invalidTransmittance
        }
        self.radianceRed = radianceRed
        self.radianceGreen = radianceGreen
        self.radianceBlue = radianceBlue
        self.weight = weight
        self.transmittance = transmittance
    }
}

/// The frozen light accumulation and transillumination composition of
/// `VOXELIA-ALG-0078`, accepted by `ADR-0388`.
public enum LightingComposition {
    /// Accumulates declared light samples in order; the empty set is
    /// exactly zero.
    public static func accumulate(
        lights: ContiguousArray<LightSample>
    ) -> (red: Double, green: Double, blue: Double) {
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        for light in lights {
            let factor = light.weight * light.transmittance
            red = red + factor * light.radianceRed
            green = green + factor * light.radianceGreen
            blue = blue + factor * light.radianceBlue
        }
        return (red, green, blue)
    }

    /// Composes one integrated radiance over a background: what the
    /// volume did not absorb arrives from behind it.
    ///
    /// - Throws: ``LightingError``.
    public static func transilluminate(
        radiance: RadianceSample,
        backgroundRed: Double,
        backgroundGreen: Double,
        backgroundBlue: Double
    ) throws -> (red: Double, green: Double, blue: Double) {
        for component in [backgroundRed, backgroundGreen, backgroundBlue] {
            guard component.isFinite else {
                throw LightingError.nonFiniteComponent
            }
            guard component >= 0 else {
                throw LightingError.negativeValue
            }
        }
        let remaining = 1 - radiance.opacity
        return (
            radiance.red + remaining * backgroundRed,
            radiance.green + remaining * backgroundGreen,
            radiance.blue + remaining * backgroundBlue
        )
    }
}
