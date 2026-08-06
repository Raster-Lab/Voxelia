---
document_id: "ADR-0250"
title: "Interpolation analytical confirmation"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-003"
  - "VOX-VS1-011"
---

# ADR-0250 - Interpolation analytical confirmation

## Context

`VOX-VS1-011` requires the first vertical slice to provide nearest-neighbour and
linear interpolation, and declares `T` alone. `ADR-0248` sized it as "likely
already satisfied; needs confirmation, not construction". This record performs
that confirmation.

**`ADR-0217` already discharged the row**, citing `ResampleNearestOperation` and
`ResampleLinearOperation` under `VOXELIA-ALG-0008` and `VOXELIA-ALG-0015`, their
test suites, and the `InterpolationPolicy` vocabulary `ADR-0124` added. That
discharge stands and is **not re-claimed here** — a second record claiming the
same row would double-count it.

What this record adds is the part the confirmation actually turned up.

## The finding: the discharge is right, and its citation is incomplete

The plan's §28.2 states that **"linear interpolation shall operate in
three-dimensional continuous index space"**. `ResampleLinearOperation` is
*bilinear* — rank two. So the two operations `ADR-0217` cites do not, between
them, cover the clause the plan writes for linear interpolation.

The capability nevertheless exists, in a record `ADR-0217` did not name:
`ObliqueSliceOperation` performs the trilinear reduction over three-dimensional
continuous index space, with its own frozen fixtures. So:

- **The conclusion `ADR-0217` reached is correct**: the row is satisfied.
- **Its evidence was under-cited**: the 3D clause is met by the oblique slice
  operation's trilinear reduction, which that record does not mention.

This is recorded here rather than by editing `ADR-0217`, per standing practice.
It is worth stating plainly because the two dimensionalities are easy to conflate
— the requirement's one-line text says only "linear interpolation", and searching
for that phrase finds the rank-two operations first. **Dimensionality was the
discriminator, and only §28.2 supplies it.**

## The second finding: there is no nearest mode for volume sampling

`ObliqueSliceOperation` is trilinear **only**. No `InterpolationMode` type exists
at the volume-sampling boundary, and the only nearest-neighbour sampler in the
project is the rank-two `ResampleNearestOperation`. So a caller cannot ask for
nearest-neighbour sampling of a volume at a non-integer position.

**This is not a `VOX-VS1-011` gap, and the reason is specific rather than
convenient.** Every first-vertical-slice reconstruction path is axis-aligned:
`MPRSliceCoordinator` composes region extraction with a singleton axis drop, so
each output sample *is* a stored voxel. Where every sample lands exactly on a
sample point, nearest and linear agree exactly — which the accepted suite already
demonstrates in `integerCoordinatesReproduceTheStoredPlane`, and which the new
suite extends over all twenty-seven samples. The interpolation *mode* cannot
change an axis-aligned result, so the first slice's reconstruction does not
depend on having a 3D nearest sampler.

It is a genuine gap for **oblique** slicing and for volume rendering, where
positions are not sample points. `InterpolationPolicy` already names
`.nearestNeighbour` and `.linear` as a display policy, so the vocabulary exists
without a volume-sampling implementation behind the nearest case. That is a real
absence and it belongs to whichever row requires oblique or DVR interpolation
selection — recorded here so a later increment finds it named rather than
discovering it as a surprise.

## Decision

1. **`VOX-VS1-011` is confirmed as discharged by `ADR-0217`, not re-discharged
   here.** This record adds evidence and corrects a citation; the row's claim
   stays where it was made.
2. **`ADR-0217`'s citation is completed**: the plan's three-dimensional clause is
   satisfied by `ObliqueSliceOperation`'s trilinear reduction, in addition to the
   rank-two operations that record names.
3. **The analytical property the plan asks for is now stated as a test.** §1957
   names the verification method for CPU linear interpolation as *analytical*
   equality. The accepted suites verify frozen fixtures and the integer-coordinate
   case; neither states the property that makes an interpolator linear — that it
   reproduces a linear function **everywhere**, not only at the samples. Three
   tests now do: linear precision over twelve interior positions, exactness at all
   twenty-seven samples, and monotonicity in quarter steps along each axis.
