---
document_id: "ADR-0315"
title: "Residency response is unbuilt"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-013"
---

# ADR-0315 - Residency response is unbuilt

## Context

`VOX-MTL-013` requires that "GPU resource residency shall respond to memory pressure and
active workload priority". P0, **`T,D`**, milestone M5, from `ADR-0290`'s sweep.

The row has two halves and they are in different states, so it is measured half by half.

## Half one: active workload priority

Blocked, and already recorded. `ADR-0314` found the words `priority` and `Priority` do not
appear in `Sources/` at all. There is no workload priority for residency to respond to.

## Half two: memory pressure — and the finding

There is **no response** to memory pressure. No `DISPATCH_SOURCE_TYPE_MEMORYPRESSURE`, no
`setPurgeableState`, and no path that releases or downgrades a GPU allocation when memory
tightens. `MetalResidencyManager` allocates and returns; nothing later reconsiders.

Eviction does exist, and it is **not** this. `BrickEvictionConsideration` in `VoxeliaStorage`
gives the brick cache a frozen eviction order under `ADR-0151` — that is a **CPU-side cache**
policy, not GPU residency, and reading it as evidence for this row would be reading a
neighbouring subsystem's work as this one's.

**The input the row needs is already in hand and consumed by nothing.**
`MetalExecutionContext` reads `device.recommendedMaxWorkingSetSize` and publishes it as
`recommendedMaximumWorkingSetByteCount`. Searching every use finds: the declaration, the
initialiser parameter, the assignment, the capability read, and **two test lines that assert
it is greater than zero and print it**. No allocation path consults it. The budget exists as a
number, and nothing is bounded by it.

That is a milder form of the pattern this arc has now found eight times: not a rule with no
enforcement, but a **capability captured with no consumer**.

## Decision

1. **`VOX-MTL-013` is not discharged, and no test is written.** Both halves are unbuilt, and a
   test of a response that does not exist would assert nothing.
2. **The unconsumed working-set budget is recorded as the row's natural starting point.** When
   the row is built, the first question is not where to get a memory-pressure signal — it is
   already read — but what should happen when an allocation would cross it.
3. **`BrickEvictionConsideration` is named as *not* being this row's evidence**, so a later
   increment does not mistake it for a discharge. It is a different subsystem, a different
   memory, and a different frozen policy.
4. **No pressure-handling design is proposed here.** Whether Voxelia should evict, downgrade
   `.privateDevice` to `.shared`, or refuse an allocation that would exceed the budget is a
   clinical-safety trade as much as an engineering one: a refused allocation is a failed
   render, and a downgraded one is a slower one.
5. **The `D` remains an owner item.**

## Alternatives considered

### Read `BrickEvictionConsideration` as the response

Rejected; see decision 3. It orders CPU-side cache entries and never touches a `MTLBuffer`.

### Bound allocations by the working-set budget now

Rejected as deciding decision 4 by accident. Adding a bound is a two-line change and choosing
what happens at the bound is the whole requirement.

### Record only that the row is unbuilt

Rejected as under-reporting. That the memory-pressure input is already read, and unused, is the
most useful thing this measurement produced.

## Consequences

`VOX-MTL-013` is recorded as unbuilt on both halves, with its starting point identified and one
false trail closed.

**5 entered-milestone rows remain** from `ADR-0290`'s sweep — unchanged.

## Affected modules

None.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None. This record changes nothing.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the derived queue's remaining 5 rows.
3. **Owner**: **one new item** — what should happen when a GPU allocation would cross the
   device's recommended working-set budget: refuse, downgrade, or evict. A refused allocation
   is a failed render and a downgraded one is a slower render, so the choice is a safety trade.

## Supersession

This record supersedes nothing. It **records a row as unbuilt**, names a captured capability
with no consumer, and closes a false trail.

## References

- [ADR-0151 - Brick cache design](ADR-0151-brick-cache-design.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0306 - Residency duplication analysis](ADR-0306-residency-duplication-analysis.md)
- [ADR-0314 - Priority propagation is unbuilt](ADR-0314-priority-propagation-is-unbuilt.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
