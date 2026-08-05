# Voxelia autonomous progress ledger

Last updated: 2026-08-04 (Asia/Kolkata)

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
- Governance: `ADR-0021` was accepted by the project owner on 2026-08-04,
  resolving the axis-model ownership conflict in favour of `VoxeliaSpatial`
  ownership of `AxisID`, `AxisSemantic`, `AxisSampling` and `AxisDescriptor`
  with Core-owned image-descriptor binding validation. Its migration steps
  (controlled CDMS/FVSP corrections, Spatial implementation with focused
  tests, Core binding validation, traceability and release evidence) are now
  authorised and tracked through this ledger. Migration step 1 is complete:
  controlled-correction record `CCR-0001` under
  `docs/architecture/corrections/` quotes the exact conflicting CDMS
  section-6/Appendix-A and FVSP section-14 baseline rows, states the
  corrected ownership rows and records the owner approval; the immutable
  `v0.1.1` files are unedited and a future `v0.1.2` revision set must
  incorporate the corrected rows verbatim. Migration step 2 is complete: the
  CDMS section-14 axis model (`AxisSemantic`, `AxisSampling`,
  `AxisDescriptor`, joining the existing `AxisID`) is implemented in its
  owning `VoxeliaSpatial` module with validated construction, strict
  revalidating wires and focused exact-evidence tests. Migration step 3
  (Core-owned descriptor-binding validation) remains blocked behind the
  other `ImageDescriptor` prerequisites; steps 4 and 5 are satisfied for the
  Spatial half by the new tests and regenerated evidence ledgers.
- Governance: `ADR-0022` was accepted by the project owner on 2026-08-04,
  selecting the namespaced six-case `CoordinateConvention` shape with exact
  built-in string tags and the strict namespaced custom object, owned by
  `VoxeliaSpatial`. Its migration steps (controlled MTA section-10.2
  correction, Spatial implementation with focused tests, traceability and
  release evidence) are authorised; the separate `CoordinateSpaceDescriptor`
  unit policy remains an open approval. Migration steps 1-3 and 5 are
  complete: `CCR-0002` records the MTA correction, and
  `CoordinateConvention` is implemented in `VoxeliaSpatial` with the exact
  six-case wire, exact UTF-8 custom identity, a documented
  `impliedHandedness` projection that resolves nothing for `imageDisplay`
  or `custom`, and focused exact-evidence tests including the complete
  built-in handedness matrix.
- Governance: `ADR-0023` was accepted by the project owner on 2026-08-04,
  selecting the validated four-case `ValueTransform` intersection owned by
  `VoxeliaCore` (`identity`, `linear` with a validated finite descriptor,
  `lookupTable` reusing the existing validated descriptor, `composed` with a
  validated nonempty ordered composition) while deferring the undefined
  `piecewiseLinear` case and all lookup-execution behavior. `CCR-0003`
  records the controlled corrections to MTA section 9.9 and CDMS sections
  18.2/18.4, selecting the empty-composition rejection branch exactly.
  Migration steps 1-3 and 5 are complete: the three types are implemented in
  `VoxeliaCore` with validated construction, signed-zero canonicalization,
  strict revalidating one-tag wires and focused exact-evidence tests; step 4
  (lookup execution and piecewise-linear specification) remains separate
  later scope.
- Governance: `ADR-0026` was accepted by the project owner on 2026-08-04,
  selecting the versioned `ray-axis-aligned-bounds-intersection/binary64-v1`
  contract with typed representability failures. Its complete migration is
  executed: algorithm specification `VOXELIA-ALG-0001` under
  `docs/algorithms/`, the `RayAxisAlignedBoundsIntersection3D` transient
  result, `RayIntersectionParameterFailureReason`, two new
  `SpatialBoundsError` cases and the reference query on
  `AxisAlignedBounds3D` in `VoxeliaSpatial`, with the focused analytic and
  numerical suite including an independent evaluator cross-check.
  Ray-plane, oriented-bounds, transformed-space and point-evaluation
  operations remain deferred.
- Governance: `ADR-0027` was accepted by the project owner on 2026-08-04,
  replacing the cross-module frame-index reference with a Spatial-owned,
  full-rank validated `FrameAnchorIndex` and the minimum full-frame
  logical-anchor semantics needed for stable identity. `CCR-0004` records
  the controlled CDMS section-26.2 field correction
  (`frameAnchorIndex: FrameAnchorIndex`) and the Appendix A additions. The
  leaf and its strict wire are implemented in `VoxeliaSpatial`;
  `FrameGeometry`, frame-set ordering, sparse/enhanced coverage,
  coordinate-space compatibility and Core descriptor binding remain blocked
  by their own contracts.
- The existing `MeasurementUnit` leaf now has coherent semantic identity and
  type-level encoding: exact UTF-8 namespace/code spelling, display-text-
  independent equality and hashing, signed-zero normalization, and an exact
  six-key explicit-null wire shape. This does not define unit conversion or
  coordinate-space unit admissibility.
- Governance: `ADR-0031` was accepted by the project owner on 2026-08-04
  with all three leaf dependencies already accepted, and its authorised
  migration is executed. The bounded recursive `MetadataValue` is
  implemented in `VoxeliaCore` with validated `MetadataArray` and
  `MetadataObject` containers, the privacy-neutral nested object member,
  exact UTF-8 string identity, canonical unsigned-UTF-8 object member order
  with exact-key duplicate rejection, cached checked metrics, iterative
  equality and hashing, and the strict externally tagged one-member wire
  with exact decode-time depth tracking and incremental element/payload
  budgets. The three hard ceilings (depth 64, 1,048,576 logical structural
  elements, 64 MiB logical variable payload per recursive root) are
  accepted on local Apple Silicon boundary evidence; measured
  lowest-resource supported-device evidence remains an explicit open gap.
  `CCR-0008` records the controlled CDMS corrections. Proposed `ADR-0033`
  (ordered collection and multiplicity), `ADR-0034` (closed typed reads),
  `ADR-0035` (versioned canonical document and raw ingress) and `ADR-0036`
  (complete-record identity) remain unaccepted and authorise no source.
- Governance: `ADR-0032` was accepted by the project owner on 2026-08-04
  with its value dependencies already accepted, and its authorised
  migration is executed. The general `MetadataEntry` is implemented in
  `VoxeliaCore` with the required nondefaulted three-field initializer:
  every entry carries exactly one explicit immutable
  `MetadataPrivacyClass` governing the whole record (both key fields and
  the entire recursive value subtree), there is no valid unclassified
  entry in source or on the wire, and no implicit entry/member conversion
  exists. Identity includes the exact declared class, so equal key/value
  pairs under distinct classes never collapse. The class gains no
  severity order or aggregation helper; one-to-one transformations
  preserve the exact declaration, `hostDefined` stays unresolved and
  fails closed, and unknown wire tokens are rejected, never coerced. The
  strict three-field Codable rejects missing, null, distinct-extra and
  wrong-shaped fields with value-redacted errors whose model-relative
  paths name only the fixed fields and retain only audited payload-free
  project errors. `CCR-0009` records the controlled CDMS corrections.
- Governance: `ADR-0033` was accepted by the project owner on 2026-08-04
  with its value and entry dependencies already accepted, and its
  authorised migration is executed. The ordered `MetadataCollection` is
  implemented in `VoxeliaCore` with the payload-free
  `MetadataCollectionError` vocabulary and the bounded immutable
  `MetadataMultiplicityPolicy` exact-key allow-list. Ordinary
  construction and coding are unique-only by exact key; repeats require
  the explicit policy at the initializer or the configured
  `CodableWithConfiguration` call site, the policy is never serialised
  or stored, and every admitted occurrence and privacy declaration is
  retained in exact input order with order-sensitive equality and
  hashing. The five hard ceilings (1,048,576 entries, 1,048,576
  aggregate structural elements, 64 MiB aggregate logical payload,
  1,048,576 supplied policy keys, 64 MiB supplied policy key bytes) use
  checked accounting charged per occurrence, ordinary encoding of a
  repeat-bearing value fails typed before an encoder container exists,
  configured encoding revalidates under the exact supplied snapshot, and
  decoding threads remaining aggregate budgets into recursive value
  decoding. The ceilings are accepted on local Apple Silicon boundary
  evidence with the lowest-resource supported-device matrix an explicit
  open gap. `CCR-0010` records the controlled CDMS corrections. Canonical
  bytes and record identity remain governed by Proposed `ADR-0035` and
  `ADR-0036`.
- Governance: `ADR-0034` was accepted by the project owner on 2026-08-04
  with its dependencies already accepted, and its authorised migration is
  executed. The closed exact-case typed read boundary is implemented in
  `VoxeliaCore`: the non-generic payload-free `MetadataReadError`
  (`missingValue`, `multipleValues`, `typeMismatch`), the classified
  `TypedMetadataEntry` result retaining typed key, exact payload and the
  occurrence's exact privacy class with no public initializer or Codable,
  and the 22 concrete `entry(for:)`/`entries(for:)` overloads covering
  exactly the eleven corrected value cases. Extraction pattern-matches
  the stored case with no parsing, bridging, widening or unit
  conversion; key matching is exact ordered UTF-8; single reads decide
  exact-key cardinality before inspecting any stored case; plural reads
  return every match in occurrence order after a complete preflight and
  fail atomically on any mismatch. Unsupported specialisations such as
  `MetadataKey<Double>` fail overload resolution at compile time.
  `CCR-0011` records the controlled CDMS and MTA corrections.
- Governance: `ADR-0035` was accepted by the project owner on 2026-08-04
  with its semantic dependencies already accepted, and its authorised
  migration is executed. `VoxeliaCore` owns Voxelia Canonical Metadata
  JSON version 1 (`VCMJ-1`): a JCS-derived UTF-8 record profile with
  decimal-string 64-bit integers, RFC 8785 escaping/property-order/
  shortest-round-trip binary64 tokens, preservation of all valid Swift
  scalars including noncharacters, the fixed three-member envelope, and
  the out-of-band trusted multiplicity binding whose policy never
  appears on the wire. The dedicated iterative ingress state machine
  (never Foundation) charges raw document/token/string/binary/count/
  depth budgets before growth, admits keys before values, rejects
  duplicates, aliases, BOM, whitespace and order violations, enforces
  the grammar-derived raw depth 198 and semantic depth 64, polls
  cancellation at the 4,096-work-unit cadence and publishes one
  immutable `CanonicalMetadataDocument` after complete validation.
  Emission preflights admission and exact checked output sizing before
  allocating, shares one sizing/writing fragment primitive and never
  publishes bytes on failure. The frozen scalar whitespace oracle
  replaced `Character.isWhitespace` in the Core metadata-key and
  coded-concept constructors and Spatial's `MeasurementUnit` — the
  documented pre-1.0 blank-domain broadening. `CCR-0012` records the
  controlled corrections. Open evidence gaps recorded: lowest-resource
  device cancellation latency, fuzz corpora, external Ryu/V8
  differential oracles, universal raw-ceiling derivation and the
  `VOX-ERR-001` allocation-failure disposition. Record identity remains
  governed by Proposed `ADR-0036`.
- Governance: `ADR-0036` was accepted by the project owner on 2026-08-04
  with its dependencies already accepted, and its authorised migration is
  executed. `VoxeliaCore` owns the complete canonical metadata record
  identity: the corrected scoped, projected `ContentID` (typed algorithm,
  required scope, bounded `ContentProjectionReference`, owned 32-byte
  digest, no public unchecked initializer), one compiled accepted tuple
  (`sha256`/`serialisedObject`/`org.voxelia.metadata-complete-record`
  v1.0 via CryptoKit), the fixed 109-byte `VOXELIA-CONTENT-ID` digest
  frame binding purpose into the preimage, strict 64-character lowercase
  hexadecimal type-level coding, timing-safe `timingsafe_bcmp` direct
  verification and payload-free identity errors. The pre-registered
  golden fixtures reproduced exactly: the emitter's 148-byte empty
  document hashes to the registered raw and framed digests, byte for
  byte. The public data-model change is recorded as `RFC-0002` (register
  fail-closed `Draft`) with the project owner's maintainer approval
  recorded in the accepted ADR, `CCR-0013` and this ledger. The digest
  remains sensitive-derived linkage material with no logging, export or
  authenticity claim; semantic collection identity, image/data identity
  and signatures remain future decisions under Proposed `ADR-0037` and
  later records.
- Governance: `ADR-0037` was accepted by the project owner on 2026-08-04
  as a documentation-and-corrections boundary. Its accepted content: the
  claim-versus-assurance split (identity values are always claims;
  assurance is host-validated runtime evidence bound to exact snapshot,
  purpose and policy, never a serialised Boolean), the closed `C/S/D`
  state model rejecting only the object-only state, the exact
  source-locator invariants with duplicate rejection and preserved
  order, the explicit three-tier cache-admission order with partitioned
  key spaces, and the deferral of the displayed `DerivationIdentity`
  and undeclared `DataIdentityReference` sketches behind the source
  gate. `CCR-0014` records the MTA section 11.3 corrected identity
  sentence, the CDMS section 32.5/33 state-model binding, the
  `VOX-RGN-007`/`VOX-RGN-008` readings and the cache-admission
  interpretation. Deliberately, no identity value source was
  implemented: the accepted source gate forbids `SourceIdentity`,
  `DerivationIdentity`, `DataIdentity`, `DataIdentityReference`, trust,
  cache and lazy-digest source until the identifier profiles,
  `DataObjectID` persistent-identity resolution, reference lifecycle,
  registered parameter/derivation projections, `objectID` enrichment
  lifecycle and execution/cache contracts receive their own decisions.
  The CDMS section 59 `DataIntegrityState` conflict is recorded and
  remains unresolved.
- Governance: `ADR-0038` was accepted by the project owner on 2026-08-04
  as a documentation-and-corrections boundary. Its accepted content: the
  Core-claims/Execution-behaviour ownership split preserving the live
  dependency graph (Core owns immutable backend-neutral claim values;
  Execution owns capture, assembly and the single atomic publication of
  output, identity, matching provenance root and authorised cache
  aliases; Storage owns persistence integrity; Validation evaluates
  evidence; hosts own trust, signatures and privacy); the closed
  subject-bound `ProvenanceRecord` target (explicit subject reference,
  closed origin-versus-operation activity with the eleven-kind table,
  ordered role/occurrence-unique inputs, flat non-recursive
  graphNode/externalRecord references, bounded machine-readable
  warnings, validation cases documented as claims); and the bounded
  transactional graph admission with explicit complete-versus-compact
  authority and byte-for-byte rollback on failure. `CCR-0015` records
  the MTA section 12.2/12.4 ownership corrections and the CDMS section
  36 record/activity/validation/graph corrections plus the
  `ProvenanceID` durable-use restriction. Deliberately, no provenance
  source was implemented: the accepted eleven-item source gate keeps
  every aggregate blocked until the persistent `ProvenanceID`, reference
  wire, execution claim shapes, warning schemas, validation-evidence
  references, canonical projections, hard ceilings, publication and
  cache contracts and controlled reconciliation receive their own
  decisions.
- Governance: the `RFC-0001` storage-contract and logical-data-model
  composition received the project owner's directional approval on
  2026-08-04, selecting the Foundation-preserving mapped-storage
  schedule (production mapping at M5 via the corrected `VOX-STO-004`
  reading; M1 keeps contract semantics, isolated lifetime evidence and
  one verified owned contiguous provider), and its three composed ADRs
  were accepted in dependency order: `ADR-0039` (Core owns
  backend-neutral contracts, admission authority and the private result
  target; Storage owns concrete providers and I/O; Execution/host owns
  atomic `ImageData` publication; Metal owns residency as dynamic
  evidence; capability bag split into characteristics, witnessed
  operations, runtime evidence and dynamic state), `ADR-0040` (four
  non-interchangeable layers separating logical sample identity from
  source-bit interpretation, physical representation and
  identity/evidence) and `ADR-0041` (owned complete region-read
  transaction with monotonic fill and one commit linearisation point,
  checked erasure and owner-retaining `Data` lease scopes, its
  seal/stamping and drain model authoritative over `ADR-0039`'s older
  read-probe shape). `CCR-0016` records the correction package. The
  `RFC-0001` file remains register-`Draft` under the fail-closed
  validator with the approval recorded in the accepted ADRs, `CCR-0016`
  and this ledger. No storage source was implemented: the accepted
  source gates and the RFC's approval-order steps 4 through 11 (final
  API names, wires, ceilings, admission factory, platform evidence,
  builder and publication contracts) remain closed, with its fourteen
  unresolved questions recorded as explicit approval gates. The ADR
  register now holds no Proposed records: `ADR-0001` through `ADR-0041`
  are all Accepted.
- Governance: `ADR-0042` was accepted by the project owner on 2026-08-04
  as the `RFC-0001` step-4 freeze artefact, closing unresolved questions
  2, 3, 5 and 7. Frozen: the public storage vocabulary
  (`LogicalSampleBinding`, `StorageRepresentationDescriptor`,
  `StorageSnapshotHandle`, `StorageOperation` with retained witnesses,
  `RegionReadResult`, `StorageByteLease`, the retained `AnyImageStorage`
  erased-handle name and the closed payload-free nine-case
  `StorageContractError` family with `ADR-0041` precedence); the no-wire
  policy (no persistent operational wire at M1, no convenience Codable);
  and the caller-limits policy (explicit inclusive checked `UInt64`
  ceilings with no permissive defaults, hard implementation maxima
  deferred to the recorded device-evidence campaign). Steps 5 through 7
  (compatibility projections, Core contracts, one owned contiguous
  provider) are now unblocked as separate user-requested increments;
  steps 8 through 11 and unresolved questions 4, 6 and 8 through 14
  remain gated. Documentation-only: no storage source was added.
- Under the project owner's 2026-08-04 autonomous delegation ("work
  autonomously, take your own decisions"), executed the first `RFC-0001`
  step-5/6 storage increment: `StorageContract.swift` in `VoxeliaCore`
  adds the frozen payload-free nine-case `StorageContractError` and the
  validated `LogicalSampleBinding` (validated shape, exact decoded
  scalar type, positive component count, checked `Int` value and byte
  accounting mapping overflow to the typed limit) plus the lossless
  step-5 compatibility projection from the existing `ScalarFormat` and
  `ComponentDescriptor` leaves, consuming only their
  representation-independent fields so byte order never changes logical
  identity. Two focused tests cover checked accounting, overflow
  rejection, projection losslessness and byte-order independence. The
  remaining step-6 surface (tagged `StorageRepresentationDescriptor`,
  `StorageSnapshotHandle` admission authority, the read transaction,
  `RegionReadResult`, `StorageByteLease` and checked `AnyImageStorage`
  erasure) continues as the next increments in this loop.
- Second autonomous storage increment: `StorageRepresentation.swift`
  adds the tagged `StorageRepresentationDescriptor`
  (`decodedStrided`/`opaque`), the checked
  `DecodedStridedRepresentation` whose first admitted profile accepts
  exactly the canonical packed interleaved layout for its binding
  (canonical axis-zero-fastest strides, component stride equal to the
  scalar byte count, arbitrary checked non-negative base offset, checked
  addressed span within the initialised length, multi-byte `.native`
  byte order restricted to process-local owned memory) with the
  `canonicalPacked` factory, and the bounded non-blank
  `OpaqueRepresentation` tag record. General permuted/padded strided and
  packed sub-byte admission remain later increments per the accepted
  fail-closed rule. Two focused tests cover exact admission, span/offset
  /stride/rank rejections, the byte-order locality rule and opaque tag
  bounds.
- Third autonomous storage increment: `StorageSnapshotHandle.swift` adds
  the Core-minted nonforgeable `StorageReadAuthority` (internal-only
  initializer, reference identity, one fresh authority per admission
  with no cross-admission aliasing) and the immutable
  `StorageSnapshotHandle` binding authority, exact logical binding,
  representation descriptor, retained owner and snapshot generation.
  Admission validates that a decoded representation carries exactly the
  admitted binding; `successor` derives strictly-newer generations that
  co-retain the same authority while non-increasing generations fail as
  `staleSnapshot` and the original handle stays immutable. Two focused
  tests cover authority nonforgeability, foreign-binding rejection,
  successor co-retention and stale-generation rejection.
- Fourth autonomous storage increment: `RegionReadTransaction.swift`
  implements the `ADR-0041` safe first read profile as a single-owner
  synchronous transaction: pre-admission rejections (opaque
  representation unsupported, rank/containment/empty-region invalidity,
  checked expected-byte overflow) throw from construction and create no
  transaction; the provider receives only the weak bounded
  `RegionFillCapability` whose monotonic cursor poisons on overrun or
  after-close writes; cancellation blocks commit immediately and
  permanently; a throwing provider terminalises as `providerFailure`
  without retaining its error; and `commit()` mints the owned immutable
  packed `RegionReadResult` (region-shaped binding, exact expected
  bytes) exactly once, with poisoned or incomplete fills failing closed
  and committed/failed transactions remaining tombstones. The
  asynchronous coordinator, byte-budget ledger and provider-drain
  accounting remain the Execution-facing later increments. Three focused
  tests cover the monotonic happy path with tombstone behaviour,
  pre-admission rejection including the opaque case, and
  poison/incomplete/cancel/provider-failure fail-closed paths.
- Fifth autonomous storage increment closing the `RFC-0001` step-6/7
  value chain: `ImageStorageContract.swift` in `VoxeliaCore` adds the
  backend-neutral provider protocol and the checked `AnyImageStorage`
  erasure box (single witness dispatch; `unerased(as:)` recovers exactly
  the erased concrete type and fails typed with no fallback), and
  `ContiguousImageStorage.swift` in `VoxeliaStorage` implements the
  first verified owned contiguous provider: an immutable process-local
  packed backing admitted through Core snapshot authority, byte-count
  admission, and complete owned region reads that copy contiguous
  axis-zero runs monotonically through the Core transaction. Focused
  tests prove byte-exact full and sub-region reads, short-backing
  rejection, erased forwarding with authority identity and checked
  foreign-unerase failure. The static package-graph and
  prohibited-import checks confirm the dependency direction is
  unchanged. The `StorageByteLease` closure-result shape remains
  source-gated on the recorded `Data.span` platform-evidence question
  (RFC unresolved question 8), and the asynchronous coordinator/budget
  ledger remains the Execution-facing later work.
- Sixth autonomous increment: authored and accepted `ADR-0043` (spatial
  descriptor admission boundary) under the recorded owner delegation,
  closing the four `ImageDescriptor` blockers with conservative
  fail-closed rules: coordinate-space units must carry
  `UnitDimension.length` (non-physical classifications need a future
  decision); affine admission requires finite entries, the exact
  homogeneous bottom row and an upper-left determinant magnitude of at
  least `Double.leastNormalMagnitude` with no epsilon parameter;
  rectilinear binding (strictly increasing finite per-axis arrays with
  exact extent counts) and frame-set coverage (exactly one transform
  per `FrameAnchorIndex`) are frozen as admission rules with their
  implementations deferred to the recorded M1/M7 and M1/M4 windows.
  `CCR-0017` records the CDMS section 19.2/21/22 corrections.
  Implementation of `CoordinateSpaceDescriptor`, the affine geometry,
  the version-one `SpatialGeometry` surface and `ImageDescriptor`
  follows as the next increments.
- Seventh autonomous increment: `SpatialGeometry.swift` in
  `VoxeliaSpatial` implements the accepted `ADR-0043` admission rules:
  `CoordinateSpaceDescriptor` (reusing the existing `CoordinateSpaceID`
  leaf) rejects non-length or missing unit dimensions, duplicate exact
  external references and declared handedness contradicting a
  convention's implied handedness; `AffineGridGeometry` enforces the
  exact homogeneous bottom row and the
  `Double.leastNormalMagnitude` determinant boundary (zero and
  subnormal determinants rejected, the exact boundary admitted); and
  the version-one `SpatialGeometry` enum admits the affine case. Wire
  coding for the new aggregates is deliberately deferred to a dedicated
  strict-wire increment. Two focused tests cover every rejection path
  and the determinant boundary in both directions.
- Eighth autonomous increment — the M1 centrepiece: `ImageDescriptor`
  is implemented in `VoxeliaCore` with the typed payload-free
  `ImageDescriptorError` and the CDMS section 19.2 invariants validated
  at construction with no storage access: axis count equals shape rank;
  axis identifiers unique; colour semantics require RGB/RGBA component
  interpretations while non-colour semantics reject them; an affine
  spatial geometry may reference only in-rank image axes; and a present
  sample unit must not carry the length dimension (spatial-coordinate
  units live on axes and coordinate spaces). Wire coding is deferred to
  the dedicated strict-wire increment alongside the spatial aggregates.
  Two focused tests cover every invariant in both directions. The
  descriptor was the recorded central blocker of milestone M1; the
  remaining structural `ImageData` aggregate stays gated on the
  identity/provenance prerequisites recorded with `ADR-0037`/`ADR-0038`.
- Ninth autonomous increment — the deferred strict wire: manual
  exact-key `Codable` for `CoordinateSpaceDescriptor` (five fields),
  `AffineGridGeometry` (three fields), the externally tagged one-member
  `SpatialGeometry` wire and the eight-field `ImageDescriptor` wire with
  explicit nulls for its three optionals. Every decoder checks the exact
  key set, decodes strict children and revalidates through the
  constructing initializer, mapping invariant violations to fixed
  value-redacted `dataCorrupted` failures with empty model-relative
  paths. Tests cover the full nested round trip (including an affine
  geometry with an external frame reference and a `validBitCount`
  scalar format), explicit-null emission, missing/extra-field and
  unknown-tag rejections, an invariant violation surfaced through the
  wire (duplicated axis identifier) and redaction of space identifiers
  from the failure context.
- Tenth autonomous increment: authored and accepted `ADR-0044`
  (persistent identifier exactness boundary) with `CCR-0018`, then
  tightened the existing `DataObjectID` and `ProvenanceID` leaves: an
  inclusive 255-UTF-8-byte raw-value ceiling rejected at construction
  (surfacing through the shared strict decoder as the value-redacted
  concrete-type failure) and exact accepted-UTF-8 equality and hashing
  so canonically equivalent byte-distinct spellings are distinct
  identifiers, matching the `AnyMetadataKey` precedent. The
  `init?(rawValue:)` surface, keyed wire and shared protocol are
  unchanged, and other identifier conformances keep their semantics.
  This discharges `ADR-0037` source-gate item 4 for `DataObjectID` and
  the `ADR-0038` bounded-identifier prerequisite for `ProvenanceID`;
  the remaining gate items stay open. One focused test covers the
  255/256 boundary, NFC/NFD distinctness in equality/hash/set
  behaviour, redacted over-ceiling decode rejection and the exact wire
  round trip; the full suite re-passed, proving no existing evidence
  relied on the loosened domains.
- Eleventh autonomous increment: authored and accepted `ADR-0045`
  (integrity state claim boundary) with `CCR-0019`, resolving the CDMS
  section 59 conflict that accepted `ADR-0037` explicitly left open:
  `failed(reason: String)` is corrected to a payload-free `failed`
  case, the verified cases are documented as claims whose decoded
  presence proves nothing (assurance stays runtime evidence under the
  accepted vocabulary), no ordering or upgrade exists between cases,
  and no `DataIntegrityState` source is authorised until an owning
  aggregate decision needs it. Documentation-only; no source changed.
  With this record the recorded documentation-level correction queue is
  drained: the remaining open gates all require either external
  evidence (device campaigns, `Data.span` platform behaviour,
  fuzz/differential oracles, the universal raw ceiling, the
  `VOX-ERR-001` allocation disposition) or future consumers (identifier
  profiles for `SourceIdentity`, registered parameter/derivation
  projections, `DataIdentityReference` lifecycle, execution/cache
  contracts, the `ImageData` publication authority).
- Twelfth autonomous increment — milestone M2 opened on the project
  owner's explicit instruction: authored and accepted `ADR-0046`
  (execution read coordination boundary) and implemented
  `StorageReadCoordinator` in `VoxeliaExecution`, the actor-isolated
  active-plus-retained result-byte ledger. The Core transaction is
  admitted before any budget work; the checked inclusive reservation is
  charged before the provider is invoked (an over-budget request never
  reaches the provider and mutates nothing); provider fill and commit
  run outside the actor's isolation; failure, foreign errors and
  observed cancellation release the reservation exactly once with typed
  causes; and a committed result's charge is retained until its
  identity-based `ReadRetentionToken` is explicitly released, with
  double release a typed `contractViolation`. Two focused async tests
  cover exact charge/release accounting, over-budget rejection with an
  unchanged ledger, provider-failure and pre-admission paths,
  cancellation, and concurrent reads accounting exactly. Single-flight
  deduplication, result caching, lazy identity computation and
  provenance capture remain the next M2 increments under their recorded
  gates.
- Thirteenth autonomous increment: authored and accepted `ADR-0047`
  (coordinated metadata identity boundary) and implemented
  `MetadataIdentityCoordinator` in `VoxeliaExecution` — the unblocked
  slice of the accepted lazy-identity machinery, since an immutable
  `MetadataCollection` value is itself the pinned snapshot and the
  complete-record projection is registered. The actor coalesces
  concurrent identical requests (work key: collection value plus output
  ceiling, in-process only) onto one shared detached computation that
  publishes the exact canonical `VCMJ-1` bytes and their framed
  `ContentID` atomically; a cancelled caller receives the typed outcome
  without cancelling shared work; the in-flight table drains after
  completion; and typed emission/identity failures propagate. Tests
  reproduce the registered golden pair (148-byte envelope and the
  `8dde…7432` framed digest) through the coordinator, verify
  self-consistency via timing-safe `matchesDigest`, prove sixteen
  concurrent identical requests start strictly fewer computations, and
  confirm distinct ceilings are distinct work keys. Repeat-bearing
  identity, general `DataIdentity` enrichment and cache/provenance
  publication remain gated.
