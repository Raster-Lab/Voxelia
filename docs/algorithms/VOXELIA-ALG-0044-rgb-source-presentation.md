---
document_id: "VOXELIA-ALG-0044"
title: "RGB source presentation v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# RGB source presentation v1

## Purpose

This specification defines `rgb-source-presentation/v1`, the deterministic
reference selected by accepted
[`ADR-0212`](../architecture/decisions/ADR-0212-rgb-source-design.md). It
presents one sample of an eight-bit RGB or RGBA source as a straight-alpha RGBA
display pixel.

## There is no arithmetic here, and that is the finding

An eight-bit RGB source already holds display values in the output
representation, so presenting it is a **byte pass-through**. This specification
therefore freezes a layout and an admission, not a computation. Manufacturing a
numeric step — a normalisation, a gamma, a rescale — would invent a transform
the source never asked for and would silently alter data the author calibrated.

That makes the explicit-transform requirement a statement about **declaration**
rather than about work: the transform is the identity, and what matters is that
it is named in the request and the provenance rather than assumed.

## The frozen rule

```text
1. reject an interpretation that is neither rgb nor rgba
2. reject a sample type other than uint8
3. reject a channel count that does not match the interpretation
4. rgb  -> (r, g, b, 255)
   rgba -> (r, g, b, a)
```

## Alpha

A source with no alpha channel is **opaque**, exactly as
[`VOXELIA-ALG-0043`](VOXELIA-ALG-0043-palette-colour-mapping.md) makes a palette
pixel opaque, and for the same reason: an image is not an overlay.

A source *with* an alpha channel has it passed through **unchanged**, including
a fully transparent one. This is the one place the two models differ, and the
registered `rgba-transparent` fixture pins it: a palette has no alpha to carry,
whereas an RGBA source does and it would be wrong to overwrite it.

The alpha is interpreted as **straight, not premultiplied**, which is the
accepted representation
[`VOXELIA-ALG-0023`](VOXELIA-ALG-0023-front-to-back-compositing.md) uses. A
premultiplied source must be converted by its adapter, where the source's own
convention is known.

## The relabelling question is discharged one level up

`ImageDescriptor` already binds `.rgb` and `.rgba` to the `.colour` semantic and
rejects the mismatch **in both directions**, so a monochrome source cannot
arrive here claiming to be colour, and a colour source cannot arrive claiming to
be anything else. This model restates none of that; the descriptor's own
admission discharges it.

What this model does reject is being *called* with a non-colour interpretation,
because it is a function a caller can invoke with any image. The registered
`scalar-source` and `vector-source` fixtures pin the typed answer.

## Eight bits only

A wider channel is rejected rather than silently reduced. Reducing sixteen bits
to eight is a real choice between taking the high byte and scaling, with no
consumer to settle it — the same reason `ALG-0043` excludes sixteen-bit palette
entries, applied consistently.

## Determinism and failure classification

The mapping is a pure function of the interpretation, the sample type and the
channel bytes. The failure family is exactly three payload-free cases:
`unsupportedInterpretation`, `unsupportedSampleType` and `channelCountMismatch`.
There is no representability failure, because no arithmetic occurs, and no
cancellation checkpoint, because one sample is `O(1)`.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0212-rgb-source-oracle.py`](../progress/evidence/ADR-0212-rgb-source-oracle.py).
It records twelve fixtures: an RGB pass-through; an RGBA pass-through; a fully
transparent RGBA source; the channel order; the eight-bit extremes; a fully
opaque maximum; two non-colour interpretations; a wider sample type; and all
three channel-count mismatches.

The registered output is:

```text
fixtureSHA256=6115cfd287cc8bd9c7cbebb79d697d198bb8d64306b1375ccbfdca003e9cb0f2
channelSHA256=9a039575cea559af60aba8c8cdc87891205e6d04b50ab0a17df371594b9d46a4
fixtures=12 presented=6 rejected=6
transform=byte-pass-through arithmetic=none alpha=straight
rgbAlpha=opaque rgbaAlpha=preserved sampleType=uint8-only
```

## Complexity and exclusions

`O(1)` per sample.

Sixteen-bit and floating-point colour channels, premultiplied sources, planar
channel layouts, chroma-subsampled sources, YCbCr and any other non-RGB colour
model, ICC or other colour-space conversion, and any published artefact remain
separate contracts.

## References

- [ADR-0208 - Colour and overlay arc](../architecture/decisions/ADR-0208-colour-and-overlay-arc.md)
- [ADR-0212 - RGB source design](../architecture/decisions/ADR-0212-rgb-source-design.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0043 - Palette-colour display mapping](VOXELIA-ALG-0043-palette-colour-mapping.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
