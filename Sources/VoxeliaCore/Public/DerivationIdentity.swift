// SPDX-License-Identifier: MIT

/// An error raised while validating a derivation identity value.
///
/// Cases deliberately carry no payload so diagnostics never disclose the
/// rejected token, role or record content.
public enum DerivationIdentityError: Error, Sendable, Equatable {
    case invalidToken
    case tokenByteLimitExceeded
    case invalidRole
    case roleByteLimitExceeded
    case emptyInputSequence
    case unexpectedInputSequence
    case unsupportedParameterProjection
    case unsupportedRecordProjection
}

/// One validated content-addressed derivation record claim per
/// `ADR-0072`.
///
/// The claim wraps the registered derivation-record digest of one
/// canonical `VCDJ-1` document; any other tuple is a typed rejection.
/// It identifies a recipe by content and proves neither determinism
/// nor input assurance.
public struct DerivationRecordID: Sendable, Hashable {
    public let recordContentID: ContentID

    /// Creates a validated derivation record claim.
    ///
    /// - Throws:
    ///   ``DerivationIdentityError/unsupportedRecordProjection`` when
    ///   the digest is not the registered derivation-record tuple.
    public init(recordContentID: ContentID) throws {
        guard
            recordContentID.scope == .serialisedObject,
            recordContentID.projection == ContentID.derivationRecordProjection
        else {
            throw DerivationIdentityError.unsupportedRecordProjection
        }
        self.recordContentID = recordContentID
    }
}

/// One bounded, descriptive derivation operation or implementation token.
///
/// The token uses the bounded lowercase ASCII reverse-domain grammar with
/// byte-limit-before-grammar precedence as its own nominal authority per
/// `ADR-0055`. It is descriptive, never executable and never a registry
/// lookup.
public struct DerivationOperationToken: Sendable, Hashable {
    /// The hard inclusive complete-token byte ceiling.
    public static let maximumTokenUTF8ByteCount: UInt64 = 255
    /// The hard inclusive per-label byte ceiling.
    public static let maximumTokenLabelByteCount: UInt64 = 63

    public let rawValue: String

    /// Creates a validated token with fixed byte-limit-before-grammar
    /// precedence.
    public init(rawValue: String) throws {
        try Self.validateToken(rawValue)
        self.rawValue = rawValue
    }

    /// Compares the exact ASCII token bytes.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.utf8.elementsEqual(rhs.rawValue.utf8)
    }

    /// Hashes the exact ASCII token bytes.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.utf8.count)
        for byte in rawValue.utf8 {
            hasher.combine(byte)
        }
    }

    private static func isLabelAlphanumeric(_ byte: UInt8) -> Bool {
        (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
            || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
    }

    static func validateToken(_ token: String) throws {
        // Precedence step one: the complete byte ceiling, stopping at the
        // first byte past the maximum.
        var totalByteCount: UInt64 = 0
        for _ in token.utf8 {
            totalByteCount += 1
            if totalByteCount > Self.maximumTokenUTF8ByteCount {
                throw DerivationIdentityError.tokenByteLimitExceeded
            }
        }

        // Precedence step two: each label length.
        var labelByteCount: UInt64 = 0
        for byte in token.utf8 {
            if byte == UInt8(ascii: ".") {
                labelByteCount = 0
                continue
            }
            labelByteCount += 1
            if labelByteCount > Self.maximumTokenLabelByteCount {
                throw DerivationIdentityError.tokenByteLimitExceeded
            }
        }

        // Precedence step three: empty labels, characters, first/last
        // characters and the label count.
        var labelCount: UInt64 = 0
        var previousByte: UInt8?
        for byte in token.utf8 {
            if byte == UInt8(ascii: ".") {
                guard let last = previousByte, isLabelAlphanumeric(last) else {
                    throw DerivationIdentityError.invalidToken
                }
                labelCount += 1
                previousByte = byte
                continue
            }
            let isHyphen = byte == UInt8(ascii: "-")
            guard isLabelAlphanumeric(byte) || isHyphen else {
                throw DerivationIdentityError.invalidToken
            }
            let startsLabel = previousByte == nil || previousByte == UInt8(ascii: ".")
            if startsLabel && isHyphen {
                throw DerivationIdentityError.invalidToken
            }
            previousByte = byte
        }
        guard let last = previousByte, isLabelAlphanumeric(last) else {
            throw DerivationIdentityError.invalidToken
        }
        labelCount += 1
        guard labelCount >= 2 else {
            throw DerivationIdentityError.invalidToken
        }
    }
}

