// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("SpatialTransformKind")
struct SpatialTransformKindTests {
    @Test("[Unit][VOX-ARC-002][VOX-API-003] exposes the exact transform taxonomy")
    func exposesExactRawValues() {
        let expected: [(kind: SpatialTransformKind, rawValue: String)] = [
            (.identity, "identity"),
            (.rigid, "rigid"),
            (.similarity, "similarity"),
            (.affine, "affine"),
            (.composite, "composite"),
            (.deformationField, "deformationField"),
        ]

        for value in expected {
            #expect(value.kind.rawValue == value.rawValue)
            #expect(SpatialTransformKind(rawValue: value.rawValue) == value.kind)
        }
        #expect(SpatialTransformKind(rawValue: "deformationfield") == nil)
        #expect(SpatialTransformKind(rawValue: "unknown") == nil)
    }

    @Test("[Unit][VOX-API-004][VOX-REG-001] Codable uses exact raw strings")
    func codableUsesExactRawStrings() throws {
        let values: [SpatialTransformKind] = [
            .identity,
            .rigid,
            .similarity,
            .affine,
            .composite,
            .deformationField,
        ]

        for value in values {
            let data = try JSONEncoder().encode(value)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(value.rawValue)""#)
            #expect(try JSONDecoder().decode(SpatialTransformKind.self, from: data) == value)
        }
    }

    @Test("[Unit][VOX-API-004] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        for json in [#""unknown""#, "1", "true", "null", "{}", "[]"] {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    SpatialTransformKind.self,
                    from: Data(json.utf8)
                )
            }
        }
    }
}
