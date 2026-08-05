---
document_id: "ADR-0150"
title: "Brick request broker"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-BRK-001"
  - "VOX-BRK-006"
  - "VOX-BRK-007"
  - "VOX-BRK-010"
  - "VOX-CON-009"
---

# ADR-0150 - Brick request broker

## Context

Accepted `ADR-0149` froze the brick request lifecycle with four
binding evidence obligations. This record implements it. It was
authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **`BrickRequestBroker` joins the execution module's coordination
   actors.** In-flight work is keyed by brick identity and a
   registered representation token; the first request for a key
   starts the caller-supplied computation and every concurrent
   duplicate registers a waiter on the same in-flight entry. Waiter
   registration happens synchronously inside the actor before any
   suspension, so a completion can never race past a joining
   request.
2. **Cancellation resumes only the cancelled waiter.** The
   cancellation handler removes that waiter and resumes it with the
   standard cancellation error; the computation continues for its
   followers, per the design.
3. **The generation guard runs at admission and at publish.** A
   request issued under a generation that is no longer current
   rejects immediately; at completion every waiter whose issued
   generation is no longer current rejects `staleGeneration` while
   current waiters receive the shared outcome — success and failure
   propagate identically to every current waiter.
4. **Evidence counters are internal state**, per the content-cache
   precedent: the started-computation count and per-key waiter count
   are readable by the suite, not public surface — the observability
   vocabulary belongs to the cache-and-observability design.

## Alternatives considered

Awaiting a shared task value was rejected: a task-value await is not
responsive to the awaiter's own cancellation and a late joiner could
race a completed task into a lost wake-up; explicit waiter
registration under actor isolation has neither hazard.

## Consequences

Bricks can be requested, deduplicated, cancelled and
generation-guarded; the cache-and-observability design has its
producer.

## Affected modules

`VoxeliaExecution`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One dictionary entry per in-flight key and one per waiter; no
allocation after completion.

## Validation impact

New suite `BrickRequestBrokerTests` discharges all four obligations:
sixty-four concurrent same-key requests resolving to exactly one
computation, distinct representations computing separately,
thirty-two cancelled awaiters releasing cleanly while the remainder
complete, and the stale-generation rejection for every awaiter with
the computation count still one — deterministically gated, no
wall-clock timing.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0149`; no record is superseded.

## References

- [ADR-0149 - Brick request lifecycle design](ADR-0149-brick-request-lifecycle-design.md)
- [ADR-0050 - Content-tier result cache](ADR-0050-content-tier-result-cache.md)
