# Voxelia autonomous progress ledger

Last updated: 2026-08-03 (Asia/Kolkata)

## Goal

Complete Voxelia through its approved milestone roadmap with Apple-only platform discipline, diagnostic correctness, strict concurrency, provenance, validation evidence, and release-quality documentation.

## Current state

- Active implementation milestone: M1 - core data and spatial foundations.
- M1 implementation status: the first forty foundational slices, `ImageShape` /
  `ShapeError`, `ImageIndex`, `ImageRegion` / `RegionError`, and canonical
  scalar, component, image-semantic, semantic-version and measurement-unit
  models plus the initial typed spatial identifiers and canonical matrix
  representation, spatial-axis mapping, points, vectors, planes, rays,
  axis-aligned bounds, transform-kind taxonomy, coordinate handedness,
  external frame references, lookup-table descriptors, content-identity
  taxonomies, object identifiers, metadata privacy taxonomy and typed/erased
  metadata keys, neutral coded concepts, provenance vocabularies/identifiers,
  storage-kind/persistence taxonomies, codec identifiers, compressed-region
  access vocabulary, initial geometry/mesh taxonomies, validated geometry
  attribute descriptors, extent-based region construction and shape-aware
  region containment validation, checked region translation and deterministic
  shape clipping plus exact axis-aligned point-containment and bounds-
  intersection queries, exact shape/index and half-open region/index
  containment, explicit region emptiness and checked region element counts are
  implemented and locally verified.
- M1 supporting safety status: repository-owned executable Swift currently has
  no compiler-classified unsafe-memory, unsafe-compiler or concurrency-
  checking exceptions. A fail-closed, fixture-tested inventory and compiler
  gate enforces that state in the scaffold and security workflows. Strict
  product/test builds pass on macOS, iOS device/simulator and tvOS device/
  simulator; the unavailable visionOS 26.5 Xcode platform component remains an
  explicit evidence gap. Future exceptions require accepted authority, exact
  invariants, focused stress/lifetime evidence and independent review.
- Independently unblocked later-milestone declaration: the exact six-case
  `ResidencyPolicy` vocabulary is implemented in its owning `VoxeliaMetal`
  module without attaching allocation or capability behavior.
- Governance preparation: proposed `ADR-0021` documents the axis-model
  ownership conflict and recommends Spatial ownership with Core binding
  validation; it is not accepted and does not unblock implementation.
- Proposed `ADR-0022` selects a namespaced six-case `CoordinateConvention`
  shape and explicit type-level tags while preserving the separate descriptor
  unit-policy blocker; it is not accepted and does not unblock code.
- Proposed `ADR-0023` selects four common `ValueTransform` cases with validated
  linear and composition payloads while deferring undefined piecewise and
  lookup-execution behavior; it is not accepted and does not unblock code.
- Proposed `ADR-0027` replaces the cross-module frame-index reference with a
  Spatial-owned, full-rank `FrameAnchorIndex` and defines the minimum full-frame
  logical-anchor semantics needed for stable identity; it is not accepted and
  does not authorise source.
- The existing `MeasurementUnit` leaf now has coherent semantic identity and
  type-level encoding: exact UTF-8 namespace/code spelling, display-text-
  independent equality and hashing, signed-zero normalization, and an exact
  six-key explicit-null wire shape. This does not define unit conversion or
  coordinate-space unit admissibility.
- The recursive metadata model has been audited and remains source-blocked:
  proposed `ADR-0031` replaces its bypassable array/object payloads with
  validated bounded containers and a privacy-neutral nested object member.
  Proposed `ADR-0032` separately adds the required classified general entry,
  and Proposed `ADR-0033` adds the ordered collection plus explicit configured
  multiplicity admission. Proposed `ADR-0034` adds privacy-preserving closed
  exact-case typed reads. Proposed `ADR-0035` separately adds the versioned
  canonical-document and raw-ingress boundary, and Proposed `ADR-0036` adds a
  domain-separated SHA-256 identity for the exact complete canonical record,
  not semantic collection identity. The independently implemented metadata-key
  leaf uses exact accepted UTF-8 pair identity without claiming canonical-
  digest normalisation. None of the proposals authorises aggregate or digest
  source.
- Proposed `ADR-0028` selects a shared Core-owned `CanonicalInstant` for the raw
  metadata and provenance strings: one bounded uppercase zero-offset RFC 3339-
  derived profile, typed value-redacted errors and strict scalar-string Codable.
  It is not accepted and does not authorise source or either aggregate.
- Proposed `ADR-0029` selects a Core-owned `MetadataFloatingPoint` for the raw
  metadata `Double`: finite binary64 only, positive-zero canonical identity,
  exact preservation of every other finite bit pattern and scalar-number
  Codable without claiming canonical JSON bytes. It is not accepted and does
  not authorise source or the recursive metadata aggregate.
- Proposed `ADR-0030` selects a Core-owned `MetadataBinary` for the raw
  metadata `Data`: one owned `ContiguousArray<UInt8>` snapshot, exact ordered-
  byte identity and strict padded standard-Base64 scalar Codable. It assigns
  host-selected limits to raw and standalone-leaf ingress without inventing an
  intrinsic leaf cap; proposed `ADR-0031` separately bounds recursive
  embedding. Neither is accepted or authorises source.
- The raw metadata `String` audit retains `case string(String)`: every valid
  Swift string remains admissible. It recommends exact UTF-8 branch identity
  over Swift's canonical-equivalence relation; proposed `ADR-0031` accepts that
  candidate for the aggregate. A standalone wrapper and string-only ADR would
  add no invariant or independently implementable leaf; no source is
  authorised while the aggregate proposal remains unaccepted.
- Proposed `ADR-0031` selects privacy-neutral `MetadataArray` and
  `MetadataObject.Member`/`MetadataObject` wrappers, exact-key map ordering,
  strict one-tag Codable and hard ceilings of 64 container levels, 1,048,576
  logical structural elements and 64 MiB logical variable payload per
  recursive root. It remains Proposed, depends on `ADR-0028` through
  `ADR-0030`, requires supported-device ceiling evidence and does not authorise
  source.
- The existing `MetadataPrivacyClass` taxonomy now uses manual scalar-string
  Codable with fixed value-redacted failures. Rejected tokens, wrong-shaped
  input, arbitrary enclosing keys and unsafe underlying decoder errors are not
  retained in its diagnostic text or coding path; the five accepted raw values
  and their valid wire bytes are unchanged.
- Proposed `ADR-0032` adds a required `privacyClass` directly to every general
  `MetadataEntry`, scopes it over the key and whole recursive value, includes it
  in identity and strict three-field wire, and keeps host authorisation outside
  Core. It requires exact class preservation, forbids automatic aggregation,
  leaves `hostDefined` unresolved until trusted policy acts and does not
  authorise entry source.
- Proposed `ADR-0033` makes `MetadataCollection` an ordered immutable sequence,
  keeps ordinary construction/Codable unique-only and requires an explicit
  bounded immutable exact-key policy for repeats the caller asserts its schema
  permits. The policy is caller admission context rather than authenticated
  schema identity, is absent from value identity and wire, and grants no
  privacy permission. The proposal also adds collection-wide entry/work/payload
  limits and does not authorise source.
- Proposed `ADR-0034` maps only the eleven corrected `MetadataValue` payload
  types through concrete single/plural overloads. Reads return typed key/value/
  class projections, use cardinality-before-case precedence, preserve plural
  order and fail atomically without coercion. Arbitrary `MetadataKey<Value>`
  construction stays unchanged; unsupported types have no read overload. The
  proposal does not authorise source.
- Proposed `ADR-0035` selects `VCMJ-1`: one three-field schema envelope,
  exact out-of-band multiplicity-schema binding, decimal-string full-domain
  64-bit integers, JCS-derived string/floating/property rules, strict Base64
  and instant tokens, bounded ASCII schema-profile identifiers, iterative raw
  ingress plus four payload-free ingress and three emission failures. It
  deliberately preserves Unicode noncharacters, so it does not claim
  unmodified JCS/I-JSON. The universal canonical-document byte ceiling, vetted
  floating emitter/parser pair, Core/Spatial whitespace correction,
  cancellation/device evidence and recoverable allocation-failure evidence
  remain acceptance blockers; no codec source is authorised.
- Proposed `ADR-0036` selects one Core-owned complete-record identity tuple:
  SHA-256 over a length-framed domain containing explicit algorithm,
  `serialisedObject` scope, projection
  `org.voxelia.metadata-complete-record` version `1.0` and exact complete
  `VCMJ-1` bytes. It selects owned 32-byte storage and strict 64-character
  lowercase-hex coding, includes order/privacy/schema/presentation/unknown
  entries, excludes only the out-of-band policy snapshot and grants no schema
  trust, de-identification, export, MAC or signature authority. It deliberately
  does not define semantic `MetadataCollection` identity and authorises no
  source while its proposal and the metadata dependency chain remain
  unaccepted.
- Proposed `ADR-0037` selects a claim-bearing data-identity boundary downstream
  of `ADR-0036`: `objectID` plus at least one content, source or derivation
  claim; all seven non-empty content/source/derivation combinations; ordered
  source lineage with exact duplicate-locator rejection; and a closed
  non-recursive reference-case target whose wire and limits remain deferred. It
  keeps decoded claims separate from
  runtime assurance, makes lazy enrichment publish a new immutable snapshot
  only after a pinned-generation commit, and keeps derivation records separate
  from complete Execution result-cache keys. The proposal defines no image or
  parameter digest projection, trust Boolean, intrinsic cache authority by
  value presence, signature or export permission and authorises no source.
- Proposed `ADR-0038` selects the downstream closed provenance boundary: one
  exact subject, source-origin or complete operation-plus-execution activity,
  ordered role/occurrence-bearing data inputs, explicit flat local/external
  parent tags, complete-versus-compact graph states, iterative bounded
  transactional graph admission, claim/evidence separation, privacy-redacted
  diagnostics and one Execution-owned atomic output/identity/provenance/cache
  publication point. It reconciles Core claim-value ownership with the live
  dependency graph, defers Rendering-owned typed extensions and authorises no
  product source while time, identity, record-projection, persistent ID,
  execution-claim, warning, validation and resource-limit contracts remain
  Proposed or undefined.
- Proposed `ADR-0039` selects a Core-owned backend-neutral storage contract,
  Core-composed provider-lineage/descriptor/owner/snapshot/generation-bound
  callable operation witnesses, a closed ten-operation bit
  registry and fixed wire, tagged logical/representation descriptors, checked
  Core-private complete owned-read transaction, drain/alias accounting,
  representation claim/evidence separation and Metal-owned dynamic residency.
  It now defers builders to a separate accepted contract and records rather
  than settles the Foundation Phase-5 versus Requirements M1 mapped-provider
  conflict. It resolves the conceptual MTA/CDMS/RPSS ownership direction but
  authorises no source while the ADR/RFC, controlled corrections, logical
  projection, lifetime/erasure design, limits and reviews remain open.
- Proposed `ADR-0040` selects a representation-independent logical sample
  sequence: axis-zero-fastest indices, component-fastest ordinals and exact
  fixed-width big-endian decoded scalar bits. It removes byte order, valid-bit
  interpretation, component layout, strides and allocation padding from the
  logical binding; keeps source bit decoding, representation integrity and
  persistent content assurance separate; and stages a lossless pre-1.0 Core/
  Geometry migration. General component-role, pixel-padding and complete
  `ImageDescriptor` identity remain blocked. The proposal authorises no source.
- Proposed `ADR-0041` selects an immutable snapshot-bound complete region-read
  transaction, one synchronous cancellation/invalidation/commit gate,
  checked-`Sendable` single-witness erasure and synchronous owner-retaining
  `Data` owner scopes that derive `Data.span`/`Data.bytes` at the use site. It
  uses a Core-private exact-capacity monotonic fill target, keeps the frozen
  candidate outside authority state until exact commit, drains cancelled/stale
  provider work before releasing capacity, transfers a separate live-token
  byte budget into retained result ownership, safely recycles terminal
  tombstones, rejects stale/replayed/substituted completions and requires
  immutable direct mapped snapshots. The proposal explicitly records the
  Foundation-versus-Requirements mapped-storage milestone conflict and
  authorises no product source while the RFC, upstream proposals, controlled
  corrections, production limits, real mapping evidence and designated
  reviews remain open.
- Draft `RFC-0001` composes proposed `ADR-0039` through `ADR-0041` without
  accepting them. It preserves the `Core <- Storage <- Execution` dependency
  direction, separates logical binding/representation/operations/evidence,
  adopts the Core-private complete owned-read transaction, inventories 24
  controlled correction/disposition items and presents the Foundation Phase-5
  versus Requirements M1 mapped-provider conflict as a blocking governed
  choice. It recommends preserving the Foundation schedule but does not record
  approval, freeze final API/wire/limits or authorise any source.
- Draft companion `RFC-0001-CCD-01` expands `C01` through `C24` into proposed
  `0.1.2` targets, role-based owners/reviewers, exact correction text,
  cumulative gates and atomic application order. It preserves explicit branches
  for the mapping schedule and M1 structural-versus-M2 public `ImageData`
  staging choices; it amends no controlled baseline and closes no gate.
- RFC governance tooling now validates every file-backed primary RFC and
  controlled-correction companion, exact Draft/non-authority metadata,
  requirement provenance, the primary register, reciprocal live links, numeric
  allocation, the allocated companion and the ordered `C01`–`C24` crosswalk.
  It fails closed on non-Draft status until an approval schema is governed; a
  structural pass grants no approval or source authority. Named ownership and
  signatory enforcement remain external governance responsibilities.
- The complete `ImageDescriptor` closure has been audited field by field. Five
  of its eight direct field types are implemented, but axes, value transforms
  and every complete spatial-geometry path remain governance- or contract-
  blocked; no descriptor implementation is currently authorised.
- M0 local technical status: all host-supported build, test, documentation,
  resource and SBOM criteria pass; formal acceptance remains open for
  visionOS, external governance and human approvals.
- Local repository: the complete 283-file v0.1.1 scaffold is imported alongside the autonomous workflow files.
- Remote baseline: Google Drive folder `Voxelia_Repository_and_Package_Scaffold_v0.1.1`.
- Baseline status: the complete local M0 scaffold gate and every host-supported
  Apple platform criterion pass on the Apple Silicon host; formal M0 acceptance
  remains pending for the unavailable visionOS destinations, external
  repository governance, runner review and required human sign-offs.
- Host capability observed: Apple Silicon ARM64 macOS, Xcode 26.6, Swift 6.3.3.
- Automation: `Complete Voxelia autonomously`, active heartbeat every 15 minutes on this Codex task.

## M1 `ImageDescriptor` prerequisite matrix

Status in this matrix describes readiness for a public implementation. A
standalone prerequisite marked Implemented may still require descriptor-level
binding validation before `ImageDescriptor` can be constructed.

| Descriptor field | Direct type | Status | Remaining gate |
|---|---|---|---|
| `shape` | `ImageShape` | Implemented | Descriptor construction must use its rank when validating axes and geometry. |
| `scalarFormat` | `ScalarFormat` | Implemented | Semantic compatibility is descriptor-level; storage compatibility is deferred to `ImageData`/storage binding and must not cause descriptor construction to access storage. |
| `components` | `ComponentDescriptor` | Implemented | The semantic/component/scalar compatibility matrix is not fully specified. |
| `semantic` | `ImageSemantic` | Implemented | The detailed namespaced generic form is implemented; older MTA drift and descriptor-level consistency remain recorded. |
| `axes` | `ContiguousArray<AxisDescriptor>` | Proposed-dependent and contract-blocked | MTA ownership conflicts with CDMS/FVSP ownership; proposed `ADR-0021` is not accepted, and sampling/name/unit validation plus wire rules remain incomplete. |
| `spatialGeometry` | `SpatialGeometry?` | Proposed-dependent and contract-blocked | Coordinate-space policy, affine shape and tolerance, rectilinear binding, and the frame-index dependency cycle all remain unresolved. |
| `valueTransform` | `ValueTransform?` | Proposed-dependent | Proposed `ADR-0023` must be accepted and its controlled-document corrections completed before its bounded four-case declaration is authorised. Piecewise extension and lookup execution are explicitly later scope, not blockers to that declaration. |
| `units` | `MeasurementUnit?` | Implemented and conformance-hardened | The unit must describe authoritative sample values; semantic and transform compatibility policy is still required. |

The blocked axis and spatial branch expands as follows:

| Prerequisite | Implemented leaves | Blocking contract |
|---|---|---|
| `AxisDescriptor` | `AxisID`, `MeasurementUnit` | Proposed `ADR-0021` recommends Spatial ownership but does not authorise it. Direct enum payloads cannot enforce finite, non-zero regular spacing; origin/irregular-coordinate finiteness, generic and external string validity, categorical-label policy, duplicate-semantic support and descriptor binding are incomplete. |
| `CoordinateSpaceDescriptor` | `CoordinateSpaceID`, `CoordinateHandedness`, `ExternalFrameReference`, `MeasurementUnit` | Its implemented leaves now have coherent local identity and wire behavior, but proposed `ADR-0022` is not accepted. The descriptor still cannot classify physical versus logical Cartesian/custom/display spaces, so unit admissibility, handedness authority, external-reference ordering and construction errors remain incomplete. |
| `AffineGridGeometry` | `SpatialAxisMapping`, `Matrix4x4Double` | It depends on the blocked coordinate-space descriptor. MTA also uses fixed `SIMD3<Int>` axes while CDMS uses one-to-three `SpatialAxisMapping` entries. Affine-final-row validation has no declared tolerance; singularity and near-singularity policy separately block inverse operations. |
| `RectilinearGridGeometry` | `SpatialAxisMapping`, `Matrix4x4Double` | It depends on the blocked coordinate-space descriptor. Coordinate-count binding, monotonicity/coincident-sample policy, orientation and invertibility semantics are incomplete. |
| `FrameSetGeometry` | `SpatialAxisMapping`, `Matrix4x4Double`; Core-owned `ImageIndex` is implemented but unusable from Spatial | `FrameGeometry` depends on the blocked coordinate-space descriptor and contains Core-owned `ImageIndex`, which would reverse the approved `Core -> Spatial` dependency. Proposed `ADR-0027` supplies a role-specific replacement but is not accepted; frame-set ordering, sparse/enhanced coverage, identity, compatibility and regularity-result policies remain incomplete. |
| `SpatialGeometry` | None beyond its payload leaves | The aggregate cannot be declared safely until all three public payload contracts and their stable encodings are available. |

The descriptor also requires cross-field contracts that no individual field can
enforce:

| Binding area | Required decision or validation |
|---|---|
| Axis structure | Axis count equals shape rank; IDs are unique; irregular coordinates and categorical labels match the corresponding extent. |
| Sample semantics | Component interpretation/count, scalar domain and image semantic form a permitted combination. |
| Spatial binding | Mapped axes are in rank, geometry dimensionality is supported, and axis semantics agree with the geometry. |
| Authoritative values | `units` and `valueTransform` agree with each other and with the image semantic. |
| Stable identity | Canonical JSON still needs stable key and number forms, explicit tags, schema versioning, duplicate-key rejection, absent/null rules and non-finite policy. This blocks M1 canonical-serialisation and digest acceptance, not necessarily an earlier in-memory declaration after its type and invariant blockers are resolved; ordinary `Codable` round trips do not satisfy the byte-ingress boundary. |

Metadata, provenance, identity and storage are deliberately not fields of
the exact MTA/CDMS `ImageDescriptor`. FVSP section 18 nevertheless says the
accepted CT descriptor includes “technical metadata”; that is controlled drift
requiring correction or interpretation, not authority to add a silent ninth
field. The canonical metadata boundary is the later immutable `ImageData`
binding:

| `ImageData` dependency | Status | Boundary issue |
|---|---|---|
| `MetadataCollection` | Proposed-dependent and contract-blocked | `MetadataValue`, `MetadataEntry` and the collection are absent. Proposed `ADR-0028` through `ADR-0032` select validated leaves, a bounded recursive value and a required classified entry; Proposed `ADR-0033` selects ordered storage/configured multiplicity/aggregate limits, `ADR-0034` selects closed exact-case typed reads, `ADR-0035` selects the generic versioned canonical envelope/raw ingress and `ADR-0036` selects exact complete-record identity. None is accepted. Schema trust/resolution, custom conversion, semantic collection identity and production ceiling/parser evidence remain open. |
| `DataIdentity` | Proposed-dependent and contract-blocked | Proposed `ADR-0036` supplies a corrected scope/projection-bearing `ContentID` and one exact metadata-record profile. Proposed `ADR-0037` closes the claim-state lattice, duplicate/order rules, non-recursive reference target, assurance separation, lazy publication and cache-admission boundary. Both are unaccepted; exact source/operation identifiers, `DataObjectID` persistent identity, parameter/derivation/image projections, reference wire/limits, enrichment lifecycle and the complete derivation/cache-key split still block source. |
| `ProvenanceRecord` | Proposed-dependent, architecture- and contract-blocked | Proposed `ADR-0028` selects the `createdAt` leaf; Proposed `ADR-0036`/`ADR-0037` supply downstream identity-claim dependencies; and Proposed `ADR-0038` closes subject/activity/input state, Core-versus-Execution ownership, flat references, graph admission, evidence, diagnostics and publication conceptually. None is accepted. Exact persistent IDs, parameter/provenance projections, execution claim types, warnings, validation references, hard limits and canonical wires remain undefined, so no aggregate is authorised. |
| `AnyImageStorage` | Proposed-dependent, architecture- and contract-blocked | Proposed `ADR-0039` preserves `Storage -> Core` by assigning backend-neutral descriptors/protocols/erasure to Core and implementations/resources to Storage. Proposed `ADR-0040` separates decoded logical values/component ordinals from source bit interpretation and physical representation. Proposed `ADR-0041` supplies the complete owned-read transaction, checked erasure and owner-retaining scoped byte-access proposal without permitting `@unchecked Sendable`. All three are unaccepted; the public RFC, complete logical descriptor projection, controlled milestone/ownership corrections, production limits, actual mapping evidence and designated reviews still block source. |
| `ImageData` | Transitively blocked | Its exact five-field shape is consistent, but construction still needs accepted storage, identity and provenance boundaries, storage/logical descriptor compatibility, geometry/axis compatibility, metadata uniqueness and the Execution/host atomic publication contract. |

Conclusion: no independently implementable public leaf remains inside this
closure. Already safe leaves include `ImageShape`, `ScalarFormat`,
`ComponentDescriptor`, `ImageSemantic`, `MeasurementUnit`, `AxisID`,
`CoordinateSpaceID`, `CoordinateHandedness`, `ExternalFrameReference`,
`SpatialAxisMapping`, `Matrix4x4Double`, `ImageIndex` and
`LookupTableDescriptor`. Further work is governance and contract clarification,
not speculative source code.

## `CoordinateSpaceDescriptor` construction audit

The governed five-field declaration is cycle-free and all currently named leaf
types exist except the Proposed `CoordinateConvention`. A general validating
initializer is nevertheless a no-go under the current baseline:

| Area | Governed or conditionally settled behavior | Remaining blocker |
|---|---|---|
| Convention and handedness | Proposed `ADR-0022` says right-handed Cartesian, DICOM LPS and RAS imply right; left-handed Cartesian implies left; `.unspecified` is constructible but cannot satisfy an operation requiring resolved handedness; display/custom imply nothing. | `ADR-0022` is not accepted, and the constructor cannot rely on its matrix. |
| Unit domain | Ordinary physical spaces require a length unit and conversions must be explicit. | The five fields contain no physical/logical domain. Cartesian and custom conventions can describe either; `imageDisplay` has no governed pixel/point/normalized meaning. CDMS section 10.3's blanket length wording conflicts with section 21.6's ordinary-physical qualification. |
| Conversion metadata | `MeasurementUnit` preserves independently optional finite scale and offset without inference. | No canonical unit, affine conversion formula, scale/offset pairing rule, positive-scale rule or zero-offset spatial profile is approved. The neutral leaf must not invent one. |
| External references | References must be unique by exact namespace and identifier; an empty collection is permitted. A DICOM Frame of Reference UID belongs here, not source frame identity. | Input order versus semantic set identity, aliasing, primary reference and namespace-specific compatibility are not governed. Sorting or deduplication would silently choose identity semantics. |
| Encoding | An exact five-key outer type-level representation and constructor revalidation are mechanically possible. The nested `MeasurementUnit` representation is now exact and strict at its own keyed boundary. | Raw duplicate keys, lexical number/string forms, key order, schema envelopes, Unicode digest normalization and resource limits remain canonical byte-ingress work. |
| Compatibility | Equal coordinate-space IDs alone never prove transform equivalence. | Exact descriptor equality, external-frame compatibility and explicit-transform availability are distinct relations with no approved resolver contract. |

The audit exposed four direct conformance defects in the already implemented
`MeasurementUnit`: synthesized equality included human-readable `displayName`,
Swift `String` equality collapsed byte-distinct external codes, signed zero
could encode differently despite equal/hash-equivalent `Double` values, and a
closed coding-key enum accepted missing optional keys plus hid distinct extras.
The focused correction now:

- compares and hashes exact accepted UTF-8 `namespace` and `code` spellings;
- excludes `displayName` while including dimension, scale and offset in
  semantic declaration identity, following the existing `CodedConcept`
  presentation-text precedent;
- canonicalizes either conversion field's `-0.0` to `+0.0` at construction and
  decoding while preserving every other finite value; and
- requires exactly all six type-level keys, with explicit nulls for absent
  optional fields and constructor revalidation after decoding.

This is a defect correction to existing public promises, not a new conversion
policy or unit-policy decision. Equality does not establish compatibility or make
conversion metadata executable. Equal values may preserve different display
labels and therefore produce different ordinary `JSONEncoder` output; future
canonical descriptor digests must define their identity projection rather than
hashing ordinary type-level JSON blindly.

## M1 metadata-model prerequisite audit

`VoxeliaCore` ownership, the eleven `MetadataValue` cases and the one-field
`MetadataCollection` sketch are stable controlled inputs. The separate
two-field `MetadataEntry` sketch is not safe to publish because the same model
says metadata may carry a privacy class without attaching it. Proposed
`ADR-0031` selects the bounded recursive value, and Proposed `ADR-0032` corrects
the general entry to required `key`, `value` and `privacyClass` fields.
Proposed `ADR-0033` selects the collection's ordered content and explicit
multiplicity-admission boundary. Proposed `ADR-0034` selects closed exact-case
typed reads that retain classification. Proposed `ADR-0035` selects the
separate canonical-document and raw-ingress boundary. Proposed `ADR-0036`
selects the exact complete-record digest projection while explicitly leaving
semantic collection identity open. None is accepted. `VoxeliaCore ->
VoxeliaSpatial` is already an approved dependency, so the unit payload creates
no cycle, and `CodedConcept`, `AnyMetadataKey` and `MetadataPrivacyClass`
already exist in Core. The recursive aggregate, general entry and collection
are nevertheless a source no-go:

| Area | Governed requirement | Blocking contract |
|---|---|---|
| Floating point | Floating metadata must have an explicit non-finite policy; identity requires a NaN rule and signed-zero canonicalization. | Public `case floatingPoint(Double)` bypasses validation. NaN makes synthesized equality non-reflexive and permits two apparently identical set members; `-0.0` equals/hashes like `+0.0` but encodes differently. |
| Instant | The wire value must be a canonical UTC ISO 8601 string. | Public `case instant(String)` bypasses validation. Extended/basic form, mandatory `Z`, seconds, fractional precision, trailing zeros, calendar/year range, leap seconds and `24:00:00` are unspecified. |
| String | Generic text must preserve the supplied Unicode scalar sequence without silently choosing a namespace-specific equivalence. | The isolated audit retains raw `String` and admits every valid Swift string. Proposed `ADR-0031` accepts exact UTF-8 aggregate equality/hashing without a wrapper, but it remains unaccepted. |
| Binary | Binary metadata exists and canonical JSON must select base64 or hexadecimal. | Proposed `ADR-0030` selects an owned snapshot and strict padded standard Base64 without an intrinsic standalone cap. Proposed `ADR-0031` adds a hard logical payload ceiling only for recursive embedding; raw/token/leaf pre-allocation remains ingress policy. |
| Recursive arrays | Array order is naturally preserved. | Proposed `ADR-0031` replaces the raw payload with validated `MetadataArray`, preserves order and enforces depth, structural-work and logical-payload ceilings. The proposal and its numerical ceiling evidence remain unaccepted. |
| Objects | Object keys must be unique. | Proposed `ADR-0031` uses validated `MetadataObject` plus a privacy-neutral nested member, rejects exact-key duplicates and canonical-sorts unsigned UTF-8 namespace/name bytes. Proposed `ADR-0032` keeps that member distinct from the general entry; both remain unaccepted. |
| Collection multiplicity | Duplicate keys are rejected unless a namespace schema permits multiplicity. | Proposed `ADR-0033` keeps the context-free subset unique-only and admits repeats only through an explicit bounded exact-key policy snapshot supplied by a host/adapter. The snapshot is a caller assertion, not authenticated schema identity, and the proposal remains unaccepted. |
| Privacy | Metadata may carry `MetadataPrivacyClass`, and validation/logging/export must cover it. | Proposed `ADR-0032` selects a required direct attachment, no default/unclassified state, whole-entry scope, exact class identity and strict three-field wire. Proposed `ADR-0036` includes the exact class in complete-record identity but treats the digest as sensitive-derived and grants no authority. Both remain unaccepted; host resolver shape, versioned policy aggregation and logging/export authorisation remain future or host-owned decisions. |
| Typed access | Reads must match the requested type or return a typed error without coercion. | Proposed `ADR-0034` selects concrete overloads for the eleven exact corrected payloads, classified typed results, payload-free errors, cardinality-before-case precedence and ordered atomic plural reads. It remains unaccepted; custom/optional/default conversions stay deferred. |
| Type-level encoding | Value cases require explicit stable tags. | Proposed `ADR-0031` selects one-member externally tagged objects, strict payloads and sorted object-member arrays. It deliberately does not claim raw duplicate detection or canonical document bytes. |
| Canonical identity | Metadata included in an identity is ordered and uses canonical JSON. | Proposed `ADR-0036` names the exact `ADR-0035` bytes as a complete-record projection and selects domain-separated SHA-256 with explicit algorithm, `serialisedObject` scope, projection/version, owned 32-byte digest and strict lowercase hex. Presentation differences intentionally change this record ID even when Swift semantic equality does not; semantic collection identity remains separate. |
| Canonical ingress | Raw duplicate keys, stable lexical forms, schema versions and bounded untrusted input are mandatory. | Proposed `ADR-0035` selects `VCMJ-1`, a dedicated iterative canonical-only parser, exact schema-policy binding and coarse redacted errors. Its universal canonical-document byte cap, production floating codec, cancellation/device evidence and actual allocation-failure recovery remain unresolved; it is Proposed and authorises no source. |

Swift 6.3.3 probes confirmed that `ContiguousArray` supplies enough indirection
for the recursive shape to compile, but synthesis is not a safe contract:
`.floatingPoint(.nan)` is unequal to itself and creates two set members,
positive and negative zero encode differently, synthesized tags use `_0`,
distinct extra fields decode, raw duplicate JSON keys collapse before model
inspection, and hashing a 50,000-level tree trapped. Proposed
`ADR-0031` now supplies separately reviewed recursive containers and hard
anti-amplification ceilings. Proposed `ADR-0032` separately supplies the
required entry-privacy attachment, and Proposed `ADR-0033` supplies the ordered
collection and configured multiplicity-admission proposal. Proposed `ADR-0034`
supplies the closed typed-read proposal, and proposed `ADR-0035` supplies the
versioned canonical-document/raw-ingress proposal. Proposed `ADR-0036` supplies
only the exact complete-record digest proposal. None is accepted; schema trust,
operational host policy and semantic collection identity remain independent
rather than being folded into the value proposal.

The audit also exposed a bounded defect in the existing `MetadataKey<Value>`
and `AnyMetadataKey`: both preserve and encode opaque source spelling, while
synthesized Swift `String` equality collapsed canonically equivalent but UTF-8-
distinct namespaces or names. That could make object-key duplicate identity
disagree with the stored representation. Both key forms now compare and hash
their exact accepted UTF-8 namespace/name bytes, with field lengths included in
hashing. Namespace aliases remain schema/adapter policy, and future canonical-
digest Unicode normalization must explicitly reconcile its equivalence relation
with this exact in-memory identity.

## M1 canonical-instant prerequisite audit

The baseline gives two Core-owned raw strings the same semantic requirement:
`MetadataValue.instant(String)` must be canonical UTC ISO 8601, and
`ProvenanceRecord.createdAt: String` must be an absolute instant with canonical
UTC JSON. Three independent governance, standards and Swift implementation
audits agreed that one standalone leaf is coherent even though both aggregates
remain blocked. Proposed `ADR-0028` selects this review boundary:

| Area | Proposed version-one decision | Explicitly deferred |
|---|---|---|
| Ownership and consumers | Core-owned `CanonicalInstant`; after acceptance only, replace both raw strings with that type. | Complete `MetadataValue`, metadata collections and `ProvenanceRecord`. |
| Grammar | ASCII `YYYY-MM-DDTHH:mm:ss[.fraction]Z`; uppercase markers, mandatory seconds and no offsets or suffixes. | General ISO 8601/RFC 3339 parsing and implicit adapter conversion. |
| Calendar and clock | Proleptic Gregorian years 0001 through 9999, valid dates and a leap-unaware 86,400-labelled-second day with hours 00 through 23 and minutes/seconds 00 through 59. | Historical calendars, year zero, `24:00:00`, leap-event validation and UTC/TAI/GPS conversion. |
| Fraction | Absent or one through nine digits ending non-zero; whole seconds omit it, giving one decimal spelling per represented grid value. | Rounding, fractions beyond nanoseconds and source clock resolution/uncertainty. |
| Identity | Exact stored ASCII equality and hashing; constructor rejects aliases without normalization. | `Comparable`, arithmetic, clock capture and persistent digests. |
| Type-level encoding | One JSON string with decode-time constructor revalidation and a typed underlying error. | Schema envelopes, raw JSON escape canonicality, duplicate keys and whole-document bytes. |
| Implementation | Manual fixed-position UTF-8 parsing with typed component errors and no Foundation formatter or mutable state. | `Date` storage or an implicit `Date` bridge. |
| Limits and privacy | Accepted input is 20 or 22 through 30 bytes; scan stops on byte 31, and errors never echo the timestamp. | Pre-allocation document/string limits and logging/export policy. |

The nine-digit cap, minimal fraction, year-zero rejection and leap-unaware grid
are proposed project choices, not claims already present in the baseline.
RFC 3339 permits broader spellings; this profile deliberately rejects rather
than normalizes them. Swift 6.3.3 probes reinforced the boundary:
`ISO8601DateFormatter` is not `Sendable`, Foundation parsers accepted or
normalized invalid dates and `24:00:00`, the format-style parser also accepted
leap seconds, offsets and other aliases, and `Date` round trips lost the exact
nine-digit decimal value. Foundation may be an adapter or supplementary test
oracle, never the authoritative validator or storage.

`CanonicalInstant` therefore has no source implementation while `ADR-0028`
remains Proposed. Acceptance would authorise only the standalone leaf and the
two controlled declaration corrections, not the downstream aggregates or the
canonical byte-ingress layer.

## M1 floating-point metadata prerequisite audit

The baseline prescribes `MetadataValue.floatingPoint(Double)` but separately
requires floating metadata to choose a non-finite policy and floating identity
to resolve NaN, infinity and signed zero. Three independent governance,
standards and Swift implementation audits agreed that the raw associated value
cannot satisfy those rules by construction. Proposed `ADR-0029` selects this
review boundary:

| Area | Proposed version-one decision | Explicitly deferred |
|---|---|---|
| Ownership and consumer | Core-owned `MetadataFloatingPoint`; after acceptance only, replace the raw `Double` payload. | Complete `MetadataValue`, entries and collections. |
| Numeric domain | Accept every finite IEEE 754 binary64 value; reject all NaNs and both infinities with `.nonFiniteValue`. | Named exceptional values, decimal values, missing-value semantics and unit meaning. |
| Canonicalisation | Normalise either zero sign to positive zero; preserve every other finite bit pattern, including both signed subnormal ranges. | Arithmetic, tolerance comparisons, backend denormal policy and source conversion. |
| Identity | Exact canonical binary64 identity with reflexive equality and coherent hashing; no approximate tolerance and no persistent use of `hashValue`. | Canonical descriptor digests and cross-system identity bytes. |
| Type-level encoding | One numeric scalar, constructor revalidation and a typed underlying error at the current coding path. | Outer enum tags, canonical decimal spelling, schema envelopes and raw duplicate-key handling. |
| Privacy and limits | Wrapper-owned errors contain no rejected value or bit pattern; construction is fixed constant work. | Sanitising errors produced before wrapper validation and pre-allocation document, token, node and depth limits. |

Finite-only storage and signed-zero normalisation are Voxelia policy choices,
not IEEE 754 mandates. RFC 8259 excludes NaN and infinity from JSON numbers but
does not provide canonical number spelling; RFC 7493 supplies binary64-oriented
interoperability guidance; informative RFC 8785 JCS supplies compatible
finite-number precedent but has not been selected as Voxelia's serialiser.
Subnormals remain finite and are not flushed.

Swift 6.3.3 probes reproduced non-reflexive NaN equality, duplicate NaN set
members and equal/hash-equal signed zeros that `JSONEncoder` emitted as `0` and
`-0`. A strict-concurrency prototype preserved all finite values other than the
zero sign; a deterministic 20,000-pattern probe round-tripped 19,989 finite
patterns exactly, including subnormals. The probes also showed why the leaf
cannot claim canonical ingress: decimal tokens can round before construction,
and Foundation can reject out-of-range tokens before the wrapper while echoing
the token in its own underlying error.

`MetadataFloatingPoint` therefore has no source implementation while
`ADR-0029` remains Proposed. Acceptance would authorise only the standalone
leaf and controlled floating-payload correction, not the recursive model,
canonical serialiser or exceptional-value schema.

## M1 binary metadata prerequisite audit

The baseline prescribes `MetadataValue.binary(Data)` but separately leaves
direct `Data` permission open and requires canonical JSON to select Base64 or
hexadecimal. Three independent governance, standards and Swift implementation
audits agreed that direct storage cannot guarantee immutable byte identity and
that Foundation data coding strategies cannot define the wire contract.
Proposed `ADR-0030` selects this review boundary:

| Area | Proposed version-one decision | Explicitly deferred |
|---|---|---|
| Ownership and consumer | Core-owned `MetadataBinary`; after acceptance only, replace the raw `Data` payload. | Complete `MetadataValue`, entries and collections, plus adapter convenience APIs. |
| Storage and construction | Immutable `ContiguousArray<UInt8>` materialised from a generic byte `Collection`; no retained borrowed or no-copy storage. | No-copy Core construction, shared mutation and a Foundation type in the public shape. |
| Identity | Exact byte count and ordered sequence, including a valid empty value; source allocation, segmentation and text spelling are irrelevant. | Content typing, cryptographic identity, compression and constant-time comparison. |
| Type-level encoding | One strict standard RFC 4648 Base64 string with required padding, standard `+/` alphabet and zero unused bits. | Outer enum tags, schema envelopes, raw JSON escape spelling, key ordering and complete canonical document bytes. |
| Errors and privacy | Malformed semantic Base64 becomes value-redacted `DecodingError.dataCorrupted` at the current coding path; no public error is added because every programmatic byte sequence is valid. | Sanitising errors raised before wrapper validation, privacy attachment and host logging/export policy. |
| Limits | No fixed intrinsic standalone-leaf maximum; ingress applies host-selected raw-token and decoded-leaf limits, while proposed `ADR-0031` separately caps recursive logical payload. | Lower host profiles, pre-allocation enforcement and distributed payload policy. |

Standard padded Base64 is a Voxelia policy choice, not a JSON or RFC mandate.
It is more compact than hexadecimal and needs no URL-safe alphabet inside a
JSON string. Strict grammar is necessary because RFC 4648 permits applications
to decide how aggressively they reject noncanonical aliases, and permissive
Foundation decoding is not an identity validator. The type-level decoder still
cannot see a JSON escape alias or cap the source string before a general parser
allocates it.

Swift 6.3.3 probes confirmed that `Data` and `ContiguousArray<UInt8>` satisfy
strict `Sendable` checking and that ordinary `Data` is copy-on-write, but
`Data(bytesNoCopy:)` reflected a later external-pointer mutation. The changed
value could no longer be found in a populated `Set<Data>`, while a
`ContiguousArray` materialised before mutation retained its original bytes.
The default Foundation JSON data strategy emitted padded Base64, a configured
strategy emitted a byte array, and the Foundation Base64 decoder accepted both
surplus padding and non-zero unused-bit aliases.

`MetadataBinary` therefore has no source implementation while `ADR-0030`
remains Proposed. Acceptance would authorise only the standalone leaf and the
controlled direct-`Data`/Base64 corrections, not the recursive model,
canonical byte-ingress layer or resource-policy API.

## M1 string metadata prerequisite audit

The baseline prescribes `MetadataValue.string(String)` without a separate
string invariant. Three independent governance, Unicode/JSON and Swift audits
agreed that the associated-value shape is already sufficient: `String` is a
value-semantic, `Sendable` Unicode value, and every value in its programmatic
domain is admissible as a generic metadata payload. The unresolved defect lies
in aggregate identity, not construction. The audit therefore recommends these
candidate rules, subject to the future aggregate decision:

| Area | Audited candidate for the future aggregate | Explicitly deferred |
|---|---|---|
| Public shape | Retain `case string(String)`; add no `MetadataString`, public parser or string-specific error. | The complete `MetadataValue`, entry and collection declarations. |
| Admitted domain | Accept empty and whitespace-only strings, NUL and other controls, bidi/format controls, private-use and unassigned scalars, all 66 Unicode noncharacters and every other valid Swift `String`. | Namespace- or key-schema constraints such as non-empty, display-safe or terminology-specific text. |
| Preservation | Preserve the supplied Unicode scalar sequence without NFC/NFD/NFKC/NFKD normalisation, case folding, trimming, control removal or replacement. | Source encodings and ill-formed byte sequences, which are not representable by `String`. |
| Identity | Candidate: the `.string` branch compares exact UTF-8 byte count and ordered bytes and hashes its case discriminator, byte count and bytes. Canonically equivalent but differently encoded scalar sequences remain distinct. | Approval of the aggregate equality projection, plus schema-specific aliasing, search equivalence, locale comparison and canonical content digests. |
| Type-level encoding | The future tagged value encodes this payload as one JSON string and decodes one semantic string without normalisation. | Outer tags, raw escape spelling, schema envelopes, key order and complete canonical document bytes. |
| Malformed input | Candidate ingress rule: strict byte ingress or the underlying decoder rejects malformed UTF-8 and unpaired surrogates before aggregate construction; adapters do not repair source bytes silently. | Adapter/schema-specific preservation, a canonical raw parser and uniform sanitisation of errors raised before semantic decoding. |
| Privacy and presentation | The value itself makes no safe-display claim; errors and logs must not interpolate arbitrary text, and hosts must apply privacy classification plus sink-specific escaping. | Per-entry classification, bidi/log/terminal/UI policy and host export authorisation. |
| Limits | No intrinsic string maximum is invented. Raw token bytes, decoded UTF-8 bytes and aggregate string bytes must be host-bounded before allocation where possible. | Exact limit values, configuration API, scalar limits, recursion depth and aggregate node/entry totals. |

Primary traceability for this audit and the future aggregate decision is
`VOX-GOV-005`, `VOX-GOV-006`, `VOX-ARC-003`, `VOX-API-001`, `VOX-API-003`,
`VOX-API-004`, `VOX-META-001`, `VOX-META-002`, `VOX-ERR-001`,
`VOX-SEC-011` and `VOX-VAL-007`. The value-redacted diagnostic and logging
boundary also maps to `VOX-ERR-007` and `VOX-SEC-006`; `VOX-DAT-014` and
`VOX-DCM-003` are downstream consumers rather than authorisation for this
leaf or aggregate.

Swift's ordinary `String` equality uses Unicode canonical equivalence. That is
appropriate for general text but not for a metadata record that preserves both
the composed `café` scalar sequence and the decomposed `cafe` plus combining-
acute sequence as different serialised values. The repository already handles
the same mismatch inside `AnyMetadataKey`, `CodedConcept`, `MeasurementUnit`
and other owning types by comparing accepted UTF-8 directly. The recursive
`MetadataValue` would need approved custom, bounded equality and hashing if
this projection is selected, so its string branch can apply that rule
internally without adding a public wrapper whose only purpose is to override
`String` equality.

Under the recommended exact UTF-8 projection, identity begins after conversion
to a valid Swift `String`. JSON escape aliases such as a literal `é` and
`\u00e9`, or `/` and `\/`, correctly
decode to the same scalar sequence and identity. Composed and decomposed
sequences remain byte-distinct. Raw escape canonicality belongs to the future
canonical byte-ingress layer, not the semantic value.

RFC 8259 permits parsers to limit string size and content and warns that
unpaired surrogate escapes are not interoperable. I-JSON additionally forbids
decoded surrogate code points, including lone surrogate escapes, and
noncharacters; well-formed escape pairs representing supplementary scalars
remain valid. Voxelia has not selected I-JSON or JCS, so applying only that
profile's noncharacter prohibition at this context-independent leaf would
silently narrow source preservation. Unicode defines noncharacters as
well-formed code points that are not illegal in interchange, although they
have no standard external meaning. A future I-JSON/JCS admission or
canonicalisation boundary must reject them with a typed value-redacted profile
error, or a broader approved decision must change the value domain; it must not
delete or replace them silently. JCS remains useful precedent for preserving
parsed string data as-is and not applying Unicode normalisation.

Control and bidi characters are likewise data, not proof that text is safe for
a terminal, log, HTML, filename, query or user interface. Generic metadata
cannot choose one sink's escaping or display policy. Format adapters must
strictly decode valid source text rather than use a repairing conversion such
as `String(decoding:as:)`; how an adapter preserves malformed or intentionally
opaque source data remains a separate schema/format decision.

There is no standalone `MetadataString` implementation or string-only ADR. The
identity candidate is significant enough to resolve in the aggregate but has
no independent invariant, ownership boundary, migration or source slice.
Proposed `ADR-0031` now accepts exact UTF-8 string-branch identity as part of
the recursive algorithm that would enforce it. Until that proposal is accepted,
exact UTF-8 remains audit evidence rather than an authorised contract.

## M1 bounded recursive metadata-value prerequisite audit

The combined governance, Swift and wire audits established that the raw
recursive cases are unsafe even after the scalar leaves are corrected. Swift
does not permit a public enum case to have narrower access than its enum, so a
factory cannot prevent direct duplicate-key objects or excessive recursion.
Changing only equality and hashing to iterative traversals also leaves
arbitrary-depth recursive storage teardown unbounded. Proposed `ADR-0031`
therefore selects validated nominal payloads while preserving enum pattern
matching:

| Area | Proposed version-one decision | Explicitly deferred |
|---|---|---|
| Array shape | `case array(MetadataArray)`; one throwing generic-collection initializer, immutable `ContiguousArray` storage, empty valid and input order preserved. | Typed numeric arrays, flattening and standalone wrapper Codable. |
| Object shape | `case object(MetadataObject)` with privacy-neutral nested `MetadataObject.Member`; reject duplicate exact keys and canonical-sort namespace then name by unsigned UTF-8 bytes. | General `MetadataEntry` and `MetadataCollection`; Proposed `ADR-0032` separately selects the required direct entry attachment, while Proposed `ADR-0033` handles collection multiplicity without changing unique nested objects. |
| Hard safety | Container depth 64, 1,048,576 logical structural elements and 67,108,864 logical variable-payload bytes. Count repeated COW-shared subtrees per semantic occurrence and use checked arithmetic. | Lower host-selected document, token, leaf, entry and workload limits plus lowest-resource-device acceptance evidence. |
| Identity | Exact case tag and payload; arrays ordered; objects map-ordered; raw strings exact UTF-8; accepted instant/floating/binary leaves delegate to their contracts. | Canonical record/digest identity; unit/code presentation text remains preserved in Codable but excluded from semantic equality. |
| Traversal | Iterative depth-first equality and hashing with O(depth) cursor state; private cached metrics never enter identity or wire. | Persistent hash/digest, interning and private lookup indexing. |
| Type-level wire | Exactly one external tag from the eleven case names; object payload is a sorted array of strict `{key,value}` members; null, unknown/multiple tags and wrong shapes rejected. | Raw duplicate names, lexical integer/escape form, schema version, canonical document bytes and signatures. |
| Errors and privacy | Four payload-free typed errors for duplicate key and each hard limit; no key, value, unknown tag or recursive `self` in model-originated errors. | Proposed `ADR-0032` separately selects required whole-entry classification and exact preservation but is unaccepted; host policy, logging/export authorisation and upstream decoder sanitisation remain outside this value. |

Depth is the number of recursive containers: a leaf has depth zero, an empty
container has depth one and a nonempty container has one plus its deepest child
depth. Logical structural elements count every `MetadataValue` and object
member occurrence, not unique backing buffers. Logical variable payload counts
every occurrence of raw-string UTF-8, instant text, decoded binary, object-key
UTF-8 and all stored code/unit strings, including presentation fields.

The structural and byte ceilings are required because copy-on-write sharing
can amplify logical work without comparable resident storage. Repeatedly
wrapping `[value, value]` produces 1,048,575 logical value nodes at depth 19
and 2,097,151 at depth 20 with only twenty new container buffers. Repeating a
one-mebibyte string six times through the same binary pattern denotes 64 MiB of
logical payload. The wrappers charge every occurrence and reject the next
step. A standalone valid string or binary leaf keeps its uncapped leaf domain,
but a recursive container may reject embedding it; raw standalone admission
still belongs to the host.

Object order is non-semantic. The nested member avoids freezing the general
two-field `MetadataEntry` before privacy classification has an approved
attachment and wire contract. Exact-key uniqueness follows the already
implemented `AnyMetadataKey` identity, so canonically equivalent but UTF-8-
distinct keys remain different. Arbitrary metadata keys never become dynamic
JSON property names or diagnostic fields.

The tagged semantic wire uses `boolean`, `signedInteger`, `unsignedInteger`,
`floatingPoint`, `string`, `binary`, `instant`, `unit`, `code`, `array` and
`object`. Full `Int64` and `UInt64` values remain JSON numbers. A semantic
decoder may accept numeric aliases such as `1.0`, `1e0` or `-0`; canonical raw
ingress must select an exact lexical integer parser. Unmodified JCS cannot
round-trip the full unsigned range through its binary64 number model, so the
future canonical-byte decision must not silently narrow the controlled value
domain.

`ADR-0031` also reconciles the three Proposed leaf migrations: a leaf may enter
`MetadataValue` only after its own ADR and `ADR-0031` are accepted. Proposed
`ADR-0032` now supplies the separate entry-privacy contract, but remains
unaccepted; collections, operational host policy and canonical byte ingress are
still blocked on their own contracts. None is a prerequisite for reviewing the
privacy-neutral value. The proposed ceilings require focused boundary and
representative lowest-resource Apple-device evidence before acceptance, so no
Swift implementation is authorised in this increment.

Primary traceability is `VOX-GOV-005`, `VOX-GOV-006`, `VOX-ARC-003`,
`VOX-API-001`, `VOX-API-003`, `VOX-API-004`, `VOX-DAT-014`,
`VOX-META-001`, `VOX-META-002`, `VOX-ERR-001`, `VOX-SEC-001`,
`VOX-SEC-011`, `VOX-VAL-007`, `VOX-VAL-008` and `VOX-VAL-009`.
Value-redacted logging guidance additionally maps to `VOX-ERR-007` and
`VOX-SEC-006`.

## M1 required metadata-entry privacy-attachment audit

The controlled metadata model separately sketches a two-field general entry
and says metadata may carry one of five privacy classes. It does not attach the
class or define absence, defaults, nested scope, ordering, resolution, identity
or wire participation. Publishing that sketch would make an unclassified entry
public and require a later breaking third-field correction.

Proposed `ADR-0032` selects the smallest fail-closed entry boundary:

| Area | Proposed version-one decision | Explicitly deferred |
|---|---|---|
| Public shape | `MetadataEntry` stores `key`, `value` and required `privacyClass`; its initializer has no default, optional or two-argument overload. | `MetadataCollection`, typed access and convenience projections. |
| Authority | The declared class is a restriction signal, never logging/export permission. Wire labels are untrusted data; hosts own authorisation, purpose, destination, consent, declassification and audit. | Public resolver protocol, principal/destination model and audit storage. |
| `hostDefined` | Explicit unresolved host policy, distinct from absence and every concrete class. Unknown wire text never maps to it; disclosure fails closed without trusted resolution. | Portable custom policy identity, which the payload-free case cannot represent. |
| Recursive scope | One entry class covers both key strings and the complete recursive value subtree. `MetadataObject.Member` stays privacy-neutral and has no implicit entry conversion. | Independently classified nested members and mixed-policy object schemas. |
| Preservation and aggregation | No `Comparable`, ordering or inferred aggregate class. One-to-one library transformations preserve the exact declaration; multi-input aggregation preserves entries separately, requires an explicit trusted-host output class or fails typed and payload-free. | A governed policy schema, public resolver and policy-specific aggregation rules. |
| Identity and wire | Declared class participates in equality/hash. Codable requires exactly `key`, `value`, `privacyClass`; missing, null, extra, unknown and wrong-shaped fields reject. | Raw duplicate detection, canonical bytes and persistent scientific/content identity. |
| Diagnostics | Entry-originated errors use fixed model-relative field paths and contain no caller key, rejected token, metadata value or arbitrary underlying decoder error. | Sanitising failures raised before model decoding or inside host policy. |

There is no unclassified entry state. An optional `nil` would invent a sixth
state outside the controlled taxonomy and overlap the explicitly unresolved
purpose of `hostDefined`. No classification is a safe default: `publicData`
could disclose, `technical` and `sensitive` invent source meaning, and
`hostDefined` would silently turn omission into accepted unresolved policy.

The taxonomy defines no total or partial privacy order. Its case names mix data
categories and handling obligations, so replacing two declarations with a
supposedly more restrictive case can erase information. Library-owned one-to-one
transformations preserve the exact class. Generic multi-input operations retain
entries separately, require the trusted host to supply an explicit output class
under versioned policy with applicable provenance/audit, or fail typed and
payload-free.

`hostDefined` remains declared and unresolved through generic library
operations. Because the entry carries no policy identity, generic code preserves
such inputs separately or fails; a concrete replacement is an explicit audited
host reclassification. A public value cannot prevent its owning host from
constructing a lower-class record, so the proposal prohibits implicit library
reclassification without overclaiming system-wide enforcement.

Classification applies to the entire key/value record, including nested member
keys, array elements and retained code/unit presentation strings. A bare value
or member has no disclosure permission. Mixed-policy data remains separate
general entries where schema permits or receives one explicit host-classified
outer entry; Core cannot reconstruct labels after callers discard them into
privacy-neutral members.

Ordinary Codable is representation, not export authorisation. Default library
logs omit arbitrary keys and values for every class, including `publicData` and
`technical`. A host policy must decide destination and purpose before
disclosure; unresolved policy fails closed. Collection-level reject/filter/
redact behaviour remains a later API decision.

FHIR security-label guidance supports attaching a label to the complete
resource and evaluating it in a separate trust/policy framework. DICOM
confidentiality guidance likewise treats nested sequence content under its
enclosing protected attribute and warns that de-identification is
context-dependent. Apple OSLog privacy remains a separate sink-specific
mapping. These are design precedents, not claimed conformance or vocabulary
mappings.

The current `MetadataPrivacyClass` manual decoder already supplies fixed
value-redacted failures without changing successful wire. The Proposed entry
itself depends on still-Proposed `ADR-0031`; no `MetadataEntry` source or
controlled-document migration is authorised.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-ARC-003`, `VOX-API-001`, `VOX-API-003`, `VOX-API-004`,
`VOX-API-010`, `VOX-DAT-014`, `VOX-META-001`, `VOX-META-002`,
`VOX-ERR-001`, `VOX-ERR-007`, `VOX-SEC-006` and `VOX-VAL-007`.

## M1 ordered metadata-collection and multiplicity-policy audit

The controlled collection sketch stores one `ContiguousArray<MetadataEntry>`
and rejects duplicate keys unless a namespace schema explicitly permits
multiplicity. It defines no schema type, identity, version, resolver, trust
rule or decoding path. The collection bytes therefore cannot authenticate
their own repeat permission, while permanently rejecting every repeat would
silently remove a governed valid state.

Proposed `ADR-0033` selects an explicit context split:

| Area | Proposed version-one decision | Explicitly deferred |
|---|---|---|
| Content and identity | One immutable ordered entry sequence; preserve every occurrence and exact input order. Equality/hash include the complete ordered entries and their privacy classes, but exclude admission policy and derived indexes. | Schema-normalised or order-insensitive projections and persistent digest identity. |
| Context-free path | Ordinary construction, encode and decode are unique-only. Any second exact key rejects, even when value or privacy class differs. A duplicate-bearing value fails ordinary encoding before output. | Permissive defaults or inference from wire data. |
| Multiplicity context | `MetadataMultiplicityPolicy` is a bounded immutable finite allow-list of exact keys. Unlisted keys remain unique-only; no callbacks, globals, task locals or `Decoder.userInfo` participate. | Portable schema identity/version, registry lifecycle, resolver protocol and namespace-specific key equivalence. |
| Authority | A host/adapter supplies a snapshot after performing its external schema selection. Core does not verify that claim. The snapshot is a caller assertion for one operation, not authenticated schema proof, an access-control capability or logging/export permission. | Authentication, distributed schema binding and host authorisation policy. |
| Configured Codable | Foundation configuration-aware encode/decode carries the explicit snapshot without serialising it. Configured encoding revalidates the complete collection under that exact policy before writing. | Automatic propagation through ordinary parent `Codable` values and canonical document envelopes. |
| Hard safety | At most 1,048,576 entries and aggregate structural elements, plus 64 MiB aggregate logical key/value payload. Policy input is independently capped at 1,048,576 key occurrences and 64 MiB exact UTF-8 key payload, all with checked `UInt64` arithmetic. | Lower host limits and production acceptance until supported-destination and lowest-resource-device evidence exists. |
| Privacy | Retain each occurrence and exact class, including `hostDefined`; infer no aggregate privacy class. Default errors/logs omit keys, values, classes, counts, indices, gaps, duplicate cardinality and policy content. | Host-authorised reject/filter/redact/export behavior and structural-disclosure policy. |
| Typed cardinality | A future single read fails payload-free for missing, multiple or type mismatch; a future multi-read preserves order and validates every match without coercion or dropping mismatches. Proposed `ADR-0034` supplies the concrete closed mapping/result/error surface if accepted. | Optional/default queries, custom semantic conversion and privacy-authorised reads. |
| Type-level wire | Exactly `{"entries":[...]}`. Both decode paths reject missing, null, distinct-extra and wrong-shaped fields. Outer/field-set errors use a fixed empty path; entry payload/invariant errors use fixed `entries`, never an entry index or caller path. | Raw duplicate JSON members, lexical/canonical bytes, schema-version binding and signatures. |

The policy is intentionally not stored in collection identity or encoded bytes.
That keeps validation context from masquerading as portable authority, but it
also means a repeat-bearing value has no context-free ordinary Codable round
trip. A future distributed envelope must bind an authenticated schema
identity/version and supply a compatible policy during configured decoding.

Collection ceilings are separate aggregate contracts, not inherited proof
from the recursive value proposal. Repeated copy-on-write-shared values are
charged for every semantic occurrence, and the outer key bytes are charged for
every entry. The numerical values align with `ADR-0031` for reviewability but
remain acceptance-blocked until destination and representative device evidence
exists.

The checked-in strict Swift 6 probe verifies the configuration-aware Foundation
surface, ordered identity, unique-only default path, explicit exact-key repeat
admission, policy absence from wire, wrong-policy revalidation, small analogue
limits, strict fields and diagnostic redaction. It is architectural evidence,
not product source, authenticated-schema evidence or approval of the production
ceilings. No recursive metadata, entry or collection source is authorised while
`ADR-0028` through `ADR-0033` remain Proposed; no typed-read source is authorised
while `ADR-0034` remains Proposed.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-ARC-003`, `VOX-API-001`, `VOX-API-003`, `VOX-API-004`,
`VOX-API-010`, `VOX-DAT-014`, `VOX-META-001`, `VOX-META-002`,
`VOX-ERR-001`, `VOX-ERR-007`, `VOX-SEC-001`, `VOX-SEC-006`,
`VOX-SEC-011`, `VOX-VAL-007`, `VOX-VAL-008` and `VOX-VAL-009`.

## M1 closed exact-case typed metadata-read audit

The controlled documents require typed access without coercion but store only
an erased key/value pair. `MetadataKey<Value>` carries no runtime witness, and
the raw sketch makes both generic text and instants `String`. Current source
also permits every `Sendable` specialisation, including `Double`, without
claiming that Core can extract it. A concrete mapping is therefore new proposed
authority rather than an implementation detail hidden in the generic key.

Proposed `ADR-0034` selects a closed, privacy-preserving boundary:

| Area | Proposed version-one decision | Explicitly deferred |
|---|---|---|
| Mapping | Twenty-two concrete overloads: single and plural reads for the eleven exact corrected payloads `Bool`, `Int64`, `UInt64`, `MetadataFloatingPoint`, `String`, `MetadataBinary`, `CanonicalInstant`, `MeasurementUnit`, `CodedConcept`, `MetadataArray` and `MetadataObject`. | `Double`, `Data`, `Date`, native containers, optionals, protocol existentials, application types and semantic aliases. |
| Conversion | Direct enum-case pattern matching returns the exact associated payload. No casts, parsing, numeric conversion, bridging, flattening, Codable route, callback, registry or public converter protocol. | A separately reviewed closed projection witness if generic algorithms later demonstrate need. |
| Current keys | `MetadataKey<Value: Sendable>` fields, initializer, pair identity and phantom-only layout remain unchanged. Unsupported specialisations have no read overload and fail at compile time. | Restricting key construction or adding a runtime unsupported-type error. |
| Result | `TypedMetadataEntry<Value>` retains the requested typed key, exact payload and each occurrence's exact `privacyClass`; it has no public initializer, Codable, identity or safe-display surface. | Typed writes, bare-value convenience and persistent typed-result wire. |
| Single read | Count all exact-key matches before inspecting cases: zero → `missingValue`, more than one → `multipleValues`, exactly one wrong case → `typeMismatch`. | First/last/matching-case selection, optional/default reads and `try?` semantics. |
| Plural read | Zero → empty; otherwise preserve collection occurrence order and every class. Preflight every case and fail atomically on any mismatch without publishing a valid prefix. | Filtering, grouping, deduplication, aggregate privacy and partial results. |
| Key identity | Match both fields by exact accepted UTF-8 bytes, never native `String ==`, Unicode normalisation, aliases, schema lookup or hash alone. | Namespace equivalence and authenticated schema semantics. |
| Authority and privacy | Reads accept no multiplicity/privacy policy and prove only exact pair+case. They never authorize access, logging, export, declassification or `hostDefined` resolution. | Host principals, purpose/destination policy, filtered disclosure and audit. |
| Diagnostics | One non-generic payload-free `MetadataReadError`; no key, type, case, value, class, exact count/index/order, policy or underlying error. Read operations emit no logs. | Host-authorised diagnostics; even coarse outcomes may be sensitive. |
| Performance | Linear in entries plus compared UTF-8 key bytes: single uses one scan and O(1) auxiliary memory; plural uses a preflight scan plus a materialisation scan and one compact O(matches) result. No index in version one. | A private immutable exact-key ordered-position index after differential memory/performance evidence. |

Returning a bare payload was rejected because it would detach the class from a
library-owned projection. The typed result keeps the whole key/value/class
relationship, including all five classes and unresolved `hostDefined`, while
remaining unsafe for raw interpolation or reflection. The accessor is
mechanical lookup, not privacy policy.

Concrete overloads were preferred over an unconstrained generic function or
public protocol. Swift public protocols are not sealed, loose casts admit
existentials, closures are not `Hashable` and a key-stored discriminator would
change the current key contract. Unsupported keys remain constructible for
other type-level uses but cannot accidentally call a read API.