- Fourteenth autonomous increment: authored and accepted `ADR-0048`
  (single-flight read deduplication) and extended
  `StorageReadCoordinator` with coalescing over the accepted work-key
  binding (authority reference identity, snapshot generation, exact
  region bounds; keys never persisted). One shared provider execution
  charges its copy-on-write result bytes once; every successful waiter
  mints its own retention token against the shared charge group, whose
  charge frees only when the last token is released and the last waiter
  has finished; cancelled-after-completion waiters convert
  charge-neutrally; failed shared executions release their reservation
  exactly once and propagate typed causes to every waiter; late joiners
  after the last waiter start fresh executions. The coalescing test
  runs sixteen identical concurrent reads under a budget that could not
  fund one charge per waiter, proving strictly fewer shared executions
  than waiters, exact charged-equals-groups accounting, per-token
  release with last-release freeing and double-release rejection; the
  existing single-reader semantics tests re-passed unchanged. With this
  increment the unblocked M2 queue is drained: result caching stays
  gated on a registered bytes-scope projection, and provenance capture
  stays gated on the `ADR-0038` prerequisites.
- Fifteenth autonomous increment: authored and accepted `ADR-0049`
  (sample-bytes content projection), the first record of the owner's
  authorised three-decision-cluster continuation, and registered the
  second compiled `ContentID` tuple in `VoxeliaCore`: algorithm
  `sha256`, scope `sampleBytes`, projection `org.voxelia.sample-bytes`
  version `1.0`, whose payload is the exact canonical packed
  interleaved decoded logical bytes of one complete binding under the
  accepted `ADR-0040`/`ADR-0042` profile. The version-one
  `VOXELIA-CONTENT-ID` frame builder is generalised over the
  length-prefixed scope token and projection identifier (92-byte header
  for the new tuple, the unchanged 109-byte header for the complete
  record), `validateAcceptedProfile` admits exactly the two registered
  tuples with every crossed combination rejected as an unsupported
  projection, `sampleBytesIdentity(overCanonicalPackedBytes:)` reuses
  the shared chunked, cancellation-checked computation, and
  `matchesDigest` now verifies under the record's own registered tuple.
  Tests reproduce independently computed golden fixtures (24-byte
  payload framed digest `6f57…2111`, raw negative control, the
  identical payload under the complete-record frame, and the
  empty-payload digest), pin the 92-byte header layout, prove
  structural domain separation between the two projections, round-trip
  the new wire and reject four crossed tuples; the existing `ContentID`
  and coordinator suites re-passed unchanged. The
  `descriptorAndSamples` scope stays honestly deferred because no
  canonical descriptor byte projection exists, and ordinary `Codable`
  output is not canonical under `ADR-0036`.
- Sixteenth autonomous increment: authored and accepted `ADR-0050`
  (content-tier result cache) and implemented `ContentResultCache` in
  `VoxeliaExecution` — exactly the content tier of the accepted
  `ADR-0037` admission order, unblocked by the `ADR-0049` bytes-scope
  projection. Admission recomputes the supplied record's digest under
  its own registered tuple and compares timing-safe outside the actor's
  isolation before anything is published; every hit revalidates the
  stored bytes before returning them, with a revalidation failure
  purging the entry, counting evidence and reporting a miss; the
  initializer requires inclusive entry-count and total-byte ceilings
  with no permissive defaults and checked arithmetic; duplicate
  admission of a cached identity is an idempotent success; removal is
  explicit with unknown removal a typed rejection; and no implicit
  eviction policy exists — selecting one is recorded as a governed
  decision deferred until usage evidence exists. Tests prove mismatched
  admission publishes nothing, both registered tuples round-trip
  through verified admission and revalidated lookup, both ceilings
  reject with unchanged state, duplicates are idempotent, removal frees
  the budget exactly once, returned copies are owned, the evidence
  counter stays zero across healthy operations and the payload-free
  error discipline holds. Source-tier and derivation-tier admission
  stay gated on their `ADR-0037` prerequisites.
- Seventeenth autonomous increment: authored and accepted `ADR-0051`
  (execution claim value shapes) and implemented the Core-neutral
  execution claim leg of the accepted `ADR-0038` provenance target in
  `VoxeliaCore`: `ExecutionClaimToken` (bounded lowercase reverse-domain
  grammar with byte-limit-before-grammar precedence as its own nominal
  authority, exact-byte identity), `ExecutionComponentReference` (token
  plus exact `SemanticVersion` with build metadata rejected typed
  because it does not participate in version equality),
  `ExecutionApproximationStatus` (closed frozen `exact`/`approximate`),
  and `ExecutionProvenanceClaim` (required profile, backend, precision
  policy and quality policy, required approximation status, optional
  capability class and kernel with no defaults; every field
  participates in identity). No `Codable` is declared: the stable
  coding of every claim shape is owned by the future canonical
  provenance-record projection decision, so no ad-hoc non-canonical
  encoding can leak into persistence. Tests prove ceiling-before-
  grammar precedence, exact token classification, typed build-metadata
  rejection, per-field claim identity across seven variants, optional
  absence and payload-free diagnostics. The provenance record, warning
  schema, subject binding and graph admission remain gated on their own
  decisions.
- Eighteenth autonomous increment: authored and accepted `ADR-0052`
  (provenance warning schema) and implemented the warning leg of the
  accepted `ADR-0038` provenance target in `VoxeliaCore`:
  `ProvenanceWarningCode` (bounded reverse-domain code as its own
  nominal authority with byte-limit-before-grammar precedence and
  exact-byte identity), `ProvenanceWarningSchemaVersion` (exact
  major/minor vocabulary pin), `ProvenanceWarningSeverity` (closed
  frozen `informational`/`qualityAffecting`/`integrityAffecting`), and
  `ProvenanceWarning` (one code, one schema version, one severity and a
  checked occurrence count of at least one, so repetition is counted,
  never repeated as entries). There is no message, reason, path or
  parameter field — free text is structurally impossible in the Core
  identity, which the tests prove by mirror over the stored members —
  and no `Codable` is declared, the stable coding again being owned by
  the future canonical provenance-record projection decision. Tests
  prove ceiling-before-grammar precedence, exact code classification,
  typed zero-count rejection, per-field warning identity and
  payload-free diagnostics. The provenance record, subject binding and
  graph admission remain gated pending the source-identity and
  parameter-projection decisions ordered next.
- Nineteenth autonomous increment: authored and accepted `ADR-0053`
  (source identity profile and data identity reference) with `CCR-0020`
  recording the controlled corrections `ADR-0037` required before any
  public initializer, and implemented both values in `VoxeliaCore`.
  `SourceIdentity` gains the selected field profile — each of
  `namespace`, `identifier` and a present `version` at most 255 UTF-8
  bytes inclusive checked before content rules, then control-scalar
  rejection (C0, DEL, C1), then the frozen blank-text oracle — with
  exact accepted UTF-8 tuple identity (absent version distinct, the
  optional source-content claim participating) and a strict four-field
  wire with explicit nulls. `DataIdentityReference` is declared with
  exactly the `object`/`content`/`source` cases and a strict one-member
  tagged wire; the `derivation` case stays deferred until
  `DerivationRecordID` and its registered projection exist, and the
  reference never embeds aggregates, so cycles are structurally
  impossible. Nested decoders retain only audited payload-free project
  errors; everything else maps to a typed value-free rejection. Tests
  prove ceiling-before-content precedence, control and blank rejection
  without disclosure, byte-distinct canonically equivalent spellings
  staying distinct, exact golden wires for all three cases, and typed
  rejection of unknown tags (including `derivation`), wrong member
  counts, malformed nested records, over-ceiling fields and crossed
  content tuples. Duplicate-locator rejection, source ordering and
  aggregate limits stay with the future `DataIdentity` decision.
- Twentieth autonomous increment: authored and accepted `ADR-0054`
  (operation-parameters content projection) and registered the third
  compiled `ContentID` tuple: algorithm `sha256`, scope
  `serialisedObject`, projection `org.voxelia.operation-parameters`
  version `1.0`, whose payload is the exact complete accepted `VCMJ-1`
  bytes of one parameter `MetadataCollection` — reusing the accepted
  canonical codec so one canonical-JSON authority serves both
  registered `serialisedObject` projections, which stay structurally
  domain-separated through the length-prefixed 105-byte frame header.
  `operationParametersIdentity(overCanonicalBytes:)` reuses the shared
  chunked, cancellation-checked computation, and the accepted set in
  `validateAcceptedProfile` admits exactly the three registered tuples.
  Tests reproduce an independently computed golden framed digest over
  the canonical empty parameter document, reproduce the registered
  `ADR-0036` golden for the identical payload under the
  complete-record projection to prove structural separation, pin the
  105-byte header, round-trip the new wire and reject crossed tuples.
  This discharges the `ADR-0037` derivation prerequisite "registered
  parameter projection"; the digest proves neither parameter
  completeness nor determinism and is not by itself a cache key.
- Twenty-first autonomous increment: authored and accepted `ADR-0055`
  (derivation identity record) with `CCR-0021` recording the controlled
  correction, and implemented the closed derivation shapes in
  `VoxeliaCore`: `DerivationOperationToken` (own reverse-domain
  nominal with limit-before-grammar precedence),
  `DerivationInputRole` (bounded single lowercase label),
  `DerivationInput` (role plus `DataIdentityReference`, positional
  with exact repeats preserved), `DerivationImplementationReference`
  (token plus version in which build metadata is admitted), and
  `DerivationIdentity` binding the operation token, exact operation
  version, optional implementation, positional inputs and a
  `parameterDigest` constrained to the registered `ADR-0054`
  operation-parameters tuple with every foreign tuple a typed
  rejection. An empty input sequence is admitted only under the
  explicit zero-input generator declaration, which is not stored
  because it is derivable; equality and hashing compare every stored
  field exactly, including `SemanticVersion.buildMetadata` through an
  explicit exact-version comparison. Tests prove both grammars with
  limit precedence, both zero-input rules, foreign-tuple rejection,
  build-metadata-distinct implementations comparing distinct while
  their semantic versions compare equal, repeats, order and roles
  participating in identity, and payload-free diagnostics. The stable
  coding, input-count ceiling and `DerivationRecordID` stay with the
  future canonical derivation-record projection decision; determinism
  and input assurance remain runtime evidence under `ADR-0037`.
- Twenty-second autonomous increment: authored and accepted `ADR-0056`
  (data identity aggregate) with `CCR-0022` recording the controlled
  correction, and implemented the closed `DataIdentity` aggregate in
  `VoxeliaCore`: required `DataObjectID`, optional top-level content
  claim that must not carry the operation-parameters projection,
  ordered `SourceIdentity` lineage and optional `DerivationIdentity`.
  Construction rejects exactly the accepted state model's object-only
  state; an exact repeated source record and a repeated locator with a
  different content claim are distinct typed rejections detected in
  one linear pass over the exact accepted UTF-8 locator keys with no
  normalisation, deduplication or last-write-wins; accepted source
  order is preserved as lineage record order and participates in
  identity. Tests exercise all eight content/source/derivation
  combinations rejecting only the object-only state, prove both source
  rejection modes, admit byte-distinct canonically equivalent locators
  as distinct, distinguish absent from present versions, prove order
  participation and confirm distinct source and top-level scopes are
  admitted without comparison. With this the `ADR-0037` claim-bearing
  identity chain is complete as values; the stable coding and
  source-count ceiling stay with the future canonical data-identity
  projection decision, and cache admission, lazy enrichment and
  `objectID` lifecycle remain gated. Structural `ImageData` assessment:
  the aggregate's Core dependencies (`ImageDescriptor`,
  `AnyImageStorage`, `MetadataCollection`, `DataIdentity`) now all
  exist; the remaining blocker is the `ProvenanceRecord` target,
  which is the next ordered decision.
- Twenty-third autonomous increment: authored and accepted `ADR-0057`
  (provenance claim leaf shapes) with `CCR-0023` recording the
  controlled corrections to CDMS sections 36.3 through 36.7 —
  including the late warning-record correction the `ADR-0052`
  increment omitted — and implemented every leaf the `ADR-0038` record
  target names, in `VoxeliaCore`: `SoftwareIdentity` (identity field
  profile on name/commit/buildIdentifier, exact version comparison
  including build metadata), `OperationProvenance` (shared
  semantic-operation tokens with a required implementation and the
  parameter digest constrained to the registered operation-parameters
  tuple), `ProvenanceInputRole` and `ProvenanceInput` (bounded
  single-label role, checked occurrence ordinal starting at one,
  identity reference and optional parent), `ProvenanceParentReference`
  (exactly the `graphNode` case; the external-record case stays
  honestly deferred until a registered provenance-record digest
  projection exists), and `ProvenanceValidationClaim` with
  `ValidationEvidenceID` (the corrected validation claim whose
  free-text deprecation reason is removed and whose cases carry no
  ordering). Tests prove the field profile with limit precedence, the
  role grammar, zero-occurrence rejection, foreign-tuple rejection,
  build-metadata-exact software and operation comparison, exact
  evidence identity and payload-free diagnostics. The record
  aggregate, its structural rules, graph admission and every wire
  remain the next ordered decisions.
