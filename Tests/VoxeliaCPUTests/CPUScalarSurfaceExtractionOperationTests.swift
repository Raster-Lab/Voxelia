// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU scalar-surface publication")
struct CPUScalarSurfaceExtractionOperationTests {
    @Test("[Unit][VOX-GEO-006][VOX-EXE-002] public execution binds every fixed claim")
    func executePublishesCompleteFixedClaims() async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture()
        let request = ScalarSurfaceTestSupport.request(fixture: fixture)
        let publication = try publicationContext()
        let expectedVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )

        let result = try await CPUScalarSurfaceExtractionOperation.execute(
            request: request,
            publication: publication,
            coordinator: coordinator,
            progress: discardingProgressObserver
        )

        #expect(
            CPUScalarSurfaceExtractionOperation.implementationIdentifier
                == "org.voxelia.impl.scalar-surface-extraction.cpu"
        )
        #expect(
            result.mesh.positions.components
                == ScalarSurfaceTestSupport.singleCornerPositions
        )
        #expect(
            result.mesh.topology.indices
                == ScalarSurfaceTestSupport.singleCornerIndices
        )
        #expect(result.identity.objectID == publication.outputObjectID)
        #expect(result.identity.contentID == nil)
        #expect(result.identity.sourceIdentities.isEmpty)

        let derivation = try #require(result.identity.derivation)
        let implementation = try #require(derivation.implementation)
        #expect(
            derivation.operationID.rawValue
                == ScalarSurfaceExtractionRequest.operationIdentifier
        )
        #expect(derivation.operationVersion == expectedVersion)
        #expect(
            implementation.identifier.rawValue
                == CPUScalarSurfaceExtractionOperation.implementationIdentifier
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
                == (try independentParameterDigest(for: request.isovalue))
        )
        #expect(
            derivation.parameterDigest.digest == [
                0xad, 0x77, 0x24, 0xaf, 0xc9, 0xce, 0x3d, 0x44,
                0x69, 0xd8, 0xc1, 0xcc, 0x17, 0xc4, 0x6a, 0xc6,
                0xeb, 0xca, 0xcd, 0xcb, 0xed, 0xb9, 0xc0, 0xf8,
                0xbb, 0x63, 0xb8, 0xcf, 0xc7, 0xb3, 0x17, 0x21,
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

    @Test(
        "[Unit][VOX-EXE-008][VOX-NUM-001] two passes with different cadences compose into one sequence"
    )
    func twoPassesWithDifferentCadencesComposeIntoOneSequence() async throws {
        // The sharpest shape yet: ONE operation whose two passes use DIFFERENT
        // cadences -- sample validation at 4,096 and the cell traversal at 64.
        // A hidden assumption that the cadence is always 64 would fail here.
        let fixture = try ScalarSurfaceTestSupport.fixture()
        let request = ScalarSurfaceTestSupport.request(fixture: fixture)

        let silent = try await CPUScalarSurfaceExtractionOperation.execute(
            request: request,
            publication: try publicationContext(),
            coordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 1_024
            ),
            progress: discardingProgressObserver
        )

        let recorder = ObservationRecorder()
        let observed = try await CPUScalarSurfaceExtractionOperation.execute(
            request: request,
            publication: try publicationContext(),
            coordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 1_024
            ),
            progress: { recorder.append($0) }
        )

        // Byte-identical geometry: an observer that can change a result is a
        // defect, and a mesh is compared component by component.
        #expect(
            observed.mesh.positions.components.map(\.bitPattern)
                == silent.mesh.positions.components.map(\.bitPattern)
        )
        #expect(observed.mesh.topology.indices == silent.mesh.topology.indices)

        // The four guarantees, on a sequence built from two cadences.
        let recorded = recorder.observations()
        #expect(!recorded.isEmpty)
        let total = try #require(recorded.first?.total)
        var previous = -1
        for observation in recorded {
            #expect(observation.total == total)
            #expect(observation.completed >= previous)
            #expect(observation.completed <= observation.total)
            previous = observation.completed
        }
        #expect(
            recorded.last == ProgressObservation(completed: total, total: total)
        )

        // The total is the work performed across BOTH passes, so it exceeds
        // either pass alone.
        #expect(total > 0)
        #expect(recorded.contains { $0.completed == 0 })
    }

    private final class ObservationRecorder: Sendable {
        private let recorded = Mutex([ProgressObservation]())

        func append(_ observation: ProgressObservation) {
            recorded.withLock { $0.append(observation) }
        }

        func observations() -> [ProgressObservation] {
            recorded.withLock { $0 }
        }
    }

    @Test("[Unit][VOX-GEO-007] empty scalar sources publish a coherent empty mesh")
    func executePublishesEmptyMesh() async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture(
            extents: [1, 2, 2],
            values: [0, 0, 0, 0]
        )
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let result = try await CPUScalarSurfaceExtractionOperation.execute(
            request: ScalarSurfaceTestSupport.request(fixture: fixture),
            publication: try publicationContext(),
            coordinator: coordinator,
            progress: discardingProgressObserver
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
        let fixture = try ScalarSurfaceTestSupport.fixture()
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )

        await #expect(throws: ScalarSurfaceExtractionError.cancelled) {
            try await CPUScalarSurfaceExtractionOperation.execute(
                request: ScalarSurfaceTestSupport.request(fixture: fixture),
                publication: try publicationContext(),
                coordinator: coordinator,
                cancellation: { $0 == .final },
                progress: discardingProgressObserver
            )
        }
        #expect(fixture.owner.readCount == 1)
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-011] publication construction maps payload-free")
    func publicationConstructionFailuresMapClosed() throws {
        let fixture = try ScalarSurfaceTestSupport.fixture()
        let request = ScalarSurfaceTestSupport.request(fixture: fixture)
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

        #expect(throws: ScalarSurfaceExtractionError.publicationFailed) {
            try CPUScalarSurfaceExtractionOperation.assembleResult(
                mesh: wrongSpace,
                request: request,
                publication: publication
            )
        }
        let nonFiniteRequest = ScalarSurfaceExtractionRequest(
            source: request.source,
            isovalue: .nan,
            limits: request.limits
        )
        #expect(throws: ScalarSurfaceExtractionError.publicationFailed) {
            try CPUScalarSurfaceExtractionOperation.assembleResult(
                mesh: wrongSpace,
                request: nonFiniteRequest,
                publication: publication
            )
        }
    }

    private func publicationContext()
        throws -> ScalarSurfaceExtractionPublicationContext
    {
        ScalarSurfaceExtractionPublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "scalar-surface-output")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "scalar-surface-output-record")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-05T15:45:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia CPU Tests",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
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
}
