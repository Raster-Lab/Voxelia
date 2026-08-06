// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

/// The deterministic CPU triangle-mesh enclosed-volume operation.
///
/// The operation first **certifies** that the source mesh is a closed,
/// edge-manifold, consistently oriented surface, then executes the exact
/// `triangle-mesh-enclosed-volume/binary64-v1` serial reference, checks final
/// cancellation, and atomically returns the measurement, identity and
/// transformed provenance aggregate. No arithmetic runs for an uncertified
/// surface. It never mints identifiers, reads a clock, publishes through
/// mutable host state, or exposes a partial total. The type is stateless and
/// supports concurrent calls.
///
/// Two properties are deliberately **not** certified and a consumer must know
/// both. Vertex manifoldness is not required, because the divergence identity
/// does not need a single-cycle vertex link. Non-self-intersection is not
/// certified: for a closed oriented surface that intersects itself the frozen
/// sum is the winding-number-weighted signed volume rather than the enclosed
/// volume. `ADR-0195` records why, and both limitations are entries in the
/// operation's parameter document, so they travel inside every result's
/// digest rather than living only in documentation.
public enum CPUTriangleMeshEnclosedVolumeOperation {
    /// The exact registered CPU implementation token spelling.
    public static let implementationIdentifier =
        "org.voxelia.impl.triangle-mesh-enclosed-volume.cpu"

    /// Executes one admitted enclosed-volume request and atomically returns
    /// its immutable publication aggregate.
    ///
    /// Certification, the origin-anchored scalar triple product, the serial
    /// accumulation and the single final division follow the exact binary64
    /// ordering frozen by `ADR-0195` and `VOXELIA-ALG-0032`. The caller supplies explicit host
    /// ceilings, identifiers, completion instant and software identity.
    /// Cancellation or any typed failure returns no publication aggregate.
    /// The source identity and provenance are structurally corresponding
    /// claims only; until a canonical mesh projection exists, this operation
    /// does not establish that they cryptographically bind the source mesh.
    ///
    /// - Parameters:
    ///   - request: The immutable source mesh, source claims and host limits.
    ///   - publication: Caller authority for output identity and provenance.
    /// - Returns: A structurally bound measurement/identity/provenance
    ///   aggregate over a certified surface. This does not claim
    ///   non-self-intersection, vertex manifoldness, source-graph admission,
    ///   execution authenticity, diagnostic validation or canonical
    ///   mesh-content assurance.
    /// - Throws: A payload-free ``TriangleMeshEnclosedVolumeError`` using the
    ///   operation's fixed failure precedence.
    public static func execute(
        request: TriangleMeshEnclosedVolumeRequest,
        publication: TriangleMeshEnclosedVolumePublicationContext
    ) async throws -> TriangleMeshEnclosedVolumeResult {
        try execute(
            request: request,
            publication: publication,
            cancellation: { _ in Task.isCancelled }
        )
    }

    static func execute(
        request: TriangleMeshEnclosedVolumeRequest,
        publication: TriangleMeshEnclosedVolumePublicationContext,
        cancellation: CPUTriangleMeshEnclosedVolumeCancellationProbe
    ) throws -> TriangleMeshEnclosedVolumeResult {
        let measured = try TriangleMeshEnclosedVolumeReferenceKernel.measure(
            request: request,
            cancellation: cancellation,
            checksFinalCancellation: false
        )
        if cancellation(.final) {
            throw TriangleMeshEnclosedVolumeError.cancelled
        }
        return try assembleResult(
            volume: measured.volume,
            facetCount: measured.facetCount,
            request: request,
            publication: publication
        )
    }

    static func assembleResult(
        volume: Double,
        facetCount: UInt64,
        request: TriangleMeshEnclosedVolumeRequest,
        publication: TriangleMeshEnclosedVolumePublicationContext
    ) throws -> TriangleMeshEnclosedVolumeResult {
        do {
            let measurement = try TriangleMeshEnclosedVolumeMeasurement(
                value: volume,
                unit: try PoweredLengthUnit(
                    base: request.source.coordinateSpace.unit,
                    exponent: TriangleMeshEnclosedVolumeRequest
                        .volumeUnitExponent
                ),
                facetCount: facetCount
            )
            let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
            let operation = try DerivationOperationToken(
                rawValue: TriangleMeshEnclosedVolumeRequest.operationIdentifier
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
            return try TriangleMeshEnclosedVolumeResult(
                measurement: measurement,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        } catch {
            throw TriangleMeshEnclosedVolumeError.publicationFailed
        }
    }

    /// Reconstructs the frozen VCMJ-1 parameters independently of Geometry's
    /// structural result validator.
    private static func parameterDigest() throws -> ContentID {
        let namespace =
            TriangleMeshEnclosedVolumeRequest.operationIdentifier
        let parameters = try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "algorithm-identifier"
                ),
                value: .string(
                    TriangleMeshEnclosedVolumeRequest.algorithmIdentifier
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "certification-rule"
                ),
                value: .string(
                    "closed-edge-manifold-consistently-oriented"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "vertex-manifold-rule"
                ),
                value: .string(
                    "not-required"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "self-intersection-rule"
                ),
                value: .string(
                    "not-certified"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "degenerate-facet-rule"
                ),
                value: .string(
                    "reject-repeated-index"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "facet-term-rule"
                ),
                value: .string(
                    "origin-anchored-scalar-triple-product"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "reference-origin"
                ),
                value: .string(
                    "source-coordinate-space-origin"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "accumulation-rule"
                ),
                value: .string(
                    "triangle-order-serial-sum-then-divide-by-six"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "orientation-rule"
                ),
                value: .string(
                    "outward-positive-inward-rejected"
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "unit-rule"
                ),
                value: .string(
                    "source-length-unit-power-three"
                ),
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
