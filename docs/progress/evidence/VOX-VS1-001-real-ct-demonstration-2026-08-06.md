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

## Fourth run: publication and multiplanar reconstruction, VOX-VS1-009

With `ADR-0238` through `ADR-0244` complete, the same 899-slice series was taken all
the way through publication and reconstructed in all three planes:

```text
frames 899  members 899  verdict representable
frame of reference: dicom:...4011161000000099
volume 512x512x899  complete true  449 MiB
ImageData built. source locators: 899
published.
axial    slice 449: extents [512, 512]  geometry axes [0, 1]  0.13s
coronal  slice 256: extents [512, 899]  geometry axes [0, 1]  0.23s
sagittal slice 256: extents [512, 899]  geometry axes [0, 1]  0.67s
```

**`VOX-VS1-009` is discharged on real patient data.** The volume is 512 columns by
512 rows by 899 slices, so axial drops axis 2 to give `[512, 512]`, coronal drops
axis 1 to give `[512, 899]`, and sagittal drops axis 0 to give `[512, 899]`. Every
extent is as `VOXELIA-ALG-0050`'s layout predicts.

**All three planes keep a spatial geometry**, including coronal and sagittal, whose
dropped slot is not last and therefore needed the column permutation `ADR-0244`
decided. Before that record none of the three could be produced at all.

The identity carries **899 source locators**, one per contributing frame, which is
how `VOX-VS1-019`'s source-frame provenance is discharged for an origin.

### The frame-of-reference check fired on real data

The first attempt failed with `frameOfReferenceNotPreserved`. That was the harness's
fault and the check's success: the real series carries a Frame of Reference UID, and
the harness had supplied a `CoordinateSpaceDescriptor` with **no** external
references. `ADR-0230` decision 8 requires any frame-of-reference the series carries
to appear among the descriptor's external references, because that is how
`VOX-DCM-007`'s preservation reaches the volume rather than stopping at the series.

**Every synthetic test passes `frameOfReference: nil`, so none of them exercises
that path.** The rule was written from the requirement and had never been fired
until real data supplied a UID. It is now demonstrated to reject a caller that
drops the frame of reference.

### Reconstruction cost

Axial is cheapest at 0.13 s because a one-thick axial slab is contiguous. Sagittal
is slowest at 0.67 s because its slab is maximally strided — one column from every
row of every slice. Nothing here is optimised, and the numbers are recorded as a
baseline rather than a claim.

## Fifth run: window centre and width, VOX-VS1-012

The real axial slice was windowed with the two settings a radiologist actually uses:

```text
window lung        (c -600, w 1500): uint8  extents [512, 512]  geometry preserved  0.04s
window soft tissue (c   40, w  400): uint8  extents [512, 512]  geometry preserved  0.04s
```

**`VOX-VS1-012` is verified on real data.** `WindowLevelOperation` carries no
geometry guard — unlike the squeeze `ADR-0244` had to fix — and propagates the
slice's `spatialGeometry` unchanged, so the display output still knows where it is
in patient space.

This is display output from real CT rather than a synthetic exercise: a lung window
and a soft-tissue window are the two settings a thorax study is actually read with.

## Sixth run: quantitative sample inspection, VOX-VS1-014

Three positions of the real axial slice, chosen for what they should contain:

```text
inspect centre   (256,256): stored 8232 -> 40.0 HU
inspect mid-left (128,256): stored 7237 -> -955.0 HU
inspect corner   (2,2):     stored 0    -> -8192.0 HU
```

**These are the right values, not merely well-formed ones.** 40 HU at the centre of
a thorax slice is mediastinum — soft tissue. -955 HU at mid-left is air-filled lung
parenchyma. The corner sits at the `-8192` floor, exactly what the histogram in the
third run predicted for the region outside the circular reconstruction field.

An implementation that indexed the wrong axis, dropped the rescale, or mis-signed
the samples would produce a plausible number in none of those three places, which is
why the positions were chosen by anatomy rather than convenience.

## Seventh run: patient-space distance, VOX-VS1-015

Two points 100 columns apart in the real axial plane, whose DICOM Pixel Spacing is
`0.95313671875` mm:

```text
distance 100 columns apart: measured 95.31367187500001 mm
                            naive prediction 95.313671875 mm   (1 ULP apart)
distance 100x100 diagonal:  134.793887445204 mm
```

