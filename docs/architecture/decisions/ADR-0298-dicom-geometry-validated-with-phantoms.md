---
document_id: "ADR-0298"
title: "DICOM geometry validated with phantoms"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-012"
---

# ADR-0298 - DICOM geometry validated with phantoms

## Context

`VOX-VAL-012` requires that "DICOM-derived spatial geometry shall be validated with known
datasets and phantoms". P0, `T` alone, milestone M4, and one of the rows `ADR-0290`'s sweep
found untouched.

It is the row that the analytical phantom arc was always going to serve, and it could not
have been discharged before `ADR-0294` through `ADR-0297` existed.

## The assessment: what was already covered, and what was not

`CTAffineVolumeBuilder` has a twelve-test suite against `VOXELIA-ALG-0049`'s frozen fixtures,
including an oblique series and a determinant underflow. **That checks the matrix.**

What no test checked is the **consequence** of the matrix: that a phantom placed by a geometry
the real ingest path derived lands where its closed form says it should, and that the physical
distances between its endpoints are the known ones. A matrix can be correct element by element
against a fixture and still be validated by nothing that uses it.

So this row is genuinely a `T`, and the increment changes no source.

## What a "known dataset" has to be here

The row asks for known datasets, and the datasets in this suite are **synthetic by
construction**. That is not a compromise, for two independent reasons:

1. **A known dataset is one whose correct answer is known independently.** Real acquisition
   data does not have that property — its true geometry is exactly what one would be trying
   to establish. A constructed series is the only kind whose expected affine can be written
   down before the builder runs.
2. **No test in this repository may read patient data.** That is a standing constraint, and
   it is not in tension with the first: the row's word is "known", not "clinical".

## Decision

1. **The datasets are driven through the real ingest path** — `CTSeriesAssembler`, then
   `CTGeometryValidator`, then `CTAffineVolumeBuilder`. The geometry under test is the one the
   product derives, not one written in the test.
2. **The phantom is placed by the derived geometry**, and its values are asserted against a
   closed form written from the **DICOM inputs** — origin, direction cosines, spacings, slice
   step — rather than read back from the matrix the builder produced. Comparing the matrix
   with itself would pass for any builder.
3. **The in-plane spacings are distinct, and deliberately not in the ratio the ramp hides.**
   `VOXELIA-ALG-0053` weights patient Y by two, so a column spacing exactly twice the row
   spacing would make a transposed pairing produce identical samples. Column spacing `1` with
   row spacing `2` gives `10 + i + 4j - k` where a transposed builder gives
   `10 + 2i + 2j - k`.
4. **The transposition is falsified with a second dataset**, not merely avoided: swapping the
   two spacings in the input produces a phantom that differs at the sampled indices, so the
   first test cannot pass for a builder that crossed the axes the other way.
5. **Physical distance is validated from the DICOM side.** A half-millimetre, two-millimetre
   acquisition is exactly `DistancePhantom`'s admitted configuration, so the phantom is built
   from the spacings and origin **read out of the derived matrix** and its known lengths —
   `5`, `3`, `7`, `9` — are measured through the shipped `MeasurementConstruction`.
6. **The verdict is asserted, not assumed.** A phantom placed by a geometry the validator only
   tolerated would be validating against a dataset the product would flag, so every dataset is
   checked to be `representable` with no findings under the `.exact` tolerance — appropriate
   because a constructed series has no acquisition noise for a looser threshold to forgive.
7. **`VOX-VAL-012` is discharged** by six tests.

## The tests

- **The closed form**: `10 + i + 4j - k` at every index of a `4 x 3 x 3` phantom, exact
  integers, no tolerance.
- **The transposition falsified**: `11` against `12` at `(1, 0, 0)` and `14` against `12` at
  `(0, 1, 0)`.
- **The oblique series**: three-four-five direction cosines, with each derived element
  asserted as the exact product of a spacing and a direction component — the column step is
  `columnSpacing` times the **row** direction, which is the crossing `ADR-0227` froze.
- **Distances from a derived geometry**: all four segments measured through
  `MeasurementConstruction` and equal to their exact integer lengths.
- **Sampling independence from the DICOM side**: a coarser acquisition changes every index
  separation and leaves the measured lengths identical.
- **The datasets are ones the product accepts**: `representable`, no findings.

## Alternatives considered

### Extend `CTAffineVolumeBuilderTests` instead

Rejected. That suite's subject is `VOXELIA-ALG-0049`'s fixtures and it lives beside the
implementation; this row's subject is validation *with phantoms*, and the phantoms live in
`VoxeliaValidation`. Mixing them would put an algorithm's conformance fixtures and a
validation row's evidence in one file where neither could be read independently.

### Use a real DICOM series as the known dataset

Not available, and not what the row needs. See above: patient data is forbidden to these
tests, and its true geometry is not independently known, which is the property "known" means.

### Assert the derived matrix and stop

Rejected. That is what the existing suite already does. The gap this row names is that
nothing consumed the matrix.

### Use equal in-plane spacings

Rejected, and this is the trap worth naming. Equal spacings make a transposed axis pairing
invisible, and `columnSpacing == 2 * rowSpacing` makes it invisible **specifically** to this
ramp because of its weight on Y. Both had to be avoided deliberately.

## Consequences

`VOX-VAL-012` is discharged, and the analytical phantoms built over the last four records now
have a second consumer: the DICOM ingest geometry.

**17 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. Six tests in `VoxeliaValidationTests`; no source file changes.

## Compatibility impact

None.

## Security impact

None. Every dataset is constructed in the test, and no patient data is read.

## Performance and memory impact

None.

## Validation impact

```text
swift build && swift test
swift test --filter "DICOMGeometryPhantomTests"
swift format lint --strict Tests/VoxeliaValidationTests/DICOMGeometryPhantomTests.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1218 tests in 215 suites pass, up from 1212 in 214.

## Migration

1. This record and six tests. No source changed.
2. **Next**: the derived queue's remaining 17 rows.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **discharges** `VOX-VAL-012` using the phantoms
`ADR-0294` through `ADR-0296` built.

## References

- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0295 - Distance phantom](ADR-0295-distance-phantom.md)
- [ADR-0296 - Physical-coordinate ramp phantom](ADR-0296-physical-coordinate-ramp-phantom.md)
- [ADR-0297 - Phantoms through the shipped pipelines](ADR-0297-phantoms-through-the-shipped-pipelines.md)
- [VOXELIA-ALG-0049 - CT affine volume construction](../../algorithms/VOXELIA-ALG-0049-affine-volume-construction.md)
- [VOXELIA-ALG-0053 - Physical-coordinate ramp](../../algorithms/VOXELIA-ALG-0053-physical-coordinate-ramp.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
