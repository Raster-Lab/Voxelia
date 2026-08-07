---
document_id: "ADR-0040"
title: "Normalized logical sample and representation projection boundary"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-003"
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-GOV-009"
  - "VOX-GOV-010"
  - "VOX-ARC-001"
  - "VOX-ARC-003"
  - "VOX-ARC-004"
  - "VOX-ARC-007"
  - "VOX-ARC-012"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-007"
  - "VOX-API-010"
  - "VOX-API-011"
  - "VOX-DAT-001"
  - "VOX-DAT-004"
  - "VOX-DAT-009"
  - "VOX-DAT-010"
  - "VOX-DAT-011"
  - "VOX-DAT-012"
  - "VOX-DAT-013"
  - "VOX-DAT-014"
  - "VOX-DAT-015"
  - "VOX-IMG-001"
  - "VOX-IMG-002"
  - "VOX-IMG-009"
  - "VOX-IMG-015"
  - "VOX-META-001"
  - "VOX-META-002"
  - "VOX-META-011"
  - "VOX-STO-001"
  - "VOX-STO-002"
  - "VOX-STO-003"
  - "VOX-STO-004"
  - "VOX-STO-007"
  - "VOX-STO-008"
  - "VOX-STO-009"
  - "VOX-STO-010"
  - "VOX-STO-011"
  - "VOX-RGN-001"
  - "VOX-RGN-002"
  - "VOX-RGN-003"
  - "VOX-RGN-004"
  - "VOX-RGN-006"
  - "VOX-RGN-007"
  - "VOX-RGN-008"
  - "VOX-CON-003"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-CON-010"
  - "VOX-ERR-001"
  - "VOX-ERR-003"
  - "VOX-ERR-007"
  - "VOX-SEC-001"
  - "VOX-SEC-002"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
  - "VOX-VAL-016"
  - "VOX-VS1-005"
  - "VOX-VS1-006"
  - "VOX-VS1-008"
  - "VOX-VS1-014"
  - "VOX-VS1-019"
  - "VOX-VS1-020"
  - "VOX-DCM-003"
  - "VOX-DCM-005"
  - "VOX-DCM-006"
  - "VOX-DCM-008"
  - "VOX-DCM-010"
  - "VOX-DCM-013"
---

# ADR-0040 - Normalized logical sample and representation projection boundary

## Context

Voxelia requires one storage-independent meaning for a logical image sample
before it can bind an `ImageDescriptor` to storage or calculate a persistent
logical content identity.

The controlled model requires all of the following:

- the canonical image model is independent of physical storage;
- logical axis order is part of descriptor identity;
- a physical layout may differ while exposing the same logical samples;
- component layout never changes logical component order;
- canonical logical identity uses canonical sample and component order;
- physical storage padding does not affect logical content identity;
- source byte order and bit layout may be retained as source metadata or
  provenance;
- decoded native storage normally uses native byte order;
- packed layout cannot be inferred from `validBitCount`; and
- no value, byte-order or component-layout conversion is silent.

The live Core leaves do not provide that separation. `ScalarFormat` contains
`validBitCount` and `byteOrder`, and `ComponentDescriptor` contains `layout`.
Both values currently participate in synthesised equality, hashing and ordinary
`Codable`. `GeometryAttributeDescriptor` embeds both leaves. A future
`ImageDescriptor` that embeds them unchanged would make little-endian and
big-endian, interleaved and planar, or source-valid-bit variants different
logical descriptors even when they expose exactly the same decoded values.

The inverse shortcut is also unsafe. Ignoring those fields in one digest while
leaving them in public descriptor equality would create competing meanings for
"same descriptor". Treating `validBitCount` as sufficient packing metadata
would leave bit placement, bit order, signed extension and unused-bit policy
undefined. Hashing native representation bytes would make logical identity
depend on layout, padding and execution platform.

Proposed `ADR-0036` defines one metadata-record identity only. Proposed
`ADR-0037` distinguishes content claims from runtime assurance and leaves image
projections undefined. Proposed `ADR-0039` separates logical binding from
physical representation but intentionally leaves the normalised logical
sample/component projection as a source gate. This proposal closes that gate
conceptually. The `ADR-0039` probe proves checked physical gathering but does
not byte-swap values, so it is representation evidence rather than logical-
endian normalisation evidence. This proposal does not complete the canonical
`ImageDescriptor` wire, authorise a `ContentID`, or authorise storage product
source.

