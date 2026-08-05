---
document_id: "VOXELIA-ALG-0014"
title: "Three-point angle binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Three-point angle binary64-v1

## Purpose

This specification defines the versioned reference operation
`three-point-angle/binary64-v1` selected by accepted
[`ADR-0120`](../architecture/decisions/ADR-0120-angle-measurement.md).
It evaluates the angle at a vertex between the rays to two points in
one coordinate space, for measurement construction.

## Model

For points `A`, vertex `B` and `C` with binary64 components in one
coordinate space, the frozen binary64 sequence is:

```text
u  = A - B                       (componentwise subtraction)
v  = C - B
dot   = ((u.x * v.x) + (u.y * v.y)) + (u.z * v.z)
normU = sqrt(((u.x * u.x) + (u.y * u.y)) + (u.z * u.z))
normV = sqrt(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z))
cosine = clamp(dot / (normU * normV), -1, 1)
angle  = acos(cosine)
```

evaluated in exactly this order with each operation correctly rounded
and no fused multiply-add. The clamp is modelled: rounding can push
the quotient marginally outside the mathematical `[-1, 1]` interval,
and the clamp makes the boundary angles exact rather than undefined.
The result is in radians in `[0, pi]`; both rays must have non-zero
length, which the receiver's typed surface enforces before the model
runs.

## Determinism and failure classification

The angle is a pure function of the three points: repeated
evaluation is bit-identical. Point admission — one shared coordinate
space, non-degenerate rays — is the receiver's typed surface; the
model itself cannot fail for admitted inputs.

## Conformance fixtures

Independently computed:

- `(1, 0, 0)`, vertex `(0, 0, 0)`, `(0, 1, 0)`: exactly
  `1.5707963267948966` — the right angle.
- `(1, 0, 0)`, vertex `(0, 0, 0)`, `(-2, 0, 0)`: exactly
  `3.141592653589793` — collinear opposite rays.
- `(1, 0, 0)`, vertex `(0, 0, 0)`, `(1, 1, 0)`: exactly
  `0.7853981633974484`.
- `(3, 0, 0)`, vertex `(0, 0, 0)`, `(2, 0, 0)`: exactly `0.0` —
  collinear same-direction rays through the clamp.

## References

- [ADR-0120 - Angle measurement](../architecture/decisions/ADR-0120-angle-measurement.md)
- [VOXELIA-ALG-0010 - Polyline length binary64-v1](VOXELIA-ALG-0010-polyline-length.md)
