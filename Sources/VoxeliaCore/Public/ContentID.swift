// SPDX-License-Identifier: MIT

import CryptoKit
import Darwin

/// One exact major/minor content-projection version.
///
/// A projection version identifies the exact digest preimage rules and is
/// independent of `MetadataSchemaVersion`; every digest projection version
/// is an exact registered value, never inferred from same-major
/// compatibility. The type gains no standalone `Codable`; its stable
/// coding exists only inside the validated `ContentID` record.
public struct ContentProjectionVersion: Sendable, Hashable {
    public let major: UInt32
    public let minor: UInt32

    public init(major: UInt32, minor: UInt32) {
        self.major = major
        self.minor = minor
    }
}

/// An error raised while validating a content-projection identifier.
///
/// Cases deliberately carry no payload so diagnostics never disclose the
/// rejected identifier text.
public enum ContentProjectionReferenceError: Error, Sendable, Equatable {
    case invalidIdentifier
    case identifierByteLimitExceeded
}

/// One bounded, descriptive content-projection reference.
///
/// The identifier uses the bounded lowercase ASCII reverse-domain grammar
/// selected by `ADR-0035` for schema identifiers, but this is a distinct
/// nominal type with a distinct authority. The reference is descriptive,
/// not executable and not a registry lookup: an untrusted record cannot
/// register a new tuple or choose a callback, plugin, dynamic library,
/// network resolver or arbitrary output length.
public struct ContentProjectionReference: Sendable, Hashable {
    /// The hard inclusive complete-identifier byte ceiling.
    public static let maximumIdentifierUTF8ByteCount: UInt64 = 255
    /// The hard inclusive per-label byte ceiling.
    public static let maximumIdentifierLabelByteCount: UInt64 = 63

    public let identifier: String
    public let version: ContentProjectionVersion

    /// Creates a validated reference with fixed byte-limit-before-grammar
    /// precedence: the complete identifier byte count is checked first,
    /// each decoded label length next, and grammar rules only then, so
    /// oversized valid-looking input fails as a byte-limit error. The
    /// incremental scans stop before copying a 256th byte and never
    /// allocate an unbounded byte array.
    public init(identifier: String, version: ContentProjectionVersion) throws {
        try Self.validateIdentifier(identifier)
        self.identifier = identifier
        self.version = version
    }

    /// Internal construction for the compiled accepted profile constants,
    /// whose identifiers are validated by the registration tests.
    init(compiledIdentifier: String, version: ContentProjectionVersion) {
        self.identifier = compiledIdentifier
        self.version = version
    }

    /// Compares the exact ASCII identifier bytes and the exact version.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier.utf8.elementsEqual(rhs.identifier.utf8)
            && lhs.version == rhs.version
    }

    /// Hashes the exact ASCII identifier bytes and the exact version.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier.utf8.count)
        for byte in identifier.utf8 {
            hasher.combine(byte)
        }
        hasher.combine(version)
    }

    private static func isLabelAlphanumeric(_ byte: UInt8) -> Bool {
        (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
            || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
    }

    static func validateIdentifier(_ identifier: String) throws {
        // Precedence step one: the complete byte ceiling, stopping at the
        // first byte past the maximum.
        var totalByteCount: UInt64 = 0
        for _ in identifier.utf8 {
            totalByteCount += 1
            if totalByteCount > Self.maximumIdentifierUTF8ByteCount {
                throw ContentProjectionReferenceError.identifierByteLimitExceeded
            }
        }

        // Precedence step two: each decoded label length.
        var labelByteCount: UInt64 = 0
        for byte in identifier.utf8 {
            if byte == UInt8(ascii: ".") {
                labelByteCount = 0
                continue
            }
            labelByteCount += 1
            if labelByteCount > Self.maximumIdentifierLabelByteCount {
                throw ContentProjectionReferenceError.identifierByteLimitExceeded
            }
        }

        // Precedence step three: empty labels, characters, first/last
        // characters and the label count.
        var labelCount: UInt64 = 0
        var previousByte: UInt8?
        for byte in identifier.utf8 {
            if byte == UInt8(ascii: ".") {
                guard let last = previousByte, isLabelAlphanumeric(last) else {
                    throw ContentProjectionReferenceError.invalidIdentifier
                }
                labelCount += 1
                previousByte = byte
                continue
            }
            let isHyphen = byte == UInt8(ascii: "-")
            guard isLabelAlphanumeric(byte) || isHyphen else {
                throw ContentProjectionReferenceError.invalidIdentifier
            }
            let startsLabel = previousByte == nil || previousByte == UInt8(ascii: ".")
            if startsLabel && isHyphen {
                throw ContentProjectionReferenceError.invalidIdentifier
            }
            previousByte = byte
        }
        guard let last = previousByte, isLabelAlphanumeric(last) else {
            throw ContentProjectionReferenceError.invalidIdentifier
        }
        labelCount += 1
        guard labelCount >= 2 else {
            throw ContentProjectionReferenceError.invalidIdentifier
        }
    }
}

