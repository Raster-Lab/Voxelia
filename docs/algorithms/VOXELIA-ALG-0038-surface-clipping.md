---
document_id: "VOXELIA-ALG-0038"
title: "Surface world-box clipping binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Surface world-box clipping binary64-v1

## Purpose

This specification defines `surface-world-box-clipping/binary64-v1`, the
deterministic CPU reference selected by accepted
[`ADR-0204`](../architecture/decisions/ADR-0204-surface-clipping-design.md). For
one fragment it interpolates the world position and decides whether the
fragment is retained under an axis-aligned world clip box.

## Clipping is a predicate, not a cut

**No geometry is cut, no vertex is created and no topology is changed.**
Clipping is a per-fragment predicate over an interpolated world position.

That choice is what keeps this contract small. Geometric clipping would have
to split facets, synthesise vertices, decide the new vertices' attributes and
re-establish winding — a constructive-geometry subsystem this record does not
need, because the visibility and fragment stages already evaluate per-fragment
data and discarding a fragment is exact.

## Section views are uncapped, and that is legible by construction

A clipped solid shows its **own far side** through the cut. No cap is
synthesised.

This composes a decision already made for a different reason:
[`VOXELIA-ALG-0036`](VOXELIA-ALG-0036-surface-diagnostic-shading.md)'s material
is two-sided precisely because extraction publishes open surfaces, so the
interior revealed by a cut is lit rather than black. Uncapped section views are
therefore readable without any additional rule.

What a capped variant would additionally have to settle is recorded in
`ADR-0204` rather than left vague, and it is bounded: the accepted
[`VOXELIA-ALG-0032`](VOXELIA-ALG-0032-triangle-mesh-enclosed-volume.md)
certification is the natural precondition, because a cap is only well defined
for a surface already proven closed and consistently oriented.

## Input domain and admission

The inputs are three vertex world positions in the mesh's **original** vertex
order, three barycentric weights in the coverage rule's canonicalised order
with its swap flag, and an optional `VolumeClipBounds`.

The bounds are the accepted `ADR-0179` value and are composed unchanged: it
already admits only a finite box whose minimum is strictly less than its
maximum on every axis, and already requires its two corners to share one
coordinate space. This record adds one admission the surface path needs and
the volume path did not: the clip's coordinate space must be the scene's world
space, rejected `coordinateSpaceMismatch`.

An **absent** clip retains every fragment. The unclipped path is therefore the
same code with no special case.

## World position

`VOXELIA-ALG-0033` computes each vertex's world position as an intermediate.
`ADR-0204` publishes it, which is additive and changes no registered
`ALG-0033` digest, so this record interpolates a published value rather than
inverting the projection.

```text
w[lane] = ((wA * p0[lane] + wB * p1[lane]) + wC * p2[lane])
```

for each of `x`, `y`, `z`, using the frozen `((a + b) + c)` grouping and the
same original-vertex-order weight mapping `ALG-0036` and `ALG-0037` use,
including the canonicalisation swap flag. A consumer that ignored the flag
would clip the wrong fragments on every mirrored facet, and the registered
`swapped-weights` fixture makes the difference observable.

## The retention test

```text
retained = for every lane:
    w[lane] >= minimum[lane] and w[lane] <= maximum[lane]
```

**The boundary is inclusive.** A fragment exactly on a face, edge or corner is
retained. The box is a closed region; excluding its boundary would discard a
zero-measure set for no benefit, and `VolumeClipBounds` uses strict
inequalities only to reject a degenerate box, not to describe an open region.
The registered `on-near-face`, `on-far-face`, `on-near-corner` and
`on-far-corner` fixtures pin this.

The test is a comparison, not a sign rule: the registered negative-box fixtures
prove a box entirely in negative coordinates behaves identically.

## Precision and representability

IEEE-754 binary64, round-to-nearest-ties-to-even, no fast math, no contraction,
no reassociation.

There is **no representability failure**. A covered sample's barycentric
weights are non-negative and sum to the projected area, so the interpolated
position is a convex combination of three finite world positions and is
therefore bounded by them. The comparisons cannot overflow. As with
`ALG-0035`, an unreachable failure case is not carried.

## Failure precedence and cancellation

```text
coordinateSpaceMismatch
cancelled
```

The space check is per-request and precedes any fragment work. Cancellation is
checked before fragment zero and every fragment ordinal divisible by 4,096,
matching `ALG-0036` and `ALG-0037`.

## Determinism and accelerated conformance

The reference is serial and stateless. An accelerated implementation must
reproduce every interpolated position bit-for-bit and every retention decision
exactly. A shader clip-distance interpolated in a different order does not
conform.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0204-surface-clipping-oracle.py`](../progress/evidence/ADR-0204-surface-clipping-oracle.py).
It records nineteen fixtures: a fragment strictly inside; six fragments outside
on each face of the box; fragments exactly on a near and far face and on a near
and far corner, all retained; three fragments of one straddling facet, of which
only the middle is retained; equal second and third weights making the swap a
no-op; asymmetric weights where the swap changes the position; an absent clip
retaining everything; and a wholly negative box retaining and rejecting
correctly.

The registered output is:

```text
fixtureSHA256=8dd30ec41bd27c11bebb15501739a46398294d86ff6e9956fd7aa1be2976e604
positionSHA256=0f0ee1270ffda5115052a0c370ecaae427ba5e2fbc26bb9e8b47e84b53521335
fixtures=19 successful=19 failures=0
clip=per-fragment-world-box boundary=inclusive capping=absent
geometry=never-cut absentClip=retains-everything
```

## Complexity and exclusions

`O(1)` per fragment.

Capped section views, oriented (non-axis-aligned) clip planes, multiple clip
regions, boolean combinations of regions, clip-region colouring, geometric
clipping that cuts facets, and any published image remain separate contracts.

## References

- [ADR-0179 - Volume clipping](../architecture/decisions/ADR-0179-volume-clipping.md)
- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0204 - Surface clipping design](../architecture/decisions/ADR-0204-surface-clipping-design.md)
- [VOXELIA-ALG-0032 - Triangle-mesh certified enclosed volume](VOXELIA-ALG-0032-triangle-mesh-enclosed-volume.md)
- [VOXELIA-ALG-0033 - Surface vertex orthographic projection](VOXELIA-ALG-0033-surface-vertex-projection.md)
- [VOXELIA-ALG-0036 - Surface diagnostic shading](VOXELIA-ALG-0036-surface-diagnostic-shading.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
