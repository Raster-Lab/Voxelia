---
document_id: "ADR-0057"
title: "Provenance claim leaf shapes"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-META-003"
  - "VOX-META-005"
  - "VOX-META-007"
  - "VOX-ERR-001"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
---

# ADR-0057 - Provenance claim leaf shapes

## Context

Accepted `ADR-0038` closed the provenance record target but left the
software, operation, input-role, parent-reference and validation
shapes unresolved; the CDMS sections 36.3 through 36.6 display them as
open bags of arbitrary strings. The prerequisites those shapes need
are now accepted: bounded persistent identifiers (`ADR-0044`), the
execution claim (`ADR-0051`), the warning schema (`ADR-0052`), the
identity reference (`ADR-0053`) and the registered parameter
projection with the derivation token vocabulary (`ADR-0054`,
`ADR-0055`). This record was authored and accepted on 2026-08-04 under
the project owner's recorded autonomous delegation; `CCR-0023` records
the controlled corrections.

## Decision

`VoxeliaCore` gains the closed provenance claim leaves:

1. **`SoftwareIdentity`.** A bounded non-blank `name` plus exact
   `SemanticVersion` and optional bounded `commit` and
   `buildIdentifier`, each string field validated with the accepted
   identity field profile (255-byte inclusive ceiling before content
   rules, control-scalar rejection, frozen blank oracle) and compared
   as exact accepted UTF-8; the version compares exactly including
   build metadata.
2. **`OperationProvenance`.** The asserted operation of one completed
   run: `DerivationOperationToken` operation and implementation
   identifiers — the same semantic-operation naming domain as the
   derivation record, so reuse is principled — with exact operation
   and implementation versions (build metadata compared), and a
   `parameterDigest` constrained to the registered
   operation-parameters tuple. Unlike the derivation recipe, the
   implementation is required: a completed run always ran something.
3. **`ProvenanceInputRole` and `ProvenanceInput`.** A bounded single
   lowercase label role with exact-byte identity; an input binds one
   role, one checked occurrence ordinal of at least one, one
   `DataIdentityReference` and an optional parent reference.
4. **`ProvenanceParentReference`.** Version one holds exactly the
   `graphNode(ProvenanceID)` case. The external-record case is
   deferred honestly: it requires a registered provenance-record
   digest projection, which does not exist and must not be improvised
   from the metadata-record projection.
5. **`ProvenanceValidationClaim`.** The corrected validation claim:
   `unknown`, `experimental`, `preview`, `validated` and
   `diagnosticReady` carrying a bounded `ValidationEvidenceID`, and a
   payload-free `deprecated` — the displayed free-text reason is
   removed, deprecation context belonging to governed warning codes. A
   decoded case is a claim referring to separately governed evidence;
   no ordering exists between cases.
6. **No wire.** The stable coding of every leaf is owned by the
   future canonical provenance-record projection decision.

## Alternatives considered

Free-text software names without a profile were rejected as a
disclosure channel. A fresh operation token type was rejected because
the semantic-operation naming domain is shared with the accepted
derivation record — reuse within one domain is not the cross-domain
blurring `ADR-0055` rejected. Declaring the external parent-record
case with an improvised digest was rejected as a domain confusion.
Keeping `deprecated(reason: String)` was rejected: free text is
structurally banned from Core claims.

## Consequences

Every leaf named by the `ADR-0038` record target now exists as a
validated value; the record aggregate and its structural rules are the
only remaining provenance decision before graph admission.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface; no wire exists yet.

## Security impact

Bounded validated fields, no control scalars, no free text, exact-byte
identity, payload-free typed rejections and evidence references that
confer no evidence authority.

## Performance and memory impact

One bounded scan per field; values are small immutable records.

## Validation impact

Tests must prove the field profile with limit precedence, the role
grammar, the zero-occurrence rejection, the foreign parameter-digest
rejection, build-metadata-exact software and operation comparison,
evidence identifiers participating exactly in claim identity and
payload-free diagnostics.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0038` leaf-shape deferrals and supersedes
nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0051 - Execution claim value shapes](ADR-0051-execution-claim-value-shapes.md)
- [ADR-0055 - Derivation identity record](ADR-0055-derivation-identity-record.md)
- [CCR-0023 - Controlled correction for ADR-0057](../corrections/CCR-0023-adr-0057-provenance-claim-leaves.md)
