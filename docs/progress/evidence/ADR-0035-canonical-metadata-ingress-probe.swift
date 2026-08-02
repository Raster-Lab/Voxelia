// SPDX-License-Identifier: MIT
//
// Isolated Swift 6 evidence for a candidate ADR-0035 canonical metadata JSON
// boundary. These Probe* declarations are not Voxelia public API, a production
// parser, or implementation authorisation. They exercise raw-parser negative
// controls, exact UTF-8 identity, canonical token subprofiles, bounded schema
// binding, and payload-free failures only.

import Foundation

enum ProbeMetadataJSONIngressError: Error, Sendable, Equatable {
    case invalidDocument
    case unsupportedSchemaVersion
    case resourceLimitExceeded
    case cancelled
}

enum ProbeMetadataJSONEmissionError: Error, Sendable, Equatable {
    case invalidValue
    case resourceLimitExceeded
    case cancelled
}

struct ProbeExactUTF8: Sendable, Hashable {
    let bytes: ContiguousArray<UInt8>

    init(_ string: String) {
        bytes = ContiguousArray(string.utf8)
    }

    init(bytes: [UInt8]) {
        self.bytes = ContiguousArray(bytes)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes.elementsEqual(rhs.bytes)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bytes.count)
        for byte in bytes {
            hasher.combine(byte)
        }
    }
}

struct ProbeKey: Sendable, Hashable {
    let namespace: ProbeExactUTF8
    let name: ProbeExactUTF8
}

enum ProbeSchemaReferenceError: Error, Sendable, Equatable {
    case invalidIdentifier
    case identifierByteLimitExceeded
}

struct ProbeSchemaReference: Sendable, Hashable {
    static let maximumIdentifierUTF8ByteCount: UInt64 = 255
    static let maximumIdentifierLabelByteCount: UInt64 = 63

    let identifier: ProbeExactUTF8
    let major: UInt32
    let minor: UInt32

    init(identifier: String, major: UInt32, minor: UInt32) throws {
        let byteCount = UInt64(identifier.utf8.count)
        guard byteCount <= Self.maximumIdentifierUTF8ByteCount else {
            throw ProbeSchemaReferenceError.identifierByteLimitExceeded
        }
        let bytes = Array(identifier.utf8)

        let labels = bytes.split(separator: 0x2E, omittingEmptySubsequences: false)
        guard labels.count >= 2 else {
            throw ProbeSchemaReferenceError.invalidIdentifier
        }
        for label in labels {
            guard UInt64(label.count) <= Self.maximumIdentifierLabelByteCount else {
                throw ProbeSchemaReferenceError.identifierByteLimitExceeded
            }
            guard
                !label.isEmpty,
                label.first.map(isSchemaIdentifierAlphaNumeric) == true,
                label.last.map(isSchemaIdentifierAlphaNumeric) == true,
                label.allSatisfy({ isSchemaIdentifierAlphaNumeric($0) || $0 == 0x2D })
            else {
                throw ProbeSchemaReferenceError.invalidIdentifier
            }
        }

        self.identifier = ProbeExactUTF8(bytes: bytes)
        self.major = major
        self.minor = minor
    }
}

func isSchemaIdentifierAlphaNumeric(_ byte: UInt8) -> Bool {
    (0x61...0x7A).contains(byte) || (0x30...0x39).contains(byte)
}

func isFrozenMetadataWhitespace(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x0009...0x000D, 0x0020, 0x0085, 0x00A0, 0x1680, 0x2000...0x200A,
        0x2028, 0x2029, 0x202F, 0x205F, 0x3000:
        true
    default:
        false
    }
}

func isFrozenMetadataBlank(_ value: String) -> Bool {
    value.unicodeScalars.allSatisfy(isFrozenMetadataWhitespace)
}

struct ProbeIngressContext: Sendable {
    let expectedMultiplicitySchema: ProbeSchemaReference
    let repeatableKeys: Set<ProbeKey>
}

struct ProbeIngressLimits: Sendable, Hashable {
    let maximumDocumentByteCount: UInt64
    let maximumRawTokenByteCount: UInt64
    let maximumDecodedStringByteCount: UInt64
    let maximumDecodedBinaryByteCount: UInt64
    let maximumEntryCount: UInt64
    let maximumStructuralElementCount: UInt64
    let maximumLogicalPayloadByteCount: UInt64
    let maximumSemanticValueDepth: UInt64
    let maximumRawJSONDepth: UInt64
}

