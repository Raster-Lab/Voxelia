---
document_id: "ADR-0318"
title: "Bounded brick working set"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PER-009"
---

# ADR-0318 - Bounded brick working set

## Context

`ADR-0317` split `VOX-PER-009` into a decoded-brick half that was one small test away and a
GPU-residency half blocked on an owner decision, and named this increment as the next step.
This supplies the brick half.

## Decision

1. **The resident set is reconstructed from the cache's own events**, not read from a private
   field. `decode` admits with a byte count and `eviction` removes with one, so admissions
   minus evictions give the working set. That is the stronger observation: it checks what the
   cache **reports to a host** against what it **promised**, so accounting that drifted from
   behaviour fails here.
2. **The invariant is checked after every insertion**, not at the end. A cache that grew
   without limit and trimmed once at the end would satisfy a final-state assertion.
3. **The two ceilings are exercised separately.** One run makes the byte ceiling unreachable
   so only the entry ceiling can hold the set; the other inverts it. A run that breached both
   could not say which bound did the work.
4. **Each run carries a positive control** — 200 bricks into 8 slots produces exactly 192
   evictions, so the bound held because eviction ran rather than because little was inserted.
5. **The brick half of `VOX-PER-009` is discharged.** The row as a whole is not: its
   GPU-residency half remains blocked on `ADR-0315`'s owner item, exactly as `ADR-0317` split
   it.

## The correction the run produced

The third test was written expecting a zero budget to admit a brick and immediately evict it,
leaving nothing resident. **It throws `BrickCacheError.resourceLimitExceeded` instead.**

That is better behaviour than the one assumed, and it strengthens the row's claim: the cache
**never admits something it cannot hold**, so the decoded-brick working set is bounded by
*refusal* as well as by eviction. The test now asserts the refusal, with a positive control
one byte either side — a 32-byte brick is refused at a 31-byte budget and admitted at 32 — so
the refusal discriminates on the budget rather than rejecting everything.

## Alternatives considered

### Read `totalByteCount` directly

Not available — it is `private`, which `@testable` does not reach — and not wanted. Reading the
cache's internal counter would test the counter against itself; reconstructing from events
tests the counter against what the host is told.

### One run exercising both ceilings

Rejected; see decision 3. It is the cheaper test and it cannot attribute the bound.

### Assert only the final resident set

Rejected; see decision 2. It is satisfied by a cache that is unbounded until its last
insertion.

## Consequences

`VOX-PER-009`'s decoded-brick half is evidenced, and the cache's refusal behaviour — stronger
than the eviction the row asked about — is recorded.

**5 entered-milestone rows remain** from `ADR-0290`'s sweep — unchanged, because the row's
GPU half is still open.

## Affected modules

None. Three tests in `VoxeliaExecutionTests`; no source file changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None to the product. The suite inserts 400 small bricks.

## Validation impact

```text
swift build && swift test
swift test --filter "BrickWorkingSetBoundTests"
swift format lint --strict Tests/VoxeliaExecutionTests/BrickWorkingSetBoundTests.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, up from 1235 in 218.

## Migration

1. This record and three tests. No source changed.
2. **Next**: the derived queue's remaining 5 rows.
3. **Owner**: unchanged. `VOX-PER-009`'s GPU half waits on `ADR-0315`'s existing item.

## Supersession

This record supersedes nothing. It **supplies** the half `ADR-0317` identified as unblocked.

## References

- [ADR-0151 - Brick cache design](ADR-0151-brick-cache-design.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0315 - Residency response is unbuilt](ADR-0315-residency-response-is-unbuilt.md)
- [ADR-0317 - Bounded working sets half built](ADR-0317-bounded-working-sets-half-built.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
