---
document_id: "ADR-0128"
title: "Composite calibration passthrough"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-013"
  - "VOX-EXE-002"
  - "VOX-ERR-001"
---

# ADR-0128 - Composite calibration passthrough

## Context

The compositing operation rejected calibrated layers, so
geometry-bearing scenes could not blend even though blending moves no
samples; the inversion operation already passes its whole descriptor
through, needing nothing. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`CompositeLayersOperation` widens to 1.2.0 under the established
rule:

1. **Equal calibration in, that calibration out.** Every layer's axis
   list — descriptors, sampling payloads and all — and spatial
   geometry must be exactly equal across the scene, with any
   difference the new typed `layerCalibrationMismatch`: blending
   samples that sit at different physical positions would fabricate a
   position for the blend, and exact equality is the only rule that
   needs no resampling model. The output carries the shared axes and
   geometry unchanged, because the blend moves no samples.
2. **Dead cases removed.** The former index-only sampling rule and
   the geometry rejection have no remaining throw sites and are
   removed per the dead-case precedent; the equality rule subsumes
   both.
3. **The device implementation stays at its contract.** The device
   composite continues to claim contract 1.1.0 — the geometry-free
   revision it implements — per the established
   claim-what-you-implement rule; its widening is its own future
   increment.

## Alternatives considered

Resampling layers onto a shared grid inside the composite was
rejected: that is the resampling operations' job, composed
explicitly. Comparing geometry approximately was rejected: the
no-epsilon rule stands, and hosts that need alignment resample first.

## Consequences

Geometry-bearing scenes blend end to end on the CPU path with
calibration preserved; frame-of-reference preservation extends
through compositing.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Admission widening under the established version bump; geometry-free
behaviour byte-identical; two dead cases removed, one typed case
added.

## Security impact

Unchanged budgets; typed payload-free rejections.

## Performance and memory impact

Per-layer descriptor equality checks.

## Validation impact

Tests must blend two identically calibrated layers with the axes and
geometry preserved and the widened version in the recipe, keep
geometry-free blends byte-identical, and reject a calibration
mismatch typed in both the axis and geometry forms.

## Migration

Implemented in this increment.

## Supersession

Widens `ADR-0090` and its `ADR-0094` revision; those records
otherwise stand.

## References

- [ADR-0126 - Geometry-bearing resampling](ADR-0126-geometry-bearing-resampling.md)
- [ADR-0090 - Layer compositing operation](ADR-0090-layer-compositing-operation.md)
