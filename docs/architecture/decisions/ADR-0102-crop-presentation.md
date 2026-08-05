---
document_id: "ADR-0102"
title: "Crop presentation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-008"
  - "VOX-VS1-017"
  - "VOX-ERR-001"
---

# ADR-0102 - Crop presentation

## Context

The region-extraction operation has been accepted since `ADR-0064`
and lifted through `ADR-0074`, but the renderer could not present a
sub-region: every render consumed full images, and `ADR-0085`
recorded clipping and cropping as awaiting their own model. This
record was authored and accepted on 2026-08-05 under the project
owner's recorded broadened autonomous delegation.

## Decision

1. **A validated crop request.** `VoxeliaRendering` gains
   `RenderCrop` — one half-open rank-two region in image index space,
   validated non-negative and non-empty at construction with the new
   typed `RenderModelError.invalidCropBounds` — and `RenderRequest`
   carries an optional one, a pre-release revision of the `ADR-0085`
   shape with no permissive default: callers state absence
   explicitly. Bounds beyond an image's extents surface as the
   extraction operation's own typed region rejection.
2. **Crop is the first stage.** When a crop is requested the renderer
   runs the accepted region-extraction operation over every layer's
   stored image before window-level — extraction is the stored-domain
   model and its geometry and sampling rules are already registered —
   publishing each cropped stage under the new
   `cropped(layerIndex:)` publication stage.
3. **The presentation claims it.** `PresentationProvenance` gains an
   optional `crop` member filled from what actually ran — the
   `ADR-0100` rule — so a consumer reads the presented sub-region
   honestly from the result.

## Alternatives considered

Cropping after window-level was rejected: extraction is a
stored-domain operation and its registered geometry and sampling
arithmetic bind to stored indices. Per-layer crops were rejected in
version one: one scene, one presented region; per-layer regions are
their own decision. A silent viewport-derived crop was rejected: the
crop is the host's explicit request, never an inference.

## Consequences

All four accepted operations are now reachable through the renderer,
each stage published and claimed.

## Affected modules

`VoxeliaRendering` and `VoxeliaMetal`; no dependency change.

## Compatibility impact

Pre-release revisions of `RenderRequest`, `PresentationProvenance`
and `RenderPublicationStage`; no released caller exists.

## Security impact

Bounded by the extraction operation's existing admission and budgets.

## Performance and memory impact

One extraction execution and publication per layer of a cropped
render.

## Validation impact

Tests must render a cropped single-layer scene end to end with the
cropped stage published and the exact windowed sub-region bytes,
verify the crop and identity-scaling claims on the result, reject
invalid crop bounds typed at construction, and keep uncropped renders
claiming an absent crop.

## Migration

Implemented in this increment.

## Supersession

Discharges the `ADR-0085` cropping deferral; `ADR-0085` otherwise
stands.

## References

- [ADR-0064 - Exact region extraction operation](ADR-0064-exact-region-extraction-operation.md)
- [ADR-0100 - Presentation scaling claim](ADR-0100-presentation-scaling-claim.md)
