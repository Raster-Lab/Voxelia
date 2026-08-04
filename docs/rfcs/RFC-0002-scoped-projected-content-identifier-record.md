---
document_id: "RFC-0002"
title: "Scoped, projected content identifier record"
status: "Draft"
date: "2026-08-04"
authority: "Non-authoritative proposal"
authors:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-003"
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-ARC-003"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-010"
  - "VOX-DAT-014"
  - "VOX-META-011"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-ERR-001"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
---

# RFC-0002 - Scoped, projected content identifier record

## Decision status

This RFC is a **Draft**. It records the public data-model shape selected by
accepted `ADR-0036` for the register required by that decision's migration
gate; as a structural register record it does not authorise product source.
The RFC register's validator fails closed on every status other than
`Draft` until a machine-readable approval schema is governed, so this file
retains `Draft` status. The project owner's 2026-08-04 maintainer approval
of the underlying public data-model change is recorded in accepted
`ADR-0036`, in `CCR-0013` and in the progress ledger; source authority
flows from that accepted decision, never from this structural record.

## Summary

The two controlled `ContentID` sketches disagree (Foundation `Data` versus
`ContiguousArray<UInt8>`, `DigestAlgorithm` versus arbitrary `String`) and
both omit the required scope and the versioned projection that produced the
digest. This proposal records the corrected public record: typed algorithm,
required scope, a bounded versioned projection reference, owned contiguous
digest bytes with no public unchecked initializer, and strict 64-character
lowercase-hexadecimal type-level digest text.

## Motivation

A digest without scope and projection cannot be reproduced or verified, and
representation-dependent synthesised coding produces incompatible wire
forms. Binding algorithm, scope, projection and version into one validated
record — and into the digest preimage through the `ADR-0036` frame — makes
identity domains explicit and migration-safe.

## Scope

The record shape `ContentID` (algorithm, scope, projection, owned digest),
the bounded `ContentProjectionReference` and `ContentProjectionVersion`
support types, the payload-free `ContentIdentityError` vocabulary and the
strict digest text. Semantic collection identity, image/data identity,
source/derivation identity, signatures, MACs, keyed pseudonyms and
algorithm registries are out of scope.

## Proposed design

```swift
public struct ContentID: Sendable, Hashable, Codable {
    public let algorithm: DigestAlgorithm
    public let scope: ContentScope
    public let projection: ContentProjectionReference
    public var digest: ContiguousArray<UInt8> { get }
}
```

Construction is profile-validated with no public memberwise initializer.
Version one compiles exactly one accepted tuple: `sha256`,
`serialisedObject`, `org.voxelia.metadata-complete-record` major `1` minor
`0`, 32 digest bytes. The projection identifier uses the bounded lowercase
ASCII reverse-domain grammar with byte-limit-before-grammar validation
precedence and no unbounded copy of oversized input.

## Public API

`ContentProjectionVersion`, `ContentProjectionReferenceError`,
`ContentProjectionReference`, `ContentIdentityError` and `ContentID` in
`VoxeliaCore`, plus the framed complete-record digest computation and
timing-safe verification selected by `ADR-0036`. No
`CustomStringConvertible`, `CustomDebugStringConvertible` or
`CustomReflectable` conformance exists, and the hex form is not a
safe-display form.

## Data and spatial semantics

The record is spatial-neutral. Equality and hashing combine exact
algorithm, scope, projection identifier/version and every digest byte;
process-randomised Swift hashes are never persisted.

## Concurrency

All types are immutable `Sendable` values. Digest computation checks
cancellation at the bounded cadence selected by `ADR-0036` and publishes
atomically.

## Storage and memory

Digest storage is 32 owned bytes; canonical text is 64 bytes. The identity
frame header is a fixed 109 bytes, and payload hashing uses bounded slices
without one contiguous `header + payload` allocation.

## Security

Domain separation, explicit length framing, a closed compiled profile set,
strict digest lengths and hex, owned bytes and platform timing-safe direct
comparison. An unkeyed digest remains an equality/linkage oracle:
sensitive-derived by default, never authentication, de-identification or
export permission.

## Performance

SHA-256 computation is O(n) in the exact canonical record byte count with
bounded hasher state. No performance claim is made from isolated probes;
production benchmarks remain future evidence.

## Validation

Golden empty-record raw and framed digests, NIST known-answer vectors,
frame domain mutations, digest text boundaries, projection-identifier
byte-limit precedence, owned-byte snapshots, timing-safe mismatch fixtures
and payload-free error rendering, as itemised by `ADR-0036`.

## Compatibility and migration

There is no live `ContentID` product source to migrate. The corrected
record adds `scope` and `projection`, selects owned contiguous bytes and
strict lowercase hex; `CCR-0013` records the controlled-document
correction. Once accepted, a projection's frame and golden digest are
immutable; changes create a new projection version, never an in-place
meaning change.

## Alternatives

Raw unframed digests, semantic projections, storing only algorithm and
digest, Foundation `Data` storage, synthesised coding, algorithm inference
from digest length and reuse of the payload-free `.custom` case were all
rejected for the reasons recorded in `ADR-0036`.

## Implementation plan

Implement the bounded projection reference, private validated `ContentID`
construction, manual type-level coding, the CryptoKit SHA-256 framed
helper and timing-safe verification in `VoxeliaCore` with the focused
evidence above, exactly as ordered by accepted `ADR-0036`'s migration
steps.

## Unresolved questions

A governed machine-readable RFC approval schema; future algorithm
profiles (`sha512`, BLAKE3 mode/output, namespaced custom profiles);
semantic collection identity; and the streaming source/sink surface for
raw-stream hashing with authoritative lengths.