/// One bounded operation-defined input role per `ADR-0055`.
///
/// A role is a single lowercase label of 1 through 63 bytes — `a` to
/// `z`, `0` to `9` or `-`, starting and ending alphanumeric — with
/// exact-byte identity. The record does not interpret roles; the owning
/// operation contract defines them.
public struct DerivationInputRole: Sendable, Hashable {
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
                throw DerivationIdentityError.roleByteLimitExceeded
            }
        }
        var previousByte: UInt8?
        for byte in rawValue.utf8 {
            let isAlphanumeric =
                (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
                || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
            let isHyphen = byte == UInt8(ascii: "-")
            guard isAlphanumeric || isHyphen else {
                throw DerivationIdentityError.invalidRole
            }
            if previousByte == nil && isHyphen {
                throw DerivationIdentityError.invalidRole
            }
            previousByte = byte
        }
        guard let last = previousByte, last != UInt8(ascii: "-") else {
            throw DerivationIdentityError.invalidRole
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

/// One positional role-bearing derivation input.
public struct DerivationInput: Sendable, Hashable {
    public let role: DerivationInputRole
    public let identity: DataIdentityReference

    public init(role: DerivationInputRole, identity: DataIdentityReference) {
        self.role = role
        self.identity = identity
    }
}

/// One identified implementation whose version may carry build metadata,
/// because implementation builds can differ only there; the owning
/// record compares that metadata exactly.
public struct DerivationImplementationReference: Sendable, Hashable {
    public let identifier: DerivationOperationToken
    public let version: SemanticVersion

    public init(identifier: DerivationOperationToken, version: SemanticVersion) {
        self.identifier = identifier
        self.version = version
    }

    /// Compares the token and the exact version including build
    /// metadata.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
            && DerivationIdentity.exactVersionEquals(lhs.version, rhs.version)
    }

    /// Hashes the token and the exact version including build metadata.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        DerivationIdentity.hashExactVersion(version, into: &hasher)
    }
}

/// One immutable derivation recipe claim per `ADR-0037` and `ADR-0055`.
///
/// The record asserts which semantic operation, implementation,
/// positional role-bearing inputs and registered parameter digest
/// produced a result. Accepted input order and exact repeats are
/// preserved and participate in identity, and every stored version field
/// compares exactly, including build metadata. A derivation identity is
/// a semantic recipe claim, not an execution cache key: it proves
/// neither determinism nor input assurance. The stable coding, the
/// input-count ceiling and `DerivationRecordID` belong to the future
/// canonical derivation-record projection decision.
public struct DerivationIdentity: Sendable, Hashable {
    public let operationID: DerivationOperationToken
    public let operationVersion: SemanticVersion
    public let implementation: DerivationImplementationReference?
    public let inputs: ContiguousArray<DerivationInput>
    public let parameterDigest: ContentID

    /// Creates a validated derivation recipe claim.
    ///
    /// - Throws: ``DerivationIdentityError/emptyInputSequence`` for an
    ///   undeclared empty sequence,
    ///   ``DerivationIdentityError/unexpectedInputSequence`` for a
    ///   declared zero-input generator carrying inputs, or
    ///   ``DerivationIdentityError/unsupportedParameterProjection`` when
    ///   the digest is not the registered operation-parameters tuple.
    public init(
        operationID: DerivationOperationToken,
        operationVersion: SemanticVersion,
        implementation: DerivationImplementationReference?,
        inputs: ContiguousArray<DerivationInput>,
        parameterDigest: ContentID,
        declaresZeroInputGenerator: Bool
    ) throws {
        if inputs.isEmpty && !declaresZeroInputGenerator {
            throw DerivationIdentityError.emptyInputSequence
        }
        if !inputs.isEmpty && declaresZeroInputGenerator {
            throw DerivationIdentityError.unexpectedInputSequence
        }
        guard
            parameterDigest.scope == .serialisedObject,
            parameterDigest.projection == ContentID.operationParametersProjection
        else {
            throw DerivationIdentityError.unsupportedParameterProjection
        }
        self.operationID = operationID
        self.operationVersion = operationVersion
        self.implementation = implementation
        self.inputs = inputs
        self.parameterDigest = parameterDigest
    }

    /// Compares every stored field exactly, including build metadata.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.operationID == rhs.operationID
            && exactVersionEquals(lhs.operationVersion, rhs.operationVersion)
            && lhs.implementation == rhs.implementation
            && lhs.inputs == rhs.inputs
            && lhs.parameterDigest == rhs.parameterDigest
    }

    /// Hashes every stored field exactly, including build metadata.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(operationID)
        Self.hashExactVersion(operationVersion, into: &hasher)
        if let implementation {
            hasher.combine(true)
            hasher.combine(implementation)
        } else {
            hasher.combine(false)
        }
        hasher.combine(inputs)
        hasher.combine(parameterDigest)
    }

    /// Exact version equality including build metadata, which ordinary
    /// semantic-version equality excludes.
    static func exactVersionEquals(
        _ lhs: SemanticVersion,
        _ rhs: SemanticVersion
    ) -> Bool {
        lhs == rhs && lhs.buildMetadata == rhs.buildMetadata
    }

    static func hashExactVersion(
        _ version: SemanticVersion,
        into hasher: inout Hasher
    ) {
        hasher.combine(version)
        hasher.combine(version.buildMetadata)
    }
}
