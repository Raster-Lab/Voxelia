---
document_id: "VOXELIA-ALG-0037"
title: "Surface scalar colour map binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Surface scalar colour map binary64-v1

## Purpose

This specification defines `surface-scalar-colour-map/binary64-v1`, the
deterministic CPU reference selected by accepted
[`ADR-0203`](../architecture/decisions/ADR-0203-surface-colour-map-design.md).
For one fragment it interpolates the source mesh's scalar attribute, selects a
`TransferFunction1D` entry, applies the shading intensity, and produces the
fragment's colour components and effective opacity.

## The colour representation is composed, not invented

`ADR-0201` and `ADR-0202` both deliberately produced scalars rather than
colours and deferred the colour representation to this record. That deferral
resolves to **composition**: every part of the representation is already
settled by accepted records.

- `TransferFunctionEntry` (`ADR-0083`) is four `UInt8` channels: red, green,
  blue and opacity.
- `VOXELIA-ALG-0023` normalises each by exactly `/ 255.0`.
- Colour is **straight, not premultiplied**: `ALG-0023` multiplies an entry's
  colour by the accumulation weight at composite time, which is only correct
  for unpremultiplied colour.
- `ColourOutputConfiguration.rgba8` (`ADR-0085`) is the accepted output shape.

No colour space is declared by any accepted record, and this record does not
invent one: the channels are the supplied table's own values, and a colour
space is a separate contract for whoever needs to interchange them.

## Input domain and admission

The inputs are three vertex scalars in the mesh's **original** vertex order,
three barycentric weights in the same order, a closed domain
`[minimum, maximum]`, a `TransferFunction1D` table, the shading intensity from
[`VOXELIA-ALG-0036`](VOXELIA-ALG-0036-surface-diagnostic-shading.md) and the
layer opacity.

The domain must be finite with `minimum` **strictly** less than `maximum`; a
degenerate domain is rejected `invalidDomain` rather than dividing by zero.
The table must hold at least one entry, rejected `invalidTable` otherwise.

The interpolated scalar must be finite, rejected `scalarNotRepresentable`
otherwise. Unlike positions, a vertex attribute is raw bytes with no accepted
finiteness guarantee, so this check is real rather than defensive.

## Interpolation

```text
value = ((wA * s0 + wB * s1) + wC * s2)
```

using the same `((a + b) + c)` grouping and the same original-vertex-order
weight mapping `ALG-0036` uses, including the canonicalisation swap flag.

## Entry selection

```text
span       = maximum - minimum
normalised = (value - minimum) / span
scaled     = normalised * (entryCount - 1)
index      = roundHalfAway(scaled)
index      = clamp(index, 0, entryCount - 1)
```

`roundHalfAway` is the round-half-away-from-zero rule accepted by
[`VOXELIA-ALG-0026`](VOXELIA-ALG-0026-segmentation-mask-sampling.md), reused
rather than reinvented.

**Out-of-domain scalars clamp**, and the clamp is what makes the mapping total:
a value below the minimum yields a negative index that clamps to the first
entry, and a value above the maximum clamps to the last. There is deliberately
no separate out-of-domain branch and no out-of-domain failure.

A single-entry table multiplies by zero and therefore selects entry zero for
every scalar, which is correct and needs no special case.

## Shading modulation

```text
red   = (entry.red   * intensity) / 255
green = (entry.green * intensity) / 255
blue  = (entry.blue  * intensity) / 255
alpha = entry.opacity / 255
```

This composes `ALG-0023`'s accepted shaded rule verbatim, including its
central property: **shading modulates colour and never opacity**. A fully
shadowed surface is black but still occludes what is behind it, which is what
makes shading a lighting effect rather than a transparency effect. The
registered `zero-intensity-keeps-opacity` fixture proves it.

## Effective opacity

```text
effectiveOpacity = layerOpacity * alpha
```

Per-object opacity (`VOX-SUR-003`) and per-value opacity (the table entry)
compose by multiplication, in that order. `VOXELIA-ALG-0035` takes this
product as the fragment opacity it weighs; the two records compose rather than
compete. The registered `layer-and-entry-opacity` fixture is a half-opaque
object over a half-opaque entry.

## Precision and representability

IEEE-754 binary64, round-to-nearest-ties-to-even, no fast math, no contraction,
no reassociation. Every displayed operation is one separate correctly rounded
binary64 operation in exactly the order shown.

Overflow is unreachable: the interpolated scalar is admitted finite, the span
is a difference of finite values with `minimum < maximum`, and every colour
operand is a `UInt8` divided by 255. The failure family is therefore entirely
about admission.

## Failure precedence and cancellation

```text
invalidDomain
invalidTable
scalarNotRepresentable
cancelled
```

Domain and table admission precede the scalar check, because they are
per-request while the scalar is per-fragment: a caller with a bad domain
learns so once rather than once per pixel. Cancellation is checked before
fragment zero and every fragment ordinal divisible by 4,096, matching
`ALG-0036`.

## Determinism and accelerated conformance

The reference is serial and stateless. An accelerated implementation must
reproduce every component bit-for-bit; a shader that interpolates in 8-bit or
selects by linear filtering between entries does **not** conform, because
nearest-entry selection is part of the algorithm.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0203-surface-colour-map-oracle.py`](../progress/evidence/ADR-0203-surface-colour-map-oracle.py).
It records sixteen fixtures: the domain minimum and maximum selecting the first
and last entries; a value exactly halfway between entries rounding away; below-
and above-domain scalars clamping; a single-entry table; a fully lit and a
half-lit entry; zero intensity darkening colour while keeping opacity; layer
and entry opacity multiplying; an interpolated scalar and a skewed-weight
selection; a negative domain; and rejections for a degenerate domain, a
non-finite scalar and an empty table.

The registered output is:

```text
fixtureSHA256=1c6b807ea1bc930d00398946db2342476258c799732aeb81492fbd00fe62a63f
colourSHA256=0337dbc24117ac54e875c838ef2703d7813917eefc43ff24f59edaacfd72d506
fixtures=16 successful=13 failures=3
colour=8-bit-straight-rgba normalisation=divide-by-255
selection=nearest-entry-round-half-away outOfDomain=clamped
shading=modulates-colour-never-opacity opacity=layer-times-entry
```

## Complexity and exclusions

`O(1)` per fragment.

Colour spaces and conversion, interpolated (rather than nearest) table lookup,
windowing, multi-channel or vector attributes, per-vertex colour attributes,
isoline or contour overlays, tone mapping and any published image remain
separate contracts.

## References

- [ADR-0083 - Rendering transfer function](../architecture/decisions/ADR-0083-rendering-transfer-function.md)
- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0201 - Surface compositing design](../architecture/decisions/ADR-0201-surface-compositing-design.md)
- [ADR-0202 - Surface shading design](../architecture/decisions/ADR-0202-surface-shading-design.md)
- [ADR-0203 - Surface colour map design](../architecture/decisions/ADR-0203-surface-colour-map-design.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0026 - Segmentation mask sampling](VOXELIA-ALG-0026-segmentation-mask-sampling.md)
- [VOXELIA-ALG-0035 - Surface per-object opacity compositing](VOXELIA-ALG-0035-surface-opacity-compositing.md)
- [VOXELIA-ALG-0036 - Surface diagnostic shading](VOXELIA-ALG-0036-surface-diagnostic-shading.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
