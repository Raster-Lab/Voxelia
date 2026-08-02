# Voxelia autonomous progress ledger

Last updated: 2026-08-02 (Asia/Kolkata)

## Goal

Complete Voxelia through its approved milestone roadmap with Apple-only platform discipline, diagnostic correctness, strict concurrency, provenance, validation evidence, and release-quality documentation.

## Current state

- Active implementation milestone: M1 - core data and spatial foundations.
- M1 implementation status: the first five core-data slices, `ImageShape` /
  `ShapeError`, `ImageIndex`, `ImageRegion` / `RegionError`, and canonical
  scalar and component formats are implemented and locally verified.
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

## Verification evidence

- Automation definition reports `status = "ACTIVE"` and `FREQ=MINUTELY;INTERVAL=15`.
- Local host reports `arm64`, macOS 26.5.1, Xcode 26.6, and Swift 6.3.3.
- The original imported SHA-256 ledgers passed and all 280 baseline inventory records matched size and digest before development changes.
- The current 306-entry manifest covers every releasable file except its intentional self-reference exclusion, with no case-folded path collision.
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
- The regenerated 305-record inventory and 306-entry SHA-256 ledger pass the
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

## Exact next action

Audit and implement the next independent M1 image-semantics slice,
`ImageSemantic`, from Core Data Model Specification section 17 for
`VOX-DAT-012`. Keep descriptor-level semantic contradiction checks in a later
`ImageDescriptor` initializer where scalar, component and geometry context is
available together.

## Test policy for the next action

- Run `swift build --target VoxeliaCore` and only image-semantic-filtered
  VoxeliaCore tests for the next slice.
- Do not rerun the complete scaffold suite unless a later cross-cutting change
  affects its gate or a release candidate is being accepted.
- Keep unavailable SDKs, signing contexts, repository settings and human
  approvals recorded as explicit evidence gaps rather than treating them as
  passing.
