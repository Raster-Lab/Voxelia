// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by the distributed-integrity vocabulary.
public enum DistributedIntegrityError: Error, Sendable, Equatable {
    /// A partial result named a different job.
    case foreignJob
    /// One partition arrived more than once.
    case duplicatedPartition
    /// A partition arrived that the plan never declared.
    case unexpectedPartition
    /// A declared partition never arrived.
    case missingPartition
    /// The job's contract is outside the worker's declared envelope.
    case incompatibleJob
    /// The task was pre-empted by the external fabric.
    case preempted
}

/// One partition's transportable result record, per `ADR-0402`
/// (`VOX-DST-006`): partition identity, payload checksum and producer
/// provenance in the accepted vocabulary. The payload itself travels
/// out of band; this record is what makes it auditable.
public struct PartialResult: Sendable {
    public let jobIdentifier: String
    public let partition: WorkPartition
    /// The payload's content digest.
    public let checksum: ContentID
    /// The producing worker's identity — provenance, not trust.
    public let producer: SoftwareIdentity

    /// Creates a validated partial-result record.
    ///
    /// - Throws: ``DistributedJobError``.
    public init(
        jobIdentifier: String,
        partition: WorkPartition,
        checksum: ContentID,
        producer: SoftwareIdentity
    ) throws {
        guard jobIdentifier.contains(where: { !$0.isWhitespace }) else {
            throw DistributedJobError.emptyJobIdentifier
        }
        try partition.validate()
        self.jobIdentifier = jobIdentifier
        self.partition = partition
        self.checksum = checksum
        self.producer = producer
    }
}

/// The closed reduction-ordering vocabulary of `VOX-DST-009`.
public enum ReductionOrdering: String, Sendable, Hashable, Codable {
    /// Partitions merge in ascending partition identity as a left
    /// fold — the declared rule that makes distributed reductions
    /// bit-reproducible under `VOXELIA-ALG-0083`.
    case ascendingPartitionIdentityLeftFold
}

/// One reduction's declared semantics: the numerical model identifier
/// and the ordering rule. A distributed reduction without declared
/// semantics is unrepresentable.
public struct ReductionSemantics: Sendable, Hashable, Codable {
    public let modelIdentifier: String
    public let ordering: ReductionOrdering

    /// Creates a declared semantics record.
    ///
    /// - Throws: ``DistributedJobError/emptyJobIdentifier``.
    public init(modelIdentifier: String, ordering: ReductionOrdering) throws {
        guard modelIdentifier.contains(where: { !$0.isWhitespace }) else {
            throw DistributedJobError.emptyJobIdentifier
        }
        self.modelIdentifier = modelIdentifier
        self.ordering = ordering
    }
}

/// The merge audit of `VOX-DST-007`, per `ADR-0402`: refusals in fixed
/// precedence — foreign job, duplicated partition, unexpected
/// partition, missing partition — so one failure never masks
/// another's category.
public enum MergeValidator {
    /// Audits received partial results against the declared plan.
    ///
    /// - Throws: ``DistributedIntegrityError``.
    public static func validate(
        jobIdentifier: String,
        expected: [WorkPartition],
        received: [PartialResult],
        semantics: ReductionSemantics
    ) throws {
        _ = semantics
        for result in received where result.jobIdentifier != jobIdentifier {
            throw DistributedIntegrityError.foreignJob
        }
        var seen = [WorkPartition]()
        for result in received {
            guard !seen.contains(result.partition) else {
                throw DistributedIntegrityError.duplicatedPartition
            }
            seen.append(result.partition)
        }
        for result in received where !expected.contains(result.partition) {
            throw DistributedIntegrityError.unexpectedPartition
        }
        for partition in expected where !seen.contains(partition) {
            throw DistributedIntegrityError.missingPartition
        }
    }
}

/// The worker-side admission of `VOX-DST-012`: a job's embedded
/// `ADR-0380` contract must sit inside the worker's declared envelope,
/// or the job refuses typed. Silent best-effort acceptance is the
/// prohibited shape.
public enum WorkerCompatibility {
    /// Requires `job` to be within `worker`'s declared envelope.
    ///
    /// - Throws: ``DistributedIntegrityError/incompatibleJob``.
    public static func require(
        job: DeclaredImplementationContract,
        worker: DeclaredImplementationContract
    ) throws {
        switch (job.domain, worker.domain) {
        case (.triangleMesh, .triangleMesh):
            break
        case (
            .image(let jobRanks, let jobScalars, let jobGeometry),
            .image(let workerRanks, let workerScalars, let workerGeometry)
        ):
            switch (jobRanks, workerRanks) {
            case (_, .any):
                break
            case (.range(let job), .range(let worker)):
                guard
                    job.lowerBound >= worker.lowerBound,
                    job.upperBound <= worker.upperBound
                else {
                    throw DistributedIntegrityError.incompatibleJob
                }
            case (.any, .range):
                throw DistributedIntegrityError.incompatibleJob
            }
            switch (jobScalars, workerScalars) {
            case (_, .any):
                break
            case (.scalars(let job), .scalars(let worker)):
                guard Set(job).isSubset(of: Set(worker)) else {
                    throw DistributedIntegrityError.incompatibleJob
                }
            case (.any, .scalars):
                throw DistributedIntegrityError.incompatibleJob
            }
            switch (jobGeometry, workerGeometry) {
            case (.any, .any), (.requiresAffine, _):
                break
            case (.any, .requiresAffine):
                throw DistributedIntegrityError.incompatibleJob
            }
        default:
            throw DistributedIntegrityError.incompatibleJob
        }
        guard
            Set(job.qualityProfiles).isSubset(of: Set(worker.qualityProfiles)),
            Set(job.capabilityRequirements)
                .isSubset(of: Set(worker.capabilityRequirements))
        else {
            throw DistributedIntegrityError.incompatibleJob
        }
    }
}

/// The cooperative pre-emption seam of `VOX-DST-011`: the external
/// fabric flips it, and the worker checks between partitions —
/// publication races are already guarded by the `ADR-0399` stale-drop.
public actor WorkerPreemption {
    private var preempted = false

    public init() {}

    /// Flips the seam; idempotent.
    public func preempt() {
        preempted = true
    }

    /// Continues, or refuses typed once pre-empted.
    ///
    /// - Throws: ``DistributedIntegrityError/preempted``.
    public func checkContinue() throws {
        guard !preempted else {
            throw DistributedIntegrityError.preempted
        }
    }
}
