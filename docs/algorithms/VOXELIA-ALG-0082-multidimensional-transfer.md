---
document_id: "VOXELIA-ALG-0082"
title: "Multi-dimensional transfer function v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Multi-dimensional transfer function v1

## Purpose

`VOX-DVR-006` — transfer functions over more than intensity: a declared
two-dimensional table over intensity and gradient magnitude, optionally
held per material class. The model is `multidimensional-transfer/v1`;
`ADR-0395` records the design.

## The rule

Over a declared table of RGBA entries with declared bin counts (each at
least two) and finite ordered ranges per dimension:

- **The bin rule is the `VOXELIA-ALG-0072` metric's**: one width
  rounding per dimension, `floor((v − lower)/width)`, a value exactly
  at the upper bound joining the last bin, anything outside `0..<bins`
  refused typed — an out-of-range sample has no colour rather than a
  silently clamped one.
- **Lookup returns the stored entry verbatim** — the table is data,
  admitted once (finite entries, opacity in `[0, 1]`), never
  interpolated in v1: interpolation is a different model with its own
  rounding story, addable when a row demands it.
- **Material conditioning is one table per declared material class**,
  selected by exact index — the same declared-material vocabulary as
  `VOXELIA-ALG-0081`.

## Determinism and failure classification

Lookup is exact. Failure cases are admission-only: bin counts below
two, non-finite or unordered ranges, a table whose entry count is not
`intensityBins × gradientBins`, non-finite entries, opacity outside
`[0, 1]`, or an out-of-range sample at lookup.

## Conformance fixtures

Computed by
`docs/progress/evidence/ADR-0395-multidimensional-transfer-oracle.py`.
Over the two-by-two fixture table: `(10, 1)` selects entry `(0,0)`;
`(50, 4)` selects `(1,1)` (the exact top edge joins the last bin);
`(100, 0)` selects `(1,0)`; `(150, 0)` refuses.

## Validation obligations

The implementing increment must reproduce every fixture exactly and
verify the admission rejections typed.

## References

- [VOXELIA-ALG-0072 - Registration metrics](VOXELIA-ALG-0072-registration-metrics.md)
- [VOXELIA-ALG-0081 - Material separation](VOXELIA-ALG-0081-material-separation.md)
- [ADR-0395 - Multi-dimensional transfer functions](../architecture/decisions/ADR-0395-multidimensional-transfer-functions.md)
