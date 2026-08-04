---
document_id: "ADR-0072"
title: "Canonical derivation record projection"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CON-006"
  - "VOX-API-004"
  - "VOX-DAT-014"
  - "VOX-CCH-004"
  - "VOX-ERR-001"
---

# ADR-0072 - Canonical derivation record projection

## Context

Accepted `ADR-0037` and `ADR-0053` deferred the `derivation` case of
`DataIdentityReference` until `DerivationRecordID` and its registered
canonical projection existed. Every field of the accepted
`DerivationIdentity` already has a canonical member form under the
`VCPJ-1` rules, so the derivation projection is a fixed-schema reuse
of accepted decisions rather than a new codec design. This record was
authored and accepted on 2026-08-04 under the project owner's recorded
overnight autonomous delegation.

## Decision

1. **`VCDJ-1` profile.** One UTF-8 JSON envelope with `documentSchema`
   (`org.voxelia.derivation-record`, numeric major 1, minor 0) and
   `payload`, members in ascending UTF-8 byte order with the shared
   RFC 8785 string-token authority, explicit nulls and the accepted
   member forms: bare grammar tokens, the `VCPJ-1` semantic-version
   form with decimal string components and exact build metadata, the
   accepted reference wire for input identities, and the accepted
   `ContentID` wire for the parameter digest. Inputs are positional
   `{"identity", "role"}` members; an empty input array is the
   canonical form of a declared zero-input generator, which is the
   only way such a record exists. The record's own identity is an
   envelope claim about the bytes, never a field inside them.
2. **Fifth tuple.** Algorithm `sha256`, scope `serialisedObject`,
   projection `org.voxelia.derivation-record` version `1.0`, framed by
   the version-one header (102 bytes); the accepted set holds exactly
   five tuples and every crossed combination stays rejected. The
   emitter enforces the 65,536-input ceiling before writing and the
   caller's output byte ceiling with the established cancellation
   cadence.
3. **`DerivationRecordID`.** A validated value wrapping one
   `recordContentID` constrained to the registered derivation tuple —
   any other tuple is a typed rejection — identifying a canonical
   derivation record content-addressably without proving determinism
   or input assurance.
4. **Reference completion.** `DataIdentityReference` gains the
   `derivation(DerivationRecordID)` case with the one-member
   `{"derivation":{"recordContentID":…}}` wire, completing the
   `ADR-0037` reference union; the `ADR-0053` strict wire and the
   `VCPJ-1` reference member widen accordingly before any release, so
   existing documents' bytes and digests are unchanged and both
   grammars stay at their registered versions.
5. **Deferral.** Strict `VCDJ-1` ingress follows the `ADR-0061`
   pattern as its own increment; until then the projection emits,
   digests and verifies.

## Alternatives considered

An opaque persistent string identifier for derivation records was
rejected: a recipe is a value, and content-addressed identity via the
registered projection is exactly the accepted claim discipline with no
new identifier lifecycle. Embedding the derivation identity inside the
reference was rejected long since as recursive.

## Consequences

Derivation recipes gain exact canonical bytes and a registered
domain-separated digest; data identities and provenance inputs can now
reference recipes by content, completing the reference union.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive; the widened reference grammars predate any release.

## Security impact

Structural domain separation via the length-prefixed frame; the record
claim is constrained to its registered tuple; bounded emission with
checked arithmetic; failures stay payload-free.

## Performance and memory impact

One linear emission pass with the bounded sink and one incremental
hash pass per record.

## Validation impact

Tests must reproduce two independently computed golden documents and
framed digests — a full record with build metadata and a declared
zero-input generator — byte for byte, prove determinism, reject the
crossed record-claim tuple, round-trip the widened reference wire, and
round-trip a provenance document whose input identity is a derivation
reference through the accepted `VCPJ-1` codec.

## Migration

Implemented in this increment.

## Supersession

This ADR completes the `ADR-0037` reference union and supersedes
nothing.

## References

- [ADR-0055 - Derivation identity record](ADR-0055-derivation-identity-record.md)
- [ADR-0060 - Canonical provenance record projection](ADR-0060-canonical-provenance-record-projection.md)
- [ADR-0053 - Source identity profile and data identity reference](ADR-0053-source-identity-and-data-identity-reference.md)
