---
document_id: "ADR-0039"
title: "Closed storage capability and descriptor admission boundary"
status: "Proposed"
date: "2026-08-03"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-003"
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-GOV-009"
  - "VOX-GOV-010"
  - "VOX-PLT-008"
  - "VOX-PLT-009"
  - "VOX-REP-010"
  - "VOX-ARC-001"
  - "VOX-ARC-003"
  - "VOX-ARC-004"
  - "VOX-ARC-005"
  - "VOX-ARC-011"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-005"
  - "VOX-API-007"
  - "VOX-API-010"
  - "VOX-API-011"
  - "VOX-DAT-004"
  - "VOX-DAT-010"
  - "VOX-DAT-011"
  - "VOX-DAT-013"
  - "VOX-DAT-014"
  - "VOX-DAT-015"
  - "VOX-RGN-001"
  - "VOX-RGN-002"
  - "VOX-RGN-003"
  - "VOX-RGN-004"
  - "VOX-RGN-006"
  - "VOX-STO-001"
  - "VOX-STO-002"
  - "VOX-STO-003"
  - "VOX-STO-004"
  - "VOX-STO-005"
  - "VOX-STO-006"
  - "VOX-STO-007"
  - "VOX-STO-008"
  - "VOX-STO-009"
  - "VOX-STO-010"
  - "VOX-STO-011"
  - "VOX-STO-012"
  - "VOX-BRK-002"
  - "VOX-BRK-005"
  - "VOX-EXE-007"
  - "VOX-EXE-009"
  - "VOX-CON-001"
  - "VOX-CON-003"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-CON-009"
  - "VOX-CON-010"
  - "VOX-ERR-001"
  - "VOX-ERR-002"
  - "VOX-ERR-003"
  - "VOX-ERR-007"
  - "VOX-SEC-001"
  - "VOX-SEC-002"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
  - "VOX-VAL-011"
  - "VOX-VAL-016"
  - "VOX-PER-007"
  - "VOX-PER-008"
  - "VOX-VS1-017"
  - "VOX-VS1-018"
  - "VOX-VS1-020"
---

# ADR-0039 - Closed storage capability and descriptor admission boundary

## Context

Voxelia requires an M1 storage contract, but its controlled documents do not
currently authorise one coherent declaration.

The Master Technical Architecture assigns storage protocols and type erasure
to `VoxeliaCore` and concrete providers to `VoxeliaStorage`. The Core Data
Model Specification instead assigns `StorageDescriptor`,
`StorageCapabilities`, `ImageStorage`, region reading and `AnyImageStorage` to
`VoxeliaStorage`. Core-owned `ImageData` embeds `AnyImageStorage`, while the
Repository and Package Scaffold Specification and live package graph fix:

```text
VoxeliaStorage -> VoxeliaCore -> VoxeliaSpatial
```

Core cannot import a Storage-owned erasure or descriptor without the prohibited
reverse edge. `VOX-ARC-003` and `VOX-ARC-004` support the MTA split: Core owns
canonical descriptors and data handles; Storage owns concrete implementations.

The displayed capability sets also disagree:

| State | Names |
|---|---|
| Shared | `randomRead`, `sequentialRead`, `directByteAccess`, `memoryMapped`, `tiled`, `bricked`, `compressed`, `multiresolution`, `remote` |
| MTA only | `writable` |
| CDMS only | `writableBuilder`, `prefetch`, `contentDigest` |

MTA supplies neither a raw type nor stable coding. CDMS adds `UInt64`,
`Hashable` and `Codable`, but neither assigns bits, defines implications,
reserves unknown bits or specifies a wire. Synthesised coding would freeze an
accident. Masking unknown bits could discard a future safety constraint and
continue under weaker authority.

The names also mix unrelated facts:

- region readability is a callable operation;
- sequential reading needs a cursor/session/order contract;
- mapping exposes representation bytes, not necessarily logical samples;
- tiled, bricked, compressed and multiresolution describe representation facts
  plus separate typed access;
- remote origin is locality, and absence of a bit cannot mean local;
- published storage is immutable, while editing uses an unpublished builder;
- digest API availability is not a digest claim or verification; and
- residency changes by device and generation, so it cannot be immutable state.

The displayed `StorageDescriptor` is an optional-field bag. It has no base
offset, component/plane stride, exact initialized representation length,
packing description, encoded-versus-decoded length distinction, non-overlap
proof, strict byte-order rule or declared `StorageIntegrityDescriptor`.
`DestinationDescriptor` and `ImageReadSource` are referenced but undeclared.

The descriptor exposes a logical-versus-physical identity conflict. CDMS
requires equivalent logical samples in different layouts to retain the same
logical content relation and excludes physical padding from canonical content
identity. Yet the displayed `ImageDescriptor` includes
`ScalarFormat.byteOrder` and physical `ComponentDescriptor.layout`. No
accepted projection separates logical values from representation details.

