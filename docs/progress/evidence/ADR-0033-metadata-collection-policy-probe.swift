// SPDX-License-Identifier: MIT
//
// Isolated Swift 6 evidence for a candidate ADR-0033 collection boundary.
// These Probe* declarations are not Voxelia public API or implementation
// authorisation. Reduced string values exercise collection policy only;
// ADR-0031 and ADR-0032 own recursive values and classified entries.

import Foundation

enum ProbePrivacyClass: String, Sendable, Hashable, Codable {
    case publicData
    case technical
    case potentiallyIdentifying
    case sensitive
    case hostDefined
}

struct ProbeKey: Sendable, Hashable, Codable {
    let namespace: String
    let name: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.namespace.utf8.elementsEqual(rhs.namespace.utf8)
            && lhs.name.utf8.elementsEqual(rhs.name.utf8)
    }

    func hash(into hasher: inout Hasher) {
        Self.hashExact(namespace, into: &hasher)
        Self.hashExact(name, into: &hasher)
    }

    private static func hashExact(_ value: String, into hasher: inout Hasher) {
        hasher.combine(value.utf8.count)
        for byte in value.utf8 {
            hasher.combine(byte)
        }
    }
}

struct ProbeEntry: Sendable, Hashable, Codable {
    let key: ProbeKey
    let value: String
    let privacyClass: ProbePrivacyClass
}

enum ProbeCollectionError: Error, Sendable, Equatable {
    case duplicateKey
    case multiplicityPolicyRequired
    case multiplicityPolicyLimitExceeded
    case entryCountLimitExceeded
    case aggregateStructuralElementLimitExceeded
    case logicalPayloadByteLimitExceeded
}

struct ProbeMultiplicityPolicy: Sendable {
    static let uniqueKeysOnly = Self(uncheckedRepeatableKeys: [])

    private static let maximumKeyCount = 4
    private static let maximumLogicalPayloadBytes = 64

    private let repeatableKeys: Set<ProbeKey>

    init<Keys: Collection>(repeatableKeys: Keys) throws
    where Keys.Element == ProbeKey {
        guard repeatableKeys.count <= Self.maximumKeyCount else {
            throw ProbeCollectionError.multiplicityPolicyLimitExceeded
        }

        var payloadBytes = 0
        for key in repeatableKeys {
            let namespaceAddition = payloadBytes.addingReportingOverflow(
                key.namespace.utf8.count
            )
            guard !namespaceAddition.overflow else {
                throw ProbeCollectionError.multiplicityPolicyLimitExceeded
            }
            let nameAddition = namespaceAddition.partialValue.addingReportingOverflow(
                key.name.utf8.count
            )
            guard !nameAddition.overflow,
                nameAddition.partialValue <= Self.maximumLogicalPayloadBytes
            else {
                throw ProbeCollectionError.multiplicityPolicyLimitExceeded
            }
            payloadBytes = nameAddition.partialValue
        }
        self.init(uncheckedRepeatableKeys: Set(repeatableKeys))
    }

    func permitsMultiplicity(for key: ProbeKey) -> Bool {
        repeatableKeys.contains(key)
    }

    private init(uncheckedRepeatableKeys: Set<ProbeKey>) {
        repeatableKeys = uncheckedRepeatableKeys
    }
}

struct ProbeCollection: Sendable, Hashable, Codable, CodableWithConfiguration {
    typealias DecodingConfiguration = ProbeMultiplicityPolicy
    typealias EncodingConfiguration = ProbeMultiplicityPolicy

    private static let maximumEntryCount = 6
    private static let maximumAggregateStructuralElements = 5
    private static let maximumLogicalPayloadBytes = 64

    let entries: ContiguousArray<ProbeEntry>

    init<Entries: Collection>(entries: Entries) throws
    where Entries.Element == ProbeEntry {
        self.entries = try Self.validatedEntries(
            from: entries,
            multiplicityPolicy: .uniqueKeysOnly
        )
    }

