// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

/// The `ADR-0396` engineering halves of the photorealistic validation
/// rows: deterministic convergence, bit-equal reproducibility and
/// contrast preservation through the pinned composition.
@Suite("PhotorealisticValidation")
struct PhotorealisticValidationTests {
    @Test("[Integration][VOX-VAL-015] convergence is a deterministic fact of the seed")
    func convergenceIsADeterministicFactOfTheSeed() throws {
        var sequence = DeterministicSampleSequence(seed: 7)
        var accumulator = ProgressiveAccumulator()
        var meanVarianceCheckpoints = [Double]()
        for sampleIndex in 1...1000 {
            try accumulator.accumulate(sequence.nextUnit())
            if sampleIndex == 10 || sampleIndex == 100 || sampleIndex == 1000 {
                let variance = try #require(accumulator.variance)
                meanVarianceCheckpoints.append(
                    variance / Double(accumulator.count)
                )
            }
        }
        // The variance of the mean strictly decreases across
        // order-of-magnitude checkpoints — deterministically, for this
        // declared seed, with no tolerance band.
        #expect(meanVarianceCheckpoints.count == 3)
        #expect(meanVarianceCheckpoints[1] < meanVarianceCheckpoints[0])
        #expect(meanVarianceCheckpoints[2] < meanVarianceCheckpoints[1])
    }

    @Test("[Integration][VOX-VAL-015] reproducibility is bit-equality of state")
    func reproducibilityIsBitEqualityOfState() throws {
        func run(seed: UInt64) throws -> (Int, Double, Double?) {
            var sequence = DeterministicSampleSequence(seed: seed)
            var accumulator = ProgressiveAccumulator()
            for _ in 0..<256 {
                try accumulator.accumulate(sequence.nextUnit())
            }
            return (accumulator.count, accumulator.mean, accumulator.variance)
        }
        let first = try run(seed: 99)
        let second = try run(seed: 99)
        #expect(first.0 == second.0)
        #expect(first.1 == second.1)
        #expect(first.2 == second.2)
        let other = try run(seed: 100)
        #expect(other.1 != first.1)
    }

    @Test("[Integration][VOX-PRR-017] the preset preserves a one-sample-thin structure")
    func thePresetPreservesAOneSampleThinStructure() throws {
        // The preset under test: one unit light, unit weight, and the
        // albedo mapping of the ADR-0389 composition. Background rays
        // carry faint wide material; the structure ray carries one thin
        // bright high-value sample inside it.
        func integrate(withStructure: Bool) throws -> RadianceSample {
            var samples = ContiguousArray<RaySample>()
            for index in 0..<9 {
                if withStructure && index == 4 {
                    samples.append(
                        try RaySample(
                            emissionRed: 4,
                            emissionGreen: 4,
                            emissionBlue: 4,
                            opacity: 0.25
                        )
                    )
                }
                samples.append(
                    try RaySample(
                        emissionRed: 0.05,
                        emissionGreen: 0.05,
                        emissionBlue: 0.05,
                        opacity: 0.02
                    )
                )
            }
            return VolumetricIlluminationIntegrator.integrate(samples: samples)
        }
        let background = try integrate(withStructure: false)
        let structure = try integrate(withStructure: true)
        // Strictly positive contrast: the thin structure survives the
        // preset rather than washing into the background.
        #expect(structure.red > background.red)
        #expect(structure.opacity > background.opacity)

        // High-value intensity carries monotonically: doubling the
        // structure's emission strictly increases the output.
        let brighter = VolumetricIlluminationIntegrator.integrate(samples: [
            try RaySample(emissionRed: 8, emissionGreen: 8, emissionBlue: 8, opacity: 0.25)
        ])
        let bright = VolumetricIlluminationIntegrator.integrate(samples: [
            try RaySample(emissionRed: 4, emissionGreen: 4, emissionBlue: 4, opacity: 0.25)
        ])
        #expect(brighter.red > bright.red)
    }
}
