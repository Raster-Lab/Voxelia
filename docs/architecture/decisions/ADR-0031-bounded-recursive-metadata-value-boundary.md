---
document_id: "ADR-0031"
title: "Bounded recursive metadata value boundary"
status: "Proposed"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-ARC-003"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
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

# ADR-0031 - Bounded recursive metadata value boundary

## Context

The Core Data Model Specification prescribes eleven recursive metadata cases:

```swift
public enum MetadataValue: Sendable, Hashable, Codable {
    case boolean(Bool)
    case signedInteger(Int64)
    case unsignedInteger(UInt64)
    case floatingPoint(Double)
    case string(String)
    case binary(Data)
    case instant(String)
    case unit(MeasurementUnit)
    case code(CodedConcept)
    case array(ContiguousArray<MetadataValue>)
    case object(ContiguousArray<MetadataEntry>)
}
```

It separately requires unique object keys, explicit enum tags, stable
serialisation and host-controlled resource limits. The raw recursive cases do
not enforce those requirements. A public enum case has the enum's public access
and cannot be replaced by a throwing factory with the same pattern-matching
shape, so every caller could directly construct an object with duplicate keys
or a recursive value that bypasses resource validation.

`ContiguousArray` supplies enough indirection for the reciprocal enum, entry
and container declarations to compile, but that does not make arbitrary depth
safe. A Swift 6.3.3 subprocess probe trapped while hashing a 50,000-container
chain. Iterative equality and hashing avoid that traversal stack failure, but
the physically recursive public shape still requires a hard container-depth
invariant or a flat arena representation; a host-only JSON limit cannot protect
programmatic construction or bound recursive storage teardown.

Depth alone is also insufficient. Copy-on-write storage lets a caller build
`value = .array([value, value])` repeatedly with only linear physical storage,
while the semantic tree, equality, hashing and encoding work double at every
level. The logical tree has `2^(d + 1) - 1` value occurrences at depth `d`.
Variable payload has the same amplification when a shared string, key, code,
unit or binary leaf occurs more than once. The value boundary needs finite
logical-work and logical-payload ceilings in addition to a depth ceiling.

Three earlier proposals select corrected leaf contracts if accepted:

- `ADR-0028` replaces the raw instant with `CanonicalInstant`;
- `ADR-0029` replaces the raw `Double` with `MetadataFloatingPoint`; and
- `ADR-0030` replaces the raw `Data` with `MetadataBinary`.

The isolated string audit retains raw `String` and recommends exact UTF-8
branch identity, but deliberately leaves approval of that identity projection
to the recursive aggregate decision. This proposal accepts that candidate.

The general two-field `MetadataEntry` cannot safely be frozen here while the
specified privacy classification has no attachment, default, nesting,
downgrade or wire policy. Adding classification later could change entry
construction, equality, hashing and strict encoding. Recursive object members
therefore receive a distinct privacy-neutral nested type. General
`MetadataEntry`, `MetadataCollection`, multiplicity, typed access and privacy
attachment remain separate decisions. Proposed `ADR-0032` now selects a
required direct entry classification and whole-entry privacy scope, but remains
unaccepted and does not change this value proposal's independent member.

This proposal selects the bounded semantic value model and its type-level
Codable shape only. It does not select complete canonical JSON bytes, raw
duplicate-member detection, a schema-version document, adapter mapping,
collection policy, privacy policy or a persistent digest. Its Proposed status
does not authorise implementation or controlled-document changes.

## Decision

If this ADR and its three leaf dependencies are accepted, `VoxeliaCore` will
own the following public shape:

```swift
public enum MetadataValueError: Error, Sendable, Equatable {
    case duplicateObjectKey
    case containerDepthLimitExceeded
    case structuralElementLimitExceeded
    case logicalPayloadByteLimitExceeded
}

public struct MetadataArray: Sendable, Hashable {
    public let values: ContiguousArray<MetadataValue>

    public init<Values: Collection>(values: Values) throws
    where Values.Element == MetadataValue
}

public struct MetadataObject: Sendable, Hashable {
    public struct Member: Sendable, Hashable {
        public let key: AnyMetadataKey
        public let value: MetadataValue

        public init(key: AnyMetadataKey, value: MetadataValue)
    }

    public let members: ContiguousArray<Member>

    public init<Members: Collection>(members: Members) throws
    where Members.Element == Member
}

public enum MetadataValue: Sendable, Hashable, Codable {
    public static let maximumContainerDepth = 64
    public static let maximumLogicalStructuralElementCount: UInt64 = 1_048_576
    public static let maximumRecursiveContainerLogicalVariablePayloadByteCount: UInt64 = 67_108_864

    case boolean(Bool)
    case signedInteger(Int64)
    case unsignedInteger(UInt64)
    case floatingPoint(MetadataFloatingPoint)
    case string(String)
    case binary(MetadataBinary)
    case instant(CanonicalInstant)
    case unit(MeasurementUnit)
    case code(CodedConcept)
    case array(MetadataArray)
    case object(MetadataObject)
}
```

`MetadataArray`, `MetadataObject` and `MetadataObject.Member` do not gain
standalone `Codable` conformances in version one. Their only stable wire role is
the payload owned and encoded by `MetadataValue`; publishing additional
standalone wire shapes would add compatibility surface without a requirement.

### Recursive structural invariants

The hard version-one ceilings are:

| Metric | Maximum | Exact accounting |
|---|---:|---|
| Container depth | 64 | A leaf is depth zero. An empty array or object is depth one. A nonempty container is one plus the greatest child depth. A member does not add depth. |
| Logical structural elements | 1,048,576 | Count every `MetadataValue` occurrence and every `MetadataObject.Member` occurrence, including repeated copy-on-write-shared subtrees. The root value counts once. |
| Recursive-container logical variable payload | 67,108,864 bytes (64 MiB) | For an array or object root, count every occurrence of the exact stored variable bytes listed below, including repeated shared payloads. This metric does not cap a standalone leaf. |

Logical variable payload includes:

- raw `.string` UTF-8 bytes;
- `CanonicalInstant` stored UTF-8 bytes;
- `MetadataBinary` decoded bytes;
- both UTF-8 identity fields of every object-member key;
- all present stored strings in `CodedConcept`, including display meaning and
  version; and
- all present stored strings in `MeasurementUnit`, including display name.

Fixed case tags, Boolean and integer storage, finite binary64 storage, fixed
enum values, in-memory allocator overhead, JSON field names, JSON escaping and
Base64 expansion are not logical variable payload. Fixed work is bounded by
the structural-element ceiling; raw and encoded document bytes require their
own earlier ingress limits.

Each validated container will cache its derived depth, structural-element
count and logical-payload byte count privately. Metrics count semantic
occurrences, not unique storage buffers. Every addition uses checked `UInt64`
arithmetic; arithmetic overflow is the corresponding typed limit failure and
never wraps. Cached metrics and the numeric ceilings do not participate in
equality, hashing or encoding.

Container initialisers will preflight the source collection count before
reserving storage, accumulate child metrics before accepting each element and
materialise one immutable `ContiguousArray`. An existing safely shareable
`ContiguousArray` may share copy-on-write storage, but later mutation of either
copy must not alter the accepted value. Empty arrays and objects are valid.

These are representation-safety ceilings, not host admission defaults. A host
may impose lower document, token, depth, element, entry, string, binary or
aggregate limits, but no host may construct a value above the hard ceilings.
Host policy is not passed to these context-independent value initialisers and
does not become value identity.

A valid standalone string, code, unit or `MetadataBinary` leaf retains its
leaf-level domain and may exceed 64 MiB. Such a leaf cannot be embedded in an
array or object whose logical payload would exceed this aggregate ceiling.
This distinction preserves the uncapped standalone leaf contracts while
preventing recursive copy-on-write amplification. Untrusted standalone leaves
still require host and raw-ingress limits before allocation.

The numerical ceilings are proposed engineering contracts, not values derived
from the observed crash threshold or from JSON syntax. Powers of two make
boundary and overflow evidence exact. Depth 64 bounds recursive storage
destruction and Codable descent; 2^20 bounds worst-case structural traversal;
64 MiB is a deliberately generous metadata payload ceiling while the
controlled specification directs large sample buffers outside descriptor
JSON. Acceptance requires focused boundary evidence on every supported
destination and representative lowest-resource Apple hardware.

