---
document_id: "ADR-0213"
title: "Overlay compositing design"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-NUM-001"
  - "VOX-R2D-002"
  - "VOX-R2D-011"
---

# ADR-0213 - Overlay compositing design

## Context

`ADR-0208` decision 2(e) makes overlay alpha compositing the arc's fifth
increment, governed by `VOX-R2D-011`: "The pipeline shall support segmentation,
mask and image overlays with defined alpha-compositing semantics." It is the
arc's only **P0** row and declares **T** alone.

`ADR-0208` deliberately left one question open: whether overlays extend the
accepted `CompositeLayersOperation` or need their own model. That was to be
decided on evidence, and this record decides it.

## The finding: a separate model, sharing the operator

`VOXELIA-ALG-0009` `layered-linear-blend/binary64-v1` differs from overlay
compositing in three ways:

1. **Alpha is per layer, not per pixel.** An overlay's presence varies pixel by
   pixel; `ALG-0009` carries one opacity for a whole layer.
2. **The background is black.** An overlay composites onto the base image.
3. **It is greyscale.** An overlay is coloured — that is what makes it legible
   against the image it covers, and `ADR-0208` decision 3 sequenced the colour
   vocabulary before this increment for exactly that reason.

Any one of these would be enough; together they are conclusive. So this is a
separate model — but the **per-channel arithmetic is `ALG-0009`'s frozen
sequence, inherited verbatim**, so the two records cannot disagree about what
`over` means. The layer model is not extended; the operator is shared.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0045` defines `overlay-alpha-compositing/binary64-v1`.
2. **Three named overlays reduce to two resolvers and one compositing rule.**
   Segmentation, mask and image overlays differ only in how they *produce* a
   colour and an alpha. Once each is resolved to that pair, one rule composites
   all of them.
3. **A mask is a segmentation with two labels.** Carrying a separate mask model
   would be two places for one rule, and they would drift. The fixtures use a
   two-entry table and nothing else.
4. **A "background" label is an entry whose alpha is zero**, so no background
   convention is invented. This avoids hard-coding label zero, which is a DICOM
   habit rather than a guarantee.
5. **`ALG-0009`'s per-channel sequence is inherited verbatim**, including the
   prohibition on fused multiply-add.
6. **The accumulator is rounded exactly once, at the end.** Rounding between
   overlays would drift, and the registered `single-rounding` fixture pins a
   case where it visibly does: two overlays at opacity `0.3` over a base of
   `10` give `58` with one final rounding and `59` if rounded in between. That
   fixture exists specifically so an implementation that quantises per overlay
   fails rather than looking plausible.
7. **Alpha is normalised by `/255.0` and multiplied by the layer opacity**, in
   one correctly rounded multiplication, composing the accepted `ALG-0023`
   rule. It is straight, not premultiplied, as `ALG-0044` also holds.
8. **An unmapped label is rejected, not clamped.** Clamping is right for a
   palette, where an out-of-range value is a display artefact; here it would
   paint a label nobody assigned a colour to with the last colour in the table
   — a silently wrong overlay on diagnostic imagery. This is the same
   distinction `ADR-0211` drew from the opposite side, and the two records
   disagree deliberately because the inputs mean different things.
9. **The result is opaque.** The base is an opaque display image, so no alpha
   accumulation is needed. Compositing onto a transparent canvas is a separate
   contract.
10. **The failure family is exactly two payload-free cases**, `invalidOpacity`
    and `unmappedLabel`. There is no representability failure: every
    intermediate is a convex combination of values in `[0, 255]`.
11. **There is no cancellation checkpoint**, because one pixel is `O(k)` in its
    overlays. The operation that applies this per pixel owns its own cadence.
12. **Only the `over` operator is defined.** Multiply, screen and the rest are
    presentation choices with no consumer, and each would need its own
    registered evidence.
13. **Stored values are untouched**, so `VOX-R2D-002` and `ADR-0208`
    decision 6 hold without a special rule.
14. **Independent analytical evidence is registered now**: eighteen fixtures,
    fourteen composited and four rejected, with two SHA-256 digests frozen in
    `ALG-0045`.

## Alternatives considered

### Extend `CompositeLayersOperation` and `ALG-0009`

Rejected; see the finding. Widening an accepted greyscale, per-layer-opacity,
black-background model into a coloured, per-pixel-alpha, base-background one is
not a widening — it is a different model wearing the old record's name, and it
would have changed that record's meaning rather than adding to it.

### Carry a separate mask model alongside segmentation

Rejected; see decision 3.

### Treat label zero as the background by convention

Rejected; see decision 4. It is a habit, not a guarantee, and a source is free
to use zero for a real structure.

### Clamp an unmapped label to the nearest entry

Rejected; see decision 8.

### Quantise each overlay to eight bits before the next composites

Rejected; see decision 6. It is the obvious implementation shortcut and it
visibly changes the result.

### Accumulate an output alpha

Rejected; see decision 9. There is no transparent canvas in this pipeline, so
the accumulated alpha would be a value no consumer could use and no fixture
could meaningfully constrain.

### Define additional blend modes now

Rejected; see decision 12.

## Consequences

The migration can implement one bounded, exact reference with no remaining
choice about the resolvers, the operator, the rounding, the alpha or the
failure family. `VOX-R2D-011` — the arc's only P0 row — becomes fully
dischargeable, verification method included, because it declares Test alone.

The deliberate limitations are the `over` operator only, no premultiplied
overlays, no transparent canvas, no overlay resampling, no contour rendering,
and no per-label opacity beyond each entry's own alpha.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the reference to `VoxeliaExecution`, beside the palette and RGB
references. No dependency edge changes.

## Compatibility impact

None in this design-only increment. `CompositeLayersOperation` and `ALG-0009`
are untouched and remain correct for the greyscale layer blend they describe.

## Security impact

No allocation beyond one pixel; errors are payload-free and disclose no
colours, labels or opacities.

## Performance and memory impact

`O(k)` per pixel in the number of overlays.

## Validation impact

The oracle registers:

```text
fixtureSHA256=f91aaecff517a77019e9ec4201555cbdd16784b30f68c447f9d8087d919d3a0b
pixelSHA256=36c48cd8d48defdc25039dffea2936cdcad64a6963de89319aecdabd9e964171
fixtures=18 composited=14 rejected=4
```

Migration must reproduce all eighteen fixtures bit-exactly, prove that a fully
opaque overlay replaces the base exactly and a fully transparent one leaves it
exactly, prove that order matters, **prove the single-rounding case so a
per-overlay quantisation fails**, prove a mask is a two-label segmentation,
prove an unmapped and a negative label are rejected, and prove an out-of-range
and a NaN opacity are rejected.

## Migration

1. Add the overlay compositing reference to `VoxeliaExecution` with every
   fixture from `ALG-0045`.
2. `ADR-0208` increment (f) completes the request and provenance and closes the
   arc.

## Supersession

This record executes `ADR-0208` decision 2(e) and supersedes no accepted
record. It composes `ALG-0009`'s operator without extending its layer model.

## References

- [ADR-0090 - Layer compositing operation](ADR-0090-layer-compositing-operation.md)
- [ADR-0208 - Colour and overlay arc](ADR-0208-colour-and-overlay-arc.md)
- [ADR-0211 - Palette-colour design](ADR-0211-palette-colour-design.md)
- [ADR-0212 - RGB source design](ADR-0212-rgb-source-design.md)
- [VOXELIA-ALG-0009 - Layered linear blend](../../algorithms/VOXELIA-ALG-0009-layered-linear-blend.md)
- [VOXELIA-ALG-0045 - Overlay alpha compositing](../../algorithms/VOXELIA-ALG-0045-overlay-alpha-compositing.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
