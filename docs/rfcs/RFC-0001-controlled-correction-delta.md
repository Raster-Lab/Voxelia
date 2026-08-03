---
document_id: "RFC-0001-CCD-01"
title: "Storage contract and logical data-model controlled-correction delta"
version: "0.1"
status: "Draft"
date: "2026-08-03"
document_type: "Controlled Correction Delta Proposal"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
owner: "Voxelia Project"
parent_rfc: "RFC-0001"
baseline_revision_set: "0.1.1"
proposed_revision_set: "0.1.2"
authority: "Non-authoritative proposal"
composed_adrs:
  - "ADR-0039"
  - "ADR-0040"
  - "ADR-0041"
supplemental_affected_requirements:
  - "VOX-DOC-008"
  - "VOX-DOC-009"
  - "VOX-DOC-010"
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
  - "VOX-ARC-007"
  - "VOX-ARC-011"
  - "VOX-ARC-012"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-005"
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
  - "VOX-RGN-001"
  - "VOX-RGN-002"
  - "VOX-RGN-003"
  - "VOX-RGN-004"
  - "VOX-RGN-006"
  - "VOX-RGN-007"
  - "VOX-RGN-008"
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
  - "VOX-META-001"
  - "VOX-META-002"
  - "VOX-META-011"
  - "VOX-IMG-001"
  - "VOX-IMG-002"
  - "VOX-IMG-009"
  - "VOX-IMG-015"
  - "VOX-DCM-003"
  - "VOX-DCM-005"
  - "VOX-DCM-006"
  - "VOX-DCM-008"
  - "VOX-DCM-010"
  - "VOX-DCM-013"
  - "VOX-DOC-008"
  - "VOX-DOC-009"
  - "VOX-DOC-010"
  - "VOX-VS1-005"
  - "VOX-VS1-006"
  - "VOX-VS1-008"
  - "VOX-VS1-014"
  - "VOX-VS1-017"
  - "VOX-VS1-018"
  - "VOX-VS1-019"
  - "VOX-VS1-020"
---

# RFC-0001-CCD-01 - Storage contract and logical data-model controlled-correction delta

## Decision status

This document is a **Draft, non-authoritative correction proposal** associated
with Draft `RFC-0001`. It does not amend a controlled document, accept an ADR,
select the mapping schedule, approve an `ImageData` staging option, close an
acceptance/evidence gate or authorise product source.

Every baseline `v0.1.1` file remains immutable and authoritative. The proposed
`v0.1.2` revision set becomes effective only if the exact selected deltas are
reviewed, approved, published together and recorded with their effective commit
and date. Empty approval fields mean open, never tacit approval.

## Purpose and scope

