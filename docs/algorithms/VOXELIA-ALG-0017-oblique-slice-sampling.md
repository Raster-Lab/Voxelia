---
document_id: "VOXELIA-ALG-0017"
title: "Oblique slice sampling binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Oblique slice sampling binary64-v1

## Purpose

This specification defines the versioned reference operation
`oblique-slice-sampling/binary64-v1` selected by accepted
[`ADR-0141`](../architecture/decisions/ADR-0141-oblique-extraction-design.md).
It samples an obliquely oriented plane from a rank-three eight-bit
regular affine volume — the reconstruction model behind
`VOX-MPR-003`'s remainder.

## Model

The request is the output slice's own affine geometry: a rank-two
output of `nU` by `nV` samples whose claimed matrix carries the plane
origin as its translation and the two in-plane step columns for
slots zero and one. For output position `(i, j)` the world sample
position evaluates in the claimed forward form — translation plus
ascending products, each operation correctly rounded:

```text
w[r] = (t[r] + (M[r][0] * i)) + (M[r][1] * j)
```

The world position maps to continuous volume indices through the
accepted `VOXELIA-ALG-0016` inverse and its frozen consuming
composition — three correctly rounded subtractions, then per slot
the ascending left-to-right accumulation — yielding `c0, c1, c2` in
the volume's image-axis order.

**Support and padding.** The sample support on volume axis `k` with
extent `n_k` is the closed pixel-centre interval
`[-0.5, n_k - 0.5]`. A sample whose continuous coordinate leaves the
support on any axis yields exactly `0` — the declared version-one
padding value, stated rather than parameterised; a declared-sentinel
widening follows the `ADR-0113` precedent as its own revision.
Inside the support, per-axis taps derive from the unclamped floor
exactly as the accepted `VOXELIA-ALG-0015` rule:

```text
i0f = floor(c)
t   = c - i0f
i0  = clamp(i0f, 0, n - 1)
i1  = clamp(i0f + 1, 0, n - 1)
```

so a coordinate within half a voxel of the border replicates the
border sample.

**Trilinear reduction.** Sample values convert exactly to binary64
and reduce over ascending volume axes, each operation correctly
rounded, no fused multiply-add:

```text
vx(j, k)  = (v(i0, j, k) * (1 - t0)) + (v(i1, j, k) * t0)
vxy(k)    = (vx(j0, k) * (1 - t1)) + (vx(j1, k) * t1)
value     = (vxy(k0) * (1 - t2)) + (vxy(k1) * t2)
```

The output byte is `clamp(roundHalfToEven(value), 0, 255)`; every
stage is a convex combination so the clamp is modelled. A request
whose samples all land on integer in-support coordinates reproduces
the stored bytes exactly.

## Determinism and failure classification

The mapping is a pure function of the volume, its claimed geometry
and the request geometry: repeated evaluation is bit-identical.
Admission — rank, format, calibration, shared coordinate space,
output bounds — is the receiver's typed surface; no branch of the
model itself can fail for admitted inputs.

## Output geometry claim

The output slice claims the request geometry verbatim: the sampler
honours exactly the grid the request describes, so the claim records
what ran. The out-of-plane column of the request matrix takes no
part in sampling and survives only as the claimed plane orientation.

## Conformance fixtures

Independently computed under the frozen order over the rank-three
volume with extents `(3, 3, 3)`, identity index-to-world geometry
and stored value `2*i0 + 6*i1 + 18*i2`:

- The diagonal request — origin `(0.5, 0.5, 0.5)`, step columns
  `(0.5, 0.5, 0)` and `(0, 0, 1)`, two by two — produces exactly
  `[13, 17, 31, 35]` axis-zero fastest: trilinear reduction of an
  affine field reproduces the field at every sample.
- A sample at continuous `(-5, 0, 0)` leaves the support and yields
  exactly the padding value `0`.
- A sample at continuous `(-0.25, 1, 0)` is inside the support with
  both axis-zero taps clamped to the border and yields exactly `6`.
- A sample at continuous `(1/3, 0, 0)` pins the rounded weight: the
  frozen binary64 pre-round value is exactly
  `0.6666666666666666` and the output byte is `1`.

## Validation obligations

The implementing increment must reproduce all four fixtures, prove
the integer-coordinate identity against a stored plane, and reject
each typed admission — an uncalibrated volume, a foreign-space
request, a non-rank-three volume and an unsupported format — without
coercion.

## References

- [ADR-0141 - Oblique extraction design](../architecture/decisions/ADR-0141-oblique-extraction-design.md)
- [VOXELIA-ALG-0015 - Bilinear resampling binary64-v1](VOXELIA-ALG-0015-bilinear-resampling.md)
- [VOXELIA-ALG-0016 - Affine spatial inverse binary64-v1](VOXELIA-ALG-0016-affine-inverse.md)
