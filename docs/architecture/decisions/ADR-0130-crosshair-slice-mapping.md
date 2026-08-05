---
document_id: "ADR-0130"
title: "Crosshair slice mapping"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-005"
  - "VOX-ERR-001"
---

# ADR-0130 - Crosshair slice mapping

## Context

Linked orthogonal views share a validated crosshair, but nothing
mapped a crosshair component to the slice index a plane should
present, leaving the second half of `VOX-MPR-005` open. This record
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

`MPRSliceCoordinator` gains `sliceIndex`, mapping one axis-domain
crosshair component to the plane's slice index:

1. **The frozen regular-sampling rule.** The plane's fixed axis must
   carry regular sampling — any other kind is the new typed
   `unsupportedAxisSampling` — and the index is the frozen binary64
   sequence `difference = value - origin`,
   `quotient = difference / spacing`, then ties-to-even rounding to
   an integer, each operation correctly rounded; an index outside the
   axis extent is the new typed `crosshairOutsideVolume`, never a
   clamp, because presenting a nearest slice for a crosshair that
   left the volume would misreport where the views point.
2. **Axis-domain input, honestly scoped.** The component is the value
   in the fixed axis's own sampled coordinate domain; mapping an
   arbitrary world point onto an obliquely oriented volume requires
   the affine inverse, which is its own future frozen model —
   recorded here as the arc's remaining opening — while axis-aligned
   calibrated volumes, whose axis domains are the world components,
   are served exactly today.

## Alternatives considered

Clamping out-of-volume crosshairs was rejected as misreporting. An
approximate affine inverse was rejected: matrix inversion deserves
its own registered model with its own error analysis, not an
incidental appearance here.

## Consequences

`VOX-MPR-005` is complete for axis-aligned volumes: linked views
share a validated crosshair and each plane maps it to its slice
exactly; the affine-inverse mapping is the recorded remaining
opening.

## Affected modules

`VoxeliaImaging` only; no dependency change.

## Compatibility impact

Purely additive; two new typed error cases.

## Security impact

Values carry indices and coordinates only.

## Performance and memory impact

Negligible.

## Validation impact

Tests must map crosshair components through a regular fixed axis with
exact indices including a ties-to-even case, and reject non-regular
sampling, out-of-volume components, an unpublished volume and a
rank-two volume typed.

## Migration

Implemented in this increment.

## Supersession

Completes `ADR-0119`'s linkage with the mapping half of
`VOX-MPR-005`; no record is superseded.

## References

- [ADR-0117 - Multiplanar slice coordinator](ADR-0117-mpr-slice-coordinator.md)
- [ADR-0119 - Viewport synchronisation group](ADR-0119-viewport-synchronisation.md)
