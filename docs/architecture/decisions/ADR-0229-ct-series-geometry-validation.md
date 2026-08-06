---
document_id: "ADR-0229"
title: "CT series geometry validation"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-009"
  - "VOX-VS1-003"
---

# ADR-0229 - CT series geometry validation

## Context

This record performs increment (c) of the `ADR-0226` arc: rejecting irregular
geometry, for `VOX-VS1-003` and `VOX-DCM-009`.

`ADR-0226` named this the arc's hardest question and reserved it deliberately.
Three increments have deferred judgements here, and this record must consume
them rather than rediscover them:

1. the three `CTSeriesObservation` facts assembly reports — degenerate normal,
   non-finite normal, non-finite projection;
2. the non-orthogonal and non-unit direction cosines `ADR-0227` decision 3
   admits by design;
3. the mixed grid extents `ADR-0228` decision 4 deliberately allows into a
   single group.

`ADR-0226` decision 6 set the question precisely: **which** of position,
orientation and spacing admits a tolerance, and **where that tolerance comes
from**. `ADR-0215` established exact equality for registration, but scanner
geometry does not arrive exact, so the answer cannot simply be inherited.

## Where a tolerance may come from

Four candidates were considered, and three fail for the same reason.

An **absolute epsilon** in millimetres is arbitrary and wrong at a different
scale. A **relative epsilon** is scale-free and still arbitrary. A **fraction of
a voxel** sounds principled — the sampling grid as the ruler, a deviation below
the finest thing the volume can express being unobservable — but it still
requires choosing the fraction, and dressing an invented constant in a physical
argument makes it harder to question, not easier.

The fourth candidate was to **derive the tolerance from the source's own stated
precision**. DICOM decimal strings carry limited significant digits, so two
spellings of one intended value differ by at most a unit in their last shared
place. This is the only genuinely principled option, and **it is not available**:
the neutral frame description carries `Double` values, not the original strings,
so the precision that would justify a tolerance has already been discarded by
the time this stage sees the data. Recovering it would mean pushing string
handling into increments (a) through (d), which `ADR-0226` decision 5 forbids.

**So no threshold this project could set today would be evidence-based.** That
finding, rather than a number, is what this record acts on.

## Decision

1. **Measurement is separated from judgement.** Every quantity
   `VOXELIA-ALG-0048` defines is an exact measurement — a subtraction, a
   product-sum, or a comparison against zero — and **no threshold appears
   anywhere in the arithmetic**. Thresholds enter once, at the end, as a
   supplied policy value. A tolerance is a clinical safety parameter; a
   measurement is a fact; mixing them would bury the parameter inside a
   comparison where no oracle could see it.
2. **The tolerance is an explicit input, and this record defines exactly one
   value: `exact`, with all four thresholds zero.** No permissive default is
   defined. Inventing one and calling it a default would give an unevidenced
   clinical parameter the authority of an accepted decision, which is the
   failure mode this project's governance exists to prevent.
3. **A permissive tolerance is an owner gate.** Setting one requires evidence —
   phantom studies, or a characterised corpus of real scanner output — and owner
   acceptance. It joins the Raster-Lab codecs and reference hardware as a named
   gate rather than being quietly filled in.
4. **`exact` is far less brittle than it sounds, and the record does not
   overstate its cost.** Two different decimal spellings that round to the same
   binary64 value produce a deviation of *exactly* zero and are admitted;
   fixture G13 is that case. Exact tolerance forgives re-spelling and refuses
   only values landing on genuinely different doubles. An earlier draft of this
   record claimed exact tolerance would reject mere re-spellings — the oracle
   disproved it, and the corrected claim is narrower and true.
5. **It nevertheless will reject real series, and that is the intended posture.**
   A slice spacing short by one ten-thousandth of a millimetre is physically
   negligible and is rejected under `exact` (fixture G2). Until decision 3's
   gate is passed, refusing to build a volume whose regularity cannot be
   justified is the correct direction of error. `VOX-VS1-003` asks for rejection
   or a clear warning, not for accommodation.
6. **Every measurement is reported whether or not it triggers a finding**, so a
   caller holding its own evidence can apply its own thresholds today without
   this project pretending to have set them.
7. **Which measurement answers which part of `ADR-0226` decision 6:**
   - *Orientation* is compared componentwise against the anchor, never as a
     norm, because a norm would add a square root and an overflow path for
     nothing.
   - *Spacing* is judged by the **spread** — maximum minus minimum — not by
     deviation from a nominal value. A nominal spacing would need an arbitrary
     anchor, or a mean (a division and a summation order), or a median (a sort
     and an even-count tie rule). The spread needs none and answers the question
     directly.
   - *Position* is not compared directly at all. Its geometric content is
     already the projection assembly computed, so comparing positions as well
     would be a second rule for one fact.
