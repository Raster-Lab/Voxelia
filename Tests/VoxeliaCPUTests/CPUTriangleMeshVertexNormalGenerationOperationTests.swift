// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU triangle-mesh vertex-normal publication")
struct CPUTriangleMeshVertexNormalGenerationOperationTests {
    @Test(
        "[Operation][VOX-GEO-009][VOX-META-003][VOX-META-006] public execution binds every fixed claim"
    )
    func executePublishesCompleteFixedClaims() async throws {
        let request = try self.request(mesh: sourceMesh())
        let publication = try publicationContext()
        let expectedVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )

        let result = try await CPUTriangleMeshVertexNormalGenerationOperation.execute(
            request: request,
            publication: publication
        )

        #expect(
            CPUTriangleMeshVertexNormalGenerationOperation
                .implementationIdentifier
                == "org.voxelia.impl.triangle-mesh-vertex-normal-generation.cpu"
        )
        #expect(
            result.mesh.positions.components.map(\.bitPattern)
                == request.source.positions.components.map(\.bitPattern)
        )
        #expect(result.mesh.positions.coordinateSpace == request.source.coordinateSpace)
        #expect(result.mesh.topology == request.source.topology)
        #expect(result.mesh.vertexAttributes.count == 2)
        #expect(
            result.mesh.vertexAttributes[0].descriptor
                == request.source.vertexAttributes[0].descriptor
        )
        #expect(
            result.mesh.vertexAttributes[0].bytes
                == request.source.vertexAttributes[0].bytes
        )
        #expect(
            bitPatterns(in: result.mesh.vertexAttributes[1].bytes)
                == [
                    0, 0, 0x3ff0_0000_0000_0000,
                    0, 0, 0x3ff0_0000_0000_0000,
                    0, 0, 0x3ff0_0000_0000_0000,
                ]
        )

        #expect(result.identity.objectID == publication.outputObjectID)
        #expect(result.identity.contentID == nil)
        #expect(result.identity.sourceIdentities.isEmpty)
        let derivation = try #require(result.identity.derivation)
        let implementation = try #require(derivation.implementation)
        #expect(
            derivation.operationID.rawValue
                == TriangleMeshVertexNormalGenerationRequest
                .operationIdentifier
        )
        #expect(derivation.operationVersion == expectedVersion)
        #expect(derivation.operationVersion.prerelease == nil)
        #expect(derivation.operationVersion.buildMetadata == nil)
        #expect(
            implementation.identifier.rawValue
                == CPUTriangleMeshVertexNormalGenerationOperation
                .implementationIdentifier
        )
        #expect(implementation.version == expectedVersion)
        #expect(implementation.version.prerelease == nil)
        #expect(implementation.version.buildMetadata == nil)
        #expect(derivation.inputs.count == 1)
        #expect(derivation.inputs[0].role.rawValue == "source-mesh")
        #expect(
            derivation.inputs[0].identity
                == .object(request.sourceIdentity.objectID)
        )
        let expectedDigest = try independentParameterDigest()
        #expect(derivation.parameterDigest == expectedDigest)
        #expect(
            derivation.parameterDigest.digest == [
                0x47, 0xec, 0x10, 0x65, 0x0d, 0xa9, 0x8d, 0x29,
                0x5f, 0x3f, 0x69, 0x6c, 0xaa, 0xdb, 0xc1, 0x91,
                0x1f, 0x32, 0x21, 0x4b, 0xbc, 0x8d, 0x28, 0xec,
                0x58, 0x21, 0x20, 0x93, 0x41, 0x82, 0x59, 0x2f,
            ]
        )

        #expect(result.provenance.id == publication.outputProvenanceID)
        #expect(result.provenance.kind == .transformed)
        #expect(result.provenance.createdAt == publication.createdAt)
        #expect(result.provenance.subject == .object(publication.outputObjectID))
        #expect(result.provenance.software == publication.software)
        #expect(result.provenance.inputs.count == 1)
        #expect(result.provenance.inputs[0].role.rawValue == "source-mesh")
        #expect(result.provenance.inputs[0].occurrence == 1)
        #expect(
            result.provenance.inputs[0].identity
                == .object(request.sourceIdentity.objectID)
        )
        #expect(
            result.provenance.inputs[0].parent
                == .graphNode(request.sourceProvenance.id)
        )
        #expect(result.provenance.warnings.isEmpty)
        #expect(result.provenance.validationClaim == .unknown)

        switch result.provenance.activity {
        case .origin:
            Issue.record("Expected operation provenance.")
        case .operation(let operation, let execution):
            #expect(operation.operationID == derivation.operationID)
            #expect(operation.operationVersion == expectedVersion)
            #expect(operation.operationVersion.prerelease == nil)
            #expect(operation.operationVersion.buildMetadata == nil)
            #expect(operation.implementationID == implementation.identifier)
            #expect(operation.implementationVersion == expectedVersion)
            #expect(operation.implementationVersion.prerelease == nil)
            #expect(operation.implementationVersion.buildMetadata == nil)
            #expect(operation.parameterDigest == derivation.parameterDigest)
            #expect(
                execution.profile.identifier.rawValue
                    == "org.voxelia.profile.default"
            )
            #expect(execution.profile.version == expectedVersion)
            #expect(
                execution.backend.identifier.rawValue
                    == CPUBackendRegistrations.backendIdentifier
            )
            #expect(execution.backend.version == expectedVersion)
            #expect(
                execution.precisionPolicy.rawValue
                    == "org.voxelia.precision.binary64-strict"
            )
            #expect(
                execution.qualityPolicy.rawValue
                    == "org.voxelia.quality.full"
            )
            #expect(execution.approximationStatus == .exact)
            #expect(execution.capabilityClass == nil)
            #expect(execution.kernel == nil)
        }

        let transferred = await Task.detached {
            (
                result.mesh.vertexAttributes.last?.bytes.count,
                result.identity.objectID,
                result.provenance.id
            )
        }.value
        #expect(transferred.0 == 72)
        #expect(transferred.1 == publication.outputObjectID)
        #expect(transferred.2 == publication.outputProvenanceID)
    }

    @Test("[Operation][VOX-GEO-009] an empty mesh publishes one coherent empty normal stream")
    func executePublishesEmptyMesh() async throws {
        let source = try mesh(positions: [], indices: [], attributes: [])
        let result = try await CPUTriangleMeshVertexNormalGenerationOperation.execute(
            request: try request(mesh: source),
            publication: publicationContext()
        )

        #expect(result.mesh.positions.components.isEmpty)
        #expect(result.mesh.topology.indices.isEmpty)
        #expect(result.mesh.vertexAttributes.count == 1)
        #expect(result.mesh.vertexAttributes[0].descriptor.semantic == .normal)
        #expect(result.mesh.vertexAttributes[0].descriptor.elementCount == 0)
        #expect(result.mesh.vertexAttributes[0].bytes.isEmpty)
        #expect(result.identity.derivation != nil)
        #expect(result.provenance.kind == .transformed)
    }

    @Test(
        "[Operation][VOX-CON-006][VOX-CON-007] task and final cancellation publish no aggregate"
    )
    func cancellationPublishesNothing() async throws {
        let request = try self.request(mesh: sourceMesh())
        let publication = try publicationContext()
        let cancelledTask = Task {
            while !Task.isCancelled {
                await Task.yield()
            }
            return try await CPUTriangleMeshVertexNormalGenerationOperation.execute(
                request: request,
                publication: publication
            )
        }
        cancelledTask.cancel()
        await #expect(
            throws: TriangleMeshVertexNormalGenerationError.cancelled
        ) {
            try await cancelledTask.value
        }

        #expect(throws: TriangleMeshVertexNormalGenerationError.cancelled) {
            try CPUTriangleMeshVertexNormalGenerationOperation.execute(
                request: request,
                publication: publication,
                cancellation: { $0 == .final }
            )
        }
    }

    @Test(
        "[Operation][VOX-ERR-001][VOX-SEC-011] kernel and publication failures remain atomic and payload-free"
    )
    func failuresPublishNothing() async throws {
        let isolated = try mesh(
            positions: [
                0, 0, 0,
                1, 0, 0,
                0, 1, 0,
                4, 4, 4,
            ],
            indices: [0, 1, 2],
            attributes: []
        )
        await #expect(
            throws: TriangleMeshVertexNormalGenerationError.undefinedNormal
        ) {
            try await CPUTriangleMeshVertexNormalGenerationOperation.execute(
                request: try request(mesh: isolated),
                publication: publicationContext()
            )
        }

        let sourceRequest = try self.request(mesh: sourceMesh())
        #expect(
            throws: TriangleMeshVertexNormalGenerationError.publicationFailed
        ) {
            try CPUTriangleMeshVertexNormalGenerationOperation.assembleResult(
                mesh: sourceRequest.source,
                request: sourceRequest,
                publication: publicationContext()
            )
        }
    }

    private func request(
        mesh: TriangleMesh
    ) throws -> TriangleMeshVertexNormalGenerationRequest {
        let identity = try sourceIdentity()
        return TriangleMeshVertexNormalGenerationRequest(
            source: mesh,
            sourceIdentity: identity,
            sourceProvenance: try sourceProvenance(
                subjectObjectID: identity.objectID
            ),
            limits: TriangleMeshVertexNormalGenerationLimits(
                maximumVertexCount: 10_000,
                maximumTriangleCount: 10_000,
                maximumExistingVertexAttributeCount: 10_000,
                maximumAdditionalLogicalByteCount: 1_000_000
            )
        )
    }

    private func sourceMesh() throws -> TriangleMesh {
        try mesh(
            positions: [-0.0, 0, 0, 2, 0, 0, 0, 3, 0],
            indices: [0, 1, 2],
            attributes: [try sourceAttribute(elementCount: 3)]
        )
    }

    private func mesh(
        positions: ContiguousArray<Double>,
        indices: ContiguousArray<UInt64>,
        attributes: ContiguousArray<TriangleMeshVertexAttribute>
    ) throws -> TriangleMesh {
        let positionDomain = try TriangleMeshPositionDomain(
            coordinateSpace: coordinateSpace(),
            components: positions
        )
        return try TriangleMesh(
            positions: positionDomain,
            topology: try TriangleMeshTopology(
                vertexCount: positionDomain.vertexCount,
                indices: indices
            ),
            vertexAttributes: attributes
        )
    }

    private func sourceAttribute(
        elementCount: Int
    ) throws -> TriangleMeshVertexAttribute {
        try TriangleMeshVertexAttribute(
            descriptor: try GeometryAttributeDescriptor(
                semantic: .custom(
                    namespace: "org.voxelia.normal.test",
                    name: "normal-source"
                ),
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
                elementCount: elementCount
            ),
            bytes: ContiguousArray(repeating: 7, count: elementCount)
        )
    }

    private func sourceIdentity() throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(
                DataObjectID(rawValue: "normal-operation-source")
            ),
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: [1, 2, 3]
            ),
            sourceIdentities: [],
            derivation: nil
        )
    }

    private func sourceProvenance(
        subjectObjectID: DataObjectID
    ) throws -> ProvenanceRecord {
        try ProvenanceRecord(
            id: try #require(
                ProvenanceID(rawValue: "normal-operation-source-record")
            ),
            kind: .source,
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T18:10:00Z"
            ),
            subject: .object(subjectObjectID),
            software: try SoftwareIdentity(
                name: "Voxelia Normal Operation Test Source",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: nil,
                buildIdentifier: nil
            ),
            activity: .origin,
            inputs: [],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    private func publicationContext()
        throws -> TriangleMeshVertexNormalGenerationPublicationContext
    {
        TriangleMeshVertexNormalGenerationPublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "normal-operation-output")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "normal-operation-output-record")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T18:20:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia CPU Tests",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
        )
    }

    private func coordinateSpace() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(
                CoordinateSpaceID(rawValue: "normal-operation-space")
            ),
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

    private func independentParameterDigest() throws -> ContentID {
        let namespace =
            "org.voxelia.op.triangle-mesh-vertex-normal-generation"
        let parameters = try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "algorithm-identifier"
                ),
                value: .string(
                    "triangle-area-weighted-vertex-normals/binary64-v1"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "weighting-rule"
                ),
                value: .string("oriented-doubled-area-vector"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "degenerate-face-rule"
                ),
                value: .string("zero-vector-contributes-nothing"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "accumulation-rule"
                ),
                value: .string(
                    "triangle-order-corner-order-component-order"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "normalization-rule"
                ),
                value: .string("maximum-component-scaled-euclidean"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "zero-component-rule"
                ),
                value: .string("positive-zero"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "output-attribute"
                ),
                value: .string(
                    "vertex-interleaved-float64-little-endian"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "existing-normal-rule"
                ),
                value: .string("reject"),
                privacyClass: .technical
            ),
        ])
        return try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: parameters,
                maximumOutputByteCount: 65_536
            )
        )
    }

    private func bitPatterns(
        in bytes: ContiguousArray<UInt8>
    ) -> [UInt64] {
        stride(from: 0, to: bytes.count, by: 8).map { offset in
            var value: UInt64 = 0
            for byteIndex in 0..<8 {
                value |=
                    UInt64(bytes[offset + byteIndex])
                    << UInt64(byteIndex * 8)
            }
            return value
        }
    }
}