    init<Entries: Collection>(
        entries: Entries,
        multiplicityPolicy: ProbeMultiplicityPolicy
    ) throws where Entries.Element == ProbeEntry {
        self.entries = try Self.validatedEntries(
            from: entries,
            multiplicityPolicy: multiplicityPolicy
        )
    }

    init(from decoder: any Decoder) throws {
        entries = try Self.decodeEntries(
            from: decoder,
            multiplicityPolicy: .uniqueKeysOnly
        )
    }

    init(
        from decoder: any Decoder,
        configuration: ProbeMultiplicityPolicy
    ) throws {
        entries = try Self.decodeEntries(
            from: decoder,
            multiplicityPolicy: configuration
        )
    }

    func encode(to encoder: any Encoder) throws {
        do {
            try Self.validate(
                entries,
                multiplicityPolicy: .uniqueKeysOnly
            )
        } catch ProbeCollectionError.duplicateKey {
            throw ProbeCollectionError.multiplicityPolicyRequired
        }
        try encodeEntries(to: encoder)
    }

    func encode(
        to encoder: any Encoder,
        configuration: ProbeMultiplicityPolicy
    ) throws {
        try Self.validate(entries, multiplicityPolicy: configuration)
        try encodeEntries(to: encoder)
    }

    private func encodeEntries(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ProbeCodingKey.self)
        try container.encode(entries, forKey: .init("entries"))
    }

    private static func validate(
        _ entries: ContiguousArray<ProbeEntry>,
        multiplicityPolicy: ProbeMultiplicityPolicy
    ) throws {
        guard entries.count <= maximumEntryCount else {
            throw ProbeCollectionError.entryCountLimitExceeded
        }

        var seenKeys = Set<ProbeKey>()
        var aggregateStructuralElements = 0
        var logicalPayloadBytes = 0
        for entry in entries {
            try validate(
                entry,
                seenKeys: &seenKeys,
                aggregateStructuralElements: &aggregateStructuralElements,
                logicalPayloadBytes: &logicalPayloadBytes,
                multiplicityPolicy: multiplicityPolicy
            )
        }
    }

    private static func validatedEntries<Entries: Collection>(
        from source: Entries,
        multiplicityPolicy: ProbeMultiplicityPolicy
    ) throws -> ContiguousArray<ProbeEntry> where Entries.Element == ProbeEntry {
        let sourceCount = source.count
        guard sourceCount <= maximumEntryCount else {
            throw ProbeCollectionError.entryCountLimitExceeded
        }

        var storedEntries = ContiguousArray<ProbeEntry>()
        storedEntries.reserveCapacity(sourceCount)
        var seenKeys = Set<ProbeKey>()
        var aggregateStructuralElements = 0
        var logicalPayloadBytes = 0
        for entry in source {
            try validate(
                entry,
                seenKeys: &seenKeys,
                aggregateStructuralElements: &aggregateStructuralElements,
                logicalPayloadBytes: &logicalPayloadBytes,
                multiplicityPolicy: multiplicityPolicy
            )
            storedEntries.append(entry)
        }
        return storedEntries
    }

    private static func validate(
        _ entry: ProbeEntry,
        seenKeys: inout Set<ProbeKey>,
        aggregateStructuralElements: inout Int,
        logicalPayloadBytes: inout Int,
        multiplicityPolicy: ProbeMultiplicityPolicy
    ) throws {
        let insertion = seenKeys.insert(entry.key)
        guard insertion.inserted || multiplicityPolicy.permitsMultiplicity(for: entry.key)
        else {
            throw ProbeCollectionError.duplicateKey
        }

        try chargeStructuralElement(to: &aggregateStructuralElements)
        try charge(entry.key.namespace.utf8.count, to: &logicalPayloadBytes)
        try charge(entry.key.name.utf8.count, to: &logicalPayloadBytes)
        try charge(entry.value.utf8.count, to: &logicalPayloadBytes)
    }

    private static func charge(_ amount: Int, to total: inout Int) throws {
        let addition = total.addingReportingOverflow(amount)
        guard !addition.overflow,
            addition.partialValue <= maximumLogicalPayloadBytes
        else {
            throw ProbeCollectionError.logicalPayloadByteLimitExceeded
        }
        total = addition.partialValue
    }

    private static func chargeStructuralElement(to total: inout Int) throws {
        let addition = total.addingReportingOverflow(1)
        guard !addition.overflow,
            addition.partialValue <= maximumAggregateStructuralElements
        else {
            throw ProbeCollectionError.aggregateStructuralElementLimitExceeded
        }
        total = addition.partialValue
    }

    private static func decodeEntries(
        from decoder: any Decoder,
        multiplicityPolicy: ProbeMultiplicityPolicy
    ) throws -> ContiguousArray<ProbeEntry> {
        let entriesKey = ProbeCodingKey("entries")
        let container: KeyedDecodingContainer<ProbeCodingKey>
        do {
            container = try decoder.container(keyedBy: ProbeCodingKey.self)
        } catch {
            throw probeCorrupted(
                path: [],
                description: "A metadata collection requires a fixed keyed object."
            )
        }

        guard Set(container.allKeys.map(\.stringValue)) == [entriesKey.stringValue]
        else {
            throw probeCorrupted(
                path: [],
                description: "A metadata collection requires exactly one entries field."
            )
        }

        var entriesContainer: UnkeyedDecodingContainer
        do {
            let entriesDecoder = try container.superDecoder(forKey: entriesKey)
            entriesContainer = try entriesDecoder.unkeyedContainer()
        } catch {
            throw probeCorrupted(
                path: [entriesKey],
                description: "A metadata collection requires an entry array."
            )
        }
        if let count = entriesContainer.count, count > maximumEntryCount {
            throw probeCorrupted(
                path: [entriesKey],
                description: "A metadata collection exceeds its entry limit.",
                underlyingError: ProbeCollectionError.entryCountLimitExceeded
            )
        }

        var entries = ContiguousArray<ProbeEntry>()
        var seenKeys = Set<ProbeKey>()
        var aggregateStructuralElements = 0
        var logicalPayloadBytes = 0
        while !entriesContainer.isAtEnd {
            guard entries.count < maximumEntryCount else {
                throw probeCorrupted(
                    path: [entriesKey],
                    description: "A metadata collection exceeds its entry limit.",
                    underlyingError: ProbeCollectionError.entryCountLimitExceeded
                )
            }

            let entry: ProbeEntry
            do {
                entry = try entriesContainer.decode(ProbeEntry.self)
            } catch {
                throw probeCorrupted(
                    path: [entriesKey],
                    description: "A metadata collection contains an invalid entry."
                )
            }

            do {
                try validate(
                    entry,
                    seenKeys: &seenKeys,
                    aggregateStructuralElements: &aggregateStructuralElements,
                    logicalPayloadBytes: &logicalPayloadBytes,
                    multiplicityPolicy: multiplicityPolicy
                )
            } catch let error as ProbeCollectionError {
                throw probeCorrupted(
                    path: [entriesKey],
                    description: "A metadata collection violates a fixed invariant.",
                    underlyingError: error
                )
            }
            entries.append(entry)
        }
        return entries
    }
}