The builder sketch is internally contradictory. `commit` accepts provenance
and metadata, returns `ImageData`, and adjacent prose says Storage creates
provenance. MTA assigns provenance assembly and result publication to
Execution. Proposed `ADR-0038` records the safe direction: Storage freezes an
unpublished snapshot and may report representation integrity; Execution or an
explicit host/import coordinator publishes storage, identity, metadata and
provenance together.

Unsafe buffer closures and erased boxes also introduce lifetime and
`Sendable` risk. CDMS deliberately leaves the exact erasure and destination
design open. `VOX-CON-010` requires independent review of every
`@unchecked Sendable` use.

This proposal closes conceptual ownership, vocabulary, stable bits, descriptor
invariants, evidence and publication rules. It does not authorise product
source while this ADR, the public RFC, controlled corrections and dependent
contracts remain unaccepted or undefined.

## Decision

If accepted, Voxelia will preserve the live graph and assign:

| Responsibility | Owner | Rule |
|---|---|---|
| Backend-neutral logical/representation, operation, snapshot, read-result, lease, error and safe-erasure contracts | `VoxeliaCore` | Never imports Storage, Execution or Metal; owns erasure/witness boxes. |
| Contract admission, read authority and private result-target adoption | `VoxeliaCore` | Owns exact writable logical capacity, byte-budget reservation/token, stamping and commit. |
| Concrete providers, builders, mappings, source/mapping allocation, I/O, codecs, caches and resource lifetime | `VoxeliaStorage` | Implements Core witnesses; never controls Core's private result target. |
| Atomic `ImageData` publication | `VoxeliaExecution` or explicit host/import coordinator | One generation-pinned linearisation point. |
| Per-device residency | `VoxeliaMetal` with Execution coordination | Dynamic evidence, never a storage bit. |
| Locators, credentials, transport, privacy, authentication and storage policy | Host | No implied reusable-toolkit authority. |

`StorageKind` and `StoragePersistence` currently remain declaration-only
vocabulary in Storage. If accepted, backend-neutral leaves will move to Core
or be replaced by orthogonal Core characteristics through an explicit pre-1.0
migration. Core will not import Storage or add duplicate lookalike types.

### Contract layers

The storage contract is composite:

1. an exact logical sample-layout binding remains independent of storage;
2. a tagged representation descriptor states physical addressing or opacity,
   organization, locality/backing, persistence, length and alignment claims;
3. one Core-admitted nonforgeable provider-lineage authority plus the
   provider-supplied retained callable witness establishes each available
   operation for one exact logical binding, representation descriptor, owner,
   snapshot and generation;
4. an admitted optional-operation set mirrors exactly those retained
   witnesses;
5. runtime results establish complete reads, leases, freezes, checksums or
   residency observations; and
6. external evidence may separately establish purpose-specific assurance.

Under proposed `ADR-0041`, one Core admission of one provider lineage into one
budget domain mints a nonforgeable authority. Every handle, re-erasure and
generation derived from that admission shares it; global cross-admission
uniqueness is not claimed. The authority is composed with the provider-supplied
exact logical binding, representation descriptor, retained owner, snapshot,
generation and callable witness. Neither caller nor provider can inject or
replace it. Equal value fields from another admission do not establish the same
binding. It is in-process runtime authority only, not canonical wire, persistent
identity or logical/representation identity. This refinement does not accept
either proposal.

A capability is a claim, not evidence. It does not prove a read completed,
bytes match an identity, a file stayed unchanged, a codec can satisfy one
region, a digest exists or was verified, content is resident, a source is
reachable or authorised, or an implementation is diagnostic-ready.

The minimal base contract exposes immutable snapshot identity plus the exact
logical and representation descriptors. Region reading is a separate witness.
The initial M1 storage-read profile requires a complete, bounded, history-
independent logical region-read witness. Its presence, not `randomRead`,
establishes that behavior.

A genuine sequential source requires an actor-isolated session defining
canonical order, cursor ownership, restart, retry, cancellation and concurrent
consumers. It is deferred with callback/remote work and cannot masquerade as
the M1 region-readable profile through partial or order-dependent results.

Type erasure exposes only exact retained witnesses. Callers cannot mint them by
supplying identifiers or requested bits. A bit without a witness, a witness
without its admitted operation, a different Core admission even when its
logical/representation/owner/snapshot/generation values are equal, any other
binding substitution or fallback to different logical content is a typed
failure.

### Optional-operation registry

The public raw `OptionSet` sketches are rejected as the invariant-bearing
shape because public `init(rawValue:)` admits unknown combinations. The
logical target is a closed set of `StorageOptionalOperation` cases. Raw bits
exist only in the exact wire adapter and validated internal admission.

