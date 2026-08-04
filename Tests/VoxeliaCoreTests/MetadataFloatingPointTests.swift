// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("MetadataFloatingPoint")
struct MetadataFloatingPointTests {
    @Test("[Unit][CDMS-34.6][VOX-META-002] preserves every finite bit pattern exactly")
    func preservesFiniteBitPatterns() throws {
        let finiteValues: [Double] = [
            1.25,
            -1024,
            .pi,
            -.pi,
            .leastNormalMagnitude,
            -.leastNormalMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
        ]
        for finiteValue in finiteValues {
            let wrapper = try MetadataFloatingPoint(value: finiteValue)
            #expect(wrapper.value.bitPattern == finiteValue.bitPattern)
        }

        // Generated deterministic finite bit patterns are preserved exactly.
        var state: UInt64 = 0x2545F4914F6CDD1D
        var generated = 0
        while generated < 512 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let candidate = Double(bitPattern: state)
            guard candidate.isFinite else { continue }
            generated += 1
            let wrapper = try MetadataFloatingPoint(value: candidate)
            if candidate.bitPattern == (-0.0).bitPattern {
                #expect(wrapper.value.bitPattern == Double(0).bitPattern)
            } else {
                #expect(wrapper.value.bitPattern == candidate.bitPattern)
            }
        }
    }

    @Test("[Unit][CDMS-34.6][VOX-ERR-001] rejects every non-finite value")
    func rejectsNonFiniteValues() {
        let nonFiniteValues: [Double] = [
            .nan,
            -.nan,
            .signalingNaN,
            -.signalingNaN,
            Double(nan: 0x7FF, signaling: false),
            Double(nan: 0x123, signaling: true),
            .infinity,
            -.infinity,
        ]
        for nonFiniteValue in nonFiniteValues {
            #expect(throws: MetadataFloatingPointError.nonFiniteValue) {
                try MetadataFloatingPoint(value: nonFiniteValue)
            }
        }
    }

    @Test("[Unit][CDMS-34.6][VOX-META-002] canonicalizes signed zero to positive zero")
    func canonicalizesSignedZero() throws {
        let negativeZero = try MetadataFloatingPoint(value: -0.0)
        let positiveZero = try MetadataFloatingPoint(value: 0)

        #expect(negativeZero.value.sign == .plus)
        #expect(negativeZero.value.bitPattern == Double(0).bitPattern)
        #expect(negativeZero == positiveZero)
        #expect(Set([negativeZero, positiveZero]).count == 1)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        #expect(try encoder.encode([negativeZero]) == encoder.encode([positiveZero]))
    }

    @Test("[Unit][VOX-API-003] equality is reflexive with coherent set behaviour")
    func equalityIsReflexive() throws {
        let values = try [1.25, -1.25, 0, .leastNonzeroMagnitude].map {
            try MetadataFloatingPoint(value: $0)
        }
        for value in values {
            #expect(value == value)
        }
        #expect(Set(values + values).count == values.count)
        requireSendable(MetadataFloatingPoint.self)
        requireSendable(MetadataFloatingPointError.self)
    }

    @Test("[Unit][VOX-API-004] Codable round trips one exact scalar number")
    func codableRoundTripsExactScalar() throws {
        let roundTripValues: [Double] = [
            1.25,
            -1024,
            .leastNonzeroMagnitude,
            .greatestFiniteMagnitude,
            0.1,
        ]
        for roundTripValue in roundTripValues {
            let wrapper = try MetadataFloatingPoint(value: roundTripValue)
            let data = try JSONEncoder().encode([wrapper])
            let decoded = try JSONDecoder().decode(
                [MetadataFloatingPoint].self,
                from: data
            )
            #expect(decoded[0].value.bitPattern == wrapper.value.bitPattern)
        }

        // Integer, fraction, exponent and signed-zero aliases decode to the
        // same binary64 values without any claim about canonical spelling.
        let aliasFixtures: [(json: String, expected: Double)] = [
            ("[1]", 1),
            ("[1.0]", 1),
            ("[1e0]", 1),
            ("[-0]", 0),
            ("[2.5e-1]", 0.25),
        ]
        for aliasFixture in aliasFixtures {
            let decoded = try JSONDecoder().decode(
                [MetadataFloatingPoint].self,
                from: Data(aliasFixture.json.utf8)
            )
            #expect(decoded[0].value.bitPattern == aliasFixture.expected.bitPattern)
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects wrong shapes and revalidates")
    func decodingRejectsAndRevalidates() {
        do {
            _ = try JSONDecoder().decode(
                MetadataFloatingPoint.self,
                from: Data("null".utf8)
            )
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // Null is rejected for the non-optional scalar.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["true", #""1.25""#, "[]", "{}"] {
            do {
                _ = try JSONDecoder().decode(
                    MetadataFloatingPoint.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped value to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-number shapes are rejected before validation.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }

        // A decoder configured to translate special strings must still not
        // create a non-finite wrapper: revalidation rejects it with the
        // typed underlying cause at the nested coding path.
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        for nonFiniteJSON in [#"["NaN"]"#, #"["Infinity"]"#, #"["-Infinity"]"#] {
            do {
                _ = try decoder.decode(
                    [MetadataFloatingPoint].self,
                    from: Data(nonFiniteJSON.utf8)
                )
                #expect(Bool(false), "Expected a non-finite value to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.count == 1)
                #expect(context.codingPath[0].intValue == 0)
                #expect(
                    context.underlyingError as? MetadataFloatingPointError
                        == .nonFiniteValue
                )
                #expect(!context.debugDescription.contains("Infinity"))
                #expect(!context.debugDescription.contains("NaN"))
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