struct ProbeCallerEnvelope: DecodableWithConfiguration {
    typealias DecodingConfiguration = ProbeMultiplicityPolicy

    init(
        from decoder: any Decoder,
        configuration: ProbeMultiplicityPolicy
    ) throws {
        let container = try decoder.container(keyedBy: ProbeCodingKey.self)
        _ = try container.decode(
            ProbeCollection.self,
            forKey: .init("patient-caller-sentinel"),
            configuration: configuration
        )
    }
}

struct ProbeCodingKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init(_ intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.init(intValue)
    }
}

func probeCorrupted(
    path: [ProbeCodingKey],
    description: String,
    underlyingError: (any Error)? = nil
) -> DecodingError {
    .dataCorrupted(
        .init(
            codingPath: path,
            debugDescription: description,
            underlyingError: underlyingError
        )
    )
}

func expectCollectionError(
    _ expected: ProbeCollectionError,
    operation: () throws -> Void
) {
    do {
        try operation()
        preconditionFailure("Accepted an invalid collection operation")
    } catch let error as ProbeCollectionError {
        precondition(error == expected)
    } catch {
        preconditionFailure("Returned the wrong collection error type")
    }
}

func expectDecodeFailure(
    _ json: String,
    expectedPath: [String]
) {
    do {
        _ = try JSONDecoder().decode(
            ProbeCollection.self,
            from: Data(json.utf8)
        )
        preconditionFailure("Accepted invalid collection JSON")
    } catch let error as DecodingError {
        guard case .dataCorrupted(let context) = error else {
            preconditionFailure("Returned the wrong decoding error kind")
        }
        precondition(context.codingPath.map(\.stringValue) == expectedPath)
    } catch {
        preconditionFailure("Returned a non-decoding error")
    }
}

