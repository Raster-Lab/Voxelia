---
document_id: "VOXELIA-ALG-0005"
title: "Composed value-transform chain binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-04"
owner: "Voxelia Project"
---

# Composed value-transform chain binary64-v1

## Purpose

This specification defines the versioned reference operation
`composed-value-transform-chain/binary64-v1` selected by accepted
[`ADR-0070`](../architecture/decisions/ADR-0070-composed-chain-composition.md).
It evaluates a validated composed value-transform chain from one
stored integer sample value to its real value by sequential
application of already-registered stage models.

## Model

The chain's stages are evaluated in declared first-to-last order over
binary64 values. Identity stages are exact no-ops. A linear stage
applies the `VOXELIA-ALG-0003` model to its input — one correctly
rounded multiplication then one correctly rounded addition, fused
multiply-add forbidden — where the input is the previous stage's
output rather than the stored value; the model is closed over
binary64, so no stage-position distinction exists in its arithmetic. A
lookup-table stage applies the `VOXELIA-ALG-0004` model and is
admissible only while every earlier stage is an identity, because its
clamped index is defined on the exact stored integer value; a table
after an arithmetic stage would need an input-rounding rule that no
registered model provides.

## Admission bounds

The consuming operation admits at most 8 declared stages per chain, a
nested composed stage is not admitted (flattening changes rounding
behaviour and needs its own model), and an empty table stage defines
no output. A chain whose effective stages are all identities is
exactly the identity mapping.

## Determinism and failure classification

Sequential evaluation of pure registered stage models is a pure
function of the stored value and the chain: repeated evaluation is
bit-identical. Every violation of the admission bounds is a typed
failure in the receiver; no branch of the model itself can fail.

## Conformance fixtures

Independently computed and composed with the `VOXELIA-ALG-0002`
window model over `uint8` stored samples `0...11`:

- Chain `linear(scale 2, offset -3)` then
  `linear(scale 0.5, offset 10)`, windowed with `c = 12`, `w = 10`:
  `[43, 71, 99, 128, 156, 184, 212, 241, 255, 255, 255, 255]`.
- Chain `identity`, then the table `firstMappedValue = 2`,
  `values = [-100, 0, 50.5, 200]`, then `linear(scale 2, offset 0)`,
  windowed with `c = 50`, `w = 600`:
  `[21, 21, 21, 106, 149, 255, 255, 255, 255, 255, 255, 255]`.

## References

- [ADR-0070 - Composed chain composition](../architecture/decisions/ADR-0070-composed-chain-composition.md)
- [VOXELIA-ALG-0003 - Linear stored-to-real value mapping binary64-v1](VOXELIA-ALG-0003-linear-value-transform.md)
- [VOXELIA-ALG-0004 - Lookup-table stored-to-real value mapping binary64-v1](VOXELIA-ALG-0004-lookup-table-value-transform.md)
