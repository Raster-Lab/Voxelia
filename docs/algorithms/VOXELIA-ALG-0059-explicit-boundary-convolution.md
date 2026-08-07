---
document_id: "VOXELIA-ALG-0059"
title: "Explicit-boundary convolution binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Explicit-boundary convolution binary64-v1

## Purpose

The first half of `VOX-IMG-011` — convolution with **explicit boundary
conditions**, the row's own emphasis — over `ADR-0352`'s stored-value domain.
The model is `convolution/binary64-v1`; the Gaussian composes it in its own
record. `ADR-0354` records the design.

## The boundary vocabulary

A closed two-case choice the caller must make — there is no default, because a
defaulted boundary is an implicit one and the row forbids exactly that:

- **`replicate`**: an out-of-image tap reads the nearest edge sample along
  each axis (per-axis clamping of the source index);
- **`zero`**: an out-of-image tap contributes exactly zero.

Mirror and periodic boundaries are future cases with their own records; a
closed enum keeps their absence visible.

## The kernel

Caller-supplied binary64 weights with **odd extents per axis** (the centre
must exist), rank equal to the image's, each extent at most `31`, every weight
finite. The kernel is applied in **correlation orientation** — the weight at
offset `o` multiplies the sample at `index + o` — stated so nobody flips it
silently; a caller wanting true convolution reverses its own kernel.

## The frozen arithmetic

Samples widen exactly to binary64 (`ADR-0352`'s domain guarantee). For each
output index in canonical order, the accumulator starts at exactly `0.0` and
kernel offsets are visited in **ascending lexicographic order, axis zero
fastest**, with left-associative accumulation:

```text
acc = acc + weight[k] * sample(index + offset(k))
```

No fused multiply-add, no pairwise or compensated summation — the order is the
contract, as `VOXELIA-ALG-0052` froze for its sums.

The output composes `VOXELIA-ALG-0058`'s result rule verbatim: integer types
round ties-to-even then saturate with every saturation counted; `float32`
narrows to binary32 and stores non-finite results verbatim, counted. The
warning codes are this operation's own —
`org.voxelia.warn.convolution-saturated` and
`org.voxelia.warn.convolution-non-finite` — so provenance attributes the stage
that produced them; both absent at zero.

## Determinism and failure classification

One pass; every rounding step is frozen above. Failure cases are
admission-only: `unsupportedLayerFormat`, `invalidKernel` (rank mismatch, even
or oversized extent, weight-count mismatch, non-finite weight).

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0354-convolution-oracle.py`; all
exact; images are rank-two `n x 1` so the frozen lexicographic order is
exercised on real machinery.

1. **uint8 smoothing `1, 2, 1`** on `10, 20, 30, 40, 50`: replicate →
   `50, 80, 120, 160, 190`; zero → `40, 80, 120, 160, 140` — the boundary
   choice changes both edges and nothing else.
2. **int16 central difference `-1, 0, 1`** on `100, 200, 400, 800, 1600`:
   replicate → `100, 300, 600, 1200, 800`; zero →
   `200, 300, 600, 1200, -800` — negatives representable, edges
   boundary-dependent.
3. **uint8 saturation**: the smoothing kernel on `100, 200, 250, 200, 100`
   under zero boundary → all five outputs `255`, saturated count `5`.
4. **float32 quarter kernel `0.25, 0.5, 0.25`** on `1, 2, 4, 8`, replicate →
   `1.25, 2.25, 4.5, 7.0`, every value an exact binary fraction.

## Validation obligations

The implementing increment must reproduce all four fixtures exactly under
both boundaries where listed, verify the saturation warning's count and its
absence at zero, and verify the admission rejections typed — including an
even-extent kernel and a non-finite weight.

## References

- [VOXELIA-ALG-0058 - Mask application and arithmetic](VOXELIA-ALG-0058-mask-application-and-arithmetic.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](VOXELIA-ALG-0052-affine-composition-and-directions.md)
- [ADR-0354 - Explicit-boundary convolution](../architecture/decisions/ADR-0354-explicit-boundary-convolution.md)
