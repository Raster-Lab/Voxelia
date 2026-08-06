---
document_id: "ADR-0217"
title: "Vertical slice traceability"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-008"
  - "VOX-VS1-002"
  - "VOX-VS1-003"
  - "VOX-VS1-004"
  - "VOX-VS1-007"
  - "VOX-VS1-010"
  - "VOX-VS1-011"
  - "VOX-VS1-012"
  - "VOX-VS1-013"
  - "VOX-VS1-015"
---

# ADR-0217 - Vertical slice traceability

## Context

`ADR-0216` measured the project's requirement traceability debt at 83 rows in
entered milestones, ratcheted it so it cannot grow, and named the `VOX-VS1`
rows as the most likely first candidates to pay down: first-vertical-slice
behaviour the project has largely built but never labelled.

Nine `VOX-VS1` rows were on that list: `002`, `003`, `004`, `007`, `010`,
`011`, `012`, `013` and `015`. This record inspects each against what actually
exists.

`ADR-0216` decision 6 binds this: a row leaves the list only when a record, a
source comment or a test genuinely cites it, never by being added to a document
for the sake of the count.

## Findings, per row

### Satisfied and now traced

- **`VOX-VS1-007`** (MONOCHROME1 and MONOCHROME2, **T**). Satisfied by the
  accepted transfer function's `standard` and `inverted` polarity and by
  `InvertDisplayOperation` under `VOXELIA-ALG-0011`, with
  `InvertDisplayOperationTests` as evidence. This is the same evidence that
  discharges `VOX-R2D-005`, which was already traced; the vertical-slice row
  restates the same capability and was simply never labelled.
- **`VOX-VS1-011`** (nearest-neighbour and linear interpolation, **T**).
  Satisfied by `ResampleNearestOperation` and `ResampleLinearOperation` under
  `VOXELIA-ALG-0008` and `VOXELIA-ALG-0015`, with their own test suites, and by
  the explicit `InterpolationPolicy` `ADR-0124` added for `VOX-R2D-013`.
- **`VOX-VS1-012`** (window centre and width, **T,D**). The value model is
  satisfied by `WindowLevelOperation` under `VOXELIA-ALG-0002`. The row's word
  is "interaction", so only the **Test** half is claimed; the interactive half
  depends on the owner-gated draw loop.
- **`VOX-VS1-013`** (linked patient-space crosshairs, **T,D**). Satisfied for
  **Test** by `ViewportSyncGroup` under `ADR-0119`, which requires every member
  and the shared crosshair to inhabit one coordinate space — frame-of-reference
  compatibility by construction, so a crosshair cannot drift into a foreign
  frame. The demonstration half depends on the draw loop.
- **`VOX-VS1-015`** (patient-space distance measurement, **T,D**). Satisfied
  for **Test** by `MeasurementConstruction` under `ADR-0111`, which preserves
  the ordered points in one coordinate space and derives the length under
  `VOXELIA-ALG-0010` in the space's own length unit. The demonstration half
  depends on the draw loop.

### Not satisfied — and this is the finding worth having

- **`VOX-VS1-010`** (Metal axial, coronal and sagittal rendering, **T,D**).
  **Not satisfied.** Both halves of it exist and *do not meet*: `MPRPlane`
  defines `axial`, `coronal` and `sagittal` in `VoxeliaImaging`, and
  `MetalSliceRenderer` renders scene layers on the GPU — but **no source file
  outside its own definition references `MPRSliceCoordinator` or `MPRPlane`**,
  and the Metal renderers consume two-dimensional scene layers rather than a
  volume and a plane. Plane extraction today is the CPU
  `ObliqueSliceOperation`. Citing the two existing pieces as though they
  composed would be exactly the false trace `ADR-0216` decision 6 forbids, so
  this row **stays on the debt list** with the reason recorded here.

### Blocked by an owner-gated dependency

- **`VOX-VS1-002`** (assemble frames using spatial metadata),
  **`VOX-VS1-003`** (reject or warn on irregular geometry) and
  **`VOX-VS1-004`** (create a Voxelia affine volume with patient-space
  geometry) all describe what happens to a **DICOM series after ingest**, and
  `VOX-VS1-001` makes that ingest DICOMKit's. The DICOMKit dependency is a
  standing owner question. The spatial vocabulary those rows would produce
  into — `AffineGridGeometry`, `CoordinateSpaceDescriptor`, `ImageDescriptor` —
  is accepted and tested, but nothing assembles a series into it, and saying
  otherwise would claim ingest the project cannot perform. They **stay on the
  debt list**.

