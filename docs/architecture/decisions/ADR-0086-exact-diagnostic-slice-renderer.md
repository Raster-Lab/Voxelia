---
document_id: "ADR-0086"
title: "Exact diagnostic slice renderer"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-008"
  - "VOX-VS1-017"
  - "VOX-VS1-019"
  - "VOX-ERR-001"
---

# ADR-0086 - Exact diagnostic slice renderer

## Context

The rendering model arc closed with the recorded assessment that an
exact axis-aligned slice presenter composing the accepted operations
is the natural first `SliceRenderer` conformer. The MTA module graph
gives `VoxeliaCPU` no edge to `VoxeliaRendering`, while `VoxeliaMetal`
explicitly owns diagnostic renderers and already depends on both
`VoxeliaRendering` and `VoxeliaExecution` — so the diagnostic renderer
belongs there by ownership, with no dependency change, even while its
version-one execution path is CPU-exact. This record was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

`VoxeliaMetal` gains `ExactSliceRenderer`, the first `SliceRenderer`
conformer:

1. **Version-one admission.** Exactly one layer — multi-layer
   compositing is its own registered model — whose image is published
   in the configured publication coordinator; the request viewport
   must equal the published image's pixel extents, because identity
   presentation is the only resampling-free mapping and resampling is
   a numeric model gated with `VOX-SPA-004`. Each violation is its
   own typed rejection.
2. **Exact composition.** The render executes the accepted
   window-level operation over the published input under the layer's
   greyscale window, publishes the output bundle through the accepted
   publication coordinator in complete mode, and returns a
   `RenderResult` whose presentation provenance carries the camera,
   viewport, transfer function and the closed version-one states. No
   new numeric model exists: every byte the renderer produces comes
   from registered, measured operations, so the result is exact by
   construction.
3. **Host-owned naming.** The renderer mints no identifiers and
   acquires no clock: a host-supplied naming closure provides the
   output object identifier, provenance identifier and instant per
   render, keeping identifier and clock authority where governance
   placed them.
4. **GPU path deferred.** The same type may later gain a GPU path
   behind the same contract; oblique and perspective presentation
   stay blocked by the `VOX-SPA-004` float-bounds gate.

## Alternatives considered

Placing the conformer in `VoxeliaCPU` was rejected: the MTA gives it
no rendering edge, and adding one for convenience would rewrite the
controlled graph. Resampling to arbitrary viewports via nearest
neighbour was rejected: even nearest neighbour is a registered model
with fixtures, not a freebie.

## Consequences

The first vertical slice runs end to end: published image in, exact
windowed presentation out, published with full provenance — every
stage an accepted, evidence-carrying contract.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Composes accepted budgeted contracts; mints nothing; typed
payload-free rejections.

## Performance and memory impact

One coordinated read, one mapping pass and one publication per
render.

## Validation impact

Tests must render a published image end to end and verify the output
bytes equal the registered window-level fixture, the result's
provenance fields, and the published depth-two graph, then reject a
two-layer scene, a viewport mismatch and an unpublished image typed.

## Migration

Implemented in this increment.

## Supersession

This ADR delivers the first renderer conformer and supersedes
nothing.

## References

- [ADR-0085 - Render request, result and renderer protocol](ADR-0085-render-request-result-and-protocol.md)
- [ADR-0067 - Result publication coordinator](ADR-0067-result-publication-coordinator.md)
- [ADR-0065 - Window-level operation](ADR-0065-window-level-operation.md)
