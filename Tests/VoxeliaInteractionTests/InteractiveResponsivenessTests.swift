// SPDX-License-Identifier: MIT

import Synchronization
import Testing

@testable import VoxeliaInteraction

/// `ADR-0279` (`VOX-INT-008`): interactive manipulation remains responsive while
/// background processing continues.
///
/// Responsiveness here is **structural, not a latency figure**. Plan §22.4 states that
/// already-submitted GPU work "may not be physically interrupted", so responsiveness
/// cannot come from stopping background work — it comes from never waiting on it. The
/// wall-clock threshold belongs to `VOX-PER-005`, which names reference workstation
/// hardware and is owner-gated; `ADR-0275` decision 4 froze that no performance threshold
/// is claimed in this arc.
///
/// Every test here is deterministic. No sleeps, no timeouts, no timing assertions.
@Suite("InteractiveResponsiveness")
struct InteractiveResponsivenessTests {
    /// A gate the test opens explicitly, so "background work is in flight" is a fact
    /// rather than a race won by a sleep.
    private actor Gate {
        private var isOpen = false
        private var waiting: [CheckedContinuation<Void, Never>] = []

        func open() {
            isOpen = true
            let pending = waiting
            waiting = []
            for continuation in pending { continuation.resume() }
        }

        func wait() async {
            if isOpen { return }
            await withCheckedContinuation { waiting.append($0) }
        }
    }

    /// Records the order events actually happened in.
    ///
    /// `Mutex` rather than a mutable capture: the safety policy reserves the bare word
    /// this project may not write, and a lock is the honest primitive for a recorder
    /// touched from more than one task.
    private final class OrderRecorder: Sendable {
        private let events = Mutex<[String]>([])

        func record(_ event: String) {
            events.withLock { $0.append(event) }
        }

        var recorded: [String] {
            events.withLock { $0 }
        }
    }

    // MARK: - The property

