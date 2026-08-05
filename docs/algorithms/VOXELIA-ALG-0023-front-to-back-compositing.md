---
document_id: "VOXELIA-ALG-0023"
title: "Front-to-back compositing binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Front-to-back compositing binary64-v1

## Purpose

This specification defines the versioned reference model
`front-to-back-compositing/binary64-v1` selected by accepted
[`ADR-0170`](../architecture/decisions/ADR-0170-compositing-design.md)
— conventional direct volume rendering's per-ray accumulation with
early termination, per `VOX-DVR-001/004`. Everything this model
produces is presentation, never a source of authoritative
quantitative measurement, per the arc's binding rule.

## Model

The input is one ray's ascending midpoint samples — each the
accepted `VOXELIA-ALG-0017` sample byte at the plan's index
position, reusing that model's rounding and support exactly — and
one accepted transfer table. The binary64 conversion the table
vocabulary deliberately left to this model is declared here: each
eight-bit component divides by `255.0`, one correctly rounded
division per component.

Accumulation starts at zero and proceeds front to back in exactly
this order per sample, each operation correctly rounded, no fused
multiply-add:

```text
alpha  = opacity / 255
weight = (1 - A) * alpha
R      = R + (weight * r)      (G and B likewise, r = red / 255)
A      = A + weight
```

**Early termination** is declared exactly: after updating `A`, the
ray stops when `A >= 255/256` — an exact dyadic threshold — and
remaining samples are never consumed. The empty ray composites to
exact zero everywhere.

**Opacity and interval.** The table opacity is the per-sample
opacity at the full-quality interval, declared as such: with exactly
one registered quality token there is exactly one interval per
volume, so an interval-correction exponent would always be one — an
untestable no-op parameter. The quality tokens that shorten or
lengthen intervals must bring the correction rule in their own
records.

**Output.** Each channel emits
`clamp(roundHalfToEven(value * 255), 0, 255)` in this order, alpha
included.

## Determinism and failure classification

The composite is a pure function of the sample sequence and table:
repeated evaluation is bit-identical. Admission belongs to the
consuming surfaces; no branch of the model itself can fail.

## Conformance fixtures

Independently computed over the ramp table whose entry components
all equal the index:

- Samples `(100, 200)`: both consumed, the frozen accumulations are
  exactly `R = 0.527700507346345` and `A = 0.8688965782391389`, and
  the output red and alpha bytes are `135` and `222`.
- Samples `(255, 17)`: the first sample's unit alpha terminates the
  ray after exactly one consumed sample and the output is
  `(255, 255)` — the seventeen is never consumed.
- Samples `(200, 200, 200)`: the accumulated alpha
  `0.9899661517817431` stays below the threshold, all three samples
  consume, and the output red and alpha bytes are `198` and `252`.
- The empty ray and the all-transparent ray output exact zero, the
  transparent ray consuming every sample.

## Validation obligations

The implementing increment must reproduce every fixture exactly
including the consumed-sample counts, prove bit-identical
repetition, and prove the termination threshold boundary — a ray
reaching exactly the threshold stops.

## References

- [ADR-0170 - Compositing design](../architecture/decisions/ADR-0170-compositing-design.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling binary64-v1](VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [VOXELIA-ALG-0022 - Volume ray sampling binary64-v1](VOXELIA-ALG-0022-ray-sampling.md)
