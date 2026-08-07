---
document_id: "VOXELIA-ALG-0075"
title: "Curved planar mapping binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Curved planar mapping binary64-v1

## Purpose

`VOX-MPR-013` — every curved-planar output position, parameterised as
arc length by lateral offset, maps back to source patient coordinates.
The model is `curved-planar-mapping/binary64-v1`; `ADR-0376` records
the design.

## The rule

Over an admitted `VOXELIA-ALG-0074` centreline and a caller-declared
reference direction in the same space — non-zero, and not exactly
parallel to any segment (exact cross-product zero refuses at
admission):

- **The segment** for arc length `s` is the `VOXELIA-ALG-0074` rule's
  segment; `s` equal to the total selects the last segment.
- **The tangent** is the segment difference divided by its stored
  length, one division per component.
- **The centre** is the `VOXELIA-ALG-0074` position — vertices and the
  far endpoint exact by rule.
- **The lateral direction is the normalised rejection** of the
  reference from the tangent: `dot = (r₀·t₀ + r₁·t₁) + r₂·t₂`,
  `w = r − dot·t` per component, one frozen norm, one division per
  component. This is the stretched-CPR convention: the lateral axis
  stays in the plane the reference and the path span.
- **The patient position** is `centre + u·lateral` per coordinate,
  negative zero normalised; the offset `u` must be finite.

## Determinism and failure classification

Every expression order is fixed; repeated evaluation is bit-identical.
Failure cases are admission-only: a reference in the wrong space, a
zero reference, a reference exactly parallel to any segment, an arc
length outside `[0, total]` (NaN included), or a non-finite offset.

## Conformance fixtures

Computed by
`docs/progress/evidence/ADR-0376-curved-planar-mapping-oracle.py`.

- The integer elbow with reference `(0,0,1)`: `(s=1.5, u=2)` maps to
  exactly `(1.5, 0, 2)`; `(s=5.5, u=−1)` to `(3, 2.5, −1)`; the far
  endpoint `(s=7, u=0.5)` to `(3, 4, 0.5)`.
- The diagonal with reference `(1,0,0)` at `(s=1, u=1)`: `x` is exactly
  `0x1.6a09e667f3bcdp+0` and `y` is the honest rounding residual
  `0x1p-53` — pinned, not rounded to a romantic zero.

## Validation obligations

The implementing increment must reproduce every fixture bit-exactly and
verify the admission rejections typed.

## References

- [VOXELIA-ALG-0074 - Curved centreline](VOXELIA-ALG-0074-curved-centreline.md)
- [ADR-0376 - Curved planar back-mapping](../architecture/decisions/ADR-0376-curved-planar-back-mapping.md)