**The naive prediction was wrong, not the measurement**, and the attribution was
computed rather than assumed:

| Step | Exact? |
|---|---|
| `sqrt(dx * dx) == dx` | **yes, exactly** — `VOXELIA-ALG-0010` contributes zero error |
| `dx == 100 * spacing` | **no** — one ULP |

The entire difference is the **affine's origin subtraction**:
`(origin + s·200) − (origin + s·100)` is not `100·s`, because both intermediates
round against the origin's magnitude of about `-249.5` before being subtracted. That
is what a real measurement does — a tool reporting `100 × spacing` would report a
number the geometry does not produce.

`VOX-VS1-015` is therefore satisfied by `MeasurementConstruction` under
`VOXELIA-ALG-0010`, correcting `ADR-0245`'s assessment that distance measurement was
not implemented. See `ADR-0247`.

## Run 8 - `VOX-VS1-013` linked patient-space crosshairs

The first composition of `ADR-0138`'s world-point slice mapping with `ADR-0140`'s
crosshair broadcast, against a scanner's affine rather than a fixture. One
crosshair at the patient-space position of voxel `(column 300, row 200,
slice 400)`, which is `(36.41758402499997, -211.89908785000003, -1166.683)` mm.

**Slice-index round trip** - each plane resolves its own component of the voxel:

| Plane | Fixed axis | Resolved | Expected | |
|---|---|---|---|---|
| Axial | 2 (slice) | `400` | `400` | MATCH |
| Coronal | 1 (row) | `200` | `200` | MATCH |
| Sagittal | 0 (column) | `300` | `300` | MATCH |

**Pixel round trip** - the three selected slices extracted, published, and the
crosshair broadcast to presentations built from each slice's own claimed geometry:

| Plane | View | Pixel | Expected | |
|---|---|---|---|---|
| Axial | `512x512` | `(300, 200)` | `(300, 200)` | MATCH |
| Coronal | `512x899` | `(300, 400)` | `(300, 400)` | MATCH |
| Sagittal | `512x899` | `(200, 400)` | `(200, 400)` | MATCH |

Exact in every case, with no tolerance applied. The coronal and sagittal rows are
the load-bearing ones: they exercise `ADR-0244`'s axis renumbering after the
singleton drop, which is what turns the slice axis into a view's `y`. This is its
first confirmation against real geometry.

**Refusals, verified alongside the successes:**

```text
axis-value overload on an affine-only volume: refused with unsupportedAxisSampling
out-of-volume sagittal slice index:           refused with crosshairOutsideVolume
```

The first is why `ADR-0138` added the world-point overload at all: the CT
descriptor declares `.indexOnly` sampling with an affine, so the `.regular`-only
axis-value path cannot serve it. The second never clamps to the last slice.

**The finding.** A crosshair 50 columns past the volume's edge resolved as:

```text
outsideViewport, outsideViewport, target(200,400)
```

The sagittal view **returned a pixel for a point outside the volume**. That is
correct at the unit level — the sagittal view presents row and slice, so an
out-of-range column cannot move the in-plane projection, and `PickResolver`
documents that non-presented slots do not gate admission. But it means
`crosshairTargets` alone is not an in-volume test: the guard is the slice-index
call, which refused this exact point, and which every host must make anyway to
know what to render. Recorded as a host composition obligation in `ADR-0248`
decision 2.

**Slice extraction cost**, for the record: axial `0.14 s`, coronal `0.23 s`,
sagittal `0.68 s`. The sagittal cost is the expected consequence of the least
contiguous access pattern over a 449 MiB volume.

**One harness mistake, caught by Voxelia.** The first attempt built the three
presentations with the camera at its own target, and `RenderCamera` refused it
with `degenerateViewDirection`. The camera plays no part in `ADR-0140`'s mapping,
which reads only geometry and viewport — but it must still be a valid camera, and
the admission said so.

## Run 9 - `ADR-0249` cancellable import on real data

`CTImportSession` driven over the same 899 files, with `DICOMFrameSource`
supplying descriptions and bytes. Cancellation is injected at each stage
boundary and **deep inside** each per-item stage, because cancelling at item zero
proves only an early exit.