struct ProbeBudget: Sendable {
    let limits: ProbeIngressLimits
    private(set) var documentBytes: UInt64 = 0
    private(set) var structuralElements: UInt64 = 0
    private(set) var logicalPayloadBytes: UInt64 = 0

    mutating func chargeDocumentBytes(_ count: UInt64) throws {
        let candidate = try checkedAdd(documentBytes, count)
        guard candidate <= limits.maximumDocumentByteCount else {
            throw ProbeMetadataJSONIngressError.resourceLimitExceeded
        }
        documentBytes = candidate
    }

    mutating func chargeStructuralElement() throws {
        let candidate = try checkedAdd(structuralElements, 1)
        guard candidate <= limits.maximumStructuralElementCount else {
            throw ProbeMetadataJSONIngressError.resourceLimitExceeded
        }
        structuralElements = candidate
    }

    mutating func chargeLogicalPayload(_ count: UInt64) throws {
        let candidate = try checkedAdd(logicalPayloadBytes, count)
        guard candidate <= limits.maximumLogicalPayloadByteCount else {
            throw ProbeMetadataJSONIngressError.resourceLimitExceeded
        }
        logicalPayloadBytes = candidate
    }

    private func checkedAdd(_ lhs: UInt64, _ rhs: UInt64) throws -> UInt64 {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        guard !overflow else {
            throw ProbeMetadataJSONIngressError.resourceLimitExceeded
        }
        return sum
    }
}

