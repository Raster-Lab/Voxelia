---
document_id: "ADR-0117"
title: "Multiplanar slice coordinator"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-001"
  - "VOX-MPR-004"
  - "VOX-ERR-001"
---

# ADR-0117 - Multiplanar slice coordinator

## Context

Extraction is rank-general and the squeeze operation is registered,
so axial, coronal and sagittal slices of a regular volume compose
from accepted operations — the standard planes need no transposition,
only a one-thick slab and a singleton drop. `VoxeliaImaging`, the
backend-neutral image-processing-semantics target, was an empty
scaffold. This record opens it and was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`VoxeliaImaging` gains its first substantive API,
`MPRSliceCoordinator`:

1. **The closed plane vocabulary.** `MPRPlane` — `axial`, `coronal`,
   `sagittal` — fixes volume axis two, one or zero respectively of a
   published rank-three volume; the slice index must lie within that
   axis's extent, and an unpublished volume, a non-rank-three shape
   and an out-of-range index reject typed.
2. **Composed, published, claimed.** The coordinator runs the
   accepted extraction over the one-thick slab and the accepted
   squeeze over the fixed axis, publishing both stages under
   host-supplied per-stage naming — the coordinator mints nothing —
   so every slice carries a complete depth-three chain whose recipes
   are the explicit reproducible output geometry of `VOX-MPR-004`:
   the slab bounds and the dropped axis are frozen parameters, and
   regular-sampling origins shift through extraction under the
   registered `VOXELIA-ALG-0006` rules, using physical spacing rather
   than assuming isotropy.
3. **Orientation conventions stay future.** Radiological versus
   neurological presentation flips and geometry-bearing volumes
   compose through the transposition operation and the future
   geometry-binding remap, each through its own decision.

## Alternatives considered

A fused reslice operation was rejected: the composition of registered
operations is the model, and fusing would hide two recipes in one. A
renderer-level MPR was rejected: slab selection is image-processing
semantics, not presentation.

## Consequences

`VOX-MPR-001` is discharged for axis-aligned reconstruction over
regular volumes, `VOX-MPR-004` by recipe-explicit geometry; oblique
reconstruction remains gated on its own sampling model.

## Affected modules

`VoxeliaImaging` gains its first API; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Bounded by the composed operations' existing budgets; typed
payload-free rejections.

## Performance and memory impact

Two operation executions and two publications per slice.

## Validation impact

Tests must publish a rank-three volume and extract all three planes
with independently computed expected bytes and axis identities,
verify the published slab and slice stages with the slice's parent
edge bound to the slab record, and reject an unpublished volume, a
rank-two volume and an out-of-range index typed.

## Migration

Implemented in this increment.

## Supersession

Opens `VoxeliaImaging`; no record is superseded.

## References

- [ADR-0116 - Singleton axis squeeze](ADR-0116-singleton-axis-squeeze.md)
- [ADR-0064 - Exact region extraction operation](ADR-0064-exact-region-extraction-operation.md)
