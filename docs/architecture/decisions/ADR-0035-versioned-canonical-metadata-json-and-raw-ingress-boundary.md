---
document_id: "ADR-0035"
title: "Versioned canonical metadata JSON and raw ingress boundary"
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
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-DAT-014"
  - "VOX-META-001"
  - "VOX-META-002"
  - "VOX-ERR-001"
  - "VOX-ERR-003"
  - "VOX-ERR-007"
  - "VOX-SEC-001"
  - "VOX-SEC-003"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
  - "VOX-VAL-008"
  - "VOX-VAL-009"
  - "VOX-VAL-011"
---

# ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary

## Context

The Core Data Model Specification requires canonical JSON for descriptors and
records. It requires UTF-8, stable member and number forms, explicit case tags,
one binary spelling, canonical UTC instants, schema versioning, raw duplicate-
member rejection and an explicit non-finite-number policy. It also requires
readers to reject unsupported major versions, admit compatible minor additions
only under declared schema rules, preserve unknown namespaced metadata where
safe and never silently reinterpret data.

Those requirements cannot be satisfied by the type-level `Codable` shapes
alone. A general `Decoder` may receive a representation after raw object names
have been collapsed, number spellings have been normalised and complete strings
or binary tokens have already been allocated. It cannot recover whether an
integer arrived as `1`, `1.0`, `1e0` or `-0`, whether a member name was repeated,
whether a UTF-8 BOM was present or whether insignificant whitespace surrounded
the value.

An isolated Apple Swift 6.3.3 negative-control probe confirmed that
`JSONDecoder` and `JSONSerialization` accept duplicate and escape-equivalent
duplicate member names while retaining one value. `JSONDecoder` also accepts
the four integer aliases above as the same unsigned integer and accepts a
leading UTF-8 BOM. `JSONEncoder` emits negative zero and an exponent spelling
that differ from RFC 8785, while `.sortedKeys` does not implement RFC 8785's
UTF-16 property-name order for all non-BMP names. Foundation remains useful for
ordinary type-level coding, but it cannot be the canonical-byte trust boundary
or the oracle for that boundary.

Proposed `ADR-0028` through `ADR-0033` supply the candidate semantic payload:

- an exact canonical instant;
- finite binary64 metadata with one zero identity;
- owned binary bytes with strict padded standard Base64 at type level;
- bounded recursive values with exact UTF-8 string/key identity and explicit
  tags;
- a required privacy class on every general entry; and
- an ordered collection whose repeated keys require an explicit immutable
  caller-supplied multiplicity policy.

All six records remain Proposed. This decision depends on their accepted
shapes; it does not convert them into current authority. Proposed `ADR-0034`
defines typed reads after a collection exists and is not a semantic dependency
of canonical ingress.

The full `Int64` and `UInt64` domains introduce a portability conflict. JSON
number syntax can spell every integer, but common interoperable JSON stacks use
binary64 and cannot preserve every 64-bit integer. RFC 7493 recommends JSON
strings when exact 64-bit interchange is required. Ordinary `MetadataValue`
`Codable` already uses numeric integer payloads, and `ADR-0031` explicitly
leaves a separately versioned canonical projection available.

Unmodified RFC 8785 is also not an exact fit. It adopts the I-JSON constraints,
including rejection of Unicode noncharacters. Voxelia's current metadata
strings and exact UTF-8 identity fields admit every valid Swift Unicode-scalar
string, including noncharacters. Silently narrowing those semantic domains at
the byte boundary would make some constructible values impossible to encode.

Multiplicity needs a separate trust decision. A wire document cannot safely
carry its own repeatable-key allow-list because that would let untrusted input
waive the duplicate invariant. A portable repeat-bearing document needs a
schema reference that is matched to trusted caller context, while hosts retain
responsibility for resolving and authenticating that schema.

Finally, the semantic ceilings in `ADR-0031` and `ADR-0033` do not themselves
bound raw input. JSON escaping can expand text, Base64 expands binary, fixed
syntax is repeated per structural element and a generic decoder can allocate a
token before model validation. Raw byte, token and nesting limits plus
incremental parsing and cancellation are therefore part of this boundary.

This proposal selects deterministic record bytes and strict raw ingress only.
It does not select a persistent digest, content identifier, signature, schema
authentication mechanism, privacy filter, export authorisation, semantic
normalisation or permissive JSON import. Its Proposed status does not authorise
recursive metadata or canonical-codec source.

## Decision

If `ADR-0028` through `ADR-0033` and this ADR are accepted, `VoxeliaCore` will
own **Voxelia Canonical Metadata JSON version 1**, abbreviated `VCMJ-1`.
`VCMJ-1` is a JCS-derived UTF-8 record profile with Voxelia-specific semantic
shapes, decimal-string 64-bit integers and preservation of all valid Swift
Unicode-scalar strings. It must not be described as unmodified JCS or I-JSON.

The logical schema support types are:

```swift
public struct MetadataSchemaVersion: Sendable, Hashable {
    public let major: UInt32
    public let minor: UInt32

    public init(major: UInt32, minor: UInt32)
}

public enum MetadataSchemaReferenceError: Error, Sendable, Equatable {
    case invalidIdentifier
    case identifierByteLimitExceeded
}

public struct MetadataSchemaReference: Sendable, Hashable {
    public static let maximumIdentifierUTF8ByteCount: UInt64 = 255
    public static let maximumIdentifierLabelByteCount: UInt64 = 63

    public let identifier: String
    public let version: MetadataSchemaVersion

    public init(
        identifier: String,
        version: MetadataSchemaVersion
    ) throws

    public static func == (lhs: Self, rhs: Self) -> Bool
    public func hash(into hasher: inout Hasher)
}

public enum MetadataJSONIngressError: Error, Sendable, Equatable {
    case invalidDocument
    case unsupportedSchemaVersion
    case resourceLimitExceeded
    case cancelled
}

public enum MetadataJSONEmissionError: Error, Sendable, Equatable {
    case invalidValue
    case resourceLimitExceeded
    case cancelled
}

public struct CanonicalMetadataDocument: Sendable {
    public let documentSchema: MetadataSchemaReference
    public let multiplicitySchema: MetadataSchemaReference?
    public let payload: MetadataCollection
}
```

The schema-reference identifier is a stable lowercase ASCII reverse-domain
name, not an arbitrary Unicode string, DNS lookup or URI. Its exact grammar is
two or more dot-separated labels. Each label is 1 through 63 bytes, begins and
ends with `a` through `z` or `0` through `9`, and otherwise contains only those
characters or `-`. The complete identifier is at most 255 UTF-8/ASCII bytes.
There is no case folding, percent decoding, IDNA, DNS resolution or aliasing.
`org.voxelia.metadata-document` and `org.example.metadata-profile` are valid;
uppercase, whitespace, underscores, empty labels and leading/trailing hyphens
are invalid.

Grammar failure throws the fixed payload-free
`MetadataSchemaReferenceError.invalidIdentifier`; exceeding either hard byte
ceiling throws `.identifierByteLimitExceeded`. Programmatic construction
validates before storing the reference, and raw ingress enforces both limits
incrementally before growing a token buffer. Equality and hashing compare the
exact ASCII bytes. `MetadataSchemaVersion` and `MetadataSchemaReference` do not
gain standalone `Codable` conformances in version one; their stable role is
inside the dedicated canonical codec.

