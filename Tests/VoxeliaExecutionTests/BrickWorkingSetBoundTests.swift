// SPDX-License-Identifier: MIT

import Foundation
import Synchronization
import Testing
import VoxeliaCore
import VoxeliaStorage

@testable import VoxeliaExecution

/// A lock-guarded collector; the sink runs inside the actor's own sequencing.
private final class BoundCollector: Sendable {
    private let storedEvents = Mutex<[BrickCacheEvent]>([])

    var sink: BrickCacheEventSink {
        { event in
            self.storedEvents.withLock { $0.append(event) }
        }
    }

    var events: [BrickCacheEvent] { storedEvents.withLock { $0 } }
}

/// `ADR-0318` (`VOX-PER-009`): the decoded-brick working set stays bounded under sustained
/// large-volume insertion.
///
/// The resident set is reconstructed from the cache's **own events** — `decode` admits with a
/// byte count and `eviction` removes with one — rather than by reading a private field. That
/// is the stronger observation: it checks what the cache reports to a host against what it
/// promised, so a cache whose accounting drifted from its behaviour would fail here.
@Suite("BrickWorkingSetBound")
struct BrickWorkingSetBoundTests {
    private func identity(_ ordinal: Int) throws -> BrickIdentity {
        try BrickIdentity(
            volumeObjectID: try #require(DataObjectID(rawValue: "volume-large")),
            levelIndex: 0,
            coordinate: [ordinal, 0, 0]
        )
    }

    private func decoded() throws -> ExecutionClaimToken {
        try ExecutionClaimToken(rawValue: "org.voxelia.representation.decoded-u8")
    }

    /// Resident entries and bytes implied by the events emitted so far.
    private func resident(_ events: [BrickCacheEvent]) -> (count: Int, bytes: UInt64) {
        var count = 0
        var bytes: UInt64 = 0
        for event in events {
            switch event {
            case .decode(_, let byteCount, _):
                count += 1
                bytes += byteCount
            case .eviction(_, let byteCount):
                count -= 1
                bytes -= byteCount
            case .hit, .miss, .recomputation:
                continue
            }
        }
        return (count, bytes)
    }

    /// Inserts `brickCount` distinct bricks of `byteCount` bytes, asserting the working set
    /// is within both ceilings **after every insertion**.
    private func drive(
        brickCount: Int,
        byteCount: Int,
        maximumEntryCount: UInt64,
        maximumTotalByteCount: UInt64
    ) async throws -> [BrickCacheEvent] {
        let collector = BoundCollector()
        let cache = BrickResultCache(
            maximumEntryCount: maximumEntryCount,
            maximumTotalByteCount: maximumTotalByteCount,
            eventSink: collector.sink
        )
        let broker = BrickRequestBroker()
        let generation = await broker.generation()
        let representation = try decoded()
        let payload = ContiguousArray<UInt8>(repeating: 7, count: byteCount)

        for ordinal in 0..<brickCount {
            _ = try await cache.result(
                for: try identity(ordinal),
                representation: representation,
                generation: generation,
                visible: false,
                reconstructionCost: 1,
                broker: broker
            ) {
                payload
            }
            // Checked every time. A cache that grew without limit and trimmed once at the end
            // would satisfy a final-state assertion and fail this one.
            let state = resident(collector.events)
            #expect(UInt64(state.count) <= maximumEntryCount)
            #expect(state.bytes <= maximumTotalByteCount)
        }
        return collector.events
    }

    @Test("[Unit][VOX-PER-009] the entry ceiling bounds a sustained insertion run")
    func entryCeilingBoundsASustainedInsertionRun() async throws {
        // The byte ceiling is deliberately unreachable here, so only the entry ceiling can be
        // what holds the set. Testing both at once could not tell which one did.
        let events = try await drive(
            brickCount: 200,
            byteCount: 16,
            maximumEntryCount: 8,
            maximumTotalByteCount: 1_000_000
        )
        let evictions = events.filter { event in
            guard case .eviction = event else { return false }
            return true
        }
        // The positive control: the bound held because eviction ran, not because little was
        // inserted. 200 bricks into 8 slots evicts 192.
        #expect(evictions.count == 192)
        #expect(resident(events).count == 8)
        #expect(resident(events).bytes == 8 * 16)
    }

    @Test("[Unit][VOX-PER-009] the byte ceiling bounds a sustained insertion run")
    func byteCeilingBoundsASustainedInsertionRun() async throws {
        // Now the entry ceiling is unreachable and the byte ceiling is the only binding one.
        let events = try await drive(
            brickCount: 200,
            byteCount: 128,
            maximumEntryCount: 10_000,
            maximumTotalByteCount: 1_024
        )
        let evictions = events.filter { event in
            guard case .eviction = event else { return false }
            return true
        }
        #expect(evictions.count > 0)
        #expect(resident(events).bytes <= 1_024)
        // Eight 128-byte bricks exactly fill the budget, so the resident set settles there.
        #expect(resident(events).count == 8)
        #expect(resident(events).bytes == 1_024)
    }

    @Test("[Unit][VOX-PER-009] a budget too small to hold a brick refuses it")
    func budgetTooSmallToHoldABrickRefusesIt() async throws {
        // Written expecting the cache to admit and immediately evict, and corrected by the
        // run: it throws `resourceLimitExceeded` instead. That is the better behaviour and
        // the stronger bound — the cache never admits something it cannot hold, so the
        // working set is bounded by refusal and not only by eviction.
        await #expect(throws: BrickCacheError.resourceLimitExceeded) {
            _ = try await self.drive(
                brickCount: 1,
                byteCount: 32,
                maximumEntryCount: 0,
                maximumTotalByteCount: 0
            )
        }
        await #expect(throws: BrickCacheError.resourceLimitExceeded) {
            _ = try await self.drive(
                brickCount: 1,
                byteCount: 32,
                maximumEntryCount: 4,
                maximumTotalByteCount: 31
            )
        }
        // The positive control: one byte more of budget admits it, so the refusals above
        // discriminate on the budget rather than rejecting everything.
        let events = try await drive(
            brickCount: 1,
            byteCount: 32,
            maximumEntryCount: 4,
            maximumTotalByteCount: 32
        )
        #expect(resident(events).count == 1)
        #expect(resident(events).bytes == 32)
    }
}
