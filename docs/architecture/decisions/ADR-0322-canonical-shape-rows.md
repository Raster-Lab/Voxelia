---
document_id: "ADR-0322"
title: "Canonical shape rows"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DAT-002"
  - "VOX-DAT-003"
---

# ADR-0322 - Canonical shape rows

## Context

`ADR-0319`'s rederived queue lists three M1 rows. This claims the two about the canonical
shape type. The third, `VOX-SPA-010`, is deliberately left — see below.

## The measurement

**`VOX-DAT-002`** — "the canonical shape type shall represent extents using a variable-rank
representation". `ImageShape` stores `extents` as a `ContiguousArray<Int>` and derives `rank`
from its count, so rank is a property of the value rather than of the type. Its initialiser is
generic over any `Collection` whose element is `Int`, so a caller is not pushed toward a fixed
arity at the call site either.

**`VOX-DAT-003`** — "shape construction shall reject zero and negative extents". The
initialiser throws `ShapeError.nonPositiveExtent(axis:value:)` on the first offending extent,
and `ShapeError.emptyRank` for an empty collection. The refusal **names the axis and the
value**, which is more than the row asks and is what makes a failure actionable rather than
merely correct.

Both are covered by `ImageShapeTests`, fourteen tests.

## Decision

1. **`VOX-DAT-002` and `VOX-DAT-003` are claimed and their `I` and `T` discharged** on the
   surface and suite above.
2. **`VOX-SPA-010` is not claimed here**, and the reason is stated rather than left as an
   omission. That row requires spatial bounds to be "computable in index **and** physical
   coordinates". Both representations exist — `ImageRegion` carries integer lower and upper
   bounds, `AxisAlignedBounds3D` carries two `Point3D` values with a coordinate space — but
   whether a **conversion between them** is provided, and under which frozen evaluation, was
   not established. Claiming the row on the existence of two types would assert a relationship
   neither of them states.
3. **No new test and no new gate.** The rejection is already exercised, and a gate asserting
   that a type validates its own initialiser would duplicate the initialiser.

## Alternatives considered

### Claim `VOX-SPA-010` alongside them

Rejected; see decision 2. Two bounds types existing is not the same as bounds being computable
in both spaces, and this arc has already had to untangle one row claimed on adjacent evidence.

### Add a test that zero and negative extents are rejected

Not needed. `ImageShapeTests` covers it; adding a second assertion of the same refusal would
grow the suite without discriminating anything new.

## Consequences

Two M1 rows are claimed, and the reason the third is not is recorded where the next increment
will read it.

**9 rows remain unclaimed** under `ADR-0319`'s criterion, recomputed rather than decremented.

## Affected modules

None. This record adds no code.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter "ImageShape"
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: `VOX-SPA-010`, beginning with whether an index-to-physical bounds conversion
   exists and under which frozen rule.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **claims** two rows delivered without a record naming them.

## References

- [ADR-0300 - CPU Metal differential references](ADR-0300-cpu-metal-differential-references.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0320 - Repository baseline rows](ADR-0320-repository-baseline-rows.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
