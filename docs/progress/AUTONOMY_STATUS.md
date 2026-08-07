# Voxelia autonomous progress ledger

Last updated: 2026-08-07 (Asia/Kolkata)

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
- Supporting safety status: the post-M3 continuation audit on 2026-08-05 found
  ten ungoverned `@unchecked Sendable` conformances introduced by the Metal,
  telemetry and brick-cache increments. The first recovery increment replaced
  all three test-only lock wrappers with checked `Synchronization.Mutex`
  storage, and the second moved `MetalPipelineCache`'s dictionaries, counters
  and compilation critical section behind one checked mutex state. The third
  moved `MetalExecutionContext`'s device and command queue behind one checked
  synchronous borrowing boundary, and the fourth moved all three kernel
  wrappers' pipeline sets behind checked encoder-configuration borrows. The
  fifth removed `MetalResidencyManager`'s obsolete exception after its sole
  stored context became checked, and the sixth proved `ExactSliceRenderer` is
  immutable checked composition. The raw fail-closed escape-hatch scan now
  passes with the exact three-expression governed Metal boundary and no
  unapproved finding. Checked bounded
  `Data` updates and a fixed-work Swift digest comparator have now removed all
  seven `ContentID.swift` diagnostics while preserving every registered
  identity golden. The semantic `--compile` gate advanced to its next failure:
  that Foundation directory-kind query was then replaced with checked URL
  resource values. Core and Storage now compile through the gate, which stops
  later on a warning-as-error for a redundant `await` in
  `BrickRequestBroker.swift`; that actor-isolated call is now corrected too.
  The duplicate internal `pixelY` spelling in `OrthographicRayGenerator` is
  now removed without changing its public selector. The three shader-source
  digest conversions use one checked lowercase encoder. The installed-SDK
  audit found a checked MetalKit upload route but no checked raw readback API.
  The project owner approved Option A and an independent subagent reviewer;
  accepted `ADR-0186` confines the exception to one fingerprinted internal
  Metal byte-transfer file with three marked expressions. The boundary,
  serializer, exact fail-closed scanner fingerprint, all three kernel
  migrations and the residency round trip are implemented; the independent
  reviewer approved the boundary/scanner and final migration diffs after all
  coherency, lifetime, governance, platform, count and error-classification
  corrections. The six test-only C-format initializers are now replaced by
  checked deterministic Swift hexadecimal and decimal encoders with their
  fixture bytes preserved. The final pointer-backed `MetadataBinaryTests`
  adversary is now a checked caller-owned reference collection that preserves
  the snapshot and hash-stability oracle without another exception. The
  complete semantic gate passes every repository package in debug and release;
  the strict safety recovery and `ADR-0186` implementation are complete.
  Independently, all four
  pointer-backed sixteen-bit fixture serializers predicted in the Metal test
  target now use exact checked little-endian shifts, with their affected device
  suites green. Strict compilation of the Metal test target now passes. The
  last recorded full platform destination builds remain historical evidence
  only; visionOS 26.5 is still unavailable.
- Independently unblocked later-milestone declaration: the exact six-case
  `ResidencyPolicy` vocabulary is implemented in its owning `VoxeliaMetal`
  module without attaching allocation or capability behaviour.
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
  `piecewiseLinear` case and all lookup-execution behaviour. `CCR-0003`
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
  independent equality and hashing, signed-zero normalisation, and an exact
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
  Authorised THREE-CLUSTER CONTINUATION IS COMPLETE: eleven accepted
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

=== ARC CLOSED, AND WHAT THE REAL DATA CHANGED (2026-08-06) ===

The DICOM ingest arc is **closed**: `ADR-0226` through `ADR-0233`, five algorithm
specifications, five oracles, 911 tests in 179 suites. The owner released the
codec gate, granted MIT for `JLSwift` and `CompressionFamily`, and supplied real
clinical CT data mid-increment.

**`VOX-VS1-001`'s Demonstration half is discharged for the geometry path.** A
899-slice thorax series: 899 of 899 files parsed and adapted, one series, verdict
`representable`, no findings, spacing spread exactly `0x0p+0`.

**Two accepted records were corrected by measurement, not by opinion.**
`ADR-0229` claimed `exact` tolerance "will reject real series"; it accepts about
half of the corpus outright, including every large primary axial reconstruction.
And it claimed the source's stated decimal precision was unavailable; `ADR-0233`
found `DICOMDecimalString.originalString` preserves it. `ADR-0234` assesses that
source and finds it **necessary but not sufficient** — it admits the
floating-point-noise group with no invented constant, and still rejects
physically-regular reformats that state more precision than their geometry has.

Three gates remain, all owner decisions:

1. **The geometry tolerance rule**, now well characterised by `ADR-0234`: one
   principled source, one case it fixes, one case it does not, one parser hazard
   (E-notation defeats naive decimal counting). Also needs a decision on whether
   reformats must be supported at all.
2. **Two licence files** — `Raster-Lab/JLSwift` and
   `Raster-Lab/CompressionFamily`. The grant is recorded; the files let third
   parties verify it. Release prerequisite.
3. **Upstream DocC errors** in `JXLSwift` and `DICOMKit`, both Raster-Lab
   repositories. Fixing them would let `build-docc.sh` return to a global
   `--warnings-as-errors` instead of a Voxelia-scoped filter.

The scaffold gate remains the one red pipeline: re-tested this session on a
byte-identical toolchain, still signal 11 at the release strict-memory-safety
stage.

**The first vertical slice now runs end to end on real data.** `ADR-0235` added
`CTVolumeByteBuffer` and `DICOMFrameTransfer`, and a 899-slice thorax series
assembled into a **512x512x899 uint16 volume, 449 MiB, with 899 of 899 slices
byte-exact** against DICOMKit's own frame bytes — verified independently of the
transfer.

`ADR-0235` corrects `ADR-0230` decision 10: it chose direct-write into a
caller-provided destination, and **DICOMKit cannot serve that model** — its pixel
surface returns an owned `Data`. The achievable model is one copy per frame, which
is the volume's materialisation rather than an avoidable intermediate. That
decision was made in increment (d), before increment (e) read DICOMKit's API: the
same unstated-assumption failure this project keeps catching, and this time it was
ours.

Two measurements worth keeping. The real samples are **unsigned** (`uint16`, Pixel
Representation 0) while every hand-built fixture defaults to `int16` — the adapter
reads the attribute so it was right, but the fixtures' assumption was not
representative. And the safe element-wise copy runs at **~120 MiB/s**, one to two
orders of magnitude slower than a bulk copy; that is the measured price of
avoiding pointer APIs, recorded rather than dismissed.

**Scope note from the owner, 2026-08-06:** the dependency libraries are already
used and tested. Do **not** divert into testing or bug-hunting them; the target is
completing Voxelia. Upstream defects already found (DocC errors in `JXLSwift` and
`DICOMKit`) stay recorded as owner options and are not to be pursued.

**Next unblocked work, in order of value:**

