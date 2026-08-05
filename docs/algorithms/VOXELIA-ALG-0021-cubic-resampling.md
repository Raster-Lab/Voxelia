---
document_id: "VOXELIA-ALG-0021"
title: "Cubic resampling binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Cubic resampling binary64-v1

## Purpose

This specification defines the versioned reference operation
`cubic-resampling/binary64-v1` selected by accepted
[`ADR-0163`](../architecture/decisions/ADR-0163-cubic-resampling-design.md)
— the `VOX-IMG-005` cubic interpolation with its documented kernel
and boundary behaviour.

## Model

The kernel is the Catmull-Rom form — the interpolating cubic whose
exact dyadic coefficients pass through the samples, so the identity
mapping reproduces input bytes exactly like every accepted resampler.
For fractional position `t` over the four taps bracketing the source
coordinate, the frozen binary64 weight evaluation is:

```text
t2 = t * t
t3 = t2 * t
w0 = ((-t3 + 2*t2) - t) * 0.5
w1 = ((3*t3 - 5*t2) + 2) * 0.5
w2 = ((-3*t3 + 4*t2) + t) * 0.5
w3 = (t3 - t2) * 0.5
```

in exactly this order with each operation correctly rounded and no
fused multiply-add. The source coordinate and taps follow the
accepted `VOXELIA-ALG-0015` convention extended to four taps:

```text
scale = nIn / nOut
s     = ((p + 0.5) * scale) - 0.5
i1f   = floor(s)
t     = s - i1f
taps  = clamp(i1f - 1 … i1f + 2, 0, nIn - 1)
```

with `t` from the unclamped floor, so border coordinates replicate
the border sample — the documented boundary behaviour is the
accepted clamped-tap convention, not a new rule. Each axis reduces
by ascending-tap left-to-right accumulation
`acc = acc + (w_k * v_k)`; the rank-two evaluation is separable with
the horizontal pass inside the vertical — four row reductions
combined by the vertical weights in ascending order. The output byte
is `clamp(roundHalfToEven(value), 0, 255)`: the Catmull-Rom weights
are negative outside the bracketing pair, so overshoot beyond the
sample range is real and the clamp is modelled, not defensive.
Identical dimensions give `t = 0` and weights `(0, 1, 0, 0)`, so the
identity mapping reproduces the input bytes exactly.

## Determinism and failure classification

The mapping is a pure function of the dimensions and values:
repeated evaluation is bit-identical. Dimension and format admission
is the receiver's typed surface; no branch of the model itself can
fail.

## Conformance fixtures

Independently computed for canonical packed axis-zero-fastest
samples:

- The ramp `[0, 64, 128, 192]` at 4 to 8:
  `[0, 12, 46, 80, 112, 146, 180, 196]`.
- The overshoot ray `[0, 255, 255, 0]` at 4 to 8:
  `[0, 52, 203, 255, 255, 203, 52, 0]` — the raw interior value is
  exactly `278.90625` before the clamp, proving the clamp is
  modelled; the undershoot mirror `[255, 0, 0, 255]` clamps at zero
  symmetrically.
- `[10, 20, 30, 40]` at 2-by-2 to 4-by-4:
  `[8, 11, 17, 19, 13, 16, 22, 25, 25, 28, 34, 37, 31, 33, 39, 42]`.
- Identical dimensions reproduce the input bytes exactly.

## Validation obligations

The implementing increment must reproduce all fixtures exactly,
prove the identity byte-for-byte, prove bit-identical repetition,
and reject the typed admissions of the accepted resampling surface.

## References

- [ADR-0163 - Cubic resampling design](../architecture/decisions/ADR-0163-cubic-resampling-design.md)
- [VOXELIA-ALG-0015 - Bilinear resampling binary64-v1](VOXELIA-ALG-0015-bilinear-resampling.md)
