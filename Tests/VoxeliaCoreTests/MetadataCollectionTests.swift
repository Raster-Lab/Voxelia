// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("MetadataCollection")
struct MetadataCollectionTests {
    private func key(_ namespace: String, _ name: String) throws -> AnyMetadataKey {
        try AnyMetadataKey(namespace: namespace, name: name)
    }

    private func entry(
        _ namespace: String,
        _ name: String,
        value: MetadataValue = .boolean(true),
        privacyClass: MetadataPrivacyClass = .technical
    ) throws -> MetadataEntry {
        MetadataEntry(
            key: try key(namespace, name),
            value: value,
            privacyClass: privacyClass
        )
    }

    private func sortedKeysEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    @Test("[Unit][CDMS-34.5][VOX-META-001] construction preserves exact input order")
    func constructionPreservesExactInputOrder() throws {
        let unsorted = [
            try entry("zulu", "last"),
            try entry("alpha", "first"),
            try entry("mike", "middle"),
        ]
        let collection = try MetadataCollection(entries: unsorted)
        #expect(Array(collection.entries) == unsorted)

        // Order is semantic identity: reordering otherwise identical
        // entries changes equality and hashing.
        let reordered = try MetadataCollection(entries: unsorted.reversed())
        #expect(collection != reordered)
        #expect(Set([collection, reordered]).count == 2)
        let duplicate = try MetadataCollection(entries: unsorted)
        #expect(collection == duplicate)
        #expect(Set([collection, duplicate]).count == 1)

        // Empty collections are valid.
        let empty = try MetadataCollection(entries: [MetadataEntry]())
        #expect(empty.entries.isEmpty)

        requireSendable(MetadataCollection.self)
        requireSendable(MetadataCollectionError.self)
        requireSendable(MetadataMultiplicityPolicy.self)
    }

    @Test("[Unit][CDMS-34.6][VOX-META-001] ordinary construction is unique-only")
    func ordinaryConstructionIsUniqueOnly() throws {
        // The second occurrence of an exact key is rejected even when the
        // two complete entries are equal.
        let repeated = try entry("example", "field")
        do {
            _ = try MetadataCollection(entries: [repeated, repeated])
            #expect(Bool(false), "Expected a repeated exact key to be rejected.")
        } catch MetadataCollectionError.duplicateKey {
            // Expected.
        }

        // Duplicate detection is exact-key, not whole-entry: equal keys
        // with different values and classes are still duplicates.
        do {
            _ = try MetadataCollection(entries: [
                try entry("example", "field", privacyClass: .publicData),
                try entry("example", "field", value: .string("x"), privacyClass: .sensitive),
            ])
            #expect(Bool(false), "Expected exact-key detection to ignore entry identity.")
        } catch MetadataCollectionError.duplicateKey {
            // Expected.
        }

        // Exact UTF-8 identity: NFC/NFD spellings and byte prefixes are
        // distinct keys, never false duplicates.
        let distinct = try MetadataCollection(entries: [
            try entry("example", "caf\u{E9}"),
            try entry("example", "cafe\u{301}"),
            try entry("example", "caf"),
        ])
        #expect(distinct.entries.count == 3)
    }

    @Test("[Unit][CDMS-34.6][VOX-META-002] configured admission retains occurrences")
    func configuredAdmissionRetainsOccurrences() throws {
        let repeatable = try key("example", "repeated")
        let policy = try MetadataMultiplicityPolicy(repeatableKeys: [repeatable])

        // Every admitted occurrence is retained in input order, including
        // entries whose values and privacy classes differ; hostDefined
        // occurrences survive unresolved.
        let occurrences = [
            try entry("example", "repeated", value: .string("first"), privacyClass: .technical),
            try entry("example", "other"),
            try entry(
                "example",
                "repeated",
                value: .string("second"),
                privacyClass: .hostDefined
            ),
        ]
        let collection = try MetadataCollection(
            entries: occurrences,
            multiplicityPolicy: policy
        )
        #expect(Array(collection.entries) == occurrences)
        #expect(collection.entries[2].privacyClass == .hostDefined)

        // An unlisted key stays unique-only under the same policy.
        do {
            _ = try MetadataCollection(
                entries: [
                    try entry("example", "other"),
                    try entry("example", "other"),
                ],
                multiplicityPolicy: policy
            )
            #expect(Bool(false), "Expected an unlisted repeated key to be rejected.")
        } catch MetadataCollectionError.duplicateKey {
            // Expected.
        }
    }

