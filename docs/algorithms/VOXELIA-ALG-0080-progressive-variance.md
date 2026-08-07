---
document_id: "VOXELIA-ALG-0080"
title: "Progressive variance binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Progressive variance binary64-v1

## Purpose

`VOX-PRR-011` — the progressive mode's convergence information: a
running mean and unbiased variance over accumulated samples, exposed
honestly. The model is `progressive-variance/binary64-v1`; `ADR-0391`
records the design.

## The rule

Welford's algorithm in frozen order, per accumulated binary64 value:

- `count += 1`; `delta = x − mean`; `mean = mean + delta/count`;
  `delta2 = x − mean`; `m2 = m2 + delta·delta2` — each expression one
  rounding, no reassociation.
- **The unbiased variance** is `m2/(count − 1)`, and it is **absent —
  never zero — below two samples**: a variance nobody measured is not
  reported as certainty.
- Accumulated values must be finite; a non-finite sample refuses typed
  rather than poisoning the running state.

## Determinism and failure classification

Every expression order is fixed; repeated accumulation of the same
sequence is bit-identical. The only failure case is a non-finite
sample.

## Conformance fixtures

Computed by
`docs/progress/evidence/ADR-0391-progressive-variance-oracle.py`.

- `(1, 2, 3, 4)`: mean exactly `2.5`, variance
  `0x1.aaaaaaaaaaaabp+0`.
- A single sample: mean exactly `0.5`, variance absent.
- `(0.1, 0.7, 0.2, 0.9, 0.4)`: mean `0x1.d70a3d70a3d71p-2`, variance
  `0x1.ced916872b020p-4`.

## Validation obligations

The implementing increment must reproduce every fixture bit-exactly,
verify the absent-variance case, and verify the admission rejection
typed.

## References

- [VOXELIA-ALG-0079 - Deterministic sample sequence](VOXELIA-ALG-0079-deterministic-sequence.md)
- [ADR-0391 - Progressive convergence exposure](../architecture/decisions/ADR-0391-progressive-convergence-exposure.md)
