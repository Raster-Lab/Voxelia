---
document_id: "ADR-0084"
title: "Render quality, layer and scene snapshot models"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-008"
  - "VOX-ERR-001"
---

# ADR-0084 - Render quality, layer and scene snapshot models

## Context

With cameras, viewports and the transfer function accepted, the
remaining static scene-side models are the quality description, the
layer and the scene snapshot. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **`RenderQuality`.** A closed two-case description: `interactive`
   and `full`. Accumulation and denoising are result-provenance
   states, not quality requests; version-one renderers are
   deterministic single-pass, so neither state exists yet.
2. **`RenderLayer`.** One published image reference by
   `DataObjectID` — the accepted object-identifier lifecycle makes it
   an immutable binding — with its transfer function. Opacity and
   blending arrive with multi-layer compositing as their own
   registered model.
3. **`SceneSnapshot`.** A non-empty ordered layer list under an
   inclusive 64-layer ceiling, with one camera; order is compositing
   order. Empty scenes and ceiling violations are typed rejections.
4. **No wire.** Stable coding remains with the future
   presentation-provenance projection decision.

## Alternatives considered

A quality parameter space (sample counts, level-of-detail biases) was
rejected for version one: parameters without an execution contract
would be unanchored numbers. Embedding `ImageData` in layers was
rejected: scenes reference published immutable bundles by identifier,
keeping snapshots small and the publication registry authoritative.

## Consequences

A complete static scene description exists; requests and results can
now bind it.

## Affected modules

`VoxeliaRendering` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Bounded validated values; identifiers only, no embedded pixel data;
typed payload-free rejections.

## Performance and memory impact

Snapshots are small identifier-bearing values.

## Validation impact

Tests must admit a valid single-layer scene, preserve layer order in
identity, and reject an empty scene and a 65-layer scene typed.

## Migration

Implemented in this increment.

## Supersession

This ADR completes the static scene-side models and supersedes
nothing.

## References

- [ADR-0082 - Rendering camera and viewport models](ADR-0082-rendering-camera-and-viewport.md)
- [ADR-0083 - Rendering transfer function model](ADR-0083-rendering-transfer-function.md)
- [ADR-0077 - Retention and enrichment lifecycle](ADR-0077-retention-and-enrichment-lifecycle.md)
