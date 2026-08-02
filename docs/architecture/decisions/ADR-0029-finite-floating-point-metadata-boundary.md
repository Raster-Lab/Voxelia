---
document_id: "ADR-0029"
title: "Finite floating-point metadata boundary"
status: "Proposed"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ARC-003"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-DAT-014"
  - "VOX-META-001"
  - "VOX-META-002"
  - "VOX-ERR-001"
  - "VOX-DCM-003"
  - "VOX-VAL-007"
---

# ADR-0029 - Finite floating-point metadata boundary

## Context

The Core Data Model Specification requires floating-point metadata to define
whether non-finite values are permitted, but prescribes this directly
constructible payload:

```swift
case floatingPoint(Double)
```

That shape admits every IEEE 754 binary64 value before metadata collection or
decoder validation can run. In particular, NaN is not equal to itself under
ordinary Swift numeric equality, so a synthesised `Hashable` recursive
`MetadataValue` would not provide an equivalence relation for all constructible
values. Multiple NaN payloads, and even repeated insertion of one NaN value,
can therefore behave incoherently in sets and duplicate detection.

Signed zero exposes a different mismatch. Swift `Double` equality and hashing
treat positive and negative zero as equal, while their bit patterns differ and
the current Foundation `JSONEncoder` emits `0` and `-0` respectively. The Core
Data Model Specification separately requires negative zero to be canonicalised
where semantic equality requires it and requires canonical JSON to choose a
stable numeric representation and a non-finite policy. A raw associated value
cannot enforce either choice.

RFC 8259 JSON numbers cannot spell NaN or infinity. It permits many decimal
spellings that a binary64 decoder may map to the same value, and it does not
define canonical number bytes. RFC 7493 gives binary64-oriented
interoperability guidance but likewise does not choose a unique spelling or a
signed-zero policy. Informative RFC 8785 JCS rejects NaN and infinity,
serialises both zero signs as `0`, and demonstrates
round-tripping finite subnormal binary64 values. Voxelia has not selected JCS,
so those rules are useful precedent rather than authority for the project's
complete canonical JSON contract.

Existing Voxelia matrix, spatial primitive, unit-conversion and lookup-table
values consistently reject NaN and both infinities, canonicalise signed zero
and preserve every other finite value. Floating metadata needs its own nominal
boundary because not every use of `Double` in the library necessarily shares
that policy, and a generic public finite-number primitive would exceed the
governed metadata correction.

This proposal selects one independently valid Core leaf and the minimum
controlled correction required to use it. It does not authorise the recursive
`MetadataValue`, metadata entries or collections, a canonical JSON byte
ingress, a decimal-number type, arithmetic, unit semantics or source-metadata
conversion. Its Proposed status does not authorise source or controlled-
document changes.

## Decision

If this ADR is accepted, `VoxeliaCore` will own these public values:

```swift
public enum MetadataFloatingPointError: Error, Sendable, Equatable {
    case nonFiniteValue
}

public struct MetadataFloatingPoint: Sendable, Hashable, Codable {
    public let value: Double

    public init(value: Double) throws
}
```

The controlled metadata declaration will replace only the raw floating-point
payload:

```swift
case floatingPoint(MetadataFloatingPoint)
```

`MetadataFloatingPoint` represents one finite IEEE 754 binary64 value. The
throwing initialiser will apply exactly these rules:

1. every quiet or signalling NaN, regardless of sign or payload, and positive
   or negative infinity throws `.nonFiniteValue`;
2. either signed zero is stored as positive zero; and
3. every other finite binary64 bit pattern is stored unchanged.

Rule three includes positive and negative normal values, positive and negative
subnormals, `leastNonzeroMagnitude`, `leastNormalMagnitude` and both finite
magnitude extrema. Construction performs no rounding, clamping, denormal
flushing, arithmetic conversion or unit inference. The implementation should
classify and canonicalise through the binary64 bit pattern, or an equivalently
exact operation, so preserving a subnormal does not depend on an arithmetic
result.

