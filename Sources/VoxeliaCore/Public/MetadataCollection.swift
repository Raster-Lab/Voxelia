// SPDX-License-Identifier: MIT

import Foundation

/// An error raised while validating a metadata collection or its
/// multiplicity policy.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// metadata keys, values, privacy classes, policy contents, entry counts,
/// indices or collection structure.
public enum MetadataCollectionError: Error, Sendable, Equatable {
    case duplicateKey
    case multiplicityPolicyRequired
    case multiplicityPolicyLimitExceeded
    case entryCountLimitExceeded
    case aggregateStructuralElementLimitExceeded
    case aggregateLogicalPayloadByteLimitExceeded
}

/// A bounded, immutable exact-key allow-list admitting repeated collection
/// keys.
///
/// The policy is an explicit caller assertion that the host or adapter has
/// already performed whatever external schema selection the candidate
/// operation requires. It is not itself that schema: it carries no schema
/// identity, authenticates no caller and grants no logging, export or
/// privacy permission. It is never stored in a collection, never appears on
/// the wire and must never be derived from the bytes being decoded.
public struct MetadataMultiplicityPolicy: Sendable {
    /// The context-free default: every exact key is unique-only.
    public static let uniqueKeysOnly = MetadataMultiplicityPolicy()

    private let repeatableKeys: Set<AnyMetadataKey>

    /// The unique-key count retained after normalisation. Derived state:
    /// it never participates in identity and never replaces the
    /// constructor's pre-normalisation hard-limit checks.
    let retainedKeyCount: UInt64
    /// The checked namespace/name UTF-8 byte sum retained after
    /// normalisation. Derived state under the same rules.
    let retainedLogicalKeyByteCount: UInt64

    private init() {
        self.repeatableKeys = []
        self.retainedKeyCount = 0
        self.retainedLogicalKeyByteCount = 0
    }

    /// Creates a bounded allow-list from any key collection.
    ///
    /// Every supplied occurrence is charged against the policy key-count
    /// and key-byte ceilings before deduplication, so repeated source keys
    /// cannot smuggle an unbounded submission past the limits.
    ///
    /// - Throws: ``MetadataCollectionError/multiplicityPolicyLimitExceeded``
    ///   when a supplied ceiling is exceeded or the checked byte sum
    ///   overflows.
    public init<Keys: Collection>(repeatableKeys: Keys) throws
    where Keys.Element == AnyMetadataKey {
        guard
            UInt64(repeatableKeys.count)
                <= MetadataCollection.maximumMultiplicityPolicyKeyCount
        else {
            throw MetadataCollectionError.multiplicityPolicyLimitExceeded
        }

        var suppliedBytes: UInt64 = 0
        for key in repeatableKeys {
            suppliedBytes = try Self.addingPolicyBytes(
                suppliedBytes,
                UInt64(key.namespace.utf8.count) &+ UInt64(key.name.utf8.count)
            )
            guard
                suppliedBytes
                    <= MetadataCollection.maximumMultiplicityPolicyLogicalKeyByteCount
            else {
                throw MetadataCollectionError.multiplicityPolicyLimitExceeded
            }
        }

        let normalised = Set(repeatableKeys)
        var retainedBytes: UInt64 = 0
        for key in normalised {
            retainedBytes = try Self.addingPolicyBytes(
                retainedBytes,
                UInt64(key.namespace.utf8.count) &+ UInt64(key.name.utf8.count)
            )
        }

        self.repeatableKeys = normalised
        self.retainedKeyCount = UInt64(normalised.count)
        self.retainedLogicalKeyByteCount = retainedBytes
    }

    /// Whether repeated occurrences of one exact key are admitted.
    func permitsRepeats(of key: AnyMetadataKey) -> Bool {
        repeatableKeys.contains(key)
    }

    private static func addingPolicyBytes(
        _ total: UInt64,
        _ addition: UInt64
    ) throws -> UInt64 {
        let (sum, overflow) = total.addingReportingOverflow(addition)
        guard !overflow else {
            throw MetadataCollectionError.multiplicityPolicyLimitExceeded
        }
        return sum
    }
}

