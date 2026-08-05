---
document_id: "ADR-0140"
title: "Crosshair broadcast"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-INT-005"
  - "VOX-INT-006"
  - "VOX-MPR-005"
---

# ADR-0140 - Crosshair broadcast

## Context

Accepted `ADR-0138` and `ADR-0139` gave world points their slice and
pixel mappings; the synchronisation group of `ADR-0119` still carries
its shared crosshair as a bare position. Following one crosshair
across linked viewports means resolving that position against every
member's presentation claim in one step, with outcomes that stay
honest per member. It was authored and accepted on 2026-08-05 under
the project owner's recorded broadened autonomous delegation.

## Decision

1. **The group broadcasts through the accepted mappings.**
   `crosshairTargets(presentations:)` resolves the group's crosshair
   against one claim per member identifier via the `ADR-0139`
   reverse mapping and returns per-member resolutions in member
   order. The group stays a vocabulary value: presentations are
   supplied at the call, not stored, because claims change per frame
   while membership does not.
2. **Per-member outcomes are states, not failures.** A member whose
   view the crosshair left reports `outsideViewport` and an
   uncalibrated member reports `notCalibrated` — both are normal view
   states a host renders (a hidden crosshair, an unsynced pane),
   never a fabricated nearest pixel. The `ADR-0139` typed cases carry
   the distinction and the broadcast folds them into outcomes.
3. **Association errors throw.** A presentation set whose identifiers
   do not exactly cover the members rejects the new typed
   `presentationMembershipMismatch`, and a member claim whose
   geometry lives in a foreign space or does not map both presented
   axes propagates its own typed error — those are caller mistakes in
   associating claims with members, not view states.

## Alternatives considered

Storing presentations on the members was rejected: claims are
per-frame render products while the group is a stable linkage value,
and coupling them would force group reconstruction every frame.
Returning a dictionary was rejected: member order is the group's
declared order and the host renders panes in it.

## Consequences

One call turns a crosshair move into every linked pane's honest
outcome; the interaction vocabulary gains one error case and two
small result types.

## Affected modules

`VoxeliaInteraction`.

## Compatibility impact

Additive: one method, two types, one error case.

## Security impact

None.

## Performance and memory impact

One reverse mapping per member; no allocation beyond the resolution
array.

## Validation impact

The group suite gains the mixed-outcome broadcast over the claimed
forward fixture and both association rejections.

## Migration

None.

## Supersession

Extends `ADR-0119` with the consuming step of `ADR-0138` and
`ADR-0139`; no record is superseded.

## References

- [ADR-0119 - Viewport synchronisation](ADR-0119-viewport-synchronisation.md)
- [ADR-0139 - World-to-viewport mapping](ADR-0139-world-to-viewport-mapping.md)
- [ADR-0138 - World-to-index mapping](ADR-0138-world-to-index-mapping.md)