The focused Swift 6 probe resolves both overload families for all eleven cases,
preserves all five classes/order, checks cardinality-before-case precedence,
empty plural reads, late atomic plural mismatch, exact UTF-8 non-aliasing and
payload-free error rendering. A compile-negative configuration proves
`MetadataKey<Double>` has no exact read overload. These are isolated shape and
semantic checks, not product source or implementation authorisation.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-ARC-003`, `VOX-API-001`, `VOX-API-003`, `VOX-API-004`,
`VOX-API-010`, `VOX-DAT-014`, `VOX-META-001`, `VOX-META-002`,
`VOX-ERR-001`, `VOX-ERR-007`, `VOX-SEC-006`, `VOX-SEC-011` and
`VOX-VAL-007`.

## M1 versioned canonical metadata JSON and raw-ingress audit

The controlled model requires canonical JSON but leaves the exact library and
cross-system digest algorithm open. Type-level `Codable` cannot establish raw
canonicality: the focused Apple Swift 6.3.3 negative controls confirmed that
Foundation collapses duplicate and escape-equivalent member names, accepts
integer aliases, accepts a BOM, emits negative zero/noncanonical exponent forms
and does not supply RFC 8785 property ordering for every non-BMP name.

Proposed `ADR-0035` selects a separate record profile without changing
ordinary type-level Codable:

| Area | Proposed `VCMJ-1` decision | Acceptance or later work |
|---|---|---|
| Envelope | Exact `documentSchema`, required nullable `multiplicitySchema` and `payload`; fixed document identifier `org.voxelia.metadata-document`, version `1.0`; successful decode retains all three in `CanonicalMetadataDocument`. Schema/profile identifiers use a bounded 255-byte lowercase ASCII reverse-domain grammar. | Future minors require explicit lossless compatibility; unknown structural fields/tags reject. |
| Multiplicity trust | `null` is context-free unique-only. A non-null reference identifies a whole-document immutable profile and must exact-match caller context containing the expected reference and an already bounded `MetadataMultiplicityPolicy`; bytes never carry the allow-list. Emission uses the symmetric complete preflight. | Hosts/adapters still own profile composition, schema selection, resolution, authentication and lifecycle. |
| Integers | Canonical-document `.signedInteger`/`.unsignedInteger` payloads are minimal decimal JSON strings parsed with checked arithmetic, preserving full `Int64`/`UInt64`. | Ordinary type-level Codable remains numeric; the two surfaces must be named distinctly. |
| Floating values | Finite `MetadataFloatingPoint` and unit conversion fields use RFC 8785/ECMAScript shortest-round-trip binary64 spelling; negative zero emits `0`; canonical tokens are analytically at most 25 bytes under a 32-byte ceiling. | Separate vetted Ryu/V8-compatible emission and correctly rounded roundTiesToEven decimal-parser oracles, RFC vectors and random-bit cross-platform differential corpora are required. |
| Unicode | Exact decoded scalar/UTF-8 identity, no normalisation, RFC 8785 escaping/property ordering and preservation of valid Unicode noncharacters. Nonblank metadata identity fields use one enumerated stable whitespace set rather than toolchain `isWhitespace`. | Because I-JSON rejects noncharacters, the profile is accurately JCS-derived rather than claimed as JCS/I-JSON. The dependency correction broadens known multi-scalar grapheme edge cases and needs compatibility fixtures before acceptance. |
| Binary and instant | Strict padded standard Base64 with zero pad bits and the exact proposed canonical-instant ASCII form; escape aliases reject. | Both semantic leaf ADRs must be accepted first. |
| Order | JSON properties follow decoded UTF-16 order; fixed v1 names are ASCII. Metadata-object tuple order, collection occurrence order and array order remain semantic. | Persistent digest normalisation, if any, requires a separate projection decision. |
| Raw parser | Dedicated iterative incremental UTF-8 scanner/state machine; no Foundation/DOM first boundary; raw duplicates reject after unescaping; publication is atomic after EOF, validation and cancellation. | Complete parser, chunk-split, mutation/fuzz, cancellation and memory-pressure evidence remain acceptance work. |
| Limits | Inclusive, compute-guard-commit ingress limits now have fixed raw-token, decoded string, Base64, direct-count, depth and aggregate units; emission has a distinct exact canonical-output-byte limit and invalid-value-before-sizing order. Actual generated worst-case structure reaches raw JSON depth 198. One additive operation-wide counter fixes a 4,096-work-unit cancellation polling bound. | The universal unrestricted raw-document/output ceiling derivation, release-device cancellation benchmark, approved allocator-failure disposition and lowest-device memory evidence remain open. Lower caps are local admission/emission policy, not another canonical profile. |
| Diagnostics/privacy | Four payload-free ingress and three payload-free emission errors; byte-order precedence and non-cancellation chunk invariance are explicit. No source path/token/version/count/class/policy/underlying error or parser log. The whole raw document is sensitive before classification, and every exact class survives. | Timing/coarse error oracles, host throttling, schema trust, disclosure policy and zeroisation remain outside the guarantee. |
| Identity/export | Bytes are unique for the complete document-schema/profile-reference-or-null/collection tuple and preserve presentation fields excluded from semantic equality; the policy remains validation context, not record content. | No hash, content ID, signature, privacy filter or export permission is implied. |

The focused probe exercises Foundation as a negative control, full integer
extrema/aliases, exact UTF-8/noncharacter preservation, the frozen whitespace
oracle, canonical control escapes, strict Base64 pad bits, bounded ASCII schema
identifiers, exact schema-policy binding, symmetric emission preflight, checked
budget arithmetic, an actually generated depth-198 structure and payload-free
errors. It is deliberately a reduced evidence program, not a raw parser,
floating emitter/parser, policy-budget proof, product API or source
authorisation.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-ARC-003`, `VOX-API-001`, `VOX-API-003`, `VOX-API-004`,
`VOX-API-010`, `VOX-CON-006`, `VOX-CON-007`, `VOX-DAT-014`,
`VOX-META-001`, `VOX-META-002`,
`VOX-ERR-001`, `VOX-ERR-003`, `VOX-ERR-007`, `VOX-SEC-001`,
`VOX-SEC-003`, `VOX-SEC-006`, `VOX-SEC-011`, `VOX-VAL-007`,
`VOX-VAL-008`, `VOX-VAL-009` and `VOX-VAL-011`.

## M1 complete canonical metadata record-identity audit

The controlled architecture assigns content identity to Core but prescribes
two incompatible `ContentID` shapes. The MTA uses typed `DigestAlgorithm` plus
Foundation `Data`; the CDMS uses an arbitrary algorithm `String` plus
`ContiguousArray<UInt8>`. Both displayed records omit the scope that CDMS says
must be present. Neither identifies the canonical projection, specifies digest
length/text, or makes the payload-free `.custom` case satisfy its required
namespaced approved identity.

Proposed `ADR-0036` resolves only the exact complete VCMJ record boundary:

| Area | Proposed complete-record decision | Acceptance or later work |
|---|---|---|
| Meaning | Exact complete canonical metadata record identity, never an implied semantic `MetadataCollection` identity. | A semantic/presentation-free or schema-normalised identity needs a separately named projection and justification. |
| Record | Core-owned `ContentID` carries typed algorithm, scope, bounded versioned projection reference and owned contiguous digest bytes. No unchecked public initializer. | Public API/data-model RFC, controlled MTA/CDMS correction and maintainer approval remain mandatory. |
| Profile | Exact tuple `sha256` / `serialisedObject` / `org.voxelia.metadata-complete-record` version `1.0`. Only compiled reviewed tuples are executable. | SHA-512, exact BLAKE3 mode/output and custom namespaced algorithm profiles remain separate approvals; no downgrade negotiation. |
| Coverage | Exact complete `VCMJ-1` bytes include document schema, multiplicity reference/null, order, privacy, presentation text and unknown retained entries. | The out-of-band policy snapshot stays validation context; the digest does not authenticate the claimed profile or supplied policy. |
| Framing | SHA-256 receives a 109-byte big-endian length-framed domain header binding magic/version, algorithm, scope, projection/version and payload count before exact VCMJ bytes. | Any framing or payload-selection change requires a new projection version; raw SHA-256 remains only a negative control. |
| Storage/wire | Exactly 32 owned bytes; exactly 64 lowercase hexadecimal characters in the manual type-level wire. No `Data`, Base64, array, uppercase, prefix, separator, truncation or inference alias. | A standalone portable Content-ID document still needs its own schema envelope and raw duplicate/lexical boundary. |
| Equality | Algorithm, scope, projection/version and all digest bytes participate. Direct fixed-byte comparison uses the platform timing-safe comparator after public discriminators. | Swift `Hasher`, `hashValue`, ordinary Codable bytes and dictionary lookup have no persistent or timing-safe claim. |
| Streaming | CryptoKit SHA-256, checked payload/frame counts, bounded updates and at most 4,096 work units between cancellation checks; final check before atomic publication. | Unknown-length raw streams require an already approved replayable bounded source or validated re-emission. This proposal selects no disk spool; any spool is separate future work. Full parser, device, cancellation, memory and fault evidence still depends on `ADR-0035`. |
| Privacy/security | Digest is sensitive-derived and an equality/dictionary oracle. No log, telemetry, filename, cross-tenant dedupe, export, schema trust, de-identification, MAC, signature or encryption authority. | Hosts own disclosure, cache partitioning, privacy/export policy, schema authenticity, signatures and keys. |

The exact frame is independently reproducible. For the 148-byte empty VCMJ-1
document, raw SHA-256 is
`a27e896af6381de3cf78c5b4166851b601b6461d9e2503935b32ab4d6811ee50`,
while the proposed domain-framed digest is
`8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432`.
CryptoKit and Python's standard SHA-256 implementation produced the same
framed value.

The focused strict Swift 6 probe covers the SHA-256 `abc` vector, exact empty-
record goldens, algorithm/scope/projection framing, bounded chunk invariance,
owned digest storage, strict lowercase hex, timing-safe first/middle/last-byte
negative comparisons, checked frame arithmetic, selected cancellation points,
payload-free errors and exact record mutations. Presentation-only code/unit
changes prove why the record ID is not semantic equality; order, privacy,
multiplicity-reference, unknown-entry and exact-UTF-8 changes prove the
complete-record coverage; two different out-of-band policies prove only their
intentional absence from the preimage, not policy trust.

The probe is not a VCMJ parser/emitter, complete cryptographic validation,
production API, supported-device matrix, allocation-failure proof or source
authorisation. Proposed `ADR-0028` through `ADR-0036`, the public RFC,
controlled-document reconciliation and `ADR-0035` acceptance evidence remain
mandatory before implementation.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-ARC-003`, `VOX-API-001`, `VOX-API-003`, `VOX-API-004`,
`VOX-API-010`, `VOX-DAT-014`, `VOX-RGN-007`, `VOX-RGN-008`,
`VOX-RGN-009`, `VOX-META-001`, `VOX-META-002`, `VOX-META-011`,
`VOX-CON-006`, `VOX-CON-007`, `VOX-ERR-001`, `VOX-ERR-003`,
`VOX-ERR-007`, `VOX-SEC-001`, `VOX-SEC-003`, `VOX-SEC-006`,
`VOX-SEC-011`, `VOX-VAL-007` and `VOX-VAL-011`.

## M1 source, derivation and data-identity authority audit

The controlled documents permit a large object to begin with source or
derivation identity but do not define how the optional fields form a complete
record or when a claim becomes verified/cache-admissible. They also reference
an undefined `DataIdentityReference`, and the displayed derivation record omits
dimensions required by the governed Execution result-cache key.

Proposed `ADR-0037` records the conservative closure:

It also requires controlled Requirements correction: `VOX-RGN-007` gains a
provisional versioned source alternative, and `VOX-RGN-008` distinguishes that
source-backed data identity from a full logical-content projection over data
bytes, descriptor semantics and relevant transforms. A structurally valid
source-only record does not satisfy M2 cache/provenance behavior until a host
admits that exact source for the stated purpose and policy context.

| Area | Proposed boundary | Deferred or owning work |
|---|---|---|
| Completeness | `objectID` plus at least one content, non-empty source or derivation claim; the object-only combination is invalid and every non-empty combination is structurally valid. | Whether successful identity enrichment preserves `objectID` remains an explicit lifecycle decision. |
| Claims and assurance | A decoded/constructed `ContentID`, source content ID, locator or provenance edge is a claim. Generated/locally verified content and host-attested source are separate runtime evidence. | Host policy owns provider authentication, tenant/privacy/security domain, purpose, policy version, expiry and revocation. No serialised `trusted` Boolean is permitted. |
| Sources | Nonblank bounded exact strings are required in principle; locator identity is exact accepted UTF-8 `(namespace, identifier, version)`. Caller order is retained as lineage-record order. Repeated locator keys fail, including conflicts with different content claims. | Exact byte ceilings/grammar are not selected. Acquisition/spatial order remains separately named. A source content scope need not equal the top-level logical-data scope. |
| Derivation | Input order and repeats are preserved; empty input is allowed only for a declared generator. Exact record comparison includes build metadata. A derivation claim is not a cache key or proof of determinism. | Operation/implementation identifiers, canonical parameter and derivation-record projections, named roles and exact public record remain deferred. The VCMJ projection is invalid for parameter identity. |
| References | The target is an explicit closed non-recursive one-of: object, content, source or future canonical derivation-record ID. Object-only is local/resolved lineage, not a persistent/distributed cache key. | `DerivationRecordID`, exact tagged wire, aggregate limits, resolver and lifecycle are undefined, so the public type remains blocked. |
| Lazy publication | Work binds object, pinned immutable snapshot and exact projection. Only a final generation/snapshot recheck may publish a new immutable claim snapshot plus assurance. Separately accepted cache/provenance contracts may conditionally stage their own side effects; digest completion alone does not authorise them. | Storage supplies snapshot-consistent reads; Execution owns single-flight work, cancellation, determinism, cache key and commit coordination. Failure, mismatch, cancellation or staleness publishes nothing. |
| Cache | Admission explicitly prefers verified content, deterministic derivation with independently verified input content identities/full execution key, then versioned host-attested source. Keys are kind- and tenant/privacy/security-domain-separated. | Persistent format versioning, atomic storage, integrity verification, eviction, revocation and complete M2 concurrency/fault evidence stay with Storage/Execution/host policy. |
| Scope/security | `serialisedObject`, `storageObject`, `compressedRepresentation`, `sampleBytes` and future `descriptorAndSamples` claims are not interchangeable. Digests and locators are sensitive-derived, not authentication or de-identification. | Image identity, checksums, integrity/validation axes, MACs, signatures, keys, schema trust and export authority remain separate decisions. |

The focused Swift 6 probe closes all eight content/source/derivation state
combinations, source duplicate/conflict and order behavior, exact UTF-8
negative controls, source-versus-data scope separation, ordered/repeated/zero-
input derivation behavior, build-metadata-sensitive exact derivation equality,
explicit reference admission, exact execution-key-bound derivation evidence,
object/snapshot/policy-domain-bound verified-content evidence, one-at-a-time
changes to every required execution/cache discriminator and atomic lazy
publication under both externally selected `objectID` lifecycle fixtures.
Existing-claim conflicts, cancellation, failure, mismatch, stale generation
and snapshot change all leave identity, assurance, cache alias and provenance
success counts unchanged.

This is isolated evidence only. Proposed `ADR-0036` and `ADR-0037`, their
controlled MTA/CDMS/Requirements corrections, the public RFC,
identifier/reference/projection
decisions and supported-device/concurrency evidence remain mandatory. No
identity aggregate or cache implementation is authorised.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-ARC-003`, `VOX-ARC-004`, `VOX-ARC-005`, `VOX-API-001`,
`VOX-API-003`, `VOX-API-004`, `VOX-API-010`, `VOX-DAT-014`,
`VOX-RGN-007`, `VOX-RGN-008`, `VOX-RGN-009`, `VOX-CON-001`,
`VOX-CON-006`, `VOX-CON-007`, `VOX-CCH-004`, `VOX-CCH-005`,
`VOX-CCH-007`, `VOX-CCH-008`, `VOX-ERR-001`, `VOX-ERR-002`,
`VOX-ERR-003`, `VOX-ERR-007`, `VOX-SEC-006`, `VOX-SEC-011`,
`VOX-VAL-007` and `VOX-VAL-011`.

## M1 provenance record and graph-admission authority audit

The controlled provenance sketch is not an implementable aggregate. It places
independent optional operation and execution values beside an undefined
`ProvenanceReference`, undefined execution-profile/backend/approximation and
warning-severity types, unrestricted warning/evidence/deprecation strings and
an unbounded raw creation-time string. It does not bind the record to its
output data identity or state how input identity, role and parent topology
relate.

The architecture assigns immutable provenance values to Core while assigning
execution provenance and assembly to Execution. The live graph is
`Execution -> Storage -> Core -> Spatial`; Core importing live Execution,
Storage or Validation types would create a cycle. Three independent read-only
audits converged on the same ownership split and confirmed that no product
aggregate or undefined leaf is safely authorised.

Proposed `ADR-0038` records the conservative closure:

| Area | Proposed boundary | Deferred or owning work |
|---|---|---|
| Ownership | Core owns immutable backend-neutral claim values and pure bounded validation; Execution owns live capture, assembly, cancellation/generation and atomic publication; Storage owns persistence/resolution/integrity; Validation/host own evidence, trust and policy. | No package edge changes. Core-neutral profile/backend/precision/quality/capability/kernel/approximation claims need accepted exact shapes before source. |
| Subject and activity | Every record binds one exact output `DataIdentityReference`. `.source` is an origin with no operation/execution/input; every other current kind requires one complete operation-plus-execution claim and at least one input. Partial operation/execution combinations are invalid. | Zero-input generators need an explicit registered contract. Kind semantics, source/output reference wire and all upstream identity dependencies remain Proposed. |
| Inputs | An ordered input carries a unique `(role, occurrence)`, exact data-identity reference and optional parent record. The same input/parent may occupy distinct slots; no sorting, inference or silent deduplication occurs. | Operation-owned role grammar/limits and exact `DataIdentityReference` are unresolved. A resolved parent's subject must match its exact input identity under an explicitly selected comparison profile. |
| References | Parent cases are explicitly tagged and non-recursive: a same-snapshot graph-node ID or an external ID plus exact provenance-record content claim. Repeated unresolved external IDs must agree on both content and expected subject. Complete provenance is a flat node table, never recursive record embedding. | Current `ProvenanceID` lacks bounded exact-byte persistent semantics. No canonical provenance-record projection or strict tagged wire exists; `ADR-0036`'s metadata projection is not reusable. |
| Graph admission | Complete mode rejects every missing parent. Compact mode may retain bounded unresolved external references but cannot claim global acyclicity; their separate cap counts input-edge occurrences, while zero explicitly disables them. Iterative visit-once validation rejects duplicate/conflicting IDs, duplicate slots, self/two-/multi-node cycles, mismatched parent content/subject, unrelated nodes outside the exact root closure and node/edge/depth/byte overflow transactionally. Replacement also checks a bounded retained ID registry and rejects changed exact values even after an ID leaves the current root closure. Its immutable owner-selected lifetime cap is separate from per-snapshot limits; exhaustion publishes nothing and evicts nothing. | Production hard ceilings require hostile-input, cancellation, allocation and lowest-resource supported-device evidence. External resolution uses a pinned owner snapshot and reruns admission before replacement while retaining its resolver revision. Durable retention/deletion semantics remain Storage/governance work. |
| Exact identity | Exact record comparison includes every stored field, order, warning occurrence and all five semantic-version fields. Node ID, canonical record content ID, recipe/derivation identity and graph evidence remain distinct. | Live `SemanticVersion ==` ignores build metadata while coding preserves it, so future records need exact comparison or an exact version-record type. Canonical record/manifest envelopes remain M9 work. |
| Warnings | Future portable warnings use bounded namespaced machine codes, a closed interpretation severity, explicit occurrence/affected input, typed classified arguments and deterministic order. Exact duplicate structured warning keys fail. Fatal conditions are typed failures. | `WarningSeverity` is undefined. Arbitrary `message` text is not authorised in portable Core provenance; host-rendered/classified detail needs a separate contract. |
| Validation | Decoded validation cases remain claims. Runtime assurance separately binds evidence/content, operation/implementation, parameters, profile/backend/precision, capability/shader, release, policy, expiry and revocation. Deprecation is an independent lifecycle axis. | Evidence and lifecycle references, trust, revocation and exact wire remain undefined. `deprecated(reason:)` and arbitrary `evidenceID` strings are source-blocked. |
| Privacy/security | Provenance and its IDs/digests are sensitive-derived. Core errors/descriptions are payload-free and redacted; Core emits no logs/telemetry. Signed manifests remain a separate host-trust contract and signatures prove only signer-controlled bytes. | Host owns storage/log/export/cross-tenant policy, retrieval, credentials, keys, trust anchors and authorisation. Rendering and photorealistic provenance need typed content-addressed extensions owned by their downstream modules, not Core dependencies or untyped blobs. |
| Publication | Execution stages output, exact identity, admitted provenance root/graph, separately authorised assurance and cache alias, then commits once after final success/cancellation/generation/snapshot/subject checks. This single-output contract requires exactly one graph root. Verified output-identity evidence and owner-held assurance/cache contexts bind the exact record value, admitted graph, purpose, output and policy. Every failure path publishes nothing. | Storage must not invent execution claims. Failure/attempt audit events are separate host records; cache hits require independent owner evidence for the stored exact output/identity/graph and read policy. Multi-output publication needs an explicit output-to-root map. |

The focused strict Swift 6 probe uses deliberately small non-production limits.
It covers the closed input/operation/execution lattice, denial of every
currently undeclared zero-input generator, hard-capped limits, exact UTF-8
identity and build-metadata-sensitive record
equality, subject/activity/kind completeness, role order, duplicate slots and
warnings, explicit local/external tags, repeated-external content/subject
consistency, parent content/subject binding, complete versus compact graphs,
exact root closure, duplicate/conflicting IDs, disconnected cycle detection,
depth/node/edge/byte/checked-overflow limits, visit-once diamond behavior and
transactional graph replacement under current or historical ID conflict,
lifetime-history exhaustion, cycle, cancellation and a pinned resolver
revision.

It also proves that a serialised diagnostic-ready claim remains unassured until
matched exact-record evidence is supplied, that validation and deprecation can
coexist as independent axes, that optional attached assurance is still checked
against an owner-held purpose context, and that cache publication/read paths
require bound owner evidence. Cancellation, failure, target removal, stale
generation/resolver/snapshot, output-identity mismatch, missing, cross-purpose
or changed-record assurance, an unmapped extra graph root, changed-graph or
cross-policy cache evidence, unauthorised cache publication and duplicate
completion leave the entire output/provenance/cache state unchanged. Sensitive
sentinel values do not appear in value/error descriptions, reflection or
`dump` output.

This is isolated evidence only. It is not product API, a canonical parser or
emitter, cryptography, a resolver/store, a signature system, a validation
package or production limit/device proof. Proposed `ADR-0028`, `ADR-0036`,
`ADR-0037` and `ADR-0038`, controlled corrections, the public RFC, exact
identifier/reference/projection/execution/warning/evidence decisions and
maintainer reviews remain mandatory. No provenance aggregate, graph builder or
publication integration is authorised.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-GOV-009`, `VOX-GOV-010`, `VOX-ARC-001`, `VOX-ARC-003`,
`VOX-ARC-004`, `VOX-ARC-005`, `VOX-API-001`, `VOX-API-003`,
`VOX-API-004`, `VOX-API-010`, `VOX-DAT-014`, `VOX-RGN-007`,
`VOX-RGN-008`, `VOX-META-003` through `VOX-META-011`,
`VOX-EXE-002` through `VOX-EXE-004`, `VOX-EXE-006`, `VOX-EXE-007`,
`VOX-EXE-009`, `VOX-EXE-011` through `VOX-EXE-016`, `VOX-CON-001`, `VOX-CON-006`,
`VOX-CON-007`, `VOX-CCH-004`, `VOX-CCH-005`, `VOX-CCH-007`,
`VOX-CCH-008`, `VOX-ERR-001` through `VOX-ERR-003`, `VOX-ERR-005`,
`VOX-ERR-007`, `VOX-SEC-006`, `VOX-SEC-010`, `VOX-SEC-011`,
`VOX-VAL-007`, `VOX-VAL-010`, `VOX-VAL-011`, `VOX-VAL-016`,
`VOX-REL-005`, `VOX-PER-007`, `VOX-VS1-017` and `VOX-VS1-019`.

## M1 storage capability and descriptor-admission authority audit

The MTA assigns storage protocols/type erasure to Core and concrete providers
to Storage. CDMS instead assigns descriptors, capabilities, protocols, erasure
and region reading to Storage. Because Core-owned `ImageData` embeds the
erasure while the live graph is `Storage -> Core -> Spatial`, the CDMS
placement would require a prohibited reverse dependency.

The displayed capability sets also drift (`writable` versus
`writableBuilder` plus CDMS-only `prefetch`/`contentDigest`), and neither
source assigns bits, exact coding, unknown handling or implications. The base
protocol mandates full region reads while also advertising random/sequential
flags without a sequential session. `StorageDescriptor` references an
undefined integrity descriptor and lacks base/component strides, exact
representation coverage, packing, overlap and byte-order closure. The builder
both accepts and says it creates provenance.

Three independent read-only audits converged on the same source gate: no
descriptor, capability, protocol, builder or erasure aggregate is independently
authorised. Proposed `ADR-0039` records the conservative closure:

| Area | Proposed boundary | Deferred or owning work |
|---|---|---|
| Ownership | Core owns backend-neutral values, protocols, destination contract, pure admission and erasure; Storage owns providers/builders/resources; Execution or an explicit host/import coordinator owns atomic `ImageData` publication; Metal owns residency; host owns locators/auth/privacy/transport. | Existing Storage-owned taxonomy leaves remain unchanged until an accepted pre-1.0 migration. No package edge changes. |
| Capability layers | One Core-admitted nonforgeable provider-lineage authority is composed with the provider-supplied exact descriptor/owner/snapshot/generation and retained callable witnesses; the mandatory M1 history-independent region witness, optional operations, runtime results and external assurance remain separate. | Neither caller nor provider can inject, clone or replace Core authority from labels or requested bits. The in-process identity prevents confused-authority substitution; it is not external authentication or persistent/distributed identity. Genuine sequential access needs a later actor/session contract. Capability presence is never evidence, locality, verification, residency or diagnostic status. |
| Optional operations | Proposed bits 0–9 are scoped contiguous bytes, mapped representation, builder acquisition, region enumeration, native tile, native brick, compressed representation, resolution levels, prefetch hints and scoped digest. Known mask is `0x3ff`. | Public raw `OptionSet` is rejected. Representation/locality/persistence/residency remain typed facts. Later bits do not claim later milestones. |
| Wire | Exact v1 bytes are `{"schemaVersion":1,"bits":"0000000000000000"}` with sixteen lowercase hex digits, fixed order and no extra syntax. Reserved bits/future versions fail closed. A separate bounded opaque envelope preserves genuine future bytes without acting. | No synthesised `Codable`, JSON numeric `UInt64`, bit masking or best-effort subset interpretation. |
| Descriptor | A tagged logical binding plus decoded-strided or opaque representation separates full logical count, addressed span and initialized representation length. Organization, origin/locality, backing/provider mechanism, persistence and resolution are orthogonal. | Physical byte order/component layout must be removed from logical identity or normalized exactly. Exact locator/callback/transport contracts, packed storage, tile/brick grids and opaque codec details need later tagged contracts. |
| Layout | Admission checks bounded rank/extents, component/scalar support, base offset, exact stride rank, positive strides, interleaved/planar component rules, conservative non-overlap, checked span, length, alignment and byte order. | Probe `UInt64` arithmetic is not source shape. Product unsigned ingress must fit controlled `Int` and host limits before conversion. Production ceilings need device/hostile-input evidence. |
| Reads | Region is bound to the exact storage shape. Core allocates one private exact-capacity packed-interleaved target, retains its one-shot seal/authority and gives the provider only a bounded monotonic fill capability. The provider returns an outcome; Core closes the fill, stamps the prepared record and publishes one complete owned result only after exact commit. | Equal-label providers cannot substitute bytes. Old bytes cannot be retagged or replayed. Short/overrun/invalid coverage, cancellation, failure, mismatch, substitution, replay or stale current-required generation publishes no bytes. Caller-owned async destinations and unsafe/no-copy implementations remain blocked. |
| Integrity | A claim binds snapshot/generation, projection/version, algorithm-sized digest, an exact non-recursive claim-free representation-descriptor projection and initialized coverage. A trusted verifier computes over exact bytes; its restricted evidence retains and revalidates the exact provider-instance binding. An authority-owned current policy snapshot controls expiry/revocation; evidence remains separate. | Structural claims carry no runtime provider authority. Claims cannot move to a same-length different descriptor, and callers cannot mint evidence with supplied digest/labels/booleans. Representation padding/encoded bytes may affect representation integrity; canonical logical samples exclude physical layout/padding. Neither proves provenance, authenticity or diagnostic validity. |
| Builder/publication | The exact provider witness issues an actor-isolated builder bound to source provider-instance/descriptor/owner/snapshot/generation, bounded non-overlapping complete regions and immutable staged bytes. Per-write cancellation is retryable; explicit transaction cancellation is terminal. Provider-revalidated one-shot freeze mints a distinct unpublished target snapshot/generation and returns it with exact source authority; source authority remains part of target identity. | Equal textual target labels or ordinals from distinct providers cannot collide. Storage does not accept/create provenance or return `ImageData`. Incomplete, terminally cancelled, failed, short, substituted or stale state exposes no frozen snapshot; stale state is not replayable. |
| Lifetime/residency | A view retains its actor owner and generation; reads return owned snapshots. Dynamic CPU/shared/GPU residency is per-device Metal state. | No pointer/token comment, textual owner ID or `@unchecked Sendable` is accepted as lifetime evidence. Mapping/prefetch does not imply residency. |

The focused strict Swift 6 probe uses deliberately small non-production limits.
It covers exact bits/wire, incremental oversized ingress rejection, the
explicitly narrow fixed-width non-operational future-capability envelope and
the earlier ADR-0039 provider/descriptor/owner/snapshot/generation witness
model, capability conflicts, a bounded
resolution-count
characteristic with operational level access denied, conservative strided layouts,
stride-overflow and cross-shape substitution denial, separated logical/request
limits, checked decoded-strided region gathering into canonical packed
destinations, the earlier destination-issued request-seal/provider-completion
model with equal-label cross-provider substitution denial,
redacted bounded byte values, CryptoKit SHA-256 over exact retained
representation bytes, structurally provider-instance-bound restricted evidence,
same-authority policy snapshots, complete
non-overlapping builder partitions, retryable write versus terminal transaction
cancellation, distinct frozen target bindings including equal-label peer
providers with different staged bytes, owned staging, non-replayable
stale generation, owner-retaining views, bounded generic sequences and exact
redacted value/actor diagnostics.

Resolution-level access remains source-gated until M5 supplies per-level
representation/layout and spatial-correspondence evidence. The ADR's milestone
split is a proposed controlled correction, not an override: current M1
`ImageData`, residency-capability and builder-return requirements remain
authoritative until the controlled documents are accepted together.

This is isolated evidence only. It uses toy bytes, an actor-backed fixture
provider and CryptoKit SHA-256; it is not product API, canonical storage wire,
a production provider or integrity implementation, complete cryptographic
validation, unsafe/no-copy access or production device/limit proof. The
identity token is an in-process fixture, not external authentication, a
globally stable identifier, canonical wire or a production authority-capability
design. Proposed `ADR-0037` through `ADR-0040`, controlled corrections, the
public RFC, complete logical descriptor projection, exact destination/erasure
lifetime design and designated reviews remain mandatory. No storage aggregate
or protocol is authorised.

Proposed `ADR-0041` and Draft `RFC-0001` refine that older read fixture: Core,
not the destination or provider, owns the authority/seal/fill/commit gate and
stamps completion after the provider returns only an outcome. The ADR-0039
probe remains evidence for its narrower historical model and is not evidence
for the production admission factory, owned-read transaction or mapping.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-GOV-009`, `VOX-GOV-010`, `VOX-ARC-001`, `VOX-ARC-003`,
`VOX-ARC-004`, `VOX-ARC-011`, `VOX-API-001`, `VOX-API-003`,
`VOX-API-004`, `VOX-API-005`, `VOX-API-007`, `VOX-API-010`,
`VOX-DAT-004`, `VOX-DAT-010`, `VOX-DAT-011`, `VOX-DAT-013` through
`VOX-DAT-015`, `VOX-RGN-001` through `VOX-RGN-004`, `VOX-RGN-006`,
`VOX-STO-001` through `VOX-STO-012`, `VOX-CON-003`, `VOX-CON-006`,
`VOX-CON-007`, `VOX-CON-010`, `VOX-ERR-001`, `VOX-ERR-003`,
`VOX-ERR-007`, `VOX-SEC-001`, `VOX-SEC-002`, `VOX-SEC-006`,
`VOX-SEC-011`, `VOX-BRK-002`, `VOX-BRK-005` and `VOX-VS1-018`.

## M1 normalized logical-sample and representation-projection audit

The controlled model requires canonical logical identity to ignore endian
order, component arrangement, strides, compression and physical padding, but
the live Core leaves place `byteOrder`, `validBitCount` and `layout` inside
synthesised descriptor equality and ordinary coding. The prior storage probe
gathers checked physical scalar bytes without endian normalization, so it is
representation/read evidence rather than a logical-identity oracle.

Three independent read-only audits covered controlled authority/live source,
projection implementation shape, and numerical/security/cache/provenance
failure modes. They converged on the source gate recorded by proposed
`ADR-0040`:

| Area | Proposed boundary | Deferred or owning work |
|---|---|---|
| Layers | Core logical binding, adapter source-bit interpretation, exact Storage representation and persistent claim/evidence are distinct. | Equal labels, byte counts or one digest never transfer authority between layers. The live package graph does not change. |
| Logical scalar | One exact decoded `ScalarType`; integers use fixed-width signed/unsigned bits and binary floats use exact interchange bits in the sample sequence. No arithmetic occurs. | Numeric conversion, value transforms, units, colour conversion and approximate equality are separate operations/projections. Complete image semantics may reject non-finite samples even though the narrow exact-bit sequence can preserve them. |
| Order | Indices enumerate with axis zero fastest under an exact ordinal formula and components enumerate by logical ordinal at each index. | The proposal treats current component names as presentation coding only through an RFC and controlled CDMS correction, not as persistent roles. General colour/vector/tensor/complex/probability role identity remains blocked; a toy RGB fixture proves only ordering mechanics. |
| Representation | Explicit endian, base/axis/component strides, initialized length and a complete physical-to-logical component permutation decode to canonical most-significant-byte-first logical values. | A valid permutation cannot prove truthful semantic labelling; adapter/provider evidence remains required. Packed/storage-defined layouts need later tagged contracts. |
| Valid bits | `validBitCount` is not logical identity or decoding authority. A source integer contract also needs field position, signedness, byte/bit order, unused-bit policy and extension result; direct M1 normalization accepts full-width decoded values. | M4 DICOMKit/codec work produces sign-extended `Int16` or zero-extended `UInt16` and preserves Bits Stored/High Bit in source metadata/provenance. Floating valid bits and guessed packing reject. |
| Padding | Initialized allocation/stride/plane/halo padding is representation-only and skipped by logical enumeration; representation integrity may cover it. | Pixel padding is semantic unavailable-value metadata/policy, never allocation padding or a quantitative replacement. Complete image identity remains unavailable until an accepted typed validity/padding projection binds it. |
| Identity | The candidate `org.voxelia.logical-sample-sequence` `1.0` payload is exact but not standalone; logical and representation hash domains are length-framed and non-substitutable. The label/version remains unregistered evidence-only and cannot be used as `ContentID`. | Full `descriptorAndSamples` identity still needs canonical complete `ImageDescriptor`, component roles, pixel-padding validity, `ADR-0036`/`ADR-0037` claim/evidence and atomic publication. Raw bytes, Swift `Hasher` and ordinary Codable are not persistent identity. |
| Bounds/diagnostics | Raw unsigned counts fit `Int.max` and stricter limits before conversion; every product, offset, span and byte count is checked. Failures are typed and payload-free; samples, names, paths and digests are redacted. | Production ceilings, streaming/cancellation cadence, hostile-input/device evidence, safe destination/erasure lifetime and designated reviews remain open. |
| Migration | Introduce lossless explicit logical/representation projections first; preserve every current Core/Geometry field or fail ambiguity. Deprecate and remove misplaced physical fields only through a documented later 0.x correction. | Proposed status changes no live API or wire. The RFC, controlled MTA/CDMS/RPSS/Requirements correction and downstream Geometry review are mandatory. |

