---
document_id: "VOXELIA-ALG-0018"
title: "Planar polygon area binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Planar polygon area binary64-v1

## Purpose

This specification defines the versioned reference model
`planar-polygon-area/binary64-v1` selected by accepted
[`ADR-0143`](../architecture/decisions/ADR-0143-area-volume-measurement-design.md)
— the area half of `VOX-SPA-014`, evaluated in the physical
coordinate space the vertices inhabit.

## Model

For ordered vertices `v0 … v(n-1)` with binary64 components in one
coordinate space, the frozen binary64 sequence anchors at the first
vertex and fans:

```text
r_i        = v_i - v0                     (componentwise, i = 1 … n-1)
cross(p,q) = ((p.y * q.z) - (p.z * q.y),
              (p.z * q.x) - (p.x * q.z),
              (p.x * q.y) - (p.y * q.x))
S          = sum of cross(r_i, r_(i+1)) for i = 1 … n-2,
             accumulated componentwise left to right
norm       = sqrt(((S.x * S.x) + (S.y * S.y)) + (S.z * S.z))
area       = 0.5 * norm
```

evaluated in exactly this order with each operation correctly
rounded and no fused multiply-add. The measured quantity is the
**vector-area magnitude** of the closed fan: for a planar simple
polygon this is exactly the enclosed area; for a non-planar or
self-intersecting cycle it is the magnitude of the algebraic vector
area, and the model declares that meaning rather than testing
planarity — an epsilon planarity test would be an arbitrary
threshold, and the declared quantity is well defined for every
admitted input. The first-vertex anchor removes the origin-distance
cancellation of the unanchored shoelace form. A degenerate cycle has
area exactly positive zero — a value, not an error. The result
carries the coordinate space's squared length unit; unit conversion
is outside this model.

## Determinism and failure classification

The area is a pure function of the ordered vertices: repeated
evaluation is bit-identical. Vertex-count and shared-space admission
is the receiver's typed surface; no branch of the model itself can
fail for admitted inputs. No error bound is claimed; the frozen
sequence is the definition, per the accepted `VOXELIA-ALG-0010`
precedent.

## Conformance fixtures

Independently computed under the frozen order:

- The right triangle `(0,0,0)`, `(2,0,0)`, `(0,2,0)`: exactly `2`.
- The off-origin square `(1,1,1)`, `(3,1,1)`, `(3,3,1)`, `(1,3,1)`:
  exactly `4`.
- The planar pentagon `(10,10,2)`, `(14,10,2)`, `(15,13,2)`,
  `(12,15,2)`, `(9,13,2)`: exactly `21`, cross-checked against the
  exact rational shoelace value.
- The non-planar quadrilateral `(0,0,0)`, `(2,0,0)`, `(2,2,2)`,
  `(0,2,0)`: the vector-area magnitude `2·√6`, frozen binary64
  spelling exactly `4.898979485566356`.
- The collinear cycle `(0,0,0)`, `(1,1,1)`, `(2,2,2)`: exactly `0`.

## Validation obligations

The implementing increment must reproduce all five fixtures, prove
bit-identical repetition, and reject fewer than three vertices and
mixed coordinate spaces typed.

## References

- [ADR-0143 - Area and volume measurement design](../architecture/decisions/ADR-0143-area-volume-measurement-design.md)
- [VOXELIA-ALG-0010 - Polyline length binary64-v1](VOXELIA-ALG-0010-polyline-length.md)
