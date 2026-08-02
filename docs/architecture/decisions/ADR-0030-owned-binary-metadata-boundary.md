---
document_id: "ADR-0030"
title: "Owned binary metadata boundary"
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

# ADR-0030 - Owned binary metadata boundary

## Context

The Core Data Model Specification prescribes this binary metadata payload:

```swift
case binary(Data)
```

The same specification leaves whether `Data` is permitted directly in core
serialisable metadata as an open implementation decision and prohibits open
decisions from being resolved by the first convenient implementation. This is
a public data-model and wire-shape choice, so it requires a focused architecture
decision before source is added.

`Data` is a useful Foundation interchange type, but its value spelling does not
by itself establish Voxelia's immutable metadata identity. In particular,
Foundation permits no-copy data backed by caller-managed memory. A local Swift
6.3.3 probe confirmed that mutating such a backing allocation changed the bytes
observed through a previously stored `Data` value and invalidated hash-based set
lookup. Ordinary copy-on-write behaviour does not protect against mutation
through an external pointer that remains outside `Data`'s mutation machinery.
Materialising the same source into `ContiguousArray<UInt8>` produced an
independent snapshot.

`Data`'s Foundation Codable conformance is not a stable Voxelia contract
either. Foundation encoders and decoders expose configurable data strategies,
so the same bytes may be represented as a Base64 string, a numeric array or an
application-defined shape. Synthesised Codable for the containing associated-
value enum would also expose a compiler-shaped envelope before Voxelia has
selected case tags or a top-level schema version.

JSON has no binary primitive. The Core Data Model Specification requires the
canonical JSON decision to select Base64 or hexadecimal, but it does not make
that choice. RFC 4648 defines standard Base64, Base64URL and Base16 while
leaving applications to select and constrain the form they use. Its padding,
non-alphabet and unused-bit rules must be made exact if one byte sequence is to
have only one accepted semantic string.

The governing requirements do not set a universal maximum for a binary
metadata leaf. The security architecture instead requires host-defined
resource limits, while the data-model specification says large sample buffers
are not embedded in descriptor JSON by default. An arbitrary fixed leaf limit
would reject previously permitted source metadata without evidence, and a
limit checked by type-level `Decodable` would run only after a general JSON
decoder had already allocated the source string.

This proposal selects one independently valid Core leaf and the minimum
controlled corrections required to use it. It does not authorise recursive
`MetadataValue`, metadata entries or collections, source-attribute mapping,
privacy attachment, canonical document bytes or a generic resource-limit API.
Its Proposed status does not authorise implementation or controlled-document
changes.

## Decision

If this ADR is accepted, `VoxeliaCore` will own this public value:

```swift
public struct MetadataBinary: Sendable, Hashable, Codable {
    public let bytes: ContiguousArray<UInt8>

    public init<Bytes: Collection>(bytes: Bytes)
    where Bytes.Element == UInt8
}
```

The controlled metadata declaration will replace only the raw binary payload:

```swift
case binary(MetadataBinary)
```

`MetadataBinary` identity is the exact byte count followed by the exact ordered
byte sequence. Source storage class, allocation address, capacity, segmentation,
Foundation bridging and source textual encoding are not part of identity.
Empty bytes are valid and differ from an absent metadata entry; a future
namespaced key schema may impose a non-empty constraint for that key.

The generic collection initialiser will materialise a canonical
`ContiguousArray<UInt8>` before returning. It must not retain the source
collection, a borrowed buffer or externally managed memory. Callers may pass a
Foundation `Data` because it is a byte collection, but the initialiser copies
the observed sequence into the owned value rather than storing or exposing that
`Data`. Passing an existing `ContiguousArray<UInt8>` may share immutable
copy-on-write storage; subsequent mutation of either value must still preserve
the stored sequence.

Equality and hashing will use the stored bytes exactly. There is no
case-folding, digest substitution, timing-safe comparison or content-type
interpretation. Swift's process-randomised hash is only an in-memory collection
aid and must never be persisted, distributed or treated as a content digest.
Cryptographic identity remains a separate `ContentID` decision.

The value will not conform to `RawRepresentable`, `ExpressibleByArrayLiteral`,
`Collection`, `MutableCollection`, `LosslessStringConvertible` or
`CustomStringConvertible`. Those conformances would add unchecked construction,
mutation, textual parsing or presentation behaviour that this leaf does not
need. Deliberate byte access remains available through the immutable `bytes`
property. Hosts must still avoid interpolating metadata values into logs.

