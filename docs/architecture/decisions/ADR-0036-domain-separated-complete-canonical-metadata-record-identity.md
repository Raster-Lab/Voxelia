---
document_id: "ADR-0036"
title: "Domain-separated complete canonical metadata record identity"
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
  - "VOX-RGN-007"
  - "VOX-RGN-008"
  - "VOX-RGN-009"
  - "VOX-META-001"
  - "VOX-META-002"
  - "VOX-META-011"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-ERR-001"
  - "VOX-ERR-003"
  - "VOX-ERR-007"
  - "VOX-SEC-001"
  - "VOX-SEC-003"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
  - "VOX-VAL-011"
---

# ADR-0036 - Domain-separated complete canonical metadata record identity

## Context

The controlled architecture requires a stable content identity for immutable
data, distinguishes a source or derivation identity from a completed content
digest and assigns identity records to `VoxeliaCore`. The Core Data Model
Specification additionally requires every content ID to declare its scope and
requires a namespaced approved identifier for a custom digest algorithm.

The two controlled `ContentID` sketches nevertheless prescribe incompatible
and incomplete records:

- the Master Technical Architecture uses `DigestAlgorithm` and Foundation
  `Data` but omits scope;
- the Core Data Model Specification uses an arbitrary `String` and
  `ContiguousArray<UInt8>` but also omits scope from the displayed record; and
- neither record identifies the versioned projection that produced the digest.

Synthesised `Codable` does not resolve the byte-storage conflict. Foundation
encodes `Data` as Base64 by default and encodes `ContiguousArray<UInt8>` as a
JSON integer array. Neither spelling is selected as the canonical digest text,
and a decoder cannot infer algorithm, scope or projection from digest length.
The existing `DigestAlgorithm.custom` case is also payload-free, so all custom
algorithms would collapse to the same persistent label despite the controlled
requirement for a namespaced identifier. The existing `blake3` case does not
distinguish the default 256-bit output from BLAKE3's extendable-output modes.

Current product source intentionally contains only `DigestAlgorithm` and
`ContentScope` declaration vocabularies. It contains no `ContentID`, digest
byte value, digest computation, verifier, `DataIdentity`, cache integration or
provenance integration. The taxonomies therefore cannot be treated as an
implemented persistent-identity contract.

Proposed `ADR-0035` selects deterministic bytes for one complete canonical
metadata document tuple:

- the fixed `VCMJ-1` document schema;
- one exact multiplicity-schema reference or `null`; and
- one complete ordered `MetadataCollection`.

Those bytes retain every entry privacy class, every recognised unknown
namespaced entry and presentation fields such as `CodedConcept.meaning` and
`MeasurementUnit.displayName`. The out-of-band multiplicity-policy snapshot is
validation context and is not record content.

Complete VCMJ bytes are consequently not a projection of Swift semantic
equality. Proposed `ADR-0031` preserves the two presentation fields for coding
but excludes them from `CodedConcept` and `MeasurementUnit` equality. Two
semantically equal collections can therefore have different complete VCMJ
bytes. Conversely, removing presentation or privacy fields before hashing
would no longer identify the complete record and could erase information that
must remain governed.

A raw `SHA256(VCMJBytes)` would also be ambiguous across uses. The same byte
sequence could otherwise be presented as a file checksum, a serialised-object
identity, a parameter digest or input to a future signature. Algorithm and
scope fields stored beside an unframed digest would describe the result but
would not bind those discriminators into the hash preimage. A versioned,
unambiguous frame is needed so projection changes cannot silently reuse an old
identity domain.

SHA-256 is available through Apple CryptoKit, has a standard 256-bit output and
has broad cross-system support. This decision needs an interoperable baseline,
not a project-written hash implementation or runtime algorithm negotiation.
Algorithm agility remains necessary, but accepting an algorithm label from an
untrusted record must never select executable code, a keyed mode, an arbitrary
output length or a downgrade.

Finally, an unkeyed digest is not authentication or de-identification. Metadata
often has low entropy. A digest can disclose equality across records and
support dictionary guessing even when the original metadata is not emitted.
Schema trust, multiplicity-policy authenticity, privacy/export authorisation,
MACs, signatures, encryption and host audit policy must stay outside this
identity result.

This proposal selects one exact complete-record projection and the minimum
logical record needed to name it. It deliberately does not select semantic
`MetadataCollection` identity, order-insensitive identity, schema-normalised
identity, image `descriptorAndSamples` identity, source/derivation identity,
signature input, keyed pseudonymisation or a generic algorithm registry. Its
Proposed status authorises documentation and isolated evidence only.