- Twenty-fourth autonomous increment: authored and accepted `ADR-0058`
  (provenance record aggregate) with `CCR-0024` recording the
  controlled correction, and implemented the `ADR-0038` record target
  in `VoxeliaCore`: `ProvenanceActivity` (exactly `origin` and
  `operation` carrying both the operation claim and the execution
  claim, so an execution without an operation — and an origin silently
  carrying an execution — are structurally impossible) and
  `ProvenanceRecord` (the nine accepted fields with `CanonicalInstant`
  replacing the raw string and the subject bound through
  `DataIdentityReference`). Construction enforces kind coherence in
  both directions (`kind == .source` exactly for origin activity), the
  origin no-input rule, the operation zero-input declaration rules
  mirroring `ADR-0055` with the derivable declaration not stored,
  unique `(role, occurrence)` input pairs and unique
  `(code, schema version, severity)` warning keys in one linear pass
  each — repetition belongs in the occurrence count, and the
  constructor never silently aggregates. Tests prove both coherence
  directions, all input rules, both duplicate rejections with counts
  differing, input order participating in identity, a cached-kind
  record carrying its claims unchanged and payload-free diagnostics.
  With this the `ADR-0038` provenance value chain is complete: the
  bounded transactional graph admission contract and the canonical
  provenance-record projection (which also gates the external parent
  reference and `ImageData`'s publication story) are the remaining
  provenance decisions.
- Twenty-fifth autonomous increment: authored and accepted `ADR-0059`
  (complete provenance graph admission) and implemented the
  complete-mode slice of the accepted `ADR-0038` fourteen-step
  admission in `VoxeliaCore`: `ProvenanceGraphLimits` (mandatory
  inclusive record-count, parent-edge-count and ancestry-depth
  ceilings, each at least one, checked arithmetic) and
  `ProvenanceGraph.admitCompleteGraph`, one transactional static
  function that validates the candidate table and declared roots and
  returns an immutable snapshot or publishes nothing. It enforces the
  ceilings; unique record identifiers with equal-valued duplicates
  still rejected; a non-empty unique known root set; per-edge
  self-reference rejection; resolution of every `graphNode` parent;
  the parent-subject rule (each resolved parent's subject must equal
  the exact input identity); the exact-closure rule over the declared
  roots; visit-once iterative cycle detection catching two- and
  multi-node cycles; and maximum resolved ancestry depth computed by
  edge-propagating traversal without recursion or diamond
  re-traversal, exposed as evidence. Tests admit a chain and a diamond
  with exact depth evidence and prove every typed rejection: all four
  root rules, duplicate identifiers, self-reference, unresolved
  parent, subject mismatch, a two-node cycle, all three ceilings,
  zero limits and payload-free diagnostics. External-record
  verification, compact-mode retention, the owner's retained-record
  registry, production hard ceilings and any actor-isolated graph
  service stay honestly deferred with the registered
  provenance-record projection and supported-device evidence. THE
  AUTHORIZED THREE-CLUSTER CONTINUATION IS COMPLETE: eleven accepted
  decisions (`ADR-0049` through `ADR-0059`) with five controlled
  corrections (`CCR-0020` through `CCR-0024`) closed the content
  projections, the content-tier cache, the execution and warning
  claims, the source/derivation/data identity chain and the complete
  provenance record and graph. The remaining recorded gates each need
  either a new governed design (canonical provenance/data-identity/
  derivation projections and `DerivationRecordID`, the `ImageData`
  publication coordinator, mutable graph ownership), external
  evidence (device campaigns, fuzz corpora, oracles, `Data.span`),
  or a milestone owner decision (M4+ scope).
- Twenty-sixth autonomous increment (owner instruction: "design the
  canonical provenance projection autonomously"): authored and
  accepted `ADR-0060` (canonical provenance record projection) and
  implemented the `VCPJ-1` profile in `VoxeliaCore` with the fourth
  compiled `ContentID` tuple (`sha256`, `serialisedObject`,
  `org.voxelia.provenance-record` version `1.0`, 102-byte frame
  header). The profile is a fixed-schema UTF-8 JSON envelope
  (`documentSchema` plus `payload`) with no whitespace, members in
  ascending UTF-8 byte order, explicit nulls, one-member tagged
  unions, the accepted keyed identifier and embedded
  `ContentID`/`SourceIdentity`/`DataIdentityReference` wire shapes,
  the shared `VCMJ-1` RFC 8785 string-token authority, 32-bit-bounded
  fields as exact JSON integers and wider profile-native integers
  (semantic-version components, warning occurrence counts) as decimal
  string tokens so no binary64 boundary can corrupt exactness. The
  record's own identity is an envelope claim about the bytes, never a
  field inside them. `CanonicalProvenanceJSON.encodeRecordDocument`
  validates explicit inclusive ceilings of 65,536 inputs and 65,536
  warnings before writing any byte, honours the caller-supplied
  output byte ceiling with checked arithmetic and observes the
  established cancellation cadence;
  `ContentID.provenanceRecordIdentity(overCanonicalBytes:)` reuses
  the shared chunked computation. Tests reproduce two independently
  computed golden documents byte for byte — a 476-byte origin record
  (framed digest `ed85…3fb5`) and a 1,747-byte operation record
  exercising the activity, input, warning, validation and embedded
  digest shapes (framed digest `8f4d…c0e9`) — prove determinism, the
  102-byte header, count-ceiling-before-emission precedence, the
  exact output byte boundary, wire round-trip and crossed-tuple
  rejection; the existing `ContentID` suites re-passed unchanged.
  Strict `VCPJ-1` ingress (bytes back to a validated record) is the
  exact next action under this profile; `DerivationRecordID`, the
  external parent-reference case, compact graphs and signed manifests
  become possible but each remains its own decision.
- Twenty-seventh autonomous increment: authored and accepted
  `ADR-0061` (strict canonical provenance ingress) and implemented
  `CanonicalProvenanceJSON.decodeRecordDocument` in `VoxeliaCore` as
  four bounded transactional phases: a caller-supplied input byte
  ceiling and a string-aware raw pre-scan enforcing the fixed nesting
  ceiling of 32 before any parser allocates; shape-directed parsing
  through the platform JSON parser with exact member-set checks,
  explicit nulls only where the profile places them and exact decimal
  string tokens; revalidating reconstruction through every accepted
  constructing initializer, with an empty operation input sequence
  reconstructing as the declared zero-input generator; and the
  canonical byte-equality gate — the reconstructed record is
  re-emitted through the accepted `ADR-0060` emitter and must equal
  the input byte for byte, so every alias (whitespace, member
  reordering, escape and number respelling) fails as a typed
  non-canonical rejection. The byte-equality gate, not the parser, is
  the canonical authority, which is why the platform parser is
  admissible; failures use a uniform payload-free five-case taxonomy
  with no underlying error retained, because reconstruction crosses
  error domains whose cases carry payloads. Tests round-trip the
  minimal origin document and a maximal operation document (every
  tagged case, optional presence, embedded digest and decimal token)
  to equal records and identities, prove the zero-input generator
  reconstruction, and reject over-ceiling input, a nesting bomb
  before parsing (while brackets inside strings stay legitimate),
  malformed JSON, wrong and extra members, unknown enum tokens and
  three canonical aliases, all payload-free. The `VCPJ-1` projection
  is now usable end to end; `DerivationRecordID`, the external parent
  reference, compact graphs and signed manifests each remain their
  own decision.
- Twenty-eighth autonomous increment (owner instruction: "build the
  external reference and compact graphs autonomously"): authored and
  accepted `ADR-0062` (external provenance reference and compact graph
  admission) and implemented it in `VoxeliaCore`.
  `ExternalProvenanceRecordReference` binds one parent identifier to a
  record-content claim constrained to the registered
  provenance-record tuple, and `ProvenanceParentReference` gains
  exactly the `externalRecord` case; the `VCPJ-1` parent union is
  completed in the emitter and strict ingress before any release, so
  existing documents' bytes and digests are unchanged and the tuple
  stays version `1.0`. Graph admission gains the explicit
  `complete`/`compact` mode policy of the accepted `ADR-0038` table:
  both modes reject unresolved local parents; complete mode rejects
  every unresolved external parent; compact mode retains them under a
  mandatory per-input-edge-occurrence cap for which zero permitted
  means none, with exact repeated-claim consistency — every retained
  occurrence of one identifier must carry the same record-content
  claim and the same expected subject, a disagreement being one typed
  conflicting claim. An available external parent is resolved only
  after its candidate record's canonical bytes are re-emitted under
  the new mandatory resolution byte ceiling and the claim compares
  timing-safe, each distinct claim verified once; resolved external
  edges join closure, cycle and depth exactly like local edges;
  self-naming references reject regardless of tag; and the admitted
  snapshot reports its resulting authority (complete exactly when
  nothing was retained) plus the retained occurrence count as
  evidence. Resolution happens only through a new transaction whose
  table supplies the formerly external record, rechecking both
  bindings. Tests reproduce the independently computed 1,995-byte
  golden document whose external claim is the registered origin
  golden digest (framed digest `01ae…e2af`), round-trip it through
  ingress, and prove available verification and mismatch rejection,
  both mode policies, the zero and nonzero caps, both consistency
  rejections, self-reference rejection, the resolution byte ceiling,
  compact authority with later complete re-admission and payload-free
  diagnostics; the prior graph and codec suites re-passed with the
  extended limits profile. Signed external manifests, durable
  provenance storage and `DerivationRecordID` remain their own
  decisions.
- Twenty-ninth autonomous increment (owner instruction: "build
  ImageData autonomously"): authored and accepted `ADR-0063` (image
  data aggregate) with `CCR-0025` recording the controlled corrections
  to CDMS sections 37.1 through 37.4, and implemented the M1
  centrepiece aggregate in `VoxeliaCore`. `ImageData` binds the five
  controlled fields — descriptor, storage-erased provider,
  unique-keyed metadata, subject-bound provenance and claim-bearing
  identity — as one immutable validated value. Construction enforces
  descriptor-storage coherence (shape, scalar type and component count
  equal to the snapshot's admitted logical binding; the representation
  must be decoded-strided with the descriptor's scalar byte order, an
  opaque representation being a typed rejection because it cannot
  supply logical samples), provenance-identity coherence (the record's
  subject must be exactly the object reference of the aggregate's own
  `DataIdentity`, and an origin-activity record requires no derivation
  recipe plus at least one source identity), and metadata uniqueness
  (repeated keys reject; repeat-bearing collections exist only through
  the explicit multiplicity-policy path and belong to other contexts).
  The aggregate conforms to `Sendable` only per the controlled
  equality rule — comparison composes from the exposed exact claims —
  and has no wire: persistence composes the accepted canonical
  projections, and the atomic staging and publication coordinator
  remains an Execution/host decision per `ADR-0038`. Tests in the
  storage target construct a coherent acquired-origin aggregate over
  the real owned contiguous provider and a derived aggregate with an
  operation record and derivation recipe, then reject all four
  descriptor-storage mismatches, an opaque-representation stub
  admitted through the public snapshot admission, a mismatched
  provenance subject, an origin with a recipe, an origin without
  source lineage and a policy-admitted repeated metadata key, all
  payload-free. Lazy identity enrichment, the publication coordinator
  and every wire remain recorded gates.
- Thirtieth autonomous increment (owner instruction: "build the first
  operation implementation autonomously"): authored and accepted
  `ADR-0064` (exact region extraction operation) and implemented the
  first executable operation in `VoxeliaExecution`, registered as
  `org.voxelia.op.extract-region` 1.0.0 with implementation
  `org.voxelia.impl.extract-region.cpu` 1.0.0. The semantic is a
  byte-exact copy of one full-rank half-open region of the input's
  canonical packed decoded bytes — no sample value is created,
  altered, rounded or interpreted, so no algorithm specification with
  rounding semantics is required and the frozen execution claim
  carries the exact-approximation tokens. The frozen parameter schema
  is one metadata collection with exactly the `lower-bounds` and
  `upper-bounds` signed-integer arrays, digested under the registered
  operation-parameters projection. Version-one admission rejects
  spatial geometry and non-index axis sampling typed, because origin
  arithmetic is deferred to its own decision; region validity stays
  owned by the read-transaction rules. The read runs through the
  budgeted coalescing `StorageReadCoordinator` — `AnyImageStorage`
  gained the `ImageStorageContract` conformance it already implements
  member for member — with the retention released once the owned
  bytes are staged into a fresh contiguous provider. The operation
  mints no identifiers and acquires no clock: the caller supplies the
  output object identifier, provenance identifier, instant and
  software identity, and receives a fully validated `ImageData` whose
  identity binds the sample-bytes content identity of the exact
  output bytes and the derivation recipe, and whose transformed-kind
  provenance record binds the output subject, the input edge and a
  graph-node parent edge to the input's own record. Tests prove the
  crop byte-exact end to end — output bytes, preserved per-sample
  properties and metadata, the content identity, the parameter digest
  reproduced independently from the frozen schema, the recipe and the
  record — then admit both records into one complete graph of depth
  two, prove determinism across repeated execution, and reject
  geometry, regular sampling, invalid regions and an insufficient
  read budget, all typed. The first vertical value-and-execution
  slice is now exercised end to end.
- Thirty-first autonomous increment (owner instruction: "build the
  window-level operation autonomously"): authored and accepted
  `VOXELIA-ALG-0002` (window-level linear mapping `binary64-v1`) and
  `ADR-0065` (window-level operation), and implemented the first
  value-producing operation in `VoxeliaExecution`, registered as
  `org.voxelia.op.window-level` 1.0.0 with implementation
  `org.voxelia.impl.window-level.cpu` 1.0.0 — the tokens the claim
  fixtures have named since `ADR-0051`. The algorithm specification
  freezes the DICOM-derived linear model with exact binary64
  evaluation order, `roundTiesToEven` with a modelled clamp, the
  proof that the degenerate unit-width window is a pure threshold
  whose interior branch is unreachable (so the division never
  executes and no special case exists), the byte-order resolution
  rule (`native` resolves to little-endian on every supported
  Apple-silicon platform) and three independently computed
  conformance fixtures. The frozen parameter schema is the `center`
  and `width` finite metadata floating-point entries digested under
  the registered operation-parameters projection; a sub-one width is
  a typed rejection, never a substitution. Version-one admission
  covers `uint8` and `int16` stored samples with one
  scalar-interpreted component, intensity semantic and no value
  transform — windowing over transformed values awaits the
  transform-composition decision — while geometry, axes, sampling and
  metadata pass through unchanged because no sample moves; the output
  is dimensionless eight-bit display intensity. The execution runs
  through the budgeted coordinator per the `ADR-0064` pattern with
  the same identity, recipe and subject-bound provenance assembly.
  Tests reproduce all three conformance fixtures byte for byte
  through the full operation, reproduce the parameter digest
  independently, verify the sample-bytes content identity, admit both
  records into a complete depth-two graph, prove bit-identical
  repeated execution, and reject a sub-one width, an unsupported
  scalar type, a non-scalar layout, a non-intensity semantic, a
  present value transform and an insufficient budget, all
  payload-free.
- Thirty-second autonomous increment (owner instruction: "build the
  transform-composition decision autonomously"): authored and
  accepted `VOXELIA-ALG-0003` (linear stored-to-real value mapping
  `binary64-v1`) and `ADR-0066` (transform composition), and extended
  the window-level operation to the real value domain. The
  composition rule is layered: the stored sample maps to its real
  value first — for the linear case one correctly rounded binary64
  multiplication then one correctly rounded addition in frozen
  association, with fused multiply-add explicitly forbidden because
  it changes the rounding count — and the downstream window model
  consumes the real value unchanged, its centre and width thereby
  expressed in the input's real domain (the DICOM-derived modality
  rescale then window layering). The version-one composable set is
  exactly the absent, `identity` and `linear` transforms; the
  `lookupTable` and `composed` cases stay typed rejections pending
  their own registered evaluation models. The operation and
  implementation versions advance to `1.1.0` so recipes and claims
  distinguish the extended contract, while previously admitted inputs
  stay bit-identical and every output invariant (dimensionless
  eight-bit display, no transform, no units) is unchanged. Tests
  reproduce both conformance fixtures through the full operation —
  the CT rescale windowed at `c = 40`, `w = 400` in Hounsfield units
  reproducing the exact real-domain outputs, and a fractional-scale
  mapping — prove the identity transform bit-identical to the absent
  transform with equal content identities, verify the advanced
  version tokens in the recipe, and reject the composed case typed;
  the existing fixtures re-passed unchanged.
- Thirty-third autonomous increment (owner instruction: "build the
  publication coordinator autonomously"): authored and accepted
  `ADR-0067` (result publication coordinator) and implemented the
  `ADR-0038` publication contract in `VoxeliaExecution`. The
  actor-isolated `PublicationCoordinator` takes an explicit
  published-object ceiling, a full graph-limits profile, a read
  coordinator and an optional content-tier cache. Publication runs in
  three phases: first, a sample-bytes content claim is verified
  against actually read bytes through the budgeted read coordinator
  with the retention released after staging and a timing-safe digest
  comparison, a mismatch being a typed rejection; second, one
  non-suspending actor section linearises the identifier-reuse checks
  (reuse rejected even for equal values — enrichment publishes a new
  immutable record, never an update), the append-only ceiling (a
  transactional failure that evicts nothing), the ancestry-closure
  walk over the published registry across both parent-reference
  cases, the accepted `ADR-0062` graph admission under the caller's
  explicit mode policy and the registry mutation — so reentrant
  publishes cannot interleave the decision and the mutation; third,
  a configured cache receives the verified bytes as a best-effort
  authorised alias whose failure never unwinds a completed
  publication and is reported honestly in the returned receipt
  (authority, ancestry depth, verification and alias evidence).
  Tests publish a real origin bundle and a real window-level output
  end to end — depth-one and depth-two complete receipts, the cached
  bytes retrievable under the claim, registry lookups — and reject a
  corrupted claim, an unpublished parent in both modes, provenance
  identifier reuse under a fresh object identifier, ceiling
  exhaustion with nothing evicted and an insufficient verification
  budget, all typed. Retention and deletion governance remain
  deferred.
- Thirty-fourth autonomous increment (owner overnight standing
  mandate): authored and accepted `ADR-0068` (window-level uint16
  extension) and advanced `VOXELIA-ALG-0002` to revision 1.1. The
  window-level operation admits `uint16` stored samples — every value
  converts to binary64 exactly, the two-byte assembly follows the
  specification's existing byte-order resolution rule, and the model
  is otherwise untouched — with the operation and implementation
  versions advanced to `1.2.0` as another compatible admission
  widening. Tests reproduce the independently computed revision-1.1
  `uint16` conformance fixture through the full operation, verify the
  advanced version tokens, move the unsupported-scalar rejection
  fixture to `int32`, and keep every previously registered fixture
  passing unchanged.
- Thirty-fifth autonomous increment (owner overnight standing
  mandate): authored and accepted `VOXELIA-ALG-0004` (lookup-table
  stored-to-real value mapping `binary64-v1`) and `ADR-0069`
  (lookup-table composition), discharging the `ADR-0066` table
  deferral. The registered model is a 64-bit clamped index from the
  stored integer value and the table's first mapped value under the
  DICOM-derived out-of-range rule — below the table takes the first
  output, beyond it the last — with a frozen overflow-clamp rule, no
  interpolation, and the window parameters expressed in the table's
  output domain whose optional unit is never converted. The
  window-level composable set gains non-empty lookup tables (an empty
  table defines no output and is its own typed rejection), the
  `composed` case stays deferred to the chain decision, and the
  operation and implementation versions advance to `1.3.0`. Tests
  reproduce the conformance fixture — below-clamp, in-range including
  a fractional output mapping to 150, above-clamp — through the full
  operation, prove the advanced tokens, reject the empty table typed
  and keep every previously registered fixture passing.
- Thirty-sixth autonomous increment (owner overnight standing
  mandate): authored and accepted `VOXELIA-ALG-0005` (composed
  value-transform chain `binary64-v1`) and `ADR-0070` (composed chain
  composition), discharging the remaining `ADR-0066` deferral. Chains
  evaluate sequentially in declared order over binary64: identity
  stages are exact no-ops, linear stages apply the registered
  `VOXELIA-ALG-0003` arithmetic to their input, and a lookup-table
  stage is admissible only while every earlier stage is an identity,
  because its clamped index is defined on the exact stored integer
  and no registered model supplies an input-rounding rule for tables
  over arithmetic outputs. Admission bounds: at most 8 declared
  stages, no nesting (flattening changes rounding behaviour), empty
  tables reject as before, and an all-identity chain is exactly the
  identity mapping. Versions advance to `1.4.0`. Tests reproduce both
  conformance fixtures — a two-stage linear chain and an
  identity-table-linear chain — prove the advanced tokens, and reject
  a nested chain, a table after arithmetic and a nine-stage chain,
  all typed. The window-level composable set now covers every
  `ValueTransform` case within registered bounds.
- Thirty-seventh autonomous increment (owner overnight standing
  mandate): authored and accepted `VOXELIA-ALG-0006` (region origin
  shift `binary64-v1`) and `ADR-0071` (geometry-preserving region
  extraction), discharging the `ADR-0064` origin-shift deferral. The
  registered model updates the affine translation column — each
  element gains the ascending-order sum of rotation-scale products
  with the mapped lower bounds, separately and correctly rounded, no
  fused multiply-add — and the regular sampling origin
  (`origin + lower * spacing`), so every extracted sample keeps the
  exact world position and axis coordinate it had in the source; the
  rotation-scale block, mapped axes, coordinate space, spacing and
  determinant admission hold by construction, and rebuilt values
  revalidate through their accepted initializers. The extraction
  operation now admits affine geometry and regular sampling
  (irregular, categorical and externally defined samplings stay typed
  rejections as different slicing models), the dead geometry
  rejection case is removed before any release, and versions advance
  to `1.1.0`. Tests reproduce both fixtures through the full
  operation — the rotated translation update `(10, 22, 30)` with
  unchanged non-translation elements and the regular-origin shift to
  `7.5` — prove byte-exact samples, the advanced tokens and the
  externally-defined rejection.
- Thirty-eighth autonomous increment (owner overnight standing
  mandate): authored and accepted `ADR-0072` (canonical derivation
  record projection) and implemented the `VCDJ-1` profile, the fifth
  compiled `ContentID` tuple (`sha256`, `serialisedObject`,
  `org.voxelia.derivation-record` version `1.0`, 102-byte frame),
  `DerivationRecordID` (a validated content-addressed derivation
  record claim constrained to the registered tuple) and the
  completing `derivation` case of `DataIdentityReference` with its
  one-member wire — updating the `ADR-0053` strict wire, the `VCPJ-1`
  emitter and the strict ingress before any release, so existing
  documents' bytes and digests are unchanged. The profile reuses the
  accepted member forms (bare tokens, decimal-string semantic
  versions with exact build metadata, the reference and `ContentID`
  wires, the shared string-token authority), an empty input array is
  the canonical form of a declared zero-input generator, the emitter
  enforces the input ceiling before writing with the established
  cancellation cadence, and strict `VCDJ-1` ingress is recorded as
  the next codec increment under the `ADR-0061` pattern. Tests
  reproduce both independently computed goldens (the 721-byte full
  record with build metadata, framed `3943…2b72`, and the 522-byte
  zero-input generator, framed `e4e0…5ccc`), prove determinism and
  the exact byte ceiling, reject the crossed record-claim tuple,
  round-trip the widened reference wire with a malformed-nested
  rejection, and round-trip a provenance record whose input identity
  is a derivation reference through the accepted `VCPJ-1` codec; the
  reference and provenance suites re-passed unchanged. The
  `ADR-0037` reference union is complete.
- Thirty-ninth autonomous increment (owner instruction: "build the
  VCDJ ingress autonomously"): authored and accepted `ADR-0073`
  (strict canonical derivation ingress) and implemented
  `CanonicalDerivationJSON.decodeRecordDocument` as the same four
  transactional phases as the accepted provenance ingress — input
  ceiling and shared pre-parse nesting scan, shape-directed platform
  parsing with exact member sets, revalidating reconstruction with an
  empty input array reconstructing as the declared zero-input
  generator, and the canonical byte-equality gate through the
  accepted emitter. Because the `VCDJ-1` member forms are by
  definition the `VCPJ-1` member forms, the shape-directed extraction
  primitives and shared member reconstructors became one internal
  authority reused by both strict ingresses — two copies decoding one
  registered form could drift silently, so reuse is the conservative
  option — with cross-domain failures mapped into the derivation
  ingress's own payload-free five-case taxonomy. Tests round-trip the
  full record, the zero-input generator and a record exercising every
  identity-reference case to equal records and identities, and reject
  over-ceiling input, a pre-parse nesting bomb, malformed JSON, the
  wrong schema identifier, an extra member, a foreign
  parameter-digest tuple and whitespace and number aliases, all
  payload-free; the provenance codec suites re-passed unchanged. The
  `VCDJ-1` projection is now usable end to end.
- Fortieth autonomous increment (owner broadened standing mandate:
  complete the work autonomously without per-gate authorization):
  authored and accepted `ADR-0074` (sampling payload slicing),
  discharging the `ADR-0071` slicing deferral for the two knowable
  samplings. Because nothing in the accepted descriptors binds a
  sampling payload count to its axis extent, slicing is defined only
  when the payload count equals the source extent — a mismatch is its
  own typed rejection, never a guessed alignment — and aligned
  irregular coordinates and categorical labels crop to the exact
  element copies at the region bounds, revalidated through their
  accepted initializers. Externally defined sampling stays a typed
  rejection because an external definition's slicing semantics are
  not knowable here. Versions advance to `1.2.0`. Tests crop an
  irregular axis and a categorical axis to the exact expected slices
  in one execution, prove the advanced tokens, and reject a
  misaligned payload and the external case typed.
- Forty-first autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0075` (canonical document
  store) and implemented the actor-isolated `CanonicalDocumentStore`
  in `VoxeliaStorage`, the `ADR-0038` persistence-integrity
  assignment for canonical documents. Because accepted `ADR-0036`
  forbids digest material in filenames, content-addressed naming is
  excluded by governance: documents are addressed by validated
  `CanonicalDocumentName` labels (single lowercase 1-through-64-byte
  labels, structurally traversal-free), with the caller owning the
  name-to-record mapping. The store verifies the supplied identity
  against the exact bytes timing-safe before anything touches disk,
  verifies read bytes against the caller's expected identity before
  returning them, preflights file sizes against the caller's byte
  ceiling before reading, writes through the platform's documented
  atomic data write (recorded as the trusted primitive, with
  independent power-fail evidence an open recorded gap), treats a
  same-name same-content store as idempotent and a same-name
  different-content store as typed corruption, and is append-only —
  no deletion, overwrite or rename exists, so an immutable name can
  never come to mean different bytes, and retention governance stays
  deferred. Tests round-trip a real canonical document through a real
  directory and produce real on-disk corruption evidence: a
  byte-flipped document rejects on load and on re-store with the
  corrupted bytes left untouched, a truncated document rejects, a
  wrong expected identity rejects, plus the unverified-claim,
  missing-document, byte-ceiling, invalid-name and invalid-directory
  rejections, all typed and payload-free.
- Forty-second autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0076` (recorded fuzz and
  differential oracle evidence) and implemented both campaigns as
  deterministic suites. The mutation campaign drives two thousand
  seeded byte mutations — flips, insertions and deletions at
  generated positions — across the five registered golden corpus
  documents (`VCMJ-1` empty envelope, both `VCPJ-1` goldens, both
  `VCDJ-1` goldens) with the invariant that every mutant is either
  rejected by throwing or accepted as a record whose canonical
  re-emission equals the mutant byte for byte: no crash, no hang
  within budgets, no acceptance of a non-canonical document. The
  oracle campaign feeds the canonical number tokens of 256
  deterministically generated finite binary64 values to the host
  `python3` interpreter, whose independent parser round-trips every
  token to the bit-identical value, as does Swift's own parser. The
  ADR records honestly that this narrows but does not close the
  `ADR-0035` gaps: external Ryu and V8 token-for-token oracles,
  sustained corpus-guided random fuzzing, the supported-device
  matrix, the universal raw ceiling and the `VOX-ERR-001` allocation
  disposition remain open.
- Forty-third autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0077` (retention and
  enrichment lifecycle) with `CCR-0026`, a documentation-and-
  governance increment discharging the `ADR-0037` enrichment and
  `objectID` lifecycle gate item. A `DataObjectID` binds to at most
  one published immutable bundle forever, with publication the
  binding event and no future deletion legitimising rebinding;
  enrichment before publication is ordinary value construction;
  enrichment after publication publishes a new immutable bundle under
  new identifiers whose shared verified content identity is the
  cross-bundle linkage claim; and version-one retention across the
  published registry and document store is append-only, with ceiling
  exhaustion a typed transactional failure and any future deletion
  decision owing audit obligations and the never-rebind rule. No code
  changed: the accepted implementations already behave exactly as the
  policy requires, and the decision is that they are the policy.
- Forty-fourth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0078` (signed record manifest
  contract) and implemented the `VCRM-1` canonical record manifest
  with the sixth compiled `ContentID` tuple (`sha256`,
  `serialisedObject`, `org.voxelia.record-manifest` version `1.0`,
  100-byte frame) and the verify-side Ed25519 signature contract in
  `VoxeliaCore`. A manifest attests one non-empty record set: the
  emitter sorts entries into ascending digest-byte order and rejects
  duplicates, so exactly one canonical form exists per set, with
  empty manifests and the output ceiling typed. The signature subject
  is the manifest's domain-separated identity — a detached Ed25519
  signature over the manifest `ContentID`'s exact 32 digest bytes —
  so a signature can never be replayed against another projection
  domain. Voxelia ships verification only, taking the host-supplied
  raw public key and signature with malformed encodings typed and a
  mismatch a boolean result; no key is ever generated, stored or seen
  as a private value inside Voxelia, and a valid signature proves
  custody of a key, never trust, authorship authority or record
  truth. Tests reproduce the independently computed 555-byte golden
  manifest of the registered derivation and provenance goldens
  (framed `7cc5…991f`), prove order-independent single canonical
  form, the duplicate, empty and ceiling rejections, and end-to-end
  signature verification with a test-generated host key including
  tampered-signature, wrong-manifest, wrong-key and
  malformed-encoding outcomes. This discharges the `ADR-0038`
  signed-manifest deferral.
- Forty-fifth autonomous increment (owner broadened standing mandate,
  OPENING MILESTONE M3): authored and accepted `ADR-0079` (Metal
  execution context boundary) and implemented `MetalExecutionContext`
  in `VoxeliaMetal`. The context acquires the system default device
  and a command queue at construction with typed payload-free
  rejections and no fallback; no API accepts or exposes a device
  name, commercial model or named Metal generation, honouring the
  `VOX-PLT-013`/`VOX-PLT-014` capability-detection requirements.
  Version one detects the closed Metal 3 capability class through the
  platform's family query, mapped to the token
  `org.voxelia.capability.metal3` — which parses as the accepted
  `ADR-0051` execution-claim capability class, so GPU-executed claims
  plug into the existing provenance discipline unchanged — and
  exposes the unified-memory flag and opaque registry identifier as
  runtime evidence while device and queue handles stay
  module-internal for the kernel and residency increments. The class
  is unchecked-`Sendable` with the recorded justification that the
  platform documents `MTLDevice` and `MTLCommandQueue` as
  thread-safe. The suite acquired a real device on this Apple-silicon
  host — real GPU evidence, with an environment lacking a device
  failing loudly rather than skipping silently. The window-level MSL
  kernel and the CPU-Metal differential harness are the next M3
  increments, with the recorded constraint that MSL has no binary64,
  so GPU precision claims must carry honest binary32-device policy
  tokens and measured differential evidence, never a false
  binary64-strict claim.
- Forty-sixth autonomous increment (owner broadened standing mandate,
  M3): authored and accepted `ADR-0080` (window-level Metal kernel
  and differential harness) and implemented Voxelia's first GPU
  kernel. The embedded `MSL` source (family `window-level` 1.0.0,
  entry point `voxelia_window_level_u8`, kernel token
  `org.voxelia.kernel.window-level`) mirrors the `VOXELIA-ALG-0002`
  branch structure in `float32` — `MSL` has no binary64 — and is
  digest-pinned by the shader manifest
  (`302c…7cbd`), with the suite verifying the pin so source and
  manifest can never drift. `MetalWindowLevelKernel` compiles the
  source at runtime on the acquired context, builds its pipeline with
  typed payload-free failures, maps samples through shared-storage
  buffers on unified memory with an explicit in-kernel sample-count
  bound, and exposes the kernel component reference for honest GPU
  claims (`binary32-device`, `approximate`); claiming
  `binary64-strict` for GPU output is recorded as structurally false
  and prohibited. The differential harness drove the exhaustive
  `uint8` domain across six windows including the degenerate unit
  width against the frozen binary64 reference anchored to the
  registered fixtures, asserted the one-display-level bound and
  bit-identical repeated execution, and MEASURED the exact agreement:
  1536 of 1536 comparisons exact on this device — the `float32`
  approximation reproduced the binary64 model bit-for-bit over the
  full exhaustive `uint8` domain, recorded as single-device evidence,
  not a universal claim. Remaining M3 scope: the shared-resource
  residency strategy over the existing `ResidencyPolicy` vocabulary
  and the broader shader-identity governance as families grow.
- Forty-seventh autonomous increment (owner broadened standing
  mandate, M3): authored and accepted `ADR-0081` (Metal residency
  strategy) and implemented `MetalResidencyManager`, giving the M0
  `ResidencyPolicy` vocabulary its fulfilment contract. The closed
  version-one mapping selects shared storage for `automatic` and
  `shared` on the detected unified-memory capability — checked, not
  assumed — and private device storage for `gpuOptimised`; a
  device-buffer request under `cpuOnly` is a contradiction and its
  own typed rejection; `streamed` and `sparse` stay typed rejections
  pending their own contracts; and the manager never upgrades,
  downgrades or substitutes a policy, so declared intent is never
  silently rewritten. Buffer handles stay module-internal. The suite
  fulfilled the policies against real device buffers — a shared
  buffer round-tripping CPU writes and a private buffer allocating at
  the requested length — and proved every typed rejection.
- Forty-eighth autonomous increment (owner broadened standing
  mandate, opening the rendering model arc): authored and accepted
  `ADR-0082` (rendering camera and viewport models) and implemented
  the first backend-neutral `VoxeliaRendering` values per
  `VOX-ARC-008`. `ViewportSize` admits positive pixel dimensions
  under an inclusive 16,384 ceiling — a hard admission bound, not a
  device claim. `CameraProjection` is the closed
  orthographic/perspective description, and `RenderCamera` validates
  the look-at intent exactly in binary64: one shared coordinate
  space, a non-degenerate view direction, and an up direction whose
  cross product with the view direction meets the accepted no-epsilon
  smallest-normal rule; projection parameters admit at the owning
  aggregate per the axis-sampling precedent. No float-precision
  transform derivation happens in the model, because `VOX-SPA-004`
  admits rendering float transforms only after verified error bounds,
  which remain a recorded gate; stable coding is owned by a future
  presentation-provenance projection decision. Tests prove the
  viewport bounds, both projection admissions and all parameter
  rejections, the space rule and both degeneracy rejections.
- Forty-ninth autonomous increment (owner broadened standing mandate,
  rendering arc): authored and accepted `ADR-0083` (rendering
  transfer function model). `GreyscaleWindowFunction` validates a
  finite centre and a width of at least one in the input's real value
  domain — exactly the parameter semantics the registered
  `VOXELIA-ALG-0002` model froze — as presentation intent whose
  evaluation belongs to backends against the registered model and its
  measured GPU approximation; the closed `TransferFunction` holds
  exactly the greyscale-window case, with colour maps, opacity curves
  and volume transfer functions deferred as registered extensions
  (a colour map additionally needs a governed map registry before any
  token can mean anything). The controlled rule keeping display
  windows out of the Core `ValueTransform` is honoured by placement.
  Tests admit valid windows including the degenerate unit width and
  reject non-finite and sub-one parameters typed.
- Fiftieth autonomous increment (owner broadened standing mandate,
  rendering arc): authored and accepted `ADR-0084` (render quality,
  layer and scene snapshot models). `RenderQuality` is the closed
  `interactive`/`full` description — accumulation and denoising are
  result-provenance states, and version-one renderers are
  deterministic single-pass; `RenderLayer` references one published
  immutable bundle by `DataObjectID` with its transfer function
  (opacity and blending arrive with multi-layer compositing as their
  own registered model); and `SceneSnapshot` binds a non-empty
  ordered layer list under an inclusive 64-layer ceiling to one
  camera, with order as compositing order participating in identity.
  Scenes reference published bundles by identifier rather than
  embedding pixel data, keeping the publication registry
  authoritative. Tests admit a single-layer scene, prove order
  identity, and reject the empty scene and the ceiling typed.
- Fifty-first autonomous increment (owner broadened standing mandate,
  closing the rendering model arc): authored and accepted `ADR-0085`
  (render request, result and renderer protocol). `RenderRequest`
  composes the validated scene, viewport and quality; the closed
  version-one presentation states register exactly one case each
  (`slice`, `greyscale8`, accumulation `none`, denoising `none`);
  `PresentationProvenance` carries the honest CDMS section 12.4
  subset — camera, viewport size, transfer function, render mode,
  colour output, accumulation and denoising — with the presentation
  transform deferred behind the `VOX-SPA-004` float-bounds gate,
  clipping and cropping awaiting their own model, and the random seed
  field arriving only with the first stochastic mode, because a
  deterministic pipeline recording a seed would be a false claim.
  `RenderResult` binds the published output object identifier to its
  presentation provenance, and the backend-neutral `SliceRenderer`
  protocol closes the `VOX-ARC-008` version-one model surface. The
  recorded conformance assessment: oblique and perspective GPU slice
  rendering stays blocked by `VOX-SPA-004`, while an exact
  axis-aligned CPU slice presenter composing the accepted
  region-extraction and window-level operations is the natural first
  conformer as its own increment. Tests compose a full request from
  validated members, prove result and provenance identity across
  every field, and exercise the protocol through a conforming stub.
- Fifty-second autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0086` (exact diagnostic slice
  renderer) and implemented `ExactSliceRenderer` in `VoxeliaMetal` —
  placed there by the MTA's explicit diagnostic-renderer ownership
  and existing dependency edges, with no package-graph change. The
  first `SliceRenderer` conformer admits exactly one published layer
  with identity presentation (the request viewport must equal the
  image extents, because resampling is a numeric model gated with
  `VOX-SPA-004`), executes the accepted window-level operation as its
  entire numeric path, publishes the output through the accepted
  publication coordinator in complete mode with host-supplied naming
  and instant, and returns the result with its presentation
  provenance. THE FIRST VERTICAL SLICE RUNS END TO END: a published
  image renders to the registered window-level fixture bytes,
  published with depth-two complete provenance — every stage an
  accepted, evidence-carrying contract. Tests verify the exact output
  bytes, the provenance and registry state, and the typed
  unpublished-image and viewport-mismatch rejections.
- Fifty-third autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0007` (camera-relative
  float transform derivation `binary32-v1`) and `ADR-0087` (float
  transform error bounds), discharging the `VOX-SPA-004` gate for the
  registered derivation. The frozen model performs the
  camera-relative subtraction in binary64 before one demotion
  rounding per element — removing the large-coordinate cancellation
  that makes naive binary32 world transforms unusable — applies the
  transform in binary32 with frozen association and no fused
  multiply-add, and states the standard Higham-style forward error
  bound: per row, gamma-5 times the binary64 row magnitude sum, valid
  wherever intermediates stay within the binary32 normal range.
  `CameraRelativeFloatTransform` in `VoxeliaRendering` exposes the
  derivation, the binary64 reference and the per-index bound. The
  measured harness verified the bound on 15,000 rows across small-
  and large-coordinate regimes with a maximum observed bound ratio of
  0.621 — thirty-eight percent analytical headroom — proved
  bit-identical repeated derivation, and demonstrated that the naive
  world-space demotion order violates the same bound in the realistic
  near-content camera regime where the registered order satisfies it.
  Oblique and perspective presentation and resampling models can now
  be designed against a verified error budget; any float transform
  other than this registered derivation remains gated.
- Fifty-fourth autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0008`
  (nearest-neighbour resampling `binary64-v1`) and `ADR-0088`, and
  implemented the third operation,
  `org.voxelia.op.resample-nearest` 1.0.0. The registered model maps
  every output pixel to exactly one whole source sample through the
  frozen binary64 index computation with the pixel-centre convention
  — the computed result is the definition — copying every sample byte
  exactly, so the model is value-neutral across scalar formats and
  component counts. Resampled output is a new derived object, so the
  honest shape is a full Execution operation with the frozen
  `output-width`/`output-height` parameter schema, the registered
  parameter digest, the derivation recipe and subject-bound
  provenance with a graph-node parent edge, and the
  `binary64-strict`/`exact` execution claim; a silent renderer step
  would be exactly the unrecorded history the discipline forbids.
  Version-one admission covers rank-two index-only geometry-free
  images with extents one through 16,384 per output dimension, values
  and metadata passing through untouched; regular-spacing and affine
  scaling under resampling are origin-and-spacing arithmetic deferred
  to their own decision. Tests reproduce both fixtures — the 2-by-2
  block upsampling and the column-selecting downsampling — prove the
  identity mapping at equal dimensions, reproduce the parameter
  digest independently, admit the output into a depth-two complete
  graph and reject unsupported sampling and out-of-range extents
  typed.
- Fifty-fifth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0089` and lifted the exact
  slice renderer's identity-only viewport admission by composing the
  `ADR-0088` resampling operation. Window-level executes first — the
  value model consumes the stored-to-real composition — and
  nearest-neighbour resampling then maps the greyscale output to the
  requested viewport, keeping every stage a registered operation over
  its accepted domain. Both derived objects publish with full
  identity and provenance as a depth-three complete chain, because
  the coordinator's ancestry closure walks the published registry and
  an unpublished parent would be silent history; a viewport equal to
  the image extents publishes the single window-levelled object
  unchanged rather than minting a bit-identical identity resample.
  The host naming closure now receives a closed publication-stage
  value so two published objects get two host-supplied identifier
  sets, a recorded pre-release signature revision of the `ADR-0086`
  contract, and the dead `viewportMismatch` error case is removed per
  the `ADR-0071` precedent. Tests render an equal-extent viewport
  unchanged and render a doubled viewport into the registered
  window-level fixture duplicated into 2-by-2 blocks with both stages
  published and the resampled record's parent edge bound to the
  intermediate record.
- Fifty-sixth autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0009` (layered linear
  blend `binary64-v1`) and `ADR-0090`, and implemented the fourth
  operation, `org.voxelia.op.composite-layers` 1.0.0. The registered
  model composites two through 64 ordered greyscale eight-bit layers
  over a black background: for every element the accumulator starts
  at exactly positive zero and each layer applies the frozen binary64
  sequence — transparency subtraction, retained and contributed
  multiplications, one addition, no fused multiply-add — with the
  final value rounded half to even under a modelled clamp; the
  uniform rule has no distinguished base case because a first layer
  at opacity one reproduces its values exactly. The frozen parameter
  schema is one `opacities` floating-point array digested under the
  registered operation-parameters projection; admission requires
  equal-extent rank-two single-component `uint8` intensity layers
  with index-only sampling and no geometry or value transform, and
  the output carries empty metadata because element-wise blended
  metadata has no defined meaning — history flows through the
  provenance chain, which binds every layer with the `layer` role at
  its occurrence and a graph-node parent edge. Tests reproduce all
  three fixtures including exact reproduction through a fully
  transparent overlay, reproduce the parameter digest independently,
  admit the output with both layer parents into a complete graph and
  reject bad layer counts, unequal extents, transformed layers,
  regular sampling and malformed opacity lists typed.
- Fifty-seventh autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0091` and delivered
  multi-layer scene presentation end to end. `RenderLayer` gains the
  validated compositing opacity — finite in zero through one, the new
  typed `invalidLayerOpacity` rejection — discharging the `ADR-0084`
  deferral now that the blending model is registered.
  `PresentationProvenance` replaces its single transfer function with
  the ordered presented layers, because one transfer function cannot
  honestly describe a multi-layer result; each layer claim carries
  the object identifier, transfer function and opacity. The exact
  slice renderer window-levels every published layer in scene order,
  publishes each stage, blends more than one layer through the
  `ADR-0090` operation with the scene opacities, publishes the
  composite, and resamples per `ADR-0089` when the viewport differs;
  the publication-stage naming widens to per-layer window-levelled,
  composited and resampled cases, all recorded pre-release contract
  revisions. A single-layer scene requires opacity one and keeps its
  accepted single-publication shape — a single-layer fade would widen
  the compositing admission to one layer, its own versioned decision
  — rejected typed. Tests render a two-layer scene over one published
  object with differing windows reproducing the registered
  `VOXELIA-ALG-0009` fixture with every stage published and both
  parent edges on the composite record, keep the single-layer and
  resampled renders exact, and reject out-of-range opacities and
  single-layer fades typed.
- Fifty-eighth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0092` and delivered the GPU
  slice presentation path. `MetalWindowLevelOperation` implements the
  registered window-level operation at its current contract version
  with the new `org.voxelia.impl.window-level.metal` 1.0.0
  implementation: the accepted digest-pinned kernel executes over one
  budgeted coordinated read and the output carries the identical
  descriptor, sample-bytes identity, derivation recipe and
  subject-bound provenance with the honest device claim — metal
  backend, `binary32-device` precision, `approximate` status, the
  kernel component reference and the detected capability class,
  because `MSL` has no 64-bit floating type and `binary64-strict`
  would be false. The operation-parameters builder of the CPU
  implementation became public and is reused, so both implementations
  digest one frozen schema authority per the `ADR-0073`
  shared-authority rule, and device admission — `uint8` samples with
  an absent or identity transform, the plain registered model —
  rejects typed through the operation's own error surface. The exact
  slice renderer's orchestration became the single internal pipeline
  authority with an injected window stage, and the new
  `MetalSliceRenderer` conformer injects the device stage while
  composite and resample stay the accepted CPU operations; backend
  choice is the host's explicit decision with no silent fallback per
  the `ADR-0081` rule. The device test measured and printed the
  differential — twelve of twelve rendered samples exactly match the
  registered binary64 model on this device, single-device evidence —
  verified every published claim member and rejected a linear
  transform on the device path typed.
- Fifty-ninth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0093` and delivered the
  sixteen-bit device window-level paths. The embedded kernel source
  gains the `int16` and `uint16` entry points with all three entry
  points calling one shared inline mapping helper — the `MSL` model
  exists exactly once — and the shader manifest repins the new source
  digest with the family advanced to 1.1.0 and every entry point
  listed, verified by the pinned-digest suite. The kernel builds one
  pipeline per entry point and gains the typed scalar surface with
  new `unsupportedScalarType` and `invalidSampleByteCount`
  rejections; the device operation's admission widens to the three
  scalar types at implementation version 1.1.0, with 16-bit device
  reads native little-endian. The differential harness measured the
  device against the frozen binary64 model over deterministic
  seeded-LCG corpora — 4096 `int16` samples across five windows and
  4096 `uint16` samples across four — recording 36,864 of 36,864
  comparisons exact on this device within the asserted
  one-display-level bound, printed as single-device evidence and
  measured, never assumed; claims stay `binary32-device` with
  `approximate` status. The operation anchor proved the device
  implementation within one display level of the registered CPU
  implementation over a native `int16` image with the 1.1.0
  implementation reference, and unsupported scalar types and odd byte
  counts reject typed.
- Sixtieth autonomous increment (owner broadened standing mandate):
  authored and accepted `ADR-0094` and admitted the single-layer
  fade. The registered `VOXELIA-ALG-0009` model already defines the
  one-layer case — the uniform black-background rule has no minimum —
  so the compositing operation widens to one through 64 layers at the
  1.1.0 versions under the established
  compatible-domain-widening rule, with an empty layer list still the
  typed rejection. The renderer now composites whenever more than one
  layer is declared or a single layer carries a non-unit opacity,
  publishing the composite stage, while a single layer at opacity one
  keeps its accepted single-publication shape because an opacity-one
  composite would mint a value-identical object with no presentation
  meaning; the now-dead `unsupportedLayerOpacity` case is removed per
  the `ADR-0071` precedent. Tests reproduce the half-opacity
  single-layer fade against an independently computed fixture through
  the operation and end to end through the renderer with the
  composite stage published, verify the widened versions in the
  recipe, and keep the empty-list rejection typed.
- Sixty-first autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0095` and delivered canonical
  record archival — published history is now durable.
  `CanonicalRecordArchival` in `VoxeliaStorage` emits a bundle's
  provenance record under `VCPJ-1` and its derivation record under
  `VCDJ-1` when one exists, computes each registered record identity
  and persists each document through the accepted `ADR-0075` store,
  inheriting verify-before-persist, idempotent same-content
  re-archive and never-overwrite. The caller owns both names per the
  `ADR-0036` digest-sensitivity rule, and name presence must match
  record presence exactly — a derivation without a name and a name
  without a derivation both reject typed, never a silent skip — while
  the receipt reports the computed identities as evidence. Tests
  archive an origin and a derived bundle through a real directory,
  load every document back under its receipt identity and decode it
  through the strict ingress to the exact original record, prove
  re-archive idempotent and both presence mismatches typed with
  nothing touching the store.
- Sixty-second autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0096` and delivered the layer
  compositing Metal kernel, the second digest-pinned shader family.
  The embedded `voxelia_composite_layers` kernel mirrors the
  registered `VOXELIA-ALG-0009` uniform composite-over structure in
  `float32` over packed equally sized layers with one demoted opacity
  per layer; the manifest gains the `composite-layers` family at
  1.0.0 with its own pinned source digest and kernel token, and
  claims stay `binary32-device` with `approximate` status — device
  accumulation may contract multiplications and additions, which the
  approximation claim honestly covers and the differential measures
  rather than legislates. `MetalCompositeKernel` compiles the pinned
  source, exposes the kernel component reference, and rejects ragged
  layers and malformed opacity lists typed before anything touches
  the device. The differential harness measured deterministic
  seeded-LCG stacks at two, four, eight and the 64-layer scene
  ceiling — 13,311 of 13,312 comparisons exact on this device with
  the single deviation within the asserted one-display-level bound,
  printed as single-device evidence — anchored all three registered
  fixtures, and proved repeated execution bit-identical. A device
  composite operation behind this kernel is the recorded natural next
  increment.
- Sixty-third autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0097`, extending the
  `ADR-0076` evidence discipline to the archival cycle — hand-built
  fixtures cannot prove that the records the real pipeline actually
  produces survive the emit-persist-load-ingress cycle. The new
  standing suite renders a two-layer scene to a doubled viewport
  through the accepted renderer, producing the full five-record stage
  history — origin, two window-levelled layers, the two-parent
  composite and the resample — archives every published bundle
  through a real directory store with the origin carrying no
  derivation name and every stage carrying one, loads every document
  back under its receipt identity, and decodes each through the
  strict ingress to the exact published record. Every future pipeline
  stage that publishes a new record shape joins this obligation.
- Sixty-fourth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0098` and delivered the device
  composite operation per the `ADR-0092` pattern.
  `MetalCompositeLayersOperation` implements the registered
  compositing operation at its current 1.1.0 contract version with
  the new `org.voxelia.impl.composite-layers.metal` 1.0.0
  implementation: device admission mirrors the registered operation
  and rejects typed through the operation's own error surface, the
  accepted `ADR-0096` kernel is the entire device numeric path, and
  the output carries the identical descriptor, empty metadata,
  sample-bytes identity, derivation recipe and subject-bound
  provenance with one layer parent edge per layer under the honest
  device claim — metal backend, `binary32-device` precision,
  `approximate` status, the composite kernel component reference and
  the detected capability class. The CPU implementation's
  operation-parameters builder became public and is reused, so both
  implementations digest one frozen schema authority. The device test
  measured twelve of twelve samples exactly matching the CPU
  implementation over the fixture scene on this device — printed
  single-device evidence — verified every claim member and the shared
  parameter digest, and rejected a transformed layer and an
  out-of-range opacity typed.
- Sixty-fifth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0099` and completed the
  fully-device renderer path. The shared pipeline gains a
  composite-stage executor mirroring the window stage — one
  orchestration authority, explicit backend choice, no silent
  fallback — and `MetalSliceRenderer` now takes the composite kernel
  alongside the window kernel and injects both device operations, so
  every value-arithmetic stage of a device render carries its own
  honest `binary32-device`, `approximate`, kernel-referenced claim;
  the resample stage remains the accepted exact CPU operation because
  whole-sample selection performs no value arithmetic and a device
  approximation claim for it would be manufactured imprecision. The
  device test rendered a two-layer scene fully on the device with
  twelve of twelve samples exactly matching the registered binary64
  fixture — printed single-device evidence — and verified both stage
  records carry their device implementation tokens and kernel
  references.
- Sixty-sixth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0100` and added the
  presentation scaling claim. `PresentationProvenance` now carries a
  required closed `PresentationScaling` — `identity`, or
  `nearestNeighbour` with the pre-resample source extents per the
  registered `VOXELIA-ALG-0008` model — a pre-release revision of the
  `ADR-0085`/`ADR-0091` shape discharging the presentation-transform
  deferral for the axis-aligned scaling case. The renderer fills the
  claim from what actually happened, never from the request: identity
  when the resample stage never ran, and the presented image's
  validated pre-resample extents otherwise, so a consumer reads the
  scaling honestly from the result while graph inspection remains
  corroboration. A general transform matrix was rejected — the
  pipeline performs axis-aligned nearest-neighbour scaling only, and
  a matrix would imply a model that does not exist. Tests verify the
  identity claim on equal-extent renders, the exact source extents on
  resampled renders and the claim's participation in presentation
  identity.
- Sixty-seventh autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0101` and delivered record
  manifest archival. `CanonicalRecordArchival` gains
  `archiveManifest`: the `VCRM-1` manifest document emits over the
  caller-supplied archived record identities — only the caller knows
  which records form one history — the registered manifest identity
  computes and returns as the receipt, and the document persists
  through the accepted store under a host-supplied name with the
  inherited verify-before-persist discipline; the emitter's typed
  surface governs empty and duplicate sets, and signing remains
  host-side per the `ADR-0078` verify-only rule with no key material
  ever touching Voxelia. The end-to-end pipeline archival suite now
  collects all nine receipt identities from a full render's archived
  records — five provenance and four derivation — archives the
  manifest, loads it back under the returned identity and reproduces
  the manifest bytes independently from the same identity set, so a
  complete archived history is one verifiable durable artefact and a
  partial store is detectable against it.
- Sixty-eighth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0102` and delivered crop
  presentation — all four accepted operations are now reachable
  through the renderer. `VoxeliaRendering` gains the validated
  `RenderCrop` — one half-open rank-two region in image index space,
  non-negative and non-empty at construction with the typed
  `invalidCropBounds` rejection, while fit against a particular image
  remains the extraction operation's own admission — and
  `RenderRequest` carries an optional one with absence stated
  explicitly, discharging the `ADR-0085` cropping deferral. When a
  crop is requested the renderer runs the accepted region-extraction
  operation over every layer's stored image before window-level —
  extraction is the stored-domain model with registered geometry and
  sampling rules — publishing each cropped stage under the new
  publication-stage case, and `PresentationProvenance` claims the
  crop from what actually ran per the `ADR-0100` rule. Per-layer
  crops and viewport-derived inference were rejected: one scene, one
  presented region, and the crop is the host's explicit request.
  Tests render a cropped scene end to end with the cropped stage
  published and the exact windowed sub-region bytes, verify the crop
  and identity-scaling claims, and reject invalid bounds typed.
- Sixty-ninth autonomous increment (owner broadened standing
  mandate): sixteen-bit pipeline render evidence under the existing
  `ADR-0093` and `ADR-0099` obligations — no new decision surface.
  The device renderer suite now publishes a native `int16` origin and
  renders it end to end through the device path, measuring twelve of
  twelve samples exactly matching the registered CPU implementation
  on this device — printed single-device evidence — and verifying the
  metal implementation token on the published stage record, so the
  sixteen-bit device admission is proven inside the full pipeline
  rather than only at the operation boundary.
- Seventieth autonomous increment (owner broadened standing mandate):
  composed-pipeline and cache-alias evidence under existing
  obligations — no new decision surface. One render now exercises
  every stage kind together — two crops, two window-levels, the
  composite and the resample, seven published objects with a
  depth-five complete chain — reproducing the independently computed
  composed fixture exactly, claiming the crop and the pre-resample
  scaling honestly. The publisher is wired with a content result
  cache for the first time in the pipeline suites, and every
  published stage's verified bytes are proven present in the cache as
  an alias, loadable and re-verified under its own sample-bytes
  claim — exercising the `ADR-0067` best-effort alias phase through
  the real pipeline.
- Seventy-first autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0103`, recording interactive
  quality equivalence. The version-one pipeline is deterministic and
  single-pass, so `interactive` and `full` requests execute
  identically — now documented on the type instead of left implicit —
  and stage records claim the `full` quality policy under either
  request because that is what executed; the requested quality is
  deliberately not recorded in the presentation provenance per the
  `ADR-0100` rule, since an identically executed request leaves
  nothing distinct to claim, and a future degraded interactive path
  will carry its own quality tokens through its own decisions.
  Recording the request as provenance and claiming an interactive
  token today were both rejected as false. The suite proves the
  equivalence: one scene rendered under both qualities publishes
  identical bytes with identical full quality-policy claims.
- Seventy-second autonomous increment (owner broadened standing
  mandate): the M3 baseline row sweep and its first executable
  outcome. All 37 M3 rows were assessed against delivered work.
  Delivered or satisfied by construction: `VOX-PLT-001/011/013/014`,
  `VOX-REP-008`, `VOX-ARC-008`, `VOX-API-008`, `VOX-SPA-004`,
  `VOX-META-007`, `VOX-CON-004`, `VOX-MTL-001/003/004/007/014/016`,
  `VOX-R2D-001/002`, `VOX-ERR-004`, `VOX-VAL-006`, `VOX-DOC-007`
  (manifest version identities with the algorithm and decision
  records as the family specifications). Substantially satisfied:
  `VOX-META-008` — camera, viewport, per-layer transfer functions and
  opacities, crop and scaling are presentation claims, executed
  quality and software identity live on every stage record; a single
  scene-identity field remains future work. Vacuously satisfied until
  their subjects exist: `VOX-EXE-014/015` (no adaptive or preview
  path), `VOX-CON-005` (no draw callbacks), `VOX-ADP-006` (no MPS).
  Open and executable: `VOX-MTL-002` capability-model widening,
  `VOX-MTL-005` pipeline-state caching, `VOX-MTL-015` telemetry
  capture, `VOX-VAL-010` digest-bearing evidence lines. Open and
  gated: `VOX-MTL-006` frame contexts (needs the interactive frame
  architecture), `VOX-MTL-008` private-residency justification and
  `VOX-CON-008` priority propagation (need measurement campaigns).
  The first executable outcome shipped as `ADR-0104`:
  `MetalRendererPlanner` with the closed `VOX-CCH-002` policy set —
  reference, CPU-preferred, GPU-preferred, automatic — returning an
  evidence-carrying `RendererPlan` whose selection is always
  reported, never silent; reference and CPU-preferred select the
  exact CPU pipeline, the device policies select the device pipeline
  when the context and both kernels acquire and otherwise report the
  CPU fallback, and the `VOX-CCH-003` fail-closed rule holds by
  construction because every selectable implementation carries
  measured validation evidence. Tests plan all four policies on this
  device-bearing host, verify the reported selections and render the
  registered fixture through policy-selected renderers on both
  backends.
- Seventy-third autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0105` and delivered the
  `VOX-MTL-002` device capability model. `MetalExecutionContext`
  gains the detected `MetalDeviceCapabilities` — unified memory,
  sparse-texture support and ray-tracing support from platform
  capability queries, the maximum threadgroup width and recommended
  maximum working-set byte count from the device's own reported
  limits, and the maximum texture dimension as the documented
  platform contract for the admitted family, recorded as a
  documented-contract reliance because no runtime query reports it.
  Family checks stay module-internal per `VOX-MTL-003`: the public
  members are semantic booleans and limits, never Metal numbering,
  and the model selects nothing by itself — residency, planning and
  future sparse or ray-tracing work consume it through their own
  decisions. The real-device test asserts the documented texture
  limit and positive reported limits and prints the detected sparse,
  ray-tracing, threadgroup and working-set values as single-device
  evidence.
- Seventy-fourth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0106` and delivered
  `VOX-MTL-005` pipeline-state caching. `MetalExecutionContext` owns
  a `MetalPipelineCache`: compiled libraries keyed by the exact
  source digest and pipeline states by kernel token, source digest
  and entry point — the stable identities, with lookup never
  comparing source text because the manifest discipline pins each
  digest to its text. Both kernel families now acquire their
  pipelines through the cache and map its typed failures into their
  own error surfaces, so repeated kernel construction on one context
  reuses every compiled state; a process-global cache was rejected
  because pipeline states are device-bound and the context is the
  device boundary, and eviction was rejected as a future governed
  decision over a set bounded by the closed family registry. Build
  counts are exposed per the coalescing-evidence precedent, and the
  test proved reuse by observation: two libraries and four pipelines
  compiled across four kernel constructions on one context, with the
  second constructions compiling nothing and distinct entry points
  holding distinct cached pipelines.
- Seventy-fifth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0107` and delivered
  `VOX-MTL-015` kernel dispatch telemetry for every currently
  existing subject. Both kernel families take an explicit optional
  host-owned `MetalTelemetrySink` — absence stated explicitly — and
  invoke it after every completed dispatch with the kernel token,
  entry point, sample count, and the platform's own measured GPU and
  command-buffer latency seconds from the completed command buffer;
  Voxelia values still mint no clock, and the host owns recording
  policy. Upload time, frame time and residency-change telemetry
  remain open with their reasons — no blit path, no frame
  architecture and no runtime residency transitions exist, and
  inventing numbers for absent subjects would be fabricated evidence.
  The real-device test measured and printed roughly seven
  microseconds of GPU time for the window dispatch and six for the
  composite dispatch over the fixture, verified one value per
  dispatch with exact counts and non-negative durations, and proved a
  sinkless kernel dispatches unchanged.
- Seventy-sixth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0108`, reconciling
  `VOX-VAL-010` with the `ADR-0036` sensitivity rule and delivering
  shader fingerprint evidence. The sensitivity rule protects
  content-derived digests — its recorded rationale is dictionary
  attacks against potentially sensitive canonical content — while a
  shader-source fingerprint digests Voxelia's own public repository
  text, already committed in the manifest and the pinned-digest
  suites, so the rule does not cover it and content-derived digests
  stay protected. The three GPU differential evidence lines now carry
  the pinned source fingerprint of the measured family, binding every
  recorded measurement to the exact shader text it measured; the
  compiled-shader fingerprint is recorded honestly open, because
  runtime source compilation produces no stable compiled artefact and
  one arrives only with the gated metallib distribution work. The M3
  sweep's executable rows are now fully discharged: `VOX-MTL-002`,
  `VOX-MTL-005`, `VOX-MTL-015` and `VOX-VAL-010` all carry recorded
  decisions and measured evidence.
- Seventy-seventh autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0109` and ran the kernel
  throughput measurement campaign. The standing harness dispatches
  both families over scaled seeded corpora — 4,096 through 1,048,576
  window samples and a 262,144-element two-layer composite — timed by
  the platform's own command-buffer timestamps through the `ADR-0107`
  sink. Measured on this device: the window kernel reached roughly
  16.9 billion samples per second at the megasample size and the
  composite roughly 7.1 billion, with every dispatch delivering
  telemetry at its exact sample count. The `VOX-MTL-007`
  justification is now measured rather than assumed: on this
  unified-memory device the shared-storage buffers are host memory,
  no upload pass exists to measure, and that measured absence with
  the sampling cost printed beside it is the copy-reduction evidence.
  `VOX-MTL-008` stays honestly open — a private-residency benefit is
  measurable only for a repeated-sampling workload through
  buffer-injected kernel paths that do not exist, and building them
  solely to benchmark was rejected; the harness is the instrument a
  future repeated-sampling design will extend.
- Seventy-eighth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0110` and delivered
  `VOX-MTL-006` bounded frame contexts at the contract level.
  `MetalFrameScheduler` takes an explicit inclusive in-flight ceiling
  of at least one — no permissive default — and hands out identity
  `MetalFrameToken` values carrying monotonic frame indices as
  ordering evidence; acquisition at the bound is the typed rejection
  per the budget-ledger precedent, because pacing is the interactive
  loop's own future decision and the caller owns the cadence, and
  release-once reuse mirrors the retention-token discipline — a slot
  can never be freed twice or by a token that never held it.
  Suspending acquisition and preallocated frame pools were both
  rejected for version one: continuation queues encode a pacing
  policy no consumer has chosen, and no resources exist to pool.
  Tests acquire to the bound, reject the over-bound acquisition and
  double and foreign releases typed, and prove slot reuse with
  monotonic indices; the interactive draw-loop integration remains
  gated on its own architecture.
- Seventy-ninth autonomous increment (owner broadened standing
  mandate): the M4 opening assessment and its first executable
  outcome. M4 — the first DICOM CT vertical slice, 78 rows — was
  assessed under the M3 sweep precedent. Gated on the owner's
  supply-chain approval: every `VOX-DCM` row and `VOX-SPA-006`
  require the DICOMKit third-party dependency, and adding external
  code changes the trust boundary — that decision is surfaced to the
  owner, not taken autonomously; the package manifest today has no
  external dependency. Gated on future architecture: `VOX-INT-008`
  responsiveness and the draw-loop-coupled parts of
  `VOX-INT-005/006/007`, `VOX-R2D-014` off-screen-versus-interactive
  equivalence, and `VOX-MTL-009` full-volume duplication (needs
  volume workloads). Executable without external dependencies: the
  `VoxeliaInteraction` value models, the `VOX-R2D` presentation
  extensions (`MONOCHROME` semantics, inversion, pixel padding,
  interpolation policies), axis-aligned `VOX-MPR` reconstruction over
  regular volumes, `VOX-SPA-013/014` frame-of-reference and
  measurement models, `VOX-CON-009` concurrency campaigns and the
  `VOX-META-011` privacy assessment. The first outcome shipped as
  `VOXELIA-ALG-0010` (polyline length `binary64-v1`, frozen segment
  evaluation with exact fixtures five and seventeen) and `ADR-0111`:
  `VoxeliaInteraction` opens with the closed UI-framework-neutral
  ten-concern command vocabulary over validated payloads — pan, zoom,
  rotation, pick, the physical-space clip box, the accepted window
  function and crop, the crosshair whose coordinate space travels
  with its point, and measurement construction preserving the exact
  ordered input points beside the derived length computed once under
  the registered model. Tests construct every case, reproduce the
  fixtures exactly and reject invalid payloads, mixed spaces and
  empty measurements typed, discharging `VOX-INT-001/002/004/009` at
  the vocabulary level.
- Eightieth autonomous increment (owner broadened standing mandate):
  authored and accepted `VOXELIA-ALG-0011` (display inversion
  `exact-v1` — the eight-bit involution `255 - x`, no floating-point
  step) and `ADR-0112`, delivering both monochrome presentation
  conventions. Inversion is the fifth operation,
  `org.voxelia.op.invert-display` 1.0.0 with an empty frozen
  parameter schema, admitting eight-bit single-component intensity of
  any rank with no value transform — a parameter on the window
  operation was rejected because `VOX-R2D-008` demands independence
  from source-value transformation, and a separate published
  operation makes that independence structural.
  `GreyscaleWindowFunction` gains the explicit closed
  `PresentationPolarity` — `standard` for `MONOCHROME2`, `inverted`
  for `MONOCHROME1` — so the polarity travels inside every per-layer
  presentation claim, and the renderer composes the inversion over
  the window output under the new `inverted` publication stage.
  Tests reproduce the fixtures and the involution through the full
  operation, render an inverted layer end to end into exactly the
  inverted registered fixture with the stage published, and reject a
  value transform typed; `VOX-R2D-005` and `VOX-R2D-008` are
  discharged.
- Eighty-first autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0113` with `VOXELIA-ALG-0002`
  revision 1.2, delivering `VOX-R2D-009` pixel-padding exclusion at
  the operation level. The registered rule: a stored integer sample
  exactly equal to the declared padding sentinel is excluded before
  every stored-to-real step and displays exactly zero, with an absent
  padding value leaving revision 1.1 byte-identical. The window
  operation takes the optional sentinel with absence stated
  explicitly, rejects an unrepresentable sentinel typed, and advances
  to 1.5.0 under the established widening rule; the frozen parameter
  schema gains the `padding` entry exactly when declared, so every
  unpadded parameter document and digest is unchanged — proven by
  test. The device window implementation continues to claim contract
  1.4.0, the revision it implements, because claiming a rule it lacks
  would be false; a padded device path is its own future increment.
  Renderer wiring waits for the adapter that supplies padding values,
  per the row's own wording. Tests reproduce both padding fixtures,
  prove unpadded byte-identity and digest stability, and reject the
  unrepresentable sentinel typed.
- Eighty-second autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0114`, recording three
  clinical pipeline assessments per the documentation-only precedent.
  `VOX-META-011` is discharged structurally: provenance members are a
  closed set of grammar-bounded tokens, digests, versions, instants
  and host-supplied identifiers, the warning schema has no free-text
  member by reflected proof, image metadata never enters a record,
  and the fixed-schema emitter's golden byte-equality fixtures pin
  every byte — the deliberate opening is the row's own host-supplied
  arm. `VOX-SPA-013` is discharged by construction: every operation
  passes spatial geometry through with its coordinate space intact or
  rejects geometry-bearing input typed; no path drops a
  frame-of-reference silently. `VOX-R2D-012` is discharged by the
  append-only publication discipline: stored origins remain published
  and byte-readable beside every display-transformed stage, which is
  a distinct object, never a mutation. A future string-closure sweep
  is recorded as a candidate alongside emitter revisions.
- Eighty-third autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0012` (axis
  transposition `exact-v1`) and `ADR-0115`, opening the multiplanar
  reconstruction arc with the sixth operation,
  `org.voxelia.op.transpose-axes` 1.0.0. Extraction was found already
  rank-general, so an axial slab of a regular volume is extractable
  today; the missing piece was the value-neutral index remap. The
  registered model reorders axes under a declared permutation with
  whole-sample byte copies in exact integer arithmetic — the identity
  permutation reproduces the input exactly and a permutation composed
  with its inverse is the identity, both proven. Every per-axis
  property travels with its axis — descriptors, semantics, units and
  sampling payloads reorder intact, with the irregular payload's
  travel proven by test — while remapping an affine geometry's
  image-axis binding stays its own recorded decision, rejected typed.
  The frozen `axis-order` parameter schema digests under the
  registered projection with independent reproduction proven, and a
  fused reslice was rejected: one operation, one model. Coronal and
  sagittal presentation now composes as extract-then-transpose; the
  composing coordinator is the arc's next increment.
- Eighty-fourth autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0013` (singleton axis
  squeeze `exact-v1`) and `ADR-0116`, the seventh operation
  `org.voxelia.op.squeeze-axes` 1.0.0. Declared extent-one axes drop
  from the descriptor while the sample bytes stay identical in order
  — in the canonical packed layout an extent-one axis contributes no
  reordering, so the model is a descriptor-level rank change with no
  arithmetic. The selection is explicit — each declared axis must
  exist, have extent one and appear once, non-empty and never total,
  all else typed — because a host that means one axis should never
  lose another it forgot about; remaining axes keep their descriptors
  and payloads in order, and geometry-bearing input rejects typed
  with the binding remap its own decision. Tests prove both fixtures
  byte-identical with axis order preserved, reproduce the parameter
  digest independently, and reject empty, non-singleton, duplicate,
  out-of-range and total selections typed. Extract-then-squeeze now
  turns a regular volume into a published rank-two slice.
- Eighty-fifth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0117` and opened
  `VoxeliaImaging` with its first substantive API, the multiplanar
  slice coordinator. The closed `MPRPlane` vocabulary — axial,
  coronal, sagittal — fixes volume axis two, one or zero of a
  published rank-three volume; the coordinator composes the accepted
  extraction over the one-thick slab with the accepted squeeze over
  the fixed axis, publishing both stages under host-supplied
  per-stage naming so every slice carries a complete depth-three
  chain whose frozen recipes — slab bounds and dropped axis — are the
  explicit reproducible output geometry of `VOX-MPR-004`, with
  regular-sampling origins shifting through extraction under the
  registered rules rather than assuming isotropy. A fused reslice and
  a renderer-level MPR were both rejected: composition of registered
  operations is the model, and slab selection is image-processing
  semantics. Tests reconstruct all three planes of a two-by-three-by
  -two volume against independently computed fixtures with axis
  identities verified, prove both stages published with the slice's
  parent edge bound to its slab record, and reject an unpublished
  volume, a rank-two volume and out-of-range indices typed;
  `VOX-MPR-001` is discharged for axis-aligned reconstruction with
  oblique sampling gated on its own model.
- Eighty-sixth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0118` and ran the
  `VOX-CON-009` concurrency storm campaign with seeded-LCG
  determinism — irreproducible failures are not evidence. Measured on
  this host: sixty-four concurrent coalescing reads through one small
  budget with thirty-two cancelled mid-flight, every survivor exact
  and the coordinator ending fully released at a zero charged-byte
  count; sixty-four concurrent identity requests served by exactly
  two started computations — coalescing held under the storm — with
  every survivor yielding the golden identity; sixteen distinct
  publishes interleaved with sixteen duplicates of one bundle
  yielding exactly one duplicate win and fifteen typed rejections
  with an exact registry count; and one hundred strictly increasing
  snapshot generation successions with equal generations rejected
  typed at every step. The memory-pressure scenario stays recorded
  open — no synthetic pressure injection exists without process-level
  tooling, and simulated callbacks would be fabricated signals —
  and race detection beyond compiler-enforced actor isolation remains
  the sanitizer campaign's subject, recorded with it.
- Eighty-seventh autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0119` and delivered the
  viewport synchronisation group. `SyncedViewport` binds one
  host-owned integer identifier to one coordinate space —
  plane-agnostic, because the plane vocabulary lives in the imaging
  layer and the linkage rule needs only the frame — and
  `ViewportSyncGroup` takes a non-empty member list bounded at
  sixteen with unique identifiers plus the shared crosshair, with
  every member's space and the crosshair's space validated as one
  space at construction and on every crosshair move:
  frame-of-reference compatibility is construction, not convention,
  and a crosshair can never drift into a foreign frame. Tests link
  three orthogonal-view members over one patient frame, move the
  crosshair with revalidation proven, and reject empty, over-bound,
  duplicate-identifier, foreign-member and foreign-move groups typed.
  `VOX-INT-005` is discharged; the linkage half of `VOX-MPR-005` is
  discharged with crosshair-to-slice-index mapping recorded open on
  geometry-bearing volumes and the binding remap.
- Eighty-eighth autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0014` (three-point
  angle `binary64-v1`) and `ADR-0120`, extending the measurement
  vocabulary. `AngleMeasurement` preserves the exact ray point,
  vertex and second ray point in one shared coordinate space beside
  the derived radians computed once at construction — the frozen
  componentwise subtraction, declared-order dot and norms, the
  modelled cosine clamp that makes boundary angles exact, and the
  platform arccosine. A zero-length ray rejects as the new typed
  `degenerateAngleRay` before the model runs, because a fabricated
  angle for an undirected ray would be false, and a measurement mode
  on the polyline value was rejected — different admissions,
  different derived quantities. Tests reproduce all four fixtures
  exactly — the right angle, collinear opposite rays through one
  clamp end, forty-five degrees, and same-direction rays through the
  other — and reject degenerate rays and mixed spaces typed.
  `VOX-SPA-014` now covers distance and angle with area and volume
  recorded future models.
- Eighty-ninth autonomous increment (owner broadened standing
  mandate): the second M4 reassessment and its first outcome.
  Reassessed honestly: `VOX-R2D-006` window edge cases — dischargeable
  by assessment, the model froze the edges with fixtures;
  `VOX-INT-007` render generations — executable as a contract-level
  monotonic counter; `VOX-R2D-013` linear-interpolation display
  policy — executable as a registered bilinear value model, the
  largest remaining row; `VOX-META-002` format-metadata preservation
  — the pass-through machinery exists and the format adapter that
  would exercise it is DICOMKit-gated with the owner; `VOX-INT-006`
  picking — partially executable as an index-space hit model, with
  physical-position picking needing geometry-bearing volumes;
  `VOX-R2D-014` — vacuous until interactive output exists. The first
  outcome shipped as `ADR-0121`, discharging `VOX-R2D-006` by
  assessment per the documentation-only precedent: the registered
  model defines both edges exactly with the half-sample threshold and
  frozen rounding, the degenerate unit-width window is a defined
  fixture-pinned threshold whose interior is unreachable, and the
  fixtures already run across three scalar domains, the composition
  chain, both polarities, the padding sentinel and the measured
  device path — the record's value is the binding, not more copies.
- Ninetieth autonomous increment (owner broadened standing mandate):
  authored and accepted `ADR-0122` and delivered the `VOX-INT-007`
  render-generation contract. `RenderGeneration` wraps one comparable
  counter with the explicit staleness relation — earlier is stale,
  equality is freshness, one comparison with no convention to misread
  — and the actor-isolated `RenderGenerationCounter` mints strictly
  increasing never-duplicated generations under concurrency, proven
  by sixty-four concurrent advances yielding sixty-four unique values
  with exact bounds. Reusing the frame scheduler's slot index was
  rejected — occupancy is not scene version — and wall-clock stamps
  were rejected because the pipeline mints no clock. Stamping frames
  and dropping stale ones is the interactive draw loop's behaviour,
  gated on its own architecture; this vocabulary is the contract it
  will consume.
- Ninety-first autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0015` (bilinear
  resampling `binary64-v1`) and `ADR-0123`, the eighth operation
  `org.voxelia.op.resample-linear` 1.0.0 — the linear interpolation
  display policy of `VOX-R2D-013`. The registered model aligns pixel
  centres with edge replication through clamped taps and the
  unclamped-floor weight, interpolates in the frozen declared order
  with no fused multiply-add under ties-to-even rounding and the
  modelled clamp, and reproduces the input exactly at equal
  dimensions by construction — proven by fixture beside the upscale
  and downscale fixtures. Version-one admission is the display-policy
  value domain — rank-two eight-bit intensity, no transform, bounded
  extents — because interpolation reads values and the admission
  names its domain; a mode parameter on the nearest-neighbour
  operation was rejected so recipes stay distinguishable by operation
  identity. All three `VOX-R2D-013` policies now have registered
  semantics — nearest-neighbour, linear and the identity
  no-interpolation presentation — with the renderer-side policy
  selection and the `PresentationScaling` widening recorded as their
  own following decision.
- Ninety-second autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0124`, completing
  `VOX-R2D-013` on the renderer side. `RenderRequest` gains the
  closed `InterpolationPolicy` — nearest-neighbour or linear, no
  permissive default, because a silent default policy is a convention
  and the row asks for explicit ones — with the no-interpolation case
  remaining the identity presentation at equal extents where no
  policy runs and none is claimed. The renderer's resample stage
  dispatches to the registered operation the policy names, and
  `PresentationScaling` widens with the bilinear case so the claim
  states what ran per the accepted rule: the policy is honoured by
  the operation identity in the published recipe and stated in the
  presentation claim, never inferred. Tests render one scene under
  both policies to a doubled viewport — the nearest output unchanged
  from the accepted fixtures and the linear output equal to the
  independently computed bilinear fixture, with the bilinear claim
  carrying the exact pre-resample extents and the published record's
  operation identity verified. All three policies are now registered,
  selectable and claimed.
- Ninety-third autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0125` and delivered
  index-space pick resolution, plus the empty-scaffold assessment.
  `PickResolver.resolve` is a pure value function from a pick target
  and a presentation claim to a resolution: the claims are the map —
  identity is the index itself, nearest-neighbour inverts the
  registered forward map exactly to the source sample the displayed
  pixel came from, bilinear resolves the frozen dominant-tap rule
  because a blended pixel has four contributors and a pick must name
  one, and a claimed crop offsets by its lower bounds because
  cropping ran before scaling. The resolution carries every claimed
  layer with its object identifier — a composited pixel blends all of
  them — and an outside-viewport target rejects typed. The
  index-space halves of `VOX-INT-006` are discharged; the
  physical-position half stays gated on geometry-bearing
  presentation. Scaffold assessment: `VoxeliaGeometry` is chartered
  by `VOX-ARC-007` for mesh and geometry-operation abstractions
  beyond the accepted ray-bounds primitives it already hosts, with
  its consumers in later milestones; `VoxeliaCPU` is chartered by
  `VOX-ARC-010` for deterministic reference kernels and backend
  registration — the reference implementations currently live as the
  operations' own CPU paths, and relocating or registering them is a
  design decision recorded as a future candidate, not an empty-target
  obligation; the umbrella target re-exports and gains substance
  last. Neither warrants invention now.
- Ninety-fourth autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0008` revision 1.1 and
  `ADR-0126`, opening the geometry-bearing presentation arc. The
  registered rescale rules freeze under the pixel-centre convention:
  a regular axis becomes origin plus the half-sample shift times
  spacing with the spacing scaled, and an affine geometry updates in
  two frozen passes — translations accumulate over the original
  columns first, then spatial columns scale — so every resampled
  sample keeps its physical position using physical spacing rather
  than assuming isotropy or axis alignment. The nearest-neighbour
  operation admits regular sampling and affine geometry at the 1.1.0
  versions, rebuilds per-axis sampling and the geometry per the
  registered rules, keeps irregular and categorical payloads typed
  rejections — no linear rescale exists for them — and drops its
  now-dead geometry rejection per the dead-case precedent. Tests
  reproduce both rescale fixtures exactly — the regular axis at
  4.375 and 1.25, and the affine matrix with its unscaled third
  column — verify the coordinate space and the widened version, and
  keep geometry-free outputs byte-identical. `VOX-MPR-003` is
  discharged for the nearest policy; the bilinear widening and the
  physical-picking decisions continue the arc.
- Ninety-fifth autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0015` revision 1.1 and
  `ADR-0127`, completing the resampling half of the geometry-bearing
  arc. The bilinear model adopts the registered rescale rules
  verbatim, and both resampling operations now evaluate them through
  one shared internal implementation per the shared-authority
  precedent — two copies of one registered rule could drift silently
  — with the nearest operation refactored onto it byte-identically.
  The linear operation admits regular sampling and affine geometry at
  the 1.1.0 versions, keeps irregular and categorical payloads typed
  rejections, and drops its now-dead geometry rejection per the
  dead-case precedent. Tests reproduce the registered rescale
  fixtures through the linear operation exactly with the widened
  version verified, and the admission test moved to the irregular
  payload it still rejects. Both display policies now preserve
  calibration: `VOX-MPR-003` is discharged for both, and the
  physical-picking decision follows.
- Ninety-sixth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0128`, extending calibration
  through compositing. The inversion operation already passes its
  whole descriptor through and needed nothing; the compositing
  operation widens to 1.2.0 under the equality rule — every layer's
  axis list and spatial geometry must be exactly equal, any
  difference the new typed `layerCalibrationMismatch`, because
  blending samples at different physical positions would fabricate a
  position for the blend and exact equality needs no resampling
  model; the output carries the shared calibration unchanged because
  the blend moves no samples. The former index-only and geometry
  rejections are dead and removed; approximate geometry comparison
  was rejected under the no-epsilon rule — hosts that need alignment
  resample first — and the device composite keeps claiming contract
  1.1.0, the geometry-free revision it implements, with calibrated
  layers outside its admitted format. Tests blend identically
  calibrated layers with the calibration carried through at the
  widened version, keep geometry-free blends byte-identical, and
  reject axis and geometry mismatches typed.
- Ninety-seventh autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0129`, fully discharging
  `VOX-INT-006` with physical pick resolution.
  `PresentationProvenance` gains the optional presented-geometry
  claim, filled by the renderer from the final output's descriptor
  per the claim-what-ran rule — an uncalibrated presentation honestly
  claims none — and `PickResolution` gains the optional world
  position: because the claimed geometry is the final object's, its
  indices are viewport indices, and the frozen
  translation-plus-ascending-products evaluation maps the pick target
  directly to a point in the geometry's coordinate space; the
  source-index inversion stays independent — index identification
  walks the recipes, position reads the claim. Tests resolve a
  calibrated pick through the registered rescaled matrix to exactly
  (7.5, 24.5, 30) in the patient space and prove uncalibrated claims
  return no position rather than a fabricated one. Process note: the
  member addition to a shared presentation struct corrupted stale
  incremental objects across module boundaries, producing impossible
  test values and one unrelated crash; a clean rebuild restored the
  suite, and the recorded rule is to clean-build after layout-changing
  edits to cross-module value types.
- Ninety-eighth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0130`, completing
  `VOX-MPR-005` for axis-aligned volumes, and reassessed the
  geometry-bearing arc. `MPRSliceCoordinator.sliceIndex` maps one
  axis-domain crosshair component through the frozen rule —
  difference, quotient, ties-to-even rounding — with an out-of-volume
  component the typed rejection rather than a clamp, because
  presenting a nearest slice for a crosshair that left the volume
  would misreport where the views point; non-regular fixed axes
  reject typed, and mapping arbitrary world points onto obliquely
  oriented volumes awaits the affine-inverse model, the arc's
  recorded remaining opening. Tests map exact indices including the
  half-slice ties-to-even case and reject all four admission
  failures typed. Arc reassessment: the geometry-bearing presentation
  arc is complete for axis-aligned calibrated data — calibration
  flows window through resample with registered rescale rules,
  presentations claim their geometry, picks resolve to physical
  positions, linked views map crosshairs to slices — and its
  remaining openings are the affine-inverse model, the device
  composite's calibration widening, and oblique reconstruction, each
  recorded. The wider queue's remaining rows stay DICOMKit-gated,
  draw-loop-gated or measurement-workload-gated as recorded; the
  natural next work is consolidation — the register and format
  reference documentation for the seventy accepted decisions of this
  window — and the owner-facing summary of the gates awaiting their
  decisions.

=== OWNER SUMMARY (2026-08-05 morning, autonomous session window) ===

While you were away the loop delivered forty-three pushed increments,
`ADR-0088` through `ADR-0130`, taking the suite from 459 tests in 90
suites to 509 tests in 112 suites with every push preceded by a
verified full-suite pass. What exists now that did not before:

- Eight registered operations (up from two): extraction and
  window-level were joined by nearest-neighbour and bilinear
  resampling, layer compositing, display inversion, axis
  transposition and singleton squeeze — each with a frozen algorithm
  specification, python-computed fixtures, typed admissions and full
  identity, recipe and provenance assembly.
- The complete presentation pipeline: multi-layer scenes with
  per-layer opacity and monochrome polarity, cropping, three explicit
  interpolation policies, pixel-padding exclusion, and honest
  per-stage presentation claims — every stage a published object with
  a complete provenance chain.
- The device path: window-level and compositing Metal kernels,
  digest-pinned manifests, measured differentials (36,864 of 36,864
  exact for the 16-bit window paths; 13,311 of 13,312 for
  compositing), the policy-driven backend planner, pipeline-state
  caching proven by build counts, measured dispatch telemetry and
  throughput evidence of roughly 16.9 billion samples per second at
  the megasample size.
- Durable history: canonical record archival through the document
  store with manifest binding — a full render's five-record history
  round-trips ingress-exact from disk.
- Multiplanar reconstruction: axial, coronal and sagittal slices from
  regular volumes with recipe-explicit geometry, plus linked
  orthogonal views with validated crosshairs mapped to slice indices.
- The geometry-bearing arc: calibration flows through the whole CPU
  pipeline under registered rescale rules, presentations claim their
  geometry, and calibrated picks resolve to exact physical positions.
- The interaction vocabulary: the ten-concern command set, distance
  and angle measurements under registered models, viewport
  synchronisation, render generations and pick resolution.
- Milestone state: M3 is fully discharged or honestly gated with
  every row assessed; M4 is open with its dependency-free rows
  substantially discharged.

Four decisions are waiting for you — each a gate the loop
deliberately did not take autonomously:

1. The DICOMKit dependency. Every `VOX-DCM` row, `VOX-SPA-006` and
   the exercise of `VOX-META-002` need the DICOMKit third-party
   package. Adding external code changes the project's trust
   boundary, so this supply-chain decision is yours; the package
   manifest currently has no external dependency.
2. The visionOS platform component: installation needs your password
   and GUI session.
3. Multi-device evidence: all GPU evidence is honestly labelled
   single-device; broadening it needs hardware you would provide or
   approve.
4. `metallib` distribution: compiled-shader fingerprints and
   ahead-of-time shader distribution await a packaging decision;
   runtime source compilation is the current recorded approach.

Everything else that remains open is recorded with its reason in the
increments above: the affine-inverse numeric model, oblique
reconstruction, the interactive draw loop, deletion governance,
memory-pressure injection, the priority-propagation and
private-residency measurement workloads, and the external Ryu and V8
oracle campaigns.

- Ninety-ninth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0131`, closing the device
  composite's calibration gap. The blend is value arithmetic while
  calibration admission and passthrough are host-side, so the device
  implementation adopts the `ADR-0128` equality rule verbatim,
  carries the shared calibration to its output, and claims contract
  1.2.0 with the implementation advanced to 1.1.0 — the
  claim-what-you-implement rule cuts both ways, and an implementation
  that serves the full contract should claim it; the kernel and its
  measured evidence are unchanged. The real-device test blends
  identically calibrated layers with the calibration carried through
  and both widened versions in the recipe, and rejects a calibration
  mismatch typed. Calibrated scenes now blend identically on both
  backends, differing only in implementation reference and claim, as
  designed.
- One-hundredth autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0132` and delivered the third
  shader family — the device invert kernel, the first device
  implementation with an honest exact claim. The registered
  involution is pure unsigned eight-bit integer arithmetic, so the
  `MSL` kernel computes the registered model exactly with no
  floating-point step: the manifest family carries the `exact`
  precision policy and status, and the manifest note now
  distinguishes floating-point families, which must claim
  approximation, from integer-exact families, which must not.
  `MetalInvertKernel` acquires its pipeline through the accepted
  cache and delivers telemetry through the host-owned sink; the
  evidence obligation is equality, not a tolerance — a single
  deviation would falsify the exact claim — and the exhaustive
  256-value involution measured exactly equal to the registered model
  on this device, with double inversion reproducing the input and
  repeats bit-identical. The device invert operation and the
  renderer's invert-stage injection compose next.
- One-hundred-first autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0133`, completing the device
  value-stage set. `MetalInvertDisplayOperation` implements the
  registered inversion with the accepted integer-exact kernel as its
  entire device path, the whole descriptor passing through
  calibration included, and a claim carrying the metal backend with
  exact precision and status plus the kernel reference and capability
  class — the first device operation whose claim is exactness,
  because the arithmetic is. The shared pipeline's inversion stage
  became injectable mirroring the window and composite stages, the
  device renderer takes the invert kernel with the planner acquiring
  it alongside the others, and the device test rendered an inverted
  scene fully on the device into exactly the inverted registered
  fixture with every claim member verified. All three device value
  stages now exist, and device renders of inverted, composited,
  calibrated scenes carry per-stage device claims throughout.
- One-hundred-second autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0134` and opened `VoxeliaCPU`
  with the `VOX-ARC-010` backend registration. Registration is data,
  not dispatch: `RegisteredImplementation` names an operation
  contract, an implementation, its backend and precision claims, and
  one validated evidence identifier naming the accepting decision
  record, while `ImplementationRegistry` validates unique
  operation-and-implementation pairs with typed rejection and ordered
  per-operation lookup — the type lives in `VoxeliaExecution` because
  every backend registers into one vocabulary, and planners may
  consult it through their own future revisions.
  `CPUBackendRegistrations.standard` registers all eight CPU
  implementations with tokens taken from the operations' own public
  constants — token drift structurally impossible — the pinned
  current contract versions and precision claims. Free-text evidence
  and closure-holding dispatch registries were both rejected. Tests
  verify the eight registrations, the pinned window-level version,
  the token set equality and the typed duplicate rejection. The metal
  implementations join through their own registration increment.
- One-hundred-third autonomous increment (owner broadened standing
  mandate): authored and accepted `ADR-0135`, completing the
  registration vocabulary across both backends.
  `MetalBackendRegistrations.standard` registers the three device
  implementations in their own module per the ownership row, with
  their honest split versions — the contract each implements beside
  the implementation's own version, which the registry type carries
  separately by design — so the registry now states, in one queryable
  vocabulary, exactly the contract gaps the decision records narrate,
  such as the device window implementing contract 1.4 while the CPU
  implements 1.5. The cross-backend evidence lives in the validation
  target, whose charter sees both: the combined registry constructs
  without collision at eleven implementations, with
  dual-implementation operations listing both backends. Planner
  consultation now has its complete input.
- One-hundred-fourth autonomous increment (owner broadened standing
  mandate): authored and accepted `VOXELIA-ALG-0016` and `ADR-0136`,
  freezing the affine spatial inverse on paper before any
  implementation exists — the plan-first discipline for a numeric
  model that must not appear incidentally inside a consumer. The
  specification fixes the adjugate-over-determinant evaluation with
  one frozen cofactor form, the declared row-zero determinant
  expansion, no fused multiply-add and the no-epsilon determinant
  admission; three exact fixtures are cross-checked against a
  rational oracle, including the symmetric matrix whose exact inverse
  row is thirteen, minus three and one forty-ninths. The elementwise
  gamma-style bound is stated with a measurement obligation binding
  the implementing increment — the harness must verify it against an
  exact rational oracle over at least ten thousand seeded diagonally
  dominant matrices and report the maximum ratio with headroom, per
  the accepted precedent, because a bound asserted without
  measurement would be a claim without evidence. Gaussian elimination
  was rejected as data-dependent branching; the Swift model, harness
  and consuming world-to-index operation follow as their own
  increments.
- One-hundred-fifth autonomous increment (owner broadened standing
  mandate): implemented accepted `ADR-0137`, the `AffineSpatialInverse`
  authority in the spatial module realising the frozen
  `VOXELIA-ALG-0016` model — the one cofactor form, the row-zero
  determinant expansion and one correctly rounded division per entry
  over the validated matrix type, leaving exactly one typed rejection
  for a sub-threshold determinant. The specification's conservative
  elementwise bounds are computed at construction from the same
  rounded intermediates, and the measurement obligation is discharged:
  the harness reproduces all three conformance fixtures exactly,
  rejects the rank-deficient and subnormal-determinant cases typed,
  and the host python rational oracle inverted ten thousand seeded
  strictly diagonally dominant matrices across four magnitude regimes
  with every one of ninety thousand entries inside its bound — maximum
  observed ratio zero point five three nine, headroom one point eight
  six. The consuming world-to-index mapping follows as its own
  increment; no consumer may embed an ad-hoc inverse.
- One-hundred-sixth autonomous increment (owner broadened standing
  mandate): implemented accepted `ADR-0138`, the world-to-index
  mapping that completes the specification's consuming step. The
  frozen composition lives once in the spatial module as
  `AffineWorldToIndexMap` — three correctly rounded subtractions of
  the translation, then per-slot ascending products with left-to-right
  accumulation over the measured inverse, mirroring the claimed
  forward evaluation — with typed rejections for a foreign coordinate
  space and an unmapped image axis, because mapping either silently
  would fabricate a calibration. The multiplanar coordinator gained
  the world-point crosshair surface: a published volume's claimed
  affine geometry maps the point and the plane's fixed-axis component
  rounds under the accepted ties-to-even rule, with a new typed
  rejection for an uncalibrated volume and a double-domain range check
  shared with the axis-value path so absurd magnitudes reject typed
  instead of trapping. Fixtures pin the exact rotation-scale
  round-trip and the python-frozen symmetric slots whose final digit
  differs from the nearest-to-exact spelling — the frozen order is the
  claim, not the ideal. Obliquely oriented volumes now have their
  crosshair mapping; the pick-side viewport consumer follows as its
  own design.
- One-hundred-seventh autonomous increment (owner broadened standing
  mandate): implemented accepted `ADR-0139`, the reverse pick mapping
  that lets linked viewports follow one world crosshair. The claims
  stay the map: the presentation's claimed geometry is the final
  object's, so the frozen world-to-index composition recovers viewport
  indices directly and the geometry's own axis mapping assigns the
  slots to the two presented axes — no scaling or crop inversion
  exists on this path because the claim already describes the
  presented object. Out-of-plane components do not gate admission,
  mirroring the multiplanar rule, because each viewport presents its
  own plane's projection of a shared crosshair. Three typed cases
  joined the interaction vocabulary — an uncalibrated claim, an
  unmapped presented axis and a crosshair that left the view — chosen
  over an optional return because a caller must distinguish a
  presentation that cannot sync from a crosshair that merely left one
  view. Fixtures mirror the claimed forward evaluation exactly,
  including the off-plane projection and the ties-to-even half-pixel
  boundary. The interaction arc's world round trip is closed: picks
  resolve to physical positions and physical positions resolve to
  pixels, both through the same honest claims.
- One-hundred-eighth autonomous increment (owner broadened standing
  mandate): implemented accepted `ADR-0140`, the crosshair broadcast
  that turns one crosshair move into every linked pane's honest
  outcome. The synchronisation group stays a vocabulary value —
  presentations are supplied at the call because claims change per
  frame while membership does not — and one claim per member resolves
  through the accepted reverse mapping into per-member resolutions in
  member order. The distinction the reverse mapping's typed cases
  carry is folded honestly: a crosshair that left a member's view and
  an uncalibrated member are normal view states a host renders as a
  hidden crosshair or an unsynced pane, never a fabricated nearest
  pixel, while a presentation set that does not exactly cover the
  members and a claim in a foreign space are association mistakes
  that reject typed. The mixed-outcome fixture exercises all three
  states over the claimed forward evaluation in one broadcast. The
  interaction story over axis-aligned and oblique geometry is now
  closed end to end; the multiplanar oblique slab extraction remains
  the recorded design gap.
- One-hundred-ninth autonomous increment (owner broadened standing
  mandate): the M4 row sweep re-assessment, thirty increments after
  the opening assessment, under the M3 precedent of assessing before
  executing. All seventy-eight rows were re-read against the accepted
  register. Discharged since the opening: the interaction arc in full
  — `VOX-ARC-009`, `VOX-INT-001/002/004/009` (`ADR-0111`),
  `VOX-INT-005` (`ADR-0119`, `ADR-0140`), `VOX-INT-006` (`ADR-0125`,
  `ADR-0129`, `ADR-0139`), `VOX-INT-007` at the model level
  (`ADR-0122`), `VOX-INT-010` by the vocabulary's host-mapping
  design; the presentation rows `VOX-R2D-003/005/006/008/009`
  (`ADR-0112`, `ADR-0113`, `ADR-0121`), `VOX-R2D-012` at the
  resolution level (`ADR-0125`) and `VOX-R2D-013` (`ADR-0124`);
  axis-aligned multiplanar reconstruction `VOX-MPR-001/004/005`
  (`ADR-0117`, `ADR-0130`, `ADR-0138`, `ADR-0140`) and `VOX-MPR-014`
  at the model level; `VOX-SPA-013` through the rescale, claim and
  mapping authorities; `VOX-HLS-001` because every renderer output is
  already windowless; `VOX-ERR-005` through structured provenance
  warnings; `VOX-PER-007` and `VOX-VS1-017` by the `ADR-0118` storm
  evidence; `VOX-VS1-020` as the standing build configuration; and
  the capability halves of `VOX-VS1-009/011/012/013/014/015/019`,
  whose demonstrations against an ingested CT series remain bound to
  ingest. Honestly gated, unchanged: the DICOMKit block —
  `VOX-SPA-006`, `VOX-META-002`, all eleven `VOX-DCM` rows,
  `VOX-VS1-001` through `008` and the report row `VOX-VS1-021` — on
  the owner's outstanding supply-chain decision; the interactive draw
  loop for `VOX-INT-008`, `VOX-R2D-014`, `VOX-VS1-016` and the
  `VOX-PER-002/003/005` targets, plus reference hardware; volume
  workloads for `VOX-MTL-009`, `VOX-PER-008`, `VOX-VS1-018`; a real
  memory-pressure mechanism for the remainder of `VOX-CON-009` and
  `VOX-VAL-011`; known datasets for `VOX-VAL-012`; a study cache for
  `VOX-PER-006`; and `VOX-DOC-011`, which binds example targets that
  do not yet exist. Newly derived actionable queue, in order: the
  oblique multiplanar extraction design (`VOX-MPR-003`'s remainder —
  the one open reconstruction gap); the area and volume measurement
  models (`VOX-SPA-014`'s remainder, two frozen numeric models with
  oracle fixtures); and the diagnostics-and-logging design for
  `VOX-ERR-007`, `VOX-SEC-006` and the non-adapter half of
  `VOX-DCM-013`, whose default-exclusion rule deserves a decided
  vocabulary rather than incidental absence. `VOX-VAL-003/004/005`
  are the standing fixture discipline for internal evidence, with
  their external-dataset halves following the adapter.

- Governance: `ADR-0028` was accepted by the project owner on 2026-08-04,
  selecting the shared Core-owned `CanonicalInstant` for the raw metadata and
  provenance strings: one bounded uppercase zero-offset RFC 3339-derived
  profile on a leap-unaware 86,400-second grid, ten payload-free typed
  errors with fixed precedence and strict scalar-string Codable. `CCR-0005`
  records the controlled CDMS corrections (section 7.7 profile binding, the
  `instant(CanonicalInstant)` case, the `createdAt: CanonicalInstant` field
  and Appendix A). The leaf and its manual bounded ASCII parser are
  implemented in `VoxeliaCore`; the recursive `MetadataValue`,
  `ProvenanceRecord`, canonical JSON bytes, clock acquisition, arithmetic
  and ordering remain blocked by their own contracts.
- Governance: `ADR-0029` was accepted by the project owner on 2026-08-04,
  selecting the Core-owned `MetadataFloatingPoint` for the raw metadata
  `Double`: finite binary64 only, positive-zero canonical identity, exact
  preservation of every other finite bit pattern and strict scalar-number
  Codable without claiming canonical JSON bytes. `CCR-0006` records the
  controlled CDMS corrections (the `floatingPoint(MetadataFloatingPoint)`
  case, the resolved section-34.6 finiteness invariant and Appendix A). The
  wrapper and its value-redacted typed error are implemented in
  `VoxeliaCore`; the recursive metadata aggregate and canonical JSON remain
  blocked by their own contracts.
- Governance: `ADR-0030` was accepted by the project owner on 2026-08-04,
  selecting the Core-owned `MetadataBinary` for the raw metadata `Data`: one
  owned `ContiguousArray<UInt8>` snapshot, exact ordered-byte identity and
  strict padded standard-Base64 scalar Codable with canonical unused-bit
  rejection. It assigns host-selected limits to raw and standalone-leaf
  ingress without inventing an intrinsic leaf cap; proposed `ADR-0031`
  separately bounds recursive embedding. `CCR-0007` records the controlled
  CDMS corrections (the `binary(MetadataBinary)` case, the resolved
  section-55.3 Base64 selection, the closed section-72 direct-`Data` open
  decision and Appendix A). The wrapper and its manual codec are implemented
  in `VoxeliaCore`; the recursive aggregate and canonical document bytes
  remain blocked by their own contracts.
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
| `axes` | `ContiguousArray<AxisDescriptor>` | Spatial leaves implemented; binding blocked | Accepted `ADR-0021` (2026-08-04) assigned the axis model to `VoxeliaSpatial`; `CCR-0001` recorded the corrections and the three axis types are implemented with validated construction and strict wires. Core-owned axis-collection binding validation waits on the remaining `ImageDescriptor` prerequisites. |
| `spatialGeometry` | `SpatialGeometry?` | Proposed-dependent and contract-blocked | Coordinate-space policy, affine shape and tolerance, rectilinear binding, and the frame-index dependency cycle all remain unresolved. |
| `valueTransform` | `ValueTransform?` | Authorised; implementation in progress | Accepted `ADR-0023` (2026-08-04) and `CCR-0003` authorise the bounded four-case declaration with validated payload types in `VoxeliaCore`. Piecewise extension and lookup execution remain explicitly later scope. |
| `units` | `MeasurementUnit?` | Implemented and conformance-hardened | The unit must describe authoritative sample values; semantic and transform compatibility policy is still required. |

The blocked axis and spatial branch expands as follows:

| Prerequisite | Implemented leaves | Blocking contract |
|---|---|---|
| `AxisDescriptor` | `AxisID`, `AxisSemantic`, `AxisSampling`, `AxisDescriptor`, `MeasurementUnit` | Implemented in owning `VoxeliaSpatial` under accepted `ADR-0021`/`CCR-0001`. The descriptor's validated initializer and revalidating wire enforce the value-intrinsic invariants (finite non-zero regular spacing, finite origin and irregular coordinates, non-blank name, generic strings, categorical labels and external identifier). Extent-dependent invariants, duplicate-semantic policy and spatial-axis consistency remain Core binding validation behind the blocked `ImageDescriptor`. |
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
| `VOX-ERR-001` | The controlled `DataModelError` sketch is implemented exactly, while `ShapeError`, `RegionError` and other specialised typed errors carry the invalid-data behavior already exercised by focused Core tests. `ScalarFormat`, `ComponentDescriptor` and `ImageShape` evidence proves direct typed rejection and decoded case/context/underlying-error preservation for invalid metadata; `ImageShape` also proves exact typed failure for derived-count overflow and expected/actual rank mismatch at its index-containment boundary. `ImageSemantic` proves exact typed wire-decoding rejection with root-versus-nested coding paths. `SemanticVersion` proves all five direct-construction error cases and decoded root-context cause preservation for one negative component plus both identifier families. `ImageRegion` proves exact direct typed lower/upper-rank-mismatch rejection at construction and decoded root-context `dataCorrupted` preservation of the same underlying `.rankMismatch` cause, plus exact first-inverted-axis payload rejection directly and through the same decoded root-context path, and exact checked extent-subtraction `.arithmeticOverflow` rejection directly and through that decoded root-context path. The `ComponentInterpretation` generic wire additionally proves strict exact-key rejection of an extra-key payload with a `generic`-path `dataCorrupted` context, and `CodedConcept` proves root-context `dataCorrupted` rejection of missing-key and extra-key objects plus `typeMismatch` rejection of a non-object shape. The `DigestAlgorithm` and `ContentScope` closed vocabularies prove exact wire rejection: root-context `dataCorrupted` for an unknown token, `valueNotFound` for null and `typeMismatch` for number, boolean, object and array shapes. The shared `VoxeliaStringIdentifier` decoder proves, through `DataObjectID` and `ProvenanceID`, `rawValue`-path `dataCorrupted` with underlying `emptyOrWhitespaceOnly` for a blank value, root-context `dataCorrupted` for wrong-keyed objects and `typeMismatch` for non-object shapes. `ProvenanceKind` proves the same exact closed-vocabulary rejection pattern including the wrong-spelling `materialized` token. `MetadataPrivacyClass` proves that all six invalid-wire fixtures collapse to its one fixed empty-path value-redacted `dataCorrupted` failure with no underlying error. `AnyMetadataKey` proves root-context `dataCorrupted` rejection of wrong-keyed objects from its exact two-key guard plus `typeMismatch` rejection of a non-object shape. `LookupTableDescriptor` proves the same exact three-key guard and container-shape rejections plus nested-`outputUnit` revalidation with the `outputUnit`/`namespace` path and underlying `MeasurementUnitError.emptyNamespace`. Every broad `DecodingError` assertion in `VoxeliaCoreTests` is now closed to exact evidence; the remaining broad assertions live in the Spatial, Storage, Geometry and Metal test targets. The owning `VoxeliaSpatialTests` additionally proves the shared identifier decoder's exact blank/wrong-key/shape rejections through `AxisID` and a permissive conformer, showing the protocol-level blank guard fires regardless of concrete-type permissiveness, and proves `MeasurementUnit`'s exact six-key guard, container-shape rejection and field-path `dataCorrupted` revalidation with underlying `emptyNamespace` and `nonFiniteScaleToCanonical` causes. `CoordinateHandedness` and `SpatialTransformKind` prove the same exact closed-vocabulary `dataCorrupted`/`valueNotFound`/`typeMismatch` rejection pattern as the Core taxonomies, and `ExternalFrameReference` proves its exact key guard, container-shape rejection and already-exact blank-field revalidation. `SpatialAxisMapping` proves `imageAxes`-path `dataCorrupted` with all four exact underlying `SpatialAxisMappingError` payloads plus its one-key guard and container-shape rejections. `Point3D` and `Vector3D` prove their exact four-key guard, `coordinateSpace`/`rawValue`-path nested-space revalidation with underlying `emptyOrWhitespaceOnly` and container-shape rejections. `Plane3D` and `Ray3D` prove their exact two-key guard and container-shape rejections alongside their already-exact composite-invariant revalidation, and `AxisAlignedBounds3D` proves the same exact two-key guard and container-shape rejections alongside its already-exact inverted-bounds and space-mismatch revalidation. `Matrix4x4Double` proves `elements`-path `dataCorrupted` with exact underlying `invalidElementCount(actual: 3)` and `nonFiniteElement(index: 0)` payloads plus its one-key guard and container-shape rejections. Every broad `DecodingError` assertion in `VoxeliaSpatialTests` is now closed to exact evidence; the remaining broad assertions live in the Storage, Geometry and Metal test targets. In the owning `VoxeliaStorageTests`, `CodecIdentifier` proves its exact key guard, container-shape rejection and already-exact blank-field revalidation, and `StorageKind`/`StoragePersistence` prove the same exact closed-vocabulary rejection pattern as the Core and Spatial taxonomies. `CompressedRegionAccess` proves its exact closed-mode rejection, one-key and nested two-key guards with root and `custom` paths, `valueNotFound` for null and `typeMismatch` for wrong shapes including the `custom`/`namespace` field path. Every broad `DecodingError` assertion in `VoxeliaStorageTests` is now closed to exact evidence; the remaining broad assertions live in the Geometry and Metal test targets. In the owning `VoxeliaGeometryTests`, `GeometryKind`, `MeshPrimitive` and `IndexType` prove the standard exact closed-vocabulary rejection pattern and `GeometryAttributeSemantic` proves its exact closed-token, one-key/nested-two-key guard and wrong-shape rejections with root and `custom` paths. `GeometryAttributeDescriptor` proves its exact four-key guard and nested `scalarFormat`/`components` revalidation paths alongside its already-exact element-count and semantic-compatibility revalidation. `ResidencyPolicy` proves exact `valueNotFound` and `typeMismatch` declaration-wire rejection in the owning `VoxeliaMetalTests`. No broad `DecodingError` assertion remains in any repository test target: every decode-rejection branch across the Core, Spatial, Storage, Geometry and Metal suites now asserts its exact error case, coding path and, where produced, underlying typed cause. The complete 248-test package suite passes after the campaign. | This is Core invalid-data, typed arithmetic and typed operation-input evidence only. Allocation, live storage-capability, cancellation, backend, shader and convergence failure paths do not yet exist in their owning layers or remain behind Proposed contracts. Expanding a speculative global error enum is not authorised. |
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
- Closed the existing `ScalarFormat` invalid-data evidence leaf without a
  production change. Its constructor and decoding tests now carry
  `VOX-ERR-001` traceability, and decoding proves `dataCorrupted`, terminal
  `validBitCount` context and underlying `DataModelError.invalidScalarFormat`.
  This is Core invalid-data evidence only, not completion of global
  `VOX-ERR-001`, `VOX-DAT-010` or `VOX-VAL-001`.
- Closed the existing `ComponentDescriptor` invalid-data evidence leaf without
  a production change. All three constructor-invariant tests and the decoding
  test now carry `VOX-ERR-001` traceability; each invalid decoded fixture proves
  `dataCorrupted`, top-level descriptor context and underlying
  `DataModelError.invalidComponentDescriptor`. This is Core invalid-data
  evidence only, not completion of global `VOX-ERR-001`, `VOX-DAT-011` or
  `VOX-VAL-001`.
- Closed the existing `ImageShape` invalid-metadata evidence leaf without a
  production change. Its empty-rank, non-positive-extent and decoding tests now
  carry `VOX-ERR-001` traceability; both invalid decoded fixtures prove
  `dataCorrupted`, the exact top-level `extents` path and their corresponding
  underlying `ShapeError`. This is Core invalid-shape-metadata evidence only,
  not completion of global `VOX-ERR-001`, `VOX-DAT-003` or `VOX-VAL-001`.
- Closed the existing `ImageShape.elementCount()` typed-overflow evidence leaf
  without a production change. The constructible `[Int.max, 2]` shape now
  carries `VOX-ERR-001` traceability and still proves the exact
  `ShapeError.elementCountOverflow`, while `[Int.max]` remains the adjacent
  successful boundary. This is typed derived-count arithmetic evidence only,
  not recoverable allocation failure, an allocator call, storage
  pre-allocation validation, global completion of `VOX-ERR-001` or completion
  of `VOX-SEC-001`.
- Closed the existing `ImageShape.contains(_:)` typed rank-mismatch evidence
  leaf without a production change. Its containment-rank test now carries
  `VOX-ERR-001` traceability and still proves exact expected/actual
  `ShapeError.rankMismatch` values for empty, short and long index ranks. This
  is typed operation-input evidence only, not completion of index bounds/access
  safety, linear-offset safety, global `VOX-ERR-001`, `VOX-SEC-001` or M2
  `VOX-DAT-006`.
- Closed the existing `ImageSemantic` malformed-wire evidence leaf without a
  production change. Its four invalid fixtures now carry `VOX-DAT-012`,
  `VOX-API-004` and `VOX-ERR-001` traceability and prove exact
  `DecodingError.dataCorrupted` cases plus root or `generic` coding paths. This
  is typed wire-decoding invalid-data evidence only, not direct generic-string
  validation, aggregate semantic consistency, canonical JSON,
  duplicate-key/resource-limit coverage or completion of global
  `VOX-ERR-001`, `VOX-DAT-012`, `VOX-API-004` or `VOX-VAL-001`.
- Closed the existing programmatic `SemanticVersion` constructor-error
  evidence leaf without a production change. Its negative-core,
  malformed-prerelease and malformed-build tests now carry `VOX-ERR-001`
  traceability and retain exact payload assertions for all five
  `SemanticVersionError` cases across 18 fixtures. This is direct-construction
  invalid-version evidence only, not decoded error preservation, canonical
  SemVer wire/JSON, schema compatibility, privacy/redaction, completion of
  `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or M2 version use.
- Closed the existing `SemanticVersion` Codable-revalidation evidence leaf
  without a production change. The combined round-trip/revalidation test now
  carries `VOX-ERR-001` traceability, preserves its valid round trip and proves
  root-context `DecodingError.dataCorrupted` plus the exact underlying
  negative-major, invalid-prerelease or invalid-build error for all three
  malformed fixtures. This is Codable invariant-revalidation evidence only,
  not field-specific paths, canonical SemVer JSON/wire, duplicate-key handling,
  resource limits, schema handling, privacy/redaction, exact error vocabulary,
  global requirement completion or M2 version use.
- Closed the existing `ImageRegion` lower/upper-rank-mismatch constructor and
  decoder evidence branch without a production change. The direct and decoded
  rank-mismatch tests now carry `VOX-ERR-001` traceability; the direct test
  retains its exact `RegionError.rankMismatch` assertion and the decoding test
  now proves root-context `DecodingError.dataCorrupted` with the same
  underlying `.rankMismatch` cause instead of a broad `DecodingError` match.
  This is lower/upper collection rank-compatibility evidence only, not
  expected/actual rank payloads, field-specific paths, completion of all
  `VOX-RGN-002`, storage/access/offset safety, `VOX-SEC-001`, global
  `VOX-ERR-001` or `VOX-VAL-001`, canonical JSON or the empty-read policy.
  Inverted bounds, arithmetic overflow, extent construction, containment,
  translation and clipping evidence remains separate and unchanged.
- Closed the existing `ImageRegion` inverted-bounds constructor and decoder
  evidence branch without a production change. The direct and decoded
  inverted-bounds tests now carry `VOX-ERR-001` traceability; the direct test
  retains its exact first-inverted-axis
  `RegionError.invertedBounds(axis:lower:upper:)` payload assertion and the
  decoding test now proves root-context `DecodingError.dataCorrupted` with the
  same exact underlying `.invertedBounds` payload instead of a broad
  `DecodingError` match. This is per-axis bound-ordering evidence only, not
  exhaustive multi-axis ordering, field-specific paths, completion of all
  `VOX-RGN-002`, storage/access/offset safety, `VOX-SEC-001`, global
  `VOX-ERR-001` or `VOX-VAL-001`, canonical JSON or the empty-read policy.
  Rank mismatch, arithmetic overflow, extent construction, containment,
  translation and clipping evidence remains separate and unchanged.
- Closed the existing `ImageRegion` extent-overflow constructor and decoder
  evidence branch without a production change. The direct and decoded
  extent-overflow tests now carry `VOX-ERR-001` traceability; the direct test
  retains its exact `RegionError.arithmeticOverflow` assertion and the decoding
  test now proves root-context `DecodingError.dataCorrupted` with the same
  underlying `.arithmeticOverflow` cause instead of a broad `DecodingError`
  match. This is checked extent-subtraction overflow evidence only, not
  element-count or accumulated arithmetic, field-specific paths, completion of
  all `VOX-RGN-002`, storage/access/offset safety, `VOX-SEC-001`, global
  `VOX-ERR-001` or `VOX-VAL-001`, canonical JSON or the empty-read policy.
  Rank mismatch, inverted bounds, extent construction, containment, translation
  and clipping evidence remains separate and unchanged.
- Closed the existing `ComponentInterpretation` malformed-generic strict-wire
  evidence branch without a production change. The `ComponentDescriptorTests`
  JSON-schema test now carries `VOX-ERR-001` traceability and proves that the
  extra-key generic payload is rejected with `DecodingError.dataCorrupted`
  carrying exactly the single-element `generic` coding path of the nested
  container, instead of a broad `DecodingError` match. This is strict
  exact-key generic-wire evidence only, not missing-key or wrong-type payloads,
  root-level case-key strictness, canonical JSON bytes, completion of
  `VOX-API-004`, `VOX-DAT-011`, global `VOX-ERR-001` or `VOX-VAL-001`, or any
  change to the accepted wire shape. Descriptor round-trip, colour-count and
  name-validation evidence remains separate and unchanged.
- Closed the existing `CodedConcept` strict-wire malformed-fixture evidence
  branch without a production change. The strict-and-contextual decoding test
  now carries `VOX-ERR-001` traceability; its missing-key and extra-key object
  fixtures now prove root-context `DecodingError.dataCorrupted` from the exact
  four-key guard and its array fixture proves `DecodingError.typeMismatch` from
  the keyed-container request, instead of one broad `DecodingError` loop. The
  already-exact blank-field revalidation evidence is unchanged. This is strict
  exact-key wire and container-shape evidence only, not canonical JSON bytes,
  vocabulary binding, completion of `VOX-API-004`, global `VOX-ERR-001` or
  `VOX-VAL-001`, or any change to the accepted wire shape.
- Closed the existing `DigestAlgorithm`/`ContentScope` invalid-wire evidence
  branch without a production change. The invalid-values test now carries
  `VOX-ERR-001` traceability and proves, for both raw-value enums through one
  shared exact helper, root-context `DecodingError.dataCorrupted` for the
  unknown string token, `DecodingError.valueNotFound` for null and
  `DecodingError.typeMismatch` for the number, boolean, object and array
  shapes, instead of two broad `DecodingError` loops. This is
  closed-vocabulary wire-rejection evidence only, not canonical JSON bytes,
  digest computation, scope semantics, completion of `VOX-API-004`, global
  `VOX-ERR-001` or `VOX-VAL-001`, or any change to the accepted raw values.
- Closed the shared string-identifier strict-wire evidence branch exercised by
  the `DataObjectID` and `ProvenanceID` Codable tests without a production
  change. Both tests now carry `VOX-ERR-001` traceability and prove, against
  the one `VoxeliaStringIdentifier` protocol decoder,
  `DecodingError.dataCorrupted` with the single-element `rawValue` coding path
  and underlying `VoxeliaStringIdentifierError.emptyOrWhitespaceOnly` for the
  blank raw value, root-context `dataCorrupted` from the exact one-key guard
  for the empty and extra-key objects, and `DecodingError.typeMismatch` for
  the plain-string and array shapes, instead of two broad five-fixture loops.
  This is shared strict-keyed identifier-wire evidence only, not identifier
  vocabulary or uniqueness semantics, concrete-type rejection payloads,
  canonical JSON bytes, completion of `VOX-API-004`, global `VOX-ERR-001` or
  `VOX-VAL-001`, or any change to the accepted wire shape.
- Closed the existing `ProvenanceKind` invalid-wire evidence branch without a
  production change. The invalid-values test now carries `VOX-ERR-001`
  traceability and proves root-context `DecodingError.dataCorrupted` for the
  unknown and wrong-spelling `materialized` tokens,
  `DecodingError.valueNotFound` for null and `DecodingError.typeMismatch` for
  the number, boolean, object and array shapes, instead of one broad
  seven-fixture loop. This is closed-vocabulary wire-rejection evidence only,
  not provenance record or graph semantics, canonical JSON bytes, completion
  of `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any change to
  the accepted raw values.
- Closed the existing `MetadataPrivacyClass` invalid-wire evidence branch
  without a production change. The invalid-values test now carries
  `VOX-ERR-001` traceability and proves that every fixture — the unknown token
  and the number, boolean, null, object and array shapes — produces the one
  fixed `DecodingError.dataCorrupted` with an empty coding path, the fixed
  description naming no rejected value and no underlying error, instead of one
  broad six-fixture loop. This is uniform value-redacted wire-rejection
  evidence only, not classification semantics, host policy, the separate
  `VOX-ERR-007`/`VOX-SEC-006` nested-redaction evidence, completion of
  `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the
  five accepted raw values.
- Closed the existing `AnyMetadataKey` strict-wire malformed-fixture evidence
  branch without a production change. The erased strict-and-contextual
  decoding test now carries `VOX-ERR-001` traceability; its missing-key and
  extra-key object fixtures now prove root-context
  `DecodingError.dataCorrupted` from the exact two-key guard and its array
  fixture proves `DecodingError.typeMismatch` from the keyed-container
  request, instead of one broad three-fixture loop. The already-exact
  blank-field revalidation evidence is unchanged. This is strict exact-key
  erased-wire and container-shape evidence only, not typed
  `MetadataKey<Value>` semantics, canonical-digest normalisation, canonical
  JSON bytes, completion of `VOX-API-004`, global `VOX-ERR-001` or
  `VOX-VAL-001`, or any change to the accepted wire shape.
- Closed the existing `LookupTableDescriptor` strict-wire malformed-fixture
  evidence branch without a production change. The strict-and-revalidating
  decoding test now carries `VOX-ERR-001` traceability; its
  missing-`outputUnit` and extra-key fixtures now prove root-context
  `DecodingError.dataCorrupted` from the exact three-key guard, its array
  fixture proves `DecodingError.typeMismatch`, and its blank-namespace nested
  unit fixture proves `dataCorrupted` with the `outputUnit`/`namespace` coding
  path and underlying `MeasurementUnitError.emptyNamespace`, instead of two
  broad assertions. The already-exact non-finite-value evidence is unchanged.
  This closes the last broad `DecodingError` assertion in `VoxeliaCoreTests`
  and is strict wire, container-shape and nested-unit revalidation evidence
  only, not lookup execution or interpolation semantics, unit conversion,
  canonical JSON bytes, completion of `VOX-API-004`, global `VOX-ERR-001` or
  `VOX-VAL-001`, or any change to the accepted wire shape.
- Closed the shared string-identifier invalid-object evidence branch in the
  owning `VoxeliaSpatialTests` without a production change. The
  invalid-objects test now carries `VOX-ERR-001` traceability and proves,
  through one exact helper applied to `AxisID` and the permissive test-local
  conformer, `rawValue`-path `DecodingError.dataCorrupted` with underlying
  `VoxeliaStringIdentifierError.emptyOrWhitespaceOnly` for the blank object
  (regardless of concrete-type permissiveness), root-context `dataCorrupted`
  from the exact one-key guard for the extra-key and empty objects, and
  `DecodingError.typeMismatch` for the plain-string shape, instead of broad
  assertions. This is owning-module strict-keyed identifier-wire evidence
  only, not identifier vocabulary semantics, `rejectedByConcreteType` decode
  evidence, canonical JSON bytes, completion of `VOX-API-004`, global
  `VOX-ERR-001` or `VOX-VAL-001`, or any change to the accepted wire shape.
- Closed the existing `MeasurementUnit` strict-wire malformed-fixture evidence
  branch in the owning `VoxeliaSpatialTests` without a production change. The
  Codable round-trip/revalidation test now carries `VOX-ERR-001` traceability
  and proves root-context `DecodingError.dataCorrupted` from the exact six-key
  guard for the missing-optional-keys and extra-key objects,
  `DecodingError.typeMismatch` for the array shape, `namespace`-path
  `dataCorrupted` with underlying `MeasurementUnitError.emptyNamespace` for
  the blank-namespace object and `scaleToCanonical`-path `dataCorrupted` with
  underlying `MeasurementUnitError.nonFiniteScaleToCanonical` for the
  NaN-scale fixture, instead of three broad assertions. This is owning-module
  strict six-field wire and revalidation evidence only, not unit conversion or
  admissibility semantics, signed-zero canonicalization, canonical JSON bytes,
  completion of `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any
  change to the accepted wire shape.
- Closed the `CoordinateHandedness` and `SpatialTransformKind` invalid-wire
  evidence branches in the owning `VoxeliaSpatialTests` without a production
  change. Both invalid-values tests now carry `VOX-ERR-001` traceability and
  prove root-context `DecodingError.dataCorrupted` for the unknown token,
  `DecodingError.valueNotFound` for null and `DecodingError.typeMismatch` for
  the number, boolean, object and array shapes, instead of two broad
  six-fixture loops. This is closed-vocabulary wire-rejection evidence only,
  not handedness or transform semantics, canonical JSON bytes, completion of
  `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the
  accepted raw values.
- Closed the existing `ExternalFrameReference` strict-wire malformed-fixture
  evidence branch in the owning `VoxeliaSpatialTests` without a production
  change. The strict-and-contextual decoding test now carries `VOX-ERR-001`
  traceability; its missing-key and extra-key fixtures now prove root-context
  `DecodingError.dataCorrupted` from the exact key guard and its array fixture
  proves `DecodingError.typeMismatch`, instead of one broad three-fixture
  loop. The already-exact blank-field revalidation evidence is unchanged.
  This is strict exact-key wire and container-shape evidence only, not frame
  semantics, canonical JSON bytes, completion of `VOX-API-004`, global
  `VOX-ERR-001` or `VOX-VAL-001`, or any change to the accepted wire shape.
- Closed the existing `SpatialAxisMapping` strict-wire malformed-fixture
  evidence branch in the owning `VoxeliaSpatialTests` without a production
  change. The Codable test now carries `VOX-ERR-001` traceability and proves
  `imageAxes`-path `DecodingError.dataCorrupted` with the exact underlying
  `invalidAxisCount(actual: 0)`, `invalidAxisCount(actual: 4)`,
  `negativeAxis(position: 1, value: -1)` and
  `duplicateAxis(axis: 0, firstPosition: 0, duplicatePosition: 2)` payloads
  for the four invalid mappings, root-context `dataCorrupted` for the
  extra-key object and `DecodingError.typeMismatch` for the bare-array shape,
  instead of one broad six-fixture loop. This is strict one-key wire and
  revalidated mapping-payload evidence only, not transform or axis-model
  semantics, the separate `ADR-0021` ownership question, canonical JSON
  bytes, completion of `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`,
  or any change to the accepted wire shape.
- Closed the existing `Point3D`/`Vector3D` strict-wire malformed-fixture
  evidence branch in the owning `VoxeliaSpatialTests` without a production
  change. The Codable test now carries `VOX-ERR-001` traceability and proves,
  through one exact helper applied to both primitives, root-context
  `DecodingError.dataCorrupted` from the exact four-key guard for the
  missing-`coordinateSpace` and extra-key objects, `dataCorrupted` with the
  `coordinateSpace`/`rawValue` coding path and underlying
  `VoxeliaStringIdentifierError.emptyOrWhitespaceOnly` for the blank nested
  space, and `DecodingError.typeMismatch` for the bare-array shape, instead
  of broad loops. The already-exact non-finite-component evidence is
  unchanged. This is strict four-key wire, nested-space revalidation and
  container-shape evidence only, not spatial semantics, canonical JSON bytes,
  completion of `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any
  change to the accepted wire shape.
- Closed the existing `Plane3D`/`Ray3D` wrong-shape evidence branch in the
  owning `VoxeliaSpatialTests` without a production change. The already-tagged
  invariant-revalidation test now proves, through one exact helper applied to
  both composites, root-context `DecodingError.dataCorrupted` from the exact
  two-key guard for the missing-key and extra-key objects and
  `DecodingError.typeMismatch` for the array shape, instead of two broad
  loops. The already-exact composite-invariant revalidation evidence is
  unchanged. This is strict two-key wire and container-shape evidence only,
  not plane or ray semantics, canonical JSON bytes, completion of
  `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the
  accepted wire shape.
- Closed the existing `AxisAlignedBounds3D` wrong-shape evidence branch in
  the owning `VoxeliaSpatialTests` without a production change. The
  already-tagged strict-and-revalidating bounds test now proves root-context
  `DecodingError.dataCorrupted` from the exact two-key guard for the
  missing-`maximum` and extra-key objects and `DecodingError.typeMismatch`
  for the array shape, instead of one broad three-fixture loop. The
  already-exact inverted-bounds and space-mismatch revalidation evidence is
  unchanged. This is strict two-key wire and container-shape evidence only,
  not bounds semantics, canonical JSON bytes, completion of `VOX-API-004`,
  global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the accepted wire
  shape.
- Closed the existing `Matrix4x4Double` strict-wire malformed-fixture
  evidence branch in the owning `VoxeliaSpatialTests` without a production
  change. The Codable test now carries `VOX-ERR-001` traceability and proves
  `elements`-path `DecodingError.dataCorrupted` with exact underlying
  `invalidElementCount(actual: 3)` for the three-element object and
  `nonFiniteElement(index: 0)` for the NaN fixture, root-context
  `dataCorrupted` for the extra-key object and `DecodingError.typeMismatch`
  for the bare-array shape, instead of broad assertions. This closes the last
  broad `DecodingError` assertion in `VoxeliaSpatialTests` and is strict
  one-key wire and revalidated element-payload evidence only, not matrix
  semantics or numerical behaviour, canonical JSON bytes, completion of
  `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the
  accepted wire shape.
- Closed the existing `CodecIdentifier` strict-wire malformed-fixture
  evidence branch in the owning `VoxeliaStorageTests` without a production
  change. The strict-and-contextual decoding test now carries `VOX-ERR-001`
  traceability; its missing-key and extra-key fixtures now prove root-context
  `DecodingError.dataCorrupted` from the exact key guard and its array
  fixture proves `DecodingError.typeMismatch`, instead of one broad
  three-fixture loop. The already-exact blank-field revalidation evidence is
  unchanged. This is strict exact-key wire and container-shape evidence only,
  not codec semantics or negotiation, canonical JSON bytes, completion of
  `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the
  accepted wire shape.
- Closed the `StorageKind`/`StoragePersistence` invalid-wire evidence branch
  in the owning `VoxeliaStorageTests` without a production change. The
  invalid-values test now carries `VOX-ERR-001` traceability and proves,
  through one exact helper applied to both raw-value enums, root-context
  `DecodingError.dataCorrupted` for the unknown token,
  `DecodingError.valueNotFound` for null and `DecodingError.typeMismatch` for
  the number, boolean, object and array shapes, instead of one broad shared
  loop. This is closed-vocabulary wire-rejection evidence only, not storage
  capability or persistence semantics, canonical JSON bytes, completion of
  `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the
  accepted raw values.
- Closed the existing `CompressedRegionAccess` malformed-representation
  evidence branch in the owning `VoxeliaStorageTests` without a production
  change. The test now carries `VOX-ERR-001` traceability and proves
  root-context `DecodingError.dataCorrupted` for the unknown token, empty,
  unexpected-key and outer-extra-key objects, `custom`-path `dataCorrupted`
  for the missing-`name` and nested-extra-key payloads,
  `DecodingError.valueNotFound` for null, `DecodingError.typeMismatch` for
  the number and array shapes and `typeMismatch` with the
  `custom`/`namespace` path for the numeric namespace, instead of one broad
  ten-fixture loop. This closes the last broad `DecodingError` assertion in
  `VoxeliaStorageTests` and is closed-mode and strict custom-payload wire
  evidence only, not compression, region-access or codec execution
  semantics, canonical JSON bytes, completion of `VOX-API-004`, global
  `VOX-ERR-001` or `VOX-VAL-001`, or any change to the accepted wire shape.
- Closed the existing geometry-taxonomy invalid-wire evidence branch in the
  owning `VoxeliaGeometryTests` without a production change. The
  malformed-values test now carries `VOX-ERR-001` traceability and proves,
  through exact helpers, the standard closed-vocabulary
  `dataCorrupted`/`valueNotFound`/`typeMismatch` rejections for
  `GeometryKind`, `MeshPrimitive` and `IndexType`, and for
  `GeometryAttributeSemantic` the root-context `dataCorrupted` rejections of
  the case-mismatched and bare-`custom` tokens plus wrong-keyed objects,
  `custom`-path `dataCorrupted` for malformed custom payloads,
  `valueNotFound` for null and `typeMismatch` for wrong shapes including the
  string-valued custom payload, instead of two broad loops. This is
  closed-vocabulary and strict custom-payload wire evidence only, not
  geometry, mesh or attribute semantics, canonical JSON bytes, completion of
  `VOX-API-004`, global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the
  accepted wire shapes.
- Closed the existing `GeometryAttributeDescriptor` strict-wire
  malformed-fixture evidence branch in the owning `VoxeliaGeometryTests`
  without a production change. The already-tagged strict-and-revalidating
  test now proves root-context `DecodingError.dataCorrupted` from the exact
  four-key guard for the missing-`elementCount` and extra-key objects and
  `dataCorrupted` whose coding paths start at `scalarFormat` and `components`
  for the out-of-range nested format and zero-count nested components,
  instead of one broad four-fixture loop. The already-exact element-count and
  semantic-compatibility revalidation evidence is unchanged. This is strict
  four-key wire and nested-descriptor revalidation evidence only, not
  attribute semantics, canonical JSON bytes, completion of `VOX-API-004`,
  global `VOX-ERR-001` or `VOX-VAL-001`, or any change to the accepted wire
  shape.
- Closed the existing `ResidencyPolicy` malformed-wire evidence branch in the
  owning `VoxeliaMetalTests` without a production change. The malformed-values
  test now carries `VOX-ERR-001` traceability and proves
  `DecodingError.valueNotFound` for null and `DecodingError.typeMismatch` for
  the number shape, instead of one broad loop. This closes the last broad
  `DecodingError` assertion in the repository and is declaration-level
  wire-rejection evidence only, not allocation, capability or residency
  behaviour, canonical JSON bytes, completion of `VOX-API-004`, global
  `VOX-ERR-001` or `VOX-VAL-001`, or any change to the accepted wire shape.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0021`. The ADR
  file status, acceptance record and body tense were updated, the decision
  register table row moved to Accepted, and the ledger's current-state,
  prerequisite-matrix and known-blocker entries were reconciled. This
  acceptance selects Spatial ownership of the four axis types with Core-owned
  binding validation and authorises the ADR's migration steps in order. It
  does not itself change controlled `v0.1.1` baselines, implement source or
  accept any other Proposed ADR.
- Recorded controlled correction `CCR-0001` executing accepted `ADR-0021`
  migration step 1. The record cites the accepted ADR as authority, quotes
  the exact conflicting baseline rows (CDMS section 6 ownership table, CDMS
  Appendix A `AxisDescriptor` allocation, FVSP section 14 module
  participation), states the corrected Spatial-ownership rows with Core
  binding validation retained, and records the project owner's 2026-08-04
  approval with the introducing commit as its effective commit. No immutable
  `v0.1.1` baseline file was edited; no package edge, requirement row or
  source changed; no other Proposed ADR or correction is affected.
- Implemented accepted `ADR-0021` migration step 2: the axis model in its
  owning `VoxeliaSpatial` module. `AxisSemantic` mirrors the implemented
  `ImageSemantic` wire pattern with the twelve CDMS named cases plus the
  namespaced generic object. `AxisSampling` implements the five CDMS cases
  with an internal value-intrinsic validator (finite non-zero regular
  spacing per CDMS 14.4; finite origin and irregular coordinates following
  the `MeasurementUnit` non-finite precedent; non-blank categorical labels
  and external identifier following the blank-string precedent) and a strict
  one-tag revalidating wire with typed `AxisSamplingError` causes.
  `AxisDescriptor` implements the five CDMS fields with a validated throwing
  initializer (blank name and blank generic-semantic components rejected
  with typed `AxisDescriptorError`; sampling revalidated), a strict
  five-key explicit-null wire and field-path `dataCorrupted` revalidation.
  The DocC topics page gained the axis-model section. Extent-dependent
  binding invariants stay in blocked Core `ImageDescriptor` work; no other
  Proposed contract, package edge or baseline changed.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0022`. The ADR
  file status, acceptance record and body tense were updated and the
  decision register table row moved to Accepted. This acceptance selects the
  six-case namespaced `CoordinateConvention` owned by `VoxeliaSpatial` and
  authorises its migration steps in order; it does not resolve the separate
  `CoordinateSpaceDescriptor` unit policy, edit any `v0.1.1` baseline or
  accept any other Proposed ADR.
- Recorded controlled correction `CCR-0002` executing accepted `ADR-0022`
  migration step 1. The record quotes the exact four-case MTA section-10.2
  baseline sketch, states the corrected six-case namespaced sketch matching
  CDMS section 21.3, restates the wire, opacity, no-inference and
  open-unit-policy limits, and records the owner approval with the
  introducing commit as its effective commit. No immutable `v0.1.1` baseline
  file was edited.
- Implemented accepted `ADR-0022` migration step 2: `CoordinateConvention`
  in its owning `VoxeliaSpatial` module, mirroring the established
  string-or-strict-object wire pattern. Built-ins encode as the five exact
  tags; the custom case uses the strict namespaced two-key object; unknown
  tags, wrong shapes, missing fields and distinct extra fields are rejected
  with root or `custom`-path `dataCorrupted`, null with `valueNotFound` and
  non-object shapes with `typeMismatch`. The documented `impliedHandedness`
  projection encodes exactly the ADR's built-in matrix (right-handed for
  `cartesianRightHanded`/`dicomPatientLPS`/`neuroimagingRAS`, left-handed
  for `cartesianLeftHanded`, nil for `imageDisplay`/`custom` so callers
  must reject unresolved handedness explicitly rather than infer it). The
  DocC topics page gained the type. No unit policy, conversion transform,
  registry or `CoordinateSpaceDescriptor` work was started.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0023` and
  controlled correction `CCR-0003`. The ADR file status, acceptance record
  and body tense were updated and the decision register table row moved to
  Accepted. `CCR-0003` quotes the exact conflicting MTA section-9.9 and CDMS
  section-18.2 transform sketches and the CDMS section-18.4
  empty-composition alternative, states the corrected validated four-case
  declaration and the exact rejection branch, and restates the wire,
  zero-scale, signed-zero, deferred-piecewise and presentation-separation
  limits with the owner approval and introducing commit. No immutable
  `v0.1.1` baseline file was edited; no source changed in the governance
  commit.
- Implemented accepted `ADR-0023` migration step 2: the validated
  `ValueTransform` family in its owning `VoxeliaCore` module.
  `LinearValueTransformDescriptor` rejects every non-finite scale/offset
  position with `DataModelError.invalidValueTransform`, permits zero scale
  and canonicalizes signed zero to positive zero for one equality, hashing
  and encoding representation. `ValueTransformComposition` accepts a generic
  collection, materializes one immutable `ContiguousArray`, preserves
  first-to-last order, rejects emptiness with the same typed error and
  performs no flattening, identity removal or one-element collapse.
  `ValueTransform` implements the four exact tags with the strict documented
  payload wire; unknown tags, wrong shapes, missing/extra/multiple-tag
  fields are rejected with root or case-path `dataCorrupted`, null with
  `valueNotFound`, non-object shapes with `typeMismatch`, and payload
  invariants are revalidated on decode through the nested strict decoders.
  The DocC topics page gained the three types. Lookup execution,
  piecewise-linear behavior and presentation-stage values remain
  unimplemented by design.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0026` and
  executed its full migration. The versioned algorithm specification
  `VOXELIA-ALG-0001` records the binary64-v1 identifier, closed-set and
  parallel rules, half-scaling overflow fallback, signed
  overflow/underflow token order, normative evaluation sequence, typed
  failure policy and bit-exact conformance rule. The `VoxeliaSpatial`
  implementation follows that sequence exactly: coordinate-space mismatch
  before arithmetic, parallel-outside miss before quotient work, token
  selection without early exit, empty-interval nil before selected
  representability failures and entry-failure precedence over exit. The
  transient result has no public initializer and no `Codable`; signed zero
  canonicalizes to positive zero; the earliest axis retains tie provenance.
  The algorithms index and Spatial DocC topics were extended. No renderer,
  Metal, plane, oriented-bounds or point-evaluation work was started.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0027` and
  executed its authorised migration in one change: controlled correction
  `CCR-0004` (CDMS section-26.2 `frameAnchorIndex: FrameAnchorIndex` field
  correction plus the Appendix A Spatial additions, with `ImageIndex`
  ownership unchanged) and the `FrameAnchorIndex`/`FrameAnchorIndexError`
  leaf in `VoxeliaSpatial`. The validated initializer materialises any
  integer collection once, rejects the empty collection with `.emptyRank`
  and rejects the first component outside `0..<Int.max` in axis order with
  `.componentOutsidePossibleImageRange(axis:value:)`. The strict one-key
  `{"components":[...]}` wire never encodes the derived rank, rejects
  missing/extra/null keys and wrong shapes, and revalidates on decode with
  the `components` coding path and typed underlying cause. The DocC topics
  page gained the frame-geometry section. `FrameGeometry`,
  `FrameSetGeometry`, frame-set ordering, sparse/enhanced coverage and Core
  shape-bound binding remain blocked by their own contracts.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0028` and
  executed its authorised migration in one change: controlled correction
  `CCR-0005` (CDMS section-7.7 profile binding, the corrected metadata
  case and provenance field, Appendix A additions) and the
  `CanonicalInstant`/`CanonicalInstantError` leaf in `VoxeliaCore`. The
  manual parser materialises at most 31 UTF-8 bytes, validates the exact
  version-one grammar with proleptic Gregorian dates and the documented
  error precedence, canonicalises nothing, rejects rather than rewrites
  every alias and never echoes the supplied text. The strict single-string
  Codable revalidates on decode with the typed underlying cause. The DocC
  topics page gained the canonical-time section. `MetadataValue`,
  `ProvenanceRecord`, canonical JSON bytes, clock acquisition, arithmetic
  and ordering remain blocked or deferred by design.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0029` and
  executed its authorised migration in one change: controlled correction
  `CCR-0006` (the corrected metadata case, the resolved finiteness
  invariant and Appendix A additions) and the
  `MetadataFloatingPoint`/`MetadataFloatingPointError` leaf in
  `VoxeliaCore`. The initializer classifies through the binary64 bit
  pattern: NaN of any sign or payload and both infinities are rejected
  with the one value-redacted error, negative zero stores as the exact
  positive-zero bit pattern and every other finite pattern, including
  subnormals, is preserved unchanged with no arithmetic that could flush
  it. Equality and hashing are exact stored-bit identity. The strict
  single-number Codable revalidates on decode, so even a decoder
  configured with non-conforming float strings cannot create a non-finite
  wrapper. The DocC metadata topics gained both types. The recursive
  aggregate, entries, collections, privacy attachment and canonical JSON
  bytes remain blocked by their own contracts.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0030` and
  executed its authorised migration in one change: controlled correction
  `CCR-0007` (the corrected binary case, the selected strict padded
  standard-Base64 profile, the closed direct-`Data` open decision and
  Appendix A) and the `MetadataBinary` leaf in `VoxeliaCore`. The generic
  initialiser materialises one owned snapshot so caller-managed no-copy
  memory cannot change a stored value after hashing; identity is the exact
  ordered bytes with a valid empty value. The manual codec validates ASCII
  grammar, exact padding placement and zero unused bits before allocating
  through checked count preflight, decodes directly into the owned array,
  emits the one canonical string and never consults a Foundation data
  strategy; malformed semantic strings become one value-redacted
  `dataCorrupted` with no public error type. The DocC metadata topics
  gained the type. The recursive aggregate, entries, collections, privacy
  attachment, canonical document bytes and content identity remain blocked
  by their own contracts.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0031` and
  executed its authorised migration in one change: controlled correction
  `CCR-0008` (validated recursive cases, the resolved uniqueness/order
  invariant with the three hard ceilings, the exact tag vocabulary and
  Appendix A additions) and the bounded recursive value family in
  `VoxeliaCore`. `MetadataArray` preserves exact semantic order;
  `MetadataObject` sorts members canonically by unsigned UTF-8 key bytes
  after the resource preflight and rejects exact-key duplicates with a
  value-redacted error; both cache depth/element/payload metrics privately
  through checked `UInt64` arithmetic that maps overflow to the
  corresponding typed limit. Equality and hashing are iterative with
  explicit cursor frames and exact UTF-8 string identity. The strict
  one-tag wire decodes with an exact task-local container-ancestor guard
  (rejecting adversarially deep documents at level 65 before unbounded
  recursion) plus incremental element and payload budgets before accepting
  further children, and model-originated failures are value-redacted with
  contexts that never copy a caller-supplied coding path. The general
  entry, collection, multiplicity, typed reads, privacy attachment,
  canonical document bytes and record identity remain governed by
  `ADR-0032` through `ADR-0036`.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0032` and
  executed its authorised migration in one change: controlled correction
  `CCR-0009` (the required three-field entry, the required-attachment and
  class-sensitive-identity invariants, the corrected "carries exactly one
  explicit classification" phrase with its fail-closed handling rules, the
  expanded privacy-validation obligations and the Appendix A
  `MetadataEntry` row) and the general entry in `VoxeliaCore`.
  `MetadataEntry` pairs `AnyMetadataKey`, `MetadataValue` and a required
  immutable `MetadataPrivacyClass` through a nonthrowing nondefaulted
  three-argument initializer; no unclassified entry exists in source or on
  the wire, and no implicit conversion to or from the privacy-neutral
  object member is published. Equality and hashing include the exact
  declared class alongside exact key identity and semantic value identity.
  The manual Codable encodes exactly three fixed fields and rejects
  missing, null, distinct-extra, unknown and wrong-shaped fields; child
  failures are replaced at each fixed field boundary with value-redacted
  errors whose model-relative coding paths name only `key`, `value` or
  `privacyClass` and retain only audited payload-free project errors,
  and unknown class tokens are never coerced to `hostDefined`. The
  collection, multiplicity, typed reads, canonical document bytes,
  record identity and any resolver or export API remain governed by
  `ADR-0033` through `ADR-0036` and host policy.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0033` and
  executed its authorised migration in one change: controlled correction
  `CCR-0010` (the accepted collection boundary in section 34.5, the
  admission-bound duplicate invariant, the fixed typed-read cardinality
  rule, structural-only admission scope, the corrected binding-validation
  item, the type-level/canonical layer split, the dedicated collection
  error surface, expanded validation obligations and the acceptance
  criterion) and the ordered collection family in `VoxeliaCore`.
  `MetadataMultiplicityPolicy` bounds every supplied key occurrence
  against the policy count and byte ceilings before deduplicating and
  privately caches retained metrics that never join identity.
  `MetadataCollection` preserves exact input order with order-sensitive
  equality and hashing, rejects the second occurrence of an exact key
  under ordinary construction, admits repeats of exactly the
  allow-listed keys while retaining every occurrence and privacy
  declaration, and charges entry, aggregate-element and
  aggregate-payload budgets through checked arithmetic before accepting
  each occurrence. Ordinary encoding of a repeat-bearing value throws
  the typed policy-required failure before requesting an encoder
  container; configured encoding revalidates under exactly the supplied
  snapshot; decoding prechecks the advertised count, threads remaining
  aggregate element/payload budgets into the recursive value decoder
  through scoped task-local ceilings, and emits value-redacted failures
  on the fixed `entries` path retaining only audited payload-free
  project errors. The policy never appears on the wire. Typed reads,
  canonical ingress, persistent identity and any resolver or export API
  remain governed by `ADR-0034` through `ADR-0036` and host policy.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0034` and
  executed its authorised migration in one change: controlled correction
  `CCR-0011` (the phantom key's read-boundary role, the accessor surface
  bound to the closed eleven-case mapping with count-first cardinality
  and atomic ordered plural reads, the dedicated payload-free read-error
  vocabulary, the linear-lookup baseline recorded against sections 66/67,
  expanded validation obligations and the acceptance criterion) and the
  typed read surface in `VoxeliaCore`. `TypedMetadataEntry` keeps every
  successful read classified; the shared single-read engine throws
  `multipleValues` for a repeated key even when exactly one occurrence
  matches the requested case, and the shared plural engine preflights
  every match before materialising any result. Eleven private
  nonthrowing projectors pattern-match the exact cases; the overload
  family is the entire public conversion authority, so no runtime
  unsupported-type case exists. Optional reads, custom conversion,
  canonical ingress, persistent identity and logging/export APIs remain
  governed by their own decisions and host policy.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0035` and
  executed its authorised migration in one change: controlled correction
  `CCR-0012` (the `VCMJ-1` naming of section 55.2, the itemised section
  55.3 profile binding, version-one closure in 55.5, the frozen
  whitespace-oracle domain correction, the raw ingress obligations
  against sections 66/67, the validation obligations and the Appendix A
  types) and the canonical codec in `VoxeliaCore`. New source:
  `MetadataSchemaVersion`/`MetadataSchemaReference` with the bounded
  lowercase reverse-domain grammar validated character-before-charge;
  `CanonicalMetadataDocument` with no public initializer;
  `CanonicalMetadataIngressLimits` and `CanonicalMultiplicityContext`
  as immutable caller snapshots with no permissive defaults; the
  iterative `VCMJIngress` state machine with explicit semantic frames,
  strict UTF-8/escape/number/Base64 lexers, canonical-order key-first
  admission and payload-free error mapping; and the
  `CanonicalMetadataJSON` emitter with the shared sizing/writing
  fragment primitive and the ECMAScript number formatter derived from
  the standard library's shortest-digit conversion. The frozen
  whitespace oracle landed as private module-local implementations in
  Core and Spatial with cross-module fixtures. Persistent digests,
  signatures, export and permissive import remain governed by
  `ADR-0036` and later decisions.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0036` and
  executed its authorised migration in one change: `RFC-0002` recorded
  in the RFC register for the public `ContentID` data-model change (held
  at the register's fail-closed `Draft` status, with the owner's
  maintainer approval recorded in the accepted ADR, `CCR-0013` and this
  ledger); controlled correction `CCR-0013` (the one corrected record
  replacing both conflicting baseline sketches, the strict digest text,
  the version-one accepted profile and framing, and the source-identity
  claim/assurance precedence); and the identity surface in `VoxeliaCore`
  (`ContentProjectionVersion`, `ContentProjectionReference` with
  byte-limit-before-grammar precedence and no unbounded copies,
  `ContentIdentityError`, the validated `ContentID` with owned digest
  storage and synthesized four-component identity, the 109-byte framed
  CryptoKit SHA-256 computation with bounded 4,096-byte update slices
  and cancellation at every required point, timing-safe direct
  verification and the strict manual four-field wire). Golden evidence:
  the registered raw `a27e…ee50` and framed `8dde…7432` empty-document
  digests reproduced exactly over the emitter's 148-byte envelope,
  cross-checking the accepted `VCMJ-1` emitter independently. Cache
  admission, provenance integration, semantic identity and signatures
  remain governed by Proposed `ADR-0037` and later decisions.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0037` and
  executed its authorised documentation-only migration in one change:
  controlled correction `CCR-0014` (the corrected MTA section 11.3
  identity sentence with the claim/assurance vocabulary, the CDMS
  section 32.5/33 closed-state and source-invariant binding, the
  deferred derivation/reference sketch record with the `DataObjectID`
  persistent-identity blocker, the `VOX-RGN-007`/`VOX-RGN-008` readings
  and the tiered cache-admission interpretation). No Swift source was
  added or authorised: the accepted decision's own source gate keeps
  every identity value record blocked until its enumerated
  prerequisites receive separate decisions, and this increment records
  that boundary rather than implementing around it.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0038` and
  executed its authorised documentation-only migration in one change:
  controlled correction `CCR-0015` (the MTA ownership-language
  correction distinguishing Core claim values from Execution
  capture/assembly behaviour with the presentation-provenance and
  storage-coordinator boundaries, the closed subject-bound record
  target replacing the open-optional CDMS section 36.1 sketch, the
  eleven-kind activity binding, the validation-claim and
  warning-boundary corrections including the `deprecated(reason:)` and
  free-text `message` restrictions, and the bounded transactional
  graph-admission interpretation with the `ProvenanceID` durable-use
  restriction). No Swift source was added or authorised: the accepted
  decision's own source gate keeps the provenance aggregate, graph
  builder, canonical codec, digest, resolver, signature and publication
  integrations blocked pending their enumerated prerequisite decisions.
  With this acceptance the ADR register holds no Proposed records:
  `ADR-0001` through `ADR-0038` are all Accepted (with the `ADR-0025`
  identifier migration), and the remaining governance queue is the
  `RFC-0001` storage-contract Draft chain composing `ADR-0039` through
  `ADR-0041`.
- Recorded the project owner's 2026-08-04 directional approval of
  `RFC-0001` and executed the resulting documentation-only migration in
  one change: acceptance of `ADR-0039`, `ADR-0040` and `ADR-0041` in
  dependency order with the `ADR-0041` seal/drain model recorded as
  authoritative over `ADR-0039`'s older read-probe shape, and controlled
  correction `CCR-0016` (storage-ownership reconciliation without a
  `Core -> Storage` edge, the capability-taxonomy replacement, the
  four-layer logical/representation separation, the owned
  read-transaction target replacing the mutable unsafe-buffer sketch,
  and the Foundation-preserving `VOX-STO-004` M1-to-M5 mapped-storage
  schedule correction selected by the owner). The `RFC-0001` file stays
  register-`Draft` per the fail-closed validator; approval lives in the
  accepted ADRs, `CCR-0016` and this ledger. No storage source was added
  or authorised.
- Recorded the project owner's 2026-08-04 acceptance of `ADR-0024` and
  performed its one-time register reconciliation in the same atomic change.
  The platform record was Git-renamed from
  `ADR-0001-apple-ecosystem-only.md` to `ADR-0025-apple-ecosystem-only.md`
  with its identifier, heading and an identifier-migration record updated
  while its decision text, Accepted status, original 2026-08-02 date, owners
  and requirements stayed unchanged. Live references migrated in the same
  change: the decision index prose and table, the root README, the
  contributing guide, the governing-document index, this ledger's
  current-facing entries, the required-file check and the Apple
  platform-policy check. An Unreleased changelog entry records the
  correction; the v0.1.1 changelog entry, Corrective Release Notes and
  Static Verification Report remain unchanged as historical records. The
  MTA file, its Appendix A register and `ADR-0021` through `ADR-0023` are
  untouched.

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

`swift test --filter ScalarFormat` executed exactly the six tests in the
`ScalarFormat` suite; both `VOX-ERR-001` cases passed, including the explicit
decoded error case, terminal coding key and underlying typed error assertions.
`swift build --target VoxeliaCore` and strict format lint for the single changed
test file passed. No production source, public API, direct dependant, complete
Swift suite, controlled baseline or Proposed/Draft contract changed.

`swift test --filter ComponentDescriptor` executed exactly the eight tests in
the `ComponentDescriptor` suite. All four `VOX-ERR-001` tests passed, including
root-context and underlying typed-error assertions for each of the three
decoded invariant failures. `swift build --target VoxeliaCore` and strict
format lint for the single changed test file passed. No production source,
public API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

`swift test --filter VoxeliaCoreTests.ImageShapeTests` executed exactly the 14
tests in the `ImageShape` suite. Both direct constructor failures and the two
decoded fixtures passed with exact typed error, root `extents` coding-path and
underlying-error assertions. `swift build --target VoxeliaCore` and strict
format lint for the single changed test file passed. No production source,
public API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

The same exact `VoxeliaCoreTests.ImageShapeTests` filter reran all 14 shape
tests for the derived-count leaf. The typed `elementCountOverflow` assertion
passed alongside the unchanged maximum non-overflowing `Int` boundary.
`swift build --target VoxeliaCore` and strict format lint for the single changed
test file passed. No production source, public API, direct dependant, complete
Swift suite, controlled baseline or Proposed/Draft contract changed.

The exact `VoxeliaCoreTests.ImageShapeTests` filter again executed 14 tests for
the containment-input leaf. All exact rank-mismatch assertions passed for a
rank-two shape with index ranks zero, one and three. The owning Core build and
strict format lint for the single changed test file passed. No production
source, public API, direct dependant, complete Swift suite, controlled baseline
or Proposed/Draft contract changed.

`swift test --filter VoxeliaCoreTests.ImageSemanticTests` executed exactly the
three tests in the `ImageSemantic` suite. All four malformed fixtures produced
the exact `dataCorrupted` case; the unknown simple and unexpected-root forms
reported the root path, while missing and extra generic keys reported
`["generic"]`. The owning Core build and strict format lint for the single
changed test file passed. No production source, public API, direct dependant,
complete Swift suite, controlled baseline or Proposed/Draft contract changed.

`swift test --filter VoxeliaCoreTests.SemanticVersionTests` executed exactly
the nine tests in the `SemanticVersion` suite. All 18 invalid constructor
fixtures passed their exact negative-component, prerelease or build-metadata
error assertions. The owning Core build and strict format lint for the single
changed test file passed. No production source, public API, direct dependant,
complete Swift suite, controlled baseline or Proposed/Draft contract changed.

The same exact `VoxeliaCoreTests.SemanticVersionTests` filter reran all nine
tests for the Codable-revalidation leaf. The valid five-field round trip passed,
and all three malformed fixtures produced root-context `dataCorrupted` with the
corresponding underlying `SemanticVersionError`. The owning Core build and
strict format lint for the single changed test file passed. No production
source, public API, direct dependant, complete Swift suite, controlled baseline
or Proposed/Draft contract changed.

`swift test --filter '(rejectsRankMismatch|decodingRejectsRankMismatch)'`
executed exactly the two `ImageRegion` rank-mismatch tests. The direct
constructor test passed its exact `RegionError.rankMismatch` assertion, and the
decoding test proved root-context `DecodingError.dataCorrupted` with an empty
coding path and the same underlying `.rankMismatch` cause. The owning
`swift build --target VoxeliaCore`, strict format lint for the single changed
test file and the requirement-index check passed. No production source, public
API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

`swift test --filter '(rejectsInvertedBounds|decodingRejectsInvertedBounds)'`
executed exactly the two `ImageRegion` inverted-bounds tests. The direct
constructor test passed its exact first-inverted-axis
`RegionError.invertedBounds(axis: 1, lower: 5, upper: 4)` assertion, and the
decoding test proved root-context `DecodingError.dataCorrupted` with an empty
coding path and the exact underlying
`.invertedBounds(axis: 1, lower: 4, upper: 3)` payload. The owning
`swift build --target VoxeliaCore`, strict format lint for the single changed
test file and the requirement-index check passed. No production source, public
API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

`swift test --filter
'(rejectsExtentOverflowDuringConstruction|decodingRejectsExtentOverflow)'`
executed exactly the two `ImageRegion` extent-overflow tests. The direct
constructor test passed its exact `RegionError.arithmeticOverflow` assertion
for the `Int.min`/`Int.max` bound pair, and the decoding test proved
root-context `DecodingError.dataCorrupted` with an empty coding path and the
same underlying `.arithmeticOverflow` cause. The owning
`swift build --target VoxeliaCore`, strict format lint for the single changed
test file and the requirement-index check passed. No production source, public
API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

`swift test --filter enumJSONSchema` executed exactly the one
`ComponentDescriptor` JSON-schema test. The canonical scalar, interleaved and
generic encodings passed unchanged, and the extra-key generic payload produced
`DecodingError.dataCorrupted` whose coding path is exactly the single `generic`
element. The owning `swift build --target VoxeliaCore`, strict format lint for
the single changed test file and the requirement-index check passed. No
production source, public API, direct dependant, complete Swift suite,
controlled baseline or Proposed/Draft contract changed.

`swift test --filter decodingIsStrictAndContextual` executed the three
same-named tests in the `CodedConcept`, `ExternalFrameReference` and
`CodecIdentifier` suites. The strengthened `CodedConcept` test proved
root-context `dataCorrupted` for both wrong-keyed object fixtures and
`typeMismatch` for the array fixture; the two unchanged neighbouring tests
passed unchanged. The owning `swift build --target VoxeliaCore`, strict format
lint for the single changed test file and the requirement-index check passed.
No production source, public API, direct dependant, complete Swift suite,
controlled baseline or Proposed/Draft contract changed.

`swift test --filter ContentIdentityTaxonomy` executed all five tests in the
suite. The strengthened invalid-values test proved the exact per-shape
`dataCorrupted`/`valueNotFound`/`typeMismatch` rejections for both
`DigestAlgorithm` and `ContentScope`; the four unchanged vocabulary and
round-trip tests passed unchanged. The owning `swift build --target
VoxeliaCore`, strict format lint for the single changed test file and the
requirement-index check passed. No production source, public API, direct
dependant, complete Swift suite, controlled baseline or Proposed/Draft
contract changed.

`swift test --filter codableRoundTripAndValidation` executed the seven
same-named tests across their suites. The strengthened `DataObjectID` and
`ProvenanceID` tests proved the exact blank-value, wrong-keyed and
wrong-shaped rejections of the shared identifier decoder; the five unchanged
neighbouring tests passed unchanged. The owning
`swift build --target VoxeliaCore`, strict format lint for the two changed
test files and the requirement-index check passed. No production source,
public API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

`swift test --filter ProvenanceKind` executed all four tests in the suite. The
strengthened invalid-values test proved the exact per-shape
`dataCorrupted`/`valueNotFound`/`typeMismatch` rejections including the
wrong-spelling `materialized` token; the three unchanged taxonomy, raw-string
and Sendable tests passed unchanged. The owning
`swift build --target VoxeliaCore`, strict format lint for the single changed
test file and the requirement-index check passed. No production source, public
API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

`swift test --filter MetadataPrivacyClass` executed all four tests in the
suite. The strengthened invalid-values test proved the one fixed empty-path
value-redacted `dataCorrupted` failure for all six fixtures; the unchanged
taxonomy, raw-string and nested value-redaction tests passed unchanged. The
owning `swift build --target VoxeliaCore`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter erasedDecodingIsStrictAndContextual` executed exactly the
one strengthened `MetadataKey` test. It proved root-context `dataCorrupted`
for both wrong-keyed object fixtures, `typeMismatch` for the array fixture and
the unchanged exact blank-field revalidation assertions. The owning
`swift build --target VoxeliaCore`, strict format lint for the single changed
test file and the requirement-index check passed. No production source, public
API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

`swift test --filter decodingIsStrictAndRevalidates` executed the strengthened
`LookupTableDescriptor` test and one unchanged same-named
`AxisAlignedBounds3D` test. The lookup-table test proved root-context
`dataCorrupted` for both wrong-keyed fixtures, `typeMismatch` for the array
fixture, the `outputUnit`/`namespace`-path `dataCorrupted` with underlying
`emptyNamespace` for the blank nested unit and the unchanged exact non-finite
evidence. The owning `swift build --target VoxeliaCore`, strict format lint
for the single changed test file and the requirement-index check passed. No
production source, public API, direct dependant, complete Swift suite,
controlled baseline or Proposed/Draft contract changed.

`swift test --filter decodingRejectsInvalidObjects` executed exactly the one
strengthened `StringIdentifier` test in the owning Spatial module. It proved
the exact blank-`rawValue`, wrong-keyed and plain-string rejections for
`AxisID` and the blank rejection for the permissive conformer. The owning
`swift build --target VoxeliaSpatial`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter MeasurementUnit` executed all eight tests in the owning
Spatial suite. The strengthened Codable test proved the exact wrong-keyed,
array-shape, blank-namespace and non-finite-scale rejections with their field
paths and underlying causes; the seven unchanged identity, validation and
canonicalization tests passed unchanged. The owning
`swift build --target VoxeliaSpatial`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter '(CoordinateHandedness|SpatialTransformKind)'` executed
all six tests in the two owning suites. Both strengthened invalid-values
tests proved the exact per-shape rejections; the four unchanged vocabulary
and raw-string tests passed unchanged. The owning
`swift build --target VoxeliaSpatial`, strict format lint for the two changed
test files and the requirement-index check passed. No production source,
public API, direct dependant, complete Swift suite, controlled baseline or
Proposed/Draft contract changed.

`swift test --filter ExternalFrameReference` executed all six tests in the
owning suite. The strengthened test proved root-context `dataCorrupted` for
both wrong-keyed fixtures, `typeMismatch` for the array fixture and the
unchanged exact blank-field revalidation; the five unchanged neighbouring
tests passed unchanged. The owning `swift build --target VoxeliaSpatial`,
strict format lint for the single changed test file and the requirement-index
check passed. No production source, public API, direct dependant, complete
Swift suite, controlled baseline or Proposed/Draft contract changed.

`swift test --filter SpatialAxisMapping` executed all six tests in the owning
suite. The strengthened Codable test proved the four exact `imageAxes`-path
underlying payloads, the root-context extra-key rejection and the array-shape
`typeMismatch`; the five unchanged construction and validation tests passed
unchanged. The owning `swift build --target VoxeliaSpatial`, strict format
lint for the single changed test file and the requirement-index check passed.
No production source, public API, direct dependant, complete Swift suite,
controlled baseline or Proposed/Draft contract changed.

`swift test --filter SpatialPrimitives` executed all six tests in the owning
suite. The strengthened Codable test proved the exact wrong-keyed,
blank-nested-space and array-shape rejections for both `Point3D` and
`Vector3D` plus the unchanged exact non-finite evidence; the five unchanged
neighbouring tests passed unchanged. The owning
`swift build --target VoxeliaSpatial`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter decodingRevalidatesInvariants` executed exactly the one
strengthened `PlaneAndRay` test. It proved the exact wrong-keyed and
array-shape rejections for both `Plane3D` and `Ray3D` plus the unchanged
exact zero-vector and space-mismatch revalidation. The owning
`swift build --target VoxeliaSpatial`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter decodingIsStrictAndRevalidatesBounds` executed exactly
the one strengthened `AxisAlignedBounds3D` test. It proved the exact
wrong-keyed and array-shape rejections plus the unchanged exact
inverted-bounds and space-mismatch revalidation. The owning
`swift build --target VoxeliaSpatial`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter Matrix4x4Double` executed all six tests in the owning
suite. The strengthened Codable test proved the exact element-count,
extra-key, array-shape and non-finite rejections with their paths and
underlying payloads; the five unchanged construction and multiplication tests
passed unchanged. The owning `swift build --target VoxeliaSpatial`, strict
format lint for the single changed test file and the requirement-index check
passed. No production source, public API, direct dependant, complete Swift
suite, controlled baseline or Proposed/Draft contract changed.

`swift test --filter CodecIdentifierTests` executed all five tests in the
owning Storage suite. The strengthened test proved root-context
`dataCorrupted` for both wrong-keyed fixtures, `typeMismatch` for the array
fixture and the unchanged exact blank-field revalidation; the four unchanged
neighbouring tests passed unchanged. The owning
`swift build --target VoxeliaStorage`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter StorageTaxonomy` executed all five tests in the owning
suite. The strengthened invalid-values test proved the exact per-shape
rejections for both `StorageKind` and `StoragePersistence`; the four
unchanged vocabulary and raw-string tests passed unchanged. The owning
`swift build --target VoxeliaStorage`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter malformedRepresentationsAreRejected` executed exactly
the one strengthened `CompressedRegionAccess` test. It proved the exact
root-path and `custom`-path `dataCorrupted` rejections, the null
`valueNotFound`, the wrong-shape `typeMismatch` rejections and the
`custom`/`namespace`-path `typeMismatch` for the numeric namespace. The
owning `swift build --target VoxeliaStorage`, strict format lint for the
single changed test file and the requirement-index check passed. No
production source, public API, direct dependant, complete Swift suite,
controlled baseline or Proposed/Draft contract changed.

`swift test --filter rejectsUnknownOrMalformedValues` executed exactly the
one strengthened `GeometryTaxonomy` test. It proved the exact per-shape
rejections for all three raw-value enums and the exact root-path,
`custom`-path, null and wrong-shape rejections for
`GeometryAttributeSemantic`. The owning
`swift build --target VoxeliaGeometry`, strict format lint for the single
changed test file and the requirement-index check passed. No production
source, public API, direct dependant, complete Swift suite, controlled
baseline or Proposed/Draft contract changed.

`swift test --filter decodingIsStrictAndRevalidating` executed exactly the
one strengthened `GeometryAttributeDescriptor` test. It proved the exact
root-path guard rejections and the `scalarFormat`- and `components`-prefixed
nested revalidation paths plus the unchanged exact revalidation evidence. The
owning `swift build --target VoxeliaGeometry`, strict format lint for the
single changed test file and the requirement-index check passed. No
production source, public API, direct dependant, complete Swift suite,
controlled baseline or Proposed/Draft contract changed.

`swift test --filter codableRejectsMalformedValues` executed exactly the one
strengthened `ResidencyPolicy` test, proving the exact null `valueNotFound`
and number `typeMismatch` rejections. The owning
`swift build --target VoxeliaMetal`, strict format lint for the single
changed test file and the requirement-index check passed. As a closing
cross-cutting gate for the wire-error campaign, the complete package suite
ran once: all 248 tests in 31 suites passed. No production source, public
API, controlled baseline or Proposed/Draft contract changed.

For the `ADR-0021` acceptance, the complete documentation gate
(`Tools/Scripts/validate-docs.sh`: front matter, ADR register, RFC register
and document text) passed for all 70 Markdown files after the status change,
and the requirement-index check passed. No `v0.1.1` baseline file, product
source or package manifest changed in the acceptance commit.

For controlled correction `CCR-0001`, the same complete documentation gate
passed for all 71 Markdown files including the new record, and the
requirement-index check passed. The release manifest gained exactly the one
new correction record. No `v0.1.1` baseline file, product source or package
edge changed.

`swift test --filter '(AxisSemantic|AxisSampling|AxisDescriptor)'` executed
all seventeen tests in the three new owning Spatial suites: exact taxonomy
and wire round trips, exact typed construction rejections, exact
strict-decode rejections with root, case and field coding paths and exact
underlying `AxisSamplingError`/`AxisDescriptorError`/
`VoxeliaStringIdentifierError` causes, and Sendable/Hashable checks. The
owning `swift build --target VoxeliaSpatial`, the direct-dependant
`swift build --target VoxeliaCore`, strict format lint for the three new
source and three new test files, the static package-graph and
prohibited-import checks (proving Spatial still depends on nothing) and the
requirement-index check passed. No controlled baseline or other Proposed
contract changed.

For the `ADR-0022` acceptance and controlled correction `CCR-0002`, the
complete documentation gate passed for all 72 Markdown files including the
new record, and the requirement-index check passed. The release manifest
gained exactly the one new correction record. No `v0.1.1` baseline file,
product source or package edge changed.

`swift test --filter CoordinateConvention` executed all six tests in the new
owning Spatial suite: exact six-case taxonomy, exact case-sensitive UTF-8
custom identity, the complete built-in handedness matrix, exact built-in
tag and custom-object round trips, exact root/`custom`-path
`dataCorrupted`, `valueNotFound` and `typeMismatch` rejections, and
Sendable/Hashable checks. The owning `swift build --target VoxeliaSpatial`,
the direct-dependant `swift build --target VoxeliaCore`, strict format lint
for the new source and test files, the static package-graph and
prohibited-import checks and the requirement-index check passed. No
controlled baseline or other Proposed contract changed.

For the `ADR-0023` acceptance and controlled correction `CCR-0003`, the
complete documentation gate passed for all 73 Markdown files including the
new record, and the requirement-index check passed. The release manifest
gained exactly the one new correction record. No `v0.1.1` baseline file,
product source or package edge changed.

`swift test --filter ValueTransform` executed all seven tests in the new
owning Core suite: finite extreme, subnormal, zero-scale and every
non-finite linear position; signed-zero canonicalization with one sorted-key
encoded representation; nonempty/ordered/nested/one-element/1,024-element
compositions and empty rejection; exact documented tags and round trips;
exact root/`linear`/`composed`-path `dataCorrupted`, `valueNotFound` and
`typeMismatch` rejections; decode-time revalidation with underlying
`DataModelError.invalidValueTransform`; and Sendable/Hashable checks. The
owning `swift build --target VoxeliaCore`, the direct-dependant
`swift build --target VoxeliaImaging`, strict format lint for the new source
and test files, the static package-graph and prohibited-import checks and
the requirement-index check passed. No controlled baseline or other
Proposed contract changed.

For the `ADR-0024` reconciliation, the ADR's prescribed focused checks
passed after the atomic migration: the complete documentation gate
(including the file-backed ADR-register checker proving identifier,
filename and heading consistency with no duplicate identifiers), the
required-file check and Apple-platform-policy check against the new
`ADR-0025` path, the manifest-path check, release-integrity regeneration
and verification, and the requirement-index check. A repository-wide search
confirmed no active link or policy script references the former platform
path; remaining `ADR-0001` texts are the immutable `v0.1.1` baselines,
historical release records and this ledger's preserved historical entries.

`swift test --filter RayAxisAlignedBoundsIntersection3DTests` executed all
seventeen tests in the new owning Spatial suite: analytic positive- and
negative-axis parameters, inverse parameter rescaling with invariant dyadic
points, behind-origin and separated-axis misses, inside/face/corner origins
with `[0, 0]` outward evidence, corner-tangency and degenerate point/line/
plane singleton and coincident intervals, per-axis parallel
inside/on/outside classification, signed-zero-parallel and
subnormal-not-parallel evidence, exact coordinate-space mismatch, the
representable half-scaling overflow fallback, selected entry-overflow and
exit-underflow typed failures, unselected-token harmlessness,
parallel-outside and empty-interval precedence, earliest-axis tie
provenance and a fifty-five-fixture bit-exact cross-check against an
independently structured `binary64-v1` evaluator. The owning
`swift build --target VoxeliaSpatial`, direct-consumer
`swift build --target VoxeliaCore` and `swift build --target Voxelia`,
strict format lint for the three changed Swift files, the documentation
gate including the new algorithm specification, the static package-graph
and prohibited-import checks and the requirement-index check passed.

`swift test --filter FrameAnchorIndex` executed all seven tests in the new
owning Spatial suite: rank-one/all-zero/multi-rank/1,024-rank and
`Int.max - 1` construction; exact axis-ordered rejection of empty,
negative, `Int.max`, `Int.min` and mixed-invalid components at first,
middle and last positions; generic slice and repeat-element
materialisation with exact order identity and Sendable/hashing checks; the
exact one-key wire without a rank field; strict root-key, null,
wrong-shape and multiple-extra-field rejections; exact element-type
rejections for string, Boolean, null, fractional and out-of-`Int` values;
and decode-time revalidation with the `components` path and typed
underlying causes. The owning `swift build --target VoxeliaSpatial`, the
direct-dependant `swift build --target VoxeliaCore`, strict format lint
for the two new Swift files, the documentation gate including `CCR-0004`,
the static package-graph check proving Spatial still has no target
dependency, the prohibited-import check and the requirement-index check
passed.

`swift test --filter CanonicalInstant` executed all eight tests in the new
owning Core suite: the exact canonical profile including year boundaries
and all nine fractional widths; a 400-year proleptic Gregorian cycle
oracle over 4,800 months plus the 1900/2000/2100 century fixtures; exact
typed out-of-range, syntax, length and fraction rejections including
offsets, lowercase separators, week dates, RFC 9557 suffixes and Unicode
digits; the deterministic error precedence over multiply defective
fixtures; a deterministic ~2,600-case ASCII pseudo-fuzz through the
maximum boundary and oversized prefixes proving totality without text
leakage; exact single-string round trips; and strict decode rejections
plus revalidation with payload-free underlying causes. The owning
`swift build --target VoxeliaCore`, strict format lint for the two new
Swift files, the documentation gate including `CCR-0005`, the static
package-graph and prohibited-import checks and the requirement-index
check passed.

`swift test --filter MetadataFloatingPoint` executed all six tests in the
new owning Core suite: exact bit-pattern preservation for representative
extremes, subnormals and 512 deterministically generated finite patterns;
exact `.nonFiniteValue` rejection of quiet and signalling NaNs across
signs and payloads and both infinities; signed-zero canonicalisation with
one equality, hashing, set and sorted-key encoded representation;
reflexive equality with coherent set behaviour and Sendable evidence;
exact scalar round trips plus integer/fraction/exponent/negative-zero
alias decoding without canonical-spelling claims; and strict wrong-shape
rejections plus non-conforming-float revalidation with the nested coding
path, typed underlying cause and no wrapper-originated value disclosure.
The owning `swift build --target VoxeliaCore`, strict format lint for the
two new Swift files, the documentation gate including `CCR-0006`, the
static package-graph and prohibited-import checks and the
requirement-index check passed.

`swift test --filter MetadataBinary` executed all nine tests in the new
owning Core suite: the adversarial `Data(bytesNoCopy:)` backing mutation
proving snapshot construction and preserved set membership; ordinary
`Data` and copy-on-write source independence; exact count-and-order
identity over empty, all-256-value, reordered and length-differing bytes;
the complete RFC 4648 vector set plus `+` and `/` exercises with exact
encoded-object evidence; bit-exact generated round trips across every
length zero through ninety-six with preflighted encoded counts; exact
rejection of missing/excess/misplaced padding, non-zero unused bits,
whitespace, line breaks, non-ASCII, Base64URL and embedded-padding
aliases with value-redacted root diagnostics; wrong-shape rejections and
independence from both Foundation data-decoding strategies; overflow-safe
near-`Int.max` count preflight without allocation; and a deterministic
~2,400-case codec fuzz proving totality and the canonical
re-encoding property for every accepted string. The owning
`swift build --target VoxeliaCore`, strict format lint for the two new
Swift files, the documentation gate including `CCR-0007`, the static
package-graph and prohibited-import checks and the requirement-index
check passed.

`swift test --filter MetadataValueTests` executed all twelve tests in the
new owning Core suite: exact case-tag and NFC/NFD-distinct string
identity; depth 64 acceptance with iterative maximum-depth equality,
hashing and destruction plus depth-65 typed rejection; the exact
structural-element limit and one-over rejection over a 1,048,575-leaf
array; the copy-on-write amplification oracle accepting 1,048,575 and
rejecting 2,097,151 logical occurrences from linear physical storage; the
exact 64 MiB embedded-payload boundary with the oversized standalone leaf
still round-tripping; checked-counter overflow rejection near
`UInt64.max` without allocation; canonical object ordering with prefix
and canonically equivalent distinct keys, caller-order-independent
equality/hash/encoding and duplicate rejection for equal and unequal
values; source-mutation snapshot evidence; every tag round trip including
both `Int64` extrema and `UInt64.max` with the exact member wire;
malformed-tag, null and wrong-shape rejections; decode-side depth 64
acceptance, depth-65 and adversarial depth-120 typed rejection through
the exact task-local guard, the beyond-parser-tolerance
decoder-originated failure documented as outside the wrapper's redaction
guarantee, and duplicate-key rejection beneath a sentinel dictionary key
with no sentinel in the context; and incremental element-budget rejection
of an oversized flat document. The owning
`swift build --target VoxeliaCore`, the direct-dependant
`swift build --target VoxeliaImaging`, strict format lint for the two new
Swift files, the documentation gate including `CCR-0008`, the static
package-graph and prohibited-import checks and the requirement-index
check passed. Boundary evidence ran on local Apple Silicon; the
lowest-resource supported-device matrix remains an explicit open gap.

`swift test --filter MetadataEntryTests` executed all seven tests in the
new owning Core suite: explicit construction under every class with the
compile-level proof that no default, optional or two-argument initializer
exists; class-sensitive equality, hashing and set behaviour for equal
key/value pairs under all five classes with ADR-0031 semantic value
identity participating unchanged; exact three-field wire round trips for
all five classes with a byte-exact sorted-keys fixture; `hostDefined`
round-tripping without generic resolution; whole-entry scope over a
nested object/array/code value with exactly one classification field on
the wire; rejection of missing, null, distinct-extra, unknown-token,
wrong-shaped and non-object entry documents; and value-redaction
evidence that a rejected class token beneath a sentinel caller key names
only `privacyClass` with no underlying error, a duplicate-member value
failure names only `value` while retaining the audited typed
`duplicateObjectKey` cause, and a blank key field names only `key` with
the audited typed `emptyNamespace` cause, none leaking sentinel or
member text. The owning `swift build --target VoxeliaCore`, strict
format lint for the two new Swift files, the documentation gate
including `CCR-0009`, and the requirement-index check passed.

`swift test --filter MetadataCollectionTests` executed all ten tests in
the new owning Core suite: exact input-order preservation with
order-sensitive equality, hashing and set behaviour plus valid empty
collections; ordinary exact-key duplicate rejection covering equal
whole entries, differently valued and classified duplicates, and
NFC/NFD-distinct plus byte-prefix keys as non-duplicates; configured
admission retaining every allow-listed occurrence and privacy
declaration in order (including unresolved `hostDefined`) while
unlisted keys stay unique-only; policy ceilings charging every supplied
occurrence before deduplication at the 2^20+1 count and 65-mebibyte
byte boundaries with the 63-occurrence acceptance; exact collection
ceilings at 2^20 entries, 2^20 aggregate structural elements from
262,144 shared four-element values, and 64 MiB aggregate payload from
eight 8 MiB strings plus key bytes, each with one-over typed rejection;
the byte-exact unique-only one-field wire fixture and empty round trip;
ordinary encoding of a repeat-bearing value throwing the typed
policy-required failure with configured round trips, wrong/narrower
snapshot revalidation failures, ordinary fail-closed decoding of
configured bytes and proof the policy is absent from the wire;
malformed field-set rejection with fixed empty outer and fixed
`entries` paths; threaded-budget evidence that a second entry's
recursive value is rejected inside value decoding once a prior entry
consumes the aggregate element budget, while a fitting leaf still
decodes; and structure redaction with no caller key, metadata key,
index or count in decode contexts or construction errors. The
regression-critical `MetadataValueTests` (twelve) and
`MetadataEntryTests` (seven) suites re-passed after the decoder gained
scoped aggregate-ceiling task-locals. The owning
`swift build --target VoxeliaCore`, strict format lint for the three
touched Swift files, the documentation gate including `CCR-0010`, the
static package-graph, prohibited-import and requirement-index checks
passed. Boundary evidence ran on local Apple Silicon; the
lowest-resource supported-device matrix remains an explicit open gap.

`swift test --filter MetadataTypedReadTests` executed all six tests in
the new owning Core suite: exact extraction for all eleven table rows
under both read families including `Int64.min`, `UInt64.max`, validated
floating/binary/instant wrappers, unit, code and recursive containers,
with the classified result retaining typed key, exact payload and the
occurrence's class; count-first single-read cardinality proving an
absent key throws `missingValue`, a mixed-case duplicate whose single
matching occurrence is never selected throws `multipleValues`, and one
mismatched match throws `typeMismatch`; exact UTF-8 lookup where the
NFD spelling and a byte prefix of a stored NFC key both miss while the
byte-identical request matches; ordered atomic plural reads returning
every occurrence with `technical`/`hostDefined`/`sensitive` classes
preserved, empty success for zero matches and a late mismatch after a
valid prefix failing atomically; no-bridging evidence that instant text
never satisfies a string read and numeric cases never widen or cross;
and payload-free error rendering with no key, value, requested type or
match structure under patient-sentinel names. Compile-closure of the
overload family rests on the checked-in `ADR-0034` probe evidence for
compile-negative fixtures. The owning `swift build --target
VoxeliaCore`, strict format lint for the two new Swift files, the
documentation gate including `CCR-0011`, the static package-graph,
prohibited-import and requirement-index checks passed.

`swift test --filter CanonicalMetadataJSONTests` executed all eleven
tests in the new owning Core suite: the byte-exact empty envelope in
both directions; a golden ten-entry document covering every value case
with exact token spot checks (decimal-string integer extrema, canonical
`0.001`, the escaped vertical-tab control, `Zg==`, the six-member unit and
four-member code objects with explicit nulls), semantic decode equality,
byte-identical re-emission and NFC/NFD byte-distinct survival; RFC 8785
number vectors including both zeros, `5e-324`,
`1.7976931348623157e+308`, the `1e+21`/`100000000000000000000`
threshold pair, `0.000001` versus `1e-7` and the shortest-digit
`333333333.3333332`, plus 512 deterministic random-bit patterns
re-parsing identically within the analytic 25-byte maximum; a
thirty-five-document malformed corpus (BOM, whitespace, trailing data,
reordered/duplicate/escape-alias members, unknown tags and privacy
tokens, numeric-integer payloads, every integer-string alias and
one-over range, floating aliases `-0`/`1.0`/`1e0`, noncanonical escapes
including uppercase hex and unpaired surrogates, Base64 aliases and pad
bits, unsorted/duplicate object members, unpermitted repeats, blank
identity fields, raw control/overlong/surrogate/truncated UTF-8) each
rejected as `invalidDocument`, with version 1.1/2.0 short-circuiting as
`unsupportedSchemaVersion` and the U+FFFF noncharacter deliberately
preserved; fail-closed multiplicity binding (missing, unexpected and
mismatched context, policy absent from wire, context preflight
rejecting before the first input byte); symmetric emission preflight
with the inclusive exact output ceiling; exact raw-document,
decoded-string, raw-depth and direct-member charges; the generated
64-level chain hitting raw depth exactly 198 with 197 rejected and a
65-level chain rejected by the semantic guard; the frozen whitespace
oracle accepting the documented broadened edge strings while every
enumerated scalar and their concatenation stay blank across Core and
Spatial constructors; bounded ASCII schema references at every grammar
and 63/64/255/256-byte boundary; and payload-free failures under
patient sentinels. The five affected regression suites (metadata key,
coded concept, measurement unit, value, collection — 42 tests) re-passed
after the whitespace-oracle replacement. The owning Core and Spatial
builds, strict format lint for the nine touched Swift files, the
documentation gate including `CCR-0012`, the static package-graph,
prohibited-import and requirement-index checks passed. Recorded open
gaps: lowest-resource device cancellation-latency campaign,
fuzz/mutation corpora, external Ryu/V8 differential oracles, the
universal raw-ceiling derivation and the `VOX-ERR-001`
allocation-failure disposition.

`swift test --filter ContentIDTests` executed all six tests in the new
owning Core suite: the golden fixtures pinning the frame (the emitter's
148-byte empty envelope byte-compared, its raw SHA-256 matching the
registered `a27e…ee50` negative control, the framed identity matching
`8dde…7432`, the exact 109-byte header with its length suffix, and the
NIST FIPS 180-4 `abc` known-answer vector); deterministic domain-bound
identity with payload-mutation divergence, timing-safe match/mismatch
verification including first/middle/last digest-byte flips and
owned-byte snapshots; the byte-exact sorted-keys four-field wire round
trip; malformed-record rejection distinguishing `unsupportedAlgorithm`
(`sha512`/`blake3`/`custom`), `invalidRecord` (unknown tokens, digest
length/case/prefix aliases, missing and extra fields) and
`unsupportedProjection` (wrong scope, identifier or version);
projection-identifier byte-limit-before-grammar precedence at the
63/64-label and 255/256-total boundaries with grammar rejections; and
payload-free failures under patient sentinels. The owning
`swift build --target VoxeliaCore`, strict format lint for the two new
Swift files, the documentation gate including `RFC-0002` and `CCR-0013`,
the static package-graph, prohibited-import and requirement-index checks
passed.

The `ADR-0037` increment is documentation-only, so its verification
surface is the documentation gate: the front-matter, ADR-register,
RFC-governance and documentation-text checks passed over the accepted
`ADR-0037`, `CCR-0014` and the updated register; the requirement-index
check passed; and release-integrity regeneration plus the read-only
check passed. No Swift source changed, so no new package tests were
added; the full suite re-ran green as the pre-push gate. The accepted
source gate's prerequisites (bounded identifier profiles, `DataObjectID`
persistent identity and byte ceiling, `DataIdentityReference` lifecycle
and wire, registered parameter/derivation projections, `objectID`
enrichment lifecycle and the execution/cache contracts) are recorded as
the open decisions blocking any identity value source, alongside the
still-open CDMS section 59 integrity-state correction.

The `ADR-0038` increment is likewise documentation-only, so its
verification surface is the documentation gate: the front-matter,
ADR-register, RFC-governance and documentation-text checks passed over
the accepted `ADR-0038`, `CCR-0015` and the updated register; the
requirement-index check passed; and release-integrity regeneration plus
the read-only check passed. No Swift source changed; the full suite
re-ran green as the pre-push gate. The eleven-item provenance source
gate's prerequisites are recorded as open decisions alongside the
`ADR-0037` identity gate and the CDMS section 59 correction.

The `RFC-0001` review increment is likewise documentation-only, so its
verification surface is the documentation gate: the front-matter,
ADR-register, RFC-governance and documentation-text checks passed over
the three newly accepted storage-composition ADRs, `CCR-0016` and the
updated register; the requirement-index check passed; and
release-integrity regeneration plus the read-only check passed. No Swift
source changed; the full suite re-ran green as the pre-push gate. The
RFC's fourteen unresolved questions and its approval-order steps 4
through 11 are recorded as the open gates blocking storage source.

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
- The `ADR-0001` identifier collision is resolved: accepted `ADR-0024`
  (2026-08-04) performed the atomic reconciliation, re-identifying the
  platform record as `ADR-0025` with live links and the required-file and
  Apple-platform-policy scripts migrated in the same change. An unqualified
  current `ADR-0001` reference now means the MTA's canonical-data-model
  decision; historical v0.1.1 release records retain the former identifier.
- The ADR checker intentionally validates file-backed records only. It does
  not compare them with MTA Appendix A and does not treat body mentions as
  record assignments; after the reconciliation every file-backed identifier
  is repository-unique and outside the MTA `ADR-0001`-`ADR-0020` reserve.
- The checked-in template and all seventeen file-backed ADRs now contain the RPSS
  section 9.2 areas, and the ADR checker enforces their presence, uniqueness and
  meaningful bodies. It intentionally does not infer decision quality, status
  transitions, module validity or supersession semantics from prose.
- `ADR-0021` is Accepted (2026-08-04). The axis-model public API is unblocked
  for `VoxeliaSpatial` implementation once the controlled CDMS/FVSP
  correction is recorded; binding validation still waits on the complete
  `ImageDescriptor`, whose other prerequisites remain blocked.
- `ADR-0022` is Accepted (2026-08-04), resolving the convention-shape
  conflict. `CoordinateSpaceDescriptor` remains blocked even so, because its
  exact five fields do not classify physical versus logical
  Cartesian/custom/display spaces and its unit policy is unapproved. The
  enum must not imply a unit, transform, display-axis policy or external
  frame identity.
- `ADR-0023` is Accepted (2026-08-04), resolving the transform-declaration
  conflict. Piecewise-linear transforms remain deferred and undefined, and
  lookup declarations still do not establish interpolation, missing-entry or
  extrapolation behavior.
- The exact in-memory `ImageDescriptor` declaration remains transitively
  blocked despite accepted `ADR-0021` and even if proposed `ADR-0022`/
  `ADR-0023` were accepted: coordinate-space descriptor policy, affine shape
  and construction tolerance, rectilinear binding and frame-set binding are
  still incomplete. Full M1 descriptor acceptance is additionally blocked by
  canonical JSON.
- Spatial-owned `FrameGeometry` is specified with Core-owned `ImageIndex`, but
  the approved dependency direction is `Core -> Spatial`; implementing that
  shape in Spatial would create a prohibited reverse edge or cycle.
- `ADR-0027` is Accepted (2026-08-04) and its authorised scope is executed:
  the standalone `FrameAnchorIndex` leaf and controlled CDMS correction.
  `FrameGeometry`, frame-set ordering, sparse/enhanced coverage,
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

The autonomous continuation of 2026-08-04 has executed `ADR-0043`
through `ADR-0072` and algorithm specifications `VOXELIA-ALG-0002`
through `VOXELIA-ALG-0006`, all Accepted and implemented: the spatial
and image descriptors, the persistent-identifier and integrity claim
boundaries, the M2 execution coordinators with single-flight
deduplication, the four content projections beyond the metadata record
(sample bytes, operation parameters, provenance record, derivation
record) with their canonical `VCPJ-1`/`VCDJ-1` emitters and strict
`VCPJ-1` ingress, the content-tier result cache, the complete
claim-bearing identity chain (`SourceIdentity`,
`DataIdentityReference` with all four cases, `DerivationIdentity`,
`DerivationRecordID`, `DataIdentity`), the complete provenance chain
(claims, warnings, record, complete and compact graph admission with
verified external references), the `ImageData` aggregate, the result
publication coordinator, and two operations — exact geometry-preserving
region extraction (1.1.0) and window-level (1.4.0) with the full
transform-composition set — every increment pushed with independently
computed golden fixtures.

The remaining recorded gates each require either a new owner
authorization, external evidence that must not be fabricated, or both:
strict `VCDJ-1` ingress (the next natural codec increment, following
the accepted `ADR-0061` pattern); slicing models for irregular,
categorical and externally defined sampling; durable provenance and
image persistence (gated on format, atomicity, corruption and
output-integrity evidence per `ADR-0037`); signed external manifests
(gated on a signature contract); retention and deletion governance for
the append-only publication registry; lazy identity enrichment and the
`objectID` lifecycle; the `ADR-0035` evidence campaigns (device
latency, fuzz corpora, external differential oracles, universal raw
ceiling, the `VOX-ERR-001` allocation disposition); the visionOS
platform component; and the M4+ milestone scopes. Do not fabricate
external evidence or begin gated persistence work autonomously.

## Test policy for the next action

- A governance decision has no test surface. When the next accepted decision
  authorises work, derive its policy from the smallest owning target as in
  prior increments, plus documentation, requirement-index and
  release-integrity checks and the package-graph checks whenever ownership
  or module boundaries are affected. Do not rerun the complete scaffold
  suite unless a cross-cutting change affects its gate or a release
  candidate is being accepted.
- Do not rerun the complete scaffold suite unless a later cross-cutting change
  affects its gate or a release candidate is being accepted.
- Keep unavailable SDKs, signing contexts, repository settings and human
  approvals recorded as explicit evidence gaps rather than treating them as
  passing.
