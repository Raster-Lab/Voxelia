---
document_id: "VOXELIA-BEN-0001"
title: "First vertical slice benchmark baseline"
version: "0.3"
status: "Draft"
document_type: "Benchmark Report"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Validation"
---

# First vertical slice benchmark baseline

> **Version 0.3 re-measures every latency figure after `ADR-0264`**, which replaced
> the frame transfer's element-wise byte loop with a standard-library range
> replacement. The complete import's warm median fell from `1.515` s to `0.216` s.
>
> **It also corrects a methodological error in versions 0.1 and 0.2**: those reported
> a "cold import, page cache empty" figure, and the harness never ensured an empty
> cache. See "Warm-up and repetitions". The cold-versus-warm claims built on it are
> withdrawn.

## Objectives and correctness gate

This is the benchmark half of `VOX-VS1-021`'s deliverable. Its objective is the one
plan §63 states can be met without approved thresholds:

> "M4 shall establish a reproducible baseline even where no absolute first-image
> threshold has yet been approved."

**A baseline is what this report establishes. It is not a performance
acceptance.** Plan §61 requires formal performance acceptance to run on at least
one approved `A-WORKSTATION` Apple Silicon Mac; no such approval exists, so no
acceptance is claimed, and no measurement here should be read as a pass against a
threshold. There are no approved thresholds to pass.

**Correctness gate: satisfied.** Plan §53 requires the correctness gate before any
performance comparison. 1024 tests in 191 suites pass, and the real-data
verification is recorded in `VOXELIA-VAL-0001`. Timings below were taken from a
build of the same commit.

## Scenarios and datasets

**One scenario: cold import of a real thoracic CT series, then three-plane
reconstruction.**

| Property | Value |
|---|---|
| Series | `Thorax_COVID_100_THIN_LUNG_3` |
| Frames | 899 |
| Frame extents | `512x512` |
| Sample format | `uint16`, Pixel Representation `0` |
| Assembled volume | `512x512x899`, 471,334,912 B (449 MiB) |
| Column spacing | `0.95313671875` mm |
| Geometry verdict | `representable` at `exact` tolerance |

The measurement runs in a **fresh process performing exactly one import**, because
`ru_maxrss` is a high-water mark: taken inside a longer-running harness it reported
a meaningless `0 MiB` delta.

## Hardware and environment

| Item | Value |
|---|---|
| Model | `Mac17,4` |
| SoC | Apple M5 |
| CPU cores | 10 (4 performance, 6 efficiency) |
| GPU cores | 10 |
| Physical memory | 24 GiB |
| Storage | Internal SSD (dataset read from local filesystem) |
| Operating system | macOS 26.5.1 (`25F80`) |
| Xcode | 26.6 |
| Swift compiler | Apple Swift 6.3.3 (`swiftlang-6.3.3.1.3 clang-2100.1.1.101`) |
| Display refresh rate | Not applicable — no interactive path exists |
| Power state | Mains, not characterised |
| Thermal state | Not instrumented |
| Source commit | `9cc241b26b4009118703ab6c89589c170c6f5152` |

**Not approved reference hardware** (plan §61). Power and thermal state are
recorded as uncharacterised rather than guessed; §61 lists both, and this report
does not have them.

## Warm-up and repetitions

**Version 0.1 of this report had neither, and named that as its principal
limitation. `ADR-0261` resolved it.**

| Setting | Value |
|---|---|
| Warm-up iterations | 3, discarded |
| Measured repetitions | 100 |
| Percentile rule | nearest-rank, frozen by `ADR-0261` |

**The percentile rule matters and is stated rather than left to a library
default.** `rank = ceil(percentile x n / 100)`, clamped to `[1, n]`, computed in
integer arithmetic, and the value is the `rank`-th smallest sample. **No
interpolation, so every figure below is a measurement that actually occurred** —
an interpolating convention would report a median lying between two observations,
which for latency invites a reader to treat a synthesised number as an observed
one.

One hundred repetitions is chosen so the required percentiles are **distinct**. At
`n = 100` the 90th, 95th and 99th select the 90th, 95th and 99th smallest samples;
at `n = 9` all three would equal the maximum, and the report would show three
identical numbers as though they were three statistics.

### Correction: this harness cannot produce a cold page cache

Versions 0.1 and 0.2 reported a figure labelled "cold import, page cache empty".
**The harness never ensured an empty cache, and a fresh process does not give one** —
the operating system's page cache persists across process launches, so every run after
the first inherits whatever the previous runs left warm.

