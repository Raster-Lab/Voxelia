// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

/// Internal cancellation sites frozen by `ADR-0192` and `ALG-0029`.
enum CPULabelledSurfaceCancellationCheckpoint: Sendable, Equatable {
    case admission
    case labelValidation(UInt64)
    case sampleValidation(UInt64)
    case cell(UInt64)
    case final
}

typealias CPULabelledSurfaceCancellationProbe =
    @Sendable (CPULabelledSurfaceCancellationCheckpoint) -> Bool

/// The deterministic CPU labelled-surface extraction operation.
///
/// The operation performs one coordinated full source read, executes the exact
/// `freudenthal-label-set-surface/binary64-v1` reference kernel, checks final
/// cancellation, and atomically returns the complete mesh, identity and
/// transformed provenance aggregate. It never mints identifiers, reads a
/// clock, publishes through mutable host state, or exposes partial results.
/// The type is stateless and supports concurrent calls; each supplied
/// coordinator and source storage retain their own documented isolation and
/// may observe read/accounting effects even when execution fails.
public enum CPULabelledSurfaceExtractionOperation {
    /// The exact registered CPU implementation token spelling.
    public static let implementationIdentifier =
        "org.voxelia.impl.labelled-surface-extraction.cpu"

    /// Executes one admitted labelled-surface request and atomically returns
    /// its immutable publication aggregate.
    ///
    /// Exact integer decoding, requested-set membership, midpoint placement
    /// and affine mapping follow the ordering frozen by `ADR-0192` and
    /// `VOXELIA-ALG-0029`. The caller supplies explicit output ceilings,
    /// identifiers, completion instant and software identity. Cancellation or
    /// any typed failure returns no publication aggregate and does not mutate a
    /// host publication destination; the coordinated source read and accounting
    /// remain observable service effects.
    ///
    /// - Parameters:
    ///   - request: The immutable source, exact label set and output limits.
    ///   - publication: Caller authority for output identity and provenance.
    ///   - coordinator: The bounded service used for exactly one full read.
    /// - Returns: A structurally bound mesh/identity/provenance aggregate. This
    ///   does not claim source-graph admission, execution authenticity,
    ///   diagnostic validation or canonical mesh-content assurance.
    /// - Throws: A payload-free `LabelledSurfaceExtractionError` using the
    ///   operation's fixed failure precedence.
    public static func execute(
        request: LabelledSurfaceExtractionRequest,
        publication: LabelledSurfaceExtractionPublicationContext,
        coordinator: StorageReadCoordinator
    ) async throws -> LabelledSurfaceExtractionResult {
        try await execute(
            request: request,
            publication: publication,
            coordinator: coordinator,
            cancellation: { _ in Task.isCancelled }
        )
    }

    static func execute(
        request: LabelledSurfaceExtractionRequest,
        publication: LabelledSurfaceExtractionPublicationContext,
        coordinator: StorageReadCoordinator,
        cancellation: @escaping CPULabelledSurfaceCancellationProbe
    ) async throws -> LabelledSurfaceExtractionResult {
        let mesh = try await extractMesh(
            request: request,
            coordinator: coordinator,
            cancellation: cancellation,
            checksFinalCancellation: false
        )
        if cancellation(.final) {
            throw LabelledSurfaceExtractionError.cancelled
        }
        return try assembleResult(
            mesh: mesh,
            request: request,
            publication: publication
        )
    }

    static func extractMesh(
        request: LabelledSurfaceExtractionRequest,
        coordinator: StorageReadCoordinator,
        cancellation: @escaping CPULabelledSurfaceCancellationProbe = { _ in
            Task.isCancelled
        },
        checksFinalCancellation: Bool = true
    ) async throws -> TriangleMesh {
        if cancellation(.admission) {
            throw LabelledSurfaceExtractionError.cancelled
        }
        guard
            request.limits.maximumSelectedLabelCount > 0,
            request.limits.maximumSelectedLabelCount
                <= LabelledSurfaceExtractionRequest.maximumSupportedLabelCount,
            request.limits.maximumVertexCount > 0,
            request.limits.maximumTriangleCount > 0
        else {
            throw LabelledSurfaceExtractionError.invalidLimits
        }

        try validateSelectedLabels(
            request.selectedLabels,
            maximumCount: request.limits.maximumSelectedLabelCount,
            cancellation: cancellation
        )
        let admission = try LabelledSurfaceSourceAdmission(request: request)

        let fullRegion: ImageRegion
        do {
            fullRegion = try ImageRegion(
                lowerBounds: [0, 0, 0],
                upperBounds: admission.extents
            )
        } catch {
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }

        let read: CoordinatedReadResult
        do {
            read = try await coordinator.read(
                from: request.source.storage,
                region: fullRegion
            )
        } catch let error as StorageContractError {
            if error == .cancelled || Task.isCancelled {
                throw LabelledSurfaceExtractionError.cancelled
            }
            throw LabelledSurfaceExtractionError.sourceReadFailed
        } catch {
            if Task.isCancelled {
                throw LabelledSurfaceExtractionError.cancelled
            }
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }

        // RegionReadResult already owns immutable packed bytes. Retain that
        // value locally, then release the coordinator's budget token before
        // decoder validation or numerical traversal.
        let stagedBytes = read.result.bytes
        do {
            try await coordinator.release(read.retention)
        } catch {
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }

        let source = try LabelledSurfaceSourceAdapter(
            request: request,
            admission: admission,
            bytes: stagedBytes
        )
        try source.validateSamples(cancellation: cancellation)
        return try LabelledSurfaceReferenceKernel.extract(
            request: request,
            source: source,
            cancellation: cancellation,
            checksFinalCancellation: checksFinalCancellation
        )
    }

