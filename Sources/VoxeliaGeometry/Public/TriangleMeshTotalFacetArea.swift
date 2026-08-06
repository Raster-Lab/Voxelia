// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// The closed failure family for triangle-mesh total-facet-area measurement.
///
/// Cases deliberately carry no payload so diagnostics cannot disclose source
/// coordinates, topology, counts, limits, identifiers, area values or
/// provenance. The CPU operation maps every underlying failure into this fixed
/// family.
///
/// There is deliberately no undefined-area case: positive zero is a legitimate
/// total for an empty or wholly degenerate mesh, and every undefined unsigned
/// magnitude is already a representability failure. There is likewise no
/// attribute-related case, because the measurement never reads a vertex
/// attribute.
public enum TriangleMeshTotalFacetAreaError: Error, Sendable, Equatable {
    /// At least one required host ceiling is zero.
    case invalidLimits

    /// The source identity and provenance claims do not correspond.
    case invalidSource

    /// A checked source count exceeds an accepted caller ceiling.
    case resourceLimitExceeded

    /// A required ordered binary64 intermediate was NaN or infinite.
    case areaNotRepresentable

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled

    /// Complete measurement, identity and provenance claims could not be bound.
    case publicationFailed
}

/// Required host ceilings for one total-facet-area request.
///
/// This immutable value is an unadmitted declaration. Zero remains
/// representable so the asynchronous operation can observe cancellation before
/// applying ``TriangleMeshTotalFacetAreaError/invalidLimits``. There is
/// deliberately no permissive default.
///
/// Only the two linear domains the operation actually controls are bounded.
/// `ADR-0194` records why there is no additional-logical-byte ceiling and no
/// existing-attribute ceiling: the reference allocates no per-vertex or
/// per-facet buffer, reducing already-owned immutable positions into one
/// binary64 accumulator, and it never scans vertex attributes.
public struct TriangleMeshTotalFacetAreaLimits: Sendable {
    /// The inclusive maximum admitted source vertex count.
    public let maximumVertexCount: UInt64

    /// The inclusive maximum admitted source triangle count.
    public let maximumTriangleCount: UInt64

    /// Creates an unadmitted set of explicit resource ceilings.
    public init(
        maximumVertexCount: UInt64,
        maximumTriangleCount: UInt64
    ) {
        self.maximumVertexCount = maximumVertexCount
        self.maximumTriangleCount = maximumTriangleCount
    }
}

/// One immutable triangle-mesh total-facet-area declaration.
///
/// The request retains an already validated immutable mesh, structurally
/// corresponding source identity and provenance claims, and explicit host
/// ceilings. It is intentionally nonthrowing and not `Hashable` or `Codable`:
/// source-claim admission belongs to the cancellable CPU operation. Until a
/// canonical mesh projection exists, the supplied identity and provenance do
/// not cryptographically bind ``source`` bytes.
public struct TriangleMeshTotalFacetAreaRequest: Sendable {
    /// The exact registered semantic operation token spelling.
    public static let operationIdentifier =
        "org.voxelia.op.triangle-mesh-total-facet-area"

    /// The exact registered numerical algorithm identity.
    public static let algorithmIdentifier =
        "triangle-mesh-total-facet-area/binary64-v1"

    /// The exponent published for an area by this operation.
    public static let areaUnitExponent: UInt8 = 2

    /// The immutable coordinate-bearing source mesh.
    public let source: TriangleMesh

    /// The derivation input identity claim corresponding to the source mesh.
    public let sourceIdentity: DataIdentity

    /// The parent provenance claim corresponding to the source mesh.
    public let sourceProvenance: ProvenanceRecord

    /// The required host resource ceilings.
    public let limits: TriangleMeshTotalFacetAreaLimits

    /// Creates an unadmitted request without scanning or copying mesh payloads.
    public init(
        source: TriangleMesh,
        sourceIdentity: DataIdentity,
        sourceProvenance: ProvenanceRecord,
        limits: TriangleMeshTotalFacetAreaLimits
    ) {
        self.source = source
        self.sourceIdentity = sourceIdentity
        self.sourceProvenance = sourceProvenance
        self.limits = limits
    }

    /// The accepted upper bound for the fixed VCMJ-1 parameter document.
    static let parameterDocumentMaximumOutputByteCount: UInt64 = 65_536

