---
document_id: "ADR-0173"
title: "Orthographic ray generator"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-002"
  - "VOX-ERR-001"
---

# ADR-0173 - Orthographic ray generator

## Context

Accepted `ADR-0172` froze the ray-generation model. This record
implements it; everything it feeds is presentation, never a source
of authoritative quantitative measurement, per the arc's binding
rule. It was authored and accepted on 2026-08-05 under the project
owner's recorded broadened autonomous delegation.

## Decision

1. **`OrthographicRayGenerator` joins `VoxeliaRendering`**, built
   from the accepted camera and viewport with the frozen basis
   computed once at construction, and `ray(atPixelX:pixelY:)`
   returning the accepted ray primitive in the camera's coordinate
   space — composing the accepted admission rather than a second
   vector vocabulary.
2. **Admission is typed and not duplicated**: the deferred
   perspective projection rejects `unsupportedProjection`, while the
   degenerate-basis obligations are discharged by the accepted
   camera's own admission — its no-epsilon rules already reject a
   zero view vector and an up parallel to the view direction, so the
   generator adds no duplicate case and its basis divisions are
   total for every validated camera.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

The volume renderer implementation composes generator, sampler and
compositor per pixel.

## Affected modules

`VoxeliaRendering`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One basis construction per generator; constant work per pixel ray.

## Validation impact

New suite `OrthographicRayGeneratorTests` reproduces the
specification fixture exactly — the basis up to signed zeros and
every pixel origin — proves bit-identical repetition, rejects the
projection admission, and documents the camera-side discharge of the
degenerate cases.

## Migration

None; the surface is new.

## Supersession

Implements the ray-generation half of accepted `ADR-0172`; no record
is superseded.

## References

- [ADR-0172 - Volume renderer design](ADR-0172-volume-renderer-design.md)
- [VOXELIA-ALG-0024 - Orthographic ray generation binary64-v1](../../algorithms/VOXELIA-ALG-0024-orthographic-ray-generation.md)
