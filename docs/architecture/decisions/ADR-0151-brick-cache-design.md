---
document_id: "ADR-0151"
title: "Brick cache design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-BRK-008"
  - "VOX-CCH-007"
  - "VOX-CCH-008"
  - "VOX-CCH-009"
  - "VOX-ERR-006"
---

# ADR-0151 - Brick cache design

## Context

The M5 queue's third item joins four concerns that share one
consumer: the brick cache's eviction inputs, its persistent format
versioning, its corruption rule and the instrumentation the host
observes. The diagnostics assessment required a real consumer and a
decision record before any instrumentation vocabulary could exist —
this is that record, and the cache is that consumer. Per the
plan-first discipline it freezes the design before implementation.
It was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **Eviction inputs are a value; the order is frozen without
   weights.** `BrickEvictionConsideration` carries per-entry inputs
   only: the last-access generation ordinal — recency as an ordinal
   because cache values mint no clock — the caller-measured
   reconstruction cost in declared cost units, the byte size, the
   visibility flag and the active-reference count. An entry with
   active references is never evictable — that is correctness, not
   policy. Among evictable entries the version-one order is
   lexicographic, chosen over numeric weights the baseline row
   forbids hard-coding: invisible before visible, then oldest access
   generation, then cheapest reconstruction, then largest byte size,
   with the insertion ordinal as the deterministic tie-break.
2. **Persistent cache formats carry their own version value.**
   `CacheFormatVersion` pairs a registered format token with a
   semantic version, stamped on any persisted cache artifact. No
   persistent brick cache exists yet; the value binds the future
   persistence increment, per `VOX-CCH-007`.
3. **Corruption rejects typed and is never published.** Every cached
   entry carries the content digest of its bytes; a lookup
   revalidates before returning — the content-tier cache's accepted
   discipline composed, not re-invented — and a mismatch removes the
   entry, rejects typed and surfaces the recomputation path, per
   `VOX-CCH-008`.
4. **Instrumentation is a closed coded event set behind a host-owned
   sink.** `BrickCacheEvent` covers exactly hit, miss, eviction,
   decode and recomputation per `VOX-CCH-009`, each with a
   structured payload of identifiers, ordinals, byte counts and
   caller-measured durations — no image bytes, no metadata values,
   no content-derived digests, per the `ADR-0145` binding rules. The
   sink is the telemetry-sink precedent: an explicit optional
   closure, absent by default, so emission is off unless the host
   opts in.
5. **The `VOX-ERR-006` remainder is mapped, not smuggled**: kernel
   and command-buffer timings are already observable through the
   dispatch telemetry; upload time, frame time, memory budget, brick
   faults and refinement progress belong to the residency and
   draw-loop arcs and are recorded here as out of scope.
6. **Implementation follows separately** — the values first, then
   the instrumented cache actor composing the broker.

## Alternatives considered

A numeric scoring formula was rejected: the baseline row forbids
hard-coded weights, and a lexicographic order is deterministic
without them. Emitting events from inside the broker was rejected:
the cache is the observable component, and instrumenting the broker
would emit duplicate events for one logical request. One combined
mega-record for all of `VOX-ERR-006` was rejected: most of its items
belong to gated arcs, and claiming them now would misreport scope.

## Consequences

The cache tier has a frozen vocabulary, order, corruption rule and
event set; the diagnostics assessment's precondition is satisfied by
this record.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

The instrumentation payloads are bound to the recorded exclusion
rules before any emission exists.

## Performance and memory impact

None in this increment.

## Validation impact

The implementing increments must prove the frozen eviction order
over a fixture set covering every lexicographic rank, the typed
corruption rejection with the entry removed, the event emission for
all five cases with sink absence emitting nothing, and the
never-evict rule for active references.

## Migration

None; implementation follows as its own increments.

## Supersession

Satisfies the consumer precondition of `ADR-0145`; no record is
superseded.

## References

- [ADR-0145 - Diagnostics and logging assessment](ADR-0145-diagnostics-assessment.md)
- [ADR-0150 - Brick request broker](ADR-0150-brick-request-broker.md)
- [ADR-0050 - Content-tier result cache](ADR-0050-content-tier-result-cache.md)
