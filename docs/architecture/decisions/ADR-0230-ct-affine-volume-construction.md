---
document_id: "ADR-0230"
title: "CT affine volume construction"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-007"
  - "VOX-VS1-004"
---

# ADR-0230 - CT affine volume construction

## Context

This record performs increment (d) of the `ADR-0226` arc: constructing a Voxelia
affine volume with patient-space geometry, for `VOX-VS1-004` and `VOX-DCM-007`.

`ADR-0229` left this increment three questions to answer rather than assume, and
all three are settled below. Two of them turned out to be different questions
than they appeared.

## The first question dissolves rather than being answered

`ADR-0229` asked where the **nominal slice spacing** comes from, having
deliberately computed only a *spread*. The answer is that the affine never needs
one.

The displacement per slice index is a **vector difference of two stated
positions**, `position[1] - position[0]`. That is the geometry the source
actually stated. It needs no square root, so `VOXELIA-ALG-0047`'s refusal to
normalise the reference normal holds; and it needs no division, mean or median,
so `VOXELIA-ALG-0048`'s refusal to pick a nominal spacing holds. Two earlier
refusals to invent a number turn out to have been the right shape for this
increment, which is the strongest evidence they were correct.

## The finding: a validated series is not a constructible volume

Two fixtures make this concrete, and neither was anticipated when `ADR-0226`
decomposed the arc.

**A perfectly regular series can still fail to construct.** Fixture D3 has
positive, finite, exactly uniform spacings and exactly orthonormal directions, so
`VOXELIA-ALG-0048` reports no findings at all. Its in-plane spacings are
`1e-160`, which `ADR-0227` admits, and the affine's determinant **underflows** to
a subnormal below `Double.leastNormalMagnitude`. `AffineGridGeometry`'s accepted
`ADR-0043` admission rejects it as singular. The rejection is correct and it comes
from the accepted spatial type, not from this algorithm.

**A perfectly regular series can construct and still not reproduce its own
positions.** Fixture D5's consecutive gaps are bit-identical — spacing spread
exactly zero, verdict `representable` — and the uniform affine misplaces a slice
by `0x1.0p-49`. It was found by searching plausible scanner geometry rather than
constructed by hand, because the point is that it arises naturally: **a position
list built by repeated addition has uniform differences without lying on a
uniform lattice.**

Together these say that `representable` is a statement about a series, not a
promise about a volume, and this increment must make its own claims rather than
inherit (c)'s.

## Decision

1. **The slice step is a vector difference of two stated positions.** No unit
   normal, no scalar spacing, no square root, no division. See above.
2. **The index order is column, row, slice**, and the in-plane steps cross:
   the column index advances along `rowDirection` by `columnSpacing`, per the
   `ADR-0227` axis convention. Every frozen fixture uses **distinct** in-plane
   spacings (0.7 and 0.8) so that a swap changes the matrix and fails a test
   rather than transposing volumes silently.
3. **The construction reports a fidelity residual**, the largest absolute
   difference between the position the affine computes for each slice index and
   the position the source stated. A uniform lattice's agreement with the data
   is a measurable fact, and this increment measures it instead of asserting it.
4. **The residual is reported and not judged.** Judging it needs a threshold, and
   that is the same owner gate `ADR-0229` decision 3 named. No fourth threshold
   is added to `CTGeometryTolerance`, which is accepted and stays as it is.
5. **`ADR-0229`'s three verdicts are honoured as follows, which is the second
   question answered:**
   - `representable` — construct.
   - `representableWithWarnings` — **construct, and carry the warnings
     forward.** Both warnings are non-geometric. `presentationDisagreement`
     concerns value comparability, which belongs to the value-transformation
     stage; the geometry is sound, so refusing would discard a valid affine over
     a fact this increment has no authority over.
   - `rejected` — refuse.
6. **A single-member series cannot be constructed, and this is not a
   contradiction of decision 5.** `singleMemberSeries` is a *warning* in
   `ADR-0229` because a one-slice series is a valid series. It is nevertheless
   **not constructible**, because there is no second position to subtract and so
   no slice step. (c) judged regularity; (d) judges constructibility; a series
   can pass one and fail the other.
7. **No slice thickness is invented to rescue the single-slice case.** DICOM's
   Slice Thickness is not the spacing between slices — thickness, gaps and
   overlaps are independent — and `ADR-0227` does not carry it. Supporting a
   one-slice volume requires either an optional thickness field on the
   description or a caller-supplied spacing. Both are **named here and
   implemented in neither**, which is preferable to defaulting to one millimetre
   and calling it geometry.
