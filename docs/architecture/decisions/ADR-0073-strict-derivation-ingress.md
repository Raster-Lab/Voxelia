---
document_id: "ADR-0073"
title: "Strict canonical derivation ingress"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-004"
  - "VOX-ERR-001"
  - "VOX-SEC-001"
  - "VOX-SEC-011"
---

# ADR-0073 - Strict canonical derivation ingress

## Context

Accepted `ADR-0072` registered the `VCDJ-1` projection with its
emitter and recorded strict ingress as the next codec increment under
the accepted `ADR-0061` pattern. This record was authored and accepted
on 2026-08-05 under the project owner's recorded autonomous
delegation, following the owner's explicit instruction to build the
`VCDJ-1` ingress.

## Decision

1. **Four phases.** `VCDJ-1` ingress composes the same four
   transactional phases as the accepted provenance ingress: the
   caller's input byte ceiling and the string-aware raw pre-scan under
   the shared nesting ceiling before any parser allocates;
   shape-directed platform parsing with exact member sets and explicit
   nulls; revalidating reconstruction through every accepted
   constructing initializer, with an empty input array reconstructing
   as the declared zero-input generator — the only way such a document
   canonically exists; and the canonical byte-equality gate through
   the accepted `ADR-0072` emitter, which remains the canonical
   authority over every alias.
2. **One shared member authority.** The `VCDJ-1` member forms are by
   definition the `VCPJ-1` member forms, so the shape-directed
   extraction primitives and the shared member reconstructors
   (semantic versions, content identifiers, identity references,
   source identities, keyed identifiers and the raw pre-scan) become
   one internal authority reused by both strict ingresses. Two copies
   decoding the same registered forms could drift, and drift in shared
   forms is a correctness bug; reuse is the conservative option.
   Cross-domain failures map into the derivation ingress's own
   payload-free five-case taxonomy, so no provenance-domain error
   escapes the derivation boundary.

## Alternatives considered

Duplicating the member reconstructors per domain — the precedent for
nominal grammar validators — was rejected here: validators freeze
distinct authorities, while these reconstructors decode one shared
registered form whose divergence would be silent corruption. A shared
public error type was rejected: each ingress keeps its own redacted
taxonomy at its own untrusted-bytes boundary.

## Consequences

The `VCDJ-1` projection is usable end to end — emit, digest, verify
and read back — so derivation records can travel and reconstruct with
full revalidation.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive; ingress accepts exactly what the accepted emitter
produces. The reconstructor visibility change is internal.

## Security impact

Identical discipline to the accepted provenance ingress: explicit
input ceiling, pre-parse depth bound, exact-shape checks, full
revalidation, canonical byte equality and payload-free typed
rejections.

## Performance and memory impact

One pre-scan pass, one parse, one reconstruction and one re-emission,
linear in the input.

## Validation impact

Tests must round-trip both registered golden documents and a record
exercising every identity-reference case to equal records and
identities, prove zero-input generator reconstruction, and reject
over-ceiling input, a pre-parse nesting bomb, malformed JSON, a wrong
schema identifier, wrong and extra members, a foreign parameter-digest
tuple and canonical aliases, all payload-free.

## Migration

Implemented in this increment.

## Supersession

This ADR completes the `ADR-0072` projection with its ingress and
supersedes nothing.

## References

- [ADR-0072 - Canonical derivation record projection](ADR-0072-canonical-derivation-projection.md)
- [ADR-0061 - Strict canonical provenance ingress](ADR-0061-strict-provenance-ingress.md)
