---
document_id: "ADR-0124"
title: "Display policy selection"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-013"
  - "VOX-VS1-019"
  - "VOX-ERR-001"
---

# ADR-0124 - Display policy selection

## Context

All three `VOX-R2D-013` interpolation policies have registered
semantics, but the renderer always resampled nearest-neighbour: the
host could not select the linear policy and the presentation claim
could not state it. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **An explicit request policy.** `RenderRequest` gains the closed
   `InterpolationPolicy` — `nearestNeighbour` or `linear` — with no
   permissive default: the host states its policy, and the
   no-interpolation case is the existing identity presentation when
   the viewport equals the presented extents, where no policy runs
   and none is claimed.
2. **The stage dispatches, the claim follows.** The renderer's
   resample stage runs the registered operation the policy names,
   and `PresentationScaling` widens with the
   `bilinear(sourceWidth:sourceHeight:)` case so the claim states
   what ran per the `ADR-0100` rule — the policy is honoured by the
   operation identity in the published recipe and stated in the
   presentation claim, never inferred.
3. **The device path is unchanged.** Both resample operations are
   exact CPU models; no device approximation exists to claim.

## Alternatives considered

Defaulting to nearest was rejected: a silent default policy is a
convention, and the row asks for explicit policies. Widening the
scaling claim with a policy field instead of a case was rejected: the
closed case set is the claim vocabulary's accepted shape.

## Consequences

`VOX-R2D-013` is complete: three explicit policies, each registered,
each selectable, each claimed.

## Affected modules

`VoxeliaRendering` and `VoxeliaMetal`; no dependency change.

## Compatibility impact

Pre-release explicit-member addition to `RenderRequest` and one
scaling case; no released caller exists.

## Security impact

Unchanged budgets and disciplines.

## Performance and memory impact

Policy dispatch only.

## Validation impact

Tests must render one scene under both policies to a differing
viewport, prove the nearest output unchanged from the accepted
fixtures and the linear output equal to the independently computed
bilinear fixture, verify each claim states its policy case with the
pre-resample extents, and keep equal-extent renders claiming
identity under either policy.

## Migration

Implemented in this increment.

## Supersession

Completes `VOX-R2D-013` over `ADR-0123`; no record is superseded.

## References

- [ADR-0123 - Bilinear resampling operation](ADR-0123-bilinear-resampling.md)
- [ADR-0100 - Presentation scaling claim](ADR-0100-presentation-scaling-claim.md)