### Array and object semantics

Array order is semantic and preserved exactly. Empty, one-element and nested
arrays are distinct values; construction does not flatten arrays, remove
values or reinterpret homogeneous arrays as typed buffers.

`MetadataObject` has map semantics. Caller order is not semantic and is not
preserved. Construction sorts members by unsigned UTF-8 lexicographic order of
`key.namespace`, then `key.name`; a proper byte prefix precedes its extension.
It compares the accepted bytes directly and never uses Swift `String`'s
canonical-equivalent ordering. Canonically equivalent but UTF-8-distinct key
spellings remain distinct.

After the bounded resource preflight, construction rejects two members with
the same exact `AnyMetadataKey`, regardless of whether their values are equal.
It detects duplicates by key, never by whole-member equality. The error is only
`.duplicateObjectKey` and contains no namespace, name, value or source text.
Canonical sorted storage makes object equality, hashing and type-level encoding
independent of caller order. A format where order carries meaning must use an
array or an adapter-owned representation rather than rely on object input
order.

`MetadataObject.Member` is a recursive object's structural key/value pair. It
is not the general collection entry and makes no privacy, multiplicity,
namespace-schema or typed-access claim. The eventual general `MetadataEntry`
must not expose an implicit privacy-erasing conversion to or from this
structural pair. Proposed `ADR-0032` instead selects direct key, value and
privacy-class fields for that separate record.

### Equality and hashing

Case tags participate in equality and hashing. Signed integer `1`, unsigned
integer `1` and floating-point `1.0` are distinct. Boolean and integer payloads
use exact ordinary value identity. The accepted leaf ADRs govern instant,
finite floating-point and binary identity.

The raw string branch uses exact UTF-8 byte-count and ordered-byte equality and
hashing. It does not use Swift `String`'s canonical-equivalence relation,
normalise text or compare raw JSON escape spelling. This approves the candidate
from the isolated string audit only for this aggregate.

Array equality is ordered. Object equality follows canonical member order,
exact key identity and recursive value equality. Unit and code cases delegate
to their existing semantic identities: `MeasurementUnit.displayName` and
`CodedConcept.meaning` remain preserved but excluded from leaf equality and
hashing. Consequently, two equal metadata values may have different ordinary
type-level encodings. `Hashable` is semantic in-memory identity, not canonical
record equality, a persistent digest or canonical JSON-byte identity.

Equality and hashing will use explicit iterative depth-first cursor frames with
O(container depth) auxiliary state. They must not recursively combine an
entire array, member or child value through synthesised `Hashable`, because
that can repeat traversal and consume recursive stack. Hashing combines a
stable in-process structural token sequence consisting of case discriminator,
container count, exact key fields and the case's equality-bearing payload.
Swift's process-randomised `Hasher` output must never be stored or used as a
content digest.

The hard ceilings bound total logical traversal and recursive destruction even
when copy-on-write buffers are shared. Implementations may exploit sharing for
storage but must never collapse repeated semantic occurrences during equality,
hashing or encoding.

### Type-level Codable

`MetadataValue` will implement Codable manually as an externally tagged object
with exactly one member:

| Case | Semantic JSON example |
|---|---|
| Boolean | `{"boolean":true}` |
| Signed integer | `{"signedInteger":-1}` |
| Unsigned integer | `{"unsignedInteger":1}` |
| Floating point | `{"floatingPoint":1.25}` |
| String | `{"string":"text"}` |
| Binary | `{"binary":"Zg=="}` |
| Instant | `{"instant":"2026-08-02T12:34:56Z"}` |
| Unit | `{"unit":{"namespace":"UCUM","code":"mm","displayName":null,"dimension":"length","scaleToCanonical":null,"offsetToCanonical":null}}` |
| Code | `{"code":{"scheme":"example","value":"A","meaning":null,"version":null}}` |
| Array | `{"array":[{"boolean":true},{"string":"x"}]}` |
| Object | `{"object":[{"key":{"namespace":"example","name":"field"},"value":{"string":"x"}}]}` |

