# CCR-0013 - Controlled correction for ADR-0036 content identifier record

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0013` |
| Authority | Accepted [`ADR-0036`](../decisions/ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md) |
| Approved by | Project owner (maintainer approval for the public data-model change, recorded with `RFC-0002`) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0036`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0013-A - Corrected ContentID record

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`
section 32.2 and `docs/project/Voxelia_Master_Technical_Architecture_v0.1.1.md`
section 11.3.

The baseline CDMS record reads:

> ```swift
> public struct ContentID: Sendable, Hashable, Codable {
>     public let algorithm: String
>     public let digest: ContiguousArray<UInt8>
> }
> ```

The baseline MTA record reads:

> ```swift
> public struct ContentID: Sendable, Hashable, Codable {
>     public let algorithm: DigestAlgorithm
>     public let digest: Data
> }
> ```

The one corrected record replacing both reads:

> ```swift
> public struct ContentID: Sendable, Hashable, Codable {
>     public let algorithm: DigestAlgorithm
>     public let scope: ContentScope
>     public let projection: ContentProjectionReference
>     public var digest: ContiguousArray<UInt8> { get }
> }
> ```

`ContentID` has no public unchecked memberwise initializer; accepted
profile-specific construction snapshots the digest into owned contiguous
bytes and validates the complete tuple before the value exists. The type
never stores Foundation `Data`. Equality and hashing combine exact
algorithm, scope, projection identifier/version and every digest byte.
`ContentProjectionReference` is a bounded lowercase ASCII reverse-domain
identifier plus an exact `ContentProjectionVersion`, validated with
byte-limit-before-grammar precedence, a distinct nominal type from the
metadata schema reference.

### CCR-0013-B - Digest text and type-level coding

Target: the same sections' serialisation implications.

The one canonical textual digest representation is exactly 64 lowercase
ASCII hexadecimal characters with no prefix, uppercase, separator,
truncation, padding, Base64 alias or integer-array alias, and no algorithm
inference from text length. The type-level object carries exactly the four
fields `algorithm`, `digest`, `projection` and `scope` through a dedicated
manual coding contract that rejects missing, null, unknown, wrong-shaped
or unsupported values with payload-free identity errors.

### CCR-0013-C - Version-one accepted profile and framing

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`
sections 32.1 and 32.3 interpretation.

Version one compiles exactly one accepted generation/verification tuple:
`sha256` (via CryptoKit), scope `serialisedObject`, projection
`org.voxelia.metadata-complete-record` major `1` minor `0`, over the exact
complete accepted `VCMJ-1` bytes, producing exactly 32 digest bytes. The
SHA-256 preimage is the fixed 109-byte `VOXELIA-CONTENT-ID` frame selected
by `ADR-0036` followed by the payload; the empty-document golden digests
are immutable fixtures. `.sha512` and `.blake3` remain reserved
declaration vocabulary; `.custom` is rejected for persistent and
distributed identity because the payload-free case cannot carry the
namespaced identifier that section 32.1 requires. Readers never infer an
algorithm from digest length and never negotiate down.

### CCR-0013-D - Source identity precedence

Target: `docs/project/Voxelia_Master_Technical_Architecture_v0.1.1.md`
section 11.3 closing paragraph.

The corrected reading confirms that a source or derivation identity may
precede a full content digest, and that a structurally valid or decoded
`ContentID` always remains a claim value: separate generation or
verification over one pinned immutable snapshot supplies assurance, and
presence alone never confers cache authority. The claim/assurance boundary
remains governed by Proposed `ADR-0037`.

## Scope and limits

- The digest is sensitive-derived material: an equality/linkage oracle
  that proves no authorship, authenticity, permission, de-identification
  or collision impossibility, and is never safe to log, place in URLs or
  filenames, share across tenants or export without trusted host policy.
- Semantic collection identity, image/data identity, source/derivation
  identity, signatures, MACs, keyed pseudonyms and algorithm registries
  remain separate future decisions; the complete-record ID intentionally
  differs between semantically equal collections.
- The `ADR-0035` evidence-closure items remain explicit open gaps recorded
  in the progress ledger and are inherited by this identity surface.
- This record grants no authority beyond the corrections above: it does
  not accept any other Proposed ADR or RFC, alter any requirement row, or
  authorise source outside the accepted `ADR-0036` migration steps.

## References

- [ADR-0036 - Domain-separated complete canonical metadata record identity](../decisions/ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](../decisions/ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
- [RFC-0002 - Scoped, projected content identifier record](../../rfcs/RFC-0002-scoped-projected-content-identifier-record.md)
- [CCR-0012 - Canonical metadata JSON correction](CCR-0012-adr-0035-canonical-metadata-json.md)
- [Voxelia Core Data Model Specification v0.1.1, section 32](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, section 11.3](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
