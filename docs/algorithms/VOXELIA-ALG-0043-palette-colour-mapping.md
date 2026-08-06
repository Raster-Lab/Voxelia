---
document_id: "VOXELIA-ALG-0043"
title: "Palette-colour display mapping v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Palette-colour display mapping v1

## Purpose

This specification defines `palette-colour-mapping/v1`, the deterministic
reference selected by accepted
[`ADR-0211`](../architecture/decisions/ADR-0211-palette-colour-design.md). It
maps one stored integer sample through three palette tables to an eight-bit
straight-alpha RGBA display pixel.

## This model introduces no new rounding rule

A palette indexes a **stored integer**, not a transformed real value. The index
derivation is therefore
[`VOXELIA-ALG-0004`](VOXELIA-ALG-0004-lookup-table-value-transform.md)'s clamped
subtraction verbatim, and nothing here needs the round-half-away rule
[`VOXELIA-ALG-0042`](VOXELIA-ALG-0042-voi-lookup-mapping.md) had to freeze for
the VOI stage — because that rule exists only to handle a fractional input this
stage cannot receive.

Channel quantisation reuses the accepted display-output rule instead:
round ties to even, then clamp, exactly as
[`VOXELIA-ALG-0002`](VOXELIA-ALG-0002-window-level-linear.md) and `ALG-0042` do.
Same job, same rule.

## The frozen rule

```text
1. reject an empty table in any channel
2. reject unless all three tables share one first-mapped value and one entry
   count
3. index = clamp(storedValue - firstMappedValue, 0, n - 1)
4. red   = clamp(roundTiesToEven(redValues[index]),   0, 255)
   green = clamp(roundTiesToEven(greenValues[index]), 0, 255)
   blue  = clamp(roundTiesToEven(blueValues[index]),  0, 255)
   alpha = 255
```

## The three tables must agree

Three differently shaped tables would mean three different index derivations for
one pixel, so a red channel could come from a different stored value than its
own green — a silently wrong colour rather than a detected error. The registered
`count-mismatch` and `origin-mismatch` fixtures reject both ways of disagreeing.

Each channel is otherwise indexed from its own table independently, and the
registered `red-entry`, `green-entry` and `blue-entry` fixtures would all change
if any two channels were swapped.

## Alpha is exactly opaque

A palette-colour image is an **image**, not an overlay. Per-object opacity is a
separate accepted contract, and giving the palette a transparency of its own
would give it a second meaning that no source supplies. The registered
`first-entry` fixture pins alpha at `255` even where every colour channel is
zero.

## Entries are display values

The tables hold display values, so nothing is normalised: an entry outside
`0...255` saturates. Rescaling entries would rewrite a palette the source author
already calibrated. The registered `output-clamp-and-tie-down` and
`output-ties-even` fixtures pin the clamp at both ends and the quantisation at
`0.5`, `1.5`, `2.5` and `3.5`.

## Out of range clamps at both ends

Values below the first mapped value take the first entry and values beyond the
table take the last. The subtraction inherits `ALG-0004`'s overflow reasoning
unchanged: an overflowing difference lies beyond the representable range on the
side opposite the origin's sign and clamps to that same end. The registered
`origin-at-int64-min` and `origin-at-int64-max` fixtures exercise both.

## Determinism and failure classification

The mapping is a pure function of the stored value and the three tables. The
failure family is exactly two payload-free cases, `emptyTable` and
`paletteShapeMismatch`. There is **no representability failure**: the input is
an integer and the descriptor validates every entry finite. There is no
cancellation checkpoint, because one pixel is `O(1)`.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0211-palette-colour-oracle.py`](../progress/evidence/ADR-0211-palette-colour-oracle.py).
It records fifteen fixtures: the first entry with opaque alpha; one fixture per
colour channel; both out-of-range ends; both signed-integer origin extremes; a
negative origin; the output clamp with a tie down; three further output ties; a
single-entry palette; both shape mismatches; and an empty table.

The registered output is:

```text
fixtureSHA256=76d9f8943c52f28b7156ab69c2dd9000e7dc137d526f597ba87a9756fa6a2e65
channelSHA256=98d9464166ab8c01ac5c266b4d29ea56684e1b2b7d38504d9c073de715105160
fixtures=15 mapped=12 rejected=3
index=alg-0004-clamped output=ties-to-even alpha=always-opaque
shape=three-tables-must-agree newRoundingRule=none
```

## Complexity and exclusions

`O(1)` per sample.

Sixteen-bit palette entries and their reduction to eight bits, segmented
palette LUTs, supplemental palettes, palette transparency, an ICC or other
colour-space conversion of palette entries, and any published artefact remain
separate contracts. A source whose palette entries are not already display
values must be converted by its adapter before this stage.

## References

- [ADR-0069 - Lookup-table composition](../architecture/decisions/ADR-0069-lookup-table-composition.md)
- [ADR-0208 - Colour and overlay arc](../architecture/decisions/ADR-0208-colour-and-overlay-arc.md)
- [ADR-0211 - Palette-colour design](../architecture/decisions/ADR-0211-palette-colour-design.md)
- [VOXELIA-ALG-0002 - Window-level linear mapping](VOXELIA-ALG-0002-window-level-linear.md)
- [VOXELIA-ALG-0004 - Lookup-table stored-to-real value mapping](VOXELIA-ALG-0004-lookup-table-value-transform.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0042 - VOI lookup display mapping](VOXELIA-ALG-0042-voi-lookup-mapping.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
