---
document_id: "VOXELIA-ALG-0071"
title: "Landmark rigid estimation binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Landmark rigid estimation binary64-v1

## Purpose

`VOX-REG-005` — the portfolio's landmark **rigid** member: the rigid
motion least-squares fitted to paired correspondences by Horn's
quaternion method, realised deterministically. The model is
`landmark-rigid/binary64-v1`; `ADR-0369` records the design.

## The rule

Over `N ≥ 3` moving/fixed correspondence pairs of finite points:

- **Centring is frozen**: per-coordinate sums fold in ascending landmark
  order and divide once by the count; centred points subtract the mean.
- **Exact collinearity refuses, on both sets**: taking the first
  non-zero centred point as `u`, if every centred point's cross product
  with `u` is exactly zero (or every centred point is zero), the set is
  degenerate — the rotation about the landmark line would be
  unconstrained. Exact zero, no epsilon; near-collinear sets are the
  caller's responsibility, exactly as pivot admission is elsewhere.
- **The cross-covariance and Horn matrix are frozen**: `S = Σ mᵢ fᵢᵀ`
  over centred points in ascending order; the symmetric 4×4 `N` builds
  from `S` with each element's expression fixed (trace fold
  `(S₀₀ + S₁₁) + S₂₂`, diagonal folds left-associative).
- **The eigensolver is cyclic Jacobi with exactly 30 sweeps**, pair
  order `(0,1),(0,2),(0,3),(1,2),(1,3),(2,3)`, the standard
  `theta`/`t`/`c`/`s` rotation with frozen expressions, skipping a pair
  only when its off-diagonal element is exactly zero. No convergence
  threshold exists — the sweep count is part of the model, which is what
  makes repeated estimation bit-identical.
- **Selection and canonicalisation**: the winning eigenvalue is the
  largest diagonal, ties to the lowest index; its eigenvector column
  `(w, x, y, z)` re-admits through `VOXELIA-ALG-0068` admission, so the
  stored quaternion is canonical.
- **The translation** is the fixed mean minus the `VOXELIA-ALG-0068`
  rotation of the moving mean, row folds frozen, negative zero
  normalised.

## Determinism and failure classification

Every expression order and the sweep count are fixed; repeated
estimation over the same admitted landmarks is bit-identical. Failure
cases are admission-only: mismatched counts, fewer than three pairs, or
an exactly degenerate (collinear or coincident) landmark set.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0369-landmark-rigid-oracle.py`.

- An exact permutation rotation plus translation `(1, 2, 3)` over a
  non-collinear integer set: the quaternion lands within one unit in the
  last place of `(0.5, 0.5, 0.5, 0.5)` — pinned exactly as
  `(0x1.0000000000001p-1, 0x1.ffffffffffffep-2, 0x1.0000000000001p-1,
  0x1p-1)` — and the translation is exactly `(1, 2, 3)`.
- Exactly collinear moving landmarks: degenerate, refused.
- An inconsistent fixed set: quaternion
  `(0x1.18ab5ea74e54ep-1, 0x1.c07327f978064p-2, 0x1.d26cad16a8adcp-2,
  0x1.188acbe01a483p-1)`, translation `(0x1.108c69592eec2p+0,
  0x1.fc9070a609b39p+0, 0x1.8464197ceb530p+1)`.

## Validation obligations

The implementing increment must reproduce all three fixtures bit-exactly
and verify the admission rejections typed.

## References

- [VOXELIA-ALG-0068 - Rigid motion](VOXELIA-ALG-0068-rigid-motion.md)
- [VOXELIA-ALG-0070 - Landmark affine estimation](VOXELIA-ALG-0070-landmark-affine.md)
- [ADR-0369 - Landmark rigid registration](../architecture/decisions/ADR-0369-landmark-rigid-registration.md)