## Decision

With this ADR accepted by the project owner on 2026-08-04 under the
`RFC-0001` directional review, Voxelia separates four non-interchangeable
layers:

| Layer | Meaning | Owner |
|---|---|---|
| Logical sample-layout binding | Shape, exact decoded scalar type, component count and exact logical component ordinals needed to enumerate values. | `VoxeliaCore` |
| Source value interpretation | Source container, byte order, stored-bit field, signed extension and source-defined unused-bit rule used to obtain a decoded logical value. | Optional adapter, with backend-neutral claim values in Core where required |
| Storage representation | Exact initialized bytes, strides, component arrangement, padding, compression, tiling and resource lifetime. | Core contract; concrete implementation in `VoxeliaStorage` |
| Persistent identity/evidence | Versioned projection claim plus separately admitted runtime evidence over one immutable snapshot. | Core claim values; Execution/Storage/Validation evidence owners |

No layer acquires the authority of another merely because byte counts or labels
match.

### Logical sample binding

The storage-compatible subset of a future image descriptor is:

```text
logical sample-layout binding
  shape: positive dynamic-rank extents
  scalar type: one exact decoded ScalarType
  components
    positive count
    ordered logical component ordinals
```

This binding excludes:

- byte order;
- `validBitCount`, bit offset, bit order and unused-bit policy;
- interleaved, planar or provider-defined arrangement;
- base offsets, strides, row/plane padding, slack and alignment;
- tile, brick, halo, compression or cache order;
- source locators and provider identity;
- Metal resources and residency; and
- pixel-padding presentation/processing policy.

The binding is not a complete `ImageDescriptor`. Component interpretation and
semantic roles do not change how the narrow sample sequence is enumerated, so
they are not fields of this storage-compatibility/sample-layout binding. They
remain logical descriptor semantics alongside image semantic, axes, units,
geometry, value transforms and other fields in the future canonical complete
descriptor projection. This ADR defines only the subset needed for storage
compatibility and canonical sample enumeration.

### Exact decoded scalar identity

`ScalarType` identifies the exact decoded value representation. Integer values
use their fixed-width two's-complement or unsigned bit pattern. `float16`,
`float32` and `float64` use their exact IEEE binary16, binary32 or binary64 bit
pattern after decoding. A logical value projection performs no arithmetic.

Therefore:

- positive and negative floating zero remain distinct;
- NaN sign, payload and quiet/signalling bit remain distinct;
- numerically equal values of different scalar types remain distinct;
- integer signedness and width remain distinct;
- no integer narrowing, widening, saturation or reinterpretation is implicit;
- no floating canonicalisation, rounding, flush-to-zero or NaN rewriting is
  implicit; and
- modality/value transforms, colour conversion and unit conversion create a
  new logical result under separately specified operations.

This is exact bit-pattern identity, not Swift `FloatingPoint` equality,
approximate numerical equality or diagnostic equivalence. Any future semantic
numeric identity must have a different projection identifier and an approved
tolerance/normalisation policy.

For this exact-bit sequence, all binary interchange bit patterns—including
subnormals, infinities and distinct NaN encodings—have a deterministic
encoding and remain distinct. This is the explicit special-value rule for this
narrow payload projection. It does not imply that every image semantic admits
non-finite values or that the future complete descriptor-and-samples projection
must do so; those cross-field constraints may make complete identity
unavailable without changing the stored sample.

### Canonical logical sample sequence

The proposed logical sample sequence enumerates:

1. logical indices with axis zero changing fastest; and
2. within each logical index, component ordinals from zero through
   `componentCount - 1`.

For extents `e[0] ... e[rank - 1]` and indices
`i[0] ... i[rank - 1]`, the sample ordinal is:

```text
i[0] + e[0] * (i[1] + e[1] * (i[2] + ...))
```

