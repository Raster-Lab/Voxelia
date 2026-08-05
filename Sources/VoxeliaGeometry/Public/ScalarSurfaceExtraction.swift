// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed failure family for scalar-surface extraction.
///
/// Cases deliberately carry no payload so diagnostics cannot disclose source
/// values, isovalues, geometry, resource limits, identifiers or provenance.
/// Underlying storage, transform and publication failures are classified at
/// the operation boundary and never escape through this type.
public enum ScalarSurfaceExtractionError: Error, Sendable, Equatable {
    /// One or both required output ceilings are zero.
    case invalidLimits

    /// The source descriptor or scalar container is outside the closed profile.
    case unsupportedSource

    /// The requested isovalue is NaN or infinite.
    case nonFiniteIsovalue

    /// An authoritative decoded or transformed source sample is non-finite.
    case nonFiniteSample

    /// A checked output count would exceed a caller-supplied ceiling.
    case resourceLimitExceeded

    /// A required interpolated coordinate is not representable in binary64.
    case interpolationNotRepresentable

    /// A required affine-mapped output position is not representable.
    case positionNotRepresentable

    /// Source coordination, reading, decoding or value transformation failed.
    case sourceReadFailed

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled

    /// Complete mesh, identity and provenance claims could not be bound.
    case publicationFailed
}

/// Required host ceilings for one scalar-surface extraction request.
///
/// This immutable value is an unadmitted declaration. Zero remains
/// representable so the asynchronous operation can observe cancellation before
/// applying the `invalidLimits` admission rule. There is deliberately no
/// permissive default.
public struct ScalarSurfaceExtractionLimits: Sendable {
    /// The inclusive maximum number of published mesh vertices.
    public let maximumVertexCount: UInt64

    /// The inclusive maximum number of published triangles.
    public let maximumTriangleCount: UInt64

    /// Creates an unadmitted pair of explicit output ceilings.
    public init(maximumVertexCount: UInt64, maximumTriangleCount: UInt64) {
        self.maximumVertexCount = maximumVertexCount
        self.maximumTriangleCount = maximumTriangleCount
    }
}

/// One immutable scalar-surface extraction declaration.
///
/// The request retains an already validated immutable image aggregate, the
/// binary64 isovalue in the source's authoritative sample unit, and explicit
/// host output ceilings. It is intentionally nonthrowing and not `Hashable` or
/// `Codable`: source storage is erased and admission, including finite
/// isovalue validation, belongs to the cancellable CPU operation.
public struct ScalarSurfaceExtractionRequest: Sendable {
    /// The exact registered semantic operation token spelling.
    public static let operationIdentifier =
        "org.voxelia.op.scalar-surface-extraction"

    /// The exact registered numerical algorithm identity.
    public static let algorithmIdentifier =
        "freudenthal-surface-extraction/binary64-v1"

    /// The immutable source volume aggregate.
    public let source: ImageData

    /// The requested finite binary64 isovalue after operation admission.
    public let isovalue: Double

    /// The required host output ceilings.
    public let limits: ScalarSurfaceExtractionLimits

    /// Creates an unadmitted request without reading source storage.
    public init(
        source: ImageData,
        isovalue: Double,
        limits: ScalarSurfaceExtractionLimits
    ) {
        self.source = source
        self.isovalue = isovalue
        self.limits = limits
    }

    /// Produces the exact `ADR-0191` operation-parameter digest.
    ///
    /// This helper is internal because callers consume a request or validated
    /// result, not an independently authoritative digest factory.
    static func parameterDigest(for isovalue: Double) throws -> ContentID {
        let namespace = Self.operationIdentifier
        let parameters = try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "algorithm-identifier"
                ),
                value: .string(Self.algorithmIdentifier),
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

/// Caller-supplied authority for one scalar-surface result publication.
///
/// The operation mints no identifier and acquires no clock. These immutable
/// claims are excluded from mesh computation and its parameter digest. The
/// value contains no caller-selectable backend, implementation, precision,
/// approximation or validation claim.
public struct ScalarSurfaceExtractionPublicationContext: Sendable {
    /// The object identifier assigned to the complete result.
    public let outputObjectID: DataObjectID

    /// The identifier assigned to the result's provenance record.
    public let outputProvenanceID: ProvenanceID

    /// The caller-supplied completion instant.
    public let createdAt: CanonicalInstant

    /// The software identity asserted for the completed operation.
    public let software: SoftwareIdentity

