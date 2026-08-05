---
document_id: "ADR-0169"
title: "Volume ray sampler"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-002"
  - "VOX-DVR-003"
  - "VOX-ERR-001"
---

# ADR-0169 - Volume ray sampler

## Context

Accepted `ADR-0168` froze the ray-sampling model. This record
implements it; everything it feeds is presentation, never a source
of authoritative quantitative measurement, per the arc's binding
rule. It was authored and accepted on 2026-08-05 under the project
owner's recorded broadened autonomous delegation.

## Decision

1. **`VolumeRaySampler` joins `VoxeliaRendering`**, built from a
   validated geometry, the volume extents and the quality token —
   the declared table's one registered entry, with an unknown token
   typed so future tokens extend the table in their own records. The
   sampler derives the interval once from the minimum column norm.
2. **The plan is a value.** `VolumeRaySamplePlan` carries the entry
   and exit distances, the interval, the sample count and the
   index-space ray, with the frozen midpoint distance and position
   evaluations as methods; the miss is the empty plan, a declared
   outcome.
3. **The slab rule is restated with its authority recorded.** The
   accepted spatial intersection speaks the world-space point
   vocabulary, and labelling index coordinates with the volume's
   world space token would misreport them — so the sampler restates
   the `VOXELIA-ALG-0001` slab rule over the index-space support,
   with the accepted specification the authority for the rule. The
   zero-length direction obligation is discharged by the composed
   `Ray3D` primitive's own typed admission — the sampler adds no
   duplicate case.

## Alternatives considered

Recorded in the design; the reuse-versus-restate choice fell to
restatement for the type-honesty reason above, which the design
anticipated.

## Consequences

The compositing increment consumes sample plans; the quality table
is live with its extension point.

## Affected modules

`VoxeliaRendering`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One inverse construction per sampler; constant work per ray plan.

## Validation impact

New suite `VolumeRaySamplerTests` reproduces all four specification
fixtures exactly, proves bit-identical repetition, and rejects the
typed admissions — extents, mapping, quality token and the
foreign-space ray through the composed map's own case.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0168`; no record is superseded.

## References

- [ADR-0168 - Ray sampling design](ADR-0168-ray-sampling-design.md)
- [VOXELIA-ALG-0022 - Volume ray sampling binary64-v1](../../algorithms/VOXELIA-ALG-0022-ray-sampling.md)
