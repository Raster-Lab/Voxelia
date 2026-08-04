---
document_id: "VOXELIA-ALG-0003"
title: "Linear stored-to-real value mapping binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-04"
owner: "Voxelia Project"
---

# Linear stored-to-real value mapping binary64-v1

## Purpose

This specification defines the versioned reference operation
`linear-value-transform/binary64-v1` selected by accepted
[`ADR-0066`](../architecture/decisions/ADR-0066-transform-composition.md).
It evaluates a validated linear value transform, mapping one stored
scalar sample value to its real value — the DICOM-derived modality
rescale — and defines how the result composes with downstream
value-domain models such as the `VOXELIA-ALG-0002` window.

## Supported formats

Every stored sample type admitted by the consuming operation whose
values convert to IEEE-754 binary64 exactly. All arithmetic uses
binary64 (`Double`). The transform's finite `scale` and `offset` come
from the accepted `LinearValueTransformDescriptor`.

## Model and evaluation order

For each stored sample value `x` converted exactly to binary64:

```text
r = (x * scale) + offset
```

evaluated as one correctly rounded binary64 multiplication followed by
one correctly rounded binary64 addition, in exactly this association.
A fused multiply-add must not be substituted: it produces one rounding
where this model requires two, and the model, not the platform, is
normative.

## Composition rule

A value-domain model consuming real values — the `VOXELIA-ALG-0002`
window — receives `r` in place of the stored value, with its own model
otherwise unchanged. Its parameters are then expressed in the real
value domain. An absent transform and the identity transform both make
the real domain equal to the stored domain, and composing this mapping
with `scale = 1`, `offset = 0` is bit-identical to no mapping.

## Determinism and failure classification

The mapping is a pure function of the stored value, `scale` and
`offset`: repeated evaluation is bit-identical on every conforming
IEEE-754 binary64 implementation. The descriptor guarantees finite
coefficients before evaluation; no branch of the model itself can
fail. Overflow to infinity is impossible for the admitted 8- and
16-bit stored domains under finite coefficients.

## Conformance fixtures

Independently computed with binary64 arithmetic, composed with the
`VOXELIA-ALG-0002` window model:

- `int16` stored samples
  `[0, 824, 924, 1024, 1044, 1064, 1084, 1104, 1144, 1224, 2024, 4024]`
  under `scale = 1`, `offset = -1024` (the CT rescale), windowed with
  `c = 40`, `w = 400` in the real domain:
  `[0, 0, 38, 102, 115, 128, 141, 153, 179, 230, 255, 255]` — exactly
  the `VOXELIA-ALG-0002` fixture over the equivalent real values.
- `uint8` stored samples `0...11` under `scale = 0.5`,
  `offset = -2`, windowed with `c = 1`, `w = 4`:
  `[0, 0, 0, 43, 85, 128, 170, 212, 255, 255, 255, 255]`.

## References

- [ADR-0066 - Transform composition](../architecture/decisions/ADR-0066-transform-composition.md)
- [VOXELIA-ALG-0002 - Window-level linear mapping binary64-v1](VOXELIA-ALG-0002-window-level-linear.md)
