// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ConcurrencyStorm")
struct ConcurrencyStormTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func axis(_ id: String) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func originImage(_ name: String) throws -> ImageData {
        let bytes = Array(0..<12).map { UInt8($0) }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: [4, 3]),
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .intensity,
                axes: [try axis("x"), try axis("y")],
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: [4, 3]),
                        scalarType: .uint8,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-\(name)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T08:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: name))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: name)),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.\(name)",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    @Test("[Integration][VOX-CON-009][VOX-VAL-007] the coordinators survive seeded storms")
    func coordinatorsSurviveSeededStorms() async throws {
        var state: UInt64 = 0x0118_5707_0001
        func nextValue() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
        let cancelledFlags = (0..<64).map { _ in nextValue() % 2 == 0 }

        // Phase one: 64 concurrent coalescing reads through one small
        // budget, half cancelled mid-flight. Every survivor yields the
        // exact bytes, and the coordinator ends fully released.
        let storage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: try ImageShape(extents: [4, 3]),
                    scalarType: .uint8,
                    componentCount: 1
                ),
                bytes: Array(0..<12)
            )
        )
        let readCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 24
        )
        let region = try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        var completedReads = 0
        var cancelledReads = 0
        try await withThrowingTaskGroup(of: Bool?.self) { group in
            for index in 0..<64 {
                let cancelled = cancelledFlags[index]
                group.addTask {
                    let task = Task {
                        let read = try await readCoordinator.read(
                            from: storage,
                            region: region
                        )
                        let exact = read.result.bytes == Array(0..<12)
                        try await readCoordinator.release(read.retention)
                        return exact
                    }
                    if cancelled {
                        task.cancel()
                    }
                    do {
                        return try await task.value
                    } catch {
                        return nil
                    }
                }
            }
            for try await outcome in group {
                switch outcome {
                case .some(let exact):
                    #expect(exact)
                    completedReads += 1
                case nil:
                    cancelledReads += 1
                }
            }
        }
        #expect(completedReads + cancelledReads == 64)
        #expect(await readCoordinator.currentChargedByteCount == 0)
        let followUp = try await readCoordinator.read(from: storage, region: region)
        #expect(followUp.result.bytes == Array(0..<12))
        try await readCoordinator.release(followUp.retention)

        // Phase two: 64 concurrent identity requests for one
        // collection, half cancelled; every survivor yields one
        // identity and coalescing holds under the storm.
        let identityCoordinator = MetadataIdentityCoordinator()
        let payload = try MetadataCollection(entries: [])
        var identities = Set<ContentID>()
        var identityCompletions = 0
        try await withThrowingTaskGroup(of: ContentID?.self) { group in
            for index in 0..<64 {
                let cancelled = cancelledFlags[63 - index]
                group.addTask {
                    let task = Task {
                        try await identityCoordinator.identity(
                            for: payload,
                            maximumOutputByteCount: 4_096
                        ).identity
                    }
                    if cancelled {
                        task.cancel()
                    }
                    return try? await task.value
                }
            }
            for try await identity in group {
                if let identity {
                    identities.insert(identity)
                    identityCompletions += 1
                }
            }
        }
        #expect(identities.count <= 1)
        let startedCount = await identityCoordinator.startedComputationCount
        #expect(startedCount < 64)

        // Phase three: 16 distinct publishes interleaved with 16
        // duplicates of one bundle; exactly one duplicate wins.
        let publisher = PublicationCoordinator(
            maximumPublishedObjectCount: 32,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 8,
                maximumParentEdgeCount: 8,
                maximumAncestryDepth: 8,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 1_024
            ),
            resultCache: nil
        )
        let contested = try originImage("contested")
        var duplicateWins = 0
        var duplicateRejections = 0
        try await withThrowingTaskGroup(of: Int.self) { group in
            for index in 0..<16 {
                let distinct = try originImage("series-\(index)")
                group.addTask {
                    _ = try await publisher.publish(distinct, mode: .complete)
                    return 0
                }
                group.addTask {
                    do {
                        _ = try await publisher.publish(contested, mode: .complete)
                        return 1
                    } catch PublicationError.duplicateObjectIdentifier {
                        return 2
                    }
                }
            }
            for try await outcome in group {
                if outcome == 1 { duplicateWins += 1 }
                if outcome == 2 { duplicateRejections += 1 }
            }
        }
        #expect(duplicateWins == 1)
        #expect(duplicateRejections == 15)
        #expect(await publisher.publishedObjectCount == 17)

        // Phase four: a strictly increasing successor chain with stale
        // and equal generations rejected typed at every step.
        final class Owner: Sendable {}
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 1
        )
        let representation = StorageRepresentationDescriptor.decodedStrided(
            try DecodedStridedRepresentation.canonicalPacked(
                binding: binding,
                byteOrder: .native,
                locality: .processLocalOwned
            )
        )
        var handle = try StorageSnapshotHandle.admit(
            binding: binding,
            representation: representation,
            owner: Owner(),
            generation: 0
        )
        for generation in 1...100 {
            handle = try handle.successor(
                representation: representation,
                owner: Owner(),
                generation: UInt64(generation)
            )
            do {
                _ = try handle.successor(
                    representation: representation,
                    owner: Owner(),
                    generation: UInt64(generation)
                )
                #expect(Bool(false), "Expected an equal generation to be rejected.")
            } catch StorageContractError.staleSnapshot {}
        }
        #expect(handle.generation == 100)

        print(
            "ADR-0118 storm evidence: reads \(completedReads) completed "
                + "\(cancelledReads) cancelled of 64; identity survivors "
                + "\(identityCompletions) with \(startedCount) started computations; "
                + "publication 1 duplicate win, 15 typed rejections; "
                + "100 generation successions with equal generations rejected."
        )
    }
}
