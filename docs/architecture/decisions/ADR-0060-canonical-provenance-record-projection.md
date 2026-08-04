---
document_id: "ADR-0060"
title: "Canonical provenance record projection"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CON-006"
  - "VOX-API-004"
  - "VOX-META-004"
  - "VOX-META-009"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0060 - Canonical provenance record projection

## Context

Accepted `ADR-0038` requires a registered domain-separated
provenance-record projection before any durable external reference,
compact-graph retention or signed manifest can exist, and forbids
reusing the metadata-record profile or treating `Codable` output as
canonical. The record aggregate and every leaf are now accepted
(`ADR-0051` through `ADR-0059`), and several of those decisions
assigned their stable coding to this projection. This record was
authored and accepted on 2026-08-04 under the project owner's recorded
autonomous delegation, following the owner's explicit instruction to
design the canonical provenance projection.

## Decision

The `VCPJ-1` profile (Voxelia Canonical Provenance JSON, version one)
and a fourth compiled content-identity tuple are registered:

1. **Envelope.** One UTF-8 JSON object with no whitespace, byte-order
   mark or trailing newline, holding exactly `documentSchema` (the
   identifier `org.voxelia.provenance-record` with numeric major 1,
   minor 0) and `payload` (one record), in that order.
2. **Member order and escaping.** Every object's members appear in
   ascending UTF-8 byte order of their names — for this fixed schema,
   a fixed documented order — and every string uses the RFC 8785
   escaping already compiled for `VCMJ-1`; the two profiles share one
   string-token authority.
3. **Fixed record schema with explicit nulls.** The payload members
   are `activity`, `createdAt`, `id`, `inputs`, `kind`, `software`,
   `subject`, `validationClaim`, `warnings`. Absent optionals encode
   as explicit `null`. Tagged unions encode as one-member objects
   (`{"origin":null}`, `{"operation":{…}}`, `{"unknown":null}`,
   `{"validated":{…}}`, `{"graphNode":{…}}`). Persistent
   `VoxeliaStringIdentifier` values keep their accepted keyed
   `{"rawValue":…}` shape; grammar-validated ASCII tokens encode as
   bare strings, since this projection owns their stable coding.
   Embedded `ContentID`, `SourceIdentity` and `DataIdentityReference`
   values keep their accepted wire shapes under this profile's
   canonical escaping. `createdAt` is the single-spelling
   `CanonicalInstant` string.
4. **Integer tokens.** Fields typed at most 32 bits (`occurrence`,
   warning schema versions, embedded accepted version shapes) encode
   as minimal decimal JSON integers, always exactly representable.
   Wider profile-native integers — semantic-version components and
   the warning occurrence count — encode as decimal string tokens,
   matching the `VCMJ-1` 64-bit precedent, so no binary64 boundary
   can corrupt exactness.
5. **Non-circularity.** The record's own `ContentID` is an
   envelope/link claim about these bytes and never a field inside
   them; the accepted record shape guarantees this structurally.
6. **Ceilings and discipline.** Emission validates explicit
   inclusive ceilings of 65,536 inputs and 65,536 warnings per record
   before writing any byte, honours a caller-supplied output byte
   ceiling with checked arithmetic and no permissive default, and
   observes the established cancellation cadence with typed
   payload-free failures.
7. **Tuple.** The fourth compiled tuple is algorithm `sha256`, scope
   `serialisedObject`, projection `org.voxelia.provenance-record`
   version `1.0`, framed by the version-one `VOXELIA-CONTENT-ID`
   header (102 bytes via the length prefixes); the accepted set holds
   exactly four tuples and every crossed combination stays rejected.
8. **Deferrals.** Strict ingress (bytes back to a validated record)
   is the immediate next increment under this profile.
   `DerivationRecordID`, the external parent-reference case, compact
   graphs and signed manifests become possible but each remains its
   own decision.

## Alternatives considered

Reusing the `VCMJ-1` metadata envelope was rejected by `ADR-0038` as a
domain confusion; sharing only the string-token authority keeps one
escaping implementation without blending domains. A binary format was
rejected: the project's canonical-byte expertise, tooling and golden
discipline are JSON-based, and RFC 8785 semantics are already
compiled. Encoding all integers as strings was rejected as gratuitous
divergence from the embedded accepted wires; encoding 64-bit values as
JSON numbers was rejected as a binary64 exactness hazard.

## Consequences

A provenance record has exact canonical bytes and a registered
domain-separated digest; external references, compact graphs and
durable provenance storage gain their missing foundation.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive. The profile is strict from its first release.

## Security impact

Structural domain separation via the length-prefixed frame; bounded
emission with checked arithmetic; no free text can reach the bytes
because the record shapes ban it; digests remain sensitive-derived
equality oracles; failures stay payload-free.

## Performance and memory impact

One linear emission pass with a bounded sink and one incremental hash
pass; output is bounded by the caller's ceiling.

## Validation impact

Tests must reproduce two independently computed golden documents and
framed digests — a minimal origin record and an operation record
exercising the activity, input, warning, validation and embedded
digest shapes — byte for byte, prove determinism, enforce both count
ceilings before emission and the output byte ceiling, round-trip the
new tuple's wire and reject crossed tuples.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0038` projection prerequisite and
supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0058 - Provenance record aggregate](ADR-0058-provenance-record-aggregate.md)
