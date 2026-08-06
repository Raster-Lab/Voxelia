---
document_id: "ADR-0276"
title: "Frame presentation and generation wiring"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-001"
  - "VOX-INT-007"
---

# ADR-0276 - Frame presentation and generation wiring

## Context

`VOX-INT-007` requires that "interaction updates shall increment render generations so
stale frames are not presented". It declares `T`.

`ADR-0122` froze the vocabulary — `RenderGeneration`, `RenderGenerationCounter`, and a
strict `isStale(comparedTo:)` — and then deferred its use to "the interactive draw loop's
behaviour, which remains gated on its own architecture". `ADR-0275` supplied that
architecture and named this as the arc's first increment.

Until now `RenderGeneration` had **no product caller**: only its own file, a DocC line and
its own tests. This record gives it one.

## The finding: the rule is stronger than the requirement's wording

`RenderGeneration`'s initialiser is **internal to `VoxeliaInteraction`**, so the only way a
host obtains a generation is `RenderGenerationCounter.advance()`. Every stamp therefore
names a generation minted in the past, which gives `stamp <= current` for all reachable
states.

Combined with `ADR-0122`'s strict comparison, `!isStale` holds **exactly when
`stamp == current`**. So the presenter admits only frames rendered for the newest scene —
not "reasonably recent" frames, the newest.

That is a consequence of the accepted vocabulary rather than a choice made here, and it has
a consequence of its own worth stating plainly: **if generations are minted faster than
frames complete, nothing is ever presented.** A host minting one generation per input event
during a drag would render continuously and display nothing.

This is not a defect in the vocabulary. It is what "stale frames are not presented" means
when staleness is strict. But it does force a decision the requirement does not make, and
that decision is below.

## Decision

1. **`FramePresenter` is the vocabulary's first product caller.** It holds a
   `RenderGenerationCounter` rather than accepting a generation per call, so a caller
   cannot present against anything but the live generation.
2. **The staleness rule is consumed, not redefined.** `ADR-0122`'s
   `isStale(comparedTo:)` is the whole test. No tolerance, no second comparison, no
   "recent enough" window.
3. **Content is carried inside the presented outcome.** `PresentationOutcome` is
   `.presented(Content)` or `.droppedStale`, so a host cannot draw what it never receives.
   This is `ADR-0259`'s shape — "a caller cannot publish what it never receives" — reused
   because honouring a drop must be structural rather than remembered.
4. **Generations are minted per *committed scene change*, never per input event.** This is
   the boundary this record freezes, and it is the answer to the starvation above. A drag,
   a scroll or a continuous window/level adjustment produces a stream of host events; the
   host coalesces them into scene commits, and the counter orders those. The counter
   counts scene versions, which is what `ADR-0122` said it was for when it rejected reusing
   the frame scheduler's frame index.
5. **The starvation is demonstrated by a test, not merely documented.** A test mints
   sixteen generations before any frame completes and asserts that fifteen are dropped and
   only the newest survives. A host author reading the suite meets the constraint directly
   rather than discovering it against a frozen viewport.
6. **Generation zero is presentable.** `RenderGenerationCounter` begins at zero and
   `advance()` returns one, so a first paint stamped at the initial generation is current
   and must not be dropped. A test covers it, because an off-by-one here would blank the
   viewport until the user touched something.
7. **Monotonicity is asserted as a consequence, not enforced as a second rule.** Presented
   generations never decrease, which follows from admitting only `stamp == current` over a
   non-decreasing counter. A test interleaves deliberately stale frames with current ones
   and asserts the presented sequence is sorted and did in fact advance, so the assertion
   is not satisfied trivially.
8. **`StampedFrame` and `FramePresenter` are generic over their content**, so this module
   names no rendering or host payload type. That keeps `VOX-INT-001` intact structurally: a
   test stands the presenter up over an unrelated content type to show the independence
   rather than asserting it.
9. **`VOX-INT-007`'s `T` is discharged.** Eight tests cover the rule, both boundaries, the
   out-of-order hazard, the monotonic consequence, the starvation consequence and the host
   independence.
10. **No algorithm specification and no oracle.** One comparison, already frozen by
    `ADR-0122`, plus a decision about who calls `advance()` and when.

## Why the presenter holds the counter

Passing `current` per call would be simpler to test and would be wrong. A caller that
computed or cached the current generation could present a frame that was stale by the time
the decision was made, and the requirement would then depend on the caller's care. Holding
the counter makes the live comparison the only available one — the same reasoning
`ADR-0273` used for putting the codestream budget inside `admitDestination` rather than
beside it.

## What this record does not do

