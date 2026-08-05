---
document_id: "ADR-0120"
title: "Angle measurement"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-014"
  - "VOX-INT-009"
  - "VOX-ERR-001"
---

# ADR-0120 - Angle measurement

## Context

`VOX-SPA-014` requires distance, angle, area and volume measurements
evaluated in the appropriate physical coordinate space; distance is
registered, and the measurement construction preserves points beside
derived results. Angle was next. This record was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

`VoxeliaInteraction` gains `AngleMeasurement` under the
`three-point-angle/binary64-v1` model of `VOXELIA-ALG-0014`:

1. **Preserved inputs, derived once.** The value preserves the exact
   ray point, vertex and second ray point — one shared coordinate
   space, mismatches typed — beside the derived radians computed once
   at construction per the `VOX-INT-009` pattern.
2. **Degenerate rays typed.** A ray of exactly zero length has no
   direction; it rejects as the new typed `degenerateAngleRay`
   before the model runs, because the model's quotient is undefined
   there and returning a fabricated angle would be false.
3. **The clamp is modelled.** Rounding can push the cosine quotient
   marginally outside the mathematical interval; the registered clamp
   makes boundary angles exact, with collinear fixtures proving both
   ends.

## Alternatives considered

Extending `MeasurementConstruction` with a mode was rejected: a
polyline and an angle have different admission rules and different
derived quantities, and one value with two shapes would blur both.
Degrees were rejected: radians are the unit of the platform's own
trigonometry, and unit presentation is the host's.

## Consequences

`VOX-SPA-014` covers distance and angle; area and volume remain
recorded future models.

## Affected modules

`VoxeliaInteraction` only; no dependency change.

## Compatibility impact

Purely additive; one new typed error case.

## Security impact

Values carry coordinates and radians only.

## Performance and memory impact

Negligible.

## Validation impact

Tests must reproduce all four `VOXELIA-ALG-0014` fixtures exactly,
prove the inputs preserved, and reject zero-length rays and mixed
spaces typed.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0111` measurement vocabulary; no record is
superseded.

## References

- [VOXELIA-ALG-0014 - Three-point angle binary64-v1](../../algorithms/VOXELIA-ALG-0014-three-point-angle.md)
- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
