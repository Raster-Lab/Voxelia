// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaGeometry

@Suite("ScalarSurfaceExtraction")
struct ScalarSurfaceExtractionTests {
    private final class StorageOwner: Sendable {}

    private struct StubStorage: ImageStorageContract {
        let snapshot: StorageSnapshotHandle

        func read(region: ImageRegion) throws -> RegionReadResult {
            throw StorageContractError.providerFailure
        }
    }

    @Test("[Unit][VOX-API-003][VOX-GEO-007] declarations preserve exact caller inputs")
    func declarationsPreserveInputsAndTransferSafely() async throws {
        let source = try sourceVolume()
        let limits = ScalarSurfaceExtractionLimits(
            maximumVertexCount: 0,
            maximumTriangleCount: UInt64.max
        )
        let request = ScalarSurfaceExtractionRequest(
            source: source,
            isovalue: .nan,
            limits: limits
        )
        let publication = try publicationContext()

        #expect(
            ScalarSurfaceExtractionRequest.operationIdentifier
                == "org.voxelia.op.scalar-surface-extraction"
        )
        #expect(
            ScalarSurfaceExtractionRequest.algorithmIdentifier
                == "freudenthal-surface-extraction/binary64-v1"
        )
        #expect(request.source.identity.objectID == source.identity.objectID)
        #expect(request.isovalue.isNaN)
        #expect(request.limits.maximumVertexCount == 0)
        #expect(request.limits.maximumTriangleCount == UInt64.max)
        #expect(publication.outputObjectID.rawValue == "surface-1")
        #expect(publication.outputProvenanceID.rawValue == "surface-record-1")
        #expect(publication.createdAt.utcString == "2026-08-05T14:45:00Z")
        #expect(publication.software.name == "Voxelia")

        requireSendable(ScalarSurfaceExtractionError.self)
        requireSendable(ScalarSurfaceExtractionLimits.self)
        requireSendable(ScalarSurfaceExtractionRequest.self)
        requireSendable(ScalarSurfaceExtractionPublicationContext.self)
        requireSendable(ScalarSurfaceExtractionResult.self)

        let transferred = await Task.detached {
            (
                request.limits.maximumVertexCount,
                request.limits.maximumTriangleCount,
                publication.outputObjectID
            )
        }.value
        #expect(transferred.0 == 0)
        #expect(transferred.1 == UInt64.max)
        #expect(transferred.2 == publication.outputObjectID)

        #expect(
            ScalarSurfaceExtractionError.publicationFailed
                == .publicationFailed
        )
    }

    @Test("[Unit][VOX-META-003][VOX-META-005] parameter digest binds only the frozen schema")
    func parameterDigestBindsFrozenSchema() throws {
        let value = 42.5
        let digest = try ScalarSurfaceExtractionRequest.parameterDigest(
            for: value
        )
        #expect(
            digest.digest == [
                0xf1, 0x00, 0xa4, 0xe6, 0xc1, 0xc7, 0x26, 0x2b,
                0xd1, 0x9c, 0x09, 0x3c, 0xe9, 0x08, 0xd2, 0xad,
                0x39, 0xd6, 0x97, 0x22, 0x9b, 0x2b, 0x8f, 0xc1,
                0x99, 0x80, 0x79, 0xa2, 0x2b, 0x08, 0xf3, 0x3e,
            ]
        )
        #expect(digest == (try independentParameterDigest(for: value)))
        #expect(
            digest
                != (try ScalarSurfaceExtractionRequest.parameterDigest(
                    for: 42.500_000_000_000_01
                ))
        )
        #expect(
            try ScalarSurfaceExtractionRequest.parameterDigest(for: -0.0)
                == ScalarSurfaceExtractionRequest.parameterDigest(for: 0.0)
        )
        #expect(throws: MetadataFloatingPointError.nonFiniteValue) {
            try ScalarSurfaceExtractionRequest.parameterDigest(for: .infinity)
        }

        // Limits and publication authority are deliberately absent from the
        // fixed parameter helper; changing them cannot change this digest.
        let firstRequest = ScalarSurfaceExtractionRequest(
            source: try sourceVolume(),
            isovalue: value,
            limits: ScalarSurfaceExtractionLimits(
                maximumVertexCount: 1,
                maximumTriangleCount: 1
            )
        )
        let secondRequest = ScalarSurfaceExtractionRequest(
            source: firstRequest.source,
            isovalue: value,
            limits: ScalarSurfaceExtractionLimits(
                maximumVertexCount: UInt64.max,
                maximumTriangleCount: UInt64.max
            )
        )
        #expect(
            try ScalarSurfaceExtractionRequest.parameterDigest(
                for: firstRequest.isovalue
            )
                == ScalarSurfaceExtractionRequest.parameterDigest(
                    for: secondRequest.isovalue
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

        let result = try ScalarSurfaceExtractionResult(
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

        let wrongPublication = ScalarSurfaceExtractionPublicationContext(
            outputObjectID: try #require(DataObjectID(rawValue: "surface-2")),
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

        let wrongOutputIdentity = try outputIdentity(
            request: request,
            publication: publication,
            objectID: DataObjectID(rawValue: "surface-2")
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: wrongOutputIdentity,
            provenance: validProvenance,
            request: request,
            publication: publication
        )

        let contentBearing = try outputIdentity(
            request: request,
            publication: publication,
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: [0]
            )
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: contentBearing,
            provenance: validProvenance,
            request: request,
            publication: publication
        )

        let sourceBearing = try outputIdentity(
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
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: sourceBearing,
            provenance: validProvenance,
            request: request,
            publication: publication
        )

        let missingDerivation = try outputIdentity(
            request: request,
            publication: publication,
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: [0]
            ),
            includeDerivation: false
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: missingDerivation,
            provenance: validProvenance,
            request: request,
            publication: publication
        )

        let wrongDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )
        let wrongRecipe = try outputIdentity(
            request: request,
            publication: publication,
            parameterDigest: wrongDigest
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: wrongRecipe,
            provenance: validProvenance,
            request: request,
            publication: publication
        )

        let buildTaggedVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            buildMetadata: "unexpected"
        )
        let inexactOperationVersion = try outputIdentity(
            request: request,
            publication: publication,
            operationVersion: buildTaggedVersion
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: inexactOperationVersion,
            provenance: validProvenance,
            request: request,
            publication: publication
        )

        let wrongInput = try outputIdentity(
            request: request,
            publication: publication,
            inputObjectID: DataObjectID(rawValue: "other-volume")
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: wrongInput,
            provenance: validProvenance,
            request: request,
            publication: publication
        )

        for identity in try [
            outputIdentity(
                request: request,
                publication: publication,
                operationID: "org.voxelia.op.other"
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

    @Test("[Unit][VOX-GEO-006][VOX-SEC-011] provenance and coordinate binding fail closed")
    func rejectsInvalidProvenanceAndCoordinateSpace() throws {
        let request = try request()
        let publication = try publicationContext()
        let identity = try outputIdentity(
            request: request,
            publication: publication
        )
        let mesh = try emptyMesh(space: try sourceSpace(from: request.source))
        let otherObjectID = try #require(
            DataObjectID(rawValue: "other-surface")
        )
        let otherProvenanceID = try #require(
            ProvenanceID(rawValue: "other-surface-record")
        )
        let otherInstant = try CanonicalInstant(
            utcString: "2026-08-05T14:46:00Z"
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
                implementationID: "org.voxelia.impl.other.cpu"
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

        let wrongSpaceMesh = try emptyMesh(space: try coordinateSpace(id: "scanner"))
        try expectPublicationFailure(
            mesh: wrongSpaceMesh,
            identity: identity,
            provenance: try outputProvenance(
                request: request,
                publication: publication
            ),
            request: request,
            publication: publication
        )

        let nonFiniteRequest = ScalarSurfaceExtractionRequest(
            source: request.source,
            isovalue: .nan,
            limits: request.limits
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: identity,
            provenance: try outputProvenance(
                request: request,
                publication: publication
            ),
            request: nonFiniteRequest,
            publication: publication
        )
    }

    private func request() throws -> ScalarSurfaceExtractionRequest {
        ScalarSurfaceExtractionRequest(
            source: try sourceVolume(),
            isovalue: 0.5,
            limits: ScalarSurfaceExtractionLimits(
                maximumVertexCount: 1_024,
                maximumTriangleCount: 1_024
            )
        )
    }

    private func publicationContext()
        throws -> ScalarSurfaceExtractionPublicationContext
    {
        ScalarSurfaceExtractionPublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "surface-1")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "surface-record-1")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T14:45:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
        )
    }

    private func sourceVolume() throws -> ImageData {
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
        let objectID = try #require(DataObjectID(rawValue: "source-volume-1"))
        let provenanceID = try #require(
            ProvenanceID(rawValue: "source-record-1")
        )
        let bytes = [UInt8](repeating: 0, count: binding.logicalByteCount)
        let software = try SoftwareIdentity(
            name: "Source Adapter",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
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
                semantic: .intensity,
                axes: [
                    try axis("x", semantic: .spatialX),
                    try axis("y", semantic: .spatialY),
                    try axis("z", semantic: .spatialZ),
                ],
                spatialGeometry: .affine(
                    try AffineGridGeometry(
                        spatialAxes: try SpatialAxisMapping(
                            imageAxes: [0, 1, 2]
                        ),
                        indexToWorld: .identity,
                        coordinateSpace: try coordinateSpace(id: "patient")
                    )
                ),
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(erasing: storage),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: provenanceID,
                kind: .source,
                createdAt: try CanonicalInstant(
                    utcString: "2026-08-05T14:40:00Z"
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
                        identifier: "volume-1",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func outputIdentity(
        request: ScalarSurfaceExtractionRequest,
        publication: ScalarSurfaceExtractionPublicationContext,
        objectID: DataObjectID? = nil,
        contentID: ContentID? = nil,
        sourceIdentities: ContiguousArray<SourceIdentity> = [],
        includeDerivation: Bool = true,
        operationID: String =
            ScalarSurfaceExtractionRequest.operationIdentifier,
        parameterDigest: ContentID? = nil,
        operationVersion: SemanticVersion? = nil,
        includeImplementation: Bool = true,
        implementationID: String =
            "org.voxelia.impl.scalar-surface-extraction.cpu",
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
            ?? ScalarSurfaceExtractionRequest.parameterDigest(
                for: request.isovalue
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
        request: ScalarSurfaceExtractionRequest,
        publication: ScalarSurfaceExtractionPublicationContext,
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
            ScalarSurfaceExtractionRequest.operationIdentifier,
        operationVersion: SemanticVersion? = nil,
        implementationID: String =
            "org.voxelia.impl.scalar-surface-extraction.cpu",
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
            ?? ScalarSurfaceExtractionRequest.parameterDigest(
                for: request.isovalue
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

    private func independentParameterDigest(for isovalue: Double) throws -> ContentID {
        let namespace = "org.voxelia.op.scalar-surface-extraction"
        return try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: [
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: namespace,
                            name: "algorithm-identifier"
                        ),
                        value: .string(
                            "freudenthal-surface-extraction/binary64-v1"
                        ),
                        privacyClass: .technical
                    ),
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: namespace,
                            name: "isovalue"
                        ),
                        value: .floatingPoint(
                            try MetadataFloatingPoint(value: isovalue)
                        ),
                        privacyClass: .technical
                    ),
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: namespace,
                            name: "inside-rule"
                        ),
                        value: .string("sample-greater-than-or-equal"),
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
                maximumOutputByteCount: 65_536
            )
        )
    }

    private func expectPublicationFailure(
        mesh: TriangleMesh,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: ScalarSurfaceExtractionRequest,
        publication: ScalarSurfaceExtractionPublicationContext
    ) throws {
        #expect(throws: ScalarSurfaceExtractionError.publicationFailed) {
            try ScalarSurfaceExtractionResult(
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