The focused strict Swift 6 evidence probe uses toy limits, tags and CryptoKit
SHA-256. It exercises little-endian interleaved, big-endian planar and padded
physical-BGR representations of one exact logical RGB fixture; an exact rank-
three/two-component axis-zero-fastest golden; exact region enumeration; padding
mutation; component-map/order failures; exact ordered signed/unsigned 12-in-16
source extraction including nonzero offsets and dirty unused bits; valid-bit/
packing rejection; all binary float bit classes without numeric conversion;
checked platform-`Int`, count, address and length failures; distinct sample-
layout, toy descriptor-bearing and representation domains; concurrent
immutable normalization; and exact redacted diagnostics. It is not product
API, canonical content-ID/descriptor wire, a general semantic component
profile, production source decoder/storage or diagnostic validation.

Primary traceability is `VOX-GOV-003`, `VOX-GOV-005`, `VOX-GOV-006`,
`VOX-GOV-009`, `VOX-GOV-010`, `VOX-ARC-001`, `VOX-ARC-003`,
`VOX-ARC-004`, `VOX-ARC-007`, `VOX-ARC-012`, `VOX-API-001`,
`VOX-API-003`, `VOX-API-004`, `VOX-API-007`, `VOX-API-010`,
`VOX-API-011`, `VOX-DAT-001`, `VOX-DAT-004`, `VOX-DAT-009` through
`VOX-DAT-015`, `VOX-RGN-001` through `VOX-RGN-004`, `VOX-RGN-006`
through `VOX-RGN-008`, `VOX-STO-001` through `VOX-STO-004`,
`VOX-STO-007` through `VOX-STO-011`, `VOX-CON-003`, `VOX-CON-006`,
`VOX-CON-007`, `VOX-CON-010`, `VOX-ERR-001`, `VOX-ERR-003`,
`VOX-ERR-007`, `VOX-SEC-001`, `VOX-SEC-002`, `VOX-SEC-006`,
`VOX-SEC-011`, `VOX-VAL-007`, `VOX-VAL-016`, `VOX-DCM-003`,
`VOX-DCM-005`, `VOX-DCM-006`, `VOX-DCM-008`, `VOX-DCM-010`,
`VOX-DCM-013`, `VOX-IMG-001`, `VOX-IMG-002`, `VOX-IMG-009`,
`VOX-IMG-015`, `VOX-META-001`, `VOX-META-002`, `VOX-META-011`,
`VOX-VS1-005`, `VOX-VS1-006`, `VOX-VS1-008`, `VOX-VS1-014`,
`VOX-VS1-019` and `VOX-VS1-020`.

## M1 diagnostic, security, concurrency and validation supporting-surface audit

The controlled M1 schedule contains one error requirement, two security
requirements and two concurrency requirements. No `VOX-VAL-*` requirement is
newly due at M1: `VOX-VAL-001` is the continuing M0 test-level scaffold, and
`VOX-VAL-002` through `VOX-VAL-016` target M2 or later. Two independent
read-only audits mapped those requirements to current Core source and tests,
the live package graph and Accepted authority before source selection.

| Family | Current accepted evidence | Disposition |
|---|---|---|
| `VOX-ERR-001` | The controlled `DataModelError` sketch is implemented exactly, while `ShapeError`, `RegionError` and other specialised typed errors carry the invalid-data behavior already exercised by focused Core tests. | This is invalid-data evidence only. Allocation, live storage-capability, cancellation, backend, shader and convergence failure paths do not yet exist in their owning layers or remain behind Proposed contracts. Expanding a speculative global error enum is not authorised. |
| `VOX-SEC-001` | `ImageShape` validates positive external extents and checked element-count multiplication. `ImageRegion` validates ranks, bounds, containment, translation, subtraction and accumulated count arithmetic with focused boundary tests. | Stride, byte-offset, allocation-size and memory-access closure requires the blocked storage/descriptor/read contracts. Current checks support but do not complete the requirement. |
| `VOX-SEC-002` | Host strict-memory builds of product and test targets, the available Apple destination matrix, manifest/configuration checks and the explicit empty inventory found no compiler-classified unsafe construct, Swift `unsafe` marker, SwiftPM unsafe flag or weakened compiler-safety setting. | The advisory always-green workflow inventory is replaced by a deterministic fail-closed repository gate. The visionOS platform-component gap prevents treating supported-destination evidence or full M1 acceptance as complete. |
| `VOX-CON-003` | Current canonical Core descriptors are immutable checked-`Sendable` values, strict Swift 6 mode is enabled and representative compile-time transfer assertions exist. | Storage/data descriptor transfer cannot close until the Proposed storage contracts are accepted and implemented. No storage or cancellation API is started here. |
| `VOX-CON-010` | No `@unchecked Sendable`, `@preconcurrency`, unsafe executor inheritance or `nonisolated(unsafe)` declaration exists in executable repository Swift. | The same zero-exception gate now prevents an unreviewed concurrency escape hatch from landing. A future exception needs invariant, owner, rationale, stress/lifetime test and independent-review evidence. |
| `VOX-VAL-*` | Core has focused automated unit tests and the repository retains the broader validation-level scaffold. | There is no separate M1 validation-family leaf. Kernel, operation, pipeline, integration and system-reference completion remains scheduled work; a premature M1 validation report would not close it. |

The selected gate deliberately excludes the controlled non-product Swift probes
under `docs/progress/evidence/` and generated build trees. Effective SwiftPM
descriptions prove both that every compiled source is inventoried and that no
governed source/test Swift file is orphaned or target-excluded. It scans package
manifests, product/test Swift, every auxiliary package and active build
configuration. Exact escape-hatch spellings, including the Swift word
`unsafe`, remain reserved in comments, strings and regexes; broad checked
vocabulary such as `free` and explanatory `UnsafePointer` text is allowed.
Host debug/release compiler builds cover all four packages, and the companion
platform workflow builds product and test targets with strict memory safety.
Proposed `ADR-0039` through `ADR-0041` and Draft `RFC-0001` grant no
unsafe-memory, storage, erasure, no-copy or cancellation source authority.

Primary traceability is `VOX-CON-003`, `VOX-CON-010`, `VOX-ERR-001`,
`VOX-SEC-001`, `VOX-SEC-002` and `VOX-VAL-001`.

## Completed in this increment

- Established the long-running Codex completion goal.
- Created and verified the 15-minute heartbeat automation.
- Added repository-level autonomous engineering, quality, safety, and targeted-test rules.
- Imported and byte-verified all 283 files from the connected Drive folder.
- Restored executable permissions on all 20 baseline shell and Python tool scripts.
- Normalized the supplied `Logs/` and `logs/` case collision to the canonical lowercase `logs/` path and regenerated the affected integrity metadata.
- Ran only the narrow tests and static checks relevant to the import gate.
- Added a host-independent manifest validator that rejects duplicate paths, component-level case or Unicode collisions, unsafe paths, empty manifests, and file/directory conflicts.
- Integrated the validator into required-file checks, repository-script tests, and the M0 scaffold gate.
- Added deterministic release-integrity checking and regeneration for manifest completeness, inventory sizes/digests, checksum coverage, duplicates, and canonical ordering.
- Integrated release-integrity verification into the M0 scaffold gate and autonomous commit workflow.
- Corrected the only proven requirements-summary drift: M0 from 45 to 46 and M3 from 38 to 37, without changing any normative row.
- Refactored requirement-index generation to provide a read-only gate for malformed or duplicate rows, declared totals, category/priority/milestone summaries, duplicate summary keys, and stale index content.
- Ran the complete M0 technical gate once; every check through the root Swift suite passed before the validation executable exposed a Swift 6.3 entry-point incompatibility.
- Resolved the shared auxiliary-package defect by moving all three explicit `@main` types out of specially treated `main.swift` files without changing command behaviour.
- Added a fast repository regression check for explicit entry points placed in `main.swift`.
- Reran the complete M0 scaffold gate after the targeted fix and passed it end to end.
- Built the root package in release configuration.
- Built the root package with complete Swift 6 concurrency checking and
  warnings promoted to errors.
- Built the package for macOS, generic iOS, iOS Simulator, generic tvOS and
  tvOS Simulator without rerunning the already passing destinations.
- Added a focused resource-bundle test that loads and verifies the
  VoxeliaMetal shader manifest through `Bundle.module`.
- Replaced the documentation workflow's unavailable, false-green SwiftPM DocC
  command with an Xcode-native wrapper that treats warnings as errors and
  verifies all 12 target-local archives.
- Corrected cross-module dependency labels that DocC had interpreted as
  unresolved symbol links.
- Replaced the target-name-only SBOM output with a versioned, schema-backed
  release profile covering source revision semantics, products, source and
  test targets, licences, file checksums, release tools, bundled resources,
  external packages and optional-dependency classification.
- Updated the Apple platform acceptance checklist with passed local evidence
  and explicit external gaps; formal M0 acceptance is not claimed.
- Made release-integrity hashing resilient to macOS dataless placeholders by
  reading provably unchanged tracked bytes from the Git index, with a bounded
  worktree comparison, size validation and non-interactive timeouts.
- Made SBOM reads fail closed with an actionable error when macOS exposes a
  required file as a dataless placeholder instead of allowing an unbounded
  File Provider wait.
- Enforced the checked-in SBOM JSON Schema during generation and validation,
  including local references, composed definitions, types, constants, enums,
  patterns, full dates, required fields, collection bounds and unexpected
  top-level fields.
- Reordered release preparation so generated SBOM evidence is validated and
  included in regenerated integrity ledgers before the scaffold and final
  integrity gates run.
- Made release-integrity checks report dataless hashing failures as structured
  gate errors and made the writer compute all dependent evidence before
  replacing any ledger content.
- Added bounded subprocess execution to repository-script regressions so a
  cloud placeholder or failed validator cannot stall an autonomous run.
- Pinned the repository metadata and top-level project contents for local
  storage so autonomous runs remain reliable in the iCloud-backed workspace.
- Implemented the canonical immutable, dynamic-rank `ImageShape` and exact
  `ShapeError` model for `VOX-DAT-002` through `VOX-DAT-005`, including
  positive-extent validation, checked element-count multiplication, no small
  fixed rank limit and invariant-preserving Codable conformance.
- Placed the new public API under the scaffold's required `Public/` source
  layout and replaced the now-obsolete directory placeholder.
- Documented the M1 shape API in the VoxeliaCore DocC catalog.
- Implemented the canonical immutable, dynamic-rank `ImageIndex`, including a
  generic collection initializer that preserves component order and values
  without inventing a standalone bounds contract.
- Documented the zero-based, pixel-or-voxel-centre and axis-zero-fastest index
  convention while explicitly deferring shape-aware validation and offset
  calculation to their later approved APIs.
- Implemented the canonical dynamic-rank, half-open `ImageRegion` and exact
  `RegionError` model for `VOX-RGN-001` and `VOX-RGN-002`, including rank and
  bound validation, overflow-safe extent calculation and invariant-preserving
  Codable conformance.
- Preserved the specified transient empty-region behavior without repurposing
  the storage-only `emptyRead` error or inventing shape-containment APIs.
- Implemented all 11 canonical `ScalarType` cases, exact type-preserving finite
  ranges, byte/bit sizes, integer/floating classification and non-finite-value
  capability metadata for `VOX-DAT-009` and `VOX-DAT-010`.
- Implemented `ByteOrder` and validated `ScalarFormat`, preserving explicit
  valid-bit and source-order metadata without inferring bit placement, packing
  or a narrowed value range.
- Added the specification's canonical `DataModelError` vocabulary so invalid
  scalar formats fail with an approved typed error and decoding revalidates the
  same invariant.
- Implemented `ComponentInterpretation`, `ComponentLayout` and validated
  `ComponentDescriptor` for `VOX-DAT-011`, keeping logical components explicit
  and distinct from image axes.
- Enforced positive component counts, exact RGB/RGBA counts and optional-name
  count agreement while preserving supplied layout, order and names without
  silent normalization.
- Implemented all canonical `ImageSemantic` cases for `VOX-DAT-012`, including
  explicit stable JSON strings and a namespaced generic representation.
- Hardened both generic semantic and component-interpretation decoders to
  reject missing, unexpected and extra fields instead of allowing typed coding
  keys to hide schema drift.
- Implemented the immutable `SemanticVersion` value type with validated
  non-negative core components, exact ASCII identifier rules, arbitrarily long
  numeric prerelease comparison and canonical Semantic Versioning precedence.
- Preserved build metadata through serialization while excluding it from
  precedence equality and hashing, maintaining a coherent Swift `Comparable`
  and `Hashable` contract.
- Added invariant-preserving semantic-version decoding and focused coverage for
  boundaries, malformed identifiers, the canonical precedence chain, numeric
  overflow avoidance, build-insensitive identity and Codable rejection.
- Implemented the neutral `MeasurementUnit` and all 11 initial
  `UnitDimension` values in the dependency-free `VoxeliaSpatial` foundation,
  without binding the canonical model to Foundation or an external unit
  library.
- Preserved opaque, case-sensitive external namespace and code spelling;
  rejected blank identities and non-finite conversion metadata while leaving
  independently optional scale and offset values explicit and uninferred.
- Added stable string dimension encoding, invariant-preserving unit decoding,
  Spatial DocC topics and focused coverage of the millimetre and Hounsfield
  examples, validation, optional conversion metadata and serialization.
- Corrected `MeasurementUnit` identity so human-readable display text no longer
  perturbs equality or hashing, while interpretation-bearing dimension and
  conversion declarations remain identity-bearing and namespace/code spelling
  uses exact accepted UTF-8 bytes.
- Canonicalized signed-zero conversion metadata and hardened the unit decoder
  to require its exact six keys with explicit nullable fields and rejection of
  distinct extras, without claiming canonical JSON byte handling.
- Implemented the shared `VoxeliaStringIdentifier` contract plus distinct
  `CoordinateSpaceID` and `AxisID` types in the dependency-free Spatial
  foundation, keeping both documented axis-ownership outcomes cycle-free.
- Added failable `RawRepresentable` construction and a typed throwing
  initializer, rejecting only empty or Unicode-whitespace-only identifiers
  while preserving external spelling, case and surrounding nonblank content.
- Added one-field keyed identifier encoding with decode-time invariant and
  distinct-extra-key rejection, plus focused coverage of protocol use,
  case-sensitive identity, representative spaces and exact serialization.
- Audited the public Axis model and deferred its implementation because the
  governing architecture assigns it to Spatial while the detailed data-model
  documents assign it to Core and explicitly require resolution before work.
- Implemented validated `Matrix4x4Double` storage in `VoxeliaSpatial` with
  exactly 16 finite row-major values, documented homogeneous column-vector
  convention, canonical identity and typed count/index diagnostics.
- Canonicalized signed zero for equality/hash/serialization coherence while
  preserving every other finite bit pattern, and added invariant-preserving,
  distinct-extra-key-rejecting keyed Codable behavior.
- Kept multiplication, inversion, affine tolerance and point/vector/normal APIs
  outside this slice because their public vector boundary, implementation and
  singularity tolerance remain explicit specification decisions.
- Audited and deferred the coordinate-space descriptor because the governing
  MTA and detailed data-model specification define incompatible public
  `CoordinateConvention` cases and associated values, requiring controlled
  resolution before implementation.
- Implemented the standalone `SpatialAxisMapping` in `VoxeliaSpatial`,
  preserving one-to-three unique nonnegative image axes in documented X/Y/Z
  consumption order with contextual typed validation errors.
- Deferred only the upper image-rank bound to later descriptor/geometry binding,
  because standalone mappings do not carry rank, and added strict keyed
  Codable behavior with constructor revalidation.
- Implemented finite, immutable `Point3D` and `Vector3D` values in
  `VoxeliaSpatial`, with explicit `CoordinateSpaceID` identity and typed
  component-index diagnostics.
- Canonicalized signed zero while preserving every other finite coordinate bit
  pattern, including subnormals, and deliberately allowed a general zero vector
  without implicit normalization.
- Added strict four-field keyed serialization with constructor revalidation and
  focused coverage of finite boundaries, every non-finite component position,
  coordinate-space identity and malformed nested identifiers.
- Implemented `Plane3D` and `Ray3D` with exact coordinate-space agreement and
  typed diagnostics for zero normal, zero direction and mismatched spaces.
- Preserved finite non-unit normals and directions exactly, including
  subnormal and extreme values, by detecting exact zero without squared-length
  arithmetic or an undocumented tolerance.
- Added strict two-field keyed serialization with constructor revalidation and
  nested error paths while leaving normalization and coordinate conversion
  explicit for future operations.
- Implemented canonical `AxisAlignedBounds3D` storage with exact coordinate-
  space agreement, deterministic X/Y/Z inversion diagnostics and no implicit
  point reordering or clamping.
- Defined zero-width point, line and plane bounds as valid while preserving
  finite extreme and subnormal coordinates without tolerance-based comparison.
- Added exact two-field keyed serialization with nested point revalidation and
  field-specific decoding context for inverted axes and mismatched spaces.
- Implemented the exact six-case `SpatialTransformKind` raw-string taxonomy in
  `VoxeliaSpatial` without adding speculative cases, protocols or behavior.
- Preserved the specified case-sensitive serialized vocabulary and added
  focused rejection coverage for unknown and non-string encoded values.
- Implemented the exact three-case `CoordinateHandedness` raw-string taxonomy
  without adding compatibility, conversion or descriptor-validation behavior.
- Preserved the specified case-sensitive JSON vocabulary and kept
  `.unspecified` as a declaration value rather than treating it as a wildcard.
- Implemented validated `ExternalFrameReference` pair identity with typed
  Unicode-blank namespace and identifier diagnostics.
- Preserved every other supplied byte, spelling, case and surrounding nonblank
  whitespace with UTF-8-exact equality and hashing, without imposing DICOM or
  other namespace-specific syntax.
- Added strict two-field keyed serialization with constructor revalidation and
  field-specific decoding context for each blank component.
- Implemented standalone `LookupTableDescriptor` storage in `VoxeliaCore` with
  ordered finite values, full-range `Int64` origins and optional output units.
- Canonicalized signed zero while preserving all other finite table values and
  explicitly accepted empty tables without inventing lookup behavior.
- Added exact three-field keyed serialization with an explicit null absent unit,
  strict key validation, constructor revalidation and nested-unit validation.
- Implemented the exact `DigestAlgorithm` and `ContentScope` raw-string
  taxonomies in `VoxeliaCore` without adding digest bytes or computation.
- Documented `descriptorAndSamples` as the preferred cross-system image scope
  while explicitly keeping custom algorithm identity and canonical digest input
  outside these declaration-only enums.
- Implemented Core-owned `DataObjectID` as a distinct validated
  `VoxeliaStringIdentifier`, reusing the shared typed blank error and strict
  one-field keyed representation.
- Documented object identity as an immutable instance or published-record key,
  never as a substitute for verified content or derivation equality.
- Implemented the exact five-case `MetadataPrivacyClass` raw-string taxonomy
  without attaching policy or classification to the still-deferred metadata
  collection model.
- Documented classification as an input to logging/export policy rather than a
  replacement for host privacy controls.
- Implemented validated `MetadataKey<Value>` and serializable `AnyMetadataKey`
  pair values with shared typed blank-field diagnostics.
- Preserved accepted opaque namespace/name spelling and case, kept the generic
  value type as compile-time information only, and limited strict two-field
  Codable behavior to the erased key.
- Audited the complete recursive metadata declaration and kept it out of source:
  raw floating-point, instant, binary and object payloads cannot satisfy the
  governed invariants, while tags, limits, multiplicity, privacy and canonical
  byte ingress remain unresolved.
- Corrected typed and erased metadata-key equality and hashing to use the exact
  accepted UTF-8 bytes of both identity fields, preventing canonically
  equivalent but byte-distinct keys from collapsing in memory.
- Preserved exact key spelling through erased-key Codable round trips; namespace
  aliases and future canonical-digest Unicode normalization remain explicit
  schema or serialization-layer decisions.
- Implemented neutral `CodedConcept` storage with typed blank scheme/value
  errors and exact UTF-8 `(scheme, value, version)` identity.
- Excluded human-readable meaning from equality and hashing while preserving it
  verbatim, and kept scheme-specific aliases or version compatibility outside
  the canonical value.
- Added exact four-field keyed serialization with explicit null optionals,
  constructor revalidation and field-specific decode context.
- Implemented the exact 11-case `ProvenanceKind` raw-string taxonomy, preserving
  the specified British `materialised` spelling.
- Kept the enum as category vocabulary only, without adding identity, graph,
  validation-status or lifecycle guarantees.
- Implemented Core-owned `ProvenanceID` as a distinct validated
  `VoxeliaStringIdentifier`, reusing the established typed blank error and strict
  one-field keyed representation.
- Documented the identifier as a record/graph-node key without implying graph
  consistency, validation evidence or authenticity.
- Implemented the exact `StorageKind` and `StoragePersistence` raw-string
  taxonomies in their owning `VoxeliaStorage` module.
- Kept both enums as descriptor vocabulary only, without inferring capabilities,
  durability, retention or cache behavior.
- Implemented validated `CodecIdentifier` values in `VoxeliaStorage` with exact
  UTF-8 namespace/name/version/profile identity and typed required-field errors.
- Preserved optional nil versus empty strings and added strict four-field keyed
  serialization with explicit nulls and constructor revalidation, without
  claiming codec capability, interoperability or digest semantics.
- Implemented all six standard `CompressedRegionAccess` cases plus the
  namespaced custom case in `VoxeliaStorage`.
- Added exact stable strings for standard modes, a strict structured custom
  representation and byte-exact custom identity without inferring actual codec
  access capability or a canonical digest serialization.
- Implemented the exact `GeometryKind`, `GeometryAttributeSemantic`,
  `MeshPrimitive` and `IndexType` vocabularies in `VoxeliaGeometry`.
- Preserved all built-in case-sensitive tags and byte-exact namespaced custom
  semantic identity with strict type-level serialization, without adding
  unstated curve kinds, descriptor behavior or mesh validation.
- Implemented validated `GeometryAttributeDescriptor` values with the exact
  four controlled fields, nonnegative element counts and two-or-three-component
  position attributes.
- Added strict four-field serialization with nested descriptor decoding,
  constructor revalidation and field-specific typed-error context while
  leaving interpolation domains and cross-attribute compatibility to binding.
- Added `ImageRegion` construction from lower bounds plus an `ImageShape`, with
  exact rank validation and checked upper-bound addition on every axis.
- Preserved negative origins, arbitrary rank and the canonical lower/upper
  value and serialization shape without clamping or introducing parallel
  extent storage.
- Added `ImageRegion.validateContainment(in:)` with exact rank and half-open
  bounds validation against a supplied `ImageShape`.
- Defined empty anchors at zero and at the upper shape boundary as contained,
  rejected anchors outside `0...extent`, and kept the validation free of
  arithmetic, allocation or implicit clipping.
- Added immutable `ImageRegion.translated(by:)` operations with exact offset
  rank validation and independent checked addition for every lower and upper
  bound.
- Preserved extents, empty axes and arbitrary rank across mixed-sign and zero
  offsets without clamping or silently imposing containment in a shape.
- Added `ImageRegion.clipped(to:)` with exact shape-rank validation and
  componentwise monotonic clamping to each `0...extent` interval.
- Defined wholly below/above regions as deterministic empty results at the
  corresponding zero/upper boundary, including exact `Int` extremes, without
  changing the region's canonical representation.
- Added inclusive `AxisAlignedBounds3D.contains(_:)` queries with exact
  coordinate-space identity checks and typed mismatch errors.
- Used exact finite component comparisons without tolerance, normalization or
  implicit coordinate conversion, including point/line/plane degeneracy.
- Added `AxisAlignedBounds3D.intersection(with:)` using exact componentwise
  maximum minima and minimum maxima in one required coordinate space.
- Returned nil only for strict separation while preserving non-nil face, edge
  and point contact as valid degenerate bounds without tolerance or arithmetic.
- Added `ImageRegion.contains(_:)` queries for `ImageIndex` with exact rank
  validation and componentwise half-open comparisons.
- Preserved negative and full-range `Int` coordinates without shape assumptions,
  normalization, allocation or arithmetic; zero-rank containment follows the
  vacuous per-axis predicate while any explicitly empty axis contains no index.
- Added `ImageShape.contains(_:)` queries for `ImageIndex` with exact typed rank
  diagnostics and componentwise `0 <= index < extent` comparisons.
- Kept the shape-aware predicate allocation- and arithmetic-free without
  calculating a linear offset, inferring axis semantics or authorizing storage
  access.
- Added `ImageRegion.isEmpty` with exact any-collapsed-axis semantics for the
  canonical half-open representation.
- Kept the query nonthrowing, allocation-free and independent of storage read
  policy; the established zero-rank region has no collapsed axis and reports
  false.
- Added `ImageRegion.elementCount()` with a zero result for any collapsed axis
  and checked exact extent and product arithmetic for every nonempty axis.
- Returned the established empty product of one for zero rank, avoided routing
  empty regions through positive-rank `ImageShape`, and kept storage read policy
  outside the operation.
- Implemented the exact six-case `ResidencyPolicy` declaration in
  `VoxeliaMetal` with only the specified `Sendable` and `Codable` conformances.
- Kept policy values declarative, avoided speculative raw-value/`Hashable`
  surface and stable JSON-byte claims, and exposed the API through its DocC
  catalog without implying device support or fulfilled residency.
- Added proposed `ADR-0021` with evidence for every conflicting axis-model
  allocation, a cycle-free recommendation, rejected alternatives, conditional
  migration and focused future validation requirements.
- Added a discoverable ADR index, reserved new IDs after the MTA's existing
  `ADR-0001` through `ADR-0020` register, and disclosed the pre-existing local
  platform `ADR-0001` identifier collision without changing either decision.
- Added proposed `ADR-0022` with the complete convention-shape conflict,
  explicit built-in and structured custom encoding, exact custom identity,
  handedness implications, unit separation and rejected alternatives.
- Kept `CoordinateSpaceDescriptor` explicitly blocked after the enum proposal
  because ordinary-physical, image-display and custom-unit validity still need
  an approved policy.
- Added proposed `ADR-0023` with exact public throwing initializer signatures,
  finite and signed-zero linear policy, ordered nonempty composition policy and
  explicit strict case tags.
- Deferred the undefined `PiecewiseLinearDescriptor` and lookup evaluation
  contract rather than inventing knot, continuity, missing-entry or
  extrapolation semantics.
- Audited both specified `StorageCapabilities` definitions and rejected a
  premature capability-only ADR because their surrounding storage contract is
  not complete enough to ground a stable public API.
- Recorded the unresolved ownership, acquisition, bit-allocation, unknown-bit,
  wire-shape, implication, digest-availability and residency-coverage questions
  instead of silently choosing behavior.
- Audited every live, generated and historical reference affected by the
  duplicate `ADR-0001` assignment and added proposed `ADR-0024` as a one-time
  decision-register reconciliation.
- Preserved the MTA's `ADR-0001` through `ADR-0020` register, the existing
  proposals and historical v0.1.1 evidence; no platform record or live link was
  renamed, and `ADR-0025` is only an allocator hold while the proposal awaits
  governance approval.
- Added a standard-library file-backed ADR validator for required metadata,
  real ISO dates, global and milestone identifier forms, filename/front-matter/
  H1 agreement and duplicate identifiers.
- Integrated the validator into documentation and scaffold gates, the
  documentation workflow trigger, required-file policy and repository-tool
  guidance without interpreting body mentions or applying proposed ADR
  reservations.
- Normalized the checked-in ADR template and all incomplete file-backed records
  with explicit affected-modules, migration and supersession content required
  by RPSS section 9.2.
- Kept the accepted platform decision and all Proposed decisions semantically
  unchanged: the added text records factual scope, completed or conditional
  migration and the absence of supersession rather than changing approval or
  authorizing implementation.
- Extended the ADR validator to require exactly one meaningful Context,
  Decision, Alternatives, Consequences, Affected modules, Validation impact,
  Migration and Supersession section, with the RPSS/template heading aliases,
  arbitrary order and additional sections permitted.
- Made structural parsing fence-aware, normalized valid ATX closing hashes and
  rejected duplicate logical sections plus comment-only or empty-fence
  placeholders as completion evidence.
- Re-audited the remaining low-level `VOX-SPA-011` surface and confirmed that
  the existing `Plane3D` and `Ray3D` values already exhaust their complete,
  non-speculative standalone contract.
- Deferred oriented bounds and new intersection operations because the
  controlled documents do not yet define the representation invariants,
  numerical policy or public result semantics needed for correct code.
- Audited the first M2 Execution policy and identifier declarations and found
  no ownership-safe public slice: the documents disagree on profile and
  backend-policy shapes while leaving priority, determinism, identifiers and
  generation representations incomplete.
- Audited three exact later-milestone taxonomies and declined to place them in
  current modules or activate optional targets early: `SegmentAlgorithmType`
  and `ConvergenceStatus` belong to M7 modules, while
  `PhotorealisticQuality` belongs to the M8 optional rendering module.
- Added proposed `ADR-0026` with one bounded ray-to-axis-aligned-bounds API,
  closed half-ray and degenerate-bound semantics, exact-space validation and a
  transient finite entry/exit result without a premature wire contract.
- Defined a deterministic `binary64-v1` slab model with overflow-safe
  subtraction scaling, signed overflow/underflow tokens, fixed ordering and
  precedence, typed entry/exit failures and explicit floating-point environment
  requirements; no operation code is authorised while the ADR is Proposed.
- Audited all eight direct `ImageDescriptor` fields and separated implemented
  standalone values from Proposed-dependent and still-undefined contracts.
- Expanded the spatial closure through affine, rectilinear and frame-set
  geometry, exposing the previously implicit reverse dependency from
  Spatial-owned `FrameGeometry` to Core-owned `ImageIndex`.
- Kept metadata, identity, provenance and storage outside the descriptor and
  mapped them at the downstream `ImageData` boundary, including the separate
  prohibited Core/Storage cycle in the currently prescribed ownership model.
- Audited the `FrameGeometry.frameIndex` conflict against the package graph,
  full-rank indexing, frame-local geometry and enhanced multi-frame needs, and
  rejected reverse dependencies, symbol moves, scalar ordinals and raw arrays.
- Added proposed `ADR-0027` with a distinct Spatial-owned
  `FrameAnchorIndex`, typed possible-image validation, strict type-level
  encoding and an explicit full-frame local-origin contract.
- Kept Core responsible for later shape- and descriptor-bound validation while
  leaving frame-set order, sparse/enhanced coverage and other aggregate
  policies outside the leaf decision; no geometry source is authorised.
- Audited the shared raw-string instant boundary across metadata, provenance,
  canonical serialisation, the Core package graph, RFC timestamp profiles and
  Swift 6.3.3 Foundation behaviour.
- Added proposed `ADR-0028` with a Core-owned `CanonicalInstant`, an exact
  bounded uppercase zero-offset RFC 3339-derived grammar, proleptic Gregorian
  validation, minimal nanosecond fractions, typed value-redacted errors and
  scalar-string Codable.
- Rejected formatter-dependent validation, `Date` identity storage, offsets,
  hidden normalization, year zero, `24:00:00` and leap-aware time-scale claims
  while keeping source conversion, clock precision and leap policy explicit
  future work.
- Updated the ADR register and its focused live-repository expectation to eight
  records; no canonical-instant, metadata or provenance Swift source is
  authorised while the proposal remains unaccepted.
- Audited the raw floating-point metadata boundary across local governance,
  IEEE 754, JSON/I-JSON/JCS and Swift 6.3.3 value, hashing and Codable behaviour.
- Added proposed `ADR-0029` with a Core-owned `MetadataFloatingPoint`, a
  finite-only binary64 domain, signed-zero canonicalisation, exact preservation
  of every other finite bit pattern, a payload-free typed error and one-number
  type-level Codable.
- Kept canonical number spelling, decoder-token sanitisation, source lexical
  precision, named exceptional values and every recursive metadata contract
  explicit future work; no floating-metadata Swift source is authorised while
  the proposal remains unaccepted.
- Audited the raw binary metadata boundary across local governance, RFC 4648,
  JSON/I-JSON/JCS, Foundation data strategies and Swift 6.3.3 ownership,
  hashing, concurrency and allocation behaviour.
- Added proposed `ADR-0030` with a Core-owned `MetadataBinary`, an owned
  `ContiguousArray<UInt8>` snapshot, exact ordered-byte identity, a valid empty
  value and strict padded standard-Base64 scalar Codable.
