---
document_id: "ADR-0064"
title: "Exact region extraction operation"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-EXE-006"
  - "VOX-IMG-001"
  - "VOX-DAT-014"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0064 - Exact region extraction operation

## Context

The complete value chain — descriptor, verified storage, metadata,
identity, provenance and the `ImageData` aggregate — now exists with
no operation that exercises it. The first operation must be
deterministic, byte-exact and free of numeric-model decisions, so that
no algorithm specification with rounding semantics is required and the
increment's entire risk lives in the already-accepted contracts. This
record was authored and accepted on 2026-08-04 under the project
owner's recorded autonomous delegation, following the owner's explicit
instruction to build the first operation implementation.

## Decision

`VoxeliaExecution` gains the exact region extraction operation:

1. **Registration.** Operation token
   `org.voxelia.op.extract-region`, semantic operation version
   `1.0.0`; implementation token
   `org.voxelia.impl.extract-region.cpu`, implementation version
   `1.0.0`. Its semantic is a byte-exact copy of one full-rank
   half-open region of the input's canonical packed decoded bytes; no
   sample value is created, altered, rounded or interpreted, so the
   execution claim carries the frozen tokens (profile
   `org.voxelia.profile.default` 1.0.0, backend
   `org.voxelia.backend.cpu` 1.0.0, precision policy
   `org.voxelia.precision.exact`, quality policy
   `org.voxelia.quality.full`, approximation `exact`) and no
   algorithm specification is required.
2. **Frozen parameter schema.** The operation's parameters are one
   metadata collection with exactly the keys
   `org.voxelia.op.extract-region/lower-bounds` and
   `…/upper-bounds`, each an array of signed integers in axis order,
   privacy class technical; the derivation and provenance
   `parameterDigest` is the registered operation-parameters identity
   of that collection's canonical `VCMJ-1` bytes.
3. **Version-one admission.** The input descriptor must carry no
   spatial geometry and only index-only axis sampling — cropping
   under affine geometry or regular sampling shifts origins, which is
   arithmetic deferred to its own decision — each violation a typed
   rejection. Region validity, bounds and rank stay owned by the
   accepted read-transaction rules.
4. **Execution path.** The read runs through the budgeted,
   coalescing `StorageReadCoordinator`, whose retention is released
   as soon as the owned bytes are staged into a fresh owned
   contiguous provider. To enable this, `AnyImageStorage` gains the
   `ImageStorageContract` conformance it already implements member
   for member.
5. **Output assembly.** The output descriptor keeps the scalar
   format, components, semantic, axes, value transform and units with
   the region's shape; metadata passes through unchanged; the output
   identity binds the caller-minted object identifier, the
   sample-bytes content identity computed over the exact output
   bytes, no source lineage and the derivation recipe whose single
   input references the input's object identity; and the provenance
   record (caller-supplied identifier, instant and software — clock
   acquisition stays host-owned) is a transformed-kind
   operation-activity record whose subject is the output object,
   whose single input edge carries the input's object identity and a
   graph-node parent reference to the input's own provenance record.
   The returned value is a fully validated `ImageData`, so every
   coherence rule guards the operation's output.

## Alternatives considered

A windowing or arithmetic operation first was rejected: it would
require a versioned algorithm specification with rounding semantics
before any of the assembled chain could be exercised. Reading storage
directly instead of through the coordinator was rejected as bypassing
the accepted budget discipline. Dropping unsupported geometry silently
was rejected as data loss; typed rejection preserves the claim.

## Consequences

The first executable operation exists and exercises the entire
accepted chain — budgeted reads, canonical parameters, registered
digests, derivation recipes, subject-bound provenance with a real
parent edge, and aggregate validation — end to end; its outputs admit
into complete provenance graphs.

## Affected modules

`VoxeliaExecution` (the operation) and `VoxeliaCore` (the
member-for-member erasure conformance); no dependency change.

## Compatibility impact

Purely additive; the conformance adds no member.

## Security impact

No sample value is interpreted; all budgets, ceilings and typed
payload-free failures of the underlying contracts apply; the
operation mints no identifiers and acquires no clock.

## Performance and memory impact

One coordinated region read, one owned staging copy and one
content-identity hash pass, all bounded by the coordinator budget and
existing ceilings.

## Validation impact

Tests must prove a byte-exact crop end to end — output bytes,
descriptor shape, preserved metadata, the sample-bytes content
identity, the exact frozen parameter digest reproduced independently,
the derivation recipe and the provenance record with its parent edge
— then admit both records into a complete graph, prove determinism
across repeated execution, and reject unsupported geometry, regular
sampling, invalid regions and an insufficient read budget, all typed.

## Migration

Implemented in this increment.

## Supersession

This ADR registers the first operation and supersedes nothing.

## References

- [ADR-0055 - Derivation identity record](ADR-0055-derivation-identity-record.md)
- [ADR-0058 - Provenance record aggregate](ADR-0058-provenance-record-aggregate.md)
- [ADR-0063 - Image data aggregate](ADR-0063-image-data-aggregate.md)
