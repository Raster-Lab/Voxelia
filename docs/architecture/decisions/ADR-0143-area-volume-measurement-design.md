---
document_id: "ADR-0143"
title: "Area and volume measurement design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-014"
  - "VOX-INT-009"
---

# ADR-0143 - Area and volume measurement design

## Context

`VOX-SPA-014` requires distance, angle, area and volume measurement
in the appropriate physical coordinate space. Distance and angle are
accepted and implemented; the M4 sweep records area and volume as
the remainder. Per the plan-first discipline this record freezes
both models on paper before implementation. It was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

1. **Area is the anchored vector-area magnitude.**
   `VOXELIA-ALG-0018` freezes the first-vertex-anchored fan of cross
   products with the accepted norm form. The measured quantity is
   declared — exactly the enclosed area for planar simple polygons,
   the algebraic vector-area magnitude otherwise — because an
   epsilon planarity test would be an arbitrary threshold and the
   declared quantity is well defined for every admitted input. A
   degenerate cycle measures exactly zero rather than erroring.
2. **Volume is a counted-cell measure against the claimed
   calibration.** `VOXELIA-ALG-0019` multiplies a supplied voxel
   count by the exact cell volume — the magnitude of the accepted
   `VOXELIA-ALG-0016` determinant, the one determinant authority,
   never re-derived. Version one deliberately measures counts, not
   shapes: the authority that produces a count (segmentation,
   thresholding, host selection) is its own future arc, and
   inventing one here would smuggle an undesigned model in through a
   measurement.
3. **No float bound is claimed by either model**, per the
   `VOXELIA-ALG-0010` precedent: the frozen sequences are the
   definitions, fixtures are exact or exactly spelled, and both
   admissions are the receivers' typed surfaces.
4. **Implementation follows separately** in the interaction module
   beside the accepted measurement constructions, as its own
   increment.

## Alternatives considered

Mesh- or contour-integral volume was rejected for version one: no
accepted authority produces meshes or contours yet. Rejecting
non-planar vertex cycles was rejected: planarity cannot be tested
without an epsilon, and declaring the measured quantity is honest
where thresholding is arbitrary.

## Consequences

Both remaining `VOX-SPA-014` measures have frozen, fixture-backed
models; the implementing increment is mechanical.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The obligations are recorded in both specifications and bind the
implementing increment.

## Migration

None; implementation follows as its own increment.

## Supersession

Extends the measurement vocabulary of `ADR-0111` and `ADR-0120`; no
record is superseded.

## References

- [VOXELIA-ALG-0018 - Planar polygon area binary64-v1](../../algorithms/VOXELIA-ALG-0018-planar-polygon-area.md)
- [VOXELIA-ALG-0019 - Calibrated voxel volume binary64-v1](../../algorithms/VOXELIA-ALG-0019-voxel-volume.md)
- [ADR-0120 - Angle measurement](ADR-0120-angle-measurement.md)