1. ~~Value interpretation under `VOX-DCM-006`~~ — **DONE** by accepted `ADR-0236`
   and `VOXELIA-ALG-0051`, discharging all four deferrals (`ADR-0227` decision 5,
   `ADR-0229` decision 10, `ADR-0232`, `ADR-0235` decision 2). Fourteen oracle
   fixtures, 20 tests. **The real slice reads as clinically plausible Hounsfield
   units**: 45.3% air, 16.3% lung and fat, 15.1% soft tissue, 1.5% bone.

   Two findings from that run. The intercept is **`-8192`**, not the textbook
   `-1024` every fixture uses — the second time real data has contradicted a
   fixture assumption, after the unsigned-samples finding. **Fixtures written from
   domain convention encode the convention, not the data.** And 18.4% of the slice
   sits at the `-8192` floor: the corners outside the circular reconstruction
   field, which the scanner declares **no** Pixel Padding Value for, so
   `VOX-DCM-008`'s exclusion mechanism has nothing to act on. Recorded as a limit
   of the data, not worked around; excluding it would need a value threshold, and
   so an owner decision of the same shape as the geometry tolerance.

   **`ADR-0237` then corrected a governance error in `ADR-0236`.** The rescale
   boundary **was already frozen**: `VOXELIA-ALG-0003`, accepted since M1, states
   its purpose includes "rescale", freezes `r = (x * scale) + offset`, and carries
   a fixture described as "the CT rescale". `VOXELIA-ALG-0051` restated the same
   computation with the operands swapped, so the register briefly held two
   specifications of one boundary.

   **No wrong result was ever produced**, and that was verified rather than
   asserted: IEEE-754 multiplication is commutative, and all thirteen fixture
   triples plus **two million random cases** — subnormals, signed zeros, `1e±300`,
   zero and negative scale — gave **zero bit-pattern differences**. The
   implementation now reads in `VOXELIA-ALG-0003`'s order and all 20 tests pass
   unchanged.

   **Why it was missed is the transferable part:** the search was for an existing
   *evaluator* in the source, not for the *boundary* in the algorithm register.
   **Rule: before freezing a numeric boundary, search the algorithm register for
   that boundary, not the source for its callers.** A boundary can be frozen with
   no evaluator yet, and an evaluator can cite a specification by number that a
   code search never surfaces.

   A second finding came out of the same trace: **nothing in the project masks by
   `ScalarFormat.validBitCount`** — `LabelledSurfaceSourceAdapter` and
   `TriangleMeshVertexNormalGeneration` *refuse* a narrowed count and every other
   operation builds formats with `nil`. So `VOXELIA-ALG-0051`'s masking and
   sign-extension stages are the only handling of a narrowed CT format anywhere,
   and a published volume declaring `validBitCount = 12` would be **refused** by
   some existing operations. The real corpus does not hit it (Bits Stored equals
   the container width) but a twelve-bit CT would.

   **`ADR-0238` opens the bridge arc.** The requirement list makes the case. The first
   vertical slice has **twenty** requirements; `VOX-VS1-001` to `008` are now
   covered, and `009` to `019` — axial/coronal/sagittal reconstruction, Metal
   rendering, interpolation, window-level interaction, linked crosshairs, pixel
   inspection, distance measurement, off-screen output, cancellation, provenance —
   are capabilities **Voxelia already has** from earlier milestones. They operate
   on a **published `ImageData`** reached through `PublicationCoordinator`.

   The ingested CT is a `CTVolumeByteBuffer` plus an `AffineGridGeometry`, and
   nothing connects the two. That bridge is the whole remaining distance, and it
   is more tractable than it looks: `ImageDescriptor` already carries
   `spatialGeometry: SpatialGeometry?` — exactly what `ADR-0230` builds — and
   `valueTransform: ValueTransform?` — exactly `ValueTransform.linear(scale:offset:)`,
   the rescale. The pieces were designed to fit; they have never been joined.

   `ADR-0238` decomposes it into six increments — (a) descriptor, (b) storage
   binding, (c) the narrowed-bit-count decision, (d) provenance, (e) identity and
   publication, (f) end-to-end slice extraction on the real series — and records
   three constraints verified by reading the accepted types rather than assumed.

   **(c) is the arc's hardest question and a genuine correctness trap.** When Bits
   Stored is narrower than Bits Allocated, declaring `validBitCount: 12` is
   accurate and is **refused** by accepted operations, while declaring `nil` is
   accepted and is **wrong for signed data** — a raw `0x0FFF` reads as `4095` where
   the sample means `-1`. Both available declarations are unusable or incorrect, so
   the answer is probably a third thing: normalising samples during transfer.
   **The owner's corpus does not expose this** — its Bits Stored equals the
   container width — so the trap is dormant and would pass every test available
   today. `ADR-0238` decision 5 requires (c) settled before (e), so a wrong
   descriptor never enters a pipeline that trusts it.

   Two more verified constraints. **There is no clock**: `CanonicalInstant` offers
   only `init(utcString:)`, so the ingest instant must be a caller parameter — which
   is better anyway, since a self-stamping ingest would make every volume's identity
   depend on the wall clock. And **byte order works by platform coincidence**:
   `ContiguousImageStorage` admits with `byteOrder: .native`, DICOM is little-endian,
   and Voxelia is Apple-Silicon-only. Recorded so a future big-endian target finds a
   stated assumption instead of silent corruption.

   The encouraging half: `ImageDescriptor` already carries `spatialGeometry`
   (`.affine(AffineGridGeometry)`, what `ADR-0230` builds) and `valueTransform`
   (`.linear(scale:offset:)`, the rescale), and `ContiguousImageStorage(binding:bytes:)`
   already takes `[UInt8]`. **The slots were designed for this and have never been
   filled** — the bridge is mostly assembly, not invention.

   **`ADR-0239` settled (c), the trap — and corrected `ADR-0238`'s own increment
   order.** That record listed the descriptor as (a) and the bit-count decision as
   (c), but the descriptor *declares* the scalar format, so the dependency runs the
   other way. The correction is recorded rather than silently rearranged.

   The answer is `ADR-0238`'s third option: **normalise samples before transfer**,
   re-encoding each stored value as a full-width container so `validBitCount: nil`
   becomes a *truthful* declaration. It is a re-encoding, not an interpretation — no
   rescale, no padding, no real value — so `ADR-0235` decision 2 holds and neither
   `CTVolumeByteBuffer` nor `DICOMFrameTransfer` changed.

   **The property is proved exhaustively, not sampled.** Reading a normalised
   container at full width yields the same stored value as reading the original at
   its narrower width — checked over every 8-bit and 16-bit container value, every
   stored-bit width, both signedness choices: **2,101,248 cases, zero failures**, in
   Python as recorded evidence and again in Swift as a test that runs in 2.9s. A
   fixture table would have been strictly weaker, and **where a space is small
   enough to enumerate, this project should enumerate it.**

   Normalisation is the **identity at full width**, verified for every value, so the
   owner's entire measured corpus pays nothing — the implementation detects the
   identity case and skips the pass. No new algorithm specification was issued:
   normalisation is defined by its round-trip relationship to `VOXELIA-ALG-0051`
   stage 2, and freezing it separately would repeat the duplicate-specification
   mistake `ADR-0237` had just corrected.

   **`ADR-0240` performed the descriptor increment.** `CTVolumeDescriptorBuilder`
   fills the slots that already existed: `spatialGeometry` takes the affine
   `ADR-0230` builds, `valueTransform` takes the rescale as
   `ValueTransform.linear`, and the published scalar format drops the
   meaningful-bit narrowing — truthful only because `ADR-0239` normalises. 15
   tests; 970 in 184 suites overall.

   **Image axis 0 is the column index, and that is forced rather than chosen.**
   `VOXELIA-ALG-0050` made the column index fastest-varying and
   `ContiguousImageStorage` reads "contiguous axis-zero runs", so any other order
   would make one frame's samples strided in storage — the copy the whole
   direct-write design exists to avoid. Extents are `[columns, rows, sliceCount]`,
   and every fixture uses three **distinct** extents so a transposition fails an
   assertion.

   **Axis sampling is `.indexOnly`, deliberately.** The affine already carries the
   spacing; declaring a regular per-axis sampling too would state one fact twice
   and let the two drift. That is the same mistake `ADR-0237` had to correct
   retroactively for a numeric boundary — applied in advance this time.

   **The finding: the corpus declares Hounsfield units and the adapter does not
   read them.** Rather than assume either way, Rescale Type (0028,1054) was
   measured: **all forty sampled files declare `HU`**. `DICOMFrameAdapter` does not
   read that attribute, so the builder **declines to assert a unit it has not
   seen** — declaring HU because CT usually means HU would be exactly the
   fixtures-encode-the-convention mistake already recorded twice, for
   signed-versus-unsigned samples and for the `-1024` intercept that turned out to
   be `-8192`. Deriving it is a named next increment: it needs a fourth field on
   `CTFrameDescription`, and `ADR-0234` already observed that a type which keeps
   gaining fields signals its boundary was drawn early.

   A unit slope with a zero intercept is published as `.identity` rather than
   `.linear(1, 0)` — not a shortcut, since `VOXELIA-ALG-0003` states the two are
   bit-identical, and the simpler declaration spares every consumer a
   multiplication that cannot change a value. A length unit for the samples is
   refused as a category error: it would claim the Hounsfield numbers are lengths.

   **`ADR-0241` bound the volume to storage** — the arc's smallest increment, as
   `ADR-0238` predicted, because `ContiguousImageStorage(binding:bytes:)` already
   accepts exactly what `CTVolumeByteBuffer` holds. 7 tests; 977 in 185 suites.

   Its one substantive decision is what to **refuse**: an **incomplete volume**.
   `ADR-0235` decision 7 added written-slice tracking precisely so a missing slice
   is a fact rather than a silence — the gap would read as zeros, which are
   plausible bytes and the wrong volume. Without this refusal that tracking would
   have been decorative.

   Two smaller calls. The descriptor and the buffer derive their byte counts
   **independently** — the binding from the descriptor, the buffer from
   `VOXELIA-ALG-0050` — so comparing them is a genuine check, and the **scalar
   type** is compared too, because `uint16` and `int16` agree on bytes and disagree
   on meaning, and they are exactly the two `VOX-DCM-005` admits. A test reads the
   whole region back through the erased provider and compares it to the transferred
   bytes, so the binding is verified by round trip rather than by construction.

   Recorded rather than smuggled: `ContiguousImageStorage` takes an `[UInt8]`, so
   the volume's bytes are copied once at that boundary — about 449 MiB at the ~120
   MiB/s `ADR-0235` measured. Avoiding it needs an ownership-transferring provider
   or an `inout` handover, both changes to accepted storage API, so it belongs to a
   record that changes storage rather than to a bridge increment.

   **`ADR-0242` performed increments (d) and (e) together**, and the merge is
   forced rather than convenient: a provenance record's subject references the
   identity's object ID and `ImageData` validates the two against each other, so
   neither can be built or verified alone. 10 tests; 987 in 186 suites.

   **The finding: an origin's source provenance is not in its inputs.**
   `ProvenanceRecord` **requires `inputs.isEmpty` for an `.origin` activity**, and
   `ImageData` separately **requires an origin's identity to carry at least one
   source identity**. Read together, the accepted model is explicit and was built
   for this case: provenance inputs describe Voxelia-to-Voxelia derivation, while an
   origin's sources are the source locators on its `DataIdentity` — and
   `sourceIdentities` is a *sequence*, so all 899 frames of a real series fit. So
   `VOX-VS1-019`'s source-frame provenance is discharged by the identity. That was a
   reading of two accepted types, and it needed both.

   **A real defect was found and fixed before it could reach publication.**
   `ImageData` requires the storage representation's byte order to equal the
   descriptor's. `ContiguousImageStorage` admits `.native`; `ADR-0240`'s descriptor
   declared `.littleEndian`, because that is what DICOM guarantees. **Different enum
   cases — `ImageData` construction would have thrown `byteOrderMismatch`.** Found by
   reading the invariants, then **confirmed by probing the two values** rather than
   inferred. `ADR-0238` had recorded that byte order "works by platform
   coincidence"; this is that coincidence becoming concrete — the values agree in
   *meaning* on Apple Silicon and disagree as *cases*. The descriptor now declares
   `.native`, and the coincidence is **enforced**: the builder refuses unless the
   platform is little-endian, so a big-endian port fails loudly instead of
   publishing a volume whose declared byte order misdescribes its bytes.

   Four smaller decisions, each declining to over-claim. A repeated source locator
   is **refused, not deduplicated** — two frames claiming one SOP Instance UID is a
   contradiction, and collapsing it would hide a duplicated frame. The identity
   carries **no content ID**, because a content claim would assert a digest this
   increment does not compute. The validation claim defaults to **`.unknown`**,
   because an ingest has run no validation. And `VOX-VS1-019` is claimed only for
   **frames and the transform** — nothing is claimed about operations,
   implementations or backends, because the ingest ran none.

   **Constructing an `ImageData` is the increment's proof.** Its admission checks the
   descriptor against the storage snapshot, the representation's byte order against
   the descriptor's, the provenance subject against the identity, and the origin
   source claim — so a value that exists has passed all four, and one test that
   builds one is worth more than any number of field-by-field assertions.

   **`ADR-0243` closed the arc, and the closing found a blocker that is not in the
   bridge.** 992 tests in 187 suites.

   | Stage | Result |
   |---|---|
   | Publication of a geometry-bearing ingested volume | **works** |
   | Slab extraction, one slice thick | **works**, and translates the affine origin |
   | Squeeze from a one-thick slab to a 2D slice | **refused** |
   | The same pipeline with `spatialGeometry: nil` | all three planes reconstruct |

   Every row is a test, not a reading, and the last two isolate the cause.

   **`SqueezeAxesOperation` guards `spatialGeometry == nil`**, and
   `MPRSliceCoordinator` uses squeeze as its second stage — so **no volume carrying
   a spatial geometry can be reconstructed through it**. That puts two P0
   requirements in tension: `VOX-VS1-004` requires an affine volume *with*
   patient-space geometry, `VOX-VS1-009` requires the reconstruction, and as
   implemented a volume can satisfy either but not both.

   **The refusal is correct conservatism, not a bug.** Dropping an axis from an
   affine means deciding what the remaining 2D geometry *is*: the 4×4 loses a
   column, the dropped axis's contribution must fold into the origin, and the
   `SpatialAxisMapping` must be renumbered. Real arithmetic, and the operation
   declined to guess. Every existing MPR test passes because its synthetic volumes
   carry no geometry — **nothing was wrong, and nothing had ever been composed.**
   Neither half of the project was at fault and no test could have caught it,
   because each half was only ever exercised alone.

   **`VOX-VS1-009` is not claimed.** The reconstruction works for geometry-free
   volumes and not for the volumes this project actually ingests; reporting that as
   satisfied would be the clearest kind of false claim. **No workaround was
   applied** — stripping the geometry before squeeze would make MPR "work" by
   discarding exactly what `VOX-VS1-004` and `VOX-DCM-007` exist to preserve, and
   would produce slices that silently do not know where they are.

   The blocker is **pinned by a test** that asserts the current refusal, so lifting
   it later is a noticed act rather than a silent behaviour change; a second test
   isolates the cause so the refusal cannot be blamed on the bridge.

   Secondary finding: **`RegionExtractionOperation`'s header contradicted its own
   code**, still describing a deferral of affine geometry and regular sampling that
   the code had stopped observing — both are handled, at lines 106 and 134, and a
   test proves the geometry branch is correct. Comment corrected; a comment that
   tells a reader the opposite of the truth is worse than none.

   **`ADR-0244` resolved the blocker, and corrected `ADR-0243` while doing it.**
   994 tests in 187 suites. **All three planes now reconstruct from a
   geometry-bearing volume**, so `VOX-VS1-009` is reachable.

   `ADR-0243` said the rule needed "real arithmetic" — folding the dropped axis's
   contribution into the origin — plus an algorithm specification with a frozen
   expression order and an oracle. **Two of those three were wrong.** Squeeze drops
   only axes of extent **one**, so the dropped index is always `0` and its
   contribution is `column × 0`: **the fold is identically zero.** No numeric
   boundary exists, so no specification and no oracle were issued. Only the
   renumbering half of the description was right.

   **Three candidate rules were probed against the accepted admissions rather than
   reasoned about**, and the obvious one is wrong:

   | Candidate | Result |
   |---|---|
   | Keep the 4×4 verbatim, renumber `imageAxes` | **admitted**, and a rank-2 descriptor accepts it |
   | Zero the dropped column, as a "2D" matrix would | **refused**: `singularTransform` |
   | Permute columns when the dropped slot is not last | **admitted** for slots 0 and 1 |

   The middle row is the finding: `AffineGridGeometry` requires a non-singular
   upper-left 3×3, so **a 2D geometry cannot be expressed by emptying a column**.
   Probing cost one test where designing around it would have cost an increment. The
   third row is the real case — matrix column `slot` maps to `imageAxes[slot]`, and
   coronal drops slot 1 while sagittal drops slot 0.

   So the rule is: **move the dropped column to the trailing slot, keep the
   survivors' order, renumber `imageAxes`.** The out-of-plane step is **preserved
   rather than zeroed** — truthful, since a slice from a volume does have one, and
   it is what keeps the matrix non-singular. A permutation changes a determinant's
   sign, not its magnitude, so the `ADR-0043` admission survives by construction.
   Replacing the column with the unit normal was rejected: it needs a square root
   and a zero-magnitude threshold to produce what the preserved column already
   gives, and `VOXELIA-ALG-0047` declined a square root for the same reason.

   `ADR-0243`'s pinned blocker test was **updated, not deleted** — it now asserts
   the new rule, keeping the coverage it was written to hold. A geometry-free volume
   still acquires no geometry, and a test asserts that too.

   **`VOX-VS1-009` is now discharged on real patient data.** The 899-slice series
   went all the way through publication and reconstructed in all three planes:

   ```text
   volume 512x512x899  complete true  449 MiB
   ImageData built. source locators: 899
   axial    slice 449: extents [512, 512]  geometry axes [0, 1]  0.13s
   coronal  slice 256: extents [512, 899]  geometry axes [0, 1]  0.23s
   sagittal slice 256: extents [512, 899]  geometry axes [0, 1]  0.67s
   ```

   Every extent matches what `VOXELIA-ALG-0050`'s layout predicts, and **all three
   planes keep a spatial geometry** — including coronal and sagittal, whose dropped
   slot is not last and needed `ADR-0244`'s column permutation. Before that record
   none of the three could be produced at all. The identity carries **899 source
   locators**, one per frame, which is how `VOX-VS1-019`'s source-frame provenance is
   discharged for an origin.

   **A second check fired on real data for the first time.** The first attempt
   failed with `frameOfReferenceNotPreserved` — the harness's fault and the check's
   success. The real series carries a Frame of Reference UID and the harness had
   supplied a descriptor with no external references, which `ADR-0230` decision 8
   refuses because that is how `VOX-DCM-007`'s preservation reaches the volume.
   **Every synthetic test passes `frameOfReference: nil`, so none of them exercises
   that path**; the rule was written from the requirement and had never been fired
   until real data supplied a UID.

   Cost baseline, unoptimised: axial 0.13 s because a one-thick axial slab is
   contiguous, sagittal 0.67 s because its slab is maximally strided — one column
   from every row of every slice.

   **`ADR-0245` assessed the five downstream requirements against the real volume
   before writing anything**, which is what the previous entry instructed. Result:
   one verified, one implemented-but-unverified, two genuine gaps, one requirement
   question.

   | Requirement | State |
   |---|---|
   | `012` window centre and width | **verified on real data** |
   | `013` linked patient-space crosshairs | implemented, never verified together |
   | `014` quantitative pixel inspection | **gap: position without value** |
   | `015` patient-space distance measurement | **gap: not implemented** |
   | `016` off-screen output | needs a requirement reading, not code |

   **`012` is verified, not merely implemented.** `WindowLevelOperation` carries no
   geometry guard and propagates the slice's geometry, and on the real axial slice a
   **lung window** (c -600, w 1500) and a **soft-tissue window** (c 40, w 400) each
   produced `uint8` 512×512 output in 0.04 s with geometry preserved. Those are the
   settings a thorax study is actually read with, so this is display output from
   real CT.

   **`014` is exactly the composition this session's pattern predicts.**
   `PickResolver` returns indices and a `worldPosition` that is absent rather than
   fabricated when uncalibrated — right design — but **no sample value**. Everything
   needed exists: the resolver gives the index, the slice gives the bytes,
   `CTValueInterpreter` gives Hounsfield units. **Nothing joins them.**

   **`015` is a gap, and a surprising one**: `AngleMeasurement`,
   `PolygonAreaMeasurement` and `VoxelVolumeMeasurement` all exist and **distance
   does not**. The simplest measurement is the missing one while three harder ones
   are built — which suggests the measurement work followed the interesting problems
   rather than the required list.

   **`016` needs a reading, not code.** No `offScreen` symbol exists anywhere.
   Either nothing implements it, or every Voxelia path is already off-screen (the
   project has no interactive viewport) so "the same semantics" holds trivially. The
   second is probably right, and probably-right is not a discharge.

   **Beyond the five: two more latent geometry refusals**, found the same way as the
   squeeze one — `ProjectIntensityOperation` and `TransposeAxesOperation` both
   `guard spatialGeometry == nil`. **Neither is on a VS1 path**, checked rather than
   assumed (`MPRSliceCoordinator` has zero transpose references). `ADR-0244` supplies
   the answer pattern for transpose — a column permutation, no arithmetic — while
   intensity projection is genuinely different, because collapsing a non-singleton
   axis really does change the geometry.

   **`ADR-0246` closed the `VOX-VS1-014` gap.** `CTSampleInspector` joins the three
   existing pieces. 1,004 tests in 188 suites.

   **The decision that shaped the type: it computes no world position.** The obvious
   design returns position *and* value, and that would **re-freeze a boundary that
   already has an owner** — `PickResolver` resolves a pick to an exact physical
   position under the rule `ADR-0129` governs. The register was searched for the
   boundary before any code was written, exactly as `ADR-0237`'s lesson requires, and
   it was found. So `PickResolver` says **where** and `CTSampleInspector` says
   **what**.

   It takes indices rather than a `PickResolution`, and **the module order made that
   decision**: `PickResolver` sits above `VoxeliaRendering`, so an inspection
   consuming its result could not live beside the interpreter it needs.

   **Verified on real data at positions chosen by anatomy, not convenience:**

   | Position | Stored | Interpreted | Expected |
   |---|---|---|---|
   | centre (256,256) | 8232 | **40.0 HU** | mediastinum |
   | mid-left (128,256) | 7237 | **−955.0 HU** | lung parenchyma |
   | corner (2,2) | 0 | **−8192.0 HU** | outside the reconstruction field |

   **These are the right values, not merely well-formed ones**, and an
   implementation that indexed the wrong axis, dropped the rescale or mis-signed the
   samples would be plausible in none of the three places.

   Two refusals kept it honest. **Lookup-table and composed transforms are refused**
   rather than half-evaluated, because a general evaluator would duplicate the model
   `VOXELIA-ALG-0005` governs and `WindowLevelOperation` already implements
   privately — sharing it is named as separate work. And **the padding value is a
   caller parameter**, following `WindowLevelOperation`'s accepted pattern rather
   than inventing a descriptor field, with a test asserting padding is compared on
   the **stored** value so a padding number equal to a *rescaled* value does not
   delete real signal.

   **`ADR-0247` found `VOX-VS1-015` was already implemented, correcting `ADR-0245`.**
   No code was added; discovering that was the increment's whole value.

   `VOXELIA-ALG-0010 - Polyline length` has been accepted since M2 and freezes
   `s = ((dx*dx) + (dy*dy)) + (dz*dz)`, `sqrt(s)`, no FMA — and **a two-point
   polyline is a distance measurement.** `MeasurementConstruction` implements it as
   `derivedLength` with the coordinate-space check `VOX-INT-009` requires.

   **Why the assessment missed it is the transferable part:** `ADR-0245` searched for
   `DistanceMeasurement` and the word "distance". The implementation is
   `MeasurementConstruction.derivedLength`. **The search was for a name rather than a
   behaviour** — the same class of error as `ADR-0237`'s source-instead-of-register
   search, and the register would have answered this one too. **The rule, extending
   `ADR-0237`'s: search the register for the capability, and expect the general case
   to be listed rather than the specialisation.** Angle, polygon area and voxel volume
   are the specialisations; polyline length is the general case, so it was the least
   likely to be named after the requirement.

   `ADR-0245`'s inference — "the simplest measurement is the missing one", suggesting
   the measurement work followed interesting problems over the required list — is
   **withdrawn**. It reasoned from a false premise, and a wrong judgement about the
   project's own history is worse than none.

   **Verified on real data, with the difference attributed rather than excused.** Two
   points 100 columns apart at `0.95313671875` mm spacing measured
   `95.31367187500001` mm against a naive prediction of `95.313671875` — 1 ULP apart.
   **The prediction was wrong, not the measurement:** `sqrt(dx*dx) == dx` **exactly**,
   so `ALG-0010` contributes zero error, while `dx == 100 * spacing` is **false**
   because the affine's origin subtraction rounds both intermediates against an origin
   of about `-249.5`. That is what a real measurement does — a tool reporting
   `100 × spacing` would report a number the geometry does not produce.

   One composition observation, recorded as understood rather than as a gap:
   `PickResolver` exposes an exact physical position only for a **rendered
   presentation**, so measuring on a bare published slice needs the `ADR-0129`
   index-to-world step the harness performed directly. In a viewer a measurement
   always happens on a presentation, so the product path is complete.

   **Next: `VOX-VS1-013`**, verifying the crosshair path end to end on the real
   volume; then `016`'s requirement reading; then `010`, `011`, `017` and `018`, none
   of which has been assessed yet.

   (Superseded framing: increment (d) was described here as the arc's largest.)

   **Increment (r): `ADR-0248`, linked patient-space crosshairs verified.**
   `VOX-VS1-013` is **discharged on real data**, and no source changed — the parts
   all existed and had never been composed. One crosshair at voxel
   `(col 300, row 200, slice 400)` of the 899-slice series, at
   `(36.41758402499997, -211.89908785000003, -1166.683)` mm:

   - **Slice-index round trip exact in all three planes** — axial `400`, coronal
     `200`, sagittal `300`, each the plane's own component of the originating voxel.
   - **Pixel round trip exact in all three views** — axial `(300, 200)` in `512x512`,
     coronal `(300, 400)` and sagittal `(200, 400)` in `512x899`. No tolerance
     applied anywhere.
   - **`ADR-0244`'s axis renumbering has its first real-geometry confirmation.** The
     coronal and sagittal rows are the load-bearing ones: they are what turns the
     slice axis into a view's `y`.
   - **Both refusal paths exercised**, not only the successes: the axis-value
     overload refused an affine-only volume with `unsupportedAxisSampling` (which is
     precisely why `ADR-0138` added the world-point overload), and an out-of-volume
     point refused with `crosshairOutsideVolume` rather than clamping.

   **The finding: `crosshairTargets` alone is not an in-volume test.** A crosshair 50
   columns past the edge resolved `outsideViewport, outsideViewport, target(200,400)`
   — the **sagittal view returned a pixel for a point outside the volume**. That is
   correct at the unit level, because the sagittal view presents row and slice so an
   out-of-range column cannot move the in-plane projection, and `PickResolver`
   documents that non-presented slots do not gate admission. But a host consulting
   only the pixel mapping would draw that crosshair. The guard is the slice-index
   call, which refused this exact point and which every host must make anyway to know
   what to render. Stated as a host obligation in `ADR-0248` decision 2 — a
   composition contract that was previously written down nowhere.

   **Capability-first sizing of the five remaining rows** — applying `ADR-0247`'s
   method rather than searching for each requirement's own vocabulary. This is
   sizing, not discharge:

   | Row | Mechanism | Assessment |
   |---|---|---|
   | `010` | `ExactSliceRenderer`, `MultiplanarRenderCoordinator` | present; needs a differential run |
   | `011` | `ALG-0008` nearest, `ALG-0015` bilinear, both with test files | likely already satisfied; confirm, do not build |
   | `016` | no `offScreen` symbol exists | requirement-reading question, unchanged |
   | `017` | `RenderGeneration.isStale` | **exists with zero production callers** |
   | `018` | `MetalResidencyManager.selection(for:)` | unified memory selects `.shared`, so no copy to duplicate; that is the `A` half, `T` open |

   **`017` is the substantive one, and it is the inverse of the error the method was
   adopted to prevent.** Capability search found the mechanism — a name search would
   have called the row satisfied — but a staleness predicate nothing calls prevents no
   stale publication. `isStale` is consulted by nothing outside its own file and test.

   One harness mistake, recorded rather than quietly fixed: the presentations were
   first built with the camera at its own target, and `RenderCamera` refused with
   `degenerateViewDirection`. The camera plays no part in `ADR-0140`'s mapping, which
   reads only geometry and viewport — but it must still be a valid camera.

   **Next: `VOX-VS1-017`**, a design record for wiring generation-based staleness into
   the publication path, since the predicate currently governs nothing. Then `011`'s
   confirmation, `010`'s differential run, `018`'s steady-state measurement, and
   `016`'s requirement reading. Non-blocking: a synthetic-affine three-plane
   composition test in `VoxeliaInteractionTests`, so CI guards what real data now
   demonstrates.

   **Increment (s): `ADR-0249`, the cancellable CT import session (stage one).**
   `VOX-VS1-017` addressed with a built path, 1012 tests / 189 suites green.

   **The previous increment's own framing was wrong, and this is the correction.**
   `ADR-0248` reported `RenderGeneration.isStale` as having zero production callers
   and treated that as the gap to close. The fact is right; the inference was not.
   `ADR-0122` decision 3 states plainly that "stamping frames and dropping stale ones
   is the interactive draw loop's behaviour", with `VOX-INT-007` "discharged at the
   contract level" and the draw-loop integration "recorded with its gate". **The
   uncalled predicate is a recorded deferral, not an oversight** — and it belongs to
   `VOX-INT-007`, not to this row. Corrected in `ADR-0249` decision 1 without editing
   `ADR-0248`.

   **The plan draws the line twice, and reading it settles the row.** §22.3: a result
   may be **presented** only if its generation matches the viewport's — that is the
   gated draw loop. §22.1: "a **CT import session shall be cancellable**", nine
   stages, and §58.1 requires that cancelling during metadata scan, decode, volume
   copy, identity or publication yields no partial `ImageData` and typed
   cancellation. `VOX-VS1-017`'s own wording is **publication**, so the row is §22.1
   — buildable now, not gated.

   **Two findings from reading the code rather than assuming:**
   - **The import path had no cancellation at all.** `RegionExtraction`,
     `SqueezeAxes` and `WindowLevel` — the three operations the CT path uses — carry
     none, nor does `PublicationCoordinator`. The `VoxeliaCPU` geometry operations do,
     so the pattern existed and imaging never adopted it.
   - **Nothing owned the frame loop.** Every CT type was Voxelia's, but the loop over
     a series' frames lived in caller code — the harness wrote it by hand. A
     cancellable session had nowhere to live until something owned that loop.

   **Publication-time atomicity is already structural, so no probe was added.**
   `publish` is three-phase and phase two is a **non-suspending critical section** in
   which identifier reuse, the ceiling, the ancestry closure, graph admission and the
   registry mutation linearise together. A non-suspending region has no cancellation
   point: "no partial `ImageData`" and "no corrupt cache entry" are properties of the
   existing design, not of a check. Adding a probe there would be a branch that can
   never fire. Recorded in `ADR-0249` decision 6, with its own test deferred to
   stage three.

   Built: `CTImportSession` in `VoxeliaImaging` — source-agnostic, generic over an
   opaque `Source`, with two caller-supplied closures — plus `CTImportCheckpoint`,
   `CTImportCancellationProbe`, `CTImportedVolume` and a payload-free failure family.
   **In `VoxeliaImaging` rather than `VoxeliaDICOMKit` deliberately**: behind the
   optional product the row's own `T` obligation would need both the dependency and
   patient data, and no repository test may read the latter.

   **A structural improvement the increment did not set out to make.** The session
   builds the `CoordinateSpaceDescriptor` itself from the chosen series, instead of
   accepting one. That is precisely the bug the `VOX-VS1-001` harness hit — a caller
   assembling the descriptor by hand omitted the series' frame of reference and was
   refused with `frameOfReferenceNotPreserved`. `VOX-DCM-007` preservation is now
   structural rather than trusted, and a test pins it.

   Eight tests, all green first run. **Every checkpoint is enumerated rather than
   sampled** (the input space is eleven sites), and one test asserts the probe is
   consulted at exactly the documented sites **in order** — so a checkpoint that is
   documented but never reached would fail rather than mislead. The row's own
   property is proved compositionally against a real `PublicationCoordinator`: for
   every checkpoint, a cancelled import leaves no published image and no published
   provenance. The sharpest case is `.final` — every stage complete, the volume fully
   assembled, and the caller still receives nothing — paired with an uncancelled
   control that *does* publish, so the test proves cancellation rather than a broken
   pipeline.

   One house-rule catch: `nonisolated(unsafe)` was reached for to capture the visited
   checkpoints, and the safety policy reserves that bare word **even in comments**.
   Replaced with a `Mutex`-backed recorder — the policy admits no escape hatch for a
   test either.

   **An ordering question named and deliberately left open**:
   `MPRSliceCoordinator.extractSlice` publishes **twice** (slab, then squeezed
   slice), so cancellation between them would leave the slab published and the slice
   absent. That belongs to the view path, not the import path, and answering it means
   deciding whether a multi-stage publication is a transaction — a provenance-graph
   question well beyond this row. Named so a later increment cannot assume it was
   settled.

   **Increment (t): `ADR-0249` stage two — the DICOM frame source, verified on real
   data, and two of my own claims refuted by measurement.** 1012 tests / 189 suites.

   Built `DICOMFrameSource` in `VoxeliaDICOMKit` plus an additive
   `DICOMFrameTransfer.frameBytes` read-only entry point. Cancellation injected at
   each stage boundary **and deep inside** each per-item stage — cancelling at item
   zero proves only an early exit:

   | Cancelled at | Refused after |
   |---|---|
   | `metadataRead(0)` / `(450)` | `0.00 s` / `0.09 s` |
   | `grouping` / `frameValidation` | `0.18 s` / `0.19 s` |
   | `decode(0)` / `(450)` | `0.56 s` / `2.45 s` |
   | `assembly` / `identity` / `final` | `4.34 s` / `4.30 s` / `4.24 s` |

   Every case refused with `cancelled` and left the coordinator with **no published
   image**, checked against the same `PublicationCoordinator` the uncancelled control
   publishes into. The control is what makes the nine refusals evidence of
   cancellation rather than of a broken pipeline. The session's volume matches the
   hand-written harness loop's, and the frame of reference is carried.

   **My documented rationale was wrong, and the measurement I ran to support it is
   what showed that.** The source re-reads each file rather than retaining the parsed
   data set, and I justified it as spending time to save memory. So I built the
   retaining mode to offer the trade and measured it: **`1.01x` faster for
   `+476 MiB`** — no speedup at all, because `DICOMFile.read` does not eagerly copy a
   file's bytes. Re-reading is strictly better, so **the option was removed rather
   than shipped** as a plausible-sounding choice with no measured benefit.

   **That refutation carried the larger finding.** If retention changes nothing, the
   ~23 s was never re-parsing — it was a copy *I had introduced*, because the new
   byte entry point returned `[UInt8]` and so converted DICOMKit's `Data` once per
   frame. Making `CTImportSession` generic over the byte collection and returning
   `Data`: **`22.85 s` → `4.23 s`, `5.4x`**, now alongside the `3.77 s` the
   hand-written transfer took in run 1. About 20 ms per frame — five times the
   transfer itself — was spent copying bytes that never needed copying.

   Worth keeping as method, not as a number: **a hedge added against a guessed trade,
   then measured, is how the guess got caught — and removing the hedge is what
   exposed the real cost.** Had I simply asserted the memory/time trade and moved on,
   the import would still be five times slower and the record would have said so
   confidently.

   **Increment (u): `ADR-0249` stage three — decision 6 verified, and the claim came
   out sharper than it went in.** 1016 tests / 190 suites. **`VOX-VS1-017` is now
   discharged across all three stages**, and it declares `T` alone, so the row closes
   completely with no demonstration half outstanding.

   Decision 6 declined to add a cancellation probe to `publish` because phase two
   does not suspend, and required that be **verified rather than asserted**. Cancelling
   the surrounding task and inspecting the registry, 24 attempts per shape:

   | Image | Cancellable window | Registry, every attempt |
   |---|---|---|
   | No content claim | none before phase two | **`both`**, 24 of 24 |
   | Sample-bytes content claim | phase one's cancellation-aware read | **`neither`**, 24 of 24 |

   **The split is deterministic, not racy**, and that is the finding. The invariant
   held everywhere — an image is published iff its provenance is — and *which*
   outcome occurs is decided entirely by the content claim: without one there is no
   suspension before the registry mutation, so an already-cancelled task publishes
   **completely**; with one, `StorageReadCoordinator`'s cancellation-aware read
   refuses and **nothing** registers. Sixteen concurrent cancelled publications never
   half-registered an object.

   **I checked whether the test was passing vacuously, and that check is what
   produced the finding.** Four green ticks would have been consistent with
   cancellation never biting at all. Instrumenting the distribution showed the
   perfect 24/24 split — so the assertion was **strengthened from "both or neither"
   to the exact outcome per shape**. The weaker form would pass unchanged if a
   suspension were introduced into phase two, which is precisely the regression
   decision 6 exists to prevent. A test that cannot fail usefully is not evidence.

   **Increment (v): `ADR-0250`, `VOX-VS1-011` confirmed — and `ADR-0217` had already
   discharged it.** 1019 tests / 191 suites. No source changed.

   **The row was claimed years-of-increments ago and I nearly re-claimed it.**
   `ADR-0217` discharged `VOX-VS1-011` citing `ResampleNearestOperation`,
   `ResampleLinearOperation`, `ALG-0008`/`ALG-0015` and `ADR-0124`'s
   `InterpolationPolicy`. This record **confirms rather than re-discharges** — a row
   claimed twice is a traceability defect even when both claims are true.

   **Finding: the discharge is right and its citation is incomplete.** Plan §28.2
   says "linear interpolation shall operate in **three-dimensional** continuous index
   space". `ResampleLinearOperation` is *bilinear* — rank two. The 3D clause is met
   by `ObliqueSliceOperation`'s trilinear reduction under `ALG-0017`, which
   `ADR-0217` never names. **Dimensionality was the discriminator, and only §28.2
   supplies it** — searching the requirement's own phrase finds the rank-two
   operations first, which is exactly the trap the capability-first method was
   adopted to avoid, in a new disguise.

   **Second finding, named not filled: there is no nearest mode for volume
   sampling.** `ObliqueSliceOperation` is trilinear only; the only nearest sampler is
   rank-two. Not a `VOX-VS1-011` gap, for a specific reason: every first-slice
   reconstruction path is **axis-aligned**, so each output sample *is* a stored
   voxel, and where every sample lands on a sample point nearest and linear agree
   exactly. Interpolation mode cannot change an axis-aligned result. It IS a real gap
   for oblique and DVR work — `InterpolationPolicy` already names
   `.nearestNeighbour` with no volume-sampling implementation behind it — so it is
   recorded for whichever row needs it.

   **Added the analytical property the plan asks for (§1957, "analytical" equality)
   and that no accepted suite states**: that a linear interpolator reproduces a
   linear function **everywhere**, not only at the samples. Three tests — linear
   precision over twelve interior positions, exactness at all 27 samples,
   monotonicity in quarter steps per axis. **No epsilon**, despite the plan's word
   "bounded": the ramp coefficients are small integers and every position is a half-
   or quarter-integer, so the arithmetic is exact. Choosing provably exact cases is
   this project's standing alternative to inventing a threshold, and it leaves the
   geometry tolerance gate untouched.

   **The test's first version was wrong and that is the useful part.** It asserted
   the unquantised ramp value and failed on exactly two of twelve cases —
   `(0.25,0,0)` and `(0.75,0,0)`, whose exact values are `0.5` and `1.5` because the
   first ramp coefficient is `2`. The observed bytes were `0` and `2`: `ALG-0002`
   ties-to-even, behaving exactly as accepted. **The interpolator was right and my
   expectation was wrong.** Composing the accepted quantisation rule fixed it and
   made the assertion stronger than intended — it now pins interpolation and output
   rounding together, so a change to either fails here.

   **Increment (w): `ADR-0251`, `VOX-VS1-016` discharged — the reading three records
   deferred.** 1022 tests / 191 suites. No source changed. **Seventeen of twenty.**

   **The problem: §35.3 requires off-screen and interactive render targets to be
   byte-identical, and one half of that comparison does not exist.** Voxelia has no
   interactive viewport — the draw loop is the standing owner gate. Both naive
   readings fail: "satisfied because everything is off-screen" is true and vacuous,
   while "blocked on the draw loop" is wrong for a row declaring `T` whose
   deliverable already exists.

   **The reading: equivalence reduces to PURITY of the render path.** `SliceRenderer`'s
   entire contract is `render(request)`. If output is a pure function of the request,
   any future interactive caller issuing that request **necessarily** gets the same
   bytes — equivalence needs the render path to have no other input, not the viewport
   to exist. Same move `ADR-0206` made for annotation registration, where
   statelessness IS the requirement.

   **Finding: eight of §35.1's nine semantics travel in the request; the ninth does
   not.** **Padding policy is not expressible in a `RenderRequest`** — it arrives via
   the renderer's injected `windowStage`, and `ExactSliceRenderer`'s convenience init
   hard-codes `paddingValue: nil`. So output is a pure function of *(request,
   injected stages)*, not the request alone, and the equivalence is stated
   **conditionally** on identical construction. The unconditional version would have
   been shorter and wrong. It matters clinically: a windowed render of padded CT maps
   padding as tissue. Deferred to its own record — §28.4 offers two candidate rules
   and says the choice is separately approved.

   **Second finding, from a test failure: identifiers MUST differ, so equivalence
   cannot include them.** Rendering the same request twice through one renderer failed
   with `duplicateObjectIdentifier` — the naming contract working correctly, since
   identifiers are the host's to mint and my closure was a pure function of the stage.
   A real viewport must mint fresh identifiers per frame. So equivalence is defined
   over published bytes and `PresentationProvenance` and **explicitly not over
   `outputObjectID`**; a record claiming "byte-identical results" without that
   distinction would describe something unachievable. Fixed with a generation-counting
   naming closure that models a viewport.

   Three tests, each proving what the others cannot: one request twice is
   byte-identical; an intervening *different* render does not change a repeat of the
   first (which makes the claim about the renderer **instance**, not one call); and two
   independently constructed renderers agree exactly (the case that actually models an
   export path and a viewport each building their own). **Non-vacuity asserted** — each
   pins the byte count at 12, because two empty arrays also compare equal, carrying
   forward `ADR-0249` stage three's lesson.

   No `offScreen` symbol was introduced: a flag with one reachable value would claim a
   distinction the code does not make.

   **Increment (x): `ADR-0252`, the CPU-Metal three-view differential — and a
   correction to my own sizing.** 1023 tests / 191 suites. No source changed.

   **`ADR-0248` said `010` "needs a differential run". Half right.** `ADR-0221` had
   **already discharged the row's Test half** through `MultiplanarRenderCoordinator`
   and correctly left the Demonstration half on the owner-gated draw loop, so
   **nothing claimable remained**. This record adds evidence to a discharged row
   rather than re-discharging it. That is the third sizing correction in this arc, all
   from reading records before designing.

   **What the two renderers are, which matters more than the result.**
   `MetalSliceRenderer` **is** `ExactSliceRenderer` with different stages injected:
   window, invert and composite run on the device with `binary32-device`
   `approximate` claims, while **the resample stage remains the accepted exact CPU
   operation** because whole-sample selection has no device approximation to claim.

   Two consequences:
   - **The differential compares the window stage, not interpolation.** The plan's
     table has a "Metal linear interpolation — CPU differential" row that **cannot be
     exercised**: there is no GPU resample, so a resample differential would compare
     CPU against CPU and pass vacuously. Recorded rather than worked around; building
     a device resample to satisfy a validation row would add the second sampling path
     `ADR-0221` refuses.
   - **It independently confirms `ADR-0251`'s conditional framing.** That record
     stated purity as conditional on identical renderer construction because padding
     travels through the injected `windowStage`. Backend selection turns out to be
     *implemented* as stage injection — so that channel is not hypothetical, it is the
     mechanism. The conditional wording was load-bearing, not pedantic.

   **Result: exact agreement on all three planes** (axial 6 bytes, coronal 8,
   sagittal 12; anisotropic `2x3x4` so a transposed plane cannot pass). The GPU
   genuinely ran — `MetalWindowLevelKernel` encodes and dispatches a compute pass, and
   the renderer documents no silent fallback.

   **The honest limit, stated rather than banked.** Exact here does NOT establish
   exact in general. The fixture is `uint8` with centre 12 and width 24 — small
   integers where binary32 is exact, so the paths have nothing to disagree about. The
   kernels agree **where the arithmetic is unambiguous**. The `approximate` claim
   stays correct and the plan's "≤ 1 code value if the rounding path is approved"
   remains right for inexact inputs.

   **No tolerance introduced**: §54's profile is explicitly provisional pending owner
   approval as `voxelia.m4.ct.diagnostic 1.0.0`, so the test asserts the plan's stated
   preference — exact — which needs no threshold. Any future divergence fails visibly
   instead of being pre-absorbed. Deliberately did NOT extend to the real CT volume:
   the interesting inputs are the inexact ones, and there the comparison needs the
   tolerance profile that is still an owner gate — measuring it would produce a number
   nobody is yet authorised to accept.

   **Increment (y): `ADR-0253`, `VOX-VS1-018` discharged in both methods. EVERY
   FIRST-SLICE ROW WITH CLAIMABLE WORK IS NOW DONE.** 1024 tests / 191 suites.

   **Analysis half — the row asks about a CPU-to-GPU duplicate, and the first slice
   performs no full-volume upload at all.** `MultiplanarRenderCoordinator` extracts
   the plane on the CPU and hands the renderer a **two-dimensional** layer; neither it
   nor `MetalSliceRenderer` touches `ExactVolumeRenderer`. So the second complete copy
   the row is about cannot exist, because the transfer that would create it never
   happens. `ADR-0081`'s residency model covers the DVR case when it arrives —
   recorded, not claimed.

   **Test half — measured in a FRESH process**, and that detail is the increment's
   methodological point:

   | Quantity | Value |
   |---|---|
   | One full logical volume | `449 MiB` |
   | Peak resident after import | `466 MiB` |
   | **Ratio** | **`1.04x`** |

   Measuring inside the long-running harness first reported a **`0 MiB` delta** —
   because `ru_maxrss` is a high-water mark, so a later import that stays under an
   earlier peak shows nothing. That number was real and the conclusion it invited was
   false. A separate single-import binary was written to get an attributable figure.

   Storage-boundary accounting confirms §59.4 directly: a full-volume read charges
   exactly `449 MiB` and releases to exactly `0`.

   **A suspected transient duplicate turned out not to exist.**
   `CTVolumeStorageBuilder` does `ContiguousImageStorage(bytes: Array(buffer.bytes))`,
   which reads like a 449 MiB copy and would show as ~`2.0x`. It measures `1.04x`:
   the buffer is uniquely referenced and unused afterwards, so the bytes move. The
   "obvious optimisation" — changing `CTVolumeByteBuffer.bytes` to `[UInt8]` — would
   have been a public-API change to a frozen type **buying nothing**.

   **Contrast increment (t)**, where a suspected copy WAS real and cost `5.4x`.
   Identical reasoning both times, opposite answers; only measurement distinguished
   them. That is now a standing rule rather than an anecdote.

   §59.3's stress cases (`512x512x1024`, dataset replacement, open/close cycles,
   export during interactive rendering) are **not claimed** — the last needs the gated
   interactive path and the rest are benchmark work belonging to `VOX-VS1-021`.

   # FIRST VERTICAL SLICE: ALL CLAIMABLE ROWS DISCHARGED

   `001`-`009`, `011`-`020` complete. **Two things remain, neither of them ordinary
   work:** `VOX-VS1-010`'s **Demonstration** half, owner-gated on the interactive draw
   loop alongside the `VOX-SUR` demonstration halves; and **`VOX-VS1-021`**, the
   validation and benchmark reports, which is where §59.3's stress volume and the
   provisional `voxelia.m4.ct.diagnostic` tolerance profile belong — and that profile
   is an **owner approval**, not something to adopt as if approved.

   **Increment (z): `ADR-0254` — the M4 validation and benchmark reports.**
   `VOX-VS1-021`'s `I` and `T` halves discharged; **`R` deliberately left unsigned.**

   **The row cannot be fully discharged by this project, and the traceability entry
   says why**: "**Approved** M4 validation and benchmark reports". `T` is
   dischargeable (1024 tests, ten real-data runs) and `I` is (the reports exist and
   can be inspected against §19.6/§61/§63/§64.4's content lists), but **`R` is a
   review method — a report this project also reviewed would be self-approval**, which
   is exactly what a review method exists to prevent. The review record carries
   `pending owner` rows so the gap is visible in the artefact, not just here.

   **Two gates sit INSIDE the row**: §61 requires an approved `A-WORKSTATION` for
   formal performance acceptance (none exists → **no acceptance claimable at all**),
   and §54's `voxelia.m4.ct.diagnostic 1.0.0` profile is explicitly provisional.
   **But §63 supplies what IS achievable**: "M4 shall establish a reproducible
   baseline even where no absolute first-image threshold has yet been approved."

   **Templates and directories already existed** — `docs/templates/{Validation,Benchmark}-Report-Template.md`,
   `docs/validation/`, `docs/benchmarks/`. Checking first avoided inventing a
   structure the project had already decided. Produced `VOXELIA-VAL-0001` and
   `VOXELIA-BEN-0001`.

   **The baseline** (release, fresh process, 899 frames, 449 MiB):

   | Stage | Release |
   |---|---:|
   | Metadata-ready | `0.291` s |
   | Geometry accepted / first decoded frame | `0.314` s |
   | Complete volume | `1.841` s |
   | First axial image | `1.942` s |
   | First three-view / steady state | `2.350` s |

   ≈ 3,090 frames/s scan, ≈ 589 frames/s decode (≈ 294 MiB/s), ≈ 244 MiB/s import.
   Peak `471 MiB` = **`1.05x`** of one volume. Metal full-volume resource **0 B**.
   **Debug published alongside release** (`4.283` s vs `1.841` s, `2.33x`): debug alone
   would understate by >2x, release alone would hide that the default `swift build` is
   much slower.

   **The benchmark report states its own principal weakness prominently**: a single
   cold run per configuration, no warm-up, no repetitions, **no distribution** — which
   is what §53's method actually asks for. Presenting one run as a median would
   manufacture a statistic; that option is named and rejected in the record.

   **Two design properties, not hardware ones:** the **first axial image arrives
   AFTER the complete volume** (reconstruction reads a published volume), so §63's
   clause is met — there is no optional preprocessing to beat — but **progressive
   display during loading is unsupported**, recorded as a limitation rather than
   hidden behind a satisfied clause. And the sagittal plane is consistently slowest,
   fixing the fastest-varying index.

   **Absences recorded as absences**: power state, thermal state, retained
   compressed-source footprint — all listed by §61/§19.6, none instrumented, none
   guessed. **The three outstanding failures are in the report's own Deviations
   section** per §2761: `validate-scaffold.sh` red on the Swift 6.3.3
   `swift-frontend` signal 11, DocC without global `--warnings-as-errors` because of
   dependency diagnostics, and two absent dependency `LICENSE` files.

   One self-inflicted bug worth noting: I used `String(format: "%-42s", swiftString)`
   for the stage table and got mojibake — **the exact `%s`-needs-a-C-string trap my
   own memory note warns about.** I had applied `padding(toLength:)` to the argument
   and still passed it through `%s`. Half-applying a rule is not applying it.

   # FIRST VERTICAL SLICE COMPLETE — SIX OWNER DECISIONS OUTSTANDING

   1. Review/approval of `VOXELIA-VAL-0001` and `VOXELIA-BEN-0001` (`VOX-VS1-021` `R`).
   2. Reference-hardware approval (§61) before any performance acceptance.
   3. The `voxelia.m4.ct.diagnostic 1.0.0` tolerance profile.
   4. The geometry tolerance rule, and whether reformats must be supported.
   5. `LICENSE` files in `Raster-Lab/JLSwift` and `Raster-Lab/CompressionFamily`.
   6. Whether the interactive draw loop proceeds — four Demonstration halves wait on
      it (`VOX-VS1-010`, `012`, `013`, plus the `VOX-SUR` and `VOX-MPR-011` halves).

   **Increment (aa): `ADR-0255` opens the M5 compression arc, and the traceability
   debt baseline is now EMPTY.** No source changed.

   **All thirteen untraced rows turned out to be one arc**, not scattered debt:
   `VOX-CMP-002`..`014`. M5 is entered (`HIGHEST_ENTERED_MILESTONE = 6`), so they are
   due. `VOX-CMP-001` was already released by the owner's codec approval, which is
   what made opening the arc possible.

   **Greenfield, unlike the last several arcs**: `VoxeliaCompression` does not exist,
   no transfer-syntax vocabulary exists anywhere in `Sources`, and
   `VoxeliaDICOMKit` touches no compression at all.

   **The finding: reading each row for WHOSE behaviour it constrains splits the arc
   cleanly, and one half conflicts with a standing owner instruction.**

   Buildable now (Voxelia's own boundary): `002` module isolation, `003` adapter
   shapes, `007` never-sampleable, `008` destination storage, `009` cancellation,
   `010` adapter validation, `013` never-a-standard-transfer-syntax.

   **Blocked** (needs characterising the Raster-Lab codecs): `004` JP3D evaluation,
   `005` HTJ2K throughput, `006` "the **actual** codec output ... documented",
   `011` **adversarial codestreams**, `012` original-preservation, `014` compression
   benchmarks.

   That second set is exactly what the owner instructed against — *"These library are
   used and tested multiple times I dont need you to divert a new for testing the
   applicaition"* — read together with *"If any bugs found on the library the we need
   to address it and fix it"*: fix what surfaces, do not go looking. **`VOX-CMP-011`
   requires going looking.** This is a genuine conflict between an accepted P0
   baseline and a standing instruction, and **it is not mine to resolve** — proceeding
   would disregard the owner; dropping the rows would hide unmet P0s. Stated and
   referred.

   **A distinction that shrinks the blocked set:** `010` and `011` look alike and are
   not. `010` is adapter-side and fully buildable — validating declared dimensions,
   formats and decoded byte counts tests **Voxelia's** admission. `011` is **not**
   fully achievable adapter-side, because a codestream cannot be validated without
   parsing it and parsing is the codec's job. Adapter-side bounds narrow `011`'s
   residual exposure without closing it, and the record says so rather than claiming
   otherwise.

   **A second supply-chain question raised before it could bite:** the five codecs are
   approved **transitively through DICOMKit**; `Package.swift` declares exactly one
   dependency and `check_licence_policy.py` enforces it. `002`'s adapters would likely
   need a codec **declared directly**, which is a different act from tolerating it
   transitively. The gate would refuse it today — correctly. Owner question.

   **The traceability ratchet then did its job on me.** Naming the thirteen rows
   *traced* them by the tool's definition, so `validate-docs.sh` FAILED with "13
   allowlisted row(s) are now traced. Remove them from the allowlist so the ratchet
   keeps its grip." All thirteen removed; the check now reports **356 requirements in
   entered milestones, 0 untraced**. The file carries an explicit warning that
   **TRACED IS NOT SATISFIED** and names the six blocked rows, because an empty
   allowlist must never be read as an arc completed.

   **Increment (bb): `ADR-0256`, compression increment (a).** `VOX-CMP-002` and
   `VOX-CMP-007` discharged. **1031 tests / 192 suites** after a clean rebuild (a new
   target is a layout change).

   `VoxeliaCompression` added, depending on **`VoxeliaCore` alone** — it needs
   `ScalarFormat` and nothing more, and depending higher would put it beside the
   reconstruction stack rather than below it.

   **`VOX-CMP-007` enforced THREE ways, none of them a comment asking the reader to be
   careful:** `CompressedPayload` does not conform to `ImageStorageContract` (asserted
   by test, **with a real-conformer positive control** so the predicate is known to be
   able to match); `VoxeliaCompression` may not import Metal, so it cannot build a
   texture; and **`VoxeliaMetal` may not import `VoxeliaCompression`**, so the module
   that *can* build textures cannot even name a compressed value. The third is the one
   a reader would not think to add, and it is `ADR-0196`'s lesson applied before an
   audit rather than after.

   **No format identifier, deliberately** — a string field here is exactly how a
   toolkit-native cache gets mislabelled as interoperable; labelling is `VOX-CMP-013`,
   increment (b). **Every shape member is named `declared`**, because nothing here can
   verify what the codestream decodes to without a codec. Byte count derived at
   admission, never supplied. Both overflow multiplications checked, with a maximal
   admissible shape tested from the accepted side.

   **The finding: two graph checks could not see a new module.** Both
   `check_package_graph.py` and `check_package_graph_static.py` iterate over their own
   `EXPECTED` map, so a target absent from it was never visited — and the consequence
   was already live: **`VoxeliaDICOMKit` had been unregistered since `ADR-0233`** and
   its dependencies had never been graph-reviewed by either tool. `VoxeliaTestSupport`
   never had either. Both checks now fail on any unregistered Voxelia target; all
   three are registered; test targets are excluded because they depend on products by
   design.

   **Everything new was negative-tested rather than assumed**: unregistering
   `VoxeliaCompression` → "unregistered Voxelia targets"; declaring a wrong dependency
   → "expected [...], got [...]"; adding `import VoxeliaCompression` to a
   `VoxeliaMetal` source → the expected refusal. The new rule found
   `VoxeliaTestSupport` on its very first run.

   One limitation recorded rather than hidden: the dynamic check extracts only
   `byName` deps, so `VoxeliaDICOMKit`'s external product linkage is invisible to it —
   that is gated by `check_licence_policy.py` instead, and the expectation carries a
   comment saying so rather than listing a dependency the extractor cannot see.

   **Increment (cc): `ADR-0257`, compression increment (b).** `VOX-CMP-013`
   discharged. 1037 tests / 193 suites.

   **The rule made a theorem, not a convention.** One predicate used in opposite
   directions: a standard transfer syntax admits **only** UID-shaped identifiers, a
   toolkit-native name admits **only** non-UID-shaped ones. So
   `standard ⟹ UID-shaped` and `toolkitNative ⟹ not UID-shaped`, and no identifier
   can be admitted as both — asserted over the same identifier set from both sides. A
   toolkit-native value also yields **no** transfer syntax UID at all, so a caller
   writing a DICOM header cannot obtain one by mistake.

   Frozen `DICOMUIDShape.isUIDShaped`: non-empty, ≤64 chars, only ASCII digits and
   full stops, ≥2 components, no empty component. **Leading zeros deliberately NOT
   rejected** — the test's job is to *refuse* UID-looking toolkit names, so
   over-inclusiveness is the safe direction; it gates shape, never meaning, and never
   authorises the standard case. Naming a syntax is not supporting it, hence
   `declaredTransferSyntaxUID`.

   **The finding, and it is about my own work: the first version's enforcement was
   NOT structural, and all six tests passed anyway.** I wrote it as a public enum with
   throwing factories and documented the requirement as structurally enforced. Public
   enum cases are directly constructible, so
   `CompressedRepresentation.toolkitNative(name: "1.2.840.10008.1.2.4.201")` compiled
   — a toolkit cache carrying the HTJ2K lossless UID, bypassing every admission. **The
   tests all passed because every one of them used the factories.** A suite that only
   exercises the intended path cannot find an unintended one.

   Found by writing the bypass in a scratch package and **compiling it** — it built.
   Fixed to a `struct` with a private nested `Kind` and private init, so the factories
   are the only construction paths; recompiling the same bypass now fails with "type
   'CompressedRepresentation' has no member 'toolkitNative'". Both compilations are
   the evidence recorded in the ADR.

   **Generalisation now in memory: when a record claims an invariant is STRUCTURAL,
   the check is not whether tests pass — it is whether the violation still compiles.**
   For a value type that means asking whether every construction path runs the
   admission, and public enum cases never do.

   **Increment (dd): `ADR-0258`, compression increment (c).** `VOX-CMP-010`
   discharged. **1045 tests / 194 suites** after a clean rebuild (a public stored
   member changed).

   **Two checks at two different times, and the order is the substance.**
   `admitDestination` runs **before** a decode; `admit(_:against:)` after it. A caller
   running only the second would already have allocated. The ceiling is
   **caller-stated, never defaulted** — no figure this module could pick would be
   anything but a guess about a caller's memory budget (the real CT volume is
   449 MiB).

   `CompressedPayload` gains a **declared component count** (the byte count now
   multiplies by it, and the overflow check gained a third multiplication):
   `VOX-CMP-010` names "component formats", and three components where one was
   declared is a disagreement the byte count alone can miss when extents compensate.

   **Exact equality throughout — this row raises no tolerance question at all.** A
   decoded byte count is a count, extents are counts, formats and component counts
   are discrete; a near-miss is a disagreement about what the data *is*, not rounding.
   Checks run dimensions → components → format → byte count so the **most specific**
   disagreement is reported, with two tests pinning the order.

   **`VOX-CMP-011` narrowed, precisely, and NOT claimed.** The ceiling bounds
   **Voxelia's** allocation against a caller-stated figure. **It does not bound the
   codec** — if a codec allocates from the codestream's own headers or faults on
   malformed input, nothing here prevents it. That residual exposure stays open and
   stays part of the owner reconciliation; both the record and the source say so,
   because it is not narrowed by going unmentioned.

   Both byte-count directions tested for distinct reasons: a **short** decode is what
   a truncated codestream produces and admitting it would publish stale destination
   bytes as samples; an **over-long** decode would overrun a destination sized from
   the declarations. Also pinned: permuted extents (`2x3x4` vs `4x3x2`) are a
   refusal, since equal byte counts do not imply equal extents.

   **Compression arc: 4 of 7 buildable rows done** (`002`, `007`, `010`, `013`).

   **Increment (ee): `ADR-0259`, compression increment (d).** `VOX-CMP-009`
   discharged. **1053 tests / 195 suites.**

   `ADR-0249`'s shape **reused, not reinvented** (as `ADR-0255` d4 required): four
   checkpoints — `.destination`, `.decode`, `.validation`, `.final` — an injected
   probe, same rule everywhere. `.decode` is checked **immediately before** the call,
   the last site where cancellation costs nothing; a test asserts the closure did NOT
   run when cancelled there, **paired with a control proving it does run otherwise**,
   so the zero is cancellation rather than a closure that never fires. `.final`
   is what makes "no partial data published as complete" structural.

   `ADR-0258`'s checks **composed, not restated** — a report disagreeing with the
   declarations refuses with the *validator's* case, and a refused ceiling leaves the
   decode unrun (tested).

   **The finding: a decode's report can lie about its own bytes, and `ADR-0258`'s
   validator could not catch it.** The validator compares a *report* against
   declarations; **the bytes were never part of that comparison**. So a decode
   returning 40 bytes while reporting 48 passes it completely — the report matches the
   declarations exactly and the disagreement is with *itself*. Admitting it would
   publish stale destination bytes as samples, which is exactly the partial-data
   output `VOX-CMP-009` forbids. The session now checks
   `claim.byteCount == bytes.count` before invoking the validator, with **its own
   error case** so a caller can tell a lying codec from a mismatched one.

   `ADR-0258` is not wrong — a validator over a report can only check the report —
   but its guarantee was **narrower than it reads**, and that only became visible when
   bytes appeared alongside the claim. **Generalisation now in memory: when a later
   stage introduces a value an earlier admission never saw, ask what that admission
   was silently assuming about it.**

   Deferred honestly: an in-decode progress checkpoint would make cancellation
   genuinely responsive during a long decode, but it needs a codec API that reports
   progress. Recorded rather than faked — and the record states plainly that
   cancellation cannot interrupt a synchronous codec call, so `.decode` is the last
   free site.

   **Compression arc: 5 of 7 buildable rows done** (`002`, `007`, `009`, `010`,
   `013`).

   **Increment (ff): `ADR-0260`, compression increment (e). THE ARC'S BUILDABLE HALF
   IS COMPLETE.** `VOX-CMP-003` discharged, `VOX-CMP-008` discharged in `T` only.
   **1064 tests / 197 suites.**

   **`VOX-CMP-003`: the four shapes are one region plus a frozen classification.**
   Original source / slice / slab / brick are not four unrelated things — each is a
   region of a parent volume, so `CompressedScope` stores an `ImageRegion` (composed
   from Core, not reinvented) and **derives** the kind. Frozen order: covers-everything
   → `originalSource`; one axis of extent 1, rest full → `slice`; one partial axis,
   rest full → `slab`; else `brick`.

   **The clause order resolves a real ambiguity.** A volume whose slice axis has
   extent 1 is *simultaneously* the whole volume and a single plane — both true.
   Covering everything is the stronger statement so it wins, and tests pin both the
   flat-volume case and plane-of-a-taller-volume so it is precedence rather than a
   special case for extent 1.

   **Classification enumerated, not sampled**: all 8 regions of a `2x2x2` volume.
   It reaches `originalSource`/`slice`/`brick` but **NOT `slab`** — a partial axis of
   a two-deep volume always has extent 1 — and that is asserted rather than left as a
   silent gap, with a taller volume covering the fourth kind.

   **`VOX-CMP-008`: built the reuse, and recorded what cannot be verified.**
   `DecodeDestination` is caller-allocated, admitted before any fill, reusable across
   differently sized decodes with contents replaced not appended; partial fills,
   over-long fills and fill-before-prepare all refuse, and no refusal leaves partial
   contents. `prepare` clears, so a decode failing after preparation cannot expose the
   previous decode's samples.

   **But the row says "where the codec API permits it", and that qualifier is
   load-bearing.** No codec is linked, so whether one accepts a caller-provided
   destination is unanswerable — **and there is a precedent for the answer being no**:
   `ADR-0235` found DICOMKit returns an owned `Data` with no destination entry point,
   which made `ADR-0230` d10's direct-write model unimplementable. So **`008`'s `A`
   half is recorded as outstanding, not claimed** — the honest reading of a row whose
   own wording is conditional on a fact I cannot establish.

   # COMPRESSION ARC: BUILDABLE HALF COMPLETE — EVERYTHING LEFT IS OWNER-BLOCKED

   Discharged: `002`, `003`, `007`, `009`, `010`, `013`, and `008` (`T`).
   Blocked: `004`, `005`, `006`, `011`, `012`, `014`, `008` (`A`), plus the
   direct-dependency question. **The arc cannot advance without the owner
   reconciliation `ADR-0255` referred.**

   **Increment (gg): `ADR-0261`, the benchmark repetition method.**
   `VOXELIA-BEN-0001` revised to **version 0.2** with a real distribution, resolving
   the principal limitation version 0.1 named about itself.

   **The strategy requires percentiles (§42.1: min, median, p90, p95, p99, max), and
   percentile conventions differ — so this was a numeric boundary needing a frozen
   rule.** Frozen as **nearest-rank**: `rank = ceil(p x n / 100)` clamped to `[1, n]`,
   computed in **integer** arithmetic (a floating-point `ceil` would make boundary
   ranks depend on rounding), and the value is the `rank`-th smallest sample.

   **No interpolation, and that is the point: every reported figure is a measurement
   that actually occurred.** An interpolating convention reports a median lying
   *between* two observations — for latency that invites a reader to treat a
   synthesised number as observed. Also why mean/stddev were rejected: they need a
   frozen summation order (a real ALG + oracle) for statistics worse suited to skewed
   latency data than order statistics.

   **100 repetitions chosen so the percentiles are DISTINCT.** At `n = 9`,
   `ceil(0.90x9) = ceil(0.95x9) = ceil(0.99x9) = 9` — all three would equal the max
   and the report would show three identical numbers as three statistics. 3 warm-ups
   discarded.

   **Cold and warm reported separately** because they measure different things: only
   the first iteration of a fresh process reads uncached.

   | Release, warm-cache, 100 reps (s) | min | p50 | p90 | p95 | p99 | max |
   |---|---:|---:|---:|---:|---:|---:|
   | Total import | `1.492` | `1.515` | `1.610` | `1.646` | `1.678` | `1.688` |
   | Metadata scan | `0.089` | `0.091` | `0.097` | `0.098` | `0.104` | `0.133` |
   | Decode + transfer | `1.397` | `1.417` | `1.508` | `1.547` | `1.575` | `1.580` |

   Cold: **`1.829` s**. Warm spread: `0.196` s.

   **Three findings a single run could not produce:**
   1. **The import is COMPUTE-bound, not I/O-bound** — cold is only `1.21x` the warm
      median, and decode+transfer is `1.417` of `1.515` s (**94%**). Effort on faster
      file access would buy almost nothing. The earlier single-run figures gave no way
      to know this.
   2. **The metadata scan is the cache-sensitive stage and it is small** — `0.291` s
      cold vs `0.091` s warm is `3.2x`, far above the whole import's `1.21x`, but it is
      6% of the total. A whole-import figure alone hides both halves.
   3. **No retention leak across 104 sequential imports** — each allocates 449 MiB and
      peak stayed at `467 MiB` throughout. A retained volume would drive peak up in
      multiples. **Materially stronger evidence for §59.4 than `ADR-0253`'s
      single-import measurement**, which could only show one import did not duplicate.

   The third was a **by-product**: repetitions were added for a latency distribution
   and incidentally became a retention stress test.

   **Explicitly NOT resolved**: reference-hardware approval (§61) is still the
   prerequisite for formal performance acceptance, and the `voxelia.m4.ct.diagnostic`
   profile is still provisional. **A distribution makes a comparison possible; it does
   not make an unapproved threshold approved.** Power and thermal remain
   uninstrumented — deferred to approved hardware rather than added as uncalibrated
   noise.

   **Increment (hh): `ADR-0262`, the crosshair composition regression guard.**
   `ADR-0248`'s open migration step closed. **1067 tests / 198 suites.** No source
   changed.

   **The gap this fills is specific: `ADR-0248`'s real-data run is evidence the
   composition worked ONCE, and it cannot run in CI** because no repository test may
   read patient data. And the two halves' own unit tests pass **independently of
   whether the halves still meet** — so an axis-renumbering change that broke only the
   composition would have left both green. That is exactly the gap `ADR-0248` found by
   composing them for the first time.

   The fixture removes each way the test could pass while the code was wrong:
   **anisotropic `4x3x5`** (a cube cannot detect a transposed plane), **three distinct
   affine spacings** `world = (10+2i, 20+3j, 30+5k)` (equal spacings would hide a
   swapped axis), and a **non-zero origin** (would hide a dropped origin term). The
   three expected pixels are all distinct — axial `(2,1)`, coronal `(2,3)`, sagittal
   `(1,3)` in viewports `4x3`/`4x5`/`3x5` — which exercises `ADR-0244`'s axis
   renumbering.

   **`ADR-0248`'s composition contract is guarded, not restated.** A second test puts
   the crosshair outside the volume on the column axis and asserts the asymmetric
   outcome: axial and coronal report `outsideViewport` (both present the column) while
   the **sagittal view still reports a pixel** (it presents row and slice, so an
   out-of-range column cannot move its in-plane projection) — and the slice-index call
   refuses. A regression in either half now breaks a test.

   **Negative-tested rather than assumed.** The coronal expectation was deliberately
   transposed and the suite failed on both axes (`viewportX → 2 == 3`,
   `viewportY → 3 == 2`), then restored green. A passing test proves nothing about
   whether it *can* fail.

   **Increment (ii): `ADR-0263`, plan §59.3 fully assessed — plus a 9.2x performance
   finding that refines an accepted measurement.** No source changed.

   **Arithmetic correction to my own last entry**: the stress volume is **512 MiB**,
   not the "~1 GiB" I stated. `512x512x1024` at two bytes is `536,870,912` B exactly,
   only `1.14x` the real 449 MiB series. Wrong by a factor of two.

   **§59.3's six cases assessed**: the `512x512x1024` volume run here; **two credited
   to `ADR-0261`** (repeated dataset replacement, repeated open/close cycles — its 104
   sequential imports with unchanged peak are what those ask about, and I had not
   credited them); cancellation during import already covered by `ADR-0249`; two
   owner-gated on the interactive draw loop. "Substantially" not "fully" for the two
   credited, since both arguably want a *published* object released between cycles and
   `ADR-0261`'s loop published nothing — recorded rather than smoothed over.

   **Real data cannot supply the stress case, and that is itself a finding.** The
   corpus has one series with ≥1024 instances — **2,580** — and it is refused with
   `geometryRejected`. It assembles as a *single* series by identity, so not a grouping
   problem; its geometry is irregular at `exact`. **So §59.3's stress case cannot be
   sourced from real data until the geometry-tolerance gate is settled** — a
   consequence nobody had attached to that gate.

   Run synthetically and labelled so: `512x512x1024` **int16**, `representable`, peak
   `523 MiB` = **`1.02x`**. Footprint property holds at scale, and it is the **first
   end-to-end exercise of SIGNED samples** (the owner's scanner is `uint16`, so `int16`
   had only ever seen fixtures).

   **The finding: the caller's byte-collection type costs `9.2x`.** The synthetic run
   took `13.397` s for 512 MiB **with no file I/O**, against `1.841` s for 449 MiB read
   from disk. Seven times slower per byte than a run that reads files is not plausible,
   so I investigated instead of reporting it. `CTImportSession` is generic over
   `Bytes: Collection<UInt8>`; the DICOM path supplies `Data`, the synthetic run
   supplied `ContiguousArray`. Same import, only that type differing:

   | Byte collection | Elapsed |
   |---|---:|
   | `ContiguousArray<UInt8>` | `13.397` s |
   | `Data` | **`1.453` s** |

   **This refines `ADR-0235`.** That record measured the element-wise transfer at "about
   120 MiB/s" and framed the options as an upstream entry point or a governed safety
   exception — attributing the cost to element-wise writing. With `Data` the *same loop*
   reaches **`352 MiB/s`**, nearly 3x that figure, so a large share of the cost is
   **generic non-specialisation**, not the copy. Refined, not contradicted: `ADR-0235`
   was correct for the path it measured.

   **No fix applied, for a real reason**: the contiguous fast path yields an
   `UnsafeBufferPointer` that `-strict-memory-safety` diagnoses and the safety policy
   forbids. The available safe remedy — making the write `@inlinable` so the loop
   specialises at the call site — changes a public API's inlining contract and deserves
   its own record, not a footnote in a stress test.

   **Increment (jj): `ADR-0264` — a `30x` transfer speedup from one line, and TWO of my
   own records corrected.** 1067 tests / 198 suites.

   **`ADR-0263`'s proposed remedy was not just inferior, it was UNAVAILABLE.**
   `@inlinable` bodies may only touch public or `@usableFromInline` members, and
   `write` mutates `bytes` and `writtenSlices` — both privately set. It would have
   forced this type to expose the state its invariants rest on.

   **The actual fix is one line**: `bytes.replaceSubrange(start..<end, with: frameBytes)`
   instead of the hand-written byte loop. No pointer API, no `@inlinable`, no
   encapsulation change, no ABI commitment — entirely within the safety policy.

   | Stage (real 899-frame series, p50) | Before | After | Gain |
   |---|---:|---:|---:|
   | Total import | `1.515` s | **`0.214` s** | **`7.1x`** |
   | Decode + transfer | `1.417` s | **`0.123` s** | **`11.5x`** |

   Transfer throughput **`3,650 MiB/s`** vs the `120 MiB/s` `ADR-0235` recorded —
   **`30.4x`**. On the synthetic stress volume: `ContiguousArray` `13.397 s → 0.069 s`
   (**194x**), `Data` `1.453 s → 0.017 s` (**85x**). **The `9.2x` type-dependence is
   gone** — specialisation now happens inside the stdlib instead of failing to happen
   here.

   **Correctness verified BEFORE the improvement was claimed**, because a result this
   large is a reason for suspicion: 25 targeted tests, then 1067 full-suite, then the
   definitive check re-run on real data — **899 of 899 slices byte-exact against
   DICOMKit's own frame bytes, 0 mismatched**. The `VOX-VS1-014` inspections reproduce
   exactly (centre `8232`→`40.0` HU, corner `0`→`-8192.0` HU, mid-left
   `7237`→`-955.0` HU).

   **`ADR-0235` corrected.** It stated the options for the `120 MiB/s` copy were "an
   upstream DICOMKit decode-into-destination entry point or a governed exception to the
   safety policy". **Both were unnecessary.** It reasoned carefully about the two
   options it had in view and never asked whether the standard library already solved
   it. **`ADR-0261` narrowed**: its compute-bound conclusion was true of the code it
   measured, and that code was compute-bound for an avoidable reason — the cold/warm
   ratio is now `1.95x`, not `1.21x`.

   **The generalisable lesson**: before accepting a performance cost as inherent to a
   safety constraint, check whether the stdlib has a specialised operation for the same
   work. A hand-written loop in a generic context is slow *because* it cannot
   specialise; the stdlib's equivalent already has.

   `VOXELIA-BEN-0001` now carries a prominent superseded notice on its latency figures
   and must be re-measured before review — left in place rather than silently edited so
   the improvement stays auditable.

   **Increment (kk): `ADR-0265` — re-measured the benchmark, and found a
   methodological error in THREE of my own records.** `VOXELIA-BEN-0001` at **v0.3**.

   **"Cold page cache" was an assumption I never measured.** `ADR-0261` reported "cold
   import, page cache empty: 1.829 s" and built a finding on the cold/warm ratio;
   `ADR-0263` and `ADR-0264` reasoned from the same kind of figure. **The harness ran
   the import first in a fresh process and called that cold — but the OS page cache
   persists across process launches.** The label described an intent, not a state.

   Caught by an inconsistency, not review: two nominally identical "cold" readings came
   out `0.437` s and `0.248` s. Five consecutive fresh processes settled it —
   `0.284/0.253/0.255/0.255/0.255` s, stable because the files stayed warm throughout.
   The `0.437` s reading came from a moment when other work had evicted them and is
   **not reproducible on demand** (dropping the cache needs elevated privileges I will
   not use on the owner's machine for a benchmark).

   **Withdrawn**: `ADR-0261`'s `1.21x` and `ADR-0264`'s `1.95x` cold/warm ratios, and
   `ADR-0261`'s "the import is compute-bound, not I/O-bound" **as stated** — its
   evidence was the ratio. A ratio with an unknown denominator is not a weaker finding,
   it is not a finding, so I withdrew rather than caveated. And I did **not** retro-fit
   the separate cache-independent argument that would have supported the conclusion:
   citing an argument I did not make would be worse than withdrawing.

   **Survives, explicitly**: the no-leak result over 104 imports (a memory observation,
   cache-independent), the `30x` transfer improvement (warm-to-warm), and the footprint
   ratio.

   **Re-measured baseline** (release, 100 reps, nearest-rank):

   | | min | p50 | p99 | max |
   |---|---:|---:|---:|---:|
   | Total import | `0.213` | **`0.216`** | `0.236` | `0.238` |
   | Metadata scan | `0.086` | `0.087` | `0.102` | `0.107` |
   | Decode + transfer | `0.122` | `0.124` | `0.135` | `0.147` |

   §63 stages (first import, fresh process): complete volume `0.248` s release /
   `0.802` debug; first axial `0.342`; three-view steady state `0.736`. Footprint
   `464 MiB` = `1.03x`. Throughput ≈ `2,080 MiB/s` import, ≈ `3,620 MiB/s` transfer.

   **The profile changed shape, not just scale**: metadata scan is now **40%** of the
   median (was 6%) and transfer **57%** (was 94%). Further transfer work would buy much
   less than the first `11.5x` did. Spread tightened `0.196 s → 0.025 s`.

   Also fixed two harness artefacts rather than reporting them: the staged stage-timing
   run had been executing *after* the cold import (so its stages were warm), and the
   footprint mode was holding two volumes at once (`923 MiB`, which is not a leak).

   **Increment (ll): OWNER RELEASED THREE GATES — `ADR-0266` + `ADR-0267`.**

   Owner replied to the eight enumerated questions: *"yes proceed with 1, 2 amd 3"* —
   the **interactive draw loop proceeds**, the **six blocked compression rows are
   authorised** (including `VOX-CMP-011`'s adversarial codec testing, which reverses
   the earlier no-dependency-testing instruction), and a **codec may be declared
   directly**. `ADR-0266` records the authorisation verbatim and states the reading of
   #2 explicitly, since it reverses a standing instruction.

   **`ADR-0267` executes the supply-chain step**: `J2KSwift` pinned exact at `11.0.2`
   (already resolved, so no new code enters the build), linked into
   `VoxeliaCompression` as `J2KCodec` + `J2K3D`. **`J2KMetal` REFUSED and barred by
   name** — the codec ships a Metal product, and linking it would put a Metal surface
   inside the module `VOX-CMP-007` exists to keep away from textures. Found by reading
   the product list before declaring.

   **Gate widened explicitly, then negative-tested** — a gate just relaxed is exactly
   the one to re-check. All three failure modes still fire: a third unapproved package,
   version drift on the new pin, and a core target linking the codec.

   **The finding: `ADR-0259`'s decode session could NOT have hosted a real codec.**
   `JP3DDecoder.decode(_:)` is `async throws`; my session took a **synchronous**
   closure. The shape was settled by tests that supplied bytes synchronously because no
   codec existed. **This is the same failure `ADR-0235` recorded against `ADR-0230`
   d10 — a contract chosen before reading the dependency's API — and the project has
   now made it twice.** Corrected: closure and method are `async`.

   A smaller self-correction inside that: my first source note claimed "no existing
   caller changed". Wrong — the test call sites all needed `await`. Fixed, because a
   comment overstating compatibility is exactly what a later reader trusts.

   1067 tests / 198 suites; licence policy now reports 2 declared dependencies.

   **Increment (mm): `ADR-0268`, the J2KSwift adapter.** 1079 tests / 199 suites after
   a clean rebuild. **Applied the rule from last increment — read the codec's API
   BEFORE designing — and four of five decisions came straight from what it found**,
   none obvious from the requirement text.

   **The codec offers geometry.** `J2KVolume` carries `spacingX/Y/Z` and
   `originX/Y/Z`; `J2KVolumeMetadata` carries `patientID`, `modality`, `windowCenter`,
   `sliceThickness`. **The adapter reads NONE of it.** Voxelia's patient-space mapping
   comes from DICOM through `CTAffineVolumeBuilder` with an oracle; taking spacing from
   a codestream would create a second source of truth for the most safety-critical
   mapping in the system. `ADR-0255` already had the rule — finding the codec *offers*
   the thing is what makes it load-bearing rather than theoretical. **The convenience
   is the hazard.**

   Tested by supplying **deliberately non-zero** spacing/origin in the fixture: zeros
   could not distinguish "ignored them" from "read zeros".

   **`tolerateErrors` defaults to `true`.** The decoder's out-of-the-box behaviour
   produces output from a codestream it could not fully parse — wrong for a diagnostic
   viewer. Set to `false` explicitly, other values restated rather than defaulted, and
   a test asserts BOTH that the codec's default is `true` and the adapter's is `false`,
   so silent adoption fails.

   **`JP3DDecoderResult.isPartial` is a signal the arc's other checks CANNOT see** —
   `ADR-0258`'s validator compares byte counts and shape, and a partial decode can be
   exactly the right length with wrong data. Third gap of this kind in the arc
   (`ADR-0259` found the second). Refused, along with tile shortfall and any warnings.

   Also refused: **subsampled components** (their data does not correspond to the
   volume's extents), **bit depths >16** (J2K admits 1–38; a 24-bit sample narrowed to
   16 is a quantitative error, not a formatting detail), signedness disagreements, and
   self-inconsistent byte counts. The **layout is checked, not assumed** — expected
   length derived from the component's own dimensions and bit depth.

   **A testability constraint shaped the design**: `JP3DDecoderResult` has no public
   initialiser, so an adapter accepting only it would be **untestable without real
   codestreams**. Split into a thin unwrapping entry point and an internal core taking
   plain values — 12 tests, every refusal exercised, no codestream needed. Recorded as
   a pattern: when a dependency's result type cannot be constructed by a consumer, the
   consumer's logic should not take it directly.

   **Increment (nn): `ADR-0269`, `VOX-CMP-004` and `005` evaluated on the real
   volume.** **I was wrong last increment** to say this needed test data from the
   owner — `J2KSwift` ships `JP3DEncoder`, so the right input was Voxelia's own 449 MiB
   CT volume, which is what the rows actually ask about.

   | Mode | Encoded | Ratio | Encode | Decode | Byte-exact |
   |---|---:|---:|---:|---:|:---:|
   | JP3D lossless | 195 MiB | `2.30:1` | `15.47` s | `9.93` s | **yes** |
   | HTJ2K lossless | 203 MiB | `2.21:1` | `3.45` s | `6.23` s | **yes** |

   `isLossless` **verified by byte comparison, not trusted as a flag**. `ADR-0268`'s
   adapter admitted both — its first exposure to real codec output.

   **`VOX-CMP-004` returns NO, on the comparison that matters:**

   ```
   re-import from original DICOM (warm p50):  0.216 s
   decode from HTJ2K cache:                   6.233 s   29x slower
   decode from JP3D cache:                    9.934 s   46x slower
   ```

   **A cache 29–46x slower than re-reading the source is not a cache.** It buys 55–57%
   disk for an order of magnitude and a half of read latency. Evaluated permits a
   negative answer, and reporting the flattering half (2.3:1 is a fine ratio!) would
   have meant ignoring the comparison the row is about. **Conditions that would flip
   it are recorded** — compressed sources, slow/remote storage, volumes that do not fit
   in memory (where `decode(_:region:)` is a different proposition).

   **`VOX-CMP-005` returns YES** independently: HTJ2K beats JP3D by **`4.5x` encode**
   and `1.6x` decode for 4% ratio. Where a compressed lossless representation is wanted
   at all, HTJ2K is the mode.

   **Checked that the evaluation was not under-selling JP3D.** `levelsZ` defaults to
   `1`, which would disable the inter-slice decorrelation a 3D codec exists for.
   Re-running at `levelsZ: 3` gave **byte-identical encoded sizes** — so the parameter
   is not changing the encode. Unimplemented, overridden by `zDeltaMode: .auto`, or
   genuinely useless here **cannot be distinguished from outside**, so it is referred to
   `VOX-CMP-006` rather than guessed.

   **Timings stated as single measurements** with ~2x observed run-to-run variance
   (`ADR-0261`'s lesson applied to my own numbers): ratios are exact byte counts, the
   `4.5x` encode gap survives the noise, the `1.6x` decode gap is directional, and the
   29–46x cache gap is far beyond it. The 100-repetition method is recorded as
   available rather than performed — half an hour of encoding for a conclusion the
   spread already supports.

   **Compression arc: `002`, `003`, `004`, `005`, `007`, `009`, `010`, `013` and `008`
   (`T`) discharged.** Remaining: `006`, `011`, `012`, `014`, `008`'s `A`.

   **Increment (oo): `ADR-0270`, `VOX-CMP-012`'s `T` discharged.** 1086 tests / 200
   suites. `R` left to the owner, per `ADR-0254`'s handling of `VOX-VS1-021`.

   The row is **conditional** ("when caches *are generated*") and Voxelia generates
   none — `ADR-0269` just found JP3D caching slower than re-importing. "Vacuously
   satisfied" was the tempting answer and the wrong one: **a safety constraint on a
   capability is worth making enforceable BEFORE the capability exists.**

   **The finding: the accepted identity model permits exactly what this row forbids.**
   `DataIdentity`'s admission is an **OR** — `contentID || sourceIdentities ||
   derivation` — so an identity with a derivation and **no source identities at all**
   is perfectly legal. A cache published that way records which operation made it while
   losing every trace of which patient instances it came from. A test **constructs that
   detached identity successfully** and then shows only the new rule refusing it, so
   the gap is demonstrated rather than asserted.

   The model is not wrong — it admits many objects with no DICOM ancestry, and
   tightening Core would refuse legitimate ones. The obligation is contextual, so the
   check is too: enforced at the compression boundary.

   `CachePreservationRule` requires a cache to carry **every** source identity the
   original had (**superset permitted** — one cache may span several series;
   **subset refused** — it has dropped instances), to **declare a derivation naming an
   input**, and to **not claim the original's object identifier** (which would be
   deletion arriving as an update). The rule inspects and never mutates — tested,
   because preservation that altered the preserved thing would be self-defeating.

   Two fixture attempts were refused by the accepted model before the tests ran, both
   recorded: `DerivationInputRole` is a validated string struct not an enum, and
   `parameterDigest` needs the **operation-parameters** projection (a sample-bytes
   identity gets `unsupportedParameterProjection`). The model keeping claim kinds
   distinct.

   **Compression discharged**: `002`, `003`, `004`, `005`, `007`, `009`, `010`,
   `012`(`T`), `013`, `008`(`T`). **Remaining**: `006`, `011`, `014`, plus `008`(`A`)
   and `012`(`R`).

   **Increment (pp): `ADR-0271` + `VOXELIA-BEN-0002`, `VOX-CMP-014` discharged.** All
   six required metrics reported.

   **The finding: random access qualifies `ADR-0269`'s cache verdict without
   overturning it.** That record measured full decode at 29–46x slower than
   re-importing, and those numbers stand. But a viewer wants **planes**, not volumes:

   | Request | Time | Voxels | Speedup |
   |---|---:|---:|---:|
   | **One axial plane** | **`0.014` s** | 0.4% | **`115.6x`** |
   | 128-cube brick | `0.247` s | 3.1% | `6.6x` |
   | 64-slice slab | `0.314` s | 25.0% | `5.2x` |

   **14 ms for one axial plane from a store holding 55% less data.** So the same
   artefact is a poor whole-volume cache and a good random-access store — both true of
   the same measurements. `ADR-0269` explicitly named this as the condition that would
   change its conclusion, and the condition holds. **Qualified, not corrected.**

   **Tile geometry — not voxel count — sets random-access cost.** A plane at 0.4% of
   voxels costs 4 of 64 tiles; a brick at 3.1% costs 8. The naive proportional model is
   wrong by an order of magnitude, so it is pre-emptively corrected for whichever
   increment wires `VOX-CMP-003`'s brick scopes to region decode.

   **Memory measured in a CLEAN process** — the combined run peaked at `1809 MiB`
   holding four encodes and their decodes, real and meaningless (same discipline as
   `ADR-0265`'s cold-cache withdrawal). Clean: encode costs ≈**4.3x the volume** in
   working set, full decode adds ≈2.1x, **region decode adds nothing measurable**.

   Lossy modes deliberately **not** benchmarked: no requirement asks for lossy
   diagnostic data, and measuring it would invite reading the numbers as endorsement.

   One harness trap worth remembering: in top-level `main.swift`, referencing a global
   declared **later** compiles fine and yields uninitialised state — it produced a
   `0x0x0` volume before I moved the block.

   **Compression discharged**: `002`, `003`, `004`, `005`, `007`, `009`, `010`,
   `012`(`T`), `013`, `014`, `008`(`T`). **Remaining: `006` and `011`**, plus
   `008`(`A`) and `012`(`R`).

   **Next: `VOX-CMP-006`** — actual codec output and interoperability documented, which
   is also where `ADR-0269`'s `levelsZ` question belongs and where the shipped
   third-party `ct512_*.j2k` fixtures become the right input. Then **`011`'s adversarial
   work last**.

   **Increment (qq): `ADR-0272`, `VOX-CMP-006`'s `I` and `T` discharged.** 1101 tests /
   201 suites. `R` left to the owner. This is the increment where the compression arc's
   headline result stopped being about speed.

   **What the output actually is.** Both modes emit a **RAW codestream** (no JP2 boxes)
   with a standards-shaped main header — `SOC → SIZ → COD → QCD → SOT` for JP3D, plus
   **`CAP` + `CPF`** for HTJ2K, so HTJ2K *does* signal itself correctly. But every tile
   payload opens with `4A 33 44 53` = **`J3DS`**, a proprietary slice-stack container
   holding **2D** per-slice codestreams. The library says so itself: the envelope
   "remains a standards-shaped JP3D wrapper". **It is a toolkit-native format wearing
   JPEG 2000 marker clothing.**

   **Interoperability is path-dependent, and the split matters.** Against the two
   third-party codestreams J2KSwift ships (`blackbuck-5.j2k`, `ct512_L4.j2k`):
   `JP3DDecoder` **refused both** ("missing 'J3DS' magic" — it also disowns its own
   older output), while the 2D `J2KDecoder` **decoded both**. A blanket "J2KSwift is not
   interoperable" would be false.

   **THE FINDING — outbound failure is silent, not loud.** Feeding Voxelia-encoded JP3D
   and HTJ2K output to the standards-shaped 2D `J2KDecoder`: it **succeeds**. No error.
   Reports `512x512`, one component — **one plane for a sixteen-slice volume**, because a
   2D `SIZ` cannot carry depth. Every sample is the constant `0x0080`; the returned plane
   holds two distinct byte values, the source holds many. `SIZ` is **self-consistent**,
   which is exactly why nothing errors. Reproduced at `64x64x4`. **Two independent silent
   failures in one artefact: depth dropped, pixels unrelated to the source.** Honest
   qualification recorded: *this* corruption is a uniform frame a human would likely
   notice — a property of this pair, not a guarantee, and not to be generalised.

   **`levelsZ` answered, and my own claim corrected.** Exactly **one byte of 3,248,558**
   differs between `levelsZ` 1 and 3 — offset 64, the `COD` Z-decomposition field,
   holding literally `1` or `3`. Coded data untouched. The library explains it: the 3D
   DWT "and JP3DRateController are skipped" and the recorded levels are "**advisory
   only**"; Z correlation comes only from opportunistic per-slice residuals under
   `zDeltaMode`. **So a codestream declares a decomposition its payload lacks** — a
   second, independent way this output misleads a reader.

   **The correction:** `VOXELIA-BEN-0002` v0.1 said the two settings produced
   "byte-identical **output**". The harness printed `count / 1_048_576` — **integer
   mebibytes** — so it established equal *rounded sizes*. Fixed in v0.2. `ADR-0269`, the
   `VOX-VS1-001` evidence doc and this ledger all say "byte-identical encoded **sizes**",
   which the exact figures confirm; they stand unedited. **Lesson: a print format is part
   of a measurement's evidence.**

   **What got built, because documenting a hazard is the weaker half.** `ADR-0257` made
   `VOX-CMP-013` structural for the *name*; the gap was the *bytes*. A caller could label
   a `J3DS` codestream `1.2.840.10008.1.2.4.90` — a **genuine, well-formed** JPEG 2000
   Lossless UID — and nothing refused it. `ToolkitNativeCodestream.inspect` +
   `CodestreamLabellingRule` now refuse that pairing; a test builds exactly that
   representation, shows the name rule admitting it, and shows only the new rule
   refusing it.

   **Parsed, never scanned — on evidence.** In one 988-byte codestream `FF 93` appeared
   at **five** offsets and only one was a marker; `J3DS` appeared once, two bytes after
   the real `SOD`. The test plants decoy magic *and* a decoy `SOD` inside a `COM` body,
   then **asserts both naive implementations would get it wrong** — a discriminator, not
   a restatement. (Verified out-of-band first: both naive forms do return the wrong
   verdict on those exact bytes.)

   **One refusal only, and the near-miss is worth remembering.** My first instinct was
   "unparseable ⟹ refuse", which is wrong: JPEG-LS, RLE and uncompressed syntaxes are
   standard and are **not** JPEG 2000, so that rule would reject legitimate objects. The
   refusal is narrowed to the measured hazard. Caught by thinking it through before
   writing, not after.

   **Two observations for the owner (who owns J2KSwift), neither fixable from here**:
   the `COD` marker declares Z levels the payload lacks; and the volumetric output is
   accepted by conformant 2D decoders which then return wrong pixels — emitting something
   they *reject* would turn a silent misread into a clean refusal.

   **Compression discharged**: `002`, `003`, `004`, `005`, `006`(`I,T`), `007`, `009`,
   `010`, `012`(`T`), `013`, `014`, `008`(`T`). **Remaining: `011` only**, plus
   `008`(`A`) and `006`/`012`(`R`).

   **Next: `VOX-CMP-011`** — bounded failure on malformed/adversarial codestreams, owner
   -authorised, deliberately last so the adapter is settled before it is attacked. Its
   first target is now this increment's own marker walk. Defects found must be **fixed**,
   not merely reported.

   **Increment (rr): `ADR-0273`, `VOX-CMP-011` discharged. THE M5 COMPRESSION ARC'S
   REQUIREMENT ROWS ARE ALL DISCHARGED.** 1116 tests / 202 suites.

   **Method**: a 41-case corpus from a real 988-byte JP3D encode of a `64x64x4` volume —
   truncations, all-zero, three `SIZ` dimension attacks, seven `J3DS` field attacks, a
   `COD` attack, garbage payload, and a deterministic byte-inversion sweep at stride 7.
   **Each case in its own process** with an external RSS watchdog at 2 GiB and 25 s,
   because the honest way to measure an unbounded allocation is to let it happen
   somewhere it cannot hurt the host. (`RLIMIT_AS` is not enforced on macOS — the harness
   tries it and the parent does the real bounding.)

   **Fair finding first: the `J3DS` slice-stack layer is well hardened.** Every attack on
   its slice count, tile dims, component count, bit depth, per-slice lengths and magic
   threw a clean specific error, as did every truncation and the garbage payload. 28 of
   41 threw cleanly, 11 decoded.

   **THREE DEFECTS, all in the standards-shaped `SIZ` envelope one layer out**, whose
   dimensions are read as 32-bit values and used with no upper bound:
   - `Xsiz`/`Ysiz` = `0xFFFF` → **process killed**, past 2,163 MiB before the watchdog;
     `SIGKILL` unwatched. ~32 GiB implied from 988 bytes.
   - `Xsiz`/`Ysiz` = `0x7FFFFFFF` → **`SIGTRAP`** (exit 133) immediately, zero allocation
     — the product overflows Int64 and traps.
   - **A SINGLE BIT FLIP** on one `Ysiz` byte → **silent success**: decoded
     `64x65344x4`, 33,456,128 bytes, **self-consistent**. A thousandfold amplification
     that reports success and that no internal consistency check can catch.

   **The fix: `CodestreamHeaderBudget`** — a bounded `SIZ` parse computing the implied
   decoded byte count with **checked** multiplication (`nil` on overflow, which is the
   entire difference between finding 2's trap and a refusal), wired **inside
   `admitDestination`** so no caller can forget it. Also bounds `Ssiz` to the standard's
   **1...38** — the field encodes to 128, a flip declared **113**, and the budget alone
   would only catch that under a tight ceiling; bounding the field refuses it at
   `Int.max`.

   **Verified binding, with two independent cross-checks**: the gate computes exactly
   **32,768** for the untouched codestream (the uncompressed volume to the byte) and
   exactly **33,456,128** for the bit-flipped one — *the same count the decoder itself
   returned*. Two separately written parsers agreeing on what the corrupt header means.
   Across the corpus: 7 refused, 34 admitted, and the 34 are precisely the cases the
   decoder already handled boundedly. **The two layers complement, not duplicate.**

   **A DEFECT IN MY OWN FIRST DRAFT, and the lesson.** The first parser counted `SIZ`
   offsets from the **marker** while addressing them from the **length field** two bytes
   earlier — it read `Ysiz` where `Xsiz` sits and **refused every valid codestream**. All
   three attacks were still refused, for entirely the wrong reason, so a suite checking
   only "the attacks are refused" would have passed and shipped a gate rejecting all real
   data. **Only requiring the VALID case to be ADMITTED caught it.** I had confirmed those
   offsets empirically an hour earlier and still transcribed them against the wrong
   origin. **Negative tests cannot validate a gate; the positive case is load-bearing.**

   **`A` half discharged as bounds, not assurances**: every path from untrusted bytes to
   an allocation or index tabulated with its bound. Memory safety is **structural** —
   `VoxeliaCompression` has **zero** pointer APIs and **zero** unchecked arithmetic
   operators (`&*`, `&+`, `&-`), verified by search and held by `check_swift_safety.py`.
   `ADR-0272`'s marker walk re-tested under the corpus: **41 of 41 returned a verdict**,
   no trap, no hang.

   **M5 compression rows: `002`, `003`, `004`, `005`, `006`(`I,T`), `007`, `008`(`T`),
   `009`, `010`, `011`, `012`(`T`), `013`, `014` — ALL DISCHARGED.**

   **Remaining on the arc**: `008`'s `A` half (codec API analysis of caller-provided
   destinations), plus owner Reviews for `006` and `012`.

   **Three dependency defects recorded for the owner** (owns J2KSwift), none fixable from
   here, all now *contained* by Voxelia refusing them pre-decode — but live for any other
   consumer of that library. With `ADR-0272`'s two observations that is **five** J2KSwift
   items on the owner's desk.

   **Next**: `008`'s `A` half, then the interactive draw-loop arc, which needs its own
   architectural record before any code.

   **Increment (ss): `ADR-0274`, `VOX-CMP-008`'s `A` discharged. EVERY M5 COMPRESSION ROW
   IS NOW DISCHARGED IN BOTH HALVES.** No code changed; 1116 tests / 202 suites unchanged.

   `ADR-0260` decision 9 deferred this honestly — "whether any codec accepts a
   caller-provided destination is not verified" — because no codec was linked then.
   `J2KSwift 11.0.2` is linked now, so it is answerable by reading the API.

   **The answer is no.** **22 public decode entry points** in the reachable closure (14
   `J2KCodec`, 8 `J2K3D`; zero in `J2KCore`/`J2KCodecNEON`/`J2KMetal`/`CompressionFamily`).
   Every one allocates its own result. Four independent checks: no destination parameter in
   a destination role; **no public `inout` anywhere in the package**; `JP3DDecoderResult`
   has `let` storage and **no public init** so a caller cannot even preallocate the
   container; and `J2KImageBuffer` — mutable, with `withUnsafeMutableBytes`, looking exactly
   like the intended reuse type — is **referenced nowhere outside its own file**.

   **Two scoping corrections to my own first pass.** `J2KFileFormat` is **not** in the
   closure, so `decodeAnyFormat`/`decodeFile` are unavailable and an earlier count was
   over-broad by two. And `J2KMetal` **is** in the closure, transitively via `J2KCodec`'s
   target deps — `check_prohibited_imports.py` governs *importing* it, not linking it, and
   those are different facts.

   **A method lesson**: a name-based search for a buffer parameter matched
   `decode(sampleBuffer:)` — an **input** buffer. Searching by parameter *name* finds
   inputs; enumeration must go by parameter **role**. My first single-line pattern said
   zero matches and the second said one; the discrepancy is what forced the check, and the
   match was spurious. Right answer both times, reliably only the second time.

   **THE COST OF THE GAP, MEASURED — and it inverts the natural expectation.** The
   unavoidable `ContiguousArray(Data)` copy in `J2KVolumeAdapter` runs at **5.3–12.5
   GiB/s**: 449 MiB in **0.035 s = 0.6% of the 6.23 s HTJ2K decode**. But peak resident
   rises by **exactly the volume, every time** (32.1/64.0/128.0/256.0 MiB at those sizes).
   **The missing capability costs memory, not time.** Specifically NOT the same problem
   `ADR-0264` fixed: that 30× win came from replacing a hand-written byte loop with a
   stdlib range replacement, whereas this copy is *already* the stdlib path at memory
   bandwidth. **There is no time to recover here — only an allocation.**

   **Both declared dependencies allocate their outputs.** `ADR-0235` found DICOMKit's
   `pixelData()`/`frameData(at:)` return owned `Data` with no caller-destination entry
   point. Two for two — assume a dependency allocates until its API is read.

   **Option recorded, deliberately NOT taken**: making `DecodedSamples.bytes` a `Data`
   would retain the codec's buffer under COW and recover the whole duplicate **without**
   any codec change — but it puts Foundation in `VoxeliaCompression`'s public API
   (`ADR-0256`'s boundary question) and changes a type accepted by `ADR-0259`. Needs its
   own record; recorded with its measured benefit so it is available, not rediscovered.

   **M5 compression: `002`, `003`, `004`, `005`, `006`(`I,T`), `007`, `008`, `009`, `010`,
   `011`, `012`(`T`), `013`, `014` — ALL DISCHARGED, BOTH HALVES. No implementation work
   remains on the arc.**

   **Only remaining compression items: the two owner Reviews** (`006`, `012`).

   **Next: the interactive draw-loop arc**, which needs its own architectural record
   before any code — target shape (the package is library-only; `VoxeliaInteraction`
   prohibits SwiftUI/AppKit/UIKit/MetalKit), platform surface, `RenderGeneration` wiring
   (ending `ADR-0122` d3's deferral), and what evidence discharges a Demonstration half.
   Plan **§34 "Interactive output"** names **16** features for the M4 macOS reference
   application, which is explicitly "a reference integration, not the future DICOM
   Workstation user interface". (Corrected: a note carried through several increments
   cited "§65, 17 features". §65 is "Benchmark scenarios"; the count is 16. Checked
   against the plan rather than repeated.)

   **Increment (tt): `ADR-0275` opens the interactive draw-loop arc.** No code; 1116 tests
   / 202 suites unchanged. This supplies the architecture `ADR-0122` d3 explicitly waited
   on — its deferral is visible in the source, since `RenderGeneration` has **no product
   callers**, only its own file, a DocC line and its own tests.

   **THE FINDING: the arc is not one blocked thing.** It has been carried as a single item
   gated on an application that does not exist. Reading each row against *what actually
   gates it* splits it three ways:
   - **Unblocked, no application, no owner** — `VOX-INT-007` (`T`), `VOX-R2D-014` (`T`),
     `VOX-VS1-016` (`T`), and `VOX-INT-008`'s `T`. **Three P0 rows, free.**
     `R2D-014`/`VS1-016` say off-screen and interactive output share *the same presentation
     semantics* — a statement about one path serving two callers, established by having one
     path and testing it, **not by drawing anything**.
   - **Needs a host** — only `VOX-INT-008`'s `D` and `VOX-INT-010`'s `D`.
   - **Owner-gated regardless** — `VOX-PER-002/003/005` each name "reference workstation
     hardware". **No amount of work here moves them**, and saying so prevents the arc
     being reported as more complete than it is.

   **A sixth owner decision raised, not pre-empted**: where a reference application lives.
   The package is **library-only** (no executable target) and `VoxeliaInteraction` is
   forbidden `SwiftUI`/`AppKit`/`UIKit`/`RealityKit`/`MetalKit` — that prohibition *is*
   `VOX-INT-001`, a P0 row. So: a new executable target (changes the package shape and a P0
   gate), a separate repository (creates one to own), or no application (narrows what
   Demonstration means for two rows). **All three are the owner's call**; I proceed with
   everything that does not depend on the answer.

   **Deliberately NOT taken**: discharging both `D` halves by declaring a headless
   demonstration sufficient. It is a defensible reading — instrumented latency under
   background load beats watching a window — but narrowing two P0/P1 rows to avoid an owner
   question is exactly the quiet scope reduction this project refuses. Offered to the owner
   as an option instead.

   **Also frozen**: no performance threshold will be claimed anywhere in this arc. Frame
   telemetry may be *produced* (§34 lists it), but a produced number is not an acceptance,
   and there is no approved hardware to accept against — same discipline as BEN-0001/0002.
   And `VoxeliaInteraction`'s import prohibitions are **not** relaxed by this record
   whatever the owner decides; if an executable target arrives, the permission belongs to
   *that target*.

   Two of §34's sixteen features are already-built vocabulary awaiting a caller — **current
   generation** (`ADR-0122`) and **linked crosshair** (`ViewportSyncGroup`) — more evidence
   the library tier is the right start.

   **Next: `VOX-INT-007`'s presentation wiring**, with its own record and its own frozen
   staleness rule, ending `ADR-0122` d3's deferral and giving `RenderGeneration` its first
   product caller. Then the shared presentation path, then `008`'s `T`.

   **Owner decisions now SIX**: the new application-location question plus report approval,
   reference hardware, the tolerance profile, the geometry tolerance rule, and the two
   `LICENSE` files — alongside `VOX-CMP-006`/`012` Reviews and five `J2KSwift` items.

   **Increment (uu): `ADR-0276`, `VOX-INT-007`'s `T` discharged. `ADR-0122` d3's DEFERRAL
   IS ENDED** — `RenderGeneration` has a product caller for the first time. 1124 tests /
   203 suites (was 1116/202).

   **THE FINDING: the rule is stronger than the requirement's wording.**
   `RenderGeneration`'s init is **internal**, so the only source of a stamp is
   `advance()` — therefore `stamp <= current` always, and with `ADR-0122`'s strict
   comparison **`!isStale` holds exactly when `stamp == current`**. The presenter admits
   only frames rendered for the *newest* scene. That falls out of the accepted vocabulary
   rather than being chosen here.

   **And it forces a decision the requirement doesn't make**: if generations are minted
   faster than frames complete, **nothing is ever presented**. A host minting one
   generation per input event during a drag would render continuously and display nothing.

   **The frozen boundary: generations are minted per COMMITTED SCENE CHANGE, never per
   input event.** Hosts coalesce gesture streams into scene commits; the counter orders
   scene *versions*, which is what `ADR-0122` said it was for when it rejected reusing the
   frame-scheduler index. **A test demonstrates the starvation directly** — 16 generations
   minted before any frame completes, 15 dropped, only the newest survives — so a host
   author meets the constraint in the suite rather than against a frozen viewport.

   **Structural, not remembered**: content is carried *inside* `.presented(Content)`, so a
   host cannot draw what it never receives (`ADR-0259`'s shape). And the presenter **holds
   the counter** rather than taking `current` per call, so the live comparison is the only
   available one — same reasoning as putting the codestream budget *inside*
   `admitDestination` in `ADR-0273`.

   **Generation zero is presentable** — the counter starts at 0 and `advance()` returns 1,
   so a first paint must not be dropped. Tested, because an off-by-one here would blank the
   viewport until the user touched something.

   **Rejected and worth recording**: making `RenderGeneration.init` public "for
   convenience" — it is precisely what makes `stamp <= current` true and therefore what
   makes the rule collapse to equality; a public init would let a host mint ahead of the
   counter. Also rejected: a staleness *tolerance* (a frame within a window is still
   stale, and a window of 2 lets gen 5 present after gen 6), and rate-limiting `advance()`
   (puts timing policy inside a value-ordering primitive).

   Monotonicity is asserted as a **consequence**, not enforced as a second rule;
   `lastPresentedGeneration` exists only because §34 displays "current generation".

   Generic over content, so `VoxeliaInteraction` still names no host type and imports no
   host framework — `VOX-INT-001` intact, with a test standing the presenter up over an
   unrelated content type.

   **Next: `VOX-R2D-014` + `VOX-VS1-016`** — one presentation path serving off-screen and
   interactive output, equality **tested** rather than asserted in prose. Then
   `VOX-INT-008`'s `T` via an injected clock and deterministic probe.

   **Increment (vv): `ADR-0277`, padding transit design — and a CORRECTION TO MY OWN
   `ADR-0275`.** No code; 1124 tests / 203 suites unchanged.

   **`VOX-VS1-016` WAS ALREADY DISCHARGED** by `ADR-0251` on 2026-08-06 (three purity
   tests in `ExactSliceRendererTests`). `ADR-0275` listed it as unblocked work with
   "nothing gates it". **The mistake: I trusted a ledger line that predated `ADR-0251`
   and never grepped `docs/architecture/decisions/` before writing the inventory.** Same
   class of error as `ADR-0248` but in the opposite direction — that one treated a
   recorded *deferral* as a gap, this one treated a *discharged* row as outstanding.
   **A row's status lives in the records; the ledger summarises them and is not an
   authority over them.** `ADR-0275` NOT edited; only that one claim withdrawn — its arc
   decomposition, the application-location owner decision and the `VOX-PER` parking all
   stand.

   **`VOX-R2D-014` is the arc's real open presentation row** — it appears in `ADR-0251`'s
   front matter but in none of its decisions or consequences, and **no test carries its
   tag**.

   **All nine of plan §35.1's shared semantics traced through the pipeline, not assumed**:
   seven travel in the request (viewport, plane geometry, interpolation, value
   transformation, windowing via `layer.transferFunction`, MONOCHROME via
   `window.polarity`, output colour descriptor); **one is legitimately construction-time**
   — "shader or CPU implementation" *is* which renderer you built, so `ADR-0251`'s
   identical-construction condition is the only right shape for it; **one is a genuine
   gap.**

   **THE FINDING — padding does not travel AT ALL, while both ends are already built.**
   Import captures it (`CTFrameDescription.pixelPadding`, read by `CTValueInterpreter`);
   both window operations accept `paddingValue: Int64?`; **`ALG-0002` rev 1.2 registers
   the rule** (a stored sample equal to the sentinel is excluded before every
   stored-to-real step and **displays exactly zero**), accepted for CPU by `ADR-0113` and
   extended to the device window by `ADR-0146`. **And nothing connects them**:
   `CTImportSession` and the `CTVolume*` builders carry no padding, and both renderers'
   convenience inits hard-code `paddingValue: nil`. `ADR-0146` recorded why at the time —
   "the adapter that supplies padding values is gated" — **that gate has since opened and
   the wiring was never revisited.** So §35.1's padding policy is shared today only
   because it is uniformly ABSENT, and **CT pixel padding is currently windowed as if it
   were data.**

   **THE SEPARABILITY that makes the row actionable**: `ADR-0251` deferred padding partly
   on plan §28.4 needing a "separately approved rule". But §28.4 governs excluding padding
   from **authoritative interpolation** (the *resample* stage, changes measured values,
   owner's to approve), while §35.1 requires the two paths to use **the same** policy —
   an *equality* requirement needing no particular rule. **Equality does not depend on the
   rule.** §28.4 stays untouched and owner-gated.

   **Frozen design**: no new vocabulary (`ALG-0002` rev 1.2's `Int64?` sentinel and its
   `padding` schema entry are the accepted shapes); **the padding value is data-intrinsic
   and travels with the IMAGE, not the viewport request** — rendering the same stored
   samples under two sentinels would make the same bytes mean different things. Four
   transit links, **two missing**: persisted with the volume, and read by the renderer.

   **Deliberately NOT taken**: picking §28.4's any-padding rule under the `ADR-0194`
   precedent (broad mandate + the document's own stated preference). It would be
   *authorised* — but **nothing being worked needs it chosen**, so it would be scope taken
   for its own sake. Also rejected: a `SliceRenderRequest` padding field (puts a
   data-interpretation fact in a viewport request), and tagging `ADR-0251`'s three
   existing tests with this row (they establish purity *conditionally on identical
   construction*, and padding is exactly the semantic that condition exists for — tagging
   them would claim eight semantics as nine).

   **Next**: persist the padding value with the volume, feed it to the window stage, and
   discharge `VOX-R2D-014` with tests carrying its tag. Two boundaries for that increment
   to settle: what a volume does when frames declare *different* padding (refusal is the
   likely answer — a volume whose slices mean different things by the same stored value is
   not one volume), and whether `WindowStageExecutor` gains a parameter or the closure
   captures the value.

   **Increment (ww): `ADR-0278`, `VOX-R2D-014` DISCHARGED — and `ADR-0277` d6 withdrawn on
   measurement.** 1125 tests / 203 suites (was 1124/203).

   **THE MEASUREMENT `ADR-0277` PROMISED, over the owner's ENTIRE input tree** (not one
   series): **30,347 files, 29,651 frames described, ZERO declaring `PixelPaddingValue`**,
   all `uint16`. The adapter reads tag `(0028,0120)` correctly — there is simply nothing
   to read. **So the padding transit gap is entirely latent**: `paddingValue: nil` gives
   byte-identical output to a fully wired transit on every frame this project can reach.
   Building it now would be machinery no data exercises, verifiable only synthetically.

   **SECOND FINDING — the divergence `ADR-0251` guarded against is NOT PUBLICLY
   REACHABLE.** Checked the access levels rather than the shape: `ExactSliceRenderer` is
   public and its **convenience** init is public, but the **designated** init is
   **internal** and `WindowStageExecutor` is **internal** — the parameter's type cannot
   even be *named* outside the module. All 11 construction sites use the convenience init,
   and both renderers' hard-code the same `nil`. **No external caller — export path or
   viewport — can inject a stage at all.**

   **THE READING**: the one remaining choice is *which renderer type*, and §35.1's eighth
   shared semantic is literally "**shader or CPU implementation**". `ADR-0251`'s
   "identical construction" condition **IS** that requirement in code, not a qualification
   of it. Nine semantics resolve: seven in the request, one fixed by the only public
   construction path, one the plan's own same-implementation rule.

   **`ADR-0277` d6 WITHDRAWN** — it required the unconditional transit before this row
   could discharge. Measurement + access levels say otherwise. `ADR-0277` NOT edited; its
   enumeration, §28.4 separability finding and `ADR-0275` correction all stand.

   **The positive control that makes the claim falsifiable**: the equality was otherwise
   about a knob that might do nothing. New test builds a renderer via the internal
   designated init with `paddingValue: 11` — a value the fixture actually contains —
   asserting the unpadded render puts something **non-zero** there, that declaring it
   padding makes that byte **exactly zero** (`ALG-0002` rev 1.2), and that **no other byte
   moves**. First test anywhere to exercise that accepted rule through a renderer.

   **A VERIFICATION TRAP, hit and recorded**: `swift test --filter` matches test
   **function names**, NOT the display strings in `@Test("…")`. Filtering on a display
   string ran **zero** tests and printed `Test run with 0 tests in 0 suites passed` — a
   green line meaning nothing ran. Caught only by counting `@Test(` in the file against
   the reported total. Same silent-pass failure mode as before, new hat. **A green tick on
   zero tests is not evidence; when a filtered count surprises you, suspect the filter.**

   **Rejected**: making padding an explicit *public* convenience-init parameter — it would
   make divergence EASIER, turning a semantic no external caller can vary into a knob every
   caller must set consistently, which is the opposite of what §35.1 asks.

   Padding is now **quantified, not open**: rule accepted, reachable internally,
   demonstrated correct, unexercised by all available data, unreachable from production.

   **The draw-loop arc's unblocked library tier has ONE row left: `VOX-INT-008`'s `T`** —
   responsiveness under background processing, via an injected clock and deterministic
   probe.

   **Increment (xx): `ADR-0279`, `VOX-INT-008`'s `T` discharged. THE DRAW-LOOP ARC'S
   UNBLOCKED LIBRARY TIER IS COMPLETE.** 1129 tests / 204 suites (was 1125/203). The row
   had reached **no accepted record and no test** — one of only two `VOX-INT` rows in that
   state.

   **THE READING — "responsive" must NOT be a latency figure, twice over.** It belongs to
   `VOX-PER-005` ("within 50 ms on reference workstation hardware", owner-gated), and
   `ADR-0275` d4 already froze that no performance threshold is claimed in this arc. **And
   the plan says responsiveness isn't achieved by speed**: §22.4 states submitted GPU work
   "may not be physically interrupted" and lists five mechanisms instead — preventing
   obsolete command preparation, tagging buffers with generation, **not presenting obsolete
   completion**, reusing resources only after completion, prioritising current work. **Not
   one is "finish faster."** So the property is structural: *an interaction is serviced
   without waiting for background processing.* Same move as `ADR-0251` (purity IS
   equivalence) and `ADR-0206` (registration IS statelessness).

   **WHY IT HOLDS**: `VoxeliaInteraction` has exactly **two** reference types
   (`RenderGenerationCounter`, `FramePresenter`). `ViewportSyncGroup`, `CrosshairState`,
   `RenderGeneration`, `StampedFrame` are all values — no identity to contend for. And
   **neither actor method contains a suspension point**, so no caller can hold one across
   an `await`, which is what blocking another caller would require. `ADR-0249` d6's
   observation in a new place: a non-suspending critical section has no blocking point.

   **Tests are fully deterministic — no sleeps, no timeouts, no timing assertions.** "In
   flight" is an explicit gate the test opens, so it's a fact rather than a race won by a
   sleep. A responsiveness test depending on machine load would be the flakiest test here
   and would assert nothing about structure.

   **Composition tested, not just halves** (`ADR-0248`'s lesson): the presenter runs
   against a genuinely in-flight background task — interaction advances the generation
   while the render is suspended, and the render's completion is **dropped as obsolete**
   when it lands, exercising §22.4's third mechanism.

   **Honest self-limitation recorded IN the test**: test 1's gates *enforce* the order it
   asserts and its background task touches nothing the interaction needs, so **it cannot
   fail through contention**. Said so in the test rather than letting a reader infer a
   strength it lacks — and moved the contention to where a regression would actually show:
   16 interactions concurrent with background presentation traffic touching **both**
   actors, still minting 16 distinct contiguous generations. **Run repeatedly, not once** —
   a concurrency test that passed one time hasn't been shown stable.

   **Positive control on the value-typed claim**: four interaction types asserted NOT
   `AnyObject`, and the two actors asserted **to be** `AnyObject`. A non-conformance
   assertion that can never fail proves nothing; a later refactor of `ViewportSyncGroup`
   to a class must now break this test.

   **INDEPENDENT CONFIRMATION OF `ADR-0276`**: plan §22.3 states outright that a result
   "may be presented only if its generation **equals** the current viewport generation".
   `ADR-0276` *derived* that equality from the vocabulary (internal init ⇒ stamp ≤ current
   ⇒ `!isStale` iff equal) **without having read §22.3**. Derivation and plan agree. §22.2
   also lists the ten state changes that must advance a generation — all reach the same
   counter, which is why one test standing for the set is honest rather than partial.

   **`VOX-INT-008`'s `D` remains HELD**, not redefined to fit what is testable.

   **ARC STATUS: no unblocked implementation work remains.** Discharged: `VOX-INT-007`,
   `VOX-R2D-014`, `VOX-VS1-016`, `VOX-INT-008`(`T`). **Owner-gated remainder**:
   `VOX-INT-008`(`D`) and `VOX-INT-010`(`D`) on the application decision;
   `VOX-PER-002/003/005` on reference hardware.

   **Next**: the exact-next-action must be **re-derived**, not assumed — this arc's queue
   is exhausted.

   **DERIVATION (done, not deferred).** Mechanically queried all 460 baseline rows for
   those with **no decision record, no test and no source mention**: 110 hits, but most sit
   in unentered milestones (M7–M9). Filtering to entered milestones leaves a short list,
   and one entry is startling:

   **`VOX-SPA-008` — P0, `T`, MILESTONE M1 — is substantially UNBUILT.** "Affine transforms
   shall support **composition**, **inversion** and **point, vector and normal**
   transformation." Searched by capability rather than vocabulary (the `ADR-0248` lesson):
   - **inversion — EXISTS**: `AffineSpatialInverse` with a typed `singularMatrix` error,
     which also means **`VOX-SPA-009`** (P0, M1, "singular or non-invertible transforms
     shall produce typed errors") is implemented but **untraced to its row**;
   - **composition — ABSENT**: `Matrix4x4Double`'s entire public surface is `encode(to:)`;
   - **point / vector / normal transformation — ABSENT**: `grep` finds no
     `transformPoint`, `transformVector`, `transformNormal` or `inverseTranspose` anywhere
     in `Sources/`.

   **Why the third one matters numerically**: points take translation, vectors do not, and
   **normals transform by the inverse-transpose** — not by the matrix. Thin-slice CT is
   strongly anisotropic, so transforming a normal as a vector gives a *wrong direction*,
   not a rounding difference. The geometry arc already publishes vertex normals
   (`ALG-0030`), so the vocabulary to get this wrong exists while the vocabulary to get it
   right does not. No active defect is claimed — nothing currently transforms normals
   across spaces — but the capability gap is real and the row is P0 in the oldest entered
   milestone.

   **Next action: assess `VOX-SPA-008`/`009` and open that arc.** Composition and the three
   transformation kinds are numeric boundaries, so **design-first with an ALG spec and an
   independent Python oracle** before any implementation. `VOX-SPA-009` likely discharges
   on inspection plus a tagged test over the existing inverse.

   Also on the derived list for later, entered-milestone and untouched: `VOX-VAL-001`
   (M0), `VOX-DOC-009` (M0), `VOX-ERR-004`/`VOX-R2D-001`/`VOX-VAL-006` (M3),
   `VOX-VAL-003`/`VOX-VAL-012`/`VOX-MPR-014`/`VOX-R2D-003` (M4),
   `VOX-VAL-013`/`VOX-PER-009`/`VOX-SEC-005` (M5). Several are likely traced-but-untagged
   rather than unbuilt — each needs the same capability search before any work is assumed.

   **Increment (yy): `ADR-0280` opens the affine transform arc — and finds a latent
   composition defect.** No code; 1129 tests / 204 suites unchanged.

   **Assessment of `VOX-SPA-008`** (P0, `T`, **M1**), searched by capability not
   vocabulary: **inversion EXISTS** and is frozen (`ALG-0016`/`ADR-0136`, adjugate,
   3×3 block); **point transformation EXISTS per consumer** (`ADR-0138`'s world-to-index,
   own frozen accumulation order); **composition ABSENT — and deliberately**, since
   `ALG-0016` says composition "is the consuming operation's own frozen step per the
   specification"; **vector transformation ABSENT**; **normal transformation ABSENT**.
   `Matrix4x4Double`'s whole public surface is `elements`, two inits and `Codable` — a
   validated container, not an algebra. **`VOX-SPA-009` is implemented but UNTRACED** —
   `AffineSpatialInverseError.singularMatrix` on a determinant below
   `Double.leastNormalMagnitude`; it needs a tagged test, not code.

   **THE FINDING — two accepted contracts assume different spaces and NEITHER SAYS SO.**
   `SurfaceLayer.objectToWorld` validates **only** the affine bottom row, so any rotation,
   scale or shear is admitted. `SurfaceVertexProjector` (`ALG-0033`) transforms vertex
   **positions** through it into world space. `SurfaceShader` (`ALG-0036`) reads vertex
   **normals** straight from `mesh.vertexAttributes` — **object space** — and dots them
   against the camera's `forward`, built from `target - position` and therefore **world
   space**. Nothing transforms the normal between. **`ADR-0202`'s only mentions of "space"
   are colour**, so this is an *unstated assumption on which two contracts differ*, not a
   decision made wrongly — a distinction that changes what needs correcting.

   **QUANTIFIED, not described** (independent Python, explicit arithmetic):
   | `objectToWorld` | as composed | correct | error |
   |---|---:|---:|---:|
   | rotation 90° about X | `1.000000` | `0.000000` | **`1.000000`** |
   | scale `(1,1,5)`, normal `(0,0,1)` | `1.000000` | `1.000000` | `0.000000` |

   The first is the **maximum possible error** for a value bounded in `[0,1]` — a facet
   squarely facing the camera shades as fully unlit. **The second is included precisely
   because it does NOT diverge** (an axis-aligned normal survives an axis-aligned scale,
   renormalisation absorbing it): the defect is real but **not universal**, and reporting
   only the first figure would overstate it. And the case proving the inverse-transpose is
   required rather than the matrix — normal `(0,1,1)` under scale `(1,1,5)`: as a **vector**
   `(0, 0.196116, 0.980581)`, as a **normal** `(0, 0.980581, 0.196116)`, **67.38° apart**.
   Thin-slice CT is strongly anisotropic, so that is the shape actually met.

   **LATENT, NOT SHIPPING**: `SurfaceShader` has **no production caller** — every reference
   outside its own file is in its own tests. **No image Voxelia can produce today is
   wrong.** Said precisely because the temptation is to call it a shipped bug; it is the
   third of the three questions this project keeps separating — capability, wiring,
   composition-verified.

   **Arc constraint frozen**: `ALG-0016`'s per-consumer position is **respected, not
   overturned**. A general composition must justify itself as *additional* vocabulary and
   **must not change any existing consumer's bits** — any adoption re-runs that consumer's
   oracle and shows digests unchanged (the swap-flag / world-position precedent).

   **Next**: `VOX-SPA-009`'s tagged test over the existing typed singular error — the
   cheapest real discharge available, and a check that this assessment is accurate before
   larger work depends on it. Then the design increment (ADR + `VOXELIA-ALG` + independent
   oracle) for composition, vector and normal transformation. Then the shading correction,
   verified against that oracle.

   **Increment (zz): `ADR-0281`, `VOX-SPA-009` DISCHARGED.** 1134 tests / 205 suites (was
   1129/204). No source changed — `ADR-0280` predicted this row needed a test, not code,
   and that held.

   **What existed**: three typed errors on a determinant below
   `Double.leastNormalMagnitude` — `AffineSpatialInverseError.singularMatrix`,
   `SpatialGeometryError.singularTransform`, `CTVolumeConstructionError.singularTransform`
   — all already tested, **none carrying this row's tag**. Every threshold is the same
   value and **none is an epsilon**, matching the no-epsilon rule rather than coincidentally
   agreeing with it.

   **THE CLAIM NOBODY HAD CHECKED**: `AffineWorldToIndexMap.init` documents its own
   `singularMatrix` throw as *"unreachable for a validated geometry whose own admission
   computes the identical frozen determinant"* — resting on **two separately written
   expressions agreeing bit-for-bit**. They are the same order (Swift's `a - b + c` is
   `(a - b) + c`), but nothing verified it, and a divergence would mean a geometry admitted
   by one layer is refused by the next, firing a branch documented as unreachable.

   **Verified in the falsifiable form that needs no determinant exposed**: both admissions
   run over 8 boundary cases and required to agree — **3 admitted, 5 refused, agreement on
   every one**. Determinants computed independently:
   identity `1` ✓ · at threshold `2.2250738585072014e-308` ✓ · one ulp below
   `...09e-308` ✗ · exactly zero ✗ · subnormal factor `4.94e-324` ✗ · **underflowing
   product `5.5626846462680035e-309` ✗** · near-cancelling `-7.105e-15` ✓ · rank
   deficient `0` ✗.

   Two cases earn their place: the **underflowing product** `diag(tiny, 0.5, 0.5)` has **no
   factor that is zero or subnormal** yet its product falls below threshold — exactly what
   `CTAffineVolumeBuilder`'s own comment anticipates about spacing values that "make the
   determinant underflow"; and **near-cancelling cofactors** at `-7.1e-15` is small enough
   that a different summation order would show while still admitting, so it catches a
   divergence in *order* rather than in magnitude.

   **Non-vacuity asserted, not assumed**: the test requires ≥1 admitted AND ≥1 refused,
   because a set falling all one way makes "the two agree" true and empty (`ADR-0249` stage
   three's lesson). And a **rank-deficient** case sits alongside the zeroed ones because
   "singular" ≠ "has a zero on the diagonal" — a test using only the latter would pass
   against an implementation that scanned for zeros instead of computing a determinant.

   **Threshold asserted from BOTH sides**, and the admitted case checks
   `determinant == tiny` exactly — the value, not just the outcome.

   **Next**: the affine design increment — ADR + `VOXELIA-ALG` + independent Python oracle
   for **composition, vector and normal transformation**, under `ADR-0280` d3's constraint
   that **no existing consumer's bits change**. Then the surface-shading correction
   `ADR-0280` quantified.

   **Increment (aaa): `ADR-0282` — I FOUND AND FIXED A PROCESS DEFECT OF MY OWN.** No Swift
   source changed; 1134 tests / 205 suites unchanged.

   Reaching for the next unallocated `ALG` identifier, I read the ADR register's equivalent
   line: **"The next unallocated numeric identifier is `ADR-0227`."** The highest record on
   disk was **`ADR-0281`**.

   **Two-part defect.** (1) **Ten accepted records had NO register row** — `ADR-0272`
   through `ADR-0281`, i.e. **everything this session produced**. The recipe names the
   register update and I skipped it **ten times**. (2) The **allocation counter was 45
   identifiers stale and that PREDATES this session**: the table was maintained through
   `0271` while the counter said `0227`, so the register's two halves had already diverged
   — the prose allocation convention lapsed around `ADR-0226`.

   **WHY NOTHING CAUGHT IT**: `validate-docs.sh` runs `check_adr_register.py` every
   increment and it passed throughout. **The name misleads** — it validates the record
   *files* (front matter, sections, duplicate IDs) and **never opens `README.md`**. Its own
   docstring says so: *"without interpreting body references."* **The register was a
   document the project treated as authoritative and no gate had ever read.** Second
   instance of the `ADR-0196` pattern — *when a record claims something, check whether
   tooling actually enforces it.*

   **Fixed**: rows regenerated **from each file's own front matter** (so titles/statuses
   can't drift from the records they index), counter corrected, and
   **`check_readme_index`** added to the gate — every `ADR-NNNN` file must have a row
   **linking that exact filename**, and the counter must equal highest+1. A **bare mention
   does not satisfy a row**: prose cross-references are common and would mask a gap, which
   is exactly how ten records looked registered to a casual `grep`.

   **Negative-tested both branches** (a gate I just wrote passing is not evidence):
   removing a row → `ADR-0275 has no register row linking ADR-0275-...md`; restoring the old
   counter → `the next unallocated identifier is ADR-0227 but the highest record on disk is
   ADR-0281, so it should be ADR-0282`. **That second message is verbatim what this
   repository would have emitted at any point in the last 45 records, had anything been
   looking.** And on creating `ADR-0282` itself the new gate **immediately demanded its own
   row** — the best possible demonstration.

   **The lesson, narrower than "be more careful": A RECIPE STEP THAT NO GATE ENFORCES WILL
   BE SKIPPED.** The fix is the gate, not the resolution. Other recipe steps sit in the same
   position and deserve the same treatment when one is next found lapsed.

   **Deliberately NOT done**: generating the table from files (the register also holds
   allocation prose and the `ADR-0024`/`ADR-0001` reconciliation note a generator would
   destroy), and reviving the per-identifier prose convention (a third hand-maintained copy
   of the same facts is what drifted).

   **Next**: the affine design increment this interrupted — ADR + **`VOXELIA-ALG-0052`** +
   independent Python oracle for composition, vector and normal transformation.

   **Increment (bbb): `ADR-0283` + `VOXELIA-ALG-0052` accepted — the affine design, frozen
   with five EXACT fixtures.** No code; 1134 tests / 205 suites unchanged.
   `affine-composition/binary64-v1` supplies the three capabilities `ADR-0280` found
   absent.

   **Frozen boundaries**: **composition means "A after B"** (`compose(A,B) × p ==
   A × (B × p)`) — which *follows* from the column-vector convention rather than being
   chosen separately; the **affine structure is used, not multiplied through** (bottom row
   set to the literal `0,0,0,1`, because multiplying admitted values by known zeros
   contributes signed zeros to otherwise-exact sums and buys nothing); the **translation
   term is added LAST**; **vector transformation reuses `ADR-0138`'s exact expression
   order** so the two agree where they overlap rather than merely resembling each other;
   **normal transformation is a COLUMN traversal** of `ALG-0016`'s inverse — the
   specification says outright it must not be rewritten as a row traversal, which would
   silently compute `Inv × n` and reintroduce the very error it exists to prevent.

   **Deliberately NOT normalised**: the normal transform is a linear map and stops there.
   `ALG-0030` publishes unit normals and `ALG-0036` renormalises before use; normalising
   here would duplicate an accepted rule and break the correspondence between transforming
   twice and transforming by the composition. A result underflowing to zero is a **value,
   not a failure** — so no untestable branch.

   **Two failure cases only** (`nonAffineOperand`; `singularMatrix` composed from
   `ALG-0016`), and **no representability failure** — inputs are admitted finite and
   neither accepted sibling carries one.

   **FIVE EXACT FIXTURES, no tolerance anywhere.** Fixture 1 checks composition **against
   staged application** (`C × p` vs `A × (B × p)`, both exactly `(-4, 3, 9)`) rather than
   against a hand-typed matrix — testing the property, not a transcription. Fixture 3 is
   `ADR-0280`'s finding made executable: under `diag(1,1,5)`, `n = (0,1,1)` gives
   **`(0, 1, 5)` as a vector but `(0, 1, 0.2)` as a normal**. **Fixture 5 registers
   NON-ASSOCIATIVITY** with a witness: `(X∘Y)∘Z` element 0 is `3.0` while `X∘(Y∘Z)` is
   `3.0000000000000004` — a consumer would reasonably assume otherwise.

   **A subtlety recorded so neither finding invites the wrong fix**: fixture 4 shows the
   vector and normal rules agree **exactly** under a pure rotation (`R⁻ᵀ = R`), while
   `ADR-0280` measured max error under rotation. Both true, different questions — *whether
   to transform at all* (wrong for ANY non-identity transform) versus *which rule to use*
   (only matters when not orthonormal).

   **Two reference errors of mine, caught not shipped**: I cited `ADR-0033` for the
   pre-multiplication prohibition — it is **`VOXELIA-ALG-0033`** (`ADR-0033` is ordered
   metadata collection); and I wrote `## Decisions` where the gate requires the literal
   `## Decision`. **The register gate added last increment caught the second immediately**
   and demanded `ADR-0283`'s own row — working exactly as intended, one increment old.

   **Next**: implement in `VoxeliaSpatial`, reproducing all five fixtures exactly and
   confirming **no existing consumer's digests change** (`ADR-0280` d3). Then the
   surface-shading correction.

   **Increment (ccc): `ADR-0284`, `VOX-SPA-008` DISCHARGED. BOTH M1 SPATIAL ROWS THE
   DERIVATION SURFACED ARE NOW CLOSED.** 1145 tests / 206 suites (was 1134/205).

   **ALL FIVE FIXTURES REPRODUCED EXACTLY, FIRST RUN** — no value needed adjustment between
   the independent Python oracle and the Swift. That is what the design-first order exists
   to produce rather than hope for, and it is worth recording because **the alternative
   failure is silent**: implementation first, then an oracle written to agree with it, gives
   the same green suite while proving nothing about the arithmetic. **The order is what
   makes the agreement evidence.**

   **Every assertion is exact equality** — each registered value is representable in
   binary64, so no tolerance appears anywhere in the suite.

   **Fixture 1 is tested twice and the SECOND is the real one**: the first compares the
   composed matrix against registered elements; the second composes, applies, and compares
   against **staged application** `outer(inner(p))`. A transcription error in the first
   would be caught by the second, which tests the property the operation exists for.

   **Coordinate spaces deliberately NOT attributed.** `Point3D`/`Vector3D` carry a
   `CoordinateSpaceID` and a transform maps *between* spaces — so the destination space is a
   real question, and it is the **consumer's**, exactly as `ALG-0016` left composition with
   a world offset to its consumers. The API takes and returns plain components; accepting
   the space-carrying types would have forced the algebra either to invent a space rule no
   requirement asked for or to ignore a field the type guarantees.

   **`ADR-0280` d3's constraint VERIFIED, not assumed**: nothing existing was modified (one
   new file), and the suites of every operation this composes were re-run —
   `AffineSpatialInverse`, `AffineWorldToIndexMap`, `SpatialGeometry`,
   `SingularTransformTypedError`: **16 tests / 4 suites, unchanged**.

   **Four tests beyond the fixtures**: a non-affine operand refused in **all four**
   positions (testing one would leave three guards unexercised); a singular matrix
   surfacing **`ALG-0016`'s own** `singularMatrix` — the only observable way a test can tell
   composing the accepted inverse from reimplementing it; a transformed normal asserted
   **not** normalised (else "deliberately not normalised" is a comment, not a behaviour);
   and identity composition over a matrix of **distinct primes** so a transposition or index
   slip cannot pass.

   **Rejected**: adding a point transformation here (`ADR-0138` already froze one; a second
   would recreate the duplicate-authority problem `ALG-0016` avoided), and normalising
   inside `transformNormal` (one line, and it would break the correspondence between
   transforming twice and transforming by the composition).

   **Next**: the **surface-shading correction** — now unblocked. `ADR-0280` established that
   `SurfaceVertexProjector` transforms positions to world space while `SurfaceShader` reads
   **object-space** normals and dots them against a **world-space** forward, quantified at
   `1.000000` vs a correct `0.000000` under pure rotation. It consumes `transformNormal` and
   **must not edit `ADR-0202` or `ALG-0036`**.

   **Increment (ddd): `ADR-0285`, the shading-correction design — and it UNCOVERED A SECOND
   NUMERIC BOUNDARY.** No code; 1145 tests / 206 suites unchanged.

   **First, what is NOT wrong**: `ALG-0036`'s arithmetic is correct. Its input domain names
   "three unit vertex normals" and "the camera's forward unit axis" and **gives neither a
   space**. The model is right for same-space inputs; the *composition* supplied inputs from
   two spaces. **The defect is in what reaches the shader, not what it does with them** — so
   `ADR-0202`/`ALG-0036` stay untouched and the normals are transformed before arrival.

   **THE BOUNDARY THIS UNCOVERED**: a transformed normal is **no longer unit**, and
   `ALG-0036` states unit inputs "by construction" and does **not re-admit** them. So
   something must restore that — and **where the normalisation happens changes the answer
   materially.** Measured under `diag(1,1,5)` (a thin-slice CT shape), three distinct unit
   normals, weights `(0.25, 0.35, 0.40)`:
   - interpolate raw then renormalise → `(0.71539960678951550, 0.51099971913536820, 0.47653193979940256)`
   - **normalise each then interpolate** → `(0.51398322650298800, 0.36713087607356293, 0.77526522088059410)`
   - **22.37° apart**, intensities differing by **`0.29873328108119157`** — nearly **30% of
     the full `[0,1]` range**.

   **No accepted spec covered this.** `ALG-0052` d7 deliberately does not normalise (leaves
   it to the consumer); `ALG-0036` renormalises the *interpolated* direction and assumes
   unit inputs. **The gap sits exactly between them.**

   **Frozen: normalise EACH transformed normal BEFORE interpolation**, using `ALG-0030`'s
   accepted scaled-normalisation rule composed rather than restated. That is what keeps
   `ALG-0036` inside its own stated domain — feeding it non-unit vectors would leave the
   arithmetic working while **violating a stated precondition**, which this project treats
   as a defect even when the numbers survive.

   **Zero-scale transformed normal → passed through as the zero direction, NOT failed**:
   `ALG-0030` fails an undefined *published* normal, but `ADR-0202` chose the opposite for
   presentation ("shading is presentation, not measurement"). This is presentation, so it
   composes `ADR-0202`'s position. **No new failure case** — the family is `normalsMissing`
   and `singularMatrix`, both already existing and already tested.

   **Rejected — and the cheapest option was the tempting one**: interpolating raw and letting
   `ALG-0036` clean up (violates its domain, shifts shading by up to `0.299`); normalising
   inside `transformNormal` (`ADR-0283` d7 settled it — would break transform-twice ≡
   transform-by-composition); and **transforming the camera forward into object space
   instead** (cheaper still — one direction per facet, not three — but each layer has its own
   `objectToWorld`, so the forward becomes per-layer and any later cross-layer comparison is
   mixing spaces again: **it moves the defect rather than removing it**).

   **No new ALG** — every step is an accepted rule (`ALG-0052` transform, `ALG-0030`
   normalise, `ALG-0036` shade); this record freezes only the **ORDER**, which is the whole
   content of the decision, which is why the measurement is registered with it.

   **Next**: implement in `VoxeliaRendering`, showing four things — the 22.37° divergence
   reproduced; `ADR-0280`'s `1.000000` vs `0.000000` as a test; `ALG-0036`'s own fixtures
   still passing **unchanged**; and the **identity** `objectToWorld` leaving shading
   bit-identical, which is what makes "nothing existing changes" checkable rather than
   claimed.

   **Increment (eee): `ADR-0286` — THE SHADING CORRECTION IS IMPLEMENTED.** 1152 tests /
   207 suites (was 1145/206). `ADR-0202` and `ALG-0036` **unedited**; `SurfaceNormalTransform`
   is a new file and nothing existing changed behaviour.

   **All four required demonstrations delivered**: `ADR-0280`'s measurement is now a test
   (uncorrected `1.0`, corrected `0.0`, difference exactly `1.0`); the normalisation-order
   divergence asserted above `0.29` of the full range; **`ALG-0036`'s own suites passing
   unchanged** (17 tests / 5 surface suites); and the **identity** transform leaving world
   normals **exactly equal** to the object ones — which is what makes "nothing existing
   changes" checkable rather than claimed.

   **Hoisting done properly**: `AffineTransformAlgebra.transformNormal` gained an overload
   taking a **precomputed** `AffineSpatialInverse`, and the matrix-taking overload now
   **delegates to it** — one implementation of the column traversal, two entry points, so
   they cannot drift. `ADR-0284`'s 11 tests passed **unchanged** after the refactor, which is
   what makes it a refactor rather than a rewrite. **Rejected**: reimplementing the traversal
   in the renderer to hoist — the obvious shortcut, and exactly what `ADR-0283` d5/d6 warned
   about, since the transpose is expressed *by* the traversal order and a duplicate is one
   edit from silently becoming `Inv × n`.

   **Unit-length asserted EXACTLY, not with a tolerance**: an axis-aligned normal under a
   diagonal transform scales to `(0,0,0.2)` whose normalisation is exactly `(0,0,1)`. The
   test asserts that **and** that the raw value is `(0,0,0.2)` — distinguishing "normalised"
   from "returned unchanged", which a unit-length tolerance would not. `ALG-0030` explicitly
   states no unit-length tolerance correction is applied, so a tolerance would assert
   something the spec deliberately does not promise.

   **TWO THINGS FOUND WHILE IMPLEMENTING, both recorded for their own increments:**
   1. **`SurfaceShader.normals(of:facetOrdinal:)` had NO caller and NO test.** Every
      reference outside its own file was to `intensity`, which the suite exercises directly
      with hand-built directions. The reader — including its `normalsMissing` rejection —
      was **unexercised until this increment called it**. Third appearance of the
      existence/wiring/verification split (`ADR-0248`, `ADR-0282`).
   2. **A pointer API reached a test and the gate did not object.** The fixture first used
      `withUnsafeBytes`; `check_swift_safety.py` **passed, because it does not scan
      `Tests/`**. The policy forbids it regardless, so it was replaced with explicit shifts —
      but this is a **third instance of the `ADR-0196` pattern**: an enforced-looking rule
      nothing enforces in that location. Widening the scan is a tooling change with its own
      blast radius, so it gets its own increment rather than being smuggled into a rendering
      correction.

   **The affine arc's named work is COMPLETE.** Next: the two tooling gaps, then a
   re-derived queue.

   **Increment (fff): `ADR-0287` — I INVESTIGATED MY OWN `ADR-0286` CLAIM AND IT WAS WRONG
   TWICE.** 1152 tests / 207 suites unchanged; no product source changed.

   **Withdrawn claim 1**: "`check_swift_safety.py` does not scan `Tests/`". **It does** —
   `Tests` is the second scan root, beside `Sources`, `Benchmarks`, `Tools`, `Validation`.
   **Withdrawn claim 2**: "the policy forbids the API regardless". **Over-strict** — the
   policy states outright that "an identifier containing `unsafe` is **not reserved**". So
   `withUnsafeBytes` passing is **the policy working as written**, not a hole. Reserved
   spellings are `@unchecked`, `@preconcurrency`, `StrictMemorySafety` and the **bare word**
   `unsafe`. `ADR-0286` NOT edited; only those two claims withdrawn.

   **THE REAL GAP, and it is sharper.** The policy's first sentence permits "only one
   explicitly approved **compiler-classified** memory boundary" — but **`StrictMemorySafety`
   appears NOWHERE in `Package.swift`** (zero occurrences). **No compiler was doing the
   classifying.** The `unsafe` markers in `MetalBufferTransfer` are voluntary, and the
   word-based scan detects **a convention the codebase follows, not a property the compiler
   enforces**. Evidence: `ADR-0286`'s test compiled `withUnsafeBytes` with no marker at all.

   **POSITIVE CONTROL FIRST, and it mattered.** My first package measurement counted
   **errors** → 0 → **which proved nothing, because strict memory safety emits WARNINGS**.
   The number was meaningless until a three-line probe established the flag fires at all:
   clean without it, `warning: expression uses unsafe constructs but is not marked with
   'unsafe' [#StrictMemorySafety]` with it.

   **Then measured on genuinely fresh scratch builds**: product source **895 units → 0
   diagnostics**; source+tests **1150 units → 14**, all from **three** `withUnsafeBytes`
   calls in two DICOMKit test files; after rewriting them to explicit shifts, **1150 units →
   0**. **The whole package is now strict-memory-safety clean.**

   **NOT enabled in this increment, and not from reluctance**: the manifest is lexed against
   a **30-identifier declarative subset** permitting **none** of `swiftSettings`,
   `SwiftSetting`, `enableExperimentalFeature`, `strictMemorySafety`. Enabling requires
   **widening a safety control** — a governed change deserving its own increment with its own
   negative tests, same reasoning `ADR-0286` used declining to widen the scan inside a
   rendering fix.

   **Also NOT done: extending the scan to camelCase identifiers** — which was the plan when
   this increment began. The policy explicitly excludes them, so adding them would make the
   tool enforce a rule **the policy does not state** — the **inverse** of `ADR-0196`'s
   finding, and just as wrong. **The right instrument is the compiler, not a wider regex.**

   **Next**: the enabling increment — manifest allowlist widening (with a negative test that
   it still refuses everything it refused before, per `ADR-0233`'s discipline), package-wide
   vs per-target, and whether `MetalBufferTransfer`'s governed `expected_findings` needs
   revisiting once the compiler rather than convention requires its markers.

   **Increment (ggg): `ADR-0288` — STRICT MEMORY SAFETY IS ENABLED. The policy's stated
   model is now TRUE.** 1152 tests / 207 suites after a **clean rebuild**; no Swift source
   changed.

   **A correction to my own working assumption mid-increment**: a probe reported
   `'strictMemorySafety' is unavailable` and I concluded a tools-version raise was needed.
   **Wrong** — my probe was at `swift-tools-version:6.0` while **Voxelia has been at 6.2 all
   along**. The setting was available the whole time. That wrong conclusion would have
   turned a two-identifier change into a manifest-semantics migration.

   **All four of `ADR-0287`'s items settled:**
   1. **Exactly two identifiers** added (`swiftSettings`, `strictMemorySafety`) — declarative
      configuration, not executable logic.
   2. **Per-target, and NOT by choice**: the manifest lexer permits **exactly one `let` and
      one `=`**, so single-sourcing via `let safety: [SwiftSetting] = [...]` is
      **structurally forbidden**. Written inline on all **29** targets — verbose, and
      matching the house rule that every optional is passed explicitly.
   3. **Negative-tested three ways, all still refusing**: `.unsafeFlags(["-Onone"])` →
      *unsafe package compiler flags* **and** *outside approved declarative subset*;
      `.define("ARBITRARY")` → refused; a **second `let`** → refused. The widening admitted
      two identifiers and **nothing else**.
   4. **`MetalBufferTransfer` unchanged and now STRONGER**: its three `unsafe` markers were
      **voluntary**; the compiler now **requires** them. SHA pin and `expected_findings`
      untouched.

   **POSITIVE CONTROL — a silently-ignored manifest change looks exactly like a working
   one.** A temporary probe using `withUnsafeBufferPointer` with no marker made the build
   emit `warning: expression uses unsafe constructs but is not marked with 'unsafe'
   [#StrictMemorySafety]`; removing it returned clean. **The mode is live.**

   **A PRE-EXISTING FAILURE FOUND, AND NOT MINE.**
   `Tools/Tests/Python/test_repository_scripts.py` fails 1 of 12: it asserts the DocC wrapper
   passes `OTHER_DOCC_FLAGS='--warnings-as-errors'`, which the wrapper **deliberately does
   not** — its own comment records that `ADR-0233` removed the global flag because
   `docbuild` documents the whole package graph. **The script was corrected and its
   self-test was not.** **Verified by stashing and reproducing on pristine `main`**, per the
   standing rule after a whole-suite failure was once misattributed. It is **not in
   `validate-docs.sh`**, which is why it went unnoticed. Recorded for its own increment
   rather than folded into a governed manifest change.

   **Next**: the stale DocC self-test, then a re-derived queue.

   **Increment (hhh): `ADR-0289` — the one stale self-test was SEVEN, and FOUR were MINE.**
   150 repository-script tests green (was 143 pass / 7 fail); 1152 Swift tests unchanged.

   **`Tools/Scripts/test-repository-scripts.sh` was wired to NOTHING** — no workflow, no
   gate. It is the runner for **every checker's own regression tests** and it had no caller.
   Seven of its 150 were failing: **4 in `test_adr_register.py` broken by MY `ADR-0282`
   change** (added `check_readme_index`, which fails a synthetic fixture with records but no
   register — and I never ran that checker's tests, *because nothing runs them*); 1 in
   `test_docc_archives` (`ADR-0233` narrowed the gate to `Voxelia`-prefixed archives, fixture
   still used an unprefixed name the checker ignores **by design**); 2 in `test_generate_sbom`
   (hardcoded counts `12/13/12` and a hardcoded index `[0]` that drifted when modules and
   dependencies were added).

   **Fixed so they cannot drift again**: register fixtures now **generate** a matching
   register (so they also exercise `check_readme_index`); SBOM counts **cross-checked against
   `Package.swift`** rather than pinned to literals — an independent source, so a
   cross-check not a tautology; licence index **derived** from where the fixture is appended;
   external-package assertions now test the **property** (every package has a reviewed
   licence) rather than the count that rotted.

   **THE FIX I GOT WRONG, IMMEDIATELY.** The obvious durable answer — call
   `test-repository-scripts.sh` from `validate-docs.sh` — **recursed without bound**, because
   `test_repository_scripts.py` **executes `validate-docs.sh` as a subprocess**. Caught within
   a minute **because I ran it rather than assumed**: six nested processes were visible before
   anything was committed. Reverted; `validate-docs.sh` is **byte-identical** to before. The
   self-tests now run as **their own workflow step** after `validate-docs.sh`, where the two
   are separate processes. Recorded because "add it to the obvious gate" is what anyone would
   try next and the reason it cannot work is invisible from outside.

   **FOURTH INSTANCE OF THE SAME PATTERN**: `ADR-0196` a rule asserted and not enforced;
   `ADR-0282` an authoritative document no gate read; `ADR-0287` a policy describing compiler
   enforcement with no compiler enabled; and now a test suite with no caller. **Something
   exists, and nothing runs it.**

   **Next**: a re-derived queue.

   **Increment (iii): `ADR-0290`, `VOX-ERR-004` discharged — queue re-derived first.** 1158
   tests / 208 suites (was 1152/207); no source changed.

   **Derivation**: 23 entered-milestone rows have **no record, no test, no source mention**.
   Picked the oldest `P0` with `T` alone and no gate: `VOX-ERR-004` (M3) — *"Unsupported
   diagnostic behaviour shall fail explicitly rather than silently select preview
   behaviour."*

   **Reading it precisely mattered.** "Preview behaviour" reads as a vague adjective until
   the baseline is searched for the word: **`VOX-EXE-011`** names four execution policies —
   *reference, diagnostic, interactive, preview* — and `ProvenanceValidationClaim` names
   `preview` beside `diagnosticReady`. So the row is **specific**: a diagnostic request that
   cannot be served gets a typed refusal, never a quieter substitute under the same name.

   **The product already does it, systematically**: **38 typed `unsupported*` cases**, none
   with a payload, none paired with a fallback. Two are the row's own subject —
   `VolumeRaySampler` admits **exactly one** registered quality token and refuses rather
   than sampling coarsely; and `ProvenanceValidationClaim` makes the second face
   **structural**: `preview` carries no evidence, `diagnosticReady(ValidationEvidenceID)`
   **cannot be constructed without it**, so a preview result cannot be relabelled — there is
   nothing to change it to.

   **Every refusal paired with the nearest SUPPORTED input** — a sampler rejecting every
   string would satisfy the refusals and prove nothing. **Token asserted EXACT, not a prefix
   or family**: suffixed, uppercased, truncated and space-prefixed near-misses all refused,
   because a forgiving match would let a near-miss name select the diagnostic path by
   accident. **Claim vocabulary asserted non-`Comparable` with a positive control on
   `Int`** — if it were orderable a caller could write `max(preview, diagnosticReady)` and
   promote arithmetically.

   **Rejected**: enumerating all 38 cases (already tested where built; a suite needing an
   edit per new case rots exactly as `ADR-0289`'s SBOM counts did); scanning source for
   fallback patterns (a grep cannot tell a total function from a silent substitution);
   reading "preview" as informal (would discharge a P0 on the wrong evidence).

   **Next**: 22 entered-milestone rows remain. `VOX-R2D-003` (signed/unsigned integer input)
   and `VOX-MPR-014` (measurements use authoritative physical geometry) are the next `P0`,
   `T`-only rows with no gate.

   **Increment (jjj): `ADR-0291`, `VOX-R2D-003` discharged.** 1164 tests / 209 suites (was
   1158/208); no source changed.

   **The row's sentence is generic; the plan is not** — "Source signedness — Signed and
   unsigned", validation fixtures for "synthetic **signed** 16-bit CT" and "synthetic
   **unsigned** 16-bit CT", and "correct signedness" among acceptance items. CT arrives both
   ways.

   **`WindowLevelOperation` admits exactly `uint8`/`int16`/`uint16`** and branches on
   signedness: `Int64(Int16(bitPattern:))` **sign-extends** where `Int64(UInt16)`
   **zero-extends**. Implemented, untested.

   **The central test uses ONE bit pattern under BOTH declarations**: `0xFC18` is `-1000` as
   `int16` and `64536` as `uint16`. Under a window centred on zero the signed reading is
   **black** and the unsigned **clamps white** — both asserted exactly. A pipeline ignoring
   signedness returns identical bytes. **Control**: below `0x8000` sign extension is a no-op,
   so the two paths must agree **exactly** — without it the divergence is equally consistent
   with two unrelated paths that happen to differ. Plus `Int16.min` (`0x8000`, where a naive
   negation traps) and the unsigned maximum.

   **TWO FIXTURE FAULTS OF MINE, both caught by running not reading:**
   1. **Byte order must be declared `.native`.** Declaring `.littleEndian` — which is what
      the layout *actually is* here — was refused `byteOrderMismatch`: the binding and
      descriptor must agree on the **declaration**, not on the resulting bytes.
   2. **The refusal test was asserting the WRONG GUARD.** Sizing every buffer at 2 bytes per
      sample made `float32`/`int64` fail `incompatibleBinding` in the **storage contract**
      before `WindowLevelOperation`'s scalar admission ever ran — **it passed for the wrong
      reason**. Sizing from the binding is what makes it reach the guard it names. Same
      lesson as `ADR-0290`'s exact-token assertions: **a refusal is only evidence when you
      know which refusal fired.**

   **Next**: 21 rows remain; `VOX-MPR-014` (measurements use authoritative physical geometry)
   is the next `P0`, `T`-only, ungated.

   **Increment (kkk): `ADR-0292`, `VOX-MPR-014` discharged — AND THE SUITE CRASHED THE TEST
   PROCESS, EXPOSING A REACHABLE TRAP IN VOXELIA'S OWN CODE.** 1172 tests / 210 suites (was
   1164/209).

   **The chain**: pixel → `PickResolver` → `Point3D` → `MeasurementConstruction`. The
   resolver maps a viewport index through the **presented geometry's own** `indexToWorld`,
   and `MeasurementConstruction` takes `Point3D` and **never sees a viewport** — so
   screen-pixel measurement is not discouraged, it is **unconstructible**.

   **THE DEFECT.** Writing the suite produced `Fatal error: Index out of range`.
   `PickResolver` builds its index array from **exactly two** values (viewport x, y) then
   reads `indices[imageAxis]` for every axis in the claim — but `SpatialAxisMapping` admits
   **one to three**. A claim naming a third axis, or naming axis 2 directly as `[2, 0]`,
   **read out of range and TRAPPED**. Every value is constructible through public API:
   `SpatialAxisMapping(imageAxes: [0,1,2])` is admitted, `AffineGridGeometry` accepts it,
   `PresentationProvenance` carries it, `PickResolver.resolve` is public. **Reachable, not
   theoretical** — and a trap is the one outcome the typed-refusal discipline exists to
   prevent. Same shape as `ADR-0273`'s dependency finding, except **this one is ours**.

   **Fixed** with `InteractionError.presentationGeometryNotPlanar` — a **distinct case, not
   a reuse** of `presentationNotCalibrated` (that means *no* claim; this means a claim a 2D
   pick cannot consume, and collapsing them loses the difference — the conflation `ADR-0272`
   refused when it chose a three-way verdict over a `Bool`). **Not `nil` either**: that
   would quietly treat a malformed claim as an absent one. **Positive control**: single- and
   two-axis claims including transposed `[1,0]` still resolve, so the guard discriminates on
   whether an index exists rather than rejecting every mapping.

   **The tests falsify §33.5 directly**: identical pixels under spacings differing 4×, giving
   **40.0 mm vs 10.0 mm** — a screen-distance pipeline returns the same number for both.
   Length asserted **exactly** at four spacings incl. a 3-4-5 diagonal so the root is exact
   and **no tolerance appears anywhere**. Uncalibrated view → **no physical position** while
   the pick still succeeds and reports its source index. **View independence** (§33.3): pixel
   8 at 2 mm and pixel 32 at 0.5 mm produce the **same `Point3D`**.

   **`ADR-0125`/`ADR-0129` NOT edited** — correction recorded here, in the commit and here.

   **Next**: 20 rows remain from the sweep.

   **Increment (lll): `ADR-0293` opens the analytical phantom arc (`VOX-VAL-003`).** No
   code; 1172 tests / 210 suites unchanged.

   **THIS ROW IS DIFFERENT FROM THE LAST THREE.** `VOX-ERR-004`, `VOX-R2D-003` and
   `VOX-MPR-014` were each **implemented and untested** — those increments supplied the `T`
   and changed no source. **`VoxeliaValidation` is a shell**: `Public/` and `Internal/` are
   both **empty**, the target holds only `ApplePlatformGate.swift` and `Module.swift`, and
   **no phantom exists anywhere**. So this row needs **construction**, not verification. One
   thing is already right: the target depends on `VoxeliaCPU` **and** `VoxeliaMetal` —
   exactly the position §55.1's "CPU–Metal difference" purpose needs.

   **Plan §55 specifies FIVE phantoms with formulas, not descriptions**: linear ramp
   `2i + 3j − 5k + 100`; physical ramp `x + 2y − 0.5z`; fiducial points; distance endpoints;
   padding border. §46.2's exit criterion: "known phantoms produce the expected CT values and
   physical distances **independently of windowing and zoom**."

   **Mapped to the row's three kinds** (not one-to-one): **spatial** = physical ramp +
   fiducials; **intensity** = index ramp + padding; **measurement** = distance endpoints. The
   row discharges when all three kinds have a phantom *and a test that consumes it* — not
   when five types exist.

   **FOUR numeric boundaries identified, and TWO explicitly declared NOT to need a
   specification** — so the arc doesn't manufacture ceremony for exact integer arithmetic:
   §55.1 is integer throughout and no order can change it; §55.2 **does** need one
   (binary64 summation order is observable, plus quantisation — composing `ALG-0002`'s
   ties-to-even rather than restating it); §55.5's sentinel **must not collide** with a
   legitimate sample or a padding test passes for the wrong reason; §55.4's endpoints need
   **Pythagorean triples** so distances are exact rather than forcing a tolerance.

   **Order chosen for a reason**: index ramp first (exact, unblocks intensity), then the
   **distance phantom second — because `ADR-0292` has just verified the measurement chain it
   feeds, so it arrives with a tested consumer**, then the physical ramp design-first.

   **Frozen**: a phantom is a **value generated from its formula**, not a fixture file — the
   formula is the artefact and nothing can drift; and phantoms are **public**, because a
   phantom locked in a test target cannot serve the validation reports this project
   publishes.

   **Next**: §55.1's linear ramp volume — `VoxeliaValidation`'s first public surface.

   **Increment (mmm): `ADR-0294` — §55.1's linear ramp built; `VoxeliaValidation` has its
   FIRST PUBLIC SURFACE.** 1180 tests / 211 suites (was 1172/210).

   **The test is written TWICE, on purpose.** The suite transcribes the plan's formula
   **independently** rather than calling into the type — a test that asked the phantom what
   it contains and compared the answer with itself **would pass for any formula at all**,
   including a wrong one.

   **Range CHECKED, not bounded by a derived constant**: the ramp rises in `i`,`j` and falls
   in `k`, so its extremes sit at **opposite corners**; both computed in `Int` and refused if
   either escapes `Int16`. A constant like "at most 6,574 slices" is correct only for these
   coefficients and would silently go wrong if they changed.

   **Non-cubic fixture `7×5×3` on purpose**: `ALG-0050` says outright that `row * columns`
   and `row * rows` **agree for every square frame** — so a cubic phantom is blind to exactly
   the addressing mistake that spec exists to catch.

   **Negatives exercised deliberately**: `−5k` takes the ramp below zero past slice 20, and a
   **zero-extending encoder would turn those into large positives**. A shallow phantom would
   never detect it — so 40 slices, asserting `−95` and `−90` exactly.

   **Refusals carry a positive control**: the largest extents that DO fit are admitted —
   **16,334 columns → exactly 32,766**, **6,574 slices → exactly −32,765** — so the overflow
   refusals discriminate on **range**, not size. Both hand-computed and passing first run.

   **No tolerance anywhere in the suite**, because nothing in it is inexact.

   **`VOX-VAL-003` NOT discharged** — this supplies the **intensity** kind only; spatial and
   measurement remain, and the row needs all three *with tests that consume them*.

   **Next**: §55.4's distance phantom — placed second by `ADR-0293` because `ADR-0292` has
   just verified the measurement chain it feeds, so it arrives with a tested consumer.

   **Five owner decisions still open**: report approval, reference hardware, tolerance
   profile, geometry tolerance rule, and the two `LICENSE` files.

   **Increment (nnn): `ADR-0295` — §55.4's distance phantom; the MEASUREMENT kind of
   `VOX-VAL-003`.** 1194 tests / 212 suites (was 1180/211).

   **A FALSE EXACTNESS CERTIFICATE, found before it was ever used.** The obvious way to
   certify a length as exact is to square the root back — admit when `fl(√s)² == s`. It is
   **wrong, and it fails at the smallest scale**: `s = 11` passes the round trip and `√11` is
   irrational. Eleven is not contrived — it is the squared length of the delta `(1, 1, 3)`, an
   entirely plausible oblique segment. Under that certificate the phantom would assert wrong
   expected distances **and no test could see it**, because the phantom is the oracle.

   **So the certificate is an INTEGER IDENTITY**: `a² + b² + c² = d²` checked in `Int`. The
   frozen table is four Pythagorean quadruples in whole millimetres — `(3,4,0)/5`,
   `(1,2,2)/3`, `(2,3,6)/7`, `(1,4,8)/9` — and the tests **re-derive the identity from the
   endpoints** rather than trusting the declared length. The falsification of the round trip
   is itself a test, not a claim in prose.

   **Frozen in PHYSICAL space, not index space.** The plan says *known physical distances*, so
   the distances must not depend on the sampling. Index separations are derived by dividing by
   spacing, which turns "does this endpoint land on a sample" into a check the phantom
   performs rather than an assumption it makes.

   **Spacing must be a POWER OF TWO** (`2⁻¹⁰…2¹⁰`) and the **origin an integer ≤ `2³⁰`**.
   Division by a power of two is exact, so integrality of the quotient is a real alignment
   test rather than a rounded one; together they keep every coordinate a dyadic rational
   spanning ≤ 42 significant bits, so the whole chain origin → measured length is exact in
   binary64. Probed at **both origin extremes**, not asserted.

   **Every z component of the table is EVEN** — so the realistic anisotropic case (0.5 mm in
   plane, 2 mm between slices) stays voxel-aligned. A phantom that only worked isotropically
   would not resemble the data the measurement path actually sees.

   **Both per-axis fallacies falsified on every segment**: summing axis distances gives
   `7,5,11,13` against the true `5,3,7,9`; longest-axis gives `4,2,6,8`. An axis-aligned
   segment would let both mistakes pass — which is why **none is in the table**.

   **Sampling invariance in one assertion**: halving the spacing doubles every index
   separation and leaves the measured distance identical.

   **The measurement runs through the SHIPPED `MeasurementConstruction`** (`ALG-0010`,
   composed not restated), compared with `==`. No length is computed inside the test.
   `VoxeliaValidationTests` gains a `VoxeliaInteraction` dependency for that; test targets are
   outside `check_package_graph.py`'s layered graph by design, so the library graph is
   unchanged.

   **My extents test refused NOTHING at first** — the reference fixture `9×12×7` has a sample
   of slack in every axis, so the triples chosen as "one short" were all still large enough.
   Boundary now pinned at the true minimum `8×11×6`.

   **`VOX-VAL-003` STILL not discharged** — intensity (`ADR-0294`) and measurement (this) are
   in; **spatial remains**.

   **Next**: §55.2's physical-coordinate ramp, **design-first with a `VOXELIA-ALG`
   specification and an independent oracle** — its summation order AND its quantisation are
   both observable, unlike either phantom built so far.

   **Increment (ooo): `VOXELIA-ALG-0053` + `ADR-0296` — §55.2's physical ramp, DESIGN-FIRST;
   the SPATIAL kind of `VOX-VAL-003`.** 1208 tests / 213 suites (was 1194/212).

   **The order is observable in the PUBLISHED INTEGER, not just the bits.** The oracle was
   written and run before any Swift. Fixture D — a 3-4-5 rotation with a non-dyadic `0.3`
   slice spacing — has two samples where a rival association rounds to a different value:
   `(2,1,2)` frozen `4.500000000000001`→`5` vs right-assoc `4.5`→`4`; `(3,3,2)` frozen
   `7.5`→`8` vs right-assoc `7.499999999999999`→`7`. **That is why the spec exists**, and it
   also shows why §55.1 and §55.4 correctly have none — neither has an order anyone could
   disagree about.

   **All twelve fixture and geometry tests passed FIRST RUN** — the Swift evaluation
   reproduced the Python oracle exactly. That is what design-first is supposed to produce.

   **Composed, not restated**: index→patient is `ADR-0138`'s frozen forward evaluation
   (translation FIRST, then ascending slots); rounding is `ALG-0002`'s ties-to-even; affine
   admission is `ALG-0052`'s exact structural test. **Which accumulation applies is NAMED** —
   Voxelia has two that differ in where the translation lands (`ADR-0138` first,
   `ALG-0052` last), so naming it is part of the spec, not a detail.

   **REFUSED, not clamped**, departing from `ALG-0002` deliberately: saturation is what a
   display window *means*; for a phantom it would publish an expected value that is not the
   ramp's value.

   **Rounding asserted against its RIVAL**: fixture A's rows are `1.0,1.5,2.0,2.5` and
   `2.0,2.5,3.0,3.5` pre-round; the suite asserts both the ties-to-even result and that it
   differs from ties-away. Fixture C adds a **negative** half, `−0.5`, which ties-away would
   send to `−1`.

   **Two of my own expectations were wrong and the suite caught both.** The identity at
   `(1,1,1)` is `2.5` → ties to the even **2**, not 3. And a test claiming an interior sample
   could escape `Int16` while every corner fits was **UNCONSTRUCTIBLE** — the composed value
   is affine in the indices, so no such geometry exists. Replaced by a test asserting the
   property that makes corner admission sound: the extreme over the whole box equals the
   extreme over the eight corners.

   **`VOX-VAL-003` STILL NOT DISCHARGED — and the reason matters more than the outcome.**
   All three kinds now have a phantom, but the tests are NOT equal: only §55.4's is fed into
   **shipped product code** (`MeasurementConstruction`). §55.1's and §55.2's suites verify
   that the phantom is what it claims to be — necessary, and not the same thing. Plan §46.2's
   criterion is about a **pipeline**, so discharging on three self-verifying suites would
   claim it on evidence that never runs one.

   **Next**: drive the §55.1 ramp through **value transformation** and the §55.2 ramp through
   an **oblique reconstruction**. Both small now the phantoms exist; both are what the row
   actually needs.

   **Increment (ppp): `ADR-0297` — phantoms through the SHIPPED pipelines; `VOX-VAL-003`
   DISCHARGED.** 1212 tests / 214 suites (was 1208/213). **No source changed** — this is the
   `T` the row declares.

   **Intensity**: §55.1 ramp → `WindowLevelOperation` twice with windows that disagree
   everywhere (`[100,102,104,106,108,110]` vs `[0,27,54,81,107,134]`) → `CTSampleInspector`
   returns the SAME CT values under both, equal to the phantom's closed form. That is plan
   §46.2's first clause instantiated, not paraphrased.

   **Spatial**: §55.2 ramp → `WindowLevelOperation` → `ObliqueSliceOperation` on a plane that
   is **not axis-aligned**, and the expected result is available **in closed form**:
   `value(u,v) = 10 + 2u − v`. Whole plane asserted with `==`, **no tolerance**.

   **The identity window makes it possible.** The oblique op admits only `uint8`, so the
   `int16` phantom must pass through window/level first — and a rescaling window would leave
   the reconstruction validating a *copy* of the phantom. Under `ALG-0002`, **c=128 w=256
   reduces exactly to the identity**, asserted over the ENTIRE `0...255` range (256 values,
   all mapping to themselves), not inferred from a couple of rows.

   **Why it is exact**: every odd output column lands at volume row `u/2` — **not** an integer
   index, so a genuine trilinear blend with weights of exactly one half. Trilinear reproduces
   an affine function exactly, and half-weights on small integers are exact in binary64.

   **Falsified against the mistake it could hide**: a pipeline ignoring the in-plane `y` step
   would publish `10 + u − v`, differing at every column past the first.

   **FINDING — a planar request with a zero out-of-plane column is REFUSED.** Building the
   request the obvious way (two in-plane directions in slots 0 and 1, zeros in slot 2 because
   the sampling loop never reads it) throws `singularTransform`. `AffineGridGeometry` demands
   an invertible matrix; the sampling loop's indifference to slot 2 does not extend to
   admission. Fix: supply the plane normal `(1, −2, 0)`, which moves **not a single sample**.
   Exactly the shape a caller assembling an MPR request from two direction cosines will hit.

   **§55.3 fiducials and §55.5 padding are deliberately NOT built** — `ADR-0293` scheduled
   them "as their consuming rows need them", and no row currently does. Building them now
   would be manufacturing coverage.

   **18 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (qqq): `ADR-0298` — DICOM-derived geometry validated WITH the phantoms;
   `VOX-VAL-012` DISCHARGED.** 1218 tests / 215 suites (was 1212/214). **No source changed.**

   **What was already covered vs what was not.** `CTAffineVolumeBuilder` has a twelve-test
   suite against `ALG-0049`'s frozen fixtures — **that checks the matrix**. Nothing checked
   the **consequence** of the matrix: that a phantom placed by the derived geometry lands
   where its closed form says, and that the distances between its endpoints are the known
   ones. A matrix can be right element by element and still be consumed by nothing.

   **"Known dataset" means synthetic, and that is not a compromise.** A known dataset is one
   whose correct answer is known *independently* — real acquisition data does not have that
   property, since its true geometry is precisely what one would be establishing. Plus the
   standing constraint: no repository test reads patient data. The row's word is **known**,
   not clinical.

   **The closed form is written from the DICOM INPUTS**, not read back from the builder's
   matrix — comparing the matrix with itself would pass for any builder. Datasets run through
   the real path: `CTSeriesAssembler` → `CTGeometryValidator` → `CTAffineVolumeBuilder`.

   **The spacing choice is a deliberate trap-avoidance.** `ALG-0053` weights patient Y by
   **2**, so `columnSpacing == 2 × rowSpacing` would make a transposed axis pairing produce
   IDENTICAL samples — invisible. Equal spacings hide it too. Chose cs=1, rs=2 → derived
   `10 + i + 4j − k`; a transposed builder gives `10 + 2i + 2j − k`. **Falsified with a second
   dataset**: 11 vs 12 at (1,0,0), 14 vs 12 at (0,1,0).

   **Physical distance validated from the DICOM side**: a 0.5 mm / 2 mm acquisition is exactly
   `DistancePhantom`'s admitted configuration, so the phantom is built from spacings and
   origin **read out of the derived matrix**, and its lengths 5/3/7/9 measured through the
   shipped `MeasurementConstruction`. A coarser acquisition changes every index separation and
   leaves the lengths identical.

   **Verdict asserted, not assumed** — a phantom placed by a geometry the validator merely
   *tolerated* would validate against a dataset the product would flag. `.exact` tolerance,
   `representable`, zero findings.

   **17 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (rrr): `ADR-0299` — lossless equality + random-access correctness;
   `VOX-VAL-013` DISCHARGED.** 1224 tests / 216 suites (was 1218/215). **No source changed.**

   **THE REPOSITORY HAD NEVER RUN THE CODEC.** `VoxeliaCompression` links `J2KCodec` and
   `J2K3D`, and every existing suite covers the vocabulary around them — scopes, payloads,
   destination admission, header budgets, the adapter — with **every** `J2KVolume`
   constructed by hand. No test encoded anything; no test decoded anything. `ADR-0271`
   measured region decode, but in a **scratch** harness, and a measurement is not a
   correctness test.

   **The fixture is a POSITIONAL phantom**: every voxel holds `100i + 10j + k`, so its value
   **names its own index**. Extents all below ten so the place values never carry —
   **injectivity asserted, not assumed**. That is the whole design: a region decode returning
   the right *shape* from the wrong *offset* is invisible against random bytes and immediate
   against this.

   **Lossless asserted BYTE-FOR-BYTE**, not sample-wise with a tolerance — that is what the
   word means. **Plus a separate value-exact assertion**, because byte equality alone would
   hold even if the codec read every sample in the wrong byte order: it would write them back
   the same way and the bytes would still match.

   **The region is deliberately NOT at the origin** — a `(0,0,0)` region is returned correctly
   by a decoder that ignores the offset entirely. Compared against `decodedRegion`, not the
   requested region, so a clamped or expanded result is checked where it actually landed.

   **Tile counts asserted EXACTLY: 1 decoded, 7 skipped** of an 8-tile grid. `tilesSkipped > 0`
   would also pass for a decoder that skipped one tile and decoded the rest — which is not
   random access.

   **All six passed first run.** On this fixture `J2KSwift`'s JP3D path is correct in both
   respects. Worth stating plainly because `ADR-0272`/`ADR-0273` recorded real defects in the
   same dependency — those findings stand; this records a different part of the surface
   behaving correctly under test.

   **16 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (sss): `ADR-0300` — CPU↔Metal differential; `VOX-VAL-006` **T** discharged,
   **R** left with the owner.** 1229 tests / 217 suites (was 1224/216). **No source changed.**

   **The sweep was WRONG about this row, and I checked before writing.** `ADR-0290` listed it
   untouched — true of the **records**, false of the **tests**. All three diagnostic Metal
   kernels already had an analytical comparison: window/level against `ALG-0002`'s model,
   invert against `255 − x` over all 256 values, composite against `ALG-0009`'s model. They
   were simply **tagged to other rows** (`VOX-PLT-011`, `VOX-MTL-016`, `VOX-VAL-007`).
   Reporting "unverified" would have been the easier claim and the false one.

   **What WAS missing: the CPU leg.** Every one of those references is a model **transcribed
   into the test file**. If a transcription and the shipped CPU operation drifted, the Metal
   suite keeps passing while the product disagrees with itself — and NOTHING compared
   `WindowLevelOperation` ↔ `MetalWindowLevelOperation`, `InvertDisplayOperation` ↔ its Metal
   twin, or `CompositeLayersOperation` ↔ its Metal twin.

   **Compared at the OPERATION level**, not the kernel level — the kernels were already
   covered; the operations are what callers use. **Input is the analytical phantom**, giving a
   third leg: CPU==GPU is *consistency*, both==closed form is *correctness*.

   **Window/level and invert asserted BYTE-EQUAL, no tolerance.** Composite deliberately is
   **not**: the GPU composites in float32, the CPU in binary64, and `ADR-0096` already
   measured and bounded that at **one code value with a 99% exact floor**. The test
   **composes that accepted bound** rather than inventing a tolerance — the only tolerance in
   the suite, and the record it comes from is named.

   **The differential is shown able to FAIL**: two windows that genuinely disagree must
   produce differing bytes on both backends, else asserting equality proves nothing.

   **`R` NOT claimed.** Review is human judgement. What the owner is asked to review is
   concrete: whether a one-code-value CPU↔GPU composite divergence is acceptable for
   diagnostic use. Evidence is in place; the judgement is not mine.

   **15 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (ttt): `ADR-0301` — the test-level taxonomy ENFORCED; `VOX-VAL-001`
   discharged (I+T).** 1229 tests / 217 suites, unchanged — retagging and a gate, no
   behaviour change. **No source changed.**

   **FIFTH instance of "something exists and nothing runs it"** — after `ADR-0196`,
   `ADR-0282`, `ADR-0287`, `ADR-0289`. Measured before deciding anything: of the row's six
   named levels, only **unit** and **integration** had a tag. **kernel, operation, pipeline
   and system-reference had NO tag at all** — their tests existed but were all labelled
   `Unit`, so nothing could tell whether a level had coverage. Three unnamed tags were in
   use, one of which — **`Boundary` — appeared exactly ONCE in 1,229 tests**. That singleton
   is the finding in miniature: an unenforced vocabulary does not stay a vocabulary.

   **`Concurrency` and `Oracle` ADMITTED, not rewritten** — each marks a real distinction the
   six do not cover, and rejecting them would delete information to satisfy a word count.
   `Boundary` was **not** admitted: one occurrence is a slip, retagged `Kernel` where it
   belongs.

   **Three rules; two clean from day one** (vocabulary closed, all six levels non-empty) and
   **one RATCHET** for the 219 untagged tests across 27 files — explicit debt baseline that
   may shrink, never grow. Follows `check_requirement_traceability.py`'s own precedent
   deliberately: a clean gate would have been red on landing and switched off.

   **THE GATE IS PROVEN ABLE TO FAIL** — all three rules run against deliberate violations
   before wiring in: `[Bogus]` tag → exit 1; extra untagged test → "above its baseline of 1"
   → exit 1; required level removed → exit 1. A gate that has never failed is a gate nobody
   has tested, which is exactly how the four earlier omissions survived.

   **Levels established by retagging whole unambiguous suites** (125 tests): Kernel 37,
   Operation 58, Pipeline 21, SystemReference 10.

   **system-reference had ZERO members until this week** — `Tests/VoxeliaTests` is a single
   linkage assertion, not a system test. The qualifying suites are the phantom-driven ones
   from `ADR-0297`/`ADR-0298`. **Ten tests is thin and the record says so** rather than
   presenting the level as healthy; the gate makes the thinness visible instead of hiding it
   inside 959 `Unit` tags.

   **14 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (uuu): `ADR-0302` — temporary-file sites DECLARED; `VOX-SEC-005` discharged
   (I+T).** Six python self-tests; Swift suite unchanged at 1229/217. **No source changed.**

   **Measured first: ZERO hits across 242 product sources** for every temp spelling —
   `temporaryDirectory`, `NSTemporaryDirectory`, `itemReplacementDirectory`, `mkstemp`,
   `mkdtemp`, `tmpfile`, `tmpnam`, literal `/tmp` and `/var/tmp`. `Tools/`, `Benchmarks/`,
   `Validation/` also clean. `FileManager` appears in `Sources/` exactly **4** times, all
   existence/attribute queries in `CanonicalDocumentStore`, which writes only to a
   caller-supplied directory it "never creates implicitly".

   **The finding: the property held BY ACCIDENT.** Nothing documented it; nothing stopped the
   next increment adding a temp file silently. A requirement reading "explicit, documented and
   configurable" is not satisfied by a codebase that merely happens to create nothing today.

   **A declaration requirement, NOT a ban** — banning would be easier to enforce and would
   answer a *different* requirement than the one written. Any site in `Sources/` must be
   declared with `path:line`, the authorising record, and how a caller configures it.

   **Clean gate, not a ratchet.** `ADR-0301` needed a ratchet for its 219-test backlog; here
   the backlog is nothing, so the stricter form is available and used.

   **Proven able to fail** — undeclared site probe → reported by file and line, exit 1. Plus
   self-tests: declared passes; a declaration for a *different* line does **not** excuse this
   one (moving a site is caught, not silently inherited); **all NINE spellings detected**, so
   a pattern cannot be listed and be dead; clean source passes; live repo passes with zero
   declared sites.

   **Tests deliberately out of scope** — three legitimate scratch dirs would need permanent
   declarations, diluting a list whose value is being short and product-facing.

   **13 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (vvv): `ADR-0303` — headless rendering ENFORCED; `VOX-HLS-001` **T**
   discharged, **D** left with the owner.** 1229/217 unchanged. **No source changed.**

   **Measured: ZERO windowing hits in `Sources/`** — `AppKit`, `UIKit`, `SwiftUI`,
   `MetalKit`, `CAMetalLayer`, `NSWindow`, `UIWindow`, `MTKView`. The product is headless in
   fact, and the 21 byte-exact off-screen renders (now `[Pipeline]`) are what shows it.

   **I CORRECTED MYSELF BEFORE WRITING.** My first read reported `VoxeliaMetal` forbidding
   **nothing** — wrong. It forbids `DICOMKit`, `RealityKit`, `ModelIO`, `CoreImage`,
   `VoxeliaCompression`; the entry spans several lines and my single-line regex missed it. Read
   it directly before claiming a defect.

   **The real gap is narrower and sharper**: every other target forbids `MetalKit`;
   **`VoxeliaMetal` does not** — the one target that talks to the GPU, and the one where an
   `MTKView` would plausibly be reached for. `AppKit`/`UIKit`/`SwiftUI` were forbidden in
   `VoxeliaInteraction` **alone**. The property held, and was enforced everywhere except where
   it mattered most.

   **Applied UNIFORMLY over all targets**, not pasted into eleven sets — eleven near-identical
   edits are eleven chances to omit one, and that failure mode has already happened once here.

   **Proven able to fail**: `import MetalKit` added to `MetalSliceRenderer.swift` → reported by
   path, exit 1. Before this change it would have passed.

   **`D` NOT claimed** — the ledger's own standing rule says byte-exact off-screen renders
   discharge **Test, never Demonstration**. Joins `VOX-VAL-006`'s `R` on the owner list.

   **12 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (www): `ADR-0304` — interaction state ownership; `VOX-ARC-009` **I**
   discharged, **R** left with the owner.** 1229/217 unchanged. **No code added at all.**

   **Measured**: `VoxeliaInteraction` publishes **24 public types** across 5 files — commands
   (`InteractionCommand`, `MeasurementCommand`), state (`CrosshairState`, `ViewportSyncGroup`,
   `ClipBox`, `ZoomFactor`, `PanDelta`, `RotationAngle`, `RenderGeneration`), resolution and
   presentation, four measurement values, one error family. **Nothing outside holds
   interaction state**: the only candidate, `MPRSliceCoordinator`, uses the *word* crosshair
   while mapping a world point to a slice index — geometry, no state, never names an
   interaction type.

   **The `I` was DELIVERED (by `ADR-0111` and successors); no record ever CLAIMED it.** Same
   shape as `VOX-VAL-006`: evidence existed, the record trail didn't point at it.

   **NO NEW GATE — deliberately.** Both properties are already enforced:
   *UI-framework-neutral* by `check_prohibited_imports.py` (and `ADR-0303` made it uniform),
   *owns* by `check_package_graph.py` pinning the graph exactly — only `Voxelia` depends on
   `VoxeliaInteraction`, so no other module can grow a second copy callers would reach. **A
   gate whose condition another gate guarantees is a gate that gets deleted the first time it
   is inconvenient.**

   **`R` NOT claimed**, and it is concrete: whether the four measurement value types belong in
   an interaction module or a spatial one. They are constructed by interaction commands and
   consumed by presentation — defensible, and not the only defensible placement. **Deciding it
   unilaterally would spend the owner's decision for them.**

   **Owner list now: 3 verification items** — `VOX-VAL-006` R (composite one-code divergence),
   `VOX-HLS-001` D (off-screen demonstration), `VOX-ARC-009` R (measurement-type placement).

   **11 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (xxx): `ADR-0305` — opens `VOX-MTL-009` (A,T,D). NOTHING DISCHARGED.**
   1229/217 unchanged; no code.

   **The mechanism is precise and worth stating**: `MetalResidencyManager.selection(for:)`
   maps `.automatic`/`.shared` → `.shared` **only if the device reports unified memory** (else
   typed `sharedStorageUnavailable`); `.gpuOptimised` → `.privateDevice`; `.cpuOnly`,
   `.streamed`, `.sparse` refuse by distinct cases. **On unified memory a `.shared` buffer is
   ONE allocation both processors address — the full-volume copy never exists.** The manager
   never rewrites a declared policy, so a caller asking for no duplication cannot be silently
   given one.

   **SIXTH instance of the pattern: NOTHING MEASURES DUPLICATION.** `ResidencyPolicyTests`
   covers the vocabulary and `Sendable` conformance and is tagged **`MTA-18.2` — a
   milestone-task id, not a requirement**. No test names `VOX-MTL-009`; none asserts the
   `.automatic` path avoids a copy.

   **Deliberately did NOT take the two shortcuts.** (a) Discharging `A` from the selection
   table — rejected: the table says what is *selected*, not what is *allocated*, and that
   difference IS the requirement. (b) Retagging `ResidencyPolicyTests` to the row and calling
   `T` done — rejected, and it was the tempting one: those tests assert a vocabulary exists and
   is Sendable, neither of which bears on duplication. Relabelling would put a requirement's
   name on evidence that does not address it — the exact defect `ADR-0300` had to untangle in
   the other direction.

   **The three methods are FIXED HERE** so the next increment cannot redefine them to suit
   itself. Also frozen: the measurement must not be a bare peak-memory figure, because
   `ADR-0271` established a combined run's peak is a harness artefact.

   **`D` is owner-witnessed** — a fourth item on the owner list, beside `VOX-VAL-006` R,
   `VOX-HLS-001` D, `VOX-ARC-009` R.

   **11 entered-milestone rows remain** — UNCHANGED, because this record discharges nothing.

   **Increment (yyy): `ADR-0306` — `VOX-MTL-009`'s **A** and **T** supplied; **D** stays with
   the owner.** 1235 tests / 218 suites (was 1229/217). **No source changed.**

   **The analysis**: `makeBuffer` reaches exactly ONE allocation, and its storage mode is
   decided by `selection(for:)` — `.automatic`/`.shared` → `storageModeShared`, which is **one
   range of memory the CPU and GPU BOTH address**. No host copy, no device copy; there is the
   buffer. So under the default a full-volume duplicate **does not exist at any point**.
   `storageModePrivate` **is** a duplicate and is the correct answer to `.gpuOptimised` — the
   row says *minimise*, not *forbid*, and that trade is the caller's to make.

   **The analysis has a SECOND branch, not exercised on this host**: `.automatic`/`.shared`
   require `supportsUnifiedMemory`; where false they throw `sharedStorageUnavailable`. So the
   guarantee there is **a typed refusal rather than a silent copy** — the caller learns its
   policy cannot be met instead of receiving a duplicate it never asked for.

   **Evidence is the ALLOCATED BUFFER'S storage mode, not the selection enum** — asserting the
   selection proves what the manager *intends*; `MTLBuffer.storageMode` proves what it
   *allocates*, and only the second is about duplication.

   **Each test earns its place**: the `.gpuOptimised` contrast exists because without it the
   shared assertion would pass for a manager that ignored its input entirely; "a refused policy
   allocates nothing" exists because a manager that refused the *selection* then allocated
   anyway would pass the refusal test and still duplicate the volume.

   **Three fabrications declined**: peak working set (a harness artefact per `ADR-0271`);
   `contents()` nil-checks (Metal's Swift signature is non-optional, so it would assert runtime
   behaviour the type system doesn't express); and a **stub context** for the non-unified
   branch — that would assert a hand-written double throws, which is a fact about the double.
   The branch is **named and left unexercised**, which is the honest record of what this host
   can show.

   **11 rows still remain** — the row isn't fully discharged, so the count is unchanged.

   **Increment (zzz): `ADR-0307` — `VOX-PER-006` recorded as UNBUILT, not untested.**
   1235/218 unchanged; no code, **no test written on purpose**.

   **This row is DIFFERENT from the last six.** Those were properties that held, designed for
   and unevidenced. Here: **there is no study cache** (the only caches are
   `CachePreservationRule`, `BrickResultCache`, `ContentResultCache` — none a study-level
   artefact whose *generation* has a completion to be earlier than), and **there is no
   incremental publication** — `CTImportSession.importVolume` returns ONE `CTImportedVolume`
   when every stage has finished. A test today could only assert the property is absent.

   **THE TENSION WORTH RECORDING BEFORE ANYONE BUILDS IT.** `CTImportSession` has seven
   checkpoints — `metadataRead(n)`, `grouping`, `frameValidation`, `decode(n)`, `assembly`,
   `identity`, `final` — and **they look like publication points. They are not.** They are
   cancellation probes, and `ADR-0249` decision 7 made the last load-bearing: *a caller cannot
   publish what it never receives*. An increment satisfying this row by emitting a partial
   volume at `decode(n)` would **dismantle that guarantee while looking like reuse of an
   existing seam**. The two properties are compatible — but only if the progressive path is
   built as its own thing rather than by relaxing a checkpoint.

   **Two definitions must precede implementation, and neither is mine**: what a **study cache**
   is (the row's clock starts at its generation), and what makes an image **useful** — a single
   decoded frame, a full plane, or a reduced-resolution volume are three different answers with
   three different costs, and "useful" is a **clinical** judgement about what a radiologist can
   act on, not an engineering one.

   **Owner list now SIX items**: `VOX-VAL-006` R, `VOX-HLS-001` D, `VOX-ARC-009` R,
   `VOX-MTL-009` D, plus these two definitions gating `VOX-PER-006`.

   **11 entered-milestone rows remain** — unchanged.

   **Increment (aaaa): `ADR-0308` — `VOX-API-008` **I**+**T** discharged; **D** to the owner.**
   1235/218 unchanged. **No code, no gate.**

   **The two rows are DIFFERENT claims, and separating them was the first job.**
   `VOX-HLS-001` is a **capability** (off-screen rendering is supported); `VOX-API-008` is an
   **absence of a precondition** (no public entry point *requires* a window). A library could
   satisfy the first and fail the second — an off-screen path beside a public API whose
   signature still demands a view.

   **Two facts, the second sharper**: (1) no target imports `AppKit`/`UIKit`/`SwiftUI`/
   `MetalKit`, and since `ADR-0303` none *can* — a module that cannot import a framework cannot
   name its types in a signature; (2) **`drawable`/`Drawable` appear ZERO times in
   `Sources/`**. That matters independently: a renderer returning a `CAMetalDrawable` would
   require a layer to exist even in a module importing nothing from AppKit, because the
   drawable **comes from** the layer. Fact 1 rules out *naming* a view; fact 2 rules out
   *needing* one.

   **`T` discharged by the existing off-screen renders READ FOR THIS ROW**, not borrowed: the
   21 `[Pipeline]` tests call the public rendering API in a process where no window, view or
   layer exists at all. **If any public entry point required one, they could not run.**

   **Deliberately wrote NO test and NO gate.** A test asserting "callable without a window" in
   a suite where no window can exist asserts nothing the suite doesn't already assert by
   running. A gate scanning public signatures would duplicate `check_prohibited_imports.py`;
   the one thing it would add — catching a drawable — needs `Metal` allowed and one type from
   it forbidden, **a rule that gets relaxed the first time it is inconvenient**.

   **Did NOT let `ADR-0303` silently cover this row** — that record claims `VOX-HLS-001`, and
   folding them would leave `VOX-API-008` discharged by a record that never mentions it: the
   exact untraceability `ADR-0300` had to untangle.

   **10 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (bbbb): `ADR-0309` — decision cross-references RESOLVED; `VOX-DOC-009` **I**
   discharged, **R** to the owner.** 1235/218 unchanged. **No source changed.**

   **The linkage SHAPE was enforced; its TARGETS were not.** All 288 records carry
   `## Supersession` and `check_adr_register.py` requires it — but across **850** ADR-to-ADR
   cross-references **nothing resolved a single one**, and nothing checked a cited record was
   *approved* rather than merely written.

   **SEVENTH instance of the pattern — and the first where the omission had ALREADY DONE
   DAMAGE, not just risked it.** Two links in `ADR-0183` did not resolve, and the failure is
   instructive: **the link TEXT was right and the NUMBERS were wrong, by one in each case.**
   `ADR-0058` is "Provenance record aggregate" and `ADR-0063` is "Image data aggregate"; the
   cited `ADR-0059`/`ADR-0064` are "Complete graph admission" and "Exact region extraction".
   So `ADR-0183` **named the two records it meant and pointed at two others** — for the life of
   the record.

   **Repairing them is NOT editing an accepted record's decisions**, and the record says so
   explicitly: the frozen-ADR rule exists so a decision cannot be rewritten after acceptance. A
   hyperlink contradicting the sentence beside it is not a decision — fixing it makes
   `ADR-0183` say what it always said. No decision, boundary or claim altered.

   **Status checked, not just existence.** Every ADR is `Accepted` today so that rule catches
   nothing now — **and it is the rule that matters when the first `Proposed` record appears,
   which is exactly when nobody will remember to look.**

   **Not made a ratchet**: two is not a backlog. A ratchet is for debt too large to clear in
   the increment that finds it; using one here would preserve a defect for no reason.

   **THE GATE REJECTED MY OWN RECORD on its first live run** — `ADR-0309` quotes the two
   broken links verbatim as evidence, and the checker read the illustration as a citation. Real
   false positive, fixed properly: fenced blocks are blanked **with offsets preserved** so
   reported line numbers stay true. A checker that cannot tell a citation from an illustration
   would push authors to stop showing what they found.

   **Proven able to fail** (re-proven after the fence change): `ADR-9999` link → reported by
   file and line, exit 1.

   **9 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (cccc): `ADR-0310` — documented example safety; `VOX-DOC-011` **I** discharged,
   **R** to the owner.** 1235/218 unchanged. **No source changed.**

   **WHERE the examples are was the first question, and the answer was not where it looked.**
   The DocC catalogues contain **no Swift code blocks at all**, and there is no `Examples/` or
   `Snippets/` directory. The project's examples are the **224 fenced Swift blocks in
   `docs/`** — algorithm specs, RFCs, project specs. `check_swift_safety.py` scans `.swift`
   files; **a fenced example in Markdown is not one**, so not one of the 224 had ever been
   scanned.

   **Scanning found ONE hit, and it is NOT a violation**: `UnsafeMutableRawBufferPointer` in a
   write-destination protocol. `ADR-0287` corrected an earlier over-strict reading of this
   exact rule — the policy reserves the **bare word** `unsafe`; an identifier merely containing
   it is not reserved. **Re-making that mistake inside the gate that enforces the rule would
   have been a poor way to enforce it**, so the gate documents the exclusion and cites 0287.

   **`try!` and `as!` are the substantive rules** — they turn a typed refusal into a crash,
   which is exactly "bypassing canonical validation for convenience", and **an example doing it
   teaches a reader to do it**.

   **Rejected: extracting blocks to temp files to reuse `check_swift_safety.py`** — it would
   duplicate that gate's full rule set onto prose that legitimately elides detail, AND
   `ADR-0302` forbids product code creating temporary files; adding a script that did so to
   enforce a documentation rule would be a poor precedent.

   **Clean gate, not a ratchet** — nothing to absorb, same as `ADR-0302`, opposite of
   `ADR-0301`'s 219-test carry. **Proven able to fail**: a `try!` example → reported by file and
   line, exit 1.

   **8 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (dddd): `ADR-0311` — MPS boundary; `VOX-ADP-006` discharged (I+T).**
   1235/218 unchanged. **No source changed.**

   **Measured: ZERO MPS usage anywhere**, and **`MetalPerformanceShaders` was not in the
   prohibited-import gate AT ALL**. The property held because nobody had used it; any target
   could have imported it tomorrow unopposed. **Eighth instance** of the pattern.

   **A BOUNDARY, NOT A BAN — the wording was nearly misread.** The row says MPS is
   **permitted**, *only behind validated Voxelia operations*. Forbidding it outright would be
   simpler to enforce and would answer a **different requirement** — the same trap `ADR-0302`
   avoided with temporary files. The boundary is **the module**: `VoxeliaMetal` may import it
   (the one target where a validated wrapper would live); every other target refuses it, which
   keeps MPS types out of general APIs structurally — **a type a module cannot import is a type
   it cannot name in a signature**.

   **PROVEN IN BOTH DIRECTIONS, and the second is the one that matters**: MPS in
   `VoxeliaRendering` → failed, named by path, exit 1; MPS in `VoxeliaMetal` → **passed**,
   exit 0. **A gate that failed on both would have enforced a prohibition the requirement does
   not state.**

   **Exemption is one MODULE, not one file** — a narrower rule would have to name the file a
   future operation lives in, and would be wrong the moment it moves.

   **7 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (eeee): `ADR-0312` — `VOX-R2D-001` discharged (I+T).** 1235/218 unchanged.
   **No code, no test, no gate.**

   **NO RECORD IN THE REPOSITORY MENTIONED `VOX-R2D-001`** — only the baseline, the
   traceability index and this ledger. Third row in the sweep (after `VOX-VAL-006`,
   `VOX-ARC-009`) whose evidence existed while the record trail pointed elsewhere.

   **Three things make it CANONICAL rather than merely present**: one protocol (`SliceRenderer`
   with `ExactSliceRenderer` its only shipped conformance), one entry point
   (`render(_:) async throws -> RenderResult`, no route that skips stages), and **named stages**
   (`RenderPublicationStage`, so provenance says which ran rather than leaving it inferred).
   `T` = the **13 `[Pipeline]` tests** in `ExactSliceRendererTests`, read for this row.

   **"Canonical" read as ONE CONTRACT WITH ONE SHIPPED PATH, not one implementation forever.**
   A second conformance is permitted by the protocol and would not breach the row; what would
   breach it is a route that **bypassed the contract**. `ADR-0300` is the evidence the two
   backends behind it do not diverge.

   **Declined to retag the 13 tests** — they genuinely evidence the rows they name, and adding
   this row's id to all of them would make a tag "everything a test touches" rather than what
   it is for. **The record is the right place for the reading.**

   **6 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (ffff): `ADR-0313` — `VOX-MPR-002` **T** discharged, **D** to the owner.**
   1235/218 unchanged. **No code, no test.**

   **`ObliqueSliceOperation`'s admission constrains STRUCTURE, not ORIENTATION** — volume maps
   `{0,1,2}`, request presents `[0,1]`, spaces match, extents `1…16,384`. **Nothing constrains
   the direction cosines**; any invertible affine is admitted, which is what *arbitrary* asks.

   **`T` = `ADR-0297`'s oblique reconstruction, read for this row**: in-plane step `(1,0.5,0)`,
   not axis-aligned, expected value **in closed form** `10 + 2u − v`, asserted with `==` over
   the whole plane, **no tolerance** — and every odd column lands half way between two volume
   rows, so it is a genuine trilinear blend, not a lookup. It also falsifies the failure this
   row cares about: ignoring the in-plane `y` step publishes `10 + u − v`.

   **THE CONSTRAINT ON "ARBITRARY" BELONGS HERE**: a planar request whose **out-of-plane column
   is zero is refused as singular**. The sampling loop reads only slots 0 and 1, so a caller
   assembling a request from two direction cosines — **the natural DICOM way** — leaves slot 2
   empty and gets `singularTransform`. Every orientation remains reconstructable (the third
   column is the cross product); it is a **calling convention, undocumented until now**.

   **Declined to default that column inside the operation** — it would silently accept a
   request the caller did not fully specify, and the singular refusal is
   `AffineGridGeometry`'s own invariant, not the operation's. **Refuse an under-specified
   input rather than complete it.**

   **5 entered-milestone rows remain** from `ADR-0290`'s sweep.

   **Increment (gggg): `ADR-0314` — `VOX-CON-008` recorded UNBUILT.** 1235/218 unchanged; no
   code, **no test written on purpose**.

   **The words `priority`/`Priority` do NOT appear in `Sources/` AT ALL** — not once, any
   spelling, any module. No `TaskPriority`, no scheduling vocabulary that could carry one.
   Nothing to propagate.

   **THE FINDING THAT MATTERS MORE THAN THIS ROW: `VOX-CON-008` and `VOX-PER-006` are blocked
   on the SAME missing artefact.** `ADR-0307` found there is no study cache. `VOX-PER-006`
   needs that stage **to have a completion**; `VOX-CON-008` needs it **to be something
   interactive work can outrank**. **One owner decision — "what is a study cache" — gates TWO
   rows**, which is worth knowing before anyone sizes it.

   **Declined to invent a priority vocabulary now**: "propagated" means carried from an
   interactive caller through to the work competing with it, and with no competing work a
   `TaskPriority` parameter would be **carried from nowhere to nowhere while looking like
   progress**.

   **Declined to claim Swift's cooperative-pool priority satisfies it** — structured
   concurrency does propagate priority through child tasks, but that is a property of **the
   language**, not of Voxelia. The row asks Voxelia to propagate it *so that* interactive work
   outranks background cache generation, and no code here creates that background work.

   **5 rows remain — unchanged**, because this discharges nothing.

   **Increment (hhhh): `ADR-0315` — `VOX-MTL-013` recorded UNBUILT on both halves.**
   1235/218 unchanged; no code, no test. Measured **half by half** because the two halves are
   in different states.

   **Half one — workload priority**: blocked, already recorded by `ADR-0314` (zero priority
   vocabulary in `Sources/`).

   **Half two — memory pressure: NO response exists.** No `DISPATCH_SOURCE_TYPE_MEMORYPRESSURE`,
   no `setPurgeableState`, no path releasing or downgrading a GPU allocation when memory
   tightens. `MetalResidencyManager` allocates and returns; **nothing later reconsiders**.

   **THE FINDING: the input the row needs is ALREADY IN HAND and consumed by NOTHING.**
   `MetalExecutionContext` reads `device.recommendedMaxWorkingSetSize` and publishes it. Every
   use: the declaration, the init parameter, the assignment, the capability read, and **two
   test lines asserting it is `> 0` and printing it**. **No allocation path consults it.** The
   budget exists as a number and nothing is bounded by it — a milder form of the pattern found
   eight times this arc: not a rule with no enforcement, but a **capability captured with no
   consumer**.

   **Closed a FALSE TRAIL**: `BrickEvictionConsideration` (`ADR-0151`) is a **CPU-side cache**
   eviction order and never touches an `MTLBuffer`. Reading it as this row's evidence would be
   reading a neighbouring subsystem's work as this one's — named explicitly so a later
   increment does not.

   **Declined to bound allocations by the budget now** — that is a two-line change, and
   choosing **what happens at the bound** is the whole requirement: refuse, downgrade
   `.privateDevice`→`.shared`, or evict. **A refused allocation is a failed render and a
   downgraded one is a slower render**, so it is a safety trade, not an engineering preference.

   **5 rows remain — unchanged.**

   **Increment (iiii): `ADR-0316` — `VOX-MTL-011` **A** discharged; **T** parked on a named
   trigger.** 1235/218 unchanged; no code.

   **THE ROW IS CONDITIONAL — "where they provide measurable benefit" — and that changes what
   discharging means.** An analysis showing the condition is NOT met is a complete answer;
   building heaps anyway would answer a requirement that says something else.

   **Measured: ZERO heaps** (`MTLHeap`/`makeHeap`/`MTLHeapDescriptor`/`heapBufferSizeAndAlign`)
   and **6 direct allocation sites**, every one scoped to a **single dispatch or request** —
   `ADR-0081` states the rule outright: buffers "remain local to each request rather than
   becoming shared manager state".

   **The analysis**: a heap earns its cost by backing **many resources with OVERLAPPING
   LIFETIMES** from one allocation — both halves of the benefit, allocation and residency,
   depend on that overlap. **Voxelia has no such set**: each buffer serves one dispatch and is
   released; a heap here would back one short-lived buffer at a time, which is direct
   allocation **with an extra object in front of it**.

   **Stated plainly as a STRUCTURAL argument, not a benchmark** — no heap-versus-direct
   measurement was taken, because the precondition for benefit is absent and measuring would
   produce a number about a configuration nobody would ship.

   **`T` parked on a NAMED TRIGGER, not dismissed**: the first allocation site keeping several
   buffers co-resident across dispatches — a brick pool, a persistent residency set, or the
   working-set bounding `ADR-0315` leaves open.

   **Distinguished from `VOX-CON-008`/`VOX-MTL-013`**: those name capabilities that do not
   exist **and should**; this names a technique that is **correctly absent**. Filing it as
   unbuilt would understate what is known.

   **5 rows remain — unchanged**, since the row is not fully discharged.

   **Increment (jjjj): `ADR-0317` — `VOX-PER-009` SPLIT; nothing discharged.** 1235/218
   unchanged; no code. **Two working sets in OPPOSITE states.**

   **Decoded-brick: BOUNDED BY CONSTRUCTION.** `BrickResultCache` takes `maximumEntryCount`
   and `maximumTotalByteCount` as **required initialiser parameters — neither has a default**,
   so an unbounded brick cache is **not constructible**, with `ADR-0151`'s frozen eviction
   order behind it. **That is STRONGER than a demonstration**: a test shows the bound held
   once; a required parameter means it cannot be absent. What's missing is the row's literal
   wording — no *large-volume* test drives it past both ceilings and observes eviction holding
   the line.

   **GPU-residency: UNBOUNDED**, per `ADR-0315` — the device budget is read and **never
   consulted**, so there is no ceiling for a test to observe.

   **NOT discharged on the brick half** — the row names both sets in one sentence, and **a
   partial discharge on a P0 row is how a gap becomes invisible**. The halves are also kept
   unmerged in evidence: one test named for this row that only exercised bricks would read as
   covering both.

   **The brick `T` is a real, small, UNBLOCKED increment** and is named as the next step —
   recording the split first means the increment that writes it **cannot quietly widen into
   claiming the GPU half**.

   **5 rows remain — unchanged.**

   **Increment (kkkk): `ADR-0318` — `VOX-PER-009`'s BRICK half discharged; GPU half still
   blocked.** 1238 tests / 219 suites (was 1235/218). **No source changed.**

   **Resident set reconstructed from the cache's OWN EVENTS**, not a private field — `decode`
   admits with a byte count, `eviction` removes with one. **Stronger than reading the
   counter**: it checks what the cache *reports to a host* against what it *promised*, so
   accounting that drifted from behaviour fails. (`totalByteCount` is `private`, which
   `@testable` doesn't reach — but reading it would test the counter against itself.)

   **Invariant checked after EVERY insertion**, not at the end — a cache that grew without
   limit and trimmed once at the end would satisfy a final-state assertion.

   **The two ceilings exercised SEPARATELY**: one run makes the byte ceiling unreachable so
   only the entry ceiling can hold the set; the other inverts it. **A run breaching both could
   not say which bound did the work.** Positive control each time: 200 bricks into 8 slots →
   **exactly 192 evictions**, so the bound held because eviction ran, not because little was
   inserted.

   **THE RUN CORRECTED ME.** I wrote the third test expecting a zero budget to admit-then-evict,
   leaving nothing resident. It throws **`resourceLimitExceeded`** instead — better behaviour
   than I assumed, and it *strengthens* the row: the cache **never admits what it cannot
   hold**, so the working set is bounded by **refusal** as well as eviction. Now asserted with
   a one-byte-either-side control: a 32-byte brick refused at a 31-byte budget, admitted at 32.

   **Row NOT fully discharged** — the GPU half stays on `ADR-0315`'s owner item, exactly as
   `ADR-0317` split it. **5 rows remain.**

   **Increment (llll): `ADR-0319` — the queue REDERIVED; MY OWN COUNT WAS WRONG.** 1238/219
   unchanged; no code.

   **I had been decrementing a COPIED SNAPSHOT, not measuring.** Records in this arc counted
   20 → 18 → 17 → … → 5 off `ADR-0290`'s list. Rederiving mechanically: **356 entered-milestone
   rows, 340 claimed in some ADR's front matter, 16 UNCLAIMED.** Sixteen, not five.
   `ADR-0290`'s list was a correct snapshot of its moment and **became a stale copy the instant
   it was written**; every increment that decremented it inherited that staleness. **This is
   the same defect the arc found eight times in code — a value asserted once and never
   recomputed — occurring in my own reporting.**

   **Criterion, stated so it can be RERUN**: a row is *claimed* when some `ADR-*.md` names it
   in `affected_requirements`. Deliberately narrower than the traceability gate, which passes
   on a **mention** anywhere. **Claimed is still not discharged** — `VOX-PER-006` and
   `VOX-CON-008` are both claimed and both recorded unbuilt.

   **The 16**: `VOX-REP-001/002/003`, `VOX-LIC-002`, `VOX-DOC-003` (M0); `VOX-DAT-002/003`,
   `VOX-SPA-010` (M1); `VOX-IMG-003/004/008` (M2); `VOX-CON-005` (M3); `VOX-ADP-003`,
   `VOX-BRK-009`, `VOX-DVR-013`, `VOX-PER-004` (M6). **Most are almost certainly implemented**
   — the repo has its directories, licence text and interpolation operations — the gap is that
   **no record names them**, same shape as `VOX-R2D-001`/`VOX-VAL-006`/`VOX-ARC-009`.

   **No gate added**: requiring front-matter claiming would be **red on 16 rows today**, and
   `ADR-0301` established what that produces — a gate nobody can land.

   **Next: the five M0 rows**, each claimed on evidence read for it. **The derivation is in the
   record so it is RECOMPUTED, not read as another list to decrement.**

   **Increment (mmmm): `ADR-0320` — four M0 rows claimed; a PARTIALLY complete gate completed.**
   1238/219 unchanged. **No source changed.**

   **Expected these to be trivial. Two were satisfied and UNENFORCED — ninth instance, and this
   time the enforcement was PARTIAL, which is harder to see than absent.**
   `check_required_files.py` covered **7 of 8** files `VOX-REP-002` names (missing
   **`CODEOWNERS`**) and **6 of 7** directories `VOX-REP-003` names (missing **`Examples`**).
   Both were **present on disk and unchecked**. A list covering seven of eight **reads as
   complete at a glance** — which is exactly why a partial omission outlives a missing gate.

   **Proven able to fail**: `Examples` moved away → exit 1; `.github/CODEOWNERS` moved away →
   exit 1. **Before this change both moves passed.**

   **A discrepancy RECORDED rather than resolved**: `VOX-REP-002` says the **root** shall
   contain `CODEOWNERS`; the file is at **`.github/CODEOWNERS`** — one of the three paths
   GitHub resolves, and the conventional one. Gate now requires it **where it actually is**.
   Moving the file or amending the row is one line **either way and not mine to pick** — the row
   is frozen text, the file is where its tooling expects. **Owner item.**

   **`VOX-DOC-003` deliberately NOT bundled** — it declares `I,R` and asks a linguistic
   question the other four do not; including it would be **four verifications and one
   assertion**.

   **12 rows remain unclaimed** under `ADR-0319`'s criterion — **recomputed, not decremented**.

   **Increment (nnnn): `ADR-0321` — British English ENFORCED; `VOX-DOC-003` **I** discharged,
   **R** to the owner.** 1238/219 unchanged. **No source changed.**

   **Nothing had ever checked spelling** — `check_document_text.py` is 30 lines and checks
   other properties. Measured: **121 American spellings across 34 files** in prose (fences and
   inline code removed). **Sampled to test the row's exemption** — "resource-limit `behavior`",
   "copy-on-write `behavior`", "duplicate-input `behavior`" — **ordinary prose, not external
   standards, not identifiers.** Tenth instance of the pattern.

   **The exemption is honoured STRUCTURALLY, not by a blessed-word list**: fences and inline
   code are blanked before scanning, so an identifier or DICOM keyword is invisible **as long
   as it is written as code**, which this project's style already does. **A word list would
   grow by argument; a structural rule does not.**

   **Code blanked, NOT deleted — newlines preserved so line numbers stay true.** Same fix
   `ADR-0309` needed after its link checker read an illustration as a citation; applied here
   **from the start** rather than after a false positive.

   **A RATCHET, not a clean gate** — 121 across 34 files is a backlog, and `ADR-0301`
   established what a red-on-landing gate produces. Counts per file; may shrink, never grow.
   **Rejected correcting all 121 now**: rewording 34 documents, several of them frozen specs
   and accepted records, bundled with the gate that would check it.

   **Proven able to fail**: `the color of the behavior is optimized` → file, count and each
   spelling with its line, exit 1.

   **THE GATE REJECTED THIS VERY RECORD** on its first live run, and the ledger entry beside
   it: I quoted the failure probe in **plain prose instead of backticks** — the exact convention
   decision 4 states — so it counted 3 spellings in a file with no baseline. **The rule working,
   not a false positive**, and worth recording that the record introducing a convention **broke
   it in the same commit**. `ADR-0309` hit the mirror image: there the *checker* was wrong about
   an illustration; here the *author* was.

   **11 rows remain unclaimed** — recomputed.

   **Increment (oooo): `ADR-0322` — two M1 shape rows claimed; `VOX-SPA-010` deliberately
   NOT.** 1238/219 unchanged; no code.

   **`VOX-DAT-002`** (variable-rank): `ImageShape` stores `extents` as `ContiguousArray<Int>`
   and **derives `rank` from its count** — rank is a property of the *value*, not the type —
   and the init is generic over any `Collection` of `Int`, so callers aren't pushed toward a
   fixed arity either.

   **`VOX-DAT-003`** (reject zero/negative): throws `nonPositiveExtent(axis:value:)` on the
   first offender plus `emptyRank`. **The refusal NAMES the axis and the value** — more than
   the row asks, and what makes a failure actionable rather than merely correct. 14 tests.

   **`VOX-SPA-010` LEFT UNCLAIMED, with the reason recorded rather than the omission.** Both
   representations exist — `ImageRegion` (integer bounds), `AxisAlignedBounds3D` (two `Point3D`
   with a space) — but whether a **conversion between them** exists, and under which frozen
   evaluation, **was not established**. **Claiming on the existence of two types would assert a
   relationship neither of them states** — and this arc has already had to untangle one row
   claimed on adjacent evidence.

   **9 rows remain unclaimed** — recomputed.

   **Increment (pppp): `ADR-0323` — `VOX-SPA-010` is HALF-BUILT; nothing discharged.**
   1238/219 unchanged; no code, no test.

   **Settled the question `ADR-0322` left open.** Index bounds exist and are used
   (`ImageRegion`, every storage read takes one). **Physical bounds exist ONLY as a type**:
   `AxisAlignedBounds3D` is **constructed nowhere except inside its own file**, by its own
   `intersection`, referenced only by ray intersection and its DocC page. **No function
   anywhere takes a shape, grid or region and produces physical bounds** — so a volume's bounds
   are not computable in physical coordinates at all.

   **THE NUMERIC BOUNDARY, FROZEN BEFORE IT IS BUILT — the obvious implementation is WRONG.**
   Transforming the index box's **min and max corners** through `indexToWorld` is correct
   **only for an axis-aligned affine**. Under any rotation — the normal CT case, and the one
   `ADR-0313` confirmed the oblique path admits — the transformed box **is not axis-aligned**
   and those two corners **are not the extremes**. The correct construction transforms **all
   EIGHT corners** and takes the axis-aligned hull. **The cheap version is correct on every
   axis-aligned fixture and quietly too small on every oblique one — a defect that passes the
   tests a hurried author would write.**

   **Also to freeze**: traversal order of the eight corners and accumulation order of min/max
   (both observable in binary64).

   **Owner item — a MODELLING choice, not an engineering one**: do a volume's physical bounds
   enclose its **sample centres** or its **sample extents**? They differ by **half a voxel per
   direction**, and choosing it silently inside an implementation is how a modelling decision
   becomes an accident.

   **9 rows remain unclaimed** — unchanged.

   **Increment (qqqq): `ADR-0324` — two M2 interpolation rows claimed; `VOX-IMG-008` NOT.**
   1238/219 unchanged; no code.

   **`VOX-IMG-003`**: `ResampleNearestOperation`, registered `org.voxelia.op.resample-nearest`,
   implementing **`VOXELIA-ALG-0008`**'s whole-sample selection, 3 tests.
   **`VOX-IMG-004`**: `ResampleLinearOperation`, registered `org.voxelia.op.resample-linear`,
   implementing **`VOXELIA-ALG-0015`**'s `bilinear-resampling/binary64-v1`, 3 tests.
   **Both are STRONGER than the rows require** — each names a **frozen specification** rather
   than an implementation choice, so "nearest" and "linear" mean a registered model with
   conformance fixtures, not whatever the code happens to do.

   **`VOX-IMG-008` LEFT, reason recorded.** It asks for resampling between explicit source and
   target **grids**; both operations resample between explicit **extents**, and whether a
   *grid* — extents **plus a geometry** — is what they accept was not established. **These are
   not the same: extents-to-extents is a PIXEL operation; grid-to-grid is a SPATIAL one.**

   **THIRD TIME in this queue that adjacent evidence would have carried a row it does not
   address** (`VOX-SPA-010`, `VOX-MTL-013` were the others) — **consistent enough now to treat
   as a standing hazard rather than a coincidence.**

   **7 rows remain unclaimed** — recomputed.

   **Increment (rrrr): `ADR-0325` — `VOX-IMG-008` is UNBUILT; hypothesis closed.**
   1238/219 unchanged; no code, no test.

   **THE TARGET IS EXTENTS, NOT A GRID.** `ResampleLinearOperation.execute` and its nearest
   sibling take `outputWidth`/`outputHeight` — **two integers**. The *source* is `ImageData`
   carrying a `spatialGeometry`, so a source grid exists; **no target grid is expressible at
   all**. They resample from a grid to a **pixel rectangle**; the row's target has **no
   parameter to receive it**.

   **`ADR-0324`'s hypothesis SETTLED and CLOSED**: `ObliqueSliceOperation` does take a target
   `AffineGridGeometry` — but it produces a **plane from a volume**, a **rank reduction**,
   where this row asks for resampling that preserves what is resampled. **Recording the
   negative stops the next increment re-opening the same guess.**

   **Two frozen boundaries named before anyone builds it**: (1) the **sample-mapping order** —
   the inverse of the target geometry composed with the source's forward map, which
   `ALG-0052`/`ADR-0138` freeze in *their own* directions, so the order **here is a NEW frozen
   decision**; (2) whether the result is defined where the target grid falls **outside** the
   source — the padding question **`ADR-0293` §55.5 was written to supply a phantom for**.

   **Recorded as UNBUILT, not merely unclaimed** — three rows in this queue were delivered and
   unclaimed; **this one is not delivered, and conflating the two would make the queue's
   remaining cost look smaller than it is.**

   **7 rows remain unclaimed** — unchanged.

   **Increment (ssss): `ADR-0326` — `VOX-CON-005` discharged on a LOCATED measurement.**
   1238/219 unchanged; no code.

   **Every unstructured-concurrency site in `Sources/` located: FOUR** — `StorageReadCoordinator`
   (`Task.detached` → `shared`), `MetadataIdentityCoordinator` (`Task.detached` → `started`),
   `BrickRequestBroker` ×2 (`Task` → `computation`) — **all in `VoxeliaExecution`**. An apparent
   fifth was **not concurrency at all**: `CanonicalMetadataJSON`'s private `EmissionTask` enum
   matched the search by name.

   **`VoxeliaInteraction` contains NONE** — the module a draw callback calls into launches no
   unstructured work, so a callback cannot inherit any from it.

   **And the four that exist are the OPPOSITE of what the row prohibits**: each binds its task
   to a name and **shares** it — the coalescing pattern, where concurrent requests for the same
   work **join one task rather than starting their own**. **A coordinator that deduplicates
   overlap is not a source of it.**

   **Refused to claim the row without locating the sites** — "the interaction module launches
   nothing" is only meaningful once the sites that DO launch have been found and read;
   otherwise it is **absence of evidence reported as evidence of absence**.

   **Eleventh property found true and UNENFORCED** — nothing stops a future increment adding
   `Task.detached` to `VoxeliaInteraction`. The prohibition (same shape as
   `check_prohibited_imports.py`) is **named as the next increment rather than half-built at
   the end of a session**, because every gate here needs its failure proof.

   **6 rows remain unclaimed** — recomputed.

   **Increment (tttt): `ADR-0327` — the gate `ADR-0326` named, BUILT with its failure proof.**
   1238/219 unchanged. **No source changed.**

   **A BOUNDARY, not a ban** (same shape as `ADR-0311`'s MPS rule): `Task.detached`, bare
   `Task {` and `Task.init` forbidden in **`VoxeliaInteraction`** — the module a draw callback
   calls into, where **a task is launched PER DRAW**. Permitted in the coordinators, where a
   task is launched **per distinct unit of work** and each binds it to a name and **shares**
   it. **Forbidding those would remove the mechanism that PREVENTS overlap.**

   **PROVEN IN THREE DIRECTIONS**: `Task.detached` in `FramePresenter.swift` → failed, named by
   file and line, exit 1; the four `VoxeliaExecution` coordinators → **passed**, exit 0;
   `EmissionTask` → **not matched**. **The second matters as much as the first — a gate failing
   on both would have turned a boundary into a ban.**

   **The third is the one a hurried version would skip, and it is the exact mistake the
   PREVIOUS increment made by hand.** `ADR-0326` found `CanonicalMetadataJSON`'s private
   `EmissionTask` enum matching a naive search; the patterns here require a **word boundary
   before `Task`**, and that immunity is **asserted, not assumed**.

   **Eleventh unenforced property CLOSED.** 6 rows remain unclaimed — unchanged, since
   `ADR-0326` already claimed this row.

   **Increment (uuuu): `ADR-0328` — `VOX-ADP-003` claimed (I+T).** 1238/219 unchanged. **No
   source changed.**

   **Recomputed the queue rather than trusting my own running total: 4 unclaimed, not the 6 I
   had been quoting** — the M0/M1/M2 claims landed more rows than the arithmetic tracked.
   `ADR-0319`'s lesson, applied.

   **The row has TWO clauses pulling opposite ways**: Model I/O is **permitted** for asset
   interchange and mesh preparation, and **forbidden** as the canonical model. **A gate doing
   only one would answer half the row.**

   **Zero ModelIO anywhere** — optional in the strongest sense. Forbidden in **9 of 11**
   targets; the two exceptions were **not** alike: `VoxeliaCPU` is where surface extraction,
   facet area and vertex normals live — **mesh preparation, which the row explicitly
   permits** — while `VoxeliaInteraction` is **neither**, and its exemption had no rationale.
   Every canonical-model target already forbade it, so clause two was protected and clause one
   was under-enforced in exactly one place.

   **Proven BOTH directions**: ModelIO in `VoxeliaInteraction` → failed by path, exit 1; in
   `VoxeliaCPU` → **passed**, exit 0. **The second is load-bearing — failing on both would make
   Model I/O unusable for the purposes the row PERMITS, a stricter rule and therefore a
   different one.**

   **3 rows remain unclaimed**, all M6 and all `T,D` — `VOX-BRK-009`, `VOX-DVR-013`,
   `VOX-PER-004`. **Each carries a Demonstration, so none can be fully discharged without the
   owner.**

   **Increment (vvvv): `ADR-0329` — `VOX-BRK-009` and `VOX-DVR-013` characterised; neither
   discharged.** 1238/219 unchanged; no code.

   **THESE TWO ARE NOT UNBUILT BY OVERSIGHT — THEY ARE UNBUILT BY AN ACCEPTED DECISION.**
   `RenderQuality` has `interactive` and `full`, and `SceneSnapshot`'s own documentation states
   the position: *"version-one renderers are deterministic single-pass, and per `ADR-0103` the
   two requests execute identically: the request is a hint … a **future** degraded interactive
   path will claim its own quality tokens"*. A `[Pipeline]` test asserts it: **"both qualities
   execute identically"**.

   **The distinction is recorded** because it matters when the work is scheduled:
   `VOX-PER-006`, `VOX-CON-008`, `VOX-IMG-008` are unbuilt with **nothing having decided they
   should be**; these two are unbuilt **because a record said so**. Filing them together would
   **invite a future increment to "fix" a deliberate design as though it were an omission**.

   **The existing test is the GUARD, not a gap** — "both qualities execute identically" will
   **fail the day a degraded path lands**, which is correct. It keeps `ADR-0103` honest while
   it holds, and is **the first thing a superseding increment must consciously replace rather
   than quietly delete**. **Refused to weaken it in advance.**

   **`VOX-PER-004` is now the only row unaccounted for** — 512³ at 30–60 fps, a measurement on
   **reference hardware the owner has yet to name**, which is already on the owner list.

   **Increment (wwww): `ADR-0330` — `VOX-PER-004` characterised. THE QUEUE IS EXHAUSTED.**
   1238/219 unchanged; no code, **no benchmark run on purpose**.

   **No frame-rate measurement exists** — `docs/benchmarks/` holds `BEN-0001` (vertical slice
   baseline) and `BEN-0002` (compression); **neither reports frames per second**, and no test
   does.

   **A frame rate is a number about A MACHINE.** This host is an Apple-silicon Mac; a figure
   measured here is a fact about **this laptop**, and the row's target is not qualified by "on
   whatever hardware happened to run the suite". **The reference device has not been named** —
   an owner decision predating this arc. Until then 30–60 fps is **either met or missed
   depending on the device, and both answers are equally true and equally useless**.

   **Producing a number anyway would be the most tempting possible fabrication** — it would
   look like progress, be arithmetically honest, and answer a question nobody asked. **Refused
   both "benchmark here and call it indicative"** (that is how a number about a laptop becomes
   a number about the product) **and "pick a plausible reference device"** (that spends the
   owner's decision to make my work look finished).

   **Not filed as unbuilt** — the renderer exists and renders; **what is missing is the
   CRITERION, not the capability**. `VOX-IMG-008`/`VOX-CON-008` are unbuilt; this is
   **unmeasured**.

   **Four measurement constraints fixed** for whoever takes it: named device; a **512³** volume
   (the row's own case, not a convenient fixture); a **clean process** per `ADR-0271` d4; and
   **the quality the frames ran at**, since `ADR-0329` records interactive and full currently
   execute identically — so a frame rate today is a **full-quality** figure and must say so.

   **EVERY entered-milestone row is now claimed, discharged, characterised, or recorded as
   unbuilt with its blocking question named.** What remains is **not a queue of unexamined rows
   but a list of OWNER DECISIONS, each attached to the row it blocks.** Next iteration **reruns
   `ADR-0319`'s criterion rather than assuming exhaustion**, since rows enter as milestones
   open.

   **Increment (xxxx): `ADR-0331` — untagged-test backlog 219 → 21 (90% cut).** 1238/219
   unchanged; **no source changed, no behaviour changed** — display strings only.

   **QUEUE CONFIRMED EXHAUSTED: 0 of 356 entered rows unclaimed.** So this turned to work
   needing **no owner decision**: the two ratchets this arc created.

   **`ADR-0301` said the backlog "shrinks opportunistically, whenever one of those 27 files is
   touched for another reason". Did it deliberately instead** — the 27 are **stable ingest
   suites**, so "whenever touched" may be **never**, and opportunistic shrinking of a 219-item
   debt is another way of saying it stays.

   **198 tagged `[Unit]`**: 206 DICOM-ingest tests over CT value types/validators/builders, plus
   13 module-linkage assertions. All unit-level — each exercises one type's construction,
   validation or refusals; the registered operations are elsewhere and already `[Operation]`.

   **`CTVolumeBridgeCompositionTests` DELIBERATELY SKIPPED (7 tests)** — its name says
   *composition*, which is what `[Integration]` describes, and **a pass whose job is to remove
   ambiguity should not resolve one by guessing.** 14 more are multi-line `@Test(` forms left
   rather than hand-edited at the end of a pass.

   **`[Unit]` is conservative, not a shrug**: reclassifying later to Kernel/Operation/Pipeline
   is a strict improvement the ratchet permits — **the tag being ABSENT was the defect**,
   because it made a level's coverage unmeasurable. `Unit` 843 → 1041, and the level counts are
   now a fair picture of the suite rather than one **missing 219 tests**.

   **Next**: the 21 remaining (7 judgement, 14 mechanical) and the **121-spelling ratchet** —
   same shape of debt.

   **Increment (yyyy): `ADR-0332` — untagged backlog 21 → **ZERO**; the ratchet is now a CLEAN
   GATE.** 1238/219 unchanged; **no source changed**.

   **All 1,238 tests carry a level**: Unit 1055, Integration 23, Operation 58, Kernel 37,
   Oracle 22, Pipeline 21, Concurrency 12, SystemReference 10.

   **`CTVolumeBridgeCompositionTests` → `[Integration]`, READ not inferred.** `ADR-0331` skipped
   it because its *name* suggested integration and a disambiguating pass **should not guess**.
   Its own doc settles it: *"an ingested CT volume is published through `PublicationCoordinator`
   and reconstructed in all three planes … the first time the ingest arc's output meets code
   written in earlier milestones … the proof that the two halves compose."* **The filename was a
   correct hint and a bad reason; the doc comment is the reason.**

   **Clean WITHOUT a rule change**: the gate already fails when a file absent from the baseline
   adds an untagged test — with an empty baseline that is **every** file. **The ratchet did its
   job and dissolved.**

   **Cleanliness PROVEN, not assumed**: untagged probe added to `VoxeliaCoreTests` → rejected;
   restored. **A ratchet that silently stopped ratcheting would look identical from outside.**

   **13 `swift format` findings recorded as PRE-EXISTING and untouched** — `OrderedImports` in
   the 12 linkage files, one `Indentation` in `Tests/Support`. **None is `LineLength`**, so this
   pass introduced none, and they are **not quietly fixed inside a retagging commit**.

   **First of this arc's three ratchets to reach zero.** `ADR-0321`'s 121 spellings and
   `ADR-0302`'s empty temp-file list stand as they were.

   **Increment (zzzz): `ADR-0333` — `Tests/` is now FORMAT-CLEAN (13 → 0).** 1238/219 unchanged;
   **no source changed**.

   **THE FORMATTER DOES NOT FIX WHAT ITS OWN LINTER REPORTS.** Ran `swift format --in-place`
   over all 13 files: **it changed NOTHING**, lint stayed at 13. `OrderedImports` and
   `Indentation` are, for these shapes, **lint-only** — reported and not corrected. **Worth
   knowing before anyone assumes a formatter pass clears a lint backlog**, and why this
   increment **edits rather than formats**.

   Fixed by hand: 11 linkage files (`@testable import` moved after plain imports, scripted
   three-line transformation, not a judgement) and `ApplePlatformGate.swift` (two `#error`
   bodies indented inside their `#if`).

   **A BACKLOG THIS UNCOVERED**: checking `Sources/` — which **no increment in this arc had
   done** — reports **29 findings** (Indentation 24, OrderedImports 4, RemoveLine 1). The arc's
   format checks have all been **per-file on changed sources**, so a whole-tree `Sources/` lint
   had never run. **Recording the number is the point of noticing it.**

   **NOT fixed here, and not for want of effort**: `Sources/` is product code under Swift 6 +
   `StrictMemorySafety`, and **24 indentation edits across it is a diff that must be read
   against the compiler**, not waved through at the end of a session that has already touched
   219 test display strings. Next increment, **one rule class at a time**.

   **Increment (aaaaa): `ADR-0334` — THE WHOLE REPOSITORY IS FORMAT-CLEAN.** `Sources/` 29 → 0,
   `Tests/` 0. Build clean, 1238/219 pass.

   **The 29 looked like product-code churn and were not.** Read by file: **5 `Module.swift`
   marker stubs** (4 OrderedImports + 1 RemoveLine) and **24 in twelve
   `ApplePlatformGate.swift` files** — two each, every one the **same shape**: an `#error(…)`
   inside `#if`, unindented, **identical to the fix `ADR-0333` already verified** in
   `Tests/Support`. **Not one finding was in a file containing algorithm or operation logic.**
   `ADR-0333`'s caution was right on the information available and **turned out not to apply**.

   **`ADR-0333`'s formatter finding REFINED, not edited there**: it concluded the formatter
   "does not fix what its linter reports". **True of some rules, not all** — run over the five
   `Module.swift` files it fixed **every one** (29 → 24), because lexicographic sorting *is* a
   formatter capability. It did **not** regroup `@testable` imports or indent a preprocessor
   directive. **Accurate statement: the formatter fixes a MEASURED SUBSET, and which subset must
   be measured rather than assumed in either direction.**

   **Verified THREE ways, not one**: lint zero over both trees, **`swift build` completes**, and
   the suite passes. **A whitespace change to files containing `#error` directives could
   plausibly have altered which branch compiled**, so the build is evidence rather than an
   afterthought.

   **Abandoned `ADR-0333`'s own plan** to split by rule class — that assumed the indentation
   findings were spread through product logic; they are **24 instances of ONE pattern in 12 stub
   files**, and splitting would produce two commits with the same one-line diff repeated.

   **Next**: `ADR-0321`'s 121-spelling ratchet — the last backlog this arc created.

   **Increment (bbbbb): `ADR-0335` — spelling backlog 121 → 15.** 1238/219 unchanged; **no
   source changed**.

   **THE BACKLOG WAS NOT UNIFORMLY CORRECTABLE, and the flat count concealed that.**
   **`ADR-0040`'s FILENAME contains `normalized`** — its `title:`, its `# ADR-0040 -` heading and
   its register row all mirror it. Prose there is correctable; **identity is not**: renaming
   would break every link in and change what the register says a record is called. The 15
   remaining are **frozen-identifier cases, not residual debt.**

   **MY PASS INTRODUCED A DEFECT AND `ADR-0309`'s GATE CAUGHT IT.** The correction **rewrote
   LINK TARGETS as though they were prose** — three records cited
   `ADR-0040-normalized-…md` and became `…normalised…`, pointing at a file that does not exist.
   `check_adr_links.py`, built two increments earlier **for an unrelated reason**, reported all
   three by file and line; restored. **Without it this ships as three dead links in accepted
   records, found by whoever next followed one.**

   **The bug is precise**: the pass protected fences, inline code and frozen headings, and **did
   not protect markdown link targets** — a link target is **an identifier that happens not to be
   in backticks**. `ADR-0321` learned a *quoted* misspelling needs backticks; **this is the same
   lesson one level down, for a misspelling that is a PATH.**

   **Two passes, deliberately**: case-sensitive first, then case-insensitive capitalising the
   replacement — **so sentence-initial forms were not mangled by a blanket substitution.**

   **Correcting spelling in an accepted record is not editing its decisions** (same distinction
   `ADR-0309` drew for a broken hyperlink). **No decision, boundary, claim or numeric value
   changed anywhere.**

   **All three ratchets this arc created are now at or near zero**: test levels **0**,
   temporary-file list **empty by achievement**, spelling **at its frozen floor**.

   **Increment (ccccc): `ADR-0336` — `VOX-DOC-003` SATISFIED; the proposed `ADR-0040` rename
   WITHDRAWN.** 1238/219 unchanged; no source changed.

   **Read all 15 hits one at a time instead of assuming.** Three were **ordinary prose** and are
   corrected: "exact `initialized` bytes" twice in an `ADR-0040` **table cell**, and
   "`serialization`" in the safety policy's list of concerns. **My previous pass skipped lines
   beginning with `|`** to protect register rows — **a table CELL can contain ordinary prose**,
   so that rule was too broad.

   **THIRD protection in this sequence correct in intent and wrong in reach** — after fenced
   blocks (`ADR-0309`) and link targets (`ADR-0335`). Each protected something real and caught
   something it should not have.

   **The remaining 12 are ALL ONE THING**: `ADR-0040`'s filename, the `title:` and heading that
   mirror it, the register row quoting both, and **8 citations of the path** from other records.

   **THE DECISION TURNS ON THE ROW'S OWN WORDING**: `VOX-DOC-003` requires British English
   *"except where external standards or **programming identifiers** require otherwise"*. **A
   record's filename IS an identifier** — what the register indexes, what `check_adr_links.py`
   resolves, what 8 accepted records cite. **So the 12 are COMPLIANT, not deferred.**

   **`ADR-0335`'s proposed rename is WITHDRAWN** — it would change an accepted record's identity
   and rewrite 8 citations plus a register row **to satisfy a rule that exempts identifiers**.
   Floating it was reasonable; **reading the clause closes it.**

   **Baseline kept at 12, not deleted** — an empty file would say the property is *clean*; a file
   listing 12 exempt cases says it is **understood**, which is what a later reader needs.

   **All three ratchets resolved**: test levels **0**, temp-file list **empty by achievement**,
   spelling **at its exempt floor**.

   **Increment (ddddd): `ADR-0337` — turned the pattern on ITSELF; NEGATIVE result, recorded.**
   1238/219 unchanged; **nothing changed**.

   **Eleven times this arc found a rule asserted with nothing running it.** Reliable enough to
   ask: **do the gates enforcing those rules actually run?** — especially the three I
   strengthened this session **on the assumption that they do**.

   **21 `check_*.py` gates exist. EVERY ONE is reachable from CI on every push.**
   `validate-docs.sh` runs 12, `validate-scaffold.sh` runs 12 (overlapping), `docc_archives` is
   named directly; **`ci.yml` invokes both shell scripts on `pull_request` and `push` to
   `main`.**

   **MY HYPOTHESIS WAS WRONG TWICE.** First reading — "seven gates run nowhere" — came from
   grepping workflows for gate **filenames**, which **misses a gate invoked through a shell
   script**. Second doubt — that the scaffold suite might be nightly-only, since the ledger says
   *"do not rerun the complete scaffold suite unless…"* — resolved by **reading `ci.yml`'s
   triggers** instead of inferring: **that ledger line is about a local development habit, not
   CI.**

   **REFUSED to publish the first reading.** It was a plausible list of seven unenforced gates
   with real-looking evidence — **publishing it would have been a fabricated defect.** The
   second and third measurements exist **because the first result was too convenient.**

   **Declined to add a gate-checking gate**, narrowly: it would be **a gate whose own invocation
   needs checking**, and the regress has to stop somewhere. A **recorded, rerunnable comparison**
   is the better stopping point.

   **The thread closes at the meta level**: eleven real defects found; turned on the enforcement
   layer itself, **none**.

   **Increment (eeeee): `ADR-0338` — THE OWNER DECISION BATCH IS ANSWERED.** 1238/219
   unchanged; the only non-record change is the `CODEOWNERS` move and its gate.

   The consolidated decision list was put to the owner with a recommendation per item;
   the owner approved all of them on 2026-08-07: *"Approve all your recommendations,
   ship at M6, restart the loop."* Recorded verbatim with each decision in `ADR-0338`.

   **What is NEWLY settled**: the reference device is named (`Mac17,4`, Apple M5,
   24 GiB, macOS 26.5.1 — `VOX-PER-004` is measurable under `ADR-0330`'s four
   constraints); study cache and first useful image are defined (`VOX-PER-006` and
   `VOX-CON-008` are now decided-to-build); **interactive refinement shall be built**
   — the owner's approval decides the question `ADR-0329` left open, so `VOX-BRK-009`
   and `VOX-DVR-013` proceed as the superseding version `ADR-0103` named as future,
   and the *"both qualities execute identically"* guard is consciously replaced, not
   quietly deleted; `voxelia.m4.ct.diagnostic 1.0.0` is approved with reformats
   required (exact-where-exact stands); the reference application lives under
   `Examples`; `VOX-SPA-010` completes on sample centres; `VOX-IMG-008` zero-pads
   with provenance; `CODEOWNERS` is at the root; the Raster-Lab `LICENSE` files are
   an owner action on the owner's repositories.

   **Two items were CONFIRMATIONS, caught before they became re-derivation**: the
   first draft of the record treated the compression measurements and the direct
   codec declaration as newly authorised. They were `ADR-0266`'s gates, executed by
   `ADR-0267`-`ADR-0273` and closed by `ADR-0274` — `VOX-CMP-011` was DISCHARGED by
   adversarial testing, not waived. `ADR-0338` d9 records both as confirmations with
   no new effect, and the stale present-tense "six are BLOCKED" note in
   `untraced-requirements.txt` is corrected to history in the same increment.

   **`CODEOWNERS` moved and the gate follows the row**: `check_required_files.py` now
   requires the root path, proven able to fail (file moved away → exit 1; restored →
   pass), closing the discrepancy `ADR-0320` recorded. `manifest.txt` updated.

   **THE FINISH LINE IS M6.** M7-M10 stay unentered; `HIGHEST_ENTERED_MILESTONE`
   remains 6 until the owner raises it. What remains to the line is engineering, not
   governance: spatial bounds' physical half, grid resampling, first useful image,
   priority propagation, the progressive-refinement arc, the frame-rate measurement
   on the named device, the reference application, then release assembly with the
   owner-witnessed Demonstrations and pending Reviews.

   **The restarted loop carries `ADR-0338` d10's bounds**: no new gate, ratchet or
   register without a requirement row demanding it; an increment must advance a row
   while any is unblocked; an empty queue stops the loop and surfaces owner questions.

   **Next**: `VOX-SPA-010`'s physical half on the sample-centre convention — the
   smallest newly unblocked row, and a design-first increment (ADR + oracle) per the
   standing recipe.

   **Increment (fffff): `ADR-0339` + `VOXELIA-ALG-0054` — `VOX-SPA-010` DISCHARGED.**
   1248 tests / 220 suites; the first code increment of the restarted loop.

   **The physical half now has its producer**:
   `AffineGridGeometry.sampleCentreBounds(slot0SampleCount:slot1SampleCount:slot2SampleCount:)`
   returns the axis-aligned hull of the outermost sample centres in the geometry's own
   coordinate space, per `ADR-0338` d7's centres answer. Eight corners, frozen
   slot-0-fastest ordinals, the `ADR-0138`/`ALG-0052` expression shape with translation
   added last, sequential fold — all frozen in `VOXELIA-ALG-0054` with a python oracle
   (`ADR-0339-sample-centre-bounds-oracle.py`), and all ten fixture tests passed
   **bit-exact on the first run**.

   **`ADR-0323`'s predicted defect is REGISTERED EVIDENCE, not prose**: fixture 5's
   world x mixes two slots with opposite signs, the true hull spans `[-2, 3]`, and the
   two-corner shortcut's `[0, 1]` is recorded in the spec AND asserted against in the
   test, so the wrong implementation cannot come back quietly.

   **Three typed failures with attribution, nothing dead**: non-positive and
   above-`2^53` counts name their slot (the ceiling is what makes every corner
   coordinate exact — `2^53` itself admits, corner index `9007199254740991.0`);
   a non-finite component names its corner ordinal and axis, checked BEFORE `Point3D`
   so the failure belongs to the corner computation (`ADR-0258` attribution rule).
   Product overflow (ordinal 1) and accumulation overflow (ordinal 3) are separate
   fixtures. `invertedBounds`/`nonFiniteComponent` are provably unreachable downstream
   — and a `-0.0` component is UNREACHABLE, with the proof in the spec: the last
   addition is with a translation `Matrix4x4Double` normalised on admission, and
   round-to-nearest addition returns `-0.0` only for `-0.0 + -0.0`.

   **Every M1 row is now accounted for.** Remaining queue per `ADR-0338`:
   `VOX-IMG-008` grid resampling (zero-pad + provenance), `VOX-PER-006` first useful
   image, `VOX-CON-008` priority propagation, the `VOX-BRK-009`/`VOX-DVR-013`
   progressive-refinement arc, `VOX-PER-004` on the named device, the `Examples`
   application, then release assembly.

   **Next**: `VOX-IMG-008` grid resampling — design first; read `ADR-0324`'s
   interpolation-row findings and the existing `Resample*Operation`s before designing,
   per the vocabulary-vs-capability trap recorded against `VOX-VS1-011`.

   **Increment (ggggg): `ADR-0340` + `VOXELIA-ALG-0055` — `VOX-IMG-008` DISCHARGED.**
   1261 tests / 221 suites.

   **The row's missing capability now has its surface**: `GridResampleOperation`
   takes the output's own rank-three `AffineGridGeometry` — the target `ADR-0325`
   proved inexpressible in the extents-based operations — and claims it verbatim,
   registered as the seventeenth CPU implementation. The chain composes accepted
   authorities only: the `ALG-0017` request order extended by the third slot term,
   the `ADR-0138` inverse, and `ObliqueSliceOperation.sample` with its built-in
   exact zero padding (`ADR-0338` d7's answer).

   **The forward order was chosen FOR a cross-check, and the cross-check runs**: the
   spec deliberately extends the sampler's own request order rather than matching
   `ALG-0052`/`ALG-0054`'s translation-last shape, so a depth-one grid resample is
   byte-identical to the oblique slice under a shared rotated request — asserted in
   the suite, not argued in prose. Consistency within the consumer family beat
   consistency across families, and the record says why.

   **Padding is recorded in provenance as `ADR-0338` d7 required**: the aggregated
   warning `org.voxelia.warn.grid-resample-padding` (`qualityAffecting` — padded
   samples are synthetic, not measured) carries the padded-sample count, and is
   ABSENT when nothing padded, per the padding-entry precedent. The support test
   was EXTRACTED into public `ObliqueSliceOperation.supports` — `sample` now calls
   it — so counting uses the same expressions that decide padding; the oblique
   fixtures re-ran green, proving the extraction changed nothing.

   **Two ceilings, distinctly typed**: the sibling per-dimension `16384` and a
   total-sample ceiling of exactly `1024^3` (three ceiling dimensions would admit a
   four-terabyte output). The budget boundary is asserted as the frozen constant —
   executing a gibibyte output is not a unit test.

   **Two registry count assertions moved 16→17 and 19→20** (`CPUBackendRegistrations`,
   `CombinedRegistry`) — the second found by the full unfiltered run, not the
   filtered one, which is recipe step 12 doing its job. The first's comment still
   said "fourteen" while asserting sixteen; it now names no number.

   **Six oracle fixtures, all exact on first run** (`ADR-0340-grid-resample-oracle.py`):
   identity, coarser-grid border replication (16, not the extrapolation 17),
   axis-exchange transposition, padding with attribution, the inclusive-then-
   exclusive support edge at 2.5 vs 2.5000000000000004, and ties-to-even in both
   directions.

   **Every M2 row is now accounted for.** Remaining queue per `ADR-0338`:
   `VOX-PER-006` first useful image, `VOX-CON-008` priority propagation, the
   `VOX-BRK-009`/`VOX-DVR-013` progressive-refinement arc, `VOX-PER-004` on the
   named device, the `Examples` application, then release assembly.

   **Next**: `VOX-CON-008` priority propagation — read `ADR-0330`'s and the
   concurrency records' framing of what "unbuilt" meant for it before designing.

   **Increment (hhhhh): `ADR-0341` — the STUDY CACHE GENERATION STAGE EXISTS;
   `VOX-CON-008` `T` DISCHARGED.** 1269 tests / 222 suites.

   **`ADR-0314`'s shared blocker is dissolved by building the artefact, not the
   vocabulary**: `StudyCacheGenerator` sweeps a study's bricks through the accepted
   cache-through-broker entry point, so the decoded brick store of `ADR-0338` d2 is
   generated by a stage with a start, ordered per-brick progress and a completion —
   the thing `ADR-0307` and `ADR-0314` both measured missing. `VOX-PER-006` now has
   the completion its clock needs; that row composes it NEXT increment.

   **Priority propagation is structural and OBSERVED, answering both of `ADR-0314`'s
   refusals at once**: no `TaskPriority` parameter was invented (d3's "nowhere to
   nowhere"), and the language is not credited alone (alt-2) — Voxelia now creates
   the background work and the relationship, and the suite records
   `Task.currentPriority` inside every computation: sweep-initiated computations
   observe `.utility` through the broker's computation start, interactive ones
   observe `.userInitiated`.

   **Outranking is proven with gates, not clocks**: with the sweep blocked on its
   first brick behind a deterministic gate, an interactive request for an unswept
   brick completes and admits in full while sweep progress is still empty — it was
   never queued, because the queueless broker is the design (a priority-ordered
   queue was REJECTED as manufacturing the thing the row exists to prevent). Racing
   on the sweep's own brick joins the in-flight computation: one computation, both
   served. The in-flight non-escalation nuance is RECORDED in the Alternatives
   (continuation awaits do not escalate; exposure bounded to one brick).

   **Composition untouched**: cancellation stops the sweep with no completion under
   `ADR-0157`'s last-awaiter rule; a pre-admitted brick is a hit with its bytes
   preserved; a stale generation rejects typed before any work; NO new error family
   — every failure is an existing audited type.

   **Every M3 row is now accounted for.** The `D` half joins the release
   demonstrations per `ADR-0338` d11.

   **Next**: `VOX-PER-006` first useful image — compose the generator's completion
   with `ADR-0338` d2's first-plane definition; `ADR-0307`'s checkpoint warning
   (decision 3: the import checkpoints are cancellation probes, NOT publication
   seams — build the progressive path as its own thing) binds that design.

   **Increment (iiiii): `ADR-0342` — `VOX-PER-006` `T` DISCHARGED; the first useful
   image is REAL and provably early.** 1276 tests / 223 suites.

   **The composition `ADR-0307` demanded, built as its own thing**: nothing touches
   `CTImportSession` or its checkpoints; the progressive path is a plan plus an
   assembly over `ADR-0341`'s stage. `FirstUsefulImagePlan` nominates a plane at
   full resolution, computes its brick layer, and emits the sweep order
   plane-bricks-first — and because the generator's progress is sequential and
   ordered, **the milestone is the existing progress callback reaching
   `planeBrickCount`**: no second callback surface that could disagree with the
   first. `FirstUsefulImageAssembly` publishes the plane by slicing decoded core
   bytes — integer arithmetic only, oracle-computed
   (`ADR-0342-first-useful-image-oracle.py`), edge bricks smaller than nominal
   covered.

   **The row's own property is the gate test**: with the sweep blocked on its first
   post-plane brick, the nominated sagittal plane assembles EXACTLY (12 oracle
   bytes, extents 4x3) while progress still equals the milestone — generation
   provably incomplete, no wall-clock anywhere. The proper-subset condition that
   makes "before completion" non-vacuous is exposed on the plan and asserted.

   **Nothing fabricated, ever**: a missing plane brick rejects typed (this is
   publication of decoded study data, not resampling — no padding rule applies);
   a wrong-size decoded payload rejects typed against the core-extent product
   instead of slicing garbage; plan admission rejects rank, axis and index typed.

   **Every M4 row is now accounted for.** The `D` half — the owner watching a
   first image appear during a real study's generation — joins the release
   demonstrations per `ADR-0338` d11.

   **Next**: the `VOX-BRK-009`/`VOX-DVR-013` progressive-refinement arc — the
   superseding version `ADR-0103` named as future. Read `ADR-0329` d3 first: the
   "both qualities execute identically" guard test must be CONSCIOUSLY REPLACED
   by per-quality claims, never quietly deleted.

   **Increment (jjjjj): `ADR-0343` + `VOXELIA-ALG-0056` — THE PROGRESSIVE-REFINEMENT
   ARC IS OPEN, and its foundation exists.** 1283 tests / 224 suites.

   **The arc order is FIXED in the record**: (1) the level representation — this
   increment; (2) the interactive render path over it while bricks load
   (`VOX-BRK-009`); (3) refinement to full after interaction stops
   (`VOX-DVR-013`); (4) the `ADR-0103` guard replaced BY PER-QUALITY CLAIMS in the
   SAME increment the qualities diverge — never earlier, so the old position stays
   guarded until the new one is tested. Neither row is claimed yet; nothing is
   claimed early.

   **A level's samples are SELECTED, never averaged** — level sample `(j)` IS the
   level-zero stored value at `(j*f)`, so every interactive pixel shows a real
   acquired sample and no synthesised intensity enters the diagnostic path (the
   same no-fabrication line as padding and halos; aliasing-vs-smoothing trade
   recorded, an averaged pyramid stays open as a separate representation). The
   level geometry scales the index-step columns by the factors, translation
   verbatim — a level sample's centre IS its selected sample's centre, and for
   power-of-two factors the scaled-matrix and scaled-index routes agree
   BIT-EXACTLY (oracle witness).

   **`LevelSelectOperation` registered (CPU 18, combined 21)**: sampler value
   domain, `BrickResolutionLevel` parameter with index >= 1 (level zero IS the
   volume — an identity copy would mint a duplicate object while looking like
   work), factors ceiling 16384, parameter document = level index + three
   factors, claim `exact` (selection copies bytes; a below-full quality claim
   belongs to the RENDER in arc step 2, through the claim vocabulary `ADR-0103`
   already routes). Five oracle fixtures exact on first run, including both
   collapsed-axis cases through the ordinary arithmetic.

   **Next**: arc step 2 — the interactive render path over the level
   (`VOX-BRK-009`): render from a level-select volume while level-zero bricks
   load, claiming `org.voxelia.quality.interactive` with the level recorded,
   composing `ADR-0341`'s stage. Read `ADR-0174`'s claim routing and the
   `MetalSliceRenderer` stage-injection note in memory before designing.

   **Increment (kkkkk): `ADR-0344` — `VOX-BRK-009` `T` DISCHARGED; interactive
   rendering uses the level while bricks load.** 1287 tests / 225 suites.

   **The arc's shape crystallised into a principle: the REPRESENTATION degrades,
   the EXECUTION never does.** `InteractiveLevelRenderCoordinator` is the degraded
   path's decision layer: `.full` renders full resolution ALWAYS (a diagnostic
   request never gets the level); `.interactive` renders the level while
   generation is incomplete and full resolution once it completes — the third
   case being arc step 3's seed. The renderer runs its accepted full-precision
   math over whichever volume is selected, so every stage claim stays exactly
   what it says.

   **`ADR-0343` step 2's wording REFINED, recorded not edited**: it said the
   interactive path claims `org.voxelia.quality.interactive`; stamping a
   full-math execution "interactive" would be LESS honest than the ancestry
   already is — the published render's lineage reaches the level volume whose own
   derivation names `org.voxelia.op.level-select` and its factors (the `ADR-0221`
   "not restated in the presentation claim" discipline). The `ADR-0103` guard
   therefore stays IN FORCE, untouched: per-quality claims arrive only if a
   future increment degrades execution itself — arc step 4 is conditional and
   this arc may never trigger it.

   **The e2e witness is the row's own sentence**: a REAL gated study-cache
   generation supplies the loading state; while blocked, the interactive render's
   extract-stage provenance input IS the level volume, the full render's IS the
   full volume; after completion the interactive render refines to full
   resolution. Slice indices map by floor division through the now-public
   `MPRPlane.fixedAxis` — one axis authority, not a mirror. Everything else is
   forwarded, never chosen.

   **Every M6 row except three is now accounted for**: `VOX-DVR-013` (arc step 3
   — refinement after interaction stops, composing the same selection rule's
   completion case), `VOX-PER-004` (the frame-rate measurement on the named
   device, after the refinement lands so both representations can be measured
   and labelled), and the release assembly.

   **Next**: arc step 3 — `VOX-DVR-013`, refinement after interaction stops. The
   selection rule's completion case is the mechanism; what needs designing is the
   "after interaction stops" trigger composed with `ADR-0341`'s completion, and
   the refinement obligation: the refined render must be the SAME bytes a direct
   full render of the same request produces.

   **Increment (lllll): `ADR-0345` — `VOX-DVR-013` `T` DISCHARGED; ARC STEPS 1-3
   ARE COMPLETE.** 1289 tests / 225 suites.

   **Refinement is a representation upgrade with a host-supplied trigger and a
   proven obligation.** `InteractionPhase` (`active`/`idle`) is the host's —
   debouncing "input stopped" needs a clock the library refuses to own.
   `refinementDecision(phase:generationComplete:)` returns `ADR-0344`'s
   interactive source UNCHANGED plus `refinementDue`, true exactly in the one
   owed case: interaction stopped, loading incomplete. An idle view over
   completed generation discharges the obligation BY that render, which the
   selection rule makes full-resolution.

   **The obligation is byte-identity, proven on published bytes**: the idle
   refinement render and a direct full-quality render of the same request
   produce identical bytes — render-path purity made it structural, the suite
   made it evidence, and object identifiers were never compared (they are the
   host's to mint).

   **The `ADR-0103` guard survives the whole arc**, untouched and still green:
   no increment degraded execution, so arc step 4 stays conditional and
   untriggered — the strongest possible outcome for that guard.

   **What remains to the M6 line**: `VOX-PER-004` (frame rate on the named
   device — `Mac17,4` / Apple M5 — under `ADR-0330`'s four constraints, now
   able to measure and label BOTH representations), the `Examples` reference
   application, then release assembly with the owner-witnessed Demonstrations
   (now including `VOX-BRK-009` and `VOX-DVR-013` halves) and pending Reviews.

   **Next**: `VOX-PER-004` — the frame-rate measurement increment. Reread
   `ADR-0330` and `ADR-0271` d4 (clean process) before building the harness;
   the 512-cubed volume is the row's own case, not a convenient fixture.

   **Increment (mmmmm): `ADR-0346` + `VOXELIA-BEN-0003` — `VOX-PER-004` MEASURED,
   and the verdict is a MISS, recorded not softened.** 1289/225 unchanged; no
   product source changed — the benchmark package gains the scenario.

   **All four `ADR-0330` constraints satisfied for the first time**: the named
   device (`Mac17,4` / Apple M5, `ADR-0338` d1), the row's own 512-cubed case (a
   deterministic ramp, not a convenient fixture), a clean release-build process
   (`voxelia-benchmark --frames`, `ADR-0271` d4), and the quality labelled —
   full-precision execution every frame, profiled across `ADR-0343`'s levels.

   **The numbers**: 0.068 fps at 512-cubed (14.7 s/frame), 0.194 at level 1,
   0.415 at level 2 — roughly **440x from the target's lower bound**, with
   under two percent frame-to-frame spread. **Attributed, not excused**: the
   only volume renderer is the CPU-exact reference path whose purpose is
   correctness evidence; no Metal DVR kernel exists (measured absence); each
   frame re-reads the full volume through the coordinated boundary; no
   acceleration engaged. The representation lever works (6.1x level 0 to
   level 2) and cannot close 440x alone. **Conditions that would reverse the
   conclusion recorded**: a device DVR kernel with resident textures under the
   same claims discipline.

   **`T` discharged BY the measurement; the target standing is the OWNER'S
   release matter** — "withholding an unfavourable number is the same
   dishonesty reversed" (`ADR-0346` alternatives). No performance work starts
   on a measurement record's authority; a device DVR kernel is its own future
   arc.

   **EVERY M6 ENGINEERING ROW IS NOW DISCHARGED OR MEASURED.** What remains to
   the finish line: the `Examples` reference application (`ADR-0338` d5's
   location decision), then release assembly with the owner's Demonstrations
   and Reviews — now including this row's target standing.

   **Next**: the `Examples` reference application — read the application-location
   decision (`ADR-0338` d5) and `VOX-REP-003`'s `Examples` directory row; the
   draw-loop demonstrations run there at release.

   **Increment (nnnnn): `ADR-0347` — THE REFERENCE APPLICATION EXISTS.** 1289/225
   unchanged; no library source changed — the `Examples/VoxeliaCTReference`
   package is new.

   **The scaffold that stood empty since M0 is filled under its own contract**:
   a SwiftPM SwiftUI executable (`swift run`, the `Benchmarks` dependency
   pattern), owning lifecycle, controls, layout and the host-side clock —
   windowing frameworks live ONLY here, which is exactly what makes the app the
   right home for the draw loop the library refused to own. Every rendered pixel
   comes from the accepted coordinators: publication, `LevelSelectOperation`,
   `StudyCacheGenerator` at `.utility` with visible progress,
   `InteractiveLevelRenderCoordinator` with the `MetalSliceRenderer` backend,
   and the `ADR-0345` debounce-to-idle refinement — demonstration pacing in the
   brick compute is the application's and is labelled as such.

   **NO `T` and NO `D` is discharged** — building the stage is not witnessing
   the play. The vehicle serves the release Demonstrations: the interactive
   plane halves (`VOX-VS1-010/012/013`, `VOX-MPR-011`), level-while-loading
   (`VOX-BRK-009`), refinement (`VOX-DVR-013`), priority (`VOX-CON-008`) and
   first useful image (`VOX-PER-006`). Recorded v0.x bounds: synthetic banded
   radial phantom (DICOM import wires in at release assembly), session-lifetime
   publication growth sized generously for a demo vehicle.

   **Build evidence**: the app package builds clean against the parent by path;
   its behaviour is the coordinators', already under suite evidence — the app
   adds composition, not logic.

   **Next: RELEASE ASSEMBLY — the last engineering increment.** Wire
   `CTImportSession` directory import into the reference app, then the release
   process: version, changelog, `prepare-release.sh`, integrity, tag readiness —
   and assemble the owner's release packet (Demonstrations to witness, Reviews
   to approve including `VOX-PER-004`'s target standing, the two Raster-Lab
   LICENSE actions).

   **Increment (ooooo): `ADR-0348` — RELEASE READINESS; the owner's session is
   turnkey.** 1289/225 unchanged; documentation and release structure only.

   **The release is `v0.2.0`, cut by the OWNER, after the session** — no tag
   exists (`v0.1.1` was a documentation release), and `VERSION` stays `0.1.1`
   until the witnessing concludes: a bumped version before it would claim a
   release that has not happened.

   **The changelog's five-hundred-commit "None" is replaced** with the compiled
   content summary by area: M1-M3 foundations, the M4 vertical slice, the M5
   compression arc, the M6 interactive stack, the frame-rate baseline with its
   recorded miss, the reference application, and the safety/governance floor.

   **`docs/releases/v0.2.0/README.md` is the owner's release packet**: eight
   Demonstrations with run instructions and what to observe, six Reviews with
   paths — `VOX-PER-004`'s 440x target standing surfaced as its OWN acceptance
   item, never a default — the two Raster-Lab LICENSE actions, then the
   mechanical tag steps in order.

   **One engineering item remains, recorded not hidden**: wiring
   `CTImportSession` directory import into the reference application so the
   Demonstrations can run on a real study as well as the phantom.

   **Next**: the DICOM import wiring — THE FINAL ENGINEERING INCREMENT. After
   it, the queue is engineering-empty and the loop STOPS per `ADR-0338` d10,
   surfacing the release packet to the owner.

   **Increment (ppppp): `ADR-0349` — STUDY IMPORT WIRED. THE ENGINEERING QUEUE
   IS EMPTY.** 1289/225 unchanged; the example application only.

   **The reference application gains study mode**: launched with a series
   directory, it imports through `CTImportSession` with `DICOMFrameSource`'s
   closures under the **exact** geometry tolerance — the accepted conservative
   posture the owner's own 899-frame series is proven to pass — publishes the
   imported volume, and views it through the multiplanar path at full quality
   with an adaptive slice range. Phantom mode is unchanged.

   **The value-domain bound is recorded, not worked around**: the level and
   refinement demonstrations stay phantom-only because `LevelSelectOperation`
   admits the sampler's `uint8` domain and CT carries wider stored values;
   widening is that operation family's own future decision, never an
   example-app patch.

   **Per `ADR-0338` d10 the loop now STOPS**: every M0-M6 row is discharged,
   characterised or measured; the demonstration vehicle serves phantom and
   study; the release packet at `docs/releases/v0.2.0/README.md` is the
   owner's next action — eight Demonstrations, six Reviews (including the
   `VOX-PER-004` 440x target standing as its own acceptance item), two
   Raster-Lab LICENSE actions, then the mechanical tag steps. The tag is the
   owner's to cut; nothing on this queue remains for the loop.

   **Increment (qqqqq): `ADR-0350` — v0.2.0 IS TAGGED, and M7-M10 ARE ENTERED.**
   1289/225 inside the release gate; the queue is FULL again.

   **The owner completed the release session and instructed the cut**; the
   repository showed no tag, so the mechanics were completed under that
   instruction and reported, not assumed: changelog compiled, `VERSION` and
   `RELEASE.json` at `0.2.0`, the COMPLETE release gate green end to end — the
   first full `prepare-release.sh` run since the gates grew — and the annotated
   tag `v0.2.0` pushed as the repository's FIRST tag.

   **The gate surfaced nine latent findings; every one fixed, none waved
   through** (`ADR-0350` d2 inventories them): new-package registrations,
   checkout-tree exclusions, the pre-approved external dependencies admitted by
   identity, six static type-assertions rewritten to runtime form, a redundant
   `try`, a DocC cross-module link, two missing platform gates
   (`VoxeliaCompression`, `VoxeliaDICOMKit`), the app's one pointer-typed call
   fingerprinted per `ADR-0186`, and **a Swift 6.3.3 optimiser crash on release
   test builds** answered by scoping the semantic release pass to product
   targets — commented, self-tested (156 pass), revisit on toolchain update.

   **`HIGHEST_ENTERED_MILESTONE` is 10.** The traceability baseline now carries
   **103 untraced rows** as the honest full remaining scope (27 of the 130
   entering rows were already traced by earlier records): M7 advanced
   processing/segmentation/registration (`VOX-SEG`, `VOX-REG`, `VOX-ADP`...),
   M8 photorealistic rendering (`VOX-PRR`, 17 rows), M9 platform/headless/
   distributed (`VOX-HLS`, `VOX-DST`, `VOX-EXT`), M10 publication baseline
   (`VOX-REL`, `VOX-DOC`, `VOX-VAL` tails).

   **Next**: derive the M7 queue — group the M7 rows by arc, read their plan
   sections, and open the first arc design-first. The finish line is M10.

   **Increment (rrrrr): `ADR-0351` — THE M7 QUEUE IS DERIVED; phase two's first
   arc is named.** 1289/225 unchanged; no code — the derivation record.

   **Six arcs, ordered by dependency**: (1) image-processing foundations
   (`VOX-IMG-010/011/012/013/014`, `VOX-IMG-007`, `VOX-R2D-004`) — pure CPU
   numerics, no owner input, and segmentation composes every one of them;
   (2) segmentation (`VOX-SEG-001..010`); (3) registration (`VOX-REG-001..010`,
   `VOX-VAL-014`, plus `VOX-DAT-008`/`VOX-SPA-012` whose first consumer is
   registration — pyramids compose `LevelSelectOperation`); (4) curved planar
   and DICOM format tails (`VOX-MPR-012/013`, `VOX-DCM-011/012`);
   (5) the extension mechanism (`VOX-EXT-001..006` — much substance exists,
   the arc measures rows against it); (6) VTK/ITK interoperability
   (`VOX-ADP-007..010`) — **blocked on the owner batch, the only blocked arc**.

   **The owner batch is surfaced ONCE** (`ADR-0351`): VTK/ITK package scope or
   post-1.0 deferral; whether `VOX-SEG-010` gets a reference AI adapter now or
   the boundary alone; confirmation the fix-what-surfaces instruction covers
   DICOMKit SEG/parametric reading. Arcs 1-5 proceed without it.

   **The ratchet did its job on the derivation**: naming the rows traced 23 of
   them; the baseline is 80 rows, all known debt, shrink-only.

   **Next**: arc 1, increment one — the `VOX-IMG-010` threshold/mask/arithmetic
   design, design-first with an independent oracle, value domain decided
   against `VOX-R2D-004`'s floating-point row rather than assumed uint8.

   **Increment (sssss): `ADR-0352` + `VOXELIA-ALG-0057` — the PROCESSING
   FOUNDATIONS ARC IS OPEN with its value domain frozen; threshold is built.**
   1294 tests / 226 suites.

   **The arc's load-bearing decision is the DOMAIN, not the operation**: the
   stored domain (`uint8`, `int16`, `uint16`, `float32`) rather than the
   display-policy uint8 the M0-M6 samplers bound themselves to — processing
   thresholds the STUDY, not a presentation, and `VOX-R2D-004` is ADVANCED by
   the float32 admission (discharge when the arc admits it uniformly). Every
   admitted type widens to binary64 exactly, so the arc's comparisons carry no
   rounding anywhere.

   **`ThresholdOperation` (CPU 19, combined 22)**: frozen order — padding
   sentinel excludes BEFORE comparison (fixture 3 proves the sentinel inside
   the range still excludes: padding is not data), NaN never included and
   always counted (aggregated `threshold-non-finite` warning, absent at zero),
   inclusive binary64 range third. Output is a `uint8` `mask`-semantic image of
   exact 0/1 claiming input geometry verbatim — masks are LABELS
   (`VOX-IMG-007`'s nearest-neighbour default binds their resampling, recorded
   before the first consumer exists). Five oracle fixtures exact on first run,
   including float32 non-finite handling and the inclusive upper edge.

   **Next**: mask application and image arithmetic, completing `VOX-IMG-010` —
   same domain, design-first; the arithmetic overflow rule per integer type is
   the frozen decision to settle.

   **Increment (ttttt): `ADR-0353` + `VOXELIA-ALG-0058` — `VOX-IMG-010` IS
   DISCHARGED; the overflow rule is saturate-and-count.** 1301 tests / 228
   suites.

   **The frozen decision**: integer arithmetic rounds ties-to-even, saturates
   to the type range, and COUNTS every saturation into the aggregated
   `arithmetic-saturated` warning (absent at zero) — silent saturation distorts
   invisibly, rejection fails a volume for one hot sample, counting keeps the
   distortion visible where it belongs. Float32 stores non-finite results
   VERBATIM, counted into `arithmetic-non-finite` — binary32 has a vocabulary
   for infinity and substituting finite values would fabricate data.

   **`MaskApplyOperation` (CPU 20)**: masked-in samples byte-verbatim, the fill
   must round-trip the stored type EXACTLY (`fillValueNotRepresentable` — a
   written value must be the declared one), and any mask byte other than 0/1
   rejects fail-closed (a corrupted mask must never silently threshold).

   **`ArithmeticOperation` (CPU 21, combined 24)**: add/subtract/multiply over
   two same-shape same-type images or an image and one finite scalar, binary64
   over the domain's exact widening; mixed-type promotion is a future record's
   rule, not this one's accident. Five oracle fixtures exact on first run —
   including 15x17=255 NOT counting as saturation, and both tie directions
   rounding to even before the range check.

   **Threshold, mask and arithmetic all exist under one domain** — VOX-IMG-010
   complete; `VOX-R2D-004` advances again (both admit float32).

   **Next**: `VOX-IMG-011` — convolution and Gaussian foundations; the frozen
   decisions are the BOUNDARY CONDITIONS the row itself names, and the Gaussian
   kernel's discretisation rule (sampled vs integrated, truncation radius).

   **Increment (uuuuu): `ADR-0354` + `VOXELIA-ALG-0059` — convolution with the
   row's explicitness honoured STRUCTURALLY.** 1306 tests / 229 suites.

   **The boundary is a closed, DEFAULTLESS choice** (`replicate` | `zero`) — a
   defaulted boundary is an implicit one and `VOX-IMG-011` forbids exactly
   that. Fixture 1 shows the choice changing both edges and nothing else;
   fixture 2's central difference goes negative only under `zero`. Correlation
   orientation is STATED so nobody flips it silently.

   **`ConvolveOperation` (CPU 22, combined 25)**: caller-supplied binary64
   kernel, odd per-axis extents ceilinged at 31, frozen lexicographic
   left-associative accumulation from exact zero (the order IS the contract,
   as `ALG-0052` froze for its sums), output composing `ALG-0058`'s rule with
   this operation's OWN warning codes — provenance attributes the producing
   stage, never pools observations. Four oracle fixtures exact on first run;
   the all-saturating case counts 5.

   **`VOX-IMG-011` is half-discharged**; `VOX-R2D-004` advances again.

   **Next**: the Gaussian filter completing `VOX-IMG-011` — the frozen
   decisions deferred to their own record: sampled-vs-integrated
   discretisation, truncation radius, weight normalisation order, and the
   separable per-axis pass order (rounding makes it observable).

   **Increment (vvvvv): `ADR-0355` + `VOXELIA-ALG-0060` — `VOX-IMG-011` IS
   DISCHARGED; the Gaussian's four decisions are frozen.** 1310 tests / 230
   suites.

   **The decisions**: SAMPLED discretisation (integrated recorded as a possible
   future record, never folded in silently); truncation radius `ceil(3 sigma)`
   under the convolution ceiling (sigma <= 5 admits, 5.1 rejects — both edges
   tested); normalisation summed left-to-right then divided (a convex
   combination up to that order's rounding); axis-ascending separable passes
   **carried in binary64 with the stored-type conversion happening EXACTLY
   ONCE** — per-pass narrowing would round once per axis, the exact error this
   design exists to avoid.

   **The core was EXTRACTED, and the extraction is proven**: the frozen
   `ALG-0059` accumulation loop moved into one internal `convolvedValues` both
   operations call, and the convolution fixtures re-ran unchanged — the
   `SurfaceCoverage` discipline, again. The Gaussian's per-axis pass is that
   core with a kernel of extent one everywhere but its axis: no second loop
   exists to drift.

   **Integer saturation is UNREACHABLE for finite inputs** — the normalised
   kernel makes every pass convex; the constant-image fixed point (200 stays
   200 exactly) is the witness, and the shared store rule's counter stays
   provably silent rather than deleted.

   **`VOX-IMG-011` complete; `VOX-R2D-004` advances again** (CPU 23, combined
   26). Four Gaussian fixtures exact on first run, including the 3x3 float32
   separable product structure byte-for-byte.

   **Next**: `VOX-IMG-012` morphology foundations — erosion and dilation; the
   frozen decisions are the structuring-element vocabulary and the boundary
   rule's interaction with min/max (a replicate boundary is the identity for
   both; the record must say what zero means for erosion).

   **Increment (wwwww): `ADR-0356` + `VOXELIA-ALG-0061` — `VOX-IMG-012` IS
   DISCHARGED; morphology is binary, over masks, exact.** 1314 tests / 231
   suites.

   **The named question is ANSWERED in the record**: under `zero`,
   border-touching foreground ERODES (out-of-image is background — the
   conservative mask reading); under `replicate` the border extends and the
   all-ones mask is an erosion fixed point. The all-ones fixture witnesses
   both readings side by side. Dilation is unaffected by zero taps —
   background never satisfies ANY.

   **`MorphologyOperation` (CPU 24, combined 27)**: general caller-supplied
   0/1 structuring element (a box and a cross are INPUTS, not vocabulary),
   odd rank-matched extents ceilinged at 31, at least one 1 (an empty element
   makes ANY vacuously false and ALL vacuously true — a trap, not a
   morphology). Corrupt mask bytes reject fail-closed per the `ALG-0058`
   rule. Erosion-dilation duality recorded as a property, deliberately NOT
   used as the implementation. Greyscale min/max morphology deferred to its
   own record — no consumer has asked. Five oracle fixtures exact on first
   run, `exact-v1`: no arithmetic exists to round, no warnings can arise.

   **Next**: `VOX-IMG-013` connected-component analysis — frozen decisions:
   the connectivity vocabulary (6/18/26 in three dimensions, 4/8 in two),
   the label-assignment determinism rule (labels must be reproducible, so
   first-encounter order in canonical scan), and the output's label-semantic
   descriptor.

   **Increment (xxxxx): `ADR-0357` + `VOXELIA-ALG-0062` — `VOX-IMG-013` IS
   DISCHARGED; labels are deterministic by construction.** 1318 tests / 232
   suites (commit `ac93d4b`; this ledger bullet follows in its own commit
   after an anchor mismatch — recorded, not hidden).

   **The connectivity vocabulary is CLOSED and rank-honest**: `faces` (4/6),
   `facesAndEdges` (18, three dimensions ONLY — it REJECTS in two rather than
   silently aliasing the vertices case), `facesEdgesAndVertices` (8/26). The
   diagonal pair witnesses the choice in 2-D; the edge-touching cube pair in
   3-D.

   **First-encounter labelling is STRUCTURAL determinism**: the canonical scan
   founds components with labels from one; membership is order-independent, so
   the only order-sensitive fact — which component gets which label — is fixed
   by the scan, and the fill's internal order is deliberately NOT part of the
   contract. Background stays exactly zero.

   **The label space is sixteen bits, ceilinged and TYPED** — proven by a
   generated 512x257 checkerboard whose 65,792 isolated pixels breach it.
   Output is a `uint16` `label`-semantic image, geometry verbatim. CPU 25,
   combined 28. Four oracle fixtures exact on first run.

   **Next**: `VOX-IMG-014` distance transforms — the LAST foundations row;
   frozen decisions: the metric (exact Euclidean squared via the parabola
   method vs chamfer — the row is "should", P1), the output type and units,
   and whether distance measures to background or to the foreground boundary.

   **Increment (yyyyy): `ADR-0358` + `VOXELIA-ALG-0063` — `VOX-IMG-014` IS
   DISCHARGED, and THE PROCESSING FOUNDATIONS ARC IS CLOSED.** 1322 tests /
   233 suites.

   **The exactness move**: the transform publishes SQUARED Euclidean distances
   as exact integers — the square root is the transform's only possible
   rounding, so it belongs to the presenter, never the operation. Distance
   measures to background (background publishes exactly zero); no-background
   rejects typed (an infinite distance has no honest uint32 spelling);
   physical-unit/anisotropic weighting is a recorded future widening.

   **The oracle is deliberately BRUTE FORCE** — the minimum over all
   background samples, sharing NO structure with the implementation's
   separable Felzenszwalb-Huttenlocher parabola method — and the exactness
   argument is in the spec: published values are integer parabola evaluations
   within binary64's exact range; the envelope's divisions only pick winners,
   and ties evaluate equal either way. 1-D, 2-D radial, competing-seeds and
   3-D corner fixtures all match brute force exactly. CPU 26, combined 29.

   **THE ARC (`ADR-0352`..`ADR-0358`) IS COMPLETE**: threshold, mask apply,
   arithmetic, convolution, Gaussian, morphology, connected components and
   distance transforms — eight operations under ONE stored-value domain, every
   numeric rule frozen with an independent oracle, every warning attributed,
   seven requirement rows discharged (`VOX-IMG-007` claimed by `ADR-0352` d3's
   binding rule, `VOX-IMG-010/011/012/013/014`, `VOX-R2D-004` advanced
   throughout).

   **Next: OPEN THE SEGMENTATION ARC** — `VOX-SEG-001`, the mask and
   multi-segment model. Read the CDMS segmentation sections and `VOX-SEG-002`'s
   overlap requirement BEFORE designing the representation: overlapping
   segments must not be forced into one exclusive label value, which rules out
   a single label map as THE model and makes the per-segment mask collection
   the natural shape; `VOX-SEG-003`'s descriptors (stable IDs, labels,
   colours, algorithm provenance) and `VOX-SEG-004`'s geometry binding join
   the same design.

   **Increment (zzzzz): `ADR-0359` — THE SEGMENTATION ARC IS OPEN;
   `VOX-SEG-001..004` DISCHARGED by activating CDMS section 52 as written.**
   1327 tests / 234 suites.

   **Nothing was invented**: the CDMS already specifies the whole model —
   `SegmentID`, algorithm descriptors, display recommendations (explicitly
   non-authoritative), segment descriptors, the TWO-representation vocabulary
   and the aggregate — hosted in Core per CDMS section 15. The increment's work
   is turning section 52.11's eleven invariants into ADMISSION: unique segment
   identifiers, unique label values with the background outside the mapping,
   representation references resolving to declared segments, explicit ordered
   finite fractional domains with in-domain thresholds, and one shared shape
   with declared-geometry agreement.

   **The overlap requirement is discharged STRUCTURALLY**: the segment
   collection admits overlapping fields by construction (the suite's witness
   has two segments claiming the same sample), the label image CANNOT express
   overlap, and having both — with conversion explicit — is exactly how the
   model refuses to collapse overlap while still offering the exclusive form.

   **A pairing lesson recorded**: `ProvenanceRecord` enforces kind-activity
   agreement (`.transformed` demands an operation activity) — the test
   fixture's mismatch was caught by the accepted admission, which is that
   admission doing its job.

   **Next**: `VOX-SEG-005` + `VOX-SEG-006` — the nearest-neighbour resampling
   default for masks and labels (composing the discharged `VOX-IMG-007` rule
   against `GridResampleOperation`'s trilinear-only surface: the design must
   either widen grid resampling with a nearest mode or refuse mask semantics
   there and route them to a mask-honest resampler), and the segmentation
   operation set over the foundations.

   **Increment (aaaaaa): `ADR-0360` + `VOXELIA-ALG-0064` — `VOX-SEG-005` and
   `VOX-SEG-006` DISCHARGED; the nearest default is STRUCTURAL.** 1331 tests /
   236 suites.

   **The default is not a parameter that could drift — it is the only door**:
   mask and label semantics are REFUSED by the intensity resampler (typed,
   witnessed in the suite) and admitted only by `LabelResampleOperation`
   (CPU 27, combined 30), so nothing can interpolate a label by accident. An
   interpolating override would be a future validated operation with its own
   record — the row's own wording made structural.

   **A composition finding worth the record**: `ALG-0026`'s accepted nearest
   rule CLAMPS — right for in-support sampling, WRONG for a grid resample,
   where clamping would replicate edge labels into space the source never
   covered. The resampler composes the ROUNDING and owns its boundary rule:
   background zero outside, counted. Every output value is an input value or
   the background; no interpolation exists anywhere in the chain. Four oracle
   fixtures exact, including the -0.5 tie rounding away from zero.

   **`VOX-SEG-006` discharged by foundations + the composition WITNESS**: an
   `[Integration]` test drives threshold → erode → connected components into
   the CDMS section 52 aggregate end to end — unit evidence of halves does not
   prove they meet, so this does.

   **Next**: `VOX-SEG-007` region growing — recorded seeds, thresholds,
   connectivity and implementation version in the parameter document; the
   growth rule composes the threshold domain and the components connectivity
   vocabulary.

   **Increment (bbbbbb): `ADR-0361` + `VOXELIA-ALG-0065` — `VOX-SEG-007`
   DISCHARGED; the recording IS the parameter document.** 1335 tests / 237
   suites.

   **`RegionGrowOperation` (CPU 28, combined 31)**: a sample is included
   exactly when in the inclusive range — padding excluded FIRST (a sentinel
   inside the range blocks growth, witnessed), NaN never in range (uncounted
   here: threshold is the instrument for that observation) — and connected to
   an in-range seed under the `ALG-0062` connectivity. **An out-of-range seed
   founds nothing, deliberately not an error** — interactive seeding must not
   throw on a miss.

   **The row's four nouns, all recorded**: every seed coordinate in order,
   both bounds, the sentinel only when declared, the connectivity token — in
   the parameter document, verified by DIGEST IDENTITY in the suite — and the
   implementation version bound structurally by the operation pattern's
   derivation and provenance. Reproducing the growth needs nothing outside
   the record. Four oracle fixtures exact, including the diagonal bridge
   crossing only under vertex connectivity.

   **Next**: `VOX-SEG-008` editing provenance — explicit, undoable-by-host,
   provenance-producing editing operations; the design composes mask
   arithmetic (union/subtract via the existing operations?) or freezes a
   dedicated mask-edit vocabulary; CDMS 52.11's "segmentation editing shall
   create new provenance" binds.

   **Increment (cccccc): `ADR-0362` + `VOXELIA-ALG-0066` — `VOX-SEG-008`
   DISCHARGED; the row's three adjectives are STRUCTURE.** 1338 tests / 238
   suites.

   **Explicit** = the defaultless closed verb enum (`union`/`subtract`/
   `intersect`). **Provenance-producing** = the operation pattern itself:
   every edit publishes a new object whose derivation and provenance carry
   BOTH input edges and the verb — CDMS 52.11's editing rule for free.
   **Undoable-by-host** = immutability: editing cannot mutate the base (the
   suite proves it byte-identical after an edit), so a host that retains
   history undoes by re-referencing the retained prior object. NO undo stack
   enters the library — a second history authority would drift from the
   host's, the `ADR-0345` clock discipline applied to memory.

   **`MaskEditOperation` (CPU 29, combined 32)**, pure boolean, three oracle
   fixtures exact, corrupt masks fail-closed.

   **Next**: `VOX-SEG-009` statistics — computed from AUTHORITATIVE image and
   segment data (the row's own emphasis): volume/count/mean/min/max over a
   mask against the stored volume, values from the stored domain widened
   exactly, voxel volume from the geometry via the accepted `ALG-0019`
   calibrated voxel volume; never from a presentation.

   **Increment (dddddd): `ADR-0363` + `VOXELIA-ALG-0067` — `VOX-SEG-009`
   DISCHARGED; exclusions are VISIBLE NUMBERS, never buried.** 1341 tests /
   239 suites.

   **`SegmentStatisticsComputer`** reads the stored volume and the mask
   through the coordinated boundary and returns counts (mask, included,
   padded, non-finite — all published, because a statistic whose denominator
   quietly shrank is the dishonesty the row exists to prevent), the frozen
   left-to-right sum with mean/min/max (ABSENT, never zero, when nothing
   contributed), and the calibrated volumes composing the `ALG-0016`
   determinant authority directly — the same value `ALG-0019`'s measurement
   wraps, reached from below because the layering runs the other way.

   **Two boundary decisions recorded**: padding excludes a voxel's INTENSITY,
   not its claimed EXTENT (the mask is the authority on extent, padding on
   intensity validity — physical volume counts all mask samples); and NO
   registry entry or published object exists — the computer publishes
   nothing, so minting a derivation would fabricate provenance; persistence
   composes the measurement-publication pattern when a consumer asks.

   **Next**: `VOX-SEG-010` — the AI-adapter boundary, the arc's LAST row:
   inference integrates through optional adapters, never embedded in the
   foundational model (I,R — the `R` sits in the owner's ADR-0351 batch). The
   design is an adapter PROTOCOL over the accepted model (in → ImageData,
   out → SegmentCollectionSegmentation with algorithm descriptors carrying
   type/.automatic/model identity), inspected for the I half; no runtime
   enters the tree without the owner's supply-chain say.

1. **2026-08-07 — ~~`VOX-SEG-010`~~ DISCHARGED (`I` half; `R` in the owner
   batch): the AI adapter boundary (`ADR-0364`). THE SEGMENTATION ARC'S
   ENGINEERING IS CLOSED.** `SegmentInferenceAdapter` +
   `SegmentInferenceResult` in `VoxeliaCore` beside the model: an adapter
   takes `ImageData` and returns descriptors (`.automatic` + model identity
   through the accepted `SegmentAlgorithmDescriptor`) and fields — the HOST
   assembles the `Segmentation`, so admission and provenance never leave the
   accepted lifecycle. "Never embedded" is enforced: `CoreML`/`CreateML`
   joined `check_prohibited_imports.py` for all ten targets (the `ADR-0328`
   Model I/O pattern) and the widened gate was negative-tested both ways.
   Stub conformance proves the protocol implementable and that an undeclared
   segment cannot smuggle past section 52.11 admission. No reference
   adapter/runtime: the supply chain stays owner-reserved (`ADR-0351`
   batch Q2). Full suite: `✔ Test run with 1343 tests in 240 suites
   passed`. **Next**: open the REGISTRATION arc — `VOX-REG-001` first (the
   transform category model), then the arc's remaining registration,
   validation and pyramid rows per the `ADR-0351` order.

1. **2026-08-07 — ~~`VOX-REG-001`~~ + ~~`VOX-REG-003`~~ DISCHARGED: the
   registration transform categories (`ADR-0365` + `VOXELIA-ALG-0068`).
   THE REGISTRATION ARC IS OPEN.** A closed defaultless three-case
   vocabulary, distinct **by type**: `rigid(RigidMotion)` — canonical unit
   quaternion + translation per `rigid-motion/binary64-v1`, rigid by
   construction so no orthonormality tolerance exists;
   `affine(AffineRegistrationTransform)` — exact `isAffine` bottom row +
   invertibility proven by the `VOXELIA-ALG-0016` determinant authority;
   `deformable(DeformableRegistrationTransform)` — structural admission of
   a `float32` three-component `.vector` `deformationField` image with
   declared geometry (evaluation deferred to its consuming row). The
   aggregate carries `sourceSpace`/`destinationSpace` full descriptors —
   that is `VOX-REG-003`, one model, two rows. Oracle fixtures bit-exact
   (permutation, sign-flip `diag(-1,-1,1)`, irrational `sqrt 5` norm);
   `q`/`-q` admit to one stored form. Baseline shrinks by one. Full
   suite: `✔ Test run with 1351 tests in 242 suites passed`. **Next**:
   the registration result record — fixed data, moving data, metric,
   optimiser, multi-resolution schedule and convergence status identified
   per row two of the arc, composing `DataIdentity` references and this
   increment's category vocabulary.

1. **2026-08-07 — ~~`VOX-REG-002`~~ DISCHARGED: the registration result
   record (`ADR-0366`).** `RegistrationResult` in `VoxeliaCore`: fixed and
   moving data identified by full `DataIdentity` (a result outlives its
   images), metric and optimiser by `VoxeliaStringIdentifier`-pattern IDs
   plus optional versions (NOT closed enums — the arc has no
   implementations to enumerate yet, and identity is all the row asks),
   a structural never-optional multi-resolution schedule (positive shrink
   factor + finite non-negative sigma per level; single-resolution is one
   explicit level), a closed defaultless convergence vocabulary
   (converged/iterationLimitReached/stoppedByUser/failed) with iteration
   count and an honest optional final metric value, and the `ADR-0365`
   transform the run estimated. No ALG — admission only, no numerics.
   Baseline shrinks by one. Full suite: `✔ Test run with 1354 tests in
   243 suites passed`. **Next**: continue the registration arc per the
   `ADR-0351` order — the initialisation row (centred/geometry-based
   initial transforms) or the next unblocked registration row from the
   baseline table, composing the categories and this record.

1. **2026-08-07 — ~~`VOX-REG-004`~~ DISCHARGED: registration transform
   composition (`ADR-0367` + `VOXELIA-ALG-0069`).** One seam:
   `RegistrationTransformComposition.compose(outer, after: inner)` in
   `VoxeliaCore` requires `inner.destinationSpace == outer.sourceSpace` as
   FULL `CoordinateSpaceDescriptor` equality — a shared identifier over a
   disagreeing convention refuses typed (witnessed in the fixtures). The
   result spans the chain. Rigid stays rigid: the frozen Hamilton product
   re-admits through `VOXELIA-ALG-0068` admission so the stored form stays
   canonical (oracle fixtures bit-exact, including the sign-flip
   re-admission witness); mixed rigid/affine pairs lower to the existing
   `VOXELIA-ALG-0052` compose and honestly widen to affine; deformable
   operands refuse — a composed field without evaluation would be
   fabrication, and evaluation belongs to a later row. Baseline shrinks by
   one. Full suite: `✔ Test run with 1361 tests in 245 suites passed`.
   **Next**: the arc's remaining rows in baseline-table order — the next
   is the initial registration portfolio row (landmark + rigid + affine
   registration, `T`), which needs its metric/optimisation design; expect
   it to span more than one increment (landmark first: exact
   correspondence-based rigid/affine estimation with an oracle).

1. **2026-08-07 — `VOX-REG-005` ADVANCED (landmark affine member built;
   the row stays OPEN until the portfolio completes): `ADR-0368` +
   `VOXELIA-ALG-0070`.** `LandmarkAffineEstimation` in `VoxeliaSpatial`:
   least squares over `N >= 4` correspondences — frozen normal-equation
   assembly in ascending landmark order, one augmented 4x7 forward
   elimination with partial pivoting (largest pivot, ties to the lowest
   row; a pivot below `leastNormalMagnitude` refuses as degenerate — the
   `VOXELIA-ALG-0016` no-epsilon rule), left-associative back
   substitution. Determinism is the promise, NOT interpolation: fixture A
   pins the frozen elimination's own rounding bits on a consistent set;
   coplanar landmarks refuse typed; the inconsistent fixture pins the
   exact-dyadic least-squares row. `LandmarkAffineRegistration` in
   `VoxeliaCore` is the face: moving points must live in the source
   space, fixed in the destination (typed refusal), and the estimate
   re-admits through `AffineRegistrationTransform` so it proves its own
   invertibility. The row left the traced baseline (named in a record)
   but the LEDGER keeps it open. Full suite: `✔ Test run with 1367 tests
   in 247 suites passed`. **Next**: the landmark RIGID member — design
   decision to make first (deterministic frame alignment vs a quaternion
   eigen-solver; determinism consequences differ), then the
   intensity-driven members with the metric rows.

1. **2026-08-07 — `VOX-REG-005` ADVANCED again (landmark RIGID member
   built; the row stays OPEN for the intensity-driven members):
   `ADR-0369` + `VOXELIA-ALG-0071`.** The deferred design decision is
   made: Horn's quaternion method, NOT frame alignment (which fits a
   triad and discards every further landmark). The deterministic
   realisation is cyclic Jacobi with EXACTLY 30 sweeps in a frozen pair
   order — no convergence threshold; the sweep count is part of the
   model, so repeated estimation is bit-identical. The winning
   eigenvector re-admits through `VOXELIA-ALG-0068` (raw eigenvector
   admitted once at the end — re-normalising an already-normalised
   quaternion would shift last bits); translation = fixed mean minus the
   rotated moving mean, frozen folds. Exact collinearity refuses on BOTH
   sets with no epsilon (an unconstrained rotation about the landmark
   line would be fabrication); near-degenerate sets stay the caller's
   responsibility, the standing pivot contract. Oracle fixtures
   bit-exact: the exact-motion fixture pins the quaternion to its ulp
   and recovers translation `(1,2,3)` exactly; the inconsistent fixture
   pins the least-squares bits. `LandmarkRigidRegistration` face mirrors
   the affine member. Full suite: `✔ Test run with 1373 tests in 249
   suites passed`. **Next**: the metric rows — the mean-square and
   mutual-information-class metric architecture row (`I,T`), which the
   intensity-driven portfolio members and the pyramid row compose.

1. **2026-08-07 — ~~`VOX-REG-007`~~ DISCHARGED: the registration metric
   architecture (`ADR-0370` + `VOXELIA-ALG-0072`).** `RegistrationMetric`
   protocol in `VoxeliaCore` over aligned binary64 sample pairs — sampling
   is the CALLER'S seam (metrics never see images; the interpolation
   decision belongs to the intensity-registration increment), each
   instance declares its `ADR-0366` identity, version and POLARITY
   structurally so no optimiser guesses a direction. Evaluations return
   an optional value + contributing/excluded counts (the honesty rule
   again: absence, never zero; shrunken denominators visible). Two
   founding classes frozen: `MeanSquaresMetric` (frozen fold of squared
   differences) and `MutualInformationMetric` (caller-declared defaultless
   bin count + per-side ranges — an assumed range is a silent rescale;
   upper bound joins the last bin; out-of-range excluded+counted; platform
   libm log under the `VOXELIA-ALG-0060` determinism contract). Fixtures
   bit-exact: perfect correlation gives exactly libm's `log 2`,
   independence exactly zero. Baseline shrinks by one. Full suite:
   `✔ Test run with 1378 tests in 250 suites passed`. **Next**: continue
   the arc in baseline-table order — the pyramid architecture row
   (`I,T`, composing the existing `LevelSelectOperation` substance per
   the `ADR-0351` note) or the failure-reporting row (`T`, composing the
   `ADR-0366` convergence vocabulary), whichever the queue reads first.

1. **2026-08-07 — ~~`VOX-REG-006`~~ DISCHARGED: the registration pyramid
   (`ADR-0371`, NO new ALG).** `RegistrationPyramid` in `VoxeliaExecution`
   COMPOSES, it does not compute: per `ADR-0366` schedule level an
   optional `VOXELIA-ALG-0060` Gaussian pass (isotropic sigma, boundary
   `replicate` recorded once — zero padding would darken every border at
   every level) then an optional `VOXELIA-ALG-0056` level selection
   (isotropic shrink factor as a `BrickResolutionLevel`). Zero sigma
   skips smoothing (the Gaussian's own admission refuses it); unit factor
   skips selection (an identity copy under a new object identity would be
   fabricated derivation — the input passes through, identity INTACT,
   witnessed). Identity is supplied per level
   (`RegistrationPyramidLevelIdentity`), never fabricated; count mismatch
   refuses typed. Version-one bounds are the composed operations' own.
   The witness drives both operations over a constant calibrated volume:
   ceil-extents, index-step geometry scaling, constant preserved.
   Baseline shrinks by one. Full suite: `✔ Test run with 1380 tests in
   251 suites passed`. **Next**: the failure-reporting row (`T` —
   registration failure/non-convergence reported explicitly, never
   presented as a successful transform; compose the `ADR-0366`
   convergence vocabulary into an explicit success/failure seam), then
   the quality-metrics and reference-implementation rows to close the
   arc's unblocked queue.

1. **2026-08-07 — ~~`VOX-REG-008`~~ DISCHARGED: explicit registration
   failure (`ADR-0372`, no ALG).** `RegistrationOutcome` in `VoxeliaCore`
   is the presentation seam: a closed two-case vocabulary —
   `succeeded(result)` / `notConverged(report)` — where the failure
   report carries identities, configuration, status, iteration count and
   the honest optional final metric value AND NO TRANSFORM, so a
   non-converged run structurally cannot hand one out. ONLY `converged`
   is success: iteration-limit, user-stop and failure all classify into
   the failure case (accepting a limit-reached estimate is an explicit
   host decision against the report, never an implicit transform grab).
   `classify` is total and non-throwing — no path around the seam; a
   failure report of a `converged` status refuses typed (`notAFailure`).
   The `ADR-0366` record stays COMPLETE for audit — audit and
   presentation are different consumers with different honesty rules.
   Baseline shrinks by one. Full suite: `✔ Test run with 1383 tests in
   252 suites passed`. **Next**: the quality-metrics row (`T` —
   registration quality metrics available to the host; compose the
   `ADR-0370` metric evaluations and landmark residuals into a
   host-facing quality surface), then the reference-implementation row
   (`T,R` — its `R` half may join the owner batch) to close the arc's
   unblocked queue before the curved-planar/DICOM-tails arc.

1. **2026-08-07 — ~~`VOX-REG-009`~~ DISCHARGED: registration quality for
   the host (`ADR-0373` + `VOXELIA-ALG-0073`).** `RegistrationQuality`
   in `VoxeliaCore`: landmark residuals under an admitted rigid/affine
   transform — frozen row folds, one square root per residual, RMS and
   exact-selection maximum, bit-pinned (exact correspondences report zero
   EVERYWHERE; the perturbed fixture pins `(0, 0.5, 0.25)` / RMS
   `0x1.4a7e9cb8a3491p-2`). WHICH landmarks measure quality is the
   CALLER'S declaration — fitting set measures fit, held-out set measures
   TRE; the report records numbers, not the claim, because pretending to
   know would fabricate a validation the library did not perform. Spaces
   validate at the face; deformable refuses typed (no matrix to measure
   by). Similarity quality is already served by `ADR-0370` evaluations —
   not wrapped again. Baseline shrinks by one. Full suite: `✔ Test run
   with 1386 tests in 253 suites passed`. **Next**: the arc's LAST
   unblocked row — reference implementations before Metal acceleration
   is accepted into a diagnostic profile (`T,R`): the `T` half inspects
   that every registration path built this arc is a CPU reference
   implementation (no Metal path exists to gate); the `R` half joins the
   owner batch. Then the registration arc closes its engineering and the
   curved-planar/DICOM-tails arc opens.

1. **2026-08-07 — `VOX-REG-010` `T`-half DISCHARGED (`R` joins the owner
   batch): registration references before Metal (`ADR-0374`, tests only).
   THE REGISTRATION ARC'S ENGINEERING IS CLOSED.** Two witnesses in
   `VoxeliaValidation`: (1) the END-TO-END reference chain — landmark
   rigid + affine registration, composition across the space seam, a
   result record, outcome classification, residual quality — runs on CPU
   and reproduces the pinned bits (the estimated quaternion's one-ulp
   rounding propagates to residuals `~5e-16`, pinned EXACTLY, not
   rounded to a romantic zero); (2) a registry TRIPWIRE — no
   Metal-backend entry names a registration operation, so the day one
   registers, the test fails until the reference-first ordering is
   re-confirmed. A second Metal-prohibition gate was NOT added
   (`ADR-0338` d10: Core/Spatial already prohibit Metal per target). Arc
   summary: `ADR-0365..0374`, `ALG-0068..0073`, six oracles, rows
   REG-001..004/006..009 discharged, REG-005 open for intensity members
   (needs the optimiser design), REG-010 `R` + Metal acceptance
   owner-reserved. Full suite: `✔ Test run with 1388 tests in 254 suites
   passed`. **Next**: open the CURVED-PLANAR/DICOM-TAILS arc per
   `ADR-0351` — first row from that arc's queue (curved-planar
   reformation rows, then the DICOM tail rows), design-first as always.