func requireSendable<Value: Sendable>(_: Value.Type) {}
requireSendable(ProbeMultiplicityPolicy.self)
requireSendable(ProbeCollection.self)

let keyA = ProbeKey(namespace: "example", name: "a")
let keyB = ProbeKey(namespace: "example", name: "b")
let publicA = ProbeEntry(
    key: keyA,
    value: "one",
    privacyClass: .publicData
)
let sensitiveA = ProbeEntry(
    key: keyA,
    value: "two",
    privacyClass: .sensitive
)
let technicalA = ProbeEntry(
    key: keyA,
    value: "three",
    privacyClass: .technical
)
let potentiallyIdentifyingA = ProbeEntry(
    key: keyA,
    value: "four",
    privacyClass: .potentiallyIdentifying
)
let hostDefinedA = ProbeEntry(
    key: keyA,
    value: "five",
    privacyClass: .hostDefined
)
let technicalB = ProbeEntry(
    key: keyB,
    value: "six",
    privacyClass: .technical
)

let ordered = try ProbeCollection(entries: [publicA, technicalB])
let reversed = try ProbeCollection(entries: [technicalB, publicA])
precondition(ordered != reversed)
precondition(Set([ordered, reversed]).count == 2)

let defaultEncoded = try JSONEncoder().encode(ordered)
let defaultDecoded = try JSONDecoder().decode(
    ProbeCollection.self,
    from: defaultEncoded
)
precondition(defaultDecoded == ordered)

expectCollectionError(.duplicateKey) {
    _ = try ProbeCollection(entries: [publicA, sensitiveA])
}

let repeatA = try ProbeMultiplicityPolicy(repeatableKeys: [keyA])
let repeatedEntries = [
    publicA,
    technicalA,
    potentiallyIdentifyingA,
    sensitiveA,
    hostDefinedA,
]
let repeated = try ProbeCollection(
    entries: repeatedEntries,
    multiplicityPolicy: repeatA
)
precondition(
    repeated.entries.map(\.privacyClass) == [
        .publicData,
        .technical,
        .potentiallyIdentifying,
        .sensitive,
        .hostDefined,
    ]
)
precondition(
    Set(Mirror(reflecting: repeated).children.compactMap(\.label)) == ["entries"]
)

expectCollectionError(.multiplicityPolicyRequired) {
    _ = try JSONEncoder().encode(repeated)
}
expectCollectionError(.duplicateKey) {
    _ = try JSONEncoder().encode(
        repeated,
        configuration: .uniqueKeysOnly
    )
}

