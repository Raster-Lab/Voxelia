---
document_id: "VOXELIA-ALG-0073"
title: "Registration quality binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Registration quality binary64-v1

## Purpose

`VOX-REG-009` — landmark-residual quality of an admitted registration
transform, available to the host: per-landmark residual distances, their
root mean square and their maximum. The model is
`registration-quality/binary64-v1`; `ADR-0373` records the design.

## The rule

Over an admitted rigid or affine transform's homogeneous matrix and
`N ≥ 1` moving/fixed correspondence pairs:

- **Each moving point maps through the matrix** with the frozen row fold
  `((m₀·x + m₁·y) + m₂·z) + m₃`.
- **Each residual** is the Euclidean distance from the fixed point to
  the mapped point: differences, the frozen squared fold
  `(dx·dx + dy·dy) + dz·dz`, one correctly rounded square root; negative
  zero is normalised.
- **The root mean square** folds the squared distances in landmark
  order, divides once by the count and takes one square root.
- **The maximum** is an exact selection, first occurrence on ties.
- **Which landmarks measure quality is the caller's declaration** — the
  fitting set measures residual error, a held-out set measures target
  registration error, and the model does not pretend to know which it
  was given.

## Determinism and failure classification

Every expression order is fixed; repeated evaluation is bit-identical.
Failure cases are admission-only: mismatched counts, no landmarks, a
landmark outside its declared space, or a deformable transform — whose
evaluation does not exist yet and whose quality cannot be measured by a
matrix it does not have.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0373-registration-quality-oracle.py`.

- The exact affine `diag(2,3,4) + t(1,2,3)` over consistent pairs:
  every residual, the RMS and the maximum are exactly zero.
- The permutation rigid motion plus `t(1,2,3)` with perturbed fixed
  points: residuals exactly `(0, 0.5, 0.25)`, RMS
  `0x1.4a7e9cb8a3491p-2`, maximum exactly `0.5`.

## Validation obligations

The implementing increment must reproduce both fixtures bit-exactly and
verify the admission rejections typed.

## References

- [VOXELIA-ALG-0068 - Rigid motion](VOXELIA-ALG-0068-rigid-motion.md)
- [VOXELIA-ALG-0070 - Landmark affine estimation](VOXELIA-ALG-0070-landmark-affine.md)
- [ADR-0373 - Registration quality for the host](../architecture/decisions/ADR-0373-registration-quality-for-the-host.md)
