---
document_id: "ADR-0109"
title: "Kernel throughput measurement campaign"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-007"
  - "VOX-MTL-008"
  - "VOX-VAL-007"
---

# ADR-0109 - Kernel throughput measurement campaign

## Context

`VOX-MTL-007` accepts shared CPU/GPU resources when this reduces
copies without unacceptable sampling cost, and `VOX-MTL-008` accepts
private resources when justified by measured performance; neither had
numbers. The `ADR-0107` telemetry makes kernel-time measurement
routine. This record was authored and accepted on 2026-08-05 under
the project owner's recorded broadened autonomous delegation.

## Decision

1. **A standing throughput harness.** The suite measures both kernel
   families over scaled corpora — through the megasample range —
   capturing the platform's own GPU times through the telemetry sink
   and printing samples-per-second evidence bound to the measured
   sizes, single-device labelled.
2. **The shared-residency justification, measured.** On this
   unified-memory device the kernels dispatch over shared-storage
   buffers that are host memory: no upload pass exists to measure,
   and that measured absence — zero copies, with the measured
   sampling cost printed beside it — is the `VOX-MTL-007`
   justification, recorded with numbers rather than assumed.
3. **Private residency honestly open.** A private-residency benefit
   is measurable only for a workload that repeatedly samples
   long-lived data through buffer-injected kernel paths, which do not
   exist; `VOX-MTL-008` stays open with that reason rather than
   receiving invented numbers, and the harness is the instrument a
   future repeated-sampling design will extend.

## Alternatives considered

Building buffer-injected kernel variants solely to benchmark private
residency was rejected: production paths should motivate production
surfaces, not benchmarks. Timing with a test-side clock was rejected:
the platform's command-buffer timestamps are the accepted measured
source.

## Consequences

`VOX-MTL-007` carries measured justification; `VOX-MTL-008` carries a
recorded honest gate and its future instrument.

## Affected modules

Test evidence only; no source change.

## Compatibility impact

None.

## Security impact

Evidence carries sizes, durations and public fingerprints only.

## Performance and memory impact

Test-time megasample allocations only.

## Validation impact

The harness must dispatch both families across scaled corpora
including at least one megasample corpus, verify every dispatch
delivered telemetry with the exact sample count, and print
samples-per-second evidence for each measured size.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0076` evidence discipline with throughput
measurement; no record is superseded.

## References

- [ADR-0107 - Kernel dispatch telemetry](ADR-0107-kernel-telemetry.md)
- [ADR-0081 - Metal residency strategy](ADR-0081-metal-residency-strategy.md)
