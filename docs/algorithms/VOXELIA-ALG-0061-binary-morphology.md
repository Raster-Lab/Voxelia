---
document_id: "VOXELIA-ALG-0061"
title: "Binary morphology exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Binary morphology exact-v1

## Purpose

`VOX-IMG-012` — morphology foundations including erosion and dilation. Version
one is **binary morphology over mask images** (the `0`/`1` `uint8` `mask`
domain `VOXELIA-ALG-0057` produces), because the segmentation arc is the
consumer; greyscale min/max morphology is a future record. The model is
`binary-morphology/exact-v1` — no arithmetic exists to round. `ADR-0356`
records the design.

## The structuring element

Caller-supplied `0`/`1` bytes with odd per-axis extents (each at most `31`,
rank-matched), at least one `1`, the centre implied. Any other byte rejects
(`invalidStructuringElement`). The general element rather than presets: a box
and a cross are inputs, not vocabulary.

## The rules

For each output sample, over the element's `1` positions in ascending
lexicographic order (axis zero fastest):

- **Dilation**: output `1` exactly when **any** covered tap is `1`.
- **Erosion**: output `1` exactly when **all** covered taps are `1`.

**The explicit boundary decides what an out-of-image tap contributes**, and
the choice is the caller's, defaultless, reusing the `VOXELIA-ALG-0059`
vocabulary:

- **`replicate`**: the tap reads the clamped edge sample — a border-touching
  object extends beyond the image, so the all-ones mask is an erosion fixed
  point;
- **`zero`**: the tap is background — border-touching foreground **erodes**,
  the conservative reading for masks, and dilation is unaffected (background
  taps never satisfy *any*).

Input mask bytes other than `0`/`1` reject fail-closed (`invalidMaskValue`),
the `VOXELIA-ALG-0058` mask rule. The output is a mask image claiming the
input geometry verbatim. Erosion-dilation duality (erosion is complemented
dilation with the reflected element) is recorded as a property, not used as
an implementation shortcut.

## Determinism and failure classification

Pure boolean selection in frozen order; no warnings can arise. Failure cases
are admission-only: `unsupportedLayerFormat`, `invalidMaskValue`,
`invalidStructuringElement`.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0356-morphology-oracle.py`; exact.

1. **Dilate the impulse** `0, 0, 1, 0, 0` with the length-three element →
   `0, 1, 1, 1, 0` (either boundary).
2. **Erode the bar** `0, 1, 1, 1, 0` → `0, 0, 1, 0, 0`.
3. **The boundary witness**: the all-ones mask under the length-three
   element erodes to `1, 1, 1, 1, 1` under `replicate` and to
   `0, 1, 1, 1, 0` under `zero`.
4. **Dilate at the border under `zero`**: `1, 0, 0, 0, 0` →
   `1, 1, 0, 0, 0` — background taps never trigger *any*.
5. **The two-dimensional cross**: dilating a centre pixel yields the cross;
   eroding the all-ones plane leaves only the centre under `zero`.

## Validation obligations

The implementing increment must reproduce all five fixtures exactly, verify
fixture 3 on both boundaries, and verify the three admission rejections
typed — including a mask byte of `2` and an all-zero structuring element.

## References

- [VOXELIA-ALG-0057 - Range threshold](VOXELIA-ALG-0057-range-threshold.md)
- [VOXELIA-ALG-0059 - Explicit-boundary convolution](VOXELIA-ALG-0059-explicit-boundary-convolution.md)
- [ADR-0356 - Binary morphology](../architecture/decisions/ADR-0356-binary-morphology.md)
