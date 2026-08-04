# CCR-0012 - Controlled correction for ADR-0035 canonical metadata JSON

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0012` |
| Authority | Accepted [`ADR-0035`](../decisions/ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0035`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0012-A - Core Data Model Specification section 55.2 initial format

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 55.2 initial format.

The baseline reads:

> The initial reference serialisation shall be canonical JSON for descriptors and records.

The corrected reading names the metadata record profile: the initial
canonical metadata-record serialisation is **Voxelia Canonical Metadata
JSON version 1 (`VCMJ-1`)**, a JCS-derived UTF-8 record profile with
Voxelia-specific semantic shapes, decimal-string 64-bit integers and
preservation of all valid Swift Unicode-scalar strings including
noncharacters. It must not be described as unmodified JCS or I-JSON.
Ordinary type-level `Codable` output is a distinct representation and must
never be labelled `VCMJ-1`.

### CCR-0012-B - Core Data Model Specification section 55.3 requirements

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 55.3 canonical JSON requirements, as already corrected for enum
tags by `CCR-0008` and for the layer split by `CCR-0010`.

The corrected requirement binds each listed item to the accepted `VCMJ-1`
profile: UTF-8 with no BOM and no insignificant whitespace; RFC 8785
decoded UTF-16 property order for the fixed ASCII structural names with
`MetadataObject` members remaining an `ADR-0031`-sorted array; RFC 8785
string escaping with exactly one byte spelling per token and rejection of
escape aliases; RFC 8785/ECMAScript shortest round-trip binary64 numbers
with negative zero emitting as `0` and a hard 32-byte raw numeric-token
ceiling; `Int64`/`UInt64` payloads as canonical decimal JSON strings;
`ADR-0030` strict padded standard Base64; the exact `ADR-0028` uppercase
zero-offset instant; the fixed three-member document envelope
(`documentSchema` with the fixed `org.voxelia.metadata-document`
identifier and version, `multiplicitySchema` as `null` or one bounded
ASCII reverse-domain schema reference, `payload` as the one-field
collection); raw duplicate-member rejection at every depth immediately
after the second decoded name; and non-finite floating-point rejection.
Repeat-bearing documents are admitted only through the out-of-band
trusted multiplicity binding: the wire never carries a repeatable-key
allow-list, and a non-null reference must exactly match caller-supplied
context before payload admission.

### CCR-0012-C - Core Data Model Specification section 55.5 evolution

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 55.5 schema evolution.

The corrected reading records version-one closure: readers accept exactly
document version `1.0`; a syntactically valid fixed identifier with
another version fails with the typed unsupported-version error after the
canonically ordered `documentSchema` prefix without inspecting the
suffix; unknown envelope members, fixed-record members, enum strings and
value tags are never treated as compatible additions; unknown namespaced
metadata entries using the recognised value vocabulary remain
representable and preserved; and a future same-major minor requires a
reviewed compatibility decision with a lossless representation.

### CCR-0012-D - Blank-identity whitespace oracle domain correction

Target: the `docs/project` baseline constructor domains for metadata-key
namespace/name (CDMS section 34.1/34.2), coded-concept scheme/value (CDMS
section 35) and measurement-unit namespace/code (MTA section 9.9 sketch as
corrected by `CCR-0003`).

The corrected domain rule replaces the toolchain-dependent
`Character.isWhitespace` blank predicate with the frozen scalar oracle:
one of these identity fields is blank exactly when it contains no Unicode
scalar outside the enumerated set U+0009 through U+000D, U+0020, U+0085,
U+00A0, U+1680, U+2000 through U+200A, U+2028, U+2029, U+202F, U+205F and
U+3000. This is a documented pre-1.0 accepted-domain broadening: edge
strings such as `" \u{0301}"` and `"\u{2003}\u{FE0F}"` are accepted
because each contains a scalar outside the frozen set, while exact bytes
remain preserved. Core and Spatial use private module-local
implementations generated from the same controlled table with
cross-module fixtures; generic metadata string payloads remain free to
contain any valid scalar sequence.