Proposed `ADR-0037` defines the downstream claim-versus-assurance boundary for
source, derivation and data identity. A structurally valid or decoded
`ContentID` from this ADR always remains a claim value. Separate generation or
verification over one pinned immutable snapshot supplies assurance; the value
never becomes cache authority by presence alone.

## Decision

If `ADR-0028` through `ADR-0036` are accepted and the public API receives the
required RFC and maintainer approval, `VoxeliaCore` will own a versioned content
projection reference and a scoped `ContentID` value. `ADR-0036` initially
registers exactly one generation and verification tuple:

| Field | Exact value |
|---|---|
| Algorithm | `sha256` |
| Scope | `serialisedObject` |
| Projection identifier | `org.voxelia.metadata-complete-record` |
| Projection version | major `1`, minor `0` |
| Payload | the exact complete accepted `VCMJ-1` bytes |
| Digest | SHA-256 of the framed payload below, exactly 32 bytes |

The result is called the **complete canonical metadata record identity**. It
must not be shortened to “metadata identity” in public API or documentation
because that phrase could be mistaken for semantic collection identity.

### Corrected logical identity record

The candidate logical surface is:

```swift
public struct ContentProjectionVersion: Sendable, Hashable {
    public let major: UInt32
    public let minor: UInt32

    public init(major: UInt32, minor: UInt32)
}

public enum ContentProjectionReferenceError: Error, Sendable, Equatable {
    case invalidIdentifier
    case identifierByteLimitExceeded
}

public struct ContentProjectionReference: Sendable, Hashable {
    public static let maximumIdentifierUTF8ByteCount: UInt64 = 255
    public static let maximumIdentifierLabelByteCount: UInt64 = 63

    public let identifier: String
    public let version: ContentProjectionVersion

    public init(
        identifier: String,
        version: ContentProjectionVersion
    ) throws
}

public enum ContentIdentityError: Error, Sendable, Equatable {
    case invalidRecord
    case unsupportedAlgorithm
    case unsupportedProjection
    case resourceLimitExceeded
    case cancelled
}

public struct ContentID: Sendable, Hashable, Codable {
    public let algorithm: DigestAlgorithm
    public let scope: ContentScope
    public let projection: ContentProjectionReference
    public var digest: ContiguousArray<UInt8> { get }
}
```

`ContentID` has no public unchecked memberwise initializer. Accepted
profile-specific construction snapshots the supplied digest into owned
`ContiguousArray<UInt8>` storage and validates the complete tuple before the
value exists. For the only tuple selected here, the digest must contain exactly
32 bytes. A 31-byte, 33-byte, truncated, padded or otherwise inferred result is
invalid.

The public accessor returns value-semantic owned bytes. A caller mutating its
original input after construction cannot mutate the stored digest. The type
does not store Foundation `Data`; adapters that receive `Data` must make the
ownership conversion explicitly.

The projection identifier uses the same bounded lowercase ASCII reverse-domain
grammar selected for metadata schema identifiers by `ADR-0035`, but it is a
distinct nominal type with a distinct authority. It has two or more labels;
each label is 1 through 63 bytes, begins and ends with a lowercase ASCII letter
or digit and otherwise contains only those characters or `-`; the complete
identifier is at most 255 bytes. There is no case folding, Unicode
normalisation, IDNA, URI processing, DNS lookup or aliasing.

Validation applies fixed precedence. The complete identifier byte count is
checked first; a value above 255 bytes throws the payload-free
`identifierByteLimitExceeded`. Each decoded label length is checked next; a
label above 63 bytes throws the same error. Only then do empty-label,
character, first/last-character and label-count checks run, with grammar failure
throwing `invalidIdentifier`. Thus 63-byte labels and a 255-byte complete valid
identifier are accepted, while 64-byte labels and 256-byte complete identifiers
fail as byte-limit errors even if a later grammar check would also fail.
Programmatic construction scans the supplied UTF-8 view incrementally, stops
before copying a 256th byte and retains at most the accepted 255-byte snapshot;
it must not first allocate an unbounded `Array(identifier.utf8)`. Raw ingress
enforces the same limit before growing its token buffer beyond 255 bytes.

The reference is descriptive, not executable and not a registry lookup. Core
supports only an explicitly compiled and reviewed set of complete
algorithm/scope/projection/version tuples. An untrusted record cannot register
a new tuple or choose a callback, plugin, dynamic library, network resolver or
arbitrary output length.