The exact tag spellings are `boolean`, `signedInteger`, `unsignedInteger`,
`floatingPoint`, `string`, `binary`, `instant`, `unit`, `code`, `array` and
`object`. An object member encodes exactly `key` and `value`; its key retains
the strict two-field `AnyMetadataKey` representation. Objects encode members in
their canonical exact-key order and never turn arbitrary metadata keys into
dynamic JSON member names.

Decoding requires one and only one recognised outer tag and the exact payload
shape. It rejects zero tags, multiple distinct tags, unknown tags, null,
wrong-shape payloads, missing fields and distinct extra fields. Unknown-tag and
shape errors contain no arbitrary tag or payload text. Empty string, binary,
array and object values remain valid and are not aliases for null or absence.
Leaf decoders revalidate their own invariants.

The decoder will thread depth and structural-element budgets through one root
traversal. When the root tag is `array` or `object`, it will also activate the
recursive-container logical-payload budget before decoding the first child or
member key; every nested leaf is then charged. A standalone leaf root is not
charged against that aggregate budget and retains its leaf domain. Decoding
rejects before adding a child that would exceed a hard ceiling; it will not
decode an unbounded tree and validate only after construction. Model-originated
decode failures use value-redacted
`DecodingError.dataCorrupted` with a typed underlying `MetadataValueError` where
applicable. Encoding never embeds `self`, a member, key or payload in
`EncodingError.invalidValue`; Foundation may reflect such a value and disclose
the entire recursive tree.

The signed and unsigned payloads are JSON numbers covering the complete
`Int64` and `UInt64` domains. Their tag is part of identity. Type-level decoding
establishes the integer value, not raw token spelling: an underlying decoder
may accept `1`, `1.0` and `1e0` for the same integer or normalise `-0` to zero.
Raw canonical ingress must use an exact integer parser and decide the one
accepted lexical form.

Unmodified JCS uses a binary64 number model and cannot round-trip the full
prescribed `Int64`/`UInt64` domain. Proposed `ADR-0035` now selects an explicitly
versioned canonical-document shape whose integer payloads are exact decimal
JSON strings, while keeping this ordinary type-level numeric representation.
It must not silently narrow the semantic cases, remains unaccepted and does
not make ordinary `JSONEncoder` output canonical JSON.

Type-level Codable cannot detect duplicate raw JSON member names after a
general decoder has collapsed them, cannot bound a token before that decoder
allocates it and cannot prove canonical escape, integer, Base64, order,
whitespace or schema-version bytes. Those hostile-byte and persistent-digest
properties remain canonical-ingress work.

### Error and privacy boundary

Every `MetadataValueError` is value-redacted and has no associated payload.
Model-originated diagnostics may name fixed case or field vocabulary and safe
numeric indices, but must never contain metadata keys, strings, binary or
Base64 data, instants, code or unit text, raw JSON fragments or an arbitrary
unknown tag. Their coding paths are rebuilt from fixed model fields and safe
numeric indices; they never copy a caller-supplied `Decoder.codingPath`.
Underlying encoder and decoder errors may be outside this guarantee and must be
sanitised before logging.

The value, array, object and member types add no textual or debug-description
conformance and make no safe-display claim. Values may contain patient-
identifying or otherwise sensitive metadata. Hosts must not interpolate them
into logs, telemetry, filenames or user interfaces. General privacy
classification, attachment, inheritance, nested aggregation, downgrade
prevention, `hostDefined` resolution and export authorisation remain outside
this value. Proposed `ADR-0032` addresses the local entry attachment and
whole-entry scope only. Proposed `ADR-0033` addresses ordered collection
construction and explicit multiplicity admission without adding a privacy
aggregate; host enforcement remains deferred.

### Dependency reconciliation

`ADR-0028`, `ADR-0029` and `ADR-0030` remain Proposed and have no authority or
source implementation. Their earlier migration text conservatively made
privacy and collection approval prerequisites for use inside `MetadataValue`.
This proposal separates the privacy-neutral recursive object member from the
general entry, so those layers no longer need to be frozen merely to review the
semantic value.

The three leaf proposal files are updated alongside this proposal to state the
joint dependency precisely: a leaf may enter `MetadataValue` only after that
leaf ADR and this bounded aggregate ADR are both accepted. General entries,
collections, privacy and canonical byte ingress remain deferred and cannot be
inferred from that joint acceptance.

