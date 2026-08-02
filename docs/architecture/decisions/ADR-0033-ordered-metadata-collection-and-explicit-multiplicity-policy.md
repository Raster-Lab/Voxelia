---
document_id: "ADR-0033"
title: "Ordered metadata collection and explicit multiplicity policy"
status: "Proposed"
date: "2026-08-03"
owners:
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
  - "VOX-META-001"
  - "VOX-META-002"
  - "VOX-ERR-001"
  - "VOX-ERR-007"
  - "VOX-SEC-001"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
  - "VOX-VAL-008"
  - "VOX-VAL-009"
---

# ADR-0033 - Ordered metadata collection and explicit multiplicity policy

## Context

The Core Data Model Specification sketches one Core-owned collection:

```swift
public struct MetadataCollection: Sendable, Hashable, Codable {
    public let entries: ContiguousArray<MetadataEntry>
}
```

It also requires duplicate keys to be rejected unless a namespace schema
explicitly permits multiplicity. No controlled document defines that schema's
type, identity, version, owner, resolver, trust rule or decoding path. The
collection stores only entries, so a decoder cannot discover a trusted schema
from the value itself. Letting input bytes carry their own repeat permission
would make the invariant self-authorising; using a mutable global registry,
task-local state or `Decoder.userInfo` would hide policy and create lifecycle,
race and cross-tenant risks.

The prescribed `ContiguousArray` also makes order observable without saying
whether caller order, key order or same-key order is semantic. Synthesised
`Hashable` and `Codable` would preserve caller order, but later sorting or
deduplication would change identity and could discard privacy-bearing entries.
Proposed `ADR-0032` requires classification to participate in entry identity
while collection duplicate detection compares keys, not whole entries.

A context-free implementation faces an incomplete choice:

- rejecting every repeat cannot represent the schema-permitted state;
- accepting every repeat violates the default invariant;
- converting repeats to arrays changes values and typed semantics;
- first-wins, last-wins, `Set` or dictionary conversion loses entries and their
  privacy declarations; and
- serialising an allow-list lets untrusted input waive validation.

Foundation supplies explicit configuration-aware encoding and decoding. A
value can support ordinary `Codable` for its context-free subset and
`CodableWithConfiguration` when explicit caller-supplied context is required.
The additional configuration is not encoded by that protocol. This proposal
selects a bounded immutable admission snapshot rather than treating the
configuration as a schema, resolver or authentication proof.

Proposed `ADR-0031` gives each recursive value cached structural and logical-
payload metrics, but its 64 MiB payload ceiling applies only to an array or
object root. Without a collection-wide budget, a caller could combine an
unbounded number of individually valid roots. A collection therefore needs
its own entry, aggregate-work and aggregate-payload ceilings, and its policy
snapshot must also be bounded.

Typed access is required eventually, but no controlled mapping exists between
`MetadataKey<Value>` and the eleven erased `MetadataValue` cases. The documents
also omit missing, wrong-type and multiple-value cardinality behaviour. This
proposal can settle ordered storage, construction, multiplicity admission,
identity, type-level wire, limits, privacy preservation and the cardinality
failure rule without inventing that conversion protocol.

This proposal does not define a portable namespace-schema identity, a mutable
registry, namespace-specific key equivalence, typed conversion, canonical raw
JSON, persistent digest identity, logging/export authorisation or a privacy
aggregate. Its Proposed status does not authorise source or controlled-document
changes.

## Decision

If this ADR and its value/entry dependencies are accepted, `VoxeliaCore` will
own this public boundary:

```swift
public enum MetadataCollectionError: Error, Sendable, Equatable {
    case duplicateKey
    case multiplicityPolicyRequired
    case multiplicityPolicyLimitExceeded
    case entryCountLimitExceeded
    case aggregateStructuralElementLimitExceeded
    case aggregateLogicalPayloadByteLimitExceeded
}

public struct MetadataMultiplicityPolicy: Sendable {
    public static let uniqueKeysOnly: Self

    public init<Keys: Collection>(repeatableKeys: Keys) throws
    where Keys.Element == AnyMetadataKey
}

public struct MetadataCollection:
    Sendable,
    Hashable,
    Codable,
    CodableWithConfiguration
{
    public typealias EncodingConfiguration = MetadataMultiplicityPolicy
    public typealias DecodingConfiguration = MetadataMultiplicityPolicy

    public static let maximumEntryCount: UInt64 = 1_048_576
    public static let maximumAggregateStructuralElementCount: UInt64 = 1_048_576
    public static let maximumAggregateLogicalVariablePayloadByteCount: UInt64 = 67_108_864
    public static let maximumMultiplicityPolicyKeyCount: UInt64 = 1_048_576
    public static let maximumMultiplicityPolicyLogicalKeyByteCount: UInt64 = 67_108_864

    public let entries: ContiguousArray<MetadataEntry>

    public init<Entries: Collection>(entries: Entries) throws
    where Entries.Element == MetadataEntry

    public init<Entries: Collection>(
        entries: Entries,
        multiplicityPolicy: MetadataMultiplicityPolicy
    ) throws where Entries.Element == MetadataEntry
}
```

The configured encoding and decoding requirements use the same immutable
`MetadataMultiplicityPolicy` type. No default configuration provider is
published. A containing configured record must pass the configuration
explicitly; an ordinary containing `Codable` record uses the ordinary
unique-only path.

### Ordered sequence semantics

The collection is an ordered immutable sequence. Construction preserves every
entry in exact input order. It never sorts, groups, flattens, deduplicates or
rewrites entries. Empty collections are valid.

Equality and hashing compare the complete ordered entry sequence. Reordering
otherwise identical entries changes equality and hashing. Each full
`MetadataEntry` participates, including its exact key, semantic value and
declared privacy class. The multiplicity policy, cached metrics and any private
lookup index do not participate because they are validation context or derived
state, not stored collection content.

The order is type-level semantic identity, not a claim that a later canonical
document digest must use ordinary `Codable` bytes. Any future order-insensitive
or schema-normalised identity needs a separately named projection and cannot
silently replace this `Hashable` contract. Swift hashes are process-randomised,
must not be persisted and must not key authorisation or schema-validation caches
without the complete external policy identity and context.

### Exact-key multiplicity admission

Ordinary construction is context-free and uses `uniqueKeysOnly`. It rejects the
second occurrence of any exact `AnyMetadataKey`, even when the two complete
entries are equal. Duplicate detection compares the existing exact UTF-8
namespace/name identity and never whole-entry equality.

`MetadataMultiplicityPolicy` is a finite immutable exact-key allow-list. An
unlisted key is unique-only. The policy preserves no live closure, protocol
existential, mutable resolver, global registration, task-local value or
`Decoder.userInfo` lookup. Its constructor deduplicates its own exact keys only
after bounding the source count and checked sum of namespace/name UTF-8 bytes.

The policy is an explicit caller assertion that the host or adapter has already
performed whatever external schema selection it requires for the candidate
operation. Core neither verifies that claim nor authenticates the selected
schema. The policy is not itself that schema, carries no schema identity,
authenticates no caller and grants no logging, export or privacy permission.
Generic Core code does not synthesize or widen it. Callers must not derive it
from the collection bytes being decoded.

Configured construction admits repeated occurrences only for exact keys in the
supplied policy. It retains every occurrence in input order, including entries
whose values or privacy classes differ. The policy cannot select first/last,
change order, coerce a value, resolve `hostDefined`, combine privacy classes or
make one occurrence authoritative.

A collection containing repeats remains a valid immutable value after checked
construction, but its admission witness is deliberately not stored. Equality
therefore proves equal ordered content, not validity under a different policy.
Portable or distributed data that needs repeat permission must use a future
enclosing canonical envelope that binds a trusted schema identity/version and
supplies a compatible policy during type-level decoding.

### Hard collection and policy ceilings

The hard version-one collection ceilings are:

| Metric | Maximum | Exact accounting |
|---|---:|---|
| Entries | 1,048,576 | Count every outer `MetadataEntry` occurrence, including equal or copy-on-write-shared values. |
| Aggregate structural elements | 1,048,576 | Sum the `ADR-0031` logical structural count of every entry value. Every value and nested object member occurrence is charged; repeated shared subtrees are charged repeatedly. |
| Aggregate logical variable payload | 67,108,864 bytes (64 MiB) | Count both exact UTF-8 key fields of every outer entry plus every entry value's complete `ADR-0031` logical variable payload. A standalone leaf becomes aggregate-charged when stored in a collection. |
| Multiplicity-policy keys | 1,048,576 | Count every supplied policy-key occurrence before set normalisation. |
| Multiplicity-policy logical key payload | 67,108,864 bytes (64 MiB) | Count both exact UTF-8 fields of every supplied policy-key occurrence before set normalisation. |

