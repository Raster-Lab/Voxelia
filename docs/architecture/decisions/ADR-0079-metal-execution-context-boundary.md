---
document_id: "ADR-0079"
title: "Metal execution context boundary"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PLT-001"
  - "VOX-PLT-013"
  - "VOX-PLT-014"
  - "VOX-EXE-003"
  - "VOX-ERR-001"
---

# ADR-0079 - Metal execution context boundary

## Context

Milestone M3 is the Metal and Apple Silicon foundation: Metal context,
shader identity, shared-resource strategy and the CPU-Metal
differential harness. The requirements bind the boundary before any
kernel exists: the public API must not require callers to select a
named Metal generation or commercial device model (`VOX-PLT-013`), and
device-specific behaviour must be selected through capability
detection rather than device-name checks (`VOX-PLT-014`). This record
opens M3 on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

`VoxeliaMetal` gains the Metal execution context boundary:

1. **Acquisition.** `MetalExecutionContext` acquires the system
   default device and a command queue at construction; an absent
   device or failed queue creation is a typed payload-free rejection,
   never a fallback. No API accepts or exposes a device name, model
   or named generation.
2. **Closed capability detection.** Version one detects exactly one
   capability class through the platform's family query: Metal 3
   support maps to the closed token
   `org.voxelia.capability.metal3` — the token grammar the accepted
   `ADR-0051` execution claim already carries in its optional
   `capabilityClass` field, so GPU-executed claims plug into the
   existing provenance discipline unchanged. A device without the
   baseline family is a typed rejection. Wider capability tiers
   arrive as registered extensions of the closed set.
3. **Evidence, not names.** The context exposes the capability token,
   the unified-memory flag that the shared-resource strategy needs,
   and the opaque registry identifier as runtime evidence. The
   device and queue handles stay module-internal for the kernel and
   residency increments.
4. **Concurrency stance.** The context is a final class marked
   unchecked-`Sendable` with the recorded justification that
   `MTLDevice` and `MTLCommandQueue` are documented thread-safe; the
   marking is a documented platform-contract reliance, not an
   unchecked invariant of Voxelia code.
5. **Honest host evidence.** The suite asserts real device
   acquisition and capability detection on the host: on supported
   Apple-silicon development hosts the assertions are evidence, and
   an environment without a device fails loudly rather than skipping
   silently, because a silently skipped acquisition test reads as
   passing evidence.

## Alternatives considered

Exposing the device publicly was rejected: callers would couple to
Metal types before the residency and kernel contracts exist. A
device-enumeration API was rejected as inviting device-name
selection. Treating a missing device as a soft state was rejected:
every accepted boundary fails typed.

## Consequences

M3 is open: kernels, shader identity and the differential harness can
build on a governed context whose capability story already feeds the
provenance claims.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

No device names or model strings enter any value or diagnostic; the
capability token is a closed registered value; failures stay
payload-free.

## Performance and memory impact

One device and queue acquisition per context.

## Validation impact

Tests must acquire a real context on the host, assert the Metal 3
capability token parses as a valid execution-claim capability class,
assert unified memory on Apple silicon, and record the acquisition
itself as host evidence.

## Migration

Implemented in this increment.

## Supersession

This ADR opens milestone M3 and supersedes nothing.

## References

- [ADR-0051 - Execution claim value shapes](ADR-0051-execution-claim-value-shapes.md)
- [ADR-0025 - Apple Silicon and Apple operating systems only](ADR-0025-apple-ecosystem-only.md)
