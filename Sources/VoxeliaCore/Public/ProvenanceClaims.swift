// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while validating a provenance claim leaf.
///
/// Cases deliberately carry no payload so diagnostics never disclose the
/// rejected field, role or record content.
public enum ProvenanceClaimError: Error, Sendable, Equatable {
    case fieldByteLimitExceeded
    case invalidField
    case invalidRole
    case roleByteLimitExceeded
    case invalidOccurrence
    case unsupportedParameterProjection
    case unsupportedRecordProjection
}

/// A stable identity for separately governed validation evidence.
///
/// The identifier refers to evidence; it does not itself establish that
/// the evidence exists, applies or passed.
public struct ValidationEvidenceID: VoxeliaStringIdentifier {
    /// The preserved case-sensitive identifier spelling.
    public let rawValue: String

    /// The hard inclusive raw-value byte ceiling per `ADR-0044`
    /// exactness precedent.
    public static let maximumUTF8ByteCount = 255

    /// Creates an identifier unless `rawValue` is empty,
    /// Unicode-whitespace-only or over the persistent byte ceiling.
    public init?(rawValue: String) {
        guard rawValue.contains(where: { !$0.isWhitespace }),
            rawValue.utf8.count <= Self.maximumUTF8ByteCount
        else { return nil }
        self.rawValue = rawValue
    }

    /// Compares the exact accepted UTF-8 bytes.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.utf8.elementsEqual(rhs.rawValue.utf8)
    }

    /// Hashes the exact accepted UTF-8 bytes.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.utf8.count)
        for byte in rawValue.utf8 {
            hasher.combine(byte)
        }
    }
}

/// The corrected serialisable validation claim per `ADR-0057`.
///
/// A decoded case is a claim referring to separately governed
/// validation evidence; it proves nothing, and no ordering exists
/// between cases. The displayed free-text deprecation reason is
/// removed — deprecation context belongs to governed warning codes.
public enum ProvenanceValidationClaim: Sendable, Hashable {
    case unknown
    case experimental
    case preview
    case validated(ValidationEvidenceID)
    case diagnosticReady(ValidationEvidenceID)
    case deprecated
}

/// One immutable software identity claim per `ADR-0057`.
///
/// Every string field uses the accepted identity field profile with
/// exact accepted UTF-8 comparison, and the version compares exactly
/// including build metadata. The claim asserts which software produced
/// a record; it proves neither authenticity nor build integrity.
public struct SoftwareIdentity: Sendable, Hashable {
    /// The hard inclusive per-field byte ceiling.
    public static let maximumFieldUTF8ByteCount: UInt64 = 255

    public let name: String
    public let version: SemanticVersion
    public let commit: String?
    public let buildIdentifier: String?

    /// Creates a validated software identity.
    ///
    /// - Throws: ``ProvenanceClaimError/fieldByteLimitExceeded`` or
    ///   ``ProvenanceClaimError/invalidField``.
    public init(
        name: String,
        version: SemanticVersion,
        commit: String?,
        buildIdentifier: String?
    ) throws {
        try Self.validateField(name)
        if let commit {
            try Self.validateField(commit)
        }
        if let buildIdentifier {
            try Self.validateField(buildIdentifier)
        }
        self.name = name
        self.version = version
        self.commit = commit
        self.buildIdentifier = buildIdentifier
    }

    static func validateField(_ field: String) throws {
        // Precedence step one: the byte ceiling, stopping at the first
        // byte past the maximum.
        var byteCount: UInt64 = 0
        for _ in field.utf8 {
            byteCount += 1
            if byteCount > Self.maximumFieldUTF8ByteCount {
                throw ProvenanceClaimError.fieldByteLimitExceeded
            }
        }

        // Precedence step two: control scalars; step three: blank text
        // under the frozen identity whitespace oracle.
        var hasNonWhitespaceScalar = false
        for scalar in field.unicodeScalars {
            switch scalar.value {
            case 0x00...0x1F, 0x7F, 0x80...0x9F:
                throw ProvenanceClaimError.invalidField
            default:
                if !isFrozenIdentityWhitespaceScalar(scalar) {
                    hasNonWhitespaceScalar = true
                }
            }
        }
        guard hasNonWhitespaceScalar else {
            throw ProvenanceClaimError.invalidField
        }
    }

