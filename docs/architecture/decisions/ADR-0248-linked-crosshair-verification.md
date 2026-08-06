---
document_id: "ADR-0248"
title: "Linked crosshair verification"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-005"
  - "VOX-INT-006"
  - "VOX-MPR-005"
  - "VOX-VS1-013"
---

# ADR-0248 - Linked crosshair verification

## Context

`VOX-VS1-013` requires linked patient-space crosshairs, and the First Vertical
Slice Plan asks for **crosshair spatial round-trip tests**. Every part existed
before this increment: `ADR-0138`'s world-point slice mapping in
`MPRSliceCoordinator`, `ADR-0140`'s crosshair broadcast in `ViewportSyncGroup`,
and `ADR-0130`'s ties-to-even rounding shared by both. What had never happened is
the composition: the parts were each tested against hand-built fixtures, never
against a real volume's affine, and never against each other.

This record is verification rather than capability. No source changed.

## What was verified

One crosshair placed at the patient-space position of voxel
`(column 300, row 200, slice 400)` in the owner's 899-slice thoracic series
(`512x512x899`, `uint16`, 449 MiB), at patient-space
`(36.41758402499997, -211.89908785000003, -1166.683)` mm.

**The slice-index round trip.** Each plane's `sliceIndex(forWorldPoint:)` returned
that plane's own component of the originating voxel:

| Plane | Fixed axis | Resolved | Expected |
|---|---|---|---|
| Axial | 2 (slice) | `400` | `400` |
| Coronal | 1 (row) | `200` | `200` |
| Sagittal | 0 (column) | `300` | `300` |

**The pixel round trip.** The three slices the crosshair selects were extracted
and published, a presentation built per plane from the slice's own claimed
geometry, and the crosshair broadcast to all three through
`ViewportSyncGroup.crosshairTargets`:

| Plane | View | Crosshair pixel | Expected |
|---|---|---|---|
| Axial | `512x512` | `(300, 200)` | `(300, 200)` |
| Coronal | `512x899` | `(300, 400)` | `(300, 400)` |
| Sagittal | `512x899` | `(200, 400)` | `(200, 400)` |

Both round trips are exact, on real geometry, with no tolerance applied. The
coronal and sagittal cases are the load-bearing ones: they exercise
`ADR-0244`'s axis renumbering after the singleton drop, which is what makes the
slice axis become a view's `y`. That renumbering had been reasoned about and
unit-tested; this is the first time it was checked against a scanner's affine.

**Refusals were verified too, not just successes.** The axis-value overload
refused with `unsupportedAxisSampling` against a descriptor that declares
`.indexOnly` sampling with an affine — which is exactly why `ADR-0138` added the
world-point overload. A point 50 columns beyond the volume refused with
`crosshairOutsideVolume` rather than clamping to the last slice.

## The finding: `crosshairTargets` alone cannot decide whether to draw a crosshair

For the crosshair placed 50 columns past the volume's edge, the three views
resolved as `outsideViewport, outsideViewport, target(200, 400)`.

**The sagittal view returned a pixel for a point that is not in the volume.** This
is correct at the unit level and is documented there: `PickResolver` states that
slots which are not presented do not gate admission, because they do not select
the pixel. The sagittal view presents row and slice; the crosshair's *column*
chooses which sagittal plane is on screen, so an out-of-range column cannot move
the in-plane projection. The projection is honest about what it computes.

But it means a host that consulted only `crosshairTargets` would draw a crosshair
on a sagittal view for a point outside the volume. **The guard is the slice-index
call** — which refused this exact point — and every host must already make that
call to know which slice to render. So the two mappings are complementary and
neither is redundant:

- `sliceIndex(forWorldPoint:)` answers *is there a plane to show, and which*.
- `crosshairTargets(presentations:)` answers *given that plane, where on it*.

This is a composition obligation, not a defect, and it was previously stated
nowhere. Decision 2 records it.

## Decision

1. **`VOX-VS1-013` is discharged on real data.** Both round trips are exact and
   the two refusal paths were exercised. No source change was required and none
   was made; a record claiming otherwise would overstate the increment.
2. **The host's crosshair obligation is stated: consult the slice mapping before
   the pixel mapping, and treat the slice mapping as the authority on whether a
   crosshair exists in a plane at all.** The pixel mapping deliberately ignores
   the non-presented axis and must not be read as an in-volume test.
3. **No tolerance is introduced.** The round trips are exact on real geometry, so
   there is nothing here to justify one. This is unrelated to the geometry
   tolerance the owner gate in `ADR-0229` and `ADR-0234` still covers, which
   concerns slice-spacing regularity rather than crosshair mapping.
4. **The harness's own two failures are recorded rather than quietly fixed**, per
   this project's practice: a camera constructed at its own target was refused
   with `degenerateViewDirection`, and an earlier run omitted the series
   frame-of-reference. Both were harness mistakes and both were caught by
   Voxelia's admissions — the second is recorded in `ADR-0235`.

