---
document_id: "VOXELIA-ALG-0064"
title: "Nearest label resampling exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Nearest label resampling exact-v1

## Purpose

`VOX-SEG-005` — binary and multi-label resampling defaults to
nearest-neighbour unless explicitly overridden by a validated operation. The
model is `nearest-label-resample/exact-v1`; `ADR-0360` records the design and
how the default is made structural.

## The chain

The target is a rank-matched `AffineGridGeometry`, exactly as
`VOXELIA-ALG-0055` takes it, and the target forward evaluation and
`ADR-0138` inverse compose unchanged. What differs is the sampling:

- **The nearest index composes `VOXELIA-ALG-0026`'s rounding** —
  round-half-away-from-zero per axis of the continuous source coordinate.
- **The out-of-image handling is this resampler's own rule, deliberately not
  `VOXELIA-ALG-0026`'s clamp**: a rounded index outside `[0, extent - 1]` on
  any axis publishes **background zero**, counted into the aggregated
  `org.voxelia.warn.label-resample-padding` warning (absent at zero).
  `VOXELIA-ALG-0026` clamps because it samples *within* a declared support;
  a grid resampler that clamped would replicate edge labels into space the
  source never covered — fabricated anatomy, refused by name.

No interpolation exists anywhere in the chain: **every output value is an
input value or the background**, which is the entire point of the row.

## The structural default

Mask and label semantics are **refused by the intensity resampler**
(`GridResampleOperation` admits `intensity`/`parametric` only) and admitted
**only** here; an explicit interpolating override would be a future validated
operation with its own record. The default is therefore not a parameter that
could drift — it is the only door.

## Determinism and failure classification

Pure selection over the frozen forward order; repeated evaluation is
bit-identical. Failure cases are admission-only, mirroring the intensity
resampler where shared: `unsupportedLayerFormat` (`mask` `uint8` or `label`
`uint16` only), `unsupportedRequestMapping`, `coordinateSpaceMismatch`,
`invalidOutputExtent`, `outputBudgetExceeded`, `invalidMaskValue` (corrupt
mask bytes, fail-closed).

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0360-label-resample-oracle.py` over
labels `1..6` on `3 x 2` with identity source geometry; exact.

1. **Identity**: the labels verbatim, padded count `0`.
2. **Half-spacing upscale**: `1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 0` — ties
   round away from zero, and the final column's `2.5` rounds to `3`,
   outside, publishing background; padded count `2`.
3. **A shift past the edge** publishes background on the vacated column,
   padded count `2`.
4. **The `-0.5` tie rounds away from zero to `-1`**: outside, background —
   the tie behaviour witnessed at the boundary.

## Validation obligations

The implementing increment must reproduce all four fixtures exactly with
their padded counts on both `mask` and `label` inputs, verify the warning's
presence and absence, verify the admission rejections typed, and verify the
structural default: the intensity resampler refuses a mask input typed.

## References

- [VOXELIA-ALG-0026 - Segmentation mask sampling](VOXELIA-ALG-0026-segmentation-mask-sampling.md)
- [VOXELIA-ALG-0055 - Grid resampling](VOXELIA-ALG-0055-grid-resampling.md)
- [ADR-0360 - Nearest label resampling and the operation set](../architecture/decisions/ADR-0360-nearest-label-resampling.md)