`ContentProjectionVersion` and `ContentProjectionReference` have no standalone
`Codable` contract in version one. Their stable coding exists only inside the
manually validated `ContentID` record; this avoids accidentally treating an
ordinary synthesised representation as a portable projection registry format.

`ContentProjectionVersion` is independent of `MetadataSchemaVersion`. A
projection version identifies the exact digest preimage rules; the VCMJ
document schema identifies the payload grammar. A change to framing, payload
selection or byte treatment requires a new projection version even when the
document schema remains readable. Supporting a newer minor version is never
inferred from same-major compatibility: every digest projection version is an
exact registered value.

### Algorithm boundary

Version one generation and verification for this projection use only unkeyed
SHA-256 through CryptoKit. SHA-256 produces exactly 32 digest bytes. Voxelia
does not implement SHA-256 and does not substitute a different algorithm when
CryptoKit is unavailable.

The existing declaration vocabulary is interpreted conservatively:

- `.sha256` is the only algorithm accepted for this projection;
- `.sha512` remains reserved for a separately accepted profile and evidence;
- `.blake3` remains reserved until an accepted decision fixes unkeyed versus
  keyed/derive-key mode, output length, algorithm spelling and implementation;
  and
- `.custom` is rejected for persistent and distributed identity because the
  payload-free case cannot carry the required profile identity.

A future custom-algorithm design must use a bounded, namespaced and versioned
algorithm-profile reference whose trusted registration fixes the standard,
mode, output length, implementation expectations and migration policy. That
work may require a successor algorithm-reference type. It cannot reinterpret
the existing `.custom` raw value or make an untrusted record authoritative.

Readers never infer an algorithm from a 32-byte digest. An unsupported
algorithm fails with `unsupportedAlgorithm`; it does not fall back to SHA-256,
truncate another digest or negotiate down to a locally available choice.
Algorithm migration uses two independently complete IDs during a governed
transition rather than one record whose meaning changes.

### Exact record coverage

The projection payload is byte-for-byte the complete canonical output selected
by `ADR-0035`. It includes:

- fixed `org.voxelia.metadata-document` version `1.0` document-schema fields;
- the exact multiplicity-schema reference or `null`;
- every entry in collection and repeated-occurrence order;
- exact array order and canonical recursive-object member order;
- every key namespace and name using its exact accepted UTF-8 identity;
- every value case and complete stored payload;
- every entry privacy class, including literal `hostDefined`;
- `CodedConcept.meaning` and `MeasurementUnit.displayName`, including exact
  present, absent and present-empty states selected by their accepted types;
- exact finite numeric, canonical instant and owned-binary VCMJ projections;
  and
- every preserved unknown namespaced entry whose value uses the recognised
  metadata vocabulary.

The out-of-band `MetadataMultiplicityPolicy` snapshot does not enter the
payload or frame. Two policy snapshots that both validate the same exact
document against the same claimed profile reference produce the same record
identity. The identity binds the reference written in the record; it does not
prove that the reference is authentic or that a caller supplied the correct
policy.

No privacy filtering, schema-specific aliasing, key rewriting, Unicode
normalisation, order normalisation, unit conversion, code-system resolution,
deduplication or presentation stripping occurs while computing this ID. Any of
those transformations creates different content, requires separate host
authority and provenance and, if emitted as VCMJ, receives a different
complete-record ID.

### Exact version-one digest frame

The SHA-256 preimage is one binary frame followed immediately by the payload.
Every integer is unsigned and encoded most-significant byte first. Every string
length is the number of following ASCII bytes, not a character count.

```text
18 bytes  ASCII "VOXELIA-CONTENT-ID"
1 byte    0x00
4 bytes   UInt32BE frame version = 1
4 bytes   UInt32BE algorithm identifier byte count = 6
6 bytes   ASCII "sha256"
4 bytes   UInt32BE scope identifier byte count = 16
16 bytes  ASCII "serialisedObject"
4 bytes   UInt32BE projection identifier byte count = 36
36 bytes  ASCII "org.voxelia.metadata-complete-record"
4 bytes   UInt32BE projection major version = 1
4 bytes   UInt32BE projection minor version = 0
8 bytes   UInt64BE payload byte count
N bytes   exact complete VCMJ-1 payload
```

The version-one header is exactly 109 bytes. The digest is:

```text
SHA-256(header || exact-complete-VCMJ-1-bytes)
```

