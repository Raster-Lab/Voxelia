// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by progressive accumulation.
public enum ProgressiveAccumulationError: Error, Sendable, Equatable {
    /// A sample was NaN or infinite: refused rather than poisoning
    /// the running state.
    case nonFiniteSample
}

/// The frozen `progressive-variance/binary64-v1` model, specified by
/// `VOXELIA-ALG-0080` and accepted by `ADR-0391`: Welford's running
/// mean and unbiased variance in frozen order.
///
/// Convergence information is three numbers — count, mean, variance —
/// and no invented "percent converged" score. The variance is absent
/// below two samples: a variance nobody measured is not reported as
/// certainty.
public struct ProgressiveAccumulator: Sendable {
    public private(set) var count: Int
    public private(set) var mean: Double
    private var m2: Double

    public init() {
        self.count = 0
        self.mean = 0
        self.m2 = 0
    }

    /// The unbiased variance, absent below two samples.
    public var variance: Double? {
        guard count >= 2 else { return nil }
        return m2 / Double(count - 1)
    }

    /// Accumulates one finite sample.
    ///
    /// - Throws: ``ProgressiveAccumulationError/nonFiniteSample``.
    public mutating func accumulate(_ value: Double) throws {
        guard value.isFinite else {
            throw ProgressiveAccumulationError.nonFiniteSample
        }
        count += 1
        let delta = value - mean
        mean = mean + delta / Double(count)
        let delta2 = value - mean
        m2 = m2 + delta * delta2
    }
}

/// The four declared identities whose change invalidates temporal
/// accumulation, per `VOX-PRR-012`: scene, camera, transfer function
/// and source data — the row's trigger set verbatim, compared by
/// equality. The module cannot know the host's scene state; declared
/// fingerprints make the trigger set explicit and testable.
public struct SceneStateFingerprint: Sendable, Hashable {
    public let sceneIdentity: String
    public let cameraIdentity: String
    public let transferFunctionIdentity: String
    public let sourceDataIdentity: String

    public init(
        sceneIdentity: String,
        cameraIdentity: String,
        transferFunctionIdentity: String,
        sourceDataIdentity: String
    ) {
        self.sceneIdentity = sceneIdentity
        self.cameraIdentity = cameraIdentity
        self.transferFunctionIdentity = transferFunctionIdentity
        self.sourceDataIdentity = sourceDataIdentity
    }
}

/// What one guarded accumulation did.
public enum TemporalAccumulationOutcome: Sendable, Hashable {
    /// The fingerprint matched; the sample joined the accumulation.
    case accumulated
    /// The fingerprint changed; the accumulation was reset **before**
    /// the sample joined — stale accumulation is unrepresentable.
    case resetAndAccumulated
}

/// The `VOX-PRR-012` guard, per `ADR-0391`: accumulation keyed to a
/// declared scene fingerprint, reset — not reprojected — on change.
/// Reprojection is an approximation with its own error story and
/// belongs to a future model if a row demands it.
public struct TemporalAccumulation: Sendable {
    public private(set) var accumulator: ProgressiveAccumulator
    public private(set) var fingerprint: SceneStateFingerprint?

    public init() {
        self.accumulator = ProgressiveAccumulator()
        self.fingerprint = nil
    }

    /// Accumulates one sample under the declared fingerprint,
    /// resetting first when the fingerprint changed.
    ///
    /// - Throws: ``ProgressiveAccumulationError``.
    public mutating func accumulate(
        _ value: Double,
        under current: SceneStateFingerprint
    ) throws -> TemporalAccumulationOutcome {
        if let started = fingerprint, started != current {
            accumulator = ProgressiveAccumulator()
            fingerprint = current
            try accumulator.accumulate(value)
            return .resetAndAccumulated
        }
        fingerprint = current
        try accumulator.accumulate(value)
        return .accumulated
    }
}
