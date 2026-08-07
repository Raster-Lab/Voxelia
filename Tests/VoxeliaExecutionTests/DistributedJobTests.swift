// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("DistributedJob")
struct DistributedJobTests {
    private func contract() throws -> DeclaredImplementationContract {
        try DeclaredImplementationContract(
            domain: .image(
                ranks: .range(3...3),
                scalars: .scalars([.uint8]),
                geometry: .requiresAffine
            ),
            qualityProfiles: [
                try ExecutionClaimToken(rawValue: "org.voxelia.quality.full")
            ],
            capabilityRequirements: []
        )
    }

    private func description(
        partition: WorkPartition,
        seed: UInt64? = nil
    ) throws -> DistributedJobDescription {
        try DistributedJobDescription(
            jobIdentifier: "job-1",
            operation: try DerivationOperationToken(
                rawValue: "org.voxelia.op.level-select"
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            parameters: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: [1, 2, 3]
            ),
            requiredInputs: [
                try JobInputIdentity(
                    objectIdentifier: "volume-7",
                    contentID: try ContentID.sampleBytesIdentity(
                        overCanonicalPackedBytes: [4, 5, 6]
                    )
                )
            ],
            compatibility: try contract(),
            partition: partition,
            seed: seed
        )
    }

    @Test("[Unit][VOX-DST-001][VOX-DST-002][VOX-DST-003] the description round-trips revalidated")
    func theDescriptionRoundTripsRevalidated() throws {
        let original = try description(
            partition: .imageTile(originX: 0, originY: 64, width: 128, height: 128)
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            DistributedJobDescription.self,
            from: encoded
        )
        #expect(decoded.jobIdentifier == "job-1")
        #expect(decoded.operation == original.operation)
        #expect(decoded.operationVersion == original.operationVersion)
        #expect(decoded.parameters == original.parameters)
        #expect(decoded.requiredInputs.count == 1)
        #expect(decoded.requiredInputs[0].objectIdentifier == "volume-7")
        // The ADR-0380 contract travels verbatim: one spelling of
        // compatibility, no transport mirror.
        #expect(decoded.compatibility == original.compatibility)
        #expect(decoded.partition == original.partition)
    }

    @Test("[Unit][VOX-DST-004][VOX-PRR-016] the four partition shapes admit validated")
    func theFourPartitionShapesAdmitValidated() throws {
        _ = try description(
            partition: .imageTile(originX: 0, originY: 0, width: 64, height: 64)
        )
        _ = try description(partition: .frameRange(0...29))
        _ = try description(partition: .brickSet(["brick-0-0-0", "brick-1-0-0"]))
        // The photorealistic partitioning row: a sample-range job with
        // its declared seed.
        let photorealistic = try description(
            partition: .sampleRange(firstSample: 4096, count: 4096),
            seed: 42
        )
        #expect(photorealistic.seed == 42)

        #expect(throws: DistributedJobError.invalidTile) {
            _ = try description(
                partition: .imageTile(originX: -1, originY: 0, width: 64, height: 64)
            )
        }
        #expect(throws: DistributedJobError.invalidBrickSet) {
            _ = try description(partition: .brickSet([]))
        }
        #expect(throws: DistributedJobError.invalidSampleRange) {
            _ = try description(
                partition: .sampleRange(firstSample: 0, count: 0),
                seed: 1
            )
        }
    }

    @Test("[Unit][VOX-DST-005] stochastic work without a seed refuses typed")
    func stochasticWorkWithoutASeedRefusesTyped() throws {
        #expect(throws: DistributedJobError.missingSeed) {
            _ = try description(
                partition: .sampleRange(firstSample: 0, count: 1024)
            )
        }
    }

    @Test("[Unit][VOX-DST-001] decode revalidates rather than trusting transport")
    func decodeRevalidatesRatherThanTrustingTransport() throws {
        let valid = try description(
            partition: .sampleRange(firstSample: 0, count: 64),
            seed: 7
        )
        let object = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(valid)
        )
        var json = try #require(object as? [String: Any])
        // A tampered wire form drops the seed: the decode refuses with
        // the same typed error as construction.
        json.removeValue(forKey: "seed")
        let tampered = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: DistributedJobError.missingSeed) {
            _ = try JSONDecoder().decode(
                DistributedJobDescription.self,
                from: tampered
            )
        }
    }
}
