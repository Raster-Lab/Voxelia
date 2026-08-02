// SPDX-License-Identifier: MIT
//
// Isolated Swift 6 evidence for proposed ADR-0031. These Probe* declarations
// are not Voxelia public API or an implementation authorization.

import Foundation

enum ProbeError: Error, Sendable, Equatable {
    case duplicateObjectKey
    case containerDepthLimitExceeded
    case structuralElementLimitExceeded
    case logicalPayloadByteLimitExceeded
}

struct ProbeMetrics: Sendable, Equatable {
    let containerDepth: Int
    let structuralElements: UInt64
    let logicalPayloadBytes: UInt64
}

struct ProbeKey: Sendable, Hashable, Codable {
    let namespace: String
    let name: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.namespace.utf8.elementsEqual(rhs.namespace.utf8)
            && lhs.name.utf8.elementsEqual(rhs.name.utf8)
    }

    func hash(into hasher: inout Hasher) {
        for value in [namespace, name] {
            hasher.combine(value.utf8.count)
            for byte in value.utf8 {
                hasher.combine(byte)
            }
        }
    }

    func precedes(_ other: Self) -> Bool {
        if !namespace.utf8.elementsEqual(other.namespace.utf8) {
            return namespace.utf8.lexicographicallyPrecedes(other.namespace.utf8)
        }
        return name.utf8.lexicographicallyPrecedes(other.name.utf8)
    }

    init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: ProbeCodingKey.self)
        guard Set(container.allKeys.map(\.stringValue)) == Set(["namespace", "name"]) else {
            throw probeCorrupted(
                description: "A probe key requires namespace and name."
            )
        }
        namespace = try container.decode(String.self, forKey: .init("namespace"))
        name = try container.decode(String.self, forKey: .init("name"))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ProbeCodingKey.self)
        try container.encode(namespace, forKey: .init("namespace"))
        try container.encode(name, forKey: .init("name"))
    }
}

struct ProbeMember: Sendable, Hashable {
    let key: ProbeKey
    let value: ProbeValue
}

struct ProbeArray: Sendable, Hashable {
    let values: ContiguousArray<ProbeValue>
    let metrics: ProbeMetrics

    init<Values: Collection>(values source: Values) throws
    where Values.Element == ProbeValue {
        guard
            source.count
                <= Int(ProbeValue.maximumLogicalStructuralElementCount - 1)
        else {
            throw ProbeError.structuralElementLimitExceeded
        }
        var values: ContiguousArray<ProbeValue> = []
        values.reserveCapacity(source.count)
        var depth = 1
        var structuralElements: UInt64 = 1
        var payloadBytes: UInt64 = 0

        for value in source {
            depth = max(depth, value.metrics.containerDepth + 1)
            structuralElements = try probeAdding(
                structuralElements,
                value.metrics.structuralElements,
                maximum: ProbeValue.maximumLogicalStructuralElementCount,
                error: .structuralElementLimitExceeded
            )
            payloadBytes = try probeAdding(
                payloadBytes,
                value.metrics.logicalPayloadBytes,
                maximum: ProbeValue.maximumRecursiveContainerLogicalVariablePayloadByteCount,
                error: .logicalPayloadByteLimitExceeded
            )
            values.append(value)
        }

        guard depth <= ProbeValue.maximumContainerDepth else {
            throw ProbeError.containerDepthLimitExceeded
        }
        self.values = values
        metrics = .init(
            containerDepth: depth,
            structuralElements: structuralElements,
            logicalPayloadBytes: payloadBytes
        )
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        ProbeValue.array(lhs) == ProbeValue.array(rhs)
    }

    func hash(into hasher: inout Hasher) {
        ProbeValue.array(self).hash(into: &hasher)
    }
}

struct ProbeObject: Sendable, Hashable {
    let members: ContiguousArray<ProbeMember>
    let metrics: ProbeMetrics

