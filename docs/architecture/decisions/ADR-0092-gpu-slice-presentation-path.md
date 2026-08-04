---
document_id: "ADR-0092"
title: "GPU slice presentation path"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-017"
  - "VOX-PLT-013"
  - "VOX-ERR-001"
---

# ADR-0092 - GPU slice presentation path

## Context

`ADR-0080` delivered the digest-pinned `float32` window-level kernel
with measured differential evidence, and `ADR-0086`/`ADR-0089`/
`ADR-0091` composed the CPU presentation pipeline behind the
`SliceRenderer` contract. The kernel was not yet reachable through
that contract, and a GPU-executed stage must carry honest claims —
`MSL` has no 64-bit floating type, so `binary64-strict` is prohibited
for device execution. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **A second implementation of the registered operation.**
   `VoxeliaMetal` gains `MetalWindowLevelOperation`, implementing
   `org.voxelia.op.window-level` at the current contract version with
   the new implementation token
   `org.voxelia.impl.window-level.metal` 1.0.0. It executes the
   accepted kernel over one budgeted coordinated read and assembles
   the identical output shape — descriptor, sample-bytes identity,
   derivation recipe and subject-bound provenance — with the honest
   execution claim: backend `org.voxelia.backend.metal`, precision
   `org.voxelia.precision.binary32-device`, approximation status
   `approximate`, the kernel component reference and the detected
   capability class. Version-one device admission is `uint8` samples
   with an absent or identity value transform — the kernel implements
   the plain registered model — rejected typed through the
   operation's own `WindowLevelError` surface.
2. **One frozen parameter authority.** The operation-parameters
   collection builder of `WindowLevelOperation` becomes public and is
   reused, because two constructions of one registered schema could
   drift silently — the `ADR-0073` shared-authority rule; both
   implementations therefore digest identical parameter documents and
   their recipes differ only in the implementation reference and
   claim.
3. **The GPU renderer conformer.** `ExactSliceRenderer`'s
   orchestration becomes the single internal pipeline authority with
   an injected window stage, and the new `MetalSliceRenderer`
   conformer injects the GPU stage; composite and resample stages
   remain the accepted CPU operations. Renderer choice is explicit —
   there is no silent fallback between backends, per the `ADR-0081`
   rule.

## Alternatives considered

Claiming `binary64-strict` for the device stage was rejected as
false. A silent GPU acceleration inside `ExactSliceRenderer` was
rejected: the claims differ, so the backend must be the host's
explicit choice. Duplicating the parameter-schema construction was
rejected under the shared-authority rule.

## Consequences

The full presentation pipeline — window, composite, resample,
publication — runs with a GPU window stage whose provenance honestly
records device execution, on the measured single-device evidence.

## Affected modules

`VoxeliaExecution` (one member becomes public) and `VoxeliaMetal`; no
dependency change.

## Compatibility impact

Purely additive plus one pre-release visibility widening.

## Security impact

Unchanged budgets; kernel source remains digest-pinned; typed
payload-free rejections.

## Performance and memory impact

One shared-storage device dispatch per rendered layer in place of the
CPU mapping pass.

## Validation impact

Tests must render through `MetalSliceRenderer` on the real device
reproducing the registered fixture bytes with a measured
GPU-versus-model differential reported as evidence, verify the
published claim carries the `binary32-device` precision policy, the
`approximate` status, the kernel reference, the capability class and
the metal implementation token, and reject a non-identity value
transform through the device admission typed.

## Migration

Implemented in this increment.

## Supersession

Extends `ADR-0080` to the renderer contract; no record is superseded.

## References

- [ADR-0080 - Window-level Metal kernel](ADR-0080-window-level-metal-kernel.md)
- [ADR-0091 - Multi-layer scene presentation](ADR-0091-multi-layer-scene-presentation.md)