| Bit | Exact operation | Meaning |
|---:|---|---|
| 0 | `scopedContiguousByteAccess` | Request a synchronous read-only owner-retaining `Data` scope bound to the exact authority, logical binding, representation, owner, snapshot, generation, layout, length and alignment; no bare view escapes. |
| 1 | `mappedRepresentationAccess` | Request a scoped exact representation mapping bound to authority, logical binding, representation, owner, snapshot, generation, file identity, offset, length, page/alignment and external-change policy, with a strong mapping owner for the complete synchronous borrowed-`Data` scope. |
| 2 | `builderAcquisition` | Reserve a candidate category for a separate unpublished transaction; no witness/source is admitted until a builder/freeze contract is accepted. |
| 3 | `regionEnumeration` | Enumerate supported logical regions through a typed bounded API. |
| 4 | `nativeTileAccess` | Use a typed tile API with a matching descriptor. |
| 5 | `nativeBrickAccess` | Use a typed brick API with a matching descriptor. |
| 6 | `compressedRepresentationAccess` | Access a typed compressed representation; no decode property is inferred. |
| 7 | `resolutionLevelAccess` | Use validated level descriptors that preserve spatial correspondence. |
| 8 | `prefetchHints` | Submit bounded cancellable hints with no completion or residency guarantee. |
| 9 | `scopedDigestAccess` | Request a scoped digest with projection, scope, completeness and verification state. |

The exact known mask is `0x00000000000003ff`. Bits 10 through 63 are reserved
and zero in version one. Bits are never reordered, aliased or reused. Activating
a reserved bit requires an accepted change and new wire schema version.

The displayed names are corrected as follows:

- `randomRead` becomes the explicit region-read witness;
- `sequentialRead` is deferred to the separate session;
- `directByteAccess` becomes `scopedContiguousByteAccess`;
- `memoryMapped` becomes `mappedRepresentationAccess`;
- `writable` and `writableBuilder` become `builderAcquisition`;
- `tiled`, `bricked`, `compressed` and `multiresolution` remain typed
  representation facts while their registry cases denote access;
- `remote` becomes a required typed locality/origin characteristic; and
- `contentDigest` becomes `scopedDigestAccess`.

No operation implies another. A mapped compressed object need not expose
decoded bytes. Direct decoded bytes do not imply mapping, locality, writability,
verification or residency. Native tile/brick access does not imply cheap
arbitrary regions. Compressed access does not imply losslessness, ROI or
progressive decode, codec availability or Metal sampleability. Prefetch is
only a hint.

### Exact wire and unknown data

The optional-operation wire is a dedicated custom envelope, not synthesised
`Codable` and not a JSON number:

```json
{"schemaVersion":1,"bits":"0000000000000000"}
```

Operational version-one ingress and egress require:

- exactly the shown keys, order and punctuation, with no whitespace or extra
  member;
- `schemaVersion` exactly integer `1`;
- `bits` exactly sixteen lowercase hexadecimal characters without a prefix;
- no bit outside `0x00000000000003ff`;
- typed failure for malformed text, future version or reserved bit; and
- no masking, subset interpretation or default substitution.

Parsing checks fixed limits incrementally before collecting the whole input.
An older operational consumer rejects future versions. A forwarding service
uses a separate bounded opaque envelope, verifies that it is genuinely a
future-version envelope, retains its original raw UTF-8 bytes exactly and may
not query or act on it.

Paths, URLs, source IDs and digests are sensitive. Default errors,
descriptions, reflection, logs and telemetry expose only bounded categories.

### Logical binding and representation descriptor

The target descriptor is tagged, not an optional-field bag:

```text
logical binding
representation tag and exact representation fields
organization
origin/locality and backing class
persistence
bounded resolution-level characteristic
exact initialized representation byte length, when known
alignment claim, when applicable
optional representation-integrity claim
```

The logical binding contains shape, exact decoded scalar type, component count
and logical component ordinals. Source valid-bit interpretation and physical
component arrangement belong to source/representation decoding under proposed
`ADR-0040`; neither enters the decoded logical sample-layout binding. The
binding also excludes paths, storage objects, strides, allocation padding,
compressed headers, tile order and device state.

Before aggregate source, the model must move physical byte order/component
arrangement out of logical identity or define an equally exact normalized
projection. Ordinary `ImageDescriptor` coding bytes are not canonical logical
content bytes until that correction is accepted.

Proposed `ADR-0040` supplies that correction: it separates exact decoded
scalar/component order from source bit interpretation and physical layout,
defines a most-significant-byte-first logical sample sequence, and keeps the
complete descriptor-and-samples identity blocked on the canonical full
descriptor and semantic-role/pixel-padding projections.

Initial representation tags are:

- **decoded strided**: base offset, one positive byte stride per logical axis,
  positive component stride, scalar container width, explicit byte order,
  component arrangement, exact initialized length and optional alignment; and
- **opaque**: typed compressed or provider-defined representation with an
  optional exact initialized length.

`byteLength` is split into:

- checked full logical sample byte count;
- required addressed decoded span; and
- exact initialized representation byte length.

Full logical representability, representation length, one read and one
authority's active-target-plus-retained-result-backing budget use independent
policy limits. Independent deep copies, provider scratch allocation and other
authority domains require separate aggregate host/Execution policy. A large
remote/tiled logical dataset is not rejected merely because one allocation
cannot contain it.

An absent opaque length means unknown and cannot plan allocation, mapping,
direct leasing or full-representation integrity. Decoded strided
representations require a known length. Alignment is meaningful only for an
addressable representation and is capped by a platform/host policy.

Packed storage is not inferred from `validBitCount`. The first profile rejects
packed direct layouts. A future tagged packing descriptor must define container
width, bit offset/order, signed interpretation, row/plane packing and padding.

### Shape, layout and platform invariants

Construction and untrusted decoding enforce limits before allocation:

- non-zero bounded rank, positive bounded extents and supported component/scalar
  counts;
- checked products, sums, offsets, upper bounds and byte counts;
- exactly one positive axis stride per rank and an explicit base offset;
- interleaved component stride equal to scalar width;
- planar component-plane stride at least one checked plane span;
- proved non-overlapping injective axis/component addressing;
- required addressed span no greater than initialized length and resource cap;
- positive power-of-two capped alignment compatible with base offset and
  concrete lease evidence;
- multi-byte `.native` only for process-local owned decoded memory;
- persistent, external and mapped representations use explicit endian order;
- opaque/storage-defined layouts do not claim generic decoded-stride access;
  and
- bounded resolution counts, with each resolution-access witness retaining
  matching validated per-level shape/layout metadata.

The probe uses a conservative sufficient non-overlap proof: sort active
dimensions by stride, start with scalar width, require each next stride at
least the accumulated span, then add `(count - 1) * stride` with checked
arithmetic. A later broader layout needs an equally bounded proof.

The probe uses `UInt64` only to stress unsigned arithmetic. Product Core shape,
region, offset and stride values remain the controlled `Int` model. Raw
unsigned ingress must be range-checked against `Int.max` and host limits before
lossless conversion; this fixture does not authorise a `UInt64` Core API.

Organization, encoding, locality, persistence and resolution are orthogonal.
A remote compressed multiresolution brick store with a local mapped cache is a
valid topology. One descriptor binds one exact representation snapshot;
multiple representations use separate descriptors/generations rather than one
mixed `kind`.

The evidence probe therefore represents origin/locality separately from the
backing/provider mechanism. A location is not an allocation strategy: remote
origin may coexist with an owned or mapped local cache, and callback is an
access mechanism rather than a place. Exact locator, callback and transport
contracts remain host/M9 work.

### Complete region reads and owned result publication

Every M1 region-readable witness is admitted before provider access against:

- the exact Core authority, logical binding, representation descriptor, owner,
  snapshot, generation and retained witness;
- explicit freshness mode and, for `require current`, a valid permit from that
  same Core authority;
- region rank, checked non-empty containment and expected logical value/byte
  counts;
- the first decoded packed-interleaved result profile with base offset zero,
  exact scalar/component order and exact checked length; and
- exact request-count and active-plus-retained-result byte-budget reservation.

The result profile rejects empty regions before reservation. Its bytes are not
automatically the canonical logical-identity byte stream.

Invalid request/result profile, absent witness, invalid/absent current permit
and resource/policy-limit rejection remain unstarted: they create no seal or
pending slot and invoke neither allocator nor provider.

After the pending reservation is recorded, a safe Core allocator or separately
admitted allocation service attempts one private backing with exact writable
logical capacity outside the gate and co-locates the idempotent live-byte token
with that backing. Recoverable allocation failure invokes no provider,
terminalises only that transaction and retires its reservation exactly once
after any partial allocation state is destroyed. On success, the provider
receives only a weak/non-owning monotonic bounded-fill capability and returns
only an outcome through the exact retained witness. It never receives the
request seal, authoritative binding, backing object, budget token or commit
capability.

The coordinator closes the fill, derives exact count/overrun and alone stamps
the prepared record. Fill must be contiguous from the current cursor; overlap,
gap, out-of-order, concurrent out-of-order, after-close, short or overrun fill
cannot commit. The same Core gate is the sole local linearisation point for
cancellation, current-required invalidation, preparation and commit. The first
terminal event wins. A non-commit read returns only after provider drain and
private-owner retirement; its reservation remains charged until then. Gate
state retains only bounded records/tombstones, never the private/result buffer,
and invokes no provider, allocator, callback or destructor while synchronized.

Success releases the request-count reservation, transfers the co-located exact
backing and independent byte-budget token into one complete immutable result,
and emits only a coordinator-authenticated non-authoritative source stamp. The
stamp is not a binding or witness and does not establish persistent/logical
identity, origin/provenance, `ImageData` publication or current-generation
authority. Another admission with equal labels cannot substitute bytes, and old
bytes cannot be retagged or replayed. A bound-snapshot read may finish for its
retained historical snapshot; a `require current` read must still hold the exact
non-caller-mintable current permit at commit.

