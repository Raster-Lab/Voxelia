---
document_id: "ADR-0034"
title: "Closed exact-case typed metadata read boundary"
status: "Accepted"
date: "2026-08-04"
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
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
---

# ADR-0034 - Closed exact-case typed metadata read boundary

## Context

The controlled metadata model declares a phantom typed key:

```swift
public struct MetadataKey<Value: Sendable>: Sendable, Hashable {
    public let namespace: String
    public let name: String
}
```

It separately stores an erased `AnyMetadataKey` and one of eleven
`MetadataValue` cases. Typed accessors must validate the expected type and
return a typed metadata error without silently coercing unrelated values, but
the documents define no conversion table, accessor signature, missing-value
rule or multiplicity behaviour.

The current `MetadataKey` source makes the gap explicit: `Value` identifies a
caller-expected type at compile time but is not stored or serialised. Runtime
identity is only the exact accepted UTF-8 namespace/name pair. Any `Sendable`
specialisation remains constructible, including `MetadataKey<Double>` and
application-defined types, without proving that Core can extract such a value.

The raw controlled value sketch cannot supply an unambiguous table. Both
generic strings and instants use `String`, while finite floating point and
binary use raw `Double` and `Data`. Proposed `ADR-0028` through `ADR-0031`
instead give every semantically distinct case one exact associated payload:
`CanonicalInstant`, `MetadataFloatingPoint`, `MetadataBinary`, nominal recursive
containers and the remaining scalar/domain types. Those still-Proposed shapes
make a closed one-to-one mapping reviewable without reintroducing raw aliases.

Open conversion mechanisms are unsafe for this boundary. A public protocol,
callback, registry or key-stored closure would let external code reinterpret,
coerce or log arbitrary erased values and return source-bearing errors. Swift
does not provide a sealed public protocol that only Core may conform. A loose
generic `as? Value` also admits protocol existentials and supertypes rather
than proving exact metatype identity. Storing a projector in `MetadataKey`
would change its layout, construction, `Hashable` semantics and documented
phantom-only role.

Proposed `ADR-0032` requires every general entry to retain an exact privacy
class over both key and complete value. Returning a bare `Value` or `[Value]`
would be a library-owned projection that silently detaches the declaration,
especially when repeated entries carry different classes. Proposed `ADR-0033`
also fixes single-read missing/multiple/type-mismatch outcomes and ordered
all-element multi-read validation, but deliberately leaves the mapping and
public API to this decision.

This record selects a Core-owned closed exact-case read surface. It does not
define namespace semantics, schema authentication, custom conversions,
optional/default reads, privacy authorisation, export, canonical bytes,
persistent identity or write/update APIs. It was reviewed and accepted by
the project owner on 2026-08-04, with its dependencies (`ADR-0028` through
`ADR-0033`) already accepted and the closed overload family, the
classified typed result and the count-first cardinality precedence each
selected through interactive decision review.

## Decision

With `ADR-0028` through `ADR-0034` accepted, `VoxeliaCore` owns these
additional public declarations:

```swift
public enum MetadataReadError: Error, Sendable, Equatable {
    case missingValue
    case multipleValues
    case typeMismatch
}

public struct TypedMetadataEntry<Value: Sendable>: Sendable {
    public let key: MetadataKey<Value>
    public let value: Value
    public let privacyClass: MetadataPrivacyClass
}
```

`TypedMetadataEntry` is an immutable read result. It has no public initializer,
`Codable`, `Hashable`, `Equatable`, textual/debug-description, `CustomReflectable`
or safe-display conformance in version one. Its stored properties remain
publicly readable. The absence of a public initializer prevents this read-only
projection from becoming an unreviewed typed-write path.

`MetadataCollection` publishes two concrete overloads for every row in the
closed table below:

```swift
public func entry(
    for key: MetadataKey<Bool>
) throws -> TypedMetadataEntry<Bool>

public func entries(
    for key: MetadataKey<Bool>
) throws -> ContiguousArray<TypedMetadataEntry<Bool>>
```

The same two exact signatures are published with `Bool` replaced by each other
supported `Value`. This is an overload family, not one unconstrained generic
method and not a public conversion protocol.

### Closed exact-case mapping

The version-one table is exhaustive:

