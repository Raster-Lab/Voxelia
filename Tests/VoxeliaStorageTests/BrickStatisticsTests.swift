// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaStorage

@Suite("BrickStatistics")
struct BrickStatisticsTests {
    @Test("[Unit][VOX-BRK-011] the one-pass statistics reproduce the design fixtures")
    func onePassStatisticsReproduceTheDesignFixtures() throws {
        // Partial exclusion reduces to the remaining samples.
        let partial = try BrickStatistics(
            overCorePayload: [7, 5, 7],
            sentinel: 7
        )
        #expect(partial.sampleCount == 3)
        #expect(partial.includedSampleCount == 1)
        #expect(partial.includedMinimum == 5)
        #expect(partial.includedMaximum == 5)
        #expect(partial.nonZeroIncludedCount == 1)

        // All-excluded: extremes absent, never fabricated.
        let excluded = try BrickStatistics(
            overCorePayload: [7, 7, 7],
            sentinel: 7
        )
        #expect(excluded.sampleCount == 3)
        #expect(excluded.includedSampleCount == 0)
        #expect(excluded.includedMinimum == nil)
        #expect(excluded.includedMaximum == nil)
        #expect(excluded.nonZeroIncludedCount == 0)

        // All-zero: fully included, zero occupancy — the empty-space
        // fact without a verdict.
        let zeroes = try BrickStatistics(
            overCorePayload: [0, 0, 0],
            sentinel: nil
        )
        #expect(zeroes.includedSampleCount == 3)
        #expect(zeroes.includedMinimum == 0)
        #expect(zeroes.includedMaximum == 0)
        #expect(zeroes.nonZeroIncludedCount == 0)

        // Unpadded mixed payload with repetition bit-identical.
        let mixed = try BrickStatistics(
            overCorePayload: [10, 1, 0, 3],
            sentinel: nil
        )
        #expect(mixed.sampleCount == 4)
        #expect(mixed.includedSampleCount == 4)
        #expect(mixed.includedMinimum == 0)
        #expect(mixed.includedMaximum == 10)
        #expect(mixed.nonZeroIncludedCount == 3)
        #expect(
            mixed
                == (try BrickStatistics(
                    overCorePayload: [10, 1, 0, 3],
                    sentinel: nil
                ))
        )

        // The domain boundary values survive the pass.
        let bounds = try BrickStatistics(
            overCorePayload: [255, 0],
            sentinel: nil
        )
        #expect(bounds.includedMinimum == 0)
        #expect(bounds.includedMaximum == 255)
    }

    @Test("[Unit][VOX-ERR-001] an empty payload rejects typed")
    func emptyPayloadRejectsTyped() {
        #expect(throws: BrickStatisticsError.emptyPayload) {
            try BrickStatistics(overCorePayload: [], sentinel: nil)
        }
    }
}
