---
document_id: "VOXELIA-ALG-0048"
title: "CT series geometry validation binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# CT series geometry validation binary64-v1

## Purpose

This specification defines `series-geometry-validation/binary64-v1`, the
deterministic assessment of an assembled CT series, selected by accepted
[`ADR-0229`](../architecture/decisions/ADR-0229-ct-series-geometry-validation.md).
It fixes what is measured, how each measurement is computed, and how a supplied
tolerance turns measurements into a verdict.

It serves `VOX-VS1-003` and `VOX-DCM-009`.

## Measurement and judgement are separated

The specification's organising rule: **every quantity is an exact measurement,
and no threshold appears anywhere in the arithmetic.** Thresholds enter once, at
the end, as a supplied policy value.

This matters because a tolerance is a clinical safety parameter while a
measurement is a fact. Mixing them would make the numbers a series is judged by
irreproducible without also fixing the judgement, and would bury a threshold
inside a comparison where no oracle could see it.

## The measurements

Let the members be in the order `VOXELIA-ALG-0047` produced, and let the
**anchor** be the member first in exact `SourceIdentity` byte order — the same
anchor that specification chose, not a second rule.

### Slice spacings

```text
spacing[i] = t[i + 1] - t[i]        for i in 0 ..< count - 1
```

Absent when the series has fewer than two members, and absent when the series is
**not ordered by projection** — that is, when assembly reported any observation —
because differences of a fallback ordering measure nothing.

### Spacing spread

```text
sliceSpacingSpread = maximum(spacing) - minimum(spacing)
```

This is the irregularity measure, and it is deliberately **not** a deviation
from a nominal spacing. A nominal spacing would have to be an anchor (arbitrary),
a mean (a division and a summation order to freeze) or a median (a sort and an
even-count tie rule). The spread needs none of them and answers the question
directly: by how much do the spacings vary? A regular series gives exactly zero.

### Orientation deviation

```text
maximumOrientationDeviation =
    max over members, over the six direction components, of
        abs(component - anchorComponent)
```

Componentwise, never a norm. A norm would square and then require a square root,
adding an overflow path and a second boundary for nothing.

### In-plane spacing deviation

```text
maximumInPlaneSpacingDeviation =
    max over members of
        abs(rowSpacing - anchorRowSpacing),
        abs(columnSpacing - anchorColumnSpacing)
```

### Orthonormality residuals

Computed on the anchor only, in this frozen expression order, with no fused
multiply-add and no square root:

```text
rowColumnDotProduct   = ((rx * cx) + (ry * cy)) + (rz * cz)
rowMagnitudeResidual  = (((rx * rx) + (ry * ry)) + (rz * rz)) - 1
columnMagnitudeResidual = (((cx * cx) + (cy * cy)) + (cz * cz)) - 1
```

### Exact predicates

```text
hasDuplicateProjections = any adjacent pair has t[i] == t[i + 1]
hasUniformGrid          = every member shares the anchor's rows, columns
                          and scalar format
```

Duplicate detection uses IEEE numeric equality, which treats `+0` and `-0` as
equal. It is absent when the series is not ordered by projection.

## The tolerance is supplied, and only one value is defined

A tolerance carries four thresholds: orientation component, in-plane spacing,
slice spacing, and orthonormality residual.

**This specification defines exactly one value: `exact`, with all four
thresholds zero.** No permissive default is defined, because a permissive
threshold is a clinical safety parameter and this project holds no evidence that
would justify a number. `ADR-0229` records that gate.

**Exact is less brittle than it sounds, and fixture G13 is the evidence.** Two
different decimal spellings that round to the same binary64 value produce a
deviation of *exactly* zero and are admitted. Exact tolerance forgives
re-spelling; it refuses only values that land on genuinely different doubles.

## The verdict

A finding is raised when its measurement exceeds its threshold, using strict
`>` on the absolute value where a residual may be signed.

| Finding | Raised when |
|---|---|
| `nonUniformGrid` | `hasUniformGrid` is false |
| `duplicateProjections` | `hasDuplicateProjections` is true |
| `singleMemberSeries` | the member count is one |
| `orientationDisagreement` | orientation deviation exceeds its threshold |
| `inPlaneSpacingDisagreement` | in-plane deviation exceeds its threshold |
| `sliceSpacingIrregular` | the spread is present and exceeds its threshold |
| `nonOrthogonalDirections` | `abs(rowColumnDotProduct)` exceeds the residual threshold |
| `nonUnitDirections` | either magnitude residual's absolute value exceeds it |
| `presentationDisagreement` | rescale slope, rescale intercept or photometric interpretation differs across members |

