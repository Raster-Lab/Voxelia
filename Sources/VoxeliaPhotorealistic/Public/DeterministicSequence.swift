// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The frozen `deterministic-sequence/v1` model, specified by
/// `VOXELIA-ALG-0079` and accepted by `ADR-0390`: SplitMix64 over
/// exact wrapping 64-bit arithmetic — no system generator, no hidden
/// entropy, no rounding anywhere.
///
/// The seed is caller-declared and defaultless: a default seed would
/// make "deterministic" mean "accidentally reproducible". Reference
/// renders declare their seed and record it.
public struct DeterministicSampleSequence: Sendable {
    private var state: UInt64

    /// Creates a sequence at the declared seed.
    public init(seed: UInt64) {
        self.state = seed
    }

    /// The next 64-bit word.
    public mutating func nextWord() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// The next unit sample: the word's top 53 bits scaled by `2⁻⁵³`,
    /// an exact binary64 in `[0, 1)`.
    public mutating func nextUnit() -> Double {
        Double(nextWord() >> 11) * 0x1p-53
    }
}
