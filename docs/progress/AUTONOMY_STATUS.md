# Voxelia autonomous progress ledger

Last updated: 2026-08-02 (Asia/Kolkata)

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

## Verification evidence

- Automation definition reports `status = "ACTIVE"` and `FREQ=MINUTELY;INTERVAL=15`.
- Local host reports `arm64`, macOS 26.5.1, Xcode 26.6, and Swift 6.3.3.
- The original imported SHA-256 ledgers passed and all 280 baseline inventory records matched size and digest before development changes.
- The current 364-entry manifest covers every releasable file except its intentional self-reference exclusion, with no case-folded path collision.
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
- `swift build --target VoxeliaCore` and strict format lint passed for the
  metadata-key slice.
- `swift test --filter MetadataKey` executed only five key tests; typed/erased
  opaque pair preservation, case-sensitive Hashable identity, both blank-field
  errors, generic Sendable behavior and strict contextual erased-key Codable all
  passed.
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
  validity or a stable public `SIMD3<Double>` serialization shape.
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
- `ContentID` is deferred because the MTA and CDMS disagree on algorithm and
  digest storage types, required scope has no declared record field, custom
  algorithm identity is incomplete, and canonical digest serialization remains
  undecided. Digest computation must not precede those contracts.
- `DigestAlgorithm.custom` alone is not an approved persistent or distributed
  identity; it still needs a namespaced algorithm identifier whose record shape
  is not defined. `ContentScope` likewise remains vocabulary until an identity
  record has an approved scope field.
- `SourceIdentity`, `DerivationIdentity` and `DataIdentity` remain blocked by
  `ContentID`; `DataIdentityReference` is also undefined, and record-level
  empty, duplicate and consistency invariants are not specified.
- Recursive metadata values, entries and collections remain deferred pending
  finite-value, canonical instant, binary, coded-concept equality, enum-tag,
  multiplicity, typed-access and privacy-attachment decisions.
- `MetadataPrivacyClass` supplies vocabulary only; host logging, export and
  redaction controls remain authoritative and no default policy is inferred.
- Metadata-key erasure/conversion, namespace schemas, multiplicity and typed
  accessors remain deferred; the current key types define only validated pair
  identity and the erased wire shape.
- `CodedConcept` defines deterministic record identity, not external terminology
  equivalence. Scheme-specific aliases, version compatibility and ontology
  resolution require an explicit resolver or ADR.
- Provenance records, software/operation/execution details, warnings and graph
  references remain blocked by undefined types, timestamp/identifier policy,
  `ContentID`, validation-state schema and graph invariants. `ProvenanceKind`
  does not imply those records exist or are verified.
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
- The checked-in template and all five file-backed ADRs now contain the RPSS
  section 9.2 areas, and the ADR checker enforces their presence, uniqueness and
  meaningful bodies. It intentionally does not infer decision quality, status
  transitions, module validity or supersession semantics from prose.
- Proposed `ADR-0021` is review material only. Until its status becomes
  Accepted and subordinate documents are corrected, the axis-model public API
  remains blocked and no implementation may rely on its recommendation.
- Proposed `ADR-0022` likewise does not resolve the convention conflict until
  accepted. Even after acceptance, `CoordinateSpaceDescriptor` remains blocked
  on display/custom unit policy; the enum must not imply a unit, transform or
  external frame identity.
- Proposed `ADR-0023` does not resolve the transform conflict until accepted.
  Piecewise-linear transforms remain undefined, and lookup declarations do not
  establish interpolation, missing-entry or extrapolation behavior.
- Point containment and axis-aligned bounds intersection are supporting
  evidence for `VOX-SPA-011`, not completion: the requirement also covers
  planes, rays, oriented bounds and rendering or interaction intersections that
  remain blocked or unimplemented.

## Exact next action

Audit the governing definitions and invariants for `Plane`, `Ray` and oriented
bounds as the remaining low-level `VOX-SPA-011` primitives. Select only the
smallest fully specified value or operation for implementation; record a
blocker rather than inventing normalization, tolerance or intersection policy.

## Test policy for the next action

- For an implemented spatial slice, run strict formatting, the affected Spatial
  and direct-consumer builds, and only that type's exact focused tests plus
  integrity checks. Do not run the full Swift suite.
- Do not rerun the complete scaffold suite unless a later cross-cutting change
  affects its gate or a release candidate is being accepted.
- Keep unavailable SDKs, signing contexts, repository settings and human
  approvals recorded as explicit evidence gaps rather than treating them as
  passing.
