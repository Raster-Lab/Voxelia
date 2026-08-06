// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

/// The deterministic CPU triangle-mesh total-facet-area operation.
///
/// The operation executes the exact `triangle-mesh-total-facet-area/binary64-v1`
/// serial reference, checks final cancellation, and atomically returns the
/// measurement, identity and transformed provenance aggregate. It never mints
/// identifiers, reads a clock, publishes through mutable host state, or exposes
/// a partial total. The type is stateless and supports concurrent calls.
///
/// The published quantity counts facet area **with multiplicity** and asserts
/// nothing about the source mesh's topology, orientation, watertightness or
/// self-intersection. It is not a certified surface area and not an enclosed
/// volume; `ADR-0194` records why those remain separate governed contracts.
public enum CPUTriangleMeshTotalFacetAreaOperation {
    /// The exact registered CPU implementation token spelling.
    public static let implementationIdentifier =
        "org.voxelia.impl.triangle-mesh-total-facet-area.cpu"

    /// Executes one admitted total-facet-area request and atomically returns
    /// its immutable publication aggregate.
    ///
    /// Facet traversal, the unsigned scaled magnitude, the halving and the
    /// serial accumulation follow the exact binary64 ordering frozen by
    /// `ADR-0194` and `VOXELIA-ALG-0031`. The caller supplies explicit host
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
    ///   aggregate. This does not claim source-graph admission, execution
    ///   authenticity, diagnostic validation or canonical mesh-content
    ///   assurance.
    /// - Throws: A payload-free ``TriangleMeshTotalFacetAreaError`` using the
    ///   operation's fixed failure precedence.
    public static func execute(
        request: TriangleMeshTotalFacetAreaRequest,
        publication: TriangleMeshTotalFacetAreaPublicationContext
    ) async throws -> TriangleMeshTotalFacetAreaResult {
        try execute(
            request: request,
            publication: publication,
            cancellation: { _ in Task.isCancelled }
        )
    }

    static func execute(
        request: TriangleMeshTotalFacetAreaRequest,
        publication: TriangleMeshTotalFacetAreaPublicationContext,
        cancellation: CPUTriangleMeshTotalFacetAreaCancellationProbe
    ) throws -> TriangleMeshTotalFacetAreaResult {
        let measured = try TriangleMeshTotalFacetAreaReferenceKernel.measure(
            request: request,
            cancellation: cancellation,
            checksFinalCancellation: false
        )
        if cancellation(.final) {
            throw TriangleMeshTotalFacetAreaError.cancelled
        }
        return try assembleResult(
            total: measured.total,
            facetCount: measured.facetCount,
            request: request,
            publication: publication
        )
    }

    static func assembleResult(
        total: Double,
        facetCount: UInt64,
        request: TriangleMeshTotalFacetAreaRequest,
        publication: TriangleMeshTotalFacetAreaPublicationContext
    ) throws -> TriangleMeshTotalFacetAreaResult {
        do {
            let measurement = try TriangleMeshTotalFacetAreaMeasurement(
                value: total,
                unit: try PoweredLengthUnit(
                    base: request.source.coordinateSpace.unit,
                    exponent: TriangleMeshTotalFacetAreaRequest
                        .areaUnitExponent
                ),
                facetCount: facetCount
            )
            let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
            let operation = try DerivationOperationToken(
                rawValue: TriangleMeshTotalFacetAreaRequest.operationIdentifier
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
            return try TriangleMeshTotalFacetAreaResult(
                measurement: measurement,
                identity: identity,
                provenance: provenance,
                request: request,
                publication: publication
            )
        } catch {
            throw TriangleMeshTotalFacetAreaError.publicationFailed
        }
    }

    /// Reconstructs the frozen VCMJ-1 parameters independently of Geometry's
    /// structural result validator.
    private static func parameterDigest() throws -> ContentID {
        let namespace =
            TriangleMeshTotalFacetAreaRequest.operationIdentifier
        let parameters = try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "algorithm-identifier"
                ),
                value: .string(
                    TriangleMeshTotalFacetAreaRequest.algorithmIdentifier
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "quantity-rule"
                ),
                value: .string("total-facet-area-with-multiplicity"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "facet-area-rule"
                ),
                value: .string("half-scaled-euclidean-cross-magnitude"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "degenerate-face-rule"
                ),
                value: .string("zero-area-contributes-zero"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "accumulation-rule"
                ),
                value: .string("triangle-order-serial-sum"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "orientation-rule"
                ),
                value: .string("unsigned-winding-independent"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "topology-claim"
                ),
                value: .string("none"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "unit-rule"
                ),
                value: .string("source-length-unit-power-two"),
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