There is no intrinsic byte-count maximum for the standalone leaf in version
one. Every finite byte collection is a semantically valid programmatic input,
subject to available memory. This absence is not permission for unbounded
untrusted decoding. A canonical or adapter ingress must apply host-selected
limits to the raw document, encoded string token and decoded binary leaf before
the corresponding allocations. Proposed `ADR-0031` additionally gives a
recursive array or object a hard logical aggregate-payload ceiling, so an
otherwise valid standalone leaf may be too large to embed in that container.
Hosts may impose lower aggregate limits. Large sample buffers remain external
references by default rather than binary metadata.

Type-level Codable will be implemented manually and will use exactly one
single-value JSON string containing the standard RFC 4648 Base64 alphabet:

```text
ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
```

The semantic string profile is:

1. the empty byte sequence is the empty string;
2. a non-empty encoding has a UTF-8 byte count divisible by four;
3. only the standard alphabet is accepted for data characters;
4. exactly zero, one or two `=` padding characters appear as required, and
   only at the end;
5. line breaks, whitespace, Base64URL `-` and `_`, and every other character
   are rejected; and
6. unused bits in the last non-padding sextet are zero.

The final rule rejects alternate strings that decode to the same bytes. With
two padding characters the low four bits of the second sextet must be zero;
with one padding character the low two bits of the third sextet must be zero.
Missing, surplus or misplaced padding is invalid rather than repaired. The
right-hand byte sequences in these canonical examples use hexadecimal notation:

```text
""        -> empty bytes
"Zg=="    -> 66
"Zm8="    -> 66 6f
"Zm9v"    -> 66 6f 6f
"+/8="    -> fb ff
```

Inputs such as `Zg`, `Zg=`, `Zg===`, `Zh==`, strings containing whitespace or
the Base64URL alphabet are rejected. The decoder will validate ASCII grammar,
padding and unused bits before materialising output. It will derive the decoded
count from complete quartets and padding using checked integer arithmetic
before reserving storage, then decode directly into the owned
`ContiguousArray<UInt8>`. The encoder will emit the same canonical alphabet and
padding directly from the stored bytes. Neither operation will delegate to a
`Data` coding strategy or a permissive Foundation Base64 decoder.

Every malformed semantic Base64 string created at this boundary will produce
`DecodingError.dataCorrupted` at the current coding path, with one generic
description that contains neither the source string, its bytes nor its length.
No public `MetadataBinaryError` is added: every byte sequence accepted by the
programmatic initialiser is valid, and there is no public textual parser whose
domain failure needs a separate error contract. Wrong JSON shapes retain the
decoder's normal typed errors. An underlying decoder may reject malformed JSON
or fail before the wrapper runs and may expose source text in its own error;
untrusted ingress and logging must sanitise those failures independently.

This leaf-level Codable contract establishes the binary value's semantic JSON
string, not the project's complete canonical JSON bytes. A general decoder can
translate JSON escape aliases such as `"\u005A\u0067=="` into `"Zg=="` before
the leaf sees them, and a general encoder may escape `/` as `\/`. The leaf also
cannot reject duplicate object keys, case-tag aliases, noncanonical outer key
order or missing schema versions. Those raw lexical and document rules remain
part of the canonical byte-ingress and serialiser decision. Proposed
`ADR-0035` now selects this padded standard-Base64 payload plus canonical pad-
bit and raw lexical checks for `VCMJ-1`, but remains unaccepted.

## Alternatives considered

### Retain Data directly

This is convenient at Foundation adapter boundaries, but it admits no-copy
storage whose externally managed bytes can change after hashing or validation.
It also lets encoder configuration choose the wire shape. Requiring adapters to
cross one explicit copying boundary is safer than making every metadata
consumer reason about `Data` provenance.

### Wrap and defensively copy into Data

A wrapper could copy into newly allocated `Data` and implement custom Codable.
That can be made correct, but retains a Foundation representation without a
Foundation semantic requirement. `ContiguousArray` follows the controlled
collection convention, keeps Core's public leaf in the Swift standard library
and makes ordered-byte identity explicit.

### Add a fixed one-mebibyte intrinsic maximum

One mebibyte provides simple bounded leaf operations and is large enough for
many technical blobs, but no baseline requirement chooses it. The existing raw
case admits larger values, format-specific metadata preservation has no such
cap, and a post-JSON-decoding check would not prevent allocation of the encoded
token. Limits belong to the host and raw ingress until a reviewed schema or
product policy supplies a stable value.

### Require a limit argument for programmatic construction

Making host policy part of the value initialiser would allow identical bytes to
be constructible in one context and invalid in another while still producing
the same public value. It would also fail to protect allocations that occurred
to create the source collection. Host and adapter admission APIs should enforce
their policies before constructing this context-independent leaf.

### Use hexadecimal

Hexadecimal is easy to inspect and has no padding, but it doubles byte size.
Base64 has approximately four-thirds expansion and a mature canonical profile.
Hex case, prefix and separator rules would still need project policy.

### Use Base64URL or omit padding

