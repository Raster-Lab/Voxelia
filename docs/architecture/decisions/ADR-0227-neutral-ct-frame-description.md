---
document_id: "ADR-0227"
title: "Neutral CT frame description"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-003"
  - "VOX-DCM-006"
  - "VOX-DCM-007"
  - "VOX-DCM-008"
---

# ADR-0227 - Neutral CT frame description

## Context

`ADR-0226` opened the DICOM ingest arc and set increment (a) as the neutral
frame-record vocabulary: Voxelia-owned, naming no DICOMKit type, and the value
every later increment consumes. This record decides that vocabulary.

The First Vertical Slice Plan sketches a fifteen-field `CTFrameRecord` and says
of itself that it is "a planning contract, not a final public API". Three of the
types it names — `MonochromeInterpretation`, `PixelPaddingDescriptor` and
`CTFrameSamples` — do not exist in this repository. So this increment cannot
simply transcribe the sketch; it has to decide what each of those is, and
whether it belongs here at all.

## The finding that decides the presentation field

The plan's `photometricInterpretation` field records MONOCHROME1 or
MONOCHROME2. This project already has a two-case presentation vocabulary:
`PresentationPolarity` (`.standard`, `.inverted`) from `ADR-0112`. Reusing it
would avoid a near-duplicate enum.

**It cannot be reused, and the reason is architectural rather than
stylistic.** `PresentationPolarity` lives in `VoxeliaRendering`, and
`Package.swift` declares `VoxeliaRendering` as depending on `VoxeliaImaging`.
A frame description in `VoxeliaImaging` referring to it would invert an
accepted module order. There is no arrangement of this increment that reuses
the type.

That constraint happens to force the right answer anyway. "The source stated
MONOCHROME1" is a **fact about the file**; "display this inverted" is a
**decision about presentation**. They coincide today, and collapsing them at
ingest would discard the evidence for the decision while keeping the decision.

**The mapping itself is not an open question and is not reopened here.**
`ADR-0112` already fixes it — `standard` for MONOCHROME2 semantics, `inverted`
for MONOCHROME1 — for `VOX-R2D-005`. What is missing is a *source-side*
vocabulary in a module that can hold one. This record adds that vocabulary and
no second mapping; the rendering boundary applies `ADR-0112`'s.

## The axis convention, stated because getting it backwards is silent

DICOM's Image Orientation (Patient) and Pixel Spacing are a well-known source
of transposed volumes, because both are pairs whose ordering is stated in prose
elsewhere. A reconstruction built on the wrong reading is not obviously wrong —
it is a plausible image of the wrong geometry. This record therefore fixes the
convention by **index**, not by the words "row" and "column" alone:

| Field | Meaning |
|---|---|
| `rowDirection` | The direction in which the **column index** increases — along a row. |
| `columnDirection` | The direction in which the **row index** increases — down a column. |
| `rowSpacingMillimetres` | Centre-to-centre distance between adjacent **rows**: the step along `columnDirection` per unit row index. |
| `columnSpacingMillimetres` | Centre-to-centre distance between adjacent **columns**: the step along `rowDirection` per unit column index. |

This matches DICOM's own ordering — Image Orientation supplies the row
direction first, and Pixel Spacing supplies row spacing first — but the table
above, not that correspondence, is what this project's code means. The shim in
increment (e) is responsible for satisfying it.

## Decision

1. **The type is `CTFrameDescription`, in `VoxeliaImaging`.** That module sits
   above `VoxeliaSpatial`, `VoxeliaCore`, `VoxeliaStorage` and
   `VoxeliaExecution`, and below `VoxeliaRendering`, so it can compose every
   accepted type the description needs and is visible to every later increment.
2. **The description carries no decoded samples**, and the plan's
   `CTFrameRecord` is therefore decomposed rather than transcribed. Increments
   (b) and (c) — series grouping and geometry validation — read only the
   description; requiring a pixel buffer would make every fixture for them
   carry data they never read. Sample ownership is a genuine design question
   with three candidate answers already enumerated in the plan's §16.1
   (direct-write, owned, borrowed), and it is the adapter that answers it, so it
   is settled where the adapter is built. `CTFrameRecord` — a description paired
   with its samples — arrives with increment (d).
3. **The description is a faithful transcription, not a judgement.** It admits
   exactly what makes the value representable and arithmetically safe, and
   refuses every rule that would need a tolerance. A frame whose direction
   cosines are thirty degrees from orthogonal is a **valid description** and a
   **rejected series**: it must be constructible, or the pipeline cannot name
   the thing it is rejecting or report which frame was at fault.
4. **The admission rules, all exact:**
   - `rows` and `columns` are each at least one.
   - `rows * columns` is computable without overflow. This is the one rule that
     looks beyond the value itself, and it is included deliberately: every later
     increment multiplies them, and admitting a pair that cannot be multiplied
     would lay a trap in a value type whose whole purpose is to be trusted
     downstream.
   - Each spacing is finite and strictly greater than zero. Finiteness is
     checked separately from positivity because infinity satisfies `> 0`.
   - Each direction vector is non-zero, tested **componentwise against exact
     zero** — never by computing a magnitude, which would introduce squaring,
     underflow, and a threshold to argue about.
   - The image position and both direction vectors share one
     `CoordinateSpaceID`. This is exact equality within a single frame, where
     mixed spaces describe nothing coherent. Whether *different* frames share a
     space is increment (c)'s question, and is untouched here.
   - The rescale slope and intercept are finite.
   - A pixel-padding value, when present, is representable in the frame's
     declared `ScalarFormat`.
