// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaInteraction

/// `ADR-0276` (`VOX-INT-007`): interaction updates increment render generations so stale
/// frames are not presented.
@Suite("FramePresenter")
struct FramePresenterTests {
    private func presenter() -> (RenderGenerationCounter, FramePresenter<String>) {
        let counter = RenderGenerationCounter()
        return (counter, FramePresenter<String>(counter: counter))
    }

    private func content(_ outcome: PresentationOutcome<String>) -> String? {
        switch outcome {
        case .presented(let value): value
        case .droppedStale: nil
        }
    }

    // MARK: - The rule

    @Test("[Unit][VOX-INT-007] a frame stamped at the current generation is presented")
    func currentFrameIsPresented() async {
        let (counter, presenter) = presenter()
        let generation = await counter.advance()
        let outcome = await presenter.present(
            StampedFrame(generation: generation, content: "frame-1")
        )
        #expect(content(outcome) == "frame-1")
        #expect(await presenter.lastPresentedGeneration == generation)
    }

    @Test("[Unit][VOX-INT-007] a frame stamped before an interaction update is dropped")
    func frameStampedBeforeUpdateIsDropped() async {
        // The requirement's core case: a render was requested, the user interacted again,
        // and the older render finished afterwards.
        let (counter, presenter) = presenter()
        let requested = await counter.advance()
        _ = await counter.advance()  // an interaction update lands mid-render

        let outcome = await presenter.present(
            StampedFrame(generation: requested, content: "obsolete")
        )
        #expect(content(outcome) == nil)
        // Nothing was presented, so there is no last generation to report.
        #expect(await presenter.lastPresentedGeneration == nil)
    }

    @Test("[Unit][VOX-INT-007] a late frame cannot overwrite a newer presented one")
    func lateFrameCannotOverwriteNewer() async {
        // Out-of-order completion, which is the hazard that makes this structural rather
        // than a matter of call ordering.
        let (counter, presenter) = presenter()
        let older = await counter.advance()
        let newer = await counter.advance()

        #expect(
            content(
                await presenter.present(
                    StampedFrame(generation: newer, content: "newer"))) == "newer")
        #expect(
            content(
                await presenter.present(
                    StampedFrame(generation: older, content: "older"))) == nil)
        #expect(await presenter.lastPresentedGeneration == newer)
    }

    @Test("[Unit][VOX-INT-007] equality is freshness, not staleness")
    func equalityIsFreshness() async {
        // `ADR-0122` froze `isStale` as a strict comparison. Re-presenting the same
        // generation — a redraw with no scene change — must be admitted.
        let (counter, presenter) = presenter()
        let generation = await counter.advance()
        #expect(
            content(
                await presenter.present(
                    StampedFrame(generation: generation, content: "first"))) == "first")
        #expect(
            content(
                await presenter.present(
                    StampedFrame(generation: generation, content: "redraw"))) == "redraw")
    }

    @Test("[Unit][VOX-INT-007] presented generations never decrease")
    func presentedGenerationsNeverDecrease() async {
        // Monotonicity is a consequence of the rule rather than a second rule, so it is
        // asserted over an interleaving that would expose a regression.
        let (counter, presenter) = presenter()
        var observed: [UInt64] = []

        for step in 0..<8 {
            let generation = await counter.advance()
            // Every other step, offer a deliberately stale frame first.
            if step.isMultiple(of: 2), let stale = await presenter.lastPresentedGeneration {
                _ = await presenter.present(
                    StampedFrame(generation: stale, content: "stale-\(step)"))
            }
            _ = await presenter.present(
                StampedFrame(generation: generation, content: "frame-\(step)"))
            if let last = await presenter.lastPresentedGeneration {
                observed.append(last.value)
            }
        }

        #expect(observed == observed.sorted())
        #expect(observed.count == 8)
        // And it strictly advanced rather than standing still, so the assertion above is
        // not satisfied trivially.
        #expect(observed.first != observed.last)
    }

    // MARK: - The consequence, demonstrated rather than left to be discovered

    @Test("[Unit][VOX-INT-007] minting faster than rendering presents nothing")
    func mintingFasterThanRenderingPresentsNothing() async {
        // Because a stamp always names a past generation, `not stale` holds only at
        // equality — so the presenter admits only the newest scene. A host that minted a
        // generation per input event during a drag would therefore show nothing at all.
        // This is why `ADR-0276` freezes minting at one generation per committed scene
        // change, and the starvation is demonstrated here so the reason is visible.
        let (counter, presenter) = presenter()
        var requested: [RenderGeneration] = []
        for _ in 0..<16 {
            requested.append(await counter.advance())
        }

        // Every render completes after all sixteen "events" have landed.
        for (index, generation) in requested.enumerated() {
            let outcome = await presenter.present(
                StampedFrame(generation: generation, content: "frame-\(index)"))
            if index < requested.count - 1 {
                #expect(content(outcome) == nil)
            } else {
                // Only the last one, which is the current generation, survives.
                #expect(content(outcome) == "frame-15")
            }
        }
        #expect(await presenter.lastPresentedGeneration == requested.last)
    }

    @Test("[Unit][VOX-INT-007] a presenter with no interaction presents its first frame")
    func presenterWithNoInteractionPresentsFirstFrame() async {
        // Generation zero is the initial state, and a frame stamped at it is current
        // until something advances the counter. A first paint must not be dropped.
        let (counter, presenter) = presenter()
        let initial = await counter.currentGeneration
        #expect(initial.value == 0)
        #expect(
            content(
                await presenter.present(
                    StampedFrame(generation: initial, content: "first-paint"))) == "first-paint")
    }

    @Test("[Unit][VOX-INT-007] the presenter is host-type independent")
    func presenterIsHostTypeIndependent() async {
        // `VOX-INT-001`: the presenter names no rendering or host type. Standing it up
        // over an unrelated content type is the check.
        struct Pixels: Sendable, Equatable {
            let samples: [UInt16]
        }
        let counter = RenderGenerationCounter()
        let presenter = FramePresenter<Pixels>(counter: counter)
        let generation = await counter.advance()
        let outcome = await presenter.present(
            StampedFrame(generation: generation, content: Pixels(samples: [1, 2, 3])))
        switch outcome {
        case .presented(let pixels): #expect(pixels == Pixels(samples: [1, 2, 3]))
        case .droppedStale: Issue.record("a current frame was dropped")
        }
    }
}
