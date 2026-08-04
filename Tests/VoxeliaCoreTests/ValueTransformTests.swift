// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ValueTransform")
struct ValueTransformTests {
    @Test("[Unit][CDMS-18.5][VOX-ERR-001] linear accepts finite extremes and rejects non-finite")
    func linearValidatesFiniteParameters() throws {
        let extreme = try LinearValueTransformDescriptor(
            scale: .greatestFiniteMagnitude,
            offset: -.greatestFiniteMagnitude
        )
        #expect(extreme.scale == .greatestFiniteMagnitude)
        #expect(extreme.offset == -.greatestFiniteMagnitude)

        let subnormal = try LinearValueTransformDescriptor(
            scale: .leastNonzeroMagnitude,
            offset: .leastNormalMagnitude
        )
        #expect(subnormal.scale == .leastNonzeroMagnitude)

        let zeroScale = try LinearValueTransformDescriptor(scale: 0, offset: -1024)
        #expect(zeroScale.scale == 0)

        let nonFinitePairs: [(scale: Double, offset: Double)] = [
            (.nan, 0),
            (.infinity, 0),
            (-.infinity, 0),
            (2, .nan),
            (2, .infinity),
            (2, -.infinity),
        ]
        for nonFinitePair in nonFinitePairs {
            #expect(throws: DataModelError.invalidValueTransform) {
                try LinearValueTransformDescriptor(
                    scale: nonFinitePair.scale,
                    offset: nonFinitePair.offset
                )
            }
        }
    }

    @Test("[Unit][CDMS-18.5][VOX-API-004] linear canonicalizes signed zero")
    func linearCanonicalizesSignedZero() throws {
        let negativeZero = try LinearValueTransformDescriptor(scale: -0.0, offset: -0.0)
        let positiveZero = try LinearValueTransformDescriptor(scale: 0, offset: 0)

        #expect(negativeZero.scale.sign == .plus)
        #expect(negativeZero.offset.sign == .plus)
        #expect(negativeZero == positiveZero)
        #expect(Set([negativeZero, positiveZero]).count == 1)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        #expect(try encoder.encode(negativeZero) == encoder.encode(positiveZero))
    }

    @Test("[Unit][CDMS-18.4][VOX-ERR-001] composition is nonempty, ordered and unsimplified")
    func compositionValidatesAndPreservesStructure() throws {
        let linear = ValueTransform.linear(
            try LinearValueTransformDescriptor(scale: 2, offset: -1024)
        )
        let ordered = try ValueTransformComposition(transforms: [linear, .identity])
        let reversed = try ValueTransformComposition(transforms: [.identity, linear])
        #expect(Array(ordered.transforms) == [linear, .identity])
        #expect(ordered != reversed)

        let oneElement = try ValueTransformComposition(transforms: [.identity])
        #expect(Array(oneElement.transforms) == [.identity])

        let nested = try ValueTransformComposition(
            transforms: [.composed(oneElement), linear]
        )
        #expect(nested.transforms.first == .composed(oneElement))

        let large = try ValueTransformComposition(
            transforms: Array(repeating: ValueTransform.identity, count: 1_024)
        )
        #expect(large.transforms.count == 1_024)

        #expect(throws: DataModelError.invalidValueTransform) {
            try ValueTransformComposition(transforms: [ValueTransform]())
        }
    }

    @Test("[Unit][VOX-API-004] Codable uses the documented explicit tags")
    func codableUsesDocumentedWire() throws {
        let identityData = try JSONEncoder().encode(ValueTransform.identity)
        #expect(String(decoding: identityData, as: UTF8.self) == #""identity""#)
        #expect(
            try JSONDecoder().decode(ValueTransform.self, from: identityData)
                == .identity
        )

        let linear = ValueTransform.linear(
            try LinearValueTransformDescriptor(scale: 2, offset: -1024)
        )
        let linearData = try JSONEncoder().encode(linear)
        let linearObject = try #require(
            JSONSerialization.jsonObject(with: linearData)
                as? [String: [String: Double]]
        )
        #expect(linearObject == ["linear": ["scale": 2, "offset": -1024]])
        #expect(try JSONDecoder().decode(ValueTransform.self, from: linearData) == linear)

        let lookup = ValueTransform.lookupTable(
            try LookupTableDescriptor(firstMappedValue: 0, values: [0, 0.5, 1])
        )
        let lookupData = try JSONEncoder().encode(lookup)
        let lookupObject = try #require(
            JSONSerialization.jsonObject(with: lookupData) as? [String: Any]
        )
        #expect(Array(lookupObject.keys) == ["lookupTable"])
        #expect(try JSONDecoder().decode(ValueTransform.self, from: lookupData) == lookup)

        let composed = ValueTransform.composed(
            try ValueTransformComposition(transforms: [linear, .identity])
        )
        let composedData = try JSONEncoder().encode(composed)
        let composedObject = try #require(
            JSONSerialization.jsonObject(with: composedData)
                as? [String: [String: [Any]]]
        )
        #expect(composedObject["composed"]?["transforms"]?.count == 2)
        #expect(
            try JSONDecoder().decode(ValueTransform.self, from: composedData) == composed
        )
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        let rootCorruptedValues = [
            #""unknown""#,
            #""Identity""#,
            #""linear""#,
            #"{}"#,
            #"{"unexpected":{"scale":2,"offset":0}}"#,
            #"{"linear":{"scale":2,"offset":0},"extra":true}"#,
            #"{"linear":{"scale":2,"offset":0},"lookupTable":{"firstMappedValue":0,"values":[],"outputUnit":null}}"#,
        ]
        for rootCorruptedValue in rootCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    ValueTransform.self,
                    from: Data(rootCorruptedValue.utf8)
                )
                #expect(Bool(false), "Expected a malformed transform to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        let linearCorruptedValues = [
            #"{"linear":{"scale":2}}"#,
            #"{"linear":{"offset":0}}"#,
            #"{"linear":{"scale":2,"offset":0,"extra":true}}"#,
        ]
        for linearCorruptedValue in linearCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    ValueTransform.self,
                    from: Data(linearCorruptedValue.utf8)
                )
                #expect(Bool(false), "Expected a malformed linear payload to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.map(\.stringValue) == ["linear"])
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(ValueTransform.self, from: Data("null".utf8))
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // The keyed-container request rejects null after the string branch.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "[]", #"{"linear":"payload"}"#] {
            do {
                _ = try JSONDecoder().decode(
                    ValueTransform.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped transform to fail decoding.")
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

        do {
            _ = try decoder.decode(
                ValueTransform.self,
                from: Data(#"{"linear":{"scale":"NaN","offset":0}}"#.utf8)
            )
            #expect(Bool(false), "Expected a NaN scale to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["linear"])
            #expect(
                context.underlyingError as? DataModelError == .invalidValueTransform
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(
                ValueTransform.self,
                from: Data(#"{"composed":{"transforms":[]}}"#.utf8)
            )
            #expect(Bool(false), "Expected an empty composition to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(
                context.codingPath.map(\.stringValue) == ["composed", "transforms"]
            )
            #expect(
                context.underlyingError as? DataModelError == .invalidValueTransform
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(
                ValueTransform.self,
                from: Data(#"{"composed":{"values":[]}}"#.utf8)
            )
            #expect(Bool(false), "Expected a wrong-keyed composition to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["composed"])
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        let nestedRoundTrip = ValueTransform.composed(
            try ValueTransformComposition(transforms: [
                .composed(try ValueTransformComposition(transforms: [.identity]))
            ])
        )
        let nestedData = try JSONEncoder().encode(nestedRoundTrip)
        #expect(
            try JSONDecoder().decode(ValueTransform.self, from: nestedData)
                == nestedRoundTrip
        )
    }

    @Test("[Unit][VOX-API-003][VOX-CON-003] values remain Sendable and Hashable")
    func remainsSendableAndHashable() throws {
        requireSendable(ValueTransform.self)
        requireSendable(LinearValueTransformDescriptor.self)
        requireSendable(ValueTransformComposition.self)

        let linear = ValueTransform.linear(
            try LinearValueTransformDescriptor(scale: 2, offset: -1024)
        )
        #expect(Set([linear, linear, .identity]).count == 2)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