- Rejected direct retained `Data`, permissive Foundation Base64 decoding and an
  unevidenced intrinsic leaf cap; host-selected raw-token and decoded-leaf
  limits remain mandatory ingress work, while proposed `ADR-0031` separately
  bounds recursive embedding. No binary-metadata Swift source is authorised.
- Audited the raw string metadata branch across local governance, Unicode
  normalisation and noncharacter rules, JSON/I-JSON/JCS, Swift 6.3.3 exact
  storage, equality, hashing, bridging, Codable and privacy behaviour.
- Retained `case string(String)` and rejected a public `MetadataString` wrapper:
  every valid Swift string is admissible, while exact UTF-8 branch identity is
  the audited aggregate candidate rather than an authorised contract.
- Kept empty text, controls, bidi/format values, private-use, unassigned and
  noncharacter scalars lossless; no string wrapper, string-only ADR, intrinsic
  leaf cap, silent normalisation or string source is authorised.
- Audited recursive construction, copy-on-write amplification, destruction,
  equality, hashing, object identity, strict semantic Codable, full-width
  integers, resource accounting and value-redacted diagnostics under Swift
  6.3.3 and the controlled metadata/canonical-JSON requirements.
- Added proposed `ADR-0031` with validated `MetadataArray` and
  `MetadataObject` payloads, a privacy-neutral nested object member, exact-key
  canonical map order and exact UTF-8 raw-string identity.
- Selected Proposed hard ceilings of 64 container levels, 1,048,576 logical
  structural elements and 64 MiB logical variable payload, counting repeated
  copy-on-write-shared occurrences with checked arithmetic; lower host limits
  and pre-allocation ingress remain separate.
- Selected strict one-member external tags for all eleven cases and preserved
  full `Int64`/`UInt64` number domains without claiming ordinary Codable output
  is canonical JSON or that JCS can represent the full unsigned range.
- Reconciled the Proposed instant, floating and binary leaf migrations with
  the bounded aggregate while leaving general `MetadataEntry`, collections,
  privacy, typed access, canonical byte ingress and source implementation
  deferred until their own approvals and the ceiling evidence exist.
- Reproduced a privacy defect in synthesized raw-enum decoding: an arbitrary
  rejected classification token and enclosing dictionary key appeared in both
  descriptive and reflective `DecodingError` text.
- Replaced only `MetadataPrivacyClass` Codable synthesis with an exact manual
  scalar-string implementation that emits a fixed empty-path failure without
  source text or an underlying error, preserving all successful wire values.
- Added a focused nested regression for unknown and wrong-shaped input that
  checks both error renderings, the empty safe path and absent underlying error.
- Audited direct versus wrapped privacy attachment, optional/default states,
  host authority, nested scope, downgrade behaviour, identity, strict wire and
  value-redacted diagnostics against the controlled model and primary
  healthcare/Apple privacy guidance.
- Added proposed `ADR-0032` with one required class directly on every general
  entry, no unclassified/default state and no implicit privacy-erasing
  conversion to or from `MetadataObject.Member`.
- Defined whole-entry recursive scope, classification-sensitive equality/hash,
  exact three-field Codable and fail-closed `hostDefined` handling while
  retaining host ownership of authorisation, logging, export and audit.
- Rejected an invented severity lattice: library-owned one-to-one transforms
  preserve exact classes, while multi-input aggregation retains entries,
  requires explicit trusted-host classification or fails payload-free.
- Added a checked-in Swift 6 evidence probe for the required shape, exact
  identity, nested scope, strict malformed forms, outer-shape/caller-path/token
  redaction and exact `hostDefined` round-tripping, and reconciled `ADR-0031`
  with the separate entry proposal.
- Audited the collection sketch, duplicate exception, schema-authority gap,
  order, identity, aggregate limits, configured coding, typed cardinality and
  structural privacy without changing product source.
- Added proposed `ADR-0033`, retaining a safe unique-only ordinary path while
  making configured repeats that a caller asserts its schema permits require
  an explicit bounded immutable exact-key policy snapshot at construction,
  encoding and decoding.
- Defined ordered occurrence-preserving identity, full policy preflight,
  collection-wide entry/work/payload ceilings, policy ceilings and a strict
  one-field type-level wire while deferring portable schema identity and
  canonical raw ingress.
- Kept multiplicity separate from privacy: every occurrence and exact class is
  retained, no aggregate privacy class is inferred, and default diagnostics
  omit collection structure as well as key/value/policy content.
- Added a checked-in strict Swift 6 evidence probe for ordinary/configured
  coding, exact-key admission, order/privacy preservation, wrong-policy
  rejection, bounded analogue limits, strict fields and diagnostic redaction;
  reconciled `ADR-0031` and `ADR-0032` with the new collection proposal.
- Audited controlled versus proposed authority for `MetadataKey<Value>`, all
  eleven erased cases, generic API designs, multiplicity/cardinality precedence,
  privacy preservation, diagnostics and indexing without changing product
  source.
- Added proposed `ADR-0034` with a closed table of exact corrected payloads and
  two concrete overload families, leaving the current arbitrary typed-key
  constructor unchanged while unsupported read specialisations fail at compile
  time.
- Rejected bare-value access and retained typed key, exact value and original
  class in `TypedMetadataEntry`; defined payload-free non-generic errors,
  cardinality-before-case single reads and ordered atomic plural reads.
- Rejected public converters, generic casts, key-stored witnesses, optional/
  default shortcuts, privacy-filtered access and a speculative index; recorded
  linear bounded lookup as the version-one oracle.
- Added a checked-in strict Swift 6 positive/negative evidence probe covering
  all mappings, both read families, all five classes, exact UTF-8 lookup,
  cardinality precedence, late plural mismatch and redacted errors; reconciled
  `ADR-0031` through `ADR-0033` with the typed-read proposal.
- Audited controlled canonical-JSON authority, Foundation raw-parser behaviour,
  full-width integer portability, Unicode/noncharacter policy, schema trust,
  multiplicity binding, privacy, cancellation and raw resource accounting
  without changing product source.
- Added proposed `ADR-0035` with the exact `VCMJ-1` envelope, a distinct
  decimal-string canonical projection for full-domain `Int64`/`UInt64`,
  JCS-derived string/floating/property rules, strict Base64/instant spellings
  and a dedicated iterative canonical-only ingress boundary. Bounded lowercase
  ASCII schema-profile references make a finite universal byte derivation
  possible without a Unicode-version-dependent control-plane identity.
- Required exact out-of-band schema-reference/policy binding for repeats,
  unique-only context-free ingress, symmetric emission preflight, retention of
  the matched profile in `CanonicalMetadataDocument`, four payload-free ingress
  and three emission failures, atomic publication, sensitive-from-byte-zero
  handling and no implied digest/export authority.
- Froze the exact whitespace-scalar oracle needed by nonblank metadata identity
  fields, split floating emission from correctly rounded decimal parsing, fixed
  byte-order/chunk-invariant failure precedence and required early offending-
  key rejection plus operation-scoped source-error teardown.
- Froze inclusive resource-accounting units and compute-guard-commit charges,
  a distinct exact emission-output budget, one additive operation-wide 4,096-
  work-unit cancellation cadence plus reproducible device benchmark, partial
  `VOX-ERR-001` allocation-failure traceability and module-local Core/Spatial
  ownership of the shared whitespace oracle.
- Generated and measured the candidate maximum raw JSON depth of 198 while
  leaving the universal document-byte ceiling, production floating oracles,
  cancellation/device evidence, recoverable allocator-failure evidence and
  supported-device memory evidence as explicit acceptance blockers rather than
  guessed defaults.
- Added a focused strict Swift 6 evidence probe for Foundation negative
  controls, integer extrema and aliases, exact UTF-8/noncharacter identity,
  frozen whitespace, bounded schema identifiers, canonical string and Base64
  subprofiles, schema-policy/emission preflight, checked budget arithmetic,
  generated nesting and redacted errors; reconciled `ADR-0028` through
  `ADR-0034` with the new proposal.
- Audited controlled content-identity authority, the two incompatible
  `ContentID` records, digest-storage wire drift, missing scope/projection,
  algorithm/mode ambiguity, complete-record versus semantic identity, privacy,
  schema trust, algorithm agility, streaming, cancellation and publication
  without changing product source.
- Added proposed `ADR-0036` with an explicit algorithm/scope/projection-bearing
  identity record and one closed complete-record tuple: CryptoKit SHA-256,
  `serialisedObject`, `org.voxelia.metadata-complete-record` version `1.0`,
  exact 32 owned bytes and strict 64-character lowercase hexadecimal coding.
- Defined the exact 109-byte domain frame binding frame version, algorithm,
  scope, projection/version and payload length before complete VCMJ bytes;
  independently reproduced the empty-document framed golden with CryptoKit and
  Python and kept raw SHA-256 as a deliberately different negative control.
- Preserved exact order, privacy classes, schema reference/null, presentation
  fields and unknown retained entries in record identity while excluding only
  the out-of-band policy snapshot. Kept semantic collection identity, schema
  authenticity, privacy/export authority, MACs, signatures and keyed
  pseudonyms explicitly separate.
- Added a focused strict Swift 6 evidence probe covering the SHA-256 known
  answer, record mutations, frame-domain mutations, bounded streaming,
  cancellation without publication, owned-byte snapshot, strict hex,
  timing-safe direct comparison, checked arithmetic and payload-free errors;
  reconciled `ADR-0031` through `ADR-0035` with the new proposal.
- Audited the downstream source/derivation/data-identity authority across the
  MTA, CDMS, requirements, vertical-slice plan and live Core leaves, including
  completeness, exact versus semantic equality, source order/duplicates,
  undefined references, lazy lifecycle, trust, privacy, cache and module
  ownership; three independent read-only reviews confirmed that product source
  remains blocked.
- Added proposed `ADR-0037` with a closed claim-state lattice, exact duplicate-
  locator rejection, ordered source lineage, non-recursive reference target,
  explicit runtime assurance and cache admission, pinned-snapshot lazy
  publication, fail-closed mismatch handling and a strict separation between a
  derivation record and the full Execution result-cache key.
- Added a focused strict Swift 6 closed-state probe covering every structural
  state, exact UTF-8/source and derivation behavior, content/source scope
  separation, reference-specific cache authority, policy-domain-bound content
  assurance, exact execution-key-bound derivation evidence, every required key
  discriminator, and zero-publication cancellation/failure/existing-claim-
  mismatch/stale-generation paths without adding product source.
- Audited the Core-owned provenance record and graph boundary across the MTA,
  CDMS, requirements, vertical-slice plan, package topology and live Core
  leaves. Three independent read-only reviews covered ownership/authority,
  closed record/reference/equality shape, and security/privacy/concurrency;
  all confirmed that product source remains blocked.
- Added proposed `ADR-0038` with explicit subject binding, a closed
  source-origin or complete operation-plus-execution activity, ordered
  role/occurrence-bearing input identities, flat tagged parent references,
  complete-versus-compact graph authority and bounded iterative transactional
  admission without adding a prohibited Core dependency.
- Separated record, graph and validation claims from runtime evidence;
  separated deprecation lifecycle from validation; excluded free warning text
  and sensitive diagnostics by default; deferred signed manifests and typed
  `VoxeliaRendering`/`VoxeliaPhotorealisticRendering` extensions; and assigned
  one atomic output/identity/provenance/cache publication point to Execution.
- Added a focused strict Swift 6 actor-safe evidence probe covering structural
  completeness, exact identity, role/warning duplicates, local/external
  reference tags, subject/content mismatches, unresolved graphs, cycles,
  resource ceilings, evidence denial, transactional replacement, cache-hit
  revalidation, redacted diagnostics and every modeled no-publication fault.
  No product source or package topology changed.
- Audited the M1 storage capability/descriptor boundary across controlled
  ownership, live package edges, flags, region/sequential behavior, layout,
  integrity, builder publication, lifetime and residency. Independent
  authority, wire/security and identity/integrity reviews all confirmed that
  the displayed aggregate source remains blocked.
- Added proposed `ADR-0039` with Core-owned backend-neutral contracts,
  Storage-owned implementations, an exact ten-operation registry and wire,
  tagged logical/representation descriptors, checked layout/platform
  admission, complete region staging, representation claim/evidence separation,
  actor-isolated unpublished freeze and Metal-owned residency.
- Added and independently reviewed a focused strict Swift 6 evidence probe.
  At the `ADR-0039` increment, review findings led to retained provider-
  authoritative opaque-provider-
  instance/descriptor/owner/snapshot/generation-bound callable witnesses,
  equal-label cross-provider substitution denial, shape-bound regions,
  destination-issued one-shot request seals, provider-instance-bound
  completions, redacted bounded staged bytes, canonical destinations,
  non-replayable generations and provider-authoritative builder acquisition/
  freeze. Equal-label peer providers with different bytes produce distinct
  frozen target bindings and source authorities. The probe also covers complete
  non-overlapping builder partitions, owner-retaining views, trusted
  representation digest computation, same-authority policy snapshots,
  restricted evidence and incremental bounded generic/wire ingress. No product
  source, unsafe code, `@unchecked Sendable` or package topology changed.
- Later proposed `ADR-0041` and Draft `RFC-0001` refine that read fixture so
  Core owns and retains the lineage authority, seal, private fill and commit
  gate; the provider now receives only bounded fill authority and returns an
  outcome. The older probe remains explicitly narrow historical evidence.
- Audited the normalized logical-sample boundary across controlled identity,
  live descriptor equality/coding, source valid-bit interpretation, physical
  representation, component semantics, pixel padding, persistent claims,
  migration and publication. Independent authority, semantic and governance
  reviews converged on the same source gate and finished clean after the
  proposal corrections.
- Added proposed `ADR-0040` with exact axis-zero-fastest/component-fastest
  ordering, fixed-width most-significant-byte-first decoded scalar bits,
  source-bit decode order, physical-versus-logical padding separation,
  independent sample-layout/representation digest domains and a lossless
  staged pre-1.0 migration. It explicitly leaves the evidence projection
  unregistered and complete image identity undefined.
- Added a focused strict Swift 6 evidence probe covering three equal-logical
  physical layouts, exact region/rank-three ordering, padding-only mutation,
  complete component maps, source bit extraction, exact floating bit classes,
  checked hostile bounds, domain separation, semantic-role exclusion,
  concurrent immutable normalization and payload-free diagnostics. No product
  source, package topology, dependency or accepted persistent wire changed.
- Independent numerical and security/privacy/concurrency probe reviews found
  no P1 issue. The numerical review identified one P2 external-ingress gap;
  raw platform and field-specific limits now precede every `Int` conversion,
  direct checked arithmetic keeps separate overflow evidence, and both focused
  re-reviews finished clean with unchanged projection goldens.
- Audited the complete M1 `VOX-ERR-*`, `VOX-SEC-*`, `VOX-CON-*` and
  `VOX-VAL-*` supporting surface against controlled authority, current Core
  source/tests and the Proposed storage boundary. The audit separates existing
  invalid-data/bounds/checked-`Sendable` evidence from later or governance-
  blocked allocation, storage, cancellation, backend, shader, convergence and
  multi-level validation work.
- Replaced the security workflow's always-green unsafe-code placeholder with
  `check_swift_safety.py`, a fail-closed zero-exception inventory gate wired
  into the scaffold, required-file and security gates.
- Added a narrow raw inventory for unchecked/concurrency escape hatches, every
  Swift `unsafe` marker and strict-safety oracle conditions, plus fail-closed
  manifest, shell, workflow and Xcode configuration checks. Common checked
  vocabulary is not reserved. Deterministic diagnostics are bounded per file
  and repository so hostile input cannot exhaust runner memory or logs.
- Added effective SwiftPM validation for Swift 6, governed local dependencies,
  resolved unsafe flags, target language overrides and bidirectional target-
  source coverage. Unexpected/nested packages, orphan or excluded Swift,
  non-`.swift` Swift scripts, direct compiler/script execution, non-regular
  files and file/directory symlinks fail closed.
- Constrained every executable package manifest to the current deterministic
  declarative PackageDescription subset, independently rejecting runtime-
  selected settings and target language-override APIs. SwiftPM metadata output
  is drained incrementally under a combined 4 MiB ceiling, with process-group
  termination on output or time bounds.
- Added bounded, process-group-cleaned strict-memory compiler builds for product
  and test targets in all four packages in debug and release. SwiftPM metadata
  evaluation is isolated from mutable repository Git metadata so an unrelated
  `git describe` traversal cannot hang the self-hosted gate.
- Upgraded the existing Apple platform matrix to build product and test targets
  with Xcode strict-memory safety and warnings-as-errors, without requiring
  signing, and made changes to that wrapper trigger its workflow.
- Published the current empty unsafe-code inventory and the exact future
  exception evidence process. Forty-four focused positive, negative, location,
  package-coverage, configuration, process-scope and adversarial fixtures
  protect the checker without authorising a product unsafe-memory exception.

## Verification evidence

- Automation definition reports `status = "ACTIVE"` and `FREQ=MINUTELY;INTERVAL=15`.
- Local host reports `arm64`, macOS 26.5.1, Xcode 26.6, and Swift 6.3.3.
- The original imported SHA-256 ledgers passed and all 280 baseline inventory records matched size and digest before development changes.
- The current 398-entry manifest covers every releasable file except its
  intentional self-reference exclusion, with no case-folded path collision.
- Final release-integrity regeneration and read-only verification passed with
  397 inventory records and 398 checksums for this increment.
- `Tools/Tests/Python/test_repository_scripts.py`: all 10 current tests passed
  across the M0 and focused runs.
- Required-file, static package-graph, prohibited-import, Apple-platform, shell-syntax, and Swift package-description checks passed.
- `Tools/Tests/Python/test_manifest_paths.py`: 10 focused tests passed, including the original different-leaf `Logs/` versus `logs/` failure mode.
- At M0 close, the then-live 296-entry repository manifest passed the new
  component-prefix validator.
- `Tools/Tests/Python/test_release_integrity.py`: 7 focused round-trip,
  omission, digest-corruption, Git-index hashing and same-size modification
  rejection tests passed, including structured computation failures and
  failed-write ledger preservation.
- The regenerated 356-record inventory and 357-entry SHA-256 ledger pass the
  read-only integrity checker.
- `Tools/Tests/Python/test_requirement_index.py`: 9 focused tests passed.
- All 486 unique normative rows parse; category summaries, P0/P1/P2 counts of 398/86/2, milestone counts, declared totals, and the checked-in traceability index agree.
- Initial M0 gate: 28 Python repository tests, all static/document checks, the root build, and all 12 root Swift tests passed; execution then stopped at `voxelia-validation` because `@main` was declared in `main.swift`.
- Focused follow-up: Validation, Benchmarks, and Tools auxiliary packages each pass their single Swift test and executable `--self-check` on Swift 6.3.3.
- Final local M0 scaffold gate: all required-file, manifest, release-integrity, package-graph, prohibited-import, Apple-policy, controlled-document and requirement-index checks passed; 29 Python tests and 12 root Swift tests passed; all three auxiliary self-checks returned `pass`; the script reported `M0 scaffold validation passed`.
- `swift build -c release` passed for all root source targets.
- `swift build -Xswiftc -strict-concurrency=complete -Xswiftc
  -warnings-as-errors` passed without warnings.
- `Tools/Scripts/test-platforms.sh` passed macOS, iOS device/simulator and tvOS
  device/simulator builds before the missing visionOS component stopped the
  sequential script.
- `swift test --filter 'VoxeliaMetalTests.shaderManifestIsBundled'` ran one
  focused Swift Testing test and passed.
- `Tools/Scripts/build-docc.sh` passed with warnings as errors and verified the
  exact expected names of all 12 generated `.doccarchive` directories.
- Three focused DocC archive-set tests passed for exact, missing/unexpected and
  duplicate archive cases.
- Three focused repository/release workflow regressions passed; they reject
  the unavailable DocC fallback and non-validating SBOM smoke check, and require
  generated release evidence to precede final integrity validation.
- Eight focused SBOM tests passed for the complete profile, required fields,
  digest tampering, unreviewed dependency licences, schema structure, enforced
  checked-in schema and dependency constraints, malformed collection values
  and dataless-placeholder failure behavior.
- `Tools/Scripts/generate-sbom.sh` produced the schema-backed release profile,
  and an independent `--validate` invocation passed. The profile includes 12
  products, 13 source targets, 12 test targets, eight source checksums, five
  release tools, 10 bundled resources and no external package dependency.
- The live integrity writer and checker completed while macOS retained
  dataless placeholders, proving that this host state no longer stalls the
  release gate.
- `swift build --target VoxeliaCore` passed with the new M1 shape API.
- `swift format lint --strict` passed for the two changed Swift files.
- `swift test --filter ImageShape` executed only the eight `ImageShape` unit
  tests; dynamic rank, invalid extents, the maximum valid count, true overflow,
  high rank and Codable invariant cases all passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  `ImageIndex` slice.
- `swift test --filter ImageIndex` executed only the three `ImageIndex` unit
  tests; representative zero-based dynamic rank, high rank and Codable
  round-trip cases all passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  `ImageRegion` slice.
- `swift test --filter ImageRegion` executed only the 12 `ImageRegion` unit
  tests; valid half-open bounds, rank and inversion failures, transient empty
  regions, extent overflow, high rank and Codable validation all passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  scalar-representation slice.
- `swift test --filter ScalarFormat` executed only six scalar-format tests;
  every declared type, exact range and classification, valid-bit boundary,
  byte-order value, round trip and invalid decode passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  component-model slice.
- `swift test --filter ComponentDescriptor` executed only eight component
  tests; every interpretation and layout, strict count rules, optional names,
  descriptor round trips and invalid decoding passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  image-semantics slice and shared strict-key decoder correction.
- `swift test --filter ImageSemantic` executed only three semantic tests; all
  meanings, exact simple/generic JSON and malformed-schema rejection passed.
- The eight-test `ComponentDescriptor` suite was rerun after the shared decoder
  correction and passed without running unrelated tests.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  semantic-version slice.
- `swift test --filter SemanticVersion` executed only nine semantic-version
  tests; core boundaries, exact validation errors, valid and malformed
  identifiers, canonical and large-numeric precedence, build-insensitive
  identity and invariant-preserving Codable behavior all passed.
- `swift build --target VoxeliaSpatial` and strict format lint passed for the
  measurement-unit slice; the direct dependent also passed
  `swift build --target VoxeliaCore` without running unrelated tests.
- `swift test --filter MeasurementUnit` executed only six unit-model tests;
  every initial dimension string, exact metadata preservation, absent and
  independently supplied conversion fields, blank identity rejection,
  non-finite rejection and decode-time revalidation all passed.
- Regression-first `swift test --filter MeasurementUnit` then reproduced seven
  issues in the prior implementation: display text affected identity, composed
  and decomposed external spellings collapsed, signed zero was retained, and
  missing or extra keys decoded successfully. After the focused correction,
  the expanded eight-test suite passed, including constructor/decode zero
  normalization, exact UTF-8 identity, display-independent hashing, exact keys,
  explicit nulls and malformed-shape rejection.
- `swift test --filter LookupTableDescriptor` executed only the six direct-
  dependent tests and passed its unit identity, strict nested decode and table
  behavior checks. `swift build --target VoxeliaSpatial`,
  `swift build --target VoxeliaCore`, and strict format lint passed; the full
  suite was intentionally not rerun for this leaf-value correction.
- Documentation validation passed for seven controlled front-matter documents,
  seven ADR records and 53 Markdown files. The direct ADR-register check,
  366-entry portable-manifest check, 365-record inventory and 366-checksum
  release-integrity verification passed, as did `git diff --check`.
- An independent read-only final review found no actionable equality/hash,
  Unicode identity, signed-zero, Codable, downstream, test or ledger issue.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  typed-identifier slice.
- `swift test --filter StringIdentifier` executed only seven identifier tests;
  accepted spelling, Unicode whitespace rejection, typed failures,
  case-sensitive/type-distinct identity, exact keyed JSON, invalid-object
  rejection and representative coordinate-space distinctness all passed.
- The formatter initially blocked because macOS had evicted the unchanged
  tracked `.swift-format` file despite its pinned marker. Its exact Git-index
  bytes were rematerialized; `git diff --exit-code -- .swift-format` confirms
  no configuration change.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  canonical matrix slice.
- `swift test --filter Matrix4x4Double` executed only six matrix tests; exact
  row-major storage and generic collection materialization, identity,
  count/non-finite diagnostics, signed-zero canonicalization, equality/hash
  distinction and strict invariant-preserving Codable behavior all passed.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  spatial-axis mapping slice.
- `swift test --filter SpatialAxisMapping` executed only six mapping tests;
  one-to-three axis ordering, generic collection materialization, exact count,
  negative and duplicate diagnostics, rank-bound deferment and strict
  invariant-preserving Codable behavior all passed.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  point/vector primitive slice.
- `swift test --filter SpatialPrimitives` executed only six primitive tests;
  finite extrema and subnormal preservation, all 18 point/vector non-finite
  placements, zero-vector validity, signed-zero canonicalization,
  coordinate-space identity and strict Codable revalidation all passed.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  plane/ray primitive slice.
- `swift test --filter PlaneAndRayTests` executed only six plane/ray tests;
  non-unit preservation, exact-zero rejection, subnormal and extreme finite
  acceptance, coordinate-space mismatch diagnostics, exact Codable shapes and
  decode-time invariant revalidation all passed.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  axis-aligned bounds slice.
- `swift test --filter AxisAlignedBounds3D` executed only six bounds tests;
  extreme/subnormal preservation, point/line/plane degeneracy, deterministic
  per-axis inversion, exact-space identity, strict Codable shape and nested
  decode-time diagnostics all passed.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  transform-kind taxonomy slice.
- `swift test --filter SpatialTransformKind` executed only three taxonomy
  tests; all six exact raw values, raw-string Codable round trips and unknown or
  wrong-shaped decoding rejection passed.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  coordinate-handedness taxonomy slice.
- `swift test --filter CoordinateHandedness` executed only three taxonomy
  tests; all three exact raw values, raw-string Codable round trips and unknown
  or wrong-shaped decoding rejection passed.
- `swift build --target VoxeliaSpatial`, the direct-dependent
  `swift build --target VoxeliaCore`, and strict format lint passed for the
  external-frame-reference slice.
- `swift test --filter ExternalFrameReference` executed only six reference
  tests; opaque Unicode preservation, blank rejection, UTF-8-exact pair
  identity including composed/decomposed spellings, strict keyed round trips
  and field-specific decoding diagnostics all passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  standalone lookup-table descriptor slice.
- `swift test --filter LookupTableDescriptor` executed only six lookup-table
  tests; collection materialization, full-range origins, absent/present units,
  empty tables, finite boundaries, signed-zero canonicalization, all nine
  non-finite placements and strict nested Codable revalidation all passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  content-identity taxonomy slice.
- `swift test --filter ContentIdentityTaxonomy` executed only five taxonomy
  tests; all nine exact raw values, case sensitivity, raw-string Codable,
  malformed decoding, Hashable distinction and Sendable conformance passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  object-identifier slice.
- `swift test --filter DataObjectID` executed only three identifier tests;
  opaque spelling/case preservation, typed and failable Unicode-blank rejection,
  distinct type identity and strict keyed Codable validation all passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  metadata privacy taxonomy slice.
- `swift test --filter MetadataPrivacyClass` executed only three taxonomy tests;
  all five exact raw values, case sensitivity, raw-string Codable and unknown or
  wrong-shaped decoding rejection passed.
- After the decoder hardening, `swift test --filter MetadataPrivacyClass`
  executed only four privacy-taxonomy tests; all valid-wire, rejection and
  nested value-redaction checks passed. Strict format lint for the two modified
  Swift files and `swift build --target VoxeliaCore` also passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  metadata-key slice.
- A regression-first sixth metadata-key test reproduced six issues under
  synthesized Swift `String` equality: composed/decomposed namespace and name
  spellings compared equal and collapsed each typed and erased three-value set
  to one member.
- After the correction, `swift test --filter MetadataKey` executed only the six
  key tests; exact UTF-8 typed/erased identity and erased Codable preservation,
  opaque pair and case-sensitive identity, both blank-field errors, generic
  Sendable behavior and strict contextual decoding all passed.
- `swift build --target VoxeliaCore` and strict format lint passed again for the
  corrected key boundary; the complete test suite was intentionally not run.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  neutral coded-concept slice.
- `swift test --filter CodedConcept` executed only six concept tests; opaque
  field preservation, both blank errors, meaning-independent/version-dependent
  identity, composed/decomposed distinction, exact explicit-null Codable and
  contextual malformed decoding all passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  provenance-kind taxonomy slice.
- `swift test --filter ProvenanceKind` executed only four taxonomy tests; all 11
  exact values, spelling/case rejection, raw-string Codable, malformed decoding,
  Hashable distinction and Sendable conformance passed.
- `swift build --target VoxeliaCore` and strict format lint passed for the
  provenance-identifier slice.
- `swift test --filter ProvenanceID` executed only three identifier tests;
  opaque spelling/case preservation, typed and failable Unicode-blank rejection,
  distinct type identity and strict keyed Codable validation all passed.
- `swift build --target VoxeliaStorage`, the direct-dependent
  `swift build --target VoxeliaExecution`, and strict format lint passed for the
  storage taxonomy slice.
- `swift test --filter StorageTaxonomy` executed only five taxonomy tests; all
  13 exact raw values, case sensitivity, raw-string Codable, malformed decoding,
  Hashable distinction and Sendable conformance passed.
- `swift build --target VoxeliaStorage`, the direct-dependent
  `swift build --target VoxeliaExecution`, and strict format lint passed for the
  codec-identifier slice.
- `swift test --filter CodecIdentifier` executed only five identifier tests;
  opaque/optional preservation, both blank errors, per-field Unicode identity,
  nil/empty distinction, explicit-null Codable and contextual strict decoding
  all passed.
- `swift build --target VoxeliaStorage`, the direct-dependent
  `swift build --target VoxeliaExecution`, and strict format lint passed for the
  compressed-region access slice.
- `swift test --filter CompressedRegionAccess` executed only five access-mode
  tests; all six exact standard tags, structured custom round trips, byte-exact
  custom identity, malformed-schema rejection, Hashable behavior and Sendable
  conformance passed.
- `swift build --target VoxeliaGeometry` and direct-consumer builds for
  `VoxeliaRendering`, `VoxeliaCPU` and the `Voxelia` umbrella target passed with
  strict format lint for the geometry taxonomy slice.
- `swift test --filter GeometryTaxonomy` executed only eight taxonomy tests;
  all 24 exact built-in tags, case sensitivity, structured custom semantics,
  byte-exact Unicode identity, strict malformed decoding, Hashable behavior and
  Sendable conformance passed.
- `swift build --target VoxeliaGeometry` and direct-consumer builds for
  `VoxeliaRendering`, `VoxeliaCPU` and `Voxelia` passed with strict format lint
  for the geometry-attribute descriptor slice.
- `swift test --filter GeometryAttributeDescriptor` executed only seven tests;
  valid 2D/3D positions, zero and maximum element counts, deferred non-position
  policy, both typed validation failures, exact Codable shape, nested failures,
  Hashable behavior and Sendable conformance passed.
- `swift build --target VoxeliaCore` and directly affected builds for
  `VoxeliaStorage`, `VoxeliaGeometry` and `Voxelia` passed with strict format
  lint for extent-based region construction.
- `swift test --filter ImageRegion` executed only the 18 region tests; exact
  negative-origin conversion, short/long rank mismatches, largest valid `Int`
  sums, independent-axis overflow, 1,024-axis construction, exact canonical
  JSON and validated-shape enforcement passed alongside the prior region cases.
- `swift build --target VoxeliaCore` and directly affected builds for
  `VoxeliaStorage`, `VoxeliaGeometry` and `Voxelia` passed with strict format
  lint for shape-aware region containment.
- `swift test --filter ImageRegion` executed only the 23 region tests; full and
  interior containment, negative/oversized rejection, rank mismatch, empty
  anchors below/at/above both boundaries, and empty/non-empty `Int.max`
  boundaries passed alongside all prior region cases.
- `swift build --target VoxeliaCore` and directly affected builds for
  `VoxeliaStorage`, `VoxeliaGeometry` and `Voxelia` passed with strict format
  lint for checked region translation.
- `swift test --filter ImageRegion` executed only the 29 region tests; mixed-
  sign translation, empty-axis preservation, short/long rank mismatches,
  isolated lower/upper overflow, exact `Int.min`/`Int.max` success and
  1,024-axis zero-offset identity passed alongside all prior region cases.
- `swift build --target VoxeliaCore` and directly affected builds for
  `VoxeliaStorage`, `VoxeliaGeometry` and `Voxelia` passed with strict format
  lint for deterministic shape clipping.
- `swift test --filter ImageRegion` executed only the 36 region tests; unchanged
  contained regions, partial overlap, `Int.min`/`Int.max` disjoint results,
  empty anchors below/inside/at/above the shape, mixed 3D below/above/interior
  anchoring, both rank mismatches and 1,024-axis clipping passed alongside all
  prior region cases.
- `swift build --target VoxeliaSpatial` and directly affected
  `VoxeliaCore`/`Voxelia` builds passed with strict format lint for
  axis-aligned point containment.
- `swift test --filter AxisAlignedBounds3D` executed only the 10 bounds tests;
  interior points, all eight corners, all six faces, each next-representable
  outside direction, point/line/plane degeneracy and exact coordinate-space
  mismatch passed alongside all prior bounds cases.
