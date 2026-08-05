---
document_id: "ADR-0175"
title: "Exact volume renderer"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-001"
  - "VOX-DVR-014"
  - "VOX-DVR-015"
  - "VOX-ERR-001"
---

# ADR-0175 - Exact volume renderer

## Context

The vocabulary, generator, sampler and compositor are live; this
record delivers the surface that composes them, per the exact-
renderer precedent. The rendered image is presentation, never a
source of authoritative quantitative measurement, per the arc's
binding rule. It was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

1. **`ExactVolumeRenderer` joins the metal module** beside the slice
   renderers as the sibling surface the design decided: constructed
   with the publisher, the coordinated read boundary and the
   software identity, and `render(_:outputObjectID:outputProvenanceID:createdAt:)`
   produces one published four-component image — per pixel, the
   accepted generator's ray, the accepted sampler's plan, the one
   public sampling authority at each midpoint, and the accepted
   compositor.
2. **The claim shape is assessed, not forced.** The presentation
   claims carry the camera, viewport, empty crop, the volume's
   claimed geometry, identity scaling, the widened `volumeDirect`
   mode and `rgba8` colour output — and an empty layer list, because
   the layer vocabulary's transfer function is the windowed slice
   claim and fabricating a window that never ran would misreport;
   the volume scene's inputs are recorded in the operation
   parameters instead.
3. **The render is a derivation.** The output's provenance is the
   operation pattern with its own tokens at 1.0.0, the volume as the
   derivation input with its parent edge, and the parameter digest
   covering the full reproduction recipe: the transfer table's bytes,
   the camera's nine components and plane height, the viewport and
   the quality token. Registry listing follows the established
   separate-increment precedent.
4. **Admission is typed**: an unpublished volume, the sampling
   authority's value domain, and a missing calibration each reject
   their own case; the generator's and sampler's own typed
   admissions propagate.

## Alternatives considered

Conforming to the slice-renderer protocol was rejected by the
design; a stage-naming closure was rejected because the volume
render publishes exactly one output, and threading the slice
pipeline's stage vocabulary through it would misname the one thing
it does.

## Consequences

Conventional direct volume rendering exists end to end as a
deterministic CPU reference with complete provenance; the gradient,
clipping, mask and acceleration increments extend this surface.

## Affected modules

`VoxeliaMetal`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One full-volume coordinated read per render; per pixel, one plan and
one pass over its consumed samples.

## Validation impact

New suite `ExactVolumeRendererTests` proves the end-to-end tiny
render byte-identical to per-ray expectations composed from the same
authorities inside the test, verifies the published claims and
provenance, and rejects the typed admissions.

## Migration

None; the surface is new.

## Supersession

Implements the surface half of accepted `ADR-0172`; no record is
superseded.

## References

- [ADR-0172 - Volume renderer design](ADR-0172-volume-renderer-design.md)
- [ADR-0174 - Volume render vocabulary](ADR-0174-volume-render-vocabulary.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing binary64-v1](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
