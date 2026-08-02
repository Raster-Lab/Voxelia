// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("SpatialAxisMapping")
struct SpatialAxisMappingTests {
    @Test("[Unit][VOX-SPA-001] preserves one-to-three axes in X/Y/Z order")
    func preservesMappingOrder() throws {
        #expect(try SpatialAxisMapping(imageAxes: [0]).imageAxes == [0])
        #expect(try SpatialAxisMapping(imageAxes: [0, 2]).imageAxes == [0, 2])
        #expect(try SpatialAxisMapping(imageAxes: [2, 0, 4]).imageAxes == [2, 0, 4])

        let padded = [-1, 3, 1, 5, -1]
        #expect(
            try SpatialAxisMapping(imageAxes: padded[1...3]).imageAxes
                == [3, 1, 5]
        )
    }

    @Test("[Unit][VOX-ERR-001] rejects invalid mapping counts")
    func rejectsInvalidCounts() {
        for count in [0, 4, 10] {
            #expect(throws: SpatialAxisMappingError.invalidAxisCount(actual: count)) {
                try SpatialAxisMapping(imageAxes: Array(0..<count))
            }
        }
    }

    @Test("[Unit][VOX-ERR-001] rejects negative axes with exact context")
    func rejectsNegativeAxes() {
        #expect(throws: SpatialAxisMappingError.negativeAxis(position: 0, value: -1)) {
            try SpatialAxisMapping(imageAxes: [-1])
        }
        #expect(throws: SpatialAxisMappingError.negativeAxis(position: 1, value: Int.min)) {
            try SpatialAxisMapping(imageAxes: [0, Int.min])
        }
    }

    @Test("[Unit][VOX-ERR-001] rejects adjacent and separated duplicate axes")
    func rejectsDuplicateAxes() {
        #expect(
            throws: SpatialAxisMappingError.duplicateAxis(
                axis: 1,
                firstPosition: 0,
                duplicatePosition: 1
            )
        ) {
            try SpatialAxisMapping(imageAxes: [1, 1])
        }
        #expect(
            throws: SpatialAxisMappingError.duplicateAxis(
                axis: 2,
                firstPosition: 0,
                duplicatePosition: 2
            )
        ) {
            try SpatialAxisMapping(imageAxes: [2, 0, 2])
        }
    }

    @Test("[Unit] defers only the image-rank upper bound to descriptor binding")
    func defersUpperRankBound() throws {
        let mapping = try SpatialAxisMapping(imageAxes: [0, Int.max, 42])

        #expect(mapping.imageAxes == [0, Int.max, 42])
    }

    @Test("[Unit][VOX-API-004] Codable preserves structure and revalidates input")
    func codableRoundTripAndValidation() throws {
        let mapping = try SpatialAxisMapping(imageAxes: [2, 0, 4])
        let encoded = try JSONEncoder().encode(mapping)
        #expect(try JSONDecoder().decode(SpatialAxisMapping.self, from: encoded) == mapping)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        #expect(Set(object.keys) == ["imageAxes"])
        #expect(try #require(object["imageAxes"] as? [Int]) == [2, 0, 4])

        let invalidValues = [
            #"{"imageAxes":[]}"#,
            #"{"imageAxes":[0,1,2,3]}"#,
            #"{"imageAxes":[0,-1]}"#,
            #"{"imageAxes":[0,1,0]}"#,
            #"{"imageAxes":[0,1],"extra":true}"#,
            #"[0,1]"#,
        ]
        for invalidValue in invalidValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    SpatialAxisMapping.self,
                    from: Data(invalidValue.utf8)
                )
            }
        }
    }
}