A shared result alias must co-retain the same result-backing owner and byte-
budget token; otherwise it is a proved independent copy charged to caller
ownership.
The source-gated lease candidate synchronously lends an owning immutable
`Foundation.Data`, from which the caller derives `Data.span` or `Data.bytes` at
the use site. It returns no bare span, pointer or unsafe buffer. An arbitrary
generic closure result remains blocked until shared-backing escape accounting
is proved.

Every mapped scope is admitted from the exact handle's authority, logical
binding, representation descriptor, owner, snapshot and generation and also
binds exact file identity, mapped offset/length, page/alignment constraints,
external-change policy and a strong mapping owner for the complete borrowed-
`Data` scope. Direct access requires an immutable stable mapping snapshot;
before/after metadata checks on an externally mutable file are insufficient.

This refinement records proposed `ADR-0041` as the controlling read/lifetime
candidate. It accepts neither proposal and authorises no source.

### Representation integrity and logical identity

A representation-integrity claim binds:

- exact immutable snapshot and generation;
- projection identifier and version;
- algorithm and algorithm-sized digest bytes;
- exact initialized byte coverage and representation length; and
- an exact non-recursive claim-free representation-descriptor projection
  needed to interpret that coverage.

The projection contains every representation field that affects interpretation
or coverage and excludes the integrity claim itself. A claim cannot be
transplanted to a different same-length descriptor. Its final canonical wire
remains source-blocked with the broader logical/representation projection.

Verification evidence is constructible only by a trusted verifier that reads
the exact admitted immutable snapshot/generation and representation, computes
the selected digest under the selected projection and compares it in constant
time where required. If currentness is required, it uses a permit from the same
Core authority rather than a provider oracle. The final M5 verifier and policy-
authority contract remains unresolved. Callers cannot obtain assurance by
passing booleans or matching labels. A decoded or matching structural claim is
not evidence.

The structural claim does not carry runtime provider authority. Verification
evidence additionally retains and revalidates the exact Core-admitted provider
binding; evidence from another admission is not substitutable merely because
its logical/representation descriptor, owner, snapshot, generation, claim or
digest is value-equal.

Representation verification proves only covered stored bytes. It does not
prove logical identity, provenance, authenticity, cache authority, clinical
meaning or diagnostic validation. A checksum is neither signature nor MAC.

- Representation digest covers defined initialized representation bytes, so
  covered row/plane padding, compressed headers or encoded bytes may change it.
- Logical `descriptorAndSamples` identity enumerates logical indices/components
  once in a fixed scalar encoding and excludes offsets, strides, alignment
  padding, slack, tile order, halo, compression and cache layout.
- Uninitialized bytes never enter either digest or export.

Unused-bit and packed source layouts are decoded under an accepted source
contract, never normalized by guessing. Pixel-padding semantics are typed
processing/presentation metadata, not allocation padding, and remain in the
relevant operation policy/identity.

### Deferred builder and atomic-publication boundary

`builderAcquisition` is a reserved cross-milestone registry category, not an M1
admitted operation. A separate accepted contract must define builder authority,
source/target binding, mutation exclusivity, concurrency, bounded write
coverage, cancellation/failure, allocation accounting, stale/replay behaviour,
freeze linearisation and synchronous resource retirement before any witness or
source exists.

That later contract may use the isolated probe's actor-backed, bounded,
non-overlapping complete-fill fixture as review input, but the fixture is not
normative authority and does not prove production builder semantics. In
particular, provider-actor currentness must not substitute for Core/Execution
generation authority.

Any accepted freeze may return only an unpublished immutable storage snapshot
plus separate representation evidence. Storage does not accept/create
provenance, attach metadata, assert diagnostic assurance, publish a cache alias
or return `ImageData`. Execution or an explicit host/import coordinator owns
the later coherent publication after its independent dependencies are accepted.

### Residency

Residency is not an immutable operation bit. Core may state static
representation compatibility and locality; Metal owns generation-qualified
per-device observations.

Compressed/mapped, decoded CPU/shared and GPU-optimized resources have
independent eviction. Mapping/prefetch does not imply residency. Device
replacement, pressure, eviction and generation changes invalidate observations.
Core imports no Metal type.

### Lifetime, erasure and `Sendable`

`AnyImageStorage` remains source-blocked until independent review proves:

- immutable logical content per exact snapshot/generation binding;
- one nonforkable Core authority per admitted lineage/budget domain;
- retained exact logical/representation/owner/snapshot/generation witnesses;
- checked single-witness dispatch with no fallback;
- private-result backing and byte-token ownership across suspension and aliases;
- first-terminal-wins cancellation/invalidation/commit plus explicit provider
  drain and synchronous reservation retirement;
