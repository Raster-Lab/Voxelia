---
document_id: "VOXELIA-ALG-0015"
title: "Bilinear resampling binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Bilinear resampling binary64-v1

## Purpose

This specification defines the versioned reference operation
`bilinear-resampling/binary64-v1` selected by accepted
[`ADR-0123`](../architecture/decisions/ADR-0123-bilinear-resampling.md).
It resamples a rank-two eight-bit image under the linear
interpolation display policy of `VOX-R2D-013`.

## Model

For output position `p` on an axis with `nIn` source and `nOut`
output samples, the frozen binary64 source coordinate aligns pixel
centres:

```text
scale = nIn / nOut                    (binary64 division)
s     = ((p + 0.5) * scale) - 0.5     (binary64, in this order)
i0f   = floor(s)
t     = s - i0f
i0    = clamp(i0f, 0, nIn - 1)
i1    = clamp(i0f + 1, 0, nIn - 1)
```

with `t` computed from the unclamped floor so edge positions
replicate the border sample — both taps clamp to the same index and
the weight becomes irrelevant there. For output position `(x, y)`
with horizontal taps `i0, i1`, weight `tx` and vertical taps
`j0, j1`, weight `ty`, sample values convert exactly to binary64 and:

```text
vx0   = (v(i0, j0) * (1 - tx)) + (v(i1, j0) * tx)
vx1   = (v(i0, j1) * (1 - tx)) + (v(i1, j1) * tx)
value = (vx0 * (1 - ty)) + (vx1 * ty)
```

evaluated in exactly this order with each operation correctly rounded
and no fused multiply-add. The output is
`clamp(roundHalfToEven(value), 0, 255)`; each row is a convex
combination so the clamp is modelled. Identical dimensions give
`s = p` exactly and `t = 0`, so the identity mapping reproduces the
input bytes exactly.

## Determinism and failure classification

The mapping is a pure function of the dimensions and values: repeated
evaluation is bit-identical. Dimension and format admission is the
receiver's typed surface; no branch of the model itself can fail.

## Conformance fixtures

Independently computed for canonical packed axis-zero-fastest
samples:

- `[10, 20, 30, 40]` at 2-by-2 to 4-by-4:
  `[10, 12, 18, 20, 15, 18, 22, 25, 25, 28, 32, 35, 30, 32, 38, 40]`.
- Samples `0...11` at 4-by-3 to 2-by-3: `[0, 2, 4, 6, 8, 10]`.
- Samples `0...11` at 4-by-3 to 4-by-3: the input exactly.

## References

- [ADR-0123 - Bilinear resampling operation](../architecture/decisions/ADR-0123-bilinear-resampling.md)
- [VOXELIA-ALG-0008 - Nearest-neighbour resampling binary64-v1](VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
