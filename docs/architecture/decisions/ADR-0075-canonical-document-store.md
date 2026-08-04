---
document_id: "ADR-0075"
title: "Canonical document store"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-STO-004"
  - "VOX-CON-006"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0075 - Canonical document store

## Context

Every canonical byte projection and its registered digest now exist,
but no governed way to persist a canonical document durably does.
Accepted `ADR-0038` assigns record and graph persistence integrity to
`VoxeliaStorage`, which must verify bytes against an accepted
projection before resolving durable references and must never author
scientific history. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`VoxeliaStorage` gains the actor-isolated `CanonicalDocumentStore`
over one caller-supplied existing directory:

1. **No digests in the filesystem namespace.** Accepted `ADR-0036`
   classifies digests as sensitive-derived material that must not be
   interpolated into filenames, so content-addressed naming is
   excluded by governance. Documents are addressed by a validated
   `CanonicalDocumentName` — a single lowercase label of 1 through 64
   bytes (`a` to `z`, `0` to `9`, `-`, alphanumeric at both ends) —
   which structurally excludes path traversal and discloses nothing;
   the caller owns the name-to-record mapping.
2. **Verify on both sides.** Storing verifies the supplied identity
   against the exact bytes timing-safe before anything touches disk —
   the store never persists an unverified claim — and loading
   verifies the read bytes against the caller's expected identity
   before returning them, with a mismatch surfaced as typed
   corruption, never repaired or substituted.
3. **Bounded, atomic, idempotent.** Loads preflight the file size
   against the caller's inclusive byte ceiling before reading. Writes
   use the platform's documented atomic data write, recorded as the
   trusted primitive — independent power-fail evidence remains an
   open recorded gap. Storing a name that already exists verifies the
   existing bytes: identical content is an idempotent success, and
   different content is typed corruption, never overwrite.
4. **Append-only.** No deletion, overwrite or rename API exists in
   version one: retention and deletion governance remain deferred,
   and an immutable name can never come to mean different bytes.
5. **Claims only.** The store proves byte integrity against supplied
   identities; it interprets no document, resolves no reference and
   authors no history.

## Alternatives considered

Content-addressed digest filenames were rejected by the accepted
sensitivity rule. Creating the directory implicitly was rejected as a
surprising filesystem effect. Silent repair of corrupted documents
was rejected: corruption is evidence the owner must see.

## Consequences

Canonical metadata, provenance and derivation documents persist
durably with verify-on-write and verify-on-read discipline; durable
external-record resolution gains its storage foundation.

## Affected modules

`VoxeliaStorage` only; no dependency change.

## Compatibility impact

Purely additive public surface.

## Security impact

No digest reaches a filename, log or path; names are bounded validated
labels; every byte returned was verified against a caller-supplied
identity; failures stay payload-free.

## Performance and memory impact

One digest pass per store and per load, bounded by the caller's
ceilings; file-size preflight bounds reads before allocation.

## Validation impact

Tests must round-trip real canonical documents through a real
directory, prove idempotent same-content restore, and prove typed
rejection of: an unverified store claim, a mismatched load identity, a
byte-flipped on-disk document, a truncated on-disk document, a missing
document, an over-ceiling load, an invalid store name and an invalid
store directory — real on-disk corruption evidence, not simulation.

## Migration

Implemented in this increment.

## Supersession

This ADR implements the `ADR-0038` persistence-integrity assignment
for canonical documents and supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0060 - Canonical provenance record projection](ADR-0060-canonical-provenance-record-projection.md)