The magic, frame version, all length prefixes, algorithm, scope, projection and
projection version participate in the hash. The payload length makes the
framing unambiguous and prevents one field or payload from being parsed as an
extension of another. No newline, BOM, NUL terminator, transport length,
filename, filesystem metadata, policy bytes or hash-text representation follows
the payload.

The smallest 148-byte empty VCMJ-1 document from `ADR-0035` has raw SHA-256:

```text
a27e896af6381de3cf78c5b4166851b601b6461d9e2503935b32ab4d6811ee50
```

Its proposed framed complete-record digest is deliberately different:

```text
8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432
```

These values are golden fixtures, not proof of collision resistance or of a
validated cryptographic module. The framed value was independently reproduced
with CryptoKit and Python's standard SHA-256 implementation.

The complete frame length is checked before hashing. SHA-256's theoretical
input limit requires the total frame to be no greater than `2^61 - 1` bytes;
the eventual accepted VCMJ raw/canonical-document ceiling must be vastly lower
and remains the operative resource limit. Any addition or integer conversion
overflow fails with `resourceLimitExceeded` before hash publication.

### Digest text and type-level wire

The one canonical textual representation of a SHA-256 digest component is
exactly 64 lowercase ASCII hexadecimal characters:

- digits `0` through `9` and letters `a` through `f` only;
- no `0x` prefix, uppercase, separator, whitespace or line ending;
- no truncation, padding, Base64 alias or integer-array alias; and
- no algorithm inference from the text length.

The type-level `ContentID` object has exactly these four fields in its dedicated
manual coding contract:

```json
{"algorithm":"sha256","digest":"8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432","projection":{"identifier":"org.voxelia.metadata-complete-record","version":{"major":1,"minor":0}},"scope":"serialisedObject"}
```

All fields are required. Unknown, missing, null, wrong-shaped or unsupported
values visible through the supplied decoder fail with a payload-free identity
error. Manual coding emits exactly those fields, while an arbitrary `Encoder`
may choose its own physical member order. Decoding verifies the exact
algorithm, length, lowercase hexadecimal, scope, projection identifier and
version before constructing the value.

This type-level fragment is not a standalone schema-versioned canonical
document, and a general decoder may already have collapsed duplicate members.
A future portable standalone Content-ID document must have its own fixed schema
envelope and raw duplicate/order/lexical boundary. Ordinary
`JSONDecoder`, `JSONEncoder`, synthesised `Codable`, `Data` coding or a
decode-and-reencode comparison is not the canonical raw trust boundary.

`ContentID` does not conform to `CustomStringConvertible`,
`CustomDebugStringConvertible` or `CustomReflectable`, and the hex form is not
a safe-display form. Default Swift reflection can still expose stored fields;
library and host code must not interpolate or reflect an ID into logs or
telemetry.

### Equality, verification and persistent identity

`ContentID` semantic equality and `Hashable` combine:

1. exact algorithm identity;
2. exact content scope;
3. exact projection identifier and major/minor version; and
4. every digest byte.

Swift `Hasher`, `hashValue`, dictionary bucket state and ordinary `Codable`
bytes are process or representation details and are never persisted, exchanged
or used as the content identity.

Direct verification first validates and compares the public algorithm, scope
and projection discriminators. The candidate then compares the fixed 32 digest
bytes with `timingsafe_bcmp`. Acceptance requires this symbol or an equivalently
reviewed data-independent comparator to compile on every supported Apple
destination before the API is exposed. Dictionary and set lookup do not gain a
timing-safety claim. Tests based on elapsed wall-clock time are not evidence of
comparison safety.

Verification of a well-formed expected ID returns a match/non-match result only
after the complete candidate digest has been calculated. A mismatch is not a
parser, source or cryptographic-system failure and carries neither digest.
Malformed or unsupported expected records fail before consuming the payload.

### Streaming, cancellation and publication

The digest operation reuses the exact accepted canonical VCMJ traversal. It
must not use `JSONEncoder`, an independently evolving metadata walk, Swift
reflection, semantic `Hashable`, a dictionary traversal or ordinary `Codable`
bytes as its payload oracle.

Programmatic unique/configured emission first performs the same complete
validation and checked byte-count preflight as canonical emission. The 109-byte
header is then supplied to CryptoKit followed by bounded payload slices. The
implementation does not allocate `header + payload` as one contiguous buffer.
It uses at most 4,096 payload work units between required cancellation checks,
matching the candidate VCMJ cadence, and a host may select a smaller bounded
chunk.

