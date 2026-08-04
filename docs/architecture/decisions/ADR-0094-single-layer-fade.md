---
document_id: "ADR-0094"
title: "Single-layer fade admission"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-ARC-008"
  - "VOX-ERR-001"
---

# ADR-0094 - Single-layer fade admission

## Context

`ADR-0090` admitted two through 64 layers, so `ADR-0091` required
opacity one for single-layer scenes and recorded the single-layer
fade as its own versioned decision. The registered
`VOXELIA-ALG-0009` model already defines the one-layer case — the
uniform black-background rule has no minimum, and its first fixture
is a single layer at opacity one — so the restriction was operation
admission only. This record was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **Operation widening.** `CompositeLayersOperation` admits one
   through 64 layers with the operation and implementation versions
   advanced to 1.1.0 — the established compatible-domain-widening
   versioning — and an empty layer list remains the typed
   `invalidLayerCount` rejection. The registered model is unchanged.
2. **Renderer fade path.** The renderer composites whenever more than
   one layer is declared or a single layer carries a non-unit
   opacity, publishing the composite stage; a single layer at opacity
   one keeps its accepted single-publication shape, because an
   opacity-one composite would mint a value-identical object with no
   presentation meaning. The now-dead
   `SliceRendererError.unsupportedLayerOpacity` case is removed per
   the `ADR-0071` precedent.

## Alternatives considered

Applying the fade inside the window-level stage was rejected: the
fade is the registered blending model's arithmetic, not the window
model's. Keeping the typed rejection was rejected: the gate existed
only because the admission was narrower than the registered model.

## Consequences

Single-layer fades render end to end through registered operations;
every scene the model defines is now presentable.

## Affected modules

`VoxeliaExecution` and `VoxeliaMetal`; no dependency change.

## Compatibility impact

Admission widening under the established version bump; one dead error
case removed pre-release.

## Security impact

Unchanged budgets and ceilings.

## Performance and memory impact

One additional composite execution and publication for faded
single-layer scenes.

## Validation impact

Tests must reproduce the single-layer opacity-one-half fade through
the operation against an independently computed fixture, reject an
empty layer list typed, render a faded single-layer scene end to end
with the composite stage published, and carry the 1.1.0 versions in
the recipe.

## Migration

Implemented in this increment.

## Supersession

Widens the `ADR-0090` admission and revises the `ADR-0091`
single-layer rule; those records otherwise stand.

## References

- [ADR-0090 - Layer compositing operation](ADR-0090-layer-compositing-operation.md)
- [ADR-0091 - Multi-layer scene presentation](ADR-0091-multi-layer-scene-presentation.md)
