---
document_id: "VOXELIA-ALG-0060"
title: "Separable Gaussian filter binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Separable Gaussian filter binary64-v1

## Purpose

The second half of `VOX-IMG-011`. The model is `gaussian/binary64-v1`,
composing `VOXELIA-ALG-0059`'s boundary and accumulation rules per axis.
`ADR-0355` records the design.

## The frozen discretisation

Per axis with deviation `sigma` (finite, positive):

- **Sampled weights**: `w(o) = exp(-o^2 / (2 sigma^2))` at integer offsets —
  the sampled Gaussian, not the integrated one; the trade (integrated is
  closer for very small deviations) is recorded in `ADR-0355` and an
  integrated variant may join by its own record.
- **Truncation radius `r = ceil(3 sigma)`**, kernel extent `2r + 1`, which
  must respect the convolution ceiling of `31` — so `sigma <= 5` admits and
  larger rejects typed (`invalidSigma`).
- **Normalisation**: the raw weights sum left-to-right in ascending offset
  order, then each divides by that binary64 sum — the frozen order, making
  the weights a convex combination up to that order's rounding.

## The frozen pass structure

Axis-ascending separable passes (axis zero first), each a one-dimensional
`VOXELIA-ALG-0059` convolution along its axis under the caller's boundary —
and **the intermediates stay binary64 between passes**: narrowing per pass
would round once per axis, so the stored-type conversion happens exactly once,
after the final pass, under the `VOXELIA-ALG-0058` output rule with this
operation's own warning codes (`org.voxelia.warn.gaussian-saturated`,
`org.voxelia.warn.gaussian-non-finite`, absent at zero).

**Integer saturation is unreachable for finite inputs** — the normalised
kernel makes every pass a convex combination, so no result exceeds the input
range; the shared store rule keeps its counter, the convexity argument keeps
it silent, and fixture 4's constant fixed point is the witness.

## Determinism and failure classification

Every rounding step is frozen above. Failure cases are admission-only:
`unsupportedLayerFormat`, `invalidSigma` (non-finite, non-positive, or a
radius breaking the extent ceiling; one deviation per axis, rank-matched).

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0355-gaussian-oracle.py`; exact.

1. **Impulse, `sigma = 1`, replicate**, `255` at the centre of `7 x 1`:
   `14, 62, 102, 62, 14, 1, 0`.
2. **Impulse, `sigma = 0.5`**: `0, 27, 201, 27, 0, 0, 0` — the smaller
   deviation concentrates, radius `2`.
3. **`3 x 3` `float32` impulse (`16` at centre), `sigma = 1`, zero
   boundary**: the separable product structure, corner `0.937305...`,
   stored bytes registered in the oracle output.
4. **The constant image is a fixed point**: `200` everywhere, mixed
   deviations, replicate → `200` everywhere — the convexity witness.
5. **The deviation ceiling**: `sigma = 5` admits (extent `31`);
   `sigma = 5.1` rejects (extent `33`).

## Validation obligations

The implementing increment must reproduce fixtures 1 through 4 exactly,
verify fixture 5's admission edge typed on both sides, verify no warning
appears in any finite fixture, and re-run the `VOXELIA-ALG-0059` fixtures
unchanged after any shared-core extraction — the extraction is proven, not
assumed.

## References

- [VOXELIA-ALG-0059 - Explicit-boundary convolution](VOXELIA-ALG-0059-explicit-boundary-convolution.md)
- [VOXELIA-ALG-0058 - Mask application and arithmetic](VOXELIA-ALG-0058-mask-application-and-arithmetic.md)
- [ADR-0355 - Separable Gaussian filter](../architecture/decisions/ADR-0355-separable-gaussian-filter.md)
