---
document_id: "ADR-0119"
title: "Viewport synchronisation group"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-005"
  - "VOX-MPR-005"
  - "VOX-ERR-001"
---

# ADR-0119 - Viewport synchronisation group

## Context

`VOX-INT-005` requires viewport synchronisation to validate
frame-of-reference compatibility and `VOX-MPR-005` requires linked
orthogonal views with a shared patient-space crosshair. The crosshair
state exists; nothing linked viewports or validated their shared
frame. This record was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

`VoxeliaInteraction` gains the synchronisation vocabulary:

1. **Plane-agnostic members.** A `SyncedViewport` binds one host-owned
   integer identifier to one coordinate space; the plane vocabulary
   lives in `VoxeliaImaging`, which `VoxeliaInteraction` does not
   depend on, and the linkage rule needs only the frame — keeping the
   member plane-agnostic keeps the dependency direction intact and
   the model general beyond orthogonal triples.
2. **One frame, validated everywhere.** `ViewportSyncGroup` takes a
   non-empty member list bounded at sixteen with unique identifiers,
   plus the shared `CrosshairState`; every member's coordinate space
   and the crosshair's space must be one space, with mismatches the
   typed `coordinateSpaceMismatch` — frame-of-reference compatibility
   is construction, not convention. Moving the crosshair yields a new
   group and revalidates the space, so a crosshair can never drift
   into a foreign frame.
3. **Index mapping stays future.** Mapping the shared crosshair to
   per-plane slice indices needs geometry-bearing volumes and the
   geometry-binding remap; the linkage half of `VOX-MPR-005` is
   discharged here and the mapping half is recorded open with that
   dependency.

## Alternatives considered

Carrying the plane in the member was rejected: it would invert the
package dependency or duplicate the vocabulary. Identity-token
members were rejected: a synchronisation group is a value snapshot,
and host-owned integer tags with in-group uniqueness keep it one.

## Consequences

`VOX-INT-005` is discharged; linked orthogonal views validate their
shared frame at construction and on every crosshair move.

## Affected modules

`VoxeliaInteraction` only; no dependency change.

## Compatibility impact

Purely additive; three new typed error cases.

## Security impact

Values carry tags, spaces and coordinates only.

## Performance and memory impact

Negligible.

## Validation impact

Tests must construct a three-member group over one space, move the
crosshair with revalidation proven, and reject an empty group, an
over-bound group, duplicate identifiers, a foreign-space member and a
foreign-space crosshair move, all typed.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0111` interaction vocabulary; no record is
superseded.

## References

- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
- [ADR-0117 - Multiplanar slice coordinator](ADR-0117-mpr-slice-coordinator.md)
