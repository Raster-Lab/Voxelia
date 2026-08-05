---
document_id: "ADR-0116"
title: "Singleton axis squeeze"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-001"
  - "VOX-EXE-002"
  - "VOX-ERR-001"
---

# ADR-0116 - Singleton axis squeeze

## Context

An extracted one-thick multiplanar slab stays rank three, while
rank-two consumers — the renderer's viewport equality among them —
need the natural slice rank. Dropping an extent-one axis is
byte-identical in the canonical packed layout, so the step is a
descriptor-level model registrable without arithmetic. This record
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

`VoxeliaExecution` gains the seventh operation, registered as
`org.voxelia.op.squeeze-axes` 1.0.0 with implementation
`org.voxelia.impl.squeeze-axes.cpu` 1.0.0 under the
`singleton-axis-squeeze/exact-v1` model of `VOXELIA-ALG-0013`:

1. **Explicit declared axes.** One frozen `axes` signed-integer-array
   parameter names the axes to drop — each must exist, have extent
   one and appear once, the selection must be non-empty and at least
   one axis must remain, all else the typed `invalidAxisSelection`;
   an implicit drop-all-singletons rule was rejected because a host
   that means one axis should never lose another it forgot about.
2. **Byte-identical payload, honest recipe.** The output samples are
   the input bytes exactly; the remaining axes keep their descriptors
   and payloads in order; scalar format, components, semantic, value
   transform, units and metadata pass through; geometry-bearing input
   rejects typed — the binding remap stays its own decision — and the
   identity, recipe, subject-bound provenance and `exact` CPU claim
   follow the accepted operation pattern.

## Alternatives considered

Reshaping inside the extraction operation was rejected: one
operation, one model. A rank-two-only renderer widening was
rejected: the slab's rank change is derived history and deserves a
record.

## Consequences

Extract-then-squeeze turns a regular volume into a published rank-two
slice; the multiplanar coordinator composes next.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Byte-identical copies under existing budgets; typed payload-free
rejections.

## Performance and memory impact

One coordinated read and one byte copy.

## Validation impact

Tests must reproduce both `VOXELIA-ALG-0013` fixtures through the
full operation with byte identity proven, verify remaining axes keep
their descriptors in order, reproduce the parameter digest
independently, and reject an empty selection, a non-singleton axis, a
duplicate, an out-of-range index and a total drop, all typed.

## Migration

Implemented in this increment.

## Supersession

Registers the seventh operation; no record is superseded.

## References

- [VOXELIA-ALG-0013 - Singleton axis squeeze exact-v1](../../algorithms/VOXELIA-ALG-0013-singleton-axis-squeeze.md)
- [ADR-0115 - Axis transposition operation](ADR-0115-axis-transposition-operation.md)