8. **The `CoordinateSpaceDescriptor` is a required caller input, exactly
   validated.** `AffineGridGeometry` needs a convention, handedness, unit and
   external references; the neutral description carries none of them, because
   they are not facts a frame states. The construction requires the descriptor
   and admits it only when its `id` matches the series' coordinate space on
   exact UTF-8 bytes, and when any frame-of-reference the series carries appears
   among the descriptor's external references. That second rule is how
   `VOX-DCM-007`'s frame-of-reference preservation reaches the volume rather than
   stopping at the series.
9. **Construction throws a payload-free typed error family** rather than
   returning a verdict. Assessment is a judgement with degrees, so `ADR-0229`
   returns one; construction either produces a value or does not.
10. **The sample-ownership question `ADR-0227` decision 2 deferred here is
    answered now, and only its implementation moves to increment (e):
    direct-write into a caller-provided destination.** The plan's §16.1 requires
    transfer "without unnecessary intermediate copies", and of its three
    candidates only direct-write achieves that: the volume allocates once and
    each frame decodes straight into its slice offset. An owned buffer adds one
    copy per frame and a borrowed buffer adds one plus a lifetime rule. The
    decision needed no adapter to make; the *plumbing* needs the adapter that
    produces the buffers, so `CTFrameRecord` lands with the shim. **This is a
    deferral of code, not of the question.**

## Alternatives considered

### Normalise the reference normal and use a scalar slice spacing

Rejected; see decision 1. It would add a square root and a zero-magnitude
threshold to compute something the vector difference already gives exactly.

### Take the slice step as `(lastPosition - firstPosition) / (count - 1)`

Rejected, and it is the most defensible alternative. It makes the first and last
slices land exactly and distributes error in between, where the first-difference
rule can accumulate it. It was rejected because it introduces a division —
another rounding boundary — and because the fidelity residual of decision 3
makes the accumulated error **visible** rather than merely smaller. A caller who
finds the residual unacceptable has the evidence to say so, which is worth more
than a quietly better average.

### Judge the fidelity residual against a threshold

Rejected; see decision 4. It is the tolerance gate again under another name.

### Refuse to construct from `representableWithWarnings`

Rejected; see decision 5. It would discard a geometrically sound volume because
of a value-comparability fact this increment has no authority over.

### Default a one-millimetre slice thickness for single-slice series

Rejected; see decision 7. It would fabricate geometry, and a fabricated
millimetre is indistinguishable from a measured one once it is in the matrix.

### Derive the coordinate-space descriptor from the series

Rejected; see decision 8. Convention and handedness are not facts a CT frame
states, and inventing them would put a patient-orientation claim in a type that
never made one.

### Add the fidelity residual as a fifth `CTGeometryTolerance` threshold

Rejected. `CTGeometryTolerance` is accepted; growing it here would edit an
accepted decision rather than compose it.

## Consequences

The arc now has a construction whose two failure modes are both recorded with
fixtures, one of which — determinant underflow from a validated series — would
have been a surprising runtime throw rather than a documented boundary.

Every constructed volume carries a measured fidelity residual, so the claim "this
volume represents that series" is quantified rather than asserted.

The single-slice case is unsupported and named, adding no gate but one explicit
unimplemented option.

## Affected modules

`VoxeliaImaging` gains the construction, its result value and its failure family.
No module's dependencies change. No third-party dependency is added.

## Compatibility impact

Additive only. `CTGeometryTolerance` and `AffineGridGeometry` are unchanged.

## Security impact

None. The failure family is payload-free.

## Performance and memory impact

One pass over the members for the residual; the matrix is a fixed sixteen
elements. No allocation per slice.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0230-affine-volume-oracle.py
swift build && swift test
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This increment: `VOXELIA-ALG-0049`, its oracle, and this record.
2. Next: the construction, verified against all six frozen fixtures.
3. Increment (e): the DICOMKit shim, `CTFrameRecord` with the direct-write
   ownership model decision 10 fixes, the manifest dependency, the
   `THIRD_PARTY_NOTICES.md` entry and the licence-gate update.

## Supersession

This record supersedes nothing. It performs increment (d) of `ADR-0226`, answers
the three questions `ADR-0229` left it, and answers the ownership question
`ADR-0227` decision 2 deferred.

## References

- [ADR-0043 - Spatial descriptor admission boundary](ADR-0043-spatial-descriptor-admission-boundary.md)
- [ADR-0226 - DICOM ingest arc](ADR-0226-dicom-ingest-arc.md)
- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [ADR-0228 - CT series grouping](ADR-0228-ct-series-grouping.md)
- [ADR-0229 - CT series geometry validation](ADR-0229-ct-series-geometry-validation.md)
- [VOXELIA-ALG-0049 - CT affine volume construction](../../algorithms/VOXELIA-ALG-0049-affine-volume-construction.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
