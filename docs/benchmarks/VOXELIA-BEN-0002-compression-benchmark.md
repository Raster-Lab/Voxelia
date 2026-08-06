---
document_id: "VOXELIA-BEN-0002"
title: "Compression benchmark"
version: "0.1"
status: "Draft"
document_type: "Benchmark Report"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Validation"
---

# Compression benchmark

## Objectives and correctness gate

`VOX-CMP-014` requires compression benchmarks to report **ratio, encode time, decode
time, random-access cost, memory use and output equality**. All six are below.

**Correctness gate: satisfied.** 1086 tests in 200 suites pass, and every
configuration measured here was verified byte-exact against its source before its
timings were recorded — a compression benchmark whose output is not provably
identical measures the wrong thing.

**This is a baseline, not a performance acceptance.** Reference-hardware approval
remains outstanding (plan §61), so no measurement here should be read as a pass
against a threshold.

## Scenarios and datasets

The owner's real thoracic CT series, encoded from Voxelia's own imported samples
rather than from a borrowed fixture — the question is how these codecs behave on
Voxelia's data.

| Property | Value |
|---|---|
| Series | `Thorax_COVID_100_THIN_LUNG_3` |
| Volumes measured | 128, 256 and 899 slices of `512x512` `uint16` |
| Full volume | `512x512x899`, 449 MiB |
| Modes | JP3D lossless, HTJ2K lossless |

## Hardware and environment

`Mac17,4`, Apple M5, 10 CPU cores (4P/6E), 10 GPU cores, 24 GiB, macOS 26.5.1,
Apple Swift 6.3.3, release build. `J2KSwift 11.0.2`.

**Not approved reference hardware** (plan §61). Power and thermal state
uninstrumented.

## Warm-up and repetitions

**None, and this report says so rather than implying otherwise.** These are single
measurements. `ADR-0261` froze a repetition method for the import benchmark and
observed that codec timings here vary by up to roughly **2x** between runs of the same
configuration.

- **Ratios are exact** — they are byte counts, unaffected by timing variance.
- **Output equality is exact** — a byte comparison.
- **Large ratios between modes survive the variance**; small ones are directional.
- **The random-access result is a 115x gap**, far beyond any observed noise.

Applying the hundred-repetition method to a 15-second encode would take about half an
hour for conclusions the current spread already supports. It is available, not
performed.

## Ratio and output equality

| Volume | Mode | Encoded | Ratio | Byte-exact |
|---|---|---:|---:|:---:|
| 899 slices (449 MiB) | JP3D lossless | 195 MiB | **2.30:1** | **yes** |
| 899 slices (449 MiB) | HTJ2K lossless | 203 MiB | **2.21:1** | **yes** |
| 256 slices (128 MiB) | HTJ2K lossless | 54 MiB | **2.34:1** | **yes** |
| 128 slices (64 MiB) | JP3D lossless | 25 MiB | **2.53:1** | **yes** |
| 128 slices (64 MiB) | HTJ2K lossless | 26 MiB | **2.41:1** | **yes** |

Ratio declines slightly with volume length — `2.53:1` at 128 slices against `2.30:1`
at 899 — consistent across both modes.

**Every `isLossless` claim was verified by comparing decoded bytes against the source
volume.** The codec's flag was never taken as evidence on its own.

## Encode and decode time

Full 449 MiB volume:

| Mode | Encode | Decode |
|---|---:|---:|
| JP3D lossless | `15.47` s (29 MiB/s) | `9.93` s (45 MiB/s) |
| HTJ2K lossless | **`3.45` s (130 MiB/s)** | **`6.23` s (72 MiB/s)** |

HTJ2K is `4.5x` faster to encode and `1.6x` faster to decode for 4 per cent worse
ratio.

## Random-access cost

**The metric that changes the picture.** HTJ2K, 256-slice volume, region decode
through `JP3DDecoder.decode(_:region:)`:

| Request | Time | Voxels | Speedup vs full decode | Tiles decoded / skipped |
|---|---:|---:|---:|---|
| **One axial plane** | **`0.014` s** | 0.4 % | **`115.6x`** | 4 / 60 |
| 128-cube brick | `0.247` s | 3.1 % | `6.6x` | 8 / 56 |
| 64-slice slab | `0.314` s | 25.0 % | `5.2x` | 16 / 48 |

**Fourteen milliseconds to pull one axial plane out of a compressed volume.**

The speedup is not proportional to the voxel fraction, because tiles are the unit of
work: a plane touches 4 of 64 tiles and skips the rest, and a 3.1 per cent brick still
costs 8 tiles. **Tile geometry, not voxel count, sets random-access cost** — which
means access patterns aligned to tile boundaries are much cheaper than their volume
suggests.

## Memory use

Measured in a **clean process** doing nothing but import, encode and decode, because
a combined run retains several results at once and its peak is an artefact of the
harness. 256-slice volume, 128 MiB.

| Stage | Peak resident | Additional |
|---|---:|---:|
| After import | `397 MiB` | — |
| After encode | `953 MiB` | **`+556 MiB`, ≈ 4.3x the volume** |
| After full decode | `1,222 MiB` | `+269 MiB`, ≈ 2.1x the volume |
| After plane decode | `1,222 MiB` | no further growth |

The `397 MiB` import figure includes the harness holding the volume twice — Voxelia's
copy and the codec's — so it is not the `1.03x` import footprint `ADR-0263` measured.

**Encoding costs roughly four times the volume in working set.** Extrapolated to the
449 MiB volume that is around 1.9 GiB above baseline, which is comfortable on this
24 GiB machine and would not be on a smaller one.

Region decode added **no** measurable peak over full decode, so random access is cheap
in memory as well as time.

## Baseline comparison

No prior compression baseline exists; this is the reference point.

## Regressions and limitations

1. **Single measurements, no distribution.** See above.
2. **Not approved reference hardware**, so no performance acceptance.
3. **One series, one scanner, one machine.**
4. **Self-consistent codec.** Encoding and decoding use the same library, so these
   figures say nothing about interoperability with other implementations. That is
   `VOX-CMP-006`'s subject.
5. **`levelsZ` had no measurable effect** — `1` and `3` produced byte-identical
   output. Referred to `VOX-CMP-006`.
6. **Lossy modes not measured.** Both `lossy(psnr:)` and `targetBitrate(_:)` exist and
   were not exercised: no requirement asks for lossy diagnostic data, and measuring it
   here would invite treating it as endorsed.
7. **Memory figures are peaks, not allocation traces.** Plan §59.1's per-stage
   accounting is finer than `ru_maxrss` provides.

## Conclusion

Both modes compress this CT data losslessly at roughly **2.2 to 2.5 to one**, verified
byte-exact. **HTJ2K is the better mode on every axis except a 4 per cent ratio
cost.**

**The random-access result qualifies `ADR-0269`'s negative verdict on caching**, and
the qualification is the report's most useful output. As a *whole-volume* cache these
formats are poor — full decode is 29 to 46 times slower than re-importing the source.
As a *random-access store* the same representation serves one axial plane in
`0.014` s while holding 55 per cent less data. Those are different products of the
same artefact, and only measuring the second reveals it.

`ADR-0269` named this possibility as a condition that would change its conclusion.
The condition holds.