| Supported `MetadataKey<Value>` | Required stored case | Returned value |
|---|---|---|
| `MetadataKey<Bool>` | `.boolean(Bool)` | Exact associated `Bool` |
| `MetadataKey<Int64>` | `.signedInteger(Int64)` | Exact associated `Int64` |
| `MetadataKey<UInt64>` | `.unsignedInteger(UInt64)` | Exact associated `UInt64` |
| `MetadataKey<MetadataFloatingPoint>` | `.floatingPoint(MetadataFloatingPoint)` | Exact validated wrapper |
| `MetadataKey<String>` | `.string(String)` | Exact stored string; never instant text |
| `MetadataKey<MetadataBinary>` | `.binary(MetadataBinary)` | Exact owned wrapper; never `Data` |
| `MetadataKey<CanonicalInstant>` | `.instant(CanonicalInstant)` | Exact validated instant wrapper |
| `MetadataKey<MeasurementUnit>` | `.unit(MeasurementUnit)` | Exact associated unit |
| `MetadataKey<CodedConcept>` | `.code(CodedConcept)` | Exact associated concept |
| `MetadataKey<MetadataArray>` | `.array(MetadataArray)` | Exact validated array wrapper |
| `MetadataKey<MetadataObject>` | `.object(MetadataObject)` | Exact validated object wrapper |

Extraction pattern-matches the enum case and returns its associated value. It
does not parse, normalise, widen, narrow, bridge, unwrap, flatten, serialise,
decode, apply unit conversion or resolve semantic aliases.

There are deliberately no read overloads for `Int`, `Float`, `Double`, `Data`,
`Date`, native arrays/dictionaries, optionals, `MetadataValue`, protocol
existentials or arbitrary application types. In particular, the already-public
`MetadataKey<Double>` remains a valid phantom key identity but cannot be passed
to `entry(for:)` or `entries(for:)`. Floating-point reads use
`MetadataKey<MetadataFloatingPoint>`. Unsupported specialisations fail overload
resolution at compile time, so no runtime `unsupportedValueType` case exists.

Adding a future exact mapping requires a reviewed additive overload decision.
Custom semantic conversion belongs in an explicit adapter operation after an
exact typed read, not inside Core lookup. A separately supplied closed
projection witness may be reviewed later if generic algorithms demonstrate a
real need; it is not stored in the key or accepted in version one.

### Exact-key matching

Both operations compare the requested typed key with stored erased keys by the
exact ordered UTF-8 bytes of namespace and name. They do not use ordinary Swift
`String ==`, Unicode normalisation, case folding, namespace aliasing, a schema
resolver, hash value alone or the generic `Value` as stored identity.

Canonically equivalent but byte-distinct strings remain distinct keys, matching
the existing `MetadataKey` and `AnyMetadataKey` contract. A successful key
match proves only exact pair identity. It does not prove that the caller chose
the correct generic type or that a namespace authority endorses the request.

### Single-entry cardinality and precedence

`entry(for:)` determines exact-key cardinality before inspecting any stored
value case:

1. zero matches throws `MetadataReadError.missingValue`;
2. more than one match throws `.multipleValues`, regardless of cases, values or
   privacy classes; and
3. exactly one match returns a `TypedMetadataEntry` when its case matches the
   concrete overload, otherwise it throws `.typeMismatch`.

The operation never selects first or last, filters matches by case before
counting, prefers a matching case among mismatches or deduplicates equal
occurrences. This precedence makes duplicate order irrelevant to the failure
category and preserves the multiplicity boundary from `ADR-0033`.

There is no optional/default single-read convenience in version one. Callers
must handle `missingValue` explicitly. `MetadataKey<Value?>`, `try?`, implicit
defaults and a nullable result would blur absent, malformed and mismatched data.
A later optional query must be separately named and continue throwing for
multiple values and type mismatch.

### Plural reads

`entries(for:)` has these exact semantics:

- zero exact-key matches returns an empty `ContiguousArray`;
- one or more matches are returned in original collection occurrence order;
- every result retains the requested typed key, exact associated payload and
  that occurrence's exact privacy class;
- every matching occurrence must have the expected exact case; and
- any mismatch throws `.typeMismatch` atomically, without returning, logging or
  otherwise publishing a valid prefix.

The operation performs complete case preflight before materialising the public
result. It never filters, drops, groups, sorts or combines occurrences and never
infers an aggregate privacy class. `hostDefined` remains exact and unresolved.
Plural reads do not throw `missingValue` or `multipleValues`.

### Privacy and policy authority