- bounded dispatch, allocation, live-result bytes and tombstones;
- simultaneous-read race freedom; and
- checked `Sendable` conformance without a Voxelia-authored
  `@unchecked Sendable` escape hatch.

The selected candidate uses owned immutable results and synchronous owner-
retaining `Data` scopes. A caller-chosen textual token plus a separate owner,
ordinary CoW copying, `RawSpan`'s standard-library unchecked conformance or an
outer wrapper token is not lifetime/accounting evidence. The older ADR-0039
probe retains an actor owner and returns copied snapshots; it does not prove the
composed production read gate, alias-token co-location or no-copy/mapped safety.

### Source gate

This Proposed ADR authorises documentation and isolated evidence only. It does
not authorise:

- descriptor, operation, storage/read/lease protocol, builder or erasure
  product source;
- moving/duplicating `StorageKind` or `StoragePersistence`;
- public raw capability bits or synthesised capability coding;
- unsafe/no-copy/mapping implementation;
- packing, tile, brick, codec, remote, sequential-session or residency
  aggregate;
- `ContentID` or digest implementation;
- `ImageData` construction/binding or atomic publication;
- provenance/metadata/identity publication; or
- `@unchecked Sendable`.

Product source requires accepted ADR/RFC and controlled corrections, closure of
the logical projection and read/lifetime contracts, production limits,
supported-destination builds and designated API, concurrency and security
reviews.

Draft `RFC-0001` composes this proposal with proposed `ADR-0040` and
`ADR-0041` and inventories the required corrections. While Draft, it satisfies
none of those acceptance or source gates.

Draft companion `RFC-0001-CCD-01` proposes exact target revisions, owners and
conditional correction text. It is non-authoritative and closes no gate.

### Proposed milestone boundary and unresolved mapping choice

The Foundation assigns storage abstractions to Phase 1 and memory-mapped
storage to Phase 5, while `VOX-STO-004`, MTA Stage 3/section 44.5 and the older
text of this proposal place a mapped implementation in the early storage
milestone. This Proposed ADR does not settle that controlled conflict.

The governed options are:

1. preserve the Foundation schedule: M1 includes the mapping contract and
   isolated lifetime evidence but no production mapped provider; M5 owns
   production mapping, and Requirements/MTA/CDMS are corrected; or
2. retain production mapping in M1 only after a formal Foundation revision,
   followed by aligned Requirements/MTA/CDMS/RFC/ADR revisions and evidence.

Subject to that unresolved choice, the proposed responsibility boundary is:

- **M1:** backend-neutral logical/representation, snapshot, operation, complete
  read and checked-erasure contracts/evidence plus one verified owned
  contiguous provider; structural storage/data-handle compatibility only after
  its independent dependencies are accepted.
- **M2:** canonical logical identity and provenance/cache/publication
  dependencies.
- **M3:** operational Metal-owned generation-qualified residency evidence. M1
  may name the absence/presence of such separately owned evidence but does not
  encode changing residency as an immutable storage capability.
- **M5:** tiled/bricked/compressed/multi-resolution providers, representation
  integrity, independent eviction and, under option 1, production mapping.
- **M9:** callback/remote providers and any sequential session, with host-owned
  transport/authentication.

No builder/freeze implementation milestone is selected here. Builder
acquisition, mutation exclusivity, freeze and hand-off require a separate
accepted contract and cannot publish `ImageData` from Storage.

Reserving later-operation bits does not claim their implementation or
validation. In particular, the evidence probe retains only a bounded
resolution-count characteristic and rejects operational
`resolutionLevelAccess`; callable per-level descriptors remain M5 work. M1
does not inherit later digest/integrity completion merely because the CDMS
checklist says “complete-content digest”. Until the mapping choice is approved
through the recorded authority route, no mapped product source is authorised.

## Alternatives considered

### Implement the CDMS types in Storage

Rejected. Core-owned `ImageData` would require a prohibited dependency/cycle.

### Make Core depend on Storage

Rejected. It reverses the foundational graph and binds canonical handles to
concrete implementations.

### Duplicate contract types

Rejected. Lookalikes drift and leave no canonical authority.

### Keep one `StorageKind` and mixed capability bag

Rejected. Organization, representation, locality, optional access, persistence
and residency are orthogonal.

### Keep random/sequential bits

Rejected. Bits do not define callable behavior, and no sequential session
contract exists.

### Keep public raw `OptionSet` and synthesised coding

Rejected. It exposes unknown states and no exact portable wire.

### Mask unknown bits

Rejected. It creates downgrade/capability-smuggling risk.

### Treat mapping as logical direct bytes

Rejected. A compressed object may be mapped without decoded samples.

### Treat absence of remote as local

Rejected. Missing information cannot grant file/network policy authority.

### Make published storage writable

