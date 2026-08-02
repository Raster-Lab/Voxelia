// SPDX-License-Identifier: MIT
//
// Isolated Swift 6 evidence for proposed ADR-0032. These Probe* declarations
// are not Voxelia public API or implementation authorisation. The reduced
// value/object payload exists only to exercise the entry privacy boundary;
// ADR-0031 owns the complete recursive MetadataValue contract.

import Foundation

enum ProbePrivacyClass: String, Sendable, Hashable, Codable {
    case publicData
    case technical
    case potentiallyIdentifying
    case sensitive
    case hostDefined

    init(from decoder: any Decoder) throws {
        let rawValue: String
        do {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(String.self)
        } catch {
            throw probeCorrupted(
                path: [],
                description: "A recognised privacy classification is required."
            )
        }

        guard let value = Self(rawValue: rawValue) else {
            throw probeCorrupted(
                path: [],
                description: "A recognised privacy classification is required."
            )
        }
        self = value
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct ProbeKey: Sendable, Hashable, Codable {
    let namespace: String
    let name: String
}

struct ProbeObjectMember: Sendable, Hashable, Codable {
    let key: ProbeKey
    let value: String
}

enum ProbeValue: Sendable, Hashable, Codable {
    case string(String)
    case object(ContiguousArray<ProbeObjectMember>)

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: ProbeCodingKey.self)
        guard container.allKeys.count == 1, let tag = container.allKeys.first else {
            throw probeCorrupted(
                path: [],
                description: "A probe value requires exactly one tag."
            )
        }

        switch tag.stringValue {
        case "string":
            self = .string(try container.decode(String.self, forKey: tag))
        case "object":
            self = .object(
                try container.decode(
                    ContiguousArray<ProbeObjectMember>.self,
                    forKey: tag
                )
            )
        default:
            throw probeCorrupted(
                path: [],
                description: "A probe value has an unknown tag."
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ProbeCodingKey.self)
        switch self {
        case .string(let value):
            try container.encode(value, forKey: .init("string"))
        case .object(let members):
            try container.encode(members, forKey: .init("object"))
        }
    }
}

struct ProbeEntry: Sendable, Hashable, Codable {
    let key: ProbeKey
    let value: ProbeValue
    let privacyClass: ProbePrivacyClass

    init(
        key: ProbeKey,
        value: ProbeValue,
        privacyClass: ProbePrivacyClass
    ) {
        self.key = key
        self.value = value
        self.privacyClass = privacyClass
    }

