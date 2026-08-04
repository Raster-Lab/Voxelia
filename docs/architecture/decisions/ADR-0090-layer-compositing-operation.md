---
document_id: "ADR-0090"
title: "Layer compositing operation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-IMG-001"
  - "VOX-ERR-001"
---

# ADR-0090 - Layer compositing operation

## Context

The scene model admits up to 64 ordered layers but the renderer
presents only one, because multi-layer blending was an unregistered
value-arithmetic model. The model is now registered as
`layered-linear-blend/binary64-v1` per `VOXELIA-ALG-0009` — a uniform
composite-over rule from a black background with one opacity per
layer, frozen binary64 evaluation and no fused multiply-add. A
blended output is a new derived object, so the honest shape is a
fourth Execution operation with the full parameter, identity and
provenance discipline. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`VoxeliaExecution` gains the fourth operation, registered as
`org.voxelia.op.composite-layers` 1.0.0 with implementation
`org.voxelia.impl.composite-layers.cpu` 1.0.0:

1. **Frozen parameter schema.** One metadata collection with exactly
   the `opacities` entry — an array of floating-point values, one per
   declared layer in order, each finite in `[0, 1]` — digested under
   the registered operation-parameters projection.
2. **Version-one admission.** Two through 64 layers — the scene
   ceiling — each a rank-two single-component `uint8` intensity image
   with index-only sampling, no spatial geometry and no value
   transform, all with equal extents, because the registered model
   blends presentation greyscale values only. The output carries the
   first layer's axes and shape, `uint8` native scalar format, empty
   metadata — element-wise blended metadata has no defined meaning,
   and history flows through the provenance chain — and no geometry,
   transform or units.
3. **Execution and claims.** Every layer is read through the budgeted
   coordinator; elements blend per the registered model; and the
   identity, recipe, subject-bound provenance and execution claim
   follow the accepted operation pattern with the `binary64-strict`
   precision policy and `exact` approximation status. The derivation
   records one positional `layer` input per layer in declared order,
   and the provenance record binds each layer with the `layer` role
   at occurrence `k + 1` and a graph-node parent edge.

## Alternatives considered

A distinguished opaque base layer was rejected: the uniform
black-background rule has no special case and a first layer at
opacity one reproduces it exactly. Blending inside the renderer was
rejected: a derived object without operation provenance is silent
history. Premultiplied-alpha and gamma-aware models were rejected
here: each is its own registered model.

## Consequences

Multi-layer scenes become composable from registered operations; the
renderer can lift its single-layer admission as its own increment.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Bounded layer count, existing read budgets, typed payload-free
rejections.

## Performance and memory impact

One coordinated read per layer and one blend pass over the output.

## Validation impact

Tests must reproduce the `VOXELIA-ALG-0009` fixtures through the full
operation including the exact opacity-one reproduction, reproduce the
parameter digest independently, admit the output with every layer
parent into a complete graph, and reject a bad layer count, unequal
extents, an unsupported layer format, and out-of-range or miscounted
opacities, all typed.

## Migration

Implemented in this increment.

## Supersession

This ADR registers the fourth operation and supersedes nothing.

## References

- [VOXELIA-ALG-0009 - Layered linear blend binary64-v1](../../algorithms/VOXELIA-ALG-0009-layered-linear-blend.md)
- [ADR-0088 - Nearest-neighbour resampling operation](ADR-0088-nearest-neighbour-resampling.md)
