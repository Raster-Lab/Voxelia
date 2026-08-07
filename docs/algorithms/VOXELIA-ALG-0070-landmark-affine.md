---
document_id: "VOXELIA-ALG-0070"
title: "Landmark affine estimation binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Landmark affine estimation binary64-v1

## Purpose

`VOX-REG-005` — the portfolio's landmark entry, affine first: the affine
transform least-squares fitted to paired point correspondences. The model
is `landmark-affine/binary64-v1`; `ADR-0368` records the design.

## The rule

Over `N ≥ 4` moving/fixed correspondence pairs of finite points:

- **Normal-equation assembly is frozen**: with `P = (mₓ, m_y, m_z, 1)`,
  the symmetric matrix `M = Σ P Pᵀ` and the three right-hand columns
  `Σ P·f_c` accumulate in ascending landmark order, element order
  row-major, one rounding per accumulation step.
- **The augmented 4×7 system eliminates forward with partial pivoting**:
  at column `c` the pivot is the largest-magnitude candidate in rows
  `c..3`, ties to the lowest row index; a winning magnitude below
  `Double.leastNormalMagnitude` refuses as degenerate — the same
  no-epsilon rule `VOXELIA-ALG-0016` admitted. Row updates fold
  left-to-right; back substitution folds left-associative in ascending
  column order with one division per unknown.
- **The result is the affine matrix** whose rows are the three solved
  coordinate rows over the exact bottom row; negative zero is normalised.
- **Determinism, not interpolation, is the promise**: with consistent
  correspondences the frozen elimination recovers the transform up to
  its own recorded rounding (fixture A pins the exact bits); with
  inconsistent correspondences the result is the least-squares solution
  under the frozen order.

## Determinism and failure classification

Every expression order is fixed; repeated estimation over the same
admitted landmarks is bit-identical. Failure cases are admission-only:
mismatched counts, fewer than four pairs, or a degenerate (coplanar or
coincident) landmark set.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0368-landmark-affine-oracle.py`.

- Five consistent pairs under `diag(2,3,4) + t(1,2,3)`: rows `x` and `y`
  exact; row `z` carries the frozen elimination's rounding —
  `(−0x1p-51, −0x1.5555555555555p-52, 0x1.0000000000001p+2, 3)`.
- Four coplanar pairs (all `z = 0`): degenerate, refused.
- An inconsistent fifth point: row `x` is exactly
  `(1.1875, 0.1875, 0.1875, −0.25)`; rows `y` and `z` are exact
  identity rows.

## Validation obligations

The implementing increment must reproduce all three fixtures bit-exactly
and verify the admission rejections typed.

## References

- [VOXELIA-ALG-0016 - Affine inverse](VOXELIA-ALG-0016-affine-inverse.md)
- [VOXELIA-ALG-0069 - Rigid composition](VOXELIA-ALG-0069-rigid-composition.md)
- [ADR-0368 - Landmark affine registration](../architecture/decisions/ADR-0368-landmark-affine-registration.md)