Base64URL is helpful inside URLs and filenames, but JSON strings have no such
constraint. A Base64URL-only or unpadded-only design could also define one
canonical profile; neither inherently requires accepting aliases. Standard
padded Base64 is selected as the sole profile because it directly satisfies
the controlled Base64 option and follows RFC 4648's default padding rule
without a project need to opt out. Decoders accept neither the alternate
alphabet nor the unpadded form.

Standards Track I-JSON normatively recommends Base64URL for binary data in JSON
strings, but that recommendation is not a MUST. Choosing standard Base64 is a
deliberate interoperability trade-off: it retains the established Base64
alphabet and padding in a context that needs neither URL nor filename safety,
at the cost of not following that recommendation.

### Encode a JSON array of byte numbers

An array is substantially larger, admits numeric spelling aliases at raw
ingress and conflicts with the controlled Base64-or-hexadecimal direction. It
also risks confusion with the separate recursive metadata array case.

### Use a content ID instead of bytes

Large sample data should normally be referenced by content identity or storage,
but small opaque metadata and source-format attributes still need lossless byte
values. A digest is not the content and cannot replace bytes when round-trip
preservation is required.

### Defer binary until the complete metadata model

That avoids a standalone proposal but leaves immutable ownership and Base64
canonicalisation mixed with unrelated recursion, key uniqueness, multiplicity,
privacy and case-tag decisions. The byte leaf is independently reviewable and
can be implemented after acceptance without authorising those aggregates.

## Consequences

- Every constructible binary metadata leaf owns a stable exact byte sequence,
  including a well-defined empty value.
- Foundation `Data` remains convenient at adapters but is copied at the Core
  value boundary and does not appear in the public stored representation.
- Type-level Codable has one strict padded Base64 semantic string independent
  of Foundation data strategies.
- The standalone leaf adds no arbitrary intrinsic maximum; safe untrusted
  decoding depends on earlier host-selected raw and decoded resource limits,
  while proposed `ADR-0031` separately bounds recursive embedding.
- Construction is linear in the general case but may share safe canonical
  copy-on-write storage in constant time; equality, hashing and serialisation
  are linear in byte count, so callers must not confuse this metadata leaf with
  large sample storage.
- Recursive metadata remains blocked by string identity and limits, tags,
  depth and total-size limits, object uniqueness and ordering, multiplicity,
  privacy and canonical document ingress.

## Affected modules

If accepted, `VoxeliaCore` will own `MetadataBinary` and the future corrected
`MetadataValue` payload. No package edge, product or current module ownership
changes. Foundation adapters may provide `Data` as collection input, but this
metadata boundary does not expose a Foundation binary type or depend on adapter
ownership rules. Storage, provenance, DICOM and other format adapters remain
downstream consumers and must not reinterpret the ordered bytes.

## Compatibility impact

No public `MetadataValue`, `MetadataBinary` or serialised metadata fixture
exists, so replacing the prescribed raw payload will not move a compiled symbol
or persisted artefact. The correction is intentionally proposed before the
recursive aggregate becomes public.

Once implemented, the type name, `bytes` property, copying initialiser, exact
ordered-byte identity, valid empty value and strict padded-Base64 semantic
Codable shape become pre-1.0 compatibility contracts. Future content typing or
compression must use a distinct schema or case rather than reinterpret these
opaque bytes. A future ingress limit may reject an input in a particular host
without changing which already-constructed `MetadataBinary` values are valid.

## Security impact

Snapshot materialisation prevents caller-managed no-copy memory from changing a
value after validation, hashing or insertion into a collection. Strict Base64
validation rejects ignored characters, alternate alphabets, excess padding and
non-zero unused bits that could otherwise create covert textual aliases. Base64
is an encoding, not encryption or redaction, and the bytes may themselves
contain identifying or sensitive metadata.

Wrapper-originated malformed-value errors disclose no source content or length.
The value is not an untrusted byte-ingress security boundary: a general JSON
decoder has already allocated its string, and programmatic source collections
already exist before construction. Hosts must cap raw documents and tokens
before allocation, cap decoded leaves and aggregate metadata, sanitise upstream
errors, enforce privacy policy and avoid logging values. Resource limits,
authenticity, trust, authorisation and privacy classification remain separate
contracts.

## Performance and memory impact

Construction is O(n) in the general case and materialises O(n) owned storage;
an existing safely shareable `ContiguousArray` may instead take an O(1)
copy-on-write path. When the source cannot transfer or share safe copy-on-write
storage, the copy temporarily coexists with the source. Equality and hashing
are O(n). Encoding and decoding are O(n); padded Base64 output contains
`4 * ceil(n / 3)` ASCII bytes, and decoding allocates the resulting byte count
after preflight.

