---
document_id: "ADR-0100"
title: "Presentation scaling claim"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-008"
  - "VOX-VS1-019"
  - "VOX-ERR-001"
---

# ADR-0100 - Presentation scaling claim

## Context

`ADR-0089` made the renderer resample to differing viewports, but the
presentation provenance did not say so: a consumer reading a
`RenderResult` could not tell an identity presentation from a
resampled one without walking the published graph. `ADR-0085`
deferred the presentation transform behind the float-bounds gate; the
gate is discharged and the pipeline's actual scaling behaviour is now
claimable honestly. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **A closed scaling claim.** `VoxeliaRendering` gains the closed
   `PresentationScaling` — `identity`, or
   `nearestNeighbour(sourceWidth:sourceHeight:)` per the registered
   `VOXELIA-ALG-0008` model — and `PresentationProvenance` carries
   one as a required member, a pre-release revision of the
   `ADR-0085`/`ADR-0091` shape. The payload extents come from the
   presented image's validated descriptor, so the claim needs no
   independent validation surface.
2. **The renderer records what happened.** The pipeline fills the
   claim from its actual behaviour — `identity` when the viewport
   equals the presented extents and the resample stage never ran,
   `nearestNeighbour` with the pre-resample source extents otherwise
   — never from the request, because presentation provenance claims
   what was done, not what was asked.
3. **Full geometric transforms stay deferred.** Oblique and
   perspective presentation remain pending their own models; this
   claim covers exactly the axis-aligned scaling the pipeline
   performs today, and richer cases will widen the closed set through
   their own decisions.

## Alternatives considered

Claiming a general presentation transform matrix was rejected: the
pipeline performs axis-aligned nearest-neighbour scaling only, and a
matrix would imply a model that does not exist. Deriving the claim
from viewport-versus-request comparison by consumers was rejected:
provenance is the producer's honest record, not the reader's
inference.

## Consequences

Every render result now states its scaling honestly in the closed
presentation vocabulary; graph inspection is corroboration, not the
only source.

## Affected modules

`VoxeliaRendering` and `VoxeliaMetal`; no dependency change.

## Compatibility impact

Pre-release member addition to `PresentationProvenance`; no released
caller exists.

## Security impact

None beyond existing disciplines.

## Performance and memory impact

Negligible.

## Validation impact

Tests must verify an equal-extent render claims `identity`, a
resampled render claims `nearestNeighbour` with the exact
pre-resample source extents, and the claim participates in
presentation identity.

## Migration

Implemented in this increment.

## Supersession

Discharges the `ADR-0085` presentation-transform deferral for the
axis-aligned scaling case; `ADR-0085` otherwise stands.

## References

- [ADR-0089 - Renderer viewport resampling composition](ADR-0089-renderer-viewport-resampling.md)
- [ADR-0085 - Render request, result and protocol](ADR-0085-render-request-result-and-protocol.md)
