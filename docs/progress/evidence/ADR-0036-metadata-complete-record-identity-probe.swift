import CryptoKit
import Darwin
import Foundation

// Isolated Swift 6 evidence for proposed ADR-0036. These Probe* declarations
// are deliberately not product API. The canonical metadata strings below are
// fixed fixtures, not a VCMJ parser or emitter.

enum ProbeIdentityError: Error, Sendable, Equatable {
    case invalidRecord
    case unsupportedAlgorithm
    case unsupportedProjection
    case resourceLimitExceeded
    case cancelled
}

struct ProbeProjectionVersion: Sendable, Hashable {
    let major: UInt32
    let minor: UInt32
}

enum ProbeProjectionReferenceError: Error, Sendable, Equatable {
    case invalidIdentifier
    case identifierByteLimitExceeded
}

struct ProbeProjectionReference: Sendable, Hashable {
    static let maximumIdentifierByteCount = 255
    static let maximumLabelByteCount = 63

    let identifier: String
    let version: ProbeProjectionVersion

    init(identifier: String, version: ProbeProjectionVersion) throws {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(Self.maximumIdentifierByteCount)
        for byte in identifier.utf8 {
            guard bytes.count < Self.maximumIdentifierByteCount else {
                throw ProbeProjectionReferenceError.identifierByteLimitExceeded
            }
            bytes.append(byte)
        }

        let labels = bytes.split(separator: 0x2E, omittingEmptySubsequences: false)
        for label in labels {
            guard label.count <= Self.maximumLabelByteCount else {
                throw ProbeProjectionReferenceError.identifierByteLimitExceeded
            }
        }
        guard labels.count >= 2 else {
            throw ProbeProjectionReferenceError.invalidIdentifier
        }
        for label in labels {
            guard !label.isEmpty else {
                throw ProbeProjectionReferenceError.invalidIdentifier
            }
            guard isLowercaseASCIIAlphanumeric(label.first!),
                isLowercaseASCIIAlphanumeric(label.last!)
            else {
                throw ProbeProjectionReferenceError.invalidIdentifier
            }
            guard label.allSatisfy({ isLowercaseASCIIAlphanumeric($0) || $0 == 0x2D }) else {
                throw ProbeProjectionReferenceError.invalidIdentifier
            }
        }

        self.identifier = identifier
        self.version = version
    }
}

enum ProbeDigestAlgorithm: String, Sendable, Hashable {
    case sha256
    case sha512
    case blake3
    case custom
}

enum ProbeContentScope: String, Sendable, Hashable {
    case serialisedObject
}

struct ProbeContentID: Sendable, Hashable {
    let algorithm: ProbeDigestAlgorithm
    let scope: ProbeContentScope
    let projection: ProbeProjectionReference
    private let digestStorage: ContiguousArray<UInt8>

    var digest: ContiguousArray<UInt8> {
        digestStorage
    }

    init(
        algorithm: ProbeDigestAlgorithm,
        scope: ProbeContentScope,
        projection: ProbeProjectionReference,
        digest: some Collection<UInt8>
    ) throws {
        guard algorithm == .sha256 else {
            throw ProbeIdentityError.unsupportedAlgorithm
        }
        guard scope == .serialisedObject,
            projection.identifier == "org.voxelia.metadata-complete-record",
            projection.version == ProbeProjectionVersion(major: 1, minor: 0)
        else {
            throw ProbeIdentityError.unsupportedProjection
        }
        guard digest.count == 32 else {
            throw ProbeIdentityError.invalidRecord
        }

        self.algorithm = algorithm
        self.scope = scope
        self.projection = projection
        digestStorage = ContiguousArray(digest)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.algorithm == rhs.algorithm
            && lhs.scope == rhs.scope
            && lhs.projection == rhs.projection
            && timingSafeEqual(lhs.digestStorage, rhs.digestStorage)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(algorithm)
        hasher.combine(scope)
        hasher.combine(projection)
        for byte in digestStorage {
            hasher.combine(byte)
        }
    }
}

struct ProbeMultiplicityPolicy: Sendable {
    let admittedKeys: Set<String>
}

struct ProbeMultiplicityContext: Sendable {
    let expectedReference: String
    let policy: ProbeMultiplicityPolicy
}

struct ProbeCodedConcept: Sendable, Equatable {
    let scheme: String
    let value: String
    let version: String?
    let meaning: String?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.scheme == rhs.scheme && lhs.value == rhs.value && lhs.version == rhs.version
    }
}

