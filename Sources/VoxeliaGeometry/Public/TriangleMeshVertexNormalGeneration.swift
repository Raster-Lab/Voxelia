// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed failure family for triangle-mesh vertex-normal generation.
///
/// Cases deliberately carry no payload so diagnostics cannot disclose source
/// coordinates, topology, attributes, counts, limits, identifiers, normal
/// values or provenance. The future CPU operation maps every underlying
/// failure into this fixed family.
public enum TriangleMeshVertexNormalGenerationError:
    Error, Sendable, Equatable
{
    /// At least one required host ceiling is zero.
    case invalidLimits

    /// The source identity and provenance claims do not correspond.
    case invalidSource

    /// The source mesh already contains the built-in normal semantic.
    case normalAlreadyPresent

    /// Checked work or output would exceed an accepted caller ceiling.
    case resourceLimitExceeded

    /// A required ordered binary64 intermediate was NaN or infinite.
    case normalNotRepresentable

    /// At least one vertex accumulated an exactly zero normal vector.
    case undefinedNormal

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled

    /// Complete mesh, identity and provenance claims could not be bound.
    case publicationFailed
}

/// Required host ceilings for one vertex-normal generation request.
///
/// This immutable value is an unadmitted declaration. Zero remains
/// representable so the future asynchronous operation can observe cancellation
/// before applying `invalidLimits`. There is deliberately no permissive
/// default. The additional-byte ceiling covers only the two operation-owned
/// 24-byte-per-vertex logical buffers frozen by `ADR-0193`.
public struct TriangleMeshVertexNormalGenerationLimits: Sendable {
    /// The inclusive maximum admitted source vertex count.
    public let maximumVertexCount: UInt64

    /// The inclusive maximum admitted source triangle count.
    public let maximumTriangleCount: UInt64

    /// The inclusive maximum admitted existing vertex-attribute count.
    public let maximumExistingVertexAttributeCount: UInt64

    /// The inclusive maximum operation-controlled additional logical bytes.
    public let maximumAdditionalLogicalByteCount: UInt64

    /// Creates an unadmitted set of explicit resource ceilings.
    public init(
        maximumVertexCount: UInt64,
        maximumTriangleCount: UInt64,
        maximumExistingVertexAttributeCount: UInt64,
        maximumAdditionalLogicalByteCount: UInt64
    ) {
        self.maximumVertexCount = maximumVertexCount
        self.maximumTriangleCount = maximumTriangleCount
        self.maximumExistingVertexAttributeCount =
            maximumExistingVertexAttributeCount
        self.maximumAdditionalLogicalByteCount =
            maximumAdditionalLogicalByteCount
    }
}

/// One immutable triangle-mesh vertex-normal generation declaration.
///
/// The request retains an already validated immutable mesh, structurally
/// corresponding source identity and provenance claims, and explicit host
/// ceilings. It is intentionally nonthrowing and not `Hashable` or `Codable`:
/// source-claim admission belongs to the cancellable CPU operation. Until a
/// canonical mesh projection exists, the supplied identity and provenance do
/// not cryptographically bind ``source`` bytes.
public struct TriangleMeshVertexNormalGenerationRequest: Sendable {
    /// The exact registered semantic operation token spelling.
    public static let operationIdentifier =
        "org.voxelia.op.triangle-mesh-vertex-normal-generation"

    /// The exact registered numerical algorithm identity.
    public static let algorithmIdentifier =
        "triangle-area-weighted-vertex-normals/binary64-v1"

    /// The immutable coordinate-bearing source mesh.
    public let source: TriangleMesh

    /// The derivation input identity claim corresponding to the source mesh.
    public let sourceIdentity: DataIdentity

    /// The parent provenance claim corresponding to the source mesh.
    public let sourceProvenance: ProvenanceRecord

    /// The required host resource ceilings.
    public let limits: TriangleMeshVertexNormalGenerationLimits

    /// Creates an unadmitted request without scanning or copying mesh payloads.
    public init(
        source: TriangleMesh,
        sourceIdentity: DataIdentity,
        sourceProvenance: ProvenanceRecord,
        limits: TriangleMeshVertexNormalGenerationLimits
    ) {
        self.source = source
        self.sourceIdentity = sourceIdentity
        self.sourceProvenance = sourceProvenance
        self.limits = limits
    }

