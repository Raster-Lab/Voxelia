// SPDX-License-Identifier: MIT

/// One composited ray per `ADR-0171`: the four output bytes and the
/// consumed sample count — part of the frozen behaviour, and the
/// early-termination evidence acceleration will later compare
/// against.
public struct CompositedRay: Sendable, Hashable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    /// The number of samples consumed before completion or the
    /// declared early termination.
    public let consumedSampleCount: Int
}

/// The pure front-to-back ray compositor per `ADR-0171`, realising
/// the frozen `VOXELIA-ALG-0023` model.
///
/// Samples are the accepted trilinear sample bytes; the binary64
/// conversion the table vocabulary deferred is applied here — one
/// correctly rounded division by two hundred fifty-five per
/// component — and accumulation proceeds front to back in the frozen
/// order with the exact dyadic termination threshold. Everything
/// this produces is presentation, never a source of authoritative
/// quantitative measurement, per the arc's binding rule.
public enum VolumeRayCompositor {
    /// The declared exact early-termination threshold.
    public static let terminationThreshold = 255.0 / 256.0

    /// Composites one ray's ascending sample bytes through the table.
    public static func composite(
        samples: some Sequence<UInt8>,
        table: TransferFunction1D
    ) -> CompositedRay {
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var accumulated = 0.0
        var consumed = 0
        for sample in samples {
            let entry = table.entry(at: Int(sample))
            let alpha = Double(entry.opacity) / 255.0
            let weight = (1.0 - accumulated) * alpha
            red = red + (weight * (Double(entry.red) / 255.0))
            green = green + (weight * (Double(entry.green) / 255.0))
            blue = blue + (weight * (Double(entry.blue) / 255.0))
            accumulated = accumulated + weight
            consumed += 1
            if accumulated >= Self.terminationThreshold {
                break
            }
        }
        return CompositedRay(
            red: Self.outputByte(red),
            green: Self.outputByte(green),
            blue: Self.outputByte(blue),
            alpha: Self.outputByte(accumulated),
            consumedSampleCount: consumed
        )
    }

    /// Composites one ray with per-sample shading factors aligned to
    /// the samples, per `VOXELIA-ALG-0025`: each colour component is
    /// modulated by its factor before the accepted conversion —
    /// `(component * factor) / 255` — and opacity is never modulated,
    /// because lighting changes appearance, never coverage. The
    /// unshaded mode calls the accepted unshaded entry instead, so
    /// byte identity is structural.
    public static func composite(
        samples: [UInt8],
        shadingFactors: [Double],
        table: TransferFunction1D
    ) -> CompositedRay {
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var accumulated = 0.0
        var consumed = 0
        for (sample, factor) in zip(samples, shadingFactors) {
            let entry = table.entry(at: Int(sample))
            let alpha = Double(entry.opacity) / 255.0
            let weight = (1.0 - accumulated) * alpha
            red = red + (weight * ((Double(entry.red) * factor) / 255.0))
            green = green + (weight * ((Double(entry.green) * factor) / 255.0))
            blue = blue + (weight * ((Double(entry.blue) * factor) / 255.0))
            accumulated = accumulated + weight
            consumed += 1
            if accumulated >= Self.terminationThreshold {
                break
            }
        }
        return CompositedRay(
            red: Self.outputByte(red),
            green: Self.outputByte(green),
            blue: Self.outputByte(blue),
            alpha: Self.outputByte(accumulated),
            consumedSampleCount: consumed
        )
    }

    /// Composites one ray with a per-sample inclusion flag aligned to
    /// the samples, per `VOXELIA-ALG-0026`: an excluded sample's
    /// colour and opacity never reach the accumulation, but it is
    /// still counted as consumed, because the ray still visited that
    /// position. The consumed count and the termination check proceed
    /// unconditionally, exactly as the accepted unmasked entry's;
    /// that entry itself is untouched.
    public static func composite(
        samples: [UInt8],
        inclusion: [Bool],
        table: TransferFunction1D
    ) -> CompositedRay {
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var accumulated = 0.0
        var consumed = 0
        for index in samples.indices {
            if inclusion[index] {
                let entry = table.entry(at: Int(samples[index]))
                let alpha = Double(entry.opacity) / 255.0
                let weight = (1.0 - accumulated) * alpha
                red = red + (weight * (Double(entry.red) / 255.0))
                green = green + (weight * (Double(entry.green) / 255.0))
                blue = blue + (weight * (Double(entry.blue) / 255.0))
                accumulated = accumulated + weight
            }
            consumed += 1
            if accumulated >= Self.terminationThreshold {
                break
            }
        }
        return CompositedRay(
            red: Self.outputByte(red),
            green: Self.outputByte(green),
            blue: Self.outputByte(blue),
            alpha: Self.outputByte(accumulated),
            consumedSampleCount: consumed
        )
    }

    /// Composites one ray with both per-sample shading factors and a
    /// per-sample inclusion flag, per `VOXELIA-ALG-0026`: the two
    /// modulations apply to the same step in the declared order —
    /// inclusion gates whether the shading-modulated contribution
    /// happens at all. The consumed count and the termination check
    /// proceed unconditionally, exactly as the accepted shaded
    /// entry's; that entry itself is untouched.
    public static func composite(
        samples: [UInt8],
        shadingFactors: [Double],
        inclusion: [Bool],
        table: TransferFunction1D
    ) -> CompositedRay {
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var accumulated = 0.0
        var consumed = 0
        for index in samples.indices {
            if inclusion[index] {
                let entry = table.entry(at: Int(samples[index]))
                let alpha = Double(entry.opacity) / 255.0
                let weight = (1.0 - accumulated) * alpha
                let factor = shadingFactors[index]
                red = red + (weight * ((Double(entry.red) * factor) / 255.0))
                green = green + (weight * ((Double(entry.green) * factor) / 255.0))
                blue = blue + (weight * ((Double(entry.blue) * factor) / 255.0))
                accumulated = accumulated + weight
            }
            consumed += 1
            if accumulated >= Self.terminationThreshold {
                break
            }
        }
        return CompositedRay(
            red: Self.outputByte(red),
            green: Self.outputByte(green),
            blue: Self.outputByte(blue),
            alpha: Self.outputByte(accumulated),
            consumedSampleCount: consumed
        )
    }

    /// The declared output conversion:
    /// `clamp(roundHalfToEven(value * 255), 0, 255)`.
    private static func outputByte(_ value: Double) -> UInt8 {
        let rounded = (value * 255.0).rounded(.toNearestOrEven)
        return UInt8(min(255.0, max(0.0, rounded)))
    }
}
