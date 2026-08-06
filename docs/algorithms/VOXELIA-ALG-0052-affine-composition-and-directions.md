---
document_id: "VOXELIA-ALG-0052"
title: "Affine composition and direction transformation binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Affine composition and direction transformation binary64-v1

## Purpose

`VOX-SPA-008` requires affine transforms to support composition, inversion and point,
vector and normal transformation. `VOXELIA-ALG-0016` specifies inversion and `ADR-0138`
froze a point transformation for one consumer. This specification adds the three that
`ADR-0280` found absent: **composition**, **vector transformation** and **normal
transformation**.

It is the model `affine-composition/binary64-v1`.

## Conventions inherited, not restated

`Matrix4x4Double` stores sixteen elements in row-major order, so row `r` column `c` is
`elements[4r + c]`; it admits only finite elements and normalises negative zero to positive
zero on admission. Voxelia multiplies homogeneous **column** vectors, `M × [x, y, z, 1]ᵀ`,
so translation occupies indices `3`, `7` and `11`.

Throughout, `M3` denotes the upper-left three-by-three block in row-major order and `Mt`
the translation triple.

## Admission

Both composition operands, and the operand of a direction transformation, must be
**affine**: elements `12`, `13`, `14` exactly zero and element `15` exactly one. A
non-affine operand is rejected as `nonAffineOperand`.

Admission is exact equality, not a tolerance. `Matrix4x4Double` already guarantees
finiteness, so no separate finiteness check is performed and none is claimed.

## Composition

`compose(A, B)` produces `C` such that **`C × p` equals `A × (B × p)`** — that is, `B` is
applied first. The name reads "A after B".

The affine structure is used rather than multiplying by known zeros and ones:

```text
C3[3r + c] = ((A3[3r+0] * B3[0*3+c] + A3[3r+1] * B3[1*3+c]) + A3[3r+2] * B3[2*3+c])
Ct[r]      = (((A3[3r+0] * Bt[0] + A3[3r+1] * Bt[1]) + A3[3r+2] * Bt[2]) + At[r])
```

Every sum is **left-associative in ascending index order** and there is **no fused
multiply-add**. The translation term `At[r]` is added **last**, after the three products
have accumulated.

The bottom row of `C` is **set to the literal `0, 0, 0, 1`** and is not computed. Computing
it would multiply admitted values by known zeros, which contributes signed zeros to sums
that are otherwise exact and buys nothing: both operands are affine by admission, so the
product's bottom row is that literal by construction.

## Vector transformation

A vector is a direction and takes no translation:

```text
v'[r] = ((M3[3r+0] * v[0] + M3[3r+1] * v[1]) + M3[3r+2] * v[2])
```

This is a **row** traversal of `M3`, and it is deliberately the same expression order
`ADR-0138` froze for the world-to-index step, so the two agree where they overlap.

## Normal transformation

A normal is a covector and transforms by the **inverse transpose**:

```text
n'[r] = ((Inv[0*3+r] * n[0] + Inv[1*3+r] * n[1]) + Inv[2*3+r] * n[2])
```

where `Inv` is `VOXELIA-ALG-0016`'s inverse of `M3`, composed unchanged rather than
recomputed.

This is a **column** traversal of `Inv`, which is what expresses the transpose. It must not
be rewritten as a row traversal: that would silently compute `Inv × n` and reintroduce the
error this operation exists to prevent.

### The result is deliberately not normalised

The operation is a linear map and stops there. Normalisation is a separate accepted rule
(`VOXELIA-ALG-0030` publishes unit normals; `VOXELIA-ALG-0036` renormalises the
interpolated direction before use), and applying it here would duplicate that rule and make
a chain of transformations differ from the composition of its matrices.

A result that underflows to zero is therefore a value, not a failure. The undefined
direction it represents is already handled where normalisation happens, so no failure case
is carried here for it.

## When the vector and normal rules differ

They agree exactly when `M3` is orthonormal, because `R⁻ᵀ = R` for a rotation. They diverge
under any anisotropic scale or shear.

