---
document_id: "ADR-0101"
title: "Record manifest archival"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-STO-004"
  - "VOX-CON-006"
  - "VOX-ERR-001"
---

# ADR-0101 - Record manifest archival

## Context

`ADR-0095` made individual records durable, but a render's history is
a set: nothing durable bound the archived records together, so a
store could silently hold a partial history with no artefact saying
what complete looks like. The `ADR-0078` `VCRM-1` manifest is exactly
that artefact — one canonical form per record-identity set — and the
verify-only signature contract binds to the manifest identity when a
host chooses to sign. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`CanonicalRecordArchival` gains `archiveManifest`: emit the `VCRM-1`
manifest document over the caller-supplied archived record
identities, compute the registered manifest identity, and persist the
document through the accepted store under a host-supplied name with
the inherited verify-before-persist discipline; the manifest identity
returns as the receipt. The emitter's own typed surface governs the
set — empty and duplicate identity sets stay rejected there — and
signing remains host-side per the `ADR-0078` verify-only rule: the
archival never generates or holds keys.

## Alternatives considered

Deriving the manifest set implicitly from store contents was
rejected: the store holds names, not history membership, and only
the caller knows which records form one history. Bundling signature
persistence here was rejected: Voxelia verifies signatures and never
custodies keys.

## Consequences

A complete archived history is now one verifiable durable artefact;
a partial store is detectable against its manifest.

## Affected modules

`VoxeliaStorage` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Inherited store discipline; no key material touches Voxelia.

## Performance and memory impact

One emission and one bounded atomic write per manifest.

## Validation impact

Tests must extend the end-to-end pipeline archival: collect every
receipt identity from a full render's archived records, archive the
manifest, load it back under the returned identity, and reproduce the
manifest bytes independently from the same identity set.

## Migration

Implemented in this increment.

## Supersession

Connects the `ADR-0078` manifest projection to the `ADR-0075` store;
no record is superseded.

## References

- [ADR-0095 - Canonical record archival](ADR-0095-canonical-record-archival.md)
- [ADR-0078 - Signed record manifest](ADR-0078-signed-record-manifest.md)
