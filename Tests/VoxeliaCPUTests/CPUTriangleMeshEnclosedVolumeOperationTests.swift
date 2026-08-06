// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU triangle-mesh enclosed-volume publication")
struct CPUTriangleMeshEnclosedVolumeOperationTests {
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

        let result = try await CPUTriangleMeshEnclosedVolumeOperation.execute(
            request: request,
            publication: publication,
            progress: discardingProgressObserver
        )

        #expect(
            CPUTriangleMeshEnclosedVolumeOperation.implementationIdentifier
                == "org.voxelia.impl.triangle-mesh-enclosed-volume.cpu"
        )
        #expect(result.measurement.value == 1)
        #expect(result.measurement.value.bitPattern == 0x3FF0_0000_0000_0000)
        #expect(result.measurement.facetCount == 12)
        #expect(result.measurement.unit.exponent == 3)
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
                == TriangleMeshEnclosedVolumeRequest.operationIdentifier
        )
        #expect(derivation.operationVersion == expectedVersion)
        #expect(derivation.operationVersion.prerelease == nil)
        #expect(derivation.operationVersion.buildMetadata == nil)
        #expect(
            implementation.identifier.rawValue
                == CPUTriangleMeshEnclosedVolumeOperation
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
        #expect(transferred.0 == 0x3FF0_0000_0000_0000)
        #expect(transferred.1 == 12)
        #expect(transferred.2 == publication.outputObjectID)
        #expect(transferred.3 == publication.outputProvenanceID)
    }

    @Test(
        "[Unit][VOX-GEO-010] an empty mesh publishes a coherent positive-zero measurement"
    )
    func executePublishesEmptyMesh() async throws {
        let source = try mesh(positions: [], indices: [])
        let result = try await CPUTriangleMeshEnclosedVolumeOperation.execute(
            request: try request(mesh: source),
            publication: publicationContext(),
            progress: discardingProgressObserver
        )

        #expect(result.measurement.value.bitPattern == (0.0).bitPattern)
        #expect(result.measurement.facetCount == 0)
        #expect(result.measurement.unit.exponent == 3)
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
            positions: cubePositions,
            indices: cubeIndices,
            unit: centimetre
        )
        let result = try await CPUTriangleMeshEnclosedVolumeOperation.execute(
            request: try request(mesh: source),
            publication: publicationContext(),
            progress: discardingProgressObserver
        )

        #expect(result.measurement.unit.base.namespace == "DICOM")
        #expect(result.measurement.unit.base.code == "cm")
        #expect(result.measurement.unit.base.displayName == "centimetre")
        #expect(result.measurement.unit.exponent == 3)
        // The conversion metadata is carried through exactly and is never
        // squared, combined or otherwise reinterpreted by the powered unit.
        #expect(result.measurement.unit.base.scaleToCanonical == 10)
        #expect(result.measurement.unit.base.offsetToCanonical == 0)
        // The unit changed but the numbers did not: the arithmetic never
        // reads a unit, so the volume is the same as the millimetre mesh's.
        #expect(result.measurement.value == 1)
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
            return try await CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: request,
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        cancelledTask.cancel()
        await #expect(throws: TriangleMeshEnclosedVolumeError.cancelled) {
            try await cancelledTask.value
        }

        // The final checkpoint is the operation's own, taken after the total
        // exists and before any claim is constructed.
        #expect(throws: TriangleMeshEnclosedVolumeError.cancelled) {
            try CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: request,
                publication: publication,
                cancellation: { $0 == .final },
                progress: discardingProgressObserver
            )
        }
        #expect(throws: TriangleMeshEnclosedVolumeError.cancelled) {
            try CPUTriangleMeshEnclosedVolumeOperation.execute(
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

        await #expect(throws: TriangleMeshEnclosedVolumeError.invalidLimits) {
            try await CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: try request(
                    mesh: simple,
                    limits: TriangleMeshEnclosedVolumeLimits(
                        maximumVertexCount: 0,
                        maximumTriangleCount: 1,
                        maximumAdditionalLogicalByteCount: 1
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        await #expect(throws: TriangleMeshEnclosedVolumeError.invalidSource) {
            try await CPUTriangleMeshEnclosedVolumeOperation.execute(
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
            throws: TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        ) {
            try await CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: try request(
                    mesh: simple,
                    limits: TriangleMeshEnclosedVolumeLimits(
                        maximumVertexCount: 2,
                        maximumTriangleCount: 1,
                        maximumAdditionalLogicalByteCount: 1_000
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        // Certification failures surface as their own classes and publish
        // nothing, because no arithmetic runs for an uncertified surface.
        await #expect(throws: TriangleMeshEnclosedVolumeError.openSurface) {
            try await CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: try request(
                    mesh: try mesh(
                        positions: cubePositions,
                        indices: ContiguousArray(cubeIndices.dropFirst(3))
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        var duplicated = cubeIndices
        duplicated.append(contentsOf: cubeIndices[0..<3])
        await #expect(
            throws: TriangleMeshEnclosedVolumeError.nonManifoldOrientation
        ) {
            try await CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: try request(
                    mesh: try mesh(
                        positions: cubePositions,
                        indices: duplicated
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        await #expect(throws: TriangleMeshEnclosedVolumeError.degenerateFacet) {
            try await CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: try request(
                    mesh: try mesh(
                        positions: cubePositions,
                        indices: [0, 0, 1]
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        var inverted = ContiguousArray<UInt64>()
        for facet in stride(from: 0, to: cubeIndices.count, by: 3) {
            inverted.append(cubeIndices[facet])
            inverted.append(cubeIndices[facet + 2])
            inverted.append(cubeIndices[facet + 1])
        }
        await #expect(
            throws: TriangleMeshEnclosedVolumeError.invertedOrientation
        ) {
            try await CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: try request(
                    mesh: try mesh(
                        positions: cubePositions,
                        indices: inverted
                    )
                ),
                publication: publication,
                progress: discardingProgressObserver
            )
        }
        await #expect(
            throws: TriangleMeshEnclosedVolumeError.volumeNotRepresentable
        ) {
            try await CPUTriangleMeshEnclosedVolumeOperation.execute(
                request: try request(
                    mesh: try mesh(
                        positions: [
                            0, 0, 0,
                            1e200, 0, 0,
                            0, 1e200, 0,
                            0, 0, 1e200,
                        ],
                        indices: [0, 2, 1, 0, 1, 3, 0, 3, 2, 1, 2, 3]
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
                    try await CPUTriangleMeshEnclosedVolumeOperation.execute(
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
        #expect(Set(results) == [0x3FF0_0000_0000_0000])
    }

    // MARK: - Helpers

    /// One outward-oriented closed unit cube: eight vertices, twelve facets,
    /// enclosing exactly one cubic unit.
    private let cubePositions: ContiguousArray<Double> = [
        0, 0, 0,
        1, 0, 0,
        1, 1, 0,
        0, 1, 0,
        0, 0, 1,
        1, 0, 1,
        1, 1, 1,
        0, 1, 1,
    ]

    private let cubeIndices: ContiguousArray<UInt64> = [
        0, 3, 2, 0, 2, 1,
        4, 5, 6, 4, 6, 7,
        0, 1, 5, 0, 5, 4,
        1, 2, 6, 1, 6, 5,
        2, 3, 7, 2, 7, 6,
        3, 0, 4, 3, 4, 7,
    ]

    private func sourceMesh() throws -> TriangleMesh {
        try mesh(positions: cubePositions, indices: cubeIndices)
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
        limits: TriangleMeshEnclosedVolumeLimits? = nil,
        provenance: ProvenanceRecord? = nil
    ) throws -> TriangleMeshEnclosedVolumeRequest {
        let identity = try sourceIdentity()
        return TriangleMeshEnclosedVolumeRequest(
            source: mesh,
            sourceIdentity: identity,
            sourceProvenance: try provenance
                ?? sourceProvenance(subjectObjectID: identity.objectID),
            limits: limits
                ?? TriangleMeshEnclosedVolumeLimits(
                    maximumVertexCount: 10_000,
                    maximumTriangleCount: 10_000,
                    maximumAdditionalLogicalByteCount: 1_000_000
                )
        )
    }

    private func publicationContext()
        throws -> TriangleMeshEnclosedVolumePublicationContext
    {
        TriangleMeshEnclosedVolumePublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "volume-operation-output")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "volume-operation-record")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-06T09:30:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia Volume Operation Test Publisher",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
        )
    }

    private func sourceIdentity() throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(
                DataObjectID(rawValue: "volume-operation-source")
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
                name: "Voxelia Volume Operation Test Source",
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
                CoordinateSpaceID(rawValue: "volume-operation-space")
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
        let namespace = "org.voxelia.op.triangle-mesh-enclosed-volume"
        let document = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: try MetadataCollection(entries: [
                try parameterEntry(
                    namespace: namespace,
                    name: "algorithm-identifier",
                    value: "triangle-mesh-enclosed-volume/binary64-v1"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "certification-rule",
                    value: "closed-edge-manifold-consistently-oriented"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "vertex-manifold-rule",
                    value: "not-required"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "self-intersection-rule",
                    value: "not-certified"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "degenerate-facet-rule",
                    value: "reject-repeated-index"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "facet-term-rule",
                    value: "origin-anchored-scalar-triple-product"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "reference-origin",
                    value: "source-coordinate-space-origin"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "accumulation-rule",
                    value: "triangle-order-serial-sum-then-divide-by-six"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "orientation-rule",
                    value: "outward-positive-inward-rejected"
                ),
                try parameterEntry(
                    namespace: namespace,
                    name: "unit-rule",
                    value: "source-length-unit-power-three"
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
