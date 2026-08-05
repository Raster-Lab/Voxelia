// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU labelled-surface publication")
struct CPULabelledSurfaceExtractionOperationTests {
    @Test("[Unit][VOX-GEO-007][VOX-GEO-008][VOX-EXE-002] public execution binds every fixed claim")
    func executePublishesCompleteFixedClaims() async throws {
        let fixture = try LabelledSurfaceTestSupport.fixture(
            scalarType: .int8,
            values: .signed([-9, 0, 0, 0, 0, 0, 0, 0])
        )
        let request = LabelledSurfaceTestSupport.request(
            fixture: fixture,
            selectedLabels: .signed([-9, 4, 71])
        )
        let publication = try publicationContext()
        let expectedVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )

        let result = try await CPULabelledSurfaceExtractionOperation.execute(
            request: request,
            publication: publication,
            coordinator: coordinator
        )

        #expect(
            CPULabelledSurfaceExtractionOperation.implementationIdentifier
                == "org.voxelia.impl.labelled-surface-extraction.cpu"
        )
        #expect(
            result.mesh.positions.components
                == LabelledSurfaceTestSupport.singleCornerPositions
        )
        #expect(
            result.mesh.topology.indices
                == LabelledSurfaceTestSupport.singleCornerIndices
        )
        #expect(result.mesh.vertexAttributes.isEmpty)
        #expect(result.identity.objectID == publication.outputObjectID)
        #expect(result.identity.contentID == nil)
        #expect(result.identity.sourceIdentities.isEmpty)

        let derivation = try #require(result.identity.derivation)
        let implementation = try #require(derivation.implementation)
        #expect(
            derivation.operationID.rawValue
                == LabelledSurfaceExtractionRequest.operationIdentifier
        )
        #expect(derivation.operationVersion == expectedVersion)
        #expect(
            implementation.identifier.rawValue
                == CPULabelledSurfaceExtractionOperation
                .implementationIdentifier
        )
        #expect(implementation.version == expectedVersion)
        #expect(derivation.inputs.count == 1)
        #expect(derivation.inputs[0].role.rawValue == "source-volume")
        #expect(
            derivation.inputs[0].identity
                == .object(request.source.identity.objectID)
        )
        #expect(
            derivation.parameterDigest
                == (try independentParameterDigest(
                    for: request.selectedLabels
                ))
        )
        #expect(
            derivation.parameterDigest.digest == [
                0x79, 0xd1, 0xe8, 0x15, 0xa2, 0xb2, 0x14, 0x6e,
                0x24, 0xde, 0x98, 0xa3, 0x5b, 0x1e, 0x25, 0xd7,
                0x09, 0x1a, 0x7c, 0x19, 0xee, 0x7f, 0xe7, 0xa2,
                0x03, 0x31, 0xe8, 0x1a, 0xd7, 0x13, 0xd3, 0x50,
            ]
        )

        #expect(result.provenance.id == publication.outputProvenanceID)
        #expect(result.provenance.kind == .transformed)
        #expect(result.provenance.createdAt == publication.createdAt)
        #expect(result.provenance.subject == .object(publication.outputObjectID))
        #expect(result.provenance.software == publication.software)
        #expect(result.provenance.inputs.count == 1)
        #expect(result.provenance.inputs[0].role.rawValue == "source-volume")
        #expect(result.provenance.inputs[0].occurrence == 1)
        #expect(
            result.provenance.inputs[0].identity
                == .object(request.source.identity.objectID)
        )
        #expect(
            result.provenance.inputs[0].parent
                == .graphNode(request.source.provenance.id)
        )
        #expect(result.provenance.warnings.isEmpty)
        #expect(result.provenance.validationClaim == .unknown)

        switch result.provenance.activity {
        case .origin:
            Issue.record("Expected operation provenance.")
        case .operation(let operation, let execution):
            #expect(operation.operationID == derivation.operationID)
            #expect(operation.operationVersion == expectedVersion)
            #expect(operation.implementationID == implementation.identifier)
            #expect(operation.implementationVersion == expectedVersion)
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

        #expect(fixture.owner.readCount == 1)
        #expect(await coordinator.currentChargedByteCount == 0)
        let transferred = await Task.detached {
            (
                result.mesh.topology.triangleCount,
                result.identity.objectID,
                result.provenance.id
            )
        }.value
        #expect(transferred.0 == 6)
        #expect(transferred.1 == publication.outputObjectID)
        #expect(transferred.2 == publication.outputProvenanceID)
    }

    @Test("[Unit][VOX-GEO-007] empty labelled sources publish a coherent empty mesh")
    func executePublishesEmptyMesh() async throws {
        let fixture = try LabelledSurfaceTestSupport.fixture(
            extents: [1, 2, 2],
            values: .unsigned([7, 0, 0, 0])
        )
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let result = try await CPULabelledSurfaceExtractionOperation.execute(
            request: LabelledSurfaceTestSupport.request(fixture: fixture),
            publication: try publicationContext(),
            coordinator: coordinator
        )

        #expect(result.mesh.positions.components.isEmpty)
        #expect(result.mesh.topology.indices.isEmpty)
        #expect(result.identity.derivation != nil)
        #expect(result.provenance.kind == .transformed)
        #expect(fixture.owner.readCount == 1)
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    @Test("[Unit][VOX-EXE-006] final cancellation precedes publication assembly")
    func finalCancellationPublishesNothing() async throws {
        let fixture = try LabelledSurfaceTestSupport.fixture()
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )

        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.execute(
                request: LabelledSurfaceTestSupport.request(fixture: fixture),
                publication: try publicationContext(),
                coordinator: coordinator,
                cancellation: { $0 == .final }
            )
        }
        #expect(fixture.owner.readCount == 1)
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-011] publication construction maps payload-free")
    func publicationConstructionFailuresMapClosed() throws {
        let fixture = try LabelledSurfaceTestSupport.fixture()
        let request = LabelledSurfaceTestSupport.request(fixture: fixture)
        let publication = try publicationContext()
        let wrongSpace = try emptyMesh(
            coordinateSpace: try CoordinateSpaceDescriptor(
                id: try #require(CoordinateSpaceID(rawValue: "scanner")),
                convention: .dicomPatientLPS,
                handedness: .unspecified,
                unit: try MeasurementUnit(
                    namespace: "UCUM",
                    code: "mm",
                    dimension: .length
                ),
                externalReferences: []
            )
        )

        #expect(throws: LabelledSurfaceExtractionError.publicationFailed) {
            try CPULabelledSurfaceExtractionOperation.assembleResult(
                mesh: wrongSpace,
                request: request,
                publication: publication
            )
        }
        let invalidRequest = LabelledSurfaceExtractionRequest(
            source: request.source,
            selectedLabels: .unsigned([]),
            limits: request.limits
        )
        #expect(throws: LabelledSurfaceExtractionError.publicationFailed) {
            try CPULabelledSurfaceExtractionOperation.assembleResult(
                mesh: try emptyMesh(
                    coordinateSpace: try sourceCoordinateSpace(request)
                ),
                request: invalidRequest,
                publication: publication
            )
        }
    }

    private func publicationContext()
        throws -> LabelledSurfaceExtractionPublicationContext
    {
        LabelledSurfaceExtractionPublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "labelled-surface-output")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "labelled-surface-output-record")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T17:10:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia CPU Tests",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
        )
    }

    private func independentParameterDigest(
        for selectedLabels: LabelledSurfaceLabelSet
    ) throws -> ContentID {
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
        return try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
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
        )
    }

    private func sourceCoordinateSpace(
        _ request: LabelledSurfaceExtractionRequest
    ) throws -> CoordinateSpaceDescriptor {
        guard
            case .affine(let geometry) =
                request.source.descriptor.spatialGeometry
        else {
            throw FixtureError.missingAffineGeometry
        }
        return geometry.coordinateSpace
    }

    private func emptyMesh(
        coordinateSpace: CoordinateSpaceDescriptor
    ) throws -> TriangleMesh {
        try TriangleMesh(
            positions: TriangleMeshPositionDomain(
                coordinateSpace: coordinateSpace,
                components: []
            ),
            topology: TriangleMeshTopology(vertexCount: 0, indices: []),
            vertexAttributes: []
        )
    }

    private enum FixtureError: Error {
        case missingAffineGeometry
    }
}
