---
document_id: "VOXELIA-ALG-0008"
title: "Nearest-neighbour resampling binary64-v1"
version: "1.1"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Nearest-neighbour resampling binary64-v1

## Purpose

This specification defines the versioned reference operation
`nearest-neighbour-resampling/binary64-v1` selected by accepted
[`ADR-0088`](../architecture/decisions/ADR-0088-nearest-neighbour-resampling.md).
It maps every output pixel of a rank-two resampled image to exactly
one source sample, whole-sample copies with no value arithmetic.

## Model

For output position `p` on an axis with `nIn` source and `nOut`
output samples, the source index is defined by the frozen binary64
computation — the computed result is the definition, and no exact
rational reference exists beside it:

```text
scale = nIn / nOut                    (binary64 division)
position = (p + 0.5) * scale          (binary64 multiplication)
index = clamp(floor(position), 0, nIn - 1)
```

evaluated in exactly this order with each operation correctly
rounded; the half-sample offset is the pixel-centre convention. The
output sample at `(x, y)` is the whole source sample at the mapped
`(index(x), index(y))` — every byte of the sample copied exactly, so
the model is value-neutral and applies to every scalar format and
component count.

## Determinism and failure classification

The mapping is a pure function of the dimensions: repeated evaluation
is bit-identical, and identical dimensions produce the identity
mapping. Dimension admission is the receiver's typed surface; no
branch of the model itself can fail.

## Geometry and sampling rescale

Revision 1.1, selected by accepted
[`ADR-0126`](../architecture/decisions/ADR-0126-geometry-bearing-resampling.md),
adds the frozen rescale rules for regular sampling and affine
geometry so every resampled sample keeps its physical position under
the pixel-centre convention. With `scale = nIn / nOut` per axis and
the half-sample shift `h = ((0.5 * scale) - 0.5)`, each operation
correctly rounded in this order:

- A regular axis `(origin, spacing)` becomes
  `(origin + (h * spacing), scale * spacing)`.
- An affine geometry updates in two frozen passes over the spatial
  mapping slots in ascending order: first every translation component
  `t[r]` accumulates `m[4r + s] * h(axis(s))` using the original
  column values; then every spatial column `m[4r + s]` scales by
  `scale(axis(s))`.

Irregular and categorical payloads have no linear rescale and remain
outside the admitted domain.

### Rescale fixtures

Independently computed for 4-by-3 to 8-by-6 (both scales one half):

- Regular axis zero `(5, 2.5)` becomes `(4.375, 1.25)`.
- The affine matrix with rows `(0, -2, 0, 10)`, `(2, 0, 0, 20)`,
  `(0, 0, 1, 30)` over image axes `(0, 1)` becomes rows
  `(0, -1, 0, 10.5)`, `(1, 0, 0, 19.5)`, `(0, 0, 0.5, 30)` — with
  the third spatial column unscaled because no image axis maps to it,
  exactly: `(0, 0, 1, 30)`.

## Conformance fixtures

Independently computed for source samples `0...11` in a 4-by-3 image,
axis zero fastest:

- Upsampling to 8-by-6 duplicates every sample into a 2-by-2 block:
  `[0,0,1,1,2,2,3,3, 0,0,1,1,2,2,3,3, 4,4,5,5,6,6,7,7,
  4,4,5,5,6,6,7,7, 8,8,9,9,10,10,11,11, 8,8,9,9,10,10,11,11]`.
- Downsampling to 2-by-3 selects columns one and three:
  `[1, 3, 5, 7, 9, 11]`.

## References

- [ADR-0088 - Nearest-neighbour resampling operation](../architecture/decisions/ADR-0088-nearest-neighbour-resampling.md)
- [VOXELIA-ALG-0007 - Camera-relative float transform derivation binary32-v1](VOXELIA-ALG-0007-camera-relative-float-transform.md)
