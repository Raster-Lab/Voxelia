// SPDX-License-Identifier: MIT

import Foundation

/// An error raised by registration-metric admission, per `ADR-0370`.
public enum RegistrationMetricError: Error, Sendable, Equatable {
    /// The fixed and moving sample counts differ.
    case countMismatch
    /// No sample pairs were supplied.
    case emptySamples
    /// The bin count was below two.
    case invalidBinCount
    /// A range bound was non-finite, or the range was not ordered.
    case invalidRange
}

/// Whether an optimiser should drive a metric's value down or up —
/// recorded structurally so no consumer ever guesses a direction.
public enum RegistrationMetricPolarity: String, Sendable, Hashable, Codable {
    case lowerIsBetter
    case higherIsBetter
}

/// One metric evaluation: an optional value plus visible counts.
///
/// The value is absent — never zero — when nothing contributed, and the
/// excluded count keeps a shrunken denominator visible, the same
/// honesty rule segment statistics set.
public struct RegistrationMetricEvaluation: Sendable, Hashable {
    public let value: Double?
    public let contributingSampleCount: Int
    public let excludedSampleCount: Int

    public init(
        value: Double?,
        contributingSampleCount: Int,
        excludedSampleCount: Int
    ) {
        self.value = value
        self.contributingSampleCount = contributingSampleCount
        self.excludedSampleCount = excludedSampleCount
    }
}

/// The metric face of the registration architecture, per `ADR-0370`
/// (`VOX-REG-007`): an instance carries its configuration and evaluates
/// aligned binary64 sample pairs. How a transform produces aligned
/// pairs is the caller's seam — metrics never see images.
public protocol RegistrationMetric: Sendable {
    /// The stable identity the `ADR-0366` result record names.
    var identifier: RegistrationMetricID { get }
    /// The metric's version.
    var version: String { get }
    /// The direction an optimiser should drive the value.
    var polarity: RegistrationMetricPolarity { get }

    /// Evaluates the metric over aligned sample pairs.
    func evaluate(
        fixedSamples: ContiguousArray<Double>,
        movingSamples: ContiguousArray<Double>
    ) throws -> RegistrationMetricEvaluation
}

/// The mean-squares metric of `VOXELIA-ALG-0072`: the frozen fold of
/// squared differences over contributing pairs. Non-finite pairs are
/// excluded and counted.
public struct MeanSquaresMetric: RegistrationMetric {
    public var identifier: RegistrationMetricID {
        guard let id = RegistrationMetricID(rawValue: "org.voxelia.metric.mean-squares")
        else {
            preconditionFailure("The literal identifier is valid by construction.")
        }
        return id
    }
    public let version = "1.0.0"
    public let polarity = RegistrationMetricPolarity.lowerIsBetter

    public init() {}

    public func evaluate(
        fixedSamples: ContiguousArray<Double>,
        movingSamples: ContiguousArray<Double>
    ) throws -> RegistrationMetricEvaluation {
        guard fixedSamples.count == movingSamples.count else {
            throw RegistrationMetricError.countMismatch
        }
        guard !fixedSamples.isEmpty else {
            throw RegistrationMetricError.emptySamples
        }
        var total = 0.0
        var contributing = 0
        var excluded = 0
        for index in fixedSamples.indices {
            let fixed = fixedSamples[index]
            let moving = movingSamples[index]
            guard fixed.isFinite, moving.isFinite else {
                excluded += 1
                continue
            }
            let difference = moving - fixed
            total = total + difference * difference
            contributing += 1
        }
        return RegistrationMetricEvaluation(
            value: contributing > 0 ? total / Double(contributing) : nil,
            contributingSampleCount: contributing,
            excludedSampleCount: excluded
        )
    }
}

