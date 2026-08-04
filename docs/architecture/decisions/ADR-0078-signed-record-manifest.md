---
document_id: "ADR-0078"
title: "Signed record manifest contract"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CON-006"
  - "VOX-API-004"
  - "VOX-SEC-010"
  - "VOX-SEC-011"
  - "VOX-ERR-001"
---

# ADR-0078 - Signed record manifest contract

## Context

The Master Technical Architecture permits a signed external provenance
manifest, and accepted `ADR-0038` deferred it for want of a signature
contract while freezing that an unkeyed digest is not authentication.
The canonical projections and the domain-separated identity frame now
provide everything a verify-side contract needs; key generation,
custody and trust policy are host responsibilities that never enter
Voxelia. This record was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

1. **Manifest profile.** The `VCRM-1` canonical record manifest is
   one envelope (`org.voxelia.record-manifest`, numeric major 1,
   minor 0) whose payload holds exactly `records`: a non-empty array
   of accepted `ContentID` wires in ascending digest-byte order with
   duplicates rejected — the emitter sorts, so exactly one canonical
   form exists per record set. An empty manifest attests nothing and
   is a typed rejection. The shared string-token authority and member
   forms apply.
2. **Sixth tuple.** Algorithm `sha256`, scope `serialisedObject`,
   projection `org.voxelia.record-manifest` version `1.0` (100-byte
   frame header); the accepted set holds exactly six tuples and every
   crossed combination stays rejected.
3. **Signature contract.** The signature subject is the manifest's
   domain-separated identity: an Ed25519 detached signature over the
   manifest `ContentID`'s exact 32 digest bytes, so a signature can
   never be replayed against another projection domain's bytes.
   Voxelia ships the verify side only: verification takes the
   host-supplied 32-byte raw public key and 64-byte signature,
   rejects malformed encodings typed, and returns a boolean result —
   a mismatch is a result, not an error. No key is ever generated,
   stored, or seen as a private value inside Voxelia, and a valid
   signature proves custody of a key, never trust, authorship
   authority or record truth; trust policy stays host-owned per
   `ADR-0038`.

## Alternatives considered

Signing the raw manifest bytes was rejected: signing the
domain-separated identity binds the projection domain and keeps the
message fixed-size. Shipping a signing convenience was rejected: the
moment Voxelia touches a private key, custody questions enter a
library that has no business answering them. P-256 was considered and
Ed25519 selected for its deterministic signatures and misuse
resistance; a future algorithm arrives as its own registered contract.

## Consequences

Hosts can attest exported record sets with their own keys, and any
Voxelia installation can verify the attestation against the canonical
manifest identity — completing the last deferred `ADR-0038` surface
that was buildable without external evidence.

## Affected modules

`VoxeliaCore` only; CryptoKit is already a permitted dependency.

## Compatibility impact

Purely additive.

## Security impact

The signature binds a domain-separated identity; malformed keys and
signatures reject typed; verification is constant-time within
CryptoKit's implementation; a boolean mismatch carries no material;
digests appear only inside canonical documents, never in filenames or
diagnostics.

## Performance and memory impact

One emission and hash pass per manifest and one Ed25519 verification.

## Validation impact

Tests must reproduce the independently computed golden manifest
document and framed identity byte for byte, prove the sorted
single-canonical-form rule and the duplicate and empty rejections,
and prove signature verification end to end with a test-generated
key: a valid signature verifies, a tampered manifest identity or
signature fails as a boolean result, and malformed key and signature
encodings reject typed.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0038` signed-manifest deferral and
supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
