// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution

/// An error raised by benchmark-record admission.
public enum BenchmarkReportError: Error, Sendable, Equatable {
    /// A required text field was empty or whitespace-only.
    case emptyField
    /// A measurement was negative, NaN or infinite.
    case invalidMeasurement
    /// The regression threshold was not a finite positive fraction.
    case invalidThreshold
}

/// The closed benchmark-mode vocabulary of `VOX-PER-010`, verbatim.
public enum BenchmarkMode: String, Sendable, Hashable, Codable, CaseIterable {
    case coldStart
    case warmCache
    case steadyState
    case memoryPressure
    case cancellation
    case contention
    case headlessBatch
    case distributed
}

/// One validated benchmark report row, per `ADR-0407`
/// (`VOX-PER-011`): the baseline's field list verbatim, admitted and
/// revalidated on decode. A report is a set of records, and "as
/// applicable" means the report says which modes ran.
public struct BenchmarkRecord: Sendable, Codable {
    public let mode: BenchmarkMode
    public let hardware: String
    public let operatingSystem: String
    public let compiler: String
    public let voxeliaVersion: String
    public let operationIdentifier: DerivationOperationToken
    public let operationVersion: SemanticVersion
    /// Absent for CPU entries, honestly optional.
    public let shaderIdentity: String?
    public let dataset: String
    public let storageForm: String
    public let cacheState: String
    public let quality: ExecutionClaimToken
    public let latencyMilliseconds: Double
    public let throughputPerSecond: Double
    public let peakMemoryBytes: Double
    public let validationStatus: String

    /// Creates a validated record.
    ///
    /// - Throws: ``BenchmarkReportError``.
    public init(
        mode: BenchmarkMode,
        hardware: String,
        operatingSystem: String,
        compiler: String,
        voxeliaVersion: String,
        operationIdentifier: DerivationOperationToken,
        operationVersion: SemanticVersion,
        shaderIdentity: String?,
        dataset: String,
        storageForm: String,
        cacheState: String,
        quality: ExecutionClaimToken,
        latencyMilliseconds: Double,
        throughputPerSecond: Double,
        peakMemoryBytes: Double,
        validationStatus: String
    ) throws {
        for field in [
            hardware, operatingSystem, compiler, voxeliaVersion,
            dataset, storageForm, cacheState, validationStatus,
        ]
        where !field.contains(where: { !$0.isWhitespace }) {
            throw BenchmarkReportError.emptyField
        }
        if let shaderIdentity,
            !shaderIdentity.contains(where: { !$0.isWhitespace })
        {
            throw BenchmarkReportError.emptyField
        }
        for measurement in [
            latencyMilliseconds, throughputPerSecond, peakMemoryBytes,
        ] {
            guard measurement.isFinite, measurement >= 0 else {
                throw BenchmarkReportError.invalidMeasurement
            }
        }
        self.mode = mode
        self.hardware = hardware
        self.operatingSystem = operatingSystem
        self.compiler = compiler
        self.voxeliaVersion = voxeliaVersion
        self.operationIdentifier = operationIdentifier
        self.operationVersion = operationVersion
        self.shaderIdentity = shaderIdentity
        self.dataset = dataset
        self.storageForm = storageForm
        self.cacheState = cacheState
        self.quality = quality
        self.latencyMilliseconds = latencyMilliseconds
        self.throughputPerSecond = throughputPerSecond
        self.peakMemoryBytes = peakMemoryBytes
        self.validationStatus = validationStatus
    }

    private enum CodingKeys: String, CodingKey {
        case mode, hardware, operatingSystem, compiler, voxeliaVersion
        case operationIdentifier, operationVersion, shaderIdentity
        case dataset, storageForm, cacheState, quality
        case latencyMilliseconds, throughputPerSecond, peakMemoryBytes
        case validationStatus
    }

    /// Decodes and revalidates through the throwing admission.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            mode: try container.decode(BenchmarkMode.self, forKey: .mode),
            hardware: try container.decode(String.self, forKey: .hardware),
            operatingSystem: try container.decode(
                String.self, forKey: .operatingSystem
            ),
            compiler: try container.decode(String.self, forKey: .compiler),
            voxeliaVersion: try container.decode(
                String.self, forKey: .voxeliaVersion
            ),
            operationIdentifier: try container.decode(
                DerivationOperationToken.self, forKey: .operationIdentifier
            ),
            operationVersion: try container.decode(
                SemanticVersion.self, forKey: .operationVersion
            ),
            shaderIdentity: try container.decodeIfPresent(
                String.self, forKey: .shaderIdentity
            ),
            dataset: try container.decode(String.self, forKey: .dataset),
            storageForm: try container.decode(String.self, forKey: .storageForm),
            cacheState: try container.decode(String.self, forKey: .cacheState),
            quality: try container.decode(ExecutionClaimToken.self, forKey: .quality),
            latencyMilliseconds: try container.decode(
                Double.self, forKey: .latencyMilliseconds
            ),
            throughputPerSecond: try container.decode(
                Double.self, forKey: .throughputPerSecond
            ),
            peakMemoryBytes: try container.decode(
                Double.self, forKey: .peakMemoryBytes
            ),
            validationStatus: try container.decode(
                String.self, forKey: .validationStatus
            )
        )
    }
}

/// One regression evaluation's closed outcome.
public enum RegressionOutcome: Sendable, Hashable {
    case pass
    /// The candidate regressed beyond the declared threshold on the
    /// named dimension.
    case regression(dimension: String)
}

/// The `VOX-PER-012` threshold seam, per `ADR-0407`: the approved
/// threshold is caller-declared — defaultless, because approval is the
/// owner's — and CI wiring consumes the closed outcome.
public enum RegressionCheck {
    /// Evaluates a candidate against a baseline under a fractional
    /// threshold (for example `0.1` for ten percent).
    ///
    /// - Throws: ``BenchmarkReportError/invalidThreshold``.
    public static func evaluate(
        baseline: BenchmarkRecord,
        candidate: BenchmarkRecord,
        threshold: Double
    ) throws -> RegressionOutcome {
        guard threshold.isFinite, threshold > 0 else {
            throw BenchmarkReportError.invalidThreshold
        }
        if candidate.latencyMilliseconds
            > baseline.latencyMilliseconds * (1 + threshold)
        {
            return .regression(dimension: "latency")
        }
        if candidate.throughputPerSecond
            < baseline.throughputPerSecond * (1 - threshold)
        {
            return .regression(dimension: "throughput")
        }
        if candidate.peakMemoryBytes > baseline.peakMemoryBytes * (1 + threshold) {
            return .regression(dimension: "memory")
        }
        return .pass
    }
}
