# VOX-VS1-001 real CT ingest demonstration, 2026-08-06

Recorded evidence for the **Demonstration** half of `VOX-VS1-001`, run against
real clinical CT data the project owner supplied at
`/Users/ranjith/telerad-dicom-input` (30,348 files; the CT tree holds five
studies). The pipeline exercised was the whole accepted arc:

```text
DICOMFile.read  ->  DICOMFrameAdapter  ->  CTSeriesAssembler
                ->  CTGeometryValidator (tolerance: .exact)
                ->  CTAffineVolumeBuilder
```

The harness was a scratch executable depending on the local package; no test in
the repository reads this path, because the data is not part of the repository.

## Headline result

**A 899-slice thorax CT series ingested completely and was assessed
`representable` under the `exact` tolerance**, with a spacing spread of exactly
`0x0p+0`:

```text
files: 899   parsed: 899   adapted: 899
series assembled: 1
verdict: representable      findings: []
slice spacing: min 0.5  max 0.5      spacing spread: 0.0
orientation deviation: 0.0           in-plane deviation: 0.0
row.col dot: 0.0    row |v|^2-1: 0.0    col |v|^2-1: 0.0
uniform grid: true                   duplicates: false
```

Every file parsed, every file adapted, one series, no findings.

## This corrects ADR-0229

`ADR-0229` decision 5 said the `exact` tolerance "will reject real series whose
spacing or orientation varies at all", and framed that as an accepted cost.

**The measured position is far better than that warning.** Across roughly forty
real CT series, `exact` **accepts** about half outright — including every large
primary axial reconstruction measured (899, 678, 663, 516, 497, 450, 449, 448,
324 slices). The warning was not wrong in principle; it was wrong about how often
the principle bites, and it should not have been stated so strongly without
measurement.

## The measured distribution of spacing spread

| Group | Observed spread | Character | Verdict under `exact` |
|---|---|---|---|
| Exactly regular | `0.0` | Primary axial reconstructions | **representable** |
| Floating-point noise | `1.42e-14` to `1.14e-13` mm | Physically regular, position values differ in the last few bits | rejected |
| Reformat noise | `2.1e-4` to `1.2e-3` mm | Coronal/sagittal/axial reformats (`_cor_`, `_sag_`, `_ax_`) | rejected |
| Genuinely irregular | `51.77` and `72.57` mm | `Results_CT_View&GO` secondary captures | rejected, correctly |

**This is the evidence the geometry-tolerance gate was waiting for.** The two
middle groups are physically regular data that `exact` refuses, and their
magnitudes are now measured rather than hypothesised: a tolerance somewhere above
`1.2e-3` mm and far below the millimetre scale would admit them while still
rejecting the 51 mm case by four orders of magnitude. Choosing the number remains
an owner decision with a record and an oracle; it is no longer a decision without
data.

## Two anomalies, both the pipeline behaving correctly

**`Monitoring_1000_12`** — eight frames, spacing spread `0.0`, yet **rejected**
for `duplicateProjections`. All eight occupy one position: it is a CT monitoring
sequence, repeated acquisitions at a single location, not a volume. This is a
real-world instance of frozen fixture G4, and the rejection is right.

**`CT_Raw_data_601`** — two files parsed, **zero adapted**, both refused with
`missingRows`. They are raw-data objects carrying no image pixel module. The
adapter named the precise missing attribute rather than failing vaguely.

**`Results_CT_View&GO`** — 15 of 17 and 23 of 24 files adapted; the remainder
refused. These are secondary-capture screenshots mixed into a study, and the
refusals are the adapter declining to treat non-monochrome captures as CT frames.

## What this discharges, and what it does not

- `VOX-VS1-001`'s **Demonstration** half is now evidenced for ingest through
  assembly and geometry assessment on real data.
- `VOX-DCM-003`, `VOX-DCM-004`, `VOX-DCM-007` and `VOX-DCM-008` are exercised
  against real attribute values rather than synthesised ones.
- **Not discharged**: the pixel-data path. No samples were decoded or written;
  `ADR-0230` decision 10's direct-write model and `CTVolumeLayout` were not
  exercised here, because the shim that decodes into a destination buffer does
  not exist yet.
- **Not discharged**: the geometry-tolerance decision, which remains an owner
  gate — now with measurements attached.

## Reproduction

```text
harness: scratch executable, .package(path: "/Users/ranjith/Documents/Voxelia")
         products VoxeliaDICOMKit + VoxeliaImaging
input:   /Users/ranjith/telerad-dicom-input/CT/**  (one directory per series)
run:     ctdemo <series-directory>
```

Toolchain: Apple Swift 6.3.3 (`swiftlang-6.3.3.1.3 clang-2100.1.1.101`),
`arm64-apple-macosx26.0`. DICOMKit `2.2.11`.
