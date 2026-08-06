---
document_id: "ADR-0279"
title: "Interactive responsiveness"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-008"
---

# ADR-0279 - Interactive responsiveness

## Context

`VOX-INT-008` requires that "interactive manipulation shall remain responsive while
background processing continues". It declares `T,D` and, until now, reached **no accepted
record and no test** — one of only two `VOX-INT` rows in that state.

`ADR-0275` opened the draw-loop arc and identified this row's `T` as unblocked: free of
the application question and free of the reference-hardware gate. It is the last such row
in the arc's library tier.

## The reading

The word "responsive" invites a latency figure, and a latency figure would be wrong here
twice over.

**It belongs to a different row.** `VOX-PER-005` requires "visible response within 50
milliseconds on reference workstation hardware". That is the threshold, that hardware is
unapproved, and `ADR-0275` decision 4 froze that no performance threshold is claimed
anywhere in this arc.

**And the plan says responsiveness is not achieved by speed.** §22.4 states that
already-submitted GPU work "may not be physically interrupted", then lists five ways
cancellation acceptance is achieved instead: preventing obsolete command preparation,
tagging command buffers with generation, **not presenting obsolete completion**, reusing
resources only after completion, and prioritising current work. Not one of them is "finish
faster". Responsiveness is achieved by **never waiting on background work**, not by
shortening it.

So the property is structural: **an interaction is serviced without waiting for background
processing to complete.**

That is the same move `ADR-0251` made for off-screen equivalence and `ADR-0206` made for
annotation registration — reduce a requirement that names an absent counterpart to a
property of the code that is true regardless.

## Why the property holds, structurally

`VoxeliaInteraction` contains exactly **two** reference types, `RenderGenerationCounter`
and `FramePresenter`. Everything else an interaction touches is a value:
`ViewportSyncGroup` is a `struct`, `CrosshairState` is a `struct`, `PickResolver` is an
`enum` used as a namespace, `RenderGeneration` and `StampedFrame` are `struct`s.

A value has no identity to contend for, so an interaction computed from one waits on
nothing.

That leaves the two actors, and **neither has a suspension point in any method that
mutates state**. `RenderGenerationCounter.advance()` increments and returns;
`currentGeneration` reads. No `await` appears inside either. **So no caller can hold the
counter across a suspension**, which is what blocking another caller would require.

This is `ADR-0249` decision 6's observation in a new place: a non-suspending critical
section has no cancellation point, and by the same argument it has no blocking point.

## Decision

1. **`VOX-INT-008`'s `T` is discharged; its `D` remains held.** The Demonstration half
   needs a host application, which is the owner decision `ADR-0275` raised. It is not
   redefined here to fit what is testable.
2. **Responsiveness is defined as "an interaction is serviced without waiting for
   background processing", and no latency is asserted.** `VOX-PER-005` owns the threshold.
3. **Every test is deterministic — no sleeps, no timeouts, no timing assertions.** "In
   flight" is established by an explicit gate the test opens, so it is a fact rather than
   a race won by a sleep. A responsiveness test that depended on machine load would be the
   flakiest test in the repository and would assert nothing about structure.
4. **The composition is tested, not just the halves.** One test runs `ADR-0276`'s presenter
   against a genuinely in-flight background task: the interaction advances the generation
   while the render is suspended, and the render's completion is dropped as obsolete when
   it lands — plan §22.4's third mechanism, exercised. `ADR-0248` found a gap exactly like
   this, where two individually green suites had nothing guarding their meeting.
5. **Contention is tested where a regression would actually show.** Sixteen interactions
   run concurrently with background presentation traffic touching **both** actors, and must
   still mint sixteen distinct contiguous generations. A lost update would let two scenes
   share a generation, and the presenter would then admit a frame rendered for the wrong
   one.
6. **The first test states what it cannot prove.** Its gates enforce the order it asserts,
   and its background task touches nothing the interaction needs, so it cannot fail through
   contention. It demonstrates the composition; decision 5's test carries the contention.
   Recording that inside the test is cheaper than a later reader inferring a strength it
   does not have.
7. **The value-typed claim is asserted with a positive control.** Four interaction types
   are checked not to be `AnyObject`, and the two actors are checked to **be** `AnyObject`
   — because a non-conformance assertion that can never fail proves nothing, and a later
   refactor of `ViewportSyncGroup` to a class must break this test rather than pass it.
8. **No algorithm specification and no oracle.** No numeric boundary is fixed.

## An independent confirmation of `ADR-0276`

Plan §22.3 states the publication rule directly: "A CPU or Metal result may be presented
only if its generation **equals** the current viewport generation."

