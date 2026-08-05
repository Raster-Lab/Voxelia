---
document_id: "VOXELIA-ALG-0010"
title: "Polyline length binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Polyline length binary64-v1

## Purpose

This specification defines the versioned reference operation
`polyline-length/binary64-v1` selected by accepted
[`ADR-0111`](../architecture/decisions/ADR-0111-interaction-command-vocabulary.md).
It evaluates the physical length of an ordered point sequence in one
coordinate space, for measurement construction.

## Model

For consecutive points `a` and `b` with binary64 components in one
coordinate space, the segment length is the frozen binary64 sequence:

```text
dx = b.x - a.x        (binary64 subtraction)
dy = b.y - a.y
dz = b.z - a.z
s  = ((dx * dx) + (dy * dy)) + (dz * dz)
length = sqrt(s)
```

evaluated in exactly this order with each operation correctly rounded
and no fused multiply-add, and the total length accumulates segment
lengths left to right with one correctly rounded addition per
segment. A single point has length exactly positive zero, and a
zero-length segment contributes exactly zero. The result carries the
coordinate space's length unit; unit conversion is outside this
model.

## Determinism and failure classification

The length is a pure function of the ordered points: repeated
evaluation is bit-identical. Point admission — non-empty, one shared
coordinate space — is the receiver's typed surface; no branch of the
model itself can fail for finite inputs, and point components are
finite by their own validation.

## Conformance fixtures

Independently computed:

- `(0, 0, 0)` to `(3, 4, 0)`: length exactly `5.0`.
- `(0, 0, 0)`, `(3, 4, 0)`, `(3, 4, 12)`: length exactly `17.0`.
- The single point `(10.5, -2.25, 7)`: length exactly `0.0`.

## References

- [ADR-0111 - Interaction command vocabulary](../architecture/decisions/ADR-0111-interaction-command-vocabulary.md)
- [VOXELIA-ALG-0001 - Ray axis-aligned bounds intersection binary64-v1](VOXELIA-ALG-0001-ray-axis-aligned-bounds-intersection.md)