Equality and hashing will use the stored canonical binary64 identity. After
non-finite rejection and zero normalisation, each stored bit pattern denotes
one ordinary finite numeric value and ordinary equality is reflexive. A custom
bit-pattern implementation or synthesis with demonstrably equivalent behaviour
is acceptable; equality and hashing must never apply an approximate tolerance.
Two decimal source tokens that round to the same binary64 value are therefore
the same `MetadataFloatingPoint`. Source decimal spelling or precision is not
part of this type's identity. Process-randomised `hashValue` is only an
in-memory collection aid and must never be stored or used as a content digest.

The type will not conform to `RawRepresentable`, `Comparable`,
`LosslessStringConvertible`, `ExpressibleByFloatLiteral`,
`CustomStringConvertible` or a floating-point arithmetic protocol. Those
conformances would add unchecked construction, unapproved presentation,
ordering or arithmetic behaviour. Callers that require units, uncertainty,
missing-value semantics or source lexical preservation need separately typed
metadata rather than conventions attached to this scalar.

There will be no named NaN, infinity, missing or unavailable member in version
one. IEEE 754 does not assign application meaning to a NaN payload, and the
governing metadata model defines no sentinel semantics. A source that needs to
preserve exceptional bits or a special-value vocabulary must retain them at an
explicitly specified adapter boundary until an approved namespaced metadata
schema defines meaning and wire representation. It must not silently coerce
them to zero, omit an entry or invent a string token.

Type-level Codable will use one single-value floating-point scalar. In JSON the
shape is one JSON number, for example:

```json
1.25
```

Encoding will pass the finite stored `Double` to a single-value container.
Decoding will request one `Double` from a single-value container and invoke the
validating initialiser. A decoded non-finite value will become
`DecodingError.dataCorrupted` at the current coding path, with
`MetadataFloatingPointError.nonFiniteValue` as its underlying error and a generic
description that does not include the value or its source token. A normal
`JSONDecoder`, including one configured to translate special strings such as
`"NaN"` or `"Infinity"`, must therefore not create a non-finite wrapper. Null,
Boolean, ordinary strings, arrays and objects are invalid JSON shapes.

This Codable contract is strict about the scalar type and the value invariant;
it is not a raw-number lexer. A general decoder can map `1`, `1.0`, `1e0` or a
longer decimal to the same binary64 value before the initialiser runs, and it
can preserve a negative-zero token only long enough for the wrapper to
normalise it. The leaf cannot recover the original token, reject duplicate
object keys, enforce a document or token byte limit, or prove that input was
already in canonical form.

Ordinary `JSONEncoder` output is likewise not declared to be Voxelia canonical
JSON. Stable shortest-round-trip spelling, exponent form, key ordering,
schema-version envelopes, raw duplicate-key rejection and acceptance or
rejection of noncanonical input remain part of the canonical byte-ingress and
serialiser decision. Proposed `ADR-0035` now selects a JCS-derived shortest-
round-trip projection with positive-zero spelling, but it remains unaccepted
and still requires differential evidence. This ADR only ensures that every
value admitted by the leaf has a valid JSON-number representation available to
such a serialiser.

Only errors created by `MetadataFloatingPoint` are guaranteed to redact the
value. An underlying JSON implementation may reject an out-of-range or
malformed numeric token before the wrapper is called and may include that token
in its own error. Untrusted byte ingress and logging must sanitise those
decoder failures and enforce resource limits independently.

## Alternatives considered

### Retain the raw Double payload

Collection-time validation could reject non-finite values later, but invalid
standalone `MetadataValue` values would remain constructible, hashable and
serialisable before that check. Synthesised Codable would also expose the
compiler-shaped associated-value payload rather than a reviewed scalar
contract.

### Permit every IEEE 754 value

This preserves computation results without loss, but leaves NaN outside an
equivalence relation and outside the JSON number grammar. It would require
sign, payload, equality, hashing and tagged wire rules that no metadata
requirement currently supplies.

### Add named NaN and infinity cases

A nominal enum could provide coherent identity for `notANumber`,
`positiveInfinity` and `negativeInfinity` and could encode them with explicit
tags or strings. It is deferred because the baseline does not define their
metadata meaning, whether all NaN payloads collapse, whether NaN sign matters,
or which consumers may treat them numerically. Named sentinels can be added
later under a versioned metadata-schema decision without weakening this finite
case.

