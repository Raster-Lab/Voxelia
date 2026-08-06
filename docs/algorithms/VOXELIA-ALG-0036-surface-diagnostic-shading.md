---
document_id: "VOXELIA-ALG-0036"
title: "Surface diagnostic shading binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Surface diagnostic shading binary64-v1

## Purpose

This specification defines `surface-diagnostic-shading/binary64-v1`, the
deterministic CPU reference selected by accepted
[`ADR-0202`](../architecture/decisions/ADR-0202-surface-shading-design.md). For
one fragment it interpolates the source mesh's deterministic vertex normals by
that fragment's barycentric weights and produces one **shading intensity** in
`[0, 1]`.

**Colour is deliberately absent.** The intensity is a scalar; a colour
representation is the scalar-colour-map contract's to settle, and it must
settle one regardless. Producing an intensity here keeps this record free of a
channel-count, colour-space and premultiplication decision it has no authority
to make.

## Input domain and admission

The inputs are three unit vertex normals in the mesh's **original** vertex
order, three barycentric weights in the same order, and the camera's forward
unit axis.

The source mesh must carry a built-in `.normal` vertex attribute. A mesh
without one is rejected `normalsMissing` rather than falling back to a facet
normal: a fallback would give two meshes that differ only in whether they carry
normals two different shadings, and `ADR-0193` already provides an accepted
operation to generate them.

The normals are the accepted `ADR-0193` output and are therefore unit vectors
by construction; this model does not re-admit them.

## Weight-to-vertex correspondence

`VOXELIA-ALG-0034` canonicalises a facet's winding by swapping its second and
third vertices whenever the projection mirrored it, and publishes its
barycentric weights in that **canonicalised** order. Consuming those weights
therefore requires knowing whether the swap occurred, and a consumer that
assumed it had not would attribute the second vertex's normal to the third.

`ADR-0202` closes that gap by publishing the swap alongside the weights, which
is additive and changes no registered `ALG-0034` digest. This model consumes
weights already mapped back to original vertex order.

The registered `mis-mapped-weights` fixture is the evidence that the
correspondence matters: the same normals and weights with two of the normals
exchanged produce a different intensity.

## Interpolation

```text
n[lane] = ((wA * n0[lane] + wB * n1[lane]) + wC * n2[lane])
```

for each of `x`, `y`, `z`, in that order. Every displayed multiplication and
addition is one separate correctly rounded binary64 operation, using the same
`((a + b) + c)` grouping the projection, visibility and measurement records
share.

Interpolation can lose the direction entirely. A least-subnormal normal
multiplied by a weight of one third underflows to exactly zero, so the
interpolated vector is zero even though every input was non-zero. The
registered `subnormal-underflows` fixture proves this happens in the
*interpolation*, not the normalisation, and the model publishes the resulting
zero rather than inferring the direction the inputs implied.

## Renormalisation

The interpolated vector is renormalised by the maximum-component-scaled
Euclidean rule frozen by
[`VOXELIA-ALG-0030`](VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md):

```text
scale = max(abs(n.x), abs(n.y), abs(n.z))
```

If `scale` is exactly zero the direction is undefined and the intensity is
positive zero. This deliberately differs from `ADR-0193`, which rejects an
undefined **published** normal: shading is presentation, not measurement, and
failing an entire render because one sample's normals cancelled exactly would
be disproportionate. The registered `cancelling-normals` fixture holds two
exactly opposed normals at equal weight.

Otherwise:

```text
sx = n.x / scale ; sy = n.y / scale ; sz = n.z / scale
sum = (sx * sx + sy * sy) + sz * sz
length = sqrt(sum)
ux = sx / length ; uy = sy / length ; uz = sz / length
```

The registered `subnormal-at-vertex` fixture shows the scaled rule recovering a
least-subnormal normal at full weight, because it never forms an underflowing
sum of squares.

## Two-sided Lambert headlight

