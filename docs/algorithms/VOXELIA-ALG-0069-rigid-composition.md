---
document_id: "VOXELIA-ALG-0069"
title: "Rigid composition binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Rigid composition binary64-v1

## Purpose

`VOX-REG-004` — composing two rigid motions **without leaving the rigid
category**: matrix composition would surrender the by-construction
rigidity `VOXELIA-ALG-0068` bought. The model is
`rigid-composition/binary64-v1`; `ADR-0367` records the design.

## The rule

Over two canonical `VOXELIA-ALG-0068` motions, `outer` applied after
`inner`:

- **The quaternion is the Hamilton product** `outer ⊗ inner`, each
  component a frozen left-associative fold of four products:
  `w = ((w₁·w₂ − x₁·x₂) − y₁·y₂) − z₁·z₂`,
  `x = ((w₁·x₂ + x₁·w₂) + y₁·z₂) − z₁·y₂`,
  `y = ((w₁·y₂ − x₁·z₂) + y₁·w₂) + z₁·x₂`,
  `z = ((w₁·z₂ + x₁·y₂) − y₁·x₂) + z₁·w₂`, no fused multiply-add.
- **The product re-admits through `VOXELIA-ALG-0068` admission** —
  normalisation, canonical sign, zero normalisation — so rounding drift
  in the product's norm is corrected at the door and the stored form
  stays canonical.
- **The translation** is the outer rotation applied to the inner
  translation plus the outer translation, each row the frozen fold
  `((r₀·t₀ + r₁·t₁) + r₂·t₂) + s`, over the `VOXELIA-ALG-0068` rotation
  of the outer's canonical quaternion, negative zero normalised.

## Determinism and failure classification

Every expression order is fixed; repeated composition of the same
admitted operands is bit-identical. No failure cases exist beyond
`VOXELIA-ALG-0068` admission of the re-admitted product — two admitted
unit quaternions cannot produce a zero product.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0367-rigid-composition-oracle.py`.

- Permutation outer `(0.5, 0.5, 0.5, 0.5)` with translation
  `(10, 20, 30)` after identity-rotation inner with translation
  `(1, 2, 3)`: quaternion unchanged, translation exactly `(13, 21, 32)`.
- The permutation composed with itself: the Hamilton product lands at
  `(−0.5, 0.5, 0.5, 0.5)` and the canonical sign flips it to
  `(0.5, −0.5, −0.5, −0.5)`; zero translations stay exactly zero.
- Irrational operands `(2, 1, 0, 0)` after `(1, 1, 1, 1)` with
  translations `(1, 0, 0)` and `(0, 1, 0)`: quaternion
  `(0x1.c9f25c5bfedd9p-3, 0x1.5775c544ff263p-1, 0x1.c9f25c5bfedd9p-3,
  0x1.5775c544ff263p-1)`, translation `(1, 0x1.3333333333334p-1,
  0x1.9999999999999p-1)`.

## Validation obligations

The implementing increment must reproduce all three fixtures bit-exactly
and verify that composition of admitted operands never leaves the
canonical stored form.

## References

- [VOXELIA-ALG-0068 - Rigid motion](VOXELIA-ALG-0068-rigid-motion.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](VOXELIA-ALG-0052-affine-composition-and-directions.md)
- [ADR-0367 - Registration transform composition](../architecture/decisions/ADR-0367-registration-transform-composition.md)
