// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

/// The deterministic CPU triangle-mesh vertex-normal generation operation.
///
/// The operation executes the exact
/// `triangle-area-weighted-vertex-normals/binary64-v1` serial reference,
/// checks final cancellation, and atomically returns the complete mesh,
/// identity and transformed provenance aggregate. It never mints identifiers,
/// reads a clock, publishes through mutable host state, or exposes partial
/// normals. The type is stateless and supports concurrent calls.
public enum CPUTriangleMeshVertexNormalGenerationOperation {
    /// The exact registered CPU implementation token spelling.
    public static let implementationIdentifier =
        "org.voxelia.impl.triangle-mesh-vertex-normal-generation.cpu"

    /// Executes one admitted vertex-normal request and atomically returns its
    /// immutable publication aggregate.
    ///
    /// Triangle traversal, area-weighted accumulation, normalization and
    /// little-endian serialization follow the exact binary64 ordering frozen
    /// by `ADR-0193` and `VOXELIA-ALG-0030`. The caller supplies explicit host
    /// ceilings, identifiers, completion instant and software identity.
    /// Cancellation or any typed failure returns no publication aggregate.
    /// The source identity and provenance are structurally corresponding
    /// claims only; until a canonical mesh projection exists, this operation
    /// does not establish that they cryptographically bind the source mesh.
    ///
    /// - Parameters:
    ///   - request: The immutable source mesh, source claims and host limits.
    ///   - publication: Caller authority for output identity and provenance.
    /// - Returns: A structurally bound mesh/identity/provenance aggregate. This
    ///   does not claim source-graph admission, execution authenticity,
    ///   diagnostic validation or canonical mesh-content assurance.
    /// - Throws: A payload-free
    ///   `TriangleMeshVertexNormalGenerationError` using the operation's
    ///   fixed failure precedence.
    public static func execute(
        request: TriangleMeshVertexNormalGenerationRequest,
        publication: TriangleMeshVertexNormalGenerationPublicationContext
    ) async throws -> TriangleMeshVertexNormalGenerationResult {
        try execute(
            request: request,
            publication: publication,
            cancellation: { _ in Task.isCancelled }
        )
    }

    static func execute(
        request: TriangleMeshVertexNormalGenerationRequest,
        publication: TriangleMeshVertexNormalGenerationPublicationContext,
        cancellation: CPUTriangleMeshVertexNormalCancellationProbe
    ) throws -> TriangleMeshVertexNormalGenerationResult {
        let mesh = try TriangleMeshVertexNormalReferenceKernel.generate(
            request: request,
            cancellation: cancellation,
            checksFinalCancellation: false
        )
        if cancellation(.final) {
            throw TriangleMeshVertexNormalGenerationError.cancelled
        }
        return try assembleResult(
            mesh: mesh,
            request: request,
            publication: publication
        )
    }

    static func assembleResult(
        mesh: TriangleMesh,
        request: TriangleMeshVertexNormalGenerationRequest,
        publication: TriangleMeshVertexNormalGenerationPublicationContext
    ) throws -> TriangleMeshVertexNormalGenerationResult {
        do {
            let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
            let operation = try DerivationOperationToken(
                rawValue: TriangleMeshVertexNormalGenerationRequest
                    .operationIdentifier
            )
            let implementation = try DerivationOperationToken(
                rawValue: Self.implementationIdentifier
            )
            let parameterDigest = try parameterDigest()
            let sourceIdentity = DataIdentityReference.object(
                request.sourceIdentity.objectID
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
                            rawValue: "source-mesh"
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
                            rawValue: "source-mesh"
                        ),
                        occurrence: 1,
                        identity: sourceIdentity,
                        parent: .graphNode(request.sourceProvenance.id)
                    )
                ],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            )
            return try TriangleMeshVertexNormalGenerationResult(
                mesh: mesh,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        } catch {
            throw TriangleMeshVertexNormalGenerationError.publicationFailed
        }
    }

    /// Reconstructs the frozen VCMJ-1 parameters independently of Geometry's
    /// structural result validator.
    private static func parameterDigest() throws -> ContentID {
        let namespace =
            TriangleMeshVertexNormalGenerationRequest.operationIdentifier
        let parameters = try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "algorithm-identifier"
                ),
                value: .string(
                    TriangleMeshVertexNormalGenerationRequest
                        .algorithmIdentifier
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
        let document = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: parameters,
            maximumOutputByteCount: 65_536
        )
        return try ContentID.operationParametersIdentity(
            overCanonicalBytes: document
        )
    }
}
