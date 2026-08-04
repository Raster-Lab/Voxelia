---
document_id: "ADR-0061"
title: "Strict canonical provenance ingress"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-004"
  - "VOX-ERR-001"
  - "VOX-SEC-001"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
---

# ADR-0061 - Strict canonical provenance ingress

## Context

Accepted `ADR-0060` registered the `VCPJ-1` profile and its emitter
and recorded strict ingress as the exact next action: without a
decoder, canonical provenance bytes can be digested and verified but
never read back into validated values. This record was authored and
accepted on 2026-08-04 under the project owner's recorded autonomous
delegation continuing the canonical-projection instruction.

## Decision

`VCPJ-1` ingress is the composition of four bounded phases, each
transactional:

1. **Bounded pre-scan.** The caller supplies an inclusive input byte
   ceiling with no permissive default; the raw bytes are then scanned
   once — string- and escape-aware — enforcing the fixed raw nesting
   ceiling of 32 before any parser allocates, so hostile deep nesting
   is rejected ahead of parsing. The profile's fixed schema nests
   well below the ceiling.
2. **Shape-directed parsing.** The platform JSON parser produces the
   candidate tree; extraction then checks the exact member set of
   every object before reading values, admits explicit nulls exactly
   where the profile places them, and parses the profile's decimal
   string tokens exactly.
3. **Revalidating reconstruction.** Every value is rebuilt through
   its accepted constructing initializer — identifiers, tokens,
   roles, versions, instants, digests, references, claims, warnings,
   inputs and finally the record — so nothing structurally invalid
   can exist after decoding. An operation record with an empty input
   sequence reconstructs as the declared zero-input generator, which
   is the only way such a document can canonically exist.
4. **Canonical byte equality.** The reconstructed record is
   re-emitted through the accepted `ADR-0060` emitter and the output
   must equal the input byte for byte. Every alias — whitespace,
   member reordering, escape or number respelling, trailing bytes the
   parser tolerated — fails as a typed non-canonical rejection. This
   gate, not the parser, is the canonical authority, which is why a
   lenient platform parser is admissible at phase two.

Failures are payload-free: over-ceiling input, raw-depth violation,
malformed or wrongly shaped documents, non-canonical spellings and
cancellation each map to their own case, and no underlying error that
could carry value text is retained.

## Alternatives considered

A hand-rolled byte-level canonical parser was rejected as redundant:
re-emission byte equality enforces exactly the canonical form, the
pre-scan bounds the platform parser's recursion exposure, and the
parser can be replaced later without any wire change. Retaining
underlying typed causes was rejected here — unlike the accepted
strict wires — because reconstruction crosses many error domains,
including ones whose cases carry payloads, and a uniform redacted
taxonomy is safer at an untrusted-bytes boundary.

## Consequences

The `VCPJ-1` projection is usable end to end: emit, digest, verify
and read back. Durable provenance interchange, the external parent
reference and compact graphs now lack only their own decisions.

## Affected modules

`VoxeliaCore` only; the platform JSON parser is already a permitted
dependency in this module.

## Compatibility impact

Purely additive; ingress accepts exactly what the accepted emitter
produces, so no permissive decoding ever needs deprecation.

## Security impact

Explicit input ceiling, pre-parse depth bound, exact-shape checks,
full revalidation, canonical byte equality and payload-free typed
rejections; decoded values remain claims with no added authority.

## Performance and memory impact

One pre-scan pass, one parse, one reconstruction and one re-emission
with the existing bounded sink — linear in the input with bounded
auxiliary state.

## Validation impact

Tests must round-trip both registered golden documents to equal
records and identities, and reject: over-ceiling input, a deep
nesting bomb before parsing, malformed JSON, wrong or extra members,
invalid field values, and canonical aliases (inserted whitespace,
member reordering, number and escape respelling) as the non-canonical
case, all payload-free.

## Migration

Implemented in this increment.

## Supersession

This ADR completes the `ADR-0060` projection with its ingress and
supersedes nothing.

## References

- [ADR-0060 - Canonical provenance record projection](ADR-0060-canonical-provenance-record-projection.md)
- [ADR-0058 - Provenance record aggregate](ADR-0058-provenance-record-aggregate.md)
