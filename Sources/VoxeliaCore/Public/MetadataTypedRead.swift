// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised by a typed metadata read.
///
/// The enum is deliberately non-generic and payload-free: cases carry no
/// key, requested or actual type, value, privacy class, match count, index,
/// order, policy or underlying error. The coarse outcome itself can still be
/// sensitive in context, so hosts must not log even a fixed case where
/// presence or cardinality is sensitive.
public enum MetadataReadError: Error, Sendable, Equatable {
    case missingValue
    case multipleValues
    case typeMismatch
}

/// One immutable classified typed read result.
///
/// The result retains the requested typed key, the exact stored payload and
/// that occurrence's exact privacy class, keeping the required declaration
/// adjacent to the value instead of creating an unclassified bare-value
/// path. It has no public initializer, so this read-only projection cannot
/// become an unreviewed typed-write path, and no `Codable`, `Hashable`,
/// textual or safe-display conformance. A successful result proves only
/// exact key and exact case; it is not read, logging, export or
/// declassification authorisation, and it must not be interpolated or
/// reflected into logs, telemetry, filenames or user interfaces.
public struct TypedMetadataEntry<Value: Sendable>: Sendable {
    /// The exact typed key the caller requested.
    public let key: MetadataKey<Value>
    /// The exact associated payload of the matched stored case.
    public let value: Value
    /// The matched occurrence's exact declared privacy class.
    public let privacyClass: MetadataPrivacyClass

    init(key: MetadataKey<Value>, value: Value, privacyClass: MetadataPrivacyClass) {
        self.key = key
        self.value = value
        self.privacyClass = privacyClass
    }
}

extension MetadataCollection {
    /// Exact ordered UTF-8 identity between a stored erased key and one
    /// requested typed key: no normalisation, case folding, aliasing or
    /// schema resolution.
    private func matchesExactly<Value>(
        _ stored: AnyMetadataKey,
        _ requested: MetadataKey<Value>
    ) -> Bool {
        stored.namespace.utf8.elementsEqual(requested.namespace.utf8)
            && stored.name.utf8.elementsEqual(requested.name.utf8)
    }

    /// The shared single-read engine: exact-key cardinality is decided
    /// before any stored value case is inspected, so duplicate order never
    /// changes the failure category.
    private func singleEntry<Value>(
        for key: MetadataKey<Value>,
        project: (MetadataValue) -> Value?
    ) throws -> TypedMetadataEntry<Value> {
        var match: MetadataEntry?
        for entry in entries where matchesExactly(entry.key, key) {
            guard match == nil else {
                throw MetadataReadError.multipleValues
            }
            match = entry
        }
        guard let match else {
            throw MetadataReadError.missingValue
        }
        guard let value = project(match.value) else {
            throw MetadataReadError.typeMismatch
        }
        return TypedMetadataEntry(
            key: key,
            value: value,
            privacyClass: match.privacyClass
        )
    }

    /// The shared plural-read engine: one complete count and case preflight
    /// pass, then one materialisation pass, so any mismatch fails
    /// atomically without publishing a valid prefix.
    private func allEntries<Value>(
        for key: MetadataKey<Value>,
        project: (MetadataValue) -> Value?
    ) throws -> ContiguousArray<TypedMetadataEntry<Value>> {
        var matchCount = 0
        for entry in entries where matchesExactly(entry.key, key) {
            guard project(entry.value) != nil else {
                throw MetadataReadError.typeMismatch
            }
            matchCount += 1
        }

        var results = ContiguousArray<TypedMetadataEntry<Value>>()
        results.reserveCapacity(matchCount)
        for entry in entries where matchesExactly(entry.key, key) {
            guard let value = project(entry.value) else {
                throw MetadataReadError.typeMismatch
            }
            results.append(
                TypedMetadataEntry(
                    key: key,
                    value: value,
                    privacyClass: entry.privacyClass
                )
            )
        }
        return results
    }

    // MARK: - Private nonthrowing exact-case projectors

    private static func booleanPayload(_ value: MetadataValue) -> Bool? {
        if case .boolean(let payload) = value { payload } else { nil }
    }

    private static func signedIntegerPayload(_ value: MetadataValue) -> Int64? {
        if case .signedInteger(let payload) = value { payload } else { nil }
    }

    private static func unsignedIntegerPayload(_ value: MetadataValue) -> UInt64? {
        if case .unsignedInteger(let payload) = value { payload } else { nil }
    }

    private static func floatingPointPayload(
        _ value: MetadataValue
    ) -> MetadataFloatingPoint? {
        if case .floatingPoint(let payload) = value { payload } else { nil }
    }

    private static func stringPayload(_ value: MetadataValue) -> String? {
        if case .string(let payload) = value { payload } else { nil }
    }

    private static func binaryPayload(_ value: MetadataValue) -> MetadataBinary? {
        if case .binary(let payload) = value { payload } else { nil }
    }

    private static func instantPayload(_ value: MetadataValue) -> CanonicalInstant? {
        if case .instant(let payload) = value { payload } else { nil }
    }

    private static func unitPayload(_ value: MetadataValue) -> MeasurementUnit? {
        if case .unit(let payload) = value { payload } else { nil }
    }

    private static func codePayload(_ value: MetadataValue) -> CodedConcept? {
        if case .code(let payload) = value { payload } else { nil }
    }

    private static func arrayPayload(_ value: MetadataValue) -> MetadataArray? {
        if case .array(let payload) = value { payload } else { nil }
    }

    private static func objectPayload(_ value: MetadataValue) -> MetadataObject? {
        if case .object(let payload) = value { payload } else { nil }
    }