The value ordinal is `component + componentCount * sampleOrdinal`. The
highest-numbered axis is the outermost axis loop, axis zero is the innermost
axis loop and component is the innermost value loop at each sample. Every
intermediate addition and multiplication is checked. Focused evidence includes
an exact rank-three, multi-component ordering golden so conventional uses of
"row-major" cannot silently reverse the intended axis order.

Each decoded value contributes exactly its scalar width in most-significant-
byte-first order. Signed integers contribute their fixed-width two's-complement
bits, unsigned integers their fixed-width binary bits, and floating-point
values their exact binary interchange bits. No delimiter or padding appears
between values because the exact scalar type and checked value count are bound
out of band by the logical sample-layout binding.

The checked value count is:

```text
product(shape.extents) * componentCount
```

The checked payload length is that count multiplied by scalar byte width.
Overflow, a value count beyond policy, a short/long source or an out-of-range
platform conversion is a typed failure before allocation or publication.

The sequence is a payload projection, not a standalone identifier. Raw payload
bytes can alias across different shapes, scalar types, component counts or
semantic descriptors.
A persistent `sampleBytes` or `descriptorAndSamples` identity must domain-bind
the exact projection/version and the accepted sample-layout binding or full
descriptor respectively.

`org.voxelia.logical-sample-sequence` version `1.0` is an unregistered evidence
label only. No `ContentID` may use it until an accepted ADR fixes the exact
binding/frame wire, length domains and complete preimage rules. This proposal
does not register that projection or define the canonical full descriptor wire.

### Logical component ordinals and semantic separation

Component ordinals are logical and exact. Representation layout cannot reorder
them implicitly. The sample payload contains values in ordinal order;
interpretation and semantic roles are bound by the future canonical logical
descriptor rather than repeated beside every sample.

`sampleBytes` is therefore a narrow value-sequence claim, not complete image
content identity and not a sufficient object/cache key. Semantic interpretation
changes the future `descriptorAndSamples` projection even when the narrow
sample sequence is unchanged.

The controlled model currently defines `componentNames` only as optional names
in logical component order. This proposal interprets them as ordinary
presentation coding rather than stable semantic-role authority; accepting that
interpretation requires the public RFC and a controlled CDMS correction.
Existing strings remain losslessly available as presentation names during
migration, but never become persistent role identity by implication. Stable
roles require a separate bounded exact type and cannot inherit Swift `String`
canonical-equivalence ambiguity. A missing name is never replaced by an
invented one.

Scalar/count-one is the only generally unambiguous current profile. `rgb` and
`rgba` establish red-green-blue[-alpha] ordinal names but do not complete
scientific colour identity without colour space, transfer/range and alpha
association. Vector, tensor, complex, probability and generic profiles need
accepted basis, order, symmetry, class or namespace semantics before a
complete persistent descriptor-and-samples identity is available. A toy RGB
fixture may prove ordering mechanics without claiming that missing contract.

An explicit operation may permute components and produce a new descriptor and
sample sequence. A representation adapter may map physical planes to logical
ordinals only when the mapping is complete, one-to-one, bounded and retained
in the representation contract. A missing, duplicate or substituted ordinal
fails before reading.

A syntactically valid permutation cannot prove that an adapter labelled its
planes truthfully. Provider/source-adapter evidence and differential fixtures
remain required; bytes alone cannot establish semantic channel truth.

### Byte order and native representations

Byte order is a representation decoding fact, not logical value identity.
Decoding a full-width scalar from explicit little-endian, big-endian or already
resolved process-native bytes must produce the same exact logical bit pattern.

`.native` is meaningful only for process-local decoded memory whose platform is
known at use time. A persistent, mapped, external, distributed or canonical
record resolves byte order to an explicit value. No persistent identity or
wire serialises `.native` as if it had one universal meaning.

Byte swapping is permitted only as an exact representation-to-value decode.
It is not a numeric conversion and does not change the logical binding.

### Valid bits, extension and packed storage

`validBitCount` does not belong to decoded logical identity and is never enough
to decode a source representation. A complete source integer interpretation
needs at least:

- source container width;
- exact stored value width;
- least-significant stored-bit position;
- signed or unsigned interpretation;
- explicit byte order;
- the source-contract rule for unused bits; and
- the required sign-extension or zero-extension result type.

