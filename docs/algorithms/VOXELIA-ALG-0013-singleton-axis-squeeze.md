---
document_id: "VOXELIA-ALG-0013"
title: "Singleton axis squeeze exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Singleton axis squeeze exact-v1

## Purpose

This specification defines the versioned reference operation
`singleton-axis-squeeze/exact-v1` selected by accepted
[`ADR-0116`](../architecture/decisions/ADR-0116-singleton-axis-squeeze.md).
It removes declared extent-one axes so a one-thick slab presents at
its natural rank — the step that turns an extracted multiplanar slab
into a rank-two slice.

## Model

The declared axes — each with extent exactly one — are removed from
the shape and axis list, preserving the order of the remaining axes.
In the canonical packed axis-zero-fastest layout an extent-one axis
contributes no sample reordering, so the output sample bytes are the
input sample bytes exactly, in the same order: the model is a
descriptor-level rank change over a byte-identical payload, with no
arithmetic of any kind.

## Determinism and failure classification

The squeeze is a pure function of the declared axes: repeated
evaluation is bit-identical. Axis admission — valid indices, extent
one, no duplicates, non-empty selection, at least one remaining
axis — is the receiver's typed surface; no branch of the model
itself can fail.

## Conformance fixtures

Independently verifiable by layout inspection:

- Extents `[2, 3, 1]`, dropping axis 2: extents `[2, 3]`, the six
  sample bytes unchanged in order.
- Extents `[1, 4]`, dropping axis 0: extents `[4]`, the four sample
  bytes unchanged in order.

## References

- [ADR-0116 - Singleton axis squeeze](../architecture/decisions/ADR-0116-singleton-axis-squeeze.md)
- [VOXELIA-ALG-0012 - Axis transposition exact-v1](VOXELIA-ALG-0012-axis-transposition.md)