Typed reads are mechanical projections of already-admitted collection content.
They accept no multiplicity policy, privacy policy, resolver, principal,
purpose or destination. Single access rejects every repeated key even when a
construction policy admitted it; plural access returns every ordered match.
Neither operation re-authenticates the caller assertion used during configured
construction.

A successful result proves only exact key and exact case. It is not read,
logging, export, disclosure or declassification authorisation. There is no
privacy-filtered read, class ordering, minimum-class option, `publicData`
shortcut, `isReadable` Boolean or `hostDefined` resolver in Core.

The result deliberately retains key and class, but ordinary Swift interpolation
or reflection can expose all three fields. `TypedMetadataEntry`, its key, value
and privacy class have no safe-display claim. Library and host code must not
interpolate or reflect raw results into logs, telemetry, filenames or user
interfaces. Hosts remain responsible for trusted policy before any disclosure.

### Error and diagnostic boundary

`MetadataReadError` is one non-generic payload-free enum. Its cases have no key,
requested type, actual case/type, value, privacy class, match count, index,
order, policy or underlying error. A generic error would reveal the requested
domain type through reflection even without an associated value.

The three fixed cases necessarily reveal a coarse read outcome to the direct
caller: absent, repeated or mismatched. That structured control flow is not
automatically safe telemetry. The read operations emit no logs or telemetry,
and hosts must not log even a fixed error case where presence or cardinality is
sensitive in context.

Private projectors pattern-match directly and cannot throw. No arbitrary
converter failure is caught or reflected. A result or error never retains an
underlying adapter, decoder, schema or host-policy error.

## Alternatives considered

### One unconstrained generic accessor with runtime casts

An API accepting every `MetadataKey<Value>` would need runtime metatype checks
and casts. Loose `as? Value` admits existentials or supertypes such as
`any Sendable`; exact metatype guards plus forced casts are fragile and still
make unsupported keys appear callable. Concrete overloads express the closed
surface at compile time and avoid `unsupportedValueType` runtime control flow.

### Public conversion or marker protocol

Swift public protocols are extensible. External conformers could parse,
coerce, log or throw arbitrary source-bearing errors, defeating Core's exact
mapping and diagnostic guarantees. A static witness requirement is not sealed
merely because current conformances are documented. Version one remains closed.

### Store a converter or discriminator in MetadataKey

A closure is not `Hashable`, may capture mutable state and could make equal key
pairs decode differently. A stored discriminator is safer but changes key
layout, construction and the current rule that only the pair is runtime
identity. Neither is necessary for a finite enum vocabulary.

### Return bare payloads

`Value` and `[Value]` are convenient but silently erase the required per-entry
privacy attachment. A separate privacy lookup is easy to omit and becomes
ambiguous for repeated keys. `TypedMetadataEntry` keeps each exact declaration
adjacent to its key and value.

### Return MetadataEntry plus a typed payload

Returning the complete erased entry beside a second payload duplicates the
value and still invites disagreement between them. A typed projection containing
one typed key, one exact payload and the original class is smaller and coherent.

### First/last or first-matching-case access

These choices silently discard occurrences and can use value case or order as a
selector. They violate `ADR-0033` cardinality, can hide a stricter privacy
declaration and make malformed mixed-case repeats appear valid.

### Optional or default-valued access

Returning `nil`, using `try?` or supplying a default can collapse absence,
multiplicity and type mismatch. Optional query ergonomics may be reviewed later
under a separately named API, but not by weakening the required accessor.

### Add a private lookup index immediately

The collection is bounded and metadata lookup only “may” be indexed. A private
index adds memory, immutable initialisation and collision/order review before
evidence shows a need. A linear baseline is simpler and supplies an oracle for
any future indexed implementation.

## Consequences

- All eleven corrected metadata cases have one compile-time visible exact read
  mapping, with no coercion or open converter authority.
- Current arbitrary `MetadataKey<Value: Sendable>` construction remains source-
  and layout-compatible; unsupported values simply have no read overload.
- Single reads distinguish missing, repeated and mismatched data with one
  payload-free non-generic error.
- Plural reads preserve order and every privacy declaration, return empty for
  absence and fail atomically on any case mismatch.
- Typed results retain classification instead of creating an unclassified bare-
  value convenience path.
- No read operation authenticates schemas, revalidates multiplicity or grants
  privacy/export permission.