`CanonicalMetadataDocument` is the immutable successful decode result. It has
no public initializer, `Codable`, `Hashable`, `CustomStringConvertible`,
`CustomDebugStringConvertible`, `CustomReflectable` or safe-display/export
claim in version one. Its three stored properties are publicly readable so a
caller can retain the matched profile reference and later re-supply trusted
context. Construction remains inside the codec after complete validation;
programmatic emission uses the explicit unique/configured operations rather
than creating an unchecked document. Omitting those conformances does not make
the value safe: default `String(describing:)`, `String(reflecting:)` and
`Mirror` can expose stored payloads. Library and host code must not interpolate
or reflect the document into logs or telemetry.

The exact public streaming source/sink and limit-configuration method names are
deferred until implementation evidence proves cancellation and allocation
behaviour. That deferral does not permit a different grammar, envelope, schema
binding, error surface or trust model.

Canonicality applies to the complete logical document tuple: the fixed
`VCMJ-1` document schema, one exact multiplicity-profile reference or null, and
the complete stored `MetadataCollection`. It is not a canonical representation
of `MetadataCollection` alone. The same collection may intentionally produce a
different valid document when bound to a different profile reference; each
complete tuple has exactly one canonical byte sequence. The policy snapshot is
required validation context but is deliberately not record content: two caller
policies that both admit the same collection under the same claimed profile
produce the same bytes. Core cannot prove that either caller claim is truthful.

### Exact document envelope

The smallest valid unique-only document is exactly:

```json
{"documentSchema":{"identifier":"org.voxelia.metadata-document","version":{"major":1,"minor":0}},"multiplicitySchema":null,"payload":{"entries":[]}}
```

The root object contains exactly three members in the displayed order:

1. `documentSchema` identifies the canonical document grammar. Its identifier
   is the fixed ASCII string `org.voxelia.metadata-document`; version one is
   exactly major `1`, minor `0`.
2. `multiplicitySchema` is required and is either `null` or one
   `MetadataSchemaReference`.
3. `payload` is exactly the one-field `MetadataCollection` representation from
   `ADR-0033`.

The schema reference contains exactly `identifier` and `version`; the version
contains exactly `major` and `minor`. The payload contains exactly `entries`.
All fields are required. `null` is permitted only for `multiplicitySchema` and
for optional leaf fields whose accepted type-level decisions require explicit
nulls. Missing, extra, reordered, duplicate or wrong-shaped structural fields
are invalid.

Version-one readers accept only document version `1.0`. A syntactically valid
fixed document identifier with another supported-format version fails with
`unsupportedSchemaVersion`; malformed identifiers, versions or envelopes fail
with `invalidDocument`. A future same-major minor is accepted only after a
reviewed decision declares every addition compatible and gives the reader a
lossless representation. Unknown case tags or structural members are not
silently treated as compatible additions.

Unknown *namespaced metadata entries* remain representable because a key is an
opaque namespace/name pair. A reader preserves such an entry when its value
uses the recognised metadata vocabulary and it passes all limits, privacy and
multiplicity rules. This preservation rule does not admit unknown envelope
members, fixed-record members, enum strings or value tags.

### Trusted multiplicity binding

`multiplicitySchema: null` selects the context-free unique-only path. The codec
uses `MetadataMultiplicityPolicy.uniqueKeysOnly` and rejects the second exact
key occurrence. No resolver or schema configuration is consulted.

A non-null `multiplicitySchema` permits repeat-bearing ingress only when the
caller supplies one immutable configuration snapshot containing:

- the exact expected `MetadataSchemaReference`; and
- an already validated, bounded `MetadataMultiplicityPolicy` that the caller
  asserts was resolved for that exact reference.

The codec compares the wire reference with the expected reference by exact
identifier bytes and exact major/minor values before admitting payload entries.
It then uses only the caller-supplied policy. Missing context, unexpected
context for a null reference, reference mismatch or policy violation fails with
`invalidDocument`. The wire never contains a repeatable-key allow-list and can
never widen, replace or select the supplied policy.

Core owns the generic envelope grammar, exact binding and collection
validation. The host or adapter owns schema selection, lookup, authenticity,
authorisation, lifecycle and any network or registry access. The codec performs
no callback, global lookup, `Decoder.userInfo` lookup, task-local lookup or
network operation. A caller can still lie by supplying an inappropriate policy;
this configuration is an admission assertion, not a cryptographic capability.

One `multiplicitySchema` reference identifies an immutable schema **profile**
covering the complete policy snapshot for the document, not just one namespace.
When a host composes permissions from several namespace schemas, that exact
composition receives its own separately identified and versioned profile. A
profile change that changes repeat admission requires a different version; a
policy assembled ad hoc without that identity cannot be used for portable
repeat-bearing bytes.

Emission is symmetric. The context-free operation writes
`multiplicitySchema: null`, preflights the complete collection under
`uniqueKeysOnly` and rejects any supplied schema context before writing a byte.
The configured operation requires one non-null reference plus the immutable
context whose expected reference matches it exactly, preflights the entire
collection under that exact policy and only then emits the reference and
payload. Missing or mismatched reference context, unexpected context on the
null path, or a policy that does not admit the collection throws the fixed
payload-free `MetadataJSONEmissionError.invalidValue`; resource and
cancellation failures use the other two fixed cases. Core cannot detect a
caller that lies with an overly broad policy under the same claimed profile.
No output byte is published by the returned-value operation after a failed
preflight. Emission checks cancellation throughout preflight and byte
generation, then has one success linearisation point at a final cancellation
check immediately before assigning the returned bytes. A future external
streaming sink still needs adapter-owned transaction semantics for transport
failures.

### Canonical byte profile

A `VCMJ-1` document has all of these byte properties:

- one JSON root object encoded as UTF-8;
- no UTF-8 BOM;
- no leading, trailing or internal insignificant whitespace;
- no comments, trailing commas or trailing JSON value;
- no malformed, overlong or truncated UTF-8 and no replacement decoding;
- no duplicate raw object member at any depth;
- JSON object members in RFC 8785 decoded UTF-16 code-unit order;
- array elements in their semantic order; and
- only the exact token spelling selected below.

All version-one structural property names are fixed ASCII, so their RFC 8785
order is also ordinary ASCII order. Arbitrary metadata key text is represented
as string values, not as JSON property names. `MetadataObject.members` remains
an array sorted by `ADR-0031`'s exact unsigned UTF-8 namespace/name tuple;
canonical JSON does not reorder it. `MetadataCollection.entries`, recursive
arrays and same-key occurrences preserve their exact accepted order.

Raw member-name duplicates are rejected after JSON escape processing and
immediately after the second decoded name, before consuming its colon or value.
Property-order violations reject at the same point. Thus literal and escaped
spellings of the same name cannot evade duplicate detection or attach a huge
second value before failure. Duplicate raw object members are always invalid
and are distinct from repeated metadata entry keys, which are governed only by
the trusted multiplicity binding.