struct ProbeMeasurementUnit: Sendable, Equatable {
    let namespace: String
    let code: String
    let dimension: String?
    let scaleToCanonical: Double?
    let offsetToCanonical: Double?
    let displayName: String?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.namespace == rhs.namespace
            && lhs.code == rhs.code
            && lhs.dimension == rhs.dimension
            && lhs.scaleToCanonical == rhs.scaleToCanonical
            && lhs.offsetToCanonical == rhs.offsetToCanonical
    }
}

let probeFrameMagic = Array("VOXELIA-CONTENT-ID\0".utf8)
let probeFrameVersion: UInt32 = 1
let probeMaximumUpdateByteCount = 4_096
let probeMaximumSHA256InputByteCount = UInt64.max >> 3

func isLowercaseASCIIAlphanumeric(_ byte: UInt8) -> Bool {
    (0x61...0x7A).contains(byte) || (0x30...0x39).contains(byte)
}

func appendBigEndian(_ value: UInt32, to bytes: inout [UInt8]) {
    bytes.append(UInt8(truncatingIfNeeded: value >> 24))
    bytes.append(UInt8(truncatingIfNeeded: value >> 16))
    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
    bytes.append(UInt8(truncatingIfNeeded: value))
}

func appendBigEndian(_ value: UInt64, to bytes: inout [UInt8]) {
    bytes.append(UInt8(truncatingIfNeeded: value >> 56))
    bytes.append(UInt8(truncatingIfNeeded: value >> 48))
    bytes.append(UInt8(truncatingIfNeeded: value >> 40))
    bytes.append(UInt8(truncatingIfNeeded: value >> 32))
    bytes.append(UInt8(truncatingIfNeeded: value >> 24))
    bytes.append(UInt8(truncatingIfNeeded: value >> 16))
    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
    bytes.append(UInt8(truncatingIfNeeded: value))
}

func appendLengthPrefixedASCII(_ value: String, to bytes: inout [UInt8]) throws {
    let valueBytes = Array(value.utf8)
    guard valueBytes.allSatisfy({ $0 < 0x80 }),
        let byteCount = UInt32(exactly: valueBytes.count)
    else {
        throw ProbeIdentityError.invalidRecord
    }
    appendBigEndian(byteCount, to: &bytes)
    bytes.append(contentsOf: valueBytes)
}

func makeFrameHeader(
    algorithmIdentifier: String,
    scopeIdentifier: String,
    projection: ProbeProjectionReference,
    payloadByteCount: UInt64
) throws -> [UInt8] {
    var header = probeFrameMagic
    appendBigEndian(probeFrameVersion, to: &header)
    try appendLengthPrefixedASCII(algorithmIdentifier, to: &header)
    try appendLengthPrefixedASCII(scopeIdentifier, to: &header)
    try appendLengthPrefixedASCII(projection.identifier, to: &header)
    appendBigEndian(projection.version.major, to: &header)
    appendBigEndian(projection.version.minor, to: &header)
    appendBigEndian(payloadByteCount, to: &header)
    return header
}

func checkedFrameByteCount(headerByteCount: UInt64, payloadByteCount: UInt64) throws -> UInt64 {
    let (total, overflow) = headerByteCount.addingReportingOverflow(payloadByteCount)
    guard !overflow, total <= probeMaximumSHA256InputByteCount else {
        throw ProbeIdentityError.resourceLimitExceeded
    }
    return total
}

