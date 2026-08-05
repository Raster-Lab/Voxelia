---
document_id: "ADR-0099"
title: "Fully-device renderer path"
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

# ADR-0099 - Fully-device renderer path

## Context

`ADR-0092` made the window stage injectable and `ADR-0098` delivered
the device composite operation, but the renderer's composite stage
was still hard-wired to the CPU implementation, so a device render of
a multi-layer scene silently mixed backends. This record was authored
and accepted on 2026-08-05 under the project owner's recorded
broadened autonomous delegation.

## Decision

1. **Composite-stage injection.** The shared pipeline gains a
   composite-stage executor mirroring the window stage; the exact
   renderer's public shape is unchanged and injects the CPU
   implementation, keeping one orchestration authority.
2. **Both stages on the device.** `MetalSliceRenderer` takes the
   composite kernel alongside the window kernel — a pre-release
   signature revision of the `ADR-0092` conformer — and injects both
   device operations, so every value-arithmetic stage of a device
   render carries its own honest `binary32-device`, `approximate`,
   kernel-referenced claim. The resample stage remains the accepted
   exact CPU operation, because whole-sample selection performs no
   value arithmetic and a device approximation claim for it would be
   manufactured imprecision.

## Alternatives considered

Mixing device window with CPU composite silently was rejected: each
stage's record is honest, but the renderer choice should mean what it
says. A device resample stage was rejected here: the operation is
exact byte selection with nothing to approximate.

## Consequences

A device render's published history now claims device execution on
every value-arithmetic stage, verifiable record by record.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Pre-release signature revision of `MetalSliceRenderer`; no released
caller exists.

## Security impact

Unchanged budgets and disciplines.

## Performance and memory impact

One additional device dispatch per multi-layer or faded device
render.

## Validation impact

Tests must render a two-layer scene fully on the device within one
display level of the registered binary64 fixture with the measured
count printed, and verify both stage records carry their device
implementation tokens and kernel references.

## Migration

Implemented in this increment.

## Supersession

Completes the `ADR-0092` device path with the `ADR-0098` operation;
no record is superseded.

## References

- [ADR-0098 - Device composite operation](ADR-0098-device-composite-operation.md)
- [ADR-0092 - GPU slice presentation path](ADR-0092-gpu-slice-presentation-path.md)
