---
document_id: "VOXELIA-ALG-0007"
title: "Camera-relative float transform derivation binary32-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Camera-relative float transform derivation binary32-v1

## Purpose

This specification defines the versioned reference operation
`camera-relative-float-transform/binary32-v1` selected by accepted
[`ADR-0087`](../architecture/decisions/ADR-0087-float-transform-error-bounds.md).
It derives a `binary32` camera-relative affine transform from a
validated `binary64` index-to-world affine and a camera position, and
states the verified forward error bound that `VOX-SPA-004` requires
before any rendering-specific float transform is permitted.

## Model and evaluation order

Given the affine matrix `M` with rotation-scale block `R`, translation
`t` (all `binary64`) and camera position `p` (`binary64`), the
derivation is:

```text
t'[r] = t[r] - p[r]                    (binary64, correctly rounded)
F[r][c] = binary32(R[r][c])            (one rounding per element)
F[r][3] = binary32(t'[r])              (one rounding per element)
```

The camera-relative subtraction happens in `binary64` before any
demotion, which removes the large-coordinate cancellation that makes
naive `binary32` world transforms unusable. Applying `F` to an index
`i` uses `binary32` arithmetic:

```text
y32[r] = ((F[r][0] * i0 + F[r][1] * i1) + F[r][2] * i2) + F[r][3]
```

in exactly this association, each operation correctly rounded, no
fused multiply-add.

## Verified error bound

Let `u = 2^-24` (the `binary32` unit roundoff), `γ5 = 5u / (1 - 5u)`,
and for each row define the magnitude sum

```text
S[r] = |R[r][0]*i0| + |R[r][1]*i1| + |R[r][2]*i2| + |t'[r]|
```

evaluated in `binary64`. With `y64[r]` the exact `binary64`
camera-relative result, the derivation and evaluation above satisfy

```text
|y32[r] - y64[r]| <= γ5 * S[r]
```

for every index whose products and sums stay within the `binary32`
normal range. The bound follows the standard forward error analysis:
four initial demotion roundings contribute at most `u` relative error
per element, and the three multiplications and three additions
contribute the classic `γ4` inner-product term; `γ5` dominates their
composition. Subnormal intermediate values fall outside the verified
domain and must be reported, not assumed.

## Determinism and failure classification

The derivation is a pure function of `M` and `p`; repeated evaluation
is bit-identical. The receiver rejects a camera whose coordinate
space differs from the geometry's and surfaces no other failure: the
inputs are already validated values.

## Conformance harness

The verification harness generates thousands of deterministic
seeded-generator affines, camera positions and indices across
magnitude regimes, computes `y64` in `binary64` and `y32` per this
model, and asserts `|y32[r] - y64[r]| <= γ5 * S[r]` for every sample
and row, reporting the maximum observed bound ratio as measured
evidence. A violated bound is a failed suite, never a widened bound.

## References

- [ADR-0087 - Float transform error bounds](../architecture/decisions/ADR-0087-float-transform-error-bounds.md)
- [VOXELIA-ALG-0006 - Region origin shift binary64-v1](VOXELIA-ALG-0006-region-origin-shift.md)
