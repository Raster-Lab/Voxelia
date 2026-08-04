---
document_id: "ADR-0054"
title: "Operation-parameters content projection"
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
---

# ADR-0054 - Operation-parameters content projection

## Context

Accepted `ADR-0037` requires the future derivation record's
`parameterDigest` to use a registered, versioned canonical parameter
projection binding every output-affecting semantic parameter, and
explicitly rejects reuse of the `org.voxelia.metadata-complete-record`
projection for that digest because it identifies a different domain.
Accepted `ADR-0036` requires every new tuple to arrive through its own
governed registration. This record was authored and accepted on
2026-08-04 under the project owner's recorded autonomous delegation.

## Decision

A third compiled content-identity tuple is registered:

1. **Tuple.** Algorithm `sha256`, scope `serialisedObject`, projection
   `org.voxelia.operation-parameters` version `1.0`. The compiled
   accepted set now holds exactly three tuples; every other
   scope/projection combination stays rejected as an unsupported
   projection.
2. **Preimage.** The payload is the exact complete accepted `VCMJ-1`
   document bytes of one parameter `MetadataCollection`: an operation's
   output-affecting semantic parameters expressed as metadata entries
   and emitted or accepted by the dedicated canonical codec. The frame
   is the same `VOXELIA-CONTENT-ID` version-one shape; the
   length-prefixed scope and projection members make the header 105
   bytes, so the preimage can never collide with the complete metadata
   record or the sample-bytes projection by construction.
3. **Semantics.** The digest identifies exactly the canonical
   parameter document. It does not prove parameter completeness — the
   owning operation contract decides which parameters are
   output-affecting — nor determinism, and it is not by itself a cache
   key.

## Alternatives considered

A bespoke parameter serialisation was rejected: the accepted `VCMJ-1`
codec already provides canonical bytes for bounded metadata documents,
and reusing it keeps one canonical-JSON authority. Reusing the
complete-record projection was rejected by `ADR-0037` as a domain
confusion. Registering a derivation-record projection at the same time
was rejected: the derivation record's shape arrives in its own
decision, and its projection must follow the frozen shape.

## Consequences

The `ADR-0037` derivation prerequisite "registered parameter
projection" is discharged; the future `DerivationIdentity` can bind
its `parameterDigest` to a registered domain-separated tuple.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

The `ContentID` wire is unchanged; records carrying the new tuple
become decodable, and the existing tuples' digests are unaffected.

## Security impact

Domain separation between all three registered preimages is structural
via the length-prefixed frame members; digest bytes remain
sensitive-derived equality oracles; errors stay payload-free.

## Performance and memory impact

One incremental hash pass with the existing bounded chunking and
cancellation cadence; no new allocation classes.

## Validation impact

Tests must reproduce an independently computed golden framed digest
over the canonical empty parameter document, pin the 105-byte header,
prove the identical payload digests differently under the two
`serialisedObject` projections, round-trip the new tuple's wire and
reject crossed tuples.

## Migration

Implemented in this increment.

## Supersession

This ADR refines accepted `ADR-0036` by registering a third compiled
tuple and supersedes nothing.

## References

- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0049 - Sample-bytes content projection](ADR-0049-sample-bytes-content-projection.md)
