---
document_id: "ADR-0044"
title: "Persistent identifier exactness boundary"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-001"
  - "VOX-API-004"
  - "VOX-CON-001"
  - "VOX-META-003"
  - "VOX-ERR-001"
  - "VOX-SEC-006"
  - "VOX-VAL-007"
---

# ADR-0044 - Persistent identifier exactness boundary

## Context

Accepted `ADR-0037` recorded `DataObjectID`'s Swift-`String` equality and
missing byte ceiling as an explicit blocker to persistent exact reference
coding, and accepted `ADR-0038` restricted `ProvenanceID` from durable or
untrusted graph use until a bounded exact-byte identity exists. Both
leaves accept any non-blank unbounded string and compare through Swift
`String` equality, which unifies canonically equivalent Unicode spellings
with different UTF-8 bytes. This record was authored and accepted on
2026-08-04 under the project owner's recorded autonomous delegation.

## Decision

`DataObjectID` and `ProvenanceID` become exact persistent identifiers:

1. **Byte ceiling.** The raw value is at most 255 UTF-8 bytes, inclusive.
   Over-ceiling values are rejected at construction; through the existing
   shared strict decoder that rejection surfaces as the value-redacted
   concrete-type failure.
2. **Exact identity.** Equality and hashing compare the exact accepted
   UTF-8 bytes, so canonically equivalent but byte-distinct spellings are
   distinct identifiers, matching the `AnyMetadataKey` precedent.
3. **Unchanged surface.** The `init?(rawValue:)` shape, the keyed
   `{"rawValue": ...}` wire and the shared `VoxeliaStringIdentifier`
   protocol are unchanged; other identifier conformances keep their
   current semantics until their own persistence decisions.

This closes gate item 4 of the `ADR-0037` source gate for `DataObjectID`
and the corresponding `ADR-0038` prerequisite for `ProvenanceID`. It does
not by itself authorise the blocked identity or provenance aggregates,
whose remaining prerequisites stay open.

## Alternatives considered

A reverse-domain grammar was rejected as needlessly restrictive for
host-supplied object identifiers. Tightening the shared protocol was
rejected because axis and space identifiers have no persistence
requirement. Leaving the leaves unchanged was rejected because both
accepted boundaries name them as blockers.

## Consequences

Pre-1.0 source-breaking tightening: previously accepted over-ceiling or
canonically-aliased identifiers become invalid or distinct. No persisted
records exist, so no migration is required.

## Affected modules

`VoxeliaCore` owns both leaves. No dependency edge changes.

## Compatibility impact

`CCR-0018` records the controlled correction. The tightened acceptance
domain and exact identity become pre-1.0 contracts.

## Security impact

Bounded identifiers prevent unbounded token retention; exact bytes
prevent Unicode-aliasing confusion in future graph keys; the shared
decoder's redaction is unchanged.

## Performance and memory impact

Identity comparison is O(bytes) with a 255-byte bound.

## Validation impact

Focused tests must cover the 255/256-byte boundary, NFC/NFD distinctness
in equality, hashing and set behaviour, and redacted decode rejection of
over-ceiling values.

## Migration

Implemented in the same increment: leaf tightening plus focused tests.

## Supersession

This ADR supersedes no accepted decision; it discharges one prerequisite
each from `ADR-0037` and `ADR-0038`.

## References

- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
