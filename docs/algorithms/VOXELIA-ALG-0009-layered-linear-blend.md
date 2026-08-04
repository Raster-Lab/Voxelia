---
document_id: "VOXELIA-ALG-0009"
title: "Layered linear blend binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Layered linear blend binary64-v1

## Purpose

This specification defines the versioned reference operation
`layered-linear-blend/binary64-v1` selected by accepted
[`ADR-0090`](../architecture/decisions/ADR-0090-layer-compositing-operation.md).
It composites an ordered list of greyscale eight-bit layers, each with
one opacity, into one greyscale eight-bit output.

## Model

Every layer `k` in declared order carries one finite binary64 opacity
`a_k` with `0 <= a_k <= 1`. For each element position, the
accumulator starts at exactly positive zero — the black background —
and every layer composites over it by the frozen binary64 sequence:

```text
t = 1 - a_k                (binary64 subtraction)
p = acc * t                (binary64 multiplication)
q = x_k * a_k              (binary64 multiplication)
acc = p + q                (binary64 addition)
```

evaluated in exactly this order with each operation correctly rounded
and no fused multiply-add — fusing changes the rounding count. `x_k`
is the layer's eight-bit sample value converted exactly to binary64.
The output value is `clamp(roundHalfToEven(acc), 0, 255)`; each step
is a convex combination so the clamp is modelled, reachable only
through rounding at the interval edges. A first layer with opacity
one reproduces its values exactly, because
`0 * 0 + x * 1` is exact in binary64.

## Determinism and failure classification

The blend is a pure function of the declared layer order, values and
opacities: repeated evaluation is bit-identical. Layer and opacity
admission is the receiver's typed surface; no branch of the model
itself can fail.

## Conformance fixtures

Independently computed over the `VOXELIA-ALG-0002` uint8 fixture
`[0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]` (centre 6,
width 8 over samples `0...11`) as the first layer, and the same
samples through centre 3 width 6 —
`[0, 51, 102, 153, 204, 255, 255, 255, 255, 255, 255, 255]` — as the
second layer:

- One layer, opacity `1.0`: the first layer's values exactly.
- Opacities `[1.0, 0.5]`:
  `[0, 26, 51, 94, 138, 182, 200, 218, 237, 255, 255, 255]`.
- Opacities `[0.75, 0.25]`:
  `[0, 13, 26, 58, 92, 125, 146, 166, 187, 207, 207, 207]`.

## References

- [ADR-0090 - Layer compositing operation](../architecture/decisions/ADR-0090-layer-compositing-operation.md)
- [VOXELIA-ALG-0002 - Window-level linear binary64-v1](VOXELIA-ALG-0002-window-level-linear.md)