Canonical field order also exposes semantic keys before their values. After a
general entry's complete key is decoded, the parser performs exact duplicate/
policy admission before reading `privacyClass` or `value`. After a recursive
object member's complete key is decoded, it checks exact uniqueness and
strictly increasing `ADR-0031` tuple order before reading that member's value.
A disallowed repeated or unsorted key therefore rejects before an attacker can
attach a large value to the offending occurrence.

Strict ingress accepts only bytes already in canonical form. A future,
separately named import/normalisation operation may accept broader JSON and
produce `VCMJ-1`, but it cannot be used as evidence that its input was
canonical and is outside version one.

### String and Unicode tokens

Strings preserve the decoded Unicode scalar sequence exactly and compare its
UTF-8 bytes where the semantic type requires exact identity. There is no NFC,
NFD, compatibility normalisation, case folding or namespace aliasing. Composed
and decomposed spellings remain byte-distinct. Valid Unicode noncharacters are
preserved, which is the deliberate point where `VCMJ-1` extends beyond I-JSON.
Invalid UTF-8, unpaired surrogate escapes and non-scalar values are rejected.

Identity fields that existing semantic constructors require to be nonblank use
one frozen whitespace oracle before `VCMJ-1` acceptance. The exact whitespace
set is U+0009 through U+000D, U+0020, U+0085, U+00A0, U+1680, U+2000 through
U+200A, U+2028, U+2029, U+202F, U+205F and U+3000. A metadata-key namespace or
name, coded-concept scheme or value, or measurement-unit namespace or code is
blank only when it contains no scalar outside that set. Generic metadata string
payloads remain allowed to contain any valid scalar sequence, including empty
or all-whitespace text. The implementation must not delegate this invariant to
the toolchain-dependent `Character.isWhitespace` property; dependency
constructors and cross-version fixtures must use the same enumerated oracle.

Emission follows the RFC 8785 string escaping algorithm:

- quote and reverse solidus use `\"` and `\\`;
- backspace, tab, newline, form feed and carriage return use `\b`, `\t`, `\n`,
  `\f` and `\r`;
- other U+0000 through U+001F controls use lowercase `\u00xx`;
- solidus is not escaped; and
- every other scalar is emitted directly as UTF-8, including non-BMP scalars
  and noncharacters.

Strict ingress rejects alternative but semantically equivalent escape forms,
including escaped ordinary letters, escaped solidus, uppercase hexadecimal and
surrogate-pair spelling of a scalar that must be literal UTF-8. This ensures
one byte spelling without changing the decoded semantic string.

### Numeric tokens

Metadata signed and unsigned integers use JSON **strings** in this canonical
document projection:

```json
{"signedInteger":"-9223372036854775808"}
{"unsignedInteger":"18446744073709551615"}
```

The signed grammar is `"0"` or an optional minus followed by a nonzero decimal
digit and zero or more decimal digits. The unsigned grammar is `"0"` or a
nonzero decimal digit followed by zero or more decimal digits. The decoded
token is range-checked directly with checked integer arithmetic. Parsing never
passes through `Double`, `NSNumber`, `Decimal` or another lossy intermediary.
Plus signs, leading zeros, `-0`, decimal points, exponents, escaped digits and
out-of-range values are invalid.

This differs intentionally from ordinary `MetadataValue` type-level Codable,
which retains numeric payloads such as `{"signedInteger":-1}`. The two
representations have distinct APIs and purposes. `JSONEncoder` output must
never be labelled `VCMJ-1`, and the canonical ingress path does not invoke the
ordinary `MetadataValue` decoder for integer cases.

All binary64 fields use the RFC 8785/ECMAScript shortest round-trip number
serialization algorithm. This includes `MetadataFloatingPoint` and present
`MeasurementUnit` scale or offset values. Only finite values are valid;
negative zero emits as `0`. Strict ingress parses with a vetted correctly
rounded decimal-to-binary64 parser using round-to-nearest, ties-to-even. It then
serialises the resulting bits with the canonical emitter and byte-compares that
token, rejecting aliases such as `-0`, `1.0`, `1e0` or `1e-07` when the
canonical token differs. The lexical stage admits only the RFC 8259 number
grammar and enforces its token cap before conversion.

Schema major and minor are minimal unsigned decimal JSON numbers in the
`UInt32` range. A fixed 32-byte raw numeric-token ceiling covers every v1
binary64 and schema-version number. The bound is analytic: shortest binary64
output needs at most 17 significant decimal digits; scientific form therefore
needs at most 24 bytes including sign, point, `e`, exponent sign and three
exponent digits, fixed integer form at most 22, and fixed fractional form at
the ECMAScript `10^-6` threshold at most 25. Ten decimal digits cover `UInt32`.
A token longer than 32 bytes is therefore never canonical and rejects before
conversion.

Neither direction is delegated to Foundation. Acceptance treats them as two
separate oracles: binary64-to-decimal emission is differential-tested against
Ryu/V8-compatible RFC 8785 output, while decimal-to-binary64 parsing is
differential-tested against a separately vetted correctly rounded parser or
ECMAScript `JSON.parse`. Canonical validation then re-emits and byte-compares.
The corpus covers random finite bit patterns on every supported Apple
destination.

### Binary, instant and value projections

Binary values use `ADR-0030`'s standard Base64 alphabet with required padding,
no whitespace and zero unused pad bits. Empty binary is the empty JSON string.
The parser validates encoded and decoded lengths with checked arithmetic before
growth and decodes incrementally. Base64URL aliases and alternative escape
spellings are invalid.

Instants use `ADR-0028`'s exact uppercase zero-offset ASCII profile. Escape
aliases for timestamp characters are invalid because those characters must be
emitted literally by the string rule.

The version-one `MetadataValue` projection is exhaustive:

| Semantic case | Canonical payload |
|---|---|
| `boolean` | JSON `true` or `false` |
| `signedInteger` | Canonical decimal `Int64` JSON string |
| `unsignedInteger` | Canonical decimal `UInt64` JSON string |
| `floatingPoint` | Canonical finite binary64 JSON number |
| `string` | Canonical exact-scalar JSON string |
| `binary` | Canonical padded standard-Base64 JSON string |
| `instant` | Exact canonical-instant JSON string |
| `unit` | Exact six-member `MeasurementUnit` object |
| `code` | Exact four-member `CodedConcept` object |
| `array` | Ordered array of canonical values |
| `object` | ADR-0031-sorted array of canonical member objects |

Every case is a one-member externally tagged object. Fixed nested objects use
these exact canonical orders:

- metadata key: `name`, `namespace`;
- metadata object member: `key`, `value`;
- general entry: `key`, `privacyClass`, `value`;
- coded concept: `meaning`, `scheme`, `value`, `version`;
- measurement unit: `code`, `dimension`, `displayName`, `namespace`,
  `offsetToCanonical`, `scaleToCanonical`;
- schema reference: `identifier`, `version`; and
- schema version: `major`, `minor`.

Optional coded-concept and measurement-unit fields retain the explicit nulls
selected by their type-level contracts. Unknown enum strings, tags or fields
fail rather than falling back to a generic value.

