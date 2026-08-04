// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("PublicationCoordinator")
struct PublicationCoordinatorTests {
    private func axis(_ id: String) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func originImage(
        objectName: String = "series-7",
        recordName: String = "record-in",
        claimedBytes: [UInt8]? = nil
    ) throws -> ImageData {
        let storedBytes: [UInt8] = Array(0..<12)
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 1
        )
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
                    binding: binding,
                    bytes: storedBytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: recordName)),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: objectName))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: objectName)),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: claimedBytes ?? storedBytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.2",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func graphLimits() throws -> ProvenanceGraphLimits {
        try ProvenanceGraphLimits(
            maximumRecordCount: 8,
            maximumParentEdgeCount: 8,
            maximumAncestryDepth: 8,
            maximumUnresolvedExternalReferenceCount: 0,
            maximumExternalResolutionByteCount: 8_192
        )
    }

    private func coordinator(
        maximumPublishedObjectCount: UInt64 = 8,
        readBudget: UInt64 = 64,
        cache: ContentResultCache? = nil
    ) throws -> PublicationCoordinator {
        PublicationCoordinator(
            maximumPublishedObjectCount: maximumPublishedObjectCount,
            graphLimits: try graphLimits(),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: readBudget
            ),
            resultCache: cache
        )
    }

    private func windowed(_ input: ImageData) async throws -> ImageData {
        try await WindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: 6),
            width: try MetadataFloatingPoint(value: 8),
            outputObjectID: try #require(DataObjectID(rawValue: "series-8")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:05:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    @Test("[Unit][VOX-EXE-002][VOX-CCH-004] publication linearises, verifies and aliases")
    func publicationLinearisesVerifiesAndAliases() async throws {
        let cache = ContentResultCache(
            maximumEntryCount: 4,
            maximumTotalByteCount: 64
        )
        let publisher = try coordinator(cache: cache)
        let origin = try originImage()

        // Publishing the origin verifies its claim, admits a depth-one
        // complete graph and aliases the verified bytes.
        let originReceipt = try await publisher.publish(origin, mode: .complete)
        #expect(originReceipt.authority == .complete)
        #expect(originReceipt.ancestryDepth == 1)
        #expect(originReceipt.contentClaimVerified)
        #expect(originReceipt.cachedAlias)
        let claim = try #require(origin.identity.contentID)
        #expect(try await cache.lookup(claim) == Array(0..<12))

        // A real operation output publishes against its published
        // parent with depth-two complete authority.
        let output = try await windowed(origin)
        let outputReceipt = try await publisher.publish(output, mode: .complete)
        #expect(outputReceipt.authority == .complete)
        #expect(outputReceipt.ancestryDepth == 2)
        #expect(outputReceipt.contentClaimVerified)
        #expect(await publisher.publishedObjectCount == 2)
        #expect(
            await publisher.publishedImage(for: output.identity.objectID)?
                .provenance.id == output.provenance.id
        )
        #expect(
            await publisher.publishedProvenanceRecord(for: origin.provenance.id)
                == origin.provenance
        )

        // Republication of a published identifier is a typed rejection
        // even for the identical bundle.
        do {
            _ = try await publisher.publish(origin, mode: .complete)
            #expect(Bool(false), "Expected identifier reuse to be rejected.")
        } catch PublicationError.duplicateObjectIdentifier {}

        // Without a cache the receipt reports the alias honestly.
        let uncachedPublisher = try coordinator()
        let uncachedReceipt = try await uncachedPublisher.publish(
            try originImage(),
            mode: .complete
        )
        #expect(uncachedReceipt.contentClaimVerified)
        #expect(!uncachedReceipt.cachedAlias)

        requireSendable(PublicationReceipt.self)
        requireSendable(PublicationError.self)
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] publication rejects incoherence typed")
    func publicationRejectsIncoherenceTyped() async throws {
        // A corrupted content claim never publishes.
        do {
            _ = try await (try coordinator()).publish(
                try originImage(claimedBytes: [9, 9, 9]),
                mode: .complete
            )
            #expect(Bool(false), "Expected a corrupted claim to be rejected.")
        } catch PublicationError.contentClaimMismatch {}

        // An output whose parent record is unpublished is an unresolved
        // parent in both modes.
        let orphanPublisher = try coordinator()
        let output = try await windowed(try originImage())
        for mode in [ProvenanceGraphAdmissionMode.complete, .compact] {
            do {
                _ = try await orphanPublisher.publish(output, mode: mode)
                #expect(Bool(false), "Expected an unpublished parent to be rejected.")
            } catch ProvenanceGraphError.unresolvedParent {}
        }

        // Provenance identifier reuse rejects even under a fresh object
        // identifier.
        let reusePublisher = try coordinator()
        _ = try await reusePublisher.publish(try originImage(), mode: .complete)
        do {
            _ = try await reusePublisher.publish(
                try originImage(objectName: "series-9", recordName: "record-in"),
                mode: .complete
            )
            #expect(Bool(false), "Expected provenance reuse to be rejected.")
        } catch PublicationError.duplicateProvenanceIdentifier {}

        // The append-only ceiling is a transactional failure that
        // evicts nothing.
        let boundedPublisher = try coordinator(maximumPublishedObjectCount: 1)
        _ = try await boundedPublisher.publish(try originImage(), mode: .complete)
        do {
            _ = try await boundedPublisher.publish(
                try originImage(objectName: "series-9", recordName: "record-2"),
                mode: .complete
            )
            #expect(Bool(false), "Expected the ceiling to reject.")
        } catch PublicationError.publishedRecordLimitExceeded {}
        #expect(await boundedPublisher.publishedObjectCount == 1)

        // The verification read stays under the read budget.
        do {
            _ = try await (try coordinator(readBudget: 2)).publish(
                try originImage(),
                mode: .complete
            )
            #expect(Bool(false), "Expected the verification budget to reject.")
        } catch StorageContractError.resourceLimitExceeded {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
