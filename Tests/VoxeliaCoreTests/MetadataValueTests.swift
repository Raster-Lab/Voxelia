// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("MetadataValue")
struct MetadataValueTests {
    private func key(_ namespace: String, _ name: String) throws -> AnyMetadataKey {
        try AnyMetadataKey(namespace: namespace, name: name)
    }

    @Test("[Unit][CDMS-34.3][VOX-META-002] case tags and leaves use exact identity")
    func caseTagsAndLeavesUseExactIdentity() throws {
        #expect(MetadataValue.signedInteger(1) != .unsignedInteger(1))
        #expect(
            MetadataValue.signedInteger(1)
                != .floatingPoint(try MetadataFloatingPoint(value: 1))
        )
        #expect(MetadataValue.boolean(true) != .boolean(false))

        // Exact UTF-8 identity: NFC and NFD spellings are distinct values
        // even though Swift String equality would unify them.
        let composed = "caf\u{E9}"
        let decomposed = "cafe\u{301}"
        #expect(composed == decomposed)
        #expect(MetadataValue.string(composed) != .string(decomposed))
        #expect(
            Set([MetadataValue.string(composed), .string(decomposed)]).count == 2
        )

        requireSendable(MetadataValue.self)
        requireSendable(MetadataValueError.self)
        requireSendable(MetadataArray.self)
        requireSendable(MetadataObject.self)
        requireSendable(MetadataObject.Member.self)
    }

    @Test("[Unit][CDMS-34.6][VOX-SEC-001] depth ceiling accepts 64 and rejects 65")
    func depthCeilingIsExact() throws {
        var value = MetadataValue.boolean(true)
        for _ in 0..<MetadataValue.maximumContainerDepth {
            value = .array(try MetadataArray(values: [value]))
        }
        #expect(value.metrics.depth == 64)
        let deepest = value

        #expect(throws: MetadataValueError.containerDepthLimitExceeded) {
            try MetadataArray(values: [deepest])
        }

        // Iterative equality, hashing and set behaviour at maximum depth,
        // followed by normal destruction.
        var duplicate = MetadataValue.boolean(true)
        for _ in 0..<MetadataValue.maximumContainerDepth {
            duplicate = .array(try MetadataArray(values: [duplicate]))
        }
        #expect(deepest == duplicate)
        #expect(Set([deepest, duplicate]).count == 1)
    }

    @Test("[Unit][CDMS-34.6][VOX-SEC-001] element ceiling is exact at the limit")
    func elementCeilingIsExact() throws {
        let limit = Int(MetadataValue.maximumLogicalStructuralElementCount)
        let leaves = Array(
            repeating: MetadataValue.boolean(true),
            count: limit - 1
        )

        let accepted = try MetadataArray(values: leaves)
        #expect(
            MetadataValue.array(accepted).metrics.elements
                == MetadataValue.maximumLogicalStructuralElementCount
        )

        #expect(throws: MetadataValueError.structuralElementLimitExceeded) {
            try MetadataArray(values: leaves + [.boolean(true)])
        }
    }

    @Test("[Unit][VOX-SEC-001] copy-on-write amplification obeys the logical oracle")
    func amplificationObeysLogicalOracle() throws {
        var value = MetadataValue.boolean(true)
        for _ in 0..<19 {
            value = .array(try MetadataArray(values: [value, value]))
        }
        // 19 doublings give exactly 2^20 - 1 logical occurrences.
        #expect(value.metrics.elements == 1_048_575)
        let amplified = value

        // The 20th doubling would reach 2,097,151 occurrences and is
        // rejected despite linear physical storage.
        #expect(throws: MetadataValueError.structuralElementLimitExceeded) {
            try MetadataArray(values: [amplified, amplified])
        }
    }

    @Test("[Unit][CDMS-34.6][VOX-SEC-001] payload ceiling caps embedding, not leaves")
    func payloadCeilingCapsEmbeddingOnly() throws {
        let limit = Int(
            MetadataValue.maximumRecursiveContainerLogicalVariablePayloadByteCount
        )
        let exact = MetadataValue.string(String(repeating: "a", count: limit))
        _ = try MetadataArray(values: [exact])

        let oversized = MetadataValue.string(String(repeating: "a", count: limit + 1))
        #expect(throws: MetadataValueError.logicalPayloadByteLimitExceeded) {
            try MetadataArray(values: [oversized])
        }
        #expect(throws: MetadataValueError.logicalPayloadByteLimitExceeded) {
            try MetadataObject(members: [
                MetadataObject.Member(key: try key("example", "big"), value: oversized)
            ])
        }

        // The standalone leaf above the aggregate ceiling stays valid and
        // round trips through the ordinary wire.
        let data = try JSONEncoder().encode(oversized)
        let decoded = try JSONDecoder().decode(MetadataValue.self, from: data)
        #expect(decoded == oversized)
    }

    @Test("[Unit][VOX-SEC-001] checked accounting rejects overflow without allocation")
    func checkedAccountingRejectsOverflow() throws {
        #expect(throws: MetadataValueError.structuralElementLimitExceeded) {
            _ = try MetadataValue.addingElements(UInt64.max, 1)
        }
        #expect(throws: MetadataValueError.logicalPayloadByteLimitExceeded) {
            _ = try MetadataValue.addingPayload(UInt64.max - 1, 2)
        }
        #expect(try MetadataValue.addingElements(UInt64.max - 1, 1) == UInt64.max)
    }

    @Test("[Unit][CDMS-34.6][VOX-META-002] objects are canonical exact-key maps")
    func objectsAreCanonicalMaps() throws {
        let first = MetadataObject.Member(
            key: try key("example", "beta"),
            value: .boolean(true)
        )
        let second = MetadataObject.Member(
            key: try key("example", "alpha"),
            value: .signedInteger(7)
        )
        let prefix = MetadataObject.Member(
            key: try key("example", "alph"),
            value: .boolean(false)
        )

        let ordered = try MetadataObject(members: [first, second, prefix])
        #expect(
            ordered.members.map(\.key.name) == ["alph", "alpha", "beta"]
        )

        // Caller order is not semantic: equality, hashing and encoding are
        // identical for reversed input.
        let reversed = try MetadataObject(members: [prefix, second, first])
        #expect(ordered == reversed)
        #expect(Set([ordered, reversed]).count == 1)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        #expect(
            try encoder.encode(MetadataValue.object(ordered))
                == encoder.encode(MetadataValue.object(reversed))
        )

        // Exact-key duplicates are rejected with equal and unequal values.
        #expect(throws: MetadataValueError.duplicateObjectKey) {
            try MetadataObject(members: [first, first])
        }
        #expect(throws: MetadataValueError.duplicateObjectKey) {
            try MetadataObject(members: [
                first,
                MetadataObject.Member(
                    key: try key("example", "beta"),
                    value: .signedInteger(9)
                ),
            ])
        }

        // Canonically equivalent but UTF-8-distinct keys remain distinct.
        let canonicallyEquivalent = try MetadataObject(members: [
            MetadataObject.Member(
                key: try key("example", "caf\u{E9}"),
                value: .boolean(true)
            ),
            MetadataObject.Member(
                key: try key("example", "cafe\u{301}"),
                value: .boolean(false)
            ),
        ])
        #expect(canonicallyEquivalent.members.count == 2)
    }

    @Test("[Unit][VOX-META-002] construction snapshots the source collection")
    func constructionSnapshotsSource() throws {
        var source = [MetadataValue.boolean(true)]
        let array = try MetadataArray(values: source)
        source.append(.boolean(false))
        #expect(array.values.count == 1)
    }

    @Test("[Unit][VOX-API-004] every tag round trips with the documented wire")
    func everyTagRoundTrips() throws {
        let object = try MetadataObject(members: [
            MetadataObject.Member(
                key: try key("example", "field"),
                value: .string("x")
            )
        ])
        let values: [MetadataValue] = [
            .boolean(true),
            .signedInteger(Int64.min),
            .signedInteger(Int64.max),
            .unsignedInteger(UInt64.max),
            .floatingPoint(try MetadataFloatingPoint(value: 1.25)),
            .string("text"),
            .binary(MetadataBinary(bytes: [0x66])),
            .instant(try CanonicalInstant(utcString: "2026-08-02T12:34:56Z")),
            .unit(try MeasurementUnit(namespace: "UCUM", code: "mm")),
            .code(try CodedConcept(scheme: "example", value: "A")),
            .array(try MetadataArray(values: [.boolean(true), .string("x")])),
            .object(object),
        ]
        let expectedTags = [
            "boolean", "signedInteger", "signedInteger", "unsignedInteger",
            "floatingPoint", "string", "binary", "instant", "unit", "code",
            "array", "object",
        ]
        for (value, expectedTag) in zip(values, expectedTags) {
            let data = try JSONEncoder().encode(value)
            let jsonObject = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            #expect(Array(jsonObject.keys) == [expectedTag])
            #expect(try JSONDecoder().decode(MetadataValue.self, from: data) == value)
        }

        // The object member wire is exactly key and value.
        let objectData = try JSONEncoder().encode(MetadataValue.object(object))
        let outer = try #require(
            JSONSerialization.jsonObject(with: objectData) as? [String: [[String: Any]]]
        )
        let member = try #require(outer["object"]?.first)
        #expect(Set(member.keys) == ["key", "value"])
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects malformed tag shapes")
    func decodingRejectsMalformedTagShapes() {
        let corruptedFixtures = [
            "{}",
            #"{"boolean":true,"string":"x"}"#,
            #"{"unknownTag":1}"#,
            #"{"object":[{"key":{"namespace":"example","name":"field"}}]}"#,
            #"{"object":[{"key":{"namespace":"example","name":"field"},"value":{"boolean":true},"extra":1}]}"#,
        ]
        for corruptedFixture in corruptedFixtures {
            do {
                _ = try JSONDecoder().decode(
                    MetadataValue.self,
                    from: Data(corruptedFixture.utf8)
                )
                #expect(Bool(false), "Expected a malformed value to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
                #expect(!context.debugDescription.contains("unknownTag"))
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(MetadataValue.self, from: Data("null".utf8))
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // Null is rejected for the non-optional tagged object.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", #""x""#, "[]", "true"] {
            do {
                _ = try JSONDecoder().decode(
                    MetadataValue.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped value to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-object shapes are rejected by the keyed request.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-006] decode ceilings reject with redacted causes")
    func decodeCeilingsRejectWithRedactedCauses() throws {
        // Depth 64 decodes; depth 65 is rejected bottom-up with the typed
        // underlying cause.
        func nestedDocument(depth: Int) -> Data {
            let prefix = String(repeating: #"{"array":["#, count: depth)
            let suffix = String(repeating: "]}", count: depth)
            return Data((prefix + #"{"boolean":true}"# + suffix).utf8)
        }

        let deepest = try JSONDecoder().decode(
            MetadataValue.self,
            from: nestedDocument(depth: 64)
        )
        #expect(deepest.metrics.depth == 64)

        do {
            _ = try JSONDecoder().decode(
                MetadataValue.self,
                from: nestedDocument(depth: 65)
            )
            #expect(Bool(false), "Expected depth 65 to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(
                context.underlyingError as? MetadataValueError
                    == .containerDepthLimitExceeded
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        // An adversarially deep document within the raw parser's nesting
        // tolerance is rejected by the conservative early guard during
        // descent, long before unbounded recursion.
        do {
            _ = try JSONDecoder().decode(
                MetadataValue.self,
                from: nestedDocument(depth: 120)
            )
            #expect(Bool(false), "Expected an adversarial document to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(
                context.underlyingError as? MetadataValueError
                    == .containerDepthLimitExceeded
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        // A document beyond the raw parser's own nesting tolerance fails in
        // the underlying decoder before this model runs; that
        // decoder-originated failure is outside the wrapper's redaction
        // guarantee and must be sanitised by ingress.
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                MetadataValue.self,
                from: nestedDocument(depth: 4_096)
            )
        }

        // A model-originated duplicate-key failure decoded beneath an
        // arbitrary caller dictionary key never copies that key into its
        // context.
        let sentinelDocument =
            #"{"patient-sentinel":{"object":["#
            + #"{"key":{"namespace":"example","name":"field"},"value":{"boolean":true}},"#
            + #"{"key":{"namespace":"example","name":"field"},"value":{"boolean":false}}"#
            + "]}}"
        do {
            _ = try JSONDecoder().decode(
                [String: MetadataValue].self,
                from: Data(sentinelDocument.utf8)
            )
            #expect(Bool(false), "Expected a duplicate object key to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(
                context.underlyingError as? MetadataValueError == .duplicateObjectKey
            )
            #expect(context.codingPath.isEmpty)
            #expect(!context.debugDescription.contains("patient-sentinel"))
            #expect(!context.debugDescription.contains("field"))
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    @Test("[Unit][VOX-SEC-001] decode enforces element budgets incrementally")
    func decodeEnforcesElementBudgets() throws {
        // A flat array document one over the ceiling is rejected with the
        // typed underlying cause before construction completes.
        let limit = Int(MetadataValue.maximumLogicalStructuralElementCount)
        let oversized =
            #"{"array":["#
            + Array(
                repeating: #"{"boolean":true}"#,
                count: limit
            ).joined(separator: ",")
            + "]}"
        do {
            _ = try JSONDecoder().decode(
                MetadataValue.self,
                from: Data(oversized.utf8)
            )
            #expect(Bool(false), "Expected an oversized array to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(
                context.underlyingError as? MetadataValueError
                    == .structuralElementLimitExceeded
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
