// SPDX-License-Identifier: MIT

/// An error raised while validating an execution claim value.
///
/// Cases deliberately carry no payload so diagnostics never disclose the
/// rejected token or version text.
public enum ExecutionClaimError: Error, Sendable, Equatable {
    case invalidToken
    case tokenByteLimitExceeded
    case inexactVersion
}

/// One bounded, descriptive execution claim token.
///
/// The token uses the bounded lowercase ASCII reverse-domain grammar and
/// the byte-limit-before-grammar precedence selected by `ADR-0036` for
/// projection identifiers, as its own nominal authority per `ADR-0051`.
/// A token is descriptive, never executable and never a registry lookup:
/// an untrusted record cannot select a callback, plugin, dynamic library
/// or live object through it.
public struct ExecutionClaimToken: Sendable, Hashable {
    /// The hard inclusive complete-token byte ceiling.
    public static let maximumTokenUTF8ByteCount: UInt64 = 255
    /// The hard inclusive per-label byte ceiling.
    public static let maximumTokenLabelByteCount: UInt64 = 63

    public let rawValue: String

    /// Creates a validated token with fixed byte-limit-before-grammar
    /// precedence: the complete byte count is checked first, each label
    /// length next, and grammar rules only then, so oversized
    /// valid-looking input fails as a byte-limit error.
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
                throw ExecutionClaimError.tokenByteLimitExceeded
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
                throw ExecutionClaimError.tokenByteLimitExceeded
            }
        }

        // Precedence step three: empty labels, characters, first/last
        // characters and the label count.
        var labelCount: UInt64 = 0
        var previousByte: UInt8?
        for byte in token.utf8 {
            if byte == UInt8(ascii: ".") {
                guard let last = previousByte, isLabelAlphanumeric(last) else {
                    throw ExecutionClaimError.invalidToken
                }
                labelCount += 1
                previousByte = byte
                continue
            }
            let isHyphen = byte == UInt8(ascii: "-")
            guard isLabelAlphanumeric(byte) || isHyphen else {
                throw ExecutionClaimError.invalidToken
            }
            let startsLabel = previousByte == nil || previousByte == UInt8(ascii: ".")
            if startsLabel && isHyphen {
                throw ExecutionClaimError.invalidToken
            }
            previousByte = byte
        }
        guard let last = previousByte, isLabelAlphanumeric(last) else {
            throw ExecutionClaimError.invalidToken
        }
        labelCount += 1
        guard labelCount >= 2 else {
            throw ExecutionClaimError.invalidToken
        }
    }
}

/// One identified, exactly versioned execution component claim.
///
/// The claim record's field names assign the roles (profile, backend,
/// kernel); this value binds one token to one exact version. Build
/// metadata is rejected because it does not participate in
/// `SemanticVersion` equality, and every output-affecting claim field
/// must be identity-bearing.
public struct ExecutionComponentReference: Sendable, Hashable {
    public let identifier: ExecutionClaimToken
    public let version: SemanticVersion

    /// Creates a reference unless the version carries build metadata.
    ///
    /// - Throws: ``ExecutionClaimError/inexactVersion`` when build
    ///   metadata is present.
    public init(identifier: ExecutionClaimToken, version: SemanticVersion) throws {
        guard version.buildMetadata == nil else {
            throw ExecutionClaimError.inexactVersion
        }
        self.identifier = identifier
        self.version = version
    }
}

/// The closed approximation status of one asserted execution.
///
/// Exactly two cases exist; any extension requires its own decision
/// record per `ADR-0051`.
public enum ExecutionApproximationStatus: Sendable, Hashable {
    case exact
    case approximate
}

/// One immutable backend-neutral execution claim per `ADR-0038` and
/// `ADR-0051`.
///
/// The claim asserts which profile, backend, policies, approximation
/// status and optionally capability class and kernel produced a result.
/// It is a claim, not evidence: constructing or comparing it proves
/// nothing about what actually ran. No live Execution, Storage or
/// Validation object can be stored here, and its stable coding is owned
/// by the future canonical provenance-record projection decision.
public struct ExecutionProvenanceClaim: Sendable, Hashable {
    public let profile: ExecutionComponentReference
    public let backend: ExecutionComponentReference
    public let precisionPolicy: ExecutionClaimToken
    public let qualityPolicy: ExecutionClaimToken
    public let approximationStatus: ExecutionApproximationStatus
    public let capabilityClass: ExecutionClaimToken?
    public let kernel: ExecutionComponentReference?

    /// Creates a claim from already-validated component values; optional
    /// fields have no defaults, so every construction site states them.
    public init(
        profile: ExecutionComponentReference,
        backend: ExecutionComponentReference,
        precisionPolicy: ExecutionClaimToken,
        qualityPolicy: ExecutionClaimToken,
        approximationStatus: ExecutionApproximationStatus,
        capabilityClass: ExecutionClaimToken?,
        kernel: ExecutionComponentReference?
    ) {
        self.profile = profile
        self.backend = backend
        self.precisionPolicy = precisionPolicy
        self.qualityPolicy = qualityPolicy
        self.approximationStatus = approximationStatus
        self.capabilityClass = capabilityClass
        self.kernel = kernel
    }
}