Measured directly: five consecutive fresh processes reported `0.284`, `0.253`, `0.255`,
`0.255` and `0.255` s for the same first import. A single earlier reading of `0.437` s
was recorded when the cache had been evicted by other work, and it is **not
reproducible on demand** — dropping the cache requires elevated privileges this
measurement does not have.

**Consequences, stated rather than quietly dropped:**

- The "cold" figures in versions 0.1 and 0.2 were first-import-of-a-fresh-process
  figures under an unknown cache state, not cold-cache figures.
- The cold-to-warm ratios derived from them — `1.21x` in version 0.2, and the `1.95x`
  quoted in `ADR-0264` — are **withdrawn**. Both measured cache state as much as they
  measured Voxelia.
- The **warm distribution is unaffected** and remains the reliable measurement: 100
  repetitions with a `0.025` s spread.
- A genuine cold-cache figure needs a privileged cache drop between runs, and is
  recorded as outstanding rather than approximated.

The first-import figures are still reported, labelled as what they are.

## Latency and throughput

Plan §63 asks the report to distinguish named stages. Timings are seconds from
process start, taken through `CTImportSession`'s cancellation probe — which
`ADR-0249` added for cancellation and which, because it is consulted at every named
checkpoint, also serves as the progress reporter plan §22.1 asked for.

| Stage (§63) | Release | Debug |
|---|---:|---:|
| **Complete volume** | `0.248` | `0.802` |
| Volume published | `0.248` | `0.802` |
| **First axial image** | `0.342` | `0.932` |
| **First three-view image / steady state** | `0.736` | `1.843` |

Measured on the first import of a fresh process, which is **not** a cold page cache —
see below. Earlier stages (metadata-ready, geometry accepted, first decoded frame) are
reported in the distribution table instead, where they have dispersion rather than a
single reading.

Derived throughput, release, from the warm median:

| Quantity | Value |
|---|---|
| Metadata scan | 899 frames in `0.087` s ≈ **10,300 frames/s** |
| Frame decode and transfer | 899 frames in `0.124` s ≈ **7,250 frames/s**, ≈ **3,620 MiB/s** |
| Complete import | 449 MiB in `0.216` s ≈ **2,080 MiB/s** |
| Axial plane extraction | `0.094` s |
| Coronal and sagittal extraction | `0.394` s combined |

**Both configurations are reported because the difference is large and a debug
figure alone would mislead.** Release completes the import in `0.248` s against
`0.802` s debug — a `3.2x` difference. Any future comparison must state its build
configuration.

### Latency distribution (release, 100 measured repetitions)

After 3 discarded warm-ups. Seconds. Nearest-rank percentiles per `ADR-0261`.

| Quantity | min | p50 | p90 | p95 | p99 | max |
|---|---:|---:|---:|---:|---:|---:|
| **Total import** | `0.213` | `0.216` | `0.223` | `0.226` | `0.236` | `0.238` |
| Metadata scan | `0.086` | `0.087` | `0.089` | `0.091` | `0.102` | `0.107` |
| Decode and transfer | `0.122` | `0.124` | `0.128` | `0.130` | `0.135` | `0.147` |

Spread of the total: **`0.025` s** over 100 repetitions — about 12 per cent of the
median, and tighter in absolute terms than version 0.2's `0.196` s.

### What the distribution shows

**The import is now roughly balanced between metadata reading and byte transfer.**
Metadata scan is `0.087` s of the `0.216` s median (40 per cent) and decode plus
transfer is `0.124` s (57 per cent). Before `ADR-0264` the transfer alone was 94 per
cent, so the profile has changed shape, not merely scale: optimising the transfer
further would now buy much less than the first `11.5x` did.

**Version 0.2's compute-bound conclusion is withdrawn**, not because it was wrong
about the code it measured but because the evidence for it — a cold-to-warm ratio —
rests on a cold figure this harness cannot produce reliably. See below.

**No retention leak across 104 sequential imports.** Each iteration allocates a
449 MiB volume and peak resident stays at `464`–`466 MiB`, `1.03x` of one volume, from
the first import to the last. This finding is **cache-independent** and survives the
correction above; it is materially stronger evidence for plan §59.4's leak criterion
than a single-import measurement.

Two observations that are properties of the design rather than of the hardware:

- **The sagittal plane is the slowest**, consistently. It fixes the fastest-varying
  index, so its extraction has the least contiguous access pattern of the three.
- **The first axial image comes *after* the complete volume**, not before, because
  reconstruction reads a published volume. Plan §63's requirement is that a first
  image not wait on *optional* preprocessing, and there is none — but progressive
  display during loading is not supported. Recorded as a limitation in
  `VOXELIA-VAL-0001`.

## Memory and copies

Plan §19.6's list, with absences stated as absences:

| Quantity | Value |
|---|---|
| Source decoded byte count | 471,334,912 B (449 MiB) |
| Final canonical storage byte count | 471,334,912 B (449 MiB) |
| **Metal full-volume resource byte count** | **0 B — no full volume is uploaded** |
| Output resource byte count | Per plane: axial 262,144 B; coronal 460,288 B; sagittal 460,288 B (`uint8`) |
| Peak resident memory | 471 MiB (release), 472 MiB (debug) |
| Steady-state resident memory | 471 MiB |
| Bytes copied during import | 449 MiB — one copy per frame, which is the materialisation |
| Retained compressed-source footprint | Not measured; the frame source retains URLs, not bytes |
| **Evidence that a second full decoded volume is absent** | Peak is `1.05x` of one volume; a second copy would show `2.0x` |

**The `1.05x` figure is the load-bearing one.** For a 449 MiB volume the process
peaks at 471 MiB — one volume plus five percent for the process, the frame source's
URL map and one frame's bytes at a time.

The Metal full-volume resource is **zero because the transfer never happens**: the
multiplanar path extracts a two-dimensional plane on the CPU and uploads that.
See `ADR-0253`.

Storage-boundary accounting, which is plan §59.4's leak criterion measured directly
rather than inferred from process memory:

```text
read coordinator charged at rest:                 0 bytes
charged while one full-volume read is retained:   449 MiB
charged after release:                            0 bytes
```

## Energy and thermal observations

**None.** Neither is instrumented. Plan §61 lists thermal state among the required
records; this report does not have it, and no substitute is offered.

## Baseline comparison

**No prior baseline exists**, so there is nothing to compare against. This document
is intended as the reference point for the first comparison.

For a future comparison to be valid against these figures it must state: build
configuration (release or debug), the same series or an equivalently characterised
one, a fresh process for memory, and its warm-up and repetition counts. It should
use `ADR-0261`'s frozen nearest-rank percentile rule, because a comparison against
these percentiles computed under an interpolating convention would not be
comparing like with like.

## Regressions and limitations

1. **Resolved in version 0.2**: the report now carries a 100-repetition
   distribution with 3 discarded warm-ups, so plan §53's distribution comparison is
   possible. `ADR-0261` records the method.
2. **Not approved reference hardware**, so **still no performance acceptance**
   (§61). A distribution makes a comparison possible; it does not make an
   unapproved threshold approved.
3. **Power and thermal state uncharacterised.**
4. **One series, one scanner, one machine.** No variation established.
5. **Plan §59.3's stress cases not run**: `512x512x1024` signed 16-bit, repeated
   dataset replacement, repeated open/close cycles, export during interactive
   rendering. The last requires the owner-gated interactive path.
6. **Debug timings included deliberately** so the `2.3x` gap is visible, not so
   they can be quoted as performance.
7. **The GPU is barely exercised.** The multiplanar path uploads 2D slices; no
   volume rendering is measured, so these figures say almost nothing about GPU
   throughput.
8. **`validate-scaffold.sh` is red** on an Apple Swift 6.3.3 `swift-frontend`
   signal 11 (`ADR-0224`). Recorded here because a benchmark report that omitted a
   failing release gate would misrepresent the build's state.

## Conclusion

The first vertical slice imports a real 899-frame, 449 MiB thoracic CT series and
reaches three-view steady state in **2.35 s** in a release build, retaining
**1.05x** of one volume, with no full-volume GPU upload and no second decoded
volume at any point. Over 100 warm repetitions the import's median is **1.515 s**
with a **0.196 s** spread, and 104 sequential imports left peak resident unchanged.

**That is a reproducible baseline with a distribution, and it is still not an
acceptance.** No threshold has been approved to compare it against, and the
hardware is not approved reference hardware. The repetition method that version 0.1
recorded as outstanding is now supplied (`ADR-0261`); **reference-hardware approval
remains the outstanding prerequisite for formal performance acceptance.**
