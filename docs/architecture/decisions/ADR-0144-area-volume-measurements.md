---
document_id: "ADR-0144"
title: "Area and volume measurements"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SPA-014"
  - "VOX-INT-009"
  - "VOX-ERR-001"
---

# ADR-0144 - Area and volume measurements

## Context

Accepted `ADR-0143` froze the planar polygon area and calibrated
voxel volume models with python-verified fixtures. This record
implements both as interaction measurement values beside the
accepted constructions. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **`PolygonAreaMeasurement` preserves its ordered vertices** in one
   shared coordinate space beside the derived vector-area magnitude,
   computed once at construction under the frozen
   `VOXELIA-ALG-0018` anchored-fan sequence — the `VOX-INT-009`
   discipline the existing measurements follow. Fewer than three
   vertices reject the new typed `insufficientVertices`; the
   existing mixed-space case is reused because its meaning fits
   exactly.
2. **`VoxelVolumeMeasurement` preserves its calibration and count**
   beside the derived volume: the validated geometry is stored
   whole, the count is typed nonnegative and bounded at `2^53` so
   its binary64 conversion is exact — the new
   `invalidVoxelCount` case — and the cell volume is read from the
   accepted determinant authority, never re-derived.
3. **Both values compute once and are bit-identical on repetition**;
   neither claims a float bound, per the accepted designs.

## Alternatives considered

Reusing `emptyMeasurement` for the vertex-count admission was
rejected: a two-vertex cycle is not empty, and one case for both
would misreport which rule fired. Storing only the determinant
instead of the geometry was rejected: the preserved input is the
calibration itself, and the derived value alone would break the
preserved-inputs discipline.

## Consequences

`VOX-SPA-014` is discharged at the model level across all four
measures; the interaction vocabulary gains two values and two error
cases.

## Affected modules

`VoxeliaInteraction`.

## Compatibility impact

Additive: two types and two error cases.

## Security impact

None.

## Performance and memory impact

One pass over the vertices per area construction; one inverse
construction per volume measurement.

## Validation impact

The command suite gains all ten frozen fixtures, bit-identical
repetition and the four typed rejections.

## Migration

None.

## Supersession

Implements accepted `ADR-0143`; no record is superseded.

## References

- [ADR-0143 - Area and volume measurement design](ADR-0143-area-volume-measurement-design.md)
- [VOXELIA-ALG-0018 - Planar polygon area binary64-v1](../../algorithms/VOXELIA-ALG-0018-planar-polygon-area.md)
- [VOXELIA-ALG-0019 - Calibrated voxel volume binary64-v1](../../algorithms/VOXELIA-ALG-0019-voxel-volume.md)
