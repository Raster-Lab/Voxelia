---
document_id: "ADR-0110"
title: "Bounded frame contexts"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-006"
  - "VOX-ERR-001"
---

# ADR-0110 - Bounded frame contexts

## Context

`VOX-MTL-006` requires reusable frame contexts and bounded in-flight
frame counts; nothing existed, and the interactive draw loop the
frames will one day serve does not exist either. The bound and the
reuse discipline are contract-level value semantics, deliverable
without any UI. This record was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

`VoxeliaMetal` gains the `MetalFrameScheduler` actor:

1. **An explicit inclusive bound.** Construction takes the maximum
   in-flight frame count, validated at least one — no permissive
   default — and `acquireFrame` returns an identity
   `MetalFrameToken` carrying a monotonic frame index as ordering
   evidence; at the bound, acquisition is the typed
   `inFlightLimitExceeded` rejection per the budget-ledger
   precedent. Pacing — suspending until a slot frees — is the
   interactive loop's own future decision; the contract enforces the
   bound and the caller owns the cadence.
2. **Release-once reuse.** Releasing a frame returns its slot for
   reuse; releasing a foreign or already-released token is the typed
   `invalidRelease` rejection, mirroring the retention-token
   discipline — a frame slot can never be freed twice or by a token
   that never held it.
3. **Frames carry nothing yet.** The token is identity and ordering
   evidence only; per-frame resource slots arrive when a consumer
   exists, through their own decisions.

## Alternatives considered

Suspending acquisition was rejected for version one: continuation
queues encode a pacing policy no consumer has chosen, and the
explicit-ceiling precedent already models exhaustion typed. Frame
pools with preallocated resources were rejected: no resources exist
to pool.

## Consequences

`VOX-MTL-006` is discharged at the contract level; the interactive
draw-loop integration remains gated on its own architecture, and
`VOX-CON-005` stays vacuously satisfied until it exists.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

None beyond existing disciplines.

## Performance and memory impact

Constant-size actor state per scheduler.

## Validation impact

Tests must acquire to the bound, reject the over-bound acquisition
typed, release and reacquire proving slot reuse with monotonic frame
indices, and reject double and foreign releases typed.

## Migration

Implemented in this increment.

## Supersession

Discharges the contract level of `VOX-MTL-006`; no record is
superseded.

## References

- [ADR-0046 - Execution read coordination boundary](ADR-0046-execution-read-coordination-boundary.md)
- [ADR-0081 - Metal residency strategy](ADR-0081-metal-residency-strategy.md)
