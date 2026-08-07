---
document_id: "ADR-0293"
title: "Open the analytical phantom arc"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-003"
---

# ADR-0293 - Open the analytical phantom arc

## Context

`VOX-VAL-003` requires that "validation shall use synthetic phantoms for spatial,
intensity and measurement validation". P0, `T` alone, milestone M4, from `ADR-0290`'s
sweep.

## The assessment, and how it differs from the last four rows

`VOX-ERR-004`, `VOX-R2D-003` and `VOX-MPR-014` were each **implemented and untested** — the
increments supplied the `T` and changed no source. This row is not like them.

**`VoxeliaValidation` is a shell.** Its `Public/` and `Internal/` directories are both
empty; the target contains `ApplePlatformGate.swift` and `Module.swift` and nothing else. No
phantom exists anywhere in the repository — the only match for the word is an unrelated
mention in `CTGeometryValidation`.

So this row is genuinely unbuilt, and the increment is construction rather than
verification.

One thing is already right: the target depends on `VoxeliaCPU` and `VoxeliaMetal`, which is
exactly the position the "CPU–Metal difference" purpose in plan §55.1 needs.

## What the plan specifies

§55 names five analytical phantoms, with formulas rather than descriptions:

| Phantom | Definition | Named purposes |
|---|---|---|
| **55.1 Linear ramp volume** | `value(i, j, k) = 2i + 3j − 5k + 100` | trilinear interpolation, value transformation, MPR, CPU–Metal difference |
| **55.2 Physical-coordinate ramp** | `value(x, y, z) = x + 2y − 0.5z` | affine geometry, oblique stack, patient-plane reconstruction |
| **55.3 Fiducial point phantom** | sparse high-value points at known patient coordinates | crosshair, screen mapping, nearest sampling, source identity |
| **55.4 Distance phantom** | endpoints at known physical distances and oblique orientations | patient-space measurement |
| **55.5 Padding phantom** | known padding border around valid CT values | padding classification, interpolation boundary, presentation background, inspection unavailability |

§46.2's exit criterion states what they are for: "known phantoms produce the expected CT
values and physical distances independently of windowing and zoom".

## Mapping the five to the row's three kinds

`VOX-VAL-003` names spatial, intensity and measurement validation. The five phantoms cover
all three, and the mapping is not one-to-one:

- **Spatial** — §55.2's physical-coordinate ramp and §55.3's fiducials.
- **Intensity** — §55.1's index ramp and §55.5's padding border.
- **Measurement** — §55.4's distance endpoints.

The row is discharged when all three kinds have a phantom and a test that consumes it, not
when five types exist.

## The numeric boundaries, and which actually need freezing

1. **§55.1 is exact and needs no specification.** `2i + 3j − 5k + 100` over integer indices
   is integer arithmetic throughout; with bounded extents it is representable in `int16`
   with room to spare, and no evaluation order can change the result.
2. **§55.2 does need one.** `x + 2y − 0.5z` is binary64 over patient coordinates, so the
   summation order is observable, and the result must then be quantised into a stored
   integer type. Both the order and the quantisation rule are frozen decisions, and
   `VOXELIA-ALG-0002`'s ties-to-even is the accepted rounding rule to compose rather than
   restate.
3. **§55.5's padding value must not collide with a legitimate sample.** The border's
   sentinel has to sit outside the range the ramp produces, or a padding test would pass
   for the wrong reason.
4. **§55.4's "oblique orientations" must give exact distances.** Endpoints chosen carelessly
   produce irrational lengths and force a tolerance; Pythagorean triples in three dimensions
   keep them exact, which this project prefers over an epsilon wherever it is available.

## Decision

1. **The analytical phantom arc opens**, with `VOX-VAL-003` as its subject and
   `VoxeliaValidation` as its home.
2. **Increment order, each with its own record:**
   1. **§55.1's index ramp** — exact integer arithmetic, no specification needed, and it
      unblocks the intensity kind immediately.
   2. **§55.4's distance phantom** — chosen second because `ADR-0292` has just verified the
      measurement chain it feeds, so the phantom has a tested consumer on arrival.
   3. **§55.2's physical ramp** — design-first with a `VOXELIA-ALG` specification and an
      independent oracle, because its order and quantisation are observable.
   4. §55.3 and §55.5 after, as their consuming rows need them.
3. **A phantom is a value, not a fixture file.** It is generated from its formula at use, so
   the formula is the artefact and there is nothing to drift. This also keeps the phantoms
   out of `check_release_integrity.py`'s manifest, which governs shipped files.
4. **Phantoms are public.** `VOX-VAL-003` is about validation the project performs, and a
   phantom locked inside a test target cannot be used by the validation reports
   `VOXELIA-VAL-0001` and its successors.
5. **Nothing is discharged by this record.** The row declares `T`, and no phantom exists
   yet.

## Alternatives considered

### Build all five phantoms in one increment

Rejected. Two of them carry numeric boundaries that need a specification and an oracle, and
bundling those with the three that do not is how an unexamined rounding rule ships inside a
larger diff.

### Ship phantoms as fixture files

Rejected; see decision 3. A generated value cannot drift from its formula, a file can, and
the file would then need integrity coverage to detect that it had.

### Put phantoms in a test target

Rejected. The validation reports are deliverables of this project, and a phantom they cannot
reach does not validate anything they publish.

### Treat `VOX-VAL-003` as satisfied by the existing synthetic test fixtures

Rejected, and it was worth considering because many suites already build synthetic volumes.
Those are ad-hoc per test and none is the analytical phantom §55 specifies; a phantom's
value is that its expected result is known in closed form, which a hand-built fixture's is
not.

## Consequences

An arc opens on the first row in this sweep that needs construction rather than
verification.

The four numeric boundaries that need freezing are identified before any of them is
implemented, and the two that do **not** need a specification are named as such so the arc
does not manufacture ceremony for exact integer arithmetic.

`VoxeliaValidation` gains its first public surface in the next increment.

## Affected modules

None yet. The arc will populate `VoxeliaValidation`.

## Compatibility impact

None.

## Security impact

None. Phantoms are synthetic by definition and touch no patient data.

## Performance and memory impact

None yet.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1172 tests in 210 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: §55.1's linear ramp volume in `VoxeliaValidation`, with the intensity-kind
   tests it unblocks.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **opens an arc** against plan §55 and records which of
its boundaries need a specification.

## References

- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0292 - Reconstructed measurement geometry](ADR-0292-reconstructed-measurement-geometry.md)
- [VOXELIA-ALG-0002 - Window level linear](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
