---
document_id: "VOXELIA-ALG-0006"
title: "Region origin shift binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-04"
owner: "Voxelia Project"
---

# Region origin shift binary64-v1

## Purpose

This specification defines the versioned reference operation
`region-origin-shift/binary64-v1` selected by accepted
[`ADR-0071`](../architecture/decisions/ADR-0071-geometry-preserving-region-extraction.md).
It computes the spatial-origin updates that keep an extracted region's
world positions and regular axis coordinates identical to the
positions the same samples had in the source image.

## Model

Let `lower` be the region's lower bounds. All arithmetic uses IEEE-754
binary64, every product and sum separately and correctly rounded in
the stated order; fused multiply-add is forbidden.

**Affine translation update.** For a source affine geometry with
row-major matrix elements `m`, mapped image axes `a[0..<k]`
(`1 <= k <= 3`) and spatial lower offsets
`l[s] = binary64(lower[a[s]])` (missing slots contribute nothing), each
translation element `r` in `0...2` updates as:

```text
t'[r] = m[4r + 3]
for s in 0..<k:            (ascending order)
    t'[r] = t'[r] + (m[4r + s] * l[s])
```

The rotation-scale block, the mapped axes, the coordinate space and
the bottom row are unchanged, so the determinant admission rule holds
by construction.

**Regular sampling update.** For an axis with regular sampling
`origin`, `spacing` and region lower bound `lower[axis]`:

```text
origin' = origin + (binary64(lower[axis]) * spacing)
```

Index-only sampling needs no update. Irregular, categorical and
externally defined samplings are not covered: slicing their payloads
is a different model.

## Determinism and failure classification

Both updates are pure binary64 functions of the source values and the
region bounds: repeated evaluation is bit-identical. Rebuilt
geometries and axes revalidate through their accepted constructing
initializers; no branch of the model itself can fail.

## Conformance fixtures

Hand-derived exact binary64 values (every product and sum exact):

- Matrix rows `[0, -2, 0, 10]`, `[2, 0, 0, 20]`, `[0, 0, 1, 30]`,
  `[0, 0, 0, 1]`, mapped axes `[0, 1]`, region lower bounds `[1, 0]`:
  the translation updates to `(10, 22, 30)` and every other element is
  unchanged.
- Regular sampling `origin = 5`, `spacing = 2.5`, lower bound `1`:
  `origin' = 7.5`. Lower bound `0` leaves any origin unchanged.

## References

- [ADR-0071 - Geometry-preserving region extraction](../architecture/decisions/ADR-0071-geometry-preserving-region-extraction.md)
- [ADR-0043 - Spatial descriptor admission boundary](../architecture/decisions/ADR-0043-spatial-descriptor-admission-boundary.md)