The light is a headlight at the camera, so the light direction is the camera's
forward axis and no light position, colour or falloff exists.

```text
projection = ((ux * fx + uy * fy) + uz * fz)
magnitude  = abs(projection)
intensity  = magnitude < 1 ? magnitude : 1
```

The **absolute value** is what makes the material two-sided, and that is a
deliberate choice rather than a convenience. Extraction publishes open
surfaces, `ALG-0034` deliberately does not cull back faces, and a one-sided
`max(0, N·L)` would therefore render the interior of every open surface black —
hiding geometry a diagnostic reader needs to see.

The clamp is an **exact** operation, not an epsilon, and it is **reachable**:
rounding in the renormalisation and the dot product can carry the magnitude
above one even for a unit normal against itself. The registered
`rounding-clamped` fixture uses a normal whose self-projection evaluates to
`1.0000000000000002`.

The `forty-five` fixture records a related consequence: the frozen scaled
normalisation yields `1 / sqrt(2)`, which differs in the last place from
`sqrt(0.5)`. The normalisation expression is part of the algorithm identity.

## Precision and representability

IEEE-754 binary64, round-to-nearest-ties-to-even, gradual subnormals, no fast
math, no flush-to-zero, no contraction, no reassociation.

There is **no representability failure**. Every input is a unit normal or a
barycentric weight; the interpolated components are bounded by the largest
input magnitude, the scaled components lie in `[-1, 1]`, the sum of squares
lies in `[1, 3]`, and the clamped intensity lies in `[0, 1]`. Infinity is
unreachable and NaN would require `0 * infinity` or `infinity - infinity`. The
only non-arithmetic failure is the missing-normals rejection.

## Failure precedence and cancellation

```text
normalsMissing
cancelled
```

Cancellation is checked before fragment zero and every fragment ordinal
divisible by 4,096, matching the per-sample cadence the projector uses.

## Determinism and accelerated conformance

The reference is serial and stateless. Identical normals, weights and forward
axis produce an identical intensity. An accelerated implementation must
reproduce every intensity bit-for-bit; a half-precision or fast-normalise
shader does not conform.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0202-surface-shading-oracle.py`](../progress/evidence/ADR-0202-surface-shading-oracle.py).
It records fourteen fixtures: a surface facing the camera fully lit; one facing
away lit **identically**, proving the two-sided rule; an edge-on surface unlit;
a forty-five degree surface at the scaled rule's own root of one half; full
weight at the first and second vertices reproducing each vertex's own shading;
an interpolated mixture strictly between; exactly cancelling normals at
positive zero; a rounding case clamped to exactly one; a least-subnormal normal
underflowing during interpolation; the same normal surviving at full weight; an
oblique forward axis; skewed weights; and the same normals mis-mapped,
producing a different intensity.

The registered output is:

```text
fixtureSHA256=a1f8fd3ff7933c12bcd269b94c05d2919fb78801bf99fabf15dc29b7f0514330
intensitySHA256=c9dfc8df1e26cf1c4ebff61561fbc9c030290ecd426d79e72193fdb54c22cd37
fixtures=14 successful=14 failures=0
material=two-sided-lambert-headlight intensity=[0,1] clamp=exact
undefinedNormal=positive-zero colour=absent
```

## Complexity and exclusions

`O(1)` per fragment.

Colour, colour spaces, premultiplication, ambient and specular terms, multiple
or positioned lights, light colour, falloff, shadows, physically based
materials, texture mapping, tone mapping and any published image remain
separate contracts.

## References

- [ADR-0193 - Deterministic triangle-mesh vertex normals design](../architecture/decisions/ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0200 - Surface visibility design](../architecture/decisions/ADR-0200-surface-visibility-design.md)
- [ADR-0202 - Surface shading design](../architecture/decisions/ADR-0202-surface-shading-design.md)
- [VOXELIA-ALG-0030 - Triangle area-weighted vertex normals](VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