Because payload length precedes payload bytes, a raw input stream may be hashed
in the same pass only when an authoritative checked length is known before the
header and the parser later verifies that exact count. Otherwise the accepted
implementation must use an already approved replayable bounded source or the
validated canonical emitter; it cannot hash payload first and pretend to
prepend the header later. This ADR authorises no temporary-file or disk-spool
path. Any future spool needs its own owner, explicit opt-in, byte/disk limit,
file-protection, permission, backup-exclusion, cleanup and residual-data
decision plus fault evidence. The concrete source/sink API remains an
acceptance-evidence decision.

The operation checks cancellation:

- before significant allocation and before hashing starts;
- at every input/output chunk boundary;
- at the fixed bounded-work cadence in validation, counting, emission and
  CryptoKit update loops;
- before finalisation; and
- after finalisation immediately before the success linearisation point.

Cancellation, invalid input, source failure, allocation failure, length
mismatch or any other error discards the hasher and tentative result. It
publishes no `ContentID`, cache entry, provenance edge, document/result pair,
temporary external name, log or telemetry field. Successful document and ID
publication is atomic from the caller's perspective. Cancellation after that
linearisation point applies to later work and does not retroactively invalidate
the completed ID.

The fixed payload-free identity errors mean:

| Error | Meaning |
|---|---|
| `invalidRecord` | Malformed identity fields, digest text/length or invalid already-bounded input. |
| `unsupportedAlgorithm` | The algorithm is syntactically known or supplied but not accepted for this projection. |
| `unsupportedProjection` | The scope/projection/version tuple is not an accepted compiled profile. |
| `resourceLimitExceeded` | A caller/hard byte ceiling, checked conversion/addition or SHA-256 frame limit failed. |
| `cancelled` | Cancellation was observed before successful publication. |

Errors retain no algorithm token, scope, projection identifier/version, digest,
payload byte/count/offset, schema reference, metadata key/value/privacy class,
policy content, source path or underlying error. Identity-owned code emits no
logs or telemetry. Adapter/source errors remain typed at their owning boundary
and must be sanitised before crossing an untrusted disclosure boundary.

### Semantic metadata identity remains separate

This complete-record ID intentionally changes when only
`CodedConcept.meaning` or `MeasurementUnit.displayName` changes, even though
the corresponding proposed Swift values compare equal. It also changes with
entry/repeat/array order, privacy class, multiplicity-schema reference and every
unknown retained entry. That behaviour is required for exact record identity
and is not a defect.

No `MetadataCollection.contentID` convenience is selected. Such a name would
hide whether presentation fields and external schema context participate. A
future semantic collection identity needs a separately named versioned
projection and must independently decide:

- whether its scope requires a new `ContentScope` case;
- exact agreement with every leaf and aggregate semantic-equality rule;
- treatment of presentation fields, document and multiplicity-schema
  references;
- order, repeated occurrences, unknown namespaces and exact UTF-8 identity;
- privacy classes and the absence of a portable privacy lattice;
- schema-authenticated normalisation, if any; and
- migration when semantic equality changes.

That future projection must not reuse
`org.voxelia.metadata-complete-record` or this digest. A caller that needs both
exact record bytes and a later semantic identity stores both explicitly rather
than substituting one for the other.

### Privacy, schema trust, export and signatures

The ID is sensitive-derived material by default. It can reveal equality across
records, tenants or time and can support guesses against low-entropy metadata.
Lowercase hexadecimal is an encoding, not redaction or de-identification.

Core assigns no aggregate `MetadataPrivacyClass` to the digest because the
taxonomy has no governed aggregation rule. Hosts must not log, place in
telemetry, expose in UI, use in URLs or filenames, share across tenants,
deduplicate across privacy domains or export the ID without explicit trusted
policy. A privacy-filtered export is a new document with a new complete-record
ID and appropriate transformation provenance.

The digest proves none of the following:

- authorship, authenticity, freshness or trusted origin;
- authenticity of the document or multiplicity-schema reference;
- correctness of the out-of-band multiplicity-policy snapshot;
- permission to read, correlate, cache, disclose, log or export metadata;
- absence of patient-identifying or host-sensitive information;
- collision impossibility or malicious-substitution resistance equivalent to
  a signature;
- encryption, a MAC, a keyed pseudonym or a signature; or
- completion of image/data/provenance identity requirements.

A future signature signs a separately domain-separated canonical statement
that binds algorithm, scope, projection and digest. It does not sign naked
digest bytes by convention. HMAC or keyed pseudonymisation requires a distinct
type plus key-management and threat-model decisions; it is never represented
as `DigestAlgorithm.sha256`.

