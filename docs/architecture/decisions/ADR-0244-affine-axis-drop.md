---
document_id: "ADR-0244"
title: "Affine axis drop"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-004"
  - "VOX-VS1-009"
  - "VOX-MPR-001"
---

# ADR-0244 - Affine axis drop

## Context

`ADR-0243` closed the bridge arc with one blocker: `SqueezeAxesOperation` refuses
any volume carrying a spatial geometry, and `MPRSliceCoordinator` uses squeeze as
its second stage, so no volume with patient-space geometry can be reconstructed.
Eleven first-vertical-slice requirements wait on it.

## The correction: there is no arithmetic, and ADR-0243 said there was

`ADR-0243` described the rule as needing "real arithmetic": the dropped axis's
contribution folding into the origin, the matrix losing a column, and the axis
mapping renumbering. It also said the increment would need "an algorithm
specification with a frozen expression order, an oracle".

**Two of those three are wrong.**

**The fold is identically zero.** `SqueezeAxesOperation` drops only axes whose
extent is **one** — it already guards `inputExtents[$0] == 1` — so the dropped
axis's index is always `0`, and its contribution to the position is
`column × 0`. There is nothing to fold. In the MPR path this is doubly true:
`RegionExtractionOperation` has already translated the origin by the slab's lower
bounds, which a test in `ADR-0243` verified.

**So no numeric boundary exists, and no algorithm specification is issued.** The
rule is a column permutation and an axis renumbering — moving numbers, not
computing them. Freezing an expression order for arithmetic that does not happen
would be the ceremony `ADR-0237` warned about.

The renumbering half of `ADR-0243`'s description was right.

## What was verified before designing

Three candidate rules were probed against the accepted admissions rather than
reasoned about:

| Candidate | Result |
|---|---|
| Keep the 4×4 verbatim, renumber `imageAxes` to the two survivors | **admitted**, and a rank-2 `ImageDescriptor` accepts it |
| Zero the dropped column, as a "genuinely 2D" matrix would | **refused**: `singularTransform` |
| Permute columns when the dropped slot is not last | **admitted** for dropped slot 0 and slot 1 |

The second row is why the obvious approach is wrong: `AffineGridGeometry` requires
an upper-left 3×3 determinant of at least `Double.leastNormalMagnitude`, and a
zeroed column makes it exactly zero. **A two-dimensional geometry cannot be
expressed by emptying a column**, and discovering that by probing cost one test
where designing around it would have cost an increment.

The third row matters because it is the real case: matrix column `slot`
corresponds to image axis `imageAxes[slot]`, so dropping the axial plane's axis
drops the last slot, but coronal drops slot 1 and sagittal drops slot 0.

## Decision

1. **The dropped axis's column is moved to the third slot; the two survivors keep
   their relative order in slots 0 and 1.** The origin column is untouched.
2. **`imageAxes` is renumbered to the surviving image axes** in their post-squeeze
   numbering: an axis above the dropped one shifts down by one.
3. **The out-of-plane step is preserved rather than discarded.** Keeping the
   dropped column in the third slot means a 2D slice still knows its out-of-plane
   direction and spacing, which is truthful — a slice extracted from a volume does
   have one — and it is what keeps the matrix non-singular.
4. **No arithmetic is performed**, so the operation's registered numeric model is
   unchanged and no oracle accompanies this record. A column permutation changes a
   determinant's sign and not its magnitude, so the `ADR-0043` admission survives
   by construction.
5. **Only the singleton case is claimed**, which is all `SqueezeAxesOperation`
   admits. Dropping an axis with extent greater than one is not a squeeze and is not
   addressed here.
6. **A geometry-free input still produces a geometry-free output.** Nothing is
   invented for a volume that never had a geometry.
7. **`ADR-0243`'s pinned blocker test is updated, not deleted.** It asserted that
   squeeze refuses a geometry-bearing slab; that behaviour is now intentionally
   changed, so the test becomes an assertion of the new rule. Deleting it would
   discard the coverage it was written to hold.

## Alternatives considered

### Zero the dropped column

Rejected, and refuted: `singularTransform`. See the table.

### Drop the column entirely and shrink to a 3×3 or 3×4

Rejected. `AffineGridGeometry` holds a `Matrix4x4Double` and its admission reads
the upper-left 3×3; there is no smaller shape to produce.

### Replace the dropped column with the unit normal

Rejected. It would need a square root and a zero-magnitude threshold — two numeric
boundaries — to produce something the preserved column already provides without
either. `VOXELIA-ALG-0047` declined a square root for the same reason.

### Keep refusing, and give MPR a geometry-aware path of its own

Rejected. It would duplicate the squeeze operation for one caller, and the rule is
correct for every caller: dropping a singleton axis never moves the origin.

### Issue an algorithm specification anyway, for consistency of form

Rejected; see decision 4. Consistency of form is not worth a specification that
freezes nothing.

## Consequences

`MPRSliceCoordinator` can reconstruct a geometry-bearing volume, so
`VOX-VS1-009` becomes reachable, and with it the requirements downstream of a 2D
slice — window-level interaction, crosshairs, pixel inspection, distance
measurement and off-screen output.

Extracted slices now carry a spatial geometry where they previously could not
exist at all, so a consumer can ask where a slice is in patient space.

## Affected modules

`VoxeliaExecution`: `SqueezeAxesOperation` gains geometry handling in place of its
refusal. `VoxeliaImagingTests` updates the pinned blocker test.

## Compatibility impact

A squeeze that previously threw `unsupportedGeometry` now succeeds. No existing
call site relied on the refusal: the only caller is `MPRSliceCoordinator`, and its
tests use geometry-free volumes, which are unaffected by decision 6.

## Security impact

None. No new admission is relaxed; the accepted `ADR-0043` determinant check still
applies to the permuted matrix.

## Performance and memory impact

Sixteen element moves per squeeze. Nothing measurable beside the operation's full
read.

## Validation impact

```text
swift build && swift test
swift test --filter "SqueezeAxes|CTVolumeBridgeComposition"
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record and the operation change.
2. `VOX-VS1-009` verification: all three planes from the real 899-slice series.
3. Then the requirements downstream of a 2D slice.

## Supersession

This record supersedes nothing. It resolves `ADR-0243`'s blocker and **corrects
that record's claim** that the rule requires arithmetic, an algorithm
specification and an oracle.

## References

- [ADR-0043 - Spatial descriptor admission boundary](ADR-0043-spatial-descriptor-admission-boundary.md)
- [ADR-0116 - Singleton axis squeeze](ADR-0116-singleton-axis-squeeze.md)
- [ADR-0243 - Bridge arc conclusion](ADR-0243-bridge-arc-conclusion.md)
- [VOXELIA-ALG-0047 - CT series grouping and slice ordering](../../algorithms/VOXELIA-ALG-0047-series-grouping-and-ordering.md)
