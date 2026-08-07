---
document_id: "VOXELIA-ALG-0063"
title: "Squared Euclidean distance transform exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Squared Euclidean distance transform exact-v1

## Purpose

`VOX-IMG-014` — distance transforms (a "should" row, P1). The model is
`squared-euclidean-distance/exact-v1`; `ADR-0358` records the design.

## The three frozen answers

- **The metric is exact squared Euclidean distance in sample units.** Squared
  distances of integer offsets are integers, so the published values are
  **exact**; taking the square root would introduce the transform's only
  rounding, so the square root is the consumer's presentation step, never
  this operation's. Physical-unit and anisotropic-spacing variants are a
  recorded future widening (the weighted transform), not a silent scaling.
- **Distance is measured to the background**: background samples publish
  exactly zero; each foreground sample publishes the minimum squared offset
  to any background sample. The boundary-distance variant composes an
  erosion and is not a second rule here.
- **The output is `uint32` with `parametric` semantic**, the input geometry
  verbatim. With the per-axis extent ceiling of `16384`, the largest
  possible value is `3 x 16383^2`, far inside `uint32`.

## The method, and why it is exact

The separable Felzenszwalb-Huttenlocher lower-envelope method: initialise
`0` at background and **the far-parabola sentinel `1e15`** at foreground —
above any admissible squared distance, far below `2^53`, so integer
arithmetic near it stays exact — then transform each axis in ascending order
with the one-dimensional lower envelope of parabolas.

Exactness holds because every **published value** is computed as
`(x - v)^2 + f(v)` over integers within binary64's exact range; the
envelope's intersection divisions only decide **which** parabola wins at each
integer sample, and at a boundary where two parabolas tie, both evaluate to
the same integer — so a rounding in the boundary position cannot change any
published value. The independent oracle is deliberately **brute force** (the
minimum over all background samples), sharing no structure with the method.

A mask with **no background rejects typed** (`noBackground`): every distance
would be infinite, and a sentinel in the output would poison downstream
arithmetic while looking like data.

## Determinism and failure classification

Frozen pass order and integer evaluation; no warnings can arise. Failure
cases: `unsupportedLayerFormat` (including an extent above `16384`),
`invalidMaskValue`, `noBackground`.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0358-distance-transform-oracle.py`
by brute force; exact.

1. **The bar** `1, 1, 0, 1, 1, 1` → `4, 1, 0, 1, 4, 9`.
2. **A `5 x 5` plane, centre background**: the radial squared field, corner
   `8`.
3. **Two competing seeds** at opposite corners of `3 x 3` → centre `2`.
4. **A `3 x 3 x 3` corner seed** → far corner `12`.
5. **All background** → all zero; **no background** → the typed rejection.

## Validation obligations

The implementing increment must reproduce fixtures 1 through 4 exactly
against the brute-force values, verify the all-background and no-background
cases, and verify corrupt mask bytes and oversized extents reject typed.

## References

- [VOXELIA-ALG-0062 - Connected components](VOXELIA-ALG-0062-connected-components.md)
- [ADR-0358 - Squared Euclidean distance transform](../architecture/decisions/ADR-0358-squared-euclidean-distance.md)