    /// Produces the exact `ADR-0194` operation-parameter document.
    ///
    /// This helper is internal because callers consume a request or validated
    /// result, not independently authoritative parameter bytes. The document
    /// contains only output-affecting rules; limits, source claims,
    /// cancellation policy and publication authority are excluded. The source
    /// coordinate unit is also excluded: it is carried by the published
    /// measurement and by the source mesh's own identity, and the arithmetic
    /// never reads it.
    static func parameterDocument() throws -> [UInt8] {
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
        return try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: parameters,
            maximumOutputByteCount: parameterDocumentMaximumOutputByteCount
        )
    }

    /// Produces the exact `ADR-0194` operation-parameter digest.
    ///
    /// The digest is constant for version one because all output-affecting
    /// choices are frozen rules. Source mesh values and host execution policy
    /// are deliberately absent.
    static func parameterDigest() throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: parameterDocument()
        )
    }
}

/// Caller-supplied authority for one total-facet-area result publication.
///
/// The operation mints no identifier and acquires no clock. These immutable
/// claims are excluded from the measured total and its parameter digest. The
/// value contains no caller-selectable backend, implementation, precision,
/// approximation or validation claim.
public struct TriangleMeshTotalFacetAreaPublicationContext: Sendable {
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

/// One admitted total-facet-area measurement.
///
/// The value is the serial topology-order sum of every admitted facet's own
/// unsigned area, frozen by `VOXELIA-ALG-0031`. It counts facet area **with
/// multiplicity**: repeated, coincident, overlapping, self-intersecting,
/// non-manifold, disconnected and boundary-touching facets are all admitted and
/// all counted. It is therefore a property of the supplied facet list and is
/// **not** a certified surface area, a union area, a closed-surface area or any
/// statement about the topology, orientation or watertightness of the mesh.
///
/// ``facetCount`` publishes the exact number of facets reduced so the
/// multiplicity rule is inspectable rather than a documentation-only promise.
public struct TriangleMeshTotalFacetAreaMeasurement: Sendable {
    /// The finite, non-negative accumulated total.
    public let value: Double

    /// The source coordinate space's length unit raised to the power two.
    public let unit: PoweredLengthUnit

    /// The exact number of admitted facets reduced into ``value``.
    public let facetCount: UInt64

    /// Creates an admitted measurement.
    ///
    /// Negative zero is rejected rather than canonicalized so a publication
    /// path that produced one is diagnosed instead of silently corrected;
    /// `VOXELIA-ALG-0031` never produces one.
    ///
    /// - Throws:
    ///   ``TriangleMeshTotalFacetAreaError/publicationFailed`` when the value
    ///   is not finite, is negative, is negative zero, or when the unit
    ///   exponent is not the frozen area exponent two.
    public init(
        value: Double,
        unit: PoweredLengthUnit,
        facetCount: UInt64
    ) throws {
        guard
            value.isFinite,
            value >= 0,
            !(value == 0 && value.sign == .minus),
            unit.exponent
                == TriangleMeshTotalFacetAreaRequest.areaUnitExponent
        else {
            throw TriangleMeshTotalFacetAreaError.publicationFailed
        }
        self.value = value
        self.unit = unit
        self.facetCount = facetCount
    }
}

/// One atomically bound triangle-mesh total-facet-area publication.
///
/// The immutable result combines the admitted measurement with its
/// derivation-only data identity and subject-bound provenance record. The
/// request and publication context are validation witnesses and are not
/// retained.
///
/// Unlike the vertex-normal result, this operation publishes a measurement
/// rather than a mesh: positions, topology and attributes are unchanged and
/// unowned here, so there is no source-preservation obligation to prove and no
/// output mesh to bind. Construction proves claim coherence and unit
/// derivation only; it does not recompute the total, admit the source
/// provenance graph, authenticate execution, establish diagnostic validation or
/// create a mesh content digest.
public struct TriangleMeshTotalFacetAreaResult: Sendable {
    /// The admitted total-facet-area measurement.
    public let measurement: TriangleMeshTotalFacetAreaMeasurement

    /// The derivation-only result identity; no mesh projection exists yet.
    public let identity: DataIdentity

    /// The transformed, source-linked result provenance record.
    public let provenance: ProvenanceRecord