Canonical record bytes preserve the complete serialised record. They are not a
projection of Swift `Hashable` equality: `CodedConcept.meaning` and
`MeasurementUnit.displayName` remain encoded even though those presentation
fields are excluded from their semantic equality. Two semantically equal
values can therefore have different valid canonical document bytes. A later
persistent identity decision must select its own scope and projection rather
than hashing these bytes by implication.

### Dedicated incremental ingress

`VCMJ-1` ingress uses a dedicated iterative incremental parser and schema-aware
state machine. `JSONDecoder`, `JSONSerialization`, a generic DOM, decode-and-
reencode comparison or Swift `String`/dictionary identity cannot serve as the
first trust boundary.

The parser:

- consumes bounded chunks with backpressure;
- validates UTF-8 and canonical lexemes while bytes arrive;
- checks object order and raw duplicates using decoded scalar/exact-byte
  identity rather than Swift canonical-equivalent `String` equality;
- validates the fixed envelope and schema context before admitting entries;
- constructs values through the accepted leaf, recursive, entry and collection
  invariants rather than bypassing their validation;
- remains iterative through the maximum nesting depth;
- checks cancellation at chunk boundaries, before significant allocation and
  at the fixed bounded-work cadence below in every CPU loop, including lexical
  scanning, UTF-8 comparison/hashing, duplicate/policy set work, semantic
  accounting/finalisation, copying and emission; and
- publishes one immutable `CanonicalMetadataDocument` only after complete
  input, EOF and all semantic validation at one success linearisation point:
  a final cancellation check immediately before assigning the result.

Failure or cancellation discards all partial state. It produces no partial
entries, cache record, provenance record, digest, callback, temporary file, log
or telemetry event. A transport/source error stays at the caller-owned source
boundary; the canonical parser does not retain or wrap arbitrary underlying
errors. Parser state is operation-scoped and single-owner, not a resumable
public object. Normal return, parser failure, cancellation or a throwing source
always tears it down and releases partial token/model buffers; a new operation
starts with fresh state. This prompt release is not a secure-zeroisation claim.
Transparent decompression occurs before this parser and must enforce a
decompressed-byte ceiling while feeding bounded chunks.

A convenience that accepts an already allocated `Data` feeds bounded slices to
the same state machine and does not pre-reject solely from total `data.count`
when that would change byte-order failure precedence. It cannot claim to have
prevented the caller's earlier allocation. Hostile or large inputs require the
chunked path.

### Failure precedence and chunk invariance

For identical bytes, trusted context and immutable limits, every
non-cancellation parser outcome is identical under every chunk split. The
scanner processes bytes in source order and never charges a whole supplied
chunk in advance. It charges each next raw or token byte before interpreting
that byte; a limit crossed on the same byte as a newly provable syntax error
therefore produces `resourceLimitExceeded`. A syntax, canonical-form or context
error already proved by an earlier byte remains `invalidDocument` and the
parser stops without consuming later input.

Derived-token and semantic checks use a second fixed order after raw-byte
charging:

1. validate the next complete lexical unit (UTF-8 scalar/escape, numeric
   grammar component, schema-identifier ASCII byte or Base64 quantum);
2. charge decoded string/binary/schema-label or logical-payload work produced
   by that valid unit before appending it; and
3. after the complete bounded value, apply range, canonical re-emission and
   other non-limit semantic invariants.

Consequently a valid 64th byte in one schema-identifier label crosses the
63-byte hard limit and returns `resourceLimitExceeded`, while an invalid ASCII
character at that position returns `invalidDocument` before the label charge.
For a final Base64 quantum, alphabet/padding placement and unused pad bits are
validated before its decoded-byte charge: `Zh==` is `invalidDocument` even
under a zero-byte decoded limit, while canonical `Zg==` under that limit is
`resourceLimitExceeded`. A syntactically valid but out-of-range 64-bit integer
or finite-number-domain failure within all configured byte limits is
`invalidDocument`; an earlier caller string/token limit still wins when
crossed.

Entry/direct-container counts and semantic/raw depth are charged before
accepting the next element or pushing its frame. Aggregate structural and
logical-payload budgets are charged progressively after each child/key/payload
unit is lexically valid and before it is appended. These rules, the mapping
table below and their maximum/one-over fixtures are the error-precedence oracle;
an underlying semantic constructor error is translated rather than exposed.

The canonically ordered `documentSchema` prefix is validated before the other
root members. Once its complete fixed identifier and syntactically valid
version prove that the format version is unsupported, the parser returns
`unsupportedSchemaVersion` immediately and does not inspect the suffix. A raw
or token limit crossed before that complete decision remains
`resourceLimitExceeded`; malformed prefix syntax remains `invalidDocument`.
Likewise, a complete non-null multiplicity reference is matched to preflighted
caller context before payload admission and a mismatch short-circuits as
`invalidDocument`.

Cancellation is deliberately excluded from byte-only precedence because it is
external state. The implementation checks it at the bounded cadence and may
return `cancelled` instead of the next byte-derived outcome once observed. A
throwing transport also remains outside the parser result contract.

A cancellation work unit is one visited source byte, one produced or revisited
decoded/output byte, one decoded Unicode scalar, one structural occurrence, one
visited exact-key UTF-8 byte during hashing or comparison, or one visited hash-
table slot. Categories are additive even when a fused loop performs several
roles for the same data. Re-reading a byte charges it again. One monotonic
operation-wide counter is shared by every nested loop and helper; it resets only
immediately after an actual cancellation poll, never merely because a loop or
helper starts or returns. Every data-dependent parser and emitter loop polls on
entry and whenever the shared counter reaches 4,096 units. A conforming
implementation cannot delegate an unbounded data-dependent operation to a
library call that cannot poll within that bound.

The additive 4,096-unit maximum between polls is the deterministic conformance
contract; elapsed return time on a non-real-time OS is not. Acceptance evidence
also runs each adversarial case in a release build for 1,000 warm-up and at
least 10,000 measured trials on every representative lowest-resource supported
device. It records hardware, OS, compiler, revision, power/thermal state,
benchmark isolation, corpus seed, `ContinuousClock` cancellation-request-to-
return latency, median/p95/p99/maximum and the instrumented maximum work units
between polls. The task is kept continuously runnable in a quiescent process,
without a debugger and at nominal thermal state. A p99 above 10 ms or any sample
above 50 ms triggers recorded engineering review and either a tighter cadence
or an accepted justification; scheduling alone cannot make the implementation
nonconforming when the 4,096-unit bound holds. The corpus includes long tokens,
maximum common-prefix keys, collision-heavy membership/policy work, semantic
finalisation, copying and emission.

### Resource accounting

Every ingress operation snapshots immutable caller limits before consuming
bytes; every emission operation snapshots its immutable output limit before
configuration/model preflight. Input bytes, callbacks, globals, registries,
`userInfo` and task-local state cannot raise them. All byte/count arithmetic
uses checked `UInt64` operations and checked conversion to `Int` before
allocation.

The parser enforces, before frame push, append, reserve or other growth:

- total raw document bytes, including across chunk boundaries;
- raw JSON nesting depth;
- fixed numeric and other token ceilings;
- raw and decoded bytes for each variable string token;
- encoded and decoded binary bytes;
- direct entry, array-member and object-member counts;
- the expected multiplicity-schema identifier against the operation's decoded-
  string limit and the retained unique-key metrics of the complete out-of-band
  policy configuration before input is read;
