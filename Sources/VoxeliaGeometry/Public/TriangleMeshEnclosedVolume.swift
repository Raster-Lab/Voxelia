// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// The closed failure family for triangle-mesh certified enclosed volume.
///
/// Cases deliberately carry no payload so diagnostics cannot disclose source
/// coordinates, topology, counts, limits, identifiers, volume values or
/// provenance. In particular a certification failure discloses neither the
/// offending facet ordinal nor the offending edge.
///
/// There is deliberately no duplicate-facet case: a repeated facet traverses
/// each of its directed edges a second time and is already
/// ``nonManifoldOrientation``.
public enum TriangleMeshEnclosedVolumeError: Error, Sendable, Equatable {
    /// At least one required host ceiling is zero.
    case invalidLimits

    /// The source identity and provenance claims do not correspond.
    case invalidSource

    /// A checked source count or byte product exceeds an accepted ceiling.
    case resourceLimitExceeded

    /// At least one facet repeats a vertex index.
    case degenerateFacet

    /// At least one directed edge has no reverse partner.
    case openSurface

    /// At least one directed edge occurs more than once.
    case nonManifoldOrientation

    /// The certified surface is consistently oriented inward.
    case invertedOrientation

    /// A required ordered binary64 intermediate was NaN or infinite.
    case volumeNotRepresentable

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled

    /// Complete measurement, identity and provenance claims could not be bound.
    case publicationFailed
}

/// Required host ceilings for one certified enclosed-volume request.
///
/// This immutable value is an unadmitted declaration. Zero remains
/// representable so the asynchronous operation can observe cancellation before
/// applying ``TriangleMeshEnclosedVolumeError/invalidLimits``. There is
/// deliberately no permissive default.
///
/// Unlike ``TriangleMeshTotalFacetAreaLimits`` this value does declare an
/// additional-byte ceiling, because certification owns real payload: one
/// directed-edge record per facet corner, each an ordered pair of 64-bit
/// vertex indices, for exactly `triangleCount * 3 * 16` logical bytes.
public struct TriangleMeshEnclosedVolumeLimits: Sendable {
    /// The inclusive maximum admitted source vertex count.
    public let maximumVertexCount: UInt64

    /// The inclusive maximum admitted source triangle count.
    public let maximumTriangleCount: UInt64

    /// The inclusive maximum operation-controlled additional logical bytes.
    public let maximumAdditionalLogicalByteCount: UInt64

    /// Creates an unadmitted set of explicit resource ceilings.
    public init(
        maximumVertexCount: UInt64,
        maximumTriangleCount: UInt64,
        maximumAdditionalLogicalByteCount: UInt64
    ) {
        self.maximumVertexCount = maximumVertexCount
        self.maximumTriangleCount = maximumTriangleCount
        self.maximumAdditionalLogicalByteCount =
            maximumAdditionalLogicalByteCount
    }
}

/// One immutable certified enclosed-volume declaration.
///
/// The request retains an already validated immutable mesh, structurally
/// corresponding source identity and provenance claims, and explicit host
/// ceilings. It is intentionally nonthrowing and not `Hashable` or `Codable`:
/// source-claim admission and surface certification both belong to the
/// cancellable CPU operation. Until a canonical mesh projection exists, the
/// supplied identity and provenance do not cryptographically bind ``source``
/// bytes.
public struct TriangleMeshEnclosedVolumeRequest: Sendable {
    /// The exact registered semantic operation token spelling.
    public static let operationIdentifier =
        "org.voxelia.op.triangle-mesh-enclosed-volume"

    /// The exact registered numerical algorithm identity.
    public static let algorithmIdentifier =
        "triangle-mesh-enclosed-volume/binary64-v1"

    /// The exponent published for a volume by this operation.
    public static let volumeUnitExponent: UInt8 = 3

    /// The immutable coordinate-bearing source mesh.
    public let source: TriangleMesh

    /// The derivation input identity claim corresponding to the source mesh.
    public let sourceIdentity: DataIdentity

    /// The parent provenance claim corresponding to the source mesh.
    public let sourceProvenance: ProvenanceRecord

    /// The required host resource ceilings.
    public let limits: TriangleMeshEnclosedVolumeLimits

    /// Creates an unadmitted request without scanning or copying mesh payloads.
    public init(
        source: TriangleMesh,
        sourceIdentity: DataIdentity,
        sourceProvenance: ProvenanceRecord,
        limits: TriangleMeshEnclosedVolumeLimits
    ) {
        self.source = source
        self.sourceIdentity = sourceIdentity
        self.sourceProvenance = sourceProvenance
        self.limits = limits
    }

    /// The accepted upper bound for the fixed VCMJ-1 parameter document.
    static let parameterDocumentMaximumOutputByteCount: UInt64 = 65_536

