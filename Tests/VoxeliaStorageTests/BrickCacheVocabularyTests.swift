// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaStorage

@Suite("BrickCacheVocabulary")
struct BrickCacheVocabularyTests {
    private func consideration(
        generation: UInt64 = 5,
        cost: UInt64 = 10,
        bytes: UInt64 = 1_000,
        visible: Bool = false,
        references: Int = 0,
        ordinal: UInt64 = 0
    ) throws -> BrickEvictionConsideration {
        try BrickEvictionConsideration(
            lastAccessGeneration: generation,
            reconstructionCost: cost,
            byteCount: bytes,
            visible: visible,
            activeReferenceCount: references,
            insertionOrdinal: ordinal
        )
    }

    @Test("[Unit][VOX-BRK-008] the frozen order ranks every lexicographic step")
    func frozenOrderRanksEveryLexicographicStep() throws {
        // Each rank of the ADR-0151 order in isolation: visibility,
        // then generation, then cost, then size, then the insertion
        // ordinal tie-break — and the never-evictable rule.
        let invisible = try consideration(visible: false)
        let visible = try consideration(visible: true)
        #expect(invisible.evictsBefore(visible))
        #expect(!visible.evictsBefore(invisible))

        let older = try consideration(generation: 3)
        let newer = try consideration(generation: 7)
        #expect(older.evictsBefore(newer))
        #expect(!newer.evictsBefore(older))

        let cheap = try consideration(cost: 1)
        let costly = try consideration(cost: 50)
        #expect(cheap.evictsBefore(costly))
        #expect(!costly.evictsBefore(cheap))

        let large = try consideration(bytes: 4_096)
        let small = try consideration(bytes: 64)
        #expect(large.evictsBefore(small))
        #expect(!small.evictsBefore(large))

        let first = try consideration(ordinal: 1)
        let second = try consideration(ordinal: 2)
        #expect(first.evictsBefore(second))
        #expect(!second.evictsBefore(first))

        // Visibility outranks every later field: an invisible entry
        // evicts before a visible one even when the visible entry is
        // older, cheaper and larger.
        let visibleButOld = try consideration(
            generation: 0,
            cost: 0,
            bytes: 1_000_000,
            visible: true
        )
        #expect(invisible.evictsBefore(visibleButOld))

        let referenced = try consideration(references: 3)
        #expect(!referenced.isEvictable)
        #expect(invisible.isEvictable)
    }

    @Test("[Unit][VOX-CCH-007][VOX-CCH-009][VOX-ERR-001] values validate and reject typed")
    func valuesValidateAndRejectTyped() throws {
        #expect(throws: BrickCacheVocabularyError.invalidActiveReferenceCount) {
            try self.consideration(references: -1)
        }

        let format = try #require(CacheFormatID(rawValue: "org.voxelia.cache.brick-v1"))
        let version = CacheFormatVersion(
            format: format,
            version: try SemanticVersion(major: 1, minor: 0, patch: 0)
        )
        #expect(version.format.rawValue == "org.voxelia.cache.brick-v1")
        #expect(CacheFormatID(rawValue: "   ") == nil)

        let identity = try BrickIdentity(
            volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
            levelIndex: 0,
            coordinate: [1, 2, 3]
        )
        let events: [BrickCacheEvent] = [
            .hit(identity: identity, byteCount: 64),
            .miss(identity: identity),
            .eviction(identity: identity, byteCount: 64),
            .decode(identity: identity, byteCount: 64, costUnits: 9),
            .recomputation(identity: identity),
        ]
        #expect(Set(events).count == 5)
    }
}