The implementation must use checked count arithmetic and decode directly into
the destination rather than create an intermediate `Data`. It must not promise
constant-time comparison or graceful recovery from process-wide allocation
failure. Metadata collection and canonical-ingress benchmarks should later
cover host-selected boundary sizes, but no performance suite is warranted for
a Proposed documentation-only decision.

## Validation impact

After acceptance and leaf implementation, focused Core evidence must cover:

- strict Swift concurrency, immutable public storage and the absence of a
  Foundation type from the public shape;
- adversarial `Data(bytesNoCopy:)` backing mutation proving that construction
  snapshots the observed bytes and preserves set membership;
- ordinary copy-on-write sources and mutation after construction;
- empty input, all 256 byte values, differing lengths and orders, exact
  equality, hashing and set behaviour;
- RFC 4648 empty, one-, two- and three-byte vectors, plus values exercising `+`
  and `/` and lengths around every three-byte boundary;
- exact encode/decode round trips for generated byte arrays and representative
  host-bounded larger values;
- rejection of missing, excess and misplaced padding, non-zero unused bits,
  whitespace, line breaks, non-ASCII, invalid characters and Base64URL aliases;
- independence from every Foundation JSON data coding strategy;
- rejection of null, Boolean, number, array and object shapes;
- nested coding paths, `DecodingError.dataCorrupted` and value-redacted
  wrapper-originated diagnostics;
- decoded- and encoded-count preflight with overflow-safe arithmetic, including
  near-`Int.max` helper inputs that require no corresponding allocation;
- explicit evidence that raw token pre-allocation and aggregate limits remain
  outside the leaf; and
- a static check that Core adds no dependency or prohibited import.

The Base64 codec should receive property and fuzz testing because it is a
parser over untrusted semantic strings. Canonical-document tests must wait for
the selected raw serialiser and cannot be claimed from ordinary `JSONEncoder`
output. No Swift suite is warranted while this ADR remains Proposed.

## Migration

After acceptance:

1. correct Core Data Model Specification sections 34.3, 55.3 and 72 to use
   `MetadataBinary`, select strict padded standard Base64 for this leaf and
   close the direct-`Data` open decision;
2. add the leaf to the Core type inventory without introducing Foundation at
   this metadata boundary;
3. implement only the standalone wrapper and its manual single-string Base64
   Codable in `VoxeliaCore`;
4. add the focused Core, DocC, property, fuzz and static dependency evidence
   listed above;
5. use the wrapper in `MetadataValue` only after bounded recursive-value
   decision `ADR-0031` is accepted, while keeping general entries,
   collections and privacy attachment deferred to their own decisions;
6. use raw admission and decoded-leaf limits only after proposed `ADR-0035` is
   accepted with its required evidence, with hosts permitted to tighten the
   hard recursive ceilings proposed by `ADR-0031`; and
7. update traceability, changelog and release-integrity evidence.

No migration step may begin while this ADR remains Proposed.

## Supersession

This Proposed ADR neither supersedes nor is superseded by another file-backed
ADR. If accepted, it resolves only direct `Data` ownership and the binary
leaf's semantic JSON string through the controlled migration above. It does not
select a complete metadata schema, recursive resource policy, canonical JSON
document algorithm, content identity or privacy model. Proposed `ADR-0031`
governs only whether and how the standalone leaf may be embedded in a bounded
recursive value. While Proposed, neither record has supersession effect.

## References

- [Voxelia Core Data Model Specification v0.1.1, sections 7.3, 7.4, 34, 55, 58, 60, 64, 66 through 68, 72 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 8.2, 12.1, 37 and 38](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Project Foundation v0.1.1, sections 25.2 through 25.4, 27 and 28](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, sections 10.1 and 38](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.5 through 6.7, 6.10, 6.29, 6.34 and 6.36](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [RFC 4648 - The Base16, Base32, and Base64 Data Encodings](https://www.rfc-editor.org/rfc/rfc4648.html)
- [RFC 7493, section 4.4 - I-JSON binary data guidance](https://www.rfc-editor.org/rfc/rfc7493.html#section-4.4)
- [RFC 8259, sections 3 and 9 - JSON values and parser limits](https://www.rfc-editor.org/rfc/rfc8259.html)
- [RFC 8785 - JSON Canonicalization Scheme](https://www.rfc-editor.org/rfc/rfc8785.html)
- [Apple Foundation `Data(bytesNoCopy:count:deallocator:)`](https://developer.apple.com/documentation/foundation/data/init(bytesnocopy:count:deallocator:))
- [Apple Foundation `JSONEncoder.DataEncodingStrategy`](https://developer.apple.com/documentation/foundation/jsonencoder/dataencodingstrategy)
- [Apple Foundation `JSONDecoder.DataDecodingStrategy`](https://developer.apple.com/documentation/foundation/jsondecoder/datadecodingstrategy-swift.enum)
- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