    /// Compares every field exactly, including version build metadata.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name.utf8.elementsEqual(rhs.name.utf8)
            && DerivationIdentity.exactVersionEquals(lhs.version, rhs.version)
            && exactOptionalEquals(lhs.commit, rhs.commit)
            && exactOptionalEquals(lhs.buildIdentifier, rhs.buildIdentifier)
    }

    /// Hashes every field exactly, including version build metadata.
    public func hash(into hasher: inout Hasher) {
        Self.hashField(name, into: &hasher)
        DerivationIdentity.hashExactVersion(version, into: &hasher)
        Self.hashOptionalField(commit, into: &hasher)
        Self.hashOptionalField(buildIdentifier, into: &hasher)
    }

    static func exactOptionalEquals(_ lhs: String?, _ rhs: String?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            true
        case (let lhsValue?, let rhsValue?):
            lhsValue.utf8.elementsEqual(rhsValue.utf8)
        default:
            false
        }
    }

    static func hashField(_ field: String, into hasher: inout Hasher) {
        hasher.combine(field.utf8.count)
        for byte in field.utf8 {
            hasher.combine(byte)
        }
    }

    static func hashOptionalField(_ field: String?, into hasher: inout Hasher) {
        if let field {
            hasher.combine(true)
            hashField(field, into: &hasher)
        } else {
            hasher.combine(false)
        }
    }
}

/// One asserted completed operation per `ADR-0057`.
///
/// Unlike the derivation recipe, the implementation is required: a
/// completed run always ran something. The operation and implementation
/// tokens come from the shared semantic-operation naming domain owned
/// by `ADR-0055`, versions compare exactly including build metadata,
/// and the parameter digest must carry the registered
/// operation-parameters tuple.
public struct OperationProvenance: Sendable, Hashable {
    public let operationID: DerivationOperationToken
    public let operationVersion: SemanticVersion
    public let implementationID: DerivationOperationToken
    public let implementationVersion: SemanticVersion
    public let parameterDigest: ContentID

    /// Creates a validated operation claim.
    ///
    /// - Throws:
    ///   ``ProvenanceClaimError/unsupportedParameterProjection`` when
    ///   the digest is not the registered operation-parameters tuple.
    public init(
        operationID: DerivationOperationToken,
        operationVersion: SemanticVersion,
        implementationID: DerivationOperationToken,
        implementationVersion: SemanticVersion,
        parameterDigest: ContentID
    ) throws {
        guard
            parameterDigest.scope == .serialisedObject,
            parameterDigest.projection == ContentID.operationParametersProjection
        else {
            throw ProvenanceClaimError.unsupportedParameterProjection
        }
        self.operationID = operationID
        self.operationVersion = operationVersion
        self.implementationID = implementationID
        self.implementationVersion = implementationVersion
        self.parameterDigest = parameterDigest
    }

    /// Compares every field exactly, including build metadata.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.operationID == rhs.operationID
            && DerivationIdentity.exactVersionEquals(
                lhs.operationVersion,
                rhs.operationVersion
            )
            && lhs.implementationID == rhs.implementationID
            && DerivationIdentity.exactVersionEquals(
                lhs.implementationVersion,
                rhs.implementationVersion
            )
            && lhs.parameterDigest == rhs.parameterDigest
    }

    /// Hashes every field exactly, including build metadata.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(operationID)
        DerivationIdentity.hashExactVersion(operationVersion, into: &hasher)
        hasher.combine(implementationID)
        DerivationIdentity.hashExactVersion(implementationVersion, into: &hasher)
        hasher.combine(parameterDigest)
    }
}

/// One bounded operation-defined provenance input role per `ADR-0057`.
///
/// A role is a single lowercase label of 1 through 63 bytes — `a` to
/// `z`, `0` to `9` or `-`, starting and ending alphanumeric — with
/// exact-byte identity.
public struct ProvenanceInputRole: Sendable, Hashable {
    /// The hard inclusive role byte ceiling.
    public static let maximumRoleUTF8ByteCount: UInt64 = 63