    // MARK: - Closed exact-case read overloads

    /// Reads the single `boolean` entry stored for one exact key.
    public func entry(for key: MetadataKey<Bool>) throws -> TypedMetadataEntry<Bool> {
        try singleEntry(for: key, project: Self.booleanPayload)
    }

    /// Reads every ordered `boolean` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<Bool>
    ) throws -> ContiguousArray<TypedMetadataEntry<Bool>> {
        try allEntries(for: key, project: Self.booleanPayload)
    }

    /// Reads the single `signedInteger` entry stored for one exact key.
    public func entry(for key: MetadataKey<Int64>) throws -> TypedMetadataEntry<Int64> {
        try singleEntry(for: key, project: Self.signedIntegerPayload)
    }

    /// Reads every ordered `signedInteger` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<Int64>
    ) throws -> ContiguousArray<TypedMetadataEntry<Int64>> {
        try allEntries(for: key, project: Self.signedIntegerPayload)
    }

    /// Reads the single `unsignedInteger` entry stored for one exact key.
    public func entry(
        for key: MetadataKey<UInt64>
    ) throws -> TypedMetadataEntry<UInt64> {
        try singleEntry(for: key, project: Self.unsignedIntegerPayload)
    }

    /// Reads every ordered `unsignedInteger` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<UInt64>
    ) throws -> ContiguousArray<TypedMetadataEntry<UInt64>> {
        try allEntries(for: key, project: Self.unsignedIntegerPayload)
    }

    /// Reads the single `floatingPoint` entry stored for one exact key.
    public func entry(
        for key: MetadataKey<MetadataFloatingPoint>
    ) throws -> TypedMetadataEntry<MetadataFloatingPoint> {
        try singleEntry(for: key, project: Self.floatingPointPayload)
    }

    /// Reads every ordered `floatingPoint` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<MetadataFloatingPoint>
    ) throws -> ContiguousArray<TypedMetadataEntry<MetadataFloatingPoint>> {
        try allEntries(for: key, project: Self.floatingPointPayload)
    }

    /// Reads the single `string` entry stored for one exact key; instant
    /// text is never returned as a string.
    public func entry(
        for key: MetadataKey<String>
    ) throws -> TypedMetadataEntry<String> {
        try singleEntry(for: key, project: Self.stringPayload)
    }

    /// Reads every ordered `string` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<String>
    ) throws -> ContiguousArray<TypedMetadataEntry<String>> {
        try allEntries(for: key, project: Self.stringPayload)
    }

    /// Reads the single `binary` entry stored for one exact key; the owned
    /// wrapper is never bridged to `Data`.
    public func entry(
        for key: MetadataKey<MetadataBinary>
    ) throws -> TypedMetadataEntry<MetadataBinary> {
        try singleEntry(for: key, project: Self.binaryPayload)
    }

    /// Reads every ordered `binary` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<MetadataBinary>
    ) throws -> ContiguousArray<TypedMetadataEntry<MetadataBinary>> {
        try allEntries(for: key, project: Self.binaryPayload)
    }

    /// Reads the single `instant` entry stored for one exact key.
    public func entry(
        for key: MetadataKey<CanonicalInstant>
    ) throws -> TypedMetadataEntry<CanonicalInstant> {
        try singleEntry(for: key, project: Self.instantPayload)
    }

    /// Reads every ordered `instant` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<CanonicalInstant>
    ) throws -> ContiguousArray<TypedMetadataEntry<CanonicalInstant>> {
        try allEntries(for: key, project: Self.instantPayload)
    }

    /// Reads the single `unit` entry stored for one exact key.
    public func entry(
        for key: MetadataKey<MeasurementUnit>
    ) throws -> TypedMetadataEntry<MeasurementUnit> {
        try singleEntry(for: key, project: Self.unitPayload)
    }

    /// Reads every ordered `unit` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<MeasurementUnit>
    ) throws -> ContiguousArray<TypedMetadataEntry<MeasurementUnit>> {
        try allEntries(for: key, project: Self.unitPayload)
    }

    /// Reads the single `code` entry stored for one exact key.
    public func entry(
        for key: MetadataKey<CodedConcept>
    ) throws -> TypedMetadataEntry<CodedConcept> {
        try singleEntry(for: key, project: Self.codePayload)
    }

    /// Reads every ordered `code` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<CodedConcept>
    ) throws -> ContiguousArray<TypedMetadataEntry<CodedConcept>> {
        try allEntries(for: key, project: Self.codePayload)
    }

    /// Reads the single `array` entry stored for one exact key.
    public func entry(
        for key: MetadataKey<MetadataArray>
    ) throws -> TypedMetadataEntry<MetadataArray> {
        try singleEntry(for: key, project: Self.arrayPayload)
    }

    /// Reads every ordered `array` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<MetadataArray>
    ) throws -> ContiguousArray<TypedMetadataEntry<MetadataArray>> {
        try allEntries(for: key, project: Self.arrayPayload)
    }

    /// Reads the single `object` entry stored for one exact key.
    public func entry(
        for key: MetadataKey<MetadataObject>
    ) throws -> TypedMetadataEntry<MetadataObject> {
        try singleEntry(for: key, project: Self.objectPayload)
    }

    /// Reads every ordered `object` entry stored for one exact key.
    public func entries(
        for key: MetadataKey<MetadataObject>
    ) throws -> ContiguousArray<TypedMetadataEntry<MetadataObject>> {
        try allEntries(for: key, project: Self.objectPayload)
    }
}
