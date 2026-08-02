// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ContentIdentityTaxonomy")
struct ContentIdentityTaxonomyTests {
    @Test("[Unit][VOX-ARC-003][VOX-API-003] exposes exact digest algorithms")
    func exposesExactDigestAlgorithms() {
        let expected: [(algorithm: DigestAlgorithm, rawValue: String)] = [
            (.sha256, "sha256"),
            (.sha512, "sha512"),
            (.blake3, "blake3"),
            (.custom, "custom"),
        ]

        for value in expected {
            #expect(value.algorithm.rawValue == value.rawValue)
            #expect(DigestAlgorithm(rawValue: value.rawValue) == value.algorithm)
        }
        #expect(DigestAlgorithm(rawValue: "SHA256") == nil)
        #expect(DigestAlgorithm(rawValue: "unknown") == nil)
    }

    @Test("[Unit][VOX-ARC-003][VOX-API-003] exposes exact content scopes")
    func exposesExactContentScopes() {
        let expected: [(scope: ContentScope, rawValue: String)] = [
            (.sampleBytes, "sampleBytes"),
            (.descriptorAndSamples, "descriptorAndSamples"),
            (.storageObject, "storageObject"),
            (.compressedRepresentation, "compressedRepresentation"),
            (.serialisedObject, "serialisedObject"),
        ]

        for value in expected {
            #expect(value.scope.rawValue == value.rawValue)
            #expect(ContentScope(rawValue: value.rawValue) == value.scope)
        }
        #expect(ContentScope(rawValue: "descriptorandsamples") == nil)
        #expect(ContentScope(rawValue: "unknown") == nil)
        #expect(ContentScope.descriptorAndSamples.rawValue == "descriptorAndSamples")
    }

    @Test("[Unit][VOX-API-004] Codable uses exact raw strings")
    func codableUsesExactRawStrings() throws {
        let algorithms: [DigestAlgorithm] = [.sha256, .sha512, .blake3, .custom]
        let scopes: [ContentScope] = [
            .sampleBytes,
            .descriptorAndSamples,
            .storageObject,
            .compressedRepresentation,
            .serialisedObject,
        ]

        for algorithm in algorithms {
            let data = try JSONEncoder().encode(algorithm)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(algorithm.rawValue)""#)
            #expect(try JSONDecoder().decode(DigestAlgorithm.self, from: data) == algorithm)
        }
        for scope in scopes {
            let data = try JSONEncoder().encode(scope)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(scope.rawValue)""#)
            #expect(try JSONDecoder().decode(ContentScope.self, from: data) == scope)
        }
    }

    @Test("[Unit][VOX-API-004] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        for json in [#""unknown""#, "1", "true", "null", "{}", "[]"] {
            let data = Data(json.utf8)
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(DigestAlgorithm.self, from: data)
            }
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(ContentScope.self, from: data)
            }
        }
    }

    @Test("[Unit][VOX-API-003] taxonomies remain Sendable and distinct")
    func remainsSendableAndDistinct() {
        requireSendable(DigestAlgorithm.self)
        requireSendable(ContentScope.self)
        #expect(Set([DigestAlgorithm.sha256, .sha512, .blake3, .custom]).count == 4)
        #expect(
            Set([
                ContentScope.sampleBytes,
                .descriptorAndSamples,
                .storageObject,
                .compressedRepresentation,
                .serialisedObject,
            ]).count == 5
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
