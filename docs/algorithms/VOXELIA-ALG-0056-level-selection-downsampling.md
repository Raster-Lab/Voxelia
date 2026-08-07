---
document_id: "VOXELIA-ALG-0056"
title: "Level selection downsampling binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Level selection downsampling binary64-v1

## Purpose

`VOX-BRK-009` requires interactive rendering to be able to use a lower-resolution
level, and `VOX-DVR-013` requires interactive quality to refine towards requested
diagnostic quality. Neither can exist until a lower-resolution level *is*
something, and `BrickResolutionLevel` is vocabulary with no generator. This
specification freezes how a level's samples and geometry derive from level zero.
`ADR-0343` opens the arc and records why selection was chosen over averaging.

It is the model `level-select/binary64-v1`.

## Selection

For per-axis integer factors `f_a >= 1`, the level extents are

```text
n_a = (e_a + f_a - 1) / f_a        (integer division; ceil(e_a / f_a))
```

and level sample `(j0, j1, j2)` **selects the level-zero stored value at index
`(j0*f0, j1*f1, j2*f2)`**, iterated in canonical lower-axis-fastest order. The
selected index is always inside the volume: `(n_a - 1) * f_a <= e_a - 1` by the
ceiling arithmetic. A factor at or above an axis extent collapses that axis to
one sample — index zero — through the same rule, no special case.

**Every level sample is a verbatim level-zero stored value.** No averaging, no
interpolation, no synthesised intensity anywhere: the level is a subset of the
study's own samples, which is what lets an interactive path show it without a
value-fabrication caveat. The trade — aliasing under decimation instead of
smoothing — is recorded in `ADR-0343` as the deliberate choice.

## Geometry

The level's `indexToWorld` scales the three index-step columns by the factors
and carries translation and the bottom row verbatim:

```text
scaled[4r + c] = m[4r + c] * Double(f_c)     for r, c in 0..2
scaled[4r + 3] = m[4r + 3]
```

one multiplication per element, no other arithmetic. Under this geometry, level
sample `(j0, j1, j2)`'s centre is the world position of level-zero index
`(j0*f0, j1*f1, j2*f2)` — the selected sample's own centre. For power-of-two
factors the scaled-matrix route and the scaled-index route agree **bit-exactly**
(a finite element times a power of two is exact; witnessed in the oracle); for
other factors the scaled matrix is the authoritative geometry and the
equivalence is exact in exact arithmetic only.

## Determinism and failure classification

Selection is integer indexing in a frozen order; the geometry scaling is one
frozen multiplication per element. Repeated evaluation is bit-identical.

Failure cases are admission-only, in the operation's family:
`unsupportedLayerFormat`, `volumeNotSpatiallyCalibrated`,
`unsupportedVolumeMapping`, `invalidDownsamplingLevel`. There is no
representability failure: selected bytes are copies, and the scaled matrix's
elements are products of admitted finite values with bounded integer factors,
checked by the geometry admission they feed.

## Conformance fixtures

Independently computed by `docs/progress/evidence/ADR-0343-level-select-oracle.py`
over the volume `(5, 4, 3)` with stored value `i0 + 5*i1 + 20*i2`.

**1 — factors `(2, 2, 2)`.** Extents `(3, 2, 2)`; bytes
`0, 2, 4, 10, 12, 14, 40, 42, 44, 50, 52, 54`.

**2 — mixed factors `(1, 2, 1)`.** Extents `(5, 2, 3)`; every second row of the
volume, thirty bytes, first ten `0..4, 10..14`.

**3 — factors `(4, 4, 4)`.** Extents `(2, 1, 1)`; bytes `0, 4` — two axes
collapse through the ordinary rule.

**4 — factors `(8, 8, 8)`, above every extent.** Extents `(1, 1, 1)`; the single
byte `0`.

**5 — geometry.** `diag(0.5, 0.25, 2.0)` with translation
`(10.5, -20.25, 0.125)` under factors `(2, 2, 2)` scales to
`diag(1.0, 0.5, 4.0)` with the translation verbatim.

**6 — power-of-two equivalence.** Under a rotation-bearing matrix and factors
`(2, 2, 2)`, transforming level indices through the scaled matrix equals
transforming doubled indices through the original, bit-exactly, at two witness
points.

## Validation obligations

The implementing increment must reproduce fixtures 1 through 5 exactly, must
verify the collapsed-axis cases through the ordinary path, must verify the output
claims the scaled geometry, and must verify admission rejections typed.

## References

- [VOXELIA-ALG-0050 - Volume sample layout](VOXELIA-ALG-0050-volume-sample-layout.md)
- [ADR-0343 - Open the progressive refinement arc](../architecture/decisions/ADR-0343-open-the-progressive-refinement-arc.md)
- [ADR-0338 - The owner decision batch](../architecture/decisions/ADR-0338-the-owner-decision-batch.md)