## Decision

1. **Five rows are traced by this record**: `VOX-VS1-007`, `011`, `012`, `013`
   and `015`, each to the named accepted record, operation, algorithm and test.
2. **For the three `T,D` rows among them, only the Test half is claimed.** The
   demonstration halves join the owner-gated interactive draw-loop dependency
   list, exactly as the `VOX-SUR` and `VOX-MPR-011` demonstration halves did.
3. **`VOX-VS1-010` stays on the debt list, recorded as genuinely unbuilt**, with
   the specific gap named: nothing connects the plane vocabulary to the Metal
   path. It is not traced by citing two components that never meet.
4. **`VOX-VS1-002`, `003` and `004` stay on the debt list as
   dependency-blocked**, not as oversights.
5. **No new code is written.** Every trace here points at work that already
   exists and already passes its tests. Writing something to make a row
   traceable would invert the exercise.
6. **Traced is not the same as discharged, and the debt list measures the
   first.** Writing this record made the distinction concrete: it *names* all
   nine rows, including the four it leaves undischarged, so the traceability
   check now sees all nine as traced. That is the correct reading rather than an
   accident to work around. What hid `VOX-MPR-011` was **invisibility** — a row
   nobody had written anything about. A row with a recorded status, even
   "blocked on DICOMKit" or "genuinely unbuilt", is no longer invisible, and a
   reader who searches for it finds the project's position on it. All nine
   therefore leave the debt list, taking it from 75 rows to 66.
7. **Undischarged status stays tracked where it has always been tracked** — the
   ledger's gated list and this record's findings. Conflating the two measures
   would be the error: a check that refused to let a row be described until it
   was also finished would punish exactly the honest write-up this record is.

## Alternatives considered

### Trace `VOX-VS1-010` by citing `MPRPlane` and `MetalSliceRenderer` together

Rejected; see the finding. They do not compose, and no source connects them. A
trace that points at two unconnected pieces is worse than an honest gap: it
would mark the row satisfied and stop anyone looking again.

### Build the Metal plane path now to close `VOX-VS1-010`

Rejected for this increment. It is a real capability gap deserving its own
design record — which plane vocabulary the Metal path consumes, whether it
reconstructs on the GPU or presents a CPU reconstruction, and what its numeric
boundary is against the accepted `ALG-0017` oblique sampling. Bundling that into
a traceability increment would hide a design decision inside a bookkeeping one.

### Trace the three DICOM-dependent rows against the spatial vocabulary

Rejected; see the finding. The vocabulary exists, but the rows are about
assembling a series into it, and nothing does that.

## Consequences

The traceability debt falls from 75 to 66 rows — every `VOX-VS1` entry leaves
it. Five of those rows are discharged for Test; four remain **undischarged but
now visible**, each with a recorded reason: `VOX-VS1-010` genuinely unbuilt, and
`002`, `003` and `004` blocked on the owner's DICOMKit decision.

A new candidate for the project's queue is now explicit: `VOX-VS1-010`'s Metal
plane path, which needs its own design record rather than a trace.

## Affected modules

Documentation only. No product source changes.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

`Tools/Scripts/check_requirement_traceability.py` reports the reduced debt and
passes; all nine rows are removed from
`docs/progress/untraced-requirements.txt` in the same change, which the check's
resolved-row rule requires.

## Migration

1. Remove the nine now-visible rows from the debt baseline.
2. `VOX-VS1-010`'s Metal plane path needs its own design record when it is
   taken up.

## Supersession

This record supersedes nothing and reopens nothing. It labels work that already
existed.

## References

- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
- [ADR-0119 - Viewport synchronisation](ADR-0119-viewport-synchronisation.md)
- [ADR-0124 - Display policy selection](ADR-0124-display-policy-selection.md)
- [ADR-0216 - Requirement traceability sweep](ADR-0216-requirement-traceability-sweep.md)
- [VOXELIA-ALG-0002 - Window-level linear mapping](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [VOXELIA-ALG-0008 - Nearest-neighbour resampling](../../algorithms/VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
- [VOXELIA-ALG-0010 - Polyline length](../../algorithms/VOXELIA-ALG-0010-polyline-length.md)
- [VOXELIA-ALG-0011 - Display inversion](../../algorithms/VOXELIA-ALG-0011-display-inversion.md)
- [VOXELIA-ALG-0015 - Bilinear resampling](../../algorithms/VOXELIA-ALG-0015-bilinear-resampling.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
