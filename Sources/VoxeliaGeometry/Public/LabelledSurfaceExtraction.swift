// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed failure family for labelled-surface extraction.
///
/// Cases deliberately carry no payload so diagnostics cannot disclose label
/// values, geometry, resource limits, identifiers, storage failures or
/// provenance. The future CPU operation maps all underlying failures into this
/// fixed family.
public enum LabelledSurfaceExtractionError: Error, Sendable, Equatable {
    /// A required ceiling is zero or the label ceiling exceeds the v1 maximum.
    case invalidLimits

    /// The requested label set is empty, unordered or contains a duplicate.
    case invalidLabelSet

    /// The source descriptor, geometry or integer domain is outside v1.
    case unsupportedSource

    /// Checked work or output would exceed an accepted caller ceiling.
    case resourceLimitExceeded

    /// A midpoint is inexact or ordered affine mapping becomes non-finite.
    case positionNotRepresentable

    /// Source coordination, reading, retention or integer decoding failed.
    case sourceReadFailed

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled

    /// Complete mesh, identity and provenance claims could not be bound.
    case publicationFailed
}

/// One exact signed or unsigned requested label declaration.
///
/// Cases retain the caller's immutable order and full 64-bit integer values;
/// they never convert labels through `Double`. This value is intentionally
/// unadmitted: an empty, unordered or duplicate-bearing array remains
/// representable so the future asynchronous CPU operation can apply its fixed
/// cancellation-first precedence. Successful execution requires a nonempty,
/// strictly increasing, unique array in the source's matching signedness.
public enum LabelledSurfaceLabelSet: Sendable {
    /// Requested labels in the signed-integer domain.
    case signed(ContiguousArray<Int64>)

    /// Requested labels in the unsigned-integer domain.
    case unsigned(ContiguousArray<UInt64>)

    /// Returns the admitted parameter representation without changing values.
    ///
    /// This validation is repeated at publication so the public result cannot
    /// bind a noncanonical request. The CPU operation will perform the same
    /// checks earlier under its cancellation and error-precedence contract.
    fileprivate func parameterRepresentation() throws -> (
        domain: String,
        values: ContiguousArray<MetadataValue>
    ) {
        switch self {
        case .signed(let labels):
            try Self.validateCardinality(labels)
            try Self.validateIncreasing(labels)
            return (
                "signed-integer",
                ContiguousArray(labels.map(MetadataValue.signedInteger))
            )
        case .unsigned(let labels):
            try Self.validateCardinality(labels)
            try Self.validateIncreasing(labels)
            return (
                "unsigned-integer",
                ContiguousArray(labels.map(MetadataValue.unsignedInteger))
            )
        }
    }

    /// Applies the constant-time cardinality checks before inspecting values.
    private static func validateCardinality<Value>(
        _ values: ContiguousArray<Value>
    ) throws {
        guard !values.isEmpty else {
            throw LabelledSurfaceExtractionError.invalidLabelSet
        }
        guard
            UInt64(values.count)
                <= LabelledSurfaceExtractionRequest.maximumSupportedLabelCount
        else {
            throw LabelledSurfaceExtractionError.resourceLimitExceeded
        }
    }

    private static func validateIncreasing<Value: Comparable>(
        _ values: ContiguousArray<Value>
    ) throws {
        for index in values.indices.dropFirst() {
            guard values[index - 1] < values[index] else {
                throw LabelledSurfaceExtractionError.invalidLabelSet
            }
        }
    }
}

/// Required host ceilings for one labelled-surface extraction request.
///
/// This immutable value is an unadmitted declaration. Zero and an excessive
/// label ceiling remain representable so the future asynchronous operation can
/// observe cancellation before applying `invalidLimits`. There is no
/// permissive default.
public struct LabelledSurfaceExtractionLimits: Sendable {
    /// The inclusive maximum requested-label count accepted by the host.
    public let maximumSelectedLabelCount: UInt64

    /// The inclusive maximum number of published mesh vertices.
    public let maximumVertexCount: UInt64

    /// The inclusive maximum number of published triangles.
    public let maximumTriangleCount: UInt64

    /// Creates an unadmitted set of explicit resource ceilings.
    public init(
        maximumSelectedLabelCount: UInt64,
        maximumVertexCount: UInt64,
        maximumTriangleCount: UInt64
    ) {
        self.maximumSelectedLabelCount = maximumSelectedLabelCount
        self.maximumVertexCount = maximumVertexCount
        self.maximumTriangleCount = maximumTriangleCount
    }
}

/// One immutable labelled-surface extraction declaration.
///
/// The request retains an already validated immutable image aggregate, the
/// exact signed or unsigned requested set, and required host ceilings. It is
/// intentionally nonthrowing and not `Hashable` or `Codable`: storage is
/// erased and all cancellable source/set admission belongs to the CPU
/// operation.
public struct LabelledSurfaceExtractionRequest: Sendable {
    /// The exact registered semantic operation token spelling.
    public static let operationIdentifier =
        "org.voxelia.op.labelled-surface-extraction"

