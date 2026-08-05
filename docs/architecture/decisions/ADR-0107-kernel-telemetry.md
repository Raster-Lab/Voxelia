---
document_id: "ADR-0107"
title: "Kernel dispatch telemetry"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-015"
  - "VOX-ERR-001"
---

# ADR-0107 - Kernel dispatch telemetry

## Context

`VOX-MTL-015` asks the backend to record kernel time, command-buffer
latency, upload time, frame time and residency changes; nothing was
measured. The platform reports GPU and scheduling timestamps on every
completed command buffer, so kernel time and command-buffer latency
are measurable today, while upload time (no blit path exists under
shared storage), frame time (no frame architecture exists) and
residency changes (no runtime transitions exist) have no subjects
yet. This record was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

1. **A host-owned sink.** Both kernel families take an explicit
   optional `MetalTelemetrySink` at construction — absence stated
   explicitly, matching the accepted optional-member style — and
   invoke it after every completed dispatch with one
   `MetalDispatchTelemetry` value: kernel token, entry point, sample
   count, the measured GPU seconds and the measured command-buffer
   latency seconds. The timestamps are the platform's own measured
   values from the completed command buffer — Voxelia values still
   mint no clock; measurement flows to the host, which owns
   recording.
2. **Partial discharge, recorded.** Kernel time and command-buffer
   latency are delivered and measured; upload time, frame time and
   residency-change telemetry remain open with their reasons — each
   gains its subject with its own future architecture, and inventing
   numbers for absent subjects would be fabricated evidence.

## Alternatives considered

Returning telemetry from the mapping calls was rejected: it would
entangle every caller with a priority-one concern. Storing
last-dispatch telemetry on the kernel was rejected: mutable shared
state for a host concern the sink already serves. Logging telemetry
inside Voxelia was rejected: the host owns recording policy.

## Consequences

`VOX-MTL-015` is discharged for every currently existing subject with
real measured values on this device.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Pre-release explicit-parameter addition to both kernel initialisers;
no released caller exists.

## Security impact

Telemetry carries token spellings, counts and durations only.

## Performance and memory impact

One value construction and closure call per dispatch when a sink is
installed; nothing otherwise.

## Validation impact

Tests must install a sink, dispatch on the real device, and verify
one telemetry value per dispatch carrying the kernel token, entry
point, exact sample count and non-negative measured durations,
printed as single-device evidence.

## Migration

Implemented in this increment.

## Supersession

Discharges the measurable subjects of `VOX-MTL-015`; no record is
superseded.

## References

- [ADR-0106 - Pipeline state caching](ADR-0106-pipeline-state-caching.md)
- [ADR-0080 - Window-level Metal kernel](ADR-0080-window-level-metal-kernel.md)