    init(from decoder: any Decoder) throws {
        let keyKey = ProbeCodingKey("key")
        let valueKey = ProbeCodingKey("value")
        let privacyClassKey = ProbeCodingKey("privacyClass")
        let container: KeyedDecodingContainer<ProbeCodingKey>
        do {
            container = try decoder.container(keyedBy: ProbeCodingKey.self)
        } catch {
            throw probeCorrupted(
                path: [],
                description: "A metadata entry requires a fixed keyed object."
            )
        }
        let expectedKeys = Set([
            keyKey.stringValue,
            valueKey.stringValue,
            privacyClassKey.stringValue,
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw probeCorrupted(
                path: [],
                description: "A metadata entry requires three fixed fields."
            )
        }

        let key: ProbeKey
        do {
            key = try container.decode(ProbeKey.self, forKey: keyKey)
        } catch {
            throw probeCorrupted(
                path: [keyKey],
                description: "A metadata entry has an invalid key."
            )
        }

        let value: ProbeValue
        do {
            value = try container.decode(ProbeValue.self, forKey: valueKey)
        } catch {
            throw probeCorrupted(
                path: [valueKey],
                description: "A metadata entry has an invalid value."
            )
        }

        let privacyClass: ProbePrivacyClass
        do {
            privacyClass = try container.decode(
                ProbePrivacyClass.self,
                forKey: privacyClassKey
            )
        } catch {
            throw probeCorrupted(
                path: [privacyClassKey],
                description: "A metadata entry has an invalid privacy classification."
            )
        }

        self.init(key: key, value: value, privacyClass: privacyClass)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ProbeCodingKey.self)
        try container.encode(key, forKey: .init("key"))
        try container.encode(value, forKey: .init("value"))
        try container.encode(privacyClass, forKey: .init("privacyClass"))
    }
}

struct ProbeCodingKey: CodingKey, Hashable {
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

func probeCorrupted(
    path: [ProbeCodingKey],
    description: String
) -> DecodingError {
    .dataCorrupted(
        .init(
            codingPath: path,
            debugDescription: description
        )
    )
}

func expectProbeDecodeFailure(_ json: String) {
    do {
        _ = try JSONDecoder().decode(ProbeEntry.self, from: Data(json.utf8))
        preconditionFailure("Accepted invalid probe entry JSON")
    } catch {
    }
}

func requireSendable<Value: Sendable>(_: Value.Type) {}
requireSendable(ProbePrivacyClass.self)
requireSendable(ProbeEntry.self)

let key = ProbeKey(namespace: "example", name: "field")
let value = ProbeValue.string("x")
let publicEntry = ProbeEntry(
    key: key,
    value: value,
    privacyClass: .publicData
)
let sensitiveEntry = ProbeEntry(
    key: key,
    value: value,
    privacyClass: .sensitive
)
precondition(publicEntry != sensitiveEntry)
precondition(Set([publicEntry, sensitiveEntry]).count == 2)

let objectMember = ProbeObjectMember(key: key, value: "nested")
let memberLabels = Set(
    Mirror(reflecting: objectMember).children.compactMap(\.label)
)
precondition(!memberLabels.contains("privacyClass"))
let nestedEntry = ProbeEntry(
    key: key,
    value: .object([objectMember]),
    privacyClass: .potentiallyIdentifying
)
precondition(nestedEntry.privacyClass == .potentiallyIdentifying)

let encoded = try JSONEncoder().encode(nestedEntry)
let decodedNestedEntry = try JSONDecoder().decode(ProbeEntry.self, from: encoded)
precondition(decodedNestedEntry == nestedEntry)
let hostDefinedEntry = ProbeEntry(
    key: key,
    value: value,
    privacyClass: .hostDefined
)
let encodedHostDefinedEntry = try JSONEncoder().encode(hostDefinedEntry)
let decodedHostDefinedEntry = try JSONDecoder().decode(
    ProbeEntry.self,
    from: encodedHostDefinedEntry
)
precondition(decodedHostDefinedEntry == hostDefinedEntry)

let keyJSON = #"{"namespace":"example","name":"field"}"#
let valueJSON = #"{"string":"x"}"#
expectProbeDecodeFailure(#"{"key":\#(keyJSON),"value":\#(valueJSON)}"#)
expectProbeDecodeFailure(
    #"{"key":\#(keyJSON),"value":\#(valueJSON),"privacyClass":null}"#
)
expectProbeDecodeFailure(
    #"{"key":\#(keyJSON),"value":\#(valueJSON),"privacyClass":"technical","extra":true}"#
)
expectProbeDecodeFailure(
    #"{"key":\#(keyJSON),"value":\#(valueJSON),"privacyClass":"unknown"}"#
)
expectProbeDecodeFailure(
    #"{"key":\#(keyJSON),"value":\#(valueJSON),"privacyClass":1}"#
)

let callerKey = "patient-caller-sentinel"
let rejectedToken = "patient-token-sentinel"
let nestedFailures = [
    (
        payload:
            #"{"patient-caller-sentinel":{"key":\#(keyJSON),"value":\#(valueJSON),"privacyClass":"patient-token-sentinel"}}"#,
        expectedPath: ["privacyClass"]
    ),
    (
        payload: #"{"patient-caller-sentinel":[]}"#,
        expectedPath: []
    ),
    (
        payload: #"{"patient-caller-sentinel":null}"#,
        expectedPath: []
    ),
]
for failure in nestedFailures {
    do {
        _ = try JSONDecoder().decode(
            [String: ProbeEntry].self,
            from: Data(failure.payload.utf8)
        )
        preconditionFailure("Accepted an invalid entry beneath a caller key")
    } catch let error as DecodingError {
        let rendered = [String(describing: error), String(reflecting: error)]
        precondition(rendered.allSatisfy { !$0.contains(callerKey) })
        precondition(rendered.allSatisfy { !$0.contains(rejectedToken) })
        guard case .dataCorrupted(let context) = error else {
            preconditionFailure("Returned the wrong privacy failure kind")
        }
        precondition(
            context.codingPath.map(\.stringValue) == failure.expectedPath
        )
        precondition(context.underlyingError == nil)
    }
}

let evidenceEncoder = JSONEncoder()
evidenceEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
let orderedJSON = String(
    decoding: try evidenceEncoder.encode(sensitiveEntry),
    as: UTF8.self
)

print("entryIdentityClasses=2 requiredPrivacy=true strictInvalid=5")
print("hostDefinedRoundTrip=true")
print("nestedScope=oneOuterClass outerShapePaths=sanitized")
print("callerPath=sanitized ordered=\(orderedJSON)")
