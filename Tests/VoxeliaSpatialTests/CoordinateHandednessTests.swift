// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("CoordinateHandedness")
struct CoordinateHandednessTests {
    @Test("[Unit][VOX-ARC-002][VOX-API-003] exposes the exact handedness taxonomy")
    func exposesExactRawValues() {
        let expected: [(handedness: CoordinateHandedness, rawValue: String)] = [
            (.rightHanded, "rightHanded"),
            (.leftHanded, "leftHanded"),
            (.unspecified, "unspecified"),
        ]

        for value in expected {
            #expect(value.handedness.rawValue == value.rawValue)
            #expect(CoordinateHandedness(rawValue: value.rawValue) == value.handedness)
        }
        #expect(CoordinateHandedness(rawValue: "righthanded") == nil)
        #expect(CoordinateHandedness(rawValue: "unknown") == nil)
    }

    @Test("[Unit][VOX-API-004] Codable uses exact raw strings")
    func codableUsesExactRawStrings() throws {
        let values: [CoordinateHandedness] = [
            .rightHanded,
            .leftHanded,
            .unspecified,
        ]

        for value in values {
            let data = try JSONEncoder().encode(value)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(value.rawValue)""#)
            #expect(try JSONDecoder().decode(CoordinateHandedness.self, from: data) == value)
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        do {
            _ = try JSONDecoder().decode(
                CoordinateHandedness.self,
                from: Data(#""unknown""#.utf8)
            )
            #expect(Bool(false), "Expected an unknown token to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.isEmpty)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(
                CoordinateHandedness.self,
                from: Data("null".utf8)
            )
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // Null is rejected for the non-optional raw value.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "{}", "[]"] {
            do {
                _ = try JSONDecoder().decode(
                    CoordinateHandedness.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped value to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-string shapes are rejected before raw-value lookup.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }
}