## Alternatives considered

### Hash raw VCMJ-1 bytes directly

Rejected. It does not bind the identity purpose, scope or projection into the
preimage and can be confused with a file checksum or another SHA-256 use. The
raw digest remains a useful negative-control fixture only.

### Call the result semantic metadata identity

Rejected. Complete VCMJ bytes retain presentation fields excluded from
proposed Swift equality and include document/profile context not stored in a
bare collection. The result is exact complete-record identity.

### Remove presentation fields before hashing

Rejected for this projection. Doing so would not identify the bytes that a
caller stores or transmits. A semantic projection needs separate naming,
versioning, scope and review.

### Omit privacy classes or unknown entries

Rejected. The digest would collapse records with different handling
declarations or silently discard format-specific content that Core is required
to preserve. Filtering is a separate authorised transformation.

### Hash the multiplicity-policy snapshot

Rejected. `ADR-0033` and `ADR-0035` make the snapshot caller-supplied validation
context, not portable record content or authenticated schema identity. The
claimed schema reference remains in the complete VCMJ payload.

### Store only algorithm and digest

Rejected. It violates the controlled scope requirement and cannot identify the
canonical projection needed to reproduce or verify the digest.

### Store Foundation Data or use synthesised Codable

Rejected. `Data` versus contiguous-byte coding already produces incompatible
default JSON, and neither default is the selected canonical hex form. Owned
contiguous bytes plus manual validation makes the storage and wire decisions
explicit.

### Infer the algorithm or scope from digest length

Rejected. Multiple algorithms can produce the same output length. Length is an
invariant, not an identifier, and inference prevents safe algorithm migration.

### Accept DigestAlgorithm.custom as-is

Rejected. A payload-free category does not name a custom algorithm, mode,
version or output length and cannot satisfy the controlled approval rule.

### Select SHA-512 or BLAKE3 for version one

Deferred. Both may be valid future profiles, but SHA-256 supplies the simplest
fixed cross-system and Apple-platform baseline. BLAKE3 additionally needs an
exact mode/output decision and an approved dependency or implementation path.
Algorithm agility is provided by explicit future profiles, not multiple
untested choices in the first profile.

### Use UUIDs, Swift Hashable, ordinary Codable bytes or filesystem checksums

Rejected. UUIDs do not derive from content; Swift hashes are process-randomised;
ordinary Codable is not a canonical raw-byte contract; and a filesystem
checksum has a different scope and framing.

### Treat the digest as de-identified or safe to log

Rejected. Equality and dictionary attacks remain possible, and the project has
no approved aggregate privacy classification for a digest.

### Add signatures or MACs to this record

Rejected. Authentication and keyed identity have different keys, trust,
rotation, verification, error and audit requirements. Conflating them with a
content digest would overstate the guarantee.

## Consequences

- Voxelia gains one reproducible, domain-separated exact metadata-record
  identity proposal with explicit algorithm, scope and projection.
- The controlled `ContentID` shape conflicts receive one coherent correction:
  typed algorithm vocabulary, owned contiguous bytes, required scope, required
  projection and strict lowercase-hex type-level coding.
- Complete VCMJ presentation, privacy, schema-reference, ordering and unknown-
  entry information remains bound to the record ID.
- Policy contents, schema authenticity and export authority remain outside the
  record and digest.
- Semantically equal collections can intentionally have different record IDs;
  callers must not use this ID as a substitute for semantic equality.
- Algorithm negotiation, custom algorithms, semantic metadata identity and
  image/data identity remain separate future decisions.
- Digest computation adds one linear canonical pass or an approved replay of a
  validated stream. It cannot be implemented by persisting `hashValue` or
  hashing whatever bytes an arbitrary encoder happens to emit.
- Proposed status and upstream dependencies mean no product source is
  authorised by this increment.

## Affected modules

`VoxeliaCore` owns the future projection reference, scoped ID record, profile
registry, complete-record digest orchestration and payload-free identity errors.
It may import Apple CryptoKit under the accepted Apple-only architecture.

The accepted canonical metadata codec supplies the exact VCMJ payload bytes and
checked length. `VoxeliaStorage` may later hash storage-owned streams for other
accepted scopes while returning Core-owned IDs; it does not redefine the
record. Format adapters preserve unknown metadata and supply trusted
multiplicity context without entering the hash frame.

