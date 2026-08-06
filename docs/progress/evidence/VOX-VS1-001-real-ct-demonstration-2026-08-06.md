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

## Second run: the pixel-data path, added by ADR-0235

The geometry-only run above left the pixel path untested. With `ADR-0235`'s
`CTVolumeByteBuffer` and `DICOMFrameTransfer`, the same 899-slice series was run
through the **complete** first vertical slice:

```text
frames: 899   series members: 899   verdict: representable
layout: 512x512x899 uint16
  samples: 235667456   bytes: 471334912 (449 MiB)
transferred: 899/899   complete: true
  elapsed: 3.77s
byte-exact slices: 899/899   mismatches: 0
```

The verification is independent of the transfer: for each slice, the buffer's
`sliceBytes(index)` was compared against DICOMKit's own
`pixelData()?.frameData(at: 0)` for the frame that slice came from. **All 899
matched byte for byte.**

### The samples are unsigned, and the fixtures assumed signed

This series carries Pixel Representation `0`, so the adapter selected **`uint16`**.
CT is conventionally described as signed, and every hand-built fixture in the
repository defaults to `int16`. The adapter reads Pixel Representation rather
than assuming, so it was right — but the assumption embedded in the fixtures was
**not representative of this real data**, and a design that had hard-coded signed
sixteen-bit would have mis-typed every volume from this scanner.

This is also why `ADR-0235` decision 2 keeps signedness out of the transfer: the
bytes are moved without interpretation, so being unsigned costs nothing at this
stage and is decided once, later, where the evidence for it lives.

### The cost of the safe copy, measured

449 MiB transferred element-wise in **3.77 s**, about **120 MiB/s**. A bulk memory
copy would run one to two orders of magnitude faster. That gap is the measured
price of `ADR-0235` decision 3 — no pointer or unsafe API, because the Swift
safety policy reserves the bare `unsafe` marker and `-strict-memory-safety`
diagnoses pointer APIs.

**Recorded as a real cost, not dismissed.** For a 449 MiB study it is a few
seconds; for an interactive workflow loading several studies it would be
noticeable. The options, none taken here, are an upstream DICOMKit
decode-into-destination entry point, or a governed exception to the safety policy
with an owner decision behind it.

## Third run: interpreted values, added by ADR-0236

With `CTValueInterpreter`, the middle slice of the same 899-slice series was read
through the complete path — bytes to Hounsfield units:

```text
volume: 512x512x899 uint16   complete: true
rescale: slope 1.0   intercept -8192.0   storedBits: container   padding: none
interpreter findings: []
middle slice 449: HU range -8192.0 .. 2637.0   padding samples: 0
  air (-1500..-900)         118757   45.3%
  below CT range             48253   18.4%
  lung/fat (-900..-100)      42851   16.3%
  soft tissue (-100..100)    39581   15.1%
  dense soft (100..300)       8728    3.3%
  bone (>= 300)               3974    1.5%
```

**The distribution is clinically plausible for a thorax slice**: air dominates,
lung and fat next, then soft tissue, with a small dense-soft and bone fraction
consistent with ribs and spine. The values are not merely well-formed; they are
the right values.

### The intercept is -8192, not -1024

Every hand-built fixture in the repository uses `-1024`, the textbook CT
intercept. **This scanner uses `-8192`.** The adapter reads Rescale Intercept
rather than assuming, so the interpretation is correct — but this is the second
time real data has contradicted an assumption baked into the fixtures, after the
signed-versus-unsigned finding above. The pattern is worth naming: **fixtures
written from domain convention encode the convention, not the data.**

### The out-of-field region is not declared as padding, and that is a real limit

18.4% of the slice sits below -1500 HU, at or near the `-8192` floor. That is the
region **outside the circular reconstruction field of view** — a circle inscribed
in a square array leaves about `1 - pi/4`, roughly 21.5%, in the corners, and 18.4%
is consistent with a circle extending slightly past the array edges.

**The scanner declares no Pixel Padding Value.** `padding: none`, and `padding
samples: 0`. So `VOX-DCM-008`'s padding-exclusion mechanism — which `ADR-0236`
implements correctly and which fixtures V9 and V10 verify — **cannot exclude this
region on this data**, because there is no attribute to exclude by. The
out-of-field samples are indistinguishable from measurements by attribute alone;
only their value marks them.

This is a limitation of the data, not of the implementation, and it is recorded
rather than worked around. Excluding an out-of-field region without a declared
padding value would require inferring it from the values themselves — a
segmentation decision, with a threshold, and therefore an owner decision of the
same shape as the geometry tolerance.

## Reproduction

```text
harness: scratch executable, .package(path: "/Users/ranjith/Documents/Voxelia")
         products VoxeliaDICOMKit + VoxeliaImaging
input:   /Users/ranjith/telerad-dicom-input/CT/**  (one directory per series)
run:     ctdemo <series-directory>
```

Toolchain: Apple Swift 6.3.3 (`swiftlang-6.3.3.1.3 clang-2100.1.1.101`),
`arm64-apple-macosx26.0`. DICOMKit `2.2.11`.