8. **The three assembly observations are inherited, never recomputed.** One
   place establishes each fact. Fixture G10 exists to catch a validator that
   recomputes: its members share a projection, so a recomputing implementation
   reports an irregular spacing where the correct result reports only the
   degenerate normal, with spacings absent.
9. **Slice-spacing measurements are absent when the series is not ordered by
   projection.** Differences taken over assembly's identity-order fallback
   measure nothing, and reporting them as spacings would manufacture a number.
10. **Warning versus rejection, discharging `ADR-0226` decision 7 on evidence:**
    `singleMemberSeries` and `presentationDisagreement` warn; everything else
    rejects. A single-member series is genuinely representable — it is a
    one-slice volume with no spacing to be irregular. Contradictory rescale or
    photometric terms are **not geometry facts**: they make a volume's values
    incomparable, which belongs to the value-transformation stage
    `VOX-DCM-006` requires — the same stage `ADR-0227` decision 5 assigned the
    degenerate rescale slope. They are measured and reported here so the
    condition is visible rather than unowned.
11. **What this record does not claim.** `VOX-DCM-009` requires detecting
    "missing, duplicated, irregular or contradictory" geometry. Missing and
    irregular geometry are detected — a missing slice manifests as a doubled gap
    and so as a nonzero spread (fixture G3) — but **the two are not
    distinguished by label**, because separating "a slice is absent" from "the
    spacings vary" requires a ratio test and therefore a tolerance. Duplicates
    are detected exactly. Contradictions are detected and, for the presentation
    terms, deliberately assigned elsewhere. The requirement's "shall not
    silently coerce" half is discharged completely; the labelling of missing
    slices specifically is not claimed.

## Alternatives considered

### Pick a small absolute or relative epsilon

Rejected; see the analysis above. Both are arbitrary, and an arbitrary number
with an accepted record behind it is worse than a stated gate.

### Derive the tolerance from a fraction of the in-plane voxel size

Rejected, and it was the most attractive option. The argument — a deviation below
the sampling resolution is unobservable — is sound in form but still needs a
fraction chosen without evidence, and its physical framing would discourage the
scrutiny an invented constant deserves.

### Derive the tolerance from the source's decimal precision

Rejected as unavailable, not as wrong; see above. It is the option that would
have been principled, and the reason it fails is worth recording: increment (a)
deliberately discarded the strings.

### Measure spacing as deviation from a mean or median spacing

Rejected; see decision 7. Both add numeric boundaries the spread does not need.

### Compare orientation by the angle between directions

Rejected; see decision 7. An angle needs a square root and an inverse cosine,
two further boundaries, to produce an ordering the componentwise maximum already
gives.

### Reject on contradictory rescale terms

Rejected; see decision 10. It is not a geometry judgement, and this increment
holds no authority over the value-transformation stage.

### Let the validator recompute the assembly observations

Rejected; see decision 8.

### Defer the whole tolerance question again

Rejected. Three increments have deferred to this one; deferring further would
leave `VOX-VS1-003` undischarged with no statement of why. The tolerance is now
an explicit, named owner gate, which is a decision rather than a deferral.

## Consequences

The first vertical slice will **reject real CT series** whose spacing or
orientation varies at all, until an evidence-based tolerance is accepted. This is
a real limitation and it is stated plainly rather than hidden behind a default
that would let unjustified volumes through.

Callers are not blocked by it: every measurement is reported, so a caller with
its own evidence can judge for itself.

The project gains a third named owner gate.

## Affected modules

`VoxeliaImaging` gains the validator, its measurement value, its finding set,
its verdict and its tolerance value. No module's dependencies change. No
third-party dependency is added.

## Compatibility impact

Additive only.

## Security impact

None. Findings name conditions rather than values, and the measurement value
carries geometry the caller already supplied.

## Performance and memory impact

One pass over the members for the deviations and predicates, plus one pass over
the consecutive differences. The orthonormality residuals are computed once on
the anchor, not per member.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0229-geometry-validation-oracle.py
swift build && swift test
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This increment: `VOXELIA-ALG-0048`, its oracle, and this record.
2. Next: the validator, verified against all thirteen frozen fixtures.
3. Increment (d): affine volume construction, which consumes a
   `representable` verdict and must state what it does with
   `representableWithWarnings`.

## Supersession

This record supersedes nothing. It performs increment (c) of `ADR-0226` and
discharges its decisions 6 and 7.

## References

- [ADR-0215 - Multi-volume fusion assessment](ADR-0215-multi-volume-fusion-assessment.md)
- [ADR-0226 - DICOM ingest arc](ADR-0226-dicom-ingest-arc.md)
- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [ADR-0228 - CT series grouping](ADR-0228-ct-series-grouping.md)
- [VOXELIA-ALG-0048 - CT series geometry validation](../../algorithms/VOXELIA-ALG-0048-series-geometry-validation.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
