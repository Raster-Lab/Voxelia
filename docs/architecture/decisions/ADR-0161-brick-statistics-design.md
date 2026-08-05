---
document_id: "ADR-0161"
title: "Brick statistics design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-BRK-011"
  - "VOX-DVR-012"
---

# ADR-0161 - Brick statistics design

## Context

Empty-space skipping and load prioritisation need per-brick
statistics, and the accelerated renderer that will consume them is
gated on later arcs — the vocabulary must exist first and must not
smuggle the consumer in. Per the plan-first discipline this record
freezes the value model before implementation. It was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

1. **Statistics derive from bytes; they are never stored beside
   them.** `BrickStatistics` is obtainable only through a pure
   computing initializer over a brick's core payload and an optional
   sentinel — the brick-identity precedent of deriving rather than
   storing, so statistics and bytes can never disagree.
2. **The version-one fields are exact integers over one ascending
   pass**: the total sample count, the included count after the
   accepted sentinel-exclusion rule, the included minimum and
   maximum — absent rather than fabricated when every sample is
   excluded — and the non-zero included count, the classic occupancy
   signal for intensity volumes. An empty payload rejects typed.
3. **Skipping is the consumer's decision, recorded as such.**
   Whether a brick is skippable depends on the transfer function and
   the operation consuming it; the statistics state facts — extremes
   and occupancy — and no `isEmpty` verdict exists in the
   vocabulary, because a verdict would bake one consumer's rule into
   every consumer's value.
4. **Implementation follows separately** in the storage module
   beside the brick vocabulary, with exact fixtures including the
   all-excluded and all-zero payloads.

## Alternatives considered

Storing statistics on the bricked provider's entries was rejected:
stored derived values drift from their bytes, and the computing
initializer makes disagreement unrepresentable. A boolean emptiness
verdict was rejected as one consumer's rule; a histogram was
deferred — no consumer needs more than extremes and occupancy yet,
and speculative fields are compatibility debt.

## Consequences

The acceleration arcs — empty-space skipping in the volume renderer
and load prioritisation in the cache — gain their fact vocabulary
without a gated consumer arriving early.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The implementing increment must reproduce exact fixtures including a
partially excluded payload, an all-excluded payload with absent
extremes, an all-zero payload with zero occupancy, and the typed
empty-payload rejection.

## Migration

None; implementation follows as its own increment.

## Supersession

Continues the M6 arc; no record is superseded.

## References

- [ADR-0148 - Brick vocabulary](ADR-0148-brick-vocabulary.md)
- [ADR-0113 - Pixel padding exclusion](ADR-0113-pixel-padding-exclusion.md)
