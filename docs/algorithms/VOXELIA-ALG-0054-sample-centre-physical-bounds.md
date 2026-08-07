---
document_id: "VOXELIA-ALG-0054"
title: "Sample-centre physical bounds binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Sample-centre physical bounds binary64-v1

## Purpose

`VOX-SPA-010` requires spatial bounds to be computable in index and physical
coordinates. The index half exists (`ImageRegion`); `ADR-0323` measured the physical
half as a type with no producer and froze the hazard the producer must avoid: under
rotation the transformed extreme index corners are not the extremes of the transformed
set, so the correct construction is the axis-aligned hull of **all eight** transformed
corners. `ADR-0338` decision 7 answered the modelling question `ADR-0323` raised: the
bounds enclose the outermost **sample centres**, matching DICOM, not the sample
extents.

This specification freezes that construction. It is the model
`sample-centre-bounds/binary64-v1`.

## Conventions inherited, not restated

`Matrix4x4Double` stores sixteen elements in row-major order (`elements[4r + c]`),
admits only finite elements and normalises negative zero to positive zero on
admission. `AffineGridGeometry` admits only an exact homogeneous bottom row and a
non-singular upper-left block, so neither property is re-checked here. Voxelia
multiplies homogeneous column vectors, so translation occupies indices `3`, `7` and
`11`. `Point3D` rejects non-finite components and canonicalises signed zero.

## Admission

Three per-slot sample counts `n0, n1, n2`, checked in slot order:

- `n_s < 1` is rejected as `nonPositiveSampleCount` naming the slot and count;
- `n_s > 2^53` (`9007199254740992`) is rejected as `sampleCountNotExactlyRepresentable`
  naming the slot and count.

The ceiling is what makes the corner coordinate exact: for admitted counts,
`Double(n_s - 1)` is the integer itself, never a rounded neighbour, so "the outermost
sample centre" is the value published rather than an approximation of it. The largest
admitted corner index is `9007199254740991.0`, exactly.

## Corner enumeration

Corner ordinal `c` runs from `0` to `7` in ascending order, **slot 0 varying
fastest**: bit `s` of `c` selects the continuous index of slot `s`,

```text
i_s(c) = 0.0                 when bit s of c is 0
i_s(c) = Double(n_s - 1)     when bit s of c is 1
```

A slot with one sample contributes the same coordinate to every corner, so degenerate
plane, line and point bounds fall out of the fold with no special case.

## The point rule

For world axis `r` in `0, 1, 2`, with `M` the geometry's `indexToWorld` elements:

```text
w_r(c) = (((M[4r+0] * i0(c) + M[4r+1] * i1(c)) + M[4r+2] * i2(c)) + M[4r+3])
```

Every sum is **left-associative in ascending index order**, there is **no fused
multiply-add**, and the translation term is added **last** — the same expression
shape `ADR-0138` froze for the world-to-index step and `VOXELIA-ALG-0052` froze for
composition, restated here because this is the index-to-world direction and no
accepted record publishes a point rule for it.

## Representability

Every `w_r(c)` must be finite. A non-finite value — a product overflowing, or an
accumulation overflowing, or infinities of opposite sign meeting — is rejected as
`cornerNotRepresentable` naming the **corner ordinal** and **world axis** of the
first failure, with corners visited in ascending ordinal order and axes checked in
ascending order within a corner. The attribution is the point: the failure belongs to
the corner computation, not to the bounds type that never saw the value.

## The hull fold

The minima and maxima start at corner `0`'s components and fold forward in ascending
ordinal order, minima updated before maxima within each corner:

```text
minimum_r = min(minimum_r, w_r(c))
maximum_r = max(maximum_r, w_r(c))
```

`min` and `max` on finite binary64 values are exact selections, so the fold order is
not observable in the result; it is frozen anyway so the computation is one sequence
rather than a family of equivalent ones. By construction `minimum_r <= maximum_r`, so
the bounds admission cannot fail, and after the finiteness check the point admission
cannot fail — the three typed rejections above are the complete failure family.

## A published component is never negative zero