Proposed `ADR-0032` depends on this value but is not a prerequisite for the
privacy-neutral value implementation. It selects a separate required
classification on the general entry and forbids implicit member/entry
conversion. Neither proposal has authority while Proposed.

Proposed `ADR-0033` depends on this value and on `ADR-0032`, but likewise is
not a prerequisite for reviewing this privacy-neutral value. It reuses this
ADR's cached structural and logical-payload metrics to impose separate
collection-wide ceilings. Those ceilings are new proposed contracts and do
not amend the standalone value limits while either record remains Proposed.

Proposed `ADR-0034` also depends on the exact eleven associated payloads in
this value. It selects only closed exact-case read projections and does not
change this ADR's case identity, storage, wire or recursive invariants. It is
not a prerequisite for reviewing the privacy-neutral value and has no authority
while Proposed.

`ADR-0030` continues to permit any finite standalone `MetadataBinary` if
accepted. This ADR proposes a separate hard logical-payload ceiling only when a
leaf is embedded in a recursive array or object. It therefore refines the
aggregate side of the earlier host-limit discussion without adding an
intrinsic maximum to `MetadataBinary` itself.

## Alternatives considered

### Retain raw recursive associated values

This preserves the controlled sketch verbatim, but callers can bypass object
uniqueness and every resource invariant. Synthesised equality, hashing,
Codable and destruction also do not provide a safe arbitrary-depth contract.
Validation only at `MetadataCollection` binding would leave invalid standalone
values public.

### Use a flat arena-backed MetadataValue struct

A private flat node arena could avoid recursive destruction and make every
construction path validated. It would also remove direct enum pattern matching,
require a larger traversal API and depart further from the controlled shape.
The bounded nominal-container correction is smaller. A flat representation is
the required fallback if governance rejects finite recursive ceilings.

### Enforce only host-selected ingress limits

Host limits are necessary for hostile bytes but do not constrain direct Swift
construction or copy-on-write amplification. They cannot make an unrestricted
recursive public enum safe. Hosts may select tighter limits, but a physically
recursive representation still needs project hard ceilings.

### Publish the general two-field MetadataEntry now

This matches the current sketch, but freezes the likely privacy attachment
point before privacy semantics exist. A distinct nested object member keeps
the value reviewable without deciding collection multiplicity, classification
or export policy.

### Preserve object input order as identity

This is simple with `ContiguousArray`, but gives map-equivalent objects
different equality, hashes and encodings. JSON objects are unordered and the
controlled model requires unique keys. Ordered source data can be represented
by an array without overloading object identity.

### Encode object keys as dynamic JSON member names

`AnyMetadataKey` is a pair of opaque strings. Joining them into one property
name requires an escaping grammar and risks namespace collisions; dynamic
names also expose arbitrary metadata in coding paths and diagnostics. A sorted
array of strict key/value member records is lossless and bounded.

### Use canonical JSON bytes as Hashable identity

This would couple in-memory equality to an unselected serializer and conflict
with existing code/unit semantic identity, which excludes presentation text
that Codable preserves. Persistent identity remains a separately versioned
canonical projection and digest.

### Choose no hard node or payload ceiling

Iterative equality and hashing would still permit exponential copy-on-write
work and recursive destruction. Some finite ceiling is mandatory for this
representation. The proposed values remain subject to focused acceptance
evidence rather than becoming implementation facts through convenience.

## Consequences

- Recursive construction becomes valid by construction through two nominal
  immutable containers.
- Array order remains semantic; object order becomes canonical and exact-key
  duplicates cannot enter a public value.
- Every recursive container subtree has finite depth, structural work and
  logical variable payload, including repeated shared subtrees.
- A standalone valid leaf may be too large to embed in a recursive container;
  this is an explicit aggregate-safety rule rather than silent truncation.
- The raw string case gains exact UTF-8 aggregate identity without an extra
  public string wrapper.
- Strict one-tag semantic Codable replaces compiler-shaped `_0` envelopes, but
  complete canonical JSON and persistent identity remain deferred.
- The distinct nested member avoids prematurely freezing general entry privacy
  or multiplicity semantics, at the cost of one additional public nested type.
