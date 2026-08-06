---
document_id: "ADR-0234"
title: "Geometry tolerance source assessment"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-009"
  - "VOX-VS1-003"
---

# ADR-0234 - Geometry tolerance source assessment

## Context

`ADR-0229` made an evidence-based geometry tolerance an owner gate, because no
threshold this project could set was evidence-based. Two things have changed
since:

1. `ADR-0233` found that `DICOMKit.DICOMDecimalString` preserves
   `originalString` alongside `value`, so **the source's stated decimal precision
   is available at the adapter boundary** — the one principled tolerance source
   `ADR-0229` believed had been discarded.
2. The owner supplied real clinical CT data, and `ADR-0233` recorded a measured
   distribution of spacing irregularity across roughly forty series.

This record assesses whether precision-derived tolerance closes the gate. **It
does not, and the reason is the useful part.**

## What the real data actually states

Measured from the owner's CT corpus by reading `originalString` for Image
Position (Patient), Pixel Spacing and Image Orientation (Patient):

| Series | Position decimals | Spacing decimals | Orientation decimals | Measured spread |
|---|---|---|---|---|
| `Thorax_COVID_100_THIN_LUNG_3` (899 slices) | z: **3**, x/y: 7 | 11 | **0** (exact `1\0\0\0\1\0`) | `0.0` |
| `Abd_Plain_200_THIN_SOFT_3` (652 slices) | z: **3**, x/y: 7 | 11 | **0** | `1.14e-13` |
| `Thorax_COVID_150_cor_10` (coronal reformat) | 7-8 | 10-11 | 10-11 | `1.01e-3` |
| `Results_CT_View&GO_1028` (secondary capture) | mixed, E-notation | 12 | mixed | `51.77` |

Three observations matter more than the numbers.

**Axial slice positions state the slice axis to three decimals.** The `z`
coordinate — the one the ordering projection uses — carries 3 dp while `x` and
`y` carry 7. A precision-derived tolerance for slice spacing would therefore be
about `1e-3` mm for these series.

**Axial orientation is stated exactly.** `1\0\0\0\1\0` with zero decimals, which
is why `ADR-0233` measured an orientation deviation of exactly zero: there is no
rounding to disagree about. Orientation needs no tolerance for axial CT at all.

**Reformats state far more precision than their geometry has.** The coronal
series states positions to 7-8 dp — implying `1e-7` mm — while its spacings
actually vary by `1.01e-3` mm, four orders of magnitude more.

## The finding: precision-derived tolerance is necessary but not sufficient

Applying a tolerance of one unit in the last stated place:

- **The floating-point-noise group is admitted.** `1.14e-13` mm of variation
  against a `1e-3` mm tolerance derived from 3 dp. This is the group `exact`
  wrongly rejects, and precision-derivation fixes it **with no invented
  constant** — the number comes from what the scanner wrote.
- **The genuinely irregular group stays rejected**, by orders of magnitude.
  `51.77` mm against any plausible derived tolerance.
- **The reformat group stays rejected**, and this is the case that defeats the
  idea. `1.01e-3` mm of variation against a `1e-7` mm derived tolerance. The data
  is physically regular to a nanometre and would still be refused, because it
  *claims* precision its geometry does not have.

So precision-derivation resolves the case `ADR-0229` most wanted resolved and
leaves a second case open. It is a real improvement and not a complete answer,
and reporting it as a complete answer would be the more comfortable and less
useful thing to write.

## A hazard any implementation must handle

`Results_CT_View&GO` states values in **scientific notation** —
`-2.1336917E+002`. Counting characters after the decimal point, which is the
obvious way to measure stated precision, reads that as 12 decimals when the value
is stated to 7 significant figures at a magnitude of ~213, i.e. about `1e-4`
absolute. **A naive decimal-place count is wrong on real data**, and the
measurement in the table above carries that error for that row. It is stated here
rather than quietly corrected, because the same mistake in an implementation would
silently produce a tolerance three orders of magnitude too small.

Any precision-derived rule therefore needs a parser that handles DICOM Decimal
String properly: optional sign, optional exponent, and the distinction between
decimal places and significant figures.

## Decision

1. **No tolerance value is chosen here.** This record assesses sources; the
   threshold remains the owner gate `ADR-0229` decision 3 created.
2. **The gate's description is corrected.** `ADR-0229` said the principled source
   was unavailable. It is available, at the adapter boundary, and this record
   supersedes that specific claim without editing the record that made it.
3. **Precision-derived tolerance is recorded as the leading candidate for slice
   spacing**, because it introduces no constant this project invented: the
   tolerance is read from what the source wrote. It needs its own record, an
   algorithm specification and an oracle before any implementation.
4. **It is explicitly not sufficient on its own.** Reformatted series would still
   be rejected. Whether that is acceptable — reformats are derived images, and a
   viewer may legitimately decline to rebuild a volume from one — is a clinical
   question, not an arithmetic one, and belongs to the owner alongside the
   threshold.
5. **Orientation needs no tolerance for axial CT**, on this evidence: direction
   cosines are stated exactly and measured deviation is exactly zero. A tolerance
   for orientation should not be added speculatively.
6. **Carrying precision forward would require a new field on
   `CTFrameDescription`**, and that is a decision for the implementing record, not
   this one. It would be the third field added to a type `ADR-0227` first froze
   five increments ago, which is itself worth weighing: a value type that keeps
   gaining fields is a sign its boundary was drawn too early.
7. **A DICOM Decimal String precision parser is a prerequisite**, with
   E-notation covered by fixtures. The hazard above is the reason.

## Alternatives considered

### Choose a tolerance now from the measured distribution

Rejected. The measurements make a threshold *defensible* — anything above
`1.2e-3` mm and well below a millimetre separates every observed group — but
"defensible from forty series off two scanner models" is not the same as
evidence-based, and the gate exists precisely to stop this project from making
that substitution on its own authority.

### Treat precision-derivation as the complete answer

Rejected; see the finding. It would leave reformats silently unsupported while
the record claimed the question was settled.

### Derive the tolerance from significant figures rather than decimal places

Not rejected — **not yet assessed**. It is the natural response to the E-notation
hazard and may handle reformats better, since it scales with magnitude. It needs
measurement against the corpus before it can be recommended, and this record does
not pretend to have done that.

### Add a per-series override so a caller can accept a reformat

Deferred rather than rejected. It is a plausible product answer, and it is a
different decision from what the default rule should be.

## Consequences

The tolerance gate is **narrower and better characterised** than `ADR-0229` left
it: one principled source identified and measured, one case it resolves, one case
it does not, and one implementation hazard named.

It is still an owner gate, and this record does not move it.

## Affected modules

None. Assessment only; no source changed and no dependency added.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Measurements read via DICOMKit.DICOMDecimalString.originalString over
/Users/ranjith/telerad-dicom-input/CT, with a scratch harness. No repository
test reads that path.
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record.
2. **Owner decision**: the tolerance rule, and whether reformats must be
   supported.
3. Then, with its own record, specification and oracle: a DICOM Decimal String
   precision parser with E-notation fixtures, an assessment of significant
   figures against decimal places, and whichever rule the owner accepts.

## Supersession

This record supersedes no record. It **corrects one claim** in `ADR-0229` — that
the source's stated decimal precision is unavailable — and records the correction
here rather than editing that record, following the same practice `ADR-0233`
used.

## References

- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [ADR-0229 - CT series geometry validation](ADR-0229-ct-series-geometry-validation.md)
- [ADR-0233 - DICOMKit adapter and dependency](ADR-0233-dicomkit-adapter-and-dependency.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
