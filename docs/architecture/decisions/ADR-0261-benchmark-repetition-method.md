---
document_id: "ADR-0261"
title: "Benchmark repetition method"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-021"
---

# ADR-0261 - Benchmark repetition method

## Context

`VOXELIA-BEN-0001` established the first vertical slice's performance baseline and
named its own principal limitation: **a single cold run per build configuration, no
warm-up, no repetitions, and therefore no distribution** — while plan §53's method
for performance is "distribution comparison after correctness gate".

The Validation and Benchmark Strategy is more specific still. §40 requires a report
to record the number of warm-up iterations and measured repetitions, and §42.1
requires latency to be reported as **minimum, median, 90th, 95th, 99th percentile
and maximum**.

So percentiles are mandatory, and percentile conventions differ — which makes this a
numeric boundary requiring a frozen rule rather than a library default.

## Decision

1. **The percentile rule is frozen as nearest-rank**, computed in integer
   arithmetic: `rank = ceil(percentile x n / 100)`, clamped to `[1, n]`, and the
   value is the `rank`-th smallest sample.
2. **No interpolation, and that is the point: every reported figure is a
   measurement that actually occurred.** An interpolating convention would report a
   median of an even-length sample as a value lying between two observations — a
   number no run produced. For latency that is worse than useless: it invites a
   reader to treat a synthesised figure as an observed one.
3. **The rank is computed without floating point.** `numerator = percentile * n`,
   then `rank = numerator / 100` incremented when `numerator % 100 != 0`. A
   floating-point `ceil` would make the rank of a boundary case depend on rounding.
4. **Three warm-up iterations, discarded; one hundred measured repetitions.** The
   hundred is chosen so the required percentiles are **distinct**: at `n = 100` the
   90th, 95th and 99th select the 90th, 95th and 99th smallest samples. At small `n`
   they collapse — with nine samples, `ceil(0.90 x 9) = ceil(0.95 x 9) = ceil(0.99 x
   9) = 9`, so all three would equal the maximum and the report would present three
   identical numbers as though they were three statistics.
5. **Cold and warm are different quantities and are reported separately.** The first
   iteration of a fresh process is the only one whose file reads are not served from
   the page cache. Folding it into the distribution would contaminate the sample with
   a measurement of a different thing; discarding it silently would lose the figure a
   user actually experiences opening a study. So the cold import is reported as its
   own single measurement and the distribution covers warm-cache repetitions.
6. **No algorithm specification and no oracle.** The rank rule is integer
   arithmetic with an exact result, and selecting the `rank`-th smallest is a
   selection rather than a computation. There is no floating-point boundary to
   freeze.

## What the method measured

Release build, real 899-frame `512x512` `uint16` series (449 MiB), Apple M5, three
warm-ups discarded, one hundred measured repetitions:

| Quantity | min | p50 | p90 | p95 | p99 | max |
|---|---:|---:|---:|---:|---:|---:|
| Total import | `1.492` | `1.515` | `1.610` | `1.646` | `1.678` | `1.688` |
| Metadata scan | `0.089` | `0.091` | `0.097` | `0.098` | `0.104` | `0.133` |
| Decode and transfer | `1.397` | `1.417` | `1.508` | `1.547` | `1.575` | `1.580` |

Cold import, page cache empty: **`1.829` s**. Spread of the warm total: `0.196` s.

## Three findings the distribution produced that a single run could not

**1. The import is compute-bound, not I/O-bound.** Cold is only `1.21x` the warm
median. If reading 899 files from disk dominated, a warm run served entirely from the
page cache would be far faster than that. The decode-and-transfer stage is `1.417` s
of the `1.515` s median — ninety-four percent — so effort spent on faster file access
would buy almost nothing, and the earlier single-run figures gave no way to know
that.

**2. The metadata scan is the strongly cache-sensitive stage, and it is small.**
`0.291` s in the earlier cold single run against a `0.091` s warm median: a `3.2x`
difference, far larger than the whole import's `1.21x`. So the caching effect is real
but concentrated in the stage that contributes six percent of the total. Reporting
only a whole-import figure would have hidden both halves of that.

**3. No retention leak across one hundred and four sequential imports.** Each
iteration allocates a 449 MiB volume, and peak resident stayed at `467 MiB` — `1.04x`
of one volume — from the first import to the last. If any volume were retained, peak
would have climbed in multiples. This is **much stronger evidence for plan §59.4's
leak criterion than `ADR-0253`'s single-import measurement**, which could only show
that one import did not duplicate.

The third finding is the increment's most useful outcome, and it was a by-product:
the repetitions were added for a latency distribution and they incidentally became a
retention stress test.

## Alternatives considered

### Use a linear-interpolation percentile, as most statistics libraries default to

Rejected; see decision 2. It manufactures values no run produced, and for a latency
report that is a misrepresentation rather than a convenience.

### Report mean and standard deviation

Rejected. Both require a summation order to be deterministic, which would make this a
floating-point boundary needing an algorithm specification and an oracle — for
statistics that are worse suited to skewed latency data than order statistics are.
Order statistics need no such freezing.

### Use nine or twenty-five repetitions to keep the run short

Rejected; see decision 4. The required percentiles would collapse onto the maximum,
and a report showing p90, p95 and p99 as three copies of one number would imply
precision it does not have. One hundred repetitions cost about two and a half
minutes.

### Fold the cold measurement into the distribution

Rejected; see decision 5. It measures a different quantity, and one contaminating
sample in a hundred would shift the maximum while telling a reader nothing.

### Discard the cold measurement entirely

Rejected for the opposite reason: it is the figure a user experiences on first
opening a study, and it is the only one that exercises uncached reads.

## Consequences

Plan §53's distribution comparison is now possible, and `VOXELIA-BEN-0001`'s
principal limitation is resolved: it carries a distribution rather than a single run.

**What remains outstanding is unchanged and is not addressed by this record**: the
reference-hardware approval plan §61 requires before any *formal performance
acceptance*, and the provisional `voxelia.m4.ct.diagnostic` tolerance profile. A
distribution makes a comparison possible; it does not make an unapproved threshold
approved.

Power and thermal state remain uninstrumented.

## Affected modules

None. The method is a benchmark procedure; the harness is a scratch executable, and
no repository test reads the owner's data.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None added. The measurements are reported above.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The measurement itself is a recorded harness run, reproduced in
`VOXELIA-BEN-0001` version 0.2.

## Migration

1. This record and `VOXELIA-BEN-0001` version 0.2.
2. **Open**: power and thermal instrumentation, which belongs with approved
   reference hardware rather than with an unapproved baseline.
3. **Owner decisions, unchanged**: reference-hardware approval and the tolerance
   profile, both prerequisites for formal performance acceptance.

## Supersession

This record supersedes nothing. It **resolves a limitation** `VOXELIA-BEN-0001`
version 0.1 stated about itself, and that report is revised rather than replaced.

## References

- [VOXELIA-BEN-0001 - First vertical slice benchmark baseline](../../benchmarks/VOXELIA-BEN-0001-first-vertical-slice-baseline.md)
- [ADR-0253 - Steady state volume footprint](ADR-0253-steady-state-volume-footprint.md)
- [ADR-0254 - First slice validation and benchmark reports](ADR-0254-first-slice-validation-and-benchmark-reports.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
