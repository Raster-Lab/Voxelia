---
document_id: "VOXELIA-BEN-0001"
title: "First vertical slice benchmark baseline"
version: "0.1"
status: "Draft"
document_type: "Benchmark Report"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Validation"
---

# First vertical slice benchmark baseline

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

**Neither is present, and that is the report's principal methodological
limitation.** The figures below are from a **single cold run per build
configuration** with no warm-up iteration, no repetition and therefore no
dispersion — no median, no variance, no confidence interval.

Plan §53's method for performance is "distribution comparison after correctness
gate". **A distribution is not offered here**, so this document establishes a
reproducible *reference point*, not a distribution. Producing one is recorded as
required future work rather than approximated.

## Latency and throughput

Plan §63 asks the report to distinguish named stages. Timings are seconds from
process start, taken through `CTImportSession`'s cancellation probe — which
`ADR-0249` added for cancellation and which, because it is consulted at every named
checkpoint, also serves as the progress reporter plan §22.1 asked for.

| Stage (§63) | Release | Debug |
|---|---:|---:|
| Metadata scan started | `0.026` | `0.028` |
| **Metadata-ready** (899 frames described) | `0.291` | `0.228` |
| Candidate grouping complete | `0.292` | `0.238` |
| **Geometry accepted** | `0.314` | `0.608` |
| **First decoded frame** | `0.314` | `0.608` |
| **Complete volume** | `1.841` | `4.283` |
| Descriptor and storage built | `1.842` | `4.283` |
| Identity and provenance minted | `1.842` | `4.287` |
| Volume published | `1.842` | `4.287` |
| **First axial image** | `1.942` | `4.425` |
| **First three-view image** | `2.350` | `5.352` |
| **Steady state** | `2.350` | `5.352` |

Derived throughput, release:

| Quantity | Value |
|---|---|
| Metadata scan | 899 frames in `0.291` s ≈ **3,090 frames/s** |
| Frame decode and transfer | 899 frames in `1.527` s ≈ **589 frames/s**, ≈ **294 MiB/s** |
| Complete import | 449 MiB in `1.841` s ≈ **244 MiB/s** |
| Axial plane extraction | `0.100` s |
| Coronal and sagittal extraction | `0.408` s combined |

**Both configurations are reported because the difference is large and a debug
figure alone would mislead.** Release completes the import in `1.841` s against
`4.283` s debug — a `2.3x` difference. Any future comparison must state its build
configuration.

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
one, a fresh process for memory, and warm-up and repetition counts — which this
report does not have and a comparison should.

## Regressions and limitations

1. **Single cold run, no warm-up, no repetitions, no dispersion.** The principal
   limitation; see above. Plan §53's distribution comparison is not satisfied.
2. **Not approved reference hardware**, so no performance acceptance (§61).
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
volume at any point.

**That is a reproducible baseline, not an acceptance.** No threshold has been
approved to compare it against, the hardware is not approved reference hardware,
and the single-run method supplies no distribution. Formal performance acceptance
needs the owner's reference-hardware approval and a repetition method; both are
recorded as outstanding.