| Cancelled at | Refused after |
|---|---|
| `metadataRead(0)` | `0.00 s` |
| `metadataRead(450)` | `0.09 s` |
| `grouping` | `0.18 s` |
| `frameValidation` | `0.19 s` |
| `decode(0)` | `0.56 s` |
| `decode(450)` | `2.45 s` |
| `assembly` | `4.34 s` |
| `identity` | `4.30 s` |
| `final` | `4.24 s` |

```text
every cancellation published nothing:        PASS
uncancelled control published:               PASS
matches the hand-written harness loop:       PASS
frame of reference carried:                  true
uncancelled import: 512x512x899, representable, 4.23 s
```

Every case refuses with `cancelled` and leaves the coordinator with no published
image, checked against the same `PublicationCoordinator` the uncancelled control
publishes into — so "nothing was published" is verified rather than assumed. The
control is what makes the nine refusals evidence of cancellation rather than of a
broken pipeline.

## Run 9a - a rationale refuted by its own measurement

The frame source re-reads each file when its bytes are wanted, rather than
retaining the parsed data set from the description pass. The stated reason was
that retention would cost memory to buy time. **A retaining mode was built to
offer that trade, and measuring it refuted the reason for its existence:**

| Mode | Elapsed | Peak resident |
|---|---|---|
| Re-read | `23.70 s` | `1789 MiB` |
| Retain | `23.47 s` | `2265 MiB` (`+476 MiB`) |

`1.01x` faster for `+476 MiB` — no speedup at all, because `DICOMFile.read` does
not eagerly copy a file's bytes. Re-reading is therefore strictly better, and the
option was **removed rather than shipped** as a plausible-sounding choice with no
measured benefit.

## Run 9b - what the time was actually going on

The same measurement carried a second, larger finding: if retention changes
nothing, then the ~23 s was **not** re-parsing. It was a copy introduced by the
new byte-reading entry point, which returned `[UInt8]` and so converted
DICOMKit's `Data` once per frame.

`CTImportSession` was made generic over the byte collection and
`DICOMFrameTransfer.frameBytes` now returns `Data`:

| | Elapsed |
|---|---|
| Returning `[UInt8]` | `22.85 s` |
| Returning `Data` | `4.23 s` |

**`5.4x`**, and the result now sits alongside the `3.77 s` the hand-written
transfer loop took in run 1 — the remaining difference being the description pass
the session also performs. About 20 ms per frame, roughly five times the transfer
itself, was being spent copying bytes that never needed copying.

The sequence is worth recording as method rather than as a number: a hedge added
against a guessed trade was measured, the guess was wrong, and the measurement
that removed the hedge is what exposed the real cost.

## Run 10 - `VOX-VS1-018` steady-state footprint

Measured in a **fresh process** performing exactly one import, because `ru_maxrss`
is a high-water mark: the same measurement inside this long-running harness
reported a `0 MiB` delta, which says only "this import stayed below an earlier
peak" and would have been a false conclusion.

```text
baseline peak before any import:  8 MiB
one full logical volume:          449 MiB
peak resident after import:       466 MiB
ratio to one volume:              1.04x
```

One volume plus four percent for the process, the frame source's URL map and one
frame's bytes at a time. **No second complete representation exists at any point.**

Storage-boundary accounting, which is §59.4's leak criterion measured directly
rather than inferred from process memory:

```text
read coordinator charged at rest:                    0 bytes
charged while one full-volume read is retained:      449 MiB
charged after release:                               0 bytes
```

**A suspected transient duplicate does not exist.** `CTVolumeStorageBuilder` calls
`ContiguousImageStorage(binding:bytes: Array(buffer.bytes))`, which reads like a
full-volume copy and would show as a peak near `2.0x`. It measures `1.04x`: the
buffer is uniquely referenced and unused afterwards, so the bytes move rather than
copy. The obvious "fix" — changing `CTVolumeByteBuffer.bytes` to `[UInt8]` —
would have been a public-API change buying nothing.

Contrast run 9b, where a suspected copy **was** real and cost `5.4x`. Identical
reasoning, opposite answers; only measurement distinguished them.

Reproduction of this run specifically:

```text
harness: a SEPARATE scratch executable doing one import and nothing else
run:     footprint <series-directory>
```

## Run 11 - plan §59.3's stress volume, and a 9.2x byte-collection finding

