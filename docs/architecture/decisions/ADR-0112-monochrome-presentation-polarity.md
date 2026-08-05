---
document_id: "ADR-0112"
title: "Monochrome presentation polarity"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-005"
  - "VOX-R2D-008"
  - "VOX-ERR-001"
---

# ADR-0112 - Monochrome presentation polarity

## Context

`VOX-R2D-005` requires `MONOCHROME1` and `MONOCHROME2` presentation
semantics and `VOX-R2D-008` requires presentation inversion
independent of source-value transformation; the pipeline presented
standard polarity only. Inversion of eight-bit display values is an
exact involution, registrable without any floating-point model. This
record was authored and accepted on 2026-08-05 under the project
owner's recorded broadened autonomous delegation.

## Decision

1. **Inversion is its own operation.** `VoxeliaExecution` gains the
   fifth operation, `org.voxelia.op.invert-display` 1.0.0 under the
   `display-inversion/exact-v1` model of `VOXELIA-ALG-0011` — the
   exact eight-bit involution with an empty frozen parameter schema —
   admitting eight-bit single-component intensity images of any rank
   with no value transform, and assembling the accepted identity,
   recipe and provenance shape with the `exact` CPU claim. A
   parameter on the window operation was rejected: `VOX-R2D-008`
   demands independence, and a separate published operation is
   independence made structural — the inversion never touches stored
   values or the window model.
2. **Polarity in the presentation vocabulary.**
   `GreyscaleWindowFunction` gains the closed
   `PresentationPolarity` — `standard` for `MONOCHROME2` semantics,
   `inverted` for `MONOCHROME1` — as an explicit member with no
   default; the polarity therefore travels inside every per-layer
   presentation claim unchanged.
3. **The renderer composes it.** An inverted layer runs the inversion
   operation on the window stage's output, published under the new
   `inverted(layerIndex:)` publication stage before compositing;
   standard layers are untouched.

## Alternatives considered

Extending the window model with polarity was rejected: it would
couple the value model to presentation polarity and change the frozen
parameter schema for every render. Inverting inside the renderer
without an operation was rejected: silent history.

## Consequences

Both monochrome conventions present end to end with the inversion
independently published and claimed; `VOX-R2D-005/008` are
discharged.

## Affected modules

`VoxeliaExecution`, `VoxeliaRendering` and `VoxeliaMetal`; no
dependency change.

## Compatibility impact

Pre-release explicit-member addition to `GreyscaleWindowFunction` and
one publication-stage case; no released caller exists.

## Security impact

Unchanged budgets; typed payload-free rejections.

## Performance and memory impact

One exact byte pass and one publication per inverted layer.

## Validation impact

Tests must reproduce the `VOXELIA-ALG-0011` fixtures through the full
operation including the involution, reject unsupported formats typed,
render an inverted layer end to end producing the inverted registered
fixture with the inversion stage published, and keep standard layers
byte-identical to the accepted results.

## Migration

Implemented in this increment.

## Supersession

Registers the fifth operation and extends the `ADR-0083` presentation
vocabulary; no record is superseded.

## References

- [VOXELIA-ALG-0011 - Display inversion exact-v1](../../algorithms/VOXELIA-ALG-0011-display-inversion.md)
- [ADR-0083 - Rendering transfer function](ADR-0083-rendering-transfer-function.md)
