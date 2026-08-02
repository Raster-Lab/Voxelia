// SPDX-License-Identifier: MIT
//
// Isolated Swift 6 evidence for a candidate ADR-0034 typed-read boundary.
// These Probe* declarations are not Voxelia public API or implementation
// authorisation. Reduced nominal payloads exercise closed exact-case mapping,
// cardinality, privacy preservation, ordering and diagnostics only.

import Foundation

enum ProbePrivacyClass: String, Sendable, Hashable {
    case publicData
    case technical
    case potentiallyIdentifying
    case sensitive
    case hostDefined
}

struct ProbeKey<Value: Sendable>: Sendable, Hashable {
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

struct ProbeAnyKey: Sendable, Hashable {
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

struct ProbeFloatingPoint: Sendable, Hashable {
    let value: Double
}

struct ProbeBinary: Sendable, Hashable {
    let bytes: ContiguousArray<UInt8>
}

struct ProbeInstant: Sendable, Hashable {
    let utcString: String
}

struct ProbeUnit: Sendable, Hashable {
    let code: String
    let displayName: String
}

struct ProbeCode: Sendable, Hashable {
    let value: String
    let meaning: String
}

struct ProbeArray: Sendable, Hashable {
    let values: ContiguousArray<Int64>
}

struct ProbeObject: Sendable, Hashable {
    let memberNames: ContiguousArray<String>
}

enum ProbeValue: Sendable, Hashable {
    case boolean(Bool)
    case signedInteger(Int64)
    case unsignedInteger(UInt64)
    case floatingPoint(ProbeFloatingPoint)
    case string(String)
    case binary(ProbeBinary)
    case instant(ProbeInstant)
    case unit(ProbeUnit)
    case code(ProbeCode)
    case array(ProbeArray)
    case object(ProbeObject)
}

struct ProbeEntry: Sendable, Hashable {
    let key: ProbeAnyKey
    let value: ProbeValue
    let privacyClass: ProbePrivacyClass
}

enum ProbeMetadataReadError: Error, Sendable, Equatable {
    case missingValue
    case multipleValues
    case typeMismatch
}

struct ProbeTypedMetadataEntry<Value: Sendable>: Sendable {
    let key: ProbeKey<Value>
    let value: Value
    let privacyClass: ProbePrivacyClass
}

struct ProbeCollection: Sendable {
    let entries: ContiguousArray<ProbeEntry>