Rejected. In-place mutation invalidates identity, provenance, caches, leases
and concurrency assumptions.

### Let Storage create provenance and return `ImageData`

Rejected. Storage cannot author or atomically validate all owner-specific
publication claims.

### Treat digest access as verified content

Rejected. API, claim, representation verification, logical identity and
diagnostic assurance are distinct.

### Include physical layout in logical identity

Rejected. Equivalent logical samples in different representations need a
separate representation-integrity domain.

### Return pointer/token pairs with comments

Rejected. Comments do not enforce scope, retention or race freedom.

## Consequences

- The package graph remains intact.
- Core has one future backend-neutral contract family; Storage implements it.
- Capabilities become typed retained operations plus characteristics.
- Stable bit and unknown-data behavior are fixed before persistence.
- Layout construction fails closed on rank, overlap, overflow, length,
  alignment and byte-order errors.
- Core-owned reads cannot expose partial, stale, substituted or unaccounted
  bytes; builders remain separately gated.
- Representation integrity, logical identity, provenance and diagnostic
  assurance remain distinct.
- Residency remains downstream device state.
- Product source remains blocked until acceptance prerequisites are real.

## Affected modules

- `VoxeliaCore`: future logical/representation, operation, snapshot, complete-
  read, owned-result, scoped-lease, error and checked-erasure contracts plus
  private target admission/adoption.
- `VoxeliaStorage`: concrete providers/builders, source/mapping allocations,
  resource lifetimes, I/O and representation verification.
- `VoxeliaExecution`: generation pinning and atomic publication.
- `VoxeliaMetal`: per-device residency/GPU state.
- `VoxeliaValidation`: purpose-specific assurance.
- Hosts/adapters: locators, authentication, transport, privacy and import
  publication.

## Compatibility impact

No aggregate exists in product source, so this documentation-only increment
changes no compiled aggregate or persistent Voxelia wire.

Existing `StorageKind` and `StoragePersistence` leaves are in the wrong module
for the selected ownership and collapse orthogonal facts. Their eventual
pre-1.0 migration may be source-breaking and needs explicit compatibility
notes. They are not moved here.

External prototypes using raw flags, synthesised coding, Storage-owned erasure,
caller-owned async destinations, provider-stamped completion, writable
published storage, optional stride bags or builder-returned `ImageData` are not
compatible Voxelia contracts.

## Security impact

The decision reduces bounds, overflow, lifetime, TOCTOU, downgrade,
partial-publication and confused-authority risk. Unknown wire bits fail closed;
address arithmetic and resource limits are checked before access.

It does not authenticate providers or digests. Direct mapping requires an
immutable stable snapshot for the whole scope. An externally mutable file may
only use copied private staging plus fail-closed revalidation; verification or
invalidation alone is not direct mapped-lease evidence. Remote/compressed
inputs remain adversarial. Credentials, keys, trust and network policy remain
host-owned.
The Core-admitted provider-lineage identity prevents in-process authority
substitution only; it is not external authentication, a globally stable
identifier, a signature or a trust assertion.

Direct/mapped bytes and digests may be sensitive/linkable. Default diagnostics
exclude paths, URLs, identities, digests and source metadata. Future unsafe
code needs minimal scope, independent review and hostile lifetime/concurrency
evidence.

## Performance and memory impact

Descriptor admission is O(rank log rank) under the conservative stride proof
and O(rank) space. Region validation is O(rank). Capability admission is
bounded by ten operations. Exact wire work is constant.

Inputs are bounded incrementally before generic sequences are collected.
Descriptor construction never reads sample content, and ordinary equality or
hashing never computes a digest.

Probe ceilings are fixtures, not production limits. Production maxima require
lowest-resource Apple-device, hostile-input, cancellation and recoverable
allocation-failure evidence. Safe scoped access may avoid copies; the contract
never requires implicit full materialisation for backend convenience.

## Validation impact

Acceptance requires focused evidence for:

- exact bits, mask, fixed lowercase wire and future opaque forwarding;
- malformed/future/reserved/oversized ingress rejection without pre-limit
  materialisation;
- one nonforkable Core authority per admitted lineage/budget domain, co-retained
  by derived handles, generations and re-erasure, plus exact authority/logical-
  binding/representation/owner/snapshot/generation/witness callability and
  missing/extra/substitution denial;
- mandatory history-independent read witness;
- mapping without decoded direct bytes and typed organization metadata;
- explicit source-gating of operational resolution-level access until M5 has
  per-level representation/layout and spatial-correspondence evidence;
- checked shape, component, scalar, logical/representation/request limits;
- stride rank/sign, offset, interleaved/planar layout, overlap, overflow,
  span, alignment, endian and packed/storage-defined rejection;
- cross-shape region substitution rejection;
- Core-owned one-shot seals, pending reservation before fallible private-target
  construction, monotonic bounded fill, internally stamped preparation, first-
  terminal-wins commit/cancel/stale/failure/abandonment and drain-before-return;
