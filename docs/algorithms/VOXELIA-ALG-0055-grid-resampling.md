---
document_id: "VOXELIA-ALG-0055"
title: "Grid resampling binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Grid resampling binary64-v1

## Purpose

`VOX-IMG-008` requires image resampling between explicit source and target grids.
`ADR-0325` measured the capability unbuilt — the extents-based operations cannot
express a target grid — and named the two frozen boundaries the builder must settle:
the rule mapping a target sample to a source position, and the behaviour where the
target grid falls outside the source. `ADR-0338` decision 7 answered the second:
padding is exact zero, recorded in provenance. This specification freezes both.

It is the model `grid-resample/binary64-v1`.

## Conventions inherited, not restated

`Matrix4x4Double` element order, the `ADR-0138` world-to-index composition, and the
`VOXELIA-ALG-0017` sampling authority — support test, clamped unclamped-floor taps,
trilinear reduction over ascending volume axes, ties-to-even rounding to the display
domain, and exact zero outside the declared pixel-centre support — are composed
unchanged. `ADR-0174` makes that sampling authority the one public rule; this model
calls it and does not restate it.

## The target forward evaluation

For target sample `(j0, j1, j2)` and target matrix `M`, the world position per axis
`r` is

```text
w_r = ((M[4r+3] + M[4r+0] * j0) + M[4r+1] * j1) + M[4r+2] * j2
```

— **the `VOXELIA-ALG-0017` request order extended by the third slot term**:
translation first, then ascending slot terms, left-associative, no fused
multiply-add. The alternative (translation last, as `VOXELIA-ALG-0052` composes and
`VOXELIA-ALG-0054` bounds) was rejected **for consistency with the accepted
sampler's own request evaluation**: a depth-one target grid then produces exactly
the world positions an oblique-slice request with the same columns produces, so the
two operations can be cross-checked byte-for-byte rather than merely argued
equivalent. One frozen order per consumer family, and this operation is in the
sampler's family.

## The source position

The world point is converted through the source volume's `AffineWorldToIndexMap`
(`ADR-0138`), and slot values reorder to volume axes through the source's
`spatialAxes` mapping — both composed as accepted, contributing no new arithmetic.

## Sampling and padding

Each continuous source position is sampled by the `VOXELIA-ALG-0017` authority
exactly as the oblique slice samples it. Positions outside the declared support
produce **exact zero** — the padding value `ADR-0338` decision 7 selected, already
frozen inside the authority. Nothing about the sample depends on whether the
position was reached from a plane or a grid.

**The padded-sample count is an observable of the execution**: the number of target
samples whose continuous position fails the support test. When the count is at
least one, the operation's provenance record carries the aggregated warning
`org.voxelia.warn.grid-resample-padding`, schema version `1.0`, severity
`qualityAffecting` — padded samples are synthetic values, not measured data — with
the count as its occurrence count. A zero count carries **no entry at all**, per
the padding-entry precedent: an execution that padded nothing is byte-identical in
provenance to one that could not pad.

## Admission and ceilings

The source must be a rank-three, spatially calibrated volume in the sampler's
value domain, with slot-complete axis mapping. The target grid must be rank-three
(`imageAxes == [0, 1, 2]`) in the same coordinate space. Target extents are checked
per dimension against the inclusive sibling ceiling `16384`, and their product
against the inclusive total-sample ceiling `1073741824` (exactly `1024^3`, which
`16384 x 16384 x 4` meets exactly and `16384 x 16384 x 5` exceeds). Ceiling
violations are typed rejections, checked extents-first so a caller can attribute
the failure.

## Determinism and failure classification

Repeated evaluation of the same admitted inputs is bit-identical: the forward order
is frozen above, and everything downstream is the already-deterministic accepted
chain. Iteration is target row-major (slot 0 fastest), observable only through the
output byte order, which `LogicalSampleBinding`'s canonical layout fixes anyway.

Failure cases are admission-only: `unsupportedLayerFormat`,
`volumeNotSpatiallyCalibrated`, `unsupportedVolumeMapping`,
`unsupportedRequestMapping`, `coordinateSpaceMismatch`, `invalidOutputExtent`,
`outputBudgetExceeded`. After admission the chain is total: the forward evaluation
of finite matrices over exact small integers, the accepted inverse of an admitted
geometry, and a sampler that pads rather than fails. `Point3D` finiteness at the
world step surfaces the accepted spatial error unchanged for the overflow case the
ceilings make unreachable in practice.

## Conformance fixtures

Independently computed by `docs/progress/evidence/ADR-0340-grid-resample-oracle.py`
over the oblique specification volume — extents `(3, 3, 3)`, stored value
`2*i0 + 6*i1 + 18*i2`, identity geometry, so the source inverse contributes
exactly and every fixture value is exact.

**1 — identity.** Identity target grid, extents `(3, 3, 3)`: the output bytes equal
the source bytes; padded count `0`.

**2 — coarser grid.** Spacing `2`, origin `(0.5, 0.5, 0.5)`, extents `(2, 2, 2)`:
bytes `13, 16, 22, 25, 40, 43, 49, 52`; padded count `0`. The upper target centres
sit exactly on the inclusive support edge `2.5` and replicate the border through
the clamped taps — `16`, not the naive extrapolation `17`.

**3 — axis exchange.** The x/z-swapping target over `(3, 3, 3)`: the transposed
volume, first row `0, 18, 36`; padded count `0`. The distinct ramp coefficients
make a transposed axis visible.

**4 — padding with attribution.** Extents `(3, 1, 1)`, x origin `-1.25` at
`y = z = 1`: bytes `0, 24, 26`; padded count `1`. The first sample is outside the
support and pads exact zero; the second replicates the lower border; the third
rounds `25.5` to `26` under ties-to-even.

**5 — the support edge.** A single sample at x exactly `2.5` is inside: byte `28`,
padded count `0`. At `2.5000000000000004` it is outside: byte `0`, padded count
`1`.

**6 — ties resolve to even in both directions.** Extents `(2, 1, 1)`, x spacing
`0.5`, origin `0.25`: bytes `0, 2` — `0.5` rounds down to `0` and `1.5` rounds up
to `2`.

## Validation obligations

The implementing increment must reproduce fixtures 1 through 6 exactly with their
padded counts; must verify the provenance warning appears with occurrence count
`1` for fixture 4 and is **absent** for fixture 1; must verify every admission
rejection typed, including both ceiling cases at their exact boundaries; and must
show a depth-one grid resample byte-identical to `ObliqueSliceOperation` under a
shared rotated request, since that equivalence is the reason the forward order was
chosen.

## References

- [VOXELIA-ALG-0017 - Oblique slice sampling](VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](VOXELIA-ALG-0052-affine-composition-and-directions.md)
- [VOXELIA-ALG-0054 - Sample-centre physical bounds](VOXELIA-ALG-0054-sample-centre-physical-bounds.md)
- [ADR-0138 - World to index mapping](../architecture/decisions/ADR-0138-world-to-index-mapping.md)
- [ADR-0325 - Grid resampling is unbuilt](../architecture/decisions/ADR-0325-grid-resampling-is-unbuilt.md)
- [ADR-0338 - The owner decision batch](../architecture/decisions/ADR-0338-the-owner-decision-batch.md)