/// An ordered, immutable sequence of classified general metadata entries.
///
/// Construction preserves every entry in exact input order and never
/// sorts, groups, flattens, deduplicates or rewrites entries. Ordinary
/// construction and coding are unique-only by exact key; repeated keys
/// require an explicit ``MetadataMultiplicityPolicy`` at the initializer or
/// the configured coding call site. Equality and hashing compare the
/// complete ordered entry sequence; the admission policy is deliberately
/// not stored, so equality proves equal ordered content, not validity
/// under a different policy. `Hashable` is semantic in-memory identity,
/// not canonical record equality or a persistent digest. Collections may
/// contain sensitive metadata and must not be interpolated or reflected
/// into logs, telemetry, filenames or user interfaces.
public struct MetadataCollection: Sendable, Hashable, Codable, CodableWithConfiguration {
    public typealias EncodingConfiguration = MetadataMultiplicityPolicy
    public typealias DecodingConfiguration = MetadataMultiplicityPolicy

    /// The hard version-one entry-count ceiling.
    public static let maximumEntryCount: UInt64 = 1_048_576
    /// The hard version-one aggregate logical structural-element ceiling.
    public static let maximumAggregateStructuralElementCount: UInt64 = 1_048_576
    /// The hard version-one aggregate logical variable-payload ceiling.
    public static let maximumAggregateLogicalVariablePayloadByteCount: UInt64 = 67_108_864
    /// The hard version-one supplied multiplicity-policy key ceiling.
    public static let maximumMultiplicityPolicyKeyCount: UInt64 = 1_048_576
    /// The hard version-one supplied multiplicity-policy key-byte ceiling.
    public static let maximumMultiplicityPolicyLogicalKeyByteCount: UInt64 = 67_108_864

    /// The entries in exact semantic input order.
    public let entries: ContiguousArray<MetadataEntry>

    /// Creates a unique-only collection from any entry collection.
    ///
    /// - Throws: ``MetadataCollectionError`` when a second occurrence of an
    ///   exact key appears or a hard ceiling would be exceeded.
    public init<Entries: Collection>(entries: Entries) throws
    where Entries.Element == MetadataEntry {
        self.entries = try Self.validatedEntries(entries, policy: .uniqueKeysOnly)
    }

    /// Creates a collection admitting repeats of exactly the allow-listed
    /// keys.
    ///
    /// Every admitted occurrence is retained in input order, including
    /// entries whose values or privacy classes differ. The policy cannot
    /// select first or last occurrences, change order, coerce a value,
    /// resolve `hostDefined` or combine privacy classes.
    ///
    /// - Throws: ``MetadataCollectionError`` when a repeated key is not
    ///   allow-listed or a hard ceiling would be exceeded.
    public init<Entries: Collection>(
        entries: Entries,
        multiplicityPolicy: MetadataMultiplicityPolicy
    ) throws where Entries.Element == MetadataEntry {
        self.entries = try Self.validatedEntries(entries, policy: multiplicityPolicy)
    }
}

extension MetadataCollection {
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

    /// Shared checked admission accounting for construction, decoding and
    /// encoding preflight. Charges entry, aggregate-element and
    /// aggregate-payload budgets before each occurrence is accepted and
    /// applies exact-key duplicate admission after the resource charges.
    private struct AggregateAccounting {
        var seenKeys = Set<AnyMetadataKey>()
        var entryCount: UInt64 = 0
        var elements: UInt64 = 0
        var payload: UInt64 = 0

        var remainingElements: UInt64 {
            MetadataCollection.maximumAggregateStructuralElementCount - elements
        }

        var remainingPayload: UInt64 {
            MetadataCollection.maximumAggregateLogicalVariablePayloadByteCount - payload
        }

