// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import VoxeliaCore

@Suite("ImageIndex")
struct ImageIndexTests {
    @Test("[Unit][VOX-DAT-001] stores zero-based dynamic-rank coordinates")
    func storesDynamicRankCoordinates() {
        let index = ImageIndex(components: [0, 7, 12, 3])

        #expect(index.rank == 4)
        #expect(Array(index.components) == [0, 7, 12, 3])
    }

    @Test("[Unit][VOX-DAT-005] does not impose a small fixed maximum rank")
    func supportsHighRankIndices() {
        let components = 0..<1_024
        let index = ImageIndex(components: components)

        #expect(index.rank == 1_024)
        #expect(index.components.first == 0)
        #expect(index.components.last == 1_023)
    }

    @Test("[Unit][VOX-API-004] Codable round trips every component")
    func codableRoundTrip() throws {
        let index = ImageIndex(components: [0, 2, 5])

        let encoded = try JSONEncoder().encode(index)
        let decoded = try JSONDecoder().decode(ImageIndex.self, from: encoded)

        #expect(decoded == index)
    }
}
