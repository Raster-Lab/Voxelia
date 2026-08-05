---
document_id: "VOXELIA-ALG-0024"
title: "Orthographic ray generation binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Orthographic ray generation binary64-v1

## Purpose

This specification defines the versioned reference model
`orthographic-ray-generation/binary64-v1` selected by accepted
[`ADR-0172`](../architecture/decisions/ADR-0172-volume-renderer-design.md)
— per-pixel rays from the accepted camera vocabulary's orthographic
projection. Everything this model feeds is presentation, never a
source of authoritative quantitative measurement, per the arc's
binding rule.

## Model

**Basis.** From the camera position `p`, target `t` and up vector
`u`, each operation correctly rounded, no fused multiply-add:

```text
forward = normalize(t - p)          (componentwise difference,
                                     ALG-0010 norm, one division
                                     per component)
right   = normalize(cross(forward, u))
trueUp  = cross(right, forward)     (not renormalised; orthonormal
                                     up to rounding by construction)
```

with the cross product in the accepted `VOXELIA-ALG-0018` frozen
form `((a.y * b.z) - (a.z * b.y), (a.z * b.x) - (a.x * b.z),
(a.x * b.y) - (a.y * b.x))`. A zero cross — the up parallel to the
view direction — is the receiver's typed rejection, as is a zero
view vector.

**Pixel grid.** For viewport `W` by `H` pixels and orthographic
plane height `h`:

```text
planeWidth = h * (W / H)
u_ij = (((i + 0.5) / W) - 0.5) * planeWidth
v_ij = (0.5 - ((j + 0.5) / H)) * h
```

so row zero is the top of the image — positive `trueUp` — and pixel
centres sample the plane. The per-pixel ray is:

```text
origin    = (p + (u_ij * right)) + (v_ij * trueUp)   (componentwise,
                                                      in this order)
direction = forward
```

## Determinism and failure classification

The rays are a pure function of the camera and viewport: repeated
evaluation is bit-identical. Degenerate-basis and projection
admission is the receiver's typed surface; no branch of the model
itself can fail for admitted inputs.

## Conformance fixtures

Independently computed, all values exact: camera position
`(1, 1, -5)`, target `(1, 1, 1)`, up `(0, 1, 0)`, plane height `4`,
viewport two by two. The basis is exactly `forward (0, 0, 1)`,
`right (-1, 0, 0)`, `trueUp (0, 1, 0)` up to signed zeros, and the
four pixel origins are exactly `(2, 2, -5)`, `(0, 2, -5)`,
`(2, 0, -5)` and `(0, 0, -5)` in row-major pixel order, every
direction `(0, 0, 1)`.

## Validation obligations

The implementing increment must reproduce the fixture exactly, prove
bit-identical repetition, and reject the typed admissions — a zero
view vector, an up parallel to the view direction, and the deferred
perspective projection — without coercion.

## References

- [ADR-0172 - Volume renderer design](../architecture/decisions/ADR-0172-volume-renderer-design.md)
- [VOXELIA-ALG-0010 - Polyline length binary64-v1](VOXELIA-ALG-0010-polyline-length.md)
- [VOXELIA-ALG-0018 - Planar polygon area binary64-v1](VOXELIA-ALG-0018-planar-polygon-area.md)