- The three hard ceilings become pre-1.0 compatibility contracts after
  acceptance; lowering one could invalidate a previously constructible value.
- No implementation is authorised while this ADR or a required leaf ADR
  remains Proposed, and the candidate ceilings require supported-destination
  validation before acceptance.

## Affected modules

If accepted, `VoxeliaCore` will own `MetadataValueError`, `MetadataArray`,
`MetadataObject`, its nested `Member` and `MetadataValue`. The value continues
to consume Core-owned leaves and the already approved `VoxeliaCore ->
VoxeliaSpatial` dependency for `MeasurementUnit`. No dependency edge, product
or backend ownership changes.

Adapters, Storage, provenance, DICOM, distributed and host applications remain
downstream consumers. They must apply source-schema, privacy and tighter
resource policy before constructing or publishing these context-independent
values.

## Compatibility impact

No public `MetadataValue`, recursive container, general entry or serialised
metadata fixture exists. Correcting raw recursive cases and leaf payloads before
implementation moves no compiled symbol or persisted artefact.

Once implemented, public case names, associated payload types, hard ceilings,
object ordering, duplicate identity, semantic equality and type-level tags
become pre-1.0 compatibility contracts. Wrapper-private metrics and storage
layout remain implementation details. Canonical document versions and general
entry/collection formats remain separate compatibility surfaces.

## Security impact

Validated containers prevent direct duplicate-key and resource-limit bypass.
Depth bounds recursive storage destruction. Logical structural and payload
accounting prevents copy-on-write graphs with small resident storage from
causing unbounded equality, hashing or encoding work. Checked arithmetic
prevents counter wraparound from reopening those bounds.

These controls are not a hostile-byte parser. A general JSON decoder may have
already allocated a huge token, built a deep internal tree, collapsed duplicate
member names or produced an error containing source text before
`MetadataValue` runs. Canonical and adapter ingress must bound raw document,
token, raw nesting, direct-container count, decoded strings, decoded binary,
numeric-token length and total decoded payload before allocation where
possible. It must sanitise upstream errors and enforce host privacy policy.

The hard ceilings limit work but do not guarantee responsiveness under every
host budget. Hosts may need much smaller values and cancellation-aware parsing.
No value contract supplies authenticity, trust, encryption, authorisation or
patient-data consent.

## Performance and memory impact

Array construction is O(n) in direct children. Object construction performs
O(n log n) key comparisons for canonical sorting plus exact-key validation;
time also scales with the UTF-8 bytes examined, and adversarial common prefixes
may be rescanned across comparisons. Both materialise immutable contiguous
storage and cache metrics using checked arithmetic. Safely shareable children
may retain copy-on-write storage, but logical accounting charges each
occurrence. Hosts may therefore require smaller member, key-byte or aggregate
limits than the representation ceilings.

Equality, hashing and semantic encoding are O(logical structural elements plus
visited variable payload bytes), capped by the hard limits for recursive
containers. Iterative cursor traversal uses O(container depth) auxiliary
frames. Object lookup remains linear in version one unless a private index is
added without changing public identity; the controlled internal indexing
decision remains open.

Decoded strings, Base64 text and a general decoder's parse tree may coexist
temporarily with constructed values. Raw parsers and host admission must budget
those peaks separately. The proposed 2^20 and 64 MiB ceilings require measured
acceptance evidence on representative supported Apple devices; this
documentation-only proposal makes no benchmark claim.

## Validation impact

Before acceptance and implementation, focused evidence must cover:

- strict Swift concurrency and `Sendable` checking for the reciprocal public
  shape;
- an API-surface compile check proving raw arrays/objects and duplicate keys
  cannot bypass the throwing wrappers;
- empty containers, depth 64 success and depth 65 typed rejection across
  programmatic and decode paths;
- exact hard-limit and one-over failures for structural elements and logical
  payload, plus checked-counter overflow without corresponding allocation;
- a standalone leaf above 64 MiB round trip together with rejection when that
  same leaf is embedded in a recursive container;
- the `[value, value]` copy-on-write amplification oracle, including 1,048,575
  accepted and 2,097,151 rejected logical value occurrences;
