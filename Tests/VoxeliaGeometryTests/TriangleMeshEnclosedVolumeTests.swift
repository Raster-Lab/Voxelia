// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaGeometry

@Suite("TriangleMeshEnclosedVolume")
struct TriangleMeshEnclosedVolumeTests {
    @Test(
        "[Unit][VOX-API-003][VOX-GEO-010] declarations preserve unadmitted inputs and transfer safely"
    )
    func declarationsPreserveInputsAndTransferSafely() async throws {
        let source = try sourceMesh()
        let sourceIdentity = try sourceIdentity()
        // The helper accepts an optional identifier, so `#require` here would
        // be redundant and the strict build rejects it.
        let mismatchedProvenance = try sourceProvenance(
            subjectObjectID: DataObjectID(rawValue: "unmatched-source")
        )
        let limits = TriangleMeshEnclosedVolumeLimits(
            maximumVertexCount: 0,
            maximumTriangleCount: UInt64.max,
            maximumAdditionalLogicalByteCount: 0
        )
        let request = TriangleMeshEnclosedVolumeRequest(
            source: source,
            sourceIdentity: sourceIdentity,
            sourceProvenance: mismatchedProvenance,
            limits: limits
        )
        let publication = try publicationContext()

        #expect(
            TriangleMeshEnclosedVolumeRequest.operationIdentifier
                == "org.voxelia.op.triangle-mesh-enclosed-volume"
        )
        #expect(
            TriangleMeshEnclosedVolumeRequest.algorithmIdentifier
                == "triangle-mesh-enclosed-volume/binary64-v1"
        )
        #expect(TriangleMeshEnclosedVolumeRequest.volumeUnitExponent == 3)
        #expect(
            request.source.positions.components[0].bitPattern
                == (-0.0).bitPattern
        )
        #expect(request.sourceIdentity == sourceIdentity)
        #expect(request.sourceProvenance == mismatchedProvenance)
        #expect(request.limits.maximumVertexCount == 0)
        #expect(request.limits.maximumTriangleCount == UInt64.max)
        #expect(request.limits.maximumAdditionalLogicalByteCount == 0)
        #expect(publication.outputObjectID.rawValue == "volume-measurement-1")
        #expect(
            publication.outputProvenanceID.rawValue == "volume-record-1"
        )
        #expect(publication.createdAt.utcString == "2026-08-06T09:10:00Z")

        requireSendable(TriangleMeshEnclosedVolumeError.self)
        requireSendable(TriangleMeshEnclosedVolumeLimits.self)
        requireSendable(TriangleMeshEnclosedVolumeRequest.self)
        requireSendable(TriangleMeshEnclosedVolumePublicationContext.self)
        requireSendable(TriangleMeshEnclosedVolumeMeasurement.self)
        requireSendable(TriangleMeshEnclosedVolumeResult.self)

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

        let errors: [TriangleMeshEnclosedVolumeError] = [
            .invalidLimits,
            .invalidSource,
            .resourceLimitExceeded,
            .degenerateFacet,
            .openSurface,
            .nonManifoldOrientation,
            .invertedOrientation,
            .volumeNotRepresentable,
            .cancelled,
            .publicationFailed,
        ]
        let expectedNames = [
            "invalidLimits",
            "invalidSource",
            "resourceLimitExceeded",
            "degenerateFacet",
            "openSurface",
            "nonManifoldOrientation",
            "invertedOrientation",
            "volumeNotRepresentable",
            "cancelled",
            "publicationFailed",
        ]
        #expect(errors.map { String(describing: $0) } == expectedNames)
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    @Test(
        "[Unit][VOX-META-004][VOX-META-005] parameter digest binds the ten fixed rules"
    )
    func parameterDigestBindsFrozenSchema() throws {
        let document =
            try TriangleMeshEnclosedVolumeRequest
            .parameterDocument()
        let digest = try TriangleMeshEnclosedVolumeRequest.parameterDigest()

        #expect(document == (try independentParameterDocument()))
        #expect(document.count == 1_903)
        #expect(
            TriangleMeshEnclosedVolumeRequest
                .parameterDocumentMaximumOutputByteCount == 65_536
        )
        #expect(digest == (try independentParameterDigest()))

        let text = String(decoding: document, as: UTF8.self)
        #expect(!text.contains("volume-source-mesh-1"))
        #expect(!text.contains("volume-source-record-1"))
        #expect(!text.contains("volume-measurement-1"))
        #expect(!text.contains("maximumVertexCount"))
        #expect(!text.contains("Voxelia Test Publisher"))
        // The source coordinate unit never enters the digest: the arithmetic
        // does not read it and the measurement already publishes it.
        #expect(!text.contains("UCUM"))
        #expect(!text.contains("\"mm\""))

        // Host execution policy cannot move the digest.
        let narrow = TriangleMeshEnclosedVolumeLimits(
            maximumVertexCount: 1,
            maximumTriangleCount: 1,
            maximumAdditionalLogicalByteCount: 1
        )
        let wide = TriangleMeshEnclosedVolumeLimits(
            maximumVertexCount: UInt64.max,
            maximumTriangleCount: UInt64.max,
            maximumAdditionalLogicalByteCount: UInt64.max
        )
        _ = try request(limits: narrow)
        _ = try request(limits: wide)
        #expect(
            try TriangleMeshEnclosedVolumeRequest.parameterDigest() == digest
        )
        #expect(digest != (try emptyParameterDigest()))
    }

    @Test(
        "[Unit][VOX-GEO-010][VOX-ERR-001] measurement admission rejects every non-volume value"
    )
    func measurementAdmissionRejectsNonVolumeValues() throws {
        let unit = try volumeUnit()
        let measurement = try TriangleMeshEnclosedVolumeMeasurement(
            value: 3,
            unit: unit,
            facetCount: 1
        )
        #expect(measurement.value == 3)
        #expect(measurement.facetCount == 1)
        #expect(measurement.unit.exponent == 3)
        #expect(measurement.unit.base.code == "mm")

        // Positive zero over zero facets is the admitted empty-mesh total.
        let empty = try TriangleMeshEnclosedVolumeMeasurement(
            value: 0,
            unit: unit,
            facetCount: 0
        )
        #expect(empty.value.bitPattern == (0.0).bitPattern)
        #expect(empty.facetCount == 0)

        for rejected in [
            Double.nan,
            .signalingNaN,
            .infinity,
            -.infinity,
            -1,
            -.leastNonzeroMagnitude,
            -0.0,
        ] {
            #expect(throws: TriangleMeshEnclosedVolumeError.publicationFailed) {
                _ = try TriangleMeshEnclosedVolumeMeasurement(
                    value: rejected,
                    unit: unit,
                    facetCount: 1
                )
            }
        }

        let areaUnit = try PoweredLengthUnit(
            base: try lengthUnit(),
            exponent: 2
        )
        #expect(throws: TriangleMeshEnclosedVolumeError.publicationFailed) {
            _ = try TriangleMeshEnclosedVolumeMeasurement(
                value: 3,
                unit: areaUnit,
                facetCount: 1
            )
        }
        let lengthPower = try PoweredLengthUnit(
            base: try lengthUnit(),
            exponent: 1
        )
        #expect(throws: TriangleMeshEnclosedVolumeError.publicationFailed) {
            _ = try TriangleMeshEnclosedVolumeMeasurement(
                value: 3,
                unit: lengthPower,
                facetCount: 1
            )
        }
    }

    @Test(
        "[Unit][VOX-META-003][VOX-GEO-010] result binding proves claim coherence and unit derivation"
    )
    func resultBindingProvesClaimCoherenceAndUnitDerivation() throws {
        let request = try request()
        let publication = try publicationContext()
        let measurement = try measurement()
        let identity = try outputIdentity(
            request: request,
            publication: publication
        )
        let provenance = try outputProvenance(
            request: request,
            publication: publication
        )

        let result = try TriangleMeshEnclosedVolumeResult(
            measurement: measurement,
            identity: identity,
            provenance: provenance,
            request: request,
            publication: publication
        )
        #expect(result.measurement.value == 3)
        #expect(result.measurement.facetCount == 1)
        #expect(
            result.measurement.unit.base == request.source.coordinateSpace.unit
        )
        #expect(result.identity.objectID == publication.outputObjectID)
        #expect(result.provenance.id == publication.outputProvenanceID)
        // The measurement result republishes no mesh domain.
        #expect(Mirror(reflecting: result).children.count == 3)
    }

    @Test(
        "[Unit][VOX-ERR-001][VOX-META-003] result binding rejects every incoherent publication"
    )
    func resultBindingRejectsIncoherentPublications() throws {
        let request = try request()
        let publication = try publicationContext()
        let measurement = try measurement()
        let otherObjectID = try #require(DataObjectID(rawValue: "other-object"))
        let otherProvenanceID = try #require(
            ProvenanceID(rawValue: "other-record")
        )
        let otherVersion = try SemanticVersion(major: 1, minor: 0, patch: 1)

        // A mismatched source claim fails before any output binding.
        let mismatchedRequest = TriangleMeshEnclosedVolumeRequest(
            source: request.source,
            sourceIdentity: request.sourceIdentity,
            sourceProvenance: try sourceProvenance(
                subjectObjectID: otherObjectID
            ),
            limits: request.limits
        )
        try expectPublicationFailure(
            measurement: measurement,
            identity: try outputIdentity(
                request: mismatchedRequest,
                publication: publication
            ),
            provenance: try outputProvenance(
                request: mismatchedRequest,
                publication: publication
            ),
            request: mismatchedRequest,
            publication: publication
        )

        let brokenIdentities: [DataIdentity] = [
            try outputIdentity(
                request: request,
                publication: publication,
                objectID: otherObjectID
            ),
            try outputIdentity(
                request: request,
                publication: publication,
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [9]
                )
            ),
            try outputIdentity(
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
            try outputIdentity(
                request: request,
                publication: publication,
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [0]
                ),
                includeDerivation: false
            ),
            try outputIdentity(
                request: request,
                publication: publication,
                operationID: "org.voxelia.op.triangle-mesh-enclosed-volumes"
            ),
            try outputIdentity(
                request: request,
                publication: publication,
                parameterDigest: try emptyParameterDigest()
            ),
            try outputIdentity(
                request: request,
                publication: publication,
                operationVersion: otherVersion
            ),
            try outputIdentity(
                request: request,
                publication: publication,
                includeImplementation: false
            ),
            try outputIdentity(
                request: request,
                publication: publication,
                inputRole: "source"
            ),
            try outputIdentity(
                request: request,
                publication: publication,
                inputObjectID: otherObjectID
            ),
            try outputIdentity(
                request: request,
                publication: publication,
                inputCount: 2
            ),
        ]
        for identity in brokenIdentities {
            try expectPublicationFailure(
                measurement: measurement,
                identity: identity,
                provenance: try outputProvenance(
                    request: request,
                    publication: publication
                ),
                request: request,
                publication: publication
            )
        }

        let brokenProvenances: [ProvenanceRecord] = [
            try outputProvenance(
                request: request,
                publication: publication,
                provenanceID: otherProvenanceID
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                subjectObjectID: otherObjectID
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                createdAt: try CanonicalInstant(
                    utcString: "2026-08-06T09:11:00Z"
                )
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                software: try SoftwareIdentity(
                    name: "Other Publisher",
                    version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                    commit: nil,
                    buildIdentifier: nil
                )
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                kind: .processed
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                inputRole: "source"
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                occurrence: 2
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                inputObjectID: otherObjectID
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                parentID: otherProvenanceID
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                operationID:
                    "org.voxelia.op.triangle-mesh-enclosed-volumes"
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                operationVersion: otherVersion
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                implementationVersion: otherVersion
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                parameterDigest: try emptyParameterDigest()
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                inputCount: 2
            ),
            try outputProvenance(
                request: request,
                publication: publication,
                includeWarning: true
            ),
        ]
        for provenance in brokenProvenances {
            try expectPublicationFailure(
                measurement: measurement,
                identity: try outputIdentity(
                    request: request,
                    publication: publication
                ),
                provenance: provenance,
                request: request,
                publication: publication
            )
        }
    }

    @Test(
        "[Unit][VOX-GEO-010][VOX-META-003] result binding rejects a drifted facet count or base unit"
    )
    func resultBindingRejectsDriftedFacetCountOrBaseUnit() throws {
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

        for facetCount in [UInt64.zero, 2, UInt64.max] {
            try expectPublicationFailure(
                measurement: try measurement(facetCount: facetCount),
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }

        // A different code, namespace, dimension or conversion field is a
        // different unit and cannot be published as the source space's.
        let drifted = [
            try MeasurementUnit(
                namespace: "UCUM",
                code: "cm",
                dimension: .length
            ),
            try MeasurementUnit(
                namespace: "DICOM",
                code: "mm",
                dimension: .length
            ),
            try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length,
                scaleToCanonical: 1
            ),
            try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length,
                offsetToCanonical: 0
            ),
            // MeasurementUnit equality ignores presentation text, so exact
            // publication binding must still reject a drifted display name.
            try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                displayName: "millimetre",
                dimension: .length
            ),
        ]
        for base in drifted {
            try expectPublicationFailure(
                measurement: try TriangleMeshEnclosedVolumeMeasurement(
                    value: 3,
                    unit: try PoweredLengthUnit(base: base, exponent: 3),
                    facetCount: 1
                ),
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }
        #expect(
            drifted.last?.displayName == "millimetre"
        )
        #expect(try drifted[4] == lengthUnit())
    }

    // MARK: - Helpers

    private func request(
        limits: TriangleMeshEnclosedVolumeLimits =
            TriangleMeshEnclosedVolumeLimits(
                maximumVertexCount: 1_024,
                maximumTriangleCount: 1_024,
                maximumAdditionalLogicalByteCount: 1_048_576
            )
    ) throws -> TriangleMeshEnclosedVolumeRequest {
        TriangleMeshEnclosedVolumeRequest(
            source: try sourceMesh(),
            sourceIdentity: try sourceIdentity(),
            sourceProvenance: try sourceProvenance(),
            limits: limits
        )
    }

    private func publicationContext()
        throws -> TriangleMeshEnclosedVolumePublicationContext
    {
        TriangleMeshEnclosedVolumePublicationContext(
            outputObjectID: try #require(
                DataObjectID(rawValue: "volume-measurement-1")
            ),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "volume-record-1")
            ),
            createdAt: try CanonicalInstant(
                utcString: "2026-08-06T09:10:00Z"
            ),
            software: try SoftwareIdentity(
                name: "Voxelia Test Publisher",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: "test-commit",
                buildIdentifier: nil
            )
        )
    }

    private func measurement(
        value: Double = 3,
        facetCount: UInt64 = 1
    ) throws -> TriangleMeshEnclosedVolumeMeasurement {
        try TriangleMeshEnclosedVolumeMeasurement(
            value: value,
            unit: try volumeUnit(),
            facetCount: facetCount
        )
    }

    private func lengthUnit() throws -> MeasurementUnit {
        try MeasurementUnit(
            namespace: "UCUM",
            code: "mm",
            dimension: .length
        )
    }

    private func volumeUnit() throws -> PoweredLengthUnit {
        try PoweredLengthUnit(base: try lengthUnit(), exponent: 3)
    }

    private func sourceMesh() throws -> TriangleMesh {
        try TriangleMesh(
            positions: try TriangleMeshPositionDomain(
                coordinateSpace: try coordinateSpace(id: "mesh-space"),
                components: [-0.0, 0, 0, 2, 0, 0, 0, 3, 0]
            ),
            topology: try TriangleMeshTopology(
                vertexCount: 3,
                indices: [0, 1, 2]
            ),
            vertexAttributes: []
        )
    }

    private func sourceIdentity() throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(
                DataObjectID(rawValue: "volume-source-mesh-1")
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
                ProvenanceID(rawValue: "volume-source-record-1")
            ),
            kind: .source,
            createdAt: try CanonicalInstant(
                utcString: "2026-08-06T09:00:00Z"
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
        request: TriangleMeshEnclosedVolumeRequest,
        publication: TriangleMeshEnclosedVolumePublicationContext,
        objectID: DataObjectID? = nil,
        contentID: ContentID? = nil,
        sourceIdentities: ContiguousArray<SourceIdentity> = [],
        includeDerivation: Bool = true,
        operationID: String =
            TriangleMeshEnclosedVolumeRequest.operationIdentifier,
        parameterDigest: ContentID? = nil,
        operationVersion: SemanticVersion? = nil,
        includeImplementation: Bool = true,
        implementationID: String =
            "org.voxelia.impl.triangle-mesh-enclosed-volume.cpu",
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
            ?? TriangleMeshEnclosedVolumeRequest.parameterDigest())
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
        request: TriangleMeshEnclosedVolumeRequest,
        publication: TriangleMeshEnclosedVolumePublicationContext,
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
            TriangleMeshEnclosedVolumeRequest.operationIdentifier,
        operationVersion: SemanticVersion? = nil,
        implementationID: String =
            "org.voxelia.impl.triangle-mesh-enclosed-volume.cpu",
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
            ?? TriangleMeshEnclosedVolumeRequest.parameterDigest())
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
            activity: .operation(operation, try executionClaim()),
            inputs: inputs,
            warnings: warnings,
            validationClaim: .unknown,
            declaresZeroInputGenerator: inputCount == 0
        )
    }

    private func executionClaim() throws -> ExecutionProvenanceClaim {
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
        let namespace = "org.voxelia.op.triangle-mesh-enclosed-volume"
        return try CanonicalMetadataJSON.encodeUniqueDocument(
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
        measurement: TriangleMeshEnclosedVolumeMeasurement,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: TriangleMeshEnclosedVolumeRequest,
        publication: TriangleMeshEnclosedVolumePublicationContext
    ) throws {
        #expect(throws: TriangleMeshEnclosedVolumeError.publicationFailed) {
            _ = try TriangleMeshEnclosedVolumeResult(
                measurement: measurement,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        }
    }

    private func coordinateSpace(
        id: String
    ) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try lengthUnit(),
            externalReferences: []
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
