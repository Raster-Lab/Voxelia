// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised by failure-report admission, per `ADR-0372`.
public enum RegistrationOutcomeError: Error, Sendable, Equatable {
    /// A failure report cannot carry a converged status — a "failure
    /// report" of a success is a contradiction, not a value.
    case notAFailure
}

/// One non-converged run's report, per `ADR-0372` (`VOX-REG-008`): the
/// identities, configuration and honest measurements — **and no
/// transform**. A non-converged run structurally cannot hand one out.
public struct RegistrationFailureReport: Sendable {
    public let fixedIdentity: DataIdentity
    public let movingIdentity: DataIdentity
    public let metric: RegistrationMetricID
    public let optimiser: RegistrationOptimiserID
    /// The non-converged status: iteration limit, user stop or failure.
    public let convergenceStatus: RegistrationConvergenceStatus
    public let iterationCount: Int
    /// The final metric value, absent when no finite measurement exists.
    public let finalMetricValue: Double?

    /// Creates a report for a run that did not converge.
    ///
    /// - Throws: ``RegistrationOutcomeError/notAFailure``.
    public init(
        fixedIdentity: DataIdentity,
        movingIdentity: DataIdentity,
        metric: RegistrationMetricID,
        optimiser: RegistrationOptimiserID,
        convergenceStatus: RegistrationConvergenceStatus,
        iterationCount: Int,
        finalMetricValue: Double?
    ) throws {
        guard convergenceStatus != .converged else {
            throw RegistrationOutcomeError.notAFailure
        }
        self.fixedIdentity = fixedIdentity
        self.movingIdentity = movingIdentity
        self.metric = metric
        self.optimiser = optimiser
        self.convergenceStatus = convergenceStatus
        self.iterationCount = iterationCount
        self.finalMetricValue = finalMetricValue
    }
}

/// The presentation seam of `VOX-REG-008`, per `ADR-0372`: a closed
/// two-case vocabulary in which failure cannot be presented as a
/// successful transform.
///
/// Only `converged` classifies as success — an iteration-limit stop, a
/// user stop and a failure all classify into the failure case, and
/// accepting a limit-reached estimate is a decision a host must take
/// explicitly against the report, never implicitly by reaching for a
/// transform the classification quietly surrendered. The `ADR-0366`
/// record stays complete for audit; this vocabulary is what hosts
/// consume.
public enum RegistrationOutcome: Sendable {
    case succeeded(RegistrationResult)
    case notConverged(RegistrationFailureReport)

    /// Sorts one result into exactly one case: total, non-throwing, so
    /// no result in hand has a path around the seam.
    public static func classify(_ result: RegistrationResult) -> RegistrationOutcome {
        guard result.convergenceStatus == .converged else {
            // The admission cannot refuse here: the status is known
            // non-converged, so the report's own guard always passes.
            guard
                let report = try? RegistrationFailureReport(
                    fixedIdentity: result.fixedIdentity,
                    movingIdentity: result.movingIdentity,
                    metric: result.metric,
                    optimiser: result.optimiser,
                    convergenceStatus: result.convergenceStatus,
                    iterationCount: result.iterationCount,
                    finalMetricValue: result.finalMetricValue
                )
            else {
                preconditionFailure("A non-converged status always admits.")
            }
            return .notConverged(report)
        }
        return .succeeded(result)
    }

    /// The transform, available only from a succeeded outcome.
    public var successfulTransform: RegistrationTransform? {
        guard case .succeeded(let result) = self else { return nil }
        return result.transform
    }
}
