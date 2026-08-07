// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

@Suite("MergeableAccumulation")
struct MergeableAccumulationTests {
    @Test("[Unit][VOX-DST-008] the merge reproduces the oracle in both orders")
    func theMergeReproducesTheOracleInBothOrders() throws {
        let a = try MergeableAccumulatorState(
            count: 3,
            mean: 2,
            sumOfSquaredDeviations: 2
        )
        let b = try MergeableAccumulatorState(
            count: 2,
            mean: 15,
            sumOfSquaredDeviations: 50
        )
        let ab = a.merging(b)
        let ba = b.merging(a)
        #expect(ab.count == 5)
        #expect(ab.mean == 0x1.ccccccccccccdp+2)
        #expect(ab.sumOfSquaredDeviations == 0x1.fd99999999999p+7)
        // Both orders agree bit-exactly on this fixture — and the
        // sequential fold over the same samples lands one ulp away
        // (0x1.fd9999999999ap+7): the merge is a DIFFERENT frozen
        // model, recorded, which is why reductions declare ordering.
        #expect(ba.mean == ab.mean)
        #expect(ba.sumOfSquaredDeviations == ab.sumOfSquaredDeviations)

        let c = try MergeableAccumulatorState(
            count: 3,
            mean: 0x1.5555555555555p-2,
            sumOfSquaredDeviations: 0x1.4e38e38e38e39p-2
        )
        _ = c
    }

    @Test("[Unit][VOX-DST-008] empty states are identity and admission refuses typed")
    func emptyStatesAreIdentityAndAdmissionRefusesTyped() throws {
        let empty = try MergeableAccumulatorState(
            count: 0,
            mean: 0,
            sumOfSquaredDeviations: 0
        )
        let real = try MergeableAccumulatorState(
            count: 4,
            mean: 2.5,
            sumOfSquaredDeviations: 5
        )
        #expect(empty.merging(real) == real)
        #expect(real.merging(empty) == real)
        // The honesty rule carries over: variance absent below two.
        let single = try MergeableAccumulatorState(
            count: 1,
            mean: 9,
            sumOfSquaredDeviations: 0
        )
        #expect(single.variance == nil)
        #expect(throws: ProgressiveAccumulationError.nonFiniteSample) {
            _ = try MergeableAccumulatorState(
                count: 1,
                mean: .nan,
                sumOfSquaredDeviations: 0
            )
        }
    }
}
