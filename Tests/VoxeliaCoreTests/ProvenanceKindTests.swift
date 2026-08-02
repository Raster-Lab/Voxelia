// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ProvenanceKind")
struct ProvenanceKindTests {
    @Test("[Unit][VOX-ARC-003][VOX-API-003] exposes the exact provenance taxonomy")
    func exposesExactRawValues() {
        let expected: [(kind: ProvenanceKind, rawValue: String)] = [
            (.source, "source"),
            (.imported, "imported"),
            (.decoded, "decoded"),
            (.viewed, "viewed"),
            (.transformed, "transformed"),
            (.processed, "processed"),
            (.segmented, "segmented"),
            (.registered, "registered"),
            (.rendered, "rendered"),
            (.materialised, "materialised"),
            (.cached, "cached"),
        ]

        for value in expected {
            #expect(value.kind.rawValue == value.rawValue)
            #expect(ProvenanceKind(rawValue: value.rawValue) == value.kind)
        }
        #expect(ProvenanceKind(rawValue: "materialized") == nil)
        #expect(ProvenanceKind(rawValue: "SOURCE") == nil)
        #expect(ProvenanceKind(rawValue: "unknown") == nil)
    }

    @Test("[Unit][VOX-API-004] Codable uses exact raw strings")
    func codableUsesExactRawStrings() throws {
        let values: [ProvenanceKind] = [
            .source,
            .imported,
            .decoded,
            .viewed,
            .transformed,
            .processed,
            .segmented,
            .registered,
            .rendered,
            .materialised,
            .cached,
        ]

        for value in values {
            let data = try JSONEncoder().encode(value)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(value.rawValue)""#)
            #expect(try JSONDecoder().decode(ProvenanceKind.self, from: data) == value)
        }
    }

    @Test("[Unit][VOX-API-004] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        for json in [#""unknown""#, #""materialized""#, "1", "true", "null", "{}", "[]"] {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    ProvenanceKind.self,
                    from: Data(json.utf8)
                )
            }
        }
    }

    @Test("[Unit][VOX-API-003] values remain Sendable and Hashable")
    func remainsSendableAndHashable() {
        let values: Set<ProvenanceKind> = [
            .source,
            .imported,
            .decoded,
            .viewed,
            .transformed,
            .processed,
            .segmented,
            .registered,
            .rendered,
            .materialised,
            .cached,
        ]

        #expect(values.count == 11)
        requireSendable(ProvenanceKind.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
