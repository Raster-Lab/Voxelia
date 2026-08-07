// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("DistributedIntegrity")
struct DistributedIntegrityTests {
    private func producer() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Example Worker",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func partial(
        job: String = "job-1",
        partition: WorkPartition
    ) throws -> PartialResult {
        try PartialResult(
            jobIdentifier: job,
            partition: partition,
            checksum: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: [1, 2, 3]
            ),
            producer: try producer()
        )
    }

    private func semantics() throws -> ReductionSemantics {
        try ReductionSemantics(
            modelIdentifier: "welford-merge/binary64-v1",
            ordering: .ascendingPartitionIdentityLeftFold
        )
    }

    @Test("[Unit][VOX-DST-006][VOX-DST-009] partials carry checksum, provenance, identity")
    func partialsCarryChecksumProvenanceIdentity() throws {
        let result = try partial(
            partition: .imageTile(originX: 0, originY: 0, width: 64, height: 64)
        )
        #expect(result.jobIdentifier == "job-1")
        #expect(result.producer.name == "Example Worker")
        // Declared semantics are a required value, not a convention.
        let declared = try semantics()
        #expect(declared.ordering == .ascendingPartitionIdentityLeftFold)
    }

    @Test("[Unit][VOX-DST-007] the audit refuses each category typed")
    func theAuditRefusesEachCategoryTyped() throws {
        let tileA = WorkPartition.imageTile(originX: 0, originY: 0, width: 64, height: 64)
        let tileB = WorkPartition.imageTile(originX: 64, originY: 0, width: 64, height: 64)

        // The complete set audits clean.
        try MergeValidator.validate(
            jobIdentifier: "job-1",
            expected: [tileA, tileB],
            received: [try partial(partition: tileA), try partial(partition: tileB)],
            semantics: try semantics()
        )
        #expect(throws: DistributedIntegrityError.foreignJob) {
            try MergeValidator.validate(
                jobIdentifier: "job-1",
                expected: [tileA],
                received: [try partial(job: "job-2", partition: tileA)],
                semantics: try semantics()
            )
        }
        #expect(throws: DistributedIntegrityError.duplicatedPartition) {
            try MergeValidator.validate(
                jobIdentifier: "job-1",
                expected: [tileA, tileB],
                received: [try partial(partition: tileA), try partial(partition: tileA)],
                semantics: try semantics()
            )
        }
        #expect(throws: DistributedIntegrityError.unexpectedPartition) {
            try MergeValidator.validate(
                jobIdentifier: "job-1",
                expected: [tileA],
                received: [try partial(partition: tileB)],
                semantics: try semantics()
            )
        }
        #expect(throws: DistributedIntegrityError.missingPartition) {
            try MergeValidator.validate(
                jobIdentifier: "job-1",
                expected: [tileA, tileB],
                received: [try partial(partition: tileA)],
                semantics: try semantics()
            )
        }
    }

    @Test("[Unit][VOX-DST-012] a worker refuses jobs outside its envelope")
    func aWorkerRefusesJobsOutsideItsEnvelope() throws {
        func contract(
            ranks: DeclaredRankSupport,
            scalars: DeclaredScalarSupport,
            geometry: DeclaredGeometrySupport
        ) throws -> DeclaredImplementationContract {
            try DeclaredImplementationContract(
                domain: .image(ranks: ranks, scalars: scalars, geometry: geometry),
                qualityProfiles: [
                    try ExecutionClaimToken(rawValue: "org.voxelia.quality.full")
                ],
                capabilityRequirements: []
            )
        }
        let worker = try contract(
            ranks: .range(2...3),
            scalars: .scalars([.uint8, .float32]),
            geometry: .any
        )
        try WorkerCompatibility.require(
            job: try contract(
                ranks: .range(3...3),
                scalars: .scalars([.uint8]),
                geometry: .requiresAffine
            ),
            worker: worker
        )
        // A rank outside the worker's envelope refuses.
        #expect(throws: DistributedIntegrityError.incompatibleJob) {
            try WorkerCompatibility.require(
                job: try contract(
                    ranks: .range(1...3),
                    scalars: .scalars([.uint8]),
                    geometry: .any
                ),
                worker: worker
            )
        }
        // A scalar the worker never declared refuses.
        #expect(throws: DistributedIntegrityError.incompatibleJob) {
            try WorkerCompatibility.require(
                job: try contract(
                    ranks: .range(3...3),
                    scalars: .scalars([.int16]),
                    geometry: .any
                ),
                worker: worker
            )
        }
    }

    @Test("[Unit][VOX-DST-011] pre-emption refuses continuation typed")
    func preemptionRefusesContinuationTyped() async throws {
        let preemption = WorkerPreemption()
        try await preemption.checkContinue()
        await preemption.preempt()
        await #expect(throws: DistributedIntegrityError.preempted) {
            try await preemption.checkContinue()
        }
    }
}