func framedSHA256(
    payload: [UInt8],
    algorithmIdentifier: String = ProbeDigestAlgorithm.sha256.rawValue,
    scopeIdentifier: String = ProbeContentScope.serialisedObject.rawValue,
    projection: ProbeProjectionReference,
    maximumPayloadByteCount: UInt64,
    declaredPayloadByteCount: UInt64? = nil,
    requestedChunkByteCount: Int = probeMaximumUpdateByteCount,
    cancelBeforeChunk: Int? = nil,
    cancelBeforePublication: Bool = false
) throws -> ContiguousArray<UInt8> {
    guard requestedChunkByteCount > 0 else {
        throw ProbeIdentityError.invalidRecord
    }
    guard let actualPayloadByteCount = UInt64(exactly: payload.count),
        actualPayloadByteCount <= maximumPayloadByteCount
    else {
        throw ProbeIdentityError.resourceLimitExceeded
    }
    let framedPayloadByteCount = declaredPayloadByteCount ?? actualPayloadByteCount
    guard framedPayloadByteCount <= maximumPayloadByteCount else {
        throw ProbeIdentityError.resourceLimitExceeded
    }

    let header = try makeFrameHeader(
        algorithmIdentifier: algorithmIdentifier,
        scopeIdentifier: scopeIdentifier,
        projection: projection,
        payloadByteCount: framedPayloadByteCount
    )
    _ = try checkedFrameByteCount(
        headerByteCount: UInt64(header.count),
        payloadByteCount: framedPayloadByteCount
    )

    var hasher = SHA256()
    hasher.update(data: Data(header))

    let boundedChunkByteCount = min(requestedChunkByteCount, probeMaximumUpdateByteCount)
    var offset = 0
    var chunkIndex = 0
    var observedPayloadByteCount: UInt64 = 0
    while offset < payload.count {
        if cancelBeforeChunk == chunkIndex {
            throw ProbeIdentityError.cancelled
        }
        let chunkByteCount = min(payload.count - offset, boundedChunkByteCount)
        let (end, offsetOverflow) = offset.addingReportingOverflow(chunkByteCount)
        guard !offsetOverflow, end <= payload.count else {
            throw ProbeIdentityError.resourceLimitExceeded
        }
        hasher.update(data: Data(payload[offset..<end]))
        let (nextObservedCount, countOverflow) = observedPayloadByteCount.addingReportingOverflow(
            UInt64(chunkByteCount)
        )
        guard !countOverflow else {
            throw ProbeIdentityError.resourceLimitExceeded
        }
        observedPayloadByteCount = nextObservedCount
        offset = end
        chunkIndex += 1
    }

    guard observedPayloadByteCount == framedPayloadByteCount else {
        throw ProbeIdentityError.invalidRecord
    }
    let digest = ContiguousArray(hasher.finalize())
    if cancelBeforePublication {
        throw ProbeIdentityError.cancelled
    }
    return digest
}

func makeCompleteRecordIdentity(
    document: String,
    projection: ProbeProjectionReference
) throws -> ProbeContentID {
    let payload = Array(document.utf8)
    let digest = try framedSHA256(
        payload: payload,
        projection: projection,
        maximumPayloadByteCount: UInt64(payload.count)
    )
    return try ProbeContentID(
        algorithm: .sha256,
        scope: .serialisedObject,
        projection: projection,
        digest: digest
    )
}

func uniqueOnlyCompleteRecordIdentity(
    document: String,
    projection: ProbeProjectionReference
) throws -> ProbeContentID {
    try makeCompleteRecordIdentity(document: document, projection: projection)
}

func configuredCompleteRecordIdentity(
    document: String,
    claimedReference: String,
    entryKeys: [String],
    context: ProbeMultiplicityContext,
    projection: ProbeProjectionReference
) throws -> ProbeContentID {
    guard claimedReference == context.expectedReference else {
        throw ProbeIdentityError.invalidRecord
    }

    var observed: Set<String> = []
    for key in entryKeys {
        if !observed.insert(key).inserted, !context.policy.admittedKeys.contains(key) {
            throw ProbeIdentityError.invalidRecord
        }
    }
    return try makeCompleteRecordIdentity(document: document, projection: projection)
}

func lowercaseHex(_ source: some Sequence<UInt8>) -> String {
    let bytes = Array(source)
    let alphabet = Array("0123456789abcdef".utf8)
    var encoded: [UInt8] = []
    encoded.reserveCapacity(bytes.count * 2)
    for byte in bytes {
        encoded.append(alphabet[Int(byte >> 4)])
        encoded.append(alphabet[Int(byte & 0x0F)])
    }
    return String(decoding: encoded, as: UTF8.self)
}

func decodeSHA256LowercaseHex(_ source: String) throws -> ContiguousArray<UInt8> {
    let bytes = Array(source.utf8)
    guard bytes.count == 64 else {
        throw ProbeIdentityError.invalidRecord
    }

    var decoded = ContiguousArray<UInt8>()
    decoded.reserveCapacity(32)
    for index in stride(from: 0, to: bytes.count, by: 2) {
        guard let high = lowercaseHexNibble(bytes[index]),
            let low = lowercaseHexNibble(bytes[index + 1])
        else {
            throw ProbeIdentityError.invalidRecord
        }
        decoded.append((high << 4) | low)
    }
    return decoded
}

func lowercaseHexNibble(_ byte: UInt8) -> UInt8? {
    switch byte {
    case 0x30...0x39:
        byte - 0x30
    case 0x61...0x66:
        byte - 0x61 + 10
    default:
        nil
    }
}

