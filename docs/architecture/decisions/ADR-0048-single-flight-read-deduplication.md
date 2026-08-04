---
document_id: "ADR-0048"
title: "Single-flight read deduplication"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-EXE-006"
  - "VOX-PER-007"
  - "VOX-ERR-001"
  - "VOX-VAL-007"
---

# ADR-0048 - Single-flight read deduplication

## Context

Accepted `ADR-0046` deferred read deduplication, and accepted `ADR-0037`
requires any work key to bind object identity, pinned snapshot
generation and projection. This record was authored and accepted on
2026-08-04 under the project owner's recorded M2 autonomous delegation.

## Decision

`StorageReadCoordinator` coalesces concurrent identical reads:

1. **Work key.** The in-process key binds the admitted authority's
   reference identity, the snapshot generation and the exact half-open
   region bounds; the fixed packed read profile is the projection. Keys
   are never persisted.
2. **Shared charge.** One shared provider execution charges its
   copy-on-write result bytes once. Every successful waiter mints its
   own retention token referencing the shared charge group; the group's
   charge is freed when its last token is released and its last waiter
   has finished, so neither early nor late releases can under- or
   over-account.
3. **Waiter conversion.** A waiter observing cancellation after shared
   completion converts charge-neutrally without cancelling shared work
   or leaking the group; a failed shared execution releases its own
   reservation exactly once and propagates the typed cause to every
   waiter. A joiner arriving after the last waiter finished starts a
   fresh execution, because earlier results are by then caller-owned.

## Alternatives considered

Charging per waiter was rejected as over-accounting copy-on-write
storage. One shared token for all waiters was rejected because the first
release would strand the others. Reference-counting inside the token was
rejected in favour of actor-confined group state with exact typed
double-release rejection.

## Consequences

Concurrent identical reads share provider work and budget exactly; the
observable single-reader semantics of `ADR-0046` are unchanged.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

The `ADR-0046` public surface is unchanged; coalescing is behaviour.

## Security impact

Budgets stay exact under concurrency; tokens remain identity-based and
unforgeable; errors stay payload-free.

## Performance and memory impact

Coalescing bounds duplicate provider work; group state is O(live
groups + live tokens).

## Validation impact

Tests must show identical concurrent reads starting strictly fewer
shared executions than waiters under a budget that could not fund one
charge per waiter, per-token release with last-release freeing, and
unchanged single-reader semantics.

## Migration

Implemented in this increment.

## Supersession

This ADR refines accepted `ADR-0046` and supersedes nothing.

## References

- [ADR-0046 - Execution read coordination boundary](ADR-0046-execution-read-coordination-boundary.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
