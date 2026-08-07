---
document_id: "VOXELIA-ALG-0058"
title: "Mask application and image arithmetic binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Mask application and image arithmetic binary64-v1

## Purpose

The second and third `VOX-IMG-010` foundations, over `ADR-0352`'s stored-value
domain (`uint8`, `int16`, `uint16`, `float32`; exact binary64 widening). The
models are `mask-apply/binary64-v1` and `image-arithmetic/binary64-v1`.
`ADR-0353` records the design.

## Mask application

Inputs: an image in the domain, and a mask of identical shape with `uint8`
storage and `mask` semantic whose samples are **exactly `0` or `1`** — any
other mask byte rejects (`invalidMaskValue`); a corrupted mask must never
silently threshold. The fill value is finite binary64 and must round-trip the
image's stored type **exactly** (`fillValueNotRepresentable` otherwise): a fill
that cannot be stored would be silently rewritten, and a written value must be
the declared one.

Per sample, in canonical order: mask `1` keeps the stored sample **verbatim**
(bytes, not a widen-narrow round trip); mask `0` writes the fill. The output
preserves the input's scalar type and semantic and claims its geometry
verbatim.

## Image arithmetic

Operators `add`, `subtract`, `multiply`; operands either two images of
identical shape **and identical stored type**, or an image and one finite
binary64 scalar. Both operands widen exactly; the operator applies in
binary64.

**Integer outputs round ties-to-even, then saturate, and every saturation is
counted**: results below or above the type range store the range edge, and a
non-zero count becomes the aggregated warning
`org.voxelia.warn.arithmetic-saturated` (`qualityAffecting`, absent at zero) —
saturation distorts data, so it must be visible in provenance, but rejecting a
whole volume for one hot sample would make the operation useless on real data.
Ties-to-even composes the `VOXELIA-ALG-0002` rounding convention.

**Float32 outputs round to nearest binary32 and store non-finite results
verbatim, counted**: an overflow to infinity or a NaN is representable and
stored, and a non-zero count becomes
`org.voxelia.warn.arithmetic-non-finite` (`qualityAffecting`, absent at
zero). Nothing is clamped: binary32 has its own vocabulary for these values
and substituting finite ones would fabricate data.

## Determinism and failure classification

Single passes in canonical order; the only rounding steps are the frozen
integer ties-to-even and the binary64-to-binary32 conversion. Failure cases
are admission-only: `unsupportedLayerFormat`, `shapeMismatch`,
`operandTypeMismatch`, `invalidMaskValue`, `fillValueNotRepresentable`,
`invalidScalarOperand`.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0353-mask-arithmetic-oracle.py`; all
exact.

1. **Mask apply, int16, fill `-1024`**: values `-500, 0, 40, 400, 3071, 100`
   under mask `1, 0, 1, 0, 1, 0` → `-500, -1024, 40, -1024, 3071, -1024`.
2. **int16 add saturates both ways**: `30000, -30000, 100, 0` plus
   `10000, -10000, 28, 0` → `32767, -32768, 128, 0`, saturated count `2`.
3. **uint8 multiply**: `20, 3, 0, 15` times `20, 4, 9, 17` →
   `255, 12, 0, 255`, saturated count `1` — `15 x 17` is exactly `255`,
   not a saturation.
4. **int16 scalar add `100.5`**: `10, 11, 32767, -5` →
   `110, 112, 32767, 96`, saturated count `1` — both tie directions round
   to even before the range check.
5. **float32 add producing infinity**: `3e38 + 3e38` → `+inf` stored
   verbatim, non-finite count `1`; the finite lanes are exact.

## Validation obligations

The implementing increment must reproduce all five fixtures exactly from the
oracle's byte encodings, verify both warnings appear with their counts and
are absent at zero, and verify every admission rejection typed — including a
mask byte of `2` and a fill of `0.5` on an integer image.

## References

- [VOXELIA-ALG-0002 - Window level linear](VOXELIA-ALG-0002-window-level-linear.md)
- [VOXELIA-ALG-0057 - Range threshold](VOXELIA-ALG-0057-range-threshold.md)
- [ADR-0353 - Mask application and image arithmetic](../architecture/decisions/ADR-0353-mask-application-and-arithmetic.md)
