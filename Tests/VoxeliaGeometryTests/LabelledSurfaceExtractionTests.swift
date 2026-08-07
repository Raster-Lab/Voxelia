// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaGeometry

@Suite("LabelledSurfaceExtraction")
struct LabelledSurfaceExtractionTests {
    private final class StorageOwner: Sendable {}

    private struct StubStorage: ImageStorageContract {
        let snapshot: StorageSnapshotHandle

        func read(region: ImageRegion) throws -> RegionReadResult {
            throw StorageContractError.providerFailure
        }
    }

    @Test("[Unit][VOX-API-003][VOX-GEO-007] declarations preserve exact integer domains")
    func declarationsPreserveInputsAndTransferSafely() async throws {
        let source = try sourceVolume()
        let signedLabels: ContiguousArray<Int64> = [Int64.min, -1, Int64.max]
        let limits = LabelledSurfaceExtractionLimits(
            maximumSelectedLabelCount: 0,
            maximumVertexCount: UInt64.max,
            maximumTriangleCount: 0
        )
        let request = LabelledSurfaceExtractionRequest(
            source: source,
            selectedLabels: .signed(signedLabels),
            limits: limits
        )
        let publication = try publicationContext()

        #expect(
            LabelledSurfaceExtractionRequest.operationIdentifier
                == "org.voxelia.op.labelled-surface-extraction"
        )
        #expect(
            LabelledSurfaceExtractionRequest.algorithmIdentifier
                == "freudenthal-label-set-surface/binary64-v1"
        )
        #expect(
            LabelledSurfaceExtractionRequest.maximumSupportedLabelCount
                == 65_536
        )
        #expect(request.source.identity.objectID == source.identity.objectID)
        switch request.selectedLabels {
        case .signed(let labels):
            #expect(labels == signedLabels)
        case .unsigned:
            Issue.record("Expected exact signed label domain.")
        }
        #expect(request.limits.maximumSelectedLabelCount == 0)
        #expect(request.limits.maximumVertexCount == UInt64.max)
        #expect(request.limits.maximumTriangleCount == 0)
        #expect(publication.outputObjectID.rawValue == "label-surface-1")
        #expect(
            publication.outputProvenanceID.rawValue
                == "label-surface-record-1"
        )
        #expect(publication.createdAt.utcString == "2026-08-05T16:10:00Z")
        #expect(publication.software.name == "Voxelia")

        requireSendable(LabelledSurfaceExtractionError.self)
        requireSendable(LabelledSurfaceLabelSet.self)
        requireSendable(LabelledSurfaceExtractionLimits.self)
        requireSendable(LabelledSurfaceExtractionRequest.self)
        requireSendable(LabelledSurfaceExtractionPublicationContext.self)
        requireSendable(LabelledSurfaceExtractionResult.self)

        let transferred = await Task.detached {
            let values: ContiguousArray<Int64> =
                switch request.selectedLabels {
                case .signed(let labels): labels
                case .unsigned: []
                }
            return (
                values,
                request.limits.maximumVertexCount,
                publication.outputObjectID
            )
        }.value
        #expect(transferred.0 == signedLabels)
        #expect(transferred.1 == UInt64.max)
        #expect(transferred.2 == publication.outputObjectID)

        let unsigned = LabelledSurfaceLabelSet.unsigned([0, UInt64.max])
        switch unsigned {
        case .signed:
            Issue.record("Expected exact unsigned label domain.")
        case .unsigned(let labels):
            #expect(labels == [0, UInt64.max])
        }
        #expect(
            String(describing: LabelledSurfaceExtractionError.invalidLabelSet)
                == "invalidLabelSet"
        )
    }

    @Test("[Unit][VOX-META-003][VOX-META-005] parameter digest binds exact label domain and values")
    func parameterDigestBindsFrozenSchemaAndMaximumDocument() throws {
        let selected = LabelledSurfaceLabelSet.signed([-9, 4, 71])
        let document = try LabelledSurfaceExtractionRequest.parameterDocument(
            for: selected
        )
        let digest = try LabelledSurfaceExtractionRequest.parameterDigest(
            for: selected
        )
        #expect(document == (try independentParameterDocument(for: selected)))
        #expect(digest == (try independentParameterDigest(for: selected)))
        #expect(
            digest.digest == [
                0x79, 0xd1, 0xe8, 0x15, 0xa2, 0xb2, 0x14, 0x6e,
                0x24, 0xde, 0x98, 0xa3, 0x5b, 0x1e, 0x25, 0xd7,
                0x09, 0x1a, 0x7c, 0x19, 0xee, 0x7f, 0xe7, 0xa2,
                0x03, 0x31, 0xe8, 0x1a, 0xd7, 0x13, 0xd3, 0x50,
            ]
        )

        #expect(
            digest
                != (try LabelledSurfaceExtractionRequest.parameterDigest(
                    for: .signed([-9, 4, 72])
                ))
        )
        #expect(
            try LabelledSurfaceExtractionRequest.parameterDigest(
                for: .signed([1])
            )
                != LabelledSurfaceExtractionRequest.parameterDigest(
                    for: .unsigned([1])
                )
        )

        for invalid in [
            LabelledSurfaceLabelSet.signed([]),
            .signed([1, 1]),
            .signed([2, 1]),
        ] {
            #expect(throws: LabelledSurfaceExtractionError.invalidLabelSet) {
                try LabelledSurfaceExtractionRequest.parameterDigest(
                    for: invalid
                )
            }
        }

        let base = UInt64.max - 65_535
        let maximumLabels = ContiguousArray(
            (0..<65_536).map { base + UInt64($0) }
        )
        let maximumDocument = try LabelledSurfaceExtractionRequest.parameterDocument(
            for: .unsigned(maximumLabels)
        )
        #expect(
            maximumDocument.count
                <= LabelledSurfaceExtractionRequest
                .parameterDocumentMaximumOutputByteCount
        )
        #expect(maximumDocument.count == 2_819_178)
        #expect(
            maximumDocument
                == (try independentParameterDocument(
                    for: .unsigned(maximumLabels)
                ))
        )

        let excessiveLabels = ContiguousArray(
            (0...65_536).map(UInt64.init)
        )
        #expect(
            throws: LabelledSurfaceExtractionError.resourceLimitExceeded
        ) {
            try LabelledSurfaceExtractionRequest.parameterDocument(
                for: .unsigned(excessiveLabels)
            )
        }
        let excessiveUnorderedLabels = ContiguousArray(
            repeating: UInt64.zero,
            count: 65_537
        )
        #expect(
            throws: LabelledSurfaceExtractionError.resourceLimitExceeded
        ) {
            try LabelledSurfaceExtractionRequest.parameterDocument(
                for: .unsigned(excessiveUnorderedLabels)
            )
        }

        // Host limits and publication authority are deliberately absent from
        // the parameter helper; changing them cannot change the digest.
        let firstRequest = LabelledSurfaceExtractionRequest(
            source: try sourceVolume(),
            selectedLabels: selected,
            limits: LabelledSurfaceExtractionLimits(
                maximumSelectedLabelCount: 3,
                maximumVertexCount: 1,
                maximumTriangleCount: 1
            )
        )
        let secondRequest = LabelledSurfaceExtractionRequest(
            source: firstRequest.source,
            selectedLabels: selected,
            limits: LabelledSurfaceExtractionLimits(
                maximumSelectedLabelCount: 65_536,
                maximumVertexCount: UInt64.max,
                maximumTriangleCount: UInt64.max
            )
        )
        #expect(
            try LabelledSurfaceExtractionRequest.parameterDigest(
                for: firstRequest.selectedLabels
            )
                == LabelledSurfaceExtractionRequest.parameterDigest(
                    for: secondRequest.selectedLabels
                )
        )
    }

    @Test("[Unit][VOX-GEO-006][VOX-META-003] coherent result binds mesh identity and provenance")
    func coherentResultBindsEveryDomain() async throws {
        let request = try request()
        let publication = try publicationContext()
        let identity = try outputIdentity(
            request: request,
            publication: publication
        )
        let provenance = try outputProvenance(
            request: request,
            publication: publication
        )
        let mesh = try emptyMesh(space: try sourceSpace(from: request.source))

        let result = try LabelledSurfaceExtractionResult(
            mesh: mesh,
            identity: identity,
            provenance: provenance,
            request: request,
            publication: publication
        )
        #expect(result.mesh.coordinateSpace == mesh.coordinateSpace)
        #expect(result.identity == identity)
        #expect(result.provenance == provenance)
        #expect(result.identity.contentID == nil)
        #expect(result.identity.sourceIdentities.isEmpty)

        let transferred = await Task.detached {
            (
                result.mesh.topology.triangleCount,
                result.identity.objectID,
                result.provenance.id
            )
        }.value
        #expect(transferred.0 == 0)
        #expect(transferred.1 == publication.outputObjectID)
        #expect(transferred.2 == publication.outputProvenanceID)
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-011] output authority and identity fail payload-free")
    func rejectsInvalidOutputAuthorityAndIdentity() throws {
        let request = try request()
        let publication = try publicationContext()
        let mesh = try emptyMesh(space: try sourceSpace(from: request.source))
        let validIdentity = try outputIdentity(
            request: request,
            publication: publication
        )
        let validProvenance = try outputProvenance(
            request: request,
            publication: publication
        )
        let buildTaggedVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            buildMetadata: "unexpected"
        )
        let wrongDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )

        let wrongPublication = LabelledSurfaceExtractionPublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "label-surface-2")
            ),
            outputProvenanceID: publication.outputProvenanceID,
            createdAt: publication.createdAt,
            software: publication.software
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: validIdentity,
            provenance: validProvenance,
            request: request,
            publication: wrongPublication
        )

        for identity in try [
            outputIdentity(
                request: request,
                publication: publication,
                objectID: DataObjectID(rawValue: "label-surface-2")
            ),
            outputIdentity(
                request: request,
                publication: publication,
                contentID: ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [0]
                )
            ),
            outputIdentity(
                request: request,
                publication: publication,
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "test.source",
                        identifier: "unexpected",
                        version: nil,
                        contentID: nil
                    )
                ]
            ),
            outputIdentity(
                request: request,
                publication: publication,
                contentID: ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [0]
                ),
                includeDerivation: false
            ),
            outputIdentity(
                request: request,
                publication: publication,
                operationID: "org.voxelia.op.other"
            ),
            outputIdentity(
                request: request,
                publication: publication,
                parameterDigest: wrongDigest
            ),
            outputIdentity(
                request: request,
                publication: publication,
                operationVersion: buildTaggedVersion
            ),
            outputIdentity(
                request: request,
                publication: publication,
                includeImplementation: false
            ),
            outputIdentity(
                request: request,
                publication: publication,
                implementationID: "org.voxelia.impl.other.cpu"
            ),
            outputIdentity(
                request: request,
                publication: publication,
                implementationVersion: buildTaggedVersion
            ),
            outputIdentity(
                request: request,
                publication: publication,
                inputRole: "other-source"
            ),
            outputIdentity(
                request: request,
                publication: publication,
                inputObjectID: DataObjectID(rawValue: "other-volume")
            ),
            outputIdentity(
                request: request,
                publication: publication,
                inputCount: 2
            ),
        ] {
            try expectPublicationFailure(
                mesh: mesh,
                identity: identity,
                provenance: validProvenance,
                request: request,
                publication: publication
            )
        }
    }

    @Test("[Unit][VOX-GEO-006][VOX-SEC-011] provenance coordinate and request binding fail closed")
    func rejectsInvalidProvenanceCoordinateAndLabelSet() throws {
        let request = try request()
        let publication = try publicationContext()
        let identity = try outputIdentity(
            request: request,
            publication: publication
        )
        let mesh = try emptyMesh(space: try sourceSpace(from: request.source))
        let otherObjectID = try #require(
            DataObjectID(rawValue: "other-label-surface")
        )
        let otherProvenanceID = try #require(
            ProvenanceID(rawValue: "other-label-surface-record")
        )
        let otherInstant = try CanonicalInstant(
            utcString: "2026-08-05T16:11:00Z"
        )
        let otherSoftware = try SoftwareIdentity(
            name: "Other Software",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
        let buildTaggedVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            buildMetadata: "unexpected"
        )
        let wrongDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )

        for provenance in try [
            outputProvenance(
                request: request,
                publication: publication,
                provenanceID: otherProvenanceID
            ),
            outputProvenance(
                request: request,
                publication: publication,
                subjectObjectID: otherObjectID
            ),
            outputProvenance(
                request: request,
                publication: publication,
                createdAt: otherInstant
            ),
            outputProvenance(
                request: request,
                publication: publication,
                software: otherSoftware
            ),
            outputProvenance(
                request: request,
                publication: publication,
                kind: .processed
            ),
            outputProvenance(
                request: request,
                publication: publication,
                inputRole: "other-source"
            ),
            outputProvenance(
                request: request,
                publication: publication,
                occurrence: 2
            ),
            outputProvenance(
                request: request,
                publication: publication,
                inputObjectID: DataObjectID(rawValue: "other-volume")
            ),
            outputProvenance(
                request: request,
                publication: publication,
                parentID: ProvenanceID(rawValue: "other-record")
            ),
            outputProvenance(
                request: request,
                publication: publication,
                operationID: "org.voxelia.op.other"
            ),
            outputProvenance(
                request: request,
                publication: publication,
                operationVersion: buildTaggedVersion
            ),
            outputProvenance(
                request: request,
                publication: publication,
                implementationID: "org.voxelia.impl.other.cpu"
            ),
            outputProvenance(
                request: request,
                publication: publication,
                implementationVersion: buildTaggedVersion
            ),
            outputProvenance(
                request: request,
                publication: publication,
                parameterDigest: wrongDigest
            ),
            outputProvenance(
                request: request,
                publication: publication,
                inputCount: 2
            ),
            outputProvenance(
                request: request,
                publication: publication,
                includeWarning: true
            ),
        ] {
            try expectPublicationFailure(
                mesh: mesh,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }

        try expectPublicationFailure(
            mesh: try emptyMesh(space: try coordinateSpace(id: "scanner")),
            identity: identity,
            provenance: try outputProvenance(
                request: request,
                publication: publication
            ),
            request: request,
            publication: publication
        )

        let missingGeometryRequest = LabelledSurfaceExtractionRequest(
            source: try sourceVolume(includeSpatialGeometry: false),
            selectedLabels: request.selectedLabels,
            limits: request.limits
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: try outputIdentity(
                request: missingGeometryRequest,
                publication: publication
            ),
            provenance: try outputProvenance(
                request: missingGeometryRequest,
                publication: publication
            ),
            request: missingGeometryRequest,
            publication: publication
        )

        let excessiveUnorderedLabels = ContiguousArray(
            repeating: UInt64.zero,
            count: 65_537
        )
        for invalidLabels in [
            LabelledSurfaceLabelSet.unsigned([]),
            .unsigned([1, 1]),
            .unsigned([2, 1]),
            .unsigned(excessiveUnorderedLabels),
        ] {
            let invalidRequest = LabelledSurfaceExtractionRequest(
                source: request.source,
                selectedLabels: invalidLabels,
                limits: request.limits
            )
            try expectPublicationFailure(
                mesh: mesh,
                identity: identity,
                provenance: try outputProvenance(
                    request: request,
                    publication: publication
                ),
                request: invalidRequest,
                publication: publication
            )
        }
    }

    private func request() throws -> LabelledSurfaceExtractionRequest {
        LabelledSurfaceExtractionRequest(
            source: try sourceVolume(),
            selectedLabels: .unsigned([1, 7]),
            limits: LabelledSurfaceExtractionLimits(
                maximumSelectedLabelCount: 2,
                maximumVertexCount: 1_024,
                maximumTriangleCount: 1_024
            )
        )
    }

    private func publicationContext()
        throws -> LabelledSurfaceExtractionPublicationContext
    {
        LabelledSurfaceExtractionPublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "label-surface-1")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "label-surface-record-1")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T16:10:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
        )
    }

    private func sourceVolume(
        includeSpatialGeometry: Bool = true
    ) throws -> ImageData {
        let shape = try ImageShape(extents: [2, 2, 2])
        let binding = try LogicalSampleBinding(
            shape: shape,
            scalarType: .uint8,
            componentCount: 1
        )
        let representation = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: .native,
            locality: .processLocalOwned
        )
        let storage = StubStorage(
            snapshot: try StorageSnapshotHandle.admit(
                binding: binding,
                representation: .decodedStrided(representation),
                owner: StorageOwner(),
                generation: 0
            )
        )
        let objectID = try #require(
            DataObjectID(rawValue: "label-source-volume-1")
        )
        let provenanceID = try #require(
            ProvenanceID(rawValue: "label-source-record-1")
        )
        let bytes = [UInt8](repeating: 0, count: binding.logicalByteCount)
        let software = try SoftwareIdentity(
            name: "Source Adapter",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
        let spatialGeometry: SpatialGeometry?
        if includeSpatialGeometry {
            spatialGeometry = .affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(
                        imageAxes: [0, 1, 2]
                    ),
                    indexToWorld: .identity,
                    coordinateSpace: try coordinateSpace(id: "patient")
                )
            )
        } else {
            spatialGeometry = nil
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
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
                semantic: .label,
                axes: [
                    try axis("x", semantic: .spatialX),
                    try axis("y", semantic: .spatialY),
                    try axis("z", semantic: .spatialZ),
                ],
                spatialGeometry: spatialGeometry,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(erasing: storage),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: provenanceID,
                kind: .source,
                createdAt: try CanonicalInstant(
                    utcString: "2026-08-05T16:00:00Z"
                ),
                subject: .object(objectID),
                software: software,
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: objectID,
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "test.source",
                        identifier: "label-volume-1",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func outputIdentity(
        request: LabelledSurfaceExtractionRequest,
        publication: LabelledSurfaceExtractionPublicationContext,
        objectID: DataObjectID? = nil,
        contentID: ContentID? = nil,
        sourceIdentities: ContiguousArray<SourceIdentity> = [],
        includeDerivation: Bool = true,
        operationID: String =
            LabelledSurfaceExtractionRequest.operationIdentifier,
        parameterDigest: ContentID? = nil,
        operationVersion: SemanticVersion? = nil,
        includeImplementation: Bool = true,
        implementationID: String =
            "org.voxelia.impl.labelled-surface-extraction.cpu",
        implementationVersion: SemanticVersion? = nil,
        inputRole: String = "source-volume",
        inputObjectID: DataObjectID? = nil,
        inputCount: Int = 1
    ) throws -> DataIdentity {
        guard includeDerivation else {
            return try DataIdentity(
                objectID: objectID ?? publication.outputObjectID,
                contentID: contentID,
                sourceIdentities: sourceIdentities,
                derivation: nil
            )
        }
        let version =
            try
            (operationVersion
            ?? SemanticVersion(major: 1, minor: 0, patch: 0))
        let digest =
            try
            (parameterDigest
            ?? LabelledSurfaceExtractionRequest.parameterDigest(
                for: request.selectedLabels
            ))
        let implementationVersion =
            try
            (implementationVersion
            ?? SemanticVersion(major: 1, minor: 0, patch: 0))
        let input = DerivationInput(
            role: try DerivationInputRole(rawValue: inputRole),
            identity: .object(
                inputObjectID ?? request.source.identity.objectID
            )
        )
        return try DataIdentity(
            objectID: objectID ?? publication.outputObjectID,
            contentID: contentID,
            sourceIdentities: sourceIdentities,
            derivation: try DerivationIdentity(
                operationID: try DerivationOperationToken(
                    rawValue: operationID
                ),
                operationVersion: version,
                implementation: includeImplementation
                    ? DerivationImplementationReference(
                        identifier: try DerivationOperationToken(
                            rawValue: implementationID
                        ),
                        version: implementationVersion
                    ) : nil,
                inputs: ContiguousArray(repeating: input, count: inputCount),
                parameterDigest: digest,
                declaresZeroInputGenerator: inputCount == 0
            )
        )
    }

    private func outputProvenance(
        request: LabelledSurfaceExtractionRequest,
        publication: LabelledSurfaceExtractionPublicationContext,
        provenanceID: ProvenanceID? = nil,
        subjectObjectID: DataObjectID? = nil,
        createdAt: CanonicalInstant? = nil,
        software: SoftwareIdentity? = nil,
        kind: ProvenanceKind = .transformed,
        inputRole: String = "source-volume",
        occurrence: UInt32 = 1,
        inputObjectID: DataObjectID? = nil,
        parentID: ProvenanceID? = nil,
        operationID: String =
            LabelledSurfaceExtractionRequest.operationIdentifier,
        operationVersion: SemanticVersion? = nil,
        implementationID: String =
            "org.voxelia.impl.labelled-surface-extraction.cpu",
        implementationVersion: SemanticVersion? = nil,
        parameterDigest: ContentID? = nil,
        inputCount: Int = 1,
        includeWarning: Bool = false
    ) throws -> ProvenanceRecord {
        let version =
            try
            (operationVersion
            ?? SemanticVersion(major: 1, minor: 0, patch: 0))
        let implementationVersion =
            try
            (implementationVersion
            ?? SemanticVersion(major: 1, minor: 0, patch: 0))
        let digest =
            try
            (parameterDigest
            ?? LabelledSurfaceExtractionRequest.parameterDigest(
                for: request.selectedLabels
            ))
        let executionVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )
        let operation = try OperationProvenance(
            operationID: try DerivationOperationToken(
                rawValue: operationID
            ),
            operationVersion: version,
            implementationID: try DerivationOperationToken(
                rawValue: implementationID
            ),
            implementationVersion: implementationVersion,
            parameterDigest: digest
        )
        let inputs = try ContiguousArray(
            (0..<inputCount).map { index in
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: inputRole),
                    occurrence: occurrence + UInt32(index),
                    identity: .object(
                        inputObjectID ?? request.source.identity.objectID
                    ),
                    parent: .graphNode(
                        parentID ?? request.source.provenance.id
                    )
                )
            }
        )
        let warnings: ContiguousArray<ProvenanceWarning> =
            includeWarning
            ? [try warning()] : []
        return try ProvenanceRecord(
            id: provenanceID ?? publication.outputProvenanceID,
            kind: kind,
            createdAt: createdAt ?? publication.createdAt,
            subject: .object(subjectObjectID ?? publication.outputObjectID),
            software: software ?? publication.software,
            activity: .operation(
                operation,
                try executionClaim(version: executionVersion)
            ),
            inputs: inputs,
            warnings: warnings,
            validationClaim: .unknown,
            declaresZeroInputGenerator: inputCount == 0
        )
    }

    private func warning() throws -> ProvenanceWarning {
        try ProvenanceWarning(
            code: ProvenanceWarningCode(
                rawValue: "org.voxelia.test-warning"
            ),
            schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
            severity: .informational,
            occurrenceCount: 1
        )
    }

    private func executionClaim(
        version: SemanticVersion
    ) throws -> ExecutionProvenanceClaim {
        ExecutionProvenanceClaim(
            profile: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.profile.default"
                ),
                version: version
            ),
            backend: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.backend.cpu"
                ),
                version: version
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
    }

    private func independentParameterDocument(
        for selectedLabels: LabelledSurfaceLabelSet
    ) throws -> [UInt8] {
        let namespace = "org.voxelia.op.labelled-surface-extraction"
        let domain: String
        let values: ContiguousArray<MetadataValue>
        switch selectedLabels {
        case .signed(let labels):
            domain = "signed-integer"
            values = ContiguousArray(labels.map(MetadataValue.signedInteger))
        case .unsigned(let labels):
            domain = "unsigned-integer"
            values = ContiguousArray(labels.map(MetadataValue.unsignedInteger))
        }
        return try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: try MetadataCollection(entries: [
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: namespace,
                        name: "algorithm-identifier"
                    ),
                    value: .string(
                        "freudenthal-label-set-surface/binary64-v1"
                    ),
                    privacyClass: .technical
                ),
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: namespace,
                        name: "label-domain"
                    ),
                    value: .string(domain),
                    privacyClass: .technical
                ),
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: namespace,
                        name: "selected-labels"
                    ),
                    value: .array(try MetadataArray(values: values)),
                    privacyClass: .technical
                ),
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: namespace,
                        name: "membership-rule"
                    ),
                    value: .string(
                        "exact-decoded-label-in-requested-set"
                    ),
                    privacyClass: .technical
                ),
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: namespace,
                        name: "adjacency-rule"
                    ),
                    value: .string("freudenthal-piecewise-linear"),
                    privacyClass: .technical
                ),
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: namespace,
                        name: "boundary-rule"
                    ),
                    value: .string("interior-cells-only"),
                    privacyClass: .technical
                ),
            ]),
            maximumOutputByteCount: 4_194_304
        )
    }

    private func independentParameterDigest(
        for selectedLabels: LabelledSurfaceLabelSet
    ) throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: independentParameterDocument(
                for: selectedLabels
            )
        )
    }

    private func expectPublicationFailure(
        mesh: TriangleMesh,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: LabelledSurfaceExtractionRequest,
        publication: LabelledSurfaceExtractionPublicationContext
    ) throws {
        #expect(throws: LabelledSurfaceExtractionError.publicationFailed) {
            try LabelledSurfaceExtractionResult(
                mesh: mesh,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }
    }

    private func emptyMesh(
        space: CoordinateSpaceDescriptor
    ) throws -> TriangleMesh {
        try TriangleMesh(
            positions: try TriangleMeshPositionDomain(
                coordinateSpace: space,
                components: []
            ),
            topology: try TriangleMeshTopology(vertexCount: 0, indices: []),
            vertexAttributes: []
        )
    }

    private func sourceSpace(
        from source: ImageData
    ) throws -> CoordinateSpaceDescriptor {
        switch source.descriptor.spatialGeometry {
        case .affine(let geometry):
            geometry.coordinateSpace
        default:
            throw FixtureError.missingAffineGeometry
        }
    }

    private func coordinateSpace(
        id: String
    ) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
    }

    private func axis(
        _ id: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}

    private enum FixtureError: Error {
        case missingAffineGeometry
    }
}
