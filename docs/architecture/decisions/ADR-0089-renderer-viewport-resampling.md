---
document_id: "ADR-0089"
title: "Renderer viewport resampling composition"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-017"
  - "VOX-VS1-019"
  - "VOX-ERR-001"
---

# ADR-0089 - Renderer viewport resampling composition

## Context

`ADR-0086` admitted only viewports equal to the image extents because
resampling was an unregistered numeric model. `ADR-0088` registered
nearest-neighbour resampling as a full Execution operation, so the
renderer can now present arbitrary admitted viewports by composing two
registered operations. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`ExactSliceRenderer` lifts its identity-only viewport admission:

1. **Composition order.** Window-level executes first over the stored
   samples — the value model consumes the stored-to-real composition —
   and nearest-neighbour resampling then maps the greyscale output to
   the requested viewport, because resampling is value-neutral and
   ordering it after the value model keeps every stage a registered
   operation over its accepted domain.
2. **Both derived objects publish.** The window-levelled intermediate
   and the resampled output each publish with their full identity and
   provenance, giving a depth-three complete chain, because the
   coordinator's ancestry closure is walked over the published
   registry and an unpublished parent would be exactly the silent
   history the discipline forbids. When the viewport equals the image
   extents the renderer publishes the single window-levelled object
   unchanged — an identity resample would mint a bit-identical object
   with no presentation meaning.
3. **Per-stage host naming.** `RenderPublicationNaming` now receives a
   closed `RenderPublicationStage` value — `windowLevelled` or
   `resampled` — because two published objects need two host-supplied
   identifier sets and the renderer still mints no identifiers and
   acquires no clock. This is a pre-release signature revision of the
   `ADR-0086` contract; no released caller exists.
4. **Dead case removed.** `SliceRendererError.viewportMismatch` has no
   remaining throw site and is removed pre-release per the `ADR-0071`
   precedent; unsupported inputs surface as the operations' own typed
   admissions.

## Alternatives considered

Publishing only the resampled output was rejected: complete-mode
admission would fail on the absent parent, and weakening to compact
authority to hide a locally available record would be dishonest.
Resampling before window-level was rejected: it would run the value
model over samples the registered composition never defined.

## Consequences

Arbitrary admitted viewports render end to end from registered
operations with evidence-carrying provenance at every stage.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Pre-release signature revision of `RenderPublicationNaming` and
removal of one dead error case; no released caller exists.

## Security impact

Unchanged budgets and ceilings; two bounded publications per resampled
render.

## Performance and memory impact

One additional operation execution and publication when the viewport
differs from the image extents.

## Validation impact

Tests must render an equal-extent viewport unchanged, render a
differing viewport producing the registered window-level fixture
resampled per `VOXELIA-ALG-0008` with both objects published and a
depth-three complete chain, and keep the unpublished-image rejection
typed.

## Migration

Implemented in this increment.

## Supersession

Revises the `ADR-0086` renderer admission; `ADR-0086` otherwise
stands.

## References

- [ADR-0086 - Exact diagnostic slice renderer](ADR-0086-exact-diagnostic-slice-renderer.md)
- [ADR-0088 - Nearest-neighbour resampling operation](ADR-0088-nearest-neighbour-resampling.md)