Fixed privacy enum storage, fixed field/case names, JSON escaping, Base64
expansion, allocator overhead and private index storage are not logical variable
payload. Every count and addition uses checked `UInt64` arithmetic; overflow is
the corresponding typed limit failure and never wraps.

Collection construction preflights an available source count before reserving
storage, charges policy/entry/value metrics before accepting each occurrence and
materialises one `ContiguousArray`. Decoding prechecks an available unkeyed count
and threads remaining work/payload budgets into internal entry/value decoding;
it does not decode an unbounded entry array and validate only afterward.
Encoding completes duplicate, policy and budget preflight before requesting an
encoder container or writing any entry.

These are representation-safety ceilings, not host admission defaults. A host
or adapter may impose lower document, token, entry, string, binary, policy or
aggregate limits. A valid standalone leaf may exceed 64 MiB under its leaf ADR,
but cannot enter a collection above this aggregate ceiling. Raw decoders may
allocate a token before the model sees it, so byte/token/pre-allocation limits
remain adapter and canonical-ingress obligations.

The numerical values deliberately align with the proposed `ADR-0031` work and
payload powers of two, but form a new collection contract rather than inherited
evidence. Acceptance requires focused boundary checks on every supported build
destination and representative lowest-resource Apple hardware.

### Ordinary and configured type-level Codable

The manual type-level wire remains the prescribed one-field object:

```json
{
  "entries": [
    {
      "key": {"namespace":"example","name":"field"},
      "value": {"string":"x"},
      "privacyClass": "technical"
    }
  ]
}
```

Ordinary construction and ordinary `init(from:)` use `uniqueKeysOnly`.
Ordinary encoding first revalidates with `uniqueKeysOnly`; it throws
`MetadataCollectionError.multiplicityPolicyRequired` directly, before obtaining
an encoder container, when the value contains a repeat. It never uses
`EncodingError.invalidValue` with the collection or an entry as its associated
value.

Configured construction is explicit at the initializer. Configured top-level
Foundation coding is explicit at the call site:

```swift
let data = try JSONEncoder().encode(collection, configuration: policy)
let decoded = try JSONDecoder().decode(
    MetadataCollection.self,
    from: data,
    configuration: policy
)
```

`encode(to:configuration:)` performs a full preflight with that exact policy
before writing. This prevents a collection admitted under one snapshot from
being encoded under a stale or narrower snapshot. Configured decoding applies
the same constructor rules incrementally. Neither path serialises the policy,
and no permissive default exists.

Both decode paths require exactly `entries`, reject missing, null, distinct
extra or wrong-shaped fields and enforce all budgets. Outer-shape and field-set
failures use a fixed empty model-relative path; `entries` payload and collection-
invariant failures use the fixed model-relative `entries` path. Neither copies
arbitrary caller paths or exposes entry indices, counts, keys, values, privacy
cases, policy keys or child errors. An underlying error is retained only when
it is an explicitly audited payload-free Voxelia error.

This is semantic type-level representation, not canonical document bytes or
export authorisation. A general keyed decoder may already have collapsed raw
duplicate JSON member names, normalised tokens or allocated payloads. Raw
duplicate-member rejection, schema-version binding, lexical rules, canonical
order and persistent signatures/digests remain canonical-ingress work.

### Typed-read cardinality boundary

Broad typed access remains deferred until a reviewed mapping connects
`MetadataKey<Value>` to supported `MetadataValue` cases. This ADR nevertheless
fixes the cardinality rule so a later accessor cannot silently choose:

- a single-value read with no exact-key match returns a typed payload-free
  missing-value failure;
- a single-value read with more than one exact-key match returns a typed
  payload-free multiple-values failure, even when multiplicity was permitted;