let configuredEncoder = JSONEncoder()
configuredEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
let configuredData = try configuredEncoder.encode(
    repeated,
    configuration: repeatA
)
let configuredDecoded = try JSONDecoder().decode(
    ProbeCollection.self,
    from: configuredData,
    configuration: repeatA
)
precondition(configuredDecoded == repeated)
let configuredJSON = String(decoding: configuredData, as: UTF8.self)
precondition(!configuredJSON.contains("repeatableKeys"))
precondition(!configuredJSON.contains("multiplicityPolicy"))

expectDecodeFailure(
    configuredJSON,
    expectedPath: ["entries"]
)

expectCollectionError(.duplicateKey) {
    _ = try ProbeCollection(
        entries: [technicalB, technicalB],
        multiplicityPolicy: repeatA
    )
}

let tooManyEntries = (0...6).map { index in
    ProbeEntry(
        key: ProbeKey(namespace: "n", name: String(index)),
        value: "",
        privacyClass: .technical
    )
}
expectCollectionError(.entryCountLimitExceeded) {
    _ = try ProbeCollection(entries: tooManyEntries)
}

expectCollectionError(.aggregateStructuralElementLimitExceeded) {
    _ = try ProbeCollection(entries: tooManyEntries.dropLast())
}

let oversized = ProbeEntry(
    key: ProbeKey(namespace: "n", name: "large"),
    value: String(repeating: "x", count: 65),
    privacyClass: .sensitive
)
expectCollectionError(.logicalPayloadByteLimitExceeded) {
    _ = try ProbeCollection(entries: [oversized])
}

expectCollectionError(.multiplicityPolicyLimitExceeded) {
    _ = try ProbeMultiplicityPolicy(
        repeatableKeys: tooManyEntries.map(\.key)
    )
}
expectCollectionError(.multiplicityPolicyLimitExceeded) {
    _ = try ProbeMultiplicityPolicy(
        repeatableKeys: [
            ProbeKey(
                namespace: String(repeating: "n", count: 65),
                name: "field"
            )
        ]
    )
}

expectDecodeFailure("{}", expectedPath: [])
expectDecodeFailure(#"{"entries":null}"#, expectedPath: ["entries"])
expectDecodeFailure(#"{"entries":[],"extra":true}"#, expectedPath: [])
expectDecodeFailure(#"{"entries":{}}"#, expectedPath: ["entries"])
expectDecodeFailure("[]", expectedPath: [])

let sentinelEntry =
    #"{"key":{"namespace":"patient-key-sentinel","name":"field"},"value":"patient-value-sentinel","privacyClass":"sensitive"}"#
let callerFailures = [
    (
        payload:
            #"{"patient-caller-sentinel":{"entries":[\#(sentinelEntry),\#(sentinelEntry)]}}"#,
        expectedPath: ["entries"]
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
for failure in callerFailures {
    do {
        _ = try JSONDecoder().decode(
            ProbeCallerEnvelope.self,
            from: Data(failure.payload.utf8),
            configuration: .uniqueKeysOnly
        )
        preconditionFailure("Accepted invalid nested collection JSON")
    } catch let error as DecodingError {
        let rendered = [String(describing: error), String(reflecting: error)]
        for sentinel in [
            "patient-caller-sentinel",
            "patient-key-sentinel",
            "patient-value-sentinel",
        ] {
            precondition(rendered.allSatisfy { !$0.contains(sentinel) })
        }
        guard case .dataCorrupted(let context) = error else {
            preconditionFailure("Returned the wrong nested error kind")
        }
        let actualPath = context.codingPath.map(\.stringValue)
        precondition(
            actualPath == failure.expectedPath,
            "actualPath=\(actualPath) expectedPath=\(failure.expectedPath)"
        )
        if let underlyingError = context.underlyingError {
            precondition(underlyingError is ProbeCollectionError)
        }
    }
}

print("orderedIdentity=true defaultUniqueRoundTrip=true strictInvalid=5")
print("configuredMultiplicity=true policyOnWire=false defaultDuplicate=blocked")
print("privacyAggregation=none limits=policy+entry+structure+payload")
print("callerAndMetadataText=sanitized configured=\(configuredJSON)")
