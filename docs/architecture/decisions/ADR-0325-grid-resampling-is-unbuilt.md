---
document_id: "ADR-0325"
title: "Grid resampling is unbuilt"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-IMG-008"
---

# ADR-0325 - Grid resampling is unbuilt

## Context

`VOX-IMG-008` requires that "Voxelia shall provide image resampling between explicit source
and target grids". P0, `T`, milestone M2. `ADR-0324` claimed the two interpolation rows beside
it and left this one open, recording that resampling between extents and resampling between
grids are different operations. This settles which exists.

## The measurement

**The target is extents, not a grid.** `ResampleLinearOperation.execute` and its nearest
sibling take `outputWidth` and `outputHeight` — two integers. The *source* is an `ImageData`
that carries a `spatialGeometry`, so a source grid is available; **no target grid is
expressible at all.**

So the operations resample from a grid to a **pixel rectangle**. What the row asks for — a
target the caller specifies as a grid — has no parameter to receive it.

**The one operation that does take a target grid is `ObliqueSliceOperation`**, whose `request`
is an `AffineGridGeometry`. `ADR-0313` claimed it for `VOX-MPR-002`, and it is not this row:
it produces a **plane from a volume**, a rank reduction, where `VOX-IMG-008` asks for
resampling that preserves what is being resampled.

## Decision

1. **`VOX-IMG-008` is not discharged.** It is unbuilt in the sense `ADR-0307` and `ADR-0314`
   used: the capability the row names has no surface, rather than an unevidenced one.
2. **`ADR-0324`'s hypothesis is settled and closed.** That record wondered whether
   `ObliqueSliceOperation` might be the row's subject. It is not, and recording the negative
   stops the next increment re-opening the same guess.
3. **What such an operation would need is named**, so the increment that builds it starts from
   the boundary rather than the API:
   - a **target `AffineGridGeometry`** rather than two integers;
   - the **rule mapping a target sample to a source position**, which is the inverse of the
     target geometry composed with the source's forward map — the composition
     `VOXELIA-ALG-0052` and `ADR-0138` already freeze in their own directions, and whose
     **order here is a new frozen decision**;
   - whether the result is defined where the target grid falls **outside** the source, which is
     the padding question `ADR-0293` §55.5 was written to supply a phantom for.
4. **No test is written.** There is nothing to test, and the same reasoning as `ADR-0307`
   applies.

## Alternatives considered

### Read the extents-based operations as satisfying the row

Rejected; see the measurement. A caller cannot express a target grid, so no evidence from
those operations can be about grids.

### Build it now

Rejected on decision 3's second and third points. The sample-mapping order is a frozen numeric
boundary needing its own specification, and the out-of-source behaviour is a modelling choice
that `ADR-0293` already identified as needing a padding phantom. Both belong in the record that
implements the operation, not in a hurried addition.

### Record it as merely unclaimed

Rejected as understating it. Three rows in this queue were delivered and unclaimed; this one is
not delivered, and conflating the two would make the queue's remaining cost look smaller than
it is.

## Consequences

`VOX-IMG-008` is recorded as unbuilt with its two frozen-boundary questions named, and one
hypothesis is closed.

**7 rows remain unclaimed** under `ADR-0319`'s criterion — unchanged, because this record
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
2. **Next**: the remaining unclaimed rows. `VOX-IMG-008` resumes as its own arc, beginning with
   the sample-mapping order.
3. **Owner**: **one new item** — whether grid resampling is defined where the target grid falls
   outside the source, and if so with what value. It is the same padding question `ADR-0293`
   §55.5 anticipated.

## Supersession

This record supersedes nothing. It **settles the question `ADR-0324` left open** and closes the
hypothesis that record raised.

## References

- [ADR-0293 - Open the analytical phantom arc](ADR-0293-open-the-analytical-phantom-arc.md)
- [ADR-0313 - Arbitrary oblique reconstruction](ADR-0313-arbitrary-oblique-reconstruction.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0324 - Interpolation rows](ADR-0324-interpolation-rows.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](../../algorithms/VOXELIA-ALG-0052-affine-composition-and-directions.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
