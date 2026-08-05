---
document_id: "ADR-0153"
title: "Instrumented brick cache"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-BRK-008"
  - "VOX-CCH-008"
  - "VOX-CCH-009"
  - "VOX-ERR-001"
---

# ADR-0153 - Instrumented brick cache

## Context

Accepted `ADR-0151` designed the cache and `ADR-0152` delivered its
values; this record implements the actor that composes them with the
accepted broker. It was authored and accepted on 2026-08-05 under
the project owner's recorded broadened autonomous delegation.

## Decision

1. **`BrickResultCache` joins the execution module's coordination
   actors** with two explicit inclusive budgets and the explicit
   optional event sink — no permissive defaults, absence stated at
   every call site, per the content-tier precedent. Entries are
   keyed by brick identity and representation and carry their
   content digest beside the stored bytes and the eviction fields;
   recency and insertion ordinals are the actor's own monotonic
   counters, minting no clock.
2. **Lookup revalidates before returning.** A digest mismatch
   removes the entry and rejects the typed corruption case; a hit
   touches the recency ordinal and emits the hit event; a miss emits
   the miss event and returns nil rather than erroring.
3. **The integrated path composes the broker and emits the full
   story.** `result(for:)` returns a revalidated hit; on a miss it
   resolves through the broker's deduplicated computation, emits the
   decode event with the caller-measured cost, and admits; on a
   corrupt entry it removes, emits the recomputation event in place
   of the miss, and resolves fresh — the design's recomputation path
   made concrete. Reentrant duplicate admissions are idempotent.
4. **Eviction consults only the accepted authorities.** Admission
   over budget evicts the minimum of the frozen `evictsBefore` order
   among entries without active references, emitting one eviction
   event per removal; when nothing is evictable the admission
   rejects typed rather than displacing a referenced entry. Retain,
   release and visibility mutations are typed, including the
   over-release.
5. **One internal evidence seam** tampers a stored entry for the
   corruption obligation, named for that purpose and not public —
   the suite cannot otherwise prove the revalidation rejection.

## Alternatives considered

Emitting events through a task-hopped asynchronous sink was
rejected: event order would depend on scheduler interleaving and the
suite could not assert the story; the synchronous sink preserves the
actor's own sequencing.

## Consequences

The M5 cache tier is operational: deduplicated, budgeted,
generation-aware brick results with honest corruption recovery and
host-observable instrumentation.

## Affected modules

`VoxeliaExecution`.

## Compatibility impact

Additive only.

## Security impact

Event payloads carry identities, counts and cost units only, per the
recorded exclusion rules.

## Performance and memory impact

One digest verification per lookup and admission; eviction is linear
in the entry count per displaced entry.

## Validation impact

New suite `BrickResultCacheTests` discharges the design obligations:
the frozen-order eviction with the invisible entry displaced first,
the typed corruption rejection with removal proven through the
evidence seam, all five events observed in order across one
integrated story, absent-sink paths exercised unchanged, and the
retained entry surviving eviction pressure with the typed rejection
until released.

## Migration

None; the surface is new.

## Supersession

Implements the actor half of accepted `ADR-0151`; no record is
superseded.

## References

- [ADR-0151 - Brick cache design](ADR-0151-brick-cache-design.md)
- [ADR-0152 - Brick cache vocabulary](ADR-0152-brick-cache-vocabulary.md)
- [ADR-0150 - Brick request broker](ADR-0150-brick-request-broker.md)