Stored-bit zero is the least-significant bit after explicit byte-order
resolution. An integer source decoder applies these operations in this exact
order:

1. assemble the unsigned source container using the explicit byte order;
2. check that stored-bit position plus width fits the container;
3. enforce the source contract's unused-bit rule against the original
   container;
4. shift and mask the stored field;
5. for a signed field, treat stored bit `width - 1` as the sign bit and sign-
   extend the extracted field; otherwise zero-extend it; and
6. require the exact result to fit the bound decoded `ScalarType`.

Sign extension never happens before field extraction. A canonical zero-unused-
bits rule rejects any dirty unused bit; ignoring those bits is permitted only
when a separately identified source contract explicitly selects that rule.

An approved adapter applies that rule once and yields a full-width decoded
logical integer. For the M4 CT profile, DICOMKit/codec decoding produces a
correctly sign-extended `Int16` or zero-extended `UInt16`; bits-stored/high-bit
facts remain source metadata and provenance. Two source encodings that decode
to the same exact full-width values may share logical sample identity while
retaining different source and representation identity.

Unused bits may be rejected or ignored only when the applicable source contract
explicitly selects that behaviour. Ignored bits remain covered by any exact
representation-integrity projection. They do not enter logical sample bytes.

Multiple packed values per container, cross-byte bit streams and storage-
defined packing remain rejected by the initial decoded-strided profile. A
future tagged packing contract must additionally define bit order, sample
crossing, row/plane termination and padding. Neither `validBitCount` nor total
byte length implies that contract.

Floating-point `validBitCount` is rejected as incomplete source interpretation.
A reduced-precision or custom floating encoding needs a tagged codec/format and
an explicit conversion to one supported decoded `ScalarType`.

### Physical padding and pixel padding

Allocation padding, row/plane padding, alignment gaps, tile halos, compressed
headers and uninitialised slack are not logical sample values. A complete
representation descriptor proves which exact initialised bytes are addressed;
the logical projection visits each logical sample/component exactly once and
skips physical padding.

Pixel padding is different. It is source-derived semantic metadata and an
operation/presentation policy, not allocation padding and not an alternative
numeric sample. It is never silently converted to air, zero, black or CT
intensity. The sample payload preserves the decoded source value, while the
typed pixel-padding rule remains in the relevant metadata, operation and full
data-identity/provenance projections. Because `descriptorAndSamples` does not
currently name metadata, complete image identity for data carrying pixel-
padding semantics remains unavailable until an accepted typed logical-validity/
padding projection binds that policy. Its final public type remains M4 work.

### Representation compatibility

A representation is compatible with one logical sample binding only when all
of the following are established:

| Dimension | Admission rule |
|---|---|
| Shape | Exact rank and extents; checked complete coverage. |
| Scalar | Every exposed value decodes to the exact bound `ScalarType` bit pattern. |
| Components | Exact count and complete one-to-one physical-to-logical ordinal mapping. |
| Layout | Exact bounded addressing proves each logical value is read once without overlap or out-of-bounds access. |
| Completeness | The provider supplies exactly the requested logical values; no successful prefix. |
| Snapshot | The retained provider authority, descriptor, owner, snapshot and generation remain exactly bound. A current-only operation additionally requires the non-forgeable current-generation permit proposed by `ADR-0041`; historical bound-snapshot reads do not silently stale or relabel. |

Different endian order, interleaved/planar strides and initialised physical
padding can be compatible. Equal byte length, equal labels or equal hashes in a
different projection are not compatibility evidence.

Future tiled/bricked sources enumerate every logical value exactly once.
Overlapping halo copies must agree under exact logical value identity or the
projection fails; an implementation cannot select one conflicting duplicate by
iteration order.

The following always require a new explicit operation/result or fail:

- numeric cast or saturation;
- signedness reinterpretation;
- floating normalisation or tolerance comparison;
- rescale, lookup-table, unit or colour-space transformation;
- implicit component permutation;
- treating pixel padding as a quantitative value; and
- guessing a packed or storage-defined layout.

### Logical and representation digest domains

