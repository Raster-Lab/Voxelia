---
document_id: "ADR-0095"
title: "Canonical record archival"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-STO-004"
  - "VOX-CON-006"
  - "VOX-ERR-001"
---

# ADR-0095 - Canonical record archival

## Context

Both canonical record projections are usable end to end and the
`ADR-0075` document store persists verified canonical bytes, but
nothing connected a published bundle's records to durable storage —
provenance survived only in process memory. This record was authored
and accepted on 2026-08-05 under the project owner's recorded
broadened autonomous delegation.

## Decision

`VoxeliaStorage` gains `CanonicalRecordArchival`, one stateless
archival boundary:

1. **Emit then persist.** `archive` emits the bundle's provenance
   record under `VCPJ-1` and, when the bundle carries a derivation,
   the derivation record under `VCDJ-1`, computes each registered
   record identity, and persists each document through the accepted
   store — verify-before-persist, idempotent same-content re-archive,
   corruption surfaced never repaired, all inherited from `ADR-0075`.
2. **Host-supplied names, exact presence rules.** The caller owns
   both names per the `ADR-0036` digest-sensitivity rule — no digest
   ever enters the filesystem namespace — and name presence must
   match record presence exactly: a derivation without a name is the
   typed `missingDerivationName` and a name without a derivation is
   the typed `unexpectedDerivationName`, never a silent skip.
3. **Receipts are evidence.** `ArchivedRecordReceipt` reports the
   computed record identities; loading back through the store
   requires them, and the strict ingresses remain the read-side
   authority.

## Alternatives considered

Archiving inside the publication coordinator was rejected: durable
persistence policy is the host's, and coupling publication to a
filesystem would force storage on every publisher. Deriving names
from identifiers automatically was rejected: object identifiers can
exceed the name grammar, and the caller owns the mapping per
`ADR-0075`.

## Consequences

Published history becomes durable and independently verifiable: the
stored bytes round-trip through the strict ingresses to the exact
records.

## Affected modules

`VoxeliaStorage` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Inherited store discipline; two payload-free rejections; no digest
material in names.

## Performance and memory impact

One emission and one bounded atomic write per record.

## Validation impact

Tests must archive an origin bundle and a derived bundle through a
real directory, load every document back under its receipt identity
and decode it through the strict ingress to the exact original
record, prove same-content re-archive idempotent, and reject both
name-presence mismatches typed.

## Migration

Implemented in this increment.

## Supersession

Connects `ADR-0060`/`ADR-0072` projections to the `ADR-0075` store;
no record is superseded.

## References

- [ADR-0075 - Canonical document store](ADR-0075-canonical-document-store.md)
- [ADR-0060 - Canonical provenance record projection](ADR-0060-canonical-provenance-record-projection.md)
- [ADR-0072 - Canonical derivation projection](ADR-0072-canonical-derivation-projection.md)