/// An error raised by content-identity construction, coding, digest
/// computation or verification.
///
/// Cases deliberately carry no payload: no algorithm token, scope,
/// projection identifier or version, digest, payload byte or count,
/// metadata content, policy content, source path or underlying error is
/// retained.
public enum ContentIdentityError: Error, Sendable, Equatable {
    case invalidRecord
    case unsupportedAlgorithm
    case unsupportedProjection
    case resourceLimitExceeded
    case cancelled
}

/// One scoped, projected content identifier.
///
/// The record binds the algorithm, content scope, versioned projection and
/// owned digest bytes; the same discriminators are bound into the digest
/// preimage by the `ADR-0036` frame, so an identity can never be confused
/// with a raw checksum or another SHA-256 use. There is no public
/// unchecked initializer: version one compiles exactly one accepted
/// generation/verification tuple. The digest is sensitive-derived material
/// by default — an equality and linkage oracle that proves no authorship,
/// authenticity, permission or de-identification — and it must not be
/// interpolated or reflected into logs, telemetry, URLs, filenames or user
/// interfaces.
public struct ContentID: Sendable, Hashable, Codable {
    public let algorithm: DigestAlgorithm
    public let scope: ContentScope
    public let projection: ContentProjectionReference
    private let storage: ContiguousArray<UInt8>

    /// The owned digest bytes; mutating a returned copy cannot mutate the
    /// stored digest.
    public var digest: ContiguousArray<UInt8> {
        storage
    }

    init(
        validatedAlgorithm algorithm: DigestAlgorithm,
        scope: ContentScope,
        projection: ContentProjectionReference,
        digestBytes: ContiguousArray<UInt8>
    ) {
        self.algorithm = algorithm
        self.scope = scope
        self.projection = projection
        self.storage = digestBytes
    }
}

extension ContentID {
    /// The version-one complete canonical metadata record projection.
    public static let metadataCompleteRecordProjection = ContentProjectionReference(
        compiledIdentifier: "org.voxelia.metadata-complete-record",
        version: ContentProjectionVersion(major: 1, minor: 0)
    )

    /// The exact SHA-256 digest byte count required by the accepted tuple.
    public static let sha256DigestByteCount = 32

    private static let frameMagic = "VOXELIA-CONTENT-ID"
    private static let frameVersion: UInt32 = 1
    private static let sha256FrameInputLimit: UInt64 = (1 << 61) - 1
    private static let hashChunkByteCount = 4_096

    /// Validates one candidate tuple against the compiled accepted set.
    static func validateAcceptedProfile(
        algorithm: DigestAlgorithm,
        scope: ContentScope,
        projection: ContentProjectionReference,
        digestByteCount: Int
    ) throws {
        guard algorithm == .sha256 else {
            throw ContentIdentityError.unsupportedAlgorithm
        }
        guard
            scope == .serialisedObject,
            projection == Self.metadataCompleteRecordProjection
        else {
            throw ContentIdentityError.unsupportedProjection
        }
        guard digestByteCount == Self.sha256DigestByteCount else {
            throw ContentIdentityError.invalidRecord
        }
    }

