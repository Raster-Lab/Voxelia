---
document_id: "ADR-0122"
title: "Render generations"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-007"
  - "VOX-ERR-001"
---

# ADR-0122 - Render generations

## Context

`VOX-INT-007` requires interaction updates to increment render
generations so stale frames are not presented. The frame scheduler
bounds in-flight frames with ordering evidence, but nothing named the
generation an interaction update mints or the staleness relation a
presenter checks. This record was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

`VoxeliaInteraction` gains the generation vocabulary:

1. **A comparable generation value.** `RenderGeneration` wraps one
   unsigned counter with total ordering and an explicit
   `isStale(comparedTo:)` relation — a frame stamped with an earlier
   generation than the current one is stale, and equality is
   freshness, so the presenter's check is one comparison with no
   convention to misread.
2. **An actor-isolated counter.** `RenderGenerationCounter` starts at
   generation zero and `advance()` returns the next generation
   atomically, so concurrent interaction updates mint strictly
   increasing, never-duplicated generations; the storm suite pattern
   proves uniqueness and monotonicity under concurrency.
3. **Presentation wiring stays with its loop.** Stamping frames and
   dropping stale ones is the interactive draw loop's behaviour,
   which remains gated on its own architecture; this vocabulary is
   the contract it will consume.

## Alternatives considered

Reusing the frame scheduler's frame index was rejected: a frame slot
index counts occupancy, a render generation counts scene versions,
and conflating them would tie pacing to staleness. Wall-clock stamps
were rejected: the pipeline mints no clock.

## Consequences

`VOX-INT-007` is discharged at the contract level; the draw-loop
integration remains recorded with its gate.

## Affected modules

`VoxeliaInteraction` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Values carry counters only.

## Performance and memory impact

Constant-size actor state.

## Validation impact

Tests must prove concurrent advances mint unique strictly increasing
generations, and the staleness relation over earlier, equal and later
generations.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0111` interaction vocabulary; no record is
superseded.

## References

- [ADR-0110 - Bounded frame contexts](ADR-0110-bounded-frame-contexts.md)
- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
