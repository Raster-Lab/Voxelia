// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("AxisSampling")
struct AxisSamplingTests {
    @Test("[Unit][CDMS-14.3][VOX-DAT-006] exposes the exact sampling taxonomy")
    func exposesExactTaxonomy() {
        let values: Set<AxisSampling> = [
            .indexOnly,
            .regular(origin: 0, spacing: 0.5),
            .irregular(coordinates: [0, 1, 2.5]),
            .categorical(labels: ["baseline", "contrast"]),
            .externallyDefined(identifier: "org.example.sampling"),
        ]

        #expect(values.count == 5)
    }

    @Test("[Unit][CDMS-14.4][VOX-ERR-001] validation enforces value-intrinsic invariants")
    func validationEnforcesInvariants() throws {
        try AxisSampling.indexOnly.validate()
        try AxisSampling.regular(origin: -12.5, spacing: 0.25).validate()
        try AxisSampling.irregular(coordinates: []).validate()
        try AxisSampling.categorical(labels: []).validate()

        let invalidValues: [(sampling: AxisSampling, expectedError: AxisSamplingError)] = [
            (.regular(origin: .nan, spacing: 1), .nonFiniteOrigin),
            (.regular(origin: .infinity, spacing: 1), .nonFiniteOrigin),
            (.regular(origin: 0, spacing: .nan), .nonFiniteSpacing),
            (.regular(origin: 0, spacing: -.infinity), .nonFiniteSpacing),
            (.regular(origin: 0, spacing: 0), .zeroSpacing),
            (
                .irregular(coordinates: [0, .nan, 2]),
                .nonFiniteCoordinate(index: 1)
            ),
            (
                .categorical(labels: ["baseline", " \u{2003}"]),
                .blankLabel(index: 1)
            ),
            (.externallyDefined(identifier: " "), .blankExternalIdentifier),
        ]
        for invalidValue in invalidValues {
            #expect(throws: invalidValue.expectedError) {
                try invalidValue.sampling.validate()
            }
        }
    }

    @Test("[Unit][VOX-API-004] Codable uses the strict one-tag wire")
    func codableUsesDocumentedWire() throws {
        let indexOnlyData = try JSONEncoder().encode(AxisSampling.indexOnly)
        #expect(String(decoding: indexOnlyData, as: UTF8.self) == #""indexOnly""#)
        #expect(
            try JSONDecoder().decode(AxisSampling.self, from: indexOnlyData)
                == .indexOnly
        )

        let payloadValues: [AxisSampling] = [
            .regular(origin: -2.5, spacing: 0.5),
            .irregular(coordinates: [0, 1.5, 4]),
            .categorical(labels: ["baseline", "contrast"]),
            .externallyDefined(identifier: "org.example.sampling"),
        ]
        for payloadValue in payloadValues {
            let data = try JSONEncoder().encode(payloadValue)
            let object = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            #expect(object.count == 1)
            #expect(
                try JSONDecoder().decode(AxisSampling.self, from: data) == payloadValue
            )
        }

        let regularObject = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(AxisSampling.regular(origin: -2.5, spacing: 0.5))
            ) as? [String: [String: Double]]
        )
        #expect(regularObject == ["regular": ["origin": -2.5, "spacing": 0.5]])
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        let rootCorruptedValues = [
            #""unknown""#,
            #""regular""#,
            #"{}"#,
            #"{"unexpected":{}}"#,
            #"{"regular":{"origin":0,"spacing":1},"extra":true}"#,
        ]
        for rootCorruptedValue in rootCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    AxisSampling.self,
                    from: Data(rootCorruptedValue.utf8)
                )
                #expect(Bool(false), "Expected a malformed sampling to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        let payloadCorruptedValues: [(json: String, path: [String])] = [
            (#"{"regular":{"origin":0}}"#, ["regular"]),
            (#"{"regular":{"origin":0,"spacing":1,"extra":true}}"#, ["regular"]),
            (#"{"irregular":{}}"#, ["irregular"]),
            (#"{"categorical":{"values":[]}}"#, ["categorical"]),
            (#"{"externallyDefined":{}}"#, ["externallyDefined"]),
        ]
        for payloadCorruptedValue in payloadCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    AxisSampling.self,
                    from: Data(payloadCorruptedValue.json.utf8)
                )
                #expect(Bool(false), "Expected a malformed payload to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(
                    context.codingPath.map(\.stringValue) == payloadCorruptedValue.path
                )
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(AxisSampling.self, from: Data("null".utf8))
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // The keyed-container request rejects null after the string branch.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "[]", #"{"regular":"payload"}"#] {
            do {
                _ = try JSONDecoder().decode(
                    AxisSampling.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped sampling to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-object shapes and the string-valued payload are rejected.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding revalidates payload invariants")
    func decodingRevalidatesInvariants() throws {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )

        let invalidPayloads: [(json: String, path: [String], expectedError: AxisSamplingError)] = [
            (
                #"{"regular":{"origin":"NaN","spacing":1}}"#,
                ["regular"],
                .nonFiniteOrigin
            ),
            (
                #"{"regular":{"origin":0,"spacing":"Infinity"}}"#,
                ["regular"],
                .nonFiniteSpacing
            ),
            (
                #"{"regular":{"origin":0,"spacing":0}}"#,
                ["regular"],
                .zeroSpacing
            ),
            (
                #"{"irregular":{"coordinates":[0,"NaN"]}}"#,
                ["irregular"],
                .nonFiniteCoordinate(index: 1)
            ),
            (
                #"{"categorical":{"labels":[" "]}}"#,
                ["categorical"],
                .blankLabel(index: 0)
            ),
            (
                #"{"externallyDefined":{"identifier":" "}}"#,
                ["externallyDefined"],
                .blankExternalIdentifier
            ),
        ]
        for invalidPayload in invalidPayloads {
            do {
                _ = try decoder.decode(
                    AxisSampling.self,
                    from: Data(invalidPayload.json.utf8)
                )
                #expect(Bool(false), "Expected an invalid payload to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.map(\.stringValue) == invalidPayload.path)
                #expect(
                    context.underlyingError as? AxisSamplingError
                        == invalidPayload.expectedError
                )
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-API-003] values remain Sendable and Hashable")
    func remainsSendableAndHashable() {
        requireSendable(AxisSampling.self)
        #expect(
            Set([
                AxisSampling.regular(origin: 0, spacing: 1),
                .regular(origin: 0, spacing: 1),
                .indexOnly,
            ]).count == 2
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
