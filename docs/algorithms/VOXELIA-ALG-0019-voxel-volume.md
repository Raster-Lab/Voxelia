---
document_id: "VOXELIA-ALG-0019"
title: "Calibrated voxel volume binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Calibrated voxel volume binary64-v1

## Purpose

This specification defines the versioned reference model
`voxel-volume/binary64-v1` selected by accepted
[`ADR-0143`](../architecture/decisions/ADR-0143-area-volume-measurement-design.md)
— the volume half of `VOX-SPA-014`. Version one measures a supplied
voxel count against a claimed affine calibration; the authority that
counts voxels — a segmentation, a threshold, a host selection — is
its own future arc, and this model deliberately does not invent one.

## Model

For a claimed affine grid geometry, the exact cell volume is the
magnitude of the upper-left three-by-three determinant evaluated in
the accepted `VOXELIA-ALG-0016` frozen order — the one determinant
authority, never re-derived:

```text
cellVolume = |det|                       (exact magnitude)
volume     = count * cellVolume          (one correctly rounded multiply)
```

with `count` a nonnegative integer converted exactly to binary64;
the receiver's typed surface bounds `count` at `2^53` so the
conversion is exact for every admitted value. The result carries the
coordinate space's cubed length unit; unit conversion is outside
this model.

## Determinism and failure classification

The volume is a pure function of the geometry and the count:
repeated evaluation is bit-identical. Count bounds and calibration
admission are the receiver's typed surface; the sub-threshold
determinant is already unreachable for a validated geometry. No
error bound is claimed: the determinant is the accepted authority's
value and the single multiply is correctly rounded.

## Conformance fixtures

Independently computed under the frozen order:

- The identity geometry with count `7`: exactly `7`.
- The diagonal `(2, 4, 5)` geometry (determinant exactly `40`) with
  count `3`: exactly `120`.
- The rotation-scale fixture geometry (determinant exactly `4`) with
  count `10`: exactly `40`.
- The symmetric fixture geometry (determinant exactly `98`) with
  count `2`: exactly `196`.
- Count `0` with any admitted geometry: exactly positive zero.

## Validation obligations

The implementing increment must reproduce all five fixtures, prove
bit-identical repetition, and reject a negative count and a count
above `2^53` typed.

## References

- [ADR-0143 - Area and volume measurement design](../architecture/decisions/ADR-0143-area-volume-measurement-design.md)
- [VOXELIA-ALG-0016 - Affine spatial inverse binary64-v1](VOXELIA-ALG-0016-affine-inverse.md)
