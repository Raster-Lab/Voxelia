---
document_id: "ADR-0047"
title: "Coordinated metadata identity boundary"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-001"
  - "VOX-EXE-002"
  - "VOX-EXE-006"
  - "VOX-CON-006"
  - "VOX-ERR-001"
  - "VOX-SEC-006"
  - "VOX-VAL-007"
---

# ADR-0047 - Coordinated metadata identity boundary

## Context

Accepted `ADR-0036` registered the complete canonical metadata record
projection and `ADR-0037` defined the lazy-identity state machine, whose
general form remains gated on the unresolved `DataIdentity`
prerequisites. One slice is fully unblocked: computing the framed
complete-record identity for an immutable `MetadataCollection`, whose
value is itself the pinned snapshot. This record was authored and
accepted on 2026-08-04 under the project owner's recorded M2 autonomous
delegation.

## Decision

`VoxeliaExecution` owns `MetadataIdentityCoordinator`, an actor-isolated
single-flight coordinator:

1. **Atomic pair.** One request yields the exact canonical `VCMJ-1`
   bytes and their framed `ContentID` together or nothing; no partial
   publication exists.
2. **Single flight.** Concurrent requests for the same collection value
   and output ceiling coalesce onto one shared unstructured computation;
   the work key is the immutable value plus the ceiling, satisfying the
   accepted binding rule because the value is the snapshot and the
   projection is fixed. In-process coalescing keys are never persisted.
3. **Cancellation.** A cancelled caller receives the typed cancellation
   outcome without cancelling shared work another waiter still needs;
   all-waiter cancellation propagation is a recorded later refinement
   because the underlying work is bounded by the accepted metadata
   ceilings.
4. **Deferred.** Repeat-bearing (configured-policy) identity, general
   `DataIdentity` enrichment and cache/provenance publication remain
   gated on their recorded prerequisites.

## Alternatives considered

Computing inline at every call was rejected because concurrent callers
would duplicate bounded-but-real canonical emission and hashing.
Persisting the coalescing key or exposing it was rejected per the
process-randomised-hash rule. Cancelling shared work on first caller
cancellation was rejected per the accepted waiter rule.

## Consequences

M2 gains coordinated, deduplicated, atomically published metadata
identities; the general lazy-identity machinery stays gated.

## Affected modules

`VoxeliaExecution` over the existing edges; no dependency change.

## Compatibility impact

New surface only; names become pre-1.0 contracts.

## Security impact

The identity remains sensitive-derived linkage material; the coordinator
adds no logging and returns typed payload-free failures.

## Performance and memory impact

One canonical emission plus one SHA-256 pass per distinct in-flight
request; the in-flight table drains on completion.

## Validation impact

Focused tests must cover the atomic pair against the registered golden
fixture, single-flight coalescing (one computation for concurrent
identical requests), table drainage and typed failure propagation.

## Migration

Implemented in this increment.

## Supersession

This ADR supersedes no accepted decision; it implements the unblocked
slice of `ADR-0037`'s lazy-identity machinery for metadata records.

## References

- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0046 - Execution read coordination boundary](ADR-0046-execution-read-coordination-boundary.md)
