// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import VoxeliaCore

@Suite("ImageRegion")
struct ImageRegionTests {
    @Test("[Unit][VOX-RGN-001] stores dynamic-rank half-open bounds")
    func storesDynamicRankBounds() throws {
        let region = try ImageRegion(
            lowerBounds: [2, 4, 8],
            upperBounds: [5, 10, 20]
        )

        #expect(region.rank == 3)
        #expect(Array(region.lowerBounds) == [2, 4, 8])
        #expect(Array(region.upperBounds) == [5, 10, 20])
    }

    @Test("[Unit][VOX-RGN-001] converts half-open bounds to extents")
    func calculatesHalfOpenExtents() throws {
        let region = try ImageRegion(lowerBounds: [2, 5], upperBounds: [5, 11])

        let shape = try region.extents()

        #expect(Array(shape.extents) == [3, 6])
    }

    @Test("[Unit][VOX-RGN-002] rejects a rank mismatch")
    func rejectsRankMismatch() {
        #expect(throws: RegionError.rankMismatch) {
            try ImageRegion(lowerBounds: [0, 0], upperBounds: [1])
        }
    }

    @Test("[Unit][VOX-RGN-002] reports the first inverted axis")
    func rejectsInvertedBounds() {
        #expect(throws: RegionError.invertedBounds(axis: 1, lower: 5, upper: 4)) {
            try ImageRegion(
                lowerBounds: [0, 5, 3],
                upperBounds: [1, 4, 2]
            )
        }
    }

    @Test("[Unit][VOX-RGN-001] permits an empty transient region")
    func permitsEmptyTransientRegion() throws {
        let region = try ImageRegion(lowerBounds: [2, 5], upperBounds: [2, 9])

        #expect(region.rank == 2)
        #expect(region.lowerBounds[0] == region.upperBounds[0])
    }

    @Test("[Unit][VOX-RGN-002] empty bounds cannot form an ImageShape")
    func emptyRegionHasNoImageShape() throws {
        let region = try ImageRegion(lowerBounds: [2, 5], upperBounds: [2, 9])

        #expect(throws: ShapeError.nonPositiveExtent(axis: 0, value: 0)) {
            try region.extents()
        }
    }

    @Test("[Unit][VOX-RGN-002] rejects extent overflow during construction")
    func rejectsExtentOverflowDuringConstruction() {
        #expect(throws: RegionError.arithmeticOverflow) {
            try ImageRegion(
                lowerBounds: [Int.min],
                upperBounds: [Int.max]
            )
        }
    }

    @Test("[Unit][VOX-DAT-005] does not impose a small fixed maximum rank")
    func supportsHighRankRegions() throws {
        let region = try ImageRegion(
            lowerBounds: repeatElement(0, count: 1_024),
            upperBounds: repeatElement(1, count: 1_024)
        )

        #expect(region.rank == 1_024)
        #expect(try region.extents().rank == 1_024)
    }

    @Test("[Unit][VOX-API-004] Codable round trips validated bounds")
    func codableRoundTrip() throws {
        let region = try ImageRegion(lowerBounds: [0, 2], upperBounds: [8, 12])

        let encoded = try JSONEncoder().encode(region)
        let decoded = try JSONDecoder().decode(ImageRegion.self, from: encoded)

        #expect(decoded == region)
    }

    @Test("[Unit][VOX-RGN-002] decoding rejects a rank mismatch")
    func decodingRejectsRankMismatch() {
        let invalidRegion = Data(
            #"{"lowerBounds":[0,0],"upperBounds":[1]}"#.utf8
        )

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ImageRegion.self, from: invalidRegion)
        }
    }

    @Test("[Unit][VOX-RGN-002] decoding rejects inverted bounds")
    func decodingRejectsInvertedBounds() {
        let invalidRegion = Data(
            #"{"lowerBounds":[0,4],"upperBounds":[1,3]}"#.utf8
        )

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ImageRegion.self, from: invalidRegion)
        }
    }

    @Test("[Unit][VOX-RGN-002] decoding rejects extent overflow")
    func decodingRejectsExtentOverflow() {
        let invalidRegion = Data(
            "{\"lowerBounds\":[\(Int.min)],\"upperBounds\":[\(Int.max)]}".utf8
        )

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ImageRegion.self, from: invalidRegion)
        }
    }
}
