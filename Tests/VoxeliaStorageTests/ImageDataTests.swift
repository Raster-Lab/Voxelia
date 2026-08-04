// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaStorage

@Suite("ImageData")
struct ImageDataTests {
    private final class OpaqueOwner: Sendable {}

    private struct OpaqueStubStorage: ImageStorageContract {
        let snapshot: StorageSnapshotHandle

        func read(region: ImageRegion) throws -> RegionReadResult {
            throw StorageContractError.providerFailure
        }
    }

    private func binding(componentCount: Int = 1) throws -> LogicalSampleBinding {
        try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: componentCount
        )
    }

    private func erasedStorage(componentCount: Int = 1) throws -> AnyImageStorage {
        let binding = try binding(componentCount: componentCount)
        return AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: binding,
                bytes: Array(repeating: 0, count: binding.logicalByteCount)
            )
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

    private func descriptor(
        extents: [Int] = [4, 3],
        scalarType: ScalarType = .uint8,
        byteOrder: ByteOrder = .native,
        componentCount: Int = 1
    ) throws -> ImageDescriptor {
        try ImageDescriptor(
            shape: try ImageShape(extents: extents),
            scalarFormat: try ScalarFormat(
                type: scalarType,
                validBitCount: nil,
                byteOrder: byteOrder
            ),
            components: try ComponentDescriptor(
                count: componentCount,
                interpretation: .scalar,
                layout: .interleaved,
                componentNames: nil
            ),
            semantic: .intensity,
            axes: [try axis("x"), try axis("y")],
            spatialGeometry: nil,
            valueTransform: nil,
            units: nil
        )
    }

    private func identity(
        sources: Bool = true,
        derivation: DerivationIdentity? = nil
    ) throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(DataObjectID(rawValue: "series-7")),
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: Array(repeating: 0, count: 12)
            ),
            sourceIdentities: sources
                ? [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.2",
                        version: nil,
                        contentID: nil
                    )
                ] : [],
            derivation: derivation
        )
    }

    private func derivation() throws -> DerivationIdentity {
        try DerivationIdentity(
            operationID: try DerivationOperationToken(
                rawValue: "org.voxelia.op.window-level"
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            implementation: nil,
            inputs: [
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "input"),
                    identity: .object(try #require(DataObjectID(rawValue: "series-6")))
                )
            ],
            parameterDigest: try ContentID.operationParametersIdentity(
                overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                    payload: try MetadataCollection(entries: []),
                    maximumOutputByteCount: 4_096
                )
            ),
            declaresZeroInputGenerator: false
        )
    }

    private func provenance(
        subject: String = "series-7",
        origin: Bool = true
    ) throws -> ProvenanceRecord {
        let activity: ProvenanceActivity
        let inputs: ContiguousArray<ProvenanceInput>
        let kind: ProvenanceKind
        if origin {
            activity = .origin
            inputs = []
            kind = .source
        } else {
            let claimVersion = try SemanticVersion(major: 1, minor: 0, patch: 0)
            activity = .operation(
                try OperationProvenance(
                    operationID: try DerivationOperationToken(
                        rawValue: "org.voxelia.op.window-level"
                    ),
                    operationVersion: claimVersion,
                    implementationID: try DerivationOperationToken(
                        rawValue: "org.voxelia.impl.window-level.cpu"
                    ),
                    implementationVersion: claimVersion,
                    parameterDigest: try ContentID.operationParametersIdentity(
                        overCanonicalBytes:
                            try CanonicalMetadataJSON
                            .encodeUniqueDocument(
                                payload: try MetadataCollection(entries: []),
                                maximumOutputByteCount: 4_096
                            )
                    )
                ),
                ExecutionProvenanceClaim(
                    profile: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.profile.default"
                        ),
                        version: claimVersion
                    ),
                    backend: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.backend.cpu"
                        ),
                        version: claimVersion
                    ),
                    precisionPolicy: try ExecutionClaimToken(
                        rawValue: "org.voxelia.precision.binary64-strict"
                    ),
                    qualityPolicy: try ExecutionClaimToken(
                        rawValue: "org.voxelia.quality.full"
                    ),
                    approximationStatus: .exact,
                    capabilityClass: nil,
                    kernel: nil
                )
            )
            inputs = [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(try #require(DataObjectID(rawValue: "series-6"))),
                    parent: nil
                )
            ]
            kind = .transformed
        }
        return try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-1")),
            kind: kind,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: subject))),
            software: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: nil,
                buildIdentifier: nil
            ),
            activity: activity,
            inputs: inputs,
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    private func metadata(duplicate: Bool = false) throws -> MetadataCollection {
        let key = try AnyMetadataKey(namespace: "org.voxelia", name: "modality")
        let first = MetadataEntry(
            key: key,
            value: .string("CT"),
            privacyClass: .technical
        )
        guard duplicate else {
            return try MetadataCollection(entries: [first])
        }
        // A repeat-bearing collection exists only through the explicit
        // multiplicity-policy path; the aggregate still rejects it.
        let second = MetadataEntry(
            key: key,
            value: .string("MR"),
            privacyClass: .technical
        )
        return try MetadataCollection(
            entries: [first, second],
            multiplicityPolicy: try MetadataMultiplicityPolicy(
                repeatableKeys: [key]
            )
        )
    }

    @Test("[Unit][CDMS-37.2][VOX-IMG-001] coherent aggregates construct and bind exactly")
    func coherentAggregatesConstructAndBindExactly() async throws {
        // An acquired origin image binds a real owned contiguous
        // provider to its descriptor, metadata, identity and provenance.
        let image = try ImageData(
            descriptor: try descriptor(),
            storage: try erasedStorage(),
            metadata: try metadata(),
            provenance: try provenance(),
            identity: try identity()
        )
        #expect(image.descriptor.shape == image.storage.snapshot.binding.shape)
        #expect(image.identity.objectID.rawValue == "series-7")
        #expect(image.provenance.subject == .object(image.identity.objectID))
        #expect(image.metadata.entries.count == 1)

        // A derived image with an operation-activity record and a
        // derivation recipe is likewise coherent.
        let derived = try ImageData(
            descriptor: try descriptor(),
            storage: try erasedStorage(),
            metadata: try metadata(),
            provenance: try provenance(origin: false),
            identity: try identity(sources: false, derivation: try derivation())
        )
        #expect(derived.identity.derivation != nil)

        requireSendable(ImageData.self)
        requireSendable(ImageDataError.self)
    }

    @Test("[Unit][CDMS-37.2][VOX-ERR-001] construction rejects every incoherence")
    func constructionRejectsEveryIncoherence() async throws {
        func expectRejection(
            _ expected: ImageDataError,
            descriptor: ImageDescriptor? = nil,
            storage: AnyImageStorage? = nil,
            metadata: MetadataCollection? = nil,
            provenance: ProvenanceRecord? = nil,
            identity: DataIdentity? = nil
        ) throws {
            do {
                _ = try ImageData(
                    descriptor: descriptor ?? (try self.descriptor()),
                    storage: storage ?? (try erasedStorage()),
                    metadata: metadata ?? (try self.metadata()),
                    provenance: provenance ?? (try self.provenance()),
                    identity: identity ?? (try self.identity())
                )
                #expect(Bool(false), "Expected an incoherent aggregate to be rejected.")
            } catch let error as ImageDataError {
                #expect(error == expected)
            }
        }

        // Each descriptor-storage mismatch is its own typed rejection.
        try expectRejection(
            .shapeMismatch,
            descriptor: try descriptor(extents: [3, 4])
        )
        try expectRejection(
            .scalarTypeMismatch,
            descriptor: try descriptor(scalarType: .uint16)
        )
        try expectRejection(
            .componentCountMismatch,
            storage: try erasedStorage(componentCount: 2)
        )
        try expectRejection(
            .byteOrderMismatch,
            descriptor: try descriptor(byteOrder: .littleEndian)
        )

        // An opaque representation cannot supply logical samples.
        let opaqueHandle = try StorageSnapshotHandle.admit(
            binding: try binding(),
            representation: .opaque(
                try OpaqueRepresentation(formatTag: "raw", knownByteCount: nil)
            ),
            owner: OpaqueOwner(),
            generation: 1
        )
        try expectRejection(
            .unsupportedRepresentation,
            storage: AnyImageStorage(
                erasing: OpaqueStubStorage(snapshot: opaqueHandle)
            )
        )

        // Provenance must bind this aggregate's own object identity,
        // and an origin cannot carry a derivation recipe or lack
        // source lineage.
        try expectRejection(
            .provenanceSubjectMismatch,
            provenance: try provenance(subject: "series-8")
        )
        try expectRejection(
            .originDerivationConflict,
            identity: try identity(derivation: try derivation())
        )
        try expectRejection(
            .missingOriginSource,
            identity: try identity(sources: false)
        )

        // Repeated metadata keys are rejected, and rejections stay
        // payload-free.
        do {
            _ = try ImageData(
                descriptor: try descriptor(),
                storage: try erasedStorage(),
                metadata: try metadata(duplicate: true),
                provenance: try provenance(),
                identity: try identity()
            )
            #expect(Bool(false), "Expected a repeated metadata key to be rejected.")
        } catch let error as ImageDataError {
            #expect(error == .duplicateMetadataKey)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("modality"))
            #expect(!rendered.contains("series"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