        mutating func charge(
            _ entry: MetadataEntry,
            policy: MetadataMultiplicityPolicy
        ) throws {
            entryCount += 1
            guard entryCount <= MetadataCollection.maximumEntryCount else {
                throw MetadataCollectionError.entryCountLimitExceeded
            }

            let metrics = entry.value.metrics
            elements = try MetadataCollection.addingAggregateElements(
                elements,
                metrics.elements
            )
            guard
                elements <= MetadataCollection.maximumAggregateStructuralElementCount
            else {
                throw MetadataCollectionError.aggregateStructuralElementLimitExceeded
            }

            payload = try MetadataCollection.addingAggregatePayload(
                payload,
                metrics.payload
                    &+ UInt64(entry.key.namespace.utf8.count)
                    &+ UInt64(entry.key.name.utf8.count)
            )
            guard
                payload
                    <= MetadataCollection.maximumAggregateLogicalVariablePayloadByteCount
            else {
                throw MetadataCollectionError.aggregateLogicalPayloadByteLimitExceeded
            }

            if !seenKeys.insert(entry.key).inserted,
                !policy.permitsRepeats(of: entry.key)
            {
                throw MetadataCollectionError.duplicateKey
            }
        }
    }

    private static func addingAggregateElements(
        _ total: UInt64,
        _ addition: UInt64
    ) throws -> UInt64 {
        let (sum, overflow) = total.addingReportingOverflow(addition)
        guard !overflow else {
            throw MetadataCollectionError.aggregateStructuralElementLimitExceeded
        }
        return sum
    }

    private static func addingAggregatePayload(
        _ total: UInt64,
        _ addition: UInt64
    ) throws -> UInt64 {
        let (sum, overflow) = total.addingReportingOverflow(addition)
        guard !overflow else {
            throw MetadataCollectionError.aggregateLogicalPayloadByteLimitExceeded
        }
        return sum
    }

    /// Validates one candidate sequence under one policy, preflighting the
    /// available source count before reserving storage.
    private static func validatedEntries<Entries: Collection>(
        _ entries: Entries,
        policy: MetadataMultiplicityPolicy
    ) throws -> ContiguousArray<MetadataEntry>
    where Entries.Element == MetadataEntry {
        guard UInt64(entries.count) <= maximumEntryCount else {
            throw MetadataCollectionError.entryCountLimitExceeded
        }

        var storage = ContiguousArray<MetadataEntry>()
        storage.reserveCapacity(entries.count)
        var accounting = AggregateAccounting()
        accounting.seenKeys.reserveCapacity(entries.count)
        for entry in entries {
            try accounting.charge(entry, policy: policy)
            storage.append(entry)
        }
        return storage
    }

    /// A value-redacted collection failure whose model-relative context
    /// names at most the fixed `entries` field and never copies a
    /// caller-supplied coding path.
    private static func collectionDecodingFailure(
        field: String? = nil,
        _ description: String,
        underlying: (any Error)? = nil
    ) -> DecodingError {
        .dataCorrupted(
            DecodingError.Context(
                codingPath: field.map { [ArbitraryCodingKey($0)] } ?? [],
                debugDescription: description,
                underlyingError: underlying
            )
        )
    }

    /// Retains only an audited payload-free project error from a child
    /// failure; arbitrary Foundation, adapter or decoder errors are
    /// dropped because they may reflect source text.
    private static func auditedUnderlyingError(_ error: any Error) -> (any Error)? {
        if let projectError = error as? MetadataCollectionError {
            return projectError
        }
        if let projectError = error as? MetadataValueError {
            return projectError
        }
        if let projectError = error as? MetadataKeyError {
            return projectError
        }
        if case DecodingError.dataCorrupted(let context) = error,
            let underlying = context.underlyingError
        {
            if let projectError = underlying as? MetadataCollectionError {
                return projectError
            }
            if let projectError = underlying as? MetadataValueError {
                return projectError
            }
            if let projectError = underlying as? MetadataKeyError {
                return projectError
            }
        }
        return nil
    }

    /// Decodes the strict one-field representation with the context-free
    /// unique-only policy.
    public init(from decoder: any Decoder) throws {
        try self.init(from: decoder, configuration: .uniqueKeysOnly)
    }