    @Test(
        "[Concurrency][VOX-INT-008] an interaction is serviced while background work runs"
    )
    func interactionIsServicedWhileBackgroundWorkIsInFlight() async {
        // The requirement's core case. Background work starts, blocks on a gate the test
        // holds, and an interaction update must complete before the background work is
        // allowed to finish. Asserted as an ORDER rather than a duration, so the test
        // says "the interaction did not wait for it" without measuring anything.
        //
        // What this does and does not prove, stated because the gates enforce the order:
        // it demonstrates that an interaction completes while background work is genuinely
        // suspended mid-flight. It cannot fail through contention, because the background
        // task here touches nothing the interaction needs. Contention is the subject of
        // `concurrentInteractionsUnderBackgroundLoadLoseNoGeneration` below, and the
        // reason it cannot deadlock at all is structural: neither actor method in this
        // module contains a suspension point, so no caller can hold one across an await.
        let counter = RenderGenerationCounter()
        let order = OrderRecorder()
        let started = Gate()
        let proceed = Gate()

        let background = Task {
            order.record("background-started")
            await started.open()
            await proceed.wait()
            order.record("background-finished")
        }

        await started.wait()

        // The interaction. Plan §22.2 lists ten state changes that must advance a
        // viewport generation; this stands for all of them, because they reach the same
        // counter.
        let generation = await counter.advance()
        order.record("interaction-serviced")

        await proceed.open()
        await background.value

        #expect(generation.value == 1)
        #expect(
            order.recorded == [
                "background-started", "interaction-serviced", "background-finished",
            ]
        )
    }

    @Test("[Concurrency][VOX-INT-008][VOX-INT-007] an obsolete completion is not presented")
    func obsoleteCompletionIsNotPresented() async {
        // Plan §22.4 lists five ways cancellation acceptance is achieved when the work
        // itself cannot be interrupted. The third is "not presenting obsolete
        // completion", and this is where that meets responsiveness: the interaction is
        // serviced immediately, and the background frame it obsoleted is dropped when it
        // eventually lands.
        //
        // Composing the presenter with a real in-flight task matters. Both halves have
        // their own passing suites, and neither would notice if they stopped meeting.
        let counter = RenderGenerationCounter()
        let presenter = FramePresenter<String>(counter: counter)
        let started = Gate()
        let proceed = Gate()

        let requested = await counter.advance()
        let background = Task { () -> StampedFrame<String> in
            await started.open()
            await proceed.wait()
            return StampedFrame(generation: requested, content: "obsolete-render")
        }
        await started.wait()

        // The user interacts while that render is still running.
        let current = await counter.advance()
        #expect(current.value > requested.value)

        await proceed.open()
        let frame = await background.value
        let outcome = await presenter.present(frame)

        switch outcome {
        case .presented: Issue.record("an obsolete completion was presented")
        case .droppedStale: break
        }
        #expect(await presenter.lastPresentedGeneration == nil)

        // And the frame that was requested *after* the interaction is presented, so the
        // drop above is not the presenter refusing everything.
        let fresh = StampedFrame(generation: current, content: "current-render")
        switch await presenter.present(fresh) {
        case .presented(let content): #expect(content == "current-render")
        case .droppedStale: Issue.record("a current frame was dropped")
        }
    }

    @Test(
        "[Concurrency][VOX-INT-008] concurrent interactions under load lose no generation"
    )
    func concurrentInteractionsUnderBackgroundLoadLoseNoGeneration() async {
        // Where a real regression would show. A burst of interaction — as a drag or a
        // scroll wheel produces — runs concurrently with background presentation traffic
        // that touches BOTH actors, so the counter is genuinely contended rather than
        // idle while the interactions arrive.
        //
        // Sixteen advances must still yield sixteen distinct, contiguous generations. A
        // lost update would let two different scenes share a generation, and `ADR-0276`'s
        // presenter would then admit a frame rendered for the wrong one.
        let counter = RenderGenerationCounter()
        let presenter = FramePresenter<Int>(counter: counter)

        let minted = await withTaskGroup(of: UInt64?.self) { group in
            for index in 0..<16 {
                // The interaction.
                group.addTask { await counter.advance().value }
                // Background presentation traffic contending for the same two actors.
                group.addTask {
                    let stamp = await counter.currentGeneration
                    _ = await presenter.present(
                        StampedFrame(generation: stamp, content: index)
                    )
                    return nil
                }
            }
            var values: [UInt64] = []
            for await value in group {
                if let value { values.append(value) }
            }
            return values
        }

        #expect(minted.count == 16)
        #expect(Set(minted).count == 16, "a generation was lost under contention")
        #expect(minted.sorted() == Array(1...16))
        #expect(await counter.currentGeneration.value == 16)
    }

    @Test("[Unit][VOX-INT-008] interaction state is value-typed, so it cannot be contended")
    func interactionStateIsValueTyped() {
        // The structural reason background work cannot block manipulation: apart from the
        // generation counter, `VoxeliaInteraction` holds no shared mutable state at all.
        // A value has no identity to contend for, so an interaction computed from one
        // waits on nothing by construction.
        //
        // Asserted rather than described, because this is the whole argument and a later
        // refactor to a class or an actor would silently remove it while every other test
        // here kept passing.
        #expect(!(ViewportSyncGroup.self as Any is AnyObject.Type))
        #expect(!(CrosshairState.self as Any is AnyObject.Type))
        #expect(!(RenderGeneration.self as Any is AnyObject.Type))
        #expect(!(StampedFrame<String>.self as Any is AnyObject.Type))

        // The positive control: the check must be able to fail. The two reference types
        // in this module are the actors, and they are reference types precisely because
        // they carry the shared state — which is why their methods are the ones that had
        // to be shown non-suspending.
        #expect(RenderGenerationCounter.self as Any is AnyObject.Type)
        #expect(FramePresenter<String>.self as Any is AnyObject.Type)
    }
}