- `swift build --target VoxeliaSpatial` and directly affected
  `VoxeliaCore`/`Voxelia` builds passed with strict format lint for exact
  axis-aligned bounds intersection.
- `swift test --filter AxisAlignedBounds3D` executed only the 15 bounds tests;
  exact overlap, commutativity, containment/identity, positive and negative
  next-representable separation on every axis, face/edge/point contact and
  coordinate-space mismatch passed alongside all prior bounds cases.
- `swift build --target VoxeliaCore` and directly affected builds for
  `VoxeliaStorage`, `VoxeliaGeometry` and `Voxelia` passed with strict format
  lint for half-open region/index containment.
- `swift test --filter ImageRegion` executed only the 44 region tests; lower
  faces, upper and beyond-upper exclusion, every below-lower and empty axis,
  explicit zero-rank behavior, negative and exact `Int` boundaries, both rank
  mismatches and 1,024-axis queries passed alongside all prior region cases.
- `swift build --target VoxeliaCore` and directly affected builds for
  `VoxeliaStorage`, `VoxeliaGeometry` and `Voxelia` passed with strict format
  lint for shape-aware index containment.
- `swift test --filter 'VoxeliaCoreTests.ImageShapeTests'` executed exactly the
  14 shape tests; origin and last-valid inclusion, every negative, upper and
  beyond-upper axis, exact `Int` boundaries, short/long/zero-rank mismatches and
  1,024-axis queries passed alongside all prior shape cases.
- `swift build --target VoxeliaCore` and directly affected builds for
  `VoxeliaStorage`, `VoxeliaGeometry` and `Voxelia` passed with strict format
  lint for explicit region emptiness.
- `swift test --filter 'VoxeliaCoreTests.ImageRegionTests'` executed exactly the
  49 region tests; ordinary nonempty bounds, every independently collapsed
  axis, negative and exact `Int` anchors, one collapsed axis at rank 1,024 and
  explicit zero-rank behavior passed alongside all prior region cases.
- `swift build --target VoxeliaCore` and directly affected builds for
  `VoxeliaStorage`, `VoxeliaGeometry` and `Voxelia` passed with strict format
  lint for checked region element counts.
- `swift test --filter 'VoxeliaCoreTests.ImageRegionTests'` executed exactly the
  55 region tests; negative-origin multiplication, collapsed-axis zero before a
  would-be overflow, exact `Int.max`, checked product overflow, zero-rank empty
  product and 1,024-axis counts passed alongside all prior region cases.
- `swift build --target VoxeliaMetal` and the direct-dependent
  `swift build --target VoxeliaValidation` passed with strict format lint for
  the residency-policy declaration.
- `swift test --filter 'VoxeliaMetalTests.ResidencyPolicyTests'` executed exactly
  four tests; all six cases, synthesized Codable round trips, malformed-value
  rejection and `Sendable` conformance passed without freezing JSON bytes.
- Targeted ADR checks passed for required template fields, exact Proposed
  status, collision-free `ADR-0021`, README discoverability and all five
  referenced controlled-document paths.
- `Tools/Scripts/validate-docs.sh` passed Apple-host validation, front matter
  for all seven controlled project documents and text hygiene for all 48
  Markdown files; no Swift test ran for the documentation-only slice.
- Targeted ADR checks passed for collision-free `ADR-0022`, exact Proposed
  status, template fields, README discoverability and all five referenced
  controlled-document paths.
- `Tools/Scripts/validate-docs.sh` passed again with text hygiene for all 49
  Markdown files; no Swift test ran for the coordinate-convention proposal.
- Targeted ADR checks passed for collision-free `ADR-0023`, exact Proposed
  status, public initializer signatures, README discoverability and all four
  referenced source or controlled-document paths.
- `Tools/Scripts/validate-docs.sh` passed again with text hygiene for all 50
  Markdown files; no Swift test ran for the value-transform proposal.
- Two independent read-only reviews agreed on the collision-free `ADR-0024`
  migration boundary, classified every active and historical reference, and
  found no remaining blocking omission after the proposal was corrected.
- `Tools/Scripts/validate-docs.sh` passed for all seven controlled documents and
  text hygiene for all 51 Markdown files; no Swift test ran for the
  decision-register proposal.
- Release-integrity regeneration and verification passed with 362 manifest
  paths, 361 inventory records and 362 checksums.
- `Tools/Tests/Python/test_adr_register.py` executed exactly 14 focused tests;
  numeric and milestone identifiers, malformed or incomplete metadata,
  filename and heading mismatches, duplicate IDs, fenced examples and body-only
  references all followed the intended file-backed policy.
- Three selected repository integration tests passed for direct checker
  execution, wrapper integration and documentation-workflow coverage.
- Direct ADR validation, documentation validation, required-file validation,
  Python compilation and edited-shell syntax checks passed. An independent
  parser review found three bypasses, verified their regression fixes and then
  reported the slice clean.
- Release-integrity regeneration and verification passed with 364 manifest
  paths, 363 inventory records and 364 checksums after adding the checker and
  its focused test file.
- An independent RPSS section 9.2 audit verified complete structural coverage
  after correcting one workflow-hosting overstatement in the accepted platform
  ADR; the metadata checker, documentation gate and text checks remained green.
- Release-integrity regeneration, 364-path manifest validation and read-only
  integrity verification passed after the editorial normalization.
- `Tools/Tests/Python/test_adr_register.py` executed exactly 21 focused tests
  after structural enforcement. Every required-section omission and empty body,
  both alias families, arbitrary order, duplicates, fenced examples,
  adversarial fence text, placeholder-only content and ATX closing hashes were
  covered.
- Direct validation of all five file-backed ADRs, the documentation gate and
  the selected repository integration test passed. Independent review found
  three Markdown edge cases, verified their fixes and reported the final gate
  clean.
- Three independent read-only spatial audits agreed that no additional plane,
  ray, oriented-bounds or intersection code is currently implementable without
  inventing public semantics; no Swift suite was rerun for this documentation-
  only conclusion.
- The documentation gate, 364-path manifest check and read-only release-
  integrity check passed after regenerating the inventory and checksum evidence
  for each ledger-only audit update.
- Two independent read-only Execution audits covered policy/profile types and
  identifiers respectively. Both reported no-go conclusions, so no Execution
  source or Swift tests were added for incomplete contracts.
- Three independent read-only ownership audits confirmed the M7/M8 activation
  gates for the later taxonomies. No Swift tests were run because no source,
  package graph or optional-module artifact was changed.
- `Tools/Tests/Python/test_adr_register.py` remained at exactly 21 focused tests
  and passed after its live-repository expectation moved from five to six ADRs;
  the direct checker reported all six records valid and the documentation gate
  passed for all 52 Markdown files.
- Independent API, numerical and governance reviews found and then verified
  corrections for direction-scaling scope, model-versus-exact miss claims,
  tagged-endpoint ordering, nil/error precedence, floating-point environment,
  algorithm-specification migration, compatibility evolution and British
  English. All three final re-reviews were clean.
- Release-integrity regeneration, the 365-path manifest check and read-only
  verification passed with 364 inventory records and 365 checksums after the
  sixth file-backed ADR was added.
- Three independent read-only audits covered the descriptor field shape,
  axis/spatial closure and downstream identity/metadata/storage boundary. All
  three concluded that no unimplemented public leaf is safe to add, so no Swift
  source or test suite was run for this documentation-only result.
- The audits cross-checked MTA sections 8.1 through 10, CDMS sections 6, 14, 18
  through 27, 37, 40, 55, 64, 70, 72 and Appendix A, FVSP sections 14, 18 and
  41, the live `Package.swift` graph and the current `Public/` source inventory.
- `Tools/Scripts/validate-docs.sh` passed for seven front-matter documents, all
  six file-backed ADRs and 52 Markdown files. Release-integrity regeneration,
  the 365-path manifest check, read-only integrity verification and
  `git diff --check` also passed with 364 inventory records and 365 checksums.
- `Tools/Tests/Python/test_adr_register.py` passed all 21 focused tests after
  its live-repository expectation moved from six to seven file-backed ADRs;
  the direct checker also reported all seven records valid.
- Independent API/architecture, serialisation/validation and spatial reviews
  corrected the universally unbindable `Int.max` case, mapped-axis identity,
  full-frame scope, decode error propagation, resource-limit wording and the
  physical-matrix scope. All three final re-reviews were clean.
- `Tools/Scripts/validate-docs.sh` passed for seven front-matter documents, all
  seven file-backed ADRs and 53 Markdown files; `git diff --check` also passed.
- Release-integrity regeneration, the 366-path manifest check and read-only
  integrity verification passed with 365 inventory records and 366 checksums.
- Three independent read-only metadata audits covered declaration ownership and
  shape, recursive/wire safety, scalar identity and privacy. All agreed that the
  recursive model is not source-ready and that exact UTF-8 key identity is the
  only bounded correction exposed by this audit.
- Swift 6.3.3 probes confirmed the blockers: NaN broke reflexive synthesized
  equality, signed zeros encoded differently, synthesis exposed `_0` payloads,
  distinct extras decoded, duplicate JSON keys collapsed before the model and a
  50,000-level recursive hash trapped. These probes did not become public API.
- `Tools/Scripts/validate-docs.sh` passed for seven front-matter documents, all
  seven file-backed ADRs and 53 Markdown files. The 366-path manifest check,
  release-integrity regeneration and read-only verification passed with 365
  inventory records and 366 checksums; `git diff --check` also passed.
- Three independent read-only canonical-instant audits covered local governance,
  primary timestamp standards and Swift implementation/security. They agreed on
  the bounded profile in proposed `ADR-0028` and on keeping both aggregates and
  every Foundation parser out of the leaf decision.
- Isolated Swift 6.3.3 probes found permissive invalid-date, `24:00:00`, leap-
  second, offset and alias parsing plus binary64 fraction loss; they introduced
  no repository source or public API.
- `Tools/Tests/Python/test_adr_register.py` passed all 21 focused tests after its
  live-repository expectation moved from seven to eight records; the direct
  checker reported all eight records valid.
- Independent final governance, standards and Swift/API reviews corrected
  uppercase ABNF octets, fraction-error reachability, RFC references, one weak
  requirement mapping, RFC 9557 offset semantics and leap/pre-UTC scope; all
  focused re-reviews were clean.
- `Tools/Scripts/validate-docs.sh` passed for seven front-matter documents, all
  eight file-backed ADRs and 54 Markdown files. The 367-path manifest check,
  release-integrity regeneration and read-only verification passed with 366
  inventory records and 367 checksums; `git diff --check` also passed. No Swift
  suite was run for the documentation-only Proposed decision.
- Three independent read-only floating-metadata audits covered local governance,
  IEEE 754 and JSON-family standards, and Swift 6.3.3 API, identity, Codable and
  privacy behaviour. They agreed on the bounded finite wrapper in proposed
  `ADR-0029` and on keeping exceptional values, the recursive aggregate and
  canonical bytes outside this leaf.
- An isolated `swift -e` probe reproduced non-reflexive NaN equality, three set
  members from two payloads with one repeated, equal and hash-equal signed zeros
  encoded as distinct `0` and `-0` tokens, exact selected subnormal/extrema round
  trips, numeric alias decoding and configured special-string decoding. Its
  first untyped-zero expression was compiler-ambiguous; the explicit-`Double`
  rerun passed without changing repository source.
- A separate `swift -e` decoder probe rejected `1e400`, `-1e400`, `1e-400` and
  `-1e-400` before wrapper validation and demonstrated binary64 rounding of
  longer decimal tokens. This evidence limits value-redaction claims to errors
  owned by the proposed wrapper.
- The deterministic prototype command `xcrun swift -` used seed
  `0x9e37_79b9_7f4a_7c15` and the recurrence
  `state = state &* 6364136223846793005 &+ 1442695040888963407` for 20,000
  `Double(bitPattern:)` samples. On ARM64 Swift 6.3.3 it round-tripped 19,989
  finite values through single-value JSON with zero mismatches, included six
  subnormals and classified 11 non-finite patterns.

The exact successful Swift 6 strict-concurrency probe was:

```bash
xcrun swift -swift-version 6 -strict-concurrency=complete -warnings-as-errors - <<'SWIFT'
import Foundation

enum ProbeError: Error, Sendable, Equatable {
    case nonFiniteValue
}

struct ProbeValue: Sendable, Hashable, Codable {
    let value: Double

    init(value: Double) throws {
        let magnitude = value.bitPattern & 0x7fff_ffff_ffff_ffff
        guard magnitude < 0x7ff0_0000_0000_0000 else {
            throw ProbeError.nonFiniteValue
        }
        self.value = magnitude == 0 ? 0 : value
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.value.bitPattern == rhs.value.bitPattern
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(value.bitPattern)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            try self.init(value: container.decode(Double.self))
        } catch let error as ProbeError {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid metadata floating-point value.",
                    underlyingError: error
                )
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct NestedProbe: Decodable {
    let item: ProbeValue
}

let nanA = Double(bitPattern: 0x7ff8_0000_0000_0001)
let nanB = Double(bitPattern: 0x7ff8_0000_0000_0002)
precondition(nanA != nanA)
precondition(Set([nanA, nanA, nanB]).count == 3)
precondition(Double(0) == -Double(0))
precondition(Double(0).hashValue == (-Double(0)).hashValue)
let encodedPositiveZero = try JSONEncoder().encode(Double(0))
let encodedNegativeZero = try JSONEncoder().encode(-Double(0))
precondition(String(decoding: encodedPositiveZero, as: UTF8.self) == "0")
precondition(String(decoding: encodedNegativeZero, as: UTF8.self) == "-0")

for bits: UInt64 in [
    0x7ff0_0000_0000_0000,
    0xfff0_0000_0000_0000,
    0x7ff0_0000_0000_0001,
    0xfff0_0000_0000_0001,
    0x7ff8_0000_0000_0001,
    0xfff8_0000_0000_0001,
] {
    do {
        _ = try ProbeValue(value: Double(bitPattern: bits))
        preconditionFailure("Accepted non-finite bit pattern")
    } catch ProbeError.nonFiniteValue {
    }
}

let negativeZero = try ProbeValue(value: -Double(0))
precondition(negativeZero.value.bitPattern == Double(0).bitPattern)

let boundaryValues: [Double] = [
    -Double.greatestFiniteMagnitude,
    -Double.leastNormalMagnitude,
    -Double.leastNonzeroMagnitude,
    -Double(0),
    Double(0),
    Double.leastNonzeroMagnitude,
    Double.leastNormalMagnitude,
    Double.greatestFiniteMagnitude,
]
for source in boundaryValues {
    let value = try ProbeValue(value: source)
    let decoded = try JSONDecoder().decode(
        ProbeValue.self,
        from: JSONEncoder().encode(value)
    )
    let magnitude = source.bitPattern & 0x7fff_ffff_ffff_ffff
    let expectedBits = magnitude == 0 ? Double(0).bitPattern : source.bitPattern
    precondition(value.value.bitPattern == expectedBits)
    precondition(decoded.value.bitPattern == expectedBits)
}

let specialDecoder = JSONDecoder()
specialDecoder.nonConformingFloatDecodingStrategy = .convertFromString(
    positiveInfinity: "Infinity",
    negativeInfinity: "-Infinity",
    nan: "NaN"
)
do {
    _ = try specialDecoder.decode(
        NestedProbe.self,
        from: Data(#"{"item":"NaN"}"#.utf8)
    )
    preconditionFailure("Accepted configured NaN string")
} catch DecodingError.dataCorrupted(let context) {
    precondition(context.codingPath.last?.stringValue == "item")
    precondition(context.underlyingError as? ProbeError == .nonFiniteValue)
    precondition(!context.debugDescription.contains("NaN"))
}

var state: UInt64 = 0x9e37_79b9_7f4a_7c15
var finiteCount = 0
var nonFiniteCount = 0
var subnormalCount = 0
var mismatchCount = 0
for _ in 0..<20_000 {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    let source = Double(bitPattern: state)
    do {
        let value = try ProbeValue(value: source)
        finiteCount += 1
        if source.isSubnormal {
            subnormalCount += 1
        }
        let decoded = try JSONDecoder().decode(
            ProbeValue.self,
            from: JSONEncoder().encode(value)
        )
        if decoded.value.bitPattern != value.value.bitPattern {
            mismatchCount += 1
        }
    } catch ProbeError.nonFiniteValue {
        nonFiniteCount += 1
    }
}
precondition(finiteCount == 19_989)
precondition(nonFiniteCount == 11)
precondition(subnormalCount == 6)
precondition(mismatchCount == 0)

for token in ["1", "1.0", "1e0", "-0", "-0.0", "5e-324"] {
    _ = try JSONDecoder().decode(ProbeValue.self, from: Data(token.utf8))
}
for token in ["1e400", "-1e400", "1e-400", "-1e-400"] {
    do {
        _ = try JSONDecoder().decode(Double.self, from: Data(token.utf8))
        preconditionFailure("Accepted out-of-range token")
    } catch DecodingError.dataCorrupted(let context) {
        precondition(String(describing: context.underlyingError).contains(token))
    }
}
let rounded = try JSONDecoder().decode(
    Double.self,
    from: Data("9007199254740993".utf8)
)
precondition(rounded == 9_007_199_254_740_992)

print(
    "finite=\(finiteCount) nonfinite=\(nonFiniteCount) "
        + "subnormal=\(subnormalCount) mismatches=\(mismatchCount)"
)
SWIFT
```

It printed
`finite=19989 nonfinite=11 subnormal=6 mismatches=0`. An earlier consolidated
attempt put throwing encoder calls inside `precondition` autoclosures and was
rejected at compile time; lifting those results into local constants produced
the successful command above. The probe remained isolated and added no
repository source.

- `python3 -m unittest Tools.Tests.Python.test_adr_register` passed all 21
  focused tests after the live expectation moved from eight to nine records;
  `python3 Tools/Scripts/check_adr_register.py` reported all nine records valid.
- `Tools/Scripts/validate-docs.sh` passed for seven front-matter documents, all
  nine file-backed ADRs and 55 Markdown files. Every relative link in
  `ADR-0029` resolved, and `git diff --check` passed.
- Independent final governance, standards and Swift/API reviews corrected
  British-English wording and one overbroad set-identity statement; the
  standards review found no IEEE, JSON, I-JSON, JCS or citation defect, and all
  three current-tree re-reviews were clean.
- Release-integrity regeneration, the 368-path manifest check and read-only
  integrity verification passed with 367 inventory records and 368 checksums.
  No Swift package suite was run because this is a documentation-only Proposed
  decision; its acceptance-only migration explicitly defers source and tests.

The exact focused repository commands for this proposal were:

```bash
python3 -m unittest Tools.Tests.Python.test_adr_register
python3 Tools/Scripts/check_adr_register.py
Tools/Scripts/validate-docs.sh
python3 - <<'PY'
from pathlib import Path
import re

document = Path(
    "docs/architecture/decisions/"
    "ADR-0029-finite-floating-point-metadata-boundary.md"
)
for target in re.findall(r"\]\(([^)]+)\)", document.read_text()):
    if target.startswith(("http://", "https://")):
        continue
    resolved = (document.parent / target.split("#", 1)[0]).resolve()
    print(target, resolved.exists())
PY
git diff --check
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0030`, an isolated strict-concurrency Swift 6.3.3 probe used
the exact command below. It verified both candidate byte types as `Sendable`,
showed Foundation's configurable JSON `Data` shapes, reproduced mutation
through caller-managed no-copy memory, demonstrated that a prior
`ContiguousArray` materialisation remained unchanged, reproduced failed lookup
of the mutated value in a populated set and confirmed two noncanonical Base64
aliases accepted by the Foundation decoder:

```bash
xcrun swift -swift-version 6 -strict-concurrency=complete -warnings-as-errors - <<'SWIFT'
import Foundation

func requireSendable<Value: Sendable>(_: Value.Type) {}
requireSendable(Data.self)
requireSendable(ContiguousArray<UInt8>.self)

let sample = Data([0x00, 0x01, 0x02, 0xff])
let standardEncoder = JSONEncoder()
let standardJSON = String(decoding: try standardEncoder.encode(sample), as: UTF8.self)
let deferredEncoder = JSONEncoder()
deferredEncoder.dataEncodingStrategy = .deferredToData
let deferredJSON = String(decoding: try deferredEncoder.encode(sample), as: UTF8.self)

let pointer = UnsafeMutableRawPointer.allocate(byteCount: 1_024, alignment: 1)
pointer.initializeMemory(as: UInt8.self, repeating: 200, count: 1_024)
defer { pointer.deallocate() }
let externallyBacked = Data(bytesNoCopy: pointer, count: 1_024, deallocator: .none)
var values = Set<Data>()
for byte in UInt8(0)..<UInt8(128) {
    values.insert(Data(repeating: byte, count: 1_024))
}
values.insert(externallyBacked)
precondition(values.contains(externallyBacked))
let snapshot = ContiguousArray(externallyBacked)
pointer.storeBytes(of: UInt8(9), as: UInt8.self)
precondition(externallyBacked[0] == 9)
precondition(snapshot[0] == 200)

let extraPadding = Data(base64Encoded: "Zg===")
let nonZeroPadBits = Data(base64Encoded: "Zh==")
precondition(extraPadding == Data([0x66]))
precondition(nonZeroPadBits == Data([0x66]))

print("default=\(standardJSON)")
print("deferred=\(deferredJSON)")
print("external=\(externallyBacked[0]) snapshot=\(snapshot[0]) setContains=\(values.contains(externallyBacked))")
print("aliases=\(extraPadding == nonZeroPadBits)")
SWIFT
```

It printed:

```text
default="AAEC\/w=="
deferred=[0,1,2,255]
external=9 snapshot=200 setContains=false
aliases=true
```

- `python3 -m unittest Tools.Tests.Python.test_adr_register` passed all 21
  focused tests after the live expectation moved from nine to ten records;
  `python3 Tools/Scripts/check_adr_register.py` reported all ten records valid.
- `Tools/Scripts/validate-docs.sh` passed for seven front-matter documents, all
  ten file-backed ADRs and 56 Markdown files. Every relative link in
  `ADR-0030` resolved, and `git diff --check` passed.
- Three independent current-tree reviews covered governed scope, API shape,
  Swift ownership, privacy, complexity, RFC 4648 padding and unused-bit rules,
  I-JSON interoperability and the canonical-document boundary. Their findings
  narrowed a Core-wide statement to metadata, corrected Codable attribution,
  added encoded-length overflow evidence, reconciled copy-on-write complexity
  and recorded the deliberate I-JSON recommendation trade-off.
- Release-integrity regeneration, the 369-path manifest check and read-only
  integrity verification passed with 368 inventory records and 369 checksums.
  No Swift package suite was run because this is a documentation-only Proposed
  decision; its acceptance-only migration explicitly defers source and tests.

The exact focused repository commands for this proposal were:

```bash
python3 -m unittest Tools.Tests.Python.test_adr_register
python3 Tools/Scripts/check_adr_register.py
Tools/Scripts/validate-docs.sh
python3 - <<'PY'
from pathlib import Path
import re

document = Path(
    "docs/architecture/decisions/"
    "ADR-0030-owned-binary-metadata-boundary.md"
)
missing = []
for target in re.findall(r"\]\(([^)]+)\)", document.read_text(encoding="utf-8")):
    if target.startswith(("http://", "https://")):
        continue
    resolved = (document.parent / target.split("#", 1)[0]).resolve()
    print(f"{target}: {resolved.exists()}")
    if not resolved.exists():
        missing.append(target)
if missing:
    raise SystemExit(f"missing links: {missing}")
PY
git diff --check
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py
```

For the raw string-metadata audit, an isolated strict-concurrency Swift 6.3.3
probe used the exact command below. It reproduced Swift's canonical-equivalent
`String` identity, verified the aggregate branch's exact UTF-8 alternative,
round-tripped representative controls and every Unicode noncharacter, checked
escape aliases and encoder-dependent slash spelling, confirmed rejection of
a representative overlong UTF-8 sequence and representative unpaired
surrogates before model construction, exercised copy and mutable-Foundation
bridge isolation, and distinguished grapheme, scalar and UTF-8 resource counts:

```bash
xcrun swift -swift-version 6 -strict-concurrency=complete -warnings-as-errors - <<'SWIFT'
import Foundation

struct AggregateStringBranchProbe: Sendable, Hashable {
    let payload: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.payload.utf8.elementsEqual(rhs.payload.utf8)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(payload.utf8.count)
        for byte in payload.utf8 {
            hasher.combine(byte)
        }
    }
}

func requireSendable<Value: Sendable>(_: Value.Type) {}
requireSendable(String.self)
requireSendable(AggregateStringBranchProbe.self)

let composed = "caf\u{00e9}"
let decomposed = "cafe\u{0301}"
precondition(composed == decomposed)
precondition(Array(composed.utf8) != Array(decomposed.utf8))
precondition(Set([composed, decomposed]).count == 1)
let exactComposed = AggregateStringBranchProbe(payload: composed)
let exactDecomposed = AggregateStringBranchProbe(payload: decomposed)
precondition(exactComposed != exactDecomposed)
precondition(Set([exactComposed, exactDecomposed]).count == 2)

let representativeValues = [
    "",
    "\0",
    "\u{001f}\u{007f}",
    "\n\t",
    "\u{061c}\u{202e}",
    "\u{feff}",
    "\u{e000}",
    "\u{0378}",
    "👨‍👩‍👧‍👦",
]
for value in representativeValues {
    let decoded = try JSONDecoder().decode(
        String.self,
        from: JSONEncoder().encode(value)
    )
    precondition(Array(decoded.utf8) == Array(value.utf8))
}

let composedJSON = try JSONEncoder().encode(composed)
let decomposedJSON = try JSONEncoder().encode(decomposed)
precondition(composedJSON != decomposedJSON)
let decodedComposed = try JSONDecoder().decode(String.self, from: composedJSON)
let decodedDecomposed = try JSONDecoder().decode(String.self, from: decomposedJSON)
precondition(Array(decodedComposed.utf8) == Array(composed.utf8))
precondition(Array(decodedDecomposed.utf8) == Array(decomposed.utf8))

let literalComposed = try JSONDecoder().decode(
    String.self,
    from: Data(#""café""#.utf8)
)
let escapedComposed = try JSONDecoder().decode(
    String.self,
    from: Data(#""caf\u00e9""#.utf8)
)
let escapedDecomposed = try JSONDecoder().decode(
    String.self,
    from: Data(#""cafe\u0301""#.utf8)
)
precondition(Array(literalComposed.utf8) == Array(escapedComposed.utf8))
precondition(Array(escapedDecomposed.utf8) == Array(decomposed.utf8))

let gClef = try JSONDecoder().decode(
    String.self,
    from: Data(#""\uD834\uDD1E""#.utf8)
)
precondition(gClef == "\u{1d11e}")

var noncharacterCount = 0
for codePoint in UInt32(0)...0x10ffff {
    guard let scalar = Unicode.Scalar(codePoint) else { continue }
    let isNoncharacter = (0xfdd0...0xfdef).contains(codePoint)
        || codePoint & 0xfffe == 0xfffe
    guard isNoncharacter else { continue }
    let value = String(scalar)
    let decoded = try JSONDecoder().decode(
        String.self,
        from: JSONEncoder().encode(value)
    )
    precondition(Array(decoded.utf8) == Array(value.utf8))
    noncharacterCount += 1
}
precondition(noncharacterCount == 66)

for token in [#""\uDEAD""#, #""\uD800""#, #""\uD800x""#] {
    do {
        _ = try JSONDecoder().decode(String.self, from: Data(token.utf8))
        preconditionFailure("Accepted unpaired surrogate")
    } catch {
    }
}

do {
    _ = try JSONDecoder().decode(String.self, from: Data([0x22, 0xc0, 0xaf, 0x22]))
    preconditionFailure("Accepted malformed UTF-8")
} catch {
}

let defaultSlashJSON = try JSONEncoder().encode("/")
let literalSlashEncoder = JSONEncoder()
literalSlashEncoder.outputFormatting = .withoutEscapingSlashes
let literalSlashJSON = try literalSlashEncoder.encode("/")
precondition(defaultSlashJSON != literalSlashJSON)
let decodedDefaultSlash = try JSONDecoder().decode(
    String.self,
    from: defaultSlashJSON
)
let decodedLiteralSlash = try JSONDecoder().decode(
    String.self,
    from: literalSlashJSON
)
precondition(decodedDefaultSlash == decodedLiteralSlash)

let mutable = NSMutableString(string: decomposed)
let bridged = mutable as String
mutable.append("!")
precondition(Array(bridged.utf8) == Array(decomposed.utf8))
var mutatedCopy = decomposed
let preservedCopy = mutatedCopy
mutatedCopy.append("!")
precondition(Array(preservedCopy.utf8) == Array(decomposed.utf8))

let family = "👨‍👩‍👧‍👦"
precondition(family.count == 1)
precondition(family.unicodeScalars.count == 7)
precondition(family.utf8.count == 25)

print("rawEqual=\(composed == decomposed) rawSet=\(Set([composed, decomposed]).count)")
print("exactEqual=\(exactComposed == exactDecomposed) exactSet=\(Set([exactComposed, exactDecomposed]).count)")
print("composedJSON=\(String(decoding: composedJSON, as: UTF8.self))")
print("decomposedJSON=\(String(decoding: decomposedJSON, as: UTF8.self))")
print("slash=\(String(decoding: defaultSlashJSON, as: UTF8.self)) vs \(String(decoding: literalSlashJSON, as: UTF8.self))")
print("noncharacters=\(noncharacterCount) family=\(family.count)/\(family.unicodeScalars.count)/\(family.utf8.count)")
SWIFT
```

It printed:

```text
rawEqual=true rawSet=1
exactEqual=false exactSet=2
composedJSON="café"
decomposedJSON="café"
slash="\/" vs "/"
noncharacters=66 family=1/7/25
```

- Independent governance, Unicode/JSON and Swift reviews agreed on the
  admitted string domain, exact UTF-8 identity candidate, no normalisation,
  ingress-owned limits and privacy boundary. The API reviews additionally established that
  the future recursive aggregate already needs custom identity and tagged
  Codable, so a wrapper and standalone ADR would add no enforceable invariant.
- `Tools/Scripts/validate-docs.sh` passed for seven front-matter documents, all
  ten file-backed ADRs and 56 Markdown files; `git diff --check` passed.
- Release-integrity regeneration, the 369-path manifest check and read-only
  integrity verification passed with 368 inventory records and 369 checksums.
  No Swift package suite was run because the audit adds no source and explicitly
  defers its tests to the recursive aggregate implementation.

The exact focused repository commands for this audit were:

```bash
Tools/Scripts/validate-docs.sh
git diff --check
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0031`, the isolated reproducible Swift evidence is stored in
`docs/progress/evidence/ADR-0031-bounded-recursive-metadata-probe.swift`. It is
explicitly probe code, not product source or implementation authorisation. The
exact successful strict-concurrency command was:

```bash
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0031-bounded-recursive-metadata-probe.swift
```

It printed:

```text
exactStrings=2
objectOrder=a,b
equivalentKeySpellings=2
depth=64/64 next=rejected
amplifiedElements=1048575 next=rejected
elementArithmetic=1048576/1048576 next=rejected
payload=67108864/67108864 next=rejected
standalonePayload=67108865 embedded=rejected callerPath=sanitized
wide=20000 strictInvalid=6 integerAliases=4
ordered={"object":[{"key":{"name":"a","namespace":"ns"},"value":{"signedInteger":1}},{"key":{"name":"b","namespace":"ns"},"value":{"signedInteger":2}}]}
```

The probe compiled the reciprocal value/container/member shape under strict
`Sendable` checking; exercised exact UTF-8 string and key identity, duplicate
rejection, canonical object order, order-independent object equality/hashing,
iterative O(depth)-cursor identity and a 20,000-element array; admitted depth
64 and rejected 65; admitted the 1,048,575-node COW amplification case and
rejected 2,097,151; checked exact 1,048,576-element arithmetic and one-over;
admitted exactly 64 MiB logical repeated payload and rejected 128 MiB; checked
an above-ceiling standalone leaf while rejecting the same leaf inside a
recursive container; sanitised a model-originated coding path beneath an
arbitrary caller key; checked unsigned counter overflow; round-tripped
`Int64.min`, `Int64.max`, `UInt64.max`, empty containers and representative
tags; accepted the semantic integer aliases `1`, `1.0`, `1e0` and `-0`; and
rejected empty, unknown, null, multi-tag, wrong-shape and duplicate-object wire
forms.

Earlier exploratory Swift commands separately confirmed that public enum cases
cannot be access-restricted, direct raw object construction bypasses duplicate
validation, synthesized recursive hashing can trap on very deep trees, and
Foundation integer decoding preserves both 64-bit extrema while accepting the
same lexical aliases. Two draft probe invocations failed
to compile because a throwing expression was placed in a nonthrowing
`precondition` autoclosure and because private probe types escaped to top-level
bindings; both were corrected before the checked-in evidence command above.

- Three independent read-only reviews agreed that validated array/object
  wrappers, a hard depth bound and logical anti-amplification ceilings are
  mandatory for the recursive `ContiguousArray` representation.
- The reviews also agreed that general `MetadataEntry` cannot be published
  while privacy attachment is unresolved; `ADR-0031` therefore uses a distinct
  privacy-neutral nested object member and leaves collection policy untouched.
- RFC 8259 object/array semantics and parser-limit guidance support ordered
  arrays, unordered unique-key objects and bounded parsing. JCS was retained
  only as canonicalisation precedent because its binary64 number model cannot
  preserve the complete controlled `UInt64` domain.
