// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised by registration-result admission, per `ADR-0366`.
public enum RegistrationResultError: Error, Sendable, Equatable {
    /// The schedule declared no levels.
    case emptySchedule
    /// A level's shrink factor was not positive.
    case invalidShrinkFactor
    /// A level's smoothing sigma was negative, NaN or infinite.
    case invalidSmoothingSigma
    /// The iteration count was negative.
    case invalidIterationCount
    /// The final metric value was NaN or infinite.
    case invalidFinalMetricValue
}

/// A stable identity for a registration metric.
public struct RegistrationMetricID: VoxeliaStringIdentifier {
    /// The preserved case-sensitive identifier spelling.
    public let rawValue: String

    /// The hard inclusive raw-value byte ceiling, mirroring `ADR-0044`.
    public static let maximumUTF8ByteCount = 255

    /// Creates an identifier unless `rawValue` is empty,
    /// Unicode-whitespace-only or over the persistent byte ceiling.
    public init?(rawValue: String) {
        guard rawValue.contains(where: { !$0.isWhitespace }),
            rawValue.utf8.count <= Self.maximumUTF8ByteCount
        else { return nil }
        self.rawValue = rawValue
    }
}

/// A stable identity for a registration optimiser.
public struct RegistrationOptimiserID: VoxeliaStringIdentifier {
    /// The preserved case-sensitive identifier spelling.
    public let rawValue: String

    /// The hard inclusive raw-value byte ceiling, mirroring `ADR-0044`.
    public static let maximumUTF8ByteCount = 255

    /// Creates an identifier unless `rawValue` is empty,
    /// Unicode-whitespace-only or over the persistent byte ceiling.
    public init?(rawValue: String) {
        guard rawValue.contains(where: { !$0.isWhitespace }),
            rawValue.utf8.count <= Self.maximumUTF8ByteCount
        else { return nil }
        self.rawValue = rawValue
    }
}

/// One multi-resolution level: a positive integer shrink factor and a
/// finite non-negative smoothing sigma.
public struct RegistrationScheduleLevel: Sendable, Hashable {
    public let shrinkFactor: Int
    public let smoothingSigma: Double

    /// Creates a validated level.
    ///
    /// - Throws: ``RegistrationResultError``.
    public init(shrinkFactor: Int, smoothingSigma: Double) throws {
        guard shrinkFactor > 0 else {
            throw RegistrationResultError.invalidShrinkFactor
        }
        guard smoothingSigma.isFinite, smoothingSigma >= 0 else {
            throw RegistrationResultError.invalidSmoothingSigma
        }
        self.shrinkFactor = shrinkFactor
        self.smoothingSigma = smoothingSigma
    }
}

/// How a registration run ended: a closed, defaultless vocabulary.
public enum RegistrationConvergenceStatus: String, Sendable, Hashable, Codable {
    case converged
    case iterationLimitReached
    case stoppedByUser
    case failed
}

/// One registration run's durable record, per `ADR-0366`
/// (`VOX-REG-002`): the record identifies what ran — it does not run
/// anything, and no metric or optimiser semantics are invented here.
///
/// Fixed and moving data are identified by full ``DataIdentity`` values
/// rather than retained images: a result outlives the images it came
/// from. The schedule is never optional — single-resolution runs declare
/// one explicit level, because an unknown schedule is not a reproducible
/// result. A failed run records `nil` for the final metric value, never
/// a fabricated number.
public struct RegistrationResult: Sendable {
    /// The fixed (reference) data's identity.
    public let fixedIdentity: DataIdentity
    /// The moving data's identity.
    public let movingIdentity: DataIdentity
    /// The metric that was optimised.
    public let metric: RegistrationMetricID
    /// The metric's version, when the producer declares one.
    public let metricVersion: String?
    /// The optimiser that drove the run.
    public let optimiser: RegistrationOptimiserID
    /// The optimiser's version, when the producer declares one.
    public let optimiserVersion: String?
    /// The multi-resolution schedule, coarsest level first.
    public let schedule: ContiguousArray<RegistrationScheduleLevel>
    /// How the run ended.
    public let convergenceStatus: RegistrationConvergenceStatus
    /// The total iterations the optimiser performed.
    public let iterationCount: Int
    /// The final metric value, absent when no finite measurement exists.
    public let finalMetricValue: Double?
    /// The estimated transform, with its category and spaces.
    public let transform: RegistrationTransform

    /// Creates a validated result record.
    ///
    /// - Throws: ``RegistrationResultError``.
    public init(
        fixedIdentity: DataIdentity,
        movingIdentity: DataIdentity,
        metric: RegistrationMetricID,
        metricVersion: String?,
        optimiser: RegistrationOptimiserID,
        optimiserVersion: String?,
        schedule: ContiguousArray<RegistrationScheduleLevel>,
        convergenceStatus: RegistrationConvergenceStatus,
        iterationCount: Int,
        finalMetricValue: Double?,
        transform: RegistrationTransform
    ) throws {
        guard !schedule.isEmpty else {
            throw RegistrationResultError.emptySchedule
        }
        guard iterationCount >= 0 else {
            throw RegistrationResultError.invalidIterationCount
        }
        if let finalMetricValue, !finalMetricValue.isFinite {
            throw RegistrationResultError.invalidFinalMetricValue
        }
        self.fixedIdentity = fixedIdentity
        self.movingIdentity = movingIdentity
        self.metric = metric
        self.metricVersion = metricVersion
        self.optimiser = optimiser
        self.optimiserVersion = optimiserVersion
        self.schedule = schedule
        self.convergenceStatus = convergenceStatus
        self.iterationCount = iterationCount
        self.finalMetricValue = finalMetricValue
        self.transform = transform
    }
}
