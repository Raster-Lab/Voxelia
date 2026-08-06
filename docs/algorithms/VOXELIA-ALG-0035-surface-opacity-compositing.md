---
document_id: "VOXELIA-ALG-0035"
title: "Surface per-object opacity compositing binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Surface per-object opacity compositing binary64-v1

## Purpose

This specification defines `surface-opacity-compositing/binary64-v1`, the
deterministic CPU reference selected by accepted
[`ADR-0201`](../architecture/decisions/ADR-0201-surface-compositing-design.md).
For one pixel it orders every covering fragment, applies each fragment's
per-object opacity front to back, and produces one **contribution weight** per
fragment plus the accumulated alpha.

**Colour never appears in this model.** A fragment's contribution weight is
fixed by opacity and order alone, so shading and colour mapping multiply into
these weights later without changing them. That separation is why this
increment can be frozen before any material or colour-map contract exists.

## Fragment retention

[`VOXELIA-ALG-0034`](VOXELIA-ALG-0034-surface-visibility-resolution.md) retains
only the single nearest facet per pixel, which is sufficient for an opaque
scene and for picking but cannot express transparency. This model therefore
consumes **all** covering fragments at a pixel, retained by the same coverage,
canonicalisation and fill rules `ALG-0034` froze.

`ALG-0034` is not superseded. Its nearest-only buffer remains the correct and
cheaper answer whenever every layer is fully opaque, and it is what an
authoritative picking contract will consume.

A fragment carries the depth, barycentric weights, layer index and facet
ordinal `ALG-0034` already defines, plus its layer's opacity.

## The frozen order

Fragments at one pixel are ordered ascending by the triple:

```text
(depth, layerIndex, facetOrdinal)
```

This is a **strict total order**: one facet covers a pixel at most once, so
`(layerIndex, facetOrdinal)` is unique among a pixel's fragments and the triple
can never tie. No arbitrary winner can arise, and no secondary rule is needed.

The order is deliberately consistent with `ALG-0034`'s nearest-surface
resolution, whose strict-less comparison keeps the earlier `(layer, facet)` at
equal depth. An opaque scene composited by this model therefore selects exactly
the fragment `ALG-0034` would have selected.

Supply order is irrelevant: the registered `reverse-supplied` fixture proves
fragments handed over farthest-first produce identical output.

## Front-to-back accumulation

The accumulator begins at positive binary64 zero. For each fragment in the
frozen order:

```text
remaining     = 1 - accumulatedAlpha
contribution  = opacity * remaining
accumulatedAlpha = accumulatedAlpha + contribution
```

Every displayed subtraction, multiplication and addition is one separate
correctly rounded binary64 operation in exactly that order. No fused
multiply-add, reassociation or compensated accumulation is permitted.

This composes the front-to-back principle
[`VOXELIA-ALG-0023`](VOXELIA-ALG-0023-front-to-back-compositing.md) froze for
volume samples along one ray. It is stated here rather than referenced as an
operation because the domain differs: `ALG-0023` orders samples along a single
ray by construction and never has to decide between distinct objects, which is
exactly the gap this model closes.

## Occlusion and saturation

Occlusion is not a special case. A fully opaque fragment makes
`accumulatedAlpha` exactly one, so every later `remaining` is exactly
`1 - 1 = 0` and every later contribution is exactly `opacity * 0 = 0`.

An implementation **may** stop iterating once `accumulatedAlpha` equals one,
because doing so is bit-identical to continuing: the remaining contributions
are exactly positive zero and leave the accumulator unchanged. The registered
`saturating` fixture proves it.

## Zero opacity

A fragment whose layer opacity is zero is **retained** and weighs exactly zero.
Dropping it would make the published fragment list depend on a presentation
parameter, so a caller could not reason about coverage independently of
appearance.

## Precision and representability

IEEE-754 binary64, round-to-nearest-ties-to-even, gradual subnormals, no fast
math, no flush-to-zero, no contraction, no reassociation.

There is deliberately **no representability failure** in this model, and that is
a proven property rather than an assumption. `SurfaceLayer` admits only a
finite opacity in `[0, 1]`, and the accumulator starts at zero, so every
intermediate lies in `[0, 1]`: `remaining` is a difference of two values in
`[0, 1]`, `contribution` is a product of two values in `[0, 1]`, and the sum is
bounded by one. Infinity is unreachable and NaN would require `0 * infinity` or
`infinity - infinity`, neither of which can occur. The registered `long-chain`
fixture composites twenty-four fragments and asserts at every step that the
contribution is non-negative and the accumulator never exceeds one.

Carrying an unreachable failure case would be an error case with no possible
evidence, which this project does not do.

## Failure precedence and cancellation

```text
resourceLimitExceeded
cancelled
```

Both are reachable. `resourceLimitExceeded` governs the retained fragment
payload, which — unlike `ALG-0034`'s one record per pixel — scales with scene
depth complexity and is unbounded by the viewport alone. Cancellation is
checked before facet zero and every facet ordinal divisible by 64 during
retention, matching `ALG-0034`, and before pixel zero and every pixel ordinal
divisible by 4,096 during accumulation.

An uncovered pixel composites to no fragments at accumulated alpha positive
zero, which is not a failure.

## Determinism and accelerated conformance

The reference is serial and stateless. Identical fragments and opacities
produce identical contribution weights and accumulated alpha. An accelerated
implementation must reproduce every weight bit-for-bit; order-independent
transparency approximations do **not** conform, and a GPU blend performed in a
completion-determined order conforms only if it first applies this exact
ordering.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0201-surface-compositing-oracle.py`](../progress/evidence/ADR-0201-surface-compositing-oracle.py).
It records twelve fixtures:

- one fully opaque fragment contributing everything;
- one half-opaque fragment contributing exactly one half;
- two half-opaque fragments contributing one half then one quarter;
- a nearer opaque fragment leaving a farther one exactly zero;
- fragments supplied farthest-first producing identical output;
- equal depth resolved by layer index;
- equal depth and layer resolved by facet ordinal;
- a zero-opacity fragment retained at exactly zero weight;
- a twenty-four fragment chain whose accumulator never exceeds one;
- a saturating chain whose post-saturation weights are all exactly zero;
- an uncovered pixel at accumulated alpha positive zero; and
- a repeating non-representable opacity exercising ordinary rounding.

The registered output is:

```text
fixtureSHA256=43c71d094dcf0cb932d9789c6f5f8fafa254bb715ccf73d65111ef1c58611dc5
weightSHA256=860a28e69c4b797acaad62fb311a7ad60df96973eb8aa8a1773fd7fcd56a91d0
fixtures=12 successful=12 failures=0
order=depth,layer,facet blend=front-to-back opacity=per-object
zeroOpacity=retained alphaBound=one colour=absent
```

Swift conformance is bit-exact for every contribution weight and accumulated
alpha, and exact for ordering, retention and checkpoint order.

## Complexity and exclusions

`O(f log f)` per pixel for the ordering plus `O(f)` accumulation, where `f` is
that pixel's fragment count, and one record per retained fragment of governed
payload.

Colour, shading, materials, colour maps, premultiplied or non-premultiplied
colour conventions, colour-space handling, order-independent transparency
approximations, depth peeling, clipping, picking and any published image
remain separate contracts.

## References

- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](../architecture/decisions/ADR-0198-surface-scene-vocabulary.md)
- [ADR-0200 - Surface visibility design](../architecture/decisions/ADR-0200-surface-visibility-design.md)
- [ADR-0201 - Surface compositing design](../architecture/decisions/ADR-0201-surface-compositing-design.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
