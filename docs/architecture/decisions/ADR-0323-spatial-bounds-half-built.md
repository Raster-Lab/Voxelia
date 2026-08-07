---
document_id: "ADR-0323"
title: "Spatial bounds half built"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-010"
---

# ADR-0323 - Spatial bounds half built

## Context

`VOX-SPA-010` requires that "spatial bounds shall be computable in index and physical
coordinates". P0, `T`, milestone M1. `ADR-0322` claimed the two shape rows beside it and left
this one open, recording that the existence of two bounds types is not the same as bounds being
computable in both spaces. This settles which it is.

## The measurement

- **Index bounds exist and are used.** `ImageRegion` carries integer lower and upper bounds and
  every storage read takes one.
- **Physical bounds exist only as a type.** `AxisAlignedBounds3D` is **constructed nowhere
  except inside its own file**, by its own `intersection` method, and is referenced only by
  `RayAxisAlignedBoundsIntersection` and its DocC page.

**No function anywhere takes a shape, a grid or a region and produces physical bounds.** So a
volume's bounds are not computable in physical coordinates at all: the type exists, and nothing
can make one from a volume.

The row is **half-built**, in the same shape `ADR-0317` recorded for `VOX-PER-009`.

## The numeric boundary to freeze before it is built

This is worth recording now because the obvious implementation is wrong.

Transforming the index box's **minimum and maximum corners** through `indexToWorld` and taking
those two points as the bounds is correct **only for an axis-aligned affine**. Under any
rotation — which is the normal case for a CT series, and the case `ADR-0313` confirmed the
oblique path admits — the transformed box is not axis-aligned, and its two transformed corners
are not the extremes of the transformed set.

The correct construction transforms **all eight corners** and takes the axis-aligned hull of
the results. That is the boundary a future record has to freeze, together with:

- the **traversal order** of the eight corners and the accumulation order of the minimum and
  maximum, since both are observable in binary64;
- whether the result is the hull of the **sample centres** or of the **sample extents**, which
  differ by half a voxel in each direction and is a genuine choice rather than a detail.

## Decision

1. **`VOX-SPA-010` is not discharged.** Its index half is in place and its physical half has a
   type with no producer.
2. **The two-corner implementation is recorded as wrong before it is written.** An increment
   reaching for the cheap version would produce bounds that are correct on every axis-aligned
   fixture and quietly too small on every oblique one — a defect that passes the tests a hurried
   author would write.
3. **No conversion is added here**, because the half-voxel question in the boundary above is a
   modelling choice that belongs in the record that implements it, with an algorithm
   specification if its accumulation order is observable.
4. **No test is written**, for the same reason `ADR-0307` and `ADR-0314` wrote none: there is
   nothing to test.

## Alternatives considered

### Add the conversion now, taking the eight-corner hull

Rejected only on the half-voxel question. The hull itself is settled by the analysis above; what
is not settled is whether it bounds sample centres or sample extents, and choosing that
silently inside an implementation is how a modelling decision becomes an accident.

### Claim the row on `ImageRegion` alone

Rejected. The row names both spaces, and one of them has no producer.

### Treat `AxisAlignedBounds3D` existing as the physical half

Rejected; see the measurement. A type nothing can construct from a volume does not make a
volume's bounds computable.

## Consequences

`VOX-SPA-010` is recorded as half-built with its blocking modelling question and its principal
implementation hazard both named.

**9 rows remain unclaimed** under `ADR-0319`'s criterion — unchanged, because this record
discharges nothing.

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

1238 tests in 219 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the conversion, once the half-voxel question is answered.
3. **Owner**: **one new item** — whether a volume's physical bounds enclose its **sample
   centres** or its **sample extents**. They differ by half a voxel per direction, and it is a
   modelling choice rather than an engineering one.

## Supersession

This record supersedes nothing. It **answers the question `ADR-0322` left open** and freezes the
hazard the implementation will meet.

## References

- [ADR-0313 - Arbitrary oblique reconstruction](ADR-0313-arbitrary-oblique-reconstruction.md)
- [ADR-0317 - Bounded working sets half built](ADR-0317-bounded-working-sets-half-built.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0322 - Canonical shape rows](ADR-0322-canonical-shape-rows.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
