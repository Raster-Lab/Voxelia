---
document_id: "VOXELIA-ALG-0025"
title: "Gradient lighting binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Gradient lighting binary64-v1

## Purpose

This specification defines the versioned reference model
`gradient-lighting/binary64-v1` selected by accepted
[`ADR-0176`](../architecture/decisions/ADR-0176-gradient-lighting-design.md)
— gradient estimation and lighting for direct volume rendering, per
`VOX-DVR-008`. Everything this model shades is presentation, never a
source of authoritative quantitative measurement, per the arc's
binding rule.

## Model

**Gradient.** At a sample's index position `c`, the index-space
central difference per axis uses the accepted trilinear sample at
unit index offsets, each operation correctly rounded:

```text
g_index[k] = (S(c + e_k) - S(c - e_k)) / 2
```

where `S` is the accepted `VOXELIA-ALG-0017` sample byte converted
to binary64 and `e_k` the unit offset along image axis `k`. The
world-space gradient applies the chain rule through the accepted
inverse — the transpose composition, referenced never re-derived:

```text
g_world[r] = sum over s of inverse[3*s + r] * g_index[s]
```

in ascending `s` with left-to-right accumulation. This is exact
composition: the claimed spacing and shear are absorbed by the
accepted inverse, so no separate per-axis spacing division exists.

**Lighting.** The version-one model is the headlight Lambert form
with the ambient floor declared exactly one quarter:

```text
n       = normalize(-g_world)        (ALG-0010 norm form)
L       = -unitRayDirection          (the accepted sampler's
                                      normalised direction, negated)
diffuse = max(0, dot(n, L))          (ALG-0014 dot form)
factor  = 1/4 + ((1 - 1/4) * diffuse)
```

A zero-magnitude world gradient — a flat region with no surface —
uses factor exactly one: the colour is unchanged, because shading a
surface that does not exist would fabricate one, and `normalize`
of zero is undefined. The factor modulates each colour component
before the accepted compositing conversion:

```text
shaded = component * factor
```

with opacity unmodulated — lighting changes appearance, never
coverage. The closed lighting vocabulary is `none` and `headlight`;
`none` composites the accepted unshaded model unchanged, and
positionable lights arrive with their own records.

## Determinism and failure classification

The shaded composite is a pure function of the samples, geometry,
ray and mode: repeated evaluation is bit-identical. Admission
belongs to the consuming surfaces; no branch of the model itself can
fail for admitted inputs.

## Conformance fixtures

Independently computed:

- The linear field `8·i0` on identity geometry has index gradient
  exactly `(8, 0, 0)` at every interior sample, world gradient the
  same, and normal exactly `(-1, 0, 0)`.
- A ray along `(1, 0, 0)` faces the normal head-on: diffuse exactly
  `1`, factor exactly `1`.
- A ray along `(0, 0, 1)` grazes: diffuse exactly `0`, factor
  exactly `1/4`.
- The forty-five-degree ray `(1, 0, 1)` normalised gives the frozen
  diffuse `0.7071067811865475` and factor `0.7803300858899106`; a
  single opaque sample of table red two hundred shades to the output
  byte `156`.
- The diagonal spacing-two geometry scales the world gradient to
  `(4, 0, 0)` and the normal, diffuse and factor are unchanged —
  normalisation absorbs the calibration's magnitude.
- A zero gradient leaves every component byte unchanged.

## Validation obligations

The implementing increment must reproduce every fixture exactly,
prove bit-identical repetition, prove the unshaded mode composites
byte-identically to the accepted unshaded model, and prove opacity
is never modulated.

## References

- [ADR-0176 - Gradient lighting design](../architecture/decisions/ADR-0176-gradient-lighting-design.md)
- [VOXELIA-ALG-0016 - Affine spatial inverse binary64-v1](VOXELIA-ALG-0016-affine-inverse.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling binary64-v1](VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing binary64-v1](VOXELIA-ALG-0023-front-to-back-compositing.md)
