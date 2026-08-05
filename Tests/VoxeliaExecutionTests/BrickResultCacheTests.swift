// SPDX-License-Identifier: MIT

import Foundation
import Synchronization
import Testing
import VoxeliaCore
import VoxeliaStorage

@testable import VoxeliaExecution

/// A lock-guarded synchronous event collector: the sink runs inside
/// the actor's own sequencing, so the observed order is the story.
private final class EventCollector: Sendable {
    private let storedEvents = Mutex<[BrickCacheEvent]>([])

    var sink: BrickCacheEventSink {
        { event in
            self.storedEvents.withLock { events in
                events.append(event)
            }
        }
    }

    var events: [BrickCacheEvent] {
        storedEvents.withLock { $0 }
    }
}

@Suite("BrickResultCache")
struct BrickResultCacheTests {
    private func identity(_ suffix: Int) throws -> BrickIdentity {
        try BrickIdentity(
            volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
            levelIndex: 0,
            coordinate: [suffix, 0, 0]
        )
    }

    private func decoded() throws -> ExecutionClaimToken {
        try ExecutionClaimToken(rawValue: "org.voxelia.representation.decoded-u8")
    }

    @Test("[Unit][VOX-CCH-009][VOX-CCH-008] one integrated story emits all five events")
    func oneIntegratedStoryEmitsAllFiveEvents() async throws {
        // Miss, decode, hit, eviction and recomputation observed in
        // order across one integrated story through the broker.
        let collector = EventCollector()
        let cache = BrickResultCache(
            maximumEntryCount: 1,
            maximumTotalByteCount: 1_024,
            eventSink: collector.sink
        )
        let broker = BrickRequestBroker()
        let generation = await broker.generation()
        let first = try identity(1)
        let second = try identity(2)
        let representation = try decoded()

        // Miss then decode then admission.
        let resolved = try await cache.result(
            for: first,
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 9,
            broker: broker
        ) {
            [1, 2, 3]
        }
        #expect(resolved == [1, 2, 3])

        // A revalidated hit.
        let hit = try await cache.result(
            for: first,
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 9,
            broker: broker
        ) {
            [1, 2, 3]
        }
        #expect(hit == [1, 2, 3])

        // The one-entry budget evicts the first brick for the second.
        _ = try await cache.result(
            for: second,
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 4,
            broker: broker
        ) {
            [7]
        }

        // Tampering the second brick surfaces the recomputation path:
        // the corrupt entry is removed and resolved fresh.
        await cache.tamperEntryForEvidence(
            identity: second,
            representation: representation
        )
        let recomputed = try await cache.result(
            for: second,
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 4,
            broker: broker
        ) {
            [7]
        }
        #expect(recomputed == [7])

        #expect(
            collector.events == [
                .miss(identity: first),
                .decode(identity: first, byteCount: 3, costUnits: 9),
                .hit(identity: first, byteCount: 3),
                .miss(identity: second),
                .decode(identity: second, byteCount: 1, costUnits: 4),
                .eviction(identity: first, byteCount: 3),
                .recomputation(identity: second),
                .decode(identity: second, byteCount: 1, costUnits: 4),
            ]
        )
    }

    @Test("[Unit][VOX-CCH-008][VOX-ERR-001] corruption rejects typed with the entry removed")
    func corruptionRejectsTypedWithTheEntryRemoved() async throws {
        // The low-level lookup surface: a tampered entry rejects the
        // typed corruption case, is removed, and the next lookup is a
        // plain miss — no sink, and nothing to emit to.
        let cache = BrickResultCache(
            maximumEntryCount: 4,
            maximumTotalByteCount: 1_024,
            eventSink: nil
        )
        let broker = BrickRequestBroker()
        let generation = await broker.generation()
        let brick = try identity(1)
        let representation = try decoded()
        _ = try await cache.result(
            for: brick,
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 1,
            broker: broker
        ) {
            [5, 6]
        }
        #expect(
            try await cache.lookup(
                identity: brick,
                representation: representation
            ) == [5, 6]
        )
        await cache.tamperEntryForEvidence(
            identity: brick,
            representation: representation
        )
        do {
            _ = try await cache.lookup(
                identity: brick,
                representation: representation
            )
            #expect(Bool(false), "Expected a tampered entry to be rejected.")
        } catch BrickCacheError.corruptEntry {}
        #expect(
            try await cache.lookup(
                identity: brick,
                representation: representation
            ) == nil
        )
    }

    @Test("[Unit][VOX-BRK-008][VOX-ERR-001] referenced entries survive eviction pressure")
    func referencedEntriesSurviveEvictionPressure() async throws {
        // A retained entry is never displaced: admission under
        // pressure rejects typed until the reference is released, and
        // the invisible entry is displaced before the visible one.
        let cache = BrickResultCache(
            maximumEntryCount: 1,
            maximumTotalByteCount: 1_024,
            eventSink: nil
        )
        let broker = BrickRequestBroker()
        let generation = await broker.generation()
        let pinned = try identity(1)
        let representation = try decoded()
        _ = try await cache.result(
            for: pinned,
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 1,
            broker: broker
        ) {
            [1]
        }
        try await cache.retain(identity: pinned, representation: representation)
        do {
            _ = try await cache.result(
                for: try identity(2),
                representation: representation,
                generation: generation,
                visible: false,
                reconstructionCost: 1,
                broker: broker
            ) {
                [2]
            }
            #expect(Bool(false), "Expected a pinned cache to reject admission.")
        } catch BrickCacheError.resourceLimitExceeded {}
        #expect(
            try await cache.lookup(
                identity: pinned,
                representation: representation
            ) == [1]
        )
        try await cache.release(identity: pinned, representation: representation)
        _ = try await cache.result(
            for: try identity(2),
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 1,
            broker: broker
        ) {
            [2]
        }
        #expect(
            try await cache.lookup(
                identity: pinned,
                representation: representation
            ) == nil
        )
        do {
            try await cache.release(
                identity: try identity(2),
                representation: representation
            )
            #expect(Bool(false), "Expected an unmatched release to be rejected.")
        } catch BrickCacheError.invalidRelease {}
        do {
            try await cache.retain(
                identity: try identity(9),
                representation: representation
            )
            #expect(Bool(false), "Expected an unknown entry to be rejected.")
        } catch BrickCacheError.unknownEntry {}
    }

    @Test("[Unit][VOX-BRK-008] eviction follows the frozen order")
    func evictionFollowsTheFrozenOrder() async throws {
        // Two resident entries, one visible and one invisible: the
        // invisible entry is displaced first under the one frozen
        // ordering authority even though it is newer.
        let collector = EventCollector()
        let cache = BrickResultCache(
            maximumEntryCount: 2,
            maximumTotalByteCount: 1_024,
            eventSink: collector.sink
        )
        let broker = BrickRequestBroker()
        let generation = await broker.generation()
        let representation = try decoded()
        let visibleBrick = try identity(1)
        let invisibleBrick = try identity(2)
        _ = try await cache.result(
            for: visibleBrick,
            representation: representation,
            generation: generation,
            visible: true,
            reconstructionCost: 1,
            broker: broker
        ) {
            [1]
        }
        _ = try await cache.result(
            for: invisibleBrick,
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 1,
            broker: broker
        ) {
            [2]
        }
        _ = try await cache.result(
            for: try identity(3),
            representation: representation,
            generation: generation,
            visible: false,
            reconstructionCost: 1,
            broker: broker
        ) {
            [3]
        }
        #expect(
            collector.events.contains(
                .eviction(identity: invisibleBrick, byteCount: 1)
            )
        )
        #expect(
            try await cache.lookup(
                identity: visibleBrick,
                representation: representation
            ) == [1]
        )
    }
}