### Preserve signed zero as distinct identity

Bitwise identity could retain both zeros, but it would deliberately disagree
with ordinary numeric equality and with JCS number serialisation. The
unqualified metadata case provides no direction, limit or underflow semantics
that make the sign observable. Canonicalising zero aligns value identity with
the stated numeric meaning; sign-sensitive source bits require a separately
specified representation.

### Reject negative zero

Rejection would avoid normalisation but make an otherwise finite numeric value
fail solely because of a representational alias. It would also make ordinary
decoding of a valid JSON `-0` token fail. Documented canonicalisation is the
smaller semantic policy and matches existing Voxelia finite-value leaves.

### Flush subnormals to zero

This can be convenient for some execution backends but changes finite source
data, destroys binary64 identity and depends on a floating-point environment.
Metadata storage is not an execution kernel. Every finite subnormal is
preserved, and any operation that cannot support it must fail or document its
own validated conversion policy.

### Store a decimal string or decimal type

A decimal representation could preserve source lexical precision, but it is a
different value domain from the prescribed `Double` case and would require
precision, exponent, normalisation, equality and canonical-wire rules. It may
be introduced as a distinct future metadata case rather than silently changing
binary64 semantics.

### Introduce a generic FiniteDouble type

A generic wrapper could be reused by future Core declarations, but it would
publish a cross-domain policy that the metadata requirement does not authorise
and could invite use where infinity or NaN has approved meaning. The
metadata-specific name keeps this decision bounded and does not require
retrofitting existing spatial or transform APIs.

### Defer the leaf until the complete metadata model

This avoids one proposal, but it leaves an explicit scalar invariant mixed
with unrelated recursive-depth, binary, object, multiplicity, privacy and
canonical-ingress decisions. The nominal finite leaf is independently
reviewable and can be implemented after acceptance without authorising those
aggregates.

## Consequences

- Every constructible floating metadata leaf has reflexive exact equality and
  coherent hashing.
- NaN and infinity cannot enter metadata through this case; consumers do not
  need an implicit sentinel policy.
- Signed-zero information is intentionally discarded, while every other
  finite binary64 bit pattern, including subnormals, is preserved.
- The case gains one small public wrapper and one typed error instead of
  exposing `Double` directly.
- A scalar JSON-number shape is available, but canonical decimal bytes and
  raw-ingress validation remain explicitly unresolved.
- `MetadataValue` remains blocked pending the binary leaf and accepted bounded
  recursive-value decision `ADR-0031`; collection multiplicity, privacy
  attachment, typed access and canonical JSON remain separate blockers for
  their wider layers.

## Affected modules

If accepted, `VoxeliaCore` will own `MetadataFloatingPoint`,
`MetadataFloatingPointError` and the future corrected `MetadataValue` payload.
No package edge, product or current module ownership changes. Spatial,
Storage, adapter, provenance and execution modules are downstream consumers
only and must not reinterpret the scalar's finite binary64 identity.

## Compatibility impact

No public `MetadataValue`, `MetadataFloatingPoint` or serialised metadata
fixture exists, so replacing the prescribed raw payload will not move a
compiled symbol or live artefact. The correction is intentionally proposed
before the recursive aggregate becomes public.

Once implemented, the type names, error case, `value` property, finite-only
domain, signed-zero normalisation, preservation of other finite bit patterns
and single-value Codable shape become pre-1.0 compatibility contracts. A
future decimal or exceptional-value domain must use a distinct case or an
explicitly versioned migration rather than reinterpret this one.

## Security impact

Construction has a fixed eight-byte value input and emits a value-redacted
typed error. Rejecting NaN prevents unordered comparison from bypassing later
set-membership or value-identity logic, and rejecting infinity prevents an
exceptional arithmetic token from masquerading as ordinary metadata.

The wrapper is not a byte-ingress security boundary. A generic JSON decoder may
allocate or scan an arbitrarily long numeric token and may place rejected source
text in an error before this initialiser runs. The future canonical ingress
must cap document, nesting and token sizes, reject malformed and duplicate
input before semantic decoding, and sanitise logs. This scalar provides no
authenticity, trust, authorisation or privacy classification by itself.