- `ADR-0031`'s semantic depth 64;
- `ADR-0031`/`ADR-0033`'s 1,048,576 structural-element and entry ceilings;
- their 67,108,864-byte logical variable-payload ceilings; and
- caller-selected retained-policy count/byte ceilings before input is read. The
  policy constructor's hard pre-normalisation ceilings remain authoritative.

Untrusted advertised counts never cause an unchecked reserve. Raw string and
Base64 input is consumed incrementally rather than retained in full beside a
second decoded copy.

All maxima are inclusive `UInt64` ceilings. A use of exactly the maximum
succeeds; the next unit fails. Zero permits only a zero-use instance of that
metric. Every charge computes a checked candidate, compares it with the
ceiling, and only then commits the counter, so a failed charge does not mutate
operation state. The ingress accounting units are normative:

| Limit | Exact unit and reset scope | Charge point and zero meaning |
|---|---|---|
| Total raw document bytes | Every source octet from operation start through EOF, including malformed bytes, BOM, forbidden whitespace and trailing data; one operation-wide counter. | Before interpreting each byte. Zero rejects the first byte. |
| Raw JSON token bytes | Per lexical token. A string token includes both quotes and every raw escape byte; a number or literal includes its complete lexeme. Structural punctuation is excluded and each token starts a fresh counter. | Before interpreting each token byte. Zero rejects the first token byte. |
| Decoded string bytes | Per JSON string, the exact UTF-8 length of decoded scalars, excluding quotes. This includes member names and semantic strings. | After a scalar or escape is lexically valid and before append. Zero admits only `""`, subject to later semantic invariants. |
| Schema-identifier label/total bytes | Decoded validated ASCII content per reference. A label count excludes dots; the total includes dots. | After character validation and before append. The hard inclusive maxima are 63 and 255; zero is not configurable. |
| Encoded binary bytes | Per binary value, validated Base64 ASCII content between the JSON quotes, including `=` padding but excluding quotes. | After each code unit's alphabet/padding position is valid. Zero admits only empty Base64 text. |
| Decoded binary bytes | Per binary value, output octets from canonical Base64. | After a complete quantum, including unused-pad-bit validation, and before append. Zero admits only empty binary. |
| Direct counts | Collection entries and the members of each individual recursive array or object. Each container has a fresh counter; aggregate entry and structural counters remain separate. | Before accepting the next occurrence. Zero admits only an empty corresponding container. |
| Raw JSON depth | Simultaneously open `{`/`[` frames, root object at one; one operation-wide high-water limit. | Before pushing a frame. Zero rejects the root frame. |
| Semantic container depth | `ADR-0031` accounting: leaf zero, empty container one, otherwise one plus greatest child depth. | Before admitting a container whose derived depth would exceed the inclusive ceiling. Zero admits leaves only. |
| Aggregate structural elements and entries | Exact occurrence counts from `ADR-0031`/`ADR-0033`, including repeated shared subtrees; one counter of each kind per operation. | After the next child/key is lexically valid and before model append. Zero admits only a payload with no charged occurrence. |
| Aggregate logical variable payload | Exact logical bytes from `ADR-0031`/`ADR-0033`, not JSON escaping/Base64 expansion; one operation-wide counter. | After a contributing unit is valid and before model append. Zero permits only values whose defined logical variable payload is empty. |
| Multiplicity-policy constructor hard counts/payload | Supplied key occurrences and exact UTF-8 key bytes before set normalisation, exactly as `ADR-0033`. That constructor-only history need not be retained. | Enforced once by `MetadataMultiplicityPolicy.init`; the codec trusts the invariant and never reconstructs or recharges source duplicates. |
| Ingress retained-policy counts/payload | Each privately retained unique exact key once and the checked sum of its namespace/name UTF-8 bytes, using policy-cached derived metrics; one context-preflight counter of each kind per operation. | Before reading input. Zero admits only `uniqueKeysOnly`; a lower ceiling is local admission policy and does not change the policy's identity. |

The caller's expected non-null schema identifier is charged once against the
same inclusive decoded-string ceiling during context preflight. Fixed numeric
and literal ceilings are inclusive raw-token maxima; version-one canonical
binary64 has the separate hard 32-byte raw numeric-token ceiling. These units
and charge points control every maximum/maximum-plus-one and chunk-split
fixture; convenience `Data` input uses the same counters.

Emission uses a distinct caller-supplied inclusive output-byte ceiling; it never
implicitly reuses an ingress document limit. The exact public configuration
property name remains deferred. The count is every UTF-8 output octet in the
complete canonical document, including braces, brackets, commas, colons,
property names, quotes, escapes, Base64 padding and all payload bytes. Zero
cannot admit a valid `VCMJ-1` document because even the empty envelope is
nonempty. The output ceiling must not exceed the same derived universal
canonical-document maximum; a smaller value is local emission policy.

The returned-value emitter uses this fixed order:

1. validate the complete reference/configuration/model and multiplicity
   admission, returning `invalidValue` before considering the output ceiling;
2. traverse the exact canonical projection without publishing bytes, compute
   the complete output count with checked `UInt64` arithmetic, compare it with
   the output ceiling, and check conversion to `Int`;
3. only after that compute-guard step, allocate at most the exact size and emit
   with the same canonical traversal, charging one operation-wide output byte
   counter before each write and verifying the final count; and
4. perform the final cancellation check and publish the immutable returned
   bytes at the single success linearisation point.

Overflow, failed `Int` conversion or output maximum plus one returns
`resourceLimitExceeded` without publishing a byte; steps 1 and 2 occur before
output reserve/allocation. Sizing and writing use one shared pure canonical-
fragment primitive so their length rules cannot drift. The final-count check is
an internal assertion and validation oracle: a mismatch is a library invariant
defect, not a caller resource or value error, and publishes no bytes. A lower
output maximum is local emission policy: it can reject an otherwise valid tuple
but does not define different canonical bytes. A future transactional streaming
sink uses the same exact output counter and limit, while adapter-owned rollback
remains required for sink/transport failure. Cancellation remains external and
may win at any required poll before publication.

Raw JSON depth is the greatest number of simultaneously open `{` or `[`
containers, with the root object at depth one. The grammar-derived maximum is
198: four document/payload/entries/entry containers, plus three containers for
each of 64 nested semantic object levels (tag object, member array and member
object), plus a leaf tag and its deepest unit/code object payload. This is
distinct from and enforced alongside semantic container depth 64. A caller may
choose a lower depth as a local restricted admission policy. That policy may
reject valid `VCMJ-1`; it does not define another serialised format or canonical
profile.

The universal maximum raw document byte count is not guessed in this proposal.
It must be derived from the final grammar, the schema identifier's bounded
worst-case representation, worst-case canonical escaping, Base64 expansion,
fixed syntax and the accepted semantic ceilings, then tested on the lowest-
resource supported devices before acceptance. Each operation
also requires a caller-selected document/token/string/binary limit no greater
than that universal maximum. A lower limit intentionally rejects some otherwise
serialisable values and is therefore a local restricted admission policy, not
another serialised format or canonical profile. There is no permissive default
for untrusted ingress.