`ADR-0276` derived that equality from the vocabulary — `RenderGeneration`'s initialiser is
internal, so every stamp names a past generation, so `!isStale` holds exactly at equality.
The plan states the same rule outright. The derivation and the plan agree, which is worth
recording because the derivation was reached without reading §22.3.

§22.2 also lists the ten state changes that must advance a generation — crosshair
movement, slice scroll, viewport resize, pan, zoom, interpolation change, window centre or
width, MONOCHROME state, dataset replacement, output colour descriptor. All of them reach
the same counter, which is why one test standing for the set is honest rather than
partial.

## Alternatives considered

### Assert a latency bound

Rejected twice over: it is `VOX-PER-005`'s subject on hardware nobody has approved, and
`ADR-0275` decision 4 already froze that no performance threshold is claimed in this arc.
A bound measured on this machine would also be a machine-load assertion wearing a
correctness costume.

### Use `Task.sleep` to establish that background work is running

Rejected. It would make the suite's slowest and least reliable test the one guarding a P0
row. An explicit gate makes "in flight" deterministic, and the test then asserts an order
rather than a duration.

### Discharge the `D` half with the headless harness too

Rejected, consistently with `ADR-0275` decision 5. Instrumented latency under background
load would be more rigorous than watching a window, and it is offered to the owner as an
option — but narrowing what Demonstration means for a P0 row to avoid an owner question is
the quiet scope reduction this project refuses.

### Test responsiveness through a full render pipeline under storage-budget pressure

Deferred, and worth naming because it is the one place responsiveness could genuinely
fail. `StorageReadCoordinator` carries a byte budget that background work can exhaust, and
a test previously mis-sized a ceiling by assuming coalescing would happen. But that is the
coordinator's contract rather than interaction's, it needs a full pipeline, and it belongs
with the `VOX-CON` rows.

### Claim the row vacuously, since nothing in the module can block

Rejected. It is nearly true and it is the reasoning `ADR-0270` refused for cache
preservation: a property worth having is worth making fail visibly when someone removes
it. The value-typed assertion with its positive control is precisely that guard.

## Consequences

`VOX-INT-008`'s `T` is discharged. **The interactive draw-loop arc's unblocked library
tier is now complete**: `VOX-INT-007`, `VOX-R2D-014` and `VOX-VS1-016` are discharged and
this row's testable half with them.

**What remains in the arc is owner-gated**: `VOX-INT-008`'s and `VOX-INT-010`'s
Demonstration halves need the application decision, and `VOX-PER-002/003/005` need
reference hardware. No further implementation work in this arc is unblocked.

A structural argument is now guarded by a test: if `ViewportSyncGroup` ever becomes a
reference type, or an actor method gains a suspension point that lets a caller hold it,
the guard fails rather than the reasoning quietly expiring.

## Affected modules

None. `VoxeliaInteractionTests` gains one suite of four tests; no source changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None. No measurement is taken and none is claimed.

## Validation impact

```text
swift build && swift test
swift test --filter "InteractiveResponsiveness"
python3 Tools/Scripts/check_swift_safety.py
swift format lint --strict Tests/VoxeliaInteractionTests/InteractiveResponsivenessTests.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1129 tests in 204 suites pass. The contention test was run repeatedly rather than once,
because a concurrency test that has passed a single time has not been shown to be stable.

## Migration

1. This record and its tests.
2. **Next**: no unblocked implementation work remains in this arc. The next actionable
   queue is elsewhere, and the ledger's exact-next-action should be re-derived rather than
   assumed.
3. **Owner**: the application-location decision from `ADR-0275`, which now blocks two
   Demonstration halves outright; reference hardware, which blocks three `VOX-PER` rows;
   §28.4's padding-aware interpolation rule; `VOX-CMP-006`'s and `VOX-CMP-012`'s Reviews;
   the five `J2KSwift` items; and the four other decisions already open.

## Supersession

This record supersedes nothing. It **discharges the half of `VOX-INT-008` that
`ADR-0275` identified as unblocked** and **independently confirms `ADR-0276`'s equality
derivation** against plan §22.3.

## References

- [ADR-0122 - Render generations](ADR-0122-render-generations.md)
- [ADR-0248 - Linked crosshair verification](ADR-0248-linked-crosshair-verification.md)
- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0275 - Open the interactive draw loop arc](ADR-0275-open-the-interactive-draw-loop-arc.md)
- [ADR-0276 - Frame presentation and generation wiring](ADR-0276-frame-presentation-and-generation-wiring.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