5. **A zero rescale slope is admitted**, and this is a deliberate consequence of
   decision 3 rather than an oversight. It is representable and arithmetically
   safe — `0 * x + b` is well defined — so rejecting it would be a judgement
   about usefulness, not about representability. It is recorded here because the
   judgement is real and now has no home: it belongs to the value-transformation
   stage that `VOX-DCM-006` requires, and that stage must decide it explicitly
   rather than inherit silence from this record.
6. **`ScalarFormat` is not narrowed to sixteen-bit here.** `VOX-DCM-005` scopes
   the *first vertical slice* to signed and unsigned sixteen-bit CT samples;
   that is a statement about what the pipeline handles, not about what a
   description may record. Narrowing the vocabulary to the current slice would
   have to be undone by the next one.
7. **`PixelPaddingDescriptor` carries a single value, and the omission of
   DICOM's range form is documented in the source.** `VOX-DCM-008` requires the
   padding information "required by the first vertical slice", and the accepted
   consumer of that information — `WindowLevelOperation` — takes a single
   `Int64?`. Implementing a range form no accepted code path reads would be a
   claim beyond the implementation.
8. **The descriptor does not validate itself; the description validates it.**
   Representability depends on the frame's `ScalarFormat`, which the descriptor
   does not hold. Giving the descriptor a format-taking initialiser would put
   the same rule in two places, because a caller could still pair a validated
   descriptor with a different format.
9. **The failure family is a payload-free `Error, Sendable, Equatable` enum with
   one case per admission rule**, following the accepted house pattern.
10. **No algorithm specification and no independent oracle accompany this
    record.** Every admission is an exact predicate over values whose
    finiteness the accepted spatial types already enforce: comparisons against
    zero and one, an overflow-reporting multiplication, and an exact identifier
    equality. There is no rounding, no tolerance, no expression ordering and no
    accumulation — an oracle would restate `>` and `≠` in Python. This follows
    the precedent of the accepted vocabulary records, and it is stated
    explicitly so that the absence reads as a decision rather than an omission.

## Alternatives considered

### Reuse `PresentationPolarity` for the photometric field

Rejected, and not merely on taste: it lives in a module that depends on this
one. See the finding above.

### Transcribe the plan's `CTFrameRecord` verbatim, samples included

Rejected; see decision 2. It would force pixel buffers into fixtures for two
increments that never read them, and would settle the sample-ownership question
in the increment least equipped to answer it.

### Reject non-orthogonal or non-unit direction cosines here

Rejected; see decision 3, and `ADR-0226` decision 6, which reserves every
tolerance question for increment (c). Rejecting at construction would also make
the offending frame unrepresentable, so the pipeline could not report which
frame it rejected or why.

### Reject a zero rescale slope

Rejected as a rule here; see decision 5. Recorded as an open judgement rather
than silently admitted.

### Admit any positive `rows` and `columns` without the overflow rule

Rejected; see decision 4. It is the one rule that is not purely local, and it
earns its place because the alternative is a value type that can be constructed
only to fail later in code that has every reason to trust it.

### Use `SIMD3<Double>` as the plan sketches

Rejected by `ADR-0226` decision 3; the accepted spatial types carry the
coordinate space that increment (c) exists to check.

## Consequences

Increments (b), (c) and (d) can be built and tested against synthetic
descriptions with no dependency and no pixel data. The description deliberately
accepts geometry that the series validator will reject, which is what allows
that validator to produce a diagnostic naming the frame rather than a
construction failure with no subject.

One judgement — the degenerate rescale slope — is left explicitly unhomed and is
assigned to the value-transformation stage rather than being quietly absorbed
here.

## Affected modules

`VoxeliaImaging` gains `CTFrameDescription`, `MonochromeInterpretation`,
`PixelPaddingDescriptor` and `CTFrameDescriptionError`. No module's dependencies
change. No third-party dependency is added.

## Compatibility impact

Additive only. No accepted type changes.

## Security impact

None. The failure family is payload-free, so a rejected description never
discloses source geometry, identifiers or metadata in a diagnostic.

## Performance and memory impact

Construction is a fixed number of comparisons. No allocation beyond the stored
fields.

## Validation impact

```text
swift build && swift test
swift format lint --strict
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
```

No oracle; see decision 10.

## Migration

1. This increment: the description, its two supporting types and its failure
   family, with unit tests covering every admission rule and every accepted
   field.
2. Increment (b): series grouping over descriptions.
3. Increment (c): irregular-geometry rejection, where every tolerance is
   decided with an oracle.
4. Increment (d): affine volume construction, and `CTFrameRecord` as a
   description paired with its samples.
5. Increment (e): the DICOMKit shim, which is responsible for satisfying the
   axis convention stated above.

## Supersession

This record supersedes nothing. It performs increment (a) of `ADR-0226`.

## References

- [ADR-0037 - Claim-bearing data identity and cache admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0112 - Monochrome presentation polarity](ADR-0112-monochrome-presentation-polarity.md)
- [ADR-0226 - DICOM ingest arc](ADR-0226-dicom-ingest-arc.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
