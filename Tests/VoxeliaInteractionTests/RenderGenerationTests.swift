// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaInteraction

@Suite("RenderGeneration")
struct RenderGenerationTests {
    @Test("[Unit][VOX-INT-007][VOX-ERR-001] generations mint monotonically and compare")
    func generationsMintMonotonicallyAndCompare() async throws {
        // Sixty-four concurrent advances mint unique strictly
        // increasing generations with no duplicates.
        let counter = RenderGenerationCounter()
        #expect(await counter.currentGeneration.value == 0)
        var minted = Set<UInt64>()
        await withTaskGroup(of: UInt64.self) { group in
            for _ in 0..<64 {
                group.addTask {
                    await counter.advance().value
                }
            }
            for await value in group {
                minted.insert(value)
            }
        }
        #expect(minted.count == 64)
        #expect(minted.min() == 1)
        #expect(minted.max() == 64)
        #expect(await counter.currentGeneration.value == 64)

        // The staleness relation: earlier is stale, equal is fresh,
        // later is fresh.
        let current = await counter.currentGeneration
        let earlier = RenderGeneration(value: 63)
        let later = await counter.advance()
        #expect(earlier.isStale(comparedTo: current))
        #expect(!current.isStale(comparedTo: current))
        #expect(!later.isStale(comparedTo: current))
        #expect(earlier < current)

        requireSendable(RenderGeneration.self)
        requireSendable(RenderGenerationCounter.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