func parseCanonicalSignedInteger(_ text: String) throws -> Int64 {
    let bytes = Array(text.utf8)
    guard !bytes.isEmpty, bytes.count <= 20 else {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }

    let negative = bytes[0] == 0x2D
    let digits = negative ? bytes.dropFirst() : bytes[...]
    guard !digits.isEmpty else {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }
    if digits.count > 1, digits.first == 0x30 {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }
    if negative, digits.count == 1, digits.first == 0x30 {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }

    let limit = negative ? UInt64(Int64.max) + 1 : UInt64(Int64.max)
    var magnitude: UInt64 = 0
    for byte in digits {
        guard (0x30...0x39).contains(byte) else {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
        let digit = UInt64(byte - 0x30)
        let (scaled, multiplyOverflow) = magnitude.multipliedReportingOverflow(by: 10)
        let (next, addOverflow) = scaled.addingReportingOverflow(digit)
        guard !multiplyOverflow, !addOverflow, next <= limit else {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
        magnitude = next
    }

    if negative {
        return magnitude == UInt64(Int64.max) + 1 ? Int64.min : -Int64(magnitude)
    }
    return Int64(magnitude)
}

func parseCanonicalUnsignedInteger(_ text: String) throws -> UInt64 {
    let bytes = Array(text.utf8)
    guard !bytes.isEmpty, bytes.count <= 20 else {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }
    if bytes.count > 1, bytes[0] == 0x30 {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }

    var value: UInt64 = 0
    for byte in bytes {
        guard (0x30...0x39).contains(byte) else {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
        let digit = UInt64(byte - 0x30)
        let (scaled, multiplyOverflow) = value.multipliedReportingOverflow(by: 10)
        let (next, addOverflow) = scaled.addingReportingOverflow(digit)
        guard !multiplyOverflow, !addOverflow else {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
        value = next
    }
    return value
}

func decodeCanonicalJSONStringToken(_ token: [UInt8]) throws -> ProbeExactUTF8 {
    guard token.count >= 2, token.first == 0x22, token.last == 0x22 else {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }

    var decoded: [UInt8] = []
    decoded.reserveCapacity(token.count - 2)
    var index = 1
    while index < token.count - 1 {
        let byte = token[index]
        if byte == 0x22 || byte < 0x20 {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
        if byte != 0x5C {
            decoded.append(byte)
            index += 1
            continue
        }

        index += 1
        guard index < token.count - 1 else {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
        switch token[index] {
        case 0x22:
            decoded.append(0x22)
        case 0x5C:
            decoded.append(0x5C)
        case 0x62:
            decoded.append(0x08)
        case 0x66:
            decoded.append(0x0C)
        case 0x6E:
            decoded.append(0x0A)
        case 0x72:
            decoded.append(0x0D)
        case 0x74:
            decoded.append(0x09)
        case 0x75:
            guard index + 4 < token.count - 1 else {
                throw ProbeMetadataJSONIngressError.invalidDocument
            }
            let digits = token[(index + 1)...(index + 4)]
            guard digits.allSatisfy({ (0x30...0x39).contains($0) || (0x61...0x66).contains($0) })
            else {
                throw ProbeMetadataJSONIngressError.invalidDocument
            }
            var scalar: UInt8 = 0
            for digit in digits {
                let nibble: UInt8 = digit <= 0x39 ? digit - 0x30 : digit - 0x61 + 10
                let (scaled, overflow) = scalar.multipliedReportingOverflow(by: 16)
                guard !overflow else {
                    throw ProbeMetadataJSONIngressError.invalidDocument
                }
                scalar = scaled + nibble
            }
            let shortEscapes: Set<UInt8> = [0x08, 0x09, 0x0A, 0x0C, 0x0D]
            guard scalar < 0x20, !shortEscapes.contains(scalar) else {
                throw ProbeMetadataJSONIngressError.invalidDocument
            }
            decoded.append(scalar)
            index += 4
        default:
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
        index += 1
    }

    guard String(bytes: decoded, encoding: .utf8) != nil else {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }
    return ProbeExactUTF8(bytes: decoded)
}

func decodeGeneralJSONStringForDuplicateProbe(_ source: String) throws -> ProbeExactUTF8 {
    let decoded = try JSONDecoder().decode(String.self, from: Data(source.utf8))
    return ProbeExactUTF8(decoded)
}

func base64Value(_ byte: UInt8) -> UInt8? {
    switch byte {
    case 0x41...0x5A:
        byte - 0x41
    case 0x61...0x7A:
        byte - 0x61 + 26
    case 0x30...0x39:
        byte - 0x30 + 52
    case 0x2B:
        62
    case 0x2F:
        63
    default:
        nil
    }
}

func canonicalBase64DecodedCount(
    _ text: String,
    maximumDecodedByteCount: UInt64
) throws -> UInt64 {
    let bytes = Array(text.utf8)
    if bytes.isEmpty { return 0 }
    guard bytes.count.isMultiple(of: 4) else {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }

    let padding: Int
    if bytes.suffix(2).elementsEqual([0x3D, 0x3D]) {
        padding = 2
    } else if bytes.last == 0x3D {
        padding = 1
    } else {
        padding = 0
    }
    let dataCount = bytes.count - padding
    guard bytes[..<dataCount].allSatisfy({ base64Value($0) != nil }) else {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }
    guard bytes[dataCount...].allSatisfy({ $0 == 0x3D }) else {
        throw ProbeMetadataJSONIngressError.invalidDocument
    }

    if padding == 2 {
        guard dataCount >= 2, let value = base64Value(bytes[dataCount - 1]), value & 0x0F == 0
        else {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
    } else if padding == 1 {
        guard dataCount >= 3, let value = base64Value(bytes[dataCount - 1]), value & 0x03 == 0
        else {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
    }

    let quartets = UInt64(bytes.count / 4)
    let (expanded, overflow) = quartets.multipliedReportingOverflow(by: 3)
    guard !overflow, expanded >= UInt64(padding) else {
        throw ProbeMetadataJSONIngressError.resourceLimitExceeded
    }
    let decodedCount = expanded - UInt64(padding)
    guard decodedCount <= maximumDecodedByteCount else {
        throw ProbeMetadataJSONIngressError.resourceLimitExceeded
    }
    return decodedCount
}

func observedRawContainerDepth(_ document: String) -> UInt64? {
    var stack: [UInt8] = []
    var maximumObserved: UInt64 = 0
    var insideString = false
    var escaped = false

    for byte in document.utf8 {
        if insideString {
            if escaped {
                escaped = false
            } else if byte == 0x5C {
                escaped = true
            } else if byte == 0x22 {
                insideString = false
            }
            continue
        }

        switch byte {
        case 0x22:
            insideString = true
        case 0x7B, 0x5B:
            let nextDepth = UInt64(stack.count) + 1
            stack.append(byte)
            maximumObserved = max(maximumObserved, nextDepth)
        case 0x7D:
            guard stack.popLast() == 0x7B else {
                return nil
            }
        case 0x5D:
            guard stack.popLast() == 0x5B else {
                return nil
            }
        default:
            break
        }
    }

    guard !insideString, !escaped, stack.isEmpty else {
        return nil
    }
    return maximumObserved
}

func nestedObjectValue(levels: Int) -> String {
    var value =
        "{\"unit\":{\"code\":\"mm\",\"dimension\":\"length\","
        + "\"displayName\":null,\"namespace\":\"ucum\","
        + "\"offsetToCanonical\":null,\"scaleToCanonical\":null}}"
    for level in 0..<levels {
        value =
            "{\"object\":[{\"key\":{\"name\":\"k\(level)\","
            + "\"namespace\":\"org.example\"},\"value\":\(value)}]}"
    }
    return value
}

func canonicalEnvelope(containing value: String) -> String {
    "{\"documentSchema\":{\"identifier\":\"org.voxelia.metadata-document\","
        + "\"version\":{\"major\":1,\"minor\":0}},"
        + "\"multiplicitySchema\":null,\"payload\":{\"entries\":[{"
        + "\"key\":{\"name\":\"field\",\"namespace\":\"org.example\"},"
        + "\"privacyClass\":\"technical\",\"value\":\(value)}]}}"
}

func validateSchemaAndMultiplicity(
    multiplicitySchema: ProbeSchemaReference?,
    keys: [ProbeKey],
    context: ProbeIngressContext?
) throws {
    switch (multiplicitySchema, context) {
    case (nil, nil):
        break
    case (.some(let multiplicitySchema), .some(let context))
    where multiplicitySchema == context.expectedMultiplicitySchema:
        break
    default:
        throw ProbeMetadataJSONIngressError.invalidDocument
    }

    var seen = Set<ProbeKey>()
    for key in keys {
        let inserted = seen.insert(key).inserted
        if !inserted, context?.repeatableKeys.contains(key) != true {
            throw ProbeMetadataJSONIngressError.invalidDocument
        }
    }
}

func preflightCanonicalEmission(
    multiplicitySchema: ProbeSchemaReference?,
    keys: [ProbeKey],
    context: ProbeIngressContext?,
    didBeginEmission: inout Bool
) throws {
    precondition(!didBeginEmission)
    do {
        try validateSchemaAndMultiplicity(
            multiplicitySchema: multiplicitySchema,
            keys: keys,
            context: context
        )
    } catch {
        throw ProbeMetadataJSONEmissionError.invalidValue
    }
    didBeginEmission = true
}

func expectIngressError(
    _ expected: ProbeMetadataJSONIngressError,
    forbiddenText: [String],
    operation: () throws -> Void
) {
    do {
        try operation()
        preconditionFailure("Accepted invalid canonical metadata input")
    } catch let error as ProbeMetadataJSONIngressError {
        precondition(error == expected)
        let rendered = [String(describing: error), String(reflecting: error)]
        for sentinel in forbiddenText {
            precondition(rendered.allSatisfy { !$0.contains(sentinel) })
        }
    } catch {
        preconditionFailure("Returned an unexpected ingress error")
    }
}

func expectSchemaReferenceError(
    _ expected: ProbeSchemaReferenceError,
    forbiddenText: [String],
    operation: () throws -> Void
) {
    do {
        try operation()
        preconditionFailure("Accepted an invalid schema identifier")
    } catch let error as ProbeSchemaReferenceError {
        precondition(error == expected)
        let rendered = [String(describing: error), String(reflecting: error)]
        for sentinel in forbiddenText {
            precondition(rendered.allSatisfy { !$0.contains(sentinel) })
        }
    } catch {
        preconditionFailure("Returned an unexpected schema-reference error")
    }
}

func expectEmissionError(
    _ expected: ProbeMetadataJSONEmissionError,
    forbiddenText: [String],
    operation: () throws -> Void
) {
    do {
        try operation()
        preconditionFailure("Accepted invalid emission context")
    } catch let error as ProbeMetadataJSONEmissionError {
        precondition(error == expected)
        let rendered = [String(describing: error), String(reflecting: error)]
        for sentinel in forbiddenText {
            precondition(rendered.allSatisfy { !$0.contains(sentinel) })
        }
    } catch {
        preconditionFailure("Returned an unexpected emission error")
    }
}

func requireSendable<Value: Sendable>(_: Value.Type) {}
requireSendable(ProbeMetadataJSONIngressError.self)
requireSendable(ProbeMetadataJSONEmissionError.self)
requireSendable(ProbeSchemaReferenceError.self)
requireSendable(ProbeIngressLimits.self)
requireSendable(ProbeIngressContext.self)
requireSendable(ProbeBudget.self)

// Foundation is a negative control, not the candidate security boundary.
struct ProbeOneInteger: Decodable {
    let value: UInt64
}

for source in [
    #"{"value":1,"value":2}"#,
    #"{"value":1,"\u0076alue":2}"#,
] {
    let data = Data(source.utf8)
    let decoded = try JSONDecoder().decode(ProbeOneInteger.self, from: data)
    precondition(decoded.value == 1 || decoded.value == 2)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    precondition(object?.count == 1)
}

for source in ["1", "1.0", "1e0", "-0"] {
    let decoded = try JSONDecoder().decode(UInt64.self, from: Data(source.utf8))
    precondition(decoded == (source == "-0" ? 0 : 1))
}
let bomInteger = Data([0xEF, 0xBB, 0xBF, 0x31])
let decodedBOMInteger = try JSONDecoder().decode(UInt64.self, from: bomInteger)
precondition(decodedBOMInteger == 1)

let foundationEncoder = JSONEncoder()
let encodedNegativeZero = String(
    decoding: try foundationEncoder.encode(-0.0),
    as: UTF8.self
)
let encodedSmallExponent = String(
    decoding: try foundationEncoder.encode(1e-7),
    as: UTF8.self
)
precondition(encodedNegativeZero == "-0")
precondition(encodedSmallExponent == "1e-07")
foundationEncoder.outputFormatting = [.sortedKeys]
let nonBMPOrder = String(
    decoding: try foundationEncoder.encode(["\u{E000}": 1, "\u{1F600}": 2]),
    as: UTF8.self
)
precondition(nonBMPOrder.firstIndex(of: "\u{E000}")! < nonBMPOrder.firstIndex(of: "\u{1F600}")!)

let composed = "\u{00E9}"
let decomposed = "e\u{0301}"
precondition(composed == decomposed)
precondition(Set([composed, decomposed]).count == 1)
precondition(Set([ProbeExactUTF8(composed), ProbeExactUTF8(decomposed)]).count == 2)

let frozenWhitespaceValues: [UInt32] =
    Array(0x0009...0x000D) + [
        0x0020, 0x0085, 0x00A0, 0x1680,
    ] + Array(0x2000...0x200A) + [
        0x2028, 0x2029, 0x202F, 0x205F, 0x3000,
    ]
for value in frozenWhitespaceValues {
    precondition(isFrozenMetadataWhitespace(Unicode.Scalar(value)!))
}
for value: UInt32 in [0x0008, 0x000E, 0x180E, 0x200B, 0x2060, 0x3001] {
    precondition(!isFrozenMetadataWhitespace(Unicode.Scalar(value)!))
}
precondition(isFrozenMetadataBlank(" \u{2003}"))
precondition(!isFrozenMetadataBlank(" \u{0301}"))
precondition(!isFrozenMetadataBlank("\u{2003}\u{FE0F}"))

let ordinaryName = try decodeGeneralJSONStringForDuplicateProbe(#""value""#)
let escapedName = try decodeGeneralJSONStringForDuplicateProbe(#""\u0076alue""#)
precondition(ordinaryName == escapedName)
precondition(Set([ordinaryName, escapedName]).count == 1)
let composedName = try decodeGeneralJSONStringForDuplicateProbe(#""é""#)
let decomposedName = try decodeGeneralJSONStringForDuplicateProbe("\"e\u{0301}\"")
precondition(composedName != decomposedName)

let minimumSignedInteger = try parseCanonicalSignedInteger("-9223372036854775808")
let maximumSignedInteger = try parseCanonicalSignedInteger("9223372036854775807")
let maximumUnsignedInteger = try parseCanonicalUnsignedInteger("18446744073709551615")
precondition(minimumSignedInteger == Int64.min)
precondition(maximumSignedInteger == Int64.max)
precondition(maximumUnsignedInteger == UInt64.max)
for invalid in [
    "", "-", "-0", "+1", "01", "1.0", "1e0", "9223372036854775808",
    "-9223372036854775809", "100000000000000000000",
] {
    expectIngressError(.invalidDocument, forbiddenText: [invalid]) {
        _ = try parseCanonicalSignedInteger(invalid)
    }
}
for invalid in [
    "", "-1", "+1", "01", "1.0", "1e0", "18446744073709551616",
    "100000000000000000000",
] {
    expectIngressError(.invalidDocument, forbiddenText: [invalid]) {
        _ = try parseCanonicalUnsignedInteger(invalid)
    }
}

let canonicalComposed = try decodeCanonicalJSONStringToken(Array("\"\u{00E9}\"".utf8))
let canonicalDecomposed = try decodeCanonicalJSONStringToken(Array("\"e\u{0301}\"".utf8))
let canonicalEscapes = try decodeCanonicalJSONStringToken(Array(#""\u000f\n\"\\/""#.utf8))
let canonicalNoncharacter = try decodeCanonicalJSONStringToken([0x22, 0xEF, 0xB7, 0x90, 0x22])
precondition(canonicalComposed != canonicalDecomposed)
precondition(canonicalEscapes.bytes.count == 5)
precondition(canonicalNoncharacter.bytes.count == 3)
for invalid in [#""\u0031""#, #""\u0061""#, #""\/""#, #""\u000F""#, #""\u000a""#] {
    expectIngressError(.invalidDocument, forbiddenText: [invalid]) {
        _ = try decodeCanonicalJSONStringToken(Array(invalid.utf8))
    }
}
expectIngressError(.invalidDocument, forbiddenText: ["replacement-character"]) {
    _ = try decodeCanonicalJSONStringToken([0x22, 0xC0, 0xAF, 0x22])
}

let emptyBinaryCount = try canonicalBase64DecodedCount("", maximumDecodedByteCount: 0)
let oneBinaryByteCount = try canonicalBase64DecodedCount("Zg==", maximumDecodedByteCount: 1)
let twoBinaryByteCount = try canonicalBase64DecodedCount("Zm8=", maximumDecodedByteCount: 2)
let highBinaryByteCount = try canonicalBase64DecodedCount("+/8=", maximumDecodedByteCount: 2)
precondition(emptyBinaryCount == 0)
precondition(oneBinaryByteCount == 1)
precondition(twoBinaryByteCount == 2)
precondition(highBinaryByteCount == 2)
for invalid in ["Zg", "Zg=", "Zg===", "Zh==", "Zm9=", "Zg-_", "Z g=="] {
    expectIngressError(.invalidDocument, forbiddenText: [invalid]) {
        _ = try canonicalBase64DecodedCount(invalid, maximumDecodedByteCount: 64)
    }
}
expectIngressError(.invalidDocument, forbiddenText: ["Zh==", "0"]) {
    _ = try canonicalBase64DecodedCount("Zh==", maximumDecodedByteCount: 0)
}
expectIngressError(.resourceLimitExceeded, forbiddenText: ["Zg==", "1"]) {
    _ = try canonicalBase64DecodedCount("Zg==", maximumDecodedByteCount: 0)
}

// RFC 8785 Appendix B anchors. A production implementation still requires a
// vetted shortest-round-trip emitter, separately vetted decimal parser, and
// differential corpora.
let jcsFloatingVectors: [(bits: UInt64, token: String)] = [
    (0x0000_0000_0000_0000, "0"),
    (0x0000_0000_0000_0001, "5e-324"),
    (0x8000_0000_0000_0001, "-5e-324"),
    (0x7FEF_FFFF_FFFF_FFFF, "1.7976931348623157e+308"),
    (0xFFEF_FFFF_FFFF_FFFF, "-1.7976931348623157e+308"),
]
for vector in jcsFloatingVectors {
    precondition(Double(vector.token)?.bitPattern == vector.bits)
}
precondition(Double("1e-07")?.bitPattern == Double("1e-7")?.bitPattern)
precondition(Double("1.0")?.bitPattern == Double("1")?.bitPattern)

let schema = try ProbeSchemaReference(
    identifier: "org.voxelia.example-schema",
    major: 1,
    minor: 0
)
let otherSchema = try ProbeSchemaReference(
    identifier: "org.voxelia.example-schema",
    major: 2,
    minor: 0
)
let otherNamedSchema = try ProbeSchemaReference(
    identifier: "org.voxelia.other-schema",
    major: 1,
    minor: 0
)
let maximumSchemaIdentifier = [String](
    repeating: String(repeating: "a", count: 63),
    count: 4
).joined(separator: ".")
let maximumSchema = try ProbeSchemaReference(
    identifier: maximumSchemaIdentifier,
    major: UInt32.max,
    minor: UInt32.max
)
precondition(maximumSchema.identifier.bytes.count == 255)
for invalidIdentifier in ["single", "Org.example", "org..example", "org.-example"] {
    expectSchemaReferenceError(.invalidIdentifier, forbiddenText: [invalidIdentifier]) {
        _ = try ProbeSchemaReference(identifier: invalidIdentifier, major: 1, minor: 0)
    }
}
let oversizedSchemaLabel = "org." + String(repeating: "a", count: 64)
expectSchemaReferenceError(
    .identifierByteLimitExceeded,
    forbiddenText: [oversizedSchemaLabel]
) {
    _ = try ProbeSchemaReference(identifier: oversizedSchemaLabel, major: 1, minor: 0)
}
let oversizedSchemaIdentifier =
    String(repeating: "a", count: 63) + "."
    + String(repeating: "b", count: 63) + "."
    + String(repeating: "c", count: 63) + "."
    + String(repeating: "d", count: 62) + ".e"
precondition(oversizedSchemaIdentifier.utf8.count == 256)
expectSchemaReferenceError(
    .identifierByteLimitExceeded,
    forbiddenText: [oversizedSchemaIdentifier]
) {
    _ = try ProbeSchemaReference(identifier: oversizedSchemaIdentifier, major: 1, minor: 0)
}
let repeatableKey = ProbeKey(
    namespace: ProbeExactUTF8("example"),
    name: ProbeExactUTF8("repeatable")
)
let context = ProbeIngressContext(
    expectedMultiplicitySchema: schema,
    repeatableKeys: [repeatableKey]
)
try validateSchemaAndMultiplicity(multiplicitySchema: nil, keys: [repeatableKey], context: nil)
try validateSchemaAndMultiplicity(
    multiplicitySchema: schema,
    keys: [repeatableKey, repeatableKey],
    context: context
)
expectIngressError(.invalidDocument, forbiddenText: ["example-schema", "2"]) {
    try validateSchemaAndMultiplicity(multiplicitySchema: otherSchema, keys: [], context: context)
}
expectIngressError(.invalidDocument, forbiddenText: ["example-schema"]) {
    try validateSchemaAndMultiplicity(multiplicitySchema: schema, keys: [], context: nil)
}
expectIngressError(.invalidDocument, forbiddenText: ["example-schema"]) {
    try validateSchemaAndMultiplicity(multiplicitySchema: nil, keys: [], context: context)
}
expectIngressError(.invalidDocument, forbiddenText: ["other-schema"]) {
    let namedContext = ProbeIngressContext(
        expectedMultiplicitySchema: schema,
        repeatableKeys: []
    )
    try validateSchemaAndMultiplicity(
        multiplicitySchema: otherNamedSchema,
        keys: [],
        context: namedContext
    )
}
expectIngressError(.invalidDocument, forbiddenText: ["repeatable", "2"]) {
    try validateSchemaAndMultiplicity(
        multiplicitySchema: nil,
        keys: [repeatableKey, repeatableKey],
        context: nil
    )
}

var uniqueEmissionBegan = false
try preflightCanonicalEmission(
    multiplicitySchema: nil,
    keys: [repeatableKey],
    context: nil,
    didBeginEmission: &uniqueEmissionBegan
)
precondition(uniqueEmissionBegan)

var configuredEmissionBegan = false
try preflightCanonicalEmission(
    multiplicitySchema: schema,
    keys: [repeatableKey, repeatableKey],
    context: context,
    didBeginEmission: &configuredEmissionBegan
)
precondition(configuredEmissionBegan)

let narrowerContext = ProbeIngressContext(
    expectedMultiplicitySchema: schema,
    repeatableKeys: []
)
var narrowerPolicyBeganEmission = false
expectEmissionError(.invalidValue, forbiddenText: ["repeatable", "policy"]) {
    try preflightCanonicalEmission(
        multiplicitySchema: schema,
        keys: [repeatableKey, repeatableKey],
        context: narrowerContext,
        didBeginEmission: &narrowerPolicyBeganEmission
    )
}
precondition(!narrowerPolicyBeganEmission)

var mismatchedReferenceBeganEmission = false
expectEmissionError(.invalidValue, forbiddenText: ["other-schema"]) {
    try preflightCanonicalEmission(
        multiplicitySchema: otherNamedSchema,
        keys: [repeatableKey],
        context: context,
        didBeginEmission: &mismatchedReferenceBeganEmission
    )
}
precondition(!mismatchedReferenceBeganEmission)

let smallLimits = ProbeIngressLimits(
    maximumDocumentByteCount: 16,
    maximumRawTokenByteCount: 8,
    maximumDecodedStringByteCount: 8,
    maximumDecodedBinaryByteCount: 8,
    maximumEntryCount: 2,
    maximumStructuralElementCount: 2,
    maximumLogicalPayloadByteCount: 8,
    maximumSemanticValueDepth: 2,
    maximumRawJSONDepth: 10
)
var exactBudget = ProbeBudget(limits: smallLimits)
try exactBudget.chargeDocumentBytes(16)
try exactBudget.chargeStructuralElement()
try exactBudget.chargeStructuralElement()
try exactBudget.chargeLogicalPayload(8)
var rejectedDocumentBudget = exactBudget
expectIngressError(.resourceLimitExceeded, forbiddenText: ["16", "document"]) {
    try rejectedDocumentBudget.chargeDocumentBytes(1)
}
precondition(rejectedDocumentBudget.documentBytes == exactBudget.documentBytes)
var rejectedStructuralBudget = exactBudget
expectIngressError(.resourceLimitExceeded, forbiddenText: ["2", "structural"]) {
    try rejectedStructuralBudget.chargeStructuralElement()
}
precondition(rejectedStructuralBudget.structuralElements == exactBudget.structuralElements)
var rejectedPayloadBudget = exactBudget
expectIngressError(.resourceLimitExceeded, forbiddenText: ["8", "payload"]) {
    try rejectedPayloadBudget.chargeLogicalPayload(1)
}
precondition(rejectedPayloadBudget.logicalPayloadBytes == exactBudget.logicalPayloadBytes)
expectIngressError(.resourceLimitExceeded, forbiddenText: ["overflow"]) {
    var budget = ProbeBudget(
        limits: ProbeIngressLimits(
            maximumDocumentByteCount: UInt64.max,
            maximumRawTokenByteCount: 1,
            maximumDecodedStringByteCount: 1,
            maximumDecodedBinaryByteCount: 1,
            maximumEntryCount: 1,
            maximumStructuralElementCount: 1,
            maximumLogicalPayloadByteCount: 1,
            maximumSemanticValueDepth: 1,
            maximumRawJSONDepth: 1
        )
    )
    try budget.chargeDocumentBytes(UInt64.max)
    try budget.chargeDocumentBytes(1)
}

// Envelope(1) + collection(1) + entries(1) + entry(1) +, for each of 64
// semantic object levels, a tag object, member array and member object, then a
// leaf tag and its deepest object payload. This is a grammar-derived ceiling,
// not the semantic value-depth ceiling reused accidentally.
let maximumSemanticDepth: UInt64 = 64
let derivedMaximumRawJSONDepth: UInt64 = 6 + (3 * maximumSemanticDepth)
precondition(derivedMaximumRawJSONDepth == 198)

let maximumDepthDocument = canonicalEnvelope(containing: nestedObjectValue(levels: 64))
let observedMaximumDepth = observedRawContainerDepth(maximumDepthDocument)
precondition(observedMaximumDepth == derivedMaximumRawJSONDepth)

let goldenEnvelope =
    "{\"documentSchema\":{\"identifier\":\"org.voxelia.metadata-document\","
    + "\"version\":{\"major\":1,\"minor\":0}},"
    + "\"multiplicitySchema\":null,\"payload\":{\"entries\":[]}}"
let parsedGoldenEnvelope = try JSONSerialization.jsonObject(with: Data(goldenEnvelope.utf8))
precondition(parsedGoldenEnvelope is [String: Any])
precondition(!goldenEnvelope.contains("\n"))

for error in [
    ProbeMetadataJSONIngressError.invalidDocument,
    .unsupportedSchemaVersion,
    .resourceLimitExceeded,
    .cancelled,
] {
    let rendered = [String(describing: error), String(reflecting: error)]
    for sentinel in ["patient-key-sentinel", "offset", "privacyClass", "hostDefined", "64"] {
        precondition(rendered.allSatisfy { !$0.contains(sentinel) })
    }
}

print("foundationBoundary=false duplicatesCollapsed=true integerAliasesAccepted=true")
print("integerProjection=decimalStrings fullInt64=true fullUInt64=true")
print("unicode=exactUTF8 noNormalization=true noncharacters=preserved frozenBlankOracle=true")
print("canonicalSubtokens=strings+strictBase64 floatingVectorsOnly=true")
print("foundationSortedKeysIsNotJCS=true schemaIdentifier=boundedASCII255")
print("schemaBinding=callerExpected policy=outOfBand uniqueOnlyWithoutContext=true")
print("emissionPreflight=symmetric policyFailureBeginsNoEmission=true")
print("budgetArithmetic=checked generatedRawDepth=198 diagnostics=payloadFree")
