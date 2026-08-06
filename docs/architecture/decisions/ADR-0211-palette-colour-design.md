---
document_id: "ADR-0211"
title: "Palette-colour design"
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
  - "VOX-R2D-010"
---

# ADR-0211 - Palette-colour design

## Context

`ADR-0208` decision 2(c) makes palette-colour presentation the arc's third
increment, serving the first half of `VOX-R2D-010`: "The pipeline shall support
palette-colour and RGB presentation through explicit colour transforms." The row
declares **T** alone. RGB source presentation is increment (d).

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0043` defines `palette-colour-mapping/v1`.
2. **This model introduces no new rounding rule, and that is a finding worth
   stating.** A palette indexes a **stored integer**, so the index derivation is
   `ALG-0004`'s clamped subtraction verbatim. The round-half-away rule
   `ALG-0042` had to freeze one increment ago exists only to handle a fractional
   input, and this stage cannot receive one. Reaching for it here out of
   symmetry would have added a rounding step to a value that needs none.
3. **Channel quantisation reuses the accepted display-output rule** — round ties
   to even, then clamp — because that is the same job `ALG-0002` and `ALG-0042`
   already do. Same job, same rule; the previous increment's split was between
   *different* jobs, not a licence to pick freely.
4. **The three tables must share one first-mapped value and one entry count.**
   Three differently shaped tables would mean three different index derivations
   for one pixel, so a red channel could come from a different stored value than
   its own green. That is a silently wrong colour, and this record makes it a
   detected error instead.
5. **Alpha is exactly opaque.** A palette-colour image is an image, not an
   overlay. Per-object opacity is a separate accepted contract, and giving the
   palette a transparency of its own would give it a second meaning no source
   supplies. A fixture pins alpha at `255` even where every colour channel is
   zero.
6. **Palette entries are display values and are clamped, never rescaled.**
   Rescaling would rewrite a palette the source author already calibrated.
7. **Sixteen-bit palette entries are out of scope, and the reason is recorded
   rather than left as an omission.** Reducing sixteen-bit entries to eight is a
   real decision — high byte, or scale, and they differ — with no consumer to
   settle it. A source whose entries are not already display values must be
   converted by its adapter, which is where the source's own bit depth is known.
8. **A scalar image is not palette-colour merely by being scalar.** The palette
   must be supplied; supplying one *is* the explicit colour transform
   `VOX-R2D-010` asks for. `ADR-0208` decision 7's rule — never relabel a
   monochrome source — is therefore honoured **structurally**: with no palette
   there is no palette path, and no inference exists to get wrong.
9. **The failure family is exactly two payload-free cases**, `emptyTable` and
   `paletteShapeMismatch`. There is **no representability failure**: the input
   is an integer and `LookupTableDescriptor` validates every entry finite.
10. **There is no cancellation checkpoint**, because one pixel is `O(1)`. The
    operation that applies this per sample owns its own cadence.
11. **Stored values are untouched**, so `VOX-R2D-002` and `ADR-0208` decision 6
    hold without a special rule.
12. **Independent analytical evidence is registered now**: fifteen fixtures,
    twelve mapped and three rejected, with two SHA-256 digests frozen in
    `ALG-0043`.

## Alternatives considered

### Reuse `ALG-0042`'s round-half-away index rule for symmetry

Rejected; see decision 2. The input is an integer, so the rounding step would
be a no-op dressed as a rule — and a reader would reasonably infer that a
fractional palette index is meaningful, which it is not.

### Accept three independently shaped tables and reconcile them

Rejected; see decision 4. Any reconciliation — union, intersection, shortest —
silently produces a colour no source specified.

### Give palette entries an alpha channel

Rejected; see decision 5. No source supplies one, and per-object opacity
already exists as its own contract.

### Scale sixteen-bit entries into the eight-bit range here

Rejected; see decision 7. The choice between taking the high byte and scaling is
real and consumer-dependent, and this stage does not know the source's bit
depth.

### Infer palette-colour presentation from a scalar image

Rejected; see decision 8. It is precisely the relabelling `ADR-0208` forbids.

## Consequences

The migration can implement one bounded, exact reference with no remaining
choice about the index rule, the shape check, the quantisation, the alpha or the
failure family. The first half of `VOX-R2D-010` becomes dischargeable; the row
closes when increment (d) adds RGB source presentation.

The deliberate limitations are eight-bit display entries only, no segmented or
supplemental palettes, no palette transparency, and no colour-space conversion
of entries.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the reference to `VoxeliaExecution`, beside the VOI lookup. No
dependency edge changes.

## Compatibility impact

None in this design-only increment.

## Security impact

No allocation beyond one pixel; errors are payload-free and disclose no values,
entries or indices.

## Performance and memory impact

`O(1)` per sample.

## Validation impact

The oracle registers:

```text
fixtureSHA256=76d9f8943c52f28b7156ab69c2dd9000e7dc137d526f597ba87a9756fa6a2e65
channelSHA256=98d9464166ab8c01ac5c266b4d29ea56684e1b2b7d38504d9c073de715105160
fixtures=15 mapped=12 rejected=3
```

Migration must reproduce all fifteen fixtures bit-exactly, prove each channel is
indexed from its own table so a swap would fail, prove alpha is opaque even at
an all-zero entry, prove both clamp ends and both signed-integer origin
extremes, prove both shape mismatches are rejected, and prove the quantisation
ties.

## Migration

1. Add the palette reference to `VoxeliaExecution` with every fixture from
   `ALG-0043`.
2. `ADR-0208` increment (d) designs RGB source presentation.

## Supersession

This record executes `ADR-0208` decision 2(c) and supersedes no accepted record.

## References

- [ADR-0069 - Lookup-table composition](ADR-0069-lookup-table-composition.md)
- [ADR-0208 - Colour and overlay arc](ADR-0208-colour-and-overlay-arc.md)
- [ADR-0209 - Display colour vocabulary](ADR-0209-display-colour-vocabulary.md)
- [ADR-0210 - VOI lookup design](ADR-0210-voi-lookup-design.md)
- [VOXELIA-ALG-0004 - Lookup-table stored-to-real value mapping](../../algorithms/VOXELIA-ALG-0004-lookup-table-value-transform.md)
- [VOXELIA-ALG-0042 - VOI lookup display mapping](../../algorithms/VOXELIA-ALG-0042-voi-lookup-mapping.md)
- [VOXELIA-ALG-0043 - Palette-colour display mapping](../../algorithms/VOXELIA-ALG-0043-palette-colour-mapping.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