    init<Members: Collection>(members source: Members) throws
    where Members.Element == ProbeMember {
        guard
            source.count
                <= Int((ProbeValue.maximumLogicalStructuralElementCount - 1) / 2)
        else {
            throw ProbeError.structuralElementLimitExceeded
        }
        var members: ContiguousArray<ProbeMember> = []
        members.reserveCapacity(source.count)
        var depth = 1
        var structuralElements: UInt64 = 1
        var payloadBytes: UInt64 = 0

        for member in source {
            depth = max(depth, member.value.metrics.containerDepth + 1)
            structuralElements = try probeAdding(
                structuralElements,
                1,
                maximum: ProbeValue.maximumLogicalStructuralElementCount,
                error: .structuralElementLimitExceeded
            )
            structuralElements = try probeAdding(
                structuralElements,
                member.value.metrics.structuralElements,
                maximum: ProbeValue.maximumLogicalStructuralElementCount,
                error: .structuralElementLimitExceeded
            )
            payloadBytes = try probeAdding(
                payloadBytes,
                UInt64(member.key.namespace.utf8.count),
                maximum: ProbeValue.maximumRecursiveContainerLogicalVariablePayloadByteCount,
                error: .logicalPayloadByteLimitExceeded
            )
            payloadBytes = try probeAdding(
                payloadBytes,
                UInt64(member.key.name.utf8.count),
                maximum: ProbeValue.maximumRecursiveContainerLogicalVariablePayloadByteCount,
                error: .logicalPayloadByteLimitExceeded
            )
            payloadBytes = try probeAdding(
                payloadBytes,
                member.value.metrics.logicalPayloadBytes,
                maximum: ProbeValue.maximumRecursiveContainerLogicalVariablePayloadByteCount,
                error: .logicalPayloadByteLimitExceeded
            )
            members.append(member)
        }

        guard depth <= ProbeValue.maximumContainerDepth else {
            throw ProbeError.containerDepthLimitExceeded
        }
        members.sort { $0.key.precedes($1.key) }
        for index in members.indices.dropFirst() {
            guard members[members.index(before: index)].key != members[index].key else {
                throw ProbeError.duplicateObjectKey
            }
        }
        self.members = members
        metrics = .init(
            containerDepth: depth,
            structuralElements: structuralElements,
            logicalPayloadBytes: payloadBytes
        )
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        ProbeValue.object(lhs) == ProbeValue.object(rhs)
    }

    func hash(into hasher: inout Hasher) {
        ProbeValue.object(self).hash(into: &hasher)
    }
}

enum ProbeValue: Sendable, Hashable, Codable {
    static let maximumContainerDepth = 64
    static let maximumLogicalStructuralElementCount: UInt64 = 1_048_576
    static let maximumRecursiveContainerLogicalVariablePayloadByteCount: UInt64 =
        67_108_864

    case boolean(Bool)
    case signedInteger(Int64)
    case unsignedInteger(UInt64)
    case string(String)
    case array(ProbeArray)
    case object(ProbeObject)

