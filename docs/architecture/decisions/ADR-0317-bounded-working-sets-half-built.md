---
document_id: "ADR-0317"
title: "Bounded working sets half built"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PER-009"
---

# ADR-0317 - Bounded working sets half built

## Context

`VOX-PER-009` requires that "large-volume tests shall demonstrate bounded decoded-brick and
GPU-residency working sets". P0, **`T,A`**, milestone M5, from `ADR-0290`'s sweep.

Two working sets, and they are in opposite states.

## The decoded-brick working set: bounded by construction

`BrickResultCache` takes `maximumEntryCount` and `maximumTotalByteCount` as **required
initialiser parameters**. Neither has a default, so a cache cannot exist without both
ceilings, and `BrickEvictionConsideration` supplies the frozen eviction order `ADR-0151`
governs.

**That is stronger than a demonstration.** A test showing the bound holds for one volume shows
it held once; a required parameter means an unbounded brick cache is not constructible. The
row asks for the weaker evidence, and the stronger property is already in place.

What is **not** in place is the row's actual wording: no *large-volume* test drives the cache
past its ceilings and observes eviction keeping the set bounded. `BrickResultCacheTests`
exercises the vocabulary and the ordering.

## The GPU-residency working set: unbounded

`ADR-0315` measured this two increments ago. `MetalExecutionContext` reads
`device.recommendedMaxWorkingSetSize` and publishes it, and **no allocation path consults it**.
There is no ceiling, so there is no bound to demonstrate.

## Decision

1. **`VOX-PER-009` is not discharged.** One half has a bound and no large-volume test; the
   other has no bound at all. Discharging on the brick half would claim a GPU property that
   does not exist.
2. **The brick half's `A` is recorded as satisfied by construction**, and this record is that
   analysis: two required ceilings and a frozen eviction order make an unbounded decoded-brick
   working set unconstructible.
3. **The brick half's `T` is a real, small, unblocked increment** — drive `BrickResultCache`
   past both ceilings with a volume large enough to force repeated eviction, and assert the
   entry count and total bytes never exceed them. It needs no owner decision and is the next
   thing to do on this row.
4. **The GPU half stays blocked on `ADR-0315`'s owner item** — what should happen when an
   allocation would cross the device budget. Until that is answered there is no ceiling for a
   test to observe.
5. **The two halves are not merged in evidence.** A single test named for this row that only
   exercised bricks would read as covering both.

## Alternatives considered

### Discharge on the brick half and note the GPU half as outstanding

Rejected; see decision 1. The row names both working sets in one sentence, and a partial
discharge on a P0 row is how a gap becomes invisible.

### Write the brick large-volume test in this increment

Not done, and this is a scoping choice rather than a judgement about its value. It is decision
3's named next step; recording the split first means the increment that writes it cannot
quietly widen into claiming the GPU half too.

### Treat `recommendedMaximumWorkingSetByteCount` as the GPU bound

Rejected. It is a device capability that is read and never consulted. A number nobody compares
against is not a bound, which is exactly what `ADR-0315` recorded.

## Consequences

`VOX-PER-009` is split into a half that is one small test away and a half blocked on an owner
decision, so its cost is legible rather than uniform.

**5 entered-milestone rows remain** from `ADR-0290`'s sweep — unchanged.

## Affected modules

None.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: decision 3's large-volume brick test, which is unblocked.
3. **Owner**: unchanged. The GPU half waits on `ADR-0315`'s existing item.

## Supersession

This record supersedes nothing. It **splits a row** whose two halves are in opposite states.

## References

- [ADR-0151 - Brick cache design](ADR-0151-brick-cache-design.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0315 - Residency response is unbuilt](ADR-0315-residency-response-is-unbuilt.md)
- [ADR-0316 - Metal heaps not yet warranted](ADR-0316-metal-heaps-not-yet-warranted.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
