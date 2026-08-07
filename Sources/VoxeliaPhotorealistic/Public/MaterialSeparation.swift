// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by material-separated integration.
public enum MaterialSeparationError: Error, Sendable, Equatable {
    /// The declared material count was not positive.
    case invalidMaterialCount
    /// A sample's material index was at or above the declared count.
    case materialIndexOutOfRange
}

/// One material-tagged ray sample.
public struct MaterialRaySample: Sendable, Hashable {
    /// The declared material index, assigned by the caller's
    /// classification — the module does not classify tissue.
    public let material: Int
    public let sample: RaySample

    public init(material: Int, sample: RaySample) {
        self.material = material
        self.sample = sample
    }
}

/// The frozen `material-separation/binary64-v1` model, specified by
/// `VOXELIA-ALG-0081` and accepted by `ADR-0392`: one shared opacity
/// walk, radiance recorded per declared material.
///
/// Separation changes where radiance is *recorded*, never how light
/// *travels*: a bone window in front of a vessel still shadows the
/// vessel. No combined image is computed here — summing per-material
/// triples rounds in a different order than the plain integration,
/// and the model refuses to pretend the two are bit-equal.
public enum MaterialSeparatedIntegrator {
    /// Integrates one ray into per-material radiance triples plus the
    /// shared opacity.
    ///
    /// - Throws: ``MaterialSeparationError``.
    public static func integrate(
        samples: ContiguousArray<MaterialRaySample>,
        materialCount: Int
    ) throws -> (materials: [RadianceSample], opacity: Double) {
        guard materialCount > 0 else {
            throw MaterialSeparationError.invalidMaterialCount
        }
        var red = [Double](repeating: 0, count: materialCount)
        var green = [Double](repeating: 0, count: materialCount)
        var blue = [Double](repeating: 0, count: materialCount)
        var accumulated = 0.0
        for tagged in samples {
            guard tagged.material >= 0, tagged.material < materialCount else {
                throw MaterialSeparationError.materialIndexOutOfRange
            }
            let weight = (1 - accumulated) * tagged.sample.opacity
            red[tagged.material] =
                red[tagged.material] + weight * tagged.sample.emissionRed
            green[tagged.material] =
                green[tagged.material] + weight * tagged.sample.emissionGreen
            blue[tagged.material] =
                blue[tagged.material] + weight * tagged.sample.emissionBlue
            accumulated = accumulated + weight
            if accumulated == 1 { break }
        }
        let materials = (0..<materialCount).map {
            RadianceSample(
                red: red[$0],
                green: green[$0],
                blue: blue[$0],
                opacity: accumulated
            )
        }
        return (materials, accumulated)
    }
}
