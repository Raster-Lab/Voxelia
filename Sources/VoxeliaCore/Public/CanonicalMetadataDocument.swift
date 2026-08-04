// SPDX-License-Identifier: MIT

/// An error raised by strict `VCMJ-1` ingress.
///
/// Cases deliberately carry no payload: no raw byte, token, key, value,
/// schema identifier or version, privacy class, path, offset, index,
/// count, limit name or underlying error is retained.
public enum MetadataJSONIngressError: Error, Sendable, Equatable {
    case invalidDocument
    case unsupportedSchemaVersion
    case resourceLimitExceeded
    case cancelled
}

/// An error raised by canonical `VCMJ-1` emission.
///
/// Cases deliberately carry no payload under the same redaction rules as
/// ingress.
public enum MetadataJSONEmissionError: Error, Sendable, Equatable {
    case invalidValue
    case resourceLimitExceeded
    case cancelled
}

/// The immutable caller resource limits snapshotted by one ingress
/// operation before any byte is consumed.
///
/// All maxima are inclusive `UInt64` ceilings; a use of exactly the
/// maximum succeeds and the next unit fails. There is no permissive
/// default for untrusted ingress: every limit is an explicit caller
/// choice, and input bytes can never raise a limit. A limit lower than
/// the hard model ceilings is a local restricted admission policy, not
/// another canonical profile.
public struct CanonicalMetadataIngressLimits: Sendable {
    /// Every source octet from operation start through the end of input.
    public let maximumRawDocumentByteCount: UInt64
    /// Raw bytes of each lexical token, including quotes and escapes.
    public let maximumRawTokenByteCount: UInt64
    /// Decoded UTF-8 bytes of each JSON string, excluding quotes.
    public let maximumDecodedStringByteCount: UInt64
    /// Validated Base64 ASCII content bytes of each binary value.
    public let maximumEncodedBinaryByteCount: UInt64
    /// Decoded output octets of each binary value.
    public let maximumDecodedBinaryByteCount: UInt64
    /// Direct members of the entry array and of each recursive container.
    public let maximumDirectMemberCount: UInt64
    /// Simultaneously open raw JSON frames, root object at one.
    public let maximumRawNestingDepth: UInt64

    public init(
        maximumRawDocumentByteCount: UInt64,
        maximumRawTokenByteCount: UInt64,
        maximumDecodedStringByteCount: UInt64,
        maximumEncodedBinaryByteCount: UInt64,
        maximumDecodedBinaryByteCount: UInt64,
        maximumDirectMemberCount: UInt64,
        maximumRawNestingDepth: UInt64
    ) {
        self.maximumRawDocumentByteCount = maximumRawDocumentByteCount
        self.maximumRawTokenByteCount = maximumRawTokenByteCount
        self.maximumDecodedStringByteCount = maximumDecodedStringByteCount
        self.maximumEncodedBinaryByteCount = maximumEncodedBinaryByteCount
        self.maximumDecodedBinaryByteCount = maximumDecodedBinaryByteCount
        self.maximumDirectMemberCount = maximumDirectMemberCount
        self.maximumRawNestingDepth = maximumRawNestingDepth
    }
}

/// One immutable trusted multiplicity binding supplied out of band.
///
/// The caller asserts that `multiplicityPolicy` was resolved for exactly
/// `expectedSchema` under its own trusted external schema selection. The
/// wire never carries a repeatable-key allow-list and can never widen,
/// replace or select this policy; Core cannot verify the assertion.
public struct CanonicalMultiplicityContext: Sendable {
    public let expectedSchema: MetadataSchemaReference
    public let multiplicityPolicy: MetadataMultiplicityPolicy
    /// The caller-selected inclusive ceiling on the policy's retained
    /// unique-key count, preflighted before input is read.
    public let maximumRetainedPolicyKeyCount: UInt64
    /// The caller-selected inclusive ceiling on the policy's retained
    /// exact namespace/name UTF-8 byte sum, preflighted before input is
    /// read.
    public let maximumRetainedPolicyKeyByteCount: UInt64

    public init(
        expectedSchema: MetadataSchemaReference,
        multiplicityPolicy: MetadataMultiplicityPolicy,
        maximumRetainedPolicyKeyCount: UInt64,
        maximumRetainedPolicyKeyByteCount: UInt64
    ) {
        self.expectedSchema = expectedSchema
        self.multiplicityPolicy = multiplicityPolicy
        self.maximumRetainedPolicyKeyCount = maximumRetainedPolicyKeyCount
        self.maximumRetainedPolicyKeyByteCount = maximumRetainedPolicyKeyByteCount
    }
}

/// The immutable result of one successful strict `VCMJ-1` decode.
///
/// The value has no public initializer: construction happens inside the
/// codec after complete validation, and programmatic emission uses the
/// explicit unique/configured operations rather than an unchecked
/// document. It has no `Codable`, `Hashable`, textual or safe-display
/// conformance in version one; default interpolation and reflection can
/// still expose stored payloads, so the document must not be interpolated
/// or reflected into logs, telemetry, filenames or user interfaces.
public struct CanonicalMetadataDocument: Sendable {
    /// The fixed matched `VCMJ-1` document-schema reference.
    public let documentSchema: MetadataSchemaReference
    /// The matched multiplicity-profile reference, or `nil` for the
    /// unique-only path.
    public let multiplicitySchema: MetadataSchemaReference?
    /// The completely validated payload collection.
    public let payload: MetadataCollection

    init(
        documentSchema: MetadataSchemaReference,
        multiplicitySchema: MetadataSchemaReference?,
        payload: MetadataCollection
    ) {
        self.documentSchema = documentSchema
        self.multiplicitySchema = multiplicitySchema
        self.payload = payload
    }
}
