---
document_id: "ADR-0088"
title: "Nearest-neighbour resampling operation"
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

# ADR-0088 - Nearest-neighbour resampling operation

## Context

The exact slice renderer admits only identity presentation because
resampling was an unregistered numeric model. The model is now
registered as `nearest-neighbour-resampling/binary64-v1` per
`VOXELIA-ALG-0008` — value-neutral whole-sample selection with a
frozen binary64 index computation. Because resampled output is a new
derived object, the honest shape is a third Execution operation with
the full parameter, identity and provenance discipline, never a
silent renderer step. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`VoxeliaExecution` gains the third operation, registered as
`org.voxelia.op.resample-nearest` 1.0.0 with implementation
`org.voxelia.impl.resample-nearest.cpu` 1.0.0:

1. **Frozen parameter schema.** One metadata collection with exactly
   the `output-width` and `output-height` signed-integer entries,
   digested under the registered operation-parameters projection;
   output extents admit one through 16,384 inclusive per dimension.
2. **Version-one admission.** Rank-two images with index-only axis
   sampling and no spatial geometry — scaling regular spacings and
   affine geometries under resampling is origin-and-spacing
   arithmetic deferred to its own decision — while scalar format,
   components, semantic, value transform, units and metadata pass
   through unchanged, because the model never interprets a value.
3. **Execution and claims.** The full input is read through the
   budgeted coordinator; whole samples copy per the registered index
   model; and the identity, recipe, subject-bound provenance and
   execution claim follow the accepted operation pattern with the
   `binary64-strict` precision policy and `exact` approximation
   status, because the frozen binary64 computation is the model's
   definition.

## Alternatives considered

Implementing resampling inside the renderer was rejected: a derived
object without its own operation provenance is exactly the silent
history the discipline forbids. Interpolating filters were rejected
here: each is its own registered value-arithmetic model.

## Consequences

Arbitrary-viewport slice presentation becomes composable from
registered operations, and the renderer can lift its identity-only
admission as its own increment.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Value-neutral byte copies under existing budgets; bounded output
extents; typed payload-free rejections.

## Performance and memory impact

One coordinated read and one output-sized selection pass.

## Validation impact

Tests must reproduce both `VOXELIA-ALG-0008` fixtures through the
full operation, prove the identity mapping at equal dimensions,
reproduce the parameter digest independently, admit the output into a
depth-two complete graph, and reject a non-rank-two image, regular
sampling, geometry, and out-of-range output extents, all typed.

## Migration

Implemented in this increment.

## Supersession

This ADR registers the third operation and supersedes nothing.

## References

- [VOXELIA-ALG-0008 - Nearest-neighbour resampling binary64-v1](../../algorithms/VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
- [ADR-0064 - Exact region extraction operation](ADR-0064-exact-region-extraction-operation.md)
