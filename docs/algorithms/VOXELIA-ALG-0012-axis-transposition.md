---
document_id: "VOXELIA-ALG-0012"
title: "Axis transposition exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Axis transposition exact-v1

## Purpose

This specification defines the versioned reference operation
`axis-transposition/exact-v1` selected by accepted
[`ADR-0115`](../architecture/decisions/ADR-0115-axis-transposition-operation.md).
It reorders an image's axes under a declared permutation with
whole-sample byte copies — the value-neutral index remap that
axis-aligned multiplanar reconstruction composes with extraction.

## Model

For rank `n`, a declared axis order `p` — a permutation of
`0 ..< n` — defines output axis `i` as input axis `p[i]`, so the
output extents are `outExtents[i] = inExtents[p[i]]`. Both images use
the canonical packed axis-zero-fastest layout. For every output
linear position, in ascending order, the output multi-index
`(o[0], ..., o[n-1])` is decomposed with axis zero fastest; the
source multi-index is `s[p[i]] = o[i]` for every `i`; and the whole
sample at the source position — every byte of every component —
copies exactly. All index arithmetic is exact integer arithmetic; the
identity permutation reproduces the input bytes exactly, and applying
a permutation followed by its inverse is the identity.

## Determinism and failure classification

The remap is a pure function of the extents and the permutation:
repeated evaluation is bit-identical. Permutation and rank admission
are the receiver's typed surface; no branch of the model itself can
fail.

## Conformance fixtures

Independently computed for samples `0...` in canonical packed order:

- Extents `[2, 3]`, order `[1, 0]`: extents `[3, 2]`, samples
  `[0, 2, 4, 1, 3, 5]`.
- Extents `[2, 3, 2]`, order `[2, 0, 1]`: extents `[2, 2, 3]`,
  samples `[0, 6, 1, 7, 2, 8, 3, 9, 4, 10, 5, 11]`.
- Any extents, the identity order: the input samples exactly.

## References

- [ADR-0115 - Axis transposition operation](../architecture/decisions/ADR-0115-axis-transposition-operation.md)
- [VOXELIA-ALG-0008 - Nearest-neighbour resampling binary64-v1](VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
