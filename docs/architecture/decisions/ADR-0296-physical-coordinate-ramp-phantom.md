---
document_id: "ADR-0296"
title: "Physical-coordinate ramp phantom"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-003"
---

# ADR-0296 - Physical-coordinate ramp phantom

## Context

`ADR-0293` placed plan §55.2's physical-coordinate ramp third in the analytical phantom arc
and marked it the one increment that had to be **design-first**: its numeric boundary 2 said
the summation order is observable and the result must then be quantised into a stored
integer, so it needs a specification and an independent oracle before any Swift.

```text
value(patientX, patientY, patientZ) = patientX + 2patientY - 0.5patientZ
```

`VOXELIA-ALG-0053` is that specification, written and its four fixtures computed
independently before this implementation existed.

## What the oracle established before the code was written

The order is not merely observable in the bits — it changes the **published integer**.

Fixture D, a three-four-five rotation with a non-dyadic `0.3` slice spacing, contains two
samples where a right-associated or reordered evaluation rounds differently:

| Index | Frozen | Right-associated | Reordered |
|---|---|---|---|
| `(2, 1, 2)` | `4.500000000000001` → `5` | `4.5` → `4` | `4.5` → `4` |
| `(3, 3, 2)` | `7.5` → `8` | `7.499999999999999` → `7` | `7.5` → `8` |

That is the justification for the specification existing, and it is measured rather than
asserted. It also shows why the other two phantoms in this arc correctly have none: §55.1 is
exact integer arithmetic and §55.4's lengths are certified by an integer identity, so neither
has an order that any implementation could disagree about.

A fused final term produced no bit difference on any of the four fixtures. That is a
measurement of those fixtures, not a property of the operation, and the no-fused-multiply-add
rule stands regardless.

## Decision

1. **`PhysicalRampPhantom` implements `VOXELIA-ALG-0053` and nothing more.** The
   index-to-patient step composes `ADR-0138`'s frozen forward evaluation, the rounding
   composes `VOXELIA-ALG-0002`'s ties-to-even, and the affine admission composes
   `VOXELIA-ALG-0052`'s exact structural test.
2. **Which frozen affine accumulation applies is named, not assumed.** Voxelia has two that
   differ in where the translation lands — `ADR-0138`'s forward evaluation adds it **first**,
   `VOXELIA-ALG-0052`'s composition adds it **last**. The specification names the first.
3. **A sample outside `Int16` is refused, not clamped**, departing from
   `VOXELIA-ALG-0002`. Saturation is what a display window means; for a phantom it would
   publish an expected value that is not the ramp's value. Same reasoning as `ADR-0294`.
4. **Corner admission is used at construction and described for exactly the strength it
   has.** The ramp composed with an affine is itself affine in the indices, so in exact
   arithmetic its extremes over the box lie at corners; the eight corners are evaluated on
   admission and **every sample is checked again on evaluation**, because binary64 rounding
   is not obliged to preserve that ordering at the last place.
5. **`VOX-VAL-003` is still not discharged, and this record declines to discharge it.** See
   below — the reason matters more than the outcome.

## Why the row is not discharged even though all three phantoms now exist

`ADR-0293` wrote that the row is discharged "when all three kinds have a phantom **and a test
that consumes it**, not when five types exist". All three kinds now have a phantom. The tests
are not equal, and the difference is the whole point:

| Kind | Phantom | What its tests actually do |
|---|---|---|
| Measurement | §55.4 | Feeds patient-space endpoints into the **shipped** `MeasurementConstruction` |
| Intensity | §55.1 | Compares the phantom against an independent transcription of its formula |
| Spatial | §55.2 | Compares the phantom against `VOXELIA-ALG-0053`'s independent fixtures |

Only the measurement phantom is currently used to validate **product behaviour**. The other
two verify that the phantom is what it claims to be — necessary, and not the same thing.

Plan §46.2's exit criterion is that "known phantoms produce the expected CT values and
physical distances independently of windowing and zoom", which is a statement about a
pipeline, not about a phantom. Discharging the row on three self-verifying suites would be
claiming that criterion on evidence that never runs the pipeline.

**The remaining obligation, precisely**: a test that drives the §55.1 ramp through value
transformation, and one that drives the §55.2 ramp through an oblique or multiplanar
reconstruction. Both are small now that the phantoms exist, and both are the next increment.

## The tests

