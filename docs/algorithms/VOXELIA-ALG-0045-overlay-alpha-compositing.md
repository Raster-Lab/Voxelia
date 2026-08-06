---
document_id: "VOXELIA-ALG-0045"
title: "Overlay alpha compositing binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Overlay alpha compositing binary64-v1

## Purpose

This specification defines `overlay-alpha-compositing/binary64-v1`, the
deterministic reference selected by accepted
[`ADR-0213`](../architecture/decisions/ADR-0213-overlay-compositing-design.md).
It composites an ordered list of overlays onto one base display pixel.

## Three named overlays, two resolvers, one compositing rule

`VOX-R2D-011` names segmentation, mask and image overlays. They differ only in
how they **produce** a colour and an alpha; the compositing itself is one rule.

- A **mask is a segmentation with two labels.** Carrying a separate mask model
  would be two places for one rule, and they would drift. The registered
  `mask-absent` and `mask-present` fixtures use a two-entry table and nothing
  else.
- A **segmentation** resolves its label through a table of straight-alpha RGBA
  entries. A "background" label is simply an entry whose alpha is zero, so no
  background convention is invented.
- An **image overlay** supplies its own straight-alpha RGBA per pixel.

## The operator is `ALG-0009`'s, inherited verbatim

The per-channel sequence is exactly the one
[`VOXELIA-ALG-0009`](VOXELIA-ALG-0009-layered-linear-blend.md) froze:

```text
t   = 1 - a                (binary64 subtraction)
p   = acc * t              (binary64 multiplication)
q   = x * a                (binary64 multiplication)
acc = p + q                (binary64 addition)
```

evaluated in exactly this order, correctly rounded, with **no fused
multiply-add** — fusing changes the rounding count.

What differs from `ALG-0009` is not the operator but the model around it, in
three ways that made a separate record necessary rather than an extension:

1. **Alpha is per pixel**, resolved from the overlay, where `ALG-0009` carries
   one opacity per layer.
2. **The background is the base image**, where `ALG-0009` starts from black.
3. **Colour is present**: three channels, where `ALG-0009` is greyscale.

Any one of these would have been enough; together they are conclusive. The
arithmetic is nevertheless shared, so the two records cannot disagree about
what `over` means.

## The frozen rule

```text
for each overlay in declared order:
    reject an opacity outside [0, 1] or not a number
    resolve (colour, entryAlpha):
        label kind -> table[label], rejecting an unmapped label
        image kind -> the supplied RGBA
    a = (entryAlpha / 255.0) * opacity
    for each of the three channels:
        acc = acc * (1 - a) + colour * a      [ALG-0009's ordered sequence]

output = (clamp(roundTiesToEven(acc), 0, 255) per channel, alpha 255)
```

## The accumulator is rounded exactly once

It stays binary64 across every overlay and is quantised only at the end.
Rounding between overlays would drift, and the registered `single-rounding`
fixture pins a case where it visibly does: two overlays at opacity `0.3` over a
base of `10` give `58` with one final rounding and `59` if rounded in between.

## Alpha normalisation and multiplication

An entry's alpha is normalised by `/255.0` — the accepted rule
[`VOXELIA-ALG-0023`](VOXELIA-ALG-0023-front-to-back-compositing.md) uses — and
then multiplied by the layer opacity in one correctly rounded multiplication.
Alpha is **straight, not premultiplied**, composing the same accepted
representation as
[`VOXELIA-ALG-0044`](VOXELIA-ALG-0044-rgb-source-presentation.md).

## An unmapped label is rejected, not clamped

Clamping is the right rule for a palette, where an out-of-range value is a
display artefact. Here it would paint a label nobody assigned a colour to with
the last colour in the table — a silently wrong overlay on diagnostic imagery.
The registered `unmapped-label` and `negative-label` fixtures pin both
directions.

## The result is opaque

The base is an opaque display image, so the composited result is opaque and no
alpha accumulation is needed. Compositing onto a transparent canvas is a
separate contract.

## Determinism and failure classification

The composite is a pure function of the base, the overlays and their order. The
failure family is exactly two payload-free cases, `invalidOpacity` and
`unmappedLabel`. There is no representability failure: every intermediate is a
convex combination of values in `[0, 255]`, so the clamp is reachable only
through rounding at the interval edges, exactly as `ALG-0009` records. There is
no cancellation checkpoint, because one pixel is `O(k)` in its overlays.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0213-overlay-compositing-oracle.py`](../progress/evidence/ADR-0213-overlay-compositing-oracle.py).
It records eighteen fixtures: fully opaque, fully transparent and half-alpha
overlays; the same two overlays in both orders; the single-rounding case; mask
absent and present; a segmentation label and its zero-alpha background; a
translucent image overlay at two opacities; both clamp ends; an unmapped and a
negative label; and an out-of-range and a NaN opacity.

The registered output is:

```text
fixtureSHA256=f91aaecff517a77019e9ec4201555cbdd16784b30f68c447f9d8087d919d3a0b
pixelSHA256=36c48cd8d48defdc25039dffea2936cdcad64a6963de89319aecdabd9e964171
fixtures=18 composited=14 rejected=4
operator=alg-0009-verbatim background=base-image alpha=straight
mask=two-label-segmentation unmappedLabel=rejected rounding=once
```

## Complexity and exclusions

`O(k)` per pixel in the number of overlays.

Blend modes other than `over`, premultiplied overlays, compositing onto a
transparent canvas, overlay resampling to the base grid, outline or contour
rendering of a segmentation, per-label opacity beyond the entry's own alpha,
and any published artefact remain separate contracts.

## References

- [ADR-0090 - Layer compositing operation](../architecture/decisions/ADR-0090-layer-compositing-operation.md)
- [ADR-0208 - Colour and overlay arc](../architecture/decisions/ADR-0208-colour-and-overlay-arc.md)
- [ADR-0213 - Overlay compositing design](../architecture/decisions/ADR-0213-overlay-compositing-design.md)
- [VOXELIA-ALG-0009 - Layered linear blend](VOXELIA-ALG-0009-layered-linear-blend.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0044 - RGB source presentation](VOXELIA-ALG-0044-rgb-source-presentation.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