- `Tools/Scripts/validate-docs.sh` passed for seven front-matter documents, all
  eleven file-backed ADRs and 57 Markdown files; `git diff --check` passed.
- `xcrun swift-format lint --strict` passed for the checked-in Swift evidence
  probe after three initial line-layout findings were corrected.
- The 371-path manifest check passed before final integrity regeneration. No
  Swift package suite was run because the only Swift file is an isolated
  proposal probe and no package target or product source changed.

The exact focused repository commands for the recursive proposal were:

```bash
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0031-bounded-recursive-metadata-probe.swift
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0031-bounded-recursive-metadata-probe.swift
Tools/Scripts/validate-docs.sh
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0032`, the isolated reproducible Swift evidence is stored in
`docs/progress/evidence/ADR-0032-metadata-entry-privacy-probe.swift`. It is
entry-boundary evidence, not public API or implementation authorisation. The
exact successful command was:

```bash
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0032-metadata-entry-privacy-probe.swift
```

It printed:

```text
entryIdentityClasses=2 requiredPrivacy=true strictInvalid=5
hostDefinedRoundTrip=true
nestedScope=oneOuterClass outerShapePaths=sanitized
callerPath=sanitized ordered={"key":{"name":"field","namespace":"example"},"privacyClass":"sensitive","value":{"string":"x"}}
```

The probe compiled a required key/value/class entry under strict concurrency;
proved different declarations remain unequal; kept `hostDefined` exact and
unresolved; represented nested structural members beneath one outer class;
round-tripped strict three-field entries; rejected missing, null, extra,
unknown and wrong-shaped classifications; and verified that rejected nested
tokens plus array and null outer shapes expose neither arbitrary caller paths
nor source text in descriptive or reflective errors. Its first draft failed to
compile because throwing decode expressions were placed in nonthrowing
`precondition` autoclosures; intermediate values corrected the evidence before
the checked-in successful command.

- Independent shape, security/privacy and wire reviews covered the controlled
  “may carry” ambiguity, optional versus required states, policy authority,
  recursive scope, equality, strict Codable and diagnostic leakage. The final
  decision requires an explicit class and rejects optional `nil` as an
  ungoverned duplicate of unresolved policy.
- The reviews confirmed that no total or partial order, automatic aggregation
  or Core-owned disclosure resolver is justified. Exact preservation avoids
  erasing category- or host-specific obligations, and classification never
  grants logging or export permission.
- The current manual `MetadataPrivacyClass` implementation and focused four-
  test regression were independently re-reviewed clean.
- No full Swift package suite was run for the ADR/probe increment; product
  source did not change after the separately committed focused decoder fix.

The exact focused repository commands for the entry proposal were:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0032-metadata-entry-privacy-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0032-metadata-entry-privacy-probe.swift
Tools/Scripts/validate-docs.sh
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0033`, the isolated reproducible Swift evidence is stored in
`docs/progress/evidence/ADR-0033-metadata-collection-policy-probe.swift`. It is
collection-boundary evidence, not public API, implementation authorisation or
proof that a caller-supplied policy is an authenticated schema. The exact
successful commands were:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0033-metadata-collection-policy-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0033-metadata-collection-policy-probe.swift
```

They printed:

```text
orderedIdentity=true defaultUniqueRoundTrip=true strictInvalid=5
configuredMultiplicity=true policyOnWire=false defaultDuplicate=blocked
privacyAggregation=none limits=policy+entry+structure+payload
callerAndMetadataText=sanitized configured={"entries":[{"key":{"name":"a","namespace":"example"},"privacyClass":"publicData","value":"one"},{"key":{"name":"a","namespace":"example"},"privacyClass":"technical","value":"three"},{"key":{"name":"a","namespace":"example"},"privacyClass":"potentiallyIdentifying","value":"four"},{"key":{"name":"a","namespace":"example"},"privacyClass":"sensitive","value":"two"},{"key":{"name":"a","namespace":"example"},"privacyClass":"hostDefined","value":"five"}]}
```

The probe preserved order-sensitive identity and duplicate occurrences carrying
all five privacy classes, including unresolved `hostDefined`;
kept ordinary construction/Codable unique-only; admitted only explicitly
allow-listed exact keys through Foundation coding configuration; revalidated
encoding under the supplied policy; proved the policy is absent from wire;
exercised small policy, entry, aggregate-structural and payload limits; rejected
five strict malformed forms; and kept caller/key/value sentinels out of
descriptive and reflective errors. The reduced string decoder charges semantic
budgets after each decoded entry; production recursive budget threading remains
required implementation evidence. The first execution exposed a probe-only raw-string
interpolation typo on a failure path; correcting the literal produced the
checked-in successful evidence without changing the proposed contract.

No full Swift package suite was run for this proposal increment. Product source
did not change, and the focused probe plus document, manifest and integrity
checks cover the changed surface.

- Independent controlled-authority review required the public allow-list to be
  described only as an unauthenticated caller assertion. The final ADR states
  that Core does not verify schema permission and qualifies `ImageData`
  collection validity accordingly; the re-review passed cleanly.
- Independent privacy review added explicit no-interpolation/reflection guidance
  for both collection and policy, scoped the diagnostic guarantee to audited
  collection-originated output, and expanded duplicate round-trip evidence to
  all five classes including unresolved `hostDefined`; the re-review passed.
- Independent Swift/wire/resource review caught premature constructor
  materialisation. The probe now prechecks the source count, validates and
  charges each occurrence, and performs one bounded append. It also states
  plainly that the reduced decoder does not prove recursive remaining-budget
  threading; that remains required implementation evidence. The re-review found
  no remaining coding, wire or aggregate-accounting blocker.

The exact focused repository commands for the collection proposal were:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0033-metadata-collection-policy-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0033-metadata-collection-policy-probe.swift
Tools/Scripts/validate-docs.sh
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0034`, the isolated reproducible Swift evidence is stored in
`docs/progress/evidence/ADR-0034-typed-metadata-access-probe.swift`. It is API-
shape and semantic evidence, not product source, implementation authorisation,
schema proof or privacy permission. The exact successful positive command was:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0034-typed-metadata-access-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0034-typed-metadata-access-probe.swift
```

It printed:

```text
closedExactMappings=11 singleAndPlural=true
privacyFields=key+value+class allFiveClasses=true hostDefined=unresolved
cardinality=missing+multiple+typeMismatch precedence=cardinality-first
pluralOrder=preserved pluralMissing=empty pluralMismatch=atomic
exactUTF8Lookup=true diagnostics=sanitized unsupportedMapping=compile-time
```

The compile-negative configuration was then type-checked with:

```bash
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -typecheck \
  -D ADR0034_UNSUPPORTED_MAPPING_SHOULD_FAIL \
  docs/progress/evidence/ADR-0034-typed-metadata-access-probe.swift
```

It exited 1 at only the conditional `MetadataKey<Double>` call with
`error: no exact matches in call to instance method 'entry'`, proving that the
key remains constructible while the unsupported read is absent at compile time.

The positive probe resolved both overloads for all eleven cases; retained typed
key, exact payload and every privacy class; kept `hostDefined` unresolved;
enforced missing/multiple/mismatch precedence; returned empty for absent plural
reads; preserved occurrence order; rejected a late mismatch atomically; kept
canonically equivalent but byte-distinct keys separate; and rendered no
key/type/case/value/class/count sentinel in either error form. Its first draft
placed throwing plural reads inside nonthrowing `precondition` autoclosures;
intermediate bindings corrected the probe before the checked-in successful run.

- Independent controlled-contract review confirmed that no existing document
  authorises a mapping and that the corrected eleven-case table is new Proposed
  authority; current `MetadataKey<Double>` tests prove identity only.
- Independent Swift API review rejected open protocols, loose casts, stored
  closures/witnesses and generic runtime fallback. Concrete overloads preserve
  the current phantom-key layout and make unsupported reads compile-negative.
- Independent privacy/security review rejected bare payload results, generic
  errors, optional/default shortcuts and filtered access. The final candidate
  retains every class, uses cardinality before conversion and treats both
  errors and reflectable results as unsafe telemetry.

Final diff review found that the first UTF-8 fixture changed namespace and name
together, presentation-insensitive nominal payload fields were not explicit,
and the performance prose omitted exact-key byte work and the plural second
scan. The corrected probe now proves exact-key success plus independent
namespace-only and name-only canonical-equivalent misses, preserves a
decomposed string by bytes, and checks unit/code presentation fields directly.
The ADR now accounts for compared UTF-8 bytes and both plural scans. The strict
positive and compile-negative commands passed again after those corrections.

No full Swift package suite was run for this proposal increment. Product source
did not change, and the focused positive/negative probe plus documentation,
manifest and integrity checks cover the changed surface.

The exact focused repository commands for the typed-read proposal were:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0034-typed-metadata-access-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0034-typed-metadata-access-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -typecheck \
  -D ADR0034_UNSUPPORTED_MAPPING_SHOULD_FAIL \
  docs/progress/evidence/ADR-0034-typed-metadata-access-probe.swift 2>&1 \
  | rg -F "error: no exact matches in call to instance method 'entry'"
Tools/Scripts/validate-docs.sh
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0035`, the isolated reproducible Swift evidence is stored in
`docs/progress/evidence/ADR-0035-canonical-metadata-ingress-probe.swift`. It is
a reduced raw-boundary and token-profile probe, not a complete parser,
production floating codec, public API, unrestricted-resource proof or
implementation authorisation. The exact successful commands were:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0035-canonical-metadata-ingress-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0035-canonical-metadata-ingress-probe.swift
```

It printed:

```text
foundationBoundary=false duplicatesCollapsed=true integerAliasesAccepted=true
integerProjection=decimalStrings fullInt64=true fullUInt64=true
unicode=exactUTF8 noNormalization=true noncharacters=preserved frozenBlankOracle=true
canonicalSubtokens=strings+strictBase64 floatingVectorsOnly=true
foundationSortedKeysIsNotJCS=true schemaIdentifier=boundedASCII255
schemaBinding=callerExpected policy=outOfBand uniqueOnlyWithoutContext=true
emissionPreflight=symmetric policyFailureBeginsNoEmission=true
budgetArithmetic=checked generatedRawDepth=198 diagnostics=payloadFree
```

The probe demonstrates only the named reduced checks. Its Foundation calls are
negative controls and an illustrative-envelope syntax smoke test; none sits on
the candidate trust boundary. The RFC 8785 floating values are vector anchors,
not an emitter/parser implementation. The budget helper proves checked counter
arithmetic, not pre-allocation safety; the generated nesting scanner proves the
candidate depth calculation, not semantic parsing. Complete duplicate scanning,
every chunk split, full grammar construction, policy-budget preflight, fuzzing,
cancellation, cross-platform differential results and production resource
ceilings remain required.

- Three independent reviews covered controlled authority/schema shape,
  canonical wire/Unicode/numerics and privacy/parser/resource behaviour. Their
  final findings are incorporated in the proposal and focused probe.
- No full Swift package suite was run for this proposal increment. Product
  source did not change, and only the focused probe plus documentation,
  manifest and release-integrity checks cover the changed surface.

The exact focused repository commands for the canonical-ingress proposal were:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0035-canonical-metadata-ingress-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0035-canonical-metadata-ingress-probe.swift
Tools/Scripts/validate-docs.sh
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0036`, the isolated reproducible Swift evidence is stored in
`docs/progress/evidence/ADR-0036-metadata-complete-record-identity-probe.swift`.
It is a reduced identity-record/framing probe over fixed VCMJ strings, not a
canonical parser/emitter, product API, general content-ID implementation,
cryptographic proof, complete cancellation/device/fault corpus or source
authorisation. The exact successful commands were:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0036-metadata-complete-record-identity-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0036-metadata-complete-record-identity-probe.swift
```

It printed:

```text
sha256=knownAnswer recordProjection=completeVCMJ1 emptyFramedDigest=8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432 rawDigestIsDifferent=true semanticEqualityIsNotRecordIdentity=true order+privacy+profile+unknown+presentation=bound policy=outOfBand framing=algorithm+scope+projection+length projectionIdentifier=63/64+255/256 declaredLength=mismatchRejected streaming=chunkInvariant4096 hex=lowercase64 digestBytes=owned comparison=timingsafe_bcmp cancellation=noPublication diagnostics=payloadFree
```

An independent Python standard-library construction confirmed the fixed
148-byte empty payload, 109-byte frame header, raw digest and framed digest:

```bash
python3 - <<'PY'
import hashlib
import struct

payload = b'{"documentSchema":{"identifier":"org.voxelia.metadata-document","version":{"major":1,"minor":0}},"multiplicitySchema":null,"payload":{"entries":[]}}'
parts = [b"VOXELIA-CONTENT-ID\0", struct.pack(">I", 1)]
for value in [
    b"sha256",
    b"serialisedObject",
    b"org.voxelia.metadata-complete-record",
]:
    parts.extend([struct.pack(">I", len(value)), value])
parts.extend(
    [
        struct.pack(">I", 1),
        struct.pack(">I", 0),
        struct.pack(">Q", len(payload)),
    ]
)
header = b"".join(parts)
print(
    len(payload),
    len(header),
    hashlib.sha256(payload).hexdigest(),
    hashlib.sha256(header + payload).hexdigest(),
)
PY
```

```text
148 109 a27e896af6381de3cf78c5b4166851b601b6461d9e2503935b32ab4d6811ee50 8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432
```

The probe demonstrates only the named reduced checks. Its fixed canonical
strings are fixtures, not an emitter; the Foundation `Data`/array encodings are
wire-drift negative controls; selected mutations are not collision-resistance
proof; `timingsafe_bcmp` covers direct fixed-byte comparison only; two
cancellation positions are not the complete required cancellation/fault
matrix. The probe now locks the exact 109 header bytes/framed golden,
projection-identifier 63/64 and 255/256 limits/error mapping, and both declared-
length mismatch directions. Full SHA-256 vectors, every chunk split,
independent VCMJ projection oracles, remaining boundaries, supported Apple
destinations, resource ceilings, memory pressure and atomic cache/provenance
integration remain acceptance work.

- Three independent pre-draft audits covered controlled authority/API and
  milestone ownership, exact metadata scope/equality/privacy semantics and
  cryptographic framing/algorithm/streaming boundaries. Their findings are
  incorporated in the proposal and probe.
- No full Swift package suite was run for this proposal increment. Product
  source did not change, and only the focused probe plus documentation,
  manifest and release-integrity checks cover the changed surface.

The exact focused repository commands for the complete-record identity
proposal were:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0036-metadata-complete-record-identity-probe.swift
xcrun swift -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  docs/progress/evidence/ADR-0036-metadata-complete-record-identity-probe.swift
Tools/Scripts/validate-docs.sh
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0037`, the isolated strict Swift 6 evidence is stored in
`docs/progress/evidence/ADR-0037-data-identity-cache-admission-probe.swift`.
It models claim completeness, external assurance, reference-specific cache
admission and atomic publication only; it is not product API, a canonical
codec, a digest implementation, a trust store, a persistent cache or complete
concurrency/fault evidence. The focused probe command exited successfully and
emitted no output:

```bash
mkdir -p .build/evidence
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0037-data-identity-cache-admission-probe.swift \
  -o .build/evidence/adr0037-probe
.build/evidence/adr0037-probe
```

The final narrow gate for that documentation-only proposal was:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0037-data-identity-cache-admission-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0037-data-identity-cache-admission-probe.swift \
  -o .build/evidence/adr0037-probe
.build/evidence/adr0037-probe
Tools/Scripts/validate-docs.sh
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0038`, the isolated strict Swift 6 evidence is stored in
`docs/progress/evidence/ADR-0038-provenance-record-graph-admission-probe.swift`.
It models exact claim values, a closed record state, flat graph references,
bounded iterative admission, runtime assurance and actor-isolated atomic
publication only. It is not product API, canonical coding, cryptography, a
resolver/store, a signature system, a validation package or production limits.
The focused probe command exits successfully and emits no output:

```bash
mkdir -p .build/evidence
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0038-provenance-record-graph-admission-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0038-provenance-record-graph-admission-probe.swift \
  -o .build/evidence/adr0038-probe
.build/evidence/adr0038-probe
```

The final narrow gate for this documentation-only proposal is:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0038-provenance-record-graph-admission-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0038-provenance-record-graph-admission-probe.swift \
  -o .build/evidence/adr0038-probe
.build/evidence/adr0038-probe
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_prohibited_imports.py
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0039`, the isolated strict Swift 6 evidence is stored in
`docs/progress/evidence/ADR-0039-storage-capability-descriptor-admission-probe.swift`.
It models the closed operation wire, the earlier provider/descriptor/owner/
snapshot/generation witness and destination-issued-seal fixture, checked
descriptor/layout admission, one-shot gathered region bytes, representation
claim/evidence separation, complete actor-isolated builder freeze and owner-
retaining generation views only. Proposed `ADR-0041` and Draft `RFC-0001`
replace its read authority/completion shape with a Core-owned seal/private fill/
commit gate whose provider sees only the bounded fill capability and returns an
outcome. The probe uses an actor-backed fixture provider and CryptoKit SHA-256;
it is not product API, canonical storage wire, a production admission factory,
provider or integrity implementation, complete cryptographic validation,
unsafe/no-copy access, the composed owned-read transaction or production
limits. The focused probe command exits successfully and emits no output:

```bash
mkdir -p .build/evidence
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0039-storage-capability-descriptor-admission-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0039-storage-capability-descriptor-admission-probe.swift \
  -o .build/evidence/adr0039-probe
.build/evidence/adr0039-probe
```

The final narrow gate for this documentation-only proposal is:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0039-storage-capability-descriptor-admission-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0039-storage-capability-descriptor-admission-probe.swift \
  -o .build/evidence/adr0039-probe
.build/evidence/adr0039-probe
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_prohibited_imports.py
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

For proposed `ADR-0040`, the isolated strict Swift 6 evidence is stored in
`docs/progress/evidence/ADR-0040-logical-sample-projection-probe.swift` at
SHA-256 `7ae0907e18dab77a144c8559ca1490e5a92693744a2ac8e700fe44be00b89f2b`.
It models one evidence-only sample-layout frame, a separately labelled toy
descriptor-bearing frame and exact representation frames. Ten focused groups
cover canonical layout equality, a rank-three/two-component ordering golden,
regions, semantic-role exclusion, source-bit extraction order, exact floating
bits, checked hostile bounds, redaction and immutable concurrent normalization.
It uses in-memory toy limits and CryptoKit SHA-256; it is not product API,
registered projection/content-ID wire, a production decoder/storage, streaming
or generation/cancellation/publication evidence, semantic image identity,
authenticity or diagnostic validation.

```bash
mkdir -p .build/evidence
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0040-logical-sample-projection-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0040-logical-sample-projection-probe.swift \
  -o .build/evidence/adr0040-probe
.build/evidence/adr0040-probe
```

The focused execution reports:

```text
sampleLayoutFingerprintSHA256=813b6376bf98f5dc74bac7e0fa902297364ceacd7b730eb6ec28875fcba3f254
littleInterleavedRepresentationSHA256=6b52f3fdb256e9eb94b0a0766363ce11fbc4acb046c1f7f8ed2ecbd72cbf925d
bigPlanarRepresentationSHA256=2c1dc10f36e5664ebc88fbec871d0fe9d03eb7c22bdc82860045b5073d7abb5e
paddedBGRRepresentationSHA256=d5b55f56ac4fa28a075a230822a00aa53c74bb43b7a00088ef6ab87c28e0c267
mutatedPaddingRepresentationSHA256=dd667e6dcba64df60ffd827f0c1fb6f96f4d8a16b7cdb78ec9a342ddfc56d8c7
rgbDescriptorBearingSHA256=fc72975ee02dfed43e2fed3a1f9d3249e6a189ac2b199ff058e46ae6f8c1a4bc
bgrDescriptorBearingSHA256=6d9683fb97f0394ea6d1c14b68b88887bf14581e8337f30012d2f085b1a7e65e
focusedTestGroups=10
```

The final narrow gate for this documentation-only proposal is:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0040-logical-sample-projection-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0040-logical-sample-projection-probe.swift \
  -o .build/evidence/adr0040-probe
.build/evidence/adr0040-probe
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_prohibited_imports.py
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

No complete Swift package suite is required for this proposal. Product source,
package topology and dependencies did not change, so the focused probe plus
document, ADR-register, manifest and release-integrity checks are the affected
surface.

For proposed `ADR-0041`, the isolated strict Swift 6 evidence is stored in
`docs/progress/evidence/ADR-0041-storage-read-lifetime-probe.swift` at SHA-256
`567fd60ea5e4137499126c7949f564da81c6019513c12def229f0d29f525afe7`.
Twelve focused groups cover the Core-owned authority and exact binding; checked
single-witness erasure; exact-capacity monotonic fill; prepare/commit and
first-terminal-wins behavior; short, overlapping, gapped, overrun, failed,
unsupported and target-allocation outcomes; cancellation and drain-resident
capacity; current versus bound-snapshot freshness; replay, foreign, abandoned
and FIFO-recyclable tombstone cases; concurrency and an independent live-budget
ledger while a committed result outlives its slot; owner retention and
exactly-once synchronous release; owner-retaining `Data` scopes that derive
`Span` and `RawSpan`; immutable-only mapped-access policy; and redacted
diagnostics. The probe uses toy in-memory identities and limits and copies into
`Data`. It is not product API, a production nonforgeable provider-admission
factory, actual file or VM mapping, no-copy or unsafe-memory evidence, a real
allocator/OOM test, OS cancellation-cadence evidence, arbitrary-provider
allocation control, production limits, a supported-destination matrix, or
authentication/production-diagnostic validation.

```bash
mkdir -p .build/evidence
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0041-storage-read-lifetime-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -strict-memory-safety -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0041-storage-read-lifetime-probe.swift \
  -o .build/evidence/adr0041-probe
.build/evidence/adr0041-probe
```

The focused execution reports:

```text
binding=coreAuthority+descriptor+owner+snapshot+generation exact=true
transactionGate=pending+prepared+commit+cancel+stale+drain+budget firstTerminalWins=true
readPublication=complete-owned-only residentBudgetTransfer=true
fill=exact-capacity+monotonic poisonOnInvalidCoverage=true
tombstones=FIFO-recyclable liveBudgetLedger=independent
erasure=single-checked-witness fallback=false
leases=borrowing-Data+Span+RawSpan mappedPolicy=immutable-only
ownerRetention=read+lease deinitExactlyOnce=true
diagnostics=payload+path+identity+seal+address-redacted
focusedTestGroups=12
```

Two full-compilation negative configurations prove only that custom methods
cannot return owner-derived `Span` or `RawSpan`. Both fail with
`a method cannot return a ~Escapable result`; separate escaping-closure and task
capture cases remain future acceptance evidence.

```bash
if xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -strict-memory-safety -warnings-as-errors -parse-as-library -c \
  -D ADR0041_SPAN_ESCAPE_SHOULD_FAIL \
  docs/progress/evidence/ADR-0041-storage-read-lifetime-probe.swift \
  -o .build/evidence/adr0041-span-negative.o \
  2>.build/evidence/adr0041-span-negative.stderr; then
  exit 1
fi
rg -F 'a method cannot return a ~Escapable result' \
  .build/evidence/adr0041-span-negative.stderr

if xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -strict-memory-safety -warnings-as-errors -parse-as-library -c \
  -D ADR0041_RAW_SPAN_ESCAPE_SHOULD_FAIL \
  docs/progress/evidence/ADR-0041-storage-read-lifetime-probe.swift \
  -o .build/evidence/adr0041-raw-span-negative.o \
  2>.build/evidence/adr0041-raw-span-negative.stderr; then
  exit 1
fi
rg -F 'a method cannot return a ~Escapable result' \
  .build/evidence/adr0041-raw-span-negative.stderr
```

The final narrow gate for this documentation-and-evidence-only proposal is:

```bash
xcrun swift-format lint --strict \
  docs/progress/evidence/ADR-0041-storage-read-lifetime-probe.swift
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -strict-memory-safety -warnings-as-errors -parse-as-library \
  docs/progress/evidence/ADR-0041-storage-read-lifetime-probe.swift \
  -o .build/evidence/adr0041-probe
