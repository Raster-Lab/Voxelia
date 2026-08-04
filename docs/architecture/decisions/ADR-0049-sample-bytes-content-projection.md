---
document_id: "ADR-0049"
title: "Sample-bytes content projection"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CON-006"
  - "VOX-API-004"
  - "VOX-DAT-014"
  - "VOX-RGN-007"
---

# ADR-0049 - Sample-bytes content projection

## Context

Accepted `ADR-0036` registered exactly one compiled content-identity
tuple (the complete canonical metadata record) and required every new
scope or projection to arrive through its own governed registration.
Accepted `ADR-0037` prefers content-tier cache admission, and the
`ADR-0048` increment recorded result caching as gated on a registered
bytes-scope projection. Accepted `ADR-0040`/`ADR-0042` froze exactly
one decoded logical byte profile: canonical packed interleaved bytes of
one complete `LogicalSampleBinding`. This record was authored and
accepted on 2026-08-04 under the project owner's recorded autonomous
delegation.

## Decision

A second compiled content-identity tuple is registered:

1. **Tuple.** Algorithm `sha256`, scope `sampleBytes`, projection
   `org.voxelia.sample-bytes` version `1.0`. The compiled accepted set
   now holds exactly two tuples; every crossed combination of the two
   scopes and two projection references stays rejected as an
   unsupported projection.
2. **Preimage.** The payload is the exact canonical packed interleaved
   decoded logical bytes of one complete binding under the accepted
   `ADR-0040`/`ADR-0042` profile — axis-zero-fastest canonical strides,
   component stride equal to the scalar byte count, no padding, no
   byte-order aliasing beyond the profile's admission rules. The frame
   is the same `VOXELIA-CONTENT-ID` version-one shape with the same
   length-prefixed members; the scope and projection length prefixes
   make the header 92 bytes, so the two registered preimages can never
   collide by construction.
3. **Deferral.** The `descriptorAndSamples` scope stays unregistered:
   it requires a canonical descriptor byte projection, and ordinary
   `Codable` output is not canonical under `ADR-0036`. No other scope,
   algorithm or projection gains generation or verification support.

## Alternatives considered

Hashing the payload without a distinct frame was rejected because the
`ADR-0036` domain-separation guarantee must hold between registered
projections, not only against raw checksums. Registering
`descriptorAndSamples` at the same time was rejected because its
canonical descriptor bytes do not exist. Binding the digest to the
binding's shape metadata inside the preimage was rejected: shape
authority belongs to the descriptor chain, and the sample-bytes
projection identifies exactly the decoded logical bytes.

## Consequences

Content-tier cache keys and future `DataIdentity` sample-content claims
gain a registered, domain-separated digest over decoded logical bytes.
Identical byte payloads produce distinct digests under the two
registered projections.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

The `ContentID` wire is unchanged; previously valid records stay valid,
and records carrying the new tuple become decodable. The metadata
record tuple's digests are unaffected.

## Security impact

Domain separation between the two registered preimages is structural
(distinct length-prefixed scope and projection members). Digest bytes
remain sensitive-derived equality oracles; errors stay payload-free;
verification stays timing-safe.

## Performance and memory impact

One incremental hash pass over the payload with the existing bounded
chunking and cancellation cadence; no new allocation classes.

## Validation impact

Tests must reproduce an independently computed golden framed digest,
prove the 92-byte header layout, prove identical payloads digest
differently under the two registered projections and against the raw
hash, round-trip the new tuple's wire and reject both crossed tuples.

## Migration

Implemented in this increment.

## Supersession

This ADR refines accepted `ADR-0036` by registering a second compiled
tuple and supersedes nothing.

## References

- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0042 - Storage API name, wire and limit freeze](ADR-0042-storage-api-name-wire-and-limit-freeze.md)