Fourteen. The fixture suites transcribe `VOXELIA-ALG-0053`'s sequences rather than generating
them, and all twelve fixture and geometry tests passed on the first run — the Swift
evaluation reproduced the Python oracle exactly, which is the outcome a design-first
increment is supposed to produce.

Beyond the four fixtures:

- **The rounding rule is asserted against its rival.** Fixture A's first two rows are
  `1.0, 1.5, 2.0, 2.5` and `2.0, 2.5, 3.0, 3.5` before rounding; the suite asserts both the
  ties-to-even result and that it differs from what ties-away would publish. Fixture C adds a
  **negative** half, `-0.5`, which ties-away would send to `-1`.
- **The association claim is falsified in the suite**, not left in prose: at fixture D's two
  named indices the test evaluates the rival association against the phantom's own patient
  positions and asserts it rounds differently.
- **Fixture B is checked twice**, once against the specification's sequence and once against
  its exact reduced form `0.875i + 2.5j + 0.5k`, which is available only because every
  element of that shear is dyadic.
- **Corner admission's soundness is asserted**, not assumed: on both oblique fixtures the
  extreme sample over the whole box equals the extreme over the eight corners.

Two of my own expectations were wrong and the suite caught both. The identity matrix at
`(1, 1, 1)` gives `2.5`, which ties to the even `2` and not to `3`. And a test claiming an
interior sample could escape `Int16` while every corner fits was **unconstructible** — the
composed value is affine in the indices, so no such geometry exists. That test was replaced
by one asserting the property that makes corner admission sound in the first place.

## Alternatives considered

### Clamp out-of-range samples, as `VOXELIA-ALG-0002` does

Rejected; see decision 3. Composing a model's rounding does not oblige composing its
saturation, and the reason the two differ is that one describes a display and the other
describes ground truth.

### Let the phantom own its own affine convention

Rejected. Two frozen accumulations already exist, and inventing a third would mean a phantom
whose geometry disagrees with the pick resolver it is meant to validate.

### Check every sample at construction

Rejected as a false economy in both directions: it is `O(n)` on a value that may never be
materialised, and it would still not be a proof for an evaluation that rounds. Corner
admission plus a per-sample guard says exactly what is true.

### Discharge `VOX-VAL-003` now

Rejected; see above. Three phantoms and three self-verifying suites are not the same as the
plan's exit criterion, and recording that difference is worth more than closing the row.

## Consequences

The spatial kind of `VOX-VAL-003` has a phantom, and the arc's one genuinely order-sensitive
boundary is frozen, oracled and reproduced bit-for-bit.

All three kinds now exist. The row stays open on a **named, small** obligation rather than an
unexamined one.

## Affected modules

`VoxeliaValidation` gains `PhysicalRampPhantom` and `PhysicalRampPhantomError`, both listed in
its DocC catalogue. No dependency changes — `VoxeliaSpatial` was already imported by
`DistancePhantom`.

## Compatibility impact

Additive.

## Security impact

None. The phantom is synthetic by definition and touches no patient data.

## Performance and memory impact

`storedBytes()` evaluates one affine row triple and three arithmetic operations per sample.
The phantom itself holds three integers, a matrix and a coordinate-space identifier.

## Validation impact

```text
swift build && swift test
swift test --filter "PhysicalRampPhantomTests"
swift format lint --strict Sources/VoxeliaValidation/Public/PhysicalRampPhantom.swift
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_prohibited_imports.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1208 tests in 213 suites pass, up from 1194 in 212.

## Migration

1. `VOXELIA-ALG-0053`, this record, the phantom and fourteen tests.
2. **Next**: drive the §55.1 ramp through value transformation and the §55.2 ramp through an
   oblique reconstruction, which is what `VOX-VAL-003` still needs.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **implements plan §55.2** under `ADR-0293`'s frozen arc
decisions and discharges that record's numeric boundary 2.

## References

- [ADR-0138 - World to index mapping](ADR-0138-world-to-index-mapping.md)
- [ADR-0293 - Open the analytical phantom arc](ADR-0293-open-the-analytical-phantom-arc.md)
- [ADR-0294 - Linear ramp phantom](ADR-0294-linear-ramp-phantom.md)
- [ADR-0295 - Distance phantom](ADR-0295-distance-phantom.md)
- [VOXELIA-ALG-0002 - Window level linear](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [VOXELIA-ALG-0053 - Physical-coordinate ramp](../../algorithms/VOXELIA-ALG-0053-physical-coordinate-ramp.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
