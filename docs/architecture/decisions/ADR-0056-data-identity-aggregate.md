---
document_id: "ADR-0056"
title: "Data identity aggregate"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DAT-014"
  - "VOX-RGN-007"
  - "VOX-RGN-008"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0056 - Data identity aggregate

## Context

Accepted `ADR-0037` froze the closed `DataIdentity` state model —
`objectID` always required, all eight content/source/derivation
combinations structurally valid except the object-only state — and
gated the aggregate behind prerequisites that are now discharged:
`DataObjectID` persistent identity (`ADR-0044`), the source identity
profile and reference wire (`ADR-0053`), and the registered
projections (`ADR-0049`, `ADR-0054`) with the derivation record
(`ADR-0055`). This record was authored and accepted on 2026-08-04
under the project owner's recorded autonomous delegation; `CCR-0022`
records the controlled correction.

## Decision

`VoxeliaCore` gains the closed `DataIdentity` aggregate:

1. **Shape.** The four controlled fields: required `DataObjectID`,
   optional top-level `ContentID` claim, ordered
   `SourceIdentity` array and optional `DerivationIdentity`.
2. **State model.** Construction rejects exactly the object-only
   state (no content claim, empty sources, no derivation) with a typed
   error; every other combination is structurally valid, and validity
   implies no verification, trust, determinism or cache assurance.
3. **Source rules.** Within one aggregate, an exact repeated source
   record and a repeated locator tuple carrying a different content
   claim are both typed rejections — never silent deduplication or
   last-write-wins — detected through the exact accepted UTF-8 locator
   key without normalisation. Accepted source order is preserved and
   participates in identity as lineage record order only.
4. **Content claim domain.** The top-level content claim must not
   carry the operation-parameters projection, which identifies an
   operation's parameters and never an object's own content; source
   and top-level content scopes may otherwise differ and are never
   compared or substituted.
5. **No wire, no ceiling yet.** The stable coding and the
   source-count ceiling belong to the future canonical data-identity
   projection decision; equality and hashing compose the exact
   member identities already accepted.

## Alternatives considered

Admitting the object-only state was rejected by the accepted
controlled lineage rule. Silent source deduplication was rejected by
`ADR-0037` rule 4. Restricting the top-level claim to one scope was
rejected: metadata records and decoded sample payloads legitimately
carry different registered scopes, and `descriptorAndSamples` remains
unregistered.

## Consequences

The claim-bearing identity chain selected by `ADR-0037` is complete as
values: `DataIdentity` can now describe origin and derived objects,
and the provenance record's subject and graph decisions can proceed.
The structural `ImageData` aggregate remains blocked only by the
provenance record.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface; no wire exists yet.

## Security impact

Typed payload-free rejections; no normalisation of locator text; the
aggregate encodes claims only and no trust, cache or verification
Boolean can be stored.

## Performance and memory impact

Duplicate detection is one linear pass with an exact-byte keyed table;
values compose existing immutable records.

## Validation impact

Tests must prove all eight state combinations with only the
object-only state rejected, exact-repeat and conflicting-claim source
rejection without normalisation, byte-distinct locators admitted as
distinct, source order participating in identity, the
operation-parameters top-level claim rejected typed, distinct source
and top-level scopes admitted, and payload-free diagnostics.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0037` aggregate deferral and supersedes
nothing.

## References

- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0053 - Source identity profile and data identity reference](ADR-0053-source-identity-and-data-identity-reference.md)
- [ADR-0055 - Derivation identity record](ADR-0055-derivation-identity-record.md)
- [CCR-0022 - Controlled correction for ADR-0056](../corrections/CCR-0022-adr-0056-data-identity-aggregate.md)