## Sizing of the five remaining first-slice requirements

Read by capability rather than by the requirement's vocabulary, which is the
method correction `ADR-0247` adopted after two increments of under-crediting
existing work. This is **sizing, not discharge** — none of the five is claimed
here.

| Requirement | Mechanism | Assessment |
|---|---|---|
| `VOX-VS1-010` Metal three-view | `ExactSliceRenderer`, `MultiplanarRenderCoordinator` | Present. Needs a differential run against the CPU path. |
| `VOX-VS1-011` nearest and linear | `ResampleNearestOperation` (`VOXELIA-ALG-0008`), `ResampleLinearOperation` (`VOXELIA-ALG-0015`) | Both frozen with dedicated test files. Likely already satisfied; needs confirmation, not construction. |
| `VOX-VS1-016` off-screen output | No `offScreen` symbol exists | A requirement-reading question, unchanged from `ADR-0247`. |
| `VOX-VS1-017` cancellation prevents stale publication | `RenderGeneration`, `RenderGenerationCounter`, `isStale` | **The mechanism exists and has zero production callers.** `isStale` is consulted by nothing outside its own file and its own test. |
| `VOX-VS1-018` no duplicate GPU upload | `MetalResidencyManager.selection(for:)` | On unified memory both `.automatic` and `.shared` select `.shared`, so there is no copy to duplicate. That is the architectural half of `A,T`; the measured half is open. |

**`VOX-VS1-017` is the substantive one, and it is the opposite of the error this
method was adopted to prevent.** Searching by capability found a mechanism that
exists — so a name-based search would have called the requirement satisfied — but
finding the mechanism unwired is not the same as finding the requirement met. A
staleness predicate nothing calls prevents no stale publication. Whether the
wiring belongs in the publication coordinator or in a host-side contract is a
design question for its own record.

## Alternatives considered

### Add a repository test instead of a harness run

Rejected for this increment, and not permanently. No repository test may read the
owner's patient data, so a repository test would have to use a synthetic affine —
which is what the existing unit tests already do. The gap `VOX-VS1-013` names is
specifically the composition against real geometry. A synthetic composition test
is still worth adding and is recorded as a migration step.

### Make `crosshairTargets` reject out-of-volume points

Rejected. It has no volume to check against — it holds presentations, not the
volume, and the presented axes are all it can see. Passing the volume in would
merge two mappings that are correctly separate, and would make the pixel mapping
depend on a published object it does not otherwise need.

### Treat the sagittal `target` result as a defect

Rejected; see the finding. The projection computes what it claims to compute. The
gap was in the composition contract, which decision 2 now states.

## Consequences

The first vertical slice stands at **fourteen of twenty** requirements
discharged: `001`–`009`, `012`, `013`, `014`, `015`, `019`, `020`.

`ADR-0244`'s axis renumbering has its first real-geometry confirmation. The host
crosshair contract is stated. `VOX-VS1-017` is identified as the one remaining
requirement whose mechanism is present but unwired.

## Affected modules

None. Verification only; no source changed and no dependency added.

## Compatibility impact

None.

## Security impact

None. The verification reads the owner's data through the same admissions as
every other path and adds no entry point.

## Performance and memory impact

None added. Recorded for the record: the three crosshair-selected slices
extracted in `0.14 s` (axial), `0.23 s` (coronal) and `0.68 s` (sagittal). The
sagittal cost is the expected consequence of the least contiguous access pattern.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

Plus the recorded run against the owner's real CT data, extending the
`VOX-VS1-001` demonstration harness. Evidence in
`docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md`. No
repository test reads that path.

## Migration

1. This record: `VOX-VS1-013` discharged and the host contract stated.
2. **`VOX-VS1-017`**: a design record for wiring generation-based staleness into
   the publication path, since the predicate currently governs nothing.
3. **`VOX-VS1-011`**: confirm against the two frozen models rather than rebuild.
4. **`VOX-VS1-010`** differential run, **`VOX-VS1-018`** steady-state
   measurement, **`VOX-VS1-016`** requirement reading.
5. **Non-blocking**: a synthetic-affine composition test in
   `VoxeliaInteractionTests` covering the three-plane round trip, so the
   composition is guarded in CI as well as demonstrated on real data.

## Supersession

This record supersedes nothing and corrects nothing. It adopts `ADR-0247`'s
capability-first assessment method and applies it to the remaining requirements.

## References

- [ADR-0130 - Crosshair slice mapping](ADR-0130-crosshair-slice-mapping.md)
- [ADR-0138 - World-to-index mapping](ADR-0138-world-to-index-mapping.md)
- [ADR-0140 - Crosshair broadcast](ADR-0140-crosshair-broadcast.md)
- [ADR-0244 - Affine axis drop](ADR-0244-affine-axis-drop.md)
- [ADR-0247 - Distance measurement correction](ADR-0247-distance-measurement-correction.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
