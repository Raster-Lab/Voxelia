// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaInteraction

@Suite("ProgressiveFrame")
struct ProgressiveFrameTests {
    @Test("[Unit][VOX-HLS-008] intermediate frames carry generation and convergence")
    func intermediateFramesCarryGenerationAndConvergence() async throws {
        let session = ProgressiveRenderSession<String>()
        let generation = await session.begin()

        // The first intermediate: one sample, variance honestly absent.
        let first = ProgressiveFrame(
            content: "frame-1",
            metadata: try ProgressiveFrameMetadata(
                generation: generation,
                sampleCount: 1,
                variance: nil
            )
        )
        guard case .presented(let content) = await session.publish(first) else {
            Issue.record("a fresh intermediate frame was dropped")
            return
        }
        #expect(content == "frame-1")

        // A later intermediate carries its measured convergence.
        let refined = ProgressiveFrame(
            content: "frame-64",
            metadata: try ProgressiveFrameMetadata(
                generation: generation,
                sampleCount: 64,
                variance: 0.25
            )
        )
        guard case .presented = await session.publish(refined) else {
            Issue.record("a fresh refined frame was dropped")
            return
        }
    }

    @Test("[Unit][VOX-HLS-009] cancellation stales the final at the seam")
    func cancellationStalesTheFinalAtTheSeam() async throws {
        let session = ProgressiveRenderSession<String>()
        let generation = await session.begin()

        // The renderer finishes its final frame — but the host
        // cancelled first. The final is not special: it drops.
        await session.cancel()
        let staleFinal = ProgressiveFrame(
            content: "stale-final",
            metadata: try ProgressiveFrameMetadata(
                generation: generation,
                sampleCount: 4096,
                variance: 0.001
            )
        )
        let outcome = await session.publish(staleFinal)
        guard case .droppedStale = outcome else {
            Issue.record("a cancelled request's final output was published")
            return
        }

        // The next request publishes normally.
        let next = await session.begin()
        let fresh = ProgressiveFrame(
            content: "fresh-final",
            metadata: try ProgressiveFrameMetadata(
                generation: next,
                sampleCount: 8,
                variance: 0.5
            )
        )
        guard case .presented(let content) = await session.publish(fresh) else {
            Issue.record("the successor request's frame was dropped")
            return
        }
        #expect(content == "fresh-final")
    }

    @Test("[Unit][VOX-HLS-008] admissions reject typed")
    func admissionsRejectTyped() async throws {
        let session = ProgressiveRenderSession<String>()
        let generation = await session.begin()
        #expect(throws: ProgressiveFrameError.invalidSampleCount) {
            _ = try ProgressiveFrameMetadata(
                generation: generation,
                sampleCount: 0,
                variance: nil
            )
        }
        #expect(throws: ProgressiveFrameError.invalidVariance) {
            _ = try ProgressiveFrameMetadata(
                generation: generation,
                sampleCount: 2,
                variance: -1
            )
        }
    }
}