Hosts own schema resolution/authenticity, privacy and export policy,
cross-tenant cache boundaries, audit decisions, disclosure of IDs and any
signature/key management. No module may infer those authorities from a digest.

## Compatibility impact

Acceptance requires controlled-document correction because both current
`ContentID` sketches are incomplete. The corrected record adds `scope` and
`projection`, selects owned contiguous bytes and replaces representation-
dependent digest coding with strict lowercase hex. This is a public data-model
change and therefore requires the project RFC process and maintainer approval
before source migration.

There is no live `ContentID` product source to migrate today. The two existing
taxonomy enums remain unchanged by this Proposed documentation increment.
Existing `.sha512`, `.blake3` and `.custom` cases stay declaration vocabulary;
they do not become accepted complete-record profiles by presence alone.

Once a projection is accepted, its frame and golden digest are immutable. A
framing, identifier, field-selection or payload-rule change creates a new
projection version and a new ID. Readers do not alias old and new IDs. During a
governed algorithm or projection migration, records may carry two complete IDs
with explicit profiles; one field never changes meaning in place.

## Security impact

Domain separation and explicit length framing reduce cross-purpose and parsing
ambiguity. A closed compiled profile set prevents untrusted algorithm or code
selection. Strict digest lengths and hex reject truncation and textual aliases.
Owned bytes prevent caller mutation after construction. Direct fixed-length
comparison uses the platform timing-safe byte comparator after public
discriminators match.

These controls do not make an unkeyed digest authentic, secret or collision-
free. SHA-256 collisions are computationally difficult under the assumed
security model, not impossible by type contract. Mutation fixtures establish
input coverage and mismatch detection, not collision-resistance proof.

The digest is an equality/linkage oracle and remains sensitive-derived by
default. Identity code logs nothing and exposes no safe description. Hosts
must govern cache partitioning, disclosure and export. Untrusted source errors
and parser failures remain redacted at their owning boundaries.

Length arithmetic, projection identifiers and payload counts are validated
before any unbounded or payload/hash allocation. Projection validation may use
only its fixed 255-byte bounded buffer and stops before a 256th-byte copy.
Cancellation and every failure path discard the tentative digest and leave
caches, provenance and returned documents unchanged.

## Performance and memory impact

SHA-256 computation is O(n) in the exact canonical record byte count. The
incremental hasher requires bounded state, a fixed 109-byte header and bounded
update slices. Digest storage is 32 bytes; canonical text is 64 bytes before
the containing JSON syntax.

Programmatic computation may require a validation/counting pass followed by
canonical emission and hashing. Raw streaming without a known checked length
may require an already approved replayable bounded source or validated
re-emission; this ADR selects no disk spool. Those costs are explicit and must
be measured against the accepted VCMJ codec; silently buffering an unlimited
document is not allowed.

The fixed 4,096-work-unit cancellation cadence is an upper bound, not a target
chunk size. Production benchmarks must measure throughput, latency,
cancellation latency, allocation behaviour and energy across supported Apple
capability classes. This proposal makes no performance claim from the small
isolated probe.

## Validation impact

Before acceptance or source implementation, focused evidence must cover:

- NIST SHA-256 known-answer vectors, including short and multi-block inputs;
- independent exact-frame and digest goldens for empty and nonempty VCMJ-1
  documents;
- every header/payload chunk split for bounded fixtures and random schedules
  for larger fixtures;
- raw SHA-256 versus framed digest inequality;
- algorithm, scope, projection identifier/version and payload-length domain
  mutations;
- projection-identifier 63/64-byte label and 255/256-byte total boundaries,
  grammar failures, byte-limit-before-grammar precedence and early rejection
  of very overlong programmatic input without an unbounded UTF-8 copy;
- 31/32/33-byte digest and 63/64/65-character text boundaries;
- uppercase, prefix, separator, whitespace and non-hex rejection;
- caller-buffer mutation after owned snapshot;
- first, middle and last digest-byte mismatch through the timing-safe direct
  comparator;
- order, repeated occurrence, privacy class, presentation field,
  multiplicity-schema reference, unknown-entry and exact-UTF-8 mutations;
- two policy snapshots under the same record reference producing one ID while
  proving no policy authenticity;
- checked frame/count maximum, one-over and arithmetic overflow;
- declared payload lengths shorter and longer than observed input, rejected
  before finalisation/publication;
- cancellation before work, during validation/counting/emission/hash updates,
  before finalisation and immediately before publication;
- source, allocation and parser fault injection with no partial ID, cache,
  provenance, log or document publication;
