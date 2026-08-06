---
document_id: "ADR-0245"
title: "Downstream slice requirement assessment"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-012"
  - "VOX-VS1-013"
  - "VOX-VS1-014"
  - "VOX-VS1-015"
  - "VOX-VS1-016"
---

# ADR-0245 - Downstream slice requirement assessment

## Context

`VOX-VS1-009` is discharged on the owner's real 899-slice series, so the five
requirements downstream of a two-dimensional slice have a real slice to work on for
the first time. Each names a capability the project has built in an earlier
milestone.

The ledger's own instruction for this increment was to **assess what already
satisfies these requirements against a real volume before writing anything**,
because this session's repeated lesson is that composing what exists finds more
than adding to it. That instruction is followed here.

## The assessment

| Requirement | State | Basis |
|---|---|---|
| `VOX-VS1-012` window centre and width | **verified on real data** | Both clinical windows applied to the real axial slice |
| `VOX-VS1-013` linked patient-space crosshairs | implemented, unverified together | `ViewportSyncGroup`, `MPRSliceCoordinator.sliceIndex(forWorldPoint:)` and `(forAxisValue:)` |
| `VOX-VS1-014` quantitative pixel inspection | **gap: position without value** | `PickResolver` returns indices and a world position, never a sample value |
| `VOX-VS1-015` patient-space distance measurement | **gap: not implemented** | Angle, polygon area and voxel volume exist; distance does not |
| `VOX-VS1-016` off-screen output | needs a reading, not code | No `offScreen` symbol exists anywhere in `Sources` |

### VOX-VS1-012 is verified, not merely implemented

`WindowLevelOperation` carries **no geometry guard** — unlike the squeeze
`ADR-0244` had to fix — and propagates the input's `spatialGeometry` unchanged. Run
against the real axial slice it produced `uint8` display output at 512 by 512 in
0.04 s per window, with the geometry preserved, for a **lung window** (centre
-600, width 1500) and a **soft-tissue window** (centre 40, width 400). Those are
the windows a radiologist actually uses, so this is display output from real CT
rather than a synthetic exercise.

### VOX-VS1-014 is the composition this session's pattern predicts

`PickResolver.resolve` returns `sourceX`, `sourceY` and a `worldPosition` that is
`Point3D?` — present when the presentation claim carries an affine and **absent
rather than fabricated** when it does not, which is the right design. What it does
not return is a **sample value**.

"Quantitative pixel inspection" means the number under the cursor. Everything
needed now exists: `PickResolver` gives the index, the published slice gives the
bytes, and `CTValueInterpreter` turns bytes into Hounsfield units. **Nothing joins
them**, and joining them is composition rather than new capability — precisely the
shape of gap the ledger predicted.

### VOX-VS1-015 is a real gap, and a surprising one

The measurement vocabulary holds `AngleMeasurement` (`ADR-0120`),
`PolygonAreaMeasurement` (`ADR-0144`) and `VoxelVolumeMeasurement`. There is **no
distance measurement**.

**The simplest measurement is the missing one while three harder ones exist.** That
is worth stating plainly rather than filing as routine: it suggests the measurement
work followed the interesting problems rather than the required list, and a
requirements-driven sweep would have caught it earlier.

### VOX-VS1-016 needs a reading before any code

The requirement asks for "off-screen output using the same presentation semantics as
the interactive viewport". **No symbol containing `offScreen` exists in the
project.** There are two readings:

- Nothing implements it, and it is a gap.
- **Every** Voxelia rendering path is already off-screen — the renderers produce
  published images and the project has no interactive viewport at all — so "the same
  semantics" is satisfied trivially because there is only one path.

The second is probably right, and *probably* is not a discharge. Settling it means
deciding what "the interactive viewport" refers to in a library with no window, and
that is a question about the requirement rather than about the code.

## A finding beyond the five: two more latent geometry refusals

`ADR-0244` fixed `SqueezeAxesOperation`'s refusal of geometry-bearing volumes. The
same guard exists in two more operations:

