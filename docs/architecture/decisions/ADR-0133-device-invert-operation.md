---
document_id: "ADR-0133"
title: "Device invert operation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-005"
  - "VOX-PLT-013"
  - "VOX-ERR-001"
---

# ADR-0133 - Device invert operation

## Context

The exact device invert kernel exists but no operation reached it,
and the renderer's inversion stage was hard-wired to the CPU
implementation, so a device render of an inverted scene silently
mixed backends. This record was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **The device implementation with the exact claim.**
   `MetalInvertDisplayOperation` implements the registered inversion
   at 1.0.0 with the new `org.voxelia.impl.invert-display.metal`
   1.0.0 implementation: the accepted integer-exact kernel is the
   entire device path, the whole descriptor passes through
   calibration included, and the claim carries the metal backend with
   `exact` precision and status plus the kernel reference and
   capability class — the first device operation whose claim is
   exactness, because the arithmetic is.
2. **The inversion stage becomes injectable.** The shared pipeline
   gains an invert-stage executor mirroring the window and composite
   stages; the exact renderer injects the CPU implementation and
   `MetalSliceRenderer` takes the invert kernel — with the planner
   acquiring it alongside the others — so a device render of an
   inverted scene runs every value stage on the device.

## Alternatives considered

Keeping the renderer's CPU inversion under the device renderer was
rejected: the backend choice should mean what it says, and the exact
device path costs nothing in honesty.

## Consequences

All three device value stages exist — window, composite, invert —
and device renders of inverted, composited, calibrated scenes carry
per-stage device claims throughout.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Pre-release signature revisions of `MetalSliceRenderer` and the
internal pipeline; no released caller exists.

## Security impact

Unchanged budgets and disciplines.

## Performance and memory impact

One device dispatch per inverted layer on the device path.

## Validation impact

Tests must render an inverted scene fully on the device producing
exactly the inverted registered fixture, and verify the stage record
carries the metal implementation token, the exact precision policy
and status, and the invert kernel reference.

## Migration

Implemented in this increment.

## Supersession

Completes the `ADR-0132` family with its operation and the
`ADR-0099` device path with its third stage; no record is superseded.

## References

- [ADR-0132 - Device invert kernel](ADR-0132-device-invert-kernel.md)
- [ADR-0099 - Fully-device renderer path](ADR-0099-fully-device-renderer-path.md)
