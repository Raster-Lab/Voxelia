---
document_id: "VOXELIA-ALG-0067"
title: "Segment statistics binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Segment statistics binary64-v1

## Purpose

`VOX-SEG-009` — segmentation statistics computed from **authoritative** image
and segment data: the stored volume and the mask, never a presentation. The
model is `segment-statistics/binary64-v1`; `ADR-0363` records the design.

## The rule

Over an `ADR-0352`-domain image and an aligned `0`/`1` mask:

- **The mask count** is every sample the mask claims.
- **A sample contributes to intensity statistics** unless the declared
  padding sentinel excludes it **first**, or it is NaN — both excluded and
  **counted separately in the result**, visible as numbers rather than
  buried as warnings, because a statistic whose denominator quietly shrank
  is the dishonesty this row exists to prevent.
- **The sum folds left-to-right in canonical storage order** over exactly
  widened binary64 values — the frozen order, as everywhere in the arc —
  and the **mean** is that sum divided by the included count. **Minimum and
  maximum** are exact selections. All three are absent, not zero, when
  nothing contributed.
- **The physical volume composes the `VOXELIA-ALG-0019` rule**: the cell
  volume is the magnitude of the `VOXELIA-ALG-0016` determinant authority's
  value over the geometry's spatial part — the same authority
  `VoxelVolumeMeasurement` composes, reached directly since the layering
  runs the other way — and the physical volume is the **mask count** times
  the cell volume: padding excludes a voxel's *intensity*, not its claimed
  *extent*. Both are absent when the image declares no affine geometry.

## Determinism and failure classification

One pass; the only rounding is the frozen fold and the final division.
Failure cases are admission-only: `unsupportedLayerFormat`,
`shapeMismatch`, `invalidMaskValue`, `invalidPaddingValue`.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0363-segment-statistics-oracle.py`.

Values `100, 0, 300, NaN, 500, 250` under mask `1, 1, 1, 1, 1, 0` with
sentinel `0`: mask count `5`, included `3`, padded `1`, non-finite `1`,
sum `900`, mean `300`, minimum `100`, maximum `500`. Geometry
`diag(0.5, 0.25, 2)`: cell volume `0.25`, physical volume `1.25`.

## Validation obligations

The implementing increment must reproduce the fixture exactly on `float32`
input, verify the empty-inclusion case publishes absent statistics with the
counts still honest, verify the no-geometry case publishes absent volumes,
and verify the admission rejections typed.

## References

- [VOXELIA-ALG-0019 - Calibrated voxel volume](VOXELIA-ALG-0019-voxel-volume.md)
- [VOXELIA-ALG-0057 - Range threshold](VOXELIA-ALG-0057-range-threshold.md)
- [ADR-0363 - Segment statistics](../architecture/decisions/ADR-0363-segment-statistics.md)