### CCR-0012-E - Core Data Model Specification sections 66/67 raw bounds

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
sections 66 and 67, as already corrected for typed lookup by `CCR-0011`.

The corrected reading records the raw ingress obligations: semantic
ceilings do not bound raw input, so canonical ingress snapshots immutable
caller limits before consuming bytes and enforces raw document bytes, raw
token bytes, decoded string bytes, encoded and decoded binary bytes,
direct member counts, raw JSON depth (grammar-derived maximum 198),
semantic depth and the aggregate `ADR-0031`/`ADR-0033` ceilings through
checked `UInt64` arithmetic charged before growth, with byte-order
failure precedence and one success linearisation point. Cancellation is
polled at the additive 4,096-work-unit cadence. The universal raw
document ceiling remains an explicit open derivation gap; callers must
supply explicit limits and there is no permissive default for untrusted
ingress.

### CCR-0012-F - Core Data Model Specification section 64 validation

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 64 validation (canonical serialisation items), as already
corrected by `CCR-0009` through `CCR-0011`.

The corrected item expands to the accepted evidence obligations recorded
in `ADR-0035`'s validation impact, executed on local Apple Silicon in
this increment: golden envelope and value fixtures, malformed
UTF-8/BOM/whitespace/duplicate/alias rejections, integer extrema and
alias rejections, RFC 8785 floating vectors with random-bit round-trip
self-consistency, Base64 boundaries, schema-identifier grammar and limit
boundaries, multiplicity binding admission and mismatch failures,
symmetric emission preflight with no partial publication, failure
precedence controls, redaction proofs, and the recorded open gaps
(lowest-resource device latency, fuzz corpora, external differential
oracles, universal ceiling, allocation-fault disposition).

### CCR-0012-G - Core Data Model Specification Appendix A type inventory

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
Appendix A Core type inventory.

The corrected inventory additionally records `MetadataSchemaVersion`,
`MetadataSchemaReference`, `MetadataSchemaReferenceError`,
`CanonicalMetadataDocument`, `MetadataJSONIngressError`,
`MetadataJSONEmissionError` and the `VCMJ-1` codec surface as
`VoxeliaCore` M1 types. `MetadataSchemaVersion` and
`MetadataSchemaReference` gain no standalone `Codable` in version one;
their stable role is inside the dedicated canonical codec.

## Scope and limits

- `VCMJ-1` bytes are deterministic complete-record bytes, not semantic
  equality, persistent identity, privacy safety or export permission;
  digest, signature and export remain governed by `ADR-0036` and host
  policy.
- The multiplicity binding is an admission assertion, not a cryptographic
  capability; schema resolution, authenticity, authorisation and audit
  remain host responsibilities.
- The typed `resourceLimitExceeded` coverage of `VOX-ERR-001` is partial:
  the P0 allocation-failure clause remains open until recoverable
  fallible-allocation evidence exists or the controlled baseline is
  revised.
- The lowest-resource device cancellation-latency campaign, fuzz/mutation
  corpora, external Ryu/V8 differential oracles and the universal raw
  ceiling derivation remain explicit open evidence gaps recorded in the
  progress ledger.
- This record grants no authority beyond the corrections above: it does
  not accept any other Proposed ADR, alter any requirement row, or
  authorise source outside the accepted `ADR-0035` migration steps.

## References

- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](../decisions/ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
- [CCR-0008 - Bounded recursive metadata value correction](CCR-0008-adr-0031-bounded-recursive-metadata-value.md)
- [CCR-0010 - Ordered collection multiplicity correction](CCR-0010-adr-0033-ordered-collection-multiplicity.md)
- [CCR-0011 - Closed typed read boundary correction](CCR-0011-adr-0034-closed-typed-read-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 34, 35, 55, 64, 66, 67 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, section 9.9](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [RFC 8785 - JSON Canonicalization Scheme](https://www.rfc-editor.org/rfc/rfc8785.html)
