---
document_id: "ADR-0254"
title: "First slice validation and benchmark reports"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-021"
---

# ADR-0254 - First slice validation and benchmark reports

## Context

`VOX-VS1-021` requires the first vertical slice to produce a validation and
benchmark report, declaring **`I,R,T`**. It is the last first-slice row, and the
only one whose deliverable is a document rather than code.

Its traceability entry reads "**Approved** M4 validation and benchmark reports".
That word decides the increment's shape.

## The finding: the row cannot be fully discharged by this project

Reading the three methods against what exists:

- **`T` (Test)** — dischargeable now. 1024 tests in 191 suites pass, plus ten
  recorded real-data runs.
- **`I` (Inspection)** — dischargeable now. The reports exist and can be inspected
  against the plan's own content lists (§19.6 memory evidence, §61 hardware record,
  §63 stage distinctions, §64.4 memory confirmations).
- **`R` (Review)** — **not dischargeable by this project.** Review and approval are
  the owner's acts. A report this project also reviewed would be a self-approval,
  which is exactly what a review method exists to prevent.

Two further gates sit inside the row rather than beside it:

1. **Plan §61 requires formal performance acceptance to run on an approved
   `A-WORKSTATION` Apple Silicon Mac.** No such approval exists. This is the
   reference-hardware owner gate, and it means **no performance acceptance can be
   claimed at all** — only a baseline.
2. **Plan §54's `voxelia.m4.ct.diagnostic` version `1.0.0` tolerance profile is
   explicitly provisional**, "to be approved before acceptance". Its numbers must
   not be used as acceptance criteria.

**But §63 supplies the part that is achievable**: "M4 shall establish a
reproducible baseline even where no absolute first-image threshold has yet been
approved." So a baseline is required, is possible without approvals, and is what
this increment produces.

## Decision

1. **Two reports are produced from the project's own templates**, not from an
   invented format: `VOXELIA-VAL-0001` in `docs/validation/` and
   `VOXELIA-BEN-0001` in `docs/benchmarks/`. Both directories and both templates
   already existed; checking first avoided inventing a structure the project had
   already decided.
2. **`VOX-VS1-021`'s `I` and `T` halves are discharged; `R` is left explicitly
   unsigned.** The validation report's review record carries `pending owner` rows
   rather than being omitted, so the gap is visible in the artefact rather than
   only in this record.
3. **No performance acceptance is claimed, and the reason is stated in both
   reports** rather than left to inference from a missing section.
4. **The benchmark report states its own principal weakness prominently**: a
   single cold run per configuration, no warm-up, no repetitions, and therefore no
   distribution — which is what plan §53's method actually asks for. A report that
   presented one run as a distribution would be the more comfortable and less
   useful document.
5. **Both release and debug timings are published.** Release completes the import
   in `1.841` s against `4.283` s debug, a `2.33x` gap. Publishing only debug
   figures would understate the system by more than a factor of two; publishing
   only release would hide that the project's default `swift build` is much slower.
6. **Absent measurements are recorded as absent.** Power state, thermal state and
   retained compressed-source footprint are listed by the plan and are not
   instrumented; each says so rather than carrying a guess.
7. **The three outstanding failures are in the validation report's own Deviations
   section**, because plan §2761 forbids reporting a green status without passing
   validation: `validate-scaffold.sh` red on an Apple Swift 6.3.3 `swift-frontend`
   signal 11, DocC without global `--warnings-as-errors` because of dependency
   diagnostics, and two absent dependency licence files.
8. **No algorithm specification and no oracle.** The deliverable is a document.

## The baseline, for the record

Release build, fresh process, real 899-frame `512x512` `uint16` series (449 MiB):

| Stage | Release |
|---|---:|
| Metadata-ready (899 frames described) | `0.291` s |
| Geometry accepted / first decoded frame | `0.314` s |
| Complete volume | `1.841` s |
| First axial image | `1.942` s |
| First three-view image / steady state | `2.350` s |

Derived: ≈ 3,090 frames/s metadata scan, ≈ 589 frames/s decode and transfer
(≈ 294 MiB/s), ≈ 244 MiB/s complete import. Peak resident `471 MiB` — **`1.05x` of
one volume**. Metal full-volume resource **0 B**.

## Two observations that are design properties, not hardware ones

**The first axial image arrives *after* the complete volume**, not before, because
reconstruction reads a published volume. Plan §63's requirement is that a first
image not wait on *optional* preprocessing, and Voxelia has none — so the
requirement is met — but **progressive display during loading is not supported**,
and that is recorded as a limitation rather than allowed to hide behind a satisfied
clause.

**The sagittal plane is consistently the slowest** of the three, because it fixes
the fastest-varying index and so has the least contiguous access pattern. This has
now appeared in every timing run across three increments.

## Alternatives considered

### Claim `VOX-VS1-021` fully discharged

Rejected. `R` is a review method and this project cannot review its own report
without making the method meaningless.

### Omit the benchmark report until a repetition method exists

Rejected. §63 explicitly requires a reproducible baseline *even without approved
thresholds*, so withholding it would leave a required deliverable unproduced in
order to avoid publishing a caveat.

### Present the single run as a distribution by reporting it as a median

Rejected, and worth naming as a rejected option: one run's value is not a median,
and calling it one would manufacture a statistic.

### Use plan §54's provisional tolerances as acceptance criteria

Rejected. They are unapproved, and treating them as approved is precisely the
substitution the tolerance gate exists to prevent.

### Instrument power and thermal state now

Deferred. Both belong with a repetition method and approved hardware; adding
uncalibrated readings to an unapproved baseline would add noise, not evidence.

## Consequences

**The first vertical slice's full requirement set is now either discharged or
explicitly owner-gated, with the gates named in artefacts the owner can act on.**

What the owner now needs to decide, all recorded in the reports:

1. Review and approval of `VOXELIA-VAL-0001` and `VOXELIA-BEN-0001`
   (`VOX-VS1-021`'s `R`).
2. Reference-hardware approval (plan §61) before any performance acceptance.
3. The `voxelia.m4.ct.diagnostic 1.0.0` tolerance profile.
4. The geometry tolerance rule, and whether reformats must be supported
   (`ADR-0229`, `ADR-0234`).
5. `LICENSE` files in `Raster-Lab/JLSwift` and `Raster-Lab/CompressionFamily`.
6. Whether the interactive draw loop proceeds, which is what four Demonstration
   halves wait on.

## Affected modules

None. Two documents added; no source changed.

## Compatibility impact

None.

## Security impact

None. The reports name the dataset's location but reproduce no patient data: no
identifiers, no pixel values beyond aggregate Hounsfield readings at named
coordinates.

## Performance and memory impact

None added; measured and published.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
swift test
```

## Migration

1. This record and the two reports.
2. **Owner gate**: the six decisions listed under Consequences.
3. **Open**: a repetition and warm-up method so plan §53's distribution comparison
   can be satisfied, and plan §59.3's stress cases.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-VAL-0001 - First vertical slice validation report](../../validation/VOXELIA-VAL-0001-first-vertical-slice-validation.md)
- [VOXELIA-BEN-0001 - First vertical slice benchmark baseline](../../benchmarks/VOXELIA-BEN-0001-first-vertical-slice-baseline.md)
- [ADR-0224 - Scaffold gate findings](ADR-0224-scaffold-gate-findings.md)
- [ADR-0234 - Geometry tolerance source assessment](ADR-0234-geometry-tolerance-source-assessment.md)
- [ADR-0253 - Steady state volume footprint](ADR-0253-steady-state-volume-footprint.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