    /// Produces the exact `ADR-0195` operation-parameter document.
    ///
    /// This helper is internal because callers consume a request or validated
    /// result, not independently authoritative parameter bytes. The document
    /// contains only output-affecting rules — including the two properties the
    /// operation deliberately does **not** certify, so the limitation lives
    /// inside the digest identifying every published result rather than in
    /// documentation alone.
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
                value: .string("not-required"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "self-intersection-rule"
                ),
                value: .string("not-certified"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "degenerate-facet-rule"
                ),
                value: .string("reject-repeated-index"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "facet-term-rule"
                ),
                value: .string("origin-anchored-scalar-triple-product"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "reference-origin"
                ),
                value: .string("source-coordinate-space-origin"),
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
                value: .string("outward-positive-inward-rejected"),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: namespace,
                    name: "unit-rule"
                ),
                value: .string("source-length-unit-power-three"),
                privacyClass: .technical
            ),
        ])
        return try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: parameters,
            maximumOutputByteCount: parameterDocumentMaximumOutputByteCount
        )
    }

    /// Produces the exact `ADR-0195` operation-parameter digest.
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

/// Caller-supplied authority for one enclosed-volume result publication.
///
/// The operation mints no identifier and acquires no clock. These immutable
/// claims are excluded from the measured volume and its parameter digest. The
/// value contains no caller-selectable backend, implementation, precision,
/// approximation or validation claim.
public struct TriangleMeshEnclosedVolumePublicationContext: Sendable {
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

/// One admitted certified enclosed-volume measurement.
///
/// The value is the volume of the region bounded by a surface the operation
/// has **certified** closed, edge-manifold and consistently oriented, computed
/// by the frozen `VOXELIA-ALG-0032` reduction.
///
/// Two properties are deliberately not certified and a consumer must know
/// both. Vertex manifoldness is not required, because the divergence identity
/// does not need a single-cycle vertex link. Non-self-intersection is **not**
/// certified: for a closed oriented surface that intersects itself the frozen
/// sum is the winding-number-weighted signed volume rather than the enclosed
/// volume. That limitation is recorded as `self-intersection-rule` inside the
/// operation's parameter document, so it travels with the result's digest.
///
/// Cavities are expressed by orientation: an inward-oriented shell nested
/// inside an outward one subtracts. No containment relationship between shells
/// is verified.
public struct TriangleMeshEnclosedVolumeMeasurement: Sendable {
    /// The finite, non-negative enclosed volume.
    public let value: Double

    /// The source coordinate space's length unit raised to the power three.
    public let unit: PoweredLengthUnit

    /// The exact number of certified facets reduced into ``value``.
    public let facetCount: UInt64

    /// Creates an admitted measurement.
    ///
    /// Negative zero is rejected rather than canonicalized so a publication
    /// path that produced one is diagnosed instead of silently corrected;
    /// `VOXELIA-ALG-0032` publishes positive zero for an empty region.
    ///
    /// - Throws:
    ///   ``TriangleMeshEnclosedVolumeError/publicationFailed`` when the value
    ///   is not finite, is negative, is negative zero, or when the unit
    ///   exponent is not the frozen volume exponent three.
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
                == TriangleMeshEnclosedVolumeRequest.volumeUnitExponent
        else {
            throw TriangleMeshEnclosedVolumeError.publicationFailed
        }
        self.value = value
        self.unit = unit
        self.facetCount = facetCount
    }
}

/// One atomically bound certified enclosed-volume publication.
///
/// The immutable result combines the admitted measurement with its
/// derivation-only data identity and subject-bound provenance record. The
/// request and publication context are validation witnesses and are not
/// retained.
///
/// Construction proves claim coherence and unit derivation only. It does not
/// recompute the volume, re-run certification, admit the source provenance
/// graph, authenticate execution, establish diagnostic validation or create a
/// mesh content digest.
public struct TriangleMeshEnclosedVolumeResult: Sendable {
    /// The admitted certified enclosed-volume measurement.
    public let measurement: TriangleMeshEnclosedVolumeMeasurement

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
    /// source triangle count. The frozen volume exponent is already discharged
    /// by ``TriangleMeshEnclosedVolumeMeasurement``'s own admission.
    ///
    /// - Throws:
    ///   ``TriangleMeshEnclosedVolumeError/publicationFailed`` when any
    ///   required publication binding is absent or inconsistent.
    public init(
        measurement: TriangleMeshEnclosedVolumeMeasurement,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: TriangleMeshEnclosedVolumeRequest,
        publication: TriangleMeshEnclosedVolumePublicationContext
    ) throws {
        let expectedDigest: ContentID
        let expectedOperation: DerivationOperationToken
        let expectedRole: DerivationInputRole
        let expectedProvenanceRole: ProvenanceInputRole
        let expectedOperationVersion: SemanticVersion
        do {
            expectedDigest =
                try TriangleMeshEnclosedVolumeRequest.parameterDigest()
            expectedOperation = try DerivationOperationToken(
                rawValue: TriangleMeshEnclosedVolumeRequest.operationIdentifier
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
            throw TriangleMeshEnclosedVolumeError.publicationFailed
        }

        guard
            let expectedFacetCount = UInt64(
                exactly: request.source.topology.triangleCount
            )
        else {
            throw TriangleMeshEnclosedVolumeError.publicationFailed
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
            throw TriangleMeshEnclosedVolumeError.publicationFailed
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