**No real series can serve the stress case.** The corpus was searched for a series
with at least 1,024 instances. One exists — **2,580 instances** — and importing it is
refused with `geometryRejected`: it assembles as a single series by identity, so this
is not a grouping problem, but its geometry is irregular at `exact` tolerance. The
largest real series Voxelia can admit remains the 899-slice one. **§59.3's stress
case therefore cannot be sourced from real data until the geometry-tolerance owner
gate is settled.**

Run synthetically instead, and labelled as such: 1,024 frames of `512x512`
**`int16`** at half-millimetre spacing, through the real `CTImportSession`.

```text
512x512x1024 int16 = 512 MiB      (not the ~1 GiB an earlier note stated)
geometry verdict:    representable at exact tolerance
peak resident:       523 MiB
ratio to one volume: 1.02x
```

The footprint property holds at scale, and this is the first end-to-end exercise of
**signed** samples: the owner's scanner writes `uint16`, so `int16` had only ever been
covered by fixtures.

### The finding: the caller's byte-collection type costs 9.2x

The first synthetic run took `13.397` s for 512 MiB **with no file I/O**, against
`1.841` s for 449 MiB read from disk in run 1. A synthetic run seven times slower per
byte than one that reads files is not plausible, so it was investigated.

`CTImportSession` is generic over `Bytes: Collection<UInt8>`. The DICOM path supplies
`Data`; the synthetic run supplied `ContiguousArray`. The same import, differing only
in that type:

| Byte collection | Elapsed | Peak |
|---|---:|---:|
| `ContiguousArray<UInt8>` | `13.397` s | `523 MiB` |
| `Data` | **`1.453` s** | `525 MiB` |

**`9.2x`, from the conforming type alone.** With `Data` the element-wise loop moves
512 MiB in `1.453` s — about **`352 MiB/s`**, nearly three times the `120 MiB/s`
`ADR-0235` recorded — so a large share of what looked like an inherent element-wise
copy cost is generic non-specialisation. `ADR-0263` records the refinement; no fix is
applied, because the contiguous fast path yields an `UnsafeBufferPointer` the safety
policy forbids.

## Run 12 - JP3D and HTJ2K on the real volume (`VOX-CMP-004`, `VOX-CMP-005`)

The 449 MiB volume encoded from its own samples through `JP3DEncoder`, decoded back,
and compared byte for byte.

| Mode | Encoded | Ratio | Encode | Decode | Byte-exact |
|---|---:|---:|---:|---:|:---:|
| JP3D lossless | 195 MiB | `2.30:1` | `15.47` s | `9.93` s | **yes** |
| HTJ2K lossless | 203 MiB | `2.21:1` | `3.45` s | `6.23` s | **yes** |

`isLossless` was **verified by comparison, not trusted as a flag**. `ADR-0268`'s
adapter admitted both decodes — its first run against real codec output.

**The cache question, answered by comparison with the path it would replace:**

```text
re-import from original DICOM (warm p50):  0.216 s
decode from an HTJ2K cache:                6.233 s   29x slower
decode from a JP3D cache:                  9.934 s   46x slower
```

A cache 29 to 46 times slower than re-reading the source is not a cache, so
`VOX-CMP-004` returns **no**. HTJ2K nonetheless beats JP3D at the same job by `4.5x`
encode and `1.6x` decode for 4 per cent ratio, so `VOX-CMP-005` returns **yes** on its
own terms.

**The evaluation checked it was not under-selling JP3D.** `levelsZ` defaults to `1`,
which would disable the inter-slice decorrelation a 3D codec exists for. Re-running at
`levelsZ: 3` gave **byte-identical encoded sizes**, so the parameter is not changing
the encode — referred to `VOX-CMP-006` rather than guessed at.

Timings are **single measurements** with up to ~2x run-to-run variance observed; the
ratios are exact byte counts, and the 29–46x cache gap is far beyond the noise.

## Reproduction

```text
harness: scratch executable, .package(path: "/Users/ranjith/Documents/Voxelia")
         products VoxeliaDICOMKit + VoxeliaImaging
input:   /Users/ranjith/telerad-dicom-input/CT/**  (one directory per series)
run:     ctdemo <series-directory>
```

Toolchain: Apple Swift 6.3.3 (`swiftlang-6.3.3.1.3 clang-2100.1.1.101`),
`arm64-apple-macosx26.0`. DICOMKit `2.2.11`.
