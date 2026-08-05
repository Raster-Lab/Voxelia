---
document_id: "ADR-0129"
title: "Physical pick resolution"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-006"
  - "VOX-SPA-014"
  - "VOX-ERR-001"
---

# ADR-0129 - Physical pick resolution

## Context

Calibration now flows through the whole CPU pipeline, so the final
presented object carries a rescaled affine whose indices are the
viewport's own — yet the presentation claim did not state it, and
picking stopped at index space. This record was authored and accepted
on 2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **The presented geometry is claimed.** `PresentationProvenance`
   gains an optional `geometry` member filled by the renderer from
   the final output's descriptor per the `ADR-0100` rule — the claim
   states what was presented, and an uncalibrated presentation
   honestly claims none.
2. **World position through the claim.** `PickResolution` gains an
   optional world position, computed exactly when the claim carries
   an affine: because the claimed geometry is the final object's, its
   indices are viewport indices, and the frozen `VOXELIA-ALG-0006`
   -style evaluation — translation plus the ascending per-slot
   products, separate multiplications and additions, no fused
   multiply-add — maps the pick target directly to a `Point3D` in the
   geometry's coordinate space. The source-index inversion is
   unchanged and independent: index identification walks the recipes,
   position reads the claim.
3. **The physical half of `VOX-INT-006` is discharged**: picking now
   identifies the rendered layers, the source data and the physical
   position for calibrated presentations, with uncalibrated
   presentations returning no position rather than a fabricated one.

## Alternatives considered

Mapping through the source object's geometry after index inversion
was rejected: the final object's rescaled geometry answers directly
and one map is one truth. Requiring geometry was rejected:
uncalibrated presentation is legitimate and claims none.

## Consequences

Calibrated picks carry exact physical positions; `VOX-INT-006` is
fully discharged.

## Affected modules

`VoxeliaRendering`, `VoxeliaMetal` and `VoxeliaInteraction`; no
dependency change.

## Compatibility impact

Pre-release optional-member additions to `PresentationProvenance` and
`PickResolution`; no released caller exists.

## Security impact

Values carry coordinates in already-claimed spaces only.

## Performance and memory impact

Negligible.

## Validation impact

Tests must resolve a calibrated pick to the independently computed
world position in the claimed space, return no position for an
uncalibrated claim, and prove the renderer fills the claim from the
presented descriptor end to end.

## Migration

Implemented in this increment.

## Supersession

Extends `ADR-0125` and the `ADR-0100` claim discipline; no record is
superseded.

## References

- [ADR-0125 - Index-space pick resolution](ADR-0125-pick-resolution.md)
- [ADR-0128 - Composite calibration passthrough](ADR-0128-composite-calibration-passthrough.md)
