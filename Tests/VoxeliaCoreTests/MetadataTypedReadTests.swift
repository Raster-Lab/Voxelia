// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("MetadataTypedRead")
struct MetadataTypedReadTests {
    private func anyKey(_ namespace: String, _ name: String) throws -> AnyMetadataKey {
        try AnyMetadataKey(namespace: namespace, name: name)
    }

    private func entry(
        _ namespace: String,
        _ name: String,
        value: MetadataValue,
        privacyClass: MetadataPrivacyClass = .technical
    ) throws -> MetadataEntry {
        MetadataEntry(
            key: try anyKey(namespace, name),
            value: value,
            privacyClass: privacyClass
        )
    }

    @Test("[Unit][CDMS-34.7][VOX-META-001] all eleven mappings extract exactly")
    func allElevenMappingsExtractExactly() throws {
        let floating = try MetadataFloatingPoint(value: 1.5)
        let binary = MetadataBinary(bytes: [0x00, 0xFF] as [UInt8])
        let instant = try CanonicalInstant(utcString: "2026-08-04T00:00:00Z")
        let unit = try MeasurementUnit(namespace: "UCUM", code: "mm")
        let code = try CodedConcept(scheme: "scheme", value: "value")
        let array = try MetadataArray(values: [.boolean(true), .string("a")])
        let object = try MetadataObject(members: [
            .init(key: try anyKey("inner", "member"), value: .boolean(false))
        ])

        let collection = try MetadataCollection(entries: [
            try entry("t", "boolean", value: .boolean(true)),
            try entry("t", "signed", value: .signedInteger(Int64.min)),
            try entry("t", "unsigned", value: .unsignedInteger(UInt64.max)),
            try entry("t", "floating", value: .floatingPoint(floating)),
            try entry("t", "string", value: .string("caf\u{E9}")),
            try entry("t", "binary", value: .binary(binary)),
            try entry("t", "instant", value: .instant(instant)),
            try entry("t", "unit", value: .unit(unit)),
            try entry("t", "code", value: .code(code)),
            try entry("t", "array", value: .array(array)),
            try entry("t", "object", value: .object(object), privacyClass: .sensitive),
        ])

        // Every row of the closed table resolves and extracts the exact
        // associated payload under both read families.
        #expect(
            try collection.entry(for: MetadataKey<Bool>(namespace: "t", name: "boolean"))
                .value == true
        )
        #expect(
            try collection.entry(for: MetadataKey<Int64>(namespace: "t", name: "signed"))
                .value == Int64.min
        )
        #expect(
            try collection.entry(
                for: MetadataKey<UInt64>(namespace: "t", name: "unsigned")
            ).value == UInt64.max
        )
        #expect(
            try collection.entry(
                for: MetadataKey<MetadataFloatingPoint>(namespace: "t", name: "floating")
            ).value == floating
        )
        #expect(
            try collection.entry(for: MetadataKey<String>(namespace: "t", name: "string"))
                .value == "caf\u{E9}"
        )
        #expect(
            try collection.entry(
                for: MetadataKey<MetadataBinary>(namespace: "t", name: "binary")
            ).value == binary
        )
        #expect(
            try collection.entry(
                for: MetadataKey<CanonicalInstant>(namespace: "t", name: "instant")
            ).value == instant
        )
        #expect(
            try collection.entry(
                for: MetadataKey<MeasurementUnit>(namespace: "t", name: "unit")
            ).value == unit
        )
        #expect(
            try collection.entry(
                for: MetadataKey<CodedConcept>(namespace: "t", name: "code")
            ).value == code
        )
        #expect(
            try collection.entry(
                for: MetadataKey<MetadataArray>(namespace: "t", name: "array")
            ).value == array
        )

        // The result retains the typed key, exact payload and that
        // occurrence's exact privacy class.
        let objectKey = try MetadataKey<MetadataObject>(namespace: "t", name: "object")
        let typed = try collection.entry(for: objectKey)
        #expect(typed.key == objectKey)
        #expect(typed.value == object)
        #expect(typed.privacyClass == .sensitive)

        let plural = try collection.entries(for: objectKey)
        #expect(plural.count == 1)
        #expect(plural[0].value == object)

        requireSendable(MetadataReadError.self)
        requireSendable(TypedMetadataEntry<Bool>.self)
        requireSendable(TypedMetadataEntry<MetadataObject>.self)
    }

    @Test("[Unit][CDMS-34.7][VOX-META-002] single reads decide cardinality first")
    func singleReadsDecideCardinalityFirst() throws {
        let repeatable = try anyKey("example", "repeated")
        let policy = try MetadataMultiplicityPolicy(repeatableKeys: [repeatable])
        let collection = try MetadataCollection(
            entries: [
                MetadataEntry(
                    key: repeatable,
                    value: .string("text"),
                    privacyClass: .technical
                ),
                try entry("example", "single", value: .string("only")),
                try entry("example", "mismatched", value: .signedInteger(7)),
                MetadataEntry(
                    key: repeatable,
                    value: .boolean(true),
                    privacyClass: .sensitive
                ),
            ],
            multiplicityPolicy: policy
        )

        // Zero matches throws missingValue.
        do {
            _ = try collection.entry(
                for: MetadataKey<Bool>(namespace: "example", name: "absent")
            )
            #expect(Bool(false), "Expected an absent key to throw missingValue.")
        } catch MetadataReadError.missingValue {
            // Expected.
        }

        // A mixed-case duplicate where exactly one occurrence matches the
        // requested case still throws multipleValues: cardinality is
        // decided before any stored case is inspected, and no occurrence
        // is selected, filtered or preferred.
        do {
            _ = try collection.entry(
                for: MetadataKey<Bool>(namespace: "example", name: "repeated")
            )
            #expect(Bool(false), "Expected a repeated key to throw multipleValues.")
        } catch MetadataReadError.multipleValues {
            // Expected.
        }

        // Exactly one match with a mismatched case throws typeMismatch.
        do {
            _ = try collection.entry(
                for: MetadataKey<Bool>(namespace: "example", name: "mismatched")
            )
            #expect(Bool(false), "Expected a mismatched case to throw typeMismatch.")
        } catch MetadataReadError.typeMismatch {
            // Expected.
        }

        // Exactly one match with the expected case succeeds.
        let single = try collection.entry(
            for: MetadataKey<String>(namespace: "example", name: "single")
        )
        #expect(single.value == "only")
    }

    @Test("[Unit][VOX-META-002] exact UTF-8 matching never normalises")
    func exactUTF8MatchingNeverNormalises() throws {
        // The stored key uses the composed NFC spelling.
        let collection = try MetadataCollection(entries: [
            try entry("example", "caf\u{E9}", value: .boolean(true))
        ])

        // The canonically equivalent decomposed request is a distinct key.
        do {
            _ = try collection.entry(
                for: MetadataKey<Bool>(namespace: "example", name: "cafe\u{301}")
            )
            #expect(Bool(false), "Expected NFD lookup of an NFC key to miss.")
        } catch MetadataReadError.missingValue {
            // Expected.
        }

        // A byte-prefix request is a distinct key.
        do {
            _ = try collection.entry(
                for: MetadataKey<Bool>(namespace: "example", name: "caf")
            )
            #expect(Bool(false), "Expected a byte-prefix key to miss.")
        } catch MetadataReadError.missingValue {
            // Expected.
        }

        // The byte-identical request matches.
        let matched = try collection.entry(
            for: MetadataKey<Bool>(namespace: "example", name: "caf\u{E9}")
        )
        #expect(matched.value == true)
    }

    @Test("[Unit][CDMS-34.7][VOX-META-001] plural reads are ordered and atomic")
    func pluralReadsAreOrderedAndAtomic() throws {
        let repeatable = try anyKey("example", "repeated")
        let policy = try MetadataMultiplicityPolicy(repeatableKeys: [repeatable])
        let stringKey = try MetadataKey<String>(namespace: "example", name: "repeated")

        // Zero matches returns an empty array, never missingValue.
        let empty = try MetadataCollection(entries: [MetadataEntry]())
        #expect(try empty.entries(for: stringKey).isEmpty)

        // Every ordered occurrence is returned with its exact class,
        // including unresolved hostDefined and mixed-class repeats.
        let ordered = try MetadataCollection(
            entries: [
                MetadataEntry(
                    key: repeatable,
                    value: .string("first"),
                    privacyClass: .technical
                ),
                try entry("example", "other", value: .boolean(true)),
                MetadataEntry(
                    key: repeatable,
                    value: .string("second"),
                    privacyClass: .hostDefined
                ),
                MetadataEntry(
                    key: repeatable,
                    value: .string("third"),
                    privacyClass: .sensitive
                ),
            ],
            multiplicityPolicy: policy
        )
        let results = try ordered.entries(for: stringKey)
        #expect(results.map(\.value) == ["first", "second", "third"])
        #expect(
            results.map(\.privacyClass) == [.technical, .hostDefined, .sensitive]
        )

        // A late mismatch after a valid prefix fails atomically: the two
        // valid strings are never returned beside or instead of the error.
        let lateMismatch = try MetadataCollection(
            entries: [
                MetadataEntry(
                    key: repeatable,
                    value: .string("first"),
                    privacyClass: .technical
                ),
                MetadataEntry(
                    key: repeatable,
                    value: .string("second"),
                    privacyClass: .technical
                ),
                MetadataEntry(
                    key: repeatable,
                    value: .boolean(true),
                    privacyClass: .technical
                ),
            ],
            multiplicityPolicy: policy
        )
        do {
            _ = try lateMismatch.entries(for: stringKey)
            #expect(Bool(false), "Expected a late mismatch to fail atomically.")
        } catch MetadataReadError.typeMismatch {
            // Expected.
        }
    }

    @Test("[Unit][VOX-API-004] extraction never parses, bridges or converts")
    func extractionNeverParsesBridgesOrConverts() throws {
        let instant = try CanonicalInstant(utcString: "2026-08-04T00:00:00Z")
        let collection = try MetadataCollection(entries: [
            try entry("t", "instant", value: .instant(instant)),
            try entry("t", "signed", value: .signedInteger(1)),
            try entry(
                "t",
                "floating",
                value: .floatingPoint(try MetadataFloatingPoint(value: 1))
            ),
        ])

        // Instant text is never returned through the string overload.
        do {
            _ = try collection.entry(
                for: MetadataKey<String>(namespace: "t", name: "instant")
            )
            #expect(Bool(false), "Expected an instant case to mismatch a string read.")
        } catch MetadataReadError.typeMismatch {
            // Expected.
        }

        // Numeric cases are never widened or crossed: a signed integer is
        // not readable as unsigned, and a floating value is not readable
        // as a signed integer even when numerically equal.
        do {
            _ = try collection.entry(
                for: MetadataKey<UInt64>(namespace: "t", name: "signed")
            )
            #expect(Bool(false), "Expected a signed case to mismatch an unsigned read.")
        } catch MetadataReadError.typeMismatch {
            // Expected.
        }
        do {
            _ = try collection.entry(
                for: MetadataKey<Int64>(namespace: "t", name: "floating")
            )
            #expect(Bool(false), "Expected a floating case to mismatch a signed read.")
        } catch MetadataReadError.typeMismatch {
            // Expected.
        }

        // The validated wrappers are preserved exactly.
        let readInstant = try collection.entry(
            for: MetadataKey<CanonicalInstant>(namespace: "t", name: "instant")
        )
        #expect(readInstant.value == instant)
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-006] read errors stay payload-free")
    func readErrorsStayPayloadFree() throws {
        let collection = try MetadataCollection(entries: [
            try entry(
                "patient-namespace",
                "patient-field",
                value: .string("patient-value"),
                privacyClass: .sensitive
            )
        ])

        // Each failure renders without the key, value, requested type or
        // any match structure.
        do {
            _ = try collection.entry(
                for: MetadataKey<Bool>(
                    namespace: "patient-namespace",
                    name: "patient-field"
                )
            )
            #expect(Bool(false), "Expected a mismatched case to throw typeMismatch.")
        } catch let error as MetadataReadError {
            #expect(error == .typeMismatch)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient-namespace"))
            #expect(!rendered.contains("patient-field"))
            #expect(!rendered.contains("patient-value"))
            #expect(!rendered.contains("Bool"))
        }

        do {
            _ = try collection.entry(
                for: MetadataKey<Bool>(
                    namespace: "patient-namespace",
                    name: "patient-absent"
                )
            )
            #expect(Bool(false), "Expected an absent key to throw missingValue.")
        } catch let error as MetadataReadError {
            #expect(error == .missingValue)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