    /// The exact registered numerical algorithm identity.
    public static let algorithmIdentifier =
        "freudenthal-label-set-surface/binary64-v1"

    /// The hard inclusive v1 requested-label count ceiling.
    public static let maximumSupportedLabelCount: UInt64 = 65_536

    /// The immutable mutually exclusive label-image source aggregate.
    public let source: ImageData

    /// The exact signed or unsigned requested label union.
    public let selectedLabels: LabelledSurfaceLabelSet

    /// The required host resource ceilings.
    public let limits: LabelledSurfaceExtractionLimits

    /// Creates an unadmitted request without reading or converting labels.
    public init(
        source: ImageData,
        selectedLabels: LabelledSurfaceLabelSet,
        limits: LabelledSurfaceExtractionLimits
    ) {
        self.source = source
        self.selectedLabels = selectedLabels
        self.limits = limits
    }

    /// The accepted upper bound for one VCMJ-1 parameter document.
    static let parameterDocumentMaximumOutputByteCount: UInt64 = 4_194_304

    /// Produces the exact `ADR-0192` operation-parameter document.
    ///
    /// This helper is internal because callers consume a request or validated
    /// result, not standalone parameter bytes. It revalidates the nonempty,
    /// strictly increasing, unique set and the hard label count before
    /// allocating the bounded metadata array.
    static func parameterDocument(
        for selectedLabels: LabelledSurfaceLabelSet
    ) throws -> [UInt8] {
        let representation = try selectedLabels.parameterRepresentation()
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
                    name: "label-domain"
                ),
                value: .string(representation.domain),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "selected-labels"
                ),
                value: .array(
                    try MetadataArray(values: representation.values)
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "membership-rule"
                ),
                value: .string(
                    "exact-decoded-label-in-requested-set"
                ),
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
        return try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: parameters,
            maximumOutputByteCount: parameterDocumentMaximumOutputByteCount
        )
    }

    /// Produces the exact `ADR-0192` operation-parameter digest.
    ///
    /// The digest binds the integer domain, every exact requested value and
    /// all frozen semantic rules. Limits, output authority and software claims
    /// are excluded because they cannot alter a successful mesh.
    static func parameterDigest(
        for selectedLabels: LabelledSurfaceLabelSet
    ) throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: parameterDocument(for: selectedLabels)
        )
    }
}

/// Caller-supplied authority for one labelled-surface result publication.
///
/// The operation mints no identifier and acquires no clock. These immutable
/// claims are excluded from mesh computation and its parameter digest. The
/// value contains no caller-selectable backend, implementation, precision,
/// approximation or validation claim.
public struct LabelledSurfaceExtractionPublicationContext: Sendable {
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

/// One atomically bound labelled-surface publication.
///
/// The immutable result combines the complete canonical mesh with its
/// derivation-only data identity and subject-bound provenance record. The
/// request and publication context are validation witnesses and are not
/// retained. Construction proves structural and operation-specific claim
/// coherence only; it does not prove source graph admission, execution
/// authenticity, diagnostic validation or a mesh content digest.
public struct LabelledSurfaceExtractionResult: Sendable {
    /// The complete coordinate-bearing triangle mesh for the requested union.
    public let mesh: TriangleMesh

    /// The derivation-only result identity; no mesh projection exists yet.
    public let identity: DataIdentity

    /// The transformed, source-linked result provenance record.
    public let provenance: ProvenanceRecord

    /// Creates a result only when every mesh, identity and provenance claim is
    /// coherent with the exact request and publication context.
    ///
    /// The initializer revalidates and digests the requested label set, then
    /// checks output authority, derivation/provenance correspondence, the exact
    /// `source-volume` input and parent, and coordinate-space preservation.
    /// Every failure maps to
    /// ``LabelledSurfaceExtractionError/publicationFailed`` without retaining
    /// or exposing an underlying payload.
    ///
    /// - Throws: ``LabelledSurfaceExtractionError/publicationFailed`` when any
    ///   required publication binding is absent or inconsistent.
    public init(
        mesh: TriangleMesh,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: LabelledSurfaceExtractionRequest,
        publication: LabelledSurfaceExtractionPublicationContext
    ) throws {
        let expectedDigest: ContentID
        let expectedOperation: DerivationOperationToken
        let expectedRole: DerivationInputRole
        let expectedProvenanceRole: ProvenanceInputRole
        let expectedOperationVersion: SemanticVersion
        do {
            expectedDigest = try LabelledSurfaceExtractionRequest.parameterDigest(
                for: request.selectedLabels
            )
            expectedOperation = try DerivationOperationToken(
                rawValue: LabelledSurfaceExtractionRequest.operationIdentifier
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
            throw LabelledSurfaceExtractionError.publicationFailed
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
            throw LabelledSurfaceExtractionError.publicationFailed
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