- manual coding round-trips and malformed/unsupported tuple rejection;
- payload-free error descriptions and reflection behaviour;
- strict Swift concurrency and format lint; and
- compilation and deterministic results on every supported Apple destination.

Cross-platform vectors verify reproducibility; they do not establish formal
FIPS-module validation. Timing tests based on wall-clock measurements do not
prove constant-time behaviour. Mutation tests do not prove cryptographic
collision resistance.

The isolated Swift probe referenced below covers only the SHA-256 `abc` vector,
empty-record raw/framed goldens, owned-byte and strict-hex behaviour, frame
domain mutations, selected record mutations, policy exclusion, bounded chunk
invariance, checked arithmetic, two cancellation points, platform timing-safe
comparison and payload-free errors. It is not a VCMJ parser/emitter, complete
canonical projection, production API, cryptographic proof, device matrix,
allocation-failure test or implementation authorisation.

No complete Swift package suite is required for this documentation-only
proposal. The focused probe plus document, ADR-register, manifest and release-
integrity checks cover the changed surface. Product-target tests become
mandatory only when an accepted implementation changes source.

## Migration

Acceptance and implementation proceed in this order:

1. review and accept `ADR-0028` through `ADR-0036`, including closure of
   `ADR-0035`'s raw byte ceiling, production floating codec, complete parser,
   cancellation/device and allocation-recovery evidence;
2. complete the public API/data-model RFC and maintainer approval;
3. correct the controlled MTA and CDMS `ContentID` declarations to include
   algorithm, scope, projection and owned digest bytes, select strict digest
   text and clarify that source/derivation identity may precede a full digest;
4. retain bare `.custom` as unusable declaration vocabulary until a separately
   approved algorithm-profile design exists, and do not silently assign a
   BLAKE3 mode/output;
5. implement the bounded projection reference, private validated `ContentID`
   construction, manual type-level coding and timing-safe direct equality in
   `VoxeliaCore` with focused tests;
6. implement the CryptoKit SHA-256 framed helper and cancellation/publication
   boundary with independent golden fixtures;
7. integrate only the accepted VCMJ codec's exact counting/emission path and
   add complete mutation, chunking, fault and supported-destination evidence;
8. integrate the complete-record ID into storage, cache or provenance only
   through separately accepted contracts that preserve privacy and atomicity;
   and
9. leave semantic collection, image/data, source/derivation, signature and
   keyed-identity work under their own decisions.

Until all prerequisite decisions and approvals are accepted, no `ContentID`,
CryptoKit digest helper, verifier, cache key, provenance record, recursive
metadata type, canonical parser or canonical emitter source is authorised.

## Supersession

This proposal does not supersede an accepted ADR. If accepted, it resolves only
the complete canonical metadata record's persistent identity and supplies the
candidate correction for the controlled `ContentID` record. It does not
supersede the semantic identity of metadata values/collections, VCMJ grammar,
schema policy, source/derivation identity, image identity, storage checksum,
privacy/export policy, provenance, authentication, signature or encryption
decisions.

## References

- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [ADR-0031 - Bounded recursive metadata value boundary](ADR-0031-bounded-recursive-metadata-value-boundary.md)
- [ADR-0032 - Required metadata-entry privacy attachment](ADR-0032-required-metadata-entry-privacy-attachment.md)
- [ADR-0033 - Ordered metadata collection and explicit multiplicity policy](ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md)
- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0036 complete-record identity probe](../../progress/evidence/ADR-0036-metadata-complete-record-identity-probe.swift)
- [NIST FIPS 180-4 - Secure Hash Standard](https://doi.org/10.6028/NIST.FIPS.180-4)
- [NIST Cryptographic Algorithm Validation Program - Secure Hashing](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/secure-hashing)
- [Apple Developer Documentation - SHA256](https://developer.apple.com/documentation/cryptokit/sha256)
- [Apple Developer Documentation - HashFunction](https://developer.apple.com/documentation/cryptokit/hashfunction)
- [RFC 6920 - Naming Things with Hashes](https://www.rfc-editor.org/rfc/rfc6920)
- [RFC 7696 - Guidelines for Cryptographic Algorithm Agility and Selecting Mandatory-to-Implement Algorithms](https://www.rfc-editor.org/rfc/rfc7696)
- [RFC 9380 - Hashing to Elliptic Curves](https://www.rfc-editor.org/rfc/rfc9380)
- [Official BLAKE3 specification and implementation](https://github.com/BLAKE3-team/BLAKE3)