Both statements matter and they answer different questions. Whether to transform a
direction **at all** is decided by which space its consumer works in; **which of the two
rules** to use is decided by whether the direction is a vector or a normal.

## Determinism and failure classification

Repeated evaluation of the same admitted inputs is bit-identical: every expression order is
fixed above, no fused multiply-add is permitted, and no value depends on iteration order,
allocation or time.

Failure cases, in full:

- `nonAffineOperand` — a bottom row other than exactly `0, 0, 0, 1`.
- `singularMatrix` — raised by `VOXELIA-ALG-0016` from a normal transformation only,
  composed rather than restated.

There is **no representability failure**. `Matrix4x4Double` admits only finite elements,
and the accepted siblings `VOXELIA-ALG-0016` and `ADR-0138` likewise publish products
without a finiteness check. Carrying one here would add a branch neither of them has.

## Composition is not associative, and this specification does not claim it is

Floating-point composition is not associative, so `compose(compose(X, Y), Z)` and
`compose(X, compose(Y, Z))` may differ. A witness is registered below.

A consumer that needs a specific result must fix its own grouping. `VOXELIA-ALG-0033`'s prohibition
on pre-multiplying an object-to-world with a world-to-view transform is the same hazard
seen from the other side, and stays in force: this specification supplies composition, it
does not authorise folding a chain that an accepted record keeps separate.

## Conformance fixtures

Independently computed under the frozen order.

**1 — composition order.** With `B` scaling by `2` and translating by `(1, 0, 0)`, and `A`
rotating `−90°` about Z and translating `(0, 0, 3)`, `compose(A, B)` has rows exactly:

```text
 0, -2,  0,  0
 2,  0,  0,  1
 0,  0,  2,  3
 0,  0,  0,  1
```

For `p = (1, 2, 3)`, `C × p` and `A × (B × p)` are both exactly `(-4, 3, 9)`, and
`compose(B, A)` differs from `compose(A, B)`.

**2 — a vector ignores translation.** Under that same `C` and the triple `(1, 2, 3)`:
as a vector, exactly `(-4, 2, 6)`; as a point, exactly `(-4, 3, 9)`.

**3 — normal against vector under anisotropic scale.** With `M3 = diag(1, 1, 5)` and
`n = (0, 1, 1)`: as a vector, exactly `(0, 1, 5)`; as a normal, exactly `(0, 1, 0.2)`.

**4 — the two rules agree under a pure rotation.** With `M3` the `+90°` rotation about X
and `n = (0, 0, 1)`: both rules give exactly `(0, -1, 0)`.

**5 — non-associativity witness.** With `X = diag(1e300, 1, 1)`, `Y = diag(1e-300, 1, 1)`
and `Z = diag(3, 1, 1)`, element zero of `compose(compose(X, Y), Z)` is exactly `3.0`
while element zero of `compose(X, compose(Y, Z))` is exactly `3.0000000000000004`.

## Validation obligations

The implementing increment must reproduce all five fixtures exactly, must show that
`compose` and staged application agree on fixture 1 rather than asserting it, must verify
that a normal transformation composes `VOXELIA-ALG-0016` rather than reimplementing an
inverse, and must reject a non-affine operand typed.

It must also confirm that no existing consumer's registered digests change, per `ADR-0280`
decision 3, since nothing here replaces an accepted frozen step.

## References

- [VOXELIA-ALG-0016 - Affine spatial inverse](VOXELIA-ALG-0016-affine-inverse.md)
- [VOXELIA-ALG-0030 - Triangle area weighted vertex normals](VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md)
- [VOXELIA-ALG-0033 - Surface vertex projection](VOXELIA-ALG-0033-surface-vertex-projection.md)
- [ADR-0138 - World to index mapping](../architecture/decisions/ADR-0138-world-to-index-mapping.md)
- [ADR-0280 - Open the affine transform arc](../architecture/decisions/ADR-0280-open-the-affine-transform-arc.md)
