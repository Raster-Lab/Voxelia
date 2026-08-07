// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The frozen `welford-merge/binary64-v1` model, specified by
/// `VOXELIA-ALG-0083` and accepted by `ADR-0402` (`VOX-DST-008`):
/// Chan's combination of two accumulator states. It consumes states,
/// not samples, so no sample ordering is required — and because the
/// merge is a different frozen model from sequential accumulation,
/// distributed reductions declare their ordering (`ADR-0402`'s
/// ascending-partition-identity left fold) for bit-reproducibility.
public struct MergeableAccumulatorState: Sendable, Hashable {
    public let count: Int
    public let mean: Double
    /// The sum of squared deviations (`m2` in `VOXELIA-ALG-0080`).
    public let sumOfSquaredDeviations: Double

    /// Creates a validated state.
    ///
    /// - Throws: ``ProgressiveAccumulationError/nonFiniteSample``.
    public init(count: Int, mean: Double, sumOfSquaredDeviations: Double) throws {
        guard
            count >= 0,
            mean.isFinite,
            sumOfSquaredDeviations.isFinite,
            sumOfSquaredDeviations >= 0
        else {
            throw ProgressiveAccumulationError.nonFiniteSample
        }
        self.count = count
        self.mean = mean
        self.sumOfSquaredDeviations = sumOfSquaredDeviations
    }

    /// Merges two states under the frozen rule. Merging with an empty
    /// state returns the other verbatim.
    public func merging(_ other: MergeableAccumulatorState) -> MergeableAccumulatorState {
        if count == 0 { return other }
        if other.count == 0 { return self }
        let combined = count + other.count
        let delta = other.mean - mean
        let mergedMean = mean + delta * (Double(other.count) / Double(combined))
        let mergedM2 =
            (sumOfSquaredDeviations + other.sumOfSquaredDeviations)
            + (delta * delta)
            * (Double(count) * Double(other.count) / Double(combined))
        guard
            let merged = try? MergeableAccumulatorState(
                count: combined,
                mean: mergedMean,
                sumOfSquaredDeviations: mergedM2
            )
        else {
            preconditionFailure("Merging finite admitted states stays finite.")
        }
        return merged
    }

    /// The unbiased variance, absent below two samples — the
    /// `VOXELIA-ALG-0080` honesty rule.
    public var variance: Double? {
        guard count >= 2 else { return nil }
        return sumOfSquaredDeviations / Double(count - 1)
    }
}
