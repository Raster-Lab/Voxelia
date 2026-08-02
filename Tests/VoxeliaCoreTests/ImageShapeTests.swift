// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import VoxeliaCore

@Suite("ImageShape")
struct ImageShapeTests {
    @Test("[Unit][VOX-DAT-002] stores positive variable-length extents")
    func storesDynamicRankExtents() throws {
        let shape = try ImageShape(extents: [512, 512, 128, 20])

        #expect(shape.rank == 4)
        #expect(Array(shape.extents) == [512, 512, 128, 20])
        #expect(try shape.elementCount() == 671_088_640)
    }

    @Test("[Unit][VOX-DAT-003] rejects an empty rank")
    func rejectsEmptyRank() {
        #expect(throws: ShapeError.emptyRank) {
            try ImageShape(extents: [Int]())
        }
    }

    @Test("[Unit][VOX-DAT-003] identifies zero and negative extents")
    func rejectsNonPositiveExtents() {
        #expect(throws: ShapeError.nonPositiveExtent(axis: 1, value: 0)) {
            try ImageShape(extents: [8, 0, 4])
        }
        #expect(throws: ShapeError.nonPositiveExtent(axis: 0, value: -2)) {
            try ImageShape(extents: [-2, 8])
        }
    }

    @Test("[Unit][VOX-DAT-004] reports element-count overflow")
    func reportsElementCountOverflow() throws {
        let shape = try ImageShape(extents: [Int.max, 2])

        #expect(throws: ShapeError.elementCountOverflow) {
            try shape.elementCount()
        }
    }

    @Test("[Unit][VOX-DAT-004] accepts the maximum non-overflowing element count")
    func acceptsMaximumElementCount() throws {
        let shape = try ImageShape(extents: [Int.max])

        #expect(shape.rank == 1)
        #expect(try shape.elementCount() == Int.max)
    }

    @Test("[Unit][VOX-DAT-005] does not impose a small fixed maximum rank")
    func supportsHighRankShapes() throws {
        let shape = try ImageShape(extents: repeatElement(1, count: 1_024))

        #expect(shape.rank == 1_024)
        #expect(try shape.elementCount() == 1)
    }

    @Test("[Unit][CDMS-12.3] index containment includes exact valid boundaries")
    func indexContainmentIncludesValidBoundaries() throws {
        let shape = try ImageShape(extents: [3, 5, 7])

        #expect(try shape.contains(ImageIndex(components: [0, 0, 0])))
        #expect(try shape.contains(ImageIndex(components: [2, 4, 6])))
    }

    @Test("[Unit][CDMS-12.3] index containment excludes each negative axis")
    func indexContainmentExcludesNegativeComponents() throws {
        let shape = try ImageShape(extents: [3, 5, 7])

        for axis in shape.extents.indices {
            var components = [0, 0, 0]
            components[axis] = -1
            #expect(try !shape.contains(ImageIndex(components: components)))
        }
    }

    @Test("[Unit][CDMS-12.3] index containment excludes each upper axis")
    func indexContainmentExcludesUpperAndBeyondComponents() throws {
        let shape = try ImageShape(extents: [3, 5, 7])

        for axis in shape.extents.indices {
            var components = [0, 0, 0]
            components[axis] = shape.extents[axis]
            #expect(try !shape.contains(ImageIndex(components: components)))

            components[axis] = shape.extents[axis] + 1
            #expect(try !shape.contains(ImageIndex(components: components)))
        }
    }

    @Test("[Unit][CDMS-12.3] index containment compares exact Int boundaries")
    func indexContainmentHandlesIntegerBoundaries() throws {
        let shape = try ImageShape(extents: [Int.max])

        #expect(try shape.contains(ImageIndex(components: [Int.max - 1])))
        #expect(try !shape.contains(ImageIndex(components: [Int.max])))
        #expect(try !shape.contains(ImageIndex(components: [Int.min])))
    }

    @Test("[Unit][CDMS-11.5] index containment reports exact rank mismatch")
    func indexContainmentRejectsRankMismatch() throws {
        let shape = try ImageShape(extents: [3, 5])

        #expect(throws: ShapeError.rankMismatch(expected: 2, actual: 0)) {
            try shape.contains(ImageIndex(components: [Int]()))
        }
        #expect(throws: ShapeError.rankMismatch(expected: 2, actual: 1)) {
            try shape.contains(ImageIndex(components: [0]))
        }
        #expect(throws: ShapeError.rankMismatch(expected: 2, actual: 3)) {
            try shape.contains(ImageIndex(components: [0, 0, 0]))
        }
    }

    @Test("[Unit][VOX-DAT-005] index containment supports high rank")
    func indexContainmentSupportsHighRank() throws {
        let shape = try ImageShape(extents: repeatElement(2, count: 1_024))
        let contained = ImageIndex(components: repeatElement(1, count: 1_024))
        var outsideComponents = ContiguousArray(
            repeatElement(1, count: 1_024)
        )
        outsideComponents[1_023] = 2

        #expect(try shape.contains(contained))
        #expect(try !shape.contains(ImageIndex(components: outsideComponents)))
    }

    @Test("[Unit] Codable round trips a validated shape")
    func codableRoundTrip() throws {
        let shape = try ImageShape(extents: [64, 32, 12])

        let encoded = try JSONEncoder().encode(shape)
        let decoded = try JSONDecoder().decode(ImageShape.self, from: encoded)

        #expect(decoded == shape)
    }

    @Test("[Unit] Decoding cannot bypass shape invariants")
    func decodingRejectsInvalidExtents() {
        let invalidShape = Data(#"{"extents":[8,0,4]}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ImageShape.self, from: invalidShape)
        }
    }
}