Swift cannot guarantee recovery from arbitrary allocator failure or secure
zeroisation of every copy-on-write and allocator copy. The implementation
promises conservative pre-allocation limits, no spill/cache, prompt release of
partial state and memory-pressure validation; it does not promise general OOM
recovery or complete zeroisation.

Accordingly, this ADR's mapping to `VOX-ERR-001` is partial. The typed
`resourceLimitExceeded` cases cover preventive budget checks, checked arithmetic
and checked integer conversion before requested growth; they do not prove typed
recovery from an allocator that actually fails. `VOX-ERR-001`'s P0 allocation-
failure clause remains open until a recoverable fallible-allocation path and
fault-injection evidence exist on every supported destination, or the
controlled baseline is explicitly revised. Acceptance of this ADR cannot by
itself close that requirement.

### Errors, privacy and observable behaviour

The four ingress error cases carry no associated value and use this fixed
mapping:

| Error | Exact category |
|---|---|
| `invalidDocument` | Syntax/UTF-8, root or field shape/order, raw member duplicate, noncanonical lexical alias within a limit, invalid fixed identifier/tag/enum/privacy token, schema-reference mismatch, disallowed repeated metadata key, unsorted/duplicate recursive object key, blank semantic identity field or other non-limit leaf/model invariant. |
| `unsupportedSchemaVersion` | A complete canonical fixed document-schema prefix names a syntactically valid but unsupported format version. |
| `resourceLimitExceeded` | Any hard or caller ceiling, including document/raw depth/token/schema-identifier/string/binary/direct count/semantic depth/entry/structural/logical payload/policy limits, or checked arithmetic/conversion overflow. |
| `cancelled` | Cancellation observed at a required check before the success linearisation point. |

Thus a depth, entry, structure or logical-payload error from a semantic
constructor maps to `resourceLimitExceeded`, while duplicate/order/blank/domain
invariants map to `invalidDocument`. Byte-order precedence and the
unsupported-version short circuit remain as defined above.

Emission failures are likewise payload-free. Configuration/model/policy
admission preflight uses `MetadataJSONEmissionError.invalidValue`; exact output-
size arithmetic, conversion and the distinct output ceiling use
`.resourceLimitExceeded`; observed cancellation uses `.cancelled`. Neither error
family carries the complete value, schema reference, policy or partial bytes.

Descriptions and reflection expose no raw byte, token, key, value, schema
identifier/version, privacy class, path, offset, line, column, index, count,
limit name/value, policy content or underlying error. Parser-owned code emits no
logs or telemetry. The fixed cases necessarily reveal a coarse result and
fail-fast timing remains an oracle. An untrusted network or clinical boundary
must not forward these outcomes verbatim without a reviewed disclosure policy;
collapsing non-cancellation outcomes and rate-limiting repeated failures are the
default host posture. This responsibility remains outside Core. This ADR makes
no constant-time claim.

The complete raw document is treated as sensitive and unclassified from byte
zero. Neither `publicData` nor `technical` permits parser logging. Every entry
must contain exactly one known privacy class. Missing, null, unknown, malformed
or case-variant classifications fail; an unknown token never becomes
`hostDefined`. Accepted classes, repeated occurrences and entry order are
preserved exactly, while `hostDefined` remains literal and unresolved.

Ingress performs no privacy filtering, redaction, class aggregation,
declassification, read authorisation, logging permission or export decision.
Successful parsing proves only canonical syntax and the configured structural
invariants.

### Persistent identity and export separation

`VCMJ-1` provides deterministic complete-record bytes. It defines no:

- hash algorithm, content ID, persistent digest scope or signature;
- semantic projection that removes presentation fields;
- schema authentication, registry or trust anchor;
- transport framing, compression or encryption;
- privacy transformation or export format; or
- authorisation to disclose a successfully parsed record.

Any later digest ADR must decide whether order, presentation strings, privacy
classes and schema references participate and must reconcile the controlled
`ContentID` conflicts independently. Any later export path must apply trusted
host privacy and destination policy before emitting bytes.

## Alternatives considered

### Use `JSONDecoder` or `JSONSerialization` as the raw boundary

Rejected. They accept noncanonical aliases, may collapse duplicate members and
may allocate complete source tokens before Voxelia limits run. Their errors can
also contain source-derived paths and values. They remain available for the
separate ordinary type-level representation.

### Decode ordinary values, re-encode with sorted Foundation keys and compare

Rejected. Information has already been lost at decode time, Foundation's
numeric/string output is not the selected profile and `.sortedKeys` is not the
RFC 8785 ordering oracle for all Unicode names.

### Adopt unmodified RFC 8785 and I-JSON

Rejected for version one because it would exclude Unicode noncharacters that
the current semantic model admits. `VCMJ-1` takes the deterministic RFC 8785
escaping, binary64 and property-order algorithms while declaring its broader
valid-scalar domain explicitly.

### Restrict the semantic model to I-JSON strings

Rejected absent an independent requirement and migration decision. It would
change existing exact UTF-8 metadata-key identity and make currently valid
strings, concepts and units unencodable.

### Encode full 64-bit metadata integers as JSON numbers

Rejected for the canonical document. A custom lossless lexer could preserve
the tokens locally, but generic cross-system JSON/JCS consumers commonly route
them through binary64. Decimal strings retain the complete domains without
ambiguity because the external value tag supplies the integer subtype.

### Change ordinary type-level Codable integers to strings

Rejected. It would unnecessarily break the type-level wire selected by
`ADR-0031`. The canonical document is explicitly a different versioned
projection with a dedicated codec.

### Put the repeatable-key allow-list in the document

Rejected as self-authorising input. The document carries only an opaque schema
reference; trusted caller context supplies the exact expected reference and
already bounded policy.

### Reject every repeated entry permanently

Rejected because the controlled model explicitly permits schema-authorised
multiplicity. Unique-only remains the safe context-free subset.

### Accept noncanonical JSON and normalise it during strict ingress

Rejected. That would erase the distinction between canonical and merely
parseable input. A future permissive importer must be separately named and
cannot attest to source-byte canonicality.

### Build an unbounded or two-pass generic DOM

Rejected. It can duplicate source and decoded storage, allocate before semantic
limits and publish Foundation-dependent behaviour. The selected parser checks
and constructs incrementally with bounded private state.

### Return detailed parse locations and offending values

Rejected at the public boundary because metadata keys, values, schema identity,
privacy classes, counts and structure may be sensitive. Fixed coarse errors are
actionable enough for callers without retaining source payloads.

### Choose a convenient fixed raw-document cap now

Rejected. An arbitrary number could silently exclude model-valid records after
worst-case escaping, Base64 and repeated syntax. The unrestricted ceiling must
be derived and measured; smaller deployment caps are local admission/emission
policies and do not define another canonical profile.

## Consequences

Positive consequences:

- each complete document tuple receives one versioned deterministic byte
  representation;
- every `Int64` and `UInt64` value survives standards-conforming JSON
  processing that preserves JSON string values;
- canonical and ordinary type-level Codable roles are explicit;
- raw duplicates, lexical aliases and schema mismatches fail before semantic
  publication;
