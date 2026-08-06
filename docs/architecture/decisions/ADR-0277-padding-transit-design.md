---
document_id: "ADR-0277"
title: "Padding transit design"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-014"
  - "VOX-VS1-016"
---

# ADR-0277 - Padding transit design

## Context

`ADR-0275` opened the interactive draw-loop arc and named `VOX-R2D-014` and
`VOX-VS1-016` as unblocked work. Beginning that work found that one of the two was
already done, and that the other's remaining gap is larger than a missing request field.

## A correction to `ADR-0275`

**`VOX-VS1-016` was discharged by `ADR-0251` on 2026-08-06**, on the reading that
equivalence with an absent interactive viewport is purity of the render path with respect
to its request, proven by three tests in `ExactSliceRendererTests`. `ADR-0275`'s table
listed it as unblocked work with "nothing gates it".

The mistake was trusting a ledger line — "the interactive draw loop for `VOX-INT-008`,
`VOX-R2D-014`, `VOX-VS1-016` and the `VOX-PER-002/003/005` targets" — that predated
`ADR-0251` and was never revised when that record discharged the row. Nothing was grepped
against `docs/architecture/decisions/` before the inventory was written.

That is the same class of error `ADR-0248` made, in the opposite direction: `ADR-0248`
treated a recorded deferral as a gap, and `ADR-0275` treated a discharged row as
outstanding. Both come from reading one source about a row's state instead of the records.
**A row's status lives in the records, and the ledger is a summary of them, not an
authority over them.**

`ADR-0275` is **not edited**. Its decomposition of the arc by real gate, its identification
of the application-location owner decision, and its parking of `VOX-PER-002/003/005` all
stand. Only its claim that `VOX-VS1-016` was outstanding is withdrawn.

## `VOX-R2D-014` is genuinely open

`VOX-R2D-014` — "off-screen and interactive output shall use the same presentation
semantics", P0, `T` — appears in `ADR-0251`'s front matter but nowhere in its decisions or
consequences, and **no test carries its tag**. `ADR-0251` discharged the vertical-slice
row and left this one traced but unaddressed.

## The nine semantics, enumerated against where each actually travels

Plan §35.1 names what off-screen output must share with interactive output. Each was
traced through the slice pipeline rather than assumed:

| §35.1 semantic | Where it travels |
|---|---|
| viewport request | `SliceRenderRequest.viewport` — request |
| plane geometry | `scene.camera` and `scene.layers` — request |
| interpolation | `SliceRenderRequest.interpolation` — request |
| value transformation | `layer.transferFunction` — request |
| **padding policy** | **nowhere** |
| windowing | `layer.transferFunction`'s `.greyscaleWindow(window)` — request |
| MONOCHROME handling | `window.polarity` — request |
| shader or CPU implementation | the renderer type, chosen at construction |
| output colour descriptor | `SliceRenderRequest.outputColourSpace` — request |

**Seven travel in the request. One is legitimately construction-time** — "shader or CPU
implementation" *is* which renderer you built, and §35.1 asking for the same
implementation means asking for the same renderer, so `ADR-0251`'s "identical
construction" condition is the right and only shape for it. **One is a genuine gap.**

## The finding: padding does not travel at all

The gap is not that padding is absent from the request. It is that padding never reaches
the renderer by any route, while both ends of its journey are already built:

- **Import captures it.** `CTFrameDescription.pixelPadding` is a validated
  `PixelPaddingDescriptor`, and `CTValueInterpreter` reads `frame.pixelPadding?.value`.
- **Both window operations accept it.** `WindowLevelOperation` and
  `MetalWindowLevelOperation` each take `paddingValue: Int64?` and reject a sentinel not
  representable in the admitted scalar type.
- **`ALG-0002` revision 1.2 registers the rule.** A stored integer sample exactly equal to
  the declared value is excluded before every stored-to-real step and displays exactly
  zero; an absent value leaves revision 1.1 byte-identical. `ADR-0113` accepted it for the
  CPU stage and `ADR-0146` extended it to the device window.
- **Nothing connects them.** `CTImportSession` and the `CTVolume*` builders carry no
  padding, so it is not persisted with the volume; and both slice renderers' convenience
  initialisers hard-code `paddingValue: nil`.

`ADR-0146` recorded why, at the time: "the adapter that supplies padding values is gated".
That gate has since opened — DICOMKit is a declared dependency and import reads the tag —
and the wiring was never revisited.

**So §35.1's padding policy is shared today only because it is uniformly absent.** Two
accepted records built an exclusion rule that no production path can reach. This is the
"existence, wiring and verification are three separate questions" pattern again, and the
third one has never been asked here.

## The separability that makes this actionable

`ADR-0251` deferred padding partly because plan §28.4 requires a **separately approved
rule** and offers two candidates. That deferral conflated two different things:

- **§28.4** governs excluding padding from **authoritative interpolation** — whether an
  interpolated quantitative value becomes unavailable, or is renormalised from valid
  corners. That is the **resample** stage, it changes measured values, and its rule is the
  owner's to approve.
- **§35.1** requires the two output paths to use **the same** padding policy. That is an
  equality requirement, and it needs no particular rule.

Equality does not depend on the rule. `VOX-R2D-014` is therefore actionable now, and
§28.4 remains untouched and owner-gated.

## Decision

1. **`VOX-R2D-014` is not discharged by this record.** This is the design; the
   implementation is the next increment, following the project's design-first-then-migrate
   pattern.
2. **No new vocabulary is introduced.** `ALG-0002` revision 1.2's optional `Int64`
   sentinel is the accepted padding representation and the `padding` parameter-schema entry
   is the accepted provenance shape. An accepted rule is composed, not restated.
