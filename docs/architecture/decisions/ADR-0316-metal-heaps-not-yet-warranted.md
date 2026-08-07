---
document_id: "ADR-0316"
title: "Metal heaps not yet warranted"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-011"
---

# ADR-0316 - Metal heaps not yet warranted

## Context

`VOX-MTL-011` requires that "Metal heaps shall be used **where they provide measurable
allocation or residency benefit**". P1, **`A,T`**, milestone M5, from `ADR-0290`'s sweep.

The row is **conditional**, and that changes what discharging it means. An analysis showing the
condition is not met is a complete answer to it; building heaps anyway would answer a
requirement that says something else.

## The measurement

**No heap appears anywhere.** `MTLHeap`, `makeHeap`, `MTLHeapDescriptor` and
`heapBufferSizeAndAlign` occur zero times across `Sources/` and `Tests/`.

Every allocation is direct, and there are six sites: the invert, window-level and composite
kernels each allocate their output, `MetalBufferTransfer` allocates a staging buffer, and
`MetalResidencyManager.makeBuffer` allocates under a declared policy.

**Every one of them is scoped to a single dispatch or a single request.** `ADR-0081` states
the manager's rule directly: allocated buffers "remain local to each request rather than
becoming shared manager state".

## The analysis

A heap earns its cost by backing **many resources with overlapping lifetimes** from one
allocation: the driver allocates once, sub-allocates cheaply, and the whole set becomes
resident or non-resident together. Both halves of the row's benefit — allocation and residency
— depend on that overlap.

**Voxelia has no such set.** Each buffer is created for one dispatch and released when it
ends; no two are deliberately co-resident, and there is no pool whose residency would be
managed as a unit. A heap here would back one short-lived buffer at a time, which is direct
allocation with an extra object in front of it.

**This is a structural argument, not a benchmark, and the record says so plainly.** No
heap-versus-direct measurement was taken, because the precondition for a benefit is absent —
measuring would produce a number about a configuration nobody would ship.

## Decision

1. **`VOX-MTL-011`'s `A` is discharged** by the argument above: the condition the row makes
   heaps contingent on is not met by the current allocation pattern.
2. **Its `T` is not applicable while that holds, and is not claimed.** The row's test
   obligation attaches to heaps being *used*; there is nothing to test, and writing a test
   asserting no heap exists would test the absence rather than the requirement.
3. **The trigger for revisiting is named**, so this is a deferral with a condition rather than
   a dismissal: **the first allocation site that keeps several buffers co-resident across
   dispatches** — a brick pool, a persistent volume residency set, or the working-set bounding
   `ADR-0315` leaves open. Any of those creates the overlap a heap needs, and the measurement
   becomes worth taking at that point.
4. **No heap is introduced speculatively.** Adding one now would be an untestable claim of
   benefit and would put an object in the allocation path that no measurement supports.

## Alternatives considered

### Benchmark heaps against direct allocation now

Rejected; see the analysis. The comparison would be one short-lived buffer per heap against one
direct allocation, which measures overhead rather than the benefit the row is about.

### Introduce a heap behind `MetalResidencyManager` and discharge both methods

Rejected. It would make the row's `T` satisfiable, and it would do so by creating the thing the
row says to create only when it helps — the requirement read backwards.

### Record the row as unbuilt, like `VOX-CON-008` and `VOX-MTL-013`

Rejected, and the distinction matters. Those rows name capabilities that do not exist and
should. This one names a technique that is **correctly absent**, and its analysis half is
genuinely satisfiable today. Filing it as unbuilt would understate what is known.

## Consequences

`VOX-MTL-011`'s analysis is discharged with the condition it turns on measured, and the row's
test obligation is parked against a named trigger rather than left ambiguous.

**5 entered-milestone rows remain** from `ADR-0290`'s sweep — the row is not fully discharged,
so the count is unchanged.

## Affected modules

None.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None. No allocation path changes.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the derived queue's remaining 5 rows. `VOX-MTL-011`'s `T` resumes at the trigger
   in decision 3.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **answers a conditional requirement by measuring its
condition**.

## References

- [ADR-0081 - Metal residency strategy](ADR-0081-metal-residency-strategy.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0306 - Residency duplication analysis](ADR-0306-residency-duplication-analysis.md)
- [ADR-0315 - Residency response is unbuilt](ADR-0315-residency-response-is-unbuilt.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
