---
document_id: "VOXELIA-VAL-0001"
title: "First vertical slice validation report"
version: "0.1"
status: "Draft"
document_type: "Validation Report"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Validation"
---

# First vertical slice validation report

## Purpose and scope

This report is the validation half of the deliverable `VOX-VS1-021` requires. It
records what the first vertical slice was verified to do, on the owner's real
clinical CT data, and — with equal prominence — what it was **not** verified to do.

`VOX-VS1-021` declares **`I,R,T`**. This document supplies the material for
Inspection and records the Test results. **Review is not performed here**: the
traceability entry reads "**Approved** M4 validation and benchmark reports", and
approval is the owner's act. The review record at the end is therefore empty by
design, not by omission.

Scope is the first vertical slice: DICOM CT ingest through a published
patient-space volume, three-plane reconstruction, windowing, quantitative
inspection, distance measurement, linked crosshairs, cancellation and provenance.

## Requirements covered

| Row | Methods | Status | Evidence |
|---|---|---|---|
| `VOX-VS1-001` DICOMKit ingestion | T | Discharged | `ADR-0233`, `ADR-0235`; 899 of 899 frames byte-exact |
| `VOX-VS1-002` Spatial metadata assembly | T | Discharged | `ADR-0227`, `ADR-0228` |
| `VOX-VS1-003` Irregular geometry rejection | T | Discharged | `ADR-0229`, `ADR-0234` |
| `VOX-VS1-004` Patient-space affine volume | T | Discharged | `ADR-0230`, `ADR-0240` |
| `VOX-VS1-005` Signed and unsigned 16-bit | T | Discharged | `ADR-0236`; real scanner is `uint16` |
| `VOX-VS1-006` Rescale slope and intercept | T | Discharged | `VOXELIA-ALG-0003`, `ADR-0237` |
| `VOX-VS1-007` MONOCHROME1 and MONOCHROME2 | T | Discharged | `VOXELIA-ALG-0011`, `ADR-0217` |
| `VOX-VS1-008` Pixel padding | T | Discharged | `ADR-0236`; VR selection corrected |
| `VOX-VS1-009` CPU three-plane reconstruction | T | Discharged | `ADR-0221`; real 899-slice series |
| `VOX-VS1-010` Metal three-plane rendering | T,D | **Test only** | `ADR-0221`, `ADR-0252`; **D owner-gated** |
| `VOX-VS1-011` Nearest and linear interpolation | T | Discharged | `ADR-0217`, `ADR-0250` |
| `VOX-VS1-012` Window centre and width | T,D | **Test only** | `ADR-0245`; **D owner-gated** |
| `VOX-VS1-013` Linked patient-space crosshairs | T,D | **Test only** | `ADR-0248`; **D owner-gated** |
| `VOX-VS1-014` Quantitative pixel inspection | T | Discharged | `ADR-0246` |
| `VOX-VS1-015` Patient-space distance | T | Discharged | `VOXELIA-ALG-0010`, `ADR-0247` |
| `VOX-VS1-016` Off-screen output equivalence | T | Discharged | `ADR-0251` |
| `VOX-VS1-017` Stale-result prevention | T | Discharged | `ADR-0249`, three stages |
| `VOX-VS1-018` No full-volume GPU duplicate | A,T | Discharged | `ADR-0253` |
| `VOX-VS1-019` Provenance | T | Discharged | `ADR-0242`; depth-two complete graphs |
| `VOX-VS1-020` Swift 6 strict concurrency | T | Discharged | 1024 tests, strict concurrency build |
| `VOX-VS1-021` Validation and benchmark report | I,R,T | **I and T; R pending** | this report and `VOXELIA-BEN-0001` |

**Four rows carry an undischarged Demonstration half** — `010`, `012`, `013` — plus
`010` again for its interactive act. Every one of them depends on the interactive
draw loop, which is an owner-gated architecture. **An off-screen render is not
evidence for a Demonstration half** and is not offered as such anywhere in this
report.

## Implementations and environment

| Item | Value |
|---|---|
| Model | `Mac17,4` |
| SoC | Apple M5 |
| CPU cores | 10 (4 performance, 6 efficiency) |
| GPU cores | 10 |
| Physical memory | 24 GiB |
| Operating system | macOS 26.5.1 (`25F80`) |
| Xcode | 26.6 |
| Swift compiler | Apple Swift 6.3.3 (`swiftlang-6.3.3.1.3 clang-2100.1.1.101`) |
| Source commit | `9cc241b26b4009118703ab6c89589c170c6f5152` |
| DICOMKit | `2.2.11`, exact pin |

**This host is not approved reference hardware.** Plan §61 requires formal
performance acceptance to use at least one approved `A-WORKSTATION` Apple Silicon
Mac. No such approval exists, so this report records the environment and claims
**no formal performance acceptance**. See `VOXELIA-BEN-0001`.

## Datasets and tolerances

**Dataset.** The owner's clinical CT corpus at `/Users/ranjith/telerad-dicom-input`.
The principal series is `Thorax_COVID_100_THIN_LUNG_3`: 899 frames, `512x512`,
`uint16`, Pixel Representation `0`, 449 MiB assembled. Roughly forty further series
were read for the geometry distribution recorded in `ADR-0234`.

**No repository test reads that path.** Every automated test uses synthetic
fixtures; real-data results in this report come from recorded scratch-harness runs
whose reproduction commands are in the evidence file.

**Tolerances.** `CTGeometryTolerance.exact` — every threshold zero — is the only
value the project defines.

> **The `voxelia.m4.ct.diagnostic` version `1.0.0` tolerance profile in plan §54 is
> provisional and unapproved.** Its numbers are **not** used as acceptance criteria
> anywhere in this report. Where a comparison could have taken a tolerance, it was
> instead constructed to be exact — see Methods.

