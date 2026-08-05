---
document_id: "ADR-0149"
title: "Brick request lifecycle design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-BRK-001"
  - "VOX-BRK-006"
  - "VOX-BRK-007"
  - "VOX-BRK-010"
---

# ADR-0149 - Brick request lifecycle design

## Context

The accepted brick vocabulary names bricks; nothing yet governs how
they are requested. The M5 queue's second item is the lifecycle:
cancellable requests, safe deduplication of concurrent requests for
one brick and representation, and a generation guard so refinement
never publishes into an obsolete generation. Per the plan-first
discipline this record freezes the design before implementation. It
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **One actor, `BrickRequestBroker`, in `VoxeliaExecution`** beside
   the accepted coordination actors. The broker keys in-flight work
   by brick identity and representation token; the first request for
   a key starts the caller-supplied computation and every concurrent
   duplicate awaits the same in-flight result — the
   content-cache-and-identity-coordination deduplication precedent,
   whose storm evidence showed sixty-four requests resolving to two
   computations. Deduplication is declared safe only because the
   design requires the computation to be a pure function of the key;
   a caller violating that declaration is outside the contract, per
   `VOX-BRK-007`'s own "where safe".
2. **Cancellation is per awaiter and clean.** A cancelled awaiter
   throws immediately and releases its interest without corrupting
   the shared state; the version-one computation, once started, runs
   to completion so followers keep their result — abandoning the
   computation when every awaiter has cancelled is a recorded future
   refinement, not a silent behaviour. This is the `ADR-0118`
   cancellation-storm discipline applied to bricks, satisfying
   `VOX-BRK-001` and `VOX-BRK-006` at the request level.
3. **The generation guard is the broker's own counter.** Requests
   carry the generation they were issued under; the publish step
   compares against the broker's current generation and a stale
   result rejects typed for every awaiter and is discarded, never
   returned — `VOX-BRK-010` at the lifecycle level. The counter
   mirrors the accepted render-generation pattern inside the
   execution module because the interaction module sits above it in
   the dependency graph and cannot be imported downward; the
   duplication is recorded here deliberately, and the draw-loop arc
   binds its render generations to broker generations when it
   arrives.
4. **The typed vocabulary is minimal**: `staleGeneration` is the
   broker's one own case; a cancelled awaiter surfaces the standard
   cancellation error, and a failed computation propagates its own
   audited typed error to every awaiter identically — followers must
   not receive a different outcome than the leader.
5. **Evidence obligations bind the implementing increment**: a storm
   of sixty-four concurrent same-key requests resolving to exactly
   one computation; distinct representations of one brick not
   deduplicating together; thirty-two cancelled awaiters releasing
   cleanly while the remainder complete; and a stale-generation
   result rejecting typed for every awaiter with the computation
   count still one.

## Alternatives considered

Placing the broker in the storage module was rejected: the lifecycle
is coordination, the storage module owns values and byte access, and
the accepted coordination actors already live in execution.
Cancelling the shared computation when any awaiter cancels was
rejected: one viewport abandoning a brick must not steal it from
another. Reusing the interaction module's generation type was
rejected by the dependency direction, and inverting the dependency
for a counter would couple the layers backwards.

## Consequences

The cache-and-observability design gains a defined producer; brick
work can be requested, deduplicated, cancelled and generation-guarded
before any cache or codec exists.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The evidence obligations above bind the implementing increment.

## Migration

None; implementation follows as its own increment.

## Supersession

Continues the M5 arc over accepted `ADR-0147` and `ADR-0148`; no
record is superseded. Decision 2's version-one completion rule is
superseded by accepted `ADR-0157`, which delivers the recorded
abandonment refinement.

## References

- [ADR-0148 - Brick vocabulary](ADR-0148-brick-vocabulary.md)
- [ADR-0122 - Render generations](ADR-0122-render-generations.md)
- [ADR-0118 - Concurrency storm evidence](ADR-0118-concurrency-storm-evidence.md)
- [ADR-0050 - Content-tier result cache](ADR-0050-content-tier-result-cache.md)
