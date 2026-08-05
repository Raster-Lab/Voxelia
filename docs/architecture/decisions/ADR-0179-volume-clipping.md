---
document_id: "ADR-0179"
title: "Volume clipping"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-009"
  - "VOX-ERR-001"
---

# ADR-0179 - Volume clipping

## Context

Accepted `ADR-0178` froze the clipping design. This record
implements it; everything clipped is presentation, never a source of
authoritative quantitative measurement, per the arc's binding rule.
It was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **`VolumeClipBounds` joins `VoxeliaRendering`** mirroring the
   accepted clip box's admission exactly — one coordinate space and
   strictly ordered bounds on every axis — with the render-model
   error gaining the `invalidClipBounds` case; the design record
   binds the mirror never to drift.
2. **The sampler carries the restrictions.** Its construction gains
   the explicit optional clip and crop: the clip's coordinate space
   is checked against the volume's, typed; the crop must be a
   rank-three region within the volume's extents, typed; the crop
   tightens the pixel-centre support and the clip contributes three
   world slabs in the declared order, with the absent case leaving
   the accepted path untouched so unclipped byte identity is
   structural.
3. **The request carries both, digested.** The volume request gains
   the explicit optional clip and crop with absence stated at every
   call site, and the parameter collection gains the clip corners
   and crop bounds exactly when declared — the padding-entry
   precedent, so undeclared documents and digests are unchanged.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

Rays sample only where the host asked; the mask record and the
acceleration increment remain.

## Affected modules

`VoxeliaRendering`, `VoxeliaMetal`.

## Compatibility impact

The request and sampler signatures gain the explicit optionals; call
sites state absence.

## Security impact

None.

## Performance and memory impact

Three additional slab evaluations per clipped ray; none when absent.

## Validation impact

The suites reproduce every design fixture exactly — the clipped
interval, the behind and parallel-outside empties, the tightened
crop and the all-containing identity — prove the unclipped request
unchanged through the untouched path, prove bit-identical
repetition, and reject the foreign-space clip and out-of-volume crop
typed.

## Migration

Call sites add the explicit absent clip and crop.

## Supersession

Implements accepted `ADR-0178`; no record is superseded.

## References

- [ADR-0178 - Volume clipping design](ADR-0178-volume-clipping-design.md)