    private static func appendUInt32BigEndian(_ value: UInt32, to bytes: inout [UInt8]) {
        bytes.append(UInt8(truncatingIfNeeded: value >> 24))
        bytes.append(UInt8(truncatingIfNeeded: value >> 16))
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value))
    }

    private static func appendUInt64BigEndian(_ value: UInt64, to bytes: inout [UInt8]) {
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8(truncatingIfNeeded: value >> UInt64(shift)))
        }
    }

    /// The exact 109-byte version-one identity frame header.
    static func completeRecordFrameHeader(payloadByteCount: UInt64) -> [UInt8] {
        var header = [UInt8]()
        header.reserveCapacity(109)
        header.append(contentsOf: Array(Self.frameMagic.utf8))
        header.append(0)
        appendUInt32BigEndian(Self.frameVersion, to: &header)
        appendUInt32BigEndian(6, to: &header)
        header.append(contentsOf: Array("sha256".utf8))
        appendUInt32BigEndian(16, to: &header)
        header.append(contentsOf: Array("serialisedObject".utf8))
        appendUInt32BigEndian(36, to: &header)
        header.append(
            contentsOf: Array("org.voxelia.metadata-complete-record".utf8)
        )
        appendUInt32BigEndian(1, to: &header)
        appendUInt32BigEndian(0, to: &header)
        appendUInt64BigEndian(payloadByteCount, to: &header)
        return header
    }

    /// Computes the complete canonical metadata record identity over the
    /// exact complete accepted `VCMJ-1` bytes.
    ///
    /// The caller must supply bytes produced or accepted by the dedicated
    /// canonical codec; the identity binds the tuple written in the record
    /// and proves neither schema authenticity nor policy correctness. The
    /// 109-byte header and bounded payload slices feed one incremental
    /// hasher; cancellation is checked before hashing, at chunk
    /// boundaries, before finalisation and immediately before the success
    /// linearisation point, and every failure discards the tentative
    /// digest without publishing anything.
    public static func completeMetadataRecordIdentity(
        overCanonicalBytes canonicalBytes: [UInt8]
    ) throws -> ContentID {
        if Task.isCancelled {
            throw ContentIdentityError.cancelled
        }
        let payloadByteCount = UInt64(canonicalBytes.count)
        let (frameByteCount, overflow) = payloadByteCount.addingReportingOverflow(109)
        guard !overflow, frameByteCount <= Self.sha256FrameInputLimit else {
            throw ContentIdentityError.resourceLimitExceeded
        }

        var hasher = SHA256()
        let header = completeRecordFrameHeader(payloadByteCount: payloadByteCount)
        header.withUnsafeBytes { hasher.update(bufferPointer: $0) }

        var offset = 0
        while offset < canonicalBytes.count {
            let end = min(offset + Self.hashChunkByteCount, canonicalBytes.count)
            canonicalBytes[offset..<end].withUnsafeBytes {
                hasher.update(bufferPointer: $0)
            }
            offset = end
            if Task.isCancelled {
                throw ContentIdentityError.cancelled
            }
        }

        if Task.isCancelled {
            throw ContentIdentityError.cancelled
        }
        let digest = hasher.finalize()
        if Task.isCancelled {
            throw ContentIdentityError.cancelled
        }
        return ContentID(
            validatedAlgorithm: .sha256,
            scope: .serialisedObject,
            projection: Self.metadataCompleteRecordProjection,
            digestBytes: ContiguousArray(digest)
        )
    }

    /// Verifies this identity against candidate canonical bytes.
    ///
    /// The complete candidate digest is calculated first; the fixed 32
    /// digest bytes are then compared with the platform timing-safe byte
    /// comparator. A mismatch is a result, not an error, and carries
    /// neither digest.
    public func matchesDigest(
        ofCanonicalBytes canonicalBytes: [UInt8]
    ) throws -> Bool {
        let candidate = try Self.completeMetadataRecordIdentity(
            overCanonicalBytes: canonicalBytes
        )
        return storage.withUnsafeBufferPointer { expected in
            candidate.storage.withUnsafeBufferPointer { computed in
                guard
                    let expectedBase = expected.baseAddress,
                    let computedBase = computed.baseAddress,
                    expected.count == Self.sha256DigestByteCount,
                    computed.count == Self.sha256DigestByteCount
                else {
                    return false
                }
                return timingsafe_bcmp(
                    expectedBase,
                    computedBase,
                    Self.sha256DigestByteCount
                ) == 0
            }
        }
    }

    // MARK: - Digest text

    /// The canonical 64-character lowercase hexadecimal digest text.
    static func hexDigestText(_ bytes: ContiguousArray<UInt8>) -> String {
        let digits = Array("0123456789abcdef".utf8)
        var text = [UInt8]()
        text.reserveCapacity(bytes.count * 2)
        for byte in bytes {
            text.append(digits[Int(byte >> 4)])
            text.append(digits[Int(byte & 0xF)])
        }
        return String(decoding: text, as: UTF8.self)
    }

    /// Decodes exactly 64 lowercase hexadecimal characters; every alias
    /// (uppercase, prefix, separator, wrong length) returns `nil`.
    static func digestBytes(fromHexText text: String) -> ContiguousArray<UInt8>? {
        var bytes = ContiguousArray<UInt8>()
        bytes.reserveCapacity(Self.sha256DigestByteCount)
        var pendingHighNibble: UInt8?
        var characterCount = 0
        for byte in text.utf8 {
            characterCount += 1
            guard characterCount <= 64 else {
                return nil
            }
            let nibble: UInt8
            switch byte {
            case UInt8(ascii: "0")...UInt8(ascii: "9"):
                nibble = byte - UInt8(ascii: "0")
            case UInt8(ascii: "a")...UInt8(ascii: "f"):
                nibble = byte - UInt8(ascii: "a") + 10
            default:
                return nil
            }
            if let highNibble = pendingHighNibble {
                bytes.append(highNibble << 4 | nibble)
                pendingHighNibble = nil
            } else {
                pendingHighNibble = nibble
            }
        }
        guard characterCount == 64, pendingHighNibble == nil else {
            return nil
        }
        return bytes
    }

    // MARK: - Manual type-level coding

    private struct ArbitraryCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?

        init(_ stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(stringValue: String) {
            self.init(stringValue)
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    /// Decodes the strict four-field record, verifying the exact
    /// algorithm, digest text, scope, projection identifier and version
    /// against the compiled accepted set before the value exists.
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<ArbitraryCodingKey>
        do {
            container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        } catch {
            throw ContentIdentityError.invalidRecord
        }
        let expectedFields = Set(["algorithm", "digest", "projection", "scope"])
        guard
            container.allKeys.count == expectedFields.count,
            Set(container.allKeys.map(\.stringValue)) == expectedFields
        else {
            throw ContentIdentityError.invalidRecord
        }

        let algorithmToken: String
        let scopeToken: String
        let digestText: String
        do {
            algorithmToken = try container.decode(
                String.self,
                forKey: ArbitraryCodingKey("algorithm")
            )
            scopeToken = try container.decode(
                String.self,
                forKey: ArbitraryCodingKey("scope")
            )
            digestText = try container.decode(
                String.self,
                forKey: ArbitraryCodingKey("digest")
            )
        } catch {
            throw ContentIdentityError.invalidRecord
        }
        guard let algorithm = DigestAlgorithm(rawValue: algorithmToken) else {
            throw ContentIdentityError.invalidRecord
        }
        guard let scope = ContentScope(rawValue: scopeToken) else {
            throw ContentIdentityError.invalidRecord
        }
        guard let digestBytes = Self.digestBytes(fromHexText: digestText) else {
            throw ContentIdentityError.invalidRecord
        }

        let projection = try Self.decodeProjection(from: container)
        try Self.validateAcceptedProfile(
            algorithm: algorithm,
            scope: scope,
            projection: projection,
            digestByteCount: digestBytes.count
        )
        self.init(
            validatedAlgorithm: algorithm,
            scope: scope,
            projection: projection,
            digestBytes: digestBytes
        )
    }

    private static func decodeProjection(
        from container: KeyedDecodingContainer<ArbitraryCodingKey>
    ) throws -> ContentProjectionReference {
        let projectionContainer: KeyedDecodingContainer<ArbitraryCodingKey>
        let versionContainer: KeyedDecodingContainer<ArbitraryCodingKey>
        let identifier: String
        let major: UInt32
        let minor: UInt32
        do {
            projectionContainer = try container.nestedContainer(
                keyedBy: ArbitraryCodingKey.self,
                forKey: ArbitraryCodingKey("projection")
            )
            guard
                Set(projectionContainer.allKeys.map(\.stringValue))
                    == Set(["identifier", "version"])
            else {
                throw ContentIdentityError.invalidRecord
            }
            identifier = try projectionContainer.decode(
                String.self,
                forKey: ArbitraryCodingKey("identifier")
            )
            versionContainer = try projectionContainer.nestedContainer(
                keyedBy: ArbitraryCodingKey.self,
                forKey: ArbitraryCodingKey("version")
            )
            guard
                Set(versionContainer.allKeys.map(\.stringValue))
                    == Set(["major", "minor"])
            else {
                throw ContentIdentityError.invalidRecord
            }
            major = try versionContainer.decode(
                UInt32.self,
                forKey: ArbitraryCodingKey("major")
            )
            minor = try versionContainer.decode(
                UInt32.self,
                forKey: ArbitraryCodingKey("minor")
            )
        } catch let error as ContentIdentityError {
            throw error
        } catch {
            throw ContentIdentityError.invalidRecord
        }
        do {
            return try ContentProjectionReference(
                identifier: identifier,
                version: ContentProjectionVersion(major: major, minor: minor)
            )
        } catch {
            throw ContentIdentityError.invalidRecord
        }
    }

    /// Encodes exactly the four fixed fields with the canonical lowercase
    /// hexadecimal digest text.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
        try container.encode(
            algorithm.rawValue,
            forKey: ArbitraryCodingKey("algorithm")
        )
        try container.encode(
            Self.hexDigestText(storage),
            forKey: ArbitraryCodingKey("digest")
        )
        var projectionContainer = container.nestedContainer(
            keyedBy: ArbitraryCodingKey.self,
            forKey: ArbitraryCodingKey("projection")
        )
        try projectionContainer.encode(
            projection.identifier,
            forKey: ArbitraryCodingKey("identifier")
        )
        var versionContainer = projectionContainer.nestedContainer(
            keyedBy: ArbitraryCodingKey.self,
            forKey: ArbitraryCodingKey("version")
        )
        try versionContainer.encode(
            projection.version.major,
            forKey: ArbitraryCodingKey("major")
        )
        try versionContainer.encode(
            projection.version.minor,
            forKey: ArbitraryCodingKey("minor")
        )
        try container.encode(scope.rawValue, forKey: ArbitraryCodingKey("scope"))
    }
}