Logical and representation digests are separate claims:

| Domain | Covered input | Excluded authority |
|---|---|---|
| Representation integrity | Exact claim-free representation descriptor and exact initialized representation bytes, including covered physical padding/headers. | Does not prove logical equality, provenance, authenticity or diagnostic validity. |
| Logical sample sequence | Exact sample-layout binding plus canonical decoded sample sequence. | Does not by itself cover component-role semantics, the full image descriptor, metadata, provenance or assurance. |
| Descriptor and samples | Future canonical complete logical descriptor plus logical sample sequence under one versioned domain frame. | Remains undefined until the full descriptor projection is accepted. |
| Source/derivation | Exact source or operation-specific record. | Is not interchangeable with either byte domain. |

Ordinary Swift `Hashable`, synthesised `Codable`, raw SHA-256 of bytes, a
provider checksum and a content claim do not establish persistent identity.
Publication still follows proposed `ADR-0036` and `ADR-0037`: the algorithm,
scope and projection are explicit, and owner-held runtime evidence separately
binds the exact immutable snapshot and policy context.

Digests and logical bytes are sensitive-derived. They do not de-identify image
content or authorise logging, filenames, export, cross-tenant deduplication or
cache sharing.

### Platform integers, bounds and streaming

Product shape/count/offset APIs remain the controlled `Int` model. Every
unsigned or wider external value is checked against `Int.max` and a stricter
host limit before lossless conversion. Products, strides, offsets, addressed
spans, value counts and byte counts use checked arithmetic.

Logical projection may stream in canonical order and need not materialise a
whole image or second full-volume buffer. The provider snapshot/generation is
pinned for the operation. Cancellation, decode failure, short input, stale
generation or limit exhaustion publishes neither a digest claim nor a partial
logical result. Any future long-running production implementation defines a
bounded cancellation cadence and final pre-publication revalidation.

### Errors, diagnostics and concurrency

Ingress and projection use closed typed failures for invalid binding,
incomplete source interpretation, unsupported packing, incompatible
representation, overflow/platform range, resource limit, short/long input,
cancellation and stale snapshot.

Default descriptions, debug descriptions, reflection, logs and telemetry do
not include sample values, raw bytes, component names, paths, source IDs or
digests. Detailed diagnostics require an explicit privacy-authorised sink.

Bindings and immutable projection values are `Sendable`. Mutable readers,
decoders and publication state are actor-isolated or equivalently confined.
This decision authorises no unsafe pointer and no `@unchecked Sendable` use.

### Milestone and source gate

M1 owns logical storage compatibility and the exact full-width representation-
to-decoded-value admission required for safe reads. M2 owns registration of the
versioned canonical logical sample sequence, digest claims and their assurance/
publication dependencies under the proposed `ADR-0039` milestone correction.
Source bit interpretation and DICOM pixel padding are adapter/M4 work; packed,
tiled and compressed projection details remain their owning later milestones.
The separation is specified now as risk-retirement evidence so later
representations cannot silently redefine logical identity.

Acceptance of this proposal authorises no product source. Product-source
authorization still requires the public data-model/storage RFC, controlled
MTA/CDMS/RPSS/Requirements corrections, migration approval, complete logical
descriptor projection, production limits, safe destination/erasure lifetime
design proposed by `ADR-0041`, affected Core/Geometry tests, supported Apple-
destination builds and designated API/concurrency/security reviews. This link
does not accept `ADR-0041` or close the remaining source gate.

Draft `RFC-0001` now supplies the composition and correction inventory for
review. Its Draft status does not accept this proposal, register a content
projection or authorise source.

## Alternatives considered

### Keep byte order, valid bits and component layout in logical descriptors

Rejected. Physical representations of the same decoded values would acquire
different canonical descriptor and content identity.

### Ignore selected fields only while hashing

Rejected. Public equality/Codable and persistent identity would disagree about
the meaning of the same descriptor.

### Hash native representation bytes

Rejected. Endian order, layout, padding, compression and platform would alter
logical identity.

### Normalise floating zero and NaNs

Rejected. The controlled no-hidden-coercion rule supplies no authority for
discarding sign or payload information. Numeric equivalence needs a separate
named projection.

