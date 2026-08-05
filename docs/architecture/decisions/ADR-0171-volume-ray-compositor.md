---
document_id: "ADR-0171"
title: "Volume ray compositor"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-001"
  - "VOX-DVR-004"
  - "VOX-DVR-007"
---

# ADR-0171 - Volume ray compositor

## Context

Accepted `ADR-0170` froze the compositing model. This record
implements it; everything it produces is presentation, never a
source of authoritative quantitative measurement, per the arc's
binding rule. It was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

1. **`VolumeRayCompositor` joins `VoxeliaRendering`** as the pure
   frozen function over one ray's sample bytes and the accepted
   transfer table: the declared conversions, the frozen accumulation
   order, the exact dyadic termination threshold, and the declared
   empty-ray zero.
2. **The result is a value carrying the consumed count.**
   `CompositedRay` holds the four output bytes and the consumed
   sample count — part of the frozen behaviour the fixtures pin, and
   the early-termination evidence the acceleration increment will
   later compare against.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

The renderer record has its per-ray engine; the gradient, clipping
and acceleration increments compose it.

## Affected modules

`VoxeliaRendering`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One pass over consumed samples; no allocation.

## Validation impact

New suite `VolumeRayCompositorTests` reproduces every specification
fixture exactly including consumed counts, proves the exact
threshold boundary stops the ray, and proves bit-identical
repetition.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0170`; no record is superseded.

## References

- [ADR-0170 - Compositing design](ADR-0170-compositing-design.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing binary64-v1](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