3. **The padding value is data-intrinsic and travels with the image, not in the viewport
   request.** Rendering the same stored samples under two different sentinels would make
   the same bytes mean different things, which is not a presentation choice. §35.1 lists
   padding among presentation semantics because both paths must agree on it — and coming
   from the image is exactly what guarantees they do, without either path being asked to
   remember.
4. **Therefore the transit has four links, and two are missing**: import captures it
   (built), it is persisted with the volume (**missing**), the renderer reads it from the
   image (**missing**), the window stage receives it (built, currently fed `nil`).
5. **§28.4's interpolation rule is explicitly out of scope and stays owner-gated.** Its
   two candidates concern the resample stage; `ALG-0002` revision 1.2 concerns the window
   stage. Different stages, and only the second is accepted. Recorded prominently because
   an increment that wires padding could easily be read as having settled §28.4, and it
   does not.
6. **`VOX-R2D-014` discharges when the transit is unconditional**, at which point padding
   no longer depends on renderer construction and `ADR-0251`'s conditional purity becomes
   unconditional for the ninth semantic. Its tests must carry the row's tag, which no
   existing test does.
7. **`ADR-0251`'s conditional is not withdrawn, and stays right for the eighth semantic.**
   "Shader or CPU implementation" is construction-time by nature, so equivalence will
   always be stated with respect to the same renderer type.
8. **No algorithm specification and no oracle.** `ALG-0002` revision 1.2 already registers
   the numeric rule and its fixtures; this increment adds transit, not arithmetic.

## What the implementation increment must settle

Recorded now so the next increment has a scope rather than a direction:

- **Where the persisted value lives.** A volume is built from many frames, each with its
  own `pixelPadding`. The increment must decide whether a volume carries one padding value
  and what happens when frames disagree — refusing a disagreement is the likely answer,
  since a volume whose slices mean different things by the same stored value is not one
  volume, but that is a boundary to freeze with a test rather than assert here.
- **How the renderer obtains it.** Either the `WindowStageExecutor` typealias gains a
  padding parameter, or the stage closure captures it from the layer's image. The first
  changes an accepted typealias used by both renderers and their tests; the second keeps
  the signature but makes the closure depend on a lookup.
- **That a clean rebuild is required** if any accepted public type gains a stored member.

## Alternatives considered

### Add a padding field to `SliceRenderRequest`

Rejected as the primary route, and it is what `ADR-0251` anticipated. It would make purity
unconditional, but it puts a data-interpretation fact in a viewport request and would let
one caller render an image with a sentinel its own data does not declare. Decision 3's
route achieves the same equality without that.

### Leave padding at construction and state the obligation, as `ADR-0251` did

Rejected for `VOX-R2D-014`. It was the right answer for `ADR-0251`, which was reading an
equivalence it could not otherwise establish. Here the row's whole content is that the two
paths agree, and a host obligation is the thing this project keeps converting into
structure.

### Discharge `VOX-R2D-014` now on `ADR-0251`'s existing tests with an extended tag

Rejected, and it was tempting because those three tests do establish request purity. But
they establish it *conditionally on identical construction*, and padding is precisely the
semantic that condition exists for. Tagging them with this row would claim the eight easy
semantics as if they were nine.

### Pick §28.4's any-padding rule under the standing mandate, as `ADR-0194` did for its gate

Rejected as unnecessary rather than unauthorised. `ADR-0194`'s precedent — broad
authorisation plus the document's own stated preference — would apply, and §28.4 does
prefer the simpler any-padding rule. But no requirement being worked needs that rule
chosen: §35.1 needs equality, and the window-stage rule is already accepted. Selecting an
owner-gated quantitative rule that nothing currently requires would be scope taken for its
own sake.

## Consequences

`ADR-0275`'s row inventory is corrected: `VOX-VS1-016` was already discharged, and
`VOX-R2D-014` is the arc's real open presentation row.

A latent gap is now documented rather than latent: **`ALG-0002` revision 1.2's padding
exclusion is unreachable from any production path**, so CT pixel padding is currently
windowed as if it were data. Whether that has a visible effect on the owner's series is
not claimed here and is worth measuring in the implementation increment.

The implementation increment has a frozen design, an explicit out-of-scope boundary around
§28.4, and two named boundaries of its own to settle.

Nothing is discharged by this record.

## Affected modules

None. No source changed.

## Compatibility impact

None yet. The implementation increment will touch an accepted public surface and will say
so.

## Security impact

None from this record. The documented gap is a correctness matter — padding samples
participating in display mapping — not a disclosure one.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1124 tests in 203 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: persist the padding value with the volume, feed it to the window stage, and
   discharge `VOX-R2D-014` with tests carrying its tag.
3. Then `VOX-INT-008`'s `T`.
4. **Owner**: §28.4's padding-aware interpolation rule remains outstanding and is
   unaffected by this arc; plus the application-location decision from `ADR-0275`,
   `VOX-CMP-006`'s and `VOX-CMP-012`'s Reviews, the five `J2KSwift` items, and the five
   decisions already open.

## Supersession

This record supersedes nothing. It **withdraws one claim from `ADR-0275`** — that
`VOX-VS1-016` was outstanding — and **resolves the asymmetry `ADR-0251` named for its own
record**. Neither record is edited.

## References

- [ADR-0113 - Pixel padding exclusion](ADR-0113-pixel-padding-exclusion.md)
- [ADR-0146 - Padded device window](ADR-0146-padded-device-window.md)
- [ADR-0248 - Linked crosshair verification](ADR-0248-linked-crosshair-verification.md)
- [ADR-0251 - Off-screen equivalence reading](ADR-0251-off-screen-equivalence-reading.md)
- [ADR-0275 - Open the interactive draw loop arc](ADR-0275-open-the-interactive-draw-loop-arc.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
