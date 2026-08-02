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

    @Test("[Unit][VOX-RGN-001] constructs exact bounds from an origin and extents")
    func constructsBoundsFromExtents() throws {
        let shape = try ImageShape(extents: [3, 4, 5])
        let region = try ImageRegion(
            lowerBounds: [-2, 10, 0],
            extents: shape
        )

        #expect(Array(region.lowerBounds) == [-2, 10, 0])
        #expect(Array(region.upperBounds) == [1, 14, 5])
        #expect(try region.extents() == shape)
    }

    @Test("[Unit][VOX-RGN-002] extent construction requires exact rank")
    func extentConstructionRejectsRankMismatch() throws {
        let shape = try ImageShape(extents: [3, 4, 5])

        #expect(throws: RegionError.rankMismatch) {
            try ImageRegion(lowerBounds: [0, 0], extents: shape)
        }
        #expect(throws: RegionError.rankMismatch) {
            try ImageRegion(lowerBounds: [0, 0, 0, 0], extents: shape)
        }
    }

    @Test("[Unit][VOX-RGN-002] extent construction detects upper-bound overflow")
    func extentConstructionRejectsUpperBoundOverflow() throws {
        let shape = try ImageShape(extents: [1, 3, 1])
        let boundaryShape = try ImageShape(extents: [1, 1])
        let boundaryRegion = try ImageRegion(
            lowerBounds: [Int.max - 1, Int.min],
            extents: boundaryShape
        )

        #expect(Array(boundaryRegion.upperBounds) == [Int.max, Int.min + 1])

        #expect(throws: RegionError.arithmeticOverflow) {
            try ImageRegion(
                lowerBounds: [0, Int.max - 2, 0],
                extents: shape
            )
        }
    }

    @Test("[Unit][VOX-DAT-005] extent construction preserves dynamic rank")
    func extentConstructionSupportsHighRank() throws {
        let shape = try ImageShape(extents: repeatElement(1, count: 1_024))
        let lowerBounds = repeatElement(-1, count: 1_024)
        let region = try ImageRegion(lowerBounds: lowerBounds, extents: shape)

        #expect(region.rank == 1_024)
        #expect(region.lowerBounds.allSatisfy { $0 == -1 })
        #expect(region.upperBounds.allSatisfy { $0 == 0 })
    }

    @Test("[Unit][VOX-API-004] both construction forms have one canonical value")
    func extentConstructionUsesCanonicalRepresentation() throws {
        let shape = try ImageShape(extents: [3, 6])
        let fromExtents = try ImageRegion(lowerBounds: [2, 5], extents: shape)
        let fromBounds = try ImageRegion(
            lowerBounds: [2, 5],
            upperBounds: [5, 11]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        #expect(fromExtents == fromBounds)
        let encoded = try encoder.encode(fromExtents)
        let boundsEncoded = try encoder.encode(fromBounds)
        #expect(encoded == boundsEncoded)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: [Int]]
        )
        #expect(
            object == [
                "lowerBounds": [2, 5],
                "upperBounds": [5, 11],
            ]
        )
    }

    @Test("[Unit][VOX-DAT-003] invalid extents cannot enter region construction")
    func extentConstructionRequiresValidatedShape() {
        #expect(throws: ShapeError.nonPositiveExtent(axis: 1, value: 0)) {
            let shape = try ImageShape(extents: [3, 0])
            _ = try ImageRegion(lowerBounds: [0, 0], extents: shape)
        }
    }

    @Test("[Unit][VOX-STO-007][VOX-SEC-001] accepts contained half-open bounds")
    func validatesContainedBounds() throws {
        let shape = try ImageShape(extents: [5, 10])
        let full = try ImageRegion(
            lowerBounds: [0, 0],
            upperBounds: [5, 10]
        )
        let interior = try ImageRegion(
            lowerBounds: [1, 2],
            upperBounds: [4, 9]
        )

        try full.validateContainment(in: shape)
        try interior.validateContainment(in: shape)
    }

    @Test("[Unit][VOX-STO-007][VOX-SEC-001] rejects bounds outside the shape")
    func rejectsBoundsOutsideShape() throws {
        let shape = try ImageShape(extents: [5, 10])
        let negative = try ImageRegion(
            lowerBounds: [-1, 2],
            upperBounds: [4, 9]
        )
        let oversized = try ImageRegion(
            lowerBounds: [1, 2],
            upperBounds: [4, 11]
        )

        #expect(throws: RegionError.outsideShape) {
            try negative.validateContainment(in: shape)
        }
        #expect(throws: RegionError.outsideShape) {
            try oversized.validateContainment(in: shape)
        }
    }

    @Test("[Unit][VOX-STO-007] containment requires exact rank")
    func containmentRejectsRankMismatch() throws {
        let shape = try ImageShape(extents: [5])
        let region = try ImageRegion(
            lowerBounds: [0, 0],
            upperBounds: [1, 1]
        )

        #expect(throws: RegionError.rankMismatch) {
            try region.validateContainment(in: shape)
        }
    }

    @Test("[Unit][VOX-STO-007] validates empty-region boundary anchors")
    func containmentValidatesEmptyBoundaryAnchors() throws {
        let shape = try ImageShape(extents: [10])
        let atOrigin = try ImageRegion(lowerBounds: [0], upperBounds: [0])
        let atUpperBoundary = try ImageRegion(
            lowerBounds: [10],
            upperBounds: [10]
        )
        let belowShape = try ImageRegion(lowerBounds: [-1], upperBounds: [-1])
        let aboveShape = try ImageRegion(lowerBounds: [11], upperBounds: [11])

        try atOrigin.validateContainment(in: shape)
        try atUpperBoundary.validateContainment(in: shape)
        #expect(throws: RegionError.outsideShape) {
            try belowShape.validateContainment(in: shape)
        }
        #expect(throws: RegionError.outsideShape) {
            try aboveShape.validateContainment(in: shape)
        }
    }

    @Test("[Unit][VOX-SEC-001] containment handles the maximum shape boundary")
    func containmentHandlesMaximumBoundary() throws {
        let shape = try ImageShape(extents: [Int.max])
        let boundary = try ImageRegion(
            lowerBounds: [Int.max],
            upperBounds: [Int.max]
        )
        let lastElement = try ImageRegion(
            lowerBounds: [Int.max - 1],
            upperBounds: [Int.max]
        )

        try boundary.validateContainment(in: shape)
        try lastElement.validateContainment(in: shape)
    }

    @Test("[Unit] translates every bound by mixed-sign offsets")
    func translatesByMixedSignOffsets() throws {
        let region = try ImageRegion(
            lowerBounds: [2, 5, -4],
            upperBounds: [5, 10, 1]
        )
        let translated = try region.translated(by: [-3, 2, 4])
        let originalExtents = try region.extents()
        let translatedExtents = try translated.extents()

        #expect(Array(translated.lowerBounds) == [-1, 7, 0])
        #expect(Array(translated.upperBounds) == [2, 12, 5])
        #expect(translatedExtents == originalExtents)
    }

    @Test("[Unit] translation preserves empty axes without clamping")
    func translationPreservesEmptyAxes() throws {
        let region = try ImageRegion(
            lowerBounds: [2, 5],
            upperBounds: [2, 9]
        )
        let translated = try region.translated(by: [-4, 3])

        #expect(Array(translated.lowerBounds) == [-2, 8])
        #expect(Array(translated.upperBounds) == [-2, 12])
    }

    @Test("[Unit][VOX-RGN-002] translation requires exact offset rank")
    func translationRejectsRankMismatch() throws {
        let region = try ImageRegion(
            lowerBounds: [0, 0],
            upperBounds: [1, 1]
        )

        #expect(throws: RegionError.rankMismatch) {
            try region.translated(by: [1])
        }
        #expect(throws: RegionError.rankMismatch) {
            try region.translated(by: [1, 2, 3])
        }
    }

    @Test("[Unit][VOX-RGN-002] translation checks both bound arrays for overflow")
    func translationRejectsEveryOverflowBoundary() throws {
        let lowerOverflow = try ImageRegion(
            lowerBounds: [Int.min],
            upperBounds: [Int.min + 1]
        )
        let upperOverflow = try ImageRegion(
            lowerBounds: [Int.max - 1],
            upperBounds: [Int.max]
        )

        #expect(throws: RegionError.arithmeticOverflow) {
            try lowerOverflow.translated(by: [-1])
        }
        #expect(throws: RegionError.arithmeticOverflow) {
            try upperOverflow.translated(by: [1])
        }
    }

    @Test("[Unit][VOX-RGN-002] translation accepts exact Int boundaries")
    func translationAcceptsExactIntegerBoundaries() throws {
        let region = try ImageRegion(
            lowerBounds: [Int.min + 1, Int.max - 2],
            upperBounds: [Int.min + 2, Int.max - 1]
        )
        let translated = try region.translated(by: [-1, 1])

        #expect(Array(translated.lowerBounds) == [Int.min, Int.max - 1])
        #expect(Array(translated.upperBounds) == [Int.min + 1, Int.max])
    }

    @Test("[Unit][VOX-DAT-005] zero translation preserves a high-rank value")
    func zeroTranslationPreservesHighRankValue() throws {
        let region = try ImageRegion(
            lowerBounds: repeatElement(-1, count: 1_024),
            upperBounds: repeatElement(1, count: 1_024)
        )
        let translated = try region.translated(
            by: repeatElement(0, count: 1_024)
        )

        #expect(translated == region)
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