    @Test("[Unit][VOX-SEC-001] policy ceilings charge supplied occurrences")
    func policyCeilingsChargeSuppliedOccurrences() throws {
        // The source count is bounded before deduplication: 2^20 + 1
        // occurrences of one exact key are rejected even though the
        // normalised set holds one member.
        let repeated = try key("example", "field")
        let oversizedCount = Array(
            repeating: repeated,
            count: Int(MetadataCollection.maximumMultiplicityPolicyKeyCount) + 1
        )
        do {
            _ = try MetadataMultiplicityPolicy(repeatableKeys: oversizedCount)
            #expect(Bool(false), "Expected the supplied key count to be bounded.")
        } catch MetadataCollectionError.multiplicityPolicyLimitExceeded {
            // Expected.
        }

        // The byte sum also charges every supplied occurrence before
        // deduplication: 65 copies of a one-mebibyte key exceed 64 MiB.
        let wide = try key(String(repeating: "n", count: 1_048_574), "nm")
        do {
            _ = try MetadataMultiplicityPolicy(
                repeatableKeys: Array(repeating: wide, count: 65)
            )
            #expect(Bool(false), "Expected the supplied key bytes to be bounded.")
        } catch MetadataCollectionError.multiplicityPolicyLimitExceeded {
            // Expected.
        }

        // Sixty-three occurrences fit, and the normalised policy still
        // admits repeats of exactly the listed key.
        let bounded = try MetadataMultiplicityPolicy(
            repeatableKeys: Array(repeating: wide, count: 63)
        )
        #expect(bounded.permitsRepeats(of: wide))
        #expect(!bounded.permitsRepeats(of: try key("example", "field")))
        #expect(!MetadataMultiplicityPolicy.uniqueKeysOnly.permitsRepeats(of: wide))
    }

    @Test("[Unit][CDMS-34.5][VOX-SEC-001] entry and aggregate ceilings are exact")
    func entryAndAggregateCeilingsAreExact() throws {
        let repeatable = try key("a", "b")
        let policy = try MetadataMultiplicityPolicy(repeatableKeys: [repeatable])
        let tiny = MetadataEntry(
            key: repeatable,
            value: .boolean(true),
            privacyClass: .technical
        )

        // Exactly 2^20 entries are accepted; one more is rejected by the
        // source-count preflight.
        let maximum = Int(MetadataCollection.maximumEntryCount)
        let full = try MetadataCollection(
            entries: Array(repeating: tiny, count: maximum),
            multiplicityPolicy: policy
        )
        #expect(full.entries.count == maximum)
        do {
            _ = try MetadataCollection(
                entries: Array(repeating: tiny, count: maximum + 1),
                multiplicityPolicy: policy
            )
            #expect(Bool(false), "Expected the entry-count ceiling to be exact.")
        } catch MetadataCollectionError.entryCountLimitExceeded {
            // Expected.
        }

        // Aggregate structural elements charge every occurrence of a
        // repeated copy-on-write-shared value: 262,144 four-element values
        // reach exactly 2^20, and one more single-element entry exceeds it.
        let fourElements = MetadataEntry(
            key: repeatable,
            value: .array(
                try MetadataArray(values: [.boolean(true), .boolean(false), .boolean(true)])
            ),
            privacyClass: .technical
        )
        let sharedEntries = Array(repeating: fourElements, count: 262_144)
        let atLimit = try MetadataCollection(
            entries: sharedEntries,
            multiplicityPolicy: policy
        )
        #expect(atLimit.entries.count == 262_144)
        do {
            _ = try MetadataCollection(
                entries: sharedEntries + [tiny],
                multiplicityPolicy: policy
            )
            #expect(Bool(false), "Expected the aggregate element ceiling to be exact.")
        } catch MetadataCollectionError.aggregateStructuralElementLimitExceeded {
            // Expected.
        }

        // Aggregate payload counts entry key bytes plus each value's
        // logical payload: eight entries of 8 MiB minus the two key bytes
        // reach exactly 64 MiB, and one more two-byte key exceeds it.
        let block = MetadataEntry(
            key: repeatable,
            value: .string(String(repeating: "s", count: 8_388_606)),
            privacyClass: .technical
        )
        let payloadEntries = Array(repeating: block, count: 8)
        let payloadAtLimit = try MetadataCollection(
            entries: payloadEntries,
            multiplicityPolicy: policy
        )
        #expect(payloadAtLimit.entries.count == 8)
        do {
            _ = try MetadataCollection(
                entries: payloadEntries + [tiny],
                multiplicityPolicy: policy
            )
            #expect(Bool(false), "Expected the aggregate payload ceiling to be exact.")
        } catch MetadataCollectionError.aggregateLogicalPayloadByteLimitExceeded {
            // Expected.
        }
    }

