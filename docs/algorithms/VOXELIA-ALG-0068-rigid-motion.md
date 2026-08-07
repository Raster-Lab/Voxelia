---
document_id: "VOXELIA-ALG-0068"
title: "Rigid motion binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Rigid motion binary64-v1

## Purpose

`VOX-REG-001` — the rigid transform category, distinct **by construction**: a
rigid motion is parameterised as a canonical unit quaternion plus a
translation, a parameterisation that cannot express shear or scale, so the
category needs no orthonormality tolerance. The model is
`rigid-motion/binary64-v1`; `ADR-0365` records the design.

## The rule

Over four finite binary64 components `w, x, y, z`, not all zero:

- **The squared norm folds left-to-right**: `((w·w + x·x) + y·y) + z·z`,
  each product rounded once, sums left-associative in component order. It
  must be positive and finite.
- **Normalisation** divides each component once by the IEEE-754 correctly
  rounded square root of the squared norm.
- **The canonical sign**: scanning `w, x, y, z` in order, if the first
  non-zero normalised component is negative, all four are negated — `q` and
  `−q` describe one rotation and the stored form is unique.
- **Negative zero is normalised to positive zero** in the canonical
  quaternion and the derived rotation, exactly as `Matrix4x4Double`
  admission does.
- **The rotation matrix** derives row-major with each element's expression
  frozen: diagonal `1 − 2·((a·a) + (b·b))`, off-diagonal `2·((a·b) ± (c·d))`
  with the standard quaternion element assignments and no fused
  multiply-add, so repeated derivation is bit-identical.
- **The homogeneous matrix** places the rotation in the upper-left block,
  the translation at row-major indices 3, 7 and 11, and the exact bottom
  row `0, 0, 0, 1`.

## Determinism and failure classification

Every expression order is fixed; the only rounding is the products, the
frozen folds, the square root and the divisions. Failure cases are
admission-only: a non-finite component or an all-zero quaternion is
refused typed.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0365-rigid-motion-oracle.py`.

- `(1, 1, 1, 1)`: canonical `(0.5, 0.5, 0.5, 0.5)`; the rotation is the
  exact cyclic permutation `[0,0,1, 1,0,0, 0,1,0]`.
- `(0, 0, 0, −2)`: normalisation and the sign flip yield canonical
  `(0, 0, 0, 1)`; the rotation is exactly `diag(−1, −1, 1)`.
- `(2, 1, 0, 0)`: canonical `(0x1.c9f25c5bfedd9p-1, 0x1.c9f25c5bfedd9p-2,
  0, 0)`; the rotation's non-trivial elements are `0x1.3333333333334p-1`
  and `±0x1.9999999999999p-1`.

## Validation obligations

The implementing increment must reproduce all three fixtures bit-exactly,
verify the canonical-sign uniqueness (`q` and `−q` admit to equal stored
forms), and verify the admission rejections typed.

## References

- [VOXELIA-ALG-0052 - Affine composition and directions](VOXELIA-ALG-0052-affine-composition-and-directions.md)
- [ADR-0365 - The registration transform categories](../architecture/decisions/ADR-0365-the-registration-transform-categories.md)
