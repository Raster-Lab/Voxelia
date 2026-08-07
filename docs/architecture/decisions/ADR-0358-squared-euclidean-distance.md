---
document_id: "ADR-0358"
title: "Squared Euclidean distance transform"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-014"
---

# ADR-0358 - Squared Euclidean distance transform

## Context

`VOX-IMG-014` — distance transforms, the last foundations row.
`VOXELIA-ALG-0063` freezes the three answers the ledger named: exact squared
Euclidean in sample units, distance to background, `uint32` parametric
output.

## Decision

1. **`DistanceTransformOperation`**
   (`org.voxelia.op.distance-transform`, CPU twenty-sixth implementation)
   implements the separable lower-envelope method with the frozen
   far-parabola sentinel, publishing exact integer squared distances — the
   square root is the consumer's presentation step, so the transform itself
   carries no rounding at all.

2. **Chamfer approximations are not built**: the exact method is linear per
   axis and the row deserves the exact answer; an approximation would need
   an approximation claim for no gain.

3. **No background rejects typed** — an infinite distance has no honest
   `uint32` spelling.

4. **`VOX-IMG-014` is discharged, and with it the processing foundations
   arc closes**: threshold, mask, arithmetic, convolution, Gaussian,
   morphology, components and distances all exist under one domain with
   oracle evidence. The segmentation arc opens next.

## Alternatives considered

### Publish plain distances as float32

Rejected. The square root is the transform's only possible rounding;
publishing squares keeps the operation exact and the choice with the
presenter.

### Chamfer masks

Rejected; see decision 2.

## Consequences

The foundations arc is complete; `VOX-SEG-001` (the segmentation model)
opens the next arc.

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it
(twenty-six implementations; the combined registry twenty-nine).

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

Linear per axis; one binary64 working buffer.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0358-distance-transform-oracle.py
swift test --filter "DistanceTransformOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The implementation is verified against a brute-force oracle sharing no
structure with it. The full suite must show the literal pass line before
push.

## Migration

1. This record with `VOXELIA-ALG-0063` and the oracle.
2. The operation, registration and fixture tests, in the same increment.
3. **Next**: open the segmentation arc (`VOX-SEG-001`, the mask and
   multi-segment model).

## Supersession

This record supersedes nothing. It closes the arc `ADR-0352` opened.

## References

- [VOXELIA-ALG-0063 - Squared Euclidean distance](../../algorithms/VOXELIA-ALG-0063-squared-euclidean-distance.md)
- [ADR-0352 - Open the processing foundations arc](ADR-0352-open-the-processing-foundations-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
