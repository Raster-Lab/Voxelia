---
document_id: "ADR-0098"
title: "Device composite operation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-PLT-013"
  - "VOX-ERR-001"
---

# ADR-0098 - Device composite operation

## Context

`ADR-0096` delivered the measured compositing kernel but no operation
reaches it: device blends had no identity, recipe or claim discipline.
The `ADR-0092` pattern — a second implementation of a registered
operation with the honest device claim and the one frozen parameter
authority — applies directly. This record was authored and accepted
on 2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`VoxeliaMetal` gains `MetalCompositeLayersOperation`, implementing
`org.voxelia.op.composite-layers` at its current 1.1.0 contract
version with the new implementation token
`org.voxelia.impl.composite-layers.metal` 1.0.0:

1. **Same admission, same shape.** Version-one device admission
   mirrors the registered operation — one through 64 equal-extent
   rank-two `uint8` intensity layers with index-only sampling, no
   geometry and no value transform, opacities finite in zero through
   one — rejected typed through the operation's own `CompositeError`
   surface; the output carries the identical descriptor, empty
   metadata, sample-bytes identity, derivation recipe and
   subject-bound provenance with one `layer` parent edge per layer.
2. **Honest device claim.** The execution claim records the metal
   backend, `binary32-device` precision, `approximate` status, the
   composite kernel component reference and the detected capability
   class — the `ADR-0096` kernel is the entire device numeric path.
3. **One frozen parameter authority.** The operation-parameters
   builder of the CPU implementation becomes public and is reused per
   the `ADR-0073` shared-authority rule, so both implementations
   digest identical parameter documents.

## Alternatives considered

A new operation token was rejected: the registered operation is the
model's identity and implementations are recipe-distinguishable.
Duplicating the parameter-schema construction was rejected under the
shared-authority rule. Wiring the renderer's fully-device path here
was rejected: one increment, one boundary.

## Consequences

Device blends carry full identity and provenance; a fully-device
renderer window-plus-composite path becomes a small follow-on.

## Affected modules

`VoxeliaExecution` (one member becomes public) and `VoxeliaMetal`; no
dependency change.

## Compatibility impact

Purely additive plus one pre-release visibility widening.

## Security impact

Unchanged budgets; typed payload-free rejections.

## Performance and memory impact

One packed device dispatch per composite in place of the CPU blend
pass.

## Validation impact

Tests must execute the device operation on the real device against
the CPU implementation's output within one display level with the
measured count printed, verify the published claim carries the device
precision, status, composite kernel reference, capability class and
metal implementation token, prove both implementations digest one
parameter authority, and reject a transformed layer and unequal
extents typed.

## Migration

Implemented in this increment.

## Supersession

Extends `ADR-0096` to the operation discipline per the `ADR-0092`
pattern; no record is superseded.

## References

- [ADR-0096 - Layer compositing Metal kernel](ADR-0096-composite-metal-kernel.md)
- [ADR-0092 - GPU slice presentation path](ADR-0092-gpu-slice-presentation-path.md)