/// The histogram mutual-information metric of `VOXELIA-ALG-0072`.
///
/// The bin count and both ranges are caller-declared and defaultless —
/// an assumed range is a silent rescale. Out-of-range and non-finite
/// pairs are excluded and counted; a value exactly at the upper bound
/// joins the last bin. The logarithm is the platform libm's, the same
/// determinism contract as the separable Gaussian's exponential.
public struct MutualInformationMetric: RegistrationMetric {
    public var identifier: RegistrationMetricID {
        guard
            let id = RegistrationMetricID(
                rawValue: "org.voxelia.metric.mutual-information"
            )
        else {
            preconditionFailure("The literal identifier is valid by construction.")
        }
        return id
    }
    public let version = "1.0.0"
    public let polarity = RegistrationMetricPolarity.higherIsBetter

    public let binCount: Int
    public let fixedLowerBound: Double
    public let fixedUpperBound: Double
    public let movingLowerBound: Double
    public let movingUpperBound: Double

    /// Creates a metric with a bin count of at least two and finite
    /// ordered ranges for each side.
    ///
    /// - Throws: ``RegistrationMetricError``.
    public init(
        binCount: Int,
        fixedLowerBound: Double,
        fixedUpperBound: Double,
        movingLowerBound: Double,
        movingUpperBound: Double
    ) throws {
        guard binCount >= 2 else {
            throw RegistrationMetricError.invalidBinCount
        }
        for (lower, upper) in [
            (fixedLowerBound, fixedUpperBound),
            (movingLowerBound, movingUpperBound),
        ] {
            guard lower.isFinite, upper.isFinite, lower < upper else {
                throw RegistrationMetricError.invalidRange
            }
        }
        self.binCount = binCount
        self.fixedLowerBound = fixedLowerBound
        self.fixedUpperBound = fixedUpperBound
        self.movingLowerBound = movingLowerBound
        self.movingUpperBound = movingUpperBound
    }

    private func binIndex(_ value: Double, lower: Double, width: Double) -> Int? {
        let raw = floor((value - lower) / width)
        let bins = Double(binCount)
        if raw == bins, value == lower + width * bins {
            return binCount - 1
        }
        guard raw >= 0, raw < bins else { return nil }
        return Int(raw)
    }

    public func evaluate(
        fixedSamples: ContiguousArray<Double>,
        movingSamples: ContiguousArray<Double>
    ) throws -> RegistrationMetricEvaluation {
        guard fixedSamples.count == movingSamples.count else {
            throw RegistrationMetricError.countMismatch
        }
        guard !fixedSamples.isEmpty else {
            throw RegistrationMetricError.emptySamples
        }
        let fixedWidth = (fixedUpperBound - fixedLowerBound) / Double(binCount)
        let movingWidth = (movingUpperBound - movingLowerBound) / Double(binCount)
        var joint = [Int](repeating: 0, count: binCount * binCount)
        var contributing = 0
        var excluded = 0
        for index in fixedSamples.indices {
            let fixed = fixedSamples[index]
            let moving = movingSamples[index]
            guard fixed.isFinite, moving.isFinite,
                let fixedBin = binIndex(fixed, lower: fixedLowerBound, width: fixedWidth),
                let movingBin = binIndex(
                    moving,
                    lower: movingLowerBound,
                    width: movingWidth
                )
            else {
                excluded += 1
                continue
            }
            joint[binCount * fixedBin + movingBin] += 1
            contributing += 1
        }
        guard contributing > 0 else {
            return RegistrationMetricEvaluation(
                value: nil,
                contributingSampleCount: 0,
                excludedSampleCount: excluded
            )
        }
        var rowTotals = [Int](repeating: 0, count: binCount)
        var columnTotals = [Int](repeating: 0, count: binCount)
        for row in 0..<binCount {
            for column in 0..<binCount {
                rowTotals[row] += joint[binCount * row + column]
                columnTotals[column] += joint[binCount * row + column]
            }
        }
        let total = Double(contributing)
        var value = 0.0
        for row in 0..<binCount {
            for column in 0..<binCount {
                let count = joint[binCount * row + column]
                if count == 0 { continue }
                let p = Double(count) / total
                let rowProbability = Double(rowTotals[row]) / total
                let columnProbability = Double(columnTotals[column]) / total
                value = value + p * log(p / (rowProbability * columnProbability))
            }
        }
        return RegistrationMetricEvaluation(
            value: value,
            contributingSampleCount: contributing,
            excludedSampleCount: excluded
        )
    }
}
