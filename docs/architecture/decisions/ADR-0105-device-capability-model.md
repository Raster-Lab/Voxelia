---
document_id: "ADR-0105"
title: "Device capability model"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-002"
  - "VOX-MTL-003"
  - "VOX-PLT-014"
---

# ADR-0105 - Device capability model

## Context

`VOX-MTL-002` requires an internal device-capability model covering
memory model, sparse-resource support, ray-tracing support, texture
limits and recommended concurrency; the `ADR-0079` context detected
only the family capability class and unified memory. This record was
authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

`MetalExecutionContext` gains the detected `MetalDeviceCapabilities`
value:

1. **Detection only, semantic surface only.** Unified memory,
   sparse-texture support and ray-tracing support come from platform
   capability queries; the maximum threadgroup width and the
   recommended maximum working-set byte count come from the device's
   own reported limits. Family checks stay module-internal per
   `VOX-MTL-003` — the public members are semantic booleans and
   limits, never Metal numbering.
2. **A documented limit, recorded as such.** The maximum
   two-dimensional texture dimension is the documented platform
   contract for the admitted family — 16,384 — a documented-contract
   reliance like the atomic-write reliance of `ADR-0075`, because no
   runtime query reports it; a future platform query would replace
   the documented value through a revision here.
3. **Evidence, not policy.** The model selects nothing by itself;
   residency, planning and future sparse or ray-tracing work consume
   it as recorded evidence through their own decisions.

## Alternatives considered

Exposing family numbering was rejected by `VOX-MTL-003`. Guessing
texture limits from probing allocations was rejected: the documented
contract is the honest source, and probing proves only one
allocation. Waiting for sparse and ray-tracing consumers was
rejected: the row asks for the model, and detection-only members
carry no policy risk.

## Consequences

`VOX-MTL-002` is discharged for the version-one model; sparse and
ray-tracing consumers gain their gate evidence.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

No device names or models are exposed; the surface is capability
evidence only.

## Performance and memory impact

Constant-time detection at context acquisition.

## Validation impact

Tests must read the model on the real device, assert the documented
texture limit and positive reported limits, record the detected
sparse and ray-tracing booleans as printed evidence without asserting
device-dependent values, and prove the model participates in the
context's Sendable surface.

## Migration

Implemented in this increment.

## Supersession

Extends `ADR-0079`; no record is superseded.

## References

- [ADR-0079 - Metal execution context boundary](ADR-0079-metal-execution-context-boundary.md)