### Treat `validBitCount` as a packed-layout description

Rejected. It omits position, order, extension, unused-bit and row/plane rules.

### Convert pixel padding to a numeric background value

Rejected. It would contaminate authoritative values and contradict the M4
padding policy.

### Materialise every representation before projection

Rejected. Canonical order can be streamed from a snapshot-consistent region
reader and must not require an unnecessary full-volume duplicate.

### Implement the corrected public leaves immediately

Rejected. The change is source- and wire-breaking, crosses Core and Geometry,
and depends on unaccepted storage and full-descriptor contracts.

## Consequences

- One exact decoded value relation is independent of physical layout.
- Representation integrity and logical identity no longer share ambiguous
  byte domains.
- Valid-bit decoding becomes explicit adapter work rather than descriptor
  inference.
- Floating exact identity remains bit-preserving and distinct from numerical
  comparison.
- Component order is stable across interleaved and planar representations.
- Canonical logical projection can stream without a mandatory full copy.
- Existing Core/Geometry APIs need an explicit pre-1.0 migration after
  acceptance.
- Full image content identity remains blocked on the canonical complete
  descriptor projection and assurance/publication contracts.

## Affected modules

- `VoxeliaCore`: logical scalar/component binding, future canonical payload and
  representation claim values.
- `VoxeliaStorage`: exact representation decoding, addressing, snapshot and
  lifetime witnesses.
- `VoxeliaGeometry`: migration from physical fields embedded in attribute
  logical descriptors.
- `VoxeliaDICOMKit` and codec adapters: explicit source bit interpretation,
  sign/zero extension and pixel-padding metadata.
- `VoxeliaExecution`: cancellable generation-pinned projection and atomic
  identity publication.
- `VoxeliaValidation`: exact-byte versus exact-numeric/equivalence evidence.
- `VoxeliaMetal`: consumes explicit logical/representation contracts without
  becoming identity authority.

The package graph does not change.

## Compatibility impact

If accepted, migration is staged and ends in an intentional pre-1.0 source/
wire correction:

- an initial compatibility phase introduces corrected logical projection and
  representation values while treating current `ScalarFormat` and
  `ComponentDescriptor` as legacy compound source/representation vocabulary;
- explicit conversions preserve every `type`, `validBitCount`, component and
  layout field and fail when a logical projection is ambiguous; a legacy
  `.native` byte order must be resolved to explicit little or big endian by a
  trusted process/platform context before persistence, otherwise migration
  fails;
- the final logical scalar value retains the exact `ScalarType`, while
  `validBitCount` and `byteOrder` move into explicit source/representation
  values;
- the final logical component value retains count and accepted interpretation/
  role semantics, while `layout` moves into the representation contract;
- `ByteOrder` and `ComponentLayout` may remain Core-owned backend-neutral
  representation vocabulary, but no longer participate in logical descriptor
  identity;
- `GeometryAttributeDescriptor` and its ordinary Codable shape migrate with
  those leaves;
- old JSON is not silently accepted under new logical semantics;
- misplaced fields are deprecated only after downstream Core/Geometry review
  and removed in a documented later 0.x breaking step; and
- the changelog and controlled specifications record the break under
  `VOX-API-011`.

The exact final type names and canonical wire remain RFC work. This proposal
does not deprecate or change the live declarations by itself.

## Security impact

The decision removes ambiguous byte interpretation and bounds every external
count before memory access. It requires rejection of detectable binding,
layout or projection substitution when admitted descriptors and retained
provider evidence mismatch, and prevents digest-scope confusion, packed-bit
guessing and partial identity publication.

It does not authenticate sources, providers or digests. Source contracts,
provider authority, integrity verification, signatures, transport security and
diagnostic assurance remain separate. It cannot prove adapter truthfulness or
defeat a malicious unauthenticated provider. Logical digests are equality
oracles over sensitive data and inherit privacy/export/cache-partition policy.

Sample values and source-derived names remain redacted by default. No patient
identifier or sample bytes enter typed error payloads, reflection, logs or
telemetry.

## Performance and memory impact