    /// Decodes the strict one-field representation, admitting repeats of
    /// exactly the keys allow-listed by the caller-supplied policy.
    ///
    /// Decoding prechecks an advertised entry count, charges the aggregate
    /// budgets incrementally and threads the remaining element and payload
    /// budgets into recursive value decoding, so an over-budget document is
    /// rejected during descent rather than after full materialisation.
    public init(
        from decoder: any Decoder,
        configuration: MetadataMultiplicityPolicy
    ) throws {
        let container: KeyedDecodingContainer<ArbitraryCodingKey>
        do {
            container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        } catch {
            throw Self.collectionDecodingFailure(
                "Expected a one-field metadata collection."
            )
        }
        guard
            container.allKeys.count == 1,
            container.allKeys.first?.stringValue == "entries"
        else {
            throw Self.collectionDecodingFailure(
                "Expected a one-field metadata collection."
            )
        }

        var unkeyed: UnkeyedDecodingContainer
        do {
            unkeyed = try container.nestedUnkeyedContainer(
                forKey: ArbitraryCodingKey("entries")
            )
        } catch {
            throw Self.collectionDecodingFailure(
                field: "entries",
                "The metadata collection entries are invalid."
            )
        }

        if let advertised = unkeyed.count, UInt64(advertised) > Self.maximumEntryCount {
            throw Self.collectionDecodingFailure(
                field: "entries",
                "The metadata collection violates a collection invariant.",
                underlying: MetadataCollectionError.entryCountLimitExceeded
            )
        }

        var storage = ContiguousArray<MetadataEntry>()
        if let advertised = unkeyed.count {
            storage.reserveCapacity(advertised)
        }
        var accounting = AggregateAccounting()
        do {
            while !unkeyed.isAtEnd {
                let remainingElements = accounting.remainingElements
                let remainingPayload = accounting.remainingPayload
                let entry = try MetadataValue.$decodeAggregateElementCeiling.withValue(
                    remainingElements
                ) {
                    try MetadataValue.$decodeAggregatePayloadCeiling.withValue(
                        remainingPayload
                    ) {
                        try unkeyed.decode(MetadataEntry.self)
                    }
                }
                try accounting.charge(entry, policy: configuration)
                storage.append(entry)
            }
        } catch let error as MetadataCollectionError {
            throw Self.collectionDecodingFailure(
                field: "entries",
                "The metadata collection violates a collection invariant.",
                underlying: error
            )
        } catch {
            throw Self.collectionDecodingFailure(
                field: "entries",
                "The metadata collection entries are invalid.",
                underlying: Self.auditedUnderlyingError(error)
            )
        }

        self.entries = storage
    }

    /// Encodes the strict one-field representation after a complete
    /// unique-only preflight.
    ///
    /// A collection holding policy-admitted repeats has no context-free
    /// ordinary encoding: the preflight throws
    /// ``MetadataCollectionError/multiplicityPolicyRequired`` before an
    /// encoder container is requested, and the configured path must be
    /// used instead.
    public func encode(to encoder: any Encoder) throws {
        do {
            _ = try Self.validatedEntries(entries, policy: .uniqueKeysOnly)
        } catch MetadataCollectionError.duplicateKey {
            throw MetadataCollectionError.multiplicityPolicyRequired
        }
        try encodeValidatedRepresentation(to: encoder)
    }

    /// Encodes the strict one-field representation after a complete
    /// preflight under exactly the supplied policy.
    ///
    /// The preflight prevents a collection admitted under one snapshot from
    /// being encoded under a stale or narrower snapshot; the policy itself
    /// is never serialised.
    public func encode(
        to encoder: any Encoder,
        configuration: MetadataMultiplicityPolicy
    ) throws {
        _ = try Self.validatedEntries(entries, policy: configuration)
        try encodeValidatedRepresentation(to: encoder)
    }

    /// Writes the already preflighted one-field object. Model-originated
    /// encoding never reflects `self`, an entry, key or payload into an
    /// error.
    private func encodeValidatedRepresentation(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
        try container.encode(entries, forKey: ArbitraryCodingKey("entries"))
    }
}
