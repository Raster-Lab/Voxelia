---
document_id: "ADR-0083"
title: "Rendering transfer function model"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-008"
  - "VOX-ERR-001"
---

# ADR-0083 - Rendering transfer function model

## Context

The controlled documents assign transfer functions to
`VoxeliaRendering` and expressly forbid placing a display window, VOI
LUT, transfer function or colour map in the Core `ValueTransform`,
but display no concrete shape. The only display mapping Voxelia
currently executes is the registered window-level model. This record
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **`GreyscaleWindowFunction`.** A validated description binding a
   finite window centre and a width of at least one, in the input's
   real value domain — exactly the parameter semantics the registered
   `VOXELIA-ALG-0002` model froze. The value describes presentation
   intent; evaluation belongs to backends against the registered
   model and its measured GPU approximation.
2. **Closed `TransferFunction`.** Version one holds exactly the
   `greyscaleWindow` case. Colour maps, opacity curves and
   volume-rendering transfer functions are deferred: each is a
   registered extension with its own evaluation model, and a colour
   map additionally needs a governed map registry before any token
   can mean anything.
3. **No wire.** Stable coding is owned by the future
   presentation-provenance projection decision.

## Alternatives considered

Admitting arbitrary colour-map tokens without a registry was rejected
as unanchored names. Reusing the Core window-level parameter
collection was rejected: operation parameters and presentation intent
are different domains that happen to share numbers today.

## Consequences

Render layers and requests can carry validated presentation intent
that matches exactly what the execution layer can evaluate.

## Affected modules

`VoxeliaRendering` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Bounded validated values with typed payload-free rejections.

## Performance and memory impact

Constant-size immutable values.

## Validation impact

Tests must admit valid windows including the degenerate unit width,
reject non-finite centres and sub-one or non-finite widths typed, and
prove exact value identity.

## Migration

Implemented in this increment.

## Supersession

This ADR adds the second rendering model and supersedes nothing.

## References

- [ADR-0082 - Rendering camera and viewport models](ADR-0082-rendering-camera-and-viewport.md)
- [VOXELIA-ALG-0002 - Window-level linear mapping binary64-v1](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
