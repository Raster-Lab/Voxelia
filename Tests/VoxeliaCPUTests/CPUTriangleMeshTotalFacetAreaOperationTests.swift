// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU triangle-mesh total-facet-area publication")
struct CPUTriangleMeshTotalFacetAreaOperationTests {
    @Test(
        "[Unit][VOX-GEO-010][VOX-META-003][VOX-META-006] public execution binds every fixed claim"
    )
    func executePublishesCompleteFixedClaims() async throws {
        let request = try self.request(mesh: sourceMesh())
        let publication = try publicationContext()
        let expectedVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )

        let result = try await CPUTriangleMeshTotalFacetAreaOperation.execute(
            request: request,
            publication: publication,
            progress: discardingProgressObserver
        )

        #expect(
            CPUTriangleMeshTotalFacetAreaOperation.implementationIdentifier
                == "org.voxelia.impl.triangle-mesh-total-facet-area.cpu"
        )
        #expect(result.measurement.value == 3)
        #expect(result.measurement.value.bitPattern == 0x4008_0000_0000_0000)
        #expect(result.measurement.facetCount == 1)
        #expect(result.measurement.unit.exponent == 2)
        #expect(
            result.measurement.unit.base == request.source.coordinateSpace.unit
        )
        #expect(result.measurement.unit.base.dimension == .length)
        #expect(result.measurement.unit.base.code == "mm")

        #expect(result.identity.objectID == publication.outputObjectID)
        #expect(result.identity.contentID == nil)
        #expect(result.identity.sourceIdentities.isEmpty)
        let derivation = try #require(result.identity.derivation)
        let implementation = try #require(derivation.implementation)
        #expect(
            derivation.operationID.rawValue
                == TriangleMeshTotalFacetAreaRequest.operationIdentifier
        )
        #expect(derivation.operationVersion == expectedVersion)
        #expect(derivation.operationVersion.prerelease == nil)
        #expect(derivation.operationVersion.buildMetadata == nil)
        #expect(
            implementation.identifier.rawValue
                == CPUTriangleMeshTotalFacetAreaOperation
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
        #expect(
            derivation.parameterDigest == (try independentParameterDigest())
        )

        #expect(result.provenance.id == publication.outputProvenanceID)
        #expect(result.provenance.kind == .transformed)
        #expect(result.provenance.createdAt == publication.createdAt)
        #expect(
            result.provenance.subject == .object(publication.outputObjectID)
        )
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
                result.measurement.value.bitPattern,
                result.measurement.facetCount,
                result.identity.objectID,
                result.provenance.id
            )
        }.value
        #expect(transferred.0 == 0x4008_0000_0000_0000)
        #expect(transferred.1 == 1)
        #expect(transferred.2 == publication.outputObjectID)
        #expect(transferred.3 == publication.outputProvenanceID)
    }

    @Test(
        "[Unit][VOX-GEO-010] an empty mesh publishes a coherent positive-zero measurement"
    )
    func executePublishesEmptyMesh() async throws {
        let source = try mesh(positions: [], indices: [])
        let result = try await CPUTriangleMeshTotalFacetAreaOperation.execute(
            request: try request(mesh: source),
            publication: publicationContext(),
            progress: discardingProgressObserver
        )

        #expect(result.measurement.value.bitPattern == (0.0).bitPattern)
        #expect(result.measurement.facetCount == 0)
        #expect(result.measurement.unit.exponent == 2)
        #expect(result.identity.derivation != nil)
        #expect(result.provenance.kind == .transformed)
    }

    @Test(
        "[Unit][VOX-GEO-010] the published unit derives from the source coordinate space"
    )
    func publishedUnitDerivesFromSourceCoordinateSpace() async throws {
        let centimetre = try MeasurementUnit(
            namespace: "DICOM",
            code: "cm",
            displayName: "centimetre",
            dimension: .length,
            scaleToCanonical: 10,
            offsetToCanonical: 0
        )
        let source = try mesh(
            positions: rightTrianglePositions,
            indices: [0, 1, 2],
            unit: centimetre
        )
        let result = try await CPUTriangleMeshTotalFacetAreaOperation.execute(
            request: try request(mesh: source),
            publication: publicationContext(),
            progress: discardingProgressObserver
        )

        #expect(result.measurement.unit.base.namespace == "DICOM")
        #expect(result.measurement.unit.base.code == "cm")
        #expect(result.measurement.unit.base.displayName == "centimetre")
        #expect(result.measurement.unit.exponent == 2)
        // The conversion metadata is carried through exactly and is never
        // squared, combined or otherwise reinterpreted by the powered unit.
        #expect(result.measurement.unit.base.scaleToCanonical == 10)
        #expect(result.measurement.unit.base.offsetToCanonical == 0)
        // The unit changed but the numbers did not: the arithmetic never
        // reads a unit, so the total is the same as the millimetre mesh's.
        #expect(result.measurement.value == 3)
    }

    @Test(
        "[Unit][VOX-CON-006][VOX-CON-007] task and final cancellation publish no aggregate"
    )
    func cancellationPublishesNothing() async throws {
        let request = try self.request(mesh: sourceMesh())
        let publication = try publicationContext()
        let cancelledTask = Task {
            while !Task.isCancelled {
                await Task.yield()
            }
            return try await CPUTriangleMeshTotalFacetAreaOperation.execute(
                request: request,
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        cancelledTask.cancel()
        await #expect(throws: TriangleMeshTotalFacetAreaError.cancelled) {
            try await cancelledTask.value
        }

        // The final checkpoint is the operation's own, taken after the total
        // exists and before any claim is constructed.
        #expect(throws: TriangleMeshTotalFacetAreaError.cancelled) {
            try CPUTriangleMeshTotalFacetAreaOperation.execute(
                request: request,
                publication: publication,
                cancellation: { $0 == .final },
                progress: discardingProgressObserver
            )
        }
        #expect(throws: TriangleMeshTotalFacetAreaError.cancelled) {
            try CPUTriangleMeshTotalFacetAreaOperation.execute(
                request: request,
                publication: publication,
                cancellation: { $0 == .admission },
                progress: discardingProgressObserver
            )
        }
    }

    @Test(
        "[Unit][VOX-ERR-001] every kernel failure surfaces unchanged and publishes nothing"
    )
    func kernelFailuresSurfaceUnchanged() async throws {
        let publication = try publicationContext()
        let simple = try sourceMesh()

        await #expect(throws: TriangleMeshTotalFacetAreaError.invalidLimits) {
            try await CPUTriangleMeshTotalFacetAreaOperation.execute(
                request: try request(
                    mesh: simple,
                    limits: TriangleMeshTotalFacetAreaLimits(
                        maximumVertexCount: 0,
                        maximumTriangleCount: 1
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        await #expect(throws: TriangleMeshTotalFacetAreaError.invalidSource) {
            try await CPUTriangleMeshTotalFacetAreaOperation.execute(
                request: try request(
                    mesh: simple,
                    provenance: try sourceProvenance(
                        subjectObjectID: try #require(
                            DataObjectID(rawValue: "unmatched")
                        )
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        await #expect(
            throws: TriangleMeshTotalFacetAreaError.resourceLimitExceeded
        ) {
            try await CPUTriangleMeshTotalFacetAreaOperation.execute(
                request: try request(
                    mesh: simple,
                    limits: TriangleMeshTotalFacetAreaLimits(
                        maximumVertexCount: 2,
                        maximumTriangleCount: 1
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        await #expect(
            throws: TriangleMeshTotalFacetAreaError.areaNotRepresentable
        ) {
            try await CPUTriangleMeshTotalFacetAreaOperation.execute(
                request: try request(
                    mesh: try mesh(
                        positions: [
                            Double.greatestFiniteMagnitude, 0, 0,
                            -Double.greatestFiniteMagnitude, 0, 0,
                            0, 1, 0,
                        ],
                        indices: [0, 1, 2]
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
    }

    @Test(
        "[Unit][VOX-GEO-010][VOX-CON-003] repeated and concurrent execution are identical"
    )
    func repeatedAndConcurrentExecutionAreIdentical() async throws {
        let request = try self.request(mesh: sourceMesh())
        let publication = try publicationContext()

        let results = try await withThrowingTaskGroup(
            of: UInt64.self
        ) { group in
            for _ in 0..<8 {
                group.addTask {
                    try await CPUTriangleMeshTotalFacetAreaOperation.execute(
                        request: request,
                        publication: publication,
                        progress: discardingProgressObserver
                    ).measurement.value.bitPattern
                }
            }
            var observed = [UInt64]()
            for try await bitPattern in group {
                observed.append(bitPattern)
            }
            return observed
        }
        #expect(results.count == 8)
        #expect(Set(results) == [0x4008_0000_0000_0000])
    }

    // MARK: - Helpers

    private let rightTrianglePositions: ContiguousArray<Double> = [
        0, 0, 0,
        2, 0, 0,
        0, 3, 0,
    ]

    private func sourceMesh() throws -> TriangleMesh {
        try mesh(positions: rightTrianglePositions, indices: [0, 1, 2])
    }

    private func mesh(
        positions: ContiguousArray<Double>,
        indices: ContiguousArray<UInt64>,
        unit: MeasurementUnit? = nil
    ) throws -> TriangleMesh {
        let domain = try TriangleMeshPositionDomain(
            coordinateSpace: try coordinateSpace(unit: unit),
            components: positions
        )
        return try TriangleMesh(
            positions: domain,
            topology: try TriangleMeshTopology(
                vertexCount: domain.vertexCount,
                indices: indices
            ),
            vertexAttributes: []
        )
    }

    private func request(
        mesh: TriangleMesh,
        limits: TriangleMeshTotalFacetAreaLimits? = nil,
        provenance: ProvenanceRecord? = nil
    ) throws -> TriangleMeshTotalFacetAreaRequest {
        let identity = try sourceIdentity()
        return TriangleMeshTotalFacetAreaRequest(
            source: mesh,
            sourceIdentity: identity,
            sourceProvenance: try provenance
                ?? sourceProvenance(subjectObjectID: identity.objectID),
            limits: limits
                ?? TriangleMeshTotalFacetAreaLimits(
                    maximumVertexCount: 10_000,
                    maximumTriangleCount: 10_000
                )
        )
    }

    private func publicationContext()
        throws -> TriangleMeshTotalFacetAreaPublicationContext
    {
        TriangleMeshTotalFacetAreaPublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "area-operation-output")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "area-operation-record")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-06T09:30:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia Area Operation Test Publisher",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
        )
    }

    private func sourceIdentity() throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(
                DataObjectID(rawValue: "area-operation-source")
            ),
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: [1]
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
                ProvenanceID(rawValue: "area-operation-source-record")
            ),
            kind: .source,
            createdAt: try CanonicalInstant(
                utcString: "2026-08-06T09:20:00Z"
            ),
            subject: .object(subjectObjectID),
            software: try SoftwareIdentity(
                name: "Voxelia Area Operation Test Source",
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

    private func coordinateSpace(
        unit: MeasurementUnit? = nil
    ) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(
                CoordinateSpaceID(rawValue: "area-operation-space")
            ),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try unit
                ?? MeasurementUnit(
                    namespace: "UCUM",
                    code: "mm",
                    dimension: .length
                ),
            externalReferences: []
        )
    }

    /// Reconstructs the frozen parameters a third time, independently of both
    /// the Geometry request helper and the operation's own private copy.
    private func independentParameterDigest() throws -> ContentID {
        let namespace = "org.voxelia.op.triangle-mesh-total-facet-area"
        let document = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: try MetadataCollection(entries: [
                try parameterEntry(
                    namespace: namespace,
                    name: "algorithm-identifier",
                    value: "triangle-mesh-total-facet-area/binary64-v1"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "quantity-rule",
                    value: "total-facet-area-with-multiplicity"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "facet-area-rule",
                    value: "half-scaled-euclidean-cross-magnitude"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "degenerate-face-rule",
                    value: "zero-area-contributes-zero"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "accumulation-rule",
                    value: "triangle-order-serial-sum"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "orientation-rule",
                    value: "unsigned-winding-independent"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "topology-claim",
                    value: "none"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "unit-rule",
                    value: "source-length-unit-power-two"
                ),
            ]),
            maximumOutputByteCount: 65_536
        )
        return try ContentID.operationParametersIdentity(
            overCanonicalBytes: document
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
}
