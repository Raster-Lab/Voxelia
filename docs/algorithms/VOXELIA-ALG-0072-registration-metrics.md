---
document_id: "VOXELIA-ALG-0072"
title: "Registration metrics binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Registration metrics binary64-v1

## Purpose

`VOX-REG-007` — the metric architecture's two founding classes: mean
squares and histogram mutual information over aligned sample pairs. The
model is `registration-metrics/binary64-v1`; `ADR-0370` records the
design.

## The rule

Both metrics evaluate paired samples in ascending index order; a pair
with a non-finite member is **excluded and counted**, and a metric whose
contributing count is zero publishes an **absent** value, never zero.

- **Mean squares** (dissimilarity, lower is better): the frozen fold
  `total = total + d·d` with `d = moving − fixed`, one final division by
  the contributing count.
- **Mutual information** (similarity, higher is better): over a
  caller-declared bin count `B ≥ 2` and explicit finite ordered ranges
  for each side — defaultless, because an assumed range is a silent
  rescale. Bin width is `(upper − lower)/B` rounded once; the bin index
  is `floor((v − lower)/width)`; a value exactly at `lower + width·B`
  joins the last bin; any index outside `0..<B` is excluded and counted.
  The joint histogram accumulates in pair order; marginals sum in
  ascending order; the value folds row-major over non-empty cells as
  `value + p·log(p/(pᵢ·qⱼ))` with each probability one division and the
  platform libm natural logarithm — the same determinism contract as the
  `VOXELIA-ALG-0060` Gaussian's exponential.

## Determinism and failure classification

Every fold order is fixed; repeated evaluation over the same admitted
samples is bit-identical on the reference hardware. Failure cases are
admission-only: mismatched counts, empty inputs, a bin count below two,
or a non-finite or unordered range.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0370-registration-metrics-oracle.py`.

- Mean squares over `(0,1,2,3)` versus `(1,1,4,3)`: exactly `1.25`; a
  NaN pair excludes to contributing `2`, value exactly `0.5`.
- Mutual information, two bins on `[0, 16)`: perfect correlation gives
  exactly `log 2` (`0x1.62e42fefa39efp-1`); independence gives exactly
  `0`; an out-of-range sample excludes and counts while the rest still
  give `log 2`.

## Validation obligations

The implementing increment must reproduce every fixture bit-exactly,
verify the absent-value case, and verify the admission rejections typed.

## References

- [VOXELIA-ALG-0060 - Separable Gaussian](VOXELIA-ALG-0060-separable-gaussian.md)
- [VOXELIA-ALG-0071 - Landmark rigid estimation](VOXELIA-ALG-0071-landmark-rigid.md)
- [ADR-0370 - The registration metric architecture](../architecture/decisions/ADR-0370-the-registration-metric-architecture.md)
