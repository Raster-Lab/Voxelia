---
document_id: "ADR-0080"
title: "Window-level Metal kernel and differential harness"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PLT-011"
  - "VOX-REP-008"
  - "VOX-EXE-003"
  - "VOX-VAL-007"
  - "VOX-ERR-001"
---

# ADR-0080 - Window-level Metal kernel and differential harness

## Context

Milestone M3 requires shader identity, a first Voxelia-owned Metal
Shading Language kernel and the CPU-Metal differential harness, on the
context boundary `ADR-0079` opened. `MSL` has no 64-bit floating
type, so no GPU implementation can be the registered
`VOXELIA-ALG-0002` binary64 model; it can only approximate it, and the
claims must say so. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **Kernel and identity.** The first Voxelia-owned kernel is the
   embedded `MSL` window-level compute function
   (`voxelia_window_level_u8`, family version `1.0.0`, kernel token
   `org.voxelia.kernel.window-level`), owned and compiled by
   `VoxeliaMetal` per `VOX-REP-008` through runtime source
   compilation on the acquired context. The shader manifest records
   the family with its entry point, version and the SHA-256 digest of
   the exact embedded source text, and the suite verifies the pin so
   manifest and source can never drift silently.
2. **Honest claims.** The kernel mirrors the `VOXELIA-ALG-0002`
   branch structure in `float32` with edges precomputed once from the
   binary64 parameters. A GPU execution claim for it must carry the
   precision policy `org.voxelia.precision.binary32-device`,
   approximation status `approximate` and the kernel component
   reference; claiming `binary64-strict` for GPU output is
   structurally false and prohibited.
3. **Execution path.** `MetalWindowLevelKernel` builds its pipeline
   at initialisation with typed payload-free failures, maps `uint8`
   sample buffers through shared-storage buffers on the unified
   memory the context evidences, bounds every dispatch by an explicit
   sample count inside the kernel, and surfaces command-buffer
   failure typed.
4. **Differential harness.** The suite drives the exhaustive `uint8`
   domain through both implementations across a spread of windows —
   including the degenerate unit width — anchored to the registered
   `VOXELIA-ALG-0002` fixtures, and asserts: every GPU sample is
   within one display level of the binary64 model, repeated GPU
   execution is bit-identical, and the measured exact-match count is
   reported as recorded single-device evidence rather than assumed.

## Alternatives considered

Precompiled metallib resources were rejected for the first kernel:
runtime source compilation keeps the digest-pinned source as the
single artefact and needs no build plugin; a compiled-library
distribution decision can follow with its own reproducibility
evidence. Emulating binary64 in the kernel was rejected as an
unregistered numeric model. Asserting bit-equality with the CPU model
was rejected: it would encode an unmeasured hope; the harness
measures.

## Consequences

Voxelia executes its first GPU kernel under pinned shader identity
with honest precision claims and a real measured differential against
the frozen CPU model.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

The kernel source is digest-pinned and compiled from the embedded
text only; no external shader is loaded; buffers are bounds-checked
inside the kernel; failures stay payload-free.

## Performance and memory impact

One pipeline build per kernel instance and shared-storage buffers
sized to the sample count.

## Validation impact

The suite must verify the manifest digest pin, reproduce the
registered `VOXELIA-ALG-0002` `uint8` fixture through the GPU within
the one-level bound, run the exhaustive differential with the stated
assertions and report the measured exact-match evidence, and reject a
sub-one width typed.

## Migration

Implemented in this increment.

## Supersession

This ADR delivers the first M3 kernel and supersedes nothing.

## References

- [ADR-0079 - Metal execution context boundary](ADR-0079-metal-execution-context-boundary.md)
- [VOXELIA-ALG-0002 - Window-level linear mapping binary64-v1](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
