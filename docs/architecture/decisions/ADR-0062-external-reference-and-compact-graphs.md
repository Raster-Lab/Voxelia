---
document_id: "ADR-0062"
title: "External provenance reference and compact graph admission"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-META-004"
  - "VOX-META-006"
  - "VOX-META-009"
  - "VOX-CON-006"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0062 - External provenance reference and compact graph admission

## Context

Accepted `ADR-0038` conditioned the durable external parent reference
on an accepted domain-separated provenance-record projection, an exact
digest tuple, a bounded persistent `ProvenanceID` and a strict tagged
wire, and specified compact-mode admission with per-occurrence
unresolved caps and repeated-claim consistency. Every prerequisite now
exists (`ADR-0044`, `ADR-0060`, `ADR-0061`), and no `VCPJ-1` document
has ever been released, so the profile's parent union can be completed
before first release without changing any existing document's bytes or
digest. This record was authored and accepted on 2026-08-04 under the
project owner's recorded autonomous delegation, following the owner's
explicit instruction to build the external reference and compact
graphs.

## Decision

1. **`ExternalProvenanceRecordReference`.** A validated value binding
   one parent `ProvenanceID` to one `recordContentID` that must carry
   the registered `org.voxelia.provenance-record` tuple; any other
   tuple is a typed rejection, so a metadata, sample-bytes or
   parameters digest can never masquerade as a record claim.
   `ProvenanceParentReference` gains exactly the
   `externalRecord(ExternalProvenanceRecordReference)` case.
2. **Wire completion.** The `VCPJ-1` parent union gains the
   `{"externalRecord":{"id":…,"recordContentID":…}}` member in both
   the emitter and the strict ingress. Existing documents' bytes and
   digests are unchanged: the extension only widens the accepted
   grammar, and the tuple stays version `1.0` as a pre-release
   completion of the accepted `ADR-0038` target.
3. **Admission modes.** Graph admission gains the explicit
   `complete`/`compact` mode policy of `ADR-0038`: both modes reject
   unresolved local parents; complete mode rejects any unresolved
   external parent; compact mode retains unresolved external parents
   under a per-input-edge-occurrence cap for which zero is a
   permitted value meaning none may be admitted. External edges also
   consume ordinary edge units. The existing complete-graph function
   becomes the complete-mode policy unchanged.
4. **Available-external verification.** An external reference whose
   identifier is present in the candidate table is resolved only
   after verification: the candidate parent's canonical `VCPJ-1`
   bytes are re-emitted under a new mandatory resolution byte ceiling
   and the record-content claim is compared timing-safe; a digest
   mismatch is a typed rejection, the parent-subject rule applies
   exactly as for local parents, and each distinct claim is verified
   once. Resolved external edges participate in closure, cycle and
   depth exactly like local edges, and a self-naming external
   reference is rejected regardless of tag.
5. **Repeated-unresolved consistency.** Every retained occurrence of
   one unresolved external identifier must carry the same exact
   record-content claim and the same expected subject identity (the
   input edge's identity); a disagreement is one typed conflicting
   claim, never two independent missing parents.
6. **Result authority.** The admitted snapshot reports its resolution
   authority — `complete` exactly when no unresolved external parent
   was retained, `compact` otherwise — as the resulting state, not
   the selected policy, plus the retained occurrence count as
   evidence. Resolution happens only through a new transaction whose
   candidate table supplies the formerly external record, where both
   bindings are rechecked; a failed resolution leaves the earlier
   snapshot unchanged by value semantics.
7. **Limits extension.** `ProvenanceGraphLimits` gains the mandatory
   unresolved-external-reference cap (zero permitted) and the
   mandatory external-resolution byte ceiling (at least one), keeping
   no permissive defaults.

## Alternatives considered

A second registered tuple version for the widened grammar was
rejected: no released document exists, existing bytes and digests are
unchanged, and doubling the accepted-tuple surface would add
verification paths without adding safety. A resolver callback supplied
to admission was rejected: value-semantic re-admission against an
extended candidate table is transactional by construction and keeps
untrusted resolution outside the validator. Exposing the retained
consistency map was rejected for version one — callers own their
records and the count plus authority is the minimal honest evidence.

## Consequences

The `ADR-0038` admission table is implemented in both modes; durable
cross-store provenance ancestry can be claimed, retained compactly,
and later resolved with both bindings rechecked.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

The `ProvenanceGraphLimits` initializer gains two mandatory
parameters before any release; existing `VCPJ-1` documents, digests
and the complete-mode semantics are unchanged.

## Security impact

Record-content claims are constrained to the registered tuple,
verified timing-safe before any resolution, and never confer
authenticity; caps bound retained state per occurrence; conflicting
claims are typed rejections; errors stay payload-free.

## Performance and memory impact

One verification emission per distinct available claim with a bounded
sink; consistency state is bounded by the occurrence cap; admission
stays linear in records plus edges.

## Validation impact

Tests must reproduce an independently computed golden document whose
external claim is the registered origin golden digest, round-trip it
through ingress, and prove: available-external verification success
and digest-mismatch rejection, both mode policies, the zero and
nonzero occurrence caps, repeated-claim and expected-subject
consistency rejection, self-reference rejection regardless of tag,
compact authority reporting with later complete re-admission, and
payload-free diagnostics.

## Migration

Implemented in this increment.

## Supersession

This ADR completes the `ADR-0038` admission table, refines accepted
`ADR-0059` and `ADR-0060`, and supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0059 - Complete provenance graph admission](ADR-0059-complete-graph-admission.md)
- [ADR-0060 - Canonical provenance record projection](ADR-0060-canonical-provenance-record-projection.md)
- [ADR-0061 - Strict canonical provenance ingress](ADR-0061-strict-provenance-ingress.md)