    func entry(
        for key: ProbeKey<Bool>
    ) throws -> ProbeTypedMetadataEntry<Bool> {
        try singleEntry(for: key) {
            guard case .boolean(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<Bool>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<Bool>> {
        try multipleEntries(for: key) {
            guard case .boolean(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<Int64>
    ) throws -> ProbeTypedMetadataEntry<Int64> {
        try singleEntry(for: key) {
            guard case .signedInteger(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<Int64>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<Int64>> {
        try multipleEntries(for: key) {
            guard case .signedInteger(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<UInt64>
    ) throws -> ProbeTypedMetadataEntry<UInt64> {
        try singleEntry(for: key) {
            guard case .unsignedInteger(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<UInt64>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<UInt64>> {
        try multipleEntries(for: key) {
            guard case .unsignedInteger(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<ProbeFloatingPoint>
    ) throws -> ProbeTypedMetadataEntry<ProbeFloatingPoint> {
        try singleEntry(for: key) {
            guard case .floatingPoint(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<ProbeFloatingPoint>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<ProbeFloatingPoint>> {
        try multipleEntries(for: key) {
            guard case .floatingPoint(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<String>
    ) throws -> ProbeTypedMetadataEntry<String> {
        try singleEntry(for: key) {
            guard case .string(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<String>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<String>> {
        try multipleEntries(for: key) {
            guard case .string(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<ProbeBinary>
    ) throws -> ProbeTypedMetadataEntry<ProbeBinary> {
        try singleEntry(for: key) {
            guard case .binary(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<ProbeBinary>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<ProbeBinary>> {
        try multipleEntries(for: key) {
            guard case .binary(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<ProbeInstant>
    ) throws -> ProbeTypedMetadataEntry<ProbeInstant> {
        try singleEntry(for: key) {
            guard case .instant(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<ProbeInstant>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<ProbeInstant>> {
        try multipleEntries(for: key) {
            guard case .instant(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<ProbeUnit>
    ) throws -> ProbeTypedMetadataEntry<ProbeUnit> {
        try singleEntry(for: key) {
            guard case .unit(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<ProbeUnit>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<ProbeUnit>> {
        try multipleEntries(for: key) {
            guard case .unit(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<ProbeCode>
    ) throws -> ProbeTypedMetadataEntry<ProbeCode> {
        try singleEntry(for: key) {
            guard case .code(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<ProbeCode>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<ProbeCode>> {
        try multipleEntries(for: key) {
            guard case .code(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<ProbeArray>
    ) throws -> ProbeTypedMetadataEntry<ProbeArray> {
        try singleEntry(for: key) {
            guard case .array(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<ProbeArray>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<ProbeArray>> {
        try multipleEntries(for: key) {
            guard case .array(let value) = $0 else { return nil }
            return value
        }
    }

    func entry(
        for key: ProbeKey<ProbeObject>
    ) throws -> ProbeTypedMetadataEntry<ProbeObject> {
        try singleEntry(for: key) {
            guard case .object(let value) = $0 else { return nil }
            return value
        }
    }

    func entries(
        for key: ProbeKey<ProbeObject>
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<ProbeObject>> {
        try multipleEntries(for: key) {
            guard case .object(let value) = $0 else { return nil }
            return value
        }
    }

    private func singleEntry<Value: Sendable>(
        for key: ProbeKey<Value>,
        extract: (ProbeValue) -> Value?
    ) throws -> ProbeTypedMetadataEntry<Value> {
        var firstMatch: ProbeEntry?
        var matchCount = 0
        for candidate in entries where Self.keysMatch(candidate.key, key) {
            matchCount += 1
            if firstMatch == nil {
                firstMatch = candidate
            }
        }

        guard matchCount > 0, let firstMatch else {
            throw ProbeMetadataReadError.missingValue
        }
        guard matchCount == 1 else {
            throw ProbeMetadataReadError.multipleValues
        }
        guard let value = extract(firstMatch.value) else {
            throw ProbeMetadataReadError.typeMismatch
        }
        return ProbeTypedMetadataEntry(
            key: key,
            value: value,
            privacyClass: firstMatch.privacyClass
        )
    }

    private func multipleEntries<Value: Sendable>(
        for key: ProbeKey<Value>,
        extract: (ProbeValue) -> Value?
    ) throws -> ContiguousArray<ProbeTypedMetadataEntry<Value>> {
        var matchCount = 0
        var hasTypeMismatch = false
        for candidate in entries where Self.keysMatch(candidate.key, key) {
            matchCount += 1
            if extract(candidate.value) == nil {
                hasTypeMismatch = true
            }
        }
        guard !hasTypeMismatch else {
            throw ProbeMetadataReadError.typeMismatch
        }

        var result = ContiguousArray<ProbeTypedMetadataEntry<Value>>()
        result.reserveCapacity(matchCount)
        for candidate in entries where Self.keysMatch(candidate.key, key) {
            guard let value = extract(candidate.value) else {
                throw ProbeMetadataReadError.typeMismatch
            }
            result.append(
                ProbeTypedMetadataEntry(
                    key: key,
                    value: value,
                    privacyClass: candidate.privacyClass
                )
            )
        }
        return result
    }

    private static func keysMatch<Value: Sendable>(
        _ stored: ProbeAnyKey,
        _ requested: ProbeKey<Value>
    ) -> Bool {
        stored.namespace.utf8.elementsEqual(requested.namespace.utf8)
            && stored.name.utf8.elementsEqual(requested.name.utf8)
    }
}

func storedKey<Value: Sendable>(_ key: ProbeKey<Value>) -> ProbeAnyKey {
    ProbeAnyKey(namespace: key.namespace, name: key.name)
}

func expectReadError(
    _ expected: ProbeMetadataReadError,
    forbiddenText: [String],
    operation: () throws -> Void
) {
    do {
        try operation()
        preconditionFailure("Accepted an invalid typed metadata read")
    } catch let error as ProbeMetadataReadError {
        precondition(error == expected)
        let rendered = [String(describing: error), String(reflecting: error)]
        for text in forbiddenText {
            precondition(rendered.allSatisfy { !$0.contains(text) })
        }
    } catch {
        preconditionFailure("Returned the wrong typed metadata error")
    }
}

func requireSendable<Value: Sendable>(_: Value.Type) {}
requireSendable(ProbeMetadataReadError.self)
requireSendable(ProbeTypedMetadataEntry<String>.self)
requireSendable(ProbeCollection.self)

let boolKey = ProbeKey<Bool>(namespace: "example", name: "bool")
let signedKey = ProbeKey<Int64>(namespace: "example", name: "signed")
let unsignedKey = ProbeKey<UInt64>(namespace: "example", name: "unsigned")
let floatingKey = ProbeKey<ProbeFloatingPoint>(namespace: "example", name: "floating")
let stringKey = ProbeKey<String>(namespace: "example", name: "string")
let binaryKey = ProbeKey<ProbeBinary>(namespace: "example", name: "binary")
let instantKey = ProbeKey<ProbeInstant>(namespace: "example", name: "instant")
let unitKey = ProbeKey<ProbeUnit>(namespace: "example", name: "unit")
let codeKey = ProbeKey<ProbeCode>(namespace: "example", name: "code")
let arrayKey = ProbeKey<ProbeArray>(namespace: "example", name: "array")
let objectKey = ProbeKey<ProbeObject>(namespace: "example", name: "object")

let floating = ProbeFloatingPoint(value: 1.25)
let binary = ProbeBinary(bytes: [0x00, 0xFF])
let instant = ProbeInstant(utcString: "2026-08-03T00:00:00Z")
let exactStringPayload = "patient-value-e\u{301}-sentinel"
let canonicalizedStringPayload = "patient-value-\u{00E9}-sentinel"
precondition(exactStringPayload == canonicalizedStringPayload)
precondition(!exactStringPayload.utf8.elementsEqual(canonicalizedStringPayload.utf8))
let unit = ProbeUnit(code: "mm", displayName: "millimetre-presentation-sentinel")
let code = ProbeCode(value: "A", meaning: "concept-presentation-sentinel")
let array = ProbeArray(values: [1, 2])
let object = ProbeObject(memberNames: ["field"])

let exactCollection = ProbeCollection(
    entries: [
        ProbeEntry(key: storedKey(boolKey), value: .boolean(true), privacyClass: .publicData),
        ProbeEntry(
            key: storedKey(signedKey),
            value: .signedInteger(-2),
            privacyClass: .technical
        ),
        ProbeEntry(
            key: storedKey(unsignedKey),
            value: .unsignedInteger(3),
            privacyClass: .potentiallyIdentifying
        ),
        ProbeEntry(
            key: storedKey(floatingKey),
            value: .floatingPoint(floating),
            privacyClass: .sensitive
        ),
        ProbeEntry(
            key: storedKey(stringKey),
            value: .string(exactStringPayload),
            privacyClass: .hostDefined
        ),
        ProbeEntry(key: storedKey(binaryKey), value: .binary(binary), privacyClass: .technical),
        ProbeEntry(
            key: storedKey(instantKey),
            value: .instant(instant),
            privacyClass: .technical
        ),
        ProbeEntry(key: storedKey(unitKey), value: .unit(unit), privacyClass: .technical),
        ProbeEntry(key: storedKey(codeKey), value: .code(code), privacyClass: .technical),
        ProbeEntry(key: storedKey(arrayKey), value: .array(array), privacyClass: .technical),
        ProbeEntry(key: storedKey(objectKey), value: .object(object), privacyClass: .technical),
    ]
)

let boolEntry: ProbeTypedMetadataEntry<Bool> = try exactCollection.entry(for: boolKey)
let signedEntry: ProbeTypedMetadataEntry<Int64> = try exactCollection.entry(for: signedKey)
let unsignedEntry: ProbeTypedMetadataEntry<UInt64> = try exactCollection.entry(for: unsignedKey)
let floatingEntry: ProbeTypedMetadataEntry<ProbeFloatingPoint> =
    try exactCollection.entry(for: floatingKey)
let stringEntry: ProbeTypedMetadataEntry<String> = try exactCollection.entry(for: stringKey)
let binaryEntry: ProbeTypedMetadataEntry<ProbeBinary> = try exactCollection.entry(for: binaryKey)
let instantEntry: ProbeTypedMetadataEntry<ProbeInstant> = try exactCollection.entry(for: instantKey)
let unitEntry: ProbeTypedMetadataEntry<ProbeUnit> = try exactCollection.entry(for: unitKey)
let codeEntry: ProbeTypedMetadataEntry<ProbeCode> = try exactCollection.entry(for: codeKey)
let arrayEntry: ProbeTypedMetadataEntry<ProbeArray> = try exactCollection.entry(for: arrayKey)
let objectEntry: ProbeTypedMetadataEntry<ProbeObject> = try exactCollection.entry(for: objectKey)

precondition(boolEntry.value)
precondition(signedEntry.value == -2)
precondition(unsignedEntry.value == 3)
precondition(floatingEntry.value == floating)
precondition(stringEntry.value.utf8.elementsEqual(exactStringPayload.utf8))
precondition(!stringEntry.value.utf8.elementsEqual(canonicalizedStringPayload.utf8))
precondition(binaryEntry.value == binary)
precondition(instantEntry.value == instant)
precondition(unitEntry.value == unit)
precondition(codeEntry.value == code)
precondition(unitEntry.value.code == "mm")
precondition(unitEntry.value.displayName == "millimetre-presentation-sentinel")
precondition(codeEntry.value.value == "A")
precondition(codeEntry.value.meaning == "concept-presentation-sentinel")
precondition(arrayEntry.value == array)
precondition(objectEntry.value == object)
precondition(stringEntry.key == stringKey)
precondition(stringEntry.privacyClass == .hostDefined)

let boolEntries = try exactCollection.entries(for: boolKey)
let signedEntries = try exactCollection.entries(for: signedKey)
let unsignedEntries = try exactCollection.entries(for: unsignedKey)
let floatingEntries = try exactCollection.entries(for: floatingKey)
let stringEntries = try exactCollection.entries(for: stringKey)
let binaryEntries = try exactCollection.entries(for: binaryKey)
let instantEntries = try exactCollection.entries(for: instantKey)
let unitEntries = try exactCollection.entries(for: unitKey)
let codeEntries = try exactCollection.entries(for: codeKey)
let arrayEntries = try exactCollection.entries(for: arrayKey)
let objectEntries = try exactCollection.entries(for: objectKey)
precondition(boolEntries.map(\.value) == [true])
precondition(signedEntries.map(\.value) == [-2])
precondition(unsignedEntries.map(\.value) == [3])
precondition(floatingEntries.map(\.value) == [floating])
precondition(stringEntries.count == 1)
precondition(stringEntries[0].value.utf8.elementsEqual(exactStringPayload.utf8))
precondition(binaryEntries.map(\.value) == [binary])
precondition(instantEntries.map(\.value) == [instant])
precondition(unitEntries.map(\.value) == [unit])
precondition(codeEntries.map(\.value) == [code])
precondition(arrayEntries.map(\.value) == [array])
precondition(objectEntries.map(\.value) == [object])

let repeatedKey = ProbeKey<String>(namespace: "example", name: "repeated")
let repeatedStoredKey = storedKey(repeatedKey)
let repeatedClasses: [ProbePrivacyClass] = [
    .publicData,
    .technical,
    .potentiallyIdentifying,
    .sensitive,
    .hostDefined,
]
let repeatedValues = ["one", "two", "three", "four", "five"]
let repeatedCollection = ProbeCollection(
    entries: ContiguousArray(
        zip(repeatedValues, repeatedClasses).map { value, privacyClass in
            ProbeEntry(
                key: repeatedStoredKey,
                value: .string(value),
                privacyClass: privacyClass
            )
        }
    )
)
let repeatedEntries = try repeatedCollection.entries(for: repeatedKey)
precondition(repeatedEntries.map(\.value) == repeatedValues)
precondition(repeatedEntries.map(\.privacyClass) == repeatedClasses)
precondition(repeatedEntries.allSatisfy { $0.key == repeatedKey })

let missingKey = ProbeKey<String>(
    namespace: "patient-key-sentinel",
    name: "missing"
)
expectReadError(
    .missingValue,
    forbiddenText: ["patient-key-sentinel", "String", "hostDefined", "0"]
) {
    _ = try exactCollection.entry(for: missingKey)
}
let missingPlural = try exactCollection.entries(for: missingKey)
precondition(missingPlural.isEmpty)

expectReadError(
    .multipleValues,
    forbiddenText: ["repeated", "String", "hostDefined", "5"]
) {
    _ = try repeatedCollection.entry(for: repeatedKey)
}

let mismatchStoredKey = ProbeAnyKey(
    namespace: "patient-key-sentinel",
    name: "mismatch"
)
let mismatchKey = ProbeKey<String>(
    namespace: mismatchStoredKey.namespace,
    name: mismatchStoredKey.name
)
let mismatchCollection = ProbeCollection(
    entries: [
        ProbeEntry(
            key: mismatchStoredKey,
            value: .boolean(true),
            privacyClass: .sensitive
        )
    ]
)
expectReadError(
    .typeMismatch,
    forbiddenText: ["patient-key-sentinel", "String", "boolean", "sensitive", "true"]
) {
    _ = try mismatchCollection.entry(for: mismatchKey)
}
expectReadError(
    .typeMismatch,
    forbiddenText: ["patient-key-sentinel", "String", "boolean", "sensitive", "true"]
) {
    _ = try mismatchCollection.entries(for: mismatchKey)
}

let mixedDuplicateCollection = ProbeCollection(
    entries: [
        ProbeEntry(
            key: repeatedStoredKey,
            value: .string("valid-prefix-sentinel"),
            privacyClass: .sensitive
        ),
        ProbeEntry(key: repeatedStoredKey, value: .boolean(true), privacyClass: .publicData),
    ]
)
expectReadError(
    .multipleValues,
    forbiddenText: ["repeated", "String", "boolean", "2"]
) {
    _ = try mixedDuplicateCollection.entry(for: repeatedKey)
}
expectReadError(
    .typeMismatch,
    forbiddenText: ["repeated", "String", "boolean", "valid-prefix-sentinel", "2"]
) {
    _ = try mixedDuplicateCollection.entries(for: repeatedKey)
}

let composedKey = ProbeKey<String>(
    namespace: "org.voxelia.m\u{00E9}tadata",
    name: "valu\u{00E9}"
)
let decomposedKey = ProbeKey<String>(
    namespace: "org.voxelia.me\u{301}tadata",
    name: "value\u{301}"
)
precondition(composedKey.namespace == decomposedKey.namespace)
precondition(composedKey.name == decomposedKey.name)
let exactUTF8Collection = ProbeCollection(
    entries: [
        ProbeEntry(
            key: storedKey(composedKey),
            value: .string("exact"),
            privacyClass: .technical
        )
    ]
)
let exactUTF8Entry = try exactUTF8Collection.entry(for: composedKey)
precondition(exactUTF8Entry.value == "exact")

let namespaceOnlyDecomposedKey = ProbeKey<String>(
    namespace: decomposedKey.namespace,
    name: composedKey.name
)
expectReadError(
    .missingValue,
    forbiddenText: [namespaceOnlyDecomposedKey.namespace, namespaceOnlyDecomposedKey.name]
) {
    _ = try exactUTF8Collection.entry(for: namespaceOnlyDecomposedKey)
}

let nameOnlyDecomposedKey = ProbeKey<String>(
    namespace: composedKey.namespace,
    name: decomposedKey.name
)
expectReadError(
    .missingValue,
    forbiddenText: [nameOnlyDecomposedKey.namespace, nameOnlyDecomposedKey.name]
) {
    _ = try exactUTF8Collection.entry(for: nameOnlyDecomposedKey)
}

// This conditional negative probe must fail type checking: Double remains a
// constructible key specialization but has no exact-case typed-read overload.
#if ADR0034_UNSUPPORTED_MAPPING_SHOULD_FAIL
    let unsupportedDoubleKey = ProbeKey<Double>(namespace: "example", name: "floating")
    _ = try exactCollection.entry(for: unsupportedDoubleKey)
#endif

print("closedExactMappings=11 singleAndPlural=true")
print("privacyFields=key+value+class allFiveClasses=true hostDefined=unresolved")
print("cardinality=missing+multiple+typeMismatch precedence=cardinality-first")
print("pluralOrder=preserved pluralMissing=empty pluralMismatch=atomic")
print("exactUTF8Lookup=true diagnostics=sanitized unsupportedMapping=compile-time")
