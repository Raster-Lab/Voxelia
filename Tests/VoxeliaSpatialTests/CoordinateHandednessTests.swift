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

    @Test("[Unit][VOX-API-004] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        for json in [#""unknown""#, "1", "true", "null", "{}", "[]"] {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    CoordinateHandedness.self,
                    from: Data(json.utf8)
                )
            }
        }
    }
}