func timingSafeEqual(
    _ lhs: ContiguousArray<UInt8>,
    _ rhs: ContiguousArray<UInt8>
) -> Bool {
    guard lhs.count == rhs.count, !lhs.isEmpty else {
        return lhs.isEmpty && rhs.isEmpty
    }
    return lhs.withUnsafeBytes { lhsBytes in
        rhs.withUnsafeBytes { rhsBytes in
            timingsafe_bcmp(lhsBytes.baseAddress!, rhsBytes.baseAddress!, lhs.count) == 0
        }
    }
}

func canonicalEnvelope(
    multiplicitySchema: String = "null",
    entries: String
) -> String {
    "{\"documentSchema\":{\"identifier\":\"org.voxelia.metadata-document\","
        + "\"version\":{\"major\":1,\"minor\":0}},"
        + "\"multiplicitySchema\":\(multiplicitySchema),"
        + "\"payload\":{\"entries\":[\(entries)]}}"
}

func canonicalEntry(
    namespace: String,
    name: String,
    privacyClass: String,
    value: String
) -> String {
    "{\"key\":{\"name\":\"\(name)\",\"namespace\":\"\(namespace)\"},"
        + "\"privacyClass\":\"\(privacyClass)\",\"value\":\(value)}"
}

func canonicalCodeValue(meaning: String?) -> String {
    let meaningToken = meaning.map { "\"\($0)\"" } ?? "null"
    return "{\"code\":{\"meaning\":\(meaningToken),\"scheme\":\"example\","
        + "\"value\":\"length\",\"version\":null}}"
}

func canonicalUnitValue(displayName: String?) -> String {
    let displayNameToken = displayName.map { "\"\($0)\"" } ?? "null"
    return "{\"unit\":{\"code\":\"mm\",\"dimension\":\"length\","
        + "\"displayName\":\(displayNameToken),\"namespace\":\"ucum\","
        + "\"offsetToCanonical\":null,\"scaleToCanonical\":null}}"
}

func canonicalStringValue(_ value: String) -> String {
    "{\"string\":\"\(value)\"}"
}

func canonicalContentIDWire(_ identity: ProbeContentID) -> String {
    "{\"algorithm\":\"\(identity.algorithm.rawValue)\","
        + "\"digest\":\"\(lowercaseHex(identity.digest))\","
        + "\"projection\":{\"identifier\":\"\(identity.projection.identifier)\","
        + "\"version\":{\"major\":\(identity.projection.version.major),"
        + "\"minor\":\(identity.projection.version.minor)}},"
        + "\"scope\":\"\(identity.scope.rawValue)\"}"
}

let projection = try ProbeProjectionReference(
    identifier: "org.voxelia.metadata-complete-record",
    version: ProbeProjectionVersion(major: 1, minor: 0)
)
let nextProjectionVersion = try ProbeProjectionReference(
    identifier: "org.voxelia.metadata-complete-record",
    version: ProbeProjectionVersion(major: 1, minor: 1)
)

let maximumProjectionLabel = String(repeating: "a", count: 63)
let maximumProjectionIdentifier = Array(repeating: maximumProjectionLabel, count: 4).joined(
    separator: "."
)
precondition(maximumProjectionIdentifier.utf8.count == 255)
_ = try ProbeProjectionReference(
    identifier: "\(maximumProjectionLabel).b",
    version: ProbeProjectionVersion(major: 1, minor: 0)
)
_ = try ProbeProjectionReference(
    identifier: maximumProjectionIdentifier,
    version: ProbeProjectionVersion(major: 1, minor: 0)
)

do {
    _ = try ProbeProjectionReference(
        identifier: "\(String(repeating: "a", count: 64)).b",
        version: ProbeProjectionVersion(major: 1, minor: 0)
    )
    preconditionFailure("64-byte projection label was accepted")
} catch ProbeProjectionReferenceError.identifierByteLimitExceeded {
    // Expected.
}

do {
    _ = try ProbeProjectionReference(
        identifier: String(repeating: "a", count: 64),
        version: ProbeProjectionVersion(major: 1, minor: 0)
    )
    preconditionFailure("label count incorrectly outranked 64-byte label limit")
} catch ProbeProjectionReferenceError.identifierByteLimitExceeded {
    // Expected before the one-label grammar failure.
}

let overlongProjectionIdentifier = [
    String(repeating: "a", count: 63),
    String(repeating: "b", count: 63),
    String(repeating: "c", count: 63),
    String(repeating: "d", count: 61),
    "ee",
].joined(separator: ".")
precondition(overlongProjectionIdentifier.utf8.count == 256)
do {
    _ = try ProbeProjectionReference(
        identifier: overlongProjectionIdentifier,
        version: ProbeProjectionVersion(major: 1, minor: 0)
    )
    preconditionFailure("256-byte projection identifier was accepted")
} catch ProbeProjectionReferenceError.identifierByteLimitExceeded {
    // Expected before other grammar work.
}

