---
document_id: "ADR-0126"
title: "Geometry-bearing resampling"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-003"
  - "VOX-EXE-002"
  - "VOX-ERR-001"
---

# ADR-0126 - Geometry-bearing resampling

## Context

The nearest-neighbour resampling operation rejected regular sampling
and affine geometry because the rescale rules were unregistered, so a
calibrated image lost presentability the moment a viewport differed —
and physical picking, crosshair mapping and the full `VOX-MPR-003`
row stayed gated behind that rejection. This record opens the
geometry-bearing presentation arc and was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **The registered rescale rules.** `VOXELIA-ALG-0008` revision 1.1
   freezes them under the pixel-centre convention: a regular axis
   `(origin, spacing)` becomes
   `(origin + (h * spacing), scale * spacing)` with
   `h = ((0.5 * scale) - 0.5)`, and an affine geometry updates in two
   frozen passes — translations accumulate over original columns
   first, then spatial columns scale — so every resampled sample
   keeps its physical position using physical spacing rather than
   assuming isotropy or axis alignment.
2. **The widened operation.** `ResampleNearestOperation` admits
   regular sampling and affine geometry at the 1.1.0 versions under
   the established widening rule, rebuilding per-axis sampling and
   the geometry per the registered rules; irregular and categorical
   payloads have no linear rescale and stay typed rejections, and
   the bilinear operation's identical widening follows as its own
   increment so each recipe revision stands alone.

## Alternatives considered

Dropping geometry silently on resample was rejected: a calibrated
image that loses its calibration unrecorded is silent corruption.
Widening both resampling operations at once was rejected: one
operation, one recipe revision, one increment.

## Consequences

Calibrated images resample with their calibration intact;
`VOX-MPR-003` is discharged for the nearest policy, and the
geometry-bearing arc continues through the bilinear widening and the
physical-picking decisions.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Admission widening under the established version bump; geometry-free
behaviour byte-identical.

## Security impact

Unchanged budgets; typed payload-free rejections.

## Performance and memory impact

Constant-time descriptor and matrix rebuilds per execution.

## Validation impact

Tests must reproduce both rescale fixtures through the full operation
— the regular origin and spacing, and the exact affine matrix with
its unscaled third column — prove geometry-free outputs byte-identical
to the accepted fixtures at the widened version, verify the
coordinate space preserved, and keep irregular payloads rejected
typed.

## Migration

Implemented in this increment.

## Supersession

Revises the `VOXELIA-ALG-0008` model to 1.1 and widens `ADR-0088`;
those records otherwise stand.

## References

- [VOXELIA-ALG-0008 - Nearest-neighbour resampling binary64-v1](../../algorithms/VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
- [VOXELIA-ALG-0006 - Region origin shift](../../algorithms/VOXELIA-ALG-0006-region-origin-shift.md)