- repeat permission cannot be supplied by the bytes it validates;
- exact UTF-8 identity and all valid Swift scalar strings remain representable;
- semantic order and every privacy classification survive ingress; and
- persistent identity and export policy remain independent decisions.

Costs and limitations:

- Voxelia needs a dedicated JSON parser, a vetted RFC 8785-compatible binary64
  emitter and a separately vetted correctly rounded decimal parser rather than
  relying on Foundation;
- canonical integer cases differ from ordinary type-level JSON;
- every repeat-bearing decode needs trusted out-of-band schema context;
- callers must choose explicit resource limits and a chunked source for hostile
  inputs;
- the universal raw byte ceiling and cancellation/device evidence require more
  work before acceptance; and
- deterministic complete-record bytes do not imply semantic equality,
  persistent identity, privacy safety or export permission.

Because valid noncharacters are retained, an I-JSON-only intermediary may
reject some `VCMJ-1` documents. Such an intermediary is not a conforming
`VCMJ-1` processor even though the profile otherwise derives its string,
floating and property rules from RFC 8785.

## Affected modules

- `VoxeliaCore` owns the schema-reference values,
  `CanonicalMetadataDocument`, `VCMJ-1` grammar, canonical projection,
  incremental ingress, emission and payload-free errors.
- Core metadata leaves and aggregates proposed by `ADR-0028` through
  `ADR-0033` provide the validated semantic model.
- `VoxeliaSpatial` owns the `MeasurementUnit` constructor correction. Spatial
  and Core use private module-local implementations generated from the same
  controlled whitespace-scalar table and cross-module fixtures; Spatial does
  not import a Core helper upstream.
- Storage, IO and format adapters may provide bounded byte sources and trusted
  schema-policy configurations without reimplementing the grammar or widening
  Core invariants.
- Host applications own schema resolution/authentication, privacy policy,
  transport security, throttling, export and audit.
- `VoxeliaDiagnostics` receives no raw parse payload and is not imported to log
  parser failures.
- No Metal, rendering, UI, execution or device module gains metadata-policy
  authority from this decision.

## Compatibility impact

This proposal adds a dedicated canonical-document surface and does not change
existing ordinary `Codable` bytes. Canonical integer strings are intentionally
not compatible with the ordinary numeric integer payloads. APIs and files must
label the format/version so callers cannot interchange the two paths silently.

The frozen scalar-based blank predicate is a pre-1.0 accepted-domain
correction to current dependency constructors, not merely a serializer detail.
Those constructors currently iterate extended grapheme clusters with
toolchain `Character.isWhitespace`. On the audited Swift toolchain they reject
edge strings such as `" \u{0301}"` and `"\u{2003}\u{FE0F}"`, while the selected
scalar rule accepts them because each contains a scalar outside the frozen
whitespace set. Exact bytes remain preserved. Migration must document and test
this broadening before source changes; it cannot be described as leaving all
ordinary decode acceptance unchanged.

Version `1.0` is closed. Unsupported majors reject. Same-major additions are
not assumed compatible merely because JSON readers could ignore them. A later
minor version needs an explicit compatibility decision and lossless
preservation path. New value tags or structural fields that an older model
cannot retain require a new version rather than silent dropping.

Unknown namespace/name entries that use existing values remain portable. A
non-null multiplicity reference is portable only when the recipient has
trusted context for that exact reference; otherwise decoding fails rather than
falling back to unique-only or accepting repeats.

## Security impact

The dedicated parser removes Foundation duplicate-collapse and prevalidation
allocation from the security boundary. Checked budgets, bounded chunking,
fail-closed schema binding, atomic publication and payload-free errors reduce
resource exhaustion, ambiguity, policy injection and diagnostic leakage.

Residual risks remain explicit: coarse error categories and rejection timing
are observable; exact-key sets and common-prefix comparison are not
constant-time; a malicious host can supply false schema/policy context; an
already allocated `Data` is outside streaming protection; Swift may terminate
on allocator failure; and complete secure zeroisation cannot be guaranteed.
The codec provides no authentication, encryption, authorisation or privacy
transformation.

## Performance and memory impact

Canonical ingress is O(raw bytes + admitted logical structural elements) plus
expected/amortised exact-key membership work. Fixed object order can be checked
while streaming; arrays are not sorted. Recursive metadata objects arrive in
their required tuple order and are validated rather than globally resorted.
The cancellation contract still bounds hash, equality and table-probe slices;
membership does not claim worst-case constant time.

Private memory is bounded by parser frames, decoded token/binary buffers,
duplicate/key-policy state and the validated result. The implementation avoids
holding both complete raw and decoded tokens and never reserves from an
untrusted declared count. Exact bounds depend on the final raw-document
derivation and supported-device evidence.

Canonical emission validates the complete model and configuration before
publishing a returned byte value. A future streaming sink can avoid a second
complete output allocation, but external transactional publication and sink
errors remain adapter responsibilities.

## Validation impact

Before acceptance and implementation, focused evidence must cover:

- strict `Sendable` checking, readable retained document/profile/payload fields
  and compile-negative unchecked public document construction;
- the exact empty envelope and nonempty golden documents on every supported
  Apple destination;
- byte-identical canonical emission across supported Swift/Foundation versions;
- UTF-8 BOM, whitespace, comments, trailing data, malformed/overlong/truncated
  UTF-8 and every raw-depth boundary;
- same-spelling, escaped-equivalent and nonadjacent duplicate members at the
  envelope, schema, collection, entry, key, tag and leaf levels;
- duplicate raw names, disallowed repeated entry keys and unsorted/duplicate
  object-member keys followed by a massive second value, proving rejection
  immediately after the offending key without consuming/buffering that value;
- every fixed object in canonical and noncanonical member order, including an
  independent non-BMP RFC 8785 ordering oracle;
- exact string escapes, slash, lowercase hexadecimal, controls, non-BMP
  scalars, composed/decomposed controls, noncharacters and invalid surrogates;
- every frozen blank-field whitespace scalar, adjacent non-whitespace controls
  and multi-scalar grapheme fixtures including `" \u{0301}"` and
  `"\u{2003}\u{FE0F}"` across supported Swift/Unicode versions in both the Core
  identity constructors and Spatial-owned `MeasurementUnit`;
- schema identifiers at every grammar boundary, 63/64-byte labels and
  255/256-byte totals in programmatic construction and split raw ingress;
- every `Int64`/`UInt64` extremum, safe-integer boundary and one-over value plus
  signs, leading zeros, `-0`, fraction, exponent, escaped-digit and oversized
  aliases;
- proof of the 25-byte maximum canonical binary64 token, all RFC 8785 vectors,
  both zeros, subnormal/normal boundaries, greatest finite values, exponent
  thresholds and ties, plus separate random-bit emitter and decimal-parser
  differential tests against their vetted oracles;
- empty and RFC Base64 vectors, alphabet, padding, unused pad bits, whitespace,
  Base64URL aliases and checked encoded/decoded length boundaries;
- precedence controls including valid/invalid schema byte 64, invalid `Zh==`
  versus canonical `Zg==` under decoded-binary limit zero, out-of-range integer
  within a permissive token limit and the same token crossing a tighter limit;