- a single match whose erased case cannot produce the requested type returns a
  typed payload-free type-mismatch failure; and
- a future multi-value read preserves match order and validates every element,
  never coercing or dropping a mismatch.

The exact public accessor, conversion protocol and error-type names require the
typed-access decision. Its errors never associate the requested key, expected
type, actual case, value or cardinality.

### Privacy, logging and export boundary

The collection has no aggregate privacy class, comparison, join, maximum or
effective-class cache. It preserves every entry declaration exactly, including
every `hostDefined` occurrence. Multiplicity permission is structural admission
only and cannot resolve, downgrade or authorise an entry.

Collection structure can itself disclose information. Neither
`MetadataCollection` nor `MetadataMultiplicityPolicy` gains a textual or debug-
description conformance or a safe-display claim. Ordinary Swift reflection can
still expose stored entries or private policy keys, so library and host code
must not interpolate or reflect either raw value into logs, telemetry, filenames
or user interfaces.

Audited collection-owned logs, telemetry and error descriptions omit:

- entry count and order;
- indices and gaps;
- duplicate-group cardinality;
- hashes;
- keys and values;
- privacy classes; and
- policy contents.

Fixed type/error names may be logged only where they reveal no source data. A
host-authorised filtered export creates a fresh compact ordered collection of
authorised entries. It does not reveal original indices, denied counts, gaps,
duplicate-group sizes or the presence of `hostDefined` entries unless the host
explicitly authorises that structural disclosure. Whether export rejects,
filters or redacts remains a host/export API decision; ordinary or configured
Codable never grants permission.

## Alternatives considered

### Reject every repeated key permanently

This is safe for a context-free subset but cannot represent a state the
controlled invariant explicitly permits. Keeping ordinary construction
unique-only is useful; preventing an explicit configured path would silently
narrow the metadata model.

### Accept all repeated keys

This treats absence of schema authority as permission and violates the default
invariant. It also makes accidental duplicates valid without evidence.

### Store or serialise the multiplicity policy

A wire-provided allow-list would let untrusted input waive its own duplicate
validation. Storing it would also make a caller assertion look like portable
schema identity and force policy into equality, hashing and the one-field wire.
The future canonical envelope needs an authenticated/versioned schema reference,
not an untrusted embedded allow-list.

### Use Decoder.userInfo, global registration or task-local policy

These hide required context, complicate nesting, permit lifecycle and
cross-tenant mistakes and are difficult to reason about under strict
concurrency. Explicit Foundation coding configuration keeps context visible at
the call site and immutable during the operation.

### Publish a live namespace-schema resolver in Core

No governed schema identity, compatibility model, registration lifecycle or
resolver failure contract exists. A finite resolved snapshot is sufficient for
local admission. The broader resolver belongs to the adapter/host or a future
reviewed schema boundary.

### Use a separate duplicate-capable collection wrapper

Two public collection/wire types would divide one controlled semantic record
and invite conversions that lose multiplicity context. Ordinary and configured
coding can share one ordered value while making the context requirement explicit.

### Convert repeated values into a MetadataValue array

Multiplicity and array-valued metadata are different. Conversion changes the
stored value, typed access, order and source representation and may combine
privacy declarations that must remain separate.

### Deduplicate by full entry equality or use first/last wins

Entry equality includes privacy class, while the invariant is about keys.
Equality-based dedup misses differently classified duplicates; first/last wins
silently loses data and restriction signals. Every occurrence is retained or
construction fails.

### Canonical-sort entries

No controlled comparator exists for complete values or privacy classes, and
same-key order may carry source meaning. Input-order semantics preserve all
information and match the prescribed array. A later canonical projection may
make a separately reviewed choice.

### Add typed conversion in this ADR

The generic `MetadataKey<Value>` parameter alone does not define conversion
from an erased recursive case to arbitrary `Value`. Freezing an ad hoc protocol
would couple independent construction and typed-access concerns. Only the
no-silent-cardinality rule is safe to settle here.

## Consequences

- `MetadataCollection` is one ordered immutable sequence; equality, hashing and
  type-level encoding preserve complete input order.
- Ordinary construction/Codable is safe and unique-only.
- Repeats that the caller asserts its schema permits require an explicit
  bounded immutable configuration for construction, encoding and decoding;
  the configuration never appears on the wire or in collection identity.
