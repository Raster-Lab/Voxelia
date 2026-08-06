---
document_id: "ADR-0212"
title: "RGB source design"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-R2D-002"
  - "VOX-R2D-010"
---

# ADR-0212 - RGB source design

## Context

`ADR-0208` decision 2(d) makes RGB source presentation the arc's fourth
increment, completing `VOX-R2D-010`: "The pipeline shall support palette-colour
and RGB presentation through explicit colour transforms." `ADR-0211` discharged
the palette half. The row declares **T** alone, so this increment closes it.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0044` defines `rgb-source-presentation/v1`.
2. **There is no arithmetic, and the record says so rather than manufacturing
   a rule.** An eight-bit RGB source already holds display values in the output
   representation, so presenting it is a byte pass-through. A normalisation, a
   gamma or a rescale would invent a transform the source never asked for and
   would silently alter data its author calibrated. `ADR-0211` reached the same
   kind of finding for the palette index; this is the stronger version of it.
3. **"Explicit colour transform" is therefore a statement about declaration,
   not about work.** The transform is the identity, and what `VOX-R2D-010`
   requires is that it be *named* in the request and the provenance rather than
   assumed. Increment (f) carries that naming; `ADR-0209`'s
   `DisplayColourTransform` is the vocabulary it will widen.
4. **A source with no alpha channel is opaque; a source with one keeps it
   unchanged.** This is the single place this model differs from the palette
   rule, and the difference is principled: a palette has no alpha to carry,
   whereas an RGBA source does, and overwriting it would discard what the source
   said. A fully transparent source is fixtured to pin that.
5. **Alpha is straight, not premultiplied**, composing the accepted
   representation `ALG-0023` uses. A premultiplied source must be converted by
   its adapter, where the source's own convention is known.
6. **The photometric relabelling question is discharged one level up, and this
   record restates none of it.** `ImageDescriptor` already binds `.rgb` and
   `.rgba` to the `.colour` semantic and rejects the mismatch in both
   directions, so a monochrome source cannot arrive claiming to be colour.
   `ADR-0208` decision 7 is therefore already enforced structurally, by an
   admission that predates this arc.
7. **Being *called* with a non-colour interpretation is still rejected typed.**
   The reference is a function any caller can invoke with any image, so the
   case is reachable and gets a typed answer rather than a boundary that does
   not exist yet. The alternative — a two-case layout parameter making the
   state unrepresentable — was rejected because it would push the decision onto
   an operation this increment does not build.
8. **Eight bits only.** A wider channel is rejected rather than silently
   reduced, because reducing sixteen bits to eight is a real choice between
   taking the high byte and scaling, with no consumer to settle it. This is
   `ADR-0211` decision 7 applied consistently rather than a new judgement.
9. **The failure family is exactly three payload-free cases**:
   `unsupportedInterpretation`, `unsupportedSampleType` and
   `channelCountMismatch`. There is no representability failure, because no
   arithmetic occurs.
10. **No value-domain operation may be applied to an RGB source.** Window and
    level, VOI lookup, display inversion and palette mapping are all scalar
    value-domain models; an RGB source has no single value for them to act on.
    The existing operations already require `.scalar`, so this is a
    consequence to record rather than a check to add.
11. **Stored values are untouched**, so `VOX-R2D-002` and `ADR-0208`
    decision 6 hold without a special rule.
12. **Independent analytical evidence is registered now**: twelve fixtures, six
    presented and six rejected, with two SHA-256 digests frozen in `ALG-0044`.

## Alternatives considered

### Normalise or gamma-correct RGB channels on presentation

Rejected; see decision 2. It would alter calibrated data under the banner of a
transform nobody requested, and no accepted record characterises the source's
transfer function well enough to justify one.

### Force alpha opaque for RGBA sources, matching the palette rule

Rejected; see decision 4. Consistency with the palette is the weaker argument;
not discarding what the source supplied is the stronger one.

### Take a two-case layout parameter so a non-colour source is unrepresentable

Rejected; see decision 7.

### Reduce sixteen-bit channels to eight here

Rejected; see decision 8.

### Treat `VOX-R2D-010` as already satisfied because `ImageDescriptor` admits `.rgb`

Rejected. Admitting a descriptor is not presenting a pixel: nothing in the
pipeline turned an RGB source into display output, and no transform was ever
declared. The requirement asks for presentation through an explicit transform,
and an admission is neither.

## Consequences

`VOX-R2D-010` is discharged in both halves once this migration is green:
palette-colour by `ADR-0211` and RGB by this record. Verification method
included, because the row declares Test alone.

The deliberate limitations are eight-bit channels only, no premultiplied
sources, no planar or chroma-subsampled layouts, no non-RGB colour model, and
no colour-space conversion.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the reference to `VoxeliaExecution`, beside the palette mapping.
No dependency edge changes.

## Compatibility impact

None in this design-only increment.

## Security impact

No allocation beyond one pixel; errors are payload-free and disclose no channel
values or counts.

## Performance and memory impact

`O(1)` per sample.

## Validation impact

The oracle registers:

```text
fixtureSHA256=6115cfd287cc8bd9c7cbebb79d697d198bb8d64306b1375ccbfdca003e9cb0f2
channelSHA256=9a039575cea559af60aba8c8cdc87891205e6d04b50ab0a17df371594b9d46a4
fixtures=12 presented=6 rejected=6
```

Migration must reproduce all twelve fixtures bit-exactly, prove the channel
order so a swap would fail, prove that an RGB source becomes opaque while an
RGBA source keeps even a fully transparent alpha, prove a non-colour
interpretation and a wider sample type are rejected typed, and prove all three
channel-count mismatches.

## Migration

1. Add the RGB source reference to `VoxeliaExecution` with every fixture from
   `ALG-0044`.
2. `ADR-0208` increment (e) designs overlay alpha compositing.

## Supersession

This record executes `ADR-0208` decision 2(d) and supersedes no accepted record.

## References

- [ADR-0208 - Colour and overlay arc](ADR-0208-colour-and-overlay-arc.md)
- [ADR-0209 - Display colour vocabulary](ADR-0209-display-colour-vocabulary.md)
- [ADR-0211 - Palette-colour design](ADR-0211-palette-colour-design.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0043 - Palette-colour display mapping](../../algorithms/VOXELIA-ALG-0043-palette-colour-mapping.md)
- [VOXELIA-ALG-0044 - RGB source presentation](../../algorithms/VOXELIA-ALG-0044-rgb-source-presentation.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
