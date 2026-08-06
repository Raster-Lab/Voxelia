// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

/// Internal cancellation sites frozen by `ADR-0191` and `ALG-0028`.
enum CPUScalarSurfaceCancellationCheckpoint: Sendable, Equatable {
    case admission
    case sampleValidation(UInt64)
    case cell(UInt64)
    case final
}

typealias CPUScalarSurfaceCancellationProbe =
    @Sendable (CPUScalarSurfaceCancellationCheckpoint) -> Bool

/// The deterministic CPU scalar-surface extraction operation.
///
/// The operation performs one coordinated full source read, executes the exact
/// `freudenthal-surface-extraction/binary64-v1` reference kernel, checks final
/// cancellation, and atomically returns the complete mesh, identity and
/// transformed provenance aggregate. It never mints identifiers, reads a
/// clock, publishes through mutable host state, or exposes partial results.
/// The type is stateless and supports concurrent calls; each supplied
/// coordinator and source storage retain their own documented isolation and
/// may observe read/accounting effects even when execution fails.
public enum CPUScalarSurfaceExtractionOperation {
    /// The exact registered CPU implementation token spelling.
    public static let implementationIdentifier =
        "org.voxelia.impl.scalar-surface-extraction.cpu"

    /// Executes one admitted scalar-surface request and atomically returns its
    /// immutable publication aggregate.
    ///
    /// Source decoding, value transformation, interpolation and affine mapping
    /// follow the exact binary64 ordering frozen by `ADR-0191` and
    /// `VOXELIA-ALG-0028`. The caller supplies explicit output ceilings,
    /// identifiers, completion instant and software identity. Cancellation or
    /// any typed failure returns no publication aggregate and does not mutate a
    /// host publication destination; the coordinated source read and accounting
    /// remain observable service effects.
    ///
    /// - Parameters:
    ///   - request: The immutable source, isovalue and required output limits.
    ///   - publication: Caller authority for output identity and provenance.
    ///   - coordinator: The bounded service used for exactly one full read.
    /// - Returns: A structurally bound mesh/identity/provenance aggregate. This
    ///   does not claim source-graph admission, execution authenticity,
    ///   diagnostic validation or canonical mesh-content assurance.
    /// - Throws: A payload-free `ScalarSurfaceExtractionError` using the
    ///   operation's fixed failure precedence.
    /// - Parameter progress: Receives the `VOXELIA-ALG-0046` sequence over both
    ///   passes — sample validation at the 4,096 cadence and the cell traversal
    ///   at 64. It is **required, never defaulted** on this public entry point;
    ///   pass `discardingProgressObserver` to report nothing.
    public static func execute(
        request: ScalarSurfaceExtractionRequest,
        publication: ScalarSurfaceExtractionPublicationContext,
        coordinator: StorageReadCoordinator,
        progress: @escaping ProgressObserver
    ) async throws -> ScalarSurfaceExtractionResult {
        try await execute(
            request: request,
            publication: publication,
            coordinator: coordinator,
            cancellation: { _ in Task.isCancelled },
            progress: progress
        )
    }

    static func execute(
        request: ScalarSurfaceExtractionRequest,
        publication: ScalarSurfaceExtractionPublicationContext,
        coordinator: StorageReadCoordinator,
        cancellation: @escaping CPUScalarSurfaceCancellationProbe,
        progress: @escaping ProgressObserver
    ) async throws -> ScalarSurfaceExtractionResult {
        let mesh = try await extractMesh(
            request: request,
            coordinator: coordinator,
            cancellation: cancellation,
            progress: progress,
            checksFinalCancellation: false
        )
        if cancellation(.final) {
            throw ScalarSurfaceExtractionError.cancelled
        }
        return try assembleResult(
            mesh: mesh,
            request: request,
            publication: publication
        )
    }

    static func extractMesh(
        request: ScalarSurfaceExtractionRequest,
        coordinator: StorageReadCoordinator,
        cancellation: @escaping CPUScalarSurfaceCancellationProbe = { _ in
            Task.isCancelled
        },
        progress: @escaping ProgressObserver = discardingProgressObserver,
        checksFinalCancellation: Bool = true
    ) async throws -> TriangleMesh {
        if cancellation(.admission) {
            throw ScalarSurfaceExtractionError.cancelled
        }
        guard
            request.limits.maximumVertexCount > 0,
            request.limits.maximumTriangleCount > 0
        else {
            throw ScalarSurfaceExtractionError.invalidLimits
        }

        let admission = try ScalarSurfaceSourceAdmission(request: request)
        guard request.isovalue.isFinite else {
            throw ScalarSurfaceExtractionError.nonFiniteIsovalue
        }

        let fullRegion: ImageRegion
        do {
            fullRegion = try ImageRegion(
                lowerBounds: [0, 0, 0],
                upperBounds: admission.extents
            )
        } catch {
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }

        let read: CoordinatedReadResult
        do {
            read = try await coordinator.read(
                from: request.source.storage,
                region: fullRegion
            )
        } catch let error as StorageContractError {
            if error == .cancelled || Task.isCancelled {
                throw ScalarSurfaceExtractionError.cancelled
            }
            throw ScalarSurfaceExtractionError.sourceReadFailed
        } catch {
            if Task.isCancelled {
                throw ScalarSurfaceExtractionError.cancelled
            }
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }

        // RegionReadResult already owns immutable packed bytes. Retain that
        // value locally, then release the coordinator's budget token before
        // any transform admission, validation or numerical traversal.
        let stagedBytes = read.result.bytes
        do {
            try await coordinator.release(read.retention)
        } catch {
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }

        let source = try ScalarSurfaceSourceAdapter(
            request: request,
            admission: admission,
            bytes: stagedBytes
        )
        // Two passes with DIFFERENT cadences: sample validation at 4,096 and
        // the cell traversal at 64. The total is the work performed, and each
        // pass carries its own base so the combined sequence stays monotone.
        let totalWork = admission.sampleCount + Int(admission.cellCount)
        try source.validateFiniteSamples(
            cancellation: cancellation,
            progress: progress,
            totalWork: totalWork
        )
        return try ScalarSurfaceReferenceKernel.extract(
            request: request,
            source: source,
            cancellation: cancellation,
            progress: progress,
            progressBase: admission.sampleCount,
            totalWork: totalWork,
            checksFinalCancellation: checksFinalCancellation
        )
    }

    static func assembleResult(
        mesh: TriangleMesh,
        request: ScalarSurfaceExtractionRequest,
        publication: ScalarSurfaceExtractionPublicationContext
    ) throws -> ScalarSurfaceExtractionResult {
        do {
            let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
            let operation = try DerivationOperationToken(
                rawValue: ScalarSurfaceExtractionRequest.operationIdentifier
            )
            let implementation = try DerivationOperationToken(
                rawValue: Self.implementationIdentifier
            )
            let parameterDigest = try parameterDigest(for: request.isovalue)
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
            return try ScalarSurfaceExtractionResult(
                mesh: mesh,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        } catch {
            throw ScalarSurfaceExtractionError.publicationFailed
        }
    }

    static func parameterDigest(for isovalue: Double) throws -> ContentID {
        let namespace = ScalarSurfaceExtractionRequest.operationIdentifier
        let parameters = try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "algorithm-identifier"
                ),
                value: .string(
                    ScalarSurfaceExtractionRequest.algorithmIdentifier
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
        ])
        return try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: parameters,
                maximumOutputByteCount: 65_536
            )
        )
    }
}