The three assembly observations — `degenerateReferenceNormal`,
`nonFiniteReferenceNormal`, `nonFiniteProjection` — are **inherited from
`VOXELIA-ALG-0047` and never recomputed**. There is one place each fact is
established.

Findings are then classified:

- **Warnings**: `singleMemberSeries`, `presentationDisagreement`.
- **Rejections**: every other finding.

```text
if any rejecting finding      -> rejected
else if any warning finding   -> representableWithWarnings
else                          -> representable
```

`presentationDisagreement` is a warning rather than a rejection because it is
**not a geometry fact**: contradictory rescale terms make a volume's values
incomparable, which is the value-transformation stage's judgement under
`VOX-DCM-006`, the same stage `ADR-0227` decision 5 assigned the degenerate
rescale slope to. It is measured and reported here so the condition is visible
rather than unowned.

## Numeric rules

- IEEE-754 binary64 throughout, in the frozen expression order above.
- No fused multiply-add, no reassociation, no vectorised reduction.
- No square root, no division, no normalisation.
- No threshold in any measurement; thresholds only in the verdict.

## Frozen fixtures

Computed by the independent oracle at
`docs/progress/evidence/ADR-0229-geometry-validation-oracle.py`, all under the
`exact` tolerance.

| Fixture | Input | Verdict | Key measurement |
|---|---|---|---|
| G1 | Regular 3-slice axial, spacing 2.5 | `representable` | spread `0x0.0p+0` |
| G2 | One spacing short by 1e-4 mm | `rejected` | spread `0x1.a36e2eb1c0000p-14` |
| G3 | A missing slice doubles one gap | `rejected` | spread `0x1.4000000000000p+1` |
| G4 | Two co-located slices | `rejected` | duplicate, min spacing `0x0.0p+0` |
| G5 | Mixed grid (512 and 256 rows) | `rejected` | `hasUniformGrid` false |
| G6 | Orientation differing by one ULP | `rejected` | deviation `0x1.0p-52` |
| G7 | Column `(0.5, 0.5, 0)` | `rejected` | dot `0x1.0p-1`, residual `-0x1.0p-1` |
| G8 | Row `(3, 0, 0)` | `rejected` | row residual `0x1.0p+3` |
| G9 | One member | `representableWithWarnings` | spacings absent |
| G10 | Degenerate normal from assembly | `rejected` | spacings absent, finding inherited |
| G11 | In-plane spacing 0.7 and 0.71 | `rejected` | deviation `0x1.47ae147ae1480p-7` |
| G12 | Rescale slope 1.0 and 2.0 | `representableWithWarnings` | geometry all zero |
| G13 | Two spellings of one double | `representable` | deviation exactly `0x0.0p+0` |

Three fixtures carry the specification's weight.

**G2** is the case an intuitive design gets wrong. A spacing short by one
ten-thousandth of a millimetre is physically negligible and is still rejected
under `exact`, and the spread is `9.999999999976694e-05` rather than exactly
`1e-4` because it is a difference of two binary64 values. Both facts are the
point: the measurement is exact and reproducible, and the judgement is the
tolerance's to make, not the measurement's.

**G10** proves the observations are inherited. Its members have equal
projections, so a validator that recomputed spacings would report an irregular
spacing; the correct result reports only the assembly's
`degenerateReferenceNormal`, with spacings absent.

**G13** proves `exact` is not as brittle as it sounds — see above.

## Conformance

An implementation conforms when, for every fixture, it reproduces each
measurement bit-for-bit, the absence of the optional measurements, the exact
finding set, and the verdict.

## References

- [ADR-0226 - DICOM ingest arc](../architecture/decisions/ADR-0226-dicom-ingest-arc.md)
- [ADR-0227 - Neutral CT frame description](../architecture/decisions/ADR-0227-neutral-ct-frame-description.md)
- [ADR-0228 - CT series grouping](../architecture/decisions/ADR-0228-ct-series-grouping.md)
- [ADR-0229 - CT series geometry validation](../architecture/decisions/ADR-0229-ct-series-geometry-validation.md)
- [VOXELIA-ALG-0047 - CT series grouping and slice ordering](VOXELIA-ALG-0047-series-grouping-and-ordering.md)
