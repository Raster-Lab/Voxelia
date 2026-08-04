---
document_id: "ADR-0091"
title: "Multi-layer scene presentation"
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

# ADR-0091 - Multi-layer scene presentation

## Context

The scene model admits up to 64 ordered layers and `ADR-0090`
registered the blending model, but `RenderLayer` carried no opacity
and the renderer admitted one layer only. `ADR-0084` recorded that
opacity arrives with the registered compositing model; that model now
exists. This record was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

1. **Layer opacity.** `RenderLayer` gains a validated `opacity` — one
   finite binary64 value in `[0, 1]` checked at construction with the
   new typed `RenderModelError.invalidLayerOpacity` — discharging the
   `ADR-0084` deferral; layer order remains compositing order.
2. **Honest per-layer presentation claims.** `PresentationProvenance`
   replaces its single `transferFunction` with the ordered presented
   layers, because a multi-layer result claiming one transfer
   function would be a false record; each layer claim carries the
   object identifier, transfer function and opacity. This is a
   pre-release revision of the `ADR-0085` shape; no released caller
   exists.
3. **Renderer composition.** `ExactSliceRenderer` window-levels every
   layer in scene order and publishes each stage, composites through
   the `ADR-0090` operation when more than one layer is declared and
   publishes the blend, then resamples per `ADR-0089` when the
   viewport differs. A single-layer scene requires opacity one and
   keeps its accepted single-publication shape — a single-layer fade
   would widen the compositing admission to one layer, its own
   versioned decision — rejected typed as the new
   `SliceRendererError.unsupportedLayerOpacity`.
4. **Per-layer stage naming.** `RenderPublicationStage` widens to
   `windowLevelled(layerIndex:)`, `composited` and `resampled`, a
   pre-release revision of the `ADR-0089` contract, so the host names
   every published stage distinctly and the renderer still mints
   nothing.

## Alternatives considered

Blending in the renderer without the registered operation was
rejected: silent history. Keeping the single transfer-function claim
was rejected: it would misrepresent every multi-layer render.
Admitting single-layer fades by widening the operation here was
rejected: admission widenings are versioned operation decisions.

## Consequences

Multi-layer scenes render end to end with every derived stage
published and per-layer presentation claims; the scene ceiling of 64
now matches the compositing admission ceiling.

## Affected modules

`VoxeliaRendering` and `VoxeliaMetal`; no dependency change.

## Compatibility impact

Pre-release signature revisions of `RenderLayer`,
`PresentationProvenance` and `RenderPublicationStage`; no released
caller exists.

## Security impact

Unchanged budgets; bounded stage publications per render — at most
layers plus two.

## Performance and memory impact

One window-level execution and publication per layer, plus one
composite and one resample when applicable.

## Validation impact

Tests must render a two-layer scene end to end reproducing the
registered `VOXELIA-ALG-0009` fixture with every stage published and
the composite record carrying both parent edges, keep the equal-extent
single-layer render unchanged, and reject an out-of-range layer
opacity at construction and a single-layer scene with reduced opacity
typed.

## Migration

Implemented in this increment.

## Supersession

Revises the `ADR-0084` layer shape, the `ADR-0085` presentation
claims and the `ADR-0089` naming contract; those records otherwise
stand.

## References

- [ADR-0090 - Layer compositing operation](ADR-0090-layer-compositing-operation.md)
- [ADR-0089 - Renderer viewport resampling composition](ADR-0089-renderer-viewport-resampling.md)
- [ADR-0084 - Render quality, layer and scene models](ADR-0084-render-quality-layer-and-scene.md)
