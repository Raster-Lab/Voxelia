---
document_id: "ADR-0077"
title: "Retention and enrichment lifecycle"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DAT-014"
  - "VOX-RGN-007"
  - "VOX-SEC-011"
---

# ADR-0077 - Retention and enrichment lifecycle

## Context

Accepted `ADR-0037` gated lazy identity enrichment on an
identity-enrichment and `objectID` lifecycle decision, and the
accepted publication coordinator (`ADR-0067`) and document store
(`ADR-0075`) each implemented append-only behaviour whose governing
policy was recorded as deferred. This record closes both deferrals as
one governance decision. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation; `CCR-0026` records the controlled correction.

## Decision

1. **Object identifier lifecycle.** A `DataObjectID` binds to at most
   one published immutable bundle, forever. Publication is the binding
   event; the accepted coordinator already rejects reuse even for
   equal values, and deletion — wherever a future decision permits
   it — never legitimises rebinding, as `ADR-0038` and `ADR-0075`
   already froze for provenance identifiers and document names.
2. **Enrichment before publication.** Until a bundle is published,
   computing and attaching richer claims — a sample-bytes content
   identity, source lineage, a derivation recipe — is ordinary value
   construction with no lifecycle significance; the accepted
   coordinators already serve this stage.
3. **Enrichment after publication.** A published bundle is never
   enriched in place. Richer knowledge about the same bytes publishes
   a new immutable bundle under new object and provenance
   identifiers, whose identity carries the richer claims over the
   same verified content identity, and whose provenance record binds
   the relation through its input edge to the prior record. The two
   bundles share content identity — the linkage claim — while every
   identifier stays immutable.
4. **Retention.** Version-one retention is append-only across the
   published registry and the document store: nothing is evicted,
   overwritten, renamed or deleted, and exhaustion of a ceiling is a
   typed transactional failure. A future deletion or retirement
   decision must define audit obligations, must preserve the
   never-rebind rule, and remains its own governed record; nothing
   here forecloses it.
5. **Gate closure.** This discharges the `ADR-0037` source-gate item
   on enrichment and `objectID` lifecycle; no code changes, because
   the accepted implementations already behave exactly as this policy
   requires — the decision here is that they are the policy.

## Alternatives considered

In-place enrichment under a stable `objectID` was rejected: the
accepted linearisation makes identifier reuse structurally impossible,
and mutable published identity is exactly the state the claim
discipline exists to prevent. Reference-counting or lease-based
retention was rejected for version one as ungoverned complexity.

## Consequences

Lazy enrichment has a governed shape — enrich before publication, or
republish under new identifiers with content identity as the link —
and every accepted append-only behaviour is now policy rather than
deferral.

## Affected modules

None; documentation and governance only.

## Compatibility impact

None; the decision ratifies implemented behaviour.

## Security impact

Immutable bindings prevent identifier-reuse confusion; content
identity remains the only cross-bundle linkage claim and stays
sensitive-derived.

## Validation impact

The accepted coordinator and store suites already prove the
append-only and reuse-rejection behaviour this policy requires; no
new test surface exists.

## Migration

None.

## Supersession

This ADR discharges the `ADR-0037` enrichment gate item and
supersedes nothing.

## References

- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0067 - Result publication coordinator](ADR-0067-result-publication-coordinator.md)
- [ADR-0075 - Canonical document store](ADR-0075-canonical-document-store.md)
- [CCR-0026 - Controlled correction for ADR-0077](../corrections/CCR-0026-adr-0077-retention-and-enrichment.md)
