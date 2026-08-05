// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaMetal

@Suite("MetalFrameScheduler")
struct MetalFrameSchedulerTests {
    @Test("[Unit][VOX-MTL-006][VOX-ERR-001] frame slots bound, reuse and release once")
    func frameSlotsBoundReuseAndReleaseOnce() async throws {
        // The explicit bound admits exactly its count of in-flight
        // frames with monotonic ordering evidence, rejects the
        // over-bound acquisition typed, and reuses released slots.
        let scheduler = try MetalFrameScheduler(maximumInFlightFrameCount: 2)
        let first = try await scheduler.acquireFrame()
        let second = try await scheduler.acquireFrame()
        #expect(first.frameIndex == 0)
        #expect(second.frameIndex == 1)
        #expect(await scheduler.inFlightFrameCount == 2)
        do {
            _ = try await scheduler.acquireFrame()
            #expect(Bool(false), "Expected the in-flight bound to be enforced.")
        } catch MetalFrameError.inFlightLimitExceeded {}
        try await scheduler.releaseFrame(first)
        let third = try await scheduler.acquireFrame()
        #expect(third.frameIndex == 2)
        #expect(await scheduler.inFlightFrameCount == 2)

        // Release-once discipline: double and foreign releases reject
        // typed.
        do {
            try await scheduler.releaseFrame(first)
            #expect(Bool(false), "Expected a double release to be rejected.")
        } catch MetalFrameError.invalidRelease {}
        do {
            let foreign = try await MetalFrameScheduler(
                maximumInFlightFrameCount: 1
            ).acquireFrame()
            try await scheduler.releaseFrame(foreign)
            #expect(Bool(false), "Expected a foreign release to be rejected.")
        } catch MetalFrameError.invalidRelease {}

        // The bound itself validates.
        do {
            _ = try MetalFrameScheduler(maximumInFlightFrameCount: 0)
            #expect(Bool(false), "Expected a zero bound to be rejected.")
        } catch MetalFrameError.invalidInFlightLimit {}

        requireSendable(MetalFrameScheduler.self)
        requireSendable(MetalFrameToken.self)
        requireSendable(MetalFrameError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
