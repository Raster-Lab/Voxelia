---
document_id: "ADR-0168"
title: "Ray sampling design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-002"
  - "VOX-DVR-003"
---

# ADR-0168 - Ray sampling design

## Context

The volume-rendering arc's second increment is the sampling model.
Per the plan-first discipline this record freezes it before
implementation; per the arc's binding rule, everything it feeds is
presentation, never a source of authoritative quantitative
measurement. It was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

1. **`VOXELIA-ALG-0022` composes three accepted authorities.** The
   ray maps to index space through the accepted inverse composition
   — linear, so the parameter stays world distance — the actual
   volume bounds are the accepted sampling model's pixel-centre
   support, and the intersection applies the accepted slab rule in
   index space, where an affine volume's bounds are genuinely
   axis-aligned; intersecting oblique world-space bounds directly
   would need a new model where a composition of accepted ones
   suffices.
2. **The interval derives, never fixed.** Half the minimum voxel
   spacing under the one registered quality token, with the mapping
   declared as a table that future quality tokens must extend in
   their own records — `VOX-DVR-003`'s rule made structural.
3. **Misses and inside-cameras are values.** The empty sample
   sequence and the zero-clamped entry are declared outcomes, not
   errors; typed rejection is reserved for genuine admission
   failures — an uncalibrated volume, a foreign-space ray, a
   zero-length direction.
4. **Implementation follows separately** in the rendering module,
   where the camera vocabulary lives.

## Alternatives considered

Endpoint sampling was rejected for the midpoint sequence: midpoints
weight every interval identically and avoid double-sampling shared
endpoints. A per-ray adaptive interval was deferred: adaptivity is
an acceleration concern that must prove image identity under the
arc's rule before it exists.

## Consequences

The compositing increment has its sample plan; the quality table has
its extension point.

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

Executes the second increment of accepted `ADR-0165`; no record is
superseded.

## References

- [VOXELIA-ALG-0022 - Volume ray sampling binary64-v1](../../algorithms/VOXELIA-ALG-0022-ray-sampling.md)
- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
