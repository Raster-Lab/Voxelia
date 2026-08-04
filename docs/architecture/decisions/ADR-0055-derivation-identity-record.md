---
document_id: "ADR-0055"
title: "Derivation identity record"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DAT-014"
  - "VOX-RGN-007"
  - "VOX-CCH-004"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0055 - Derivation identity record

## Context

Accepted `ADR-0037` deferred the displayed `DerivationIdentity` until
its corrected contract could provide a bounded exact operation
identifier and version, a separately identified implementation
version, a registered parameter projection, positional role-bearing
inputs with preserved repeats, explicit zero-input permission and
exact comparison including `SemanticVersion.buildMetadata`. Accepted
`ADR-0053` supplies the input reference and accepted `ADR-0054` the
registered parameter projection, so every prerequisite is now
discharged. This record was authored and accepted on 2026-08-04 under
the project owner's recorded autonomous delegation; `CCR-0021` records
the controlled correction.

## Decision

`VoxeliaCore` gains the closed derivation identity shapes:

1. **`DerivationOperationToken`.** One bounded nominal token with the
   lowercase ASCII reverse-domain grammar and byte-limit-before-grammar
   precedence (255/63 ceilings, at least two labels), exact-byte
   identity, naming the semantic operation or its implementation.
2. **`DerivationInputRole`.** One bounded single-label token — 1
   through 63 bytes, lowercase `a` to `z`, `0` to `9` or `-`, starting
   and ending alphanumeric — with exact-byte identity. Roles are
   operation-defined; the record does not interpret them.
3. **`DerivationInput`.** One role plus one `DataIdentityReference`.
   The input sequence is positional; accepted order and exact repeats
   are preserved and participate in identity.
4. **`DerivationImplementationReference`.** One token plus one
   `SemanticVersion` in which build metadata is admitted, because
   implementation builds may differ only there.
5. **`DerivationIdentity`.** The immutable record binding the
   operation token, exact operation version, optional implementation
   reference, positional inputs and a `parameterDigest` that must
   carry the registered `ADR-0054` operation-parameters tuple; any
   other tuple is a typed rejection. An empty input sequence is
   admitted only when the constructing site explicitly declares a
   zero-input generator, and declaring one with inputs present is
   likewise a typed rejection.
6. **Exact comparison.** Equality and hashing compare every stored
   field exactly, including `SemanticVersion.buildMetadata` through an
   explicit exact-version comparison, because ordinary semantic-version
   equality excludes build metadata.
7. **No wire, no ceiling yet.** The stable coding, the input-count
   ceiling and `DerivationRecordID` belong to the future canonical
   derivation-record projection decision; a derivation identity is a
   semantic recipe claim, not an execution cache key, and proves
   neither determinism nor input assurance.

## Alternatives considered

Reusing `ExecutionClaimToken` was rejected: its authority is execution
claims, and cross-domain token reuse would blur record provenance.
Rejecting build metadata as in `ADR-0051` was rejected here because
`ADR-0037` explicitly requires implementation builds distinguishable
only by build metadata to compare distinct. Storing the zero-input
declaration was rejected: an empty sequence is admissible exactly when
declared, so the stored flag would be derivable and a second source of
truth.

## Consequences

The `ADR-0037` derivation target becomes a real validated value; the
future `DataIdentity` aggregate and provenance activity claims can
carry derivation recipes.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface; no wire exists yet.

## Security impact

Bounded validated tokens, payload-free typed rejections, no free text,
and the parameter digest is constrained to its registered
domain-separated projection so a metadata-record or sample-bytes
digest can never masquerade as parameters.

## Performance and memory impact

Validation is one bounded byte scan per token; comparison is linear in
the input sequence.

## Validation impact

Tests must prove the token and role grammars with limit precedence,
typed rejection of foreign parameter-digest tuples, the zero-input
declaration rules in both directions, preserved repeats and order in
identity, build-metadata-distinct implementations comparing distinct
while their versions compare equal, and payload-free diagnostics.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0037` derivation deferral and supersedes
nothing.

## References

- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0053 - Source identity profile and data identity reference](ADR-0053-source-identity-and-data-identity-reference.md)
- [ADR-0054 - Operation-parameters content projection](ADR-0054-operation-parameters-content-projection.md)
- [CCR-0021 - Controlled correction for ADR-0055](../corrections/CCR-0021-adr-0055-derivation-identity.md)
