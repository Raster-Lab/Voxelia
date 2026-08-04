---
document_id: "ADR-0050"
title: "Content-tier result cache"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-EXE-006"
  - "VOX-CON-006"
  - "VOX-SEC-011"
  - "VOX-PER-007"
---

# ADR-0050 - Content-tier result cache

## Context

Accepted `ADR-0037` orders cache admission by assurance tier and
prefers content-tier entries, whose registered digest self-certifies
the cached bytes. The `ADR-0048` increment recorded result caching as
gated on a registered bytes-scope projection, which accepted `ADR-0049`
now supplies. This record was authored and accepted on 2026-08-04 under
the project owner's recorded autonomous delegation.

## Decision

`VoxeliaExecution` gains an actor-isolated `ContentResultCache`
implementing exactly the content tier:

1. **Explicit verified admission.** The owner supplies the exact bytes
   and their registered `ContentID`; admission recomputes the digest
   under the record's own registered tuple and compares timing-safe
   before anything is published. A mismatch is a typed rejection, and
   verification runs outside the actor's isolation.
2. **Revalidating lookup.** A hit recomputes the digest of the stored
   bytes before returning them; a revalidation failure purges the entry,
   increments an evidence counter and reports a miss rather than
   returning unverified bytes.
3. **Hard explicit budgets.** The initializer requires an inclusive
   entry-count ceiling and total retained-byte ceiling with no
   permissive defaults; an admission that would exceed either is a
   typed rejection with checked arithmetic. Duplicate admission of an
   already-cached identity is an idempotent success, since the digest
   certifies identical content. Removal is explicit, and removing an
   unknown identity is a typed rejection.
4. **No other tiers, no eviction policy.** Source-tier and
   derivation-tier admission stay gated on their `ADR-0037`
   prerequisites, and no implicit eviction policy exists in version one:
   selecting one is a governed decision deferred until usage evidence
   exists.

## Alternatives considered

Implicit least-recently-used eviction was rejected as an ungoverned
retention policy hidden behind a cache API. Trusting the supplied
identity without recomputation was rejected because content-tier
assurance is exactly the verified digest. Restricting keys to the
sample-bytes tuple was rejected: both registered tuples are content
digests over exact bytes, and the record's own tuple selects the
verification frame.

## Consequences

Execution can retain and republish expensive byte results keyed by
registered content identity with exact accounting; every published byte
was digest-verified on admission and revalidated on lookup.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Purely additive public surface in `VoxeliaExecution`.

## Security impact

Admission and lookup verification use the timing-safe comparator via
`ContentID`; cached bytes are owned copies; errors stay payload-free;
digests are never rendered into diagnostics.

## Performance and memory impact

Admission and every hit pay one chunked, cancellation-checked hash pass
over the entry's bytes — the honest content-tier price. Retained memory
is bounded by the explicit byte ceiling.

## Validation impact

Tests must prove mismatched admission rejects without publishing,
verified admission and revalidating lookup round-trip the bytes, both
budget ceilings reject with unchanged state, duplicate admission is
idempotent, explicit removal frees the budget, unknown removal rejects
typed and the evidence counter stays zero across healthy operations.

## Migration

Implemented in this increment.

## Supersession

This ADR implements the content tier of accepted `ADR-0037` and
supersedes nothing.

## References

- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0049 - Sample-bytes content projection](ADR-0049-sample-bytes-content-projection.md)
