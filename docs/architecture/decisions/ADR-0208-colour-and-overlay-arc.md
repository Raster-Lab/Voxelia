---
document_id: "ADR-0208"
title: "Colour and overlay arc"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-R2D-007"
  - "VOX-R2D-010"
  - "VOX-R2D-011"
  - "VOX-R2D-015"
---

# ADR-0208 - Colour and overlay arc

## Context

With `ADR-0197` closed, the colour and overlay block is the last actionable M6
work. Four rows remain:

| Row | Text | Priority | Methods |
|---|---|---|---|
| `VOX-R2D-007` | VOI LUT application | P1 | T |
| `VOX-R2D-010` | Palette-colour and RGB presentation through explicit colour transforms | P1 | T |
| `VOX-R2D-011` | Segmentation, mask and image overlays with defined alpha-compositing semantics | P0 | T |
| `VOX-R2D-015` | Display colour transformation and output colour space explicit in render requests and provenance | P1 | I,T |

**Every row declares `T` or `I,T`. Not one declares Demonstration.** Unlike the
surface arc, which closes seven rows only halfway and leaves their demonstration
half gated behind the owner-gated interactive draw loop, this arc can discharge
each of its requirements **completely**. That difference is recorded here so no
later increment mistakes a half-discharge for the norm.

### What already exists

- `LookupTableDescriptor` (Core) stores an ordered table and says of itself that
  it "does not define lookup, clamping, extrapolation, or display-window
  behavior". The metadata exists; the application model does not.
- `CompositeLayersOperation` blends layers under `VOXELIA-ALG-0009`
  `layered-linear-blend/binary64-v1` — but only single-component `uint8` layers
  whose component interpretation is `scalar`, over a black background.
- `ColourOutputConfiguration` offers `greyscale8` and `rgba8`, and travels in
  `PresentationProvenance`.
- `TransferFunctionEntry`, `TransferFunction1D` and `VOXELIA-ALG-0023` supply an
  accepted colour representation: four `UInt8` channels, normalised by `/255.0`,
  **straight rather than premultiplied**, with a fixed 256-entry table and a
  clamped index. `ADR-0203` reused all of it rather than inventing a
  representation, and this arc must do the same.
- `MONOCHROME1` and `MONOCHROME2` semantics are accepted, through
  `InvertDisplayOperation` and the transfer function's inverted polarity.

### What does not exist

No colour space is declared anywhere. `ADR-0203` recorded that absence
explicitly rather than silently assuming one, which is exactly why
`VOX-R2D-015`'s "output colour space shall be explicit" is genuinely
outstanding. No palette-colour path, no RGB source path, and no overlay model
beyond greyscale layer blending exist at all.

## Decision

1. **This record opens the arc and decides its decomposition and binding rules
   only.** It freezes no numeric boundary, defines no algorithm and registers no
   oracle. Each increment below carries its own accepted record, and any that
   fixes a numeric boundary carries an algorithm specification with an
   independent Python oracle before implementation, exactly as `ADR-0183` and
   `ADR-0197` required.
2. **The decomposition, in dependency order:**
   - **(a) Colour vocabulary and declared output colour space**
     (`VOX-R2D-015`, first half). The vocabulary every later increment
     publishes.
   - **(b) VOI LUT application** (`VOX-R2D-007`). Value-domain only and
     independent of colour; it may run before or after (a) but is placed here
     because it unblocks nothing else.
   - **(c) Palette-colour presentation** (`VOX-R2D-010`, first half).
   - **(d) RGB source presentation** (`VOX-R2D-010`, second half).
   - **(e) Overlay alpha compositing** (`VOX-R2D-011`).
   - **(f) Request and provenance completion, and the inspection half**
     (`VOX-R2D-015`, second half), closing the arc.
3. **Colour comes before the P0 overlay row, and the reason is recorded.** A
   segmentation overlay that cannot be told apart from the image it covers is
   not an overlay anyone can read, so (e) depends on (a). The P0 row is not
   thereby stalled: `ALG-0009` already blends greyscale layers today, so the
   greyscale case remains available throughout.
4. **Declaring is not converting.** An explicit output colour space is a
   **declaration** that grants no conversion authority — no chromatic
   adaptation, no gamma application, no primaries transform. This is the
   `PoweredLengthUnit` precedent, where the source unit is carried verbatim and
   never raised or combined. A conversion is a separate claim needing separate
   evidence.
5. **No implicit colour space is ever assumed.** An undeclared source is
   undeclared, not sRGB. Inferring one would attach a claim to every image the
   project has already published.
6. **Colour is display-side and never flows back.** `VOX-R2D-002` keeps stored
   values separate from displayed ones and `VOX-R2D-012` preserves quantitative
   inspection before display transformations; `ADR-0183` forbids rasterised
   presentation output as a measurement input. No increment in this arc may make
   a colour-transformed value an input to quantitative inspection, geometry
   measurement or any published measurement.
7. **A palette or RGB path must never relabel a monochrome source.** The
   photometric interpretation a source declares is carried, not reinterpreted —
   the coordinate-space rule of `ADR-0183` decision 4, applied to colour.
