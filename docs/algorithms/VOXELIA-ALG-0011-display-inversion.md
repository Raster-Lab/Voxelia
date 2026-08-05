---
document_id: "VOXELIA-ALG-0011"
title: "Display inversion exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Display inversion exact-v1

## Purpose

This specification defines the versioned reference operation
`display-inversion/exact-v1` selected by accepted
[`ADR-0112`](../architecture/decisions/ADR-0112-monochrome-presentation-polarity.md).
It inverts eight-bit display values for inverted presentation
polarity — the `MONOCHROME1` convention in which the minimum value
presents white.

## Model

For every eight-bit display sample `x`:

```text
y = 255 - x
```

evaluated exactly in unsigned eight-bit integer arithmetic — the
subtraction can neither overflow nor round, so the model has no
floating-point step and no approximation. The mapping is an
involution: applying it twice reproduces the input exactly.

## Determinism and failure classification

The inversion is a pure exact function of each sample: repeated
evaluation is bit-identical. Input admission is the receiver's typed
surface; no branch of the model itself can fail.

## Conformance fixtures

Independently computed:

- `[0, 1, 127, 128, 254, 255]` inverts to
  `[255, 254, 128, 127, 1, 0]`.
- The registered `VOXELIA-ALG-0002` uint8 fixture
  `[0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]` inverts to
  `[255, 255, 255, 219, 182, 146, 109, 73, 36, 0, 0, 0]`.
- Double inversion of any corpus reproduces it exactly.

## References

- [ADR-0112 - Monochrome presentation polarity](../architecture/decisions/ADR-0112-monochrome-presentation-polarity.md)
- [VOXELIA-ALG-0002 - Window-level linear binary64-v1](VOXELIA-ALG-0002-window-level-linear.md)