## Methods

**Design-first governance.** Every numeric boundary was frozen in an accepted
`ADR` with a `VOXELIA-ALG` specification and an independent Python oracle before
implementation, and the Swift reproduces the oracle's fixtures bit-exactly as
hexadecimal float literals.

**Exactness in preference to tolerance.** Where the plan permits a bound, cases
were chosen so the arithmetic is exact instead:

- Interpolation linear-precision uses small integer ramp coefficients at half- and
  quarter-integer positions, so every trilinear weight is an exact binary fraction
  (`ADR-0250`).
- The CPU/Metal differential asserts exact byte equality rather than the plan's
  provisional "≤ 1 code value" (`ADR-0252`).
- Crosshair round trips are exact with no tolerance applied (`ADR-0248`).

**Real-data verification in addition to unit tests.** Ten recorded runs against the
owner's series, listed in
`docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md`.

## Results

**Automated suite: 1024 tests in 191 suites pass**, under Swift 6 strict
concurrency, with `check_swift_safety.py` and `swift format lint --strict` clean.

Selected real-data results:

| Check | Result |
|---|---|
| Frame transfer | 899 of 899 slices byte-exact against DICOMKit's own frame bytes |
| Geometry verdict | `representable` at `exact` tolerance |
| Frame of reference | Preserved into the descriptor's external references |
| Crosshair slice index, three planes | Exact: 400 / 200 / 300 for voxel (300, 200, 400) |
| Crosshair pixel, three views | Exact: (300,200), (300,400), (200,400) |
| Distance, 100 columns | `95.31367187500001` mm; the 1-ULP difference from `100 x spacing` attributed to the affine's origin subtraction |
| Sample inspection | Centre `40.0` HU; outside the reconstruction circle at the `-8192` floor |
| Cancellation, nine points | Every one refuses typed and publishes nothing |
| Publication atomicity | Registry all-or-nothing, 24 of 24 per content-claim shape |
| CPU vs Metal, three planes | Byte-identical |
| Steady-state footprint | `1.05x` of one volume |

## Deviations and failures

**These are recorded because plan §2761 forbids reporting a green implementation
status without passing validation.**

1. **`validate-scaffold.sh` is RED and remains so.** It fails on a `swift-frontend`
   signal 11 in Apple Swift 6.3.3, reproduced in `ADR-0224`. It was attributed to
   the toolchain by reproducing on a pristine worktree, and **no flag was relaxed
   to hide it**. This is a genuine outstanding failure in a release gate.
2. **DocC is not built with global `--warnings-as-errors`.** Two dependencies
   (`JXLSwift`, `DICOMKit`) emit DocC errors, and `xcodebuild docbuild` documents
   the whole package graph. `build-docc.sh` now filters diagnostics to this
   repository's own `Sources/`, and the dependency diagnostics are reported
   separately rather than suppressed. Restoring the global setting needs upstream
   fixes.
3. **Two dependency licence files are absent.** `Raster-Lab/JLSwift` and
   `Raster-Lab/CompressionFamily` carry an owner grant of MIT but no `LICENSE`
   file in the repository. `THIRD_PARTY_NOTICES.md` marks both as release
   prerequisites.

No validation check was weakened, skipped or re-scoped to produce a pass.

## Limitations

1. **No Demonstration half is claimed.** `VOX-VS1-010`, `012` and `013` each retain
   one, all gated on the interactive draw loop.
2. **No approved reference hardware**, so no formal performance acceptance
   (plan §61).
3. **The geometry tolerance remains an owner gate.** `exact` rejects any series
   whose spacing varies at all — including reformats that are physically regular
   but state more precision than their geometry has. `ADR-0234` measured the
   distribution and identified precision-derived tolerance as the leading
   candidate, and explicitly found it **not sufficient alone**.
4. **The import is all-or-nothing; there is no progressive display.** The first
   axial image is available only after the complete volume, because reconstruction
   reads a published volume. Plan §63's intent — a first image before *optional*
   preprocessing — is met, since there is no optional preprocessing, but a viewer
   that shows slice one while the study is still loading is not supported.
5. **Padding policy is not expressible in a render request** (`ADR-0251`). It
   travels through the renderer's injected stage, whose default passes no padding
   value, so a windowed render maps padding values as if they were tissue.
6. **Plan §59.3's stress cases are not run**: `512x512x1024`, repeated dataset
   replacement, repeated open/close cycles, and export during interactive
   rendering.
7. **The CPU/Metal exact agreement is fixture-specific.** It was measured on
   `uint8` samples with a window where binary32 is exact. The Metal stage's
   `approximate` claim remains correct, and exactness elsewhere is not established.
8. **One series, one scanner, for the timing baseline.** No variation across Macs
   or across scanner models is characterised.

## Conclusion

Every first-vertical-slice requirement with claimable work is discharged, verified
on real clinical data, with 1024 automated tests passing under Swift 6 strict
concurrency.

**The slice is not accepted, and this report does not accept it.** Acceptance
requires the owner's review of this document and `VOXELIA-BEN-0001`, approved
reference hardware, an approved tolerance profile, the two dependency licence
files, and a decision on the geometry tolerance. One release gate,
`validate-scaffold.sh`, is red on a toolchain defect.

## Review record

| Role | Name | Date | Outcome |
|---|---|---|---|
| Validation review | *pending owner* | — | — |
| Approval (`VOX-VS1-021`) | *pending owner* | — | — |

**Unsigned.** `VOX-VS1-021`'s Review method is discharged only by the owner's
entry above.