This companion turns [`RFC-0001-C01` through `C24`](RFC-0001-storage-contract-and-logical-data-model-composition.md#controlled-correction-inventory)
into an application-ready review delta. It records:

- exact baseline targets and proposed next revisions;
- role-based owners and required domain reviews;
- proposed replacement or addition text without changing controlled files;
- conditional branches for the unresolved mapping and `ImageData` choices;
- cumulative acceptance, source, identity/publication and mapping gates; and
- the evidence required before any row can be marked effective.

It does not freeze final public Swift names, errors, operation/canonical wires,
production limits, a builder API, allocator implementation, mapping/no-copy
implementation or verifier/policy authority.

## Approval record

| Field | Current value |
|---|---|
| Delta status | Draft |
| Mapping selection | Open: option 1 or option 2 |
| M1 `ImageData` selection | Open: defer public construction or allow explicitly unpublished structural binding |
| Project/document-owner approval | Open |
| Architecture review | Open |
| Core/Storage/Execution/Metal review | Open |
| API/concurrency/lifetime/security/privacy review | Open |
| Validation/release review | Open |
| Effective revision set | None |
| Effective commit/date | None |

## Target revision and ownership register

The repository has role-based ownership but no complete named signatory record.
This Draft therefore proposes roles; approval must later record actual reviewers.

| Target | Current authority | Proposed target | Primary owner | Required review | Rows |
|---|---|---|---|---|---|
| Project Foundation | `VOXELIA-FOUNDATION` `0.1.1` | No change under mapping option 1; `0.1.2` only under option 2 | Project Lead and document owner | Project governance, architecture | `C01` |
| Master Technical Architecture | `VOXELIA-MTA` `0.1.1` | Coordinated Draft-for-Review `0.1.2` | Voxelia Project/document owner | Architecture, Core, Storage, Execution, Metal, Validation | `C02`, `C03`, `C05`, `C07`, `C08`, `C13`, `C15`, `C21`, `C23`, `C24` |
| Requirements Baseline | `VOXELIA-REQ` `0.1.1` | Coordinated Draft-for-Review `0.1.2` | Voxelia Project/document owner | Requirements, architecture, domain owners, Validation | `C13`–`C15`, `C21`–`C24` |
| Validation and Benchmark Strategy | `VOXELIA-VBS` `0.1.1` | Coordinated `0.1.2`; no normative change unless `C11` review requires it | Voxelia Project/document owner | Validation Lead, security/privacy, lifetime | `C11` |
| Repository and Package Scaffold Specification | `VOXELIA-RPSS` `0.1.1` | Coordinated Draft-for-Review `0.1.2` | Project Lead/document owner | Architecture, release engineering | `C12` |
| Core Data Model Specification | `VOXELIA-CDMS` `0.1.1` | Coordinated Draft-for-Review `0.1.2` | Voxelia Project/document owner | Core, Storage, Execution, Geometry, API, identity/provenance | `C04`–`C11`, `C13`, `C15`, `C18`, `C21`–`C24` |
| First Vertical Slice Plan | `VOXELIA-FVSP` `0.1.1` | Coordinated Draft-for-Review `0.1.2` | Voxelia Project/document owner | DICOMKit, Core, Storage, Execution, Metal, Validation | `C16`, `C19`, `C20` |
| Core/Storage/Execution architecture and DocC overviews | Current unversioned files | Same effective correction commit as the approved revision set | Architecture plus respective module maintainers | Documentation and domain review | `C17` |
| Proposed `ADR-0039`–`ADR-0041` | Current in-place Proposed revisions | Reconciled in-place Proposed revisions; accepted only after corrections are effective | Architecture maintainers | Listed ADR reviewers | `C14` and dependency order |

For unversioned repository documents, “same effective correction commit” is
the revision identity. Its commit hash must be written into this record before
the package is considered effective.

## Gate classes

Gate classes are cumulative:

- `A`: the exact correction or no-change disposition is approved and effective
  before a dependent ADR may be accepted;
- `S`: final API/errors/limits and focused implementation evidence close before
  relevant product source;
- `I`: identity, metadata, provenance and publication dependencies close before
  claim-bearing `ImageData` publication; and
- `M`: the governed schedule plus platform/lifetime/fault/pressure evidence
  close before mapped product source.

Every correction row starts `Open`. This companion cannot close a gate.

## Proposed exact deltas

### RFC-0001-C01 — Foundation mapping schedule

- **Targets:** Foundation authority/precedence and roadmap Phase 1/Phase 5.
- **Owner/review:** Project Lead, Foundation document owner, architecture.
- **Gate:** `A`, `M`.
- **Status:** Open; mapping option not selected.

**Option 1 — Foundation-preserving no-change disposition:** retain Foundation
`0.1.1` unchanged. Record this exact interpretation in the approval:

> Phase 1 “storage abstractions” authorises backend-neutral contracts, isolated
> lifetime evidence and the owned contiguous implementation required by the
> subordinate M1 plan. Phase 5 “memory-mapped storage” owns the first production
> mapped provider. No subordinate document may move that provider earlier.

**Option 2 — formal Foundation revision:** create Foundation `0.1.2` before any
subordinate alignment. Add production memory-mapped storage explicitly to Phase
1 and explain why the Phase 5 bullet is retained, moved or narrowed. No exact
option-2 wording is approved by this Draft.

### RFC-0001-C02 — MTA Core/Storage contract and read sketches

- **Targets:** MTA `0.1.2` §8.2, §15.1, §15.3 and Appendix D.1.
- **Owner/review:** Architecture, Core, Storage, concurrency/lifetime.
- **Gate:** `A`, `S`.

Preserve the package edge and replace the mixed ownership/API sketches with:

> `VoxeliaCore` owns backend-neutral logical/representation, characteristic,
> optional-operation, snapshot, complete-read, owned-result, scoped-lease,
> typed-error and checked-erasure contracts, including erasure/witness boxes and
> private result-target admission/adoption. `VoxeliaStorage` owns concrete
> providers, source/mapping allocations, I/O, mappings, caches and synchronous
> resource release. Core never imports Storage.

Replace the async caller-owned writable-destination sketch with normative prose:

> A Core-owned coordinator validates the exact admitted binding and budgets,
> reserves before fallible private-target construction, gives the provider only
> a bounded non-owning monotonic fill capability and accepts only an outcome.
> Core alone closes fill, stamps preparation, arbitrates commit/cancellation/
> invalidation and returns one complete owned immutable result. Non-commit work
> remains charged until provider drain. Final public spelling is separately
> gated.

### RFC-0001-C03 — MTA mapping milestone

- **Targets:** MTA `0.1.2` §44.5 and §45 Stage 3.
- **Owner/review:** Architecture, Storage, Validation.
- **Gate:** `A`, `M`.

Apply the selected `C01` branch. Under option 1 replace “contiguous or mapped
storage” in §44.5 with:

> one verified owned contiguous storage provider; mapping contracts and
> isolated lifetime evidence do not imply a production mapped provider

Under option 1 replace Stage 3 with:

> Core-owned storage contracts and checked erasure; one owned contiguous
> provider; complete owned region reads; scoped contiguous-lifetime evidence;
> storage views and cache foundations. Production mapped storage remains Phase
> 5 and requires its separate platform/lifetime/fault evidence.

Option 2 may retain early mapped implementation wording only after the effective
Foundation `0.1.2` revision exists.

### RFC-0001-C04 — CDMS module ownership and type inventory

- **Targets:** CDMS `0.1.2` §6 and Appendix A.
- **Owner/review:** CDMS owner, Architecture, Core, Storage.
- **Gate:** `A`, `S`, `I`.

Replace the Storage row in §6 with two rows:

> Backend-neutral logical/representation, storage-operation, snapshot,
> complete-read, result, lease, error and checked-erasure roles — `VoxeliaCore`.

> Concrete contiguous/mapped/tiled/bricked/compressed/callback/cache providers,
> source/mapping resources and I/O — `VoxeliaStorage`.

In Appendix A move or replace `StorageDescriptor`, `StorageCapabilities`,
`ImageStorage` and `AnyImageStorage` with backend-neutral Core roles before
aggregate source. Keep concrete provider/resource types in Storage. Do not add
`Core -> Storage` and do not create duplicate lookalike families.

### RFC-0001-C05 — Structural data handle versus coherent publication

- **Targets:** MTA `0.1.2` §11.4; CDMS `0.1.2` §37.
- **Owner/review:** Core, Execution, identity/provenance reviewers.
- **Gate:** `A`, `S`, `I`.

Replace CDMS §37.2 publication implications with:

> A structural Core data handle may bind an exact storage snapshot to a
> storage-independent logical descriptor only under the selected `C24` staging
> option. Storage compatibility uses the exact logical binding and admitted
> representation; source byte order or provider labels do not establish logical
> equality. Storage never attaches metadata/provenance, assigns identity,
> publishes a cache alias or returns claim-bearing `ImageData`.

Add to MTA §11.4 and CDMS §37:

> Execution publishes toolkit-managed results; an explicit host/import
> coordinator may publish imported results. Publication is one generation-
> pinned atomic bundle of storage, descriptor, identity, metadata, provenance
> and cache admission after every independent dependency is satisfied.

### RFC-0001-C06 — Logical binding and tagged representation

- **Targets:** CDMS `0.1.2` §§15–16, 19, 38, 41 and Appendix F.
- **Owner/review:** Core, Storage, Geometry and adapter maintainers.
- **Gate:** `A`, `S`, `I`.

Replace the optional-field `StorageDescriptor` model with these semantic layers:

> A storage-independent logical binding contains exact shape, decoded scalar
> type, component count and logical component ordinals. A separate tagged
> representation is either fully checked decoded-strided addressing or an exact
> typed opaque representation. Organisation, locality/backing, persistence,
> resolution description and integrity claim are orthogonal characteristics.

Add the migration rule:

> Existing scalar/component fields are projected losslessly into the new roles
> before deprecation. `.native` is resolved before persistence. Ambiguous old
> values fail; no adapter silently guesses component mapping, packing, valid-bit
> semantics or logical identity.

### RFC-0001-C07 — Operations, characteristics, evidence and residency

- **Targets:** MTA `0.1.2` §15.3 and §18; CDMS `0.1.2` §39 and §62.
- **Owner/review:** Core, Storage, Metal.
- **Gate:** `A`, `S`.

Replace the invariant-bearing public raw `OptionSet` with:

> Immutable characteristics describe representation facts. Closed optional
> operations are callable only through exact retained witnesses. Runtime
> results/evidence describe completed reads, leases, verified observations or
> freezes for their exact scope. Metal owns generation/device-qualified
> residency. No category inherits another category's authority.

Any operational wire is custom, versioned and fail-closed. Listing a future
builder/tile/brick/compression/resolution/digest category neither admits it at
M1 nor authorises source.

### RFC-0001-C08 — Safe complete read and checked erasure

- **Targets:** MTA `0.1.2` §15.1 and Appendix D.1; CDMS `0.1.2` §§40,
  57.4–57.5 and 58.
- **Owner/review:** Core, Storage, API, concurrency, lifetime, security.
- **Gate:** `A`, `S`.

Delete the public async writable-pointer destination. Replace it with:

> Core reserves request/byte budgets before fallible private target
> construction. The provider receives only a weak/non-owning monotonic bounded
> fill and returns only an outcome. Core closes fill, stamps preparation and
> commits one exact decoded packed-interleaved owned result. Invalid admission
> creates no seal/reservation/provider call; cancellation/stale/failure/
> abandonment returns only after drain and private-owner retirement.

Add:

> Erasure performs one checked retained-witness dispatch, preserves typed
> incompatible/unsupported failure and never falls back. Scoped byte access
> lends an owning immutable `Data` synchronously; no bare span/pointer escapes.

Final API/error names and production limits remain `S`-gated.

### RFC-0001-C09 — Exact compatibility and mapped snapshots

- **Targets:** CDMS `0.1.2` §§41–43 and Appendix F.
- **Owner/review:** Core, Storage, security/lifetime.
- **Gate:** `A`, `S`, `M`.

Replace compatibility wording with:

> Compatibility requires the exact logical binding, complete one-to-one
> physical-to-logical component decoding, checked addressing/coverage and exact
> admitted authority/representation/owner/snapshot/generation. Source byte
> order, valid-bit interpretation, packing and layout are decoding evidence, not
> logical equality.

Replace mapped immutability wording with:

> Direct mapped access requires an immutable stable mapping snapshot for the
> complete scope and binds authority, logical binding, representation, owner,
> snapshot, generation, file identity, offset, length, page/alignment,
> external-change policy and strong mapping owner. Mutable files may use copied
> private staging plus fail-closed revalidation; that is not direct mapping.

### RFC-0001-C10 — Builder and publication separation

- **Targets:** MTA `0.1.2` §15.4; CDMS `0.1.2` §48 and §70.6.
- **Owner/review:** Storage, Core, Execution, identity/provenance.
- **Gate:** `A`, `S`, `I`.

Replace the current builder commit contract with:

> Builder acquisition/freeze requires a separate accepted contract defining
> authority, exclusivity, concurrency, bounded coverage, cancellation/failure,
> accounting, stale/replay and hand-off. A successful freeze returns only an
> unpublished immutable storage snapshot plus separate representation evidence.
> Storage does not accept metadata/provenance, create identity or return
> `ImageData`.

Delete “Builder commit returns immutable `ImageData`” from CDMS §70.6. Do not
replace it with an M1 builder implementation criterion.

### RFC-0001-C11 — Concurrency, memory, errors and validation

- **Targets:** CDMS `0.1.2` §§57–59, 64.7, 67 and 72; VBS `0.1.2` §§22,
  34–35 and 38 for alignment review.
- **Owner/review:** Core, Storage, Validation, concurrency, security/privacy.
- **Gate:** `A`, `S`.

Add these normative invariants to CDMS:

> The Core gate is the sole local cancellation/invalidation/prepare/commit
> linearisation point. First terminal state wins. Non-commit work and bytes
> remain charged until drain. Active targets and retained result-backing aliases
> share one live-byte ledger independent of recyclable tombstones. Gate-held
> code invokes no provider/allocator/callback/destructor. Errors are typed,
> bounded and redacted by default.

Validation must cover exact allocation-failure ordering, fill violations,
terminal races, uncooperative cancellation, drain, retained aliases, tombstone
reuse, erasure substitution and full-compilation lifetime escape cases. If VBS
already allocates these dimensions adequately, record an explicit no-normative-
change disposition for VBS `0.1.2`.

### RFC-0001-C12 — RPSS product purpose without graph change

- **Targets:** RPSS `0.1.2` §11 and Appendices B–C.
- **Owner/review:** Project Lead, Architecture, release engineering.
- **Gate:** `A`.

Replace the `VoxeliaStorage` purpose “Concrete storage and cache abstractions”
with:

> Concrete storage/cache implementations and services

Preserve `VoxeliaStorage -> VoxeliaCore`, every target edge, prohibited import
and path ownership. Add no product or dependency.

### RFC-0001-C13 — Requirements ownership and staging separation

- **Targets:** Requirements `0.1.2` §§6.5, 6.7, 6.14 and 9.2–9.4.
- **Owner/review:** Requirements owner, Architecture, Core, Storage, Execution,
  Metal, Validation.
- **Gate:** `A`, `S`, `I`.

Replace `VOX-ARC-003` with:

> `VoxeliaCore` shall own canonical logical descriptors, backend-neutral
> storage/read/lease/error/erasure contracts, data-handle structures, regions,
> metadata/provenance/identity values and common errors.

Replace `VOX-ARC-004` with:

> `VoxeliaStorage` shall own concrete storage/cache providers, source/mapping
> resources, I/O and synchronous resource release, subject to each provider's
> governed milestone.

Extend `VOX-DAT-013`:

> The logical descriptor and identity projection shall remain independent of
> physical byte order, component arrangement, strides, allocation padding,
> storage provider and Metal residency.

Apply `C14`, `C15` and `C24` for mapping, capability/residency and data-handle
milestone wording rather than duplicating those choices here.

### RFC-0001-C14 — Requirements mapped-provider choice

- **Targets:** Requirements `0.1.2` §5 summary, §6.14 `VOX-STO-004`, §9.6;
  Proposed `ADR-0039`/`ADR-0041`.
- **Owner/review:** Project/Requirements owner, Architecture, Storage,
  Validation.
- **Gate:** `A`, `M`.
- **Status:** Open; follows `C01`.

Under mapping option 1 replace `VOX-STO-004` with:

> `VOX-STO-004` — Production memory-mapped storage shall be implemented and
> validated for immutable large-volume representations, with exact mapping
> binding and platform/lifetime/fault evidence. Priority P0; verification T,A;
> target M5.

Under option 2 retain the M1 target only after the effective Foundation
revision and aligned evidence plan. Proposed ADR-0039 must remain mapping-
neutral until this branch is approved; Proposed ADR-0041's evidence gates are
retained under either option.

### RFC-0001-C15 — Milestone allocation of characteristics and evidence

- **Targets:** Requirements `0.1.2` §§6.14, 9.2, 9.4, 9.6 and 9.10; MTA
  `0.1.2` §§15.3/18; CDMS `0.1.2` §§39/62/70.6.
- **Owner/review:** Requirements, Architecture, Storage, Execution, Metal.
- **Gate:** `A`, `S`.

Replace `VOX-STO-002` with:

> Voxelia shall define separate immutable storage characteristics, closed
> callable optional operations backed by exact witnesses, runtime evidence and
> Metal-owned residency observations covering readable regions, contiguous and
> mapped access, locality/backing, compression/multi-resolution, future
> mutability and integrity/digest scope without conflating them. M1 shall include
> complete immutable reads and contiguous access; it shall not imply later
> provider implementations, verification, locality, mutability or residency
> from a capability label.

Allocate dynamic residency to M3; mapping, representation integrity and
independent compressed/decoded/GPU eviction to M5; callback/remote providers and
sequential sessions to M9. Remove builder, digest verification and residency
completion implications from the M1 storage checklist.

### RFC-0001-C16 — FVSP unpublished snapshot and publication authority

- **Targets:** FVSP `0.1.2` §§14–15, 19.2–19.3 and 41.1–41.2.
- **Owner/review:** FVSP owner, DICOMKit, Storage, Execution, Metal, Validation.
- **Gate:** `A`, `S`, `I`.

Replace “publish the storage through `VoxeliaStorage`” with:

> finalise one unpublished immutable Storage provider snapshot and its
> representation evidence; then let the import coordinator atomically publish
> the coherent Core data bundle after descriptor, identity, metadata,
> provenance and generation checks

Retain the one-full-decoded-allocation steady-state rule. The internal Metal
bridge remains Metal/Execution state and does not turn Storage into publication
authority.

### RFC-0001-C17 — Module overview and DocC alignment

- **Targets:** [`docs/architecture/modules/VoxeliaCore.md`](../architecture/modules/VoxeliaCore.md)
  Purpose/M0 status; [`Sources/VoxeliaCore/VoxeliaCore.docc/VoxeliaCore.md`](../../Sources/VoxeliaCore/VoxeliaCore.docc/VoxeliaCore.md)
  summary/M1 status/topics; [`docs/architecture/modules/VoxeliaStorage.md`](../architecture/modules/VoxeliaStorage.md)
  Purpose/M0 status; [`Sources/VoxeliaStorage/VoxeliaStorage.docc/VoxeliaStorage.md`](../../Sources/VoxeliaStorage/VoxeliaStorage.docc/VoxeliaStorage.md)
  summary/M0 status/topics; [`docs/architecture/modules/VoxeliaExecution.md`](../architecture/modules/VoxeliaExecution.md)
  Purpose/M0 status; and [`Sources/VoxeliaExecution/VoxeliaExecution.docc/VoxeliaExecution.md`](../../Sources/VoxeliaExecution/VoxeliaExecution.docc/VoxeliaExecution.md)
  summary/M0 status/topics.
- **Owner/review:** Architecture maintainers and respective module maintainers.
- **Gate:** `A`, `S`.

Apply these exact purpose boundaries consistently:

> `VoxeliaCore`: canonical scientific data plus backend-neutral logical/
> representation, storage operation, snapshot, read-result, lease, typed-error
> and checked-erasure contracts. It owns no concrete provider.

> `VoxeliaStorage`: concrete storage/cache providers, resources, I/O and
> synchronous release implementing Core contracts. It does not publish
> `ImageData`.

> `VoxeliaExecution`: operations, scheduling, cancellation, generation and the
> later coherent publication/cache-admission coordinator for toolkit-managed
> results.

Each page must preserve the implemented status accurately: existing Core leaves
remain as documented; Storage contains scaffold/declaration leaves; no aggregate
storage/read/publication API currently exists or is authorised. Future aggregate
source remains gated until the RFC, corrections and ADRs are accepted.

### RFC-0001-C18 — Lossless legacy projection and pre-1.0 migration

- **Targets:** CDMS `0.1.2` §§15–16, 49.4, 68 and Appendix A; later Core/
  Geometry source/tests and changelog.
- **Owner/review:** Core, Geometry, API, release engineering.
- **Gate:** `A`, `S`, `I`.

At `A`, approve only this migration disposition:

> Introduce explicit lossless compatibility projections from current
> `ScalarFormat`, `ComponentDescriptor` and affected Geometry declarations into
> the corrected logical/representation roles before any field is deprecated or
> removed. Preserve every old value or fail ambiguity. Resolve `.native` before
> persistence. Migrate affected Core/Geometry consumers together and document
> later breaking 0.x removal in the changelog.

No current product source changes at `A`; source and publication remain `S/I`-
gated.

### RFC-0001-C19 — FVSP decoded descriptor versus source facts

- **Targets:** FVSP `0.1.2` §§16 and 18.
- **Owner/review:** FVSP, Core, DICOMKit, identity reviewers.
- **Gate:** `A`, `S`, `I`.

Replace the descriptor bullets “source scalar format” and “technical metadata”
with:

> exact decoded scalar type and logical component order

> technical metadata stored in `MetadataCollection`, outside the descriptor

Retain source byte order, valid bits, signed extension/zero extension and
physical arrangement in adapter representation metadata and provenance. They
do not enter logical descriptor identity.

### RFC-0001-C20 — FVSP frame ownership shapes remain planning inputs

- **Targets:** FVSP `0.1.2` §§16.1, 19.2–19.3, 39.1–39.2 and 41.1–41.2.
- **Owner/review:** FVSP, DICOMKit, Core, Storage, concurrency/lifetime.
- **Gate:** `A`, `S`, `I`.

Add after the frame-ownership list:

> These shapes are adapter planning inputs, not the public storage-read or
> builder contract. A borrowed frame is consumed or copied before its owner is
> released. A caller-owned destination or streamed fill may be used only after
> a separate accepted bounded-fill/builder contract proves lifetime,
> cancellation, allocation accounting and no partial publication. No mutable
> pointer crosses suspension in public API.

### RFC-0001-C21 — Conditional copy avoidance

- **Targets:** Requirements `0.1.2` §6.9 `VOX-RGN-004`; MTA `0.1.2` §11.2;
  CDMS `0.1.2` §§5.9, 31, 42.3 and 70.7.
- **Owner/review:** Requirements, Core, Storage, performance/lifetime.
- **Gate:** `A`, `S`.

Replace `VOX-RGN-004` with:

> Region-read correctness shall use a complete owned immutable result. Voxelia
> shall additionally support copy-avoiding logical views or synchronous scoped
> leases when exact layout, owner lifetime, alias accounting and mapping
> stability permit them. Copy avoidance is conditional, not a universal success
> guarantee.

### RFC-0001-C22 — Mutable storage and builder scope

- **Targets:** Requirements `0.1.2` §6.14 `VOX-STO-010`; MTA `0.1.2` §15.4;
  CDMS `0.1.2` §§48, 70.6 and 72.
- **Owner/review:** Requirements, Storage, Execution, concurrency.
- **Gate:** `A`, `S`, `I`.

Replace `VOX-STO-010` with:

> If a future mutable storage/builder contract is provided, it shall define
> authority, exclusivity, concurrency, allocation accounting, cancellation,
> failure, freeze and immutable hand-off explicitly. No builder implementation
> is an M1 requirement until that separate contract is accepted.

Keep `builderAcquisition` only as a reserved cross-milestone operation category
and remove its M1 implementation implication.

### RFC-0001-C23 — Separate identity and evidence domains

- **Targets:** MTA `0.1.2` §11.3; Requirements `0.1.2` §6.9
  `VOX-RGN-007`/`008`; CDMS `0.1.2` §§32–33, 37.2/37.4/37.5, 56 and 59.
- **Owner/review:** Architecture, Requirements, Core, identity/provenance,
  security.
- **Gate:** `A`, `S`, `I`.

Add this shared rule:

> Representation claims/evidence, logical sample sequence, complete descriptor-
> and-samples content identity, source/derivation claims and runtime assurance
> are separate versioned domains. A provider checksum or source-carried digest
> is a claim until verified for the exact admitted scope. A read source stamp
> proves only commit from one exact in-process runtime binding; it is not
> persistent origin, content identity, provenance, currentness or cache
> authority.

`VOX-RGN-007`/`008` retain their M2 identity obligation but must not permit a
source label or pending digest to substitute for complete immutable content
identity.

### RFC-0001-C24 — M1 structural binding versus M2 publication

- **Targets:** MTA `0.1.2` §11.4; Requirements `0.1.2` §6.7
  `VOX-DAT-014` and §§9.2–9.3; CDMS `0.1.2` §§37, 69 and 70.4–70.6.
- **Owner/review:** Requirements, Core, Execution, identity/provenance.
- **Gate:** `A`, `I`.
- **Status:** Open; staging option not selected.

**Option A — defer public construction:** retain priority `P0`, verification
`I,T`, set target `M2` and replace `VOX-DAT-014` with:

> At M2, an image data handle shall atomically bind a descriptor, immutable
> storage snapshot, complete identity, metadata and provenance under the
> publication authority. M1 may design and test structural compatibility but
> exposes no partially claim-bearing public `ImageData` construction.

**Option B — unpublished M1 structural binding:** retain priority `P0`,
verification `I,T`, target `M1` solely for the unpublished structural binding
and replace it with:

> M1 may provide an explicitly unpublished structural binding of an exact
> logical descriptor and immutable storage snapshot for internal composition.
> It carries no complete identity, metadata, provenance, cache or publication
> claim. At M2, the publication authority atomically constructs the coherent
> claim-bearing image data handle.

Under option B, M2 publication is traced to the existing M2 identity,
provenance, Execution generation and cache/publication obligations; it does not
create or double-count a second `VOX-DAT-014` row.

Under either option, Storage never publishes `ImageData`, and CDMS §70.4–70.6
must not require incomplete identity/provenance or builder publication at M1.

## Conditional requirement counts and indexes

The Requirements Baseline `0.1.1` summary records M1 `53`, M2 `57` and M5 `39`.
The selected `0.1.2` candidate must regenerate every summary/index/count from
the actual rows:

- mapping option 1 plus `C24` option A: M1 `51`, M2 `58`, M5 `40`;
- mapping option 1 plus `C24` option B: M1 `52`, M2 `57`, M5 `40`;
- mapping option 2 plus `C24` option A: M1 `52`, M2 `58`, M5 `39`; and
- mapping option 2 plus `C24` option B: M1 `53`, M2 `57`, M5 `39`.

No count in this Draft is effective. The revision generator/reviewer must
recompute, not manually trust these conditional arithmetic results.

## Atomic application and approval order

1. Finalise this exact delta candidate and record actual role-based reviewers.
2. Select `C01/C14` mapping option and `C24` publication-staging option.
3. Prepare the exact coordinated correction candidates, no-change disposition
   and reconciled Proposed ADR revisions without overwriting any `0.1.1` file.
4. Review candidates in dependency order: Foundation branch → MTA →
   Requirements → VBS/RPSS → CDMS → FVSP → module architecture/DocC; regenerate
   requirement counts/indexes, references, traceability and release ledgers.
5. Change `RFC-0001` from Draft to Accepted, recording actual reviewers, both
   selected branches, every proposed correction revision/disposition and the
   exact reconciled ADR revisions. RFC acceptance grants no source authority and
   does not make a correction or ADR effective.
6. If mapping option 2 is selected, approve Foundation `0.1.2` first; otherwise
   approve the explicit Foundation `0.1.1` no-change disposition. Then approve
   and make the selected correction revision set effective atomically in the
   reviewed dependency order.
7. Record revision, owner/reviewer, disposition, date and effective commit for
   every row.
8. Accept `ADR-0039`, `ADR-0040` and `ADR-0041` in that order. `ADR-0041`
   controls read authority, stamping, allocation, drain, result accounting,
   erasure and scoped-byte lifetime.
9. Close final API/error/wire/limit and focused source evidence gates before any
   relevant implementation.

No earlier step grants implied authority for a later one.

## Row closure record schema

Before a row can leave `Open`, its approval record must contain:

| Field | Required value |
|---|---|
| Correction ID | Exact `RFC-0001-Cnn` |
| Selected disposition | Exact approved replacement, addition or no-change branch |
| Target | Document ID/path and section |
| Effective revision | Version or unversioned effective commit |
| Owner | Recorded responsible role/person |
| Required reviewers | Recorded role/person and review result |
| Approval date | ISO date |
| Effective commit | Immutable Git commit |
| Remaining gates | Explicit `S`, `I` and/or `M`, never implied closed |
| Evidence | Focused document/link/count/graph/import or later source evidence |

“Addressed by RFC-0001” is not a valid closure record.

## Validation for this Draft

This documentation-only Draft requires only:

- documentation/front-matter/text validation;
- RFC-register and companion-link validation;
- exact `C01`–`C24` one-to-one crosswalk validation;
- requirement-ID union and relative-link validation;
- package-graph and prohibited-import checks because ownership is discussed;
- manifest and release-integrity regeneration/checks; and
- independent governance, architecture, API/concurrency/lifetime and
  traceability review.

It changes no product source, package target, dependency or evidenced probe
invariant. The ADR-0039–ADR-0041 probes and full Swift package suite need not be
rerun for this Draft.

## Open decisions and governance gaps

1. Select Foundation-preserving M5 production mapping or a formal Foundation
   revision for M1 mapping.
2. Select deferred public `ImageData` construction or an explicitly unpublished
   M1 structural binding.
3. Record named approvers/signatories; current governance supplies role-based
   owners only.
4. Decide final public names, wires, production ceilings, builder contract and
   verifier/policy authority in their separate gated artefacts.
5. Retain named `docs/rfcs/` ownership and signatory enforcement as an external
   governance gap. The repository validator now checks companion metadata,
   parent/register links, allocation and correction-ID consistency, but a
   structural pass does not establish reviewer identity or approval authority.

## References

- [RFC-0001 - Storage contract and logical data-model composition](RFC-0001-storage-contract-and-logical-data-model-composition.md)
- [Voxelia Project Foundation v0.1.1](../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1](../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [ADR-0039 - Closed storage capability and descriptor admission boundary](../architecture/decisions/ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md)
- [ADR-0040 - Normalized logical sample and representation projection boundary](../architecture/decisions/ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md)
- [ADR-0041 - Safe storage read transaction and type-erasure lifetime boundary](../architecture/decisions/ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md)