    /// The accepted upper bound for the fixed VCMJ-1 parameter document.
    static let parameterDocumentMaximumOutputByteCount: UInt64 = 65_536

    /// Produces the exact `ADR-0193` operation-parameter document.
    ///
    /// This helper is internal because callers consume a request or validated
    /// result, not independently authoritative parameter bytes. The document
    /// contains only output-affecting rules; limits, source claims,
    /// cancellation policy and publication authority are excluded.
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
        return try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: parameters,
            maximumOutputByteCount: parameterDocumentMaximumOutputByteCount
        )
    }

    /// Produces the exact `ADR-0193` operation-parameter digest.
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

/// Caller-supplied authority for one vertex-normal result publication.
///
/// The operation mints no identifier and acquires no clock. These immutable
/// claims are excluded from normal computation and its parameter digest. The
/// value contains no caller-selectable backend, implementation, precision,
/// approximation or validation claim.
public struct TriangleMeshVertexNormalGenerationPublicationContext: Sendable {
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

/// One atomically bound triangle-mesh vertex-normal publication.
///
/// The immutable result combines the complete normal-bearing canonical mesh
/// with its derivation-only data identity and subject-bound provenance record.
/// The request and publication context are validation witnesses and are not
/// retained. Construction proves source preservation and operation-specific
/// claim coherence only; it does not recompute normals, admit the source graph,
/// authenticate execution, establish diagnostic validation or create a mesh
/// content digest.
public struct TriangleMeshVertexNormalGenerationResult: Sendable {
    /// The complete source-preserving mesh with one appended normal attribute.
    public let mesh: TriangleMesh

    /// The derivation-only result identity; no mesh projection exists yet.
    public let identity: DataIdentity

    /// The transformed, source-linked result provenance record.
    public let provenance: ProvenanceRecord