- complete owned-result publication with independent live-byte tokens, retained-
  alias accounting, recyclable tombstones and no publication after short/
  overrun/invalid fill, cancellation, failure, mismatch, equal-label cross-
  admission substitution, replay or stale current-required generation;
- non-transplantable claim-free representation-descriptor binding,
  algorithm-sized representation claims, trusted exact-byte digest
  computation, exact admitted-snapshot binding, claim/evidence separation and
  mismatch denial; final verifier/policy authority, expiry and revocation remain
  M5-gated;
- explicit source-gating of builder acquisition/freeze until a separate accepted
  contract defines authority, binding, exclusivity, cancellation, coverage,
  allocation, stale/replay and unpublished hand-off semantics;
- owner-retaining synchronous `Data` scopes, generic CoW-alias escape denial or
  accounting, complete mapped-scope binding, stale denial and bounded ingress;
- strict Swift concurrency with no unsafe pointer or `@unchecked Sendable`;
- exact redacted description, debug description, reflection and dump output for
  byte-bearing values and actors plus PHI/path/digest sentinels; and
- supported-destination and designated API/security/concurrency review before
  source.

The probe's opaque forwarding fixture deliberately accepts only the same
fixed-width capability envelope with a future version. It does not satisfy the
broader acceptance requirement for arbitrary bounded future-schema
preservation. The isolated Swift 6 probe covers the descriptor/capability,
integrity, builder and earlier provider-completion/destination fixture with toy
bytes, an actor-backed provider, CryptoKit SHA-256 and non-production limits.
It does not demonstrate the composed Core admission factory, private-target
allocator, monotonic fill/prepare/commit/drain gate, live-result budget ledger,
safe erasure, CoW-alias accounting, complete mapped binding, production
provider/integrity implementation, unsafe/no-copy access, full cryptographic
validation or production limits.

No complete package suite is required because product source, targets and
dependencies do not change. The focused probe plus document, graph/import,
manifest and release-integrity gates cover this increment.

## Migration

If accepted:

1. accept the directional storage-contract RFC and record the governed mapping
   choice without treating that acceptance as source authority;
2. make the complete controlled Foundation/MTA/CDMS/RPSS/Requirements/FVSP/
   overview correction package effective;
3. reconcile all three storage proposals, then accept `ADR-0039`, `ADR-0040`
   and `ADR-0041` in that order, with `ADR-0041` controlling the Core-owned
   read/seal/stamping/drain and lifetime model;
4. freeze final public names, wires, errors and production limits through their
   required focused reviews;
5. introduce lossless Core/Geometry logical/representation compatibility
   projections before removing or moving an existing declaration;
6. implement checked Core descriptors, admission authority, operation registry,
   complete-read transaction, owned result and erasure with focused tests;
7. implement one owned contiguous Storage provider with bounds, cancellation,
   allocation-failure, race, lifetime and release tests;
8. implement direct leases or a mapped provider only after the selected
   milestone plus platform/lifetime/unsafe evidence gates;
9. design builder acquisition/freeze under a separate accepted contract;
10. integrate `ImageData` publication only after identity, metadata, provenance,
    cache and Execution/import publication dependencies are accepted; and
11. add Metal/M5/M9 contracts only at their governed milestones.

Until then, storage leaves remain declaration vocabulary and no aggregate is
source-authorised.

## Supersession

This proposal refines conflicting storage ownership, capability, descriptor,
read, builder and integrity sketches. It does not change the live graph.

It composes with proposed `ADR-0037` for data identity/cache admission and
proposed `ADR-0038` for provenance/publication, and proposed `ADR-0040` for the
normalized logical sample projection, and proposed `ADR-0041` for the read
transaction/type-erasure lifetime boundary. If the proposals are accepted in
their recorded order, `ADR-0041` controls read authority, stamping, allocation,
drain, result-accounting, erasure and scoped-byte lifetime where the older
ADR-0039 probe shape differs. None of those links accepts another proposal or
closes the remaining descriptor, identity or source gates.
It does not define canonical logical `ContentID`, final `ImageData`, metadata/
provenance, codecs, tile/brick grids, remote transport, Metal resources or
diagnostic status.

## References

- [Voxelia Project Foundation v0.1.1](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0040 - Normalized logical sample and representation projection boundary](ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md)
- [ADR-0041 - Safe storage read transaction and type-erasure lifetime boundary](ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md)
- [RFC-0001 - Storage contract and logical data-model composition](../../rfcs/RFC-0001-storage-contract-and-logical-data-model-composition.md)
- [RFC-0001-CCD-01 - Controlled-correction delta](../../rfcs/RFC-0001-controlled-correction-delta.md)
- [ADR-0039 storage capability/descriptor admission probe](../../progress/evidence/ADR-0039-storage-capability-descriptor-admission-probe.swift)