.build/evidence/adr0041-probe
# Run both negative full-compilation checks shown above.
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_prohibited_imports.py
git diff --check
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
```

No complete Swift package suite is required for this proposal. Product source,
package topology and dependencies did not change, so the focused positive and
negative probe configurations plus document, ADR-register, graph, import,
manifest and release-integrity checks are the affected surface.

Draft `RFC-0001` is stored at
`docs/rfcs/RFC-0001-storage-contract-and-logical-data-model-composition.md`.
It composes proposed `ADR-0039`, `ADR-0040` and `ADR-0041` while preserving
their Proposed status and every source gate. The Draft records:

- Core ownership of backend-neutral logical/representation, snapshot, read,
  lease, error and checked-erasure/witness contracts, private result-target
  admission, logical capacity, budget-token accounting and adoption;
- Storage ownership of concrete providers, owners, source/mapping allocations,
  mapping, I/O and synchronous resource release;
- Execution or explicit host/import ownership of later coherent `ImageData`,
  identity, metadata, provenance and cache publication;
- Metal ownership of dynamic generation/device-qualified residency;
- the exact logical-versus-representation and claim-versus-evidence domains;
- the Core-private exact-writable-capacity monotonic-fill/first-terminal-wins
  read transaction, budget reservation before fallible target construction,
  non-commit drain-before-return rule and independent live-byte ledger;
- copied-owner `Data.span`/`Data.bytes` evidence limits, the generic CoW alias-
  escape accounting gate and exact mapped authority/logical/representation/
  owner/snapshot/generation/file/range/alignment/change-policy/mapping-owner
  binding;
- rank-safe axis-zero-fastest logical ordinals, most-significant-byte-first
  scalar projection and physical-to-logical component decoding;
- 24 traceable controlled correction/disposition items across Foundation,
  MTA, CDMS, RPSS, Requirements, FVSP, module overviews/DocC and the proposed
  ADRs; and
- two governed mapped-storage options. The Draft recommends keeping production
  mapping in Foundation Phase 5 and correcting `VOX-STO-004`, MTA Stage 3 and
  proposed `ADR-0039`, but does not treat that recommendation as approval.

Independent authority/ownership and API/concurrency/lifetime reviews found no
P0 issue. Their P1 findings drove the allocated-scope governance wording,
explicit RFC/correction/ADR approval order, Core-versus-Storage allocation and
erasure split, allocation-after-reservation/drain-aware read machine, Data-alias
accounting gate, complete mapped-scope binding, rank-safe ordinal recurrence and
endian correction, M1 contiguous-provider
requirement and cumulative correction-gate classes. The reviews also preserved
the mapping conflict, builder/publication drift, FVSP descriptor/publication
drift, source-stamp/identity separation and full traceability union as explicit
gates. Final API/error names, wires, production limits, the complete logical
descriptor/component-role/pixel-padding projection, builder contract, real
mapping/no-copy evidence and all human approvals remain open.

The follow-on documentation increment reconciles proposed `ADR-0039` with that
composition. It removes the settled M1 mapped-provider claim, public async-
destination/provider-stamped completion implications and normative builder-
fixture authority. The proposal now records:

- one Core admission authority per provider lineage/budget domain, exact
  logical/representation/owner/snapshot/generation/witness binding and no
  provider/caller authority injection;
- budget reservation before fallible private-target construction, co-located
  live-byte token, Core-only fill close/stamping/commit and non-commit drain;
- complete owned results, non-authoritative source stamps, retained alias
  accounting and source-gated synchronous owner-retaining `Data` scopes;
- the complete mapped authority/descriptor/resource tuple and immutable stable-
  snapshot rule;
- builder acquisition/freeze as a separately gated future contract rather than
  accepted M1 authority; and
- mapping option 1/2 as an unresolved governed choice, with one owned contiguous
  provider retained in M1 under either branch.

Draft companion
`docs/rfcs/RFC-0001-controlled-correction-delta.md` maps every `C01`–`C24`
row to the exact current sections, proposed `0.1.2` revision targets, role-based
owners/reviewers, replacement/addition/no-change text and cumulative `A/S/I/M`
gates. It defines atomic application order and conditional requirement counts,
but leaves mapping and M1 structural-versus-M2 public `ImageData` choices open.
The companion consumes no `RFC-0002` identifier and has no authority of its own.

A focused requirements-table oracle confirmed the controlled baseline counts
M1 `53`, M2 `57`, M5 `39` and all four conditional branches: mapping option 1
plus `C24` A is `51/58/40`; option 1 plus `C24` B is `52/57/40`; mapping option
2 plus `C24` A is `52/58/39`; option 2 plus `C24` B is `53/57/39`. These are
review arithmetic only; the selected Requirements revision must regenerate its
own tables/indexes before approval.

Independent lifetime/API and controlled-governance reviews found no P0 issue.
Their P1 findings added complete authority/descriptor/owner/generation mapping
bindings, pre-admission freshness checks, result-stamp limits, builder deferral,
the 17 directly affected ADR-0039 requirement IDs, exact six-file `C17`
application scope, deterministic `C24` targets/counts and the required accepted-
RFC-before-effective-corrections approval transition. Post-fix re-reviews pass.

The ADR-0039 probe is not rerun: the proposal now explicitly classifies its
provider/destination completion and actor-backed builder shapes as older narrow
fixtures rather than changing that evidence. Product source, package topology,
dependencies and runtime behaviour remain unchanged.

The final narrow gate for this documentation-only RFC/ADR/correction increment
is:

```bash
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_prohibited_imports.py
git diff --check
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py
```

The focused gate passes: documentation validation covers 69 Markdown files and
21 ADR records; static package-graph and prohibited-import checks pass;
`git diff --check` passes; and release regeneration reports 393 manifest paths, 392
inventory records and 393 checksums. A Python standard-library inline governance
oracle parsed the RFC/companion/ADR front matter and links, proved 97 identical
parent/companion requirement IDs, 69 unique reconciled ADR-0039 IDs, exactly 24
parent correction IDs and companion headings, RFC-acceptance-before-effective-
corrections ordering, and the four conditional count branches. Relative targets
for every modified RFC/ADR link exist.

The ADR-0039 through ADR-0041 probes are not rerun because this Draft changes no
evidenced invariant. No complete Swift package suite is required: product
source, package topology, dependencies and runtime behaviour do not change.

The follow-on tooling increment replaces the one-off RFC governance oracle with
`Tools/Scripts/check_rfc_register.py`. The standard-library checker now:

- classifies every `docs/rfcs/*.md` record from front matter and rejects
  malformed, zero or duplicate primary/`CCD` identifiers;
- requires exact RFC/companion metadata, real ISO dates, H1 and required RFC
  section topology, explicit `Non-authoritative proposal` authority and a
  live Draft approval table with no effective revision/commit;
- fails closed on every lifecycle value other than exact `Draft` because the
  project has not governed a machine-readable Accepted approval schema;
- validates the one live primary register table, exact status/title/target,
  gap-free next numeric allocation and the separately allocated
  `RFC-0001-CCD-01` companion without consuming `RFC-0002`;
- validates reciprocal rendered inline links, local relative file targets and
  the exact parent correction-inventory anchor while rejecting link-hiding raw
  HTML/reference forms in the governed subset;
- proves the parent/companion requirement lists are identical, unique, known
  Requirements Baseline IDs and exactly the affected-requirement union of
  proposed `ADR-0039` through `ADR-0041` plus the three `C17` documentation
  requirements; and
- requires one live correction-inventory table and one live proposed-delta
  section containing only the ordered `RFC-0001-C01` through `C24` values.

Twenty-eight focused positive/negative fixture tests cover the repository
record, IDs, metadata, dates, filenames/headings, parent/allocation/link drift,
Draft authority/effectiveness, requirement provenance, missing/duplicate/
malformed/foreign/reordered correction IDs, table topology and Markdown
literal/comment/fence/link-hiding cases. A stale ADR regression assertion was
also made data-driven so record growth cannot silently break the repository
tooling gate. Independent governance and adversarial parser reviews pass with
no remaining P0/P1 issue.

The focused validation commands for this documentation-tooling increment are:

```bash
python3 -m py_compile \
  Tools/Scripts/check_rfc_register.py \
  Tools/Scripts/check_required_files.py \
  Tools/Tests/Python/test_rfc_register.py \
  Tools/Tests/Python/test_adr_register.py \
  Tools/Tests/Python/test_repository_scripts.py
python3 -m unittest \
  Tools.Tests.Python.test_rfc_register \
  Tools.Tests.Python.test_adr_register \
  Tools.Tests.Python.test_repository_scripts
python3 Tools/Scripts/check_rfc_register.py
python3 Tools/Scripts/check_required_files.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_prohibited_imports.py
git diff --check
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py
```

The focused checker suite reports 59 passing tests, direct RFC validation
reports one primary and one companion with both statuses Draft, required-file,
documentation, graph, import and diff checks pass, and structural validation
explicitly reports that it confers no authority. The broader repository-script
suite is not a completion claim for this change: an independent attempt reached
an unrelated existing 60-second Swift package-dump timeout in the SBOM test.
No complete Swift build/package suite or ADR Swift probe is required because no
product source, dependency, package edge, runtime invariant or evidence probe
changed.

The focused gate for the M1 Swift-safety increment is:

```bash
python3 -m py_compile \
  Tools/Scripts/check_swift_safety.py \
  Tools/Scripts/check_required_files.py \
  Tools/Tests/Python/test_swift_safety.py \
  Tools/Tests/Python/test_repository_scripts.py
python3 -m unittest \
  Tools.Tests.Python.test_swift_safety \
  Tools.Tests.Python.test_repository_scripts
python3 Tools/Scripts/check_swift_safety.py --compile
python3 Tools/Scripts/check_required_files.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/generate_requirement_index.py --check
git diff --check
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py
```

The focused Python suites pass 56 tests: 44 direct safety-gate fixtures and 12
repository/workflow checks. The inventory covers 116 current repository-owned
Swift files and 44 active configuration files. It admits checked vocabulary
while rejecting escape-hatch syntax, compiler/configuration weakening,
unexpected execution scope, orphan/excluded target sources, runtime-selected
manifest settings and adversarial diagnostic/subprocess-output volume.

The first strict compiler-gate attempt correctly exposed that release
`--build-tests` does not enable `@testable` imports. The release command now
adds `-enable-testing`; the final rerun passed product and test compilation for
the root, Validation, Benchmarks and Tools packages in both debug and release
with `-strict-memory-safety -warnings-as-errors`. Package metadata/build
metadata commands use repository-neutral Git metadata, a 60-second bound and a
4 MiB captured-output limit; streamed build commands use a 300-second bound.
Both use process-group cleanup after earlier unbounded `git describe`
inspection attempts were terminated. One final semantic rerun
correctly failed at the 60-second metadata bound while two separate diagnostic
SwiftPM help commands held the root build lock; those exact stale process
groups were terminated, and the clean rerun passed all eight package/
configuration builds.

The final `Tools/Scripts/test-platforms.sh` wrapper passed strict product/test
builds in both Debug and Release for macOS, iOS device/simulator and tvOS
device/simulator. It stopped at the generic visionOS destination because Xcode
reports the visionOS 26.5 platform component as not installed; a separate
strict visionOS Simulator `build-for-testing` attempt reported the same
unavailable destination. Neither is recorded as passing, and installing the
external component was not attempted. No Swift test case was executed by these
build-only safety oracles, and no full Swift test suite or blocked storage/
metadata probe was run.

The security workflow and complete scaffold now invoke the same fail-closed
host/package gate without an always-success fallback, while the platform
workflow supplies destination-specific compiler coverage. Required-file,
documentation, requirement-index, diff and release-ledger checks passed after
the final independent review and ledger regeneration.

## Known blockers and risks

- The Drive baseline encoded separate `Logs/` and `logs/` directories, which are incompatible with standard case-insensitive macOS volumes; the local repository now uses one lowercase directory and corrected ledgers.
- Architecture documents still disagree on storage-abstraction ownership and future segmentation/registration module boundaries.
- Approval documents still contain status and sign-off inconsistencies that require governance review before formal acceptance.
- The traceability index still lacks source digest and lifecycle/status fields promised by scaffold specification section 37.1; this is separate from the corrected count drift.
- No public repository or remote is configured.
- External GitHub governance and any push/publication require explicit user authorization.
- Xcode reports the visionOS 26.5 platform component as not installed, so both
  generic and simulator visionOS evidence remain open. Installing the component
  is a large external toolchain change and was not attempted silently.
- The Master Technical Architecture section 9.2 sketches element count as an
  optional property, while the more detailed Core Data Model Specification
  section 11.1 defines a throwing method and the exact overflow error. The M1
  implementation follows the detailed throwing contract; the older sketch
  remains a controlled-document correction for later governance review.
- The index specification defines validity only relative to a shape and does
  not define constructor errors for empty or negative standalone components.
  `ImageIndex` therefore preserves supplied coordinates without claiming bounds
  validity; shape-aware validation remains a separate API decision.
- The architecture calls axis-zero-fastest ordering "row-major", although that
  label is conventionally ambiguous. Future offset work shall follow the
  explicit axis-zero-fastest rule.
- The region specification permits transient empty regions but requires
  `extents()` to return `ImageShape`, whose extents must be positive. The
  implementation permits empty construction and lets `extents()` return the
  existing `ShapeError.nonPositiveExtent`; no unrelated region error was
  reassigned to conceal this controlled-document ambiguity.
- Scalar-format derived-property signatures and placement are not fixed by the
  controlled documents. The implementation records the selected names and a
  tagged `ScalarValueRange` as a controlled interpretation, preserving exact
  `Int64` and `UInt64` endpoints instead of coercing every range to `Double`;
  `isSignedInteger` avoids applying ambiguous Boolean signedness to floats.
- The specification's "finite-value support" wording is ambiguous. The public
  `supportsNonFiniteValues` property makes the useful distinction explicit:
  only floating-point types encode infinity and NaN.
- Component-model wording says `.scalar` shall "normally" have count one, so
  the isolated descriptor accepts larger positive scalar counts. Strict
  scalar-image consistency remains deferred to image-semantic validation.
- Component enums use explicit stable strings matching the descriptor example;
  namespaced generic interpretations use a documented structured object.
  Cross-model canonical JSON byte ordering remains an open serialization decision.
- Master Technical Architecture section 9.6 sketches a payloadless `.generic`
  image semantic, while the newer Core Data Model Specification section 17.1
  requires namespace and name payloads. The detailed data-model contract governs
  the implementation; the older sketch remains controlled-document drift.
- Swift `Decoder` exposes keyed values only after duplicate raw JSON keys have
  been collapsed. These value-type decoders reject unknown and extra distinct
  fields but do not claim full Core Data Model Specification section 55.3
  compliance; duplicate-key rejection must occur at the future canonical-JSON
  byte-ingress boundary before `Codable` decoding.
- The controlled documents prescribe `SemanticVersion` fields and conformances
  but no initializer or exact error vocabulary. The implementation uses a
  dedicated `SemanticVersionError` to distinguish negative core components
  from malformed prerelease and build identifier sequences.
- Semantic Versioning defines build metadata as precedence-neutral but does not
  define Swift value identity. `SemanticVersion` equality and hashing ignore
  build metadata, matching `<` and preserving `Comparable`'s total-order law;
  the metadata remains available and round-trippable on each stored value.
- The M1 acceptance checklist does not name `SemanticVersion`, although the
  Core Data Model Specification's type-to-milestone appendix assigns it to M1.
  The appendix governs implementation sequencing without claiming checklist
  completion.
- The Core Data Model Specification lists the initial unit dimensions but does
  not declare `UnitDimension` itself. The implementation uses the least
  expressive stable string enum matching that list, including a payloadless
  `.custom`; namespaced unit identity remains on `MeasurementUnit`.
- The exact measurement-unit initializer and error vocabulary are not
  prescribed. A Spatial-owned `MeasurementUnitError` avoids reversing the
  Core-to-Spatial dependency, while finite conversion validation follows the
  descriptor identity rules for floating-point values.
- The controlled documents do not define a canonical unit per dimension, an
  affine conversion formula, or whether scale and offset must form a pair.
  The descriptor therefore accepts each optional finite field independently
  and provides no conversion operation or inferred default.
- `MeasurementUnit` semantic equality uses exact accepted UTF-8 namespace/code
  spelling, includes dimension and conversion declarations, and excludes its
  human-readable display label. It is not a unit-compatibility predicate. A
  future canonical digest cannot blindly hash ordinary encoded unit values,
  because equal semantic values may preserve different display labels.
- Its exact six-key decoder is strict only after a general `Decoder` has
  produced keyed values. Raw duplicate-key rejection, lexical number and
  escape normalization, key ordering, schema envelopes, Unicode digest
  normalization and pre-allocation resource limits remain byte-ingress work.
- There is no dedicated `VOX-UNIT-*` requirement, and units are assigned to M1
  by the implementation sequence and type inventory but omitted from the M1
  checklist. This slice does not treat that baseline gap as acceptance.
- The Master Technical Architecture assigns axis descriptors to
  `VoxeliaSpatial`, while the Core Data Model Specification's module table and
  type inventory assign `AxisDescriptor` to `VoxeliaCore`. `AxisID` lives in
  the lower Spatial foundation so either eventual governance resolution remains
  possible without a dependency cycle; no descriptor ownership is claimed yet.
- `AxisID` is referenced by the canonical axis shape but never declared. It is
  implemented as a distinct `VoxeliaStringIdentifier`, matching the prescribed
  identifier pattern without inventing built-in axis constants.
- `RawRepresentable` requires an untyped failable `init?(rawValue:)`, while the
  public-initializer policy requires typed validation errors. Identifiers expose
  both that required initializer and `init(validating:)`, with identical blank
  input validation.
- Identifier JSON shape is not fixed by the canonical serialization schema.
  The current explicit `{ "rawValue": ... }` form follows the controlled struct
  examples and revalidates decoded data; schema wrapping, byte ordering and raw
  duplicate-key rejection remain deferred to the canonical JSON boundary.
- The specification requires normalized identifier strings for future identity
  digests but defines no Unicode normalization algorithm. Accepted identifiers
  are therefore preserved without silent normalization; canonical digest work
  must settle this before claiming stable cross-system identity.
- Full `VOX-SPA-005` evidence remains pending coordinate conventions and
  `CoordinateSpaceDescriptor`; distinct representative raw identifiers alone
  do not complete that requirement.
- The governing Master Technical Architecture assigns axis descriptors to
  `VoxeliaSpatial`, but the Core Data Model Specification and First Vertical
  Slice Plan assign them to `VoxeliaCore`. The Core Data Model Specification
  requires this discrepancy to be resolved by controlled-document correction,
  revision or an approved ADR before implementation. Axis work is deferred,
  with Spatial ownership recorded only as the audit recommendation.
- `Matrix4x4Double` currently guarantees the canonical finite storage shape,
  not transform operations. The SIMD-versus-custom public vector boundary,
  multiplication implementation, two-dimensional representation and a
  scale-aware singularity tolerance remain open decisions; `VOX-SPA-008` and
  `VOX-SPA-009` are not claimed by this storage slice.
- `Matrix4x4Double` normalizes `-0.0` to `+0.0` because Swift equality and
  hashing treat them as the same value and the identity rules require one
  canonical representation where semantic equality does. NaN and infinity are
  rejected; approximate geometric equivalence remains a separate future API.
- The MTA defines `CoordinateConvention.custom(name:)`, while the detailed
  data-model specification defines `custom(namespace:name:)` and adds
  `.cartesianLeftHanded` and `.imageDisplay`. Both public API shape and custom
  physical-unit policy require controlled-document correction or an approved
  ADR; coordinate-space implementation is deferred.
- The MTA sketches fixed `SIMD3<Int>` axes on `AffineGridGeometry`, while the
  detailed data-model specification requires a one-to-three-axis
  `SpatialAxisMapping`. The standalone mapping is additive and unambiguous, but
  affine-geometry integration is deferred pending the same required governance
  process.
- `SpatialAxisMapping` accepts any unique nonnegative axis, including
  `Int.max`, because no image rank is stored. Geometry or descriptor binding
  must reject `axis >= imageRank` before the mapping is used.
- The Point3D/Vector3D initializer and specialized error vocabulary are not
  prescribed. The shared Spatial-owned error avoids a reverse Core dependency;
  component indices 0/1/2 are documented as X/Y/Z.
- A zero `Vector3D` remains valid as a general displacement. Plane, ray,
  normal, direction and normalization consumers must impose non-zero magnitude
  explicitly and must not silently normalize.
- Spatial primitives carry only a `CoordinateSpaceID`, not a unit, convention
  or transform. Matching IDs participate in exact value identity but do not by
  themselves prove physical equivalence or authorize coordinate conversion.
- Plane/ray constructor and error names are not prescribed. The implementation
  treats exact identifier equality as the only currently safe compatibility
  rule and reports the origin space as expected and the vector space as actual.
- Plane/ray non-zero validation is exact and tolerance-free. Numerical
  conditioning and any normalization operation require a separately specified,
  explicit API; neither is inferred by these value constructors.
- `AxisAlignedBounds3D` establishes the canonical value representation but does
  not complete `VOX-SPA-010`; index/geometry-to-physical bounds computation and
  centre-versus-sample-support selection remain future operations.
- `OrientedBounds3D` is deferred because the specifications do not define axis
  count, unit length, orthogonality, handedness, tolerances, half-extent
  validity, degeneracy, axis-to-lane ordering, centre/axis space agreement or a
  stable public `SIMD3<Double>` serialization shape.
- Ray/bounds and plane intersection APIs remain blocked because the documents
  do not select a result type, ray parameter domain, boundary/tangent/parallel/
  coplanar behavior, versioned tolerance, extreme-intermediate policy or typed
  failure model. Bounds interpretation and transformed-space integration are
  additional downstream concerns, not prerequisites for an exact-space
  operation on caller-supplied values. Validation requirements for analytic
  entry and exit oracles do not by themselves define the public semantics.
- `InverseAvailability` is referenced only as a prose taxonomy; its public case
  names, encoding and capability-versus-evaluated-state lifecycle require a
  controlled correction or ADR before implementation.
- Executable spatial transforms remain blocked by that missing type, the open
  coordinate-space descriptor conflict, incomplete normal/inversion semantics
  and unresolved Core-to-Spatial provenance boundaries. The exact standalone
  `SpatialTransformKind` enumeration does not share those blockers.
- `SpatialTransformKind` is only a stable category vocabulary and does not
  claim transform execution, inversion, serialization descriptors or M1
  transform acceptance.
- `CoordinateHandedness` is only the stable declaration vocabulary. Consistency
  with a built-in convention remains a future descriptor invariant, and
  `.unspecified` does not imply compatibility with another handedness.
- External-frame namespace-specific syntax and equivalence remain adapter or
  host policy. Pair uniqueness is a future coordinate-space descriptor
  collection invariant and is not enforceable by one standalone reference.
- The MTA and CDMS disagree on `ValueTransform` cases and composition storage;
  `PiecewiseLinearDescriptor` is referenced but never defined, and raw enum
  payloads cannot enforce the required finite/non-empty invariants. Those public
  APIs require a correction or ADR before implementation.
- `LookupTableDescriptor` is independently unblocked. Its standalone contract
  requires finite ordered values but does not specify non-empty tables, lookup
  application, extrapolation or derived-domain overflow behavior.
- Proposed `ADR-0036` supplies a candidate correction for the incompatible
  controlled `ContentID` records: typed algorithm, required scope, bounded
  versioned projection, owned contiguous digest bytes and strict lowercase-hex
  coding. It remains Proposed and requires a public RFC, controlled MTA/CDMS
  reconciliation and maintainer approval, so no record or digest source is yet
  authorised.
- `DigestAlgorithm.custom` alone is not an approved persistent or distributed
  identity; it still needs a bounded namespaced/versioned algorithm profile.
  `.blake3` likewise lacks an accepted mode/output contract. Proposed
  `ADR-0036` authorises only SHA-256 for its complete-record profile and does
  not make the other taxonomy cases executable.
- `SourceIdentity`, `DerivationIdentity`, `DataIdentity` and
  `DataIdentityReference` remain product-source blocked. Proposed `ADR-0037`
  closes their conceptual claim-state, duplicate/order, non-recursive
  reference, assurance, lazy-publication and cache-admission boundary, but it
  is unaccepted and intentionally leaves exact source/operation identifiers,
  `DataObjectID` persistent identity, parameter/derivation/image projections,
  tagged reference wire/limits, enrichment lifecycle and the complete
  derivation/cache-key split unresolved.
- Recursive metadata source remains deferred. Proposed `ADR-0028` through
  `ADR-0030` supply leaf designs only if accepted, and proposed `ADR-0031`
  supplies validated containers, exact UTF-8 string identity, strict semantic
  tags, canonical exact-key object order and hard depth/work/payload ceilings.
  Proposed `ADR-0032` adds the required whole-entry privacy attachment, and
  proposed `ADR-0033` adds ordered collection construction, unique-only
  ordinary coding and explicit configured multiplicity admission. Proposed
  `ADR-0034` adds a closed exact-case typed-read mapping that preserves each
  entry's privacy class and fails cardinality or type mismatches without
  payloads. Proposed `ADR-0035` adds the generic versioned canonical envelope,
  exact schema-policy binding and duplicate-safe raw-ingress contract. Proposed
  `ADR-0036` adds only the domain-separated exact complete-record digest. None
  is accepted; the recursive/collection ceilings, universal canonical-document
  byte maximum, production floating codec, cancellation/device evidence,
  recoverable allocation-failure evidence and supported-destination evidence
  remain open, and no value, entry, collection, typed-read, codec or digest
  source is authorised. Schema trust/resolution, custom semantic conversion,
  privacy-authorised disclosure and semantic collection identity remain
  separate by design.
- `MetadataPrivacyClass` supplies a value-redacted vocabulary. Proposed
  `ADR-0032` resolves direct entry attachment, absence, whole-subtree scope,
  exact preservation, identity and type-level wire only if accepted. Public
  resolver shape, portable `hostDefined` identity, global downgrade enforcement,
  collection disclosure and logging/export APIs remain host or future-decision
  responsibilities. Proposed `ADR-0036` includes exact classes in one
  sensitive-derived complete-record digest but grants none of those powers.
- Metadata keys now define validated exact UTF-8 pair identity and a strict
  erased type-level wire shape. Namespace aliases, key erasure/conversion,
  multiplicity schemas and typed accessors remain deferred. Any future
  canonical-digest Unicode normalization must explicitly reconcile its
  equivalence relation with the exact in-memory identity.
- `CodedConcept` defines deterministic record identity, not external terminology
  equivalence. Scheme-specific aliases, version compatibility and ontology
  resolution require an explicit resolver or ADR.
- Provenance records, software/operation/execution details, warnings and graph
  references remain blocked by undefined types, identifiers, `ContentID`,
  validation-state schema and canonical projections. Proposed `ADR-0028`
  supplies the `createdAt` policy only if accepted, while Proposed `ADR-0038`
  closes subject/activity/input state, ownership, graph admission, claim versus
  evidence, privacy and publication conceptually. Neither authorises source;
  `ProvenanceKind` does not imply that records exist or are verified.
- Execution quality profiles have four required behavioral categories, but the
  documents provide no normative declaration and alternate between undefined
  `ExecutionProfile` and `ExecutionProfileDescriptor` names with unresolved
  Execution-versus-Core provenance ownership. `ExecutionPriority` and
  `DeterminismRequirement` have no case vocabularies or ordering semantics.
- `BackendPreference` appears only in a non-final appendix sketch whose
  automatic/CPU/Metal/required-ID cases do not match the requirement baseline's
  reference/CPU-preferred/GPU-preferred/automatic host policies. Fallback and
  exact-selection semantics, `BackendID` and stable encoding remain undefined.
- `OperationID` is named but not declared. Applying the mandated shared string-
  identifier pattern would add an unapproved Spatial dependency to Execution;
  duplicating it would fork the common contract. `OperationVersion` is likewise
  unresolved against Core's `SemanticVersion`, and implementation IDs and
  generation/revision tokens lack stable public representations.
- `ValidationStatus` and `DataIntegrityState` remain deferred: their tagged
  associated-value wire shapes, evidence/reason validation and trust semantics
  are undefined, and integrity state also depends on the blocked `ContentID`.
- `StorageCapabilities` is deferred because the MTA/CDMS flag sets and writable
  spelling disagree, while the MTA, CDMS and RPSS also disagree about whether
  capabilities, protocols and type erasure belong to Core or Storage.
- Neither document assigns stable public `UInt64` bit positions, reserved bits,
  unknown-bit behavior or an exact Codable representation. Sequential-only
  region reads, builder acquisition, content-digest availability and trust,
  flag implications and the required residency characteristic also remain
  undefined, so those choices cannot be resolved safely in isolation.
- `StorageDescriptor`, storage protocols and type erasure remain blocked by an
  undefined integrity/destination descriptor, incomplete byte-layout validation,
  buffer-lifetime API decisions and independent unchecked-Sendable gates.
- Tiled/bricked descriptors remain blocked by undefined resolution levels,
  public SIMD decisions, `ContentID`, spatial geometry and cross-field
  invariants. `BrickStatistics` also lacks the required raw-versus-authoritative
  value-domain field.
- `CompressedRegionAccess` records declared granularity only; it neither proves
  codec support nor defines canonical digest JSON. The custom case preserves
  even empty namespace/name strings because the directly constructible public
  enum has no specified validation rule.
- The geometry taxonomies are declaration values only. Custom semantic registry
  policy and canonical digest JSON remain undefined, and `MeshDescriptor` stays
  deferred with the blocked coordinate-space descriptor and unspecified
  topology/index-buffer binding validation.
- `SegmentAlgorithmType` and `ConvergenceStatus` have exact case vocabularies,
  but their owning `VoxeliaSegmentation` and `VoxeliaRegistration` products may
  be introduced only when M7 begins and the complete optional-module activation
  review is supplied. The controlled model also leaves open which segmentation
  and registration types may become public before M7, so neither enum may be
  relocated into an active module for convenience.
- `PhotorealisticQuality` has an exact three-case declaration without raw-value
  or `Hashable` commitments, but it belongs to `VoxeliaPhotorealisticRendering`.
  That optional product cannot be activated before M8, and its stable wire
  encoding remains unspecified; placing the type in conventional Rendering or
  adding String raw values would change the documented boundary or API shape.
- `GeometryAttributeDescriptor` validates only invariants knowable from one
  attribute. Element-domain agreement, normal/position compatibility and
  required position presence remain binding-level rules and are not inferred.
- Extent-based region construction does not imply containment in an image.
  Negative origins remain valid until the separately specified shape-aware
  access validation runs.
- The containment validator is supporting unit evidence for `VOX-STO-007` and
  `VOX-SEC-001`, not completion evidence. No storage-read implementation yet
  proves that it calls the validator, and other external dimensions, strides,
  offsets and allocation sizes remain separate validation obligations.
- Region translation deliberately does not validate or restore containment.
  Callers that translate an access region must explicitly validate the result
  against its target shape before memory access.
- Shape clipping returns a rectangular region even when the source is wholly
  disjoint, using a boundary-empty representation rather than nil. It does not
  authorize a storage read; empty-read policy remains operation-specific.
- `CDMS-13.4` test labels link to the controlled region-operations section
  because the requirements baseline has no dedicated clipping identifier; they
  neither create a new requirement nor imply `VOX-RGN-002` specifies clipping.
- `CDMS-13.4` also governs region/index containment tests because the baseline
  has no dedicated point-containment requirement. This query does not validate
  an index against an image shape or prove storage offset safety.
- Shape/index containment implements the exact `CDMS-12.3` predicate and uses
  the existing `ShapeError.rankMismatch`, but it does not calculate a stride or
  linear offset and is only supporting evidence for access-safety requirements.
- `ImageRegion.isEmpty` identifies the transient empty values permitted by
  `CDMS-13.3`; it does not decide whether a storage operation accepts a no-op
  read or must throw `RegionError.emptyRead`.
- Region element count follows `CDMS-13.4` and is safe for allocation planning,
  but it neither authorizes an empty storage read nor establishes byte length,
  which still depends on component and storage layout.
- `ResidencyPolicy` is declaration vocabulary from MTA section 18.2 only. Its
  synthesized `Codable` wire representation is not claimed as canonical, and a
  case does not prove device capability, resource allocation, fallback,
  residency-manager state or memory-pressure behavior.
- MTA Appendix A already assigns `ADR-0001` through `ADR-0020`, while the
  scaffold contains a different accepted platform `ADR-0001`. New proposals
  start at `ADR-0021`; proposed `ADR-0024` recommends re-identifying only the
  platform record as `ADR-0025`, but the collision remains until that proposal
  is accepted and its atomic migration is completed.
- `ADR-0025` is not an existing or accepted decision. While `ADR-0024` remains
  Proposed, the current platform filename, identifier, links and policy-script
  paths must not change.
- The ADR checker intentionally validates file-backed records only. It does not
  compare them with MTA Appendix A while the known `ADR-0001` collision remains
  unresolved, and it does not treat body mentions or the `ADR-0025` allocator
  hold as record assignments.
- The checked-in template and all seventeen file-backed ADRs now contain the RPSS
  section 9.2 areas, and the ADR checker enforces their presence, uniqueness and
  meaningful bodies. It intentionally does not infer decision quality, status
  transitions, module validity or supersession semantics from prose.
- Proposed `ADR-0021` is review material only. Until its status becomes
  Accepted and subordinate documents are corrected, the axis-model public API
  remains blocked and no implementation may rely on its recommendation.
- Proposed `ADR-0022` likewise does not resolve the convention conflict until
  accepted. Even after acceptance, `CoordinateSpaceDescriptor` remains blocked
  because its exact five fields do not classify physical versus logical
  Cartesian/custom/display spaces. The enum must not imply a unit, transform,
  display-axis policy or external frame identity.
- Proposed `ADR-0023` does not resolve the transform conflict until accepted.
  Piecewise-linear transforms remain undefined, and lookup declarations do not
  establish interpolation, missing-entry or extrapolation behavior.
- The exact in-memory `ImageDescriptor` declaration remains transitively blocked
  even if proposed `ADR-0021` through `ADR-0023` were accepted: coordinate-
  space descriptor policy, affine shape and construction tolerance,
  rectilinear binding and frame-set binding are still incomplete. Full M1
  descriptor acceptance is additionally blocked by canonical JSON.
- Spatial-owned `FrameGeometry` is specified with Core-owned `ImageIndex`, but
  the approved dependency direction is `Core -> Spatial`; implementing that
  shape in Spatial would create a prohibited reverse edge or cycle.
- Proposed `ADR-0027` does not resolve that boundary until accepted. It may
  authorise only the standalone `FrameAnchorIndex` leaf and controlled CDMS
  correction; `FrameGeometry`, frame-set ordering, sparse/enhanced coverage,
  coordinate-space compatibility and regularity assessment remain blocked.
- Proposed `ADR-0028` does not authorise `CanonicalInstant` until accepted. It
  may authorise only the standalone Core leaf and replacement of the two
  controlled raw-string declarations; metadata aggregates, provenance records,
  timestamp acquisition/conversion and canonical byte ingress remain blocked.
- Proposed `ADR-0029` does not authorise `MetadataFloatingPoint` until
  accepted. It may authorise only the standalone Core leaf and replacement of
  the controlled raw `Double`; metadata aggregates, named exceptional values,
  source-decimal preservation and canonical numeric bytes remain blocked.
- Proposed `ADR-0030` does not authorise `MetadataBinary` until accepted. It
  may authorise only the standalone Core leaf and replacement of the controlled
  raw `Data`; metadata aggregates, exact host resource limits, privacy
  attachment and canonical document bytes remain blocked.
- Proposed `ADR-0035` does not authorise a canonical parser or emitter until it
  and `ADR-0028` through `ADR-0033` are accepted. Its exact v1 grammar is review
  material only; the universal canonical-document byte maximum, vetted shortest-
  round-trip binary64 implementation, cancellation latency evidence under the
  fixed work cadence, complete chunk/fuzz corpus, frozen-whitespace correction
  in Core and Spatial metadata identity constructors, recoverable allocation-
  failure evidence and lowest-resource supported-device evidence remain
  acceptance blockers. Proposed `ADR-0036` separately names those bytes as one
  exact domain-separated complete-record digest, but it too remains Proposed
  and grants no export authorisation.
- Proposed `ADR-0036` does not authorise `ContentID`, CryptoKit hashing,
  verification, cache/provenance integration or recursive metadata source. Its
  public API needs the required RFC and controlled-document correction; its
  VCMJ projection also depends on acceptance and evidence closure for
  `ADR-0028` through `ADR-0035`. Semantic collection identity, general image
  identity, custom/BLAKE3 algorithms, standalone Content-ID raw ingress,
  signatures and keyed identities remain separate decisions.
- Proposed `ADR-0037` does not authorise source/derivation/data-identity values,
  trust state, lazy resolver, result-cache key, cache integration or provenance
  integration. A content-shaped or source-carried digest always remains a
  claim value; external evidence may separately admit the exact tuple for one
  pinned snapshot and policy context. Its logical reference cases include an
  undefined `DerivationRecordID`, so the displayed target is review material
  rather than an implementable enum.
- Proposed `ADR-0038` does not authorise provenance records, parent/input
  references, graph containers/builders, execution snapshots, warning or
  validation types, canonical record/manifest wire, provenance digest,
  resolver, signed manifest, assurance bridge, cache integration or atomic
  publication source. Its probe limits and content claims are deliberately
  non-production. Acceptance still requires upstream ADRs, the public RFC,
  controlled corrections, exact persistent identifiers/projections, hostile-
  input/device/cancellation evidence and designated reviews.
- Proposed `ADR-0039` does not authorise storage descriptors, capabilities,
  protocols, destinations, builders, erasure, taxonomy migration, digest
  implementation, mapping/no-copy access or residency source. Its exact bits,
  wire and probe limits are review material. Acceptance still requires the
  public RFC, controlled ownership/API/milestone corrections, normalized
  logical sample projection, production resource limits, safe destination and
  owner-retaining erasure design, supported-destination evidence and designated
  API/concurrency/security reviews.
- Proposed `ADR-0040` does not authorise logical-sample binding, source-bit
  decoder, representation descriptor, projection hashing, `ContentID`, cache,
  storage compatibility or image-descriptor migration source. Its labels,
  frames, limits and probe digests are unregistered evidence only. Acceptance
  still requires the public RFC, controlled MTA/CDMS/RPSS/Requirements
  corrections, the complete logical descriptor and semantic-role/pixel-padding
  projections, production limits and cancellation/device evidence, affected
  Core/Geometry tests, supported Apple destination builds and designated API,
  numerical, storage, security and privacy review.
- Proposed `ADR-0041` does not authorise storage/read/lease/erasure/result
  source, actual allocation or mapping, unsafe/no-copy access, mutable
  destinations/builders, `ImageData` publication or `@unchecked Sendable`.
  Its toy transaction/lifetime probe is review evidence only. Acceptance still
  requires the public storage/data-model RFC, acceptance of proposed
  `ADR-0039`/`ADR-0040`, controlled Foundation/MTA/CDMS/RPSS/Requirements and
  module-overview corrections, a governed resolution of the M1-versus-Phase-5
  mapping conflict, final API/errors, production resource limits, real
  allocation/mapping/fault/device evidence and designated API, concurrency,
  storage, security, privacy and memory-lifetime review.
- Draft `RFC-0001` is not an accepted public contract or controlled correction.
  Its recommended Foundation-preserving mapping schedule remains a governed
  choice. Proposed `ADR-0039` now records that conflict without selecting it,
  and Draft `RFC-0001-CCD-01` supplies proposed target revisions, role-based
  owners and exact conditional text for all 24 correction/disposition rows.
  Mapping, M1 `ImageData` staging, named approvers, effective `0.1.2` revisions,
  dates and commits remain open; the Draft companion closes none of those gates.
- RFC tooling now validates companion metadata, parent/register/link
  consistency, requirement provenance, correction cardinality and the current
  fail-closed Draft authority surface. It cannot enforce named `docs/rfcs/`
  owners/signatories or validate an Accepted transition because no governed
  role assignment or machine-readable approval schema exists. Those remain
  external governance gaps and the checker deliberately grants no authority.
- The downstream `ImageData` shape places a storage-erased value beside
  Core-owned descriptor, metadata, provenance and identity values. MTA assigns
  storage protocols/type erasure to Core, whereas CDMS assigns them to Storage
  and RPSS fixes the live `Storage -> Core` package edge; Core cannot import a
  Storage-owned `AnyImageStorage` without a cycle. Proposed `ADR-0039` selects
  the MTA/RPSS direction but remains unaccepted.
- Core-owned execution provenance names unresolved execution-profile, backend
  and approximation types. Proposed `ADR-0038` reconciles ownership by keeping
  only future backend-neutral immutable claim snapshots in Core and assigning
  live capture/assembly to Execution, but exact snapshot types remain undefined
  and the proposal is unaccepted. Core still cannot import Execution through
  the live `Execution -> Storage -> Core` graph.
- Proposed `ADR-0026` does not authorise the ray/bounds operation until
  accepted. Its binary64-v1 result classifies the specified rounded model, not
  arbitrary exact-rational geometry; a versioned algorithm specification and
  focused Swift evidence remain acceptance-only migration work.
- Point containment and axis-aligned bounds intersection are supporting
  evidence for `VOX-SPA-011`, not completion: the requirement also covers
  oriented bounds plus rendering or interaction intersections involving the
  existing plane and ray values, which remain blocked or unimplemented.

## Exact next action

Close the existing `ScalarFormat` invalid-data evidence leaf without changing
production API. Add `VOX-ERR-001` traceability to its invalid-bit-count
constructor and decoding tests, then require the decoding assertion to prove
`DecodingError.dataCorrupted`, a terminal `validBitCount` coding path and
underlying `DataModelError.invalidScalarFormat`. Record this as Core invalid-
data evidence only, not completion of global `VOX-ERR-001` or `VOX-VAL-001`.
Do not add allocation, storage, cancellation, backend, shader or convergence
cases, accept Proposed ADRs/RFCs, edit controlled `v0.1.1` baselines or start a
blocked aggregate.

## Test policy for the next action

- Run only `swift test --filter ScalarFormat`, the owning
  `swift build --target VoxeliaCore`, strict format lint for
  `Tests/VoxeliaCoreTests/ScalarFormatTests.swift`, requirement-index and
  release-integrity checks. Add no direct-dependant build because the public API
  is unchanged. Do not run blocked storage/metadata probes or the complete
  Swift package suite.
- Do not rerun the complete scaffold suite unless a later cross-cutting change
  affects its gate or a release candidate is being accepted.
- Keep unavailable SDKs, signing contexts, repository settings and human
  approvals recorded as explicit evidence gaps rather than treating them as
  passing.
