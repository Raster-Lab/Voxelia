---
document_id: "VOXELIA-ALG-0083"
title: "Welford merge binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Welford merge binary64-v1

## Purpose

`VOX-DST-008` — path-tracing accumulators mergeable without the
original sample ordering: Chan's parallel combination of
`VOXELIA-ALG-0080` states. The model is `welford-merge/binary64-v1`;
`ADR-0402` records the design and the declared ordering rule.

## The rule

Over two admitted states `(countA, meanA, m2A)` and
`(countB, meanB, m2B)`:

- `count = countA + countB` (exact integer);
- `delta = meanB − meanA`, one rounding;
- `mean = meanA + delta·(countB/count)` — the ratio one rounding, the
  product one, the sum one;
- `m2 = (m2A + m2B) + (delta·delta)·(countA·countB/count)` — each
  parenthesised term one rounding, left-associative.

## Determinism and the analysis half

The merge needs **no sample ordering** — it consumes states, not
samples — which is the row's demand. Two facts are recorded rather
than wished away: the merge is a **different frozen model** from
sequential accumulation (the conformance fixture shows a one-ulp `m2`
difference against the sequential fold over the same samples), and
merge-tree shape can round differently in general even though the
mathematics is symmetric. Therefore `ADR-0402` **declares the
reduction ordering** — partitions merge in ascending partition
identity, left-fold — which makes every distributed reduction
bit-reproducible under this specification. That declaration is
`VOX-DST-009`'s requirement doing its work.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0402-welford-merge-oracle.py`.

- `A = welford(1,2,3)`, `B = welford(10,20)`: `merge(A,B)` and
  `merge(B,A)` are both exactly `(5, 0x1.ccccccccccccdp+2,
  0x1.fd99999999999p+7)`; the sequential fold over the same five
  samples gives `m2 = 0x1.fd9999999999ap+7` — one ulp apart, pinned,
  not hidden.
- `C = welford(0.1, 0.7, 0.2)`, `D = welford(0.9, 0.4)`:
  `merge(C,D) = (5, 0x1.d70a3d70a3d72p-2, 0x1.ced916872b020p-2)`.

## Validation obligations

The implementing increment must reproduce every fixture bit-exactly,
witness both merge orders on the first fixture, and verify the
admission rejections typed.

## References

- [VOXELIA-ALG-0080 - Progressive variance](VOXELIA-ALG-0080-progressive-variance.md)
- [ADR-0402 - Distributed integrity](../architecture/decisions/ADR-0402-distributed-integrity.md)
