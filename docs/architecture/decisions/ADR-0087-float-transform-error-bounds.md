---
document_id: "ADR-0087"
title: "Float transform error bounds"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-004"
  - "VOX-ARC-008"
  - "VOX-ERR-001"
---

# ADR-0087 - Float transform error bounds

## Context

`VOX-SPA-004` permits rendering-specific float transforms only after
the associated error bounds are verified, and that gate has blocked
oblique and perspective presentation, resampling models and the GPU
slice path throughout the rendering arc. The bound is now derived and
verified as `camera-relative-float-transform/binary32-v1` per
`VOXELIA-ALG-0007`. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **Registered derivation.** `VoxeliaRendering` gains
   `CameraRelativeFloatTransform`: the frozen derivation — the
   camera-relative subtraction in `binary64` before one demotion
   rounding per element — with `binary32` application in frozen
   association and no fused multiply-add.
2. **Verified bound.** The value exposes the specification's per-row
   forward error bound (`γ5` times the row magnitude sum, with
   `u = 2^-24`), computed in `binary64` for any index; the bound is
   the standard inner-product forward error analysis and holds
   wherever intermediates stay within the `binary32` normal range,
   with subnormal excursions outside the verified domain by
   specification.
3. **Measured verification.** The suite is the harness: thousands of
   deterministic samples across magnitude regimes assert the bound
   for every row of every sample against the `binary64` reference,
   and report the maximum observed bound ratio as measured evidence.
   A violated bound fails the suite; the bound is never widened to
   fit an observation.
4. **Gate discharge.** With the bound derived, exposed and verified,
   the `VOX-SPA-004` gate is discharged for this registered
   derivation. Consumers — oblique and perspective presentation,
   resampling, the GPU slice path — must use this derivation and
   carry its bound; any other float transform remains gated until
   registered likewise.

## Alternatives considered

Demoting the world-space matrix before the camera subtraction was
rejected: catastrophic cancellation for large world coordinates is
exactly the failure the camera-relative form exists to avoid. Interval
arithmetic was rejected for version one as heavier machinery than the
requirement demands; the closed-form bound is standard, checkable and
sufficient.

## Consequences

The last rendering-side numeric gate for slice presentation is
discharged in registered form: oblique and perspective presentation
and resampling models can now be designed against a verified error
budget.

## Affected modules

`VoxeliaRendering` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Pure arithmetic over validated values; typed rejection of a
coordinate-space mismatch; no new failure surface.

## Performance and memory impact

Sixteen demotions per derivation; bound evaluation is a per-row
magnitude sum.

## Validation impact

The suite must verify the bound for every row of thousands of
deterministic samples across magnitude regimes including
large-coordinate cameras, prove bit-identical repeated derivation,
demonstrate the cancellation advantage of the camera-relative order,
and report the maximum observed bound ratio.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `VOX-SPA-004` gate for the registered
derivation and supersedes nothing.

## References

- [VOXELIA-ALG-0007 - Camera-relative float transform derivation binary32-v1](../../algorithms/VOXELIA-ALG-0007-camera-relative-float-transform.md)
- [ADR-0082 - Rendering camera and viewport models](ADR-0082-rendering-camera-and-viewport.md)