A pre-translation accumulation can be `-0.0` (every product `-0.0`, for example).
The final addition is with a translation element, and `Matrix4x4Double` normalised
that element on admission, so it is never `-0.0`; IEEE 754 round-to-nearest addition
returns `-0.0` only when both addends are `-0.0`, and exact cancellation returns
`+0.0`. So the published components are never `-0.0`, and `Point3D`'s signed-zero
canonicalisation is provably inert here rather than load-bearing.

## Determinism and failure classification

Repeated evaluation of the same admitted inputs is bit-identical: expression order is
fixed, no fused multiply-add is permitted, and nothing depends on iteration order
beyond the frozen ordinals.

Failure cases, in full:

- `nonPositiveSampleCount` — a slot with fewer than one sample;
- `sampleCountNotExactlyRepresentable` — a slot count above `2^53`;
- `cornerNotRepresentable` — a non-finite transformed component, attributed to its
  corner ordinal and axis.

## Conformance fixtures

Independently computed under the frozen order by
`docs/progress/evidence/ADR-0339-sample-centre-bounds-oracle.py`. All values are
exact.

**1 — identity.** Counts `(3, 4, 5)`, identity transform: minimum `(0, 0, 0)`,
maximum `(2, 3, 4)` — the outermost sample centres themselves.

**2 — anisotropic spacing, non-zero origin.** Spacing `diag(0.5, 0.25, 2.0)`, origin
`(10.5, -20.25, 0.125)`, counts `(16, 8, 4)`: minimum `(10.5, -20.25, 0.125)`,
maximum `(18.0, -18.5, 6.125)`. Distinct spacings and a non-zero origin so a
transposed axis or dropped origin term cannot hide.

**3 — flipped axis.** Fixture 2 with z spacing `-2.0`: minimum
`(10.5, -20.25, -5.875)`, maximum `(18.0, -18.5, 0.125)`. The naive transformed
extreme-corner pair inverts on z; the fold does not.

**4 — exact rotation.** `x' = 1 - 0.25 j`, `y' = 2 + 0.5 i`, `z' = 3 + 2 k`, counts
`(3, 5, 2)`: minimum `(0, 2, 3)`, maximum `(1, 3, 5)`.

**5 — the `ADR-0323` hazard witness.** World x is `i - j`, identity elsewhere, no
translation, counts `(4, 3, 1)`: the hull's x span is exactly `[-2, 3]`, reached at
corners the two-corner shortcut never visits; transforming only the extreme index
corners gives `[0, 1]`, **registered here as the wrong answer** so the defect
`ADR-0323` predicted stays visible.

**6 — single sample.** Counts `(1, 1, 1)` under fixture 2's transform: minimum and
maximum both exactly the origin `(10.5, -20.25, 0.125)` — valid degenerate point
bounds.

**7 — admission attribution.** Counts `(4, 0, 4)` reject slot `1` count `0`; counts
`(-3, 4, 4)` reject slot `0` count `-3`; counts `(4, 4, 2^53 + 1)` reject slot `2`
count `9007199254740993`. The ceiling itself is admitted: `2^53` yields the exact
corner index `9007199254740991.0`.

**8 — product overflow.** `M[0] = 1e300`, counts `(2^53, 2, 2)`: rejected at corner
ordinal `1`, axis `0` — the first corner whose slot-0 index is large.

**9 — accumulation overflow.** `M[0] = M[1] = 1e308`, counts `(2, 2, 1)`: every
product is finite and the sum overflows at corner ordinal `3`, axis `0` — the first
corner combining both large terms.

## Validation obligations

The implementing increment must reproduce fixtures 1 through 9 exactly, must assert
fixture 5's hull against the registered two-corner wrong answer rather than merely
asserting the hull, must verify the rejection attributions (slot, count, ordinal,
axis) typed, and must confirm the single-sample case produces valid degenerate
bounds through the ordinary path rather than a special case.

## References

- [VOXELIA-ALG-0052 - Affine composition and directions](VOXELIA-ALG-0052-affine-composition-and-directions.md)
- [ADR-0138 - World to index mapping](../architecture/decisions/ADR-0138-world-to-index-mapping.md)
- [ADR-0323 - Spatial bounds half built](../architecture/decisions/ADR-0323-spatial-bounds-half-built.md)
- [ADR-0338 - The owner decision batch](../architecture/decisions/ADR-0338-the-owner-decision-batch.md)
