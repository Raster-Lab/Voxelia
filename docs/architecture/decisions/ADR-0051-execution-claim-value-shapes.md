---
document_id: "ADR-0051"
title: "Execution claim value shapes"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-003"
  - "VOX-EXE-011"
  - "VOX-EXE-012"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0051 - Execution claim value shapes

## Context

Accepted `ADR-0038` interprets Core provenance ownership as immutable
backend-neutral claim values and requires the execution claim's final
declaration to carry at least the profile and profile version, backend
and implementation version, precision policy, quality policy,
approximation status, capability class when relevant and kernel
identity when relevant — with no live Execution, Storage or Validation
object ever stored in a Core value. The named descriptor types were
never declared in any controlled document, so no baseline correction is
required to declare them. This record was authored and accepted on
2026-08-04 under the project owner's recorded autonomous delegation.

## Decision

`VoxeliaCore` gains the closed execution claim value shapes:

1. **`ExecutionClaimToken`.** One bounded nominal token type with the
   lowercase ASCII reverse-domain grammar and the byte-limit-before-
   grammar precedence selected by `ADR-0036` for projection identifiers
   (inclusive 255-byte total and 63-byte label ceilings, at least two
   labels), with exact-byte equality and hashing. It is descriptive,
   never executable and never a registry lookup.
2. **`ExecutionComponentReference`.** One token plus one exact
   `SemanticVersion` whose build metadata must be absent, because build
   metadata does not participate in `SemanticVersion` equality and an
   output-affecting claim field must be identity-bearing; violation is
   a typed error. The claim record's field names assign the roles.
3. **`ExecutionApproximationStatus`.** A closed frozen enum with
   exactly the cases `exact` and `approximate`; any extension requires
   its own decision record.
4. **`ExecutionProvenanceClaim`.** The immutable record binding the
   required profile and backend component references, required
   precision-policy and quality-policy tokens, the required
   approximation status, and optional capability-class token and kernel
   component reference. All fields participate in equality and hashing.
5. **No wire.** The stable coding of every shape in this record is
   owned by the future canonical provenance-record projection decision;
   no `Codable` conformance is declared here, so no ad-hoc
   non-canonical encoding can leak into persistence.

## Alternatives considered

Distinct nominal wrapper types per role (profile, backend, kernel) were
rejected as triplicated authority without a distinct rule; the record's
field names carry the roles. Free-form policy strings were rejected in
favour of the bounded namespaced token grammar. Reusing
`ContentProjectionReference` was rejected because its authority is
digest-preimage registration. Admitting build metadata in claim
versions was rejected as an equality hole.

## Consequences

The `ADR-0038` provenance-record target gains its execution claim leg
as validated immutable Core values; Execution can project live state
into claims without Core importing Execution.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface in `VoxeliaCore`; no wire exists yet, so
no persisted compatibility surface is created.

## Security impact

Tokens are bounded validated ASCII with payload-free typed rejection;
no live object, path, device handle or free text enters a claim;
diagnostics never disclose rejected token text.

## Performance and memory impact

Validation is one bounded byte scan per token; values are small
immutable records.

## Validation impact

Tests must prove the token ceilings precede grammar, valid and invalid
tokens classify exactly, build-metadata versions are rejected typed,
every field participates in claim identity, optional fields admit
absence and errors stay payload-free.

## Migration

Implemented in this increment.

## Supersession

This ADR implements the execution claim prerequisite of accepted
`ADR-0038` and supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
