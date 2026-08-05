---
document_id: "ADR-0104"
title: "Backend policy planning"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CCH-001"
  - "VOX-CCH-002"
  - "VOX-CCH-003"
---

# ADR-0104 - Backend policy planning

## Context

The M3 baseline row sweep found `VOX-CCH-001` through `VOX-CCH-003`
undelivered: hosts choose a renderer by naming a concrete type, with
no policy vocabulary and no planner. Both backends now exist with
measured validation evidence, so policy-driven selection is
executable. This record was authored and accepted on 2026-08-05 under
the project owner's recorded broadened autonomous delegation.

## Decision

1. **The closed policy vocabulary.** `VoxeliaMetal` gains
   `BackendPolicy` — `reference`, `cpuPreferred`, `gpuPreferred` and
   `automatic`, exactly the `VOX-CCH-002` set — with no device
   generation or model anywhere in the surface per `VOX-PLT-013`.
2. **The planner and its evidence.** `MetalRendererPlanner.plan`
   returns a `RendererPlan` carrying the constructed renderer, the
   policy, and the closed `RendererBackendSelection` — `exactCPU` or
   `device` — so the selection is always reported, never silent:
   the plan is the report. Version-one rules: `reference` and
   `cpuPreferred` select the exact CPU pipeline — the registered
   binary64 reference; `gpuPreferred` and `automatic` select the
   device pipeline when the context and both kernels acquire, and
   otherwise report the exact CPU selection. The version-one
   `gpuPreferred` and `automatic` rules coincide, recorded honestly:
   `automatic` may later weigh the `VOX-CCH-001` factors — locality,
   latency, memory cost — through its own revisions, while
   `gpuPreferred` stays a host preference.
3. **Validated implementations only.** Every selectable
   implementation carries measured validation evidence — the CPU
   reference by registration and the device path by its recorded
   differentials — so the `VOX-CCH-003` fail-closed rule holds by
   construction: the planner has no unvalidated implementation to
   reach, and future backends join only with their own recorded
   evidence.

## Alternatives considered

A per-operation plan surface was rejected for version one: the
renderer is the composed unit hosts consume, and per-stage policies
without a consumer are speculation. Failing `gpuPreferred` on a
deviceless host was rejected: preference is not requirement, the
fallback is validated, and the plan reports it.

## Consequences

Hosts request policy instead of naming backends, and every selection
is evidence-carrying; `VOX-CCH-001` through `VOX-CCH-003` are
discharged for the version-one pipeline.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

None beyond existing disciplines.

## Performance and memory impact

Kernel compilation on device-selecting plans; nothing at render time.

## Validation impact

Tests must plan every policy, verify the reported selection matches
the version-one rules on this device-bearing host, render the
registered fixture through a policy-selected renderer for both
backends, and prove the plan reports policy and selection.

## Migration

Implemented in this increment.

## Supersession

Discharges the `VOX-CCH` M3 rows for the version-one pipeline; no
record is superseded.

## References

- [ADR-0099 - Fully-device renderer path](ADR-0099-fully-device-renderer-path.md)
- [ADR-0092 - GPU slice presentation path](ADR-0092-gpu-slice-presentation-path.md)
