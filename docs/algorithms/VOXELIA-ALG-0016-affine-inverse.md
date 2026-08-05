---
document_id: "VOXELIA-ALG-0016"
title: "Affine spatial inverse binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Affine spatial inverse binary64-v1

## Purpose

This specification defines the versioned reference operation
`affine-inverse/binary64-v1` selected by accepted
[`ADR-0136`](../architecture/decisions/ADR-0136-affine-inverse-design.md).
It inverts the three-by-three spatial part of an affine grid geometry
so world positions map back to grid indices — the model behind
oblique crosshair mapping and world-point picking.

## Model

For the row-major spatial matrix `m` with entries `m[r][s]`, every
two-by-two cofactor evaluates in the frozen order

```text
cof(a, d, b, c) = (a * d) - (b * c)
```

with each operation correctly rounded and no fused multiply-add. The
determinant expands along row zero:

```text
c0  = cof(m11, m22, m12, m21)
c1  = cof(m10, m22, m12, m20)
c2  = cof(m10, m21, m11, m20)
det = ((m00 * c0) - (m01 * c1)) + (m02 * c2)
```

in exactly this order. The computed determinant must satisfy
`|det| >= leastNormalMagnitude` — the no-epsilon admission rule —
and each inverse entry is the signed transposed cofactor divided by
the computed determinant, one correctly rounded division per entry,
with every cofactor evaluated through the one frozen `cof` form.
The inverse of a world offset then composes index =
`inverse * (world - translation)` under the accepted
`VOXELIA-ALG-0006`-style row evaluation; that composition is the
consuming operation's own frozen step.

## Error bound

Per cofactor, `|ĉ - c| <= γ₂ · C` with `C = |a·d| + |b·c|` and
`γₖ = k·u / (1 - k·u)`, `u = 2⁻⁵³`. For the determinant,
`|d̂ - d| <= γ₄ · D + Σₖ |m0k| · γ₂ · Cₖ` with
`D = |m00·c0| + |m01·c1| + |m02·c2|`. For each inverse entry the
composed elementwise bound is

```text
B = (γ₂ · C + |ĉ| · (E_d / |d̂|)) / |d̂| · (1 + u) + u · |ĉ / d̂|
```

where `E_d` is the determinant bound above — a conservative
composition whose constants the implementation harness must verify by
measurement: the harness computes `B` beside every entry and asserts
`|computed - exact| <= B` elementwise over the corpus, reporting the
maximum observed ratio as evidence with recorded headroom, per the
`VOXELIA-ALG-0007` precedent. The bound is valid away from
determinant cancellation; diagonally dominant admission corpora
guarantee non-cancelling determinants by the Levy–Desplanques
theorem.

## Determinism and failure classification

The inverse is a pure function of the matrix: repeated evaluation is
bit-identical. The determinant admission is the receiver's typed
surface; no branch of the model itself can fail for admitted inputs.

## Conformance fixtures

Independently computed under the frozen order:

- The rotation-scale matrix with rows `(0, -2, 0)`, `(2, 0, 0)`,
  `(0, 0, 1)`: determinant exactly `4`, inverse rows exactly
  `(0, 0.5, 0)`, `(-0.5, 0, 0)`, `(0, 0, 1)` up to signed zeros.
- The diagonal `(2, 4, 5)`: determinant exactly `40`, inverse
  diagonal exactly `(0.5, 0.25, 0.2)`.
- The symmetric matrix with rows `(4, 1, 0)`, `(1, 5, 2)`,
  `(0, 2, 6)`: determinant exactly `98`; the exact rational inverse
  row zero is `(13/49, -3/49, 1/49)` and the frozen binary64 row zero
  is exactly `0.2653061224489796`, `-0.061224489795918366`,
  `0.02040816326530612`.

## Validation obligations

The implementing increment must reproduce all three fixtures, verify
the elementwise bound against an exact rational python oracle over at
least ten thousand seeded-LCG diagonally dominant matrices across
magnitude regimes, report the maximum observed ratio with headroom,
and reject a sub-threshold determinant typed.

## References

- [ADR-0136 - Affine inverse design](../architecture/decisions/ADR-0136-affine-inverse-design.md)
- [VOXELIA-ALG-0007 - Camera-relative float transform derivation binary32-v1](VOXELIA-ALG-0007-camera-relative-float-transform.md)
