---
document_id: "ADR-0407"
title: "Benchmark reporting and instrumentation"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ERR-008"
  - "VOX-PER-010"
  - "VOX-PER-011"
  - "VOX-PER-012"
---

# ADR-0407 - Benchmark reporting and instrumentation

## Context

The `ADR-0405` queue's second arc: instrumentation overhead, benchmark
report contents, benchmark record fields, and regression thresholds.
The engineering halves are a schema and two seams; the measurement
campaigns and approved thresholds are the owner's.

## Decision

1. **`BenchmarkRecord` is the validated, `Codable` report row**
   (`VOX-PER-011`): hardware, operating system, compiler, Voxelia
   version, operation identity and version, optional shader identity
   (CPU entries have none, honestly optional), dataset, storage form,
   cache state, quality token, latency, throughput, peak memory and
   validation status — the baseline's field list verbatim, each
   admitted (non-empty strings, finite non-negative numbers),
   revalidating on decode.

2. **`BenchmarkMode` is the closed eight-case vocabulary**
   (`VOX-PER-010`): cold-start, warm-cache, steady-state,
   memory-pressure, cancellation, contention, headless-batch and
   distributed. Every record declares its mode; a report is a set of
   records, and "as applicable" means the report *says* which modes ran
   rather than implying them. The multi-mode measurement campaign is
   release evidence for the owner's session (the `A` halves).

3. **`RegressionCheck` is the threshold seam** (`VOX-PER-012`): a
   candidate record evaluates against a baseline record under a
   caller-declared fractional threshold — defaultless, because the
   approved threshold is the owner's `R` — and reports a closed
   pass/regression outcome on latency, throughput and memory. CI wiring
   consumes this seam; the policy lives with the owner.

4. **Instrumentation is removable by construction** (`VOX-ERR-008`):
   the analysis half records what the survey found — telemetry is
   sink-based and every producer accepts a `nil` sink, so a production
   host that passes nothing collects nothing, and no ambient global
   collector exists in the tree. The witness drives the benchmark
   vocabulary itself as pure data and cites the `nil`-sink surface;
   overhead when *enabled* is a measurement for the owner's campaign,
   not a promise invented here.

## Alternatives considered

### Free-form benchmark dictionaries

Rejected. A report schema nobody validates is the baseline's field
list lost one key at a time.

### A default regression threshold

Rejected — decision 3.

## Consequences

The release-policy arc can cite a real report schema; the loop's end
surfaces the campaigns to the owner.

## Affected modules

`VoxeliaValidation` gains the vocabulary.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

None; records are data.

## Validation impact

```text
swift test --filter BenchmarkReportTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the vocabulary, the witness suite and the register
   updates, in the same increment.
2. **Next**: the release-policy arc ends M10's engineering.

## Supersession

This record supersedes nothing.

## References

- [ADR-0405 - The M10 queue](ADR-0405-the-m10-queue.md)
- [ADR-0380 - The registration declaration contract](ADR-0380-the-registration-declaration-contract.md)