Logical value enumeration is O(value count) time. Index/stride validation is
O(rank plus component count), and streaming projection uses O(rank) cursor
state plus bounded hashing/decoder buffers. It does not require a second full
image allocation.

Checked offset work may cost more than a raw contiguous loop. Accepted
contiguous/interleaved implementations may specialise only after preserving
the same exact ordering and differential evidence. No performance shortcut may
hash padding, skip values, reorder components or weaken stale/cancellation
checks.

## Validation impact

Acceptance requires focused evidence for:

- exact canonical value bytes for every supported scalar width/class;
- same logical bytes across explicit little-/big-endian representations;
- same logical bytes across interleaved, planar and padded strided layouts;
- exact rank-three, multi-component ordering under the stated ordinal formula;
- distinct representation digests for physically different equal-logical
  representations;
- physical component-order changes restoring the same ordinal sequence only
  through an explicit complete map;
- toy closed semantic-role mutations changing only the probe's separately
  labelled descriptor-bearing fingerprint, never the candidate sample stream;
- exact preservation of floating signed zero and distinct NaN payloads;
- explicit exact-bit handling of subnormal and infinite fixtures without
  arithmetic conversion;
- explicit 16-bit signed/unsigned valid-bit decoding and source-only unused-bit
  treatment;
- rejection of valid-bit-only, floating valid-bit and packed-layout guesses;
- checked rank/count/byte arithmetic and lossless platform-`Int` ingress;
- short/long/out-of-bounds/incompatible input rejection without publication;
- logical-versus-representation digest domain separation;
- payload-free, sample/name/path/digest-redacted diagnostics;
- strict Swift concurrency with no unsafe or `@unchecked Sendable`; and
- designated API, numerical, storage, security and privacy review before
  source.

An isolated Swift 6 probe may use toy tags, toy limits and CryptoKit SHA-256 to
demonstrate these relations. It is not product API, the canonical descriptor or
content-ID wire, a production source decoder, a storage implementation or
diagnostic validation.

Because this increment changes only documentation and isolated evidence, the
focused probe plus documentation, package-graph/import, manifest and release-
integrity gates are sufficient. No complete package suite is required.

## Migration

If accepted:

1. approve the public data-model/storage RFC and controlled corrections;
2. name the final logical and representation leaf types;
3. introduce explicit lossless compatibility projections for current compound
   leaves without using them in a future `ImageDescriptor` identity;
4. move byte order, valid bits and component layout out of logical descriptor
   identity through documented Core/Geometry deprecation and 0.x removal;
5. update ordinary coding and tests without claiming canonical bytes;
6. accept the complete logical `ImageDescriptor` projection;
7. implement checked source interpretation in owning adapters;
8. implement storage compatibility against exact logical bindings;
9. accept proposed `ADR-0041`'s safe read/lifetime boundary;
10. add generation-pinned streaming logical projection;
11. integrate content claims only after `ADR-0036`/`ADR-0037` publication and
   assurance boundaries are accepted; and
12. run the milestone/release-wide gate only at the applicable boundary.

Until then, live scalar/component leaves remain unchanged and no storage,
logical-content identity or descriptor aggregate source is authorised.

## Supersession

This proposal refines the normalised logical-binding gate in proposed
`ADR-0039`. It does not supersede the live controlled baseline while Proposed.

It composes with proposed `ADR-0036` for versioned content claim shape,
proposed `ADR-0037` for assurance/publication, and proposed `ADR-0039` for
storage admission, and proposed `ADR-0041` for safe read/lifetime semantics.
None of those links accepts the other proposal. It does not define full
`ImageDescriptor`, metadata, provenance, pixel-padding, value-transform,
geometry or cache-key projections.

## References

- [Voxelia Project Foundation v0.1.1](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0039 - Closed storage capability and descriptor admission boundary](ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md)
- [ADR-0041 - Safe storage read transaction and type-erasure lifetime boundary](ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md)
- [RFC-0001 - Storage contract and logical data-model composition](../../rfcs/RFC-0001-storage-contract-and-logical-data-model-composition.md)
- [ADR-0040 logical-sample projection probe](../../progress/evidence/ADR-0040-logical-sample-projection-probe.swift)
