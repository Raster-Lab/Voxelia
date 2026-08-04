---
document_id: "ADR-0085"
title: "Render request, result and renderer protocol"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-008"
  - "VOX-SPA-004"
  - "VOX-ERR-001"
---

# ADR-0085 - Render request, result and renderer protocol

## Context

The static scene-side models are accepted; the arc closes with the
request, the claim-bearing result carrying the CDMS section 12.4
presentation provenance, and the backend-neutral renderer protocol.
Section 12.4 lists ten presentation fields; several depend on gated or
nonexistent contracts and must not be faked. This record was authored
and accepted on 2026-08-05 under the project owner's recorded
broadened autonomous delegation.

## Decision

1. **`RenderRequest`.** One scene snapshot, one viewport size and one
   quality description — already-validated members composed
   memberwise.
2. **Closed presentation states.** Version one registers exactly one
   case each: render mode `slice`, colour output `greyscale8`,
   accumulation `none` and denoising `none` — deterministic
   single-pass greyscale slice presentation, which is precisely what
   the accepted operations can produce. Every widening is a
   registered extension.
3. **Honest section 12.4 subset.** `PresentationProvenance` carries
   camera, viewport size, transfer function, render mode, colour
   output, accumulation state and denoising state. The presentation
   transform is deferred: deriving it is exactly the
   rendering-specific float transform that `VOX-SPA-004` admits only
   after verified error bounds, which remain a recorded gate.
   Clipping and cropping are deferred with their own model, and the
   random seed field arrives with the first stochastic mode — a
   deterministic pipeline recording a seed would be a false claim.
4. **`RenderResult`.** The claim-bearing outcome: the published
   output object identifier plus its presentation provenance.
   Construction proves structural validity only; publication and
   graph coherence stay with the accepted publication coordinator.
5. **`SliceRenderer` protocol.** One backend-neutral requirement:
   render a request into a result, asynchronous and typed-throwing.
   The honest conformance assessment is recorded: a GPU slice
   renderer for oblique or perspective geometry is blocked by the
   `VOX-SPA-004` float-bounds gate, while an exact axis-aligned CPU
   slice presenter composing the accepted region-extraction and
   window-level operations is implementable without that gate and is
   the natural first conformer, as its own increment.

## Alternatives considered

Recording all ten section 12.4 fields with placeholder values was
rejected: a placeholder in a provenance claim is a false claim.
Making the protocol synchronous was rejected: rendering composes
budgeted asynchronous reads.

## Consequences

The backend-neutral rendering model surface named by `VOX-ARC-008` is
complete for version one — scene, camera, viewport, layer, transfer
function, quality, request and result — and the renderer contract is
ready for its first exact conformer.

## Affected modules

`VoxeliaRendering` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Identifier-bearing claims only; closed states; typed payload-free
rejections; no false provenance fields.

## Performance and memory impact

Constant-size immutable values.

## Validation impact

Tests must compose a full request from validated members, prove
result and provenance identity across every field, and exercise the
protocol through a conforming stub.

## Migration

Implemented in this increment.

## Supersession

This ADR closes the version-one rendering model arc and supersedes
nothing.

## References

- [ADR-0084 - Render quality, layer and scene snapshot models](ADR-0084-render-quality-layer-and-scene.md)
- [ADR-0067 - Result publication coordinator](ADR-0067-result-publication-coordinator.md)
