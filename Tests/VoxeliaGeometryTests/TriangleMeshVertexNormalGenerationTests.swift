// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaGeometry

@Suite("TriangleMeshVertexNormalGeneration")
struct TriangleMeshVertexNormalGenerationTests {
    @Test(
        "[Unit][VOX-API-003][VOX-GEO-009] declarations preserve unadmitted inputs and transfer safely"
    )
    func declarationsPreserveInputsAndTransferSafely() async throws {
        let source = try sourceMesh()
        let sourceIdentity = try sourceIdentity()
        let mismatchedProvenance = try sourceProvenance(
            subjectObjectID: try DataObjectID(validating: "unmatched-source")
        )
        let limits = TriangleMeshVertexNormalGenerationLimits(
            maximumVertexCount: 0,
            maximumTriangleCount: UInt64.max,
            maximumExistingVertexAttributeCount: 0,
            maximumAdditionalLogicalByteCount: UInt64.max
        )
        let request = TriangleMeshVertexNormalGenerationRequest(
            source: source,
            sourceIdentity: sourceIdentity,
            sourceProvenance: mismatchedProvenance,
            limits: limits
        )
        let publication = try publicationContext()

        #expect(
            TriangleMeshVertexNormalGenerationRequest.operationIdentifier
                == "org.voxelia.op.triangle-mesh-vertex-normal-generation"
        )
        #expect(
            TriangleMeshVertexNormalGenerationRequest.algorithmIdentifier
                == "triangle-area-weighted-vertex-normals/binary64-v1"
        )
        #expect(request.source.positions.components[0].bitPattern == (-0.0).bitPattern)
        #expect(request.sourceIdentity == sourceIdentity)
        #expect(request.sourceProvenance == mismatchedProvenance)
        #expect(request.limits.maximumVertexCount == 0)
        #expect(request.limits.maximumTriangleCount == UInt64.max)
        #expect(request.limits.maximumExistingVertexAttributeCount == 0)
        #expect(request.limits.maximumAdditionalLogicalByteCount == UInt64.max)
        #expect(publication.outputObjectID.rawValue == "normal-mesh-1")
        #expect(publication.outputProvenanceID.rawValue == "normal-mesh-record-1")
        #expect(publication.createdAt.utcString == "2026-08-05T17:40:00Z")

        requireSendable(TriangleMeshVertexNormalGenerationError.self)
        requireSendable(TriangleMeshVertexNormalGenerationLimits.self)
        requireSendable(TriangleMeshVertexNormalGenerationRequest.self)
        requireSendable(
            TriangleMeshVertexNormalGenerationPublicationContext.self
        )
        requireSendable(TriangleMeshVertexNormalGenerationResult.self)

        let transferred = await Task.detached {
            (
                request.source.positions.components[0].bitPattern,
                request.sourceIdentity.objectID,
                request.limits.maximumTriangleCount,
                publication.outputObjectID
            )
        }.value
        #expect(transferred.0 == (-0.0).bitPattern)
        #expect(transferred.1 == sourceIdentity.objectID)
        #expect(transferred.2 == UInt64.max)
        #expect(transferred.3 == publication.outputObjectID)

        let errors: [TriangleMeshVertexNormalGenerationError] = [
            .invalidLimits,
            .invalidSource,
            .normalAlreadyPresent,
            .resourceLimitExceeded,
            .normalNotRepresentable,
            .undefinedNormal,
            .cancelled,
            .publicationFailed,
        ]
        let expectedNames = [
            "invalidLimits",
            "invalidSource",
            "normalAlreadyPresent",
            "resourceLimitExceeded",
            "normalNotRepresentable",
            "undefinedNormal",
            "cancelled",
            "publicationFailed",
        ]
        #expect(errors.map { String(describing: $0) } == expectedNames)
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    @Test("[Unit][VOX-META-004][VOX-META-005] parameter digest binds the eight fixed rules")
    func parameterDigestBindsFrozenSchema() throws {
        let document =
            try TriangleMeshVertexNormalGenerationRequest
            .parameterDocument()
        let digest =
            try TriangleMeshVertexNormalGenerationRequest
            .parameterDigest()

        #expect(document == (try independentParameterDocument()))
        #expect(document.count == 1_631)
        #expect(
            TriangleMeshVertexNormalGenerationRequest
                .parameterDocumentMaximumOutputByteCount == 65_536
        )
        #expect(digest == (try independentParameterDigest()))
        #expect(
            digest.digest == [
                0x47, 0xec, 0x10, 0x65, 0x0d, 0xa9, 0x8d, 0x29,
                0x5f, 0x3f, 0x69, 0x6c, 0xaa, 0xdb, 0xc1, 0x91,
                0x1f, 0x32, 0x21, 0x4b, 0xbc, 0x8d, 0x28, 0xec,
                0x58, 0x21, 0x20, 0x93, 0x41, 0x82, 0x59, 0x2f,
            ]
        )

        let text = String(decoding: document, as: UTF8.self)
        #expect(!text.contains("normal-source-mesh-1"))
        #expect(!text.contains("normal-source-record-1"))
        #expect(!text.contains("normal-mesh-1"))
        #expect(!text.contains("maximumVertexCount"))
        #expect(!text.contains("Voxelia Test Publisher"))

        let first = try request(
            limits: TriangleMeshVertexNormalGenerationLimits(
                maximumVertexCount: 1,
                maximumTriangleCount: 1,
                maximumExistingVertexAttributeCount: 1,
                maximumAdditionalLogicalByteCount: 1
            )
        )
        let second = try request(
            limits: TriangleMeshVertexNormalGenerationLimits(
                maximumVertexCount: UInt64.max,
                maximumTriangleCount: UInt64.max,
                maximumExistingVertexAttributeCount: UInt64.max,
                maximumAdditionalLogicalByteCount: UInt64.max
            )
        )
        #expect(first.limits.maximumVertexCount != second.limits.maximumVertexCount)
        #expect(
            try TriangleMeshVertexNormalGenerationRequest.parameterDigest()
                == TriangleMeshVertexNormalGenerationRequest.parameterDigest()
        )
    }

    @Test(
        "[Unit][VOX-GEO-006][VOX-GEO-009] coherent result preserves source and appends exact normals"
    )
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
        let mesh = try outputMesh(for: request.source)

        let result = try TriangleMeshVertexNormalGenerationResult(
            mesh: mesh,
            identity: identity,
            provenance: provenance,
            request: request,
            publication: publication
        )
        #expect(result.identity == identity)
        #expect(result.provenance == provenance)
        #expect(result.identity.contentID == nil)
        #expect(result.identity.sourceIdentities.isEmpty)
        #expect(result.mesh.vertexAttributes.count == 3)
        #expect(result.mesh.vertexAttributes.last?.descriptor.semantic == .normal)
        #expect(result.mesh.vertexAttributes.last?.bytes.count == 72)
        #expect(
            result.mesh.positions.components[0].bitPattern
                == request.source.positions.components[0].bitPattern
        )

        let transferred = await Task.detached {
            (
                result.mesh.topology.triangleCount,
                result.identity.objectID,
                result.provenance.id
            )
        }.value
        #expect(transferred.0 == 1)
        #expect(transferred.1 == publication.outputObjectID)
        #expect(transferred.2 == publication.outputProvenanceID)

        // Result binding is structural and deliberately does not authenticate
        // execution by re-evaluating normal bytes.
        let publishedNormal = try #require(mesh.vertexAttributes.last)
        var alteredNormalBytes = publishedNormal.bytes
        alteredNormalBytes[0] ^= 0xff
        let alteredNormal = try TriangleMeshVertexAttribute(
            descriptor: publishedNormal.descriptor,
            bytes: alteredNormalBytes
        )
        let structurallyValid = try meshReplacingAttributes(
            mesh,
            with: request.source.vertexAttributes + [alteredNormal]
        )
        _ = try TriangleMeshVertexNormalGenerationResult(
            mesh: structurallyValid,
            identity: identity,
            provenance: provenance,
            request: request,
            publication: publication
        )

        // The Geometry result is backend-neutral: it binds implementation
        // correspondence without fixing the future CPU token or trusting an
        // execution claim as evidence.
        let alternateIdentity = try outputIdentity(
            request: request,
            publication: publication,
            implementationID: "org.voxelia.impl.normal-generation.reference"
        )
        let alternateProvenance = try outputProvenance(
            request: request,
            publication: publication,
            implementationID: "org.voxelia.impl.normal-generation.reference",
            executionBackend: "org.voxelia.backend.reference"
        )
        _ = try TriangleMeshVertexNormalGenerationResult(
            mesh: mesh,
            identity: alternateIdentity,
            provenance: alternateProvenance,
            request: request,
            publication: publication
        )
    }

    @Test("[Unit][VOX-ERR-001][VOX-META-003] source and identity binding fail payload-free")
    func rejectsInvalidSourceAuthorityAndIdentity() throws {
        let request = try request()
        let publication = try publicationContext()
        let mesh = try outputMesh(for: request.source)
        let validIdentity = try outputIdentity(
            request: request,
            publication: publication
        )
        let validProvenance = try outputProvenance(
            request: request,
            publication: publication
        )
        let otherObjectID = try #require(
            DataObjectID(rawValue: "other-normal-mesh")
        )
        let buildTaggedVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            buildMetadata: "unexpected"
        )
        let wrongDigest = try emptyParameterDigest()

        let wrongPublication =
            TriangleMeshVertexNormalGenerationPublicationContext(
                outputObjectID: otherObjectID,
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

        let mismatchedRequest = TriangleMeshVertexNormalGenerationRequest(
            source: request.source,
            sourceIdentity: request.sourceIdentity,
            sourceProvenance: try sourceProvenance(
                subjectObjectID: otherObjectID
            ),
            limits: request.limits
        )
        try expectPublicationFailure(
            mesh: mesh,
            identity: validIdentity,
            provenance: validProvenance,
            request: mismatchedRequest,
            publication: publication
        )

        for identity in try [
            outputIdentity(
                request: request,
                publication: publication,
                objectID: otherObjectID
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
                operationVersion: buildTaggedVersion
            ),
            outputIdentity(
                request: request,
                publication: publication,
                parameterDigest: wrongDigest
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
                inputObjectID: otherObjectID
            ),
            outputIdentity(
                request: request,
                publication: publication,
                inputCount: 0
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

    @Test("[Unit][VOX-META-003][VOX-SEC-011] provenance binding rejects every crossed claim")
    func rejectsInvalidProvenance() throws {
        let request = try request()
        let publication = try publicationContext()
        let mesh = try outputMesh(for: request.source)
        let identity = try outputIdentity(
            request: request,
            publication: publication
        )
        let otherObjectID = try #require(
            DataObjectID(rawValue: "other-normal-mesh")
        )
        let otherProvenanceID = try #require(
            ProvenanceID(rawValue: "other-normal-record")
        )
        let otherInstant = try CanonicalInstant(
            utcString: "2026-08-05T17:41:00Z"
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
        let wrongDigest = try emptyParameterDigest()

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
                inputObjectID: otherObjectID
            ),
            outputProvenance(
                request: request,
                publication: publication,
                parentID: otherProvenanceID
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
                inputCount: 0
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
    }

    @Test("[Unit][VOX-GEO-003][VOX-GEO-006] source mesh preservation is bit and byte exact")
    func rejectsChangedSourceMeshDomains() throws {
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
        let validMesh = try outputMesh(for: request.source)

        var positiveZeroPositions = request.source.positions.components
        positiveZeroPositions[0] = 0.0
        var changedPosition = request.source.positions.components
        changedPosition[3] = 2.0
        let changedSpace = try coordinateSpace(id: "other-space")
        let reversedTopology = try TriangleMeshTopology(
            vertexCount: 3,
            indices: [0, 2, 1]
        )
        var changedSourceBytes = request.source.vertexAttributes[0].bytes
        changedSourceBytes[0] ^= 0xff
        let changedSourceAttribute = try TriangleMeshVertexAttribute(
            descriptor: request.source.vertexAttributes[0].descriptor,
            bytes: changedSourceBytes
        )
        let normal = try #require(validMesh.vertexAttributes.last)

        let meshes = try [
            mesh(
                positions: positiveZeroPositions,
                coordinateSpace: request.source.coordinateSpace,
                topology: request.source.topology,
                attributes: request.source.vertexAttributes + [normal]
            ),
            mesh(
                positions: changedPosition,
                coordinateSpace: request.source.coordinateSpace,
                topology: request.source.topology,
                attributes: request.source.vertexAttributes + [normal]
            ),
            mesh(
                positions: request.source.positions.components,
                coordinateSpace: changedSpace,
                topology: request.source.topology,
                attributes: request.source.vertexAttributes + [normal]
            ),
            mesh(
                positions: request.source.positions.components,
                coordinateSpace: request.source.coordinateSpace,
                topology: reversedTopology,
                attributes: request.source.vertexAttributes + [normal]
            ),
            meshReplacingAttributes(
                validMesh,
                with: [
                    changedSourceAttribute,
                    request.source.vertexAttributes[1],
                    normal,
                ]
            ),
            meshReplacingAttributes(
                validMesh,
                with: [
                    request.source.vertexAttributes[1],
                    request.source.vertexAttributes[0],
                    normal,
                ]
            ),
            meshReplacingAttributes(validMesh, with: [normal]),
        ]

        for mesh in meshes {
            try expectPublicationFailure(
                mesh: mesh,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }

        try rejectUTF8EquivalentSourceAttribute(
            replacing: 0,
            semantic: .custom(namespace: "org.voxelia.mésh", name: "wéight"),
            interpretation: .generic(
                namespace: "org.voxelia.géneric",
                name: "véctor"
            ),
            componentNames: ["vé"]
        )
        try rejectUTF8EquivalentSourceAttribute(
            replacing: 0,
            semantic: request.source.vertexAttributes[0].descriptor.semantic,
            interpretation: .generic(
                namespace: "org.voxelia.géneric",
                name: "véctor"
            ),
            componentNames: ["vé"]
        )
        try rejectUTF8EquivalentSourceAttribute(
            replacing: 0,
            semantic: request.source.vertexAttributes[0].descriptor.semantic,
            interpretation: request.source.vertexAttributes[0]
                .descriptor.components.interpretation,
            componentNames: ["vé"]
        )
    }

    @Test("[Unit][VOX-GEO-004][VOX-GEO-009] final normal descriptor fails closed")
    func rejectsInvalidFinalNormalAttribute() throws {
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
        let validMesh = try outputMesh(for: request.source)
        let validNormal = try #require(validMesh.vertexAttributes.last)

        let invalidNormals = try [
            attribute(
                semantic: .tangent,
                scalarType: .float64,
                validBitCount: nil,
                byteOrder: .littleEndian,
                componentCount: 3,
                interpretation: .vector,
                layout: .interleaved,
                names: nil
            ),
            attribute(
                semantic: .normal,
                scalarType: .float32,
                validBitCount: nil,
                byteOrder: .littleEndian,
                componentCount: 3,
                interpretation: .vector,
                layout: .interleaved,
                names: nil
            ),
            attribute(
                semantic: .normal,
                scalarType: .float64,
                validBitCount: 63,
                byteOrder: .littleEndian,
                componentCount: 3,
                interpretation: .vector,
                layout: .interleaved,
                names: nil
            ),
            attribute(
                semantic: .normal,
                scalarType: .float64,
                validBitCount: nil,
                byteOrder: .bigEndian,
                componentCount: 3,
                interpretation: .vector,
                layout: .interleaved,
                names: nil
            ),
            attribute(
                semantic: .normal,
                scalarType: .float64,
                validBitCount: nil,
                byteOrder: .littleEndian,
                componentCount: 2,
                interpretation: .vector,
                layout: .interleaved,
                names: nil
            ),
            attribute(
                semantic: .normal,
                scalarType: .float64,
                validBitCount: nil,
                byteOrder: .littleEndian,
                componentCount: 3,
                interpretation: .scalar,
                layout: .interleaved,
                names: nil
            ),
            attribute(
                semantic: .normal,
                scalarType: .float64,
                validBitCount: nil,
                byteOrder: .littleEndian,
                componentCount: 3,
                interpretation: .vector,
                layout: .planar,
                names: nil
            ),
            attribute(
                semantic: .normal,
                scalarType: .float64,
                validBitCount: nil,
                byteOrder: .littleEndian,
                componentCount: 3,
                interpretation: .vector,
                layout: .interleaved,
                names: ["x", "y", "z"]
            ),
        ]

        for invalidNormal in invalidNormals {
            let mesh = try meshReplacingAttributes(
                validMesh,
                with: request.source.vertexAttributes + [invalidNormal]
            )
            try expectPublicationFailure(
                mesh: mesh,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }

        let unexpected = try attribute(
            semantic: .confidence,
            scalarType: .uint8,
            validBitCount: nil,
            byteOrder: .native,
            componentCount: 1,
            interpretation: .scalar,
            layout: .interleaved,
            names: nil
        )
        let invalidAttributeCollections: [ContiguousArray<TriangleMeshVertexAttribute>] = [
            request.source.vertexAttributes,
            ContiguousArray([
                request.source.vertexAttributes[0],
                validNormal,
                request.source.vertexAttributes[1],
            ]),
            request.source.vertexAttributes + [unexpected, validNormal],
            request.source.vertexAttributes + [validNormal, unexpected],
        ]
        for attributes in invalidAttributeCollections {
            try expectPublicationFailure(
                mesh: try meshReplacingAttributes(validMesh, with: attributes),
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }
    }

    private func request(
        limits: TriangleMeshVertexNormalGenerationLimits =
            TriangleMeshVertexNormalGenerationLimits(
                maximumVertexCount: 1_024,
                maximumTriangleCount: 1_024,
                maximumExistingVertexAttributeCount: 16,
                maximumAdditionalLogicalByteCount: 1_048_576
            )
    ) throws -> TriangleMeshVertexNormalGenerationRequest {
        TriangleMeshVertexNormalGenerationRequest(
            source: try sourceMesh(),
            sourceIdentity: try sourceIdentity(),
            sourceProvenance: try sourceProvenance(),
            limits: limits
        )
    }

    private func publicationContext()
        throws -> TriangleMeshVertexNormalGenerationPublicationContext
    {
        TriangleMeshVertexNormalGenerationPublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "normal-mesh-1")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "normal-mesh-record-1")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T17:40:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia Test Publisher",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
        )
    }

    private func sourceMesh() throws -> TriangleMesh {
        let first = try TriangleMeshVertexAttribute(
            descriptor: try GeometryAttributeDescriptor(
                semantic: .custom(
                    namespace: "org.voxelia.mésh",
                    name: "wéight"
                ),
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .generic(
                        namespace: "org.voxelia.géneric",
                        name: "véctor"
                    ),
                    layout: .interleaved,
                    componentNames: ["vé"]
                ),
                elementCount: 3
            ),
            bytes: [1, 2, 3]
        )
        let second = try TriangleMeshVertexAttribute(
            descriptor: try GeometryAttributeDescriptor(
                semantic: .scalarValue,
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
                elementCount: 3
            ),
            bytes: [4, 5, 6]
        )
        return try mesh(
            positions: [-0.0, 0, 0, 1, 0, 0, 0, 1, 0],
            coordinateSpace: try coordinateSpace(id: "mesh-space"),
            topology: try TriangleMeshTopology(
                vertexCount: 3,
                indices: [0, 1, 2]
            ),
            attributes: [first, second]
        )
    }

    private func outputMesh(for source: TriangleMesh) throws -> TriangleMesh {
        try meshReplacingAttributes(
            source,
            with: source.vertexAttributes + [try normalAttribute()]
        )
    }

    private func normalAttribute() throws -> TriangleMeshVertexAttribute {
        let normalBits: [UInt64] = [
            0, 0, 0x3ff0_0000_0000_0000,
            0, 0, 0x3ff0_0000_0000_0000,
            0, 0, 0x3ff0_0000_0000_0000,
        ]
        var bytes: ContiguousArray<UInt8> = []
        bytes.reserveCapacity(normalBits.count * 8)
        for bitPattern in normalBits {
            for byteIndex in 0..<8 {
                bytes.append(
                    UInt8(
                        truncatingIfNeeded: bitPattern
                            >> UInt64(byteIndex * 8)
                    )
                )
            }
        }
        return try TriangleMeshVertexAttribute(
            descriptor: try GeometryAttributeDescriptor(
                semantic: .normal,
                scalarFormat: try ScalarFormat(
                    type: .float64,
                    validBitCount: nil,
                    byteOrder: .littleEndian
                ),
                components: try ComponentDescriptor(
                    count: 3,
                    interpretation: .vector,
                    layout: .interleaved,
                    componentNames: nil
                ),
                elementCount: 3
            ),
            bytes: bytes
        )
    }

    private func attribute(
        semantic: GeometryAttributeSemantic,
        scalarType: ScalarType,
        validBitCount: Int?,
        byteOrder: ByteOrder,
        componentCount: Int,
        interpretation: ComponentInterpretation,
        layout: ComponentLayout,
        names: ContiguousArray<String>?
    ) throws -> TriangleMeshVertexAttribute {
        let scalarFormat = try ScalarFormat(
            type: scalarType,
            validBitCount: validBitCount,
            byteOrder: byteOrder
        )
        let descriptor = try GeometryAttributeDescriptor(
            semantic: semantic,
            scalarFormat: scalarFormat,
            components: try ComponentDescriptor(
                count: componentCount,
                interpretation: interpretation,
                layout: layout,
                componentNames: names
            ),
            elementCount: 3
        )
        let byteCount = 3 * componentCount * scalarType.byteCount
        return try TriangleMeshVertexAttribute(
            descriptor: descriptor,
            bytes: ContiguousArray(repeating: 0, count: byteCount)
        )
    }

    private func mesh(
        positions: ContiguousArray<Double>,
        coordinateSpace: CoordinateSpaceDescriptor,
        topology: TriangleMeshTopology,
        attributes: ContiguousArray<TriangleMeshVertexAttribute>
    ) throws -> TriangleMesh {
        try TriangleMesh(
            positions: try TriangleMeshPositionDomain(
                coordinateSpace: coordinateSpace,
                components: positions
            ),
            topology: topology,
            vertexAttributes: attributes
        )
    }

    private func meshReplacingAttributes(
        _ mesh: TriangleMesh,
        with attributes: ContiguousArray<TriangleMeshVertexAttribute>
    ) throws -> TriangleMesh {
        try TriangleMesh(
            positions: mesh.positions,
            topology: mesh.topology,
            vertexAttributes: attributes
        )
    }

    private func sourceIdentity() throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(
                DataObjectID(rawValue: "normal-source-mesh-1")
            ),
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: [1, 2, 3]
            ),
            sourceIdentities: [],
            derivation: nil
        )
    }

    private func sourceProvenance(
        subjectObjectID: DataObjectID? = nil
    ) throws -> ProvenanceRecord {
        let sourceObjectID = try sourceIdentity().objectID
        return try ProvenanceRecord(
            id: try #require(
                ProvenanceID(rawValue: "normal-source-record-1")
            ),
            kind: .source,
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T17:30:00Z"
            ),
            subject: .object(subjectObjectID ?? sourceObjectID),
            software: try SoftwareIdentity(
                name: "Voxelia Source",
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

    private func outputIdentity(
        request: TriangleMeshVertexNormalGenerationRequest,
        publication: TriangleMeshVertexNormalGenerationPublicationContext,
        objectID: DataObjectID? = nil,
        contentID: ContentID? = nil,
        sourceIdentities: ContiguousArray<SourceIdentity> = [],
        includeDerivation: Bool = true,
        operationID: String =
            TriangleMeshVertexNormalGenerationRequest.operationIdentifier,
        parameterDigest: ContentID? = nil,
        operationVersion: SemanticVersion? = nil,
        includeImplementation: Bool = true,
        implementationID: String =
            "org.voxelia.impl.triangle-mesh-vertex-normal-generation.cpu",
        implementationVersion: SemanticVersion? = nil,
        inputRole: String = "source-mesh",
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
        let implementationVersion =
            try
            (implementationVersion
            ?? SemanticVersion(major: 1, minor: 0, patch: 0))
        let digest =
            try
            (parameterDigest
            ?? TriangleMeshVertexNormalGenerationRequest.parameterDigest())
        let input = DerivationInput(
            role: try DerivationInputRole(rawValue: inputRole),
            identity: .object(inputObjectID ?? request.sourceIdentity.objectID)
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
        request: TriangleMeshVertexNormalGenerationRequest,
        publication: TriangleMeshVertexNormalGenerationPublicationContext,
        provenanceID: ProvenanceID? = nil,
        subjectObjectID: DataObjectID? = nil,
        createdAt: CanonicalInstant? = nil,
        software: SoftwareIdentity? = nil,
        kind: ProvenanceKind = .transformed,
        inputRole: String = "source-mesh",
        occurrence: UInt32 = 1,
        inputObjectID: DataObjectID? = nil,
        parentID: ProvenanceID? = nil,
        operationID: String =
            TriangleMeshVertexNormalGenerationRequest.operationIdentifier,
        operationVersion: SemanticVersion? = nil,
        implementationID: String =
            "org.voxelia.impl.triangle-mesh-vertex-normal-generation.cpu",
        implementationVersion: SemanticVersion? = nil,
        parameterDigest: ContentID? = nil,
        inputCount: Int = 1,
        includeWarning: Bool = false,
        executionBackend: String = "org.voxelia.backend.cpu"
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
            ?? TriangleMeshVertexNormalGenerationRequest.parameterDigest())
        let operation = try OperationProvenance(
            operationID: try DerivationOperationToken(rawValue: operationID),
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
                        inputObjectID ?? request.sourceIdentity.objectID
                    ),
                    parent: .graphNode(parentID ?? request.sourceProvenance.id)
                )
            }
        )
        let warnings: ContiguousArray<ProvenanceWarning> =
            includeWarning ? [try warning()] : []
        return try ProvenanceRecord(
            id: provenanceID ?? publication.outputProvenanceID,
            kind: kind,
            createdAt: createdAt ?? publication.createdAt,
            subject: .object(subjectObjectID ?? publication.outputObjectID),
            software: software ?? publication.software,
            activity: .operation(
                operation,
                try executionClaim(backendIdentifier: executionBackend)
            ),
            inputs: inputs,
            warnings: warnings,
            validationClaim: .unknown,
            declaresZeroInputGenerator: inputCount == 0
        )
    }

    private func executionClaim(
        backendIdentifier: String
    ) throws -> ExecutionProvenanceClaim {
        let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
        return ExecutionProvenanceClaim(
            profile: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.profile.default"
                ),
                version: version
            ),
            backend: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: backendIdentifier
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

    private func warning() throws -> ProvenanceWarning {
        try ProvenanceWarning(
            code: try ProvenanceWarningCode(
                rawValue: "org.voxelia.test-warning"
            ),
            schemaVersion: ProvenanceWarningSchemaVersion(
                major: 1,
                minor: 0
            ),
            severity: .informational,
            occurrenceCount: 1
        )
    }

    private func independentParameterDocument() throws -> [UInt8] {
        let namespace =
            "org.voxelia.op.triangle-mesh-vertex-normal-generation"
        return try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: try MetadataCollection(entries: [
                try parameterEntry(
                    namespace: namespace,
                    name: "algorithm-identifier",
                    value:
                        "triangle-area-weighted-vertex-normals/binary64-v1"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "weighting-rule",
                    value: "oriented-doubled-area-vector"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "degenerate-face-rule",
                    value: "zero-vector-contributes-nothing"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "accumulation-rule",
                    value: "triangle-order-corner-order-component-order"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "normalization-rule",
                    value: "maximum-component-scaled-euclidean"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "zero-component-rule",
                    value: "positive-zero"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "output-attribute",
                    value: "vertex-interleaved-float64-little-endian"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "existing-normal-rule",
                    value: "reject"
                ),
            ]),
            maximumOutputByteCount: 65_536
        )
    }

    private func parameterEntry(
        namespace: String,
        name: String,
        value: String
    ) throws -> MetadataEntry {
        MetadataEntry(
            key: try AnyMetadataKey(namespace: namespace, name: name),
            value: .string(value),
            privacyClass: .technical
        )
    }

    private func independentParameterDigest() throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: independentParameterDocument()
        )
    }

    private func emptyParameterDigest() throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )
    }

    private func expectPublicationFailure(
        mesh: TriangleMesh,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: TriangleMeshVertexNormalGenerationRequest,
        publication: TriangleMeshVertexNormalGenerationPublicationContext
    ) throws {
        #expect(
            throws:
                TriangleMeshVertexNormalGenerationError.publicationFailed
        ) {
            try TriangleMeshVertexNormalGenerationResult(
                mesh: mesh,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }
    }

    private func rejectUTF8EquivalentSourceAttribute(
        replacing index: Int,
        semantic: GeometryAttributeSemantic,
        interpretation: ComponentInterpretation,
        componentNames: ContiguousArray<String>?
    ) throws {
        let request = try request()
        let publication = try publicationContext()
        let sourceAttribute = request.source.vertexAttributes[index]
        let replacement = try TriangleMeshVertexAttribute(
            descriptor: try GeometryAttributeDescriptor(
                semantic: semantic,
                scalarFormat: sourceAttribute.descriptor.scalarFormat,
                components: try ComponentDescriptor(
                    count: sourceAttribute.descriptor.components.count,
                    interpretation: interpretation,
                    layout: sourceAttribute.descriptor.components.layout,
                    componentNames: componentNames
                ),
                elementCount: sourceAttribute.descriptor.elementCount
            ),
            bytes: sourceAttribute.bytes
        )
        var attributes = request.source.vertexAttributes
        attributes[index] = replacement
        attributes.append(try normalAttribute())
        try expectPublicationFailure(
            mesh: try meshReplacingAttributes(request.source, with: attributes),
            identity: try outputIdentity(
                request: request,
                publication: publication
            ),
            provenance: try outputProvenance(
                request: request,
                publication: publication
            ),
            request: request,
            publication: publication
        )
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

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
