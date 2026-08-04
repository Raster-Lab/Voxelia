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

    @Test("[Unit][CDMS-13.3] nonempty regions report false")
    func nonemptyRegionIsNotEmpty() throws {
        let region = try ImageRegion(
            lowerBounds: [-3, 0, 7],
            upperBounds: [-2, 1, 8]
        )

        #expect(!region.isEmpty)
    }

    @Test("[Unit][CDMS-13.3] every collapsed axis reports empty")
    func collapsedAxisMakesRegionEmpty() throws {
        let lowerBounds = [2, 5, 8]
        for emptyAxis in lowerBounds.indices {
            var upperBounds = [3, 9, 12]
            upperBounds[emptyAxis] = lowerBounds[emptyAxis]
            let region = try ImageRegion(
                lowerBounds: lowerBounds,
                upperBounds: upperBounds
            )

            #expect(region.isEmpty)
        }
    }

    @Test("[Unit][CDMS-13.3] exact Int anchors report empty")
    func extremeAnchorsReportEmpty() throws {
        let anchors = [Int.min, -1, Int.max]

        for anchor in anchors {
            let region = try ImageRegion(
                lowerBounds: [anchor],
                upperBounds: [anchor]
            )
            #expect(region.isEmpty)
        }
    }

    @Test("[Unit][VOX-DAT-005][CDMS-13.3] high-rank collapse reports empty")
    func highRankCollapsedAxisReportsEmpty() throws {
        let lowerBounds = ContiguousArray(repeatElement(0, count: 1_024))
        var upperBounds = ContiguousArray(repeatElement(1, count: 1_024))
        upperBounds[1_023] = 0
        let region = try ImageRegion(
            lowerBounds: lowerBounds,
            upperBounds: upperBounds
        )

        #expect(region.isEmpty)
    }

    @Test("[Unit][CDMS-13.3] zero-rank region has no collapsed axis")
    func zeroRankRegionIsNotEmpty() throws {
        let region = try ImageRegion(
            lowerBounds: [Int](),
            upperBounds: [Int]()
        )

        #expect(!region.isEmpty)
    }

    @Test("[Unit][CDMS-13.4] element count multiplies exact extents")
    func elementCountUsesExactExtents() throws {
        let region = try ImageRegion(
            lowerBounds: [-5, 2, 10],
            upperBounds: [0, 5, 14]
        )

        #expect(try region.elementCount() == 60)
    }

    @Test("[Unit][CDMS-13.4] collapsed axes have zero elements")
    func emptyRegionHasZeroElements() throws {
        let region = try ImageRegion(
            lowerBounds: [0, 0, 4],
            upperBounds: [Int.max, 2, 4]
        )

        #expect(try region.elementCount() == 0)
    }

    @Test("[Unit][CDMS-13.4] exact maximum element count succeeds")
    func elementCountAcceptsIntegerMaximum() throws {
        let region = try ImageRegion(
            lowerBounds: [0, -1],
            upperBounds: [Int.max, 0]
        )

        #expect(try region.elementCount() == Int.max)
    }

    @Test("[Unit][CDMS-13.4] element count detects overflow")
    func elementCountRejectsOverflow() throws {
        let region = try ImageRegion(
            lowerBounds: [0, 0],
            upperBounds: [Int.max, 2]
        )

        #expect(throws: RegionError.arithmeticOverflow) {
            try region.elementCount()
        }
    }

    @Test("[Unit][CDMS-13.4] zero-rank element count is the empty product")
    func zeroRankRegionHasOneElement() throws {
        let region = try ImageRegion(
            lowerBounds: [Int](),
            upperBounds: [Int]()
        )

        #expect(try region.elementCount() == 1)
    }

    @Test("[Unit][VOX-DAT-005][CDMS-13.4] element count supports high rank")
    func elementCountSupportsHighRank() throws {
        let region = try ImageRegion(
            lowerBounds: repeatElement(-1, count: 1_024),
            upperBounds: repeatElement(0, count: 1_024)
        )

        #expect(try region.elementCount() == 1)
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

    @Test("[Unit][CDMS-13.4] index containment includes every lower face")
    func indexContainmentIncludesLowerBounds() throws {
        let region = try ImageRegion(
            lowerBounds: [1, 2, 3],
            upperBounds: [5, 6, 7]
        )
        let contained = [
            ImageIndex(components: [3, 4, 5]),
            ImageIndex(components: [1, 2, 3]),
            ImageIndex(components: [1, 4, 5]),
            ImageIndex(components: [3, 2, 5]),
            ImageIndex(components: [3, 4, 3]),
        ]

        for index in contained {
            #expect(try region.contains(index))
        }
    }

    @Test("[Unit][CDMS-13.4] index containment excludes upper bounds and beyond")
    func indexContainmentExcludesUpperBounds() throws {
        let region = try ImageRegion(
            lowerBounds: [1, 2, 3],
            upperBounds: [5, 6, 7]
        )
        let excluded = [
            ImageIndex(components: [5, 4, 5]),
            ImageIndex(components: [3, 6, 5]),
            ImageIndex(components: [3, 4, 7]),
            ImageIndex(components: [6, 4, 5]),
            ImageIndex(components: [3, 7, 5]),
            ImageIndex(components: [3, 4, 8]),
        ]

        for index in excluded {
            #expect(try !region.contains(index))
        }
    }

    @Test("[Unit][CDMS-13.4] index containment rejects every lower outside axis")
    func indexContainmentRejectsLowerOutsideComponents() throws {
        let region = try ImageRegion(
            lowerBounds: [1, 2, 3],
            upperBounds: [5, 6, 7]
        )
        let excluded = [
            ImageIndex(components: [0, 4, 5]),
            ImageIndex(components: [3, 1, 5]),
            ImageIndex(components: [3, 4, 2]),
        ]

        for index in excluded {
            #expect(try !region.contains(index))
        }
    }

    @Test("[Unit][CDMS-13.4] empty regions contain no index")
    func emptyRegionContainsNoIndex() throws {
        let lowerBounds = [2, 5, 8]
        for emptyAxis in lowerBounds.indices {
            var upperBounds = [3, 9, 12]
            upperBounds[emptyAxis] = lowerBounds[emptyAxis]
            let region = try ImageRegion(
                lowerBounds: lowerBounds,
                upperBounds: upperBounds
            )

            #expect(try !region.contains(ImageIndex(components: lowerBounds)))
        }

        let zeroRankRegion = try ImageRegion(
            lowerBounds: [Int](),
            upperBounds: [Int]()
        )
        #expect(try zeroRankRegion.contains(ImageIndex(components: [Int]())))
    }

    @Test("[Unit][CDMS-13.4] index containment supports negative coordinates")
    func indexContainmentSupportsNegativeCoordinates() throws {
        let region = try ImageRegion(
            lowerBounds: [-5, -3],
            upperBounds: [0, 2]
        )

        #expect(try region.contains(ImageIndex(components: [-5, -3])))
        #expect(try region.contains(ImageIndex(components: [-1, 1])))
        #expect(try !region.contains(ImageIndex(components: [-6, 0])))
        #expect(try !region.contains(ImageIndex(components: [0, 0])))
        #expect(try !region.contains(ImageIndex(components: [-1, 2])))
    }

    @Test("[Unit][CDMS-13.4] index containment requires exact rank")
    func indexContainmentRejectsRankMismatch() throws {
        let region = try ImageRegion(
            lowerBounds: [0, 0],
            upperBounds: [1, 1]
        )

        #expect(throws: RegionError.rankMismatch) {
            try region.contains(ImageIndex(components: [0]))
        }
        #expect(throws: RegionError.rankMismatch) {
            try region.contains(ImageIndex(components: [0, 0, 0]))
        }
    }

    @Test("[Unit][CDMS-13.4] index containment handles exact Int boundaries")
    func indexContainmentHandlesIntegerBoundaries() throws {
        let region = try ImageRegion(
            lowerBounds: [Int.min, Int.max - 1],
            upperBounds: [Int.min + 1, Int.max]
        )

        #expect(
            try region.contains(
                ImageIndex(components: [Int.min, Int.max - 1])
            )
        )
        #expect(
            try !region.contains(
                ImageIndex(components: [Int.min + 1, Int.max - 1])
            )
        )
        #expect(
            try !region.contains(
                ImageIndex(components: [Int.min, Int.max])
            )
        )
    }

    @Test("[Unit][CDMS-13.4][VOX-DAT-005] index containment supports high rank")
    func indexContainmentSupportsHighRank() throws {
        let region = try ImageRegion(
            lowerBounds: repeatElement(0, count: 1_024),
            upperBounds: repeatElement(2, count: 1_024)
        )
        let contained = ImageIndex(components: repeatElement(1, count: 1_024))
        var outsideComponents = ContiguousArray(
            repeatElement(1, count: 1_024)
        )
        outsideComponents[1_023] = 2

        #expect(try region.contains(contained))
        #expect(try !region.contains(ImageIndex(components: outsideComponents)))
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

    @Test("[Unit][CDMS-13.4] clipping preserves a region already inside the shape")
    func clippingPreservesContainedRegion() throws {
        let shape = try ImageShape(extents: [5, 10])
        let region = try ImageRegion(
            lowerBounds: [1, 2],
            upperBounds: [4, 9]
        )
        let clipped = try region.clipped(to: shape)

        #expect(clipped == region)
    }

    @Test("[Unit][CDMS-13.4] clipping trims partial overlap on every boundary")
    func clippingTrimsPartialOverlap() throws {
        let shape = try ImageShape(extents: [5, 10])
        let region = try ImageRegion(
            lowerBounds: [-3, 2],
            upperBounds: [7, 12]
        )
        let clipped = try region.clipped(to: shape)

        #expect(Array(clipped.lowerBounds) == [0, 2])
        #expect(Array(clipped.upperBounds) == [5, 10])
    }

    @Test("[Unit][CDMS-13.4] disjoint clipping returns deterministic boundary empties")
    func clippingReturnsBoundaryEmptyRegions() throws {
        let shape = try ImageShape(extents: [10])
        let below = try ImageRegion(
            lowerBounds: [Int.min],
            upperBounds: [Int.min + 1]
        )
        let above = try ImageRegion(
            lowerBounds: [Int.max - 1],
            upperBounds: [Int.max]
        )
        let clippedBelow = try below.clipped(to: shape)
        let clippedAbove = try above.clipped(to: shape)

        #expect(Array(clippedBelow.lowerBounds) == [0])
        #expect(Array(clippedBelow.upperBounds) == [0])
        #expect(Array(clippedAbove.lowerBounds) == [10])
        #expect(Array(clippedAbove.upperBounds) == [10])
    }

    @Test("[Unit][CDMS-13.4] clipping relocates only out-of-shape empty anchors")
    func clippingHandlesEmptyAnchors() throws {
        let shape = try ImageShape(extents: [10])
        let below = try ImageRegion(lowerBounds: [-1], upperBounds: [-1])
        let interior = try ImageRegion(lowerBounds: [4], upperBounds: [4])
        let boundary = try ImageRegion(lowerBounds: [10], upperBounds: [10])
        let above = try ImageRegion(lowerBounds: [11], upperBounds: [11])
        let originBoundary = try ImageRegion(
            lowerBounds: [0],
            upperBounds: [0]
        )
        let upperBoundary = try ImageRegion(
            lowerBounds: [10],
            upperBounds: [10]
        )
        let clippedBelow = try below.clipped(to: shape)
        let clippedInterior = try interior.clipped(to: shape)
        let clippedBoundary = try boundary.clipped(to: shape)
        let clippedAbove = try above.clipped(to: shape)

        #expect(clippedBelow == originBoundary)
        #expect(clippedInterior == interior)
        #expect(clippedBoundary == boundary)
        #expect(clippedAbove == upperBoundary)
    }

    @Test("[Unit][CDMS-13.4] mixed-axis clipping anchors each component")
    func clippingAnchorsMixedDisjointAxes() throws {
        let shape = try ImageShape(extents: [10, 20, 30])
        let disjoint = try ImageRegion(
            lowerBounds: [-5, 25, 5],
            upperBounds: [-2, 27, 12]
        )
        let empty = try ImageRegion(
            lowerBounds: [-5, 25, 7],
            upperBounds: [-5, 25, 7]
        )
        let clippedDisjoint = try disjoint.clipped(to: shape)
        let clippedEmpty = try empty.clipped(to: shape)

        #expect(Array(clippedDisjoint.lowerBounds) == [0, 20, 5])
        #expect(Array(clippedDisjoint.upperBounds) == [0, 20, 12])
        #expect(Array(clippedEmpty.lowerBounds) == [0, 20, 7])
        #expect(Array(clippedEmpty.upperBounds) == [0, 20, 7])
    }

    @Test("[Unit][CDMS-13.4][VOX-RGN-002] clipping requires exact shape rank")
    func clippingRejectsRankMismatch() throws {
        let region = try ImageRegion(
            lowerBounds: [0, 0],
            upperBounds: [1, 1]
        )
        let shortShape = try ImageShape(extents: [1])
        let longShape = try ImageShape(extents: [1, 1, 1])

        #expect(throws: RegionError.rankMismatch) {
            try region.clipped(to: shortShape)
        }
        #expect(throws: RegionError.rankMismatch) {
            try region.clipped(to: longShape)
        }
    }

    @Test("[Unit][CDMS-13.4][VOX-DAT-005] clipping preserves high dynamic rank")
    func clippingPreservesHighRank() throws {
        let shape = try ImageShape(extents: repeatElement(4, count: 1_024))
        let region = try ImageRegion(
            lowerBounds: repeatElement(-1, count: 1_024),
            upperBounds: repeatElement(5, count: 1_024)
        )
        let clipped = try region.clipped(to: shape)

        #expect(clipped.rank == 1_024)
        #expect(clipped.lowerBounds.allSatisfy { $0 == 0 })
        #expect(clipped.upperBounds.allSatisfy { $0 == 4 })
    }

    @Test("[Unit][VOX-RGN-002][VOX-ERR-001] rejects a rank mismatch")
    func rejectsRankMismatch() {
        #expect(throws: RegionError.rankMismatch) {
            try ImageRegion(lowerBounds: [0, 0], upperBounds: [1])
        }
    }

    @Test("[Unit][VOX-RGN-002][VOX-ERR-001] reports the first inverted axis")
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

    @Test("[Unit][VOX-RGN-002][VOX-ERR-001] decoding rejects a rank mismatch")
    func decodingRejectsRankMismatch() {
        let invalidRegion = Data(
            #"{"lowerBounds":[0,0],"upperBounds":[1]}"#.utf8
        )

        do {
            _ = try JSONDecoder().decode(ImageRegion.self, from: invalidRegion)
            #expect(Bool(false), "Expected rank-mismatched region to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.isEmpty)
            #expect(context.underlyingError as? RegionError == .rankMismatch)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    @Test("[Unit][VOX-RGN-002][VOX-ERR-001] decoding rejects inverted bounds")
    func decodingRejectsInvertedBounds() {
        let invalidRegion = Data(
            #"{"lowerBounds":[0,4],"upperBounds":[1,3]}"#.utf8
        )

        do {
            _ = try JSONDecoder().decode(ImageRegion.self, from: invalidRegion)
            #expect(Bool(false), "Expected inverted-bounds region to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.isEmpty)
            #expect(
                context.underlyingError as? RegionError
                    == .invertedBounds(axis: 1, lower: 4, upper: 3)
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
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