- Version one adds 22 concrete public overloads. The larger explicit surface is
  intentional evidence of a closed mapping and makes new cases reviewable.
- No typed-read source is authorised while `ADR-0028` through `ADR-0034` remain
  Proposed.

## Affected modules

If accepted, `VoxeliaCore` owns `MetadataReadError`, `TypedMetadataEntry` and the
`MetadataCollection` overloads beside the other metadata types. The existing
approved `VoxeliaCore -> VoxeliaSpatial` dependency supplies `MeasurementUnit`;
no dependency edge, product, backend or adapter ownership changes.

Adapters may construct exact typed keys and perform explicit semantic
conversion after successful reads. Hosts own authentication, authorisation,
privacy policy, logging/export decisions and namespace-schema trust. Downstream
Imaging, Storage, provenance, DICOM and application modules consume the public
Core accessors without defining Core conversion hooks.

## Compatibility impact

`MetadataKey<Value: Sendable>` already exists. This proposal changes none of
its fields, initializer, constraints, equality, hashing or runtime layout.
Existing `MetadataKey<Double>` and application-specific keys remain
constructible; they do not gain an accidental mapping.

No product `MetadataValue`, `MetadataEntry`, `MetadataCollection`,
`TypedMetadataEntry` or typed-read fixture exists. The proposed overloads add no
wire representation. `TypedMetadataEntry` is deliberately non-Codable, so the
erased collection remains the only type-level storage representation.

After implementation, the eleven mappings, method names, result fields,
cardinality precedence, plural empty/order/atomicity and error cases become
pre-1.0 source contracts. A new metadata case does not automatically acquire a
read mapping; an additive overload and compatibility review are required.

## Security impact

Closed direct case matching prevents untrusted converter callbacks, parsing,
Foundation bridging and source-bearing converter errors inside Core lookup.
Exact UTF-8 matching prevents Unicode-canonicalisation or namespace-alias
confusion. Counting keys before type inspection prevents a matching case from
hiding an additional wrong-case or differently classified occurrence.

Privacy-preserving results keep every class, while absence of filtered
conveniences avoids implying authorisation. Payload-free errors prevent direct
reflection of source text, type names, values and exact structure. The coarse
outcome itself can still be sensitive, and raw typed results remain fully
reflectable, so neither is safe for automatic logging.

The collection ceilings from `ADR-0033` bound scan and result cardinality.
Hosts may impose lower admission/workload limits. Typed access is synchronous
and does not make an untrusted higher-level workflow cancellable; hosts retain
cancellation and scheduling responsibility around repeated or remote work.

## Performance and memory impact

Let `n` be the entry count, `m` the match count and `B` the total namespace/name
UTF-8 bytes examined by exact-key comparisons during an operation. Single
access performs one complete scan in O(n + B) time and O(1) auxiliary memory.
Plural access performs two complete scans—one count/type preflight and one
result-materialisation pass—in O(n + B + m) time with O(m) result storage.
The collection entry and logical-payload ceilings bound entries and key bytes.

Returned structs may share immutable copy-on-write backing for strings, bytes,
arrays and objects; the accessor does not deep-copy recursive payloads. It does
not mutate the collection or expose shared mutation. Repeating the requested
typed key in plural results copies value handles, not necessarily underlying
UTF-8 storage.

No lookup cache or index is stored in version one. A future private index must
map complete exact keys to source-order position lists, remain immutable and
`Sendable`, handle hash collisions by equality, avoid dictionary iteration as
ordering, and stay outside public identity, hashing and wire. It must not cache
schema validity, multiplicity authority, privacy resolution or authorisation,
and requires focused memory/performance evidence against the linear oracle.

## Validation impact

Before acceptance and implementation, focused evidence must cover:

- strict Swift concurrency and `Sendable` checking for the error, typed result,
  collection and every supported payload;
- successful compile-time overload resolution and exact extraction for all
  eleven table rows under both single and plural methods;
- compile-negative fixtures for representative unsupported specialisations,
  including `Double`, `Data`, optionals, `MetadataValue`, native containers and
  protocol existentials;
- proof that the current arbitrary typed-key initializer and pair identity are
  unchanged;
- exact UTF-8 cross-form key matching, including canonically equivalent but
  byte-distinct namespace and name strings;
- zero, one and repeated exact-key cardinality, with cardinality decided before
  value-case inspection;
