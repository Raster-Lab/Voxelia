---
document_id: "ADR-0063"
title: "Image data aggregate"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-IMG-001"
  - "VOX-DAT-014"
  - "VOX-META-004"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0063 - Image data aggregate

## Context

The CDMS section 37 `ImageData` sketch places a storage-erased value
beside the Core-owned descriptor, metadata, provenance and identity
values, with a validation list but no closed rules. Accepted
`ADR-0039` selected the ownership direction that lets Core hold
`AnyImageStorage`, and every other dependency is now an accepted
validated value (`ImageDescriptor`, `MetadataCollection`,
`DataIdentity`, `ProvenanceRecord`). This record was authored and
accepted on 2026-08-04 under the project owner's recorded autonomous
delegation, following the owner's explicit instruction to build
`ImageData`; `CCR-0025` records the controlled correction.

## Decision

`VoxeliaCore` gains the closed `ImageData` aggregate: the five
controlled fields (`descriptor`, `storage`, `metadata`, `provenance`,
`identity`), immutable, validated at construction:

1. **Descriptor-storage coherence.** The descriptor's shape, scalar
   type and component count must equal the storage snapshot's admitted
   logical binding, each mismatch its own typed rejection. The
   snapshot's representation must be decoded-strided — an opaque
   representation cannot supply logical samples and is a typed
   rejection — and its byte order must equal the descriptor's scalar
   byte order.
2. **Provenance-identity coherence.** The record's subject must be
   exactly the object reference of the aggregate's own `DataIdentity`;
   an origin-activity record additionally requires the identity to
   carry no derivation recipe and at least one source identity, since
   an acquired origin has source lineage and no recipe.
3. **Metadata uniqueness.** Within the aggregate, repeated metadata
   keys are a typed rejection: an image's own metadata record is
   unique-keyed, and repeat-bearing collections belong to contexts
   with explicit multiplicity policies.
4. **No reference equality.** The aggregate conforms to `Sendable`
   only. `Equatable`/`Hashable` are deliberately absent: storage is a
   reference-holding erasure, and blanket equality would either compare
   references or force byte reads. Comparison composes explicitly from
   the exposed claims — object identity, content claims, source
   lineage, descriptor and provenance — each already exact.
5. **No wire, no publication authority.** The aggregate has no
   `Codable`; persistence composes the accepted canonical projections.
   Construction validates a bundle that already exists; the atomic
   staging and publication coordinator that produces such bundles from
   live execution remains an Execution/host decision per `ADR-0038`,
   as does lazy identity enrichment.

## Alternatives considered

Optional provenance was rejected: the controlled sketch requires the
record, and a published image without asserted history is exactly the
invalid state the provenance chain exists to prevent. Admitting opaque
representations was rejected because the aggregate asserts logical
samples the representation cannot serve. Blanket value equality was
rejected by the controlled equality rule. Widening the subject rule to
content or source references was rejected for version one: the object
reference is the local-record form, and widening is a compatible
future correction.

## Consequences

The M1 centrepiece aggregate exists: descriptor, verified storage
binding, unique-keyed metadata, claim-bearing identity and
subject-bound provenance travel as one validated immutable value.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface.

## Security impact

Every field is an already-validated bounded value; cross-checks are
exact comparisons of admitted claims; typed rejections stay
payload-free; construction grants no verification, trust or cache
authority.

## Performance and memory impact

Validation is a fixed set of exact comparisons plus one linear
unique-key pass; no storage bytes are read.

## Validation impact

Tests must prove a coherent aggregate constructs against a real owned
contiguous provider, and reject: each descriptor-storage mismatch
(shape, scalar type, component count, byte order), an opaque
representation, a mismatched provenance subject, an origin with a
derivation recipe, an origin without source lineage, and a repeated
metadata key, all payload-free.

## Migration

Implemented in this increment.

## Supersession

This ADR closes the CDMS section 37 target and supersedes nothing.

## References

- [ADR-0039 - Closed storage capability and descriptor admission boundary](ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md)
- [ADR-0056 - Data identity aggregate](ADR-0056-data-identity-aggregate.md)
- [ADR-0058 - Provenance record aggregate](ADR-0058-provenance-record-aggregate.md)
- [CCR-0025 - Controlled correction for ADR-0063](../corrections/CCR-0025-adr-0063-image-data-aggregate.md)
