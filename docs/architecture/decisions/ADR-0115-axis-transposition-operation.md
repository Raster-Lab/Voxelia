---
document_id: "ADR-0115"
title: "Axis transposition operation"
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

# ADR-0115 - Axis transposition operation

## Context

The M4 multiplanar rows need axis-aligned reslicing of regular
volumes. Extraction is already rank-general, so an axial slab is
extractable today; coronal and sagittal presentation additionally
need the axes reordered, which was an unregistered index remap. This
record opens the MPR arc and was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

`VoxeliaExecution` gains the sixth operation, registered as
`org.voxelia.op.transpose-axes` 1.0.0 with implementation
`org.voxelia.impl.transpose-axes.cpu` 1.0.0:

1. **Frozen parameter schema.** One metadata collection with exactly
   the `axis-order` signed-integer array — the declared permutation —
   digested under the registered operation-parameters projection; a
   non-permutation rejects as the typed `invalidAxisOrder`.
2. **Version-one admission.** Rank one through eight with no spatial
   geometry — remapping an affine geometry's image-axis binding is
   its own decision — while every per-axis property travels with its
   axis: descriptors, semantics, units and sampling payloads reorder
   intact, because the model never slices or interprets them; scalar
   format, components, semantic, value transform, units and metadata
   pass through unchanged, because the model never reads a value.
3. **Execution and claims.** The full input reads through the
   budgeted coordinator; whole samples copy per the registered exact
   remap; and the identity, recipe, subject-bound provenance and
   `exact` CPU claim follow the accepted operation pattern.

## Alternatives considered

Composing transposition into extraction was rejected: one operation,
one model — a fused reslice would entangle two registered models and
their admissions. Permuting geometry axis bindings in version one was
rejected: the binding remap deserves its own recorded rule.

## Consequences

Axis-aligned MPR becomes composable: extract a slab, transpose to
presentation order; the composing coordinator is the arc's next
increment.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Value-neutral byte copies under existing budgets; bounded rank; typed
payload-free rejections.

## Performance and memory impact

One coordinated read and one output-sized remap pass.

## Validation impact

Tests must reproduce both `VOXELIA-ALG-0012` fixtures through the
full operation, prove the identity permutation byte-identical and a
permutation composed with its inverse the identity, verify axis
descriptors and sampling payloads travel with their axes, reproduce
the parameter digest independently, and reject a non-permutation,
geometry-bearing input and an over-rank image typed.

## Migration

Implemented in this increment.

## Supersession

Registers the sixth operation and opens the MPR arc; no record is
superseded.

## References

- [VOXELIA-ALG-0012 - Axis transposition exact-v1](../../algorithms/VOXELIA-ALG-0012-axis-transposition.md)
- [ADR-0064 - Exact region extraction operation](ADR-0064-exact-region-extraction-operation.md)
