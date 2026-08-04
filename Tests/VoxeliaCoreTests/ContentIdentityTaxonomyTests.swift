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

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        expectExactInvalidDecoding(DigestAlgorithm.self)
        expectExactInvalidDecoding(ContentScope.self)
    }

    private func expectExactInvalidDecoding<Value: Decodable>(_ type: Value.Type) {
        do {
            _ = try JSONDecoder().decode(type, from: Data(#""unknown""#.utf8))
            #expect(Bool(false), "Expected an unknown token to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.isEmpty)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(type, from: Data("null".utf8))
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // Null is rejected for the non-optional raw value.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "{}", "[]"] {
            do {
                _ = try JSONDecoder().decode(type, from: Data(wrongShape.utf8))
                #expect(Bool(false), "Expected a wrong-shaped value to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-string shapes are rejected before raw-value lookup.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
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
