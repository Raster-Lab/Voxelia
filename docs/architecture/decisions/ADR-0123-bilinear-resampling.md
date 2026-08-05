---
document_id: "ADR-0123"
title: "Bilinear resampling operation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-013"
  - "VOX-EXE-002"
  - "VOX-ERR-001"
---

# ADR-0123 - Bilinear resampling operation

## Context

`VOX-R2D-013` requires explicit nearest-neighbour, linear and
no-interpolation display policies. Nearest-neighbour is registered
and no-interpolation is the identity presentation; the linear policy
needed its value model. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`VoxeliaExecution` gains the eighth operation, registered as
`org.voxelia.op.resample-linear` 1.0.0 with implementation
`org.voxelia.impl.resample-linear.cpu` 1.0.0 under the
`bilinear-resampling/binary64-v1` model of `VOXELIA-ALG-0015`:

1. **The registered model.** Pixel-centre-aligned source coordinates
   with edge replication through clamped taps and the unclamped-floor
   weight, the frozen declared-order interpolation with no fused
   multiply-add, ties-to-even rounding and the modelled clamp; the
   identity mapping at equal dimensions is exact by construction and
   proven by fixture.
2. **Version-one admission.** Rank-two single-component eight-bit
   intensity images with index-only sampling, no geometry and no
   value transform — the display-policy domain, mirroring the
   compositing admission — with output extents one through 16,384
   per dimension; parameters, identity, recipe, provenance and the
   `binary64-strict` `exact` claim mirror the nearest-neighbour
   operation exactly, including the frozen
   `output-width`/`output-height` schema.
3. **Renderer wiring is its own decision.** Selecting the linear
   policy through the presentation vocabulary — widening
   `PresentationScaling` and the renderer's resample stage — follows
   separately, so the policy claim arrives with the code that honours
   it.

## Alternatives considered

Widening the nearest-neighbour operation with a mode parameter was
rejected: different value arithmetic is a different registered model,
and the recipes must stay distinguishable by operation identity.
Value-neutral generality was rejected: interpolation reads values,
so the admission names its value domain.

## Consequences

All three `VOX-R2D-013` policies have registered semantics; the
renderer-side selection completes the row in its own increment.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Bounded output extents under existing budgets; typed payload-free
rejections.

## Performance and memory impact

One coordinated read and four taps per output sample.

## Validation impact

Tests must reproduce all three `VOXELIA-ALG-0015` fixtures through
the full operation including the exact identity, reproduce the
parameter digest independently, and reject unsupported formats and
out-of-range extents typed.

## Migration

Implemented in this increment.

## Supersession

Registers the eighth operation; no record is superseded.

## References

- [VOXELIA-ALG-0015 - Bilinear resampling binary64-v1](../../algorithms/VOXELIA-ALG-0015-bilinear-resampling.md)
- [ADR-0088 - Nearest-neighbour resampling operation](ADR-0088-nearest-neighbour-resampling.md)
