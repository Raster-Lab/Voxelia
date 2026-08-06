---
document_id: "ADR-0265"
title: "Cold cache measurement correction"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-021"
---

# ADR-0265 - Cold cache measurement correction

## Context

`ADR-0264` made the frame transfer `30x` faster, which invalidated every latency
figure in `VOXELIA-BEN-0001`. This record re-measures them, and in doing so found a
methodological error in my own three preceding benchmark records.

## The correction: "cold page cache" was an assumption, never a measurement

`ADR-0261` reported "cold import, page cache empty: `1.829` s" and built a finding on
the cold-to-warm ratio. `ADR-0263` and `ADR-0264` reasoned from the same kind of
figure.

**The harness never ensured an empty page cache.** It ran the import as the first
thing in a fresh process and called that cold — but the operating system's page cache
persists across process launches, so every run after the first inherits whatever
earlier runs left warm. The label described an intent, not a state.

This was caught by an inconsistency rather than by review: two nominally identical
"cold" measurements came out `0.437` s and `0.248` s, a `1.8x` spread that a genuine
first-touch measurement should not show. Measuring five consecutive fresh processes
settled it:

```text
0.284  0.253  0.255  0.255  0.255   (seconds, same first import)
```

Stable at about `0.255` s — because the files were warm in the OS cache throughout.
The single `0.437` s reading came from a moment when other work had evicted them, and
it is **not reproducible on demand**: dropping the cache needs elevated privileges
this measurement does not have.

## Decision

1. **The cold-to-warm ratios are withdrawn.** `ADR-0261`'s `1.21x` and `ADR-0264`'s
   `1.95x` measured cache state as much as they measured Voxelia. They are withdrawn
   rather than restated with a caveat, because a ratio whose denominator is unknown is
   not a weaker finding — it is not a finding.
2. **`ADR-0261`'s "the import is compute-bound, not I/O-bound" is withdrawn as
   stated.** Its evidence was the cold-to-warm ratio. The *conclusion* may well have
   been true of that code, and a separate cache-independent argument supported it — the
   transfer was 94 per cent of the median — but the claim as written rested on the
   ratio and does not survive it.
3. **The warm distribution is unaffected and remains the reliable measurement.** It
   never depended on cache state: 100 repetitions after 3 warm-ups, with a `0.025` s
   spread.
4. **`ADR-0261`'s no-leak finding is unaffected and explicitly survives.** Peak
   resident across 104 sequential 449 MiB imports is a memory observation independent
   of the page cache.
5. **First-import figures are still reported, labelled as what they are** — first
   import of a fresh process under an unknown cache state — rather than deleted. They
   are useful as a rough upper bound on a warm import; they are not cold-cache
   figures.
6. **A genuine cold-cache measurement is recorded as outstanding**, needing a
   privileged cache drop between runs. It is not approximated.
7. **`VOXELIA-BEN-0001` goes to version 0.3** with every latency figure re-measured
   and this correction stated in its own section rather than a footnote.

## The re-measured baseline

Release build, real 899-frame 449 MiB series, `ADR-0261`'s method — 3 warm-ups
discarded, 100 measured repetitions, nearest-rank percentiles.

| Quantity | min | p50 | p90 | p95 | p99 | max |
|---|---:|---:|---:|---:|---:|---:|
| **Total import** | `0.213` | `0.216` | `0.223` | `0.226` | `0.236` | `0.238` |
| Metadata scan | `0.086` | `0.087` | `0.089` | `0.091` | `0.102` | `0.107` |
| Decode and transfer | `0.122` | `0.124` | `0.128` | `0.130` | `0.135` | `0.147` |

Plan §63's stages, first import of a fresh process:

| Stage | Release | Debug |
|---|---:|---:|
| Complete volume | `0.248` | `0.802` |
| First axial image | `0.342` | `0.932` |
| First three-view image / steady state | `0.736` | `1.843` |

Footprint, measured in a process doing exactly one import: **`464 MiB`**, `1.03x` of
one volume.

Derived, from the warm median: metadata scan ≈ `10,300` frames/s; decode and transfer
≈ `7,250` frames/s ≈ `3,620 MiB/s`; complete import ≈ `2,080 MiB/s`.

## What the corrected numbers show

**The import's profile has changed shape, not just scale.** Metadata scan is now
`0.087` s of a `0.216` s median — 40 per cent — against 6 per cent before `ADR-0264`.
Decode and transfer is 57 per cent, down from 94 per cent. Further transfer
optimisation would buy much less than the first `11.5x` did, and the metadata scan is
now a comparable cost.

**The spread tightened in absolute terms**, from `0.196` s to `0.025` s, which is what
removing a slow generic loop should do to variance as well as to the median.

## Alternatives considered

### Keep the cold figures and add a caveat

Rejected. A ratio between a reliable number and an unreliable one is not a measurement
with a caveat; it is a number that should not be quoted. Retaining it with a footnote
would leave a figure available for citation that this record has just shown means
nothing.

### Drop the first-import figures entirely

Rejected. They are reproducible — five runs within `0.031` s — and useful as an upper
bound on a warm import. The error was the label, not the measurement.

### Run `sudo purge` between repetitions to get a real cold figure

Rejected for this increment: it requires elevated privileges, and this project does
not run privileged commands on the owner's machine for a benchmark. Recorded as
outstanding.

### Approximate a cold cache by reading unrelated large files first

Rejected. Evicting a cache by filling it measures the eviction policy as much as the
import, and would produce another figure whose provenance nobody could reconstruct.

### Leave `ADR-0261`'s compute-bound conclusion standing, since a separate argument supported it

Rejected as written. The record's stated evidence was the ratio. A conclusion that
happens to be defensible on other grounds is still not established by evidence that
does not hold, and rewriting history to cite the argument I did not make would be
worse than withdrawing the claim.

## Consequences

`VOXELIA-BEN-0001` version 0.3 carries current figures and an explicit account of what
versions 0.1 and 0.2 got wrong.

Three of my own records are corrected on the same point: `ADR-0261`, `ADR-0263` and
`ADR-0264` each quoted a cold-to-warm comparison that does not hold.

**The findings that survive are the cache-independent ones**: the no-leak result over
104 imports, the `30x` transfer improvement measured warm-to-warm, and the footprint
ratio.

## Affected modules

None. Measurement and documentation only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None added. Figures reported above.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record and `VOXELIA-BEN-0001` version 0.3.
2. **Outstanding**: a genuine cold-cache measurement, needing a privileged cache drop.
3. **Owner decisions, unchanged**: the six from `ADR-0254` and the two from
   `ADR-0255`. Reference-hardware approval remains the prerequisite for any formal
   performance acceptance.

## Supersession

This record supersedes nothing. It **withdraws specific claims** from `ADR-0261`,
`ADR-0263` and `ADR-0264`, recording the withdrawal here rather than editing those
records.

## References

- [VOXELIA-BEN-0001 - First vertical slice benchmark baseline](../../benchmarks/VOXELIA-BEN-0001-first-vertical-slice-baseline.md)
- [ADR-0261 - Benchmark repetition method](ADR-0261-benchmark-repetition-method.md)
- [ADR-0263 - Stress volume and byte collection cost](ADR-0263-stress-volume-and-byte-collection-cost.md)
- [ADR-0264 - Range replacement frame transfer](ADR-0264-range-replacement-frame-transfer.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