    var metrics: ProbeMetrics {
        switch self {
        case .string(let value):
            .init(
                containerDepth: 0,
                structuralElements: 1,
                logicalPayloadBytes: UInt64(value.utf8.count)
            )
        case .array(let value):
            value.metrics
        case .object(let value):
            value.metrics
        default:
            .init(containerDepth: 0, structuralElements: 1, logicalPayloadBytes: 0)
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        enum Frame {
            case value(ProbeValue, ProbeValue)
            case array(ContiguousArray<ProbeValue>, ContiguousArray<ProbeValue>, Int)
            case object(ContiguousArray<ProbeMember>, ContiguousArray<ProbeMember>, Int)
        }

        var frames = [Frame.value(lhs, rhs)]
        while let frame = frames.popLast() {
            switch frame {
            case .value(.boolean(let lhs), .boolean(let rhs)):
                guard lhs == rhs else { return false }
            case .value(.signedInteger(let lhs), .signedInteger(let rhs)):
                guard lhs == rhs else { return false }
            case .value(.unsignedInteger(let lhs), .unsignedInteger(let rhs)):
                guard lhs == rhs else { return false }
            case .value(.string(let lhs), .string(let rhs)):
                guard lhs.utf8.elementsEqual(rhs.utf8) else { return false }
            case .value(.array(let lhs), .array(let rhs)):
                guard lhs.values.count == rhs.values.count else { return false }
                frames.append(.array(lhs.values, rhs.values, 0))
            case .value(.object(let lhs), .object(let rhs)):
                guard lhs.members.count == rhs.members.count else { return false }
                frames.append(.object(lhs.members, rhs.members, 0))
            case .value:
                return false
            case .array(let lhs, let rhs, let index):
                guard index < lhs.count else { continue }
                frames.append(.array(lhs, rhs, index + 1))
                frames.append(.value(lhs[index], rhs[index]))
            case .object(let lhs, let rhs, let index):
                guard index < lhs.count else { continue }
                guard lhs[index].key == rhs[index].key else { return false }
                frames.append(.object(lhs, rhs, index + 1))
                frames.append(.value(lhs[index].value, rhs[index].value))
            }
        }
        return true
    }

    func hash(into hasher: inout Hasher) {
        enum Frame {
            case value(ProbeValue)
            case array(ContiguousArray<ProbeValue>, Int)
            case object(ContiguousArray<ProbeMember>, Int)
        }

        var frames = [Frame.value(self)]
        while let frame = frames.popLast() {
            switch frame {
            case .value(.boolean(let value)):
                hasher.combine(UInt8(0))
                hasher.combine(value)
            case .value(.signedInteger(let value)):
                hasher.combine(UInt8(1))
                hasher.combine(value)
            case .value(.unsignedInteger(let value)):
                hasher.combine(UInt8(2))
                hasher.combine(value)
            case .value(.string(let value)):
                hasher.combine(UInt8(3))
                hasher.combine(value.utf8.count)
                for byte in value.utf8 {
                    hasher.combine(byte)
                }
            case .value(.array(let array)):
                hasher.combine(UInt8(4))
                hasher.combine(array.values.count)
                frames.append(.array(array.values, 0))
            case .value(.object(let object)):
                hasher.combine(UInt8(5))
                hasher.combine(object.members.count)
                frames.append(.object(object.members, 0))
            case .array(let values, let index):
                guard index < values.count else { continue }
                frames.append(.array(values, index + 1))
                frames.append(.value(values[index]))
            case .object(let members, let index):
                guard index < members.count else { continue }
                hasher.combine(members[index].key)
                frames.append(.object(members, index + 1))
                frames.append(.value(members[index].value))
            }
        }
    }

    init(from decoder: any Decoder) throws {
        do {
            self = try Self.decode(from: decoder, parentDepth: 0, budget: .init())
        } catch let error as ProbeError {
            throw probeCorrupted(
                description: "Metadata resource validation failed.",
                underlyingError: error
            )
        }
    }

    static func decode(
        from decoder: any Decoder,
        parentDepth: Int,
        budget: ProbeDecodeBudget
    ) throws -> Self {
        try budget.addStructuralElements(1)
        let container = try decoder.container(keyedBy: ProbeCodingKey.self)
        guard container.allKeys.count == 1, let tag = container.allKeys.first else {
            throw probeCorrupted(
                description: "A metadata value requires exactly one tag."
            )
        }

        switch tag.stringValue {
        case "boolean":
            return .boolean(try container.decode(Bool.self, forKey: tag))
        case "signedInteger":
            return .signedInteger(try container.decode(Int64.self, forKey: tag))
        case "unsignedInteger":
            return .unsignedInteger(try container.decode(UInt64.self, forKey: tag))
        case "string":
            let value = try container.decode(String.self, forKey: tag)
            try budget.addPayloadBytes(UInt64(value.utf8.count))
            return .string(value)
        case "array":
            budget.enablePayloadAccounting()
            let depth = parentDepth + 1
            guard depth <= maximumContainerDepth else {
                throw probeCorrupted(
                    description: "Metadata container depth is unsupported.",
                    underlyingError: ProbeError.containerDepthLimitExceeded
                )
            }
            var source = try container.nestedUnkeyedContainer(forKey: tag)
            var values: ContiguousArray<ProbeValue> = []
            while !source.isAtEnd {
                values.append(
                    try decode(
                        from: source.superDecoder(),
                        parentDepth: depth,
                        budget: budget
                    )
                )
            }
            return .array(try ProbeArray(values: values))
        case "object":
            budget.enablePayloadAccounting()
            let depth = parentDepth + 1
            guard depth <= maximumContainerDepth else {
                throw probeCorrupted(
                    description: "Metadata container depth is unsupported.",
                    underlyingError: ProbeError.containerDepthLimitExceeded
                )
            }
            var source = try container.nestedUnkeyedContainer(forKey: tag)
            var members: ContiguousArray<ProbeMember> = []
            while !source.isAtEnd {
                try budget.addStructuralElements(1)
                let memberDecoder = try source.superDecoder()
                let memberContainer = try memberDecoder.container(
                    keyedBy: ProbeCodingKey.self
                )
                guard
                    Set(memberContainer.allKeys.map(\.stringValue))
                        == Set(["key", "value"])
                else {
                    throw probeCorrupted(
                        description: "A metadata member requires key and value."
                    )
                }
                let key = try memberContainer.decode(
                    ProbeKey.self,
                    forKey: .init("key")
                )
                try budget.addPayloadBytes(UInt64(key.namespace.utf8.count))
                try budget.addPayloadBytes(UInt64(key.name.utf8.count))
                let value = try decode(
                    from: memberContainer.superDecoder(forKey: .init("value")),
                    parentDepth: depth,
                    budget: budget
                )
                members.append(.init(key: key, value: value))
            }
            do {
                return .object(try ProbeObject(members: members))
            } catch let error as ProbeError {
                throw probeCorrupted(
                    description: "Metadata object validation failed.",
                    underlyingError: error
                )
            }
        default:
            throw probeCorrupted(
                description: "A metadata value has an unknown tag."
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ProbeCodingKey.self)
        switch self {
        case .boolean(let value):
            try container.encode(value, forKey: .init("boolean"))
        case .signedInteger(let value):
            try container.encode(value, forKey: .init("signedInteger"))
        case .unsignedInteger(let value):
            try container.encode(value, forKey: .init("unsignedInteger"))
        case .string(let value):
            try container.encode(value, forKey: .init("string"))
        case .array(let array):
            var destination = container.nestedUnkeyedContainer(forKey: .init("array"))
            for value in array.values {
                try value.encode(to: destination.superEncoder())
            }
        case .object(let object):
            var destination = container.nestedUnkeyedContainer(forKey: .init("object"))
            for member in object.members {
                let memberEncoder = destination.superEncoder()
                var memberContainer = memberEncoder.container(
                    keyedBy: ProbeCodingKey.self
                )
                try memberContainer.encode(member.key, forKey: .init("key"))
                try member.value.encode(
                    to: memberContainer.superEncoder(forKey: .init("value"))
                )
            }
        }
    }
}

final class ProbeDecodeBudget {
    private var structuralElements: UInt64 = 0
    private var payloadBytes: UInt64 = 0
    private var accountsPayload = false

    func enablePayloadAccounting() {
        accountsPayload = true
    }

    func addStructuralElements(_ count: UInt64) throws {
        structuralElements = try probeAdding(
            structuralElements,
            count,
            maximum: ProbeValue.maximumLogicalStructuralElementCount,
            error: .structuralElementLimitExceeded
        )
    }

    func addPayloadBytes(_ count: UInt64) throws {
        guard accountsPayload else { return }
        payloadBytes = try probeAdding(
            payloadBytes,
            count,
            maximum: ProbeValue.maximumRecursiveContainerLogicalVariablePayloadByteCount,
            error: .logicalPayloadByteLimitExceeded
        )
    }
}

struct ProbeCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}

func probeAdding(
    _ lhs: UInt64,
    _ rhs: UInt64,
    maximum: UInt64,
    error: ProbeError
) throws -> UInt64 {
    let sum = lhs.addingReportingOverflow(rhs)
    guard !sum.overflow, sum.partialValue <= maximum else {
        throw error
    }
    return sum.partialValue
}

func probeCorrupted(
    description: String,
    underlyingError: (any Error)? = nil
) -> DecodingError {
    .dataCorrupted(
        .init(
            codingPath: [],
            debugDescription: description,
            underlyingError: underlyingError
        )
    )
}

func expectProbeDecodeFailure(_ json: String) {
    do {
        _ = try JSONDecoder().decode(ProbeValue.self, from: Data(json.utf8))
        preconditionFailure("Accepted invalid probe metadata JSON")
    } catch {
    }
}

func requireSendable<Value: Sendable>(_: Value.Type) {}
requireSendable(ProbeValue.self)
requireSendable(ProbeArray.self)
requireSendable(ProbeObject.self)
requireSendable(ProbeMember.self)

let composed = "caf\u{00e9}"
let decomposed = "cafe\u{0301}"
let exactStrings = Set([ProbeValue.string(composed), ProbeValue.string(decomposed)])
precondition(exactStrings.count == 2)

let keyA = ProbeKey(namespace: "ns", name: "a")
let keyB = ProbeKey(namespace: "ns", name: "b")
let memberA = ProbeMember(key: keyA, value: .signedInteger(1))
let memberB = ProbeMember(key: keyB, value: .signedInteger(2))
let objectOne = try ProbeObject(members: [memberB, memberA])
let objectTwo = try ProbeObject(members: [memberA, memberB])
precondition(objectOne == objectTwo)
precondition(objectOne.members.map(\.key.name) == ["a", "b"])
precondition(Set([ProbeValue.object(objectOne), .object(objectTwo)]).count == 1)

do {
    _ = try ProbeObject(members: [memberA, memberA])
    preconditionFailure("Accepted an exact duplicate key")
} catch ProbeError.duplicateObjectKey {
}

let spellingObject = try ProbeObject(
    members: [
        .init(
            key: .init(namespace: "ns", name: composed),
            value: .boolean(true)
        ),
        .init(
            key: .init(namespace: "ns", name: decomposed),
            value: .boolean(false)
        ),
    ]
)
precondition(spellingObject.members.count == 2)

var depthValue = ProbeValue.boolean(true)
for _ in 0..<ProbeValue.maximumContainerDepth {
    depthValue = .array(try ProbeArray(values: [depthValue]))
}
precondition(depthValue.metrics.containerDepth == 64)
precondition(Set([depthValue, depthValue]).count == 1)
do {
    _ = try ProbeArray(values: [depthValue])
    preconditionFailure("Accepted depth 65")
} catch ProbeError.containerDepthLimitExceeded {
}

var amplified = ProbeValue.string("")
for _ in 0..<19 {
    amplified = .array(try ProbeArray(values: [amplified, amplified]))
}
precondition(amplified.metrics.structuralElements == 1_048_575)
do {
    _ = try ProbeArray(values: [amplified, amplified])
    preconditionFailure("Accepted 2,097,151 logical elements")
} catch ProbeError.structuralElementLimitExceeded {
}
let exactElementBoundary = try probeAdding(
    1_048_575,
    1,
    maximum: ProbeValue.maximumLogicalStructuralElementCount,
    error: .structuralElementLimitExceeded
)
precondition(exactElementBoundary == 1_048_576)
do {
    _ = try probeAdding(
        exactElementBoundary,
        1,
        maximum: ProbeValue.maximumLogicalStructuralElementCount,
        error: .structuralElementLimitExceeded
    )
    preconditionFailure("Accepted one structural element above the limit")
} catch ProbeError.structuralElementLimitExceeded {
}

var payloadAmplified = ProbeValue.string(String(repeating: "x", count: 1 << 20))
for _ in 0..<6 {
    payloadAmplified = .array(
        try ProbeArray(values: [payloadAmplified, payloadAmplified])
    )
}
precondition(payloadAmplified.metrics.logicalPayloadBytes == 67_108_864)
do {
    _ = try ProbeArray(values: [payloadAmplified, payloadAmplified])
    preconditionFailure("Accepted 128 MiB logical payload")
} catch ProbeError.logicalPayloadByteLimitExceeded {
}

guard
    let oversizedStandaloneByteCount = Int(
        exactly: ProbeValue.maximumRecursiveContainerLogicalVariablePayloadByteCount + 1
    )
else {
    preconditionFailure("The probe platform cannot represent the payload boundary")
}
do {
    let oversizedString = String(repeating: "y", count: oversizedStandaloneByteCount)
    let oversizedLeaf = ProbeValue.string(oversizedString)
    let encoded = try JSONEncoder().encode(oversizedLeaf)
    let decoded = try JSONDecoder().decode(ProbeValue.self, from: encoded)
    guard case .string(let decodedString) = decoded else {
        preconditionFailure("Decoded the wrong standalone payload tag")
    }
    precondition(decodedString.utf8.count == oversizedStandaloneByteCount)
    do {
        _ = try ProbeArray(values: [oversizedLeaf])
        preconditionFailure("Embedded a standalone leaf above the aggregate limit")
    } catch ProbeError.logicalPayloadByteLimitExceeded {
    }
}

let overflow = UInt64.max.addingReportingOverflow(1)
precondition(overflow.overflow)

let wide = ProbeValue.array(
    try ProbeArray(values: (0..<20_000).map { .signedInteger(Int64($0)) })
)
precondition(wide == wide)
precondition(Set([wide, wide]).count == 1)

let edgeValues: [ProbeValue] = [
    .boolean(true),
    .signedInteger(.min),
    .signedInteger(.max),
    .unsignedInteger(.max),
    .string("café"),
    .array(try ProbeArray(values: [])),
    .object(try ProbeObject(members: [])),
]
for value in edgeValues {
    let encoded = try JSONEncoder().encode(value)
    _ = try JSONDecoder().decode(ProbeValue.self, from: encoded)
}

expectProbeDecodeFailure("{}")
expectProbeDecodeFailure(#"{"unknown":1}"#)
expectProbeDecodeFailure(#"{"string":null}"#)
expectProbeDecodeFailure(#"{"string":"x","boolean":true}"#)
expectProbeDecodeFailure(#"{"signedInteger":"1"}"#)
expectProbeDecodeFailure(
    #"{"object":[{"key":{"namespace":"n","name":"same"},"value":{"boolean":true}},{"key":{"namespace":"n","name":"same"},"value":{"boolean":false}}]}"#
)

do {
    _ = try JSONDecoder().decode(
        [String: ProbeValue].self,
        from: Data(#"{"patient-name":{"unknown":1}}"#.utf8)
    )
    preconditionFailure("Accepted an unknown tag beneath a caller key")
} catch DecodingError.dataCorrupted(let context) {
    precondition(context.codingPath.isEmpty)
    precondition(!context.debugDescription.contains("patient-name"))
} catch {
    preconditionFailure("Returned the wrong failure kind beneath a caller key")
}

for token in ["1", "1.0", "1e0", "-0"] {
    let value = try JSONDecoder().decode(
        ProbeValue.self,
        from: Data("{\"signedInteger\":\(token)}".utf8)
    )
    guard case .signedInteger(let decoded) = value else {
        preconditionFailure("Decoded the wrong integer tag")
    }
    precondition(decoded == (token == "-0" ? 0 : 1))
}

let maximumDepthJSON = try JSONEncoder().encode(depthValue)
_ = try JSONDecoder().decode(ProbeValue.self, from: maximumDepthJSON)
var excessiveDepthJSON = #"{"boolean":true}"#
for _ in 0...ProbeValue.maximumContainerDepth {
    excessiveDepthJSON = "{\"array\":[\(excessiveDepthJSON)]}"
}
expectProbeDecodeFailure(excessiveDepthJSON)

let evidenceEncoder = JSONEncoder()
evidenceEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
let orderedJSON = String(
    decoding: try evidenceEncoder.encode(ProbeValue.object(objectOne)),
    as: UTF8.self
)

print("exactStrings=\(exactStrings.count)")
print("objectOrder=\(objectOne.members.map(\.key.name).joined(separator: ","))")
print("equivalentKeySpellings=\(spellingObject.members.count)")
print("depth=\(depthValue.metrics.containerDepth)/64 next=rejected")
print("amplifiedElements=\(amplified.metrics.structuralElements) next=rejected")
print("elementArithmetic=\(exactElementBoundary)/1048576 next=rejected")
print("payload=\(payloadAmplified.metrics.logicalPayloadBytes)/67108864 next=rejected")
print("standalonePayload=67108865 embedded=rejected callerPath=sanitized")
print("wide=20000 strictInvalid=6 integerAliases=4")
print("ordered=\(orderedJSON)")