    /// Creates a result only when the measurement, identity and provenance
    /// domains are coherent with the exact request and publication context.
    ///
    /// Validation checks source-claim correspondence, output authority,
    /// derivation and provenance operation binding, the exact `source-mesh`
    /// input and parent, that the measurement's base unit is exactly the
    /// source coordinate space's unit, and that the facet count equals the
    /// source triangle count. The frozen area exponent is already discharged
    /// by ``TriangleMeshTotalFacetAreaMeasurement``'s own admission. No area
    /// value is numerically re-evaluated.
    ///
    /// - Throws:
    ///   ``TriangleMeshTotalFacetAreaError/publicationFailed`` when any
    ///   required publication binding is absent or inconsistent.
    public init(
        measurement: TriangleMeshTotalFacetAreaMeasurement,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: TriangleMeshTotalFacetAreaRequest,
        publication: TriangleMeshTotalFacetAreaPublicationContext
    ) throws {
        let expectedDigest: ContentID
        let expectedOperation: DerivationOperationToken
        let expectedRole: DerivationInputRole
        let expectedProvenanceRole: ProvenanceInputRole
        let expectedOperationVersion: SemanticVersion
        do {
            expectedDigest =
                try TriangleMeshTotalFacetAreaRequest.parameterDigest()
            expectedOperation = try DerivationOperationToken(
                rawValue: TriangleMeshTotalFacetAreaRequest
                    .operationIdentifier
            )
            expectedRole = try DerivationInputRole(rawValue: "source-mesh")
            expectedProvenanceRole = try ProvenanceInputRole(
                rawValue: "source-mesh"
            )
            expectedOperationVersion = try SemanticVersion(
                major: 1,
                minor: 0,
                patch: 0
            )
        } catch {
            throw TriangleMeshTotalFacetAreaError.publicationFailed
        }

        guard
            let expectedFacetCount = UInt64(
                exactly: request.source.topology.triangleCount
            )
        else {
            throw TriangleMeshTotalFacetAreaError.publicationFailed
        }

        guard
            request.sourceProvenance.subject
                == .object(request.sourceIdentity.objectID),
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
                == .object(request.sourceIdentity.objectID),
            provenance.kind == .transformed,
            provenance.warnings.isEmpty,
            provenance.inputs.count == 1,
            provenance.inputs[0].role == expectedProvenanceRole,
            provenance.inputs[0].occurrence == 1,
            provenance.inputs[0].identity
                == .object(request.sourceIdentity.objectID),
            provenance.inputs[0].parent
                == .graphNode(request.sourceProvenance.id),
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
            measurement.facetCount == expectedFacetCount,
            Self.exactUnitEquals(
                measurement.unit.base,
                request.source.coordinateSpace.unit
            )
        else {
            throw TriangleMeshTotalFacetAreaError.publicationFailed
        }

        self.measurement = measurement
        self.identity = identity
        self.provenance = provenance
    }

    /// `MeasurementUnit` equality intentionally ignores presentation text;
    /// publication binding must compare every declared field instead, so a
    /// published base unit cannot silently differ from the source space's.
    private static func exactUnitEquals(
        _ lhs: MeasurementUnit,
        _ rhs: MeasurementUnit
    ) -> Bool {
        exactString(lhs.namespace, rhs.namespace)
            && exactString(lhs.code, rhs.code)
            && exactOptionalString(lhs.displayName, rhs.displayName)
            && lhs.dimension == rhs.dimension
            && exactOptionalDouble(lhs.scaleToCanonical, rhs.scaleToCanonical)
            && exactOptionalDouble(lhs.offsetToCanonical, rhs.offsetToCanonical)
    }

    private static func exactOptionalString(
        _ lhs: String?,
        _ rhs: String?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            true
        case (let lhsValue?, let rhsValue?):
            exactString(lhsValue, rhsValue)
        default:
            false
        }
    }

    private static func exactOptionalDouble(
        _ lhs: Double?,
        _ rhs: Double?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            true
        case (let lhsValue?, let rhsValue?):
            lhsValue.bitPattern == rhsValue.bitPattern
        default:
            false
        }
    }

    private static func exactString(_ lhs: String, _ rhs: String) -> Bool {
        lhs.utf8.elementsEqual(rhs.utf8)
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
