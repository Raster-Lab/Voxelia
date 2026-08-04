---
document_id: "ADR-0081"
title: "Metal residency strategy"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PLT-014"
  - "VOX-REP-008"
  - "VOX-EXE-002"
  - "VOX-ERR-001"
---

# ADR-0081 - Metal residency strategy

## Context

The M3 scope includes the shared-resource strategy, and the
`ResidencyPolicy` vocabulary has existed since M0 as declared intent
with no fulfilment contract. The context boundary (`ADR-0079`) now
evidences unified memory, so policy fulfilment can be decided through
capability detection rather than assumption. This record was authored
and accepted on 2026-08-05 under the project owner's recorded
broadened autonomous delegation.

## Decision

`VoxeliaMetal` gains the residency fulfilment boundary:

1. **Closed version-one mapping.** `automatic` selects shared storage
   on a unified-memory device — the detected capability, not an
   assumed one. `shared` requires detected unified memory and is a
   typed rejection without it. `gpuOptimised` selects private device
   storage. `cpuOnly` declares that the authoritative resource stays
   on the CPU, so a device-buffer request under it is a contradiction
   and its own typed rejection, never a silent shared fallback.
   `streamed` and `sparse` stay typed rejections: bounded working-set
   streaming and sparse residency each need their own contract with
   its own evidence.
2. **Fulfilment evidence.** Selection returns a closed value naming
   the selected storage class; buffer allocation validates a positive
   byte count, surfaces allocation failure typed, and returns handles
   that stay module-internal like the device itself. The suite
   exercises real device buffers: a shared buffer round-trips CPU
   writes, and a private buffer allocates with the requested length.
3. **No policy mutation.** The manager never upgrades, downgrades or
   substitutes a policy; every unfulfillable request is a typed
   rejection so the caller's declared intent is never silently
   rewritten.

## Alternatives considered

Falling back from `shared` to managed storage on non-unified devices
was rejected: no supported Apple-silicon target lacks unified memory,
and a silent fallback would rewrite declared intent. Fulfilling
`streamed` as plain shared storage was rejected as a false claim of a
working-set contract.

## Consequences

The declared residency vocabulary gains a governed fulfilment path
with real-buffer evidence, completing the M3 shared-resource strategy
for the currently supported policies.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

No device names; capability-checked selection; typed payload-free
rejections; internal handles.

## Performance and memory impact

One allocation per request; shared storage avoids copies on unified
memory.

## Validation impact

Tests must fulfil `automatic`, `shared` and `gpuOptimised` against
real device buffers — round-tripping bytes through shared storage —
and reject `cpuOnly` device requests, `streamed`, `sparse` and a
non-positive byte count, all typed.

## Migration

Implemented in this increment.

## Supersession

This ADR gives the M0 residency vocabulary its fulfilment contract
and supersedes nothing.

## References

- [ADR-0079 - Metal execution context boundary](ADR-0079-metal-execution-context-boundary.md)
