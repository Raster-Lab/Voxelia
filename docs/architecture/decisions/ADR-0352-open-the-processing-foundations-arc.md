---
document_id: "ADR-0352"
title: "Open the processing foundations arc"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-010"
  - "VOX-R2D-004"
---

# ADR-0352 - Open the processing foundations arc

## Context

`ADR-0351` ordered M7's arcs and put the image-processing foundations first:
segmentation composes every one of them, and they are pure CPU numerics. This
record opens the arc with its load-bearing decision — the value domain — and
its first operation, the range threshold of `VOX-IMG-010`.

## Decision

1. **The arc's value domain is the stored domain, not the display domain**:
   `uint8`, `int16`, `uint16` and `float32`, single-channel scalar,
   `intensity` or `parametric` semantic. Processing operates on the study's
   stored values; admitting `float32` advances `VOX-R2D-004`, whose discharge
   arrives when the arc's operations admit the domain uniformly. Every
   admitted type widens to binary64 exactly, so the arc's comparisons carry
   no rounding.

2. **`ThresholdOperation` implements `VOXELIA-ALG-0057`** under the
   registered-operation pattern (token `org.voxelia.op.threshold`, CPU
   implementation, version `1.0.0`, budgeted full read, parameter document
   carrying the bounds and — only when present — the padding sentinel).
   The frozen order is padding first, NaN never included and counted,
   inclusive range third; the output is a `uint8` `mask`-semantic image of
   exact `0`/`1` values claiming the input geometry verbatim; a non-zero
   NaN count becomes the aggregated `org.voxelia.warn.threshold-non-finite`
   warning, absent when zero.

3. **Masks are labels, and `VOX-IMG-007` binds here**: the `0`/`1` output
   with `mask` semantic is what the nearest-neighbour resampling default
   protects. The arc's later mask consumers must refuse interpolating
   semantics — recorded now so the rule is in place before the first
   consumer.

4. **The remaining foundations follow in this arc's order**: mask
   application and image arithmetic (completing `VOX-IMG-010`), convolution
   and Gaussian with explicit boundary conditions (`VOX-IMG-011`),
   morphology (`VOX-IMG-012`), connected components (`VOX-IMG-013`),
   distance transforms (`VOX-IMG-014`) — each design-first against this
   record's domain.

## Alternatives considered

### Reuse the display-policy uint8 domain

Rejected. Thresholding display bytes would threshold a presentation, not the
study; CT's stored values are signed, and `VOX-R2D-004` names floating point
explicitly.

### Emit masks as 0/255 for direct display

Rejected; see decision 3. A mask is a label with a semantic, not a rendered
image; presentation maps labels through its own accepted stages.

## Consequences

The arc is open with its domain frozen; `VOX-IMG-010` is one-third discharged
(threshold), and every later foundation composes the same domain decision.

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it (nineteen
implementations; the combined registry twenty-two).

## Compatibility impact

Additive only.

## Security impact

None. Admission bounds every input before the read.

## Performance and memory impact

One pass over the stored bytes; one mask allocation.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0352-threshold-oracle.py
swift test --filter "ThresholdOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0057` and the oracle.
2. The operation, registration and fixture tests, in the same increment.
3. **Next**: mask application and image arithmetic, completing
   `VOX-IMG-010`.

## Supersession

This record supersedes nothing. It opens the arc `ADR-0351` ordered first.

## References

- [VOXELIA-ALG-0057 - Range threshold](../../algorithms/VOXELIA-ALG-0057-range-threshold.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
