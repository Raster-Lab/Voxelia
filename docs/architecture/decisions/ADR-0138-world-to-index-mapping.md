---
document_id: "ADR-0138"
title: "World-to-index mapping"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SPA-004"
  - "VOX-MPR-005"
  - "VOX-INT-006"
---

# ADR-0138 - World-to-index mapping

## Context

Accepted `ADR-0137` delivered the measured `affine-inverse/binary64-v1`
model; `VOXELIA-ALG-0016` leaves the composition with a world offset as
"the consuming operation's own frozen step". The multiplanar
coordinator's crosshair mapping is still axis-value-only behind its
regular-sampling guard, so obliquely oriented volumes have no crosshair
path. This record freezes the composition and gives it its consumers.
It was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **The composition is frozen once, in `VoxeliaSpatial`.**
   `AffineWorldToIndexMap` is built from a validated
   `AffineGridGeometry` and holds the `AffineSpatialInverse` beside the
   translation, spatial-axis mapping and coordinate space. The frozen
   step: three correctly rounded subtractions
   `d[c] = world[c] - translation[c]`, then per matrix slot
   `((inverse[3r] * d0) + (inverse[3r+1] * d1)) + (inverse[3r+2] * d2)`
   — ascending products, left-to-right accumulation, no fused
   multiply-add — mirroring the forward evaluation the pick resolver
   already claims. Slot values map to image axes through the geometry's
   own axis mapping.
2. **Admission is typed, never coerced.** A point in a different
   coordinate space rejects `coordinateSpaceMismatch` — mapping across
   spaces silently would fabricate a calibration. An image axis the
   geometry does not spatially map rejects `axisNotSpatiallyMapped`.
   The singular-determinant admission is inherited from the inverse and
   is unreachable for a validated geometry, whose own admission
   computes the identical frozen determinant.
3. **The multiplanar coordinator consumes it.** `sliceIndex(forWorldPoint:plane:volumeID:publisher:)`
   maps a world crosshair point through the published volume's claimed
   affine geometry and rounds the plane's fixed-axis component under
   the accepted `ADR-0130` ties-to-even rule; only the fixed-axis
   component gates admission because the other components do not select
   the slice. An uncalibrated volume rejects the new typed
   `volumeNotSpatiallyCalibrated` — presenting a slice for a world
   point against a volume that claims no world mapping would fabricate
   a registration. Both slice-index guards now compare in the double
   domain before integer conversion, so absurd magnitudes reject typed
   instead of trapping; every previously admitted input maps
   unchanged.
4. **The pick-side viewport consumer follows separately.** Mapping a
   world point back to viewport pixels must invert the scaling and
   crop claims and is its own design.

## Alternatives considered

Embedding the composition in the coordinator was rejected: the design
record prohibits ad-hoc inverses and the interaction arc consumes the
same step. Validating all three components in-volume was rejected: the
crosshair contract selects one slice per plane, and rejecting a point
whose in-plane components leave the volume would misreport which
planes can still follow it.

## Consequences

Oblique affine volumes gain their crosshair mapping; the frozen
composition has one authority; the axis-value path keeps its exact
behaviour with a trap removed.

## Affected modules

`VoxeliaSpatial`, `VoxeliaImaging`.

## Compatibility impact

Additive surfaces plus one new typed error case; no admitted behaviour
changes.

## Security impact

None.

## Performance and memory impact

One inverse construction and three dot products per mapping.

## Validation impact

New suite `AffineWorldToIndexMapTests` pins the exact round-trip
fixture and the python-frozen symmetric fixture and both typed
rejections; the coordinator suite gains the oblique crosshair mapping,
the out-of-volume rejection and the uncalibrated rejection.

## Migration

None.

## Supersession

Completes the consuming step planned by accepted `ADR-0136`; no record
is superseded.

## References

- [ADR-0136 - Affine inverse design](ADR-0136-affine-inverse-design.md)
- [ADR-0137 - Affine inverse implementation](ADR-0137-affine-inverse-implementation.md)
- [VOXELIA-ALG-0016 - Affine spatial inverse binary64-v1](../../algorithms/VOXELIA-ALG-0016-affine-inverse.md)
- [ADR-0130 - Crosshair slice mapping](ADR-0130-crosshair-slice-mapping.md)
