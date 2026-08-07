---
document_id: "ADR-0341"
title: "Study cache generation and priority"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-CON-008"
  - "VOX-PER-006"
---

# ADR-0341 - Study cache generation and priority

## Context

`VOX-CON-008` — priority propagated so interactive work can pre-empt or outrank
background cache generation, P1, `T,D`, M3 — was measured unbuilt by `ADR-0314`: no
priority vocabulary existed, and more fundamentally **no background cache generation
existed to outrank**. That record found the row shares its missing artefact with
`VOX-PER-006`: `ADR-0307` measured that no study cache exists, so neither a
completion to precede nor a stage to outrank. `ADR-0338` decision 2 supplied the
blocking definition: a *study cache* is the decoded brick store generated from an
ingested study, its clock starting when generation starts. This record builds the
stage and discharges this row's `T`; the first-useful-image row composes the stage's
completion in its own increment.

## Decision

1. **`StudyCacheGenerator` in `VoxeliaExecution` is the study-cache generation
   stage.** It sweeps a study's brick identities, in caller order, through the
   accepted cache-through-broker entry point
   (`BrickResultCache.result(for:representation:generation:visible:reconstructionCost:broker:compute:)`),
   so generation is a real stage with a start, per-brick progress and a completion
   — the artefact `ADR-0307` and `ADR-0314` recorded as missing. The decoded brick
   store it fills is `BrickResultCache`, exactly as `ADR-0338` decision 2 defines
   the study cache.

2. **No priority vocabulary is invented — propagation is structural, and that is
   the point.** `ADR-0314` decision 3 refused a `TaskPriority` parameter carried
   "from nowhere to nowhere"; its alternative 2 refused crediting the language
   alone while no code created the background work. Both objections dissolve
   together: the generator runs inside the caller's task, so the priority the
   caller chose (`.utility` for background generation) propagates through
   structured concurrency into every brick computation, and interactive callers
   reach the same store through the same broker inside their own higher-priority
   tasks. Voxelia's contribution is the stage and the relationship; the language's
   contribution is the carriage. The tests observe both rather than asserting
   either.

3. **Interactive work outranks the sweep by construction, not by scheduling
   luck.** The broker has no queue an interactive request could wait in: a request
   for a brick the sweep has not reached starts computing immediately in the
   caller's task; a request for the brick the sweep is computing joins the
   in-flight computation through the accepted deduplication; a request for a
   swept brick is a cache hit. The deterministic gate tests assert an interactive
   result completes while the sweep is still blocked on its first brick — ordering
   proven with no wall-clock timing anywhere.

4. **The sweep is sequential with a bounded working set**: one brick in flight at
   a time, skip-if-cached through the cache's own hit path, duplicate input
   identities harmlessly hitting on their second visit. Widening to bounded
   concurrency is a future record's decision; sequential is what the decoded-brick
   working-set discipline already bounds.

5. **Cancellation composes `ADR-0157` unchanged**: cancelling the generator's task
   cancels the current brick's await under the broker's last-awaiter rule, the
   sweep stops without a partial-completion claim, and a cancelled generation
   publishes no completion. `ADR-0249` decision 7's guarantee is untouched — the
   generator never publishes volumes, only cache admissions.

6. **Progress is a sink, not state**: an optional `@Sendable` closure receiving
   `StudyCacheProgress` (completed count, total count) after each brick, the cache
   event-sink precedent. The final callback — completed equal to total — is the
   completion `VOX-PER-006`'s clock needs. Reconstruction cost travels per brick
   in `StudyCacheBrick`, since the cache's eviction ordering consumes it per
   entry.

7. **No new error family.** Every failure is an existing audited type — the
   broker's stale generation, the cache's admission errors, the computation's own
   errors, `CancellationError` — propagated unchanged. A per-brick failure aborts
   the sweep fail-closed.

8. **`VOX-CON-008`'s `T` is discharged by this increment**; its `D` remains
   owner-witnessed per `ADR-0314` decision 5, joining the release list
   `ADR-0338` decision 11 records.

## Alternatives considered

### A priority-ordered work queue inside the broker

Rejected. A queue is the thing interactive work would have to outrank; the
broker's queueless design already gives interactive requests immediate start or
in-flight join. Building a queue to then prove work can jump it would manufacture
the problem the row exists to prevent.

### Priority escalation for in-flight joins

Recorded, not built. When a high-priority caller joins a computation the sweep
started at `.utility`, the continuation-based broker does not escalate the running
computation's priority (escalation follows structured awaits, not continuations).
The exposure is bounded by decision 4 — one brick in flight, so the wait is one
brick's decode — and an escalating broker is a measurable future improvement, not
a correctness gap in this row's claim.

### Concurrent sweep

Rejected for version one; see decision 4. Concurrency width is a resource policy
that deserves its own measurement against the working-set ceiling rather than a
guess inside this record.

## Consequences

Background study-cache generation exists, interactive work provably outranks it,
and `VOX-PER-006` gains the completion its clock starts from. Every M3 row is now
accounted for.

## Affected modules

`VoxeliaExecution` gains `StudyCacheGenerator`, `StudyCacheBrick` and
`StudyCacheProgress`. No existing type changes shape.

## Compatibility impact

Additive only.

## Security impact

None. The generator admits nothing the cache would not admit from any caller.

## Performance and memory impact

One brick in flight; the cache's own ceilings bound admission. The sweep adds no
allocation beyond the progress values.

## Validation impact

```text
swift test --filter StudyCacheGeneratorTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The suite is gate-driven and deterministic — no sleeps, no wall-clock ordering.
The full suite must show the literal pass line before push.

## Migration

1. This record.
2. The generator, its vocabulary values and the deterministic suite, in the same
   increment.
3. **Next**: `VOX-PER-006` composes the generator's completion with the
   first-useful-image definition from `ADR-0338` decision 2.
4. **Owner**: the `D` half joins the release demonstrations.

## Supersession

This record supersedes nothing. It builds the artefact `ADR-0307` and `ADR-0314`
measured absent, under the definition `ADR-0338` decision 2 supplied, composing
`ADR-0150`'s broker and `ADR-0157`'s cancellation contract unchanged.

## References

- [ADR-0150 - Brick request broker](ADR-0150-brick-request-broker.md)
- [ADR-0157 - Brick request abandonment](ADR-0157-brick-request-abandonment.md)
- [ADR-0307 - First useful image is unbuilt](ADR-0307-first-useful-image-is-unbuilt.md)
- [ADR-0314 - Priority propagation is unbuilt](ADR-0314-priority-propagation-is-unbuilt.md)
- [ADR-0338 - The owner decision batch](ADR-0338-the-owner-decision-batch.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
