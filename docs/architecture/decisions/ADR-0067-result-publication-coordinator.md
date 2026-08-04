---
document_id: "ADR-0067"
title: "Result publication coordinator"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-EXE-006"
  - "VOX-META-004"
  - "VOX-CCH-004"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0067 - Result publication coordinator

## Context

Accepted `ADR-0038` defines publication as Execution's single
linearisation point that makes output, data identity, completed
provenance and authorised cache aliases visible, staged by a
coordinator that asks each owner to validate its boundary and
publishes the coherent bundle atomically. Every boundary it needs now
exists: the validated `ImageData` bundle, graph admission in both
modes, the budgeted read coordinator, the content-tier cache and real
operations producing bundles. This record was authored and accepted on
2026-08-04 under the project owner's recorded autonomous delegation,
following the owner's explicit instruction to build the publication
coordinator.

## Decision

`VoxeliaExecution` gains the actor-isolated `PublicationCoordinator`:

1. **Explicit configuration.** The initializer requires an inclusive
   published-object ceiling, a full `ProvenanceGraphLimits` profile, a
   `StorageReadCoordinator` for verification reads and an optional
   `ContentResultCache`; there are no permissive defaults.
2. **Content-claim verification.** A bundle whose identity carries a
   sample-bytes content claim has that claim verified before
   publication: the full region is read through the budgeted
   coordinator, the retention released once the owned bytes are
   staged, and the digest compared timing-safe; a mismatch is a typed
   rejection. Claims in other registered scopes pass through as
   claims — verification confers content-tier assurance only for the
   bytes actually read.
3. **Single linearisation point.** All verification runs before the
   critical section; the identifier-reuse checks, the ceiling, the
   ancestry-closure walk over the published registry, the graph
   admission and the registry mutation then execute in one
   non-suspending actor section, so reentrant publishes cannot
   interleave the decision and the mutation. Reuse of a published
   object or provenance identifier is a typed rejection even for an
   equal value — enrichment publishes a new immutable record and
   identifier, never an update — and exhaustion of the ceiling is a
   typed transactional failure that evicts nothing.
4. **Graph coherence.** The new record's ancestry closure — walked
   through the published registry over both parent-reference cases —
   plus the record itself is admitted with the accepted `ADR-0062`
   admission under the caller's explicit mode policy; every admission
   rule (subject binding, cycle, depth, external-claim verification,
   compact retention and consistency) therefore guards publication,
   and an unpublished local parent is exactly an unresolved parent.
5. **Authorised cache alias.** After successful publication, a
   configured cache receives the verified bytes under the verified
   claim as a best-effort alias: an alias failure never unwinds a
   completed publication and is reported honestly in the receipt.
6. **Receipt.** Publication returns the resulting graph authority,
   the resolved ancestry depth, whether the content claim was
   verified and whether the alias was cached — evidence, not
   authority.

## Alternatives considered

Verifying inside the critical section was rejected: reads suspend, and
a suspending critical section breaks the linearisation guarantee.
Idempotent same-value republication was rejected by the accepted
graph-owner rule. Failing publication on a full cache was rejected:
the alias is not part of the bundle's validity. Whole-registry
re-admission on every publish was rejected as quadratic; the ancestry
closure of the new record is the exact subgraph the new edge can
affect.

## Consequences

Operation outputs become visible through one governed, verified,
graph-coherent, budgeted linearisation point, and verified bytes reach
the content-tier cache under their registered identity.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Purely additive public surface.

## Security impact

Content claims are verified timing-safe against actually read bytes
under the read budget; identifier reuse is structurally rejected; the
registry is append-only with a hard ceiling; retention and deletion
governance remain deferred; errors stay payload-free.

## Performance and memory impact

One budgeted full read and one digest pass per sample-bytes claim; the
closure walk and admission are linear in the published ancestry;
registry state is bounded by the explicit ceiling.

## Validation impact

Tests must publish a real origin bundle and a real operation output
end to end — receipts reporting complete authority, correct depth,
verification and cache alias, with the cached bytes retrievable under
the claim — then prove typed rejection of: a corrupted content claim,
an unpublished local parent, object and provenance identifier reuse,
ceiling exhaustion and an insufficient verification budget, plus the
honest uncached receipt when no cache is configured.

## Migration

Implemented in this increment.

## Supersession

This ADR implements the `ADR-0038` publication contract and
supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0062 - External provenance reference and compact graph admission](ADR-0062-external-reference-and-compact-graphs.md)
- [ADR-0063 - Image data aggregate](ADR-0063-image-data-aggregate.md)