    public let rawValue: String

    /// Creates a validated role with the byte ceiling checked before the
    /// grammar.
    public init(rawValue: String) throws {
        var byteCount: UInt64 = 0
        for _ in rawValue.utf8 {
            byteCount += 1
            if byteCount > Self.maximumRoleUTF8ByteCount {
                throw ProvenanceClaimError.roleByteLimitExceeded
            }
        }
        var previousByte: UInt8?
        for byte in rawValue.utf8 {
            let isAlphanumeric =
                (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
                || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
            let isHyphen = byte == UInt8(ascii: "-")
            guard isAlphanumeric || isHyphen else {
                throw ProvenanceClaimError.invalidRole
            }
            if previousByte == nil && isHyphen {
                throw ProvenanceClaimError.invalidRole
            }
            previousByte = byte
        }
        guard let last = previousByte, last != UInt8(ascii: "-") else {
            throw ProvenanceClaimError.invalidRole
        }
        self.rawValue = rawValue
    }

    /// Compares the exact ASCII role bytes.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.utf8.elementsEqual(rhs.rawValue.utf8)
    }

    /// Hashes the exact ASCII role bytes.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.utf8.count)
        for byte in rawValue.utf8 {
            hasher.combine(byte)
        }
    }
}

/// One validated externally stored parent-record claim per `ADR-0062`.
///
/// The claim binds one parent identifier to the exact registered
/// provenance-record digest of that parent's canonical bytes; any other
/// tuple is a typed rejection. The claim proves neither that the
/// external record exists nor that it is authentic — resolution
/// verifies the digest timing-safe against supplied canonical bytes.
public struct ExternalProvenanceRecordReference: Sendable, Hashable {
    public let id: ProvenanceID
    public let recordContentID: ContentID

    /// Creates a validated external record claim.
    ///
    /// - Throws: ``ProvenanceClaimError/unsupportedRecordProjection``
    ///   when the digest is not the registered provenance-record tuple.
    public init(id: ProvenanceID, recordContentID: ContentID) throws {
        guard
            recordContentID.scope == .serialisedObject,
            recordContentID.projection == ContentID.provenanceRecordProjection
        else {
            throw ProvenanceClaimError.unsupportedRecordProjection
        }
        self.id = id
        self.recordContentID = recordContentID
    }
}

/// The non-recursive reference from one provenance record to a parent.
///
/// The in-graph case names a record in the same candidate table; the
/// external case claims an externally stored record by identifier and
/// registered record-content digest per `ADR-0062`. Neither case embeds
/// a record, so cycles and unbounded decoding stay structurally
/// impossible.
public enum ProvenanceParentReference: Sendable, Hashable {
    case graphNode(ProvenanceID)
    case externalRecord(ExternalProvenanceRecordReference)
}

/// One role-bearing provenance input claim per `ADR-0038` and
/// `ADR-0057`.
///
/// The input binds one explicit operation role and occurrence ordinal
/// to an input data-identity claim and, when known, one parent
/// provenance reference. Occurrence ordinals start at one; uniqueness
/// rules bind at the record level.
public struct ProvenanceInput: Sendable, Hashable {
    public let role: ProvenanceInputRole
    public let occurrence: UInt32
    public let identity: DataIdentityReference
    public let parent: ProvenanceParentReference?

    /// Creates a validated input claim.
    ///
    /// - Throws: ``ProvenanceClaimError/invalidOccurrence`` when the
    ///   ordinal is zero.
    public init(
        role: ProvenanceInputRole,
        occurrence: UInt32,
        identity: DataIdentityReference,
        parent: ProvenanceParentReference?
    ) throws {
        guard occurrence >= 1 else {
            throw ProvenanceClaimError.invalidOccurrence
        }
        self.role = role
        self.occurrence = occurrence
        self.identity = identity
        self.parent = parent
    }
}