- `ProjectIntensityOperation` — `guard spatialGeometry == nil`
- `TransposeAxesOperation` — `guard spatialGeometry == nil`

**Neither is on a first-vertical-slice path**, which was checked rather than
assumed: `MPRSliceCoordinator` contains zero references to transpose, and intensity
projection appears in no `VOX-VS1` requirement. So they are not blocking, and they
are recorded because they are the same latent defect class, discovered the same way,
and will block the first caller that composes them with a real volume.

**`ADR-0244` supplies the answer pattern for transpose**: a permutation of matrix
columns matching the axis permutation, with no arithmetic. Intensity projection is
different — collapsing an axis of extent greater than one genuinely changes the
geometry, and unlike a singleton drop there is real arithmetic to decide.

## Decision

1. **No implementation is added in this increment.** It assesses, and the
   assessment is the deliverable.
2. **`VOX-VS1-012` is claimed as verified on real data**, with the window
   parameters and timings recorded.
3. **`VOX-VS1-014`'s gap is characterised as composition**, and the three pieces
   that must be joined are named.
4. **`VOX-VS1-015` is recorded as not implemented**, with the observation that the
   simplest measurement is the absent one.
5. **`VOX-VS1-016` is recorded as needing a requirement reading**, not code, and
   the likely reading is stated without being claimed.
6. **`VOX-VS1-013` is recorded as implemented but never verified end to end**, which
   is a weaker claim than "works" and a stronger one than "missing".
7. **The two latent geometry refusals are recorded with their scope checked**, so
   the next caller to hit one finds a note instead of a surprise.
8. **Nothing is reported as satisfied on the strength of a type existing.** Three of
   these five requirements have implementations that have never met a real volume,
   and this session has twice found rules that passed every synthetic test without
   ever executing.

## Alternatives considered

### Implement the distance measurement now

Rejected for this increment, and it is the obvious next step. It is a small type
with a real numeric boundary — a Euclidean distance in patient space needs a square
root and a frozen expression order — so it deserves its own record and oracle rather
than being appended to an assessment.

### Claim `VOX-VS1-016` as satisfied on the "only one path" reading

Rejected; see decision 5. The reading is probably right and a probably-right reading
is not a discharge.

### Claim `VOX-VS1-013` as satisfied because the types exist

Rejected; see decisions 6 and 8.

### Fix the two latent geometry refusals while they are in view

Rejected. Neither blocks a requirement, transpose needs its own record even if the
rule is now obvious, and intensity projection needs a genuine decision about
collapsing a non-singleton axis. Doing them opportunistically would be scope drift
away from the requirements that remain.

## Consequences

Five requirements now have an evidenced status instead of an assumed one: one
verified, one implemented-but-unverified, two genuine gaps and one requirement
question.

The next increments are ordered by that assessment rather than by proximity in the
requirement list.

## Affected modules

None. Assessment only; no source changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None. Timings recorded are observations, not budgets.

## Validation impact

```text
Real-data run: publish the 899-slice series, extract axial/coronal/sagittal,
apply a lung and a soft-tissue window. Evidence in
docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record.
2. **`VOX-VS1-014`**: join `PickResolver`, the published slice's bytes and
   `CTValueInterpreter` into quantitative inspection.
3. **`VOX-VS1-015`**: a patient-space distance measurement, with a record, a frozen
   expression order and an oracle for the square root.
4. **`VOX-VS1-013`**: verify the crosshair path end to end on the real volume.
5. **`VOX-VS1-016`**: settle the requirement's reading.
6. Later, and not blocking: geometry handling for transpose and intensity
   projection.

## Supersession

This record supersedes nothing.

## References

- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
- [ADR-0120 - Angle measurement](ADR-0120-angle-measurement.md)
- [ADR-0129 - Physical pick resolution](ADR-0129-physical-pick-resolution.md)
- [ADR-0244 - Affine axis drop](ADR-0244-affine-axis-drop.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