    static func assembleResult(
        mesh: TriangleMesh,
        request: LabelledSurfaceExtractionRequest,
        publication: LabelledSurfaceExtractionPublicationContext
    ) throws -> LabelledSurfaceExtractionResult {
        do {
            let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
            let operation = try DerivationOperationToken(
                rawValue: LabelledSurfaceExtractionRequest.operationIdentifier
            )
            let implementation = try DerivationOperationToken(
                rawValue: Self.implementationIdentifier
            )
            let parameterDigest = try parameterDigest(
                for: request.selectedLabels
            )
            let sourceIdentity = DataIdentityReference.object(
                request.source.identity.objectID
            )
            let derivation = try DerivationIdentity(
                operationID: operation,
                operationVersion: version,
                implementation: DerivationImplementationReference(
                    identifier: implementation,
                    version: version
                ),
                inputs: [
                    DerivationInput(
                        role: try DerivationInputRole(
                            rawValue: "source-volume"
                        ),
                        identity: sourceIdentity
                    )
                ],
                parameterDigest: parameterDigest,
                declaresZeroInputGenerator: false
            )
            let identity = try DataIdentity(
                objectID: publication.outputObjectID,
                contentID: nil,
                sourceIdentities: [],
                derivation: derivation
            )
            let operationClaim = try OperationProvenance(
                operationID: operation,
                operationVersion: version,
                implementationID: implementation,
                implementationVersion: version,
                parameterDigest: parameterDigest
            )
            let executionClaim = try ExecutionProvenanceClaim(
                profile: ExecutionComponentReference(
                    identifier: ExecutionClaimToken(
                        rawValue: "org.voxelia.profile.default"
                    ),
                    version: version
                ),
                backend: ExecutionComponentReference(
                    identifier: ExecutionClaimToken(
                        rawValue: CPUBackendRegistrations.backendIdentifier
                    ),
                    version: version
                ),
                precisionPolicy: ExecutionClaimToken(
                    rawValue: "org.voxelia.precision.binary64-strict"
                ),
                qualityPolicy: ExecutionClaimToken(
                    rawValue: "org.voxelia.quality.full"
                ),
                approximationStatus: .exact,
                capabilityClass: nil,
                kernel: nil
            )
            let provenance = try ProvenanceRecord(
                id: publication.outputProvenanceID,
                kind: .transformed,
                createdAt: publication.createdAt,
                subject: .object(publication.outputObjectID),
                software: publication.software,
                activity: .operation(operationClaim, executionClaim),
                inputs: [
                    ProvenanceInput(
                        role: try ProvenanceInputRole(
                            rawValue: "source-volume"
                        ),
                        occurrence: 1,
                        identity: sourceIdentity,
                        parent: .graphNode(request.source.provenance.id)
                    )
                ],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            )
            return try LabelledSurfaceExtractionResult(
                mesh: mesh,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        } catch {
            throw LabelledSurfaceExtractionError.publicationFailed
        }
    }

    private static func parameterDigest(
        for selectedLabels: LabelledSurfaceLabelSet
    ) throws -> ContentID {
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
        let namespace = LabelledSurfaceExtractionRequest.operationIdentifier
        let parameters = try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "algorithm-identifier"
                ),
                value: .string(
                    LabelledSurfaceExtractionRequest.algorithmIdentifier
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
                value: .string("exact-decoded-label-in-requested-set"),
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
        ])
        let document = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: parameters,
            maximumOutputByteCount: 4_194_304
        )
        return try ContentID.operationParametersIdentity(
            overCanonicalBytes: document
        )
    }

    private static func validateSelectedLabels(
        _ selectedLabels: LabelledSurfaceLabelSet,
        maximumCount: UInt64,
        cancellation: CPULabelledSurfaceCancellationProbe
    ) throws {
        switch selectedLabels {
        case .signed(let labels):
            try validateLabels(
                labels,
                maximumCount: maximumCount,
                cancellation: cancellation
            )
        case .unsigned(let labels):
            try validateLabels(
                labels,
                maximumCount: maximumCount,
                cancellation: cancellation
            )
        }
    }

    private static func validateLabels<Value: Comparable>(
        _ labels: ContiguousArray<Value>,
        maximumCount: UInt64,
        cancellation: CPULabelledSurfaceCancellationProbe
    ) throws {
        guard !labels.isEmpty else {
            throw LabelledSurfaceExtractionError.invalidLabelSet
        }
        guard UInt64(labels.count) <= maximumCount else {
            throw LabelledSurfaceExtractionError.resourceLimitExceeded
        }
        for index in labels.indices {
            if index.isMultiple(of: 4_096),
                cancellation(.labelValidation(UInt64(index)))
            {
                throw LabelledSurfaceExtractionError.cancelled
            }
            if index > labels.startIndex,
                labels[index - 1] >= labels[index]
            {
                throw LabelledSurfaceExtractionError.invalidLabelSet
            }
        }
    }
}
