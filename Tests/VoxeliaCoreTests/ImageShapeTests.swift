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
