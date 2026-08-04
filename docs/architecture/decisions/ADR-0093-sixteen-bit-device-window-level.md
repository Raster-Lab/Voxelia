---
document_id: "ADR-0093"
title: "Sixteen-bit device window-level paths"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PLT-011"
  - "VOX-VAL-007"
  - "VOX-ERR-001"
---

# ADR-0093 - Sixteen-bit device window-level paths

## Context

The device window-level implementation of `ADR-0092` admitted `uint8`
samples only, while the registered CPU implementation admits `int16`
and `uint16`. The embedded kernel had one entry point; a 16-bit
device path needs typed entry points, a repinned source digest and
its own measured differential evidence — `float32` agreement measured
on the `uint8` domain says nothing about the 16-bit domains. This
record was authored and accepted on 2026-08-05 under the project
owner's recorded broadened autonomous delegation.

## Decision

1. **Typed entry points, one mapping authority.** The embedded source
   gains `voxelia_window_level_i16` and `voxelia_window_level_u16`,
   and all three entry points call one shared inline mapping helper
   mirroring the `VOXELIA-ALG-0002` branch structure, so the `MSL`
   model exists exactly once. The shader manifest repins the new
   source digest, advances the family to 1.1.0 and lists all three
   entry points; the pinned-digest suite verifies the pin.
2. **Kernel and operation widening.** `MetalWindowLevelKernel` builds
   one pipeline per entry point and gains the typed
   `mapSamples(storedBytes:scalarType:center:width:)` surface with
   the new `unsupportedScalarType` and `invalidSampleByteCount`
   rejections; the `uint8` signature remains as a delegating
   convenience. `MetalWindowLevelOperation` admission widens to the
   three scalar types with the implementation version advanced to
   1.1.0 — compatible domain widening per the established versioning
   precedent — and 16-bit device reads are native little-endian, so a
   non-native declared order stays outside the admitted formats.
3. **Measured 16-bit evidence.** The differential harness measures
   the device against the frozen binary64 model over deterministic
   seeded-LCG `int16` and `uint16` corpora across a spread of
   windows, asserts the one-display-level bound and the 99 percent
   exact floor, and prints the measured exact count as single-device
   evidence — measured, never assumed; claims stay `binary32-device`
   with `approximate` status.

## Alternatives considered

Duplicating the mapping arithmetic per entry point was rejected under
the shared-authority rule. Claiming the `uint8` exactness evidence
for the 16-bit domains was rejected as unmeasured. A separate kernel
token per scalar type was rejected: one family, one token, versioned
entry points.

## Consequences

The GPU presentation path accepts the same scalar domain as the CPU
implementation for plain-model inputs, with per-domain measured
evidence.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Additive kernel surface; new source digest pinned; implementation
version advanced to 1.1.0.

## Security impact

Unchanged budgets; in-kernel thread bound retained; typed
payload-free rejections.

## Performance and memory impact

One shared-storage dispatch per mapping; two bytes per stored sample
for the 16-bit paths.

## Validation impact

Tests must verify the repinned digest and manifest rows, measure the
`int16` and `uint16` differentials over seeded-LCG corpora within one
display level and at least 99 percent exact with the counts printed,
prove repeated device execution bit-identical, execute the operation
over a native `int16` image against the CPU implementation's output
within one display level with the 1.1.0 implementation reference, and
reject an unsupported scalar type and an odd byte count typed.

## Migration

Implemented in this increment.

## Supersession

Widens the `ADR-0092` device admission; no record is superseded.

## References

- [ADR-0092 - GPU slice presentation path](ADR-0092-gpu-slice-presentation-path.md)
- [ADR-0080 - Window-level Metal kernel](ADR-0080-window-level-metal-kernel.md)
