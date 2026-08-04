---
document_id: "ADR-0053"
title: "Source identity profile and data identity reference"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DAT-014"
  - "VOX-RGN-007"
  - "VOX-API-004"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0053 - Source identity profile and data identity reference

## Context

Accepted `ADR-0037` froze `SourceIdentity` as the four-field controlled
record but authorised no public initializer until exact byte ceilings
and an allowed-character profile arrive through a controlled
correction, and left `DataIdentityReference` as a closed logical target
whose exact tagged wire remained open. Accepted `ADR-0038` binds the
provenance record's subject and inputs to that reference, so the
provenance record cannot proceed without it. This record was authored
and accepted on 2026-08-04 under the project owner's recorded
autonomous delegation; `CCR-0020` records the controlled corrections.

## Decision

1. **Source identity field profile.** Each of `namespace`,
   `identifier` and a present `version` is validated with fixed
   byte-limit-before-content precedence: at most 255 UTF-8 bytes
   inclusive first; then rejection of any control scalar (U+0000
   through U+001F, U+007F, and U+0080 through U+009F); then rejection
   of blank text under the frozen identity whitespace oracle. Accepted
   spelling is preserved exactly — no case folding, normalisation,
   URI resolution or aliasing — so the profile admits opaque DICOM
   UIDs, URLs, paths and object-store keys without interpreting them.
2. **Exact tuple identity.** Equality and hashing compare the exact
   accepted UTF-8 bytes of the locator tuple, with an absent version
   distinct from every present version, and include the optional
   source-content claim; canonically equivalent but byte-distinct
   spellings are distinct identities. The optional `contentID` may
   carry any registered content tuple; unregistered scopes cannot
   exist as values.
3. **Closed tagged reference.** `DataIdentityReference` is declared
   with exactly the cases `object(DataObjectID)`, `content(ContentID)`
   and `source(SourceIdentity)`. The `derivation` case stays deferred
   until `DerivationRecordID` and its registered canonical projection
   exist. The reference never embeds `DataIdentity` or
   `DerivationIdentity`, so cycles and unbounded decoding are
   structurally impossible.
4. **Strict wire.** The reference encodes as exactly one tagged
   member; `SourceIdentity` encodes its exact four-field record with
   explicit nulls; `DataObjectID` and `ContentID` keep their accepted
   wires. Decoding checks the exact key sets before reading values,
   revalidates through the constructing initializers, retains only
   audited payload-free project errors and maps every other failure to
   a typed value-free rejection.
5. **Deferred aggregate rules.** Duplicate-locator rejection, source
   ordering semantics and aggregate limits bind at the `DataIdentity`
   level and stay with its own decision.

## Alternatives considered

A restrictive ASCII-only field grammar was rejected: source locators
are opaque foreign identifiers, and excluding non-ASCII spellings would
force lossy transliteration; excluding control scalars closes the
injection and rendering hazards without interpreting the text. Swift
`String` equality was rejected per the accepted exactness rule. An
untagged or positional reference wire was rejected as ambiguous under
evolution.

## Consequences

The `ADR-0037` reference target and the `ADR-0038` subject-binding
prerequisite become real validated values with a stable strict wire;
`DataIdentity` and the provenance record can now bind subjects and
inputs.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface; the new wires are strict from their
first release, so no permissive decoding ever needs deprecation.

## Security impact

Bounded fields, no control scalars, exact-byte identity, value-redacted
typed rejections and no free interpretation of locator text; a
reference is a claim and confers no resolution, trust or cache
authority.

## Performance and memory impact

Validation is one bounded scalar scan per field; values are small
immutable records.

## Validation impact

Tests must prove the ceiling precedes content rules, control and blank
rejection, byte-distinct spellings staying distinct, absent-version
distinctness, exact wire round-trips for all three cases, and typed
rejection of unknown tags, wrong member counts, malformed nested
records and over-ceiling fields.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0037` source-gate items for the
`SourceIdentity` profile and the `DataIdentityReference` wire and
supersedes nothing.

## References

- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [CCR-0020 - Controlled correction for ADR-0053](../corrections/CCR-0020-adr-0053-source-identity-and-reference.md)