- a mixed-case duplicate where one occurrence matches, proving single access
  returns `multipleValues` rather than selecting it;
- plural zero-match empty success, exact occurrence order, all five privacy
  classes, unresolved `hostDefined` and mixed-class repeats;
- late plural mismatch after a valid prefix, proving atomic failure with no
  filtered or partial result;
- exact wrapper preservation with no floating-point unwrapping, binary/Data
  bridging, instant parsing, numeric conversion, flattening or Codable route;
- API checks proving no bare-value, optional/default, privacy-filtered, public-
  converter, public typed-result initializer, Codable or safe-display surface;
- descriptive and reflective error rendering with no key, requested/actual
  type/case, value, class, exact count, index, order, policy or underlying error;
- no library log/telemetry emission on success or failure;
- worst-case linear lookup and plural-result allocation under the accepted
  collection ceiling and lower representative host limits; and
- owning-Core and directly affected dependent builds with strict formatting
  and prohibited-import checks after source is authorised.

The checked-in isolated Swift 6 probe uses reduced nominal payloads. It proves
that concrete generic-argument overloads compile, all eleven exact mappings and
both read families resolve, unsupported `Double` fails overload resolution,
cardinality precedes case matching, plural reads remain ordered/atomic, all five
classes survive and exact UTF-8 lookup plus payload-free errors are feasible.
It does not implement product metadata, authenticate a schema, prove production
privacy policy or authorise source. No full package suite is warranted for this
Proposed documentation boundary.

## Migration

After `ADR-0028` through `ADR-0034` are accepted and the recursive/collection
ceiling evidence required by `ADR-0031` and `ADR-0033` is approved:

1. correct Core Data Model Specification sections 34.1, 34.3, 34.7, 58, 64.6,
   66, 67 and 70.5 plus Master Technical Architecture section 12.1 to define
   the closed corrected-payload mapping, classified typed result, cardinality
   and no-coercion behaviour;
2. implement the accepted metadata leaves, recursive value, classified entry
   and ordered collection before the dependent read surface;
3. implement `MetadataReadError`, `TypedMetadataEntry`, private nonthrowing
   exact-case projectors and the 22 concrete overloads in `VoxeliaCore`;
4. add the focused positive, compile-negative, cardinality, order, privacy,
   redaction, concurrency, allocation and static-dependency evidence above;
5. keep optional/default access, custom semantic conversion, namespace-schema
   identity, privacy authorisation, canonical ingress, persistent digest,
   logging/export and write/update APIs deferred to their own accepted work,
   including proposed `ADR-0035` for canonical ingress; and
6. update traceability, changelog, API documentation, validation reports and
   release-integrity evidence.

These migration steps are authorised as of the 2026-08-04 acceptance:
`ADR-0028` through `ADR-0034` are accepted, step 2's dependent types are
already implemented, and the recursive/collection ceiling evidence is
approved on local Apple Silicon with the supported-device matrix recorded
as an open evidence gap. Step 5 remains governed by its named decisions.

## Supersession

This ADR neither supersedes nor is superseded by another file-backed ADR.
It depends on the corrected payload table accepted by `ADR-0028` through
`ADR-0031`, the required classified entry from `ADR-0032` and the ordered
collection/cardinality boundary from `ADR-0033`. It completes only closed
exact-case typed reads.

It does not supersede namespace-schema, multiplicity admission, privacy policy,
canonical serialisation, persistent identity, provenance, logging/export,
adapter conversion or host-authorisation decisions.

## References

- [Voxelia Core Data Model Specification v0.1.1, sections 5.10, 34, 58, 64.6, 66 through 70 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 8, 12, 36 and 37](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Project Foundation v0.1.1, sections 22 and 25 through 29](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.1, 6.5 through 6.7, 6.10 and 6.34 through 6.37](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, metadata, malformed-input, privacy and resource sections](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Current MetadataKey source](../../../Sources/VoxeliaCore/Public/MetadataKey.swift)
- [ADR-0031 - Bounded recursive metadata value boundary](ADR-0031-bounded-recursive-metadata-value-boundary.md)
- [ADR-0032 - Required metadata-entry privacy attachment](ADR-0032-required-metadata-entry-privacy-attachment.md)
- [ADR-0033 - Ordered metadata collection and explicit multiplicity policy](ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md)
- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
- [ADR-0034 focused Swift evidence](../../progress/evidence/ADR-0034-typed-metadata-access-probe.swift)