- Every repeated entry and privacy declaration is retained; there is no
  deduplication, inferred privacy aggregate or implicit reclassification.
- A duplicate-rich collection has no context-free ordinary Codable round trip;
  ordinary encoding fails before output and configured coding is required.
- Hard policy, entry, aggregate-work and payload ceilings prevent typed values
  from multiplying individually valid roots without bound.
- Ordered semantic identity may distinguish collections that a future schema
  considers equivalent; any normalised persistent identity must be separately
  named and reviewed.
- Typed conversion, portable schema identity, canonical bytes and concrete
  logging/export behaviour remain explicit later work.
- No collection source is authorised while this ADR or `ADR-0028` through
  `ADR-0032` remains Proposed.

## Affected modules

If accepted, `VoxeliaCore` owns `MetadataCollectionError`,
`MetadataMultiplicityPolicy` and `MetadataCollection` alongside the entry and
value types. Foundation's configuration-aware Codable protocols add no package
dependency and are available on Voxelia's declared minimum Apple platforms.

Adapters and hosts own trusted namespace-schema selection and resolve it to a
bounded policy snapshot. They also own lower admission limits, logging/export
authorisation and any canonical envelope that identifies the schema. Downstream
Imaging, Storage, provenance, DICOM and host modules consume the immutable
collection without changing Core's dependency direction.

## Compatibility impact

No public `MetadataCollection`, `MetadataEntry` or recursive metadata source
exists. The proposal preserves the controlled one-field collection and
successful unique-only ordinary wire. It makes the previously unstated order
semantic and explicitly narrows ordinary encoding of a configured duplicate-
bearing value rather than claiming a false context-free round trip.

After implementation, entry order, exact-key duplicate comparison, ordinary
unique-only coding, configured multiplicity, error cases, field name and hard
ceilings become pre-1.0 compatibility contracts. A future portable schema must
add an enclosing versioned context rather than silently changing the one-field
type-level wire or treating the allow-list as schema identity.

## Security impact

Default deny prevents an absent policy from admitting duplicates. Explicit
configuration cannot be supplied by the bytes it validates, and full preflight
prevents partial output under a wrong policy. Bounded immutable snapshots avoid
mutable callbacks, global registration and cross-task policy races.

Exact-key detection closes whole-entry-equality bypasses, including duplicates
whose values or privacy classes differ. No deduplication prevents a less
restrictive occurrence from hiding a stricter or unresolved declaration.
Audited collection-originated payload-free errors and fixed paths avoid
reflecting patient-identifying keys, values, policy contents or collection
structure. Arbitrary Foundation, adapter, host and reflection output remains
outside that guarantee and must be sanitised before logging.

The public policy remains a caller assertion, not an authenticated capability.
A malicious host can construct an inappropriate snapshot just as it can supply
an incorrect entry classification. Canonical schema authentication, adapter
trust, host privacy, authorisation and audit remain outside Core.

Type-level decoding occurs after a general decoder may allocate source data.
Hard semantic budgets bound admitted values, but hostile byte/token limits and
raw duplicate-member detection still belong before or inside canonical ingress.

## Performance and memory impact

Construction and preflight are O(entries + logical structural elements +
logical variable payload accounting). Exact-key duplicate checks use an
ephemeral set with expected O(1) lookup; the policy uses a bounded exact-key
set. Ordered storage is one `ContiguousArray` and may share safe copy-on-write
storage after validation.

Configured and ordinary encoding deliberately perform a full O(n) preflight
before a second encoding traversal. This cost prevents partial output and stale
policy use. Decoding streams the entry array, applies remaining budgets before
append and may privately reserve from a bounded advertised count.

A private derived lookup index may be added when evidence justifies it. It must
not change public order, equality, hashing or wire and must not expose shared
mutation. No aggregate privacy or policy cache is stored.

## Validation impact

Before acceptance and implementation, focused evidence must cover:

- strict Swift concurrency and `Sendable` checking for collection and policy;
- empty, one-entry and boundary-size construction;
- exact input-order preservation and order-sensitive equality/hash;
- second-occurrence rejection by exact key under ordinary construction;
- configured admission of only allow-listed exact keys, retaining every
  occurrence and privacy class in order;