8. **Compose the accepted colour representation; do not invent one.** Four
   `UInt8` channels, `/255.0` normalisation, straight (unpremultiplied) alpha
   and the clamped table index are already accepted. `ADR-0203` proved a
   deferred representation can resolve to composition, and this arc inherits
   that resolution rather than reopening it.
9. **Display calibration is explicitly out of scope.** DICOM Part 14 GSDF,
   ICC profile handling and any measured display characterisation are **not**
   claimed by this arc. They are calibration claims about physical hardware,
   they need their own record and owner engagement, and "explicit colour
   transformation" in `VOX-R2D-015` is a statement about the request and the
   provenance, not about a calibrated display chain. No increment may imply
   otherwise.
10. **Every increment's evidence method is stated in its own record.**
    Byte-exact off-screen output discharges Test. Because no row here declares
    Demonstration, a green increment closes its row outright — and any increment
    that finds itself unable to must say so rather than narrowing the claim.
11. **`VOX-MPR-011` is unassessed, and this record says so rather than
    absorbing it.** See the finding below.

## An unassessed M6 row found while opening this arc

`VOX-MPR-011` — "Voxelia shall support multi-volume fusion for spatially
registered inputs", P1, `T,D`, M6 — appears in the requirements baseline and in
the release traceability index, and appears **nowhere else**: not in any
accepted decision record, and not once in the autonomy ledger, including the M6
opening assessment that enumerated the milestone's rows.

It is recorded here as an outstanding M6 item and is **not** folded into this
arc. Fusion of registered volumes is not colour or overlay work, and smuggling
an unrelated requirement into an arc to make a milestone look closed is the
opposite of what these records are for. It needs its own assessment, which must
also determine its relationship to `VOX-DVR-010`'s deliberately deferred
multi-volume compositing half — deferred for want of a consumer-driven blend
rule, which may or may not be the same question.

This is the third time re-reading the baseline's own table has surfaced
something a decomposition list missed, and the standing process rule that
required it is what found it.

## Alternatives considered

### Fold `VOX-MPR-011` into this arc to close M6 in one pass

Rejected; see the finding above.

### Start with the P0 overlay row

Rejected; see decision 3. It would force a colour representation to be invented
inline, under time pressure from a P0 label, which is precisely how the
deferrals `ADR-0201` and `ADR-0202` avoided became debts.

### Declare sRGB as the output colour space

Rejected; see decision 5. No accepted record characterises the output, and
naming a space the project has not evidenced would make every previously
published image retroactively carry a claim nobody verified.

### Claim GSDF or ICC conformance as part of "explicit colour transformation"

Rejected; see decision 9. It reads a hardware-calibration claim into a
request-and-provenance requirement.

### Extend `CompositeLayersOperation` in place for overlays

Not decided here. Whether overlays extend the accepted layered blend or need
their own model is increment (e)'s finding, and pre-judging it in an
arc-opening record is the mistake `ADR-0197` decision 7 warned against and
`ADR-0207` then vindicated by reaching the opposite conclusion from its mirror.

## Consequences

Four requirements become actionable in a recorded order, each fully
dischargeable off-screen. M6 does not close with this arc: `VOX-MPR-011` remains
outstanding, and the gated rows — `VOX-BRK-009`, `VOX-DVR-013`, `VOX-PER-004`,
`VOX-ADP-003` — remain gated, as does the demonstration half of the surface arc.

## Affected modules

Documentation only in this increment. Later increments are expected to touch
`VoxeliaCore`, `VoxeliaExecution` and `VoxeliaRendering`; no dependency edge
change is anticipated, and any that becomes necessary needs its own recorded
justification.

## Compatibility impact

None in this arc-opening increment.

## Security impact

None in this arc-opening increment.

## Performance and memory impact

None in this arc-opening increment.

## Validation impact

Documentation, register, index, link, manifest and release-integrity checks
only. No oracle is registered, because this record freezes no numeric boundary.

## Migration

1. Increment (a): the colour vocabulary and declared output colour space.
2. Increments (b) through (f) in the recorded order.
3. `VOX-MPR-011` gets its own assessment record, separately from this arc.

## Supersession

This record opens a new arc and supersedes no accepted record. It does not
reopen `ADR-0085`, `ADR-0090`, `ADR-0100`, `ADR-0124`, `ADR-0174` or `ADR-0203`;
it composes them.

## References

- [ADR-0085 - Render request, result and protocol](ADR-0085-render-request-result-and-protocol.md)
- [ADR-0090 - Layer compositing operation](ADR-0090-layer-compositing-operation.md)
- [ADR-0183 - Geometry arc](ADR-0183-geometry-arc.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0203 - Surface colour map design](ADR-0203-surface-colour-map-design.md)
- [ADR-0207 - GPU-produced geometry representability assessment](ADR-0207-gpu-geometry-representation-assessment.md)
- [VOXELIA-ALG-0009 - Layered linear blend](../../algorithms/VOXELIA-ALG-0009-layered-linear-blend.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