    /// Creates a result only when all mesh, identity and provenance domains
    /// are coherent with the exact request and publication context.
    ///
    /// Validation checks source-claim correspondence, output authority,
    /// derivation/provenance operation binding, the exact `source-mesh` input
    /// and parent, bit-exact source positions, exact topology and source
    /// attributes, and the one frozen appended normal descriptor and byte
    /// count. Existing source attribute strings are compared by exact UTF-8
    /// bytes. No normal value is numerically re-evaluated.
    ///
    /// - Throws:
    ///   ``TriangleMeshVertexNormalGenerationError/publicationFailed`` when
    ///   any required publication binding is absent or inconsistent.
    public init(
        mesh: TriangleMesh,
        identity: DataIdentity,
        provenance: ProvenanceRecord,
        request: TriangleMeshVertexNormalGenerationRequest,
        publication: TriangleMeshVertexNormalGenerationPublicationContext
    ) throws {
        let expectedDigest: ContentID
        let expectedOperation: DerivationOperationToken
        let expectedRole: DerivationInputRole
        let expectedProvenanceRole: ProvenanceInputRole
        let expectedOperationVersion: SemanticVersion
        do {
            expectedDigest =
                try TriangleMeshVertexNormalGenerationRequest
                .parameterDigest()
            expectedOperation = try DerivationOperationToken(
                rawValue: TriangleMeshVertexNormalGenerationRequest
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
            throw TriangleMeshVertexNormalGenerationError.publicationFailed
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
            Self.meshPreservesSourceAndAppendsNormal(
                mesh,
                source: request.source
            )
        else {
            throw TriangleMeshVertexNormalGenerationError.publicationFailed
        }

        self.mesh = mesh
        self.identity = identity
        self.provenance = provenance
    }

    private static func meshPreservesSourceAndAppendsNormal(
        _ output: TriangleMesh,
        source: TriangleMesh
    ) -> Bool {
        guard
            output.coordinateSpace == source.coordinateSpace,
            exactPositionComponents(
                output.positions.components,
                source.positions.components
            ),
            output.topology == source.topology
        else {
            return false
        }

        let (expectedAttributeCount, overflow) =
            source.vertexAttributes.count.addingReportingOverflow(1)
        guard
            !overflow,
            output.vertexAttributes.count == expectedAttributeCount
        else {
            return false
        }

        for index in source.vertexAttributes.indices {
            guard
                exactAttribute(
                    output.vertexAttributes[index],
                    source.vertexAttributes[index]
                )
            else {
                return false
            }
        }

        guard let normal = output.vertexAttributes.last else {
            return false
        }
        return exactNormalAttribute(
            normal,
            vertexCount: source.positions.vertexCount
        )
    }

    private static func exactPositionComponents(
        _ lhs: ContiguousArray<Double>,
        _ rhs: ContiguousArray<Double>
    ) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for index in lhs.indices {
            guard lhs[index].bitPattern == rhs[index].bitPattern else {
                return false
            }
        }
        return true
    }

    private static func exactAttribute(
        _ lhs: TriangleMeshVertexAttribute,
        _ rhs: TriangleMeshVertexAttribute
    ) -> Bool {
        exactDescriptor(lhs.descriptor, rhs.descriptor)
            && lhs.bytes == rhs.bytes
    }

    private static func exactDescriptor(
        _ lhs: GeometryAttributeDescriptor,
        _ rhs: GeometryAttributeDescriptor
    ) -> Bool {
        exactSemantic(lhs.semantic, rhs.semantic)
            && lhs.scalarFormat == rhs.scalarFormat
            && lhs.components.count == rhs.components.count
            && exactInterpretation(
                lhs.components.interpretation,
                rhs.components.interpretation
            )
            && lhs.components.layout == rhs.components.layout
            && exactNames(
                lhs.components.componentNames,
                rhs.components.componentNames
            )
            && lhs.elementCount == rhs.elementCount
    }

    private static func exactNormalAttribute(
        _ attribute: TriangleMeshVertexAttribute,
        vertexCount: Int
    ) -> Bool {
        let descriptor = attribute.descriptor
        let (componentCount, componentOverflow) =
            vertexCount.multipliedReportingOverflow(by: 3)
        let (expectedByteCount, byteOverflow) =
            componentCount.multipliedReportingOverflow(by: 8)
        guard !componentOverflow, !byteOverflow else { return false }
        return descriptor.semantic == .normal
            && descriptor.scalarFormat.type == .float64
            && descriptor.scalarFormat.validBitCount == nil
            && descriptor.scalarFormat.byteOrder == .littleEndian
            && descriptor.components.count == 3
            && descriptor.components.interpretation == .vector
            && descriptor.components.layout == .interleaved
            && descriptor.components.componentNames == nil
            && descriptor.elementCount == vertexCount
            && attribute.bytes.count == expectedByteCount
    }

    private static func exactSemantic(
        _ lhs: GeometryAttributeSemantic,
        _ rhs: GeometryAttributeSemantic
    ) -> Bool {
        switch (lhs, rhs) {
        case (.position, .position),
            (.normal, .normal),
            (.tangent, .tangent),
            (.colour, .colour),
            (.textureCoordinate, .textureCoordinate),
            (.scalarValue, .scalarValue),
            (.label, .label),
            (.confidence, .confidence):
            true
        case (
            .custom(let lhsNamespace, let lhsName),
            .custom(let rhsNamespace, let rhsName)
        ):
            exactString(lhsNamespace, rhsNamespace)
                && exactString(lhsName, rhsName)
        default:
            false
        }
    }

    private static func exactInterpretation(
        _ lhs: ComponentInterpretation,
        _ rhs: ComponentInterpretation
    ) -> Bool {
        switch (lhs, rhs) {
        case (.scalar, .scalar),
            (.rgb, .rgb),
            (.rgba, .rgba),
            (.vector, .vector),
            (.tensor, .tensor),
            (.complex, .complex),
            (.labelProbability, .labelProbability):
            true
        case (
            .generic(let lhsNamespace, let lhsName),
            .generic(let rhsNamespace, let rhsName)
        ):
            exactString(lhsNamespace, rhsNamespace)
                && exactString(lhsName, rhsName)
        default:
            false
        }
    }

    private static func exactNames(
        _ lhs: ContiguousArray<String>?,
        _ rhs: ContiguousArray<String>?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let lhsNames?, let rhsNames?):
            guard lhsNames.count == rhsNames.count else { return false }
            for index in lhsNames.indices {
                guard exactString(lhsNames[index], rhsNames[index]) else {
                    return false
                }
            }
            return true
        default:
            return false
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
