---
document_id: "ADR-0071"
title: "Geometry-preserving region extraction"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-IMG-001"
  - "VOX-SPA-011"
  - "VOX-ERR-001"
---

# ADR-0071 - Geometry-preserving region extraction

## Context

Accepted `ADR-0064` rejected geometry-bearing and regularly sampled
inputs because cropping shifts origins, deferring that arithmetic to
its own decision. The shift is now registered as
`region-origin-shift/binary64-v1` per `VOXELIA-ALG-0006`. This record
was authored and accepted on 2026-08-04 under the project owner's
recorded overnight autonomous delegation.

## Decision

1. **Lifted admission.** The region extraction operation admits
   inputs with affine spatial geometry and with regular axis sampling.
   The output geometry keeps the rotation-scale block, mapped axes and
   coordinate space with the translation updated per the registered
   model, and regular axes keep their spacing with the origin updated
   likewise — so every extracted sample keeps the exact world position
   and axis coordinate it had in the source. Rebuilt values revalidate
   through their accepted constructing initializers. Irregular,
   categorical and externally defined samplings stay typed rejections:
   slicing their payloads is a different model.
2. **Error surface.** The dead geometry rejection case is removed
   before any release; the sampling rejection case remains for the
   uncovered samplings.
3. **Version bump.** The operation and implementation versions
   advance to `1.1.0`; previously admitted inputs stay bit-identical.

## Alternatives considered

Dropping geometry on crop was rejected long since as silent data
loss. Re-deriving the translation by inverting and re-composing the
matrix was rejected: the direct column update is exact where inversion
introduces rounding. Slicing irregular coordinate and categorical
label payloads was rejected for this increment as a separate model
with its own fixtures.

## Consequences

Spatially calibrated images crop without losing calibration, and the
first operation's admission matches its semantics: nothing about a
crop requires abandoning geometry.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Previously rejected inputs become admitted; the removed error case
predates any release; everything else is bit-identical under the
advanced version tokens.

## Security impact

The updates are bounded exact arithmetic over validated values,
revalidated on reconstruction; existing budgets and typed payload-free
failures apply.

## Performance and memory impact

At most three multiply-adds per spatial axis and one per regular axis,
once per execution.

## Validation impact

Tests must reproduce both `VOXELIA-ALG-0006` fixtures through the
full operation — the rotated affine translation update and the
regular-origin shift, with unchanged non-translation elements, spacing,
mapped axes and coordinate space — prove byte-exact samples and the
advanced version tokens, and reject an externally defined sampling
typed.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0064` origin-shift deferral and
supersedes nothing.

## References

- [VOXELIA-ALG-0006 - Region origin shift binary64-v1](../../algorithms/VOXELIA-ALG-0006-region-origin-shift.md)
- [ADR-0064 - Exact region extraction operation](ADR-0064-exact-region-extraction-operation.md)
