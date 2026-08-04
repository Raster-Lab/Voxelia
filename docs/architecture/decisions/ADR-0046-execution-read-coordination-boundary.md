---
document_id: "ADR-0046"
title: "Execution read coordination boundary"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-001"
  - "VOX-API-004"
  - "VOX-EXE-002"
  - "VOX-EXE-006"
  - "VOX-ERR-001"
  - "VOX-SEC-006"
  - "VOX-VAL-007"
---

# ADR-0046 - Execution read coordination boundary

## Context

Accepted `ADR-0039`/`ADR-0041` assign work scheduling, cancellation and
budget coordination to `VoxeliaExecution`, and the storage increments
recorded the asynchronous coordinator and active-plus-retained
result-byte budget ledger as Execution-facing later work. This record
opens milestone M2 with that first slice. It was authored and accepted on
2026-08-04 under the project owner's recorded autonomous delegation
("start M2 execution layer work autonomously").

## Decision

`VoxeliaExecution` owns `StorageReadCoordinator`, an actor-isolated
budget ledger coordinating complete owned region reads:

1. **Budget ledger.** One caller-supplied inclusive checked `UInt64`
   ceiling on active-plus-retained result bytes per coordinator; no
   permissive default; a failed charge mutates nothing. Reservation is
   charged after Core transaction admission and before any provider
   invocation; failure or cancellation releases the reservation exactly
   once; successful commit converts it to a retained charge released by
   one explicit `release` of the returned retention token, with double
   release a typed `contractViolation`.
2. **Isolation rule.** Provider fill and commit run outside the actor's
   isolation; the actor holds only ledger and token state, never the
   result buffer, and invokes no provider while its synchronisation
   domain is held.
3. **Cancellation.** Task cancellation observed before provider work
   cancels the transaction, releases the reservation and throws the
   typed `cancelled` case; cancellation after commit applies to later
   work only.
4. **Deferred.** Single-flight deduplication (whose work key must bind
   authority, snapshot generation and projection per accepted
   `ADR-0037`), result caching, lazy identity computation and provenance
   capture remain later M2 increments under their recorded gates.

## Alternatives considered

Deinit-based automatic release was rejected as unverifiable ordering
under actor isolation; explicit tokens keep accounting exact. Running
providers inside the actor was rejected per the `ADR-0041` isolation
rule. Skipping governance for the coordinator was rejected; this compact
record keeps the register complete.

## Consequences

M2 gains its first coordinated, budgeted, cancellable read path; the
richer execution contracts remain explicitly gated.

## Affected modules

`VoxeliaExecution` (coordinator) over the existing
`Execution -> Storage -> Core` edges. No dependency change.

## Compatibility impact

New surface only; the coordinator names become pre-1.0 contracts.

## Security impact

Explicit inclusive budgets bound retained result memory; payload-free
`StorageContractError` cases carry no counts or provider detail.

## Performance and memory impact

Ledger operations are O(1); provider work is unchanged and runs off the
actor.

## Validation impact

Focused tests must cover reservation-before-provider (provider not
invoked on an over-budget request), release-on-failure, exact retained
accounting across concurrent reads, explicit release with double-release
rejection, and cancellation before provider work.

## Migration

Implemented in this increment; later M2 increments add single-flight,
caching, lazy identity and provenance capture under their own records.

## Supersession

This ADR supersedes no accepted decision; it implements coordination the
storage chain deferred to Execution.

## References

- [ADR-0041 - Safe storage read transaction and type-erasure lifetime boundary](ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md)
- [ADR-0042 - Storage API name, wire and limit freeze](ADR-0042-storage-api-name-wire-and-limit-freeze.md)
