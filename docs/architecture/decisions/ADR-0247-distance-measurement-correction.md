---
document_id: "ADR-0247"
title: "Distance measurement correction"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-009"
  - "VOX-VS1-015"
---

# ADR-0247 - Distance measurement correction

## Context

`ADR-0245` assessed `VOX-VS1-015`, patient-space distance measurement, as **not
implemented**, and drew an inference from that: "the simplest measurement is the
missing one while three harder ones exist", suggesting the measurement work had
followed the interesting problems rather than the required list.

**Both the finding and the inference were wrong.** This record corrects them and
verifies the requirement on real data.

## The correction

`VOXELIA-ALG-0010 - Polyline length binary64-v1` has been accepted since
milestone M2, selected by `ADR-0111`. It freezes exactly:

```text
dx = b.x - a.x
s  = ((dx * dx) + (dy * dy)) + (dz * dz)
length = sqrt(s)
```

with no fused multiply-add and left-to-right accumulation across segments. **A
two-point polyline is a distance measurement**, and `MeasurementConstruction`
implements the model, computing `derivedLength` once at construction with the
coordinate-space check `VOX-INT-009` requires.

So the capability exists, the boundary is frozen, and an oracle-bearing
specification already governs it.

## Why the assessment missed it, which is the transferable part

`ADR-0245` searched for `DistanceMeasurement`, `measureDistance` and the word
"distance". The implementation is called `MeasurementConstruction` and its property
is `derivedLength`.

**The search was for a name rather than for a behaviour.** That is the same class of
error as `ADR-0237`'s — searching the source for an evaluator instead of the register
for a boundary — and the register would have answered this one too: the algorithm
index lists "Polyline length" plainly, and a distance is its two-point case.

**The rule this yields, extending `ADR-0237`'s:** search the register for the
*capability* the requirement asks for, and expect the general case to be listed
rather than the specialisation. Angle, polygon area and voxel volume are the
specialisations here; the polyline length is the general one, so it was the least
likely to be named after the requirement.

The inference about project priorities was therefore built on a false premise, and
it is withdrawn: the measurement work did not skip distance. It implemented the
general case and specialised from it.

## Verified on real data, with the difference attributed rather than excused

Two points 100 columns apart in the real axial plane, whose DICOM Pixel Spacing is
`0.95313671875` mm:

```text
distance 100 columns apart: measured 95.31367187500001 mm
                            naive prediction 95.313671875 mm   (differ by 1 ULP)
distance 100x100 diagonal:  134.793887445204 mm
```

**The naive prediction was wrong, not the measurement**, and the attribution was
computed rather than assumed:

| Step | Exact? |
|---|---|
| `sqrt(dx * dx) == dx` | **yes, exactly** — the `ALG-0010` model contributes zero error |
| `dx == 100 * spacing` | **no** — one ULP |

The whole difference comes from the **affine's origin subtraction**:
`(origin + s·200) − (origin + s·100)` is not `100·s`, because both intermediates
round against the origin's magnitude of about `-249.5` before being subtracted.

**That is what a real measurement does.** A tool that reported `100 × spacing` would
be reporting a number the geometry does not produce; going through patient-space
coordinates and subtracting them is the measurement, and its rounding is a property
of the coordinate round trip rather than of the length model.

## Decision

1. **`VOX-VS1-015` is satisfied**, by `MeasurementConstruction` under
   `VOXELIA-ALG-0010`, and verified on real patient geometry.
2. **`ADR-0245`'s "not implemented" finding is corrected here**, not by editing that
   record.
3. **`ADR-0245`'s inference about project priorities is withdrawn.** It was reasoning
   from a false premise, and leaving it standing would leave a wrong judgement about
   the project's own history on the record.
4. **No code is added.** The capability exists; discovering that is the increment's
   whole value, and adding a second distance type would have been the duplicate this
   project has now corrected twice.
5. **The one-ULP difference is recorded with its attribution**, because a reader who
   finds the number later needs to know it is the coordinate round trip and not a
   defect in the length model.
6. **A composition observation, not a gap:** `PickResolver` exposes an exact physical
   position only for a *rendered presentation*, so measuring on a bare published slice
   needs the `ADR-0129` index-to-world step, which the verification harness performed
   directly. In a viewer a measurement always happens on a presentation, so the
   product path is complete; this is recorded so the absence is understood rather than
   rediscovered.

## Alternatives considered

### Implement a distance measurement anyway, for a clearer name

Rejected. A second type computing the same frozen model is the duplicate `ADR-0237`
corrected and `ADR-0246` declined to repeat. If the name is the problem, the fix is
documentation or a convenience initialiser on the existing type, in a record that says
so.

### Report the one-ULP difference as a discrepancy to investigate

Rejected. It was investigated, and it is explained exactly: the length model is
exact for this input and the coordinate round trip is not. Reporting an explained
difference as open would be noise.

### Leave `ADR-0245`'s inference in place as a minor error

Rejected; see decision 3. It is a judgement about the project's own engineering
history, and a wrong one is worse than none.

## Consequences

`VOX-VS1-015` moves from "gap" to satisfied without any code, and the requirement
count is corrected downward for the right reason.

The register-search rule is extended: look for the general capability, not the
requirement's wording.

## Affected modules

None. Assessment and correction only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Real-data verification recorded in
docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record.
2. **`VOX-VS1-013`**: verify the crosshair path end to end on the real volume.
3. **`VOX-VS1-016`**: settle the requirement's reading.
4. Then `010`, `011`, `017` and `018`, none of which has been assessed yet.

## Supersession

This record supersedes nothing. It **corrects `ADR-0245`'s finding and withdraws its
inference**, recording both here rather than editing that record.

## References

- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
- [ADR-0129 - Physical pick resolution](ADR-0129-physical-pick-resolution.md)
- [ADR-0237 - Duplicate rescale freeze correction](ADR-0237-duplicate-rescale-freeze-correction.md)
- [ADR-0245 - Downstream slice requirement assessment](ADR-0245-downstream-slice-requirement-assessment.md)
- [ADR-0246 - Quantitative sample inspection](ADR-0246-quantitative-sample-inspection.md)
- [VOXELIA-ALG-0010 - Polyline length](../../algorithms/VOXELIA-ALG-0010-polyline-length.md)