let overlongAndInvalidProjectionIdentifier =
    "A" + overlongProjectionIdentifier.dropFirst()
do {
    _ = try ProbeProjectionReference(
        identifier: overlongAndInvalidProjectionIdentifier,
        version: ProbeProjectionVersion(major: 1, minor: 0)
    )
    preconditionFailure("grammar error incorrectly outranked total byte limit")
} catch ProbeProjectionReferenceError.identifierByteLimitExceeded {
    // Expected before the uppercase grammar failure.
}

do {
    _ = try ProbeProjectionReference(
        identifier: String(repeating: "a", count: 4_096),
        version: ProbeProjectionVersion(major: 1, minor: 0)
    )
    preconditionFailure("very overlong identifier was accepted")
} catch ProbeProjectionReferenceError.identifierByteLimitExceeded {
    // The initializer stops before copying a 256th UTF-8 byte.
}

do {
    _ = try ProbeProjectionReference(
        identifier: "Org.voxelia",
        version: ProbeProjectionVersion(major: 1, minor: 0)
    )
    preconditionFailure("invalid projection grammar was accepted")
} catch ProbeProjectionReferenceError.invalidIdentifier {
    // Expected.
}

let abcDigest = lowercaseHex(SHA256.hash(data: Data("abc".utf8)))
precondition(abcDigest == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")

let emptyDocument = canonicalEnvelope(entries: "")
precondition(emptyDocument.utf8.count == 148)
let rawEmptyDigest = lowercaseHex(SHA256.hash(data: Data(emptyDocument.utf8)))
precondition(rawEmptyDigest == "a27e896af6381de3cf78c5b4166851b601b6461d9e2503935b32ab4d6811ee50")

let emptyFramedDigest = try framedSHA256(
    payload: Array(emptyDocument.utf8),
    projection: projection,
    maximumPayloadByteCount: UInt64(emptyDocument.utf8.count)
)
let emptyFramedHex = lowercaseHex(emptyFramedDigest)
let emptyHeader = try makeFrameHeader(
    algorithmIdentifier: ProbeDigestAlgorithm.sha256.rawValue,
    scopeIdentifier: ProbeContentScope.serialisedObject.rawValue,
    projection: projection,
    payloadByteCount: UInt64(emptyDocument.utf8.count)
)
precondition(emptyHeader.count == 109)
precondition(
    lowercaseHex(emptyHeader)
        == "564f58454c49412d434f4e54454e542d4944000000000100000006736861323536"
        + "0000001073657269616c697365644f626a656374000000246f72672e766f78656c"
        + "69612e6d657461646174612d636f6d706c6574652d7265636f7264000000010000"
        + "00000000000000000094"
)
precondition(emptyFramedHex == "8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432")
precondition(emptyFramedHex != rawEmptyDigest)

let emptyIdentity = try uniqueOnlyCompleteRecordIdentity(
    document: emptyDocument,
    projection: projection
)

do {
    _ = try ProbeContentID(
        algorithm: .sha512,
        scope: .serialisedObject,
        projection: projection,
        digest: emptyIdentity.digest
    )
    preconditionFailure("unsupported algorithm was accepted")
} catch ProbeIdentityError.unsupportedAlgorithm {
    // Expected.
}

do {
    _ = try ProbeContentID(
        algorithm: .sha256,
        scope: .serialisedObject,
        projection: nextProjectionVersion,
        digest: emptyIdentity.digest
    )
    preconditionFailure("unsupported projection was accepted")
} catch ProbeIdentityError.unsupportedProjection {
    // Expected.
}

do {
    _ = try ProbeContentID(
        algorithm: .sha256,
        scope: .serialisedObject,
        projection: projection,
        digest: emptyIdentity.digest.dropLast()
    )
    preconditionFailure("short digest was accepted")
} catch ProbeIdentityError.invalidRecord {
    // Expected.
}

let codeEntryA = canonicalEntry(
    namespace: "org.example.unknown",
    name: "code",
    privacyClass: "technical",
    value: canonicalCodeValue(meaning: "Length")
)
let codeEntryB = canonicalEntry(
    namespace: "org.example.unknown",
    name: "code",
    privacyClass: "technical",
    value: canonicalCodeValue(meaning: "Distance")
)
let codeA = ProbeCodedConcept(
    scheme: "example",
    value: "length",
    version: nil,
    meaning: "Length"
)
let codeB = ProbeCodedConcept(
    scheme: "example",
    value: "length",
    version: nil,
    meaning: "Distance"
)
precondition(codeA == codeB)

let codeDocumentA = canonicalEnvelope(entries: codeEntryA)
let codeDocumentB = canonicalEnvelope(entries: codeEntryB)
let codeDigestA = try uniqueOnlyCompleteRecordIdentity(
    document: codeDocumentA,
    projection: projection
)
let codeDigestB = try uniqueOnlyCompleteRecordIdentity(
    document: codeDocumentB,
    projection: projection
)
precondition(codeDigestA != codeDigestB)

let unitA = ProbeMeasurementUnit(
    namespace: "ucum",
    code: "mm",
    dimension: "length",
    scaleToCanonical: nil,
    offsetToCanonical: nil,
    displayName: "millimetre"
)
let unitB = ProbeMeasurementUnit(
    namespace: "ucum",
    code: "mm",
    dimension: "length",
    scaleToCanonical: nil,
    offsetToCanonical: nil,
    displayName: "millimeter"
)
precondition(unitA == unitB)
let unitDocumentA = canonicalEnvelope(
    entries: canonicalEntry(
        namespace: "org.example",
        name: "unit",
        privacyClass: "technical",
        value: canonicalUnitValue(displayName: unitA.displayName)
    )
)
let unitDocumentB = canonicalEnvelope(
    entries: canonicalEntry(
        namespace: "org.example",
        name: "unit",
        privacyClass: "technical",
        value: canonicalUnitValue(displayName: unitB.displayName)
    )
)
let unitDigestA = try uniqueOnlyCompleteRecordIdentity(
    document: unitDocumentA,
    projection: projection
)
let unitDigestB = try uniqueOnlyCompleteRecordIdentity(
    document: unitDocumentB,
    projection: projection
)
precondition(unitDigestA != unitDigestB)

let firstEntry = canonicalEntry(
    namespace: "org.example",
    name: "first",
    privacyClass: "technical",
    value: canonicalStringValue("one")
)
let secondEntry = canonicalEntry(
    namespace: "org.example",
    name: "second",
    privacyClass: "technical",
    value: canonicalStringValue("two")
)
let orderedDocument = canonicalEnvelope(entries: "\(firstEntry),\(secondEntry)")
let reversedDocument = canonicalEnvelope(entries: "\(secondEntry),\(firstEntry)")
let orderedDigest = try uniqueOnlyCompleteRecordIdentity(
    document: orderedDocument,
    projection: projection
)
let reversedDigest = try uniqueOnlyCompleteRecordIdentity(
    document: reversedDocument,
    projection: projection
)
precondition(orderedDigest != reversedDigest)

let privateEntry = canonicalEntry(
    namespace: "org.example",
    name: "first",
    privacyClass: "potentiallyIdentifying",
    value: canonicalStringValue("one")
)
let privateDocument = canonicalEnvelope(entries: privateEntry)
let privateDigest = try uniqueOnlyCompleteRecordIdentity(
    document: privateDocument,
    projection: projection
)
let technicalDigest = try uniqueOnlyCompleteRecordIdentity(
    document: canonicalEnvelope(entries: firstEntry),
    projection: projection
)
precondition(privateDigest != technicalDigest)

let multiplicityReference =
    "{\"identifier\":\"org.example.metadata-profile\","
    + "\"version\":{\"major\":1,\"minor\":0}}"
let claimedMultiplicityReference = "org.example.metadata-profile@1.0"
let profiledDocument = canonicalEnvelope(
    multiplicitySchema: multiplicityReference,
    entries: firstEntry
)
let strictProfileContext = ProbeMultiplicityContext(
    expectedReference: claimedMultiplicityReference,
    policy: ProbeMultiplicityPolicy(admittedKeys: [])
)
let widerProfileContext = ProbeMultiplicityContext(
    expectedReference: claimedMultiplicityReference,
    policy: ProbeMultiplicityPolicy(admittedKeys: ["org.example.repeated"])
)
let profiledDigest = try configuredCompleteRecordIdentity(
    document: profiledDocument,
    claimedReference: claimedMultiplicityReference,
    entryKeys: ["org.example.first"],
    context: strictProfileContext,
    projection: projection
)
let widerPolicyProfiledDigest = try configuredCompleteRecordIdentity(
    document: profiledDocument,
    claimedReference: claimedMultiplicityReference,
    entryKeys: ["org.example.first"],
    context: widerProfileContext,
    projection: projection
)
precondition(profiledDigest == widerPolicyProfiledDigest)
precondition(profiledDigest != technicalDigest)

let unknownEntry = canonicalEntry(
    namespace: "org.vendor.private",
    name: "opaque-but-recognised",
    privacyClass: "hostDefined",
    value: canonicalStringValue("retained")
)
let unknownDigest = try uniqueOnlyCompleteRecordIdentity(
    document: canonicalEnvelope(entries: "\(firstEntry),\(unknownEntry)"),
    projection: projection
)
precondition(unknownDigest != technicalDigest)

let composedEntry = canonicalEntry(
    namespace: "org.example",
    name: "unicode",
    privacyClass: "technical",
    value: canonicalStringValue("\u{00E9}")
)
let decomposedEntry = canonicalEntry(
    namespace: "org.example",
    name: "unicode",
    privacyClass: "technical",
    value: canonicalStringValue("e\u{0301}")
)
let composedDigest = try uniqueOnlyCompleteRecordIdentity(
    document: canonicalEnvelope(entries: composedEntry),
    projection: projection
)
let decomposedDigest = try uniqueOnlyCompleteRecordIdentity(
    document: canonicalEnvelope(entries: decomposedEntry),
    projection: projection
)
precondition(composedDigest != decomposedDigest)

let oneByteChunks = try framedSHA256(
    payload: Array(orderedDocument.utf8),
    projection: projection,
    maximumPayloadByteCount: UInt64(orderedDocument.utf8.count),
    requestedChunkByteCount: 1
)
let oversizedRequestedChunks = try framedSHA256(
    payload: Array(orderedDocument.utf8),
    projection: projection,
    maximumPayloadByteCount: UInt64(orderedDocument.utf8.count),
    requestedChunkByteCount: Int.max
)
precondition(timingSafeEqual(oneByteChunks, oversizedRequestedChunks))

let nextVersionDigest = try framedSHA256(
    payload: Array(emptyDocument.utf8),
    projection: nextProjectionVersion,
    maximumPayloadByteCount: UInt64(emptyDocument.utf8.count)
)
let changedScopeDigest = try framedSHA256(
    payload: Array(emptyDocument.utf8),
    scopeIdentifier: "storageObject",
    projection: projection,
    maximumPayloadByteCount: UInt64(emptyDocument.utf8.count)
)
let changedAlgorithmDomainDigest = try framedSHA256(
    payload: Array(emptyDocument.utf8),
    algorithmIdentifier: "sha512",
    projection: projection,
    maximumPayloadByteCount: UInt64(emptyDocument.utf8.count)
)
// This is a domain-label mutation only; it deliberately does not implement
// SHA-512 or create a supported ContentID.
precondition(!timingSafeEqual(emptyFramedDigest, nextVersionDigest))
precondition(!timingSafeEqual(emptyFramedDigest, changedScopeDigest))
precondition(!timingSafeEqual(emptyFramedDigest, changedAlgorithmDomainDigest))

let encodedHex = lowercaseHex(emptyIdentity.digest)
precondition(encodedHex.count == 64)
let decodedHex = try decodeSHA256LowercaseHex(encodedHex)
precondition(decodedHex == emptyIdentity.digest)
for invalidHex in [
    String(encodedHex.dropLast()),
    encodedHex + "0",
    encodedHex.uppercased(),
    "0x" + encodedHex,
    encodedHex.replacingOccurrences(of: "a", with: "g"),
    encodedHex + " ",
] {
    do {
        _ = try decodeSHA256LowercaseHex(invalidHex)
        preconditionFailure("invalid hexadecimal alias was accepted")
    } catch ProbeIdentityError.invalidRecord {
        // Expected.
    }
}

var callerOwnedDigest = Array(emptyIdentity.digest)
let snapshottedIdentity = try ProbeContentID(
    algorithm: .sha256,
    scope: .serialisedObject,
    projection: projection,
    digest: callerOwnedDigest
)
callerOwnedDigest[0] ^= 0xFF
precondition(snapshottedIdentity == emptyIdentity)

var firstMismatch = emptyIdentity.digest
var middleMismatch = emptyIdentity.digest
var lastMismatch = emptyIdentity.digest
firstMismatch[0] ^= 1
middleMismatch[16] ^= 1
lastMismatch[31] ^= 1
precondition(!timingSafeEqual(emptyIdentity.digest, firstMismatch))
precondition(!timingSafeEqual(emptyIdentity.digest, middleMismatch))
precondition(!timingSafeEqual(emptyIdentity.digest, lastMismatch))

do {
    _ = try framedSHA256(
        payload: Array(emptyDocument.utf8),
        projection: projection,
        maximumPayloadByteCount: UInt64(emptyDocument.utf8.count - 1)
    )
    preconditionFailure("one-over payload was accepted")
} catch ProbeIdentityError.resourceLimitExceeded {
    // Expected.
}

let orderedPayload = Array(orderedDocument.utf8)
let orderedPayloadByteCount = UInt64(orderedPayload.count)
for incorrectDeclaredCount in [orderedPayloadByteCount - 1, orderedPayloadByteCount + 1] {
    do {
        _ = try framedSHA256(
            payload: orderedPayload,
            projection: projection,
            maximumPayloadByteCount: orderedPayloadByteCount + 1,
            declaredPayloadByteCount: incorrectDeclaredCount
        )
        preconditionFailure("declared/observed payload mismatch published a digest")
    } catch ProbeIdentityError.invalidRecord {
        // Expected before finalisation and publication.
    }
}

do {
    _ = try checkedFrameByteCount(headerByteCount: UInt64.max, payloadByteCount: 1)
    preconditionFailure("overflowing frame count was accepted")
} catch ProbeIdentityError.resourceLimitExceeded {
    // Expected.
}

for cancellation in [(chunk: Int?.some(0), final: false), (chunk: nil, final: true)] {
    do {
        _ = try framedSHA256(
            payload: Array(orderedDocument.utf8),
            projection: projection,
            maximumPayloadByteCount: UInt64(orderedDocument.utf8.count),
            requestedChunkByteCount: 1,
            cancelBeforeChunk: cancellation.chunk,
            cancelBeforePublication: cancellation.final
        )
        preconditionFailure("cancelled computation published a digest")
    } catch ProbeIdentityError.cancelled {
        // Expected.
    }
}

struct ProbeDataWire: Encodable {
    let digest: Data
}
struct ProbeArrayWire: Encodable {
    let digest: ContiguousArray<UInt8>
}
let foundationDataWire = String(
    decoding: try JSONEncoder().encode(ProbeDataWire(digest: Data([0, 1, 254, 255]))),
    as: UTF8.self
)
let contiguousArrayWire = String(
    decoding: try JSONEncoder().encode(ProbeArrayWire(digest: [0, 1, 254, 255])),
    as: UTF8.self
)
precondition(foundationDataWire == "{\"digest\":\"AAH+\\/w==\"}")
precondition(contiguousArrayWire == "{\"digest\":[0,1,254,255]}")

let contentIDWire = canonicalContentIDWire(emptyIdentity)
precondition(
    contentIDWire
        == "{\"algorithm\":\"sha256\",\"digest\":\"\(encodedHex)\","
        + "\"projection\":{\"identifier\":\"org.voxelia.metadata-complete-record\","
        + "\"version\":{\"major\":1,\"minor\":0}},"
        + "\"scope\":\"serialisedObject\"}"
)

for error in [
    ProbeIdentityError.invalidRecord,
    .unsupportedAlgorithm,
    .unsupportedProjection,
    .resourceLimitExceeded,
    .cancelled,
] {
    let descriptions = [String(describing: error), String(reflecting: error)]
    precondition(descriptions.allSatisfy { !$0.contains(encodedHex) })
    precondition(descriptions.allSatisfy { !$0.contains("org.example") })
}
for error in [
    ProbeProjectionReferenceError.invalidIdentifier,
    .identifierByteLimitExceeded,
] {
    let descriptions = [String(describing: error), String(reflecting: error)]
    precondition(descriptions.allSatisfy { !$0.contains("Org.voxelia") })
    precondition(descriptions.allSatisfy { !$0.contains(maximumProjectionLabel) })
}

print(
    "sha256=knownAnswer",
    "recordProjection=completeVCMJ1",
    "emptyFramedDigest=\(emptyFramedHex)",
    "rawDigestIsDifferent=true",
    "semanticEqualityIsNotRecordIdentity=true",
    "order+privacy+profile+unknown+presentation=bound",
    "policy=outOfBand",
    "framing=algorithm+scope+projection+length",
    "projectionIdentifier=63/64+255/256",
    "declaredLength=mismatchRejected",
    "streaming=chunkInvariant4096",
    "hex=lowercase64",
    "digestBytes=owned",
    "comparison=timingsafe_bcmp",
    "cancellation=noPublication",
    "diagnostics=payloadFree"
)
