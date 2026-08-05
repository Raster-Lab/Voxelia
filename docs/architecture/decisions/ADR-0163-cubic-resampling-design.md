---
document_id: "ADR-0163"
title: "Cubic resampling design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-IMG-005"
---

# ADR-0163 - Cubic resampling design

## Context

The M6 assessment queues `VOX-IMG-005` third: cubic interpolation
with documented kernel and boundary behaviour. Per the plan-first
discipline this record freezes the model before implementation. It
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **The kernel is Catmull-Rom.** `VOXELIA-ALG-0021` fixes the
   interpolating cubic with exact dyadic coefficients and a frozen
   weight-evaluation order. The B-spline kernel was rejected: it
   smooths rather than interpolates, an identity resample would not
   reproduce the input bytes, and every accepted resampler holds the
   exact-identity discipline.
2. **Boundary behaviour composes the accepted convention.** Four
   taps clamp exactly as the two-tap rule does, with the weight from
   the unclamped floor — border replication, documented by reference
   rather than invented.
3. **The output clamp is modelled, not defensive.** Catmull-Rom
   weights are negative outside the bracketing pair; the frozen
   fixtures include a real overshoot beyond the top of the domain
   and its undershoot mirror.
4. **Version one is a new rank-two operation**,
   `org.voxelia.op.resample-cubic`, mirroring the nearest and linear
   operations — each display policy is its own registered operation
   in the accepted pattern, and a revision of the linear operation
   was rejected because the kernels are different models with
   different claims, not revisions of one rule. Renderer-side policy
   selection is the consumer increment that follows the operation,
   exactly as the linear policy arrived.
5. **Implementation follows separately** as the eleventh registered
   operation, with the geometry rescale expected to adopt the shared
   `VOXELIA-ALG-0008` rules exactly as the linear operation did —
   decided at implementation against the same shared authority.

## Alternatives considered

A parameterised Catmull-Rom tension was rejected for version one: no
consumer asks for it and speculative parameters are compatibility
debt. Mitchell-Netravali was rejected with B-spline for the same
non-interpolating reason.

## Consequences

The display-policy family has its cubic model with exact fixtures;
the implementing increment is mechanical.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The obligations are recorded in the specification and bind the
implementing increment.

## Migration

None; implementation follows as its own increment.

## Supersession

Continues the M6 arc; no record is superseded.

## References

- [VOXELIA-ALG-0021 - Cubic resampling binary64-v1](../../algorithms/VOXELIA-ALG-0021-cubic-resampling.md)
- [ADR-0123 - Bilinear resampling operation](ADR-0123-bilinear-resampling.md)