- source and returned-array mutation proving snapshot value semantics;
- exact-key duplicate rejection with equal and unequal values, exact-distinct
  canonical-equivalent keys, prefix keys and canonical unsigned-UTF-8 order;
- ordered array and order-independent object equality, hashing, set behaviour
  and encoding;
- exact UTF-8 string identity and every accepted leaf identity projection;
- iterative equality and hashing at maximum depth and representative maximum
  width, followed by normal destruction;
- every tag and payload round trip, all integer extrema, semantic integer-token
  aliases and rejection of null, wrong shapes, missing, extra, multiple and
  unknown fields;
- object-member coding paths without dynamic arbitrary keys, including a
  model-originated failure decoded beneath an arbitrary caller dictionary key;
- value-redacted model errors and evidence that no encoding error reflects
  `self`, a member, key or payload;
- isolated subprocess rejection of adversarial deep or amplified inputs; and
- owning-Core and directly affected dependent builds with no prohibited import
  or dependency edge.

Boundary timing and peak-memory evidence must run on macOS and representative
lowest-resource supported iOS, iPadOS, tvOS and visionOS Apple Silicon devices
before the ceiling values are accepted. Canonical-byte, raw duplicate-key,
schema-version, privacy, collection, typed-access and adapter tests remain
separate. No Swift package suite is warranted while this ADR remains Proposed.

## Migration

After all four required ADRs are accepted and the ceiling evidence is approved:

1. correct Core Data Model Specification sections 34, 55, 58, 64 and 72 with
   the validated leaf payloads, nominal recursive containers, privacy-neutral
   object member, exact tags and hard ceilings;
2. implement the three accepted leaf proposals and their focused tests;
3. implement `MetadataValueError`, both containers, the nested member and
   `MetadataValue` with private checked metrics and iterative identity;
4. add the focused construction, amplification, Codable, privacy, property and
   static dependency evidence listed above;
5. keep general `MetadataEntry`, `MetadataCollection`, privacy attachment,
   multiplicity, typed access, canonical byte ingress and persistent digest
   identity governed by their own accepted decisions, including `ADR-0032` for
   the entry/privacy boundary and `ADR-0033` for the ordered collection and
   explicit multiplicity-policy boundary plus `ADR-0034` for closed typed
   reads and `ADR-0035` for versioned canonical document bytes; and
6. update traceability, changelog, API documentation and release-integrity
   evidence.

No migration step may begin while this ADR, `ADR-0028`, `ADR-0029` or
`ADR-0030` remains Proposed.

## Supersession

This Proposed ADR neither supersedes nor is superseded by another file-backed
ADR. It coordinates three Proposed leaf migrations but has no authority over
them while Proposed. If all are accepted, it governs only recursive semantic
value construction, identity, type-level Codable and hard container ceilings.
It does not supersede general metadata collection, privacy, canonical JSON,
adapter, provenance or persistent-identity decisions.

## References

- [Voxelia Core Data Model Specification v0.1.1, sections 5, 7, 34, 55, 58, 64, 66 through 68, 72 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 8, 12, 37 and 38](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Project Foundation v0.1.1, sections 25 through 29](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, metadata, malformed-input and resource-exhaustion sections](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.5 through 6.7, 6.10, 6.34 through 6.36](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [ADR-0028 - Canonical instant boundary](ADR-0028-canonical-instant-boundary.md)
- [ADR-0029 - Finite floating-point metadata boundary](ADR-0029-finite-floating-point-metadata-boundary.md)
- [ADR-0030 - Owned binary metadata boundary](ADR-0030-owned-binary-metadata-boundary.md)
- [ADR-0032 - Required metadata-entry privacy attachment](ADR-0032-required-metadata-entry-privacy-attachment.md)
- [ADR-0033 - Ordered metadata collection and explicit multiplicity policy](ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md)
- [ADR-0034 - Closed exact-case typed metadata read boundary](ADR-0034-closed-exact-case-typed-metadata-read-boundary.md)
- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
- [RFC 8259 - The JavaScript Object Notation Data Interchange Format](https://www.rfc-editor.org/rfc/rfc8259.html)
- [RFC 8785 - JSON Canonicalization Scheme](https://www.rfc-editor.org/rfc/rfc8785.html)