## Performance and memory impact

Validation and zero normalisation are constant-time bit-level work, and the
stored payload is one immutable `Double`. Equality, hashing and encoding are
constant time. There is no allocation, recursion, locale, registry, global
state, lock, actor hop, I/O or arithmetic conversion in construction.

## Validation impact

After acceptance and leaf implementation, focused Core evidence must cover:

- positive and negative ordinary values, `leastNormalMagnitude`, both signed
  least subnormals and both finite magnitude extrema;
- exact preservation of representative and generated finite bit patterns,
  with only negative zero changing to the positive-zero bit pattern;
- rejection of both infinities and quiet or signalling NaNs across signs and
  payloads with exactly `.nonFiniteValue`;
- positive- and negative-zero equality, hashing, set behaviour and encoded
  normalisation;
- reflexive equality and coherent set behaviour for every constructible value;
- `Sendable` conformance and immutable storage;
- single-number JSON round trips with representative exact bit preservation;
- defined value-level decoding of integer, fraction, exponent and signed-zero
  aliases without claiming their source spellings are canonical;
- rejection of null, Boolean, string, array and object shapes, including
  configured non-conforming float strings;
- decode-time invariant revalidation with the current nested coding path, the
  typed underlying error and no wrapper-originated value disclosure;
- explicit evidence that decoder failures occurring before wrapper validation
  are outside its redaction and resource-limit guarantee; and
- a static check that Core adds no dependency or prohibited import.

Property testing may sample or exhaust binary64 classification boundaries by
bit pattern; it must not perform arithmetic that could flush subnormals before
construction. Canonical JSON tests must wait for the selected raw serialiser
and cannot be claimed from ordinary `JSONEncoder` output. No Swift suite is
warranted while this ADR remains Proposed.

## Migration

After acceptance:

1. correct Core Data Model Specification sections 34.3 and 34.6 to use
   `MetadataFloatingPoint` and add the leaf and error to the Core type
   inventory;
2. implement only the standalone wrapper and typed error in `VoxeliaCore` with
   strict single-value Codable;
3. add the focused Core, DocC and static dependency evidence listed above;
4. use the wrapper in `MetadataValue` only after bounded recursive-value
   decision `ADR-0031` is accepted, while keeping general entries,
   collections and privacy attachment deferred to their own decisions;
5. use canonical numeric bytes and raw-ingress limits only after proposed
   `ADR-0035` is accepted with its required differential and resource
   evidence; and
6. update traceability, changelog and release-integrity evidence.

No migration step may begin while this ADR remains Proposed.

## Supersession

This Proposed ADR neither supersedes nor is superseded by another file-backed
ADR. If accepted, it resolves only the raw floating-point metadata policy and
payload correction through the controlled migration above. It does not select
a complete metadata schema, canonical JSON algorithm, floating-point execution
environment or exceptional-value vocabulary. While Proposed, it has no
supersession effect.

## References

- [Voxelia Core Data Model Specification v0.1.1, sections 7.3, 7.6, 34, 55, 56, 64 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 8, 9 and 12](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Project Foundation v0.1.1, sections 25.2 through 25.4](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, sections 11.5 and 26.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.5 through 6.7, 6.10, 6.29, 6.34 and 6.36](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [IEEE 754-2019 - IEEE Standard for Floating-Point Arithmetic](https://standards.ieee.org/ieee/754/6210/)
- [RFC 8259, section 6 - JSON numbers](https://www.rfc-editor.org/rfc/rfc8259.html#section-6)
- [RFC 7493, section 2.2 - I-JSON numbers](https://www.rfc-editor.org/rfc/rfc7493.html#section-2.2)
- [RFC 8785, sections 3.1, 3.2.2.3 and Appendix B - JCS number input, serialisation and examples](https://www.rfc-editor.org/rfc/rfc8785.html)
- [The Swift Programming Language - The Basics](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/thebasics/)
- [Apple Foundation `JSONEncoder.NonConformingFloatEncodingStrategy`](https://developer.apple.com/documentation/foundation/jsonencoder/nonconformingfloatencodingstrategy-swift.enum)
- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