    /// Creates an immutable publication context from validated claim leaves.
    public init(
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity
    ) {
        self.outputObjectID = outputObjectID
        self.outputProvenanceID = outputProvenanceID
        self.createdAt = createdAt
        self.software = software
    }
}

/// One atomically bound scalar-surface publication.
///
/// The immutable result combines the complete canonical mesh with its
/// derivation-only data identity and subject-bound provenance record. The
/// request and publication context are validation witnesses and are not
/// retained. Construction proves structural and operation-specific claim
/// coherence only; it does not prove source graph admission, execution
/// authenticity, diagnostic validation or a mesh content digest.
public struct ScalarSurfaceExtractionResult: Sendable {
    /// The complete coordinate-bearing triangle mesh.
    public let mesh: TriangleMesh

    /// The derivation-only result identity; no mesh content projection exists.
    public let identity: DataIdentity

    /// The transformed, source-linked result provenance record.
    public let provenance: ProvenanceRecord

    /// Creates a result only when every mesh, identity and provenance claim is
    /// coherent with the exact request and publication context.
    ///
    /// The initializer recomputes the operation-parameter digest and validates
    /// output authority, derivation/provenance correspondence, the exact
    /// `source-volume` input and parent, and coordinate-space preservation.
    /// Every failure maps to ``ScalarSurfaceExtractionError/publicationFailed``
    /// without retaining or exposing an underlying payload.
    ///
    /// - Throws: ``ScalarSurfaceExtractionError/publicationFailed`` when any
    ///   required publication binding is absent or inconsistent.
    public init(
        mesh: TriangleMesh,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: ScalarSurfaceExtractionRequest,
        publication: ScalarSurfaceExtractionPublicationContext
    ) throws {
        let expectedDigest: ContentID
        let expectedOperation: DerivationOperationToken
        let expectedRole: DerivationInputRole
        let expectedProvenanceRole: ProvenanceInputRole
        let expectedOperationVersion: SemanticVersion
        do {
            expectedDigest = try ScalarSurfaceExtractionRequest.parameterDigest(
                for: request.isovalue
            )
            expectedOperation = try DerivationOperationToken(
                rawValue: ScalarSurfaceExtractionRequest.operationIdentifier
            )
            expectedRole = try DerivationInputRole(rawValue: "source-volume")
            expectedProvenanceRole = try ProvenanceInputRole(
                rawValue: "source-volume"
            )
            expectedOperationVersion = try SemanticVersion(
                major: 1,
                minor: 0,
                patch: 0
            )
        } catch {
            throw ScalarSurfaceExtractionError.publicationFailed
        }

        guard
            identity.objectID == publication.outputObjectID,
            provenance.id == publication.outputProvenanceID,
            provenance.subject == .object(publication.outputObjectID),
            provenance.createdAt == publication.createdAt,
            provenance.software == publication.software,
            identity.contentID == nil,
            identity.sourceIdentities.isEmpty,
            let derivation = identity.derivation,
            let implementation = derivation.implementation,
            derivation.operationID == expectedOperation,
            Self.exactVersionEquals(
                derivation.operationVersion,
                expectedOperationVersion
            ),
            derivation.parameterDigest == expectedDigest,
            derivation.inputs.count == 1,
            derivation.inputs[0].role == expectedRole,
            derivation.inputs[0].identity
                == .object(request.source.identity.objectID),
            provenance.kind == .transformed,
            provenance.warnings.isEmpty,
            provenance.inputs.count == 1,
            provenance.inputs[0].role == expectedProvenanceRole,
            provenance.inputs[0].occurrence == 1,
            provenance.inputs[0].identity
                == .object(request.source.identity.objectID),
            provenance.inputs[0].parent
                == .graphNode(request.source.provenance.id),
            case .operation(let operation, _) = provenance.activity,
            operation.operationID == derivation.operationID,
            Self.exactVersionEquals(
                operation.operationVersion,
                derivation.operationVersion
            ),
            operation.implementationID == implementation.identifier,
            Self.exactVersionEquals(
                operation.implementationVersion,
                implementation.version
            ),
            operation.parameterDigest == derivation.parameterDigest,
            operation.parameterDigest == expectedDigest,
            case .affine(let sourceGeometry) =
                request.source.descriptor.spatialGeometry,
            mesh.coordinateSpace == sourceGeometry.coordinateSpace
        else {
            throw ScalarSurfaceExtractionError.publicationFailed
        }

        self.mesh = mesh
        self.identity = identity
        self.provenance = provenance
    }

    /// `SemanticVersion` equality intentionally ignores build metadata;
    /// publication binding must compare every exact claim field instead.
    private static func exactVersionEquals(
        _ lhs: SemanticVersion,
        _ rhs: SemanticVersion
    ) -> Bool {
        lhs.major == rhs.major
            && lhs.minor == rhs.minor
            && lhs.patch == rhs.patch
            && lhs.prerelease == rhs.prerelease
            && lhs.buildMetadata == rhs.buildMetadata
    }
}