- policy count/payload, entry count, aggregate structural and aggregate payload
  limits at maximum, maximum plus one and checked-overflow boundaries;
- repeated copy-on-write subtrees charged per occurrence;
- unique-only ordinary Codable round trips;
- duplicate-rich ordinary encoding failure before encoder-container creation;
- configured encoding/decoding round trips and revalidation under a wrong or
  narrower policy;
- proof that policy is absent from the one-field wire and cannot be recovered
  from decoder bytes;
- missing, null, distinct-extra and wrong-shaped field rejection;
- raw duplicate-member deferral to canonical ingress;
- fixed empty outer/field-set paths and fixed `entries` payload/invariant paths
  with no caller path, entry index, count, key, value, privacy class, policy
  text or arbitrary child error in descriptive and reflective failures;
- no aggregate privacy field or inferred class;
- future single-value cardinality tests for missing, multiple and type mismatch
  before typed access ships;
- directly affected Core/dependent builds and prohibited-import checks; and
- production ceiling evidence on every supported destination plus representative
  lowest-resource Apple hardware.

The checked-in isolated Swift probe uses deliberately small limits to exercise
the proposed shape, ordered identity, exact-key admission, bounded policy,
ordinary/configured coding split, encoding revalidation, aggregate accounting,
privacy preservation, strict fields and caller/key/value redaction. Its reduced
string entry decoder charges semantic budgets after each decoded entry; it does
not prove that the production recursive value decoder threads remaining budgets
before accepting every child. That stays required implementation evidence. The
probe is not production API, policy-authority proof, canonical-byte evidence or
numerical-ceiling acceptance. No full package suite is warranted for this
Proposed documentation boundary.

## Migration

After `ADR-0028` through `ADR-0033` are accepted and both recursive and
collection ceiling evidence is approved:

1. correct Core Data Model Specification sections 34.5 through 34.8, 37.2, 55,
   58, 64.6 and 70.5 to define ordered storage, required entry privacy,
   unique-only ordinary coding, explicit configured multiplicity, cardinality
   failures and collection validity under unique-only or caller-asserted
   configured admission rather than unconditional uniqueness or independent
   proof that a namespace schema permits a repeat;
2. implement the collection error, bounded policy snapshot and ordered
   collection in `VoxeliaCore` with shared checked construction/coding paths;
3. add the focused invariant, configuration, limit, identity, wire, redaction,
   concurrency and static-dependency tests listed above;
4. gather supported-destination and lowest-resource-device boundary evidence;
5. keep typed conversion/accessor shape, canonical schema identity, raw ingress,
   persistent digest, concrete logging/export and host resolver APIs deferred to
   their own accepted decisions; and
6. update traceability, changelog, API documentation, validation reports and
   release-integrity evidence.

No recursive metadata, entry or collection migration step may begin while a
dependency remains Proposed.

## Supersession

This Proposed ADR neither supersedes nor is superseded by another file-backed
ADR. It depends on the leaves and bounded recursive value proposed by
`ADR-0028` through `ADR-0031` and the classified entry proposed by `ADR-0032`.
It completes only ordered collection construction and type-level multiplicity
admission if accepted. It does not supersede canonical serialisation, typed
access, privacy policy, provenance, persistent identity or host-authorisation
decisions.

## References

- [Voxelia Core Data Model Specification v0.1.1, sections 34, 37.2, 55, 56, 58, 64.6, 66 through 70 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 12, 36 and 37](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Project Foundation v0.1.1, sections 7, 19, 22 and 27](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.1, 6.6, 6.7, 6.10 and 6.34 through 6.36](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, sections 5.8, 7, 35, 38 and 49.2](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0031 - Bounded recursive metadata value boundary](ADR-0031-bounded-recursive-metadata-value-boundary.md)
- [ADR-0032 - Required metadata-entry privacy attachment](ADR-0032-required-metadata-entry-privacy-attachment.md)
- [Apple Developer Documentation - CodableWithConfiguration](https://developer.apple.com/documentation/foundation/codablewithconfiguration)
- [Apple Developer Documentation - DecodableWithConfiguration](https://developer.apple.com/documentation/foundation/decodablewithconfiguration)