    @Test("[Unit][VOX-API-004] unique-only ordinary wire round trips")
    func uniqueOnlyOrdinaryWireRoundTrips() throws {
        let collection = try MetadataCollection(entries: [
            MetadataEntry(
                key: try key("example", "field"),
                value: .string("x"),
                privacyClass: .potentiallyIdentifying
            )
        ])
        let decoded = try JSONDecoder().decode(
            MetadataCollection.self,
            from: try JSONEncoder().encode(collection)
        )
        #expect(decoded == collection)

        // The documented one-field wire fixture is byte-exact under
        // sorted keys.
        let encoded = String(
            decoding: try sortedKeysEncoder().encode(collection),
            as: UTF8.self
        )
        #expect(
            encoded == #"{"entries":[{"key":{"name":"field","namespace":"example"},"#
                + #""privacyClass":"potentiallyIdentifying","value":{"string":"x"}}]}"#
        )

        // An empty collection also round trips.
        let empty = try MetadataCollection(entries: [MetadataEntry]())
        #expect(
            try JSONDecoder().decode(
                MetadataCollection.self,
                from: try JSONEncoder().encode(empty)
            ) == empty
        )
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] ordinary encoding of repeats fails first")
    func ordinaryEncodingOfRepeatsFailsFirst() throws {
        let repeatable = try key("example", "repeated")
        let policy = try MetadataMultiplicityPolicy(repeatableKeys: [repeatable])
        let duplicateRich = try MetadataCollection(
            entries: [
                MetadataEntry(
                    key: repeatable,
                    value: .string("first"),
                    privacyClass: .technical
                ),
                MetadataEntry(
                    key: repeatable,
                    value: .string("second"),
                    privacyClass: .sensitive
                ),
            ],
            multiplicityPolicy: policy
        )

        // A duplicate-rich value has no context-free ordinary encoding:
        // the typed preflight failure is thrown directly, not an
        // EncodingError carrying the collection.
        do {
            _ = try JSONEncoder().encode(duplicateRich)
            #expect(Bool(false), "Expected ordinary encoding to require a policy.")
        } catch MetadataCollectionError.multiplicityPolicyRequired {
            // Expected.
        }

        // The configured path encodes and decodes the same value exactly.
        let data = try sortedKeysEncoder().encode(duplicateRich, configuration: policy)
        let decoded = try JSONDecoder().decode(
            MetadataCollection.self,
            from: data,
            configuration: policy
        )
        #expect(decoded == duplicateRich)
        #expect(decoded.entries[1].privacyClass == .sensitive)

        // The policy is absent from the wire.
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("policy"))
        #expect(!text.contains("multiplicity"))
        #expect(!text.contains("repeatable"))

        // Encoding under a narrower snapshot revalidates and fails typed.
        do {
            _ = try JSONEncoder().encode(
                duplicateRich,
                configuration: .uniqueKeysOnly
            )
            #expect(Bool(false), "Expected a narrower policy to fail revalidation.")
        } catch MetadataCollectionError.duplicateKey {
            // Expected.
        }

        // Ordinary decoding of the configured bytes fails closed with the
        // typed duplicate cause on the fixed entries path.
        do {
            _ = try JSONDecoder().decode(MetadataCollection.self, from: data)
            #expect(Bool(false), "Expected ordinary decoding to reject repeats.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["entries"])
            #expect(
                context.underlyingError as? MetadataCollectionError == .duplicateKey
            )
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects malformed field sets")
    func decodingRejectsMalformedFieldSets() throws {
        let entryJSON =
            #"{"key":{"namespace":"example","name":"field"},"#
            + #""value":{"string":"x"},"privacyClass":"technical"}"#
        let malformedDocuments: [(document: String, path: [String])] = [
            // Missing entries field.
            (#"{}"#, []),
            // A distinct extra field is rejected.
            (#"{"entries":[\#(entryJSON)],"extra":true}"#, []),
            // A wrong field name is rejected.
            (#"{"items":[\#(entryJSON)]}"#, []),
            // A non-object collection is rejected.
            (#""entries""#, []),
            // Null entries are rejected on the fixed field path.
            (#"{"entries":null}"#, ["entries"]),
            // A wrong-shaped entries payload is rejected on the fixed path.
            (#"{"entries":"x"}"#, ["entries"]),
            // A malformed child entry is rejected on the fixed path.
            (#"{"entries":[{"key":"flat"}]}"#, ["entries"]),
        ]

        for (document, path) in malformedDocuments {
            do {
                _ = try JSONDecoder().decode(
                    MetadataCollection.self,
                    from: Data(document.utf8)
                )
                #expect(Bool(false), "Expected a malformed collection to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.map(\.stringValue) == path)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-SEC-001] decoding threads remaining aggregate budgets")
    func decodingThreadsRemainingAggregateBudgets() throws {
        // One entry consumes all but one structural element of the
        // aggregate budget; the next entry's recursive value must then be
        // rejected inside value decoding by the threaded remaining budget,
        // surfacing the typed value-limit cause rather than materialising
        // the second value and failing afterwards.
        let almostFull =
            #"{"key":{"namespace":"a","name":"b"},"privacyClass":"technical","#
            + #""value":{"array":["#
            + Array(repeating: #"{"boolean":true}"#, count: 1_048_574)
            .joined(separator: ",")
            + "]}}"
        let overflowing =
            #"{"key":{"namespace":"a","name":"c"},"privacyClass":"technical","#
            + #""value":{"array":[{"boolean":true},{"boolean":true},{"boolean":true}]}}"#
        let document = #"{"entries":[\#(almostFull),\#(overflowing)]}"#

        do {
            _ = try JSONDecoder().decode(
                MetadataCollection.self,
                from: Data(document.utf8)
            )
            #expect(Bool(false), "Expected the threaded budget to reject the document.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["entries"])
            #expect(
                context.underlyingError as? MetadataValueError
                    == .structuralElementLimitExceeded
            )
        }

        // The same first entry with a leaf second entry decodes: the
        // remaining one-element budget admits exactly one leaf value.
        let fitting =
            #"{"key":{"namespace":"a","name":"c"},"privacyClass":"technical","#
            + #""value":{"boolean":true}}"#
        let fittingDocument = #"{"entries":[\#(almostFull),\#(fitting)]}"#
        let decoded = try JSONDecoder().decode(
            MetadataCollection.self,
            from: Data(fittingDocument.utf8)
        )
        #expect(decoded.entries.count == 2)
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-006] collection failures redact structure")
    func collectionFailuresRedactStructure() throws {
        // A duplicate rejected beneath an arbitrary caller dictionary key
        // names only the fixed entries field and leaks neither the caller
        // key, the metadata key, an index nor a count.
        let entryJSON =
            #"{"key":{"namespace":"patient-namespace","name":"patient-field"},"#
            + #""value":{"string":"x"},"privacyClass":"technical"}"#
        let sentinelDocument =
            #"{"patient-sentinel":{"entries":[\#(entryJSON),\#(entryJSON)]}}"#
        do {
            _ = try JSONDecoder().decode(
                [String: MetadataCollection].self,
                from: Data(sentinelDocument.utf8)
            )
            #expect(Bool(false), "Expected a duplicate key to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["entries"])
            #expect(
                context.underlyingError as? MetadataCollectionError == .duplicateKey
            )
            var rendered = ""
            dump(context, to: &rendered)
            #expect(!rendered.contains("patient-sentinel"))
            #expect(!rendered.contains("patient-namespace"))
            #expect(!rendered.contains("patient-field"))
            #expect(!rendered.contains("Index"))
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        // Construction-side redaction: the typed errors are payload-free.
        do {
            let repeated = try entry("patient-namespace", "patient-field")
            _ = try MetadataCollection(entries: [repeated, repeated])
            #expect(Bool(false), "Expected a repeated exact key to be rejected.")
        } catch let error as MetadataCollectionError {
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient-namespace"))
            #expect(!rendered.contains("patient-field"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