- exact canonical-instant forms and escape aliases;
- semantic object tuple order, collection order, repeat occurrence order and
  complete privacy-class preservation;
- null unique-only schema, configured allowed/disallowed repeats, absent or
  mismatched trusted schema context and proof that policy contents are absent
  from wire;
- symmetric unique/configured emission preflight, mismatched references and
  non-admitting narrower policies failing before any byte is published;
- exact emission output-byte sizing at maximum and maximum plus one, zero,
  checked arithmetic/`Int` overflow, invalid-value-before-output-limit
  precedence, compute-guard-before-allocation, shared sizing/writing-fragment
  parity and no publication on every failure or injected invariant mismatch;
- every raw, token, decoded string/binary, entry, structure, logical payload,
  semantic-depth and raw-depth limit at maximum and maximum plus one, including
  zero-limit semantics, checked-overflow, compute-guard-commit state and chunk-
  boundary cases without giant allocations;
- retained-policy cached unique-key count/byte limits at zero, maximum and
  maximum plus one, plus equal normalised allow-lists built from different
  duplicate-bearing source histories producing identical codec preflight
  outcomes without recharging discarded history;
- splitting every UTF-8 scalar, escape, number and Base64 quantum at every byte
  boundary plus random chunkings and backpressure;
- identical non-cancellation outcomes for every chunking, byte-versus-limit
  precedence and unsupported-version short-circuit fixtures;
- an actually generated 64-object canonical chain with raw depth 198, a
  semantic-depth-65 rejection and an isolated raw-frame-guard depth-199
  `resourceLimitExceeded` fixture. The last is not end-to-end schema-precedence
  evidence: a schema-aware parser may prove an invalid shape before a 199th
  grammar-admissible frame;
- cancellation in every lexer state, UTF-8 hash/compare and set/policy loop,
  semantic finalisation/copy, emission loop and immediately before both decode
  and emission publication, with no result, cache, callback, provenance,
  digest, temp file or diagnostic mutation; verify additive operation-wide
  4,096-work-unit accounting and record the controlled release-device 10 ms p99/
  50 ms review thresholds with adversarial tokens, common-prefix keys and
  membership collisions;
- throwing-source teardown and fresh-operation reuse with no retained partial
  token, entry or parser state;
- descriptive and reflective failures containing no sentinel source data,
  paths, offsets, versions, counts, policy or privacy content;
- fuzz/mutation corpora, parser reuse after failure and representative lowest-
  resource device memory-pressure evidence;
- recoverable allocation-failure fault injection on every supported destination
  before claiming the `VOX-ERR-001` allocation-failure clause, or an explicit
  controlled-baseline revision; and
- directly affected Core and Spatial builds/focused constructor tests, strict
  concurrency, format/static checks and prohibited-import checks.

The checked-in isolated Swift probe supplies reduced evidence for Foundation
negative controls, exact UTF-8 identity, the frozen whitespace oracle,
decimal-string integer extrema, canonical control-string escapes, strict
Base64 pad bits, bounded ASCII schema identifiers, exact schema-policy binding,
symmetric emission preflight, checked budget arithmetic, an actually generated
depth-198 structure and payload-free error renderings. Its Foundation envelope
parse is only a syntax smoke test; it does not prove candidate property order
or canonical ingress. Its RFC 8785 values are floating-vector anchors only.
The probe is not a complete parser/emitter, pre-allocation or policy-budget
proof, fuzz result, supported-device ceiling result, public API or
implementation authorisation. No full package test suite is warranted for
this Proposed documentation boundary.

## Migration

After this ADR plus `ADR-0028` through `ADR-0033` are accepted and the raw
ceiling, floating-point, cancellation and device evidence plus the approved
allocation-failure disposition (recoverable evidence or controlled-baseline
revision) are complete:

1. correct the controlled metadata, canonical-serialisation, validation and
   resource-limit sections to name `VCMJ-1`, the exact envelope, integer-string
   projection, JCS-derived Unicode policy, frozen blank-field whitespace set
   and trusted multiplicity binding;
2. replace the Core and Spatial dependency constructors' toolchain-dependent
   whitespace predicates with private module-local implementations of the
   enumerated oracle and cross-module fixtures, then add the bounded Core-owned
   ASCII schema-reference declarations without standalone Codable;
3. implement the dedicated iterative incremental parser and canonical emitter,
   with no Foundation raw-boundary fallback;
4. add focused golden, malformed, duplicate, lexical, schema-policy, resource,
   cancellation, privacy and differential fixtures before exposing the codec;
5. retain the ordinary type-level Codable wire shape and emitted values for
   previously accepted inputs while applying the documented blank-domain
   broadening to construction and decode; label both coding surfaces explicitly
   in documentation and APIs;
6. integrate adapters only with immutable caller limits and trusted schema
   context, keeping decompression and transport errors outside Core; and
7. make no content-ID, digest, signature or export change until its own accepted
   decision defines the projection and authority.

While this ADR or any semantic dependency remains Proposed, do not add public
recursive metadata, canonical-parser or canonical-emitter source. The next
independent audit may study persistent metadata identity, but it must treat
`VCMJ-1` as proposed complete-record bytes rather than an already accepted
digest projection.

## Supersession

This ADR supersedes no accepted decision. If accepted, it refines the raw
canonical-JSON and schema-version obligations left open by `ADR-0028` through
`ADR-0033`; ordinary type-level Codable wire shape and emitted values for
previously accepted inputs remain intact, while the documented blank-domain
broadening applies to construction and decode. `ADR-0034` stays an independent
post-ingress typed-read proposal.

## References

- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Project Foundation v0.1.1](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0028 - Canonical instant boundary](ADR-0028-canonical-instant-boundary.md)
- [ADR-0029 - Finite floating-point metadata boundary](ADR-0029-finite-floating-point-metadata-boundary.md)
- [ADR-0030 - Owned binary metadata boundary](ADR-0030-owned-binary-metadata-boundary.md)
- [ADR-0031 - Bounded recursive metadata value boundary](ADR-0031-bounded-recursive-metadata-value-boundary.md)
- [ADR-0032 - Required metadata-entry privacy attachment](ADR-0032-required-metadata-entry-privacy-attachment.md)
- [ADR-0033 - Ordered metadata collection and explicit multiplicity policy](ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md)
- [ADR-0034 - Closed exact-case typed metadata read boundary](ADR-0034-closed-exact-case-typed-metadata-read-boundary.md)
- [RFC 8259 - The JavaScript Object Notation (JSON) Data Interchange Format](https://www.rfc-editor.org/rfc/rfc8259.html)
- [RFC 7493 - The I-JSON Message Format](https://www.rfc-editor.org/rfc/rfc7493.html)
- [RFC 8785 - JSON Canonicalization Scheme](https://www.rfc-editor.org/rfc/rfc8785.html)
- [RFC 4648 - The Base16, Base32, and Base64 Data Encodings](https://www.rfc-editor.org/rfc/rfc4648.html)
- [ADR-0035 canonical metadata ingress probe](../../progress/evidence/ADR-0035-canonical-metadata-ingress-probe.swift)