4. **No tolerance is introduced, and none is needed.** The plan's phrase is
   "analytical bounded numerical equality", which invites an epsilon. Instead the
   cases are chosen so the arithmetic is exact: the ramp coefficients are small
   integers and every sampled position is a half- or quarter-integer, so every
   weight is an exact binary fraction. Choosing provably exact cases is this
   project's standing alternative to inventing a threshold, and it leaves the
   geometry tolerance owner gate untouched.
5. **The expected value composes `VOXELIA-ALG-0002`'s ties-to-even output
   quantisation rather than assuming whole numbers.** This was not the first
   version of the test, and the correction is the useful part — see below.
6. **No nearest-neighbour volume sampler is added.** There is no first-slice
   consumer, and adding one would mean choosing a tie rule and a
   selection vocabulary with no requirement to constrain them. The absence is
   recorded in the second finding instead of quietly filled.
7. **No algorithm specification and no oracle.** Nothing new is frozen: the test
   composes `VOXELIA-ALG-0017`'s trilinear reduction and `VOXELIA-ALG-0002`'s
   quantisation, both accepted.

## The test's own first version was wrong, and that is worth recording

The linear-precision test initially asserted the unquantised ramp value and
**failed on exactly two of twelve cases**: at `(0.25, 0, 0)` and `(0.75, 0, 0)`.

The ramp's first coefficient is `2`, so those positions have exact values `0.5`
and `1.5` — not whole numbers. The output is `uint8`, and the observed bytes were
`0` and `2`. That is `VOXELIA-ALG-0002`'s ties-to-even rounding behaving exactly
as accepted: `0.5` to `0`, `1.5` to `2`, both to even.

**The interpolator was right and the expectation was wrong** — the test's premise
that half- and quarter-integer positions give whole numbers held for the
coefficients `6` and `18` but not for `2`. Composing the accepted quantisation
rule fixed it and made the assertion **stronger than intended**: it now pins the
interpolation and the output rounding together, so a change to either fails here.

Recorded because a test whose first run passes tells you less than one whose first
run finds a real disagreement and forces you to work out which side was wrong.

## Alternatives considered

### Re-discharge `VOX-VS1-011` in this record

Rejected. `ADR-0217` claimed it, and a row claimed twice is a traceability defect
even when both claims are true.

### Add an epsilon and assert bounded equality as the plan's wording suggests

Rejected; see decision 4. The plan permits a bound, but a bound this project chose
for itself would be exactly the invented threshold the geometry tolerance gate
exists to prevent. Exact cases are available here, so no bound is required.

### Add a nearest-neighbour volume sampler now

Rejected; see decision 6. It would need a tie rule frozen with no requirement to
justify it, and `ADR-0248`'s method — read the capability, not the vocabulary —
says to check for a consumer first. There is none in the first slice.

### Assert linear precision on the real CT volume

Rejected as evidence, though it would look impressive. The property is
mathematical, and a real volume is not a linear function — any deviation would be
the data's, not the interpolator's, and the test would need a tolerance to
survive. The synthetic ramp is what makes exactness available.

## Consequences

`VOX-VS1-011` is confirmed with its three-dimensional clause now evidenced. The
first vertical slice stands at **sixteen of twenty** rows, with `010`, `016` and
`018` remaining.

The absence of a nearest-neighbour volume sampler is named and attributed to
oblique and DVR work rather than to this row.

## Affected modules

None. `VoxeliaExecutionTests` gains one suite; no source changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter "InterpolationAnalytical"
swift test
swift format lint --strict Tests/VoxeliaExecutionTests/InterpolationAnalyticalTests.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1019 tests in 191 suites pass.

## Migration

1. This record and its suite.
2. **Open, not part of this row**: a nearest-neighbour volume sampler with a
   frozen tie rule and a selection vocabulary, for whichever row requires oblique
   or volume-rendering interpolation selection.
3. Remaining first-slice rows: `010` Metal differential, `016` requirement
   reading, `018` steady-state measurement.

## Supersession

This record supersedes nothing. It **completes `ADR-0217`'s citation** for
`VOX-VS1-011`, recording the addition here rather than editing that record.

## References

- [ADR-0124 - Display policy selection](ADR-0124-display-policy-selection.md)
- [ADR-0217 - Vertical slice traceability](ADR-0217-vertical-slice-traceability.md)
- [ADR-0248 - Linked crosshair verification](ADR-0248-linked-crosshair-verification.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