It does not present anything to a screen, and it does not schedule renders. `VoxeliaInteraction`
is forbidden `SwiftUI`, `AppKit`, `UIKit`, `RealityKit` and `MetalKit`, and that stands.
The presenter decides *whether* a frame may be shown and hands over its content; drawing
belongs to a host, and where that host lives is the owner decision `ADR-0275` raised.

## Alternatives considered

### Admit frames within a tolerance of the current generation

Rejected. A frame within a tolerance is still stale, and `VOX-INT-007` says stale frames
are not presented. A tolerance would also reintroduce exactly the regression the row
exists to prevent: with a window of two, a frame at generation 5 could be presented after
one at generation 6.

### Return a verdict alongside the content rather than inside it

Rejected. It leaves a host free to draw a dropped frame, which turns a structural
guarantee into a convention. The enum shape costs a `switch` at the call site and buys the
guarantee.

### Mint a generation per input event and drop frames aggressively

Rejected; it is the starvation case. A continuous gesture would advance the counter faster
than any renderer completes and the viewport would never update. Coalescing at the host is
the standard answer and it keeps the strict rule intact.

### Coalesce inside `RenderGenerationCounter` by rate-limiting `advance()`

Rejected. It would put a time-based policy inside a value-ordering primitive, make
`advance()` non-deterministic, and hide from a host the fact that its event rate matters.
The counter's contract — strictly increasing, never duplicated — is worth keeping free of
timing.

### Track the last presented generation as a second admission gate

Rejected as redundant. Admission already requires `stamp == current`, and `current` is
non-decreasing, so a regression is unreachable. `lastPresentedGeneration` is retained as a
**read-only report** because plan §34 lists "current generation" among the reference
application's displays, not because the rule needs it.

### Make `RenderGeneration`'s initialiser public so hosts can construct stamps

Rejected, and worth recording because it looked like a convenience. It is precisely what
makes `stamp <= current` true, and therefore what makes the rule collapse to equality. A
public initialiser would let a host mint a generation ahead of the counter and present a
frame that no interaction had produced.

## Consequences

`VOX-INT-007`'s `T` is discharged and `ADR-0122` decision 3's deferral is ended.
`RenderGeneration` has a product caller for the first time.

A host-facing constraint is now explicit and tested: **coalesce input into scene commits,
because a generation per event presents nothing.** That is the kind of thing a reference
application would otherwise discover by looking at a frozen window.

`VoxeliaInteraction` gains three public types and still imports no host framework.

**Next in the arc**: one presentation path shared by off-screen and interactive output
(`VOX-R2D-014`, `VOX-VS1-016`), then `VOX-INT-008`'s `T`.

## Affected modules

`VoxeliaInteraction` gains `StampedFrame`, `PresentationOutcome` and `FramePresenter`, and
its DocC catalogue lists all three. No other module changes and nothing new is imported.

## Compatibility impact

Additive.

## Security impact

None directly. The presenter carries no patient data of its own and its failure mode is to
withhold content rather than to release it.

## Performance and memory impact

One actor hop to read the counter and one integer comparison per frame. The presenter
retains no frame content beyond the call — only the last presented generation, a `UInt64`.

## Validation impact

```text
swift build && swift test
swift test --filter "FramePresenter"
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_prohibited_imports.py
swift format lint --strict Sources/VoxeliaInteraction/Public/FramePresenter.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1124 tests in 203 suites pass.

## Migration

1. This record, `FramePresenter`, and the DocC entries.
2. **Next**: `VOX-R2D-014` and `VOX-VS1-016` — one presentation path serving off-screen and
   interactive output, with the equality tested rather than asserted.
3. Then `VOX-INT-008`'s `T`: responsiveness while background processing continues, through
   an injected clock and a deterministic probe.
4. **Owner**: the application-location decision `ADR-0275` raised, `VOX-CMP-006`'s and
   `VOX-CMP-012`'s Reviews, the five `J2KSwift` items, and the five decisions already open.

## Supersession

This record supersedes nothing. It **satisfies `ADR-0122` decision 3** by supplying the
presentation wiring that decision deferred, and consumes that record's frozen comparison
without altering it.

## References

- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
- [ADR-0122 - Render generations](ADR-0122-render-generations.md)
- [ADR-0259 - Cancellable decode session](ADR-0259-cancellable-decode-session.md)
- [ADR-0273 - Bounded failure on adversarial codestreams](ADR-0273-bounded-failure-on-adversarial-codestreams.md)
- [ADR-0275 - Open the interactive draw loop arc](ADR-0275-open-the-interactive-draw-loop-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
