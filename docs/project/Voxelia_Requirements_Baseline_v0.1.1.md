---
document_id: VOXELIA-REQ
title: "Voxelia Requirements Baseline"
version: "0.1.1"
status: "Corrective Release"
document_type: "Requirements Baseline"
project: "Voxelia"
platform_policy: "Apple Silicon ARM64 and Apple operating systems only"
licence: "MIT"
language: "en-GB"
date: "2026-08-02"
owner: "Voxelia Project"
governing_documents:
  - "Voxelia Project Foundation v0.1.1"
  - "Voxelia Master Technical Architecture v0.1.1"
repository: "To be established"
supersedes: "Voxelia Requirements Baseline v0.1"
superseded_by: null
classification: "Public"
requirement_count: 486
---

# Voxelia Requirements Baseline v0.1.1

> **Platform applicability:** Voxelia exclusively targets Apple Silicon ARM64 hardware and Apple operating systems. References to operation across more than one platform mean only macOS, iOS/iPadOS, visionOS and tvOS within the Apple ecosystem. No alternate processor architecture, operating system, hosted Swift toolchain, renderer or compatibility target is within scope.

## Document control

| Field | Value |
|---|---|
| Document | Voxelia Requirements Baseline |
| Document identifier | `VOXELIA-REQ` |
| Version | 0.1.1 |
| Status | Corrective Release |
| Date | 2 August 2026 |
| Project | Voxelia |
| Governing documents | Voxelia Project Foundation v0.1.1; Voxelia Master Technical Architecture v0.1.1 |
| Licence | MIT |
| Language | British English |
| Requirement count | 486 |
| Intended audience | Project maintainers, systems engineers, architects, implementation teams, validation engineers, benchmark engineers, integrators and downstream product teams |

### Revision history

| Version | Date | Summary |
|---|---:|---|
| 0.1 | 2026-08-01 | Initial requirements baseline derived from the approved project foundation and master technical architecture. |
| 0.1.1 | 2026-08-02 | Corrective platform revision establishing Apple Silicon ARM64 and Apple operating systems as the exclusive supported environment without changing the requirement count. |

### Approval record

This version is a requirements draft. Formal approval roles, signatories, repository commit and release association shall be added when project governance is established.

---

## 1. Purpose

This document establishes the initial normative requirements baseline for Voxelia.

It converts the mission, scope, constraints and architectural decisions in the governing documents into uniquely identified and verifiable requirements for:

- project governance and licensing;
- supported platforms and packaging;
- canonical scientific, spatial and geometry models;
- storage, compression and Apple Silicon memory use;
- execution, concurrency, caching and provenance;
- CPU and Metal backends;
- image processing, segmentation and registration;
- diagnostic, volume, surface and Photorealistic Rendering;
- DICOMKit and Raster-Lab codec integrations;
- headless and distributed execution;
- extensibility, security, validation and performance;
- documentation, release and compatibility; and
- the first complete DICOM CT vertical slice.

This baseline defines what Voxelia shall achieve. Detailed implementation designs, algorithm mathematics, shader code and test procedures shall be maintained in lower-level specifications derived from these requirements.

---

## 2. Authority and precedence

The **Voxelia Project Foundation v0.1.1** is the governing project document.

The **Voxelia Master Technical Architecture v0.1.1** is the governing technical architecture.

If this baseline conflicts with the Project Foundation, the Project Foundation takes precedence. If it conflicts with the Master Technical Architecture without conflicting with the Foundation, the discrepancy shall be resolved by requirements review, architecture revision or an approved Architecture Decision Record.

No implementation convenience shall override a P0 diagnostic, safety, correctness, security or architecture-integrity requirement without formal change control.

---

## 3. Scope of this baseline

This baseline applies to:

- Voxelia core modules;
- optional Voxelia integration modules;
- public APIs;
- reference and accelerated implementations;
- Metal shaders;
- storage and cache formats;
- validation and benchmark infrastructure;
- example applications where they demonstrate normative behaviour;
- distributed job and result contracts; and
- release artefacts.

This baseline does not assign application-level requirements for:

- PACS or VNA behaviour;
- reporting or hanging protocols;
- user authentication or authorisation;
- browser user interfaces;
- hospital network policy;
- render-farm orchestration;
- peer discovery or enrolment;
- product licensing enforcement; or
- regulatory approval of downstream products.

---

## 4. Requirements conventions

### 4.1 Normative language

- **shall** indicates a mandatory requirement;
- **should** indicates a recommended requirement that may be deferred or waived with documented justification; and
- **may** indicates a permitted design option.

### 4.2 Requirement identifiers

Requirement identifiers use the form:

```text
VOX-<CATEGORY>-<NUMBER>
```

Identifiers are permanent. Removed requirements shall be marked retired rather than reused.

### 4.3 Priority

| Priority | Meaning |
|---|---|
| P0 | Mandatory for the stated milestone or for safety, correctness, architecture integrity or diagnostic suitability. |
| P1 | Required for the intended product capability, but may be scheduled after the earliest enabling milestone. |
| P2 | Desirable or extensibility-oriented; may be deferred without invalidating the initial baseline. |

### 4.4 Verification methods

A requirement may use more than one verification method.

| Code | Method |
|---|---|
| I | Inspection of source, configuration, package graph, documentation or generated artefacts. |
| A | Engineering analysis, including mathematical, architectural, performance, memory or security analysis. |
| T | Automated or controlled test against stated acceptance criteria. |
| D | Demonstration in a representative application, service or device environment. |
| R | Formal review of evidence, design, provenance, licence or process records. |

### 4.5 Delivery milestones

| Milestone | Meaning |
|---|---|
| M0 | Foundation, architecture and repository establishment |
| M1 | Core data, spatial and geometry foundations |
| M2 | CPU reference processing |
| M3 | Metal and Apple Silicon foundation |
| M4 | First DICOM CT vertical slice |
| M5 | Compression and large-volume storage |
| M6 | Diagnostic three-dimensional visualisation |
| M7 | Advanced processing, segmentation and registration |
| M8 | Photorealistic Rendering |
| M9 | Platform, headless and distributed expansion |
| M10 | Voxelia 1.0 publication baseline |

### 4.6 Requirement record fields

Each normative requirement records:

- **ID** — permanent requirement identifier;
- **Requirement** — testable normative statement;
- **Priority** — P0, P1 or P2;
- **Verification** — planned evidence method;
- **Target** — first intended delivery milestone;
- **Source** — governing document sections from which the requirement is derived.

A target milestone does not remove the requirement from the eventual Voxelia 1.0 baseline unless it is explicitly retired or moved to a separately versioned optional module.

---

## 5. Baseline summary

### 5.1 Requirements by category

| Category | Domain | Total | P0 | P1 | P2 |
|---|---|---:|---:|---:|---:|
| `GOV` | Project governance and scope control | 10 | 7 | 3 | 0 |
| `LIC` | Licensing and contribution provenance | 9 | 8 | 1 | 0 |
| `PLT` | Supported platforms and toolchain | 14 | 13 | 1 | 0 |
| `REP` | Repository and package distribution | 10 | 7 | 3 | 0 |
| `ARC` | Module and dependency architecture | 12 | 12 | 0 | 0 |
| `API` | Public API and type-system requirements | 12 | 10 | 2 | 0 |
| `DAT` | Canonical image and volume data model | 15 | 14 | 1 | 0 |
| `SPA` | Spatial model and coordinate systems | 14 | 13 | 1 | 0 |
| `RGN` | Regions, views and data identity | 9 | 7 | 2 | 0 |
| `META` | Metadata and provenance | 11 | 11 | 0 | 0 |
| `GEO` | Geometry model | 11 | 9 | 2 | 0 |
| `SEG` | Segmentation model and operations | 10 | 8 | 2 | 0 |
| `REG` | Registration model and operations | 10 | 8 | 2 | 0 |
| `STO` | Storage abstractions and integrity | 12 | 10 | 2 | 0 |
| `BRK` | Bricked and multi-resolution volume storage | 11 | 8 | 3 | 0 |
| `CMP` | Compression and codec integration | 14 | 12 | 2 | 0 |
| `EXE` | Operation and execution model | 16 | 14 | 2 | 0 |
| `CON` | Concurrency and task lifecycle | 10 | 9 | 1 | 0 |
| `CCH` | Planning, backend selection and caching | 9 | 7 | 2 | 0 |
| `CPU` | CPU backend | 9 | 6 | 3 | 0 |
| `MTL` | Metal backend and unified memory | 16 | 13 | 3 | 0 |
| `IMG` | Image-processing operations | 15 | 12 | 3 | 0 |
| `R2D` | Diagnostic two-dimensional presentation | 15 | 11 | 4 | 0 |
| `MPR` | Multiplanar, projection and curved reconstruction | 14 | 11 | 3 | 0 |
| `DVR` | Conventional volume rendering | 15 | 12 | 3 | 0 |
| `PRR` | Photorealistic Rendering | 17 | 13 | 4 | 0 |
| `SUR` | Surface and geometry rendering | 9 | 5 | 4 | 0 |
| `INT` | Interaction and viewport synchronisation | 10 | 9 | 1 | 0 |
| `DCM` | DICOMKit integration | 13 | 11 | 2 | 0 |
| `ADP` | Apple framework and interoperability adapters | 10 | 6 | 4 | 0 |
| `HLS` | Headless, off-screen and media output | 11 | 7 | 4 | 0 |
| `DST` | Distributed execution contracts | 12 | 9 | 3 | 0 |
| `EXT` | Extensibility and plug-in boundaries | 9 | 6 | 2 | 1 |
| `ERR` | Errors, diagnostics and observability | 9 | 7 | 2 | 0 |
| `SEC` | Security and privacy | 11 | 9 | 2 | 0 |
| `VAL` | Verification and validation | 16 | 15 | 1 | 0 |
| `PER` | Performance, memory and responsiveness | 13 | 7 | 5 | 1 |
| `DOC` | Documentation and traceability | 12 | 12 | 0 | 0 |
| `REL` | Versioning, release and compatibility | 10 | 9 | 1 | 0 |
| `VS1` | First DICOM CT vertical slice | 21 | 21 | 0 | 0 |

### 5.2 Requirements by priority

| Priority | Count |
|---|---:|
| P0 | 398 |
| P1 | 86 |
| P2 | 2 |
| **Total** | **486** |

### 5.3 Requirements by first target milestone

| Milestone | Count |
|---|---:|
| M0 | 46 |
| M1 | 53 |
| M2 | 57 |
| M3 | 37 |
| M4 | 78 |
| M5 | 39 |
| M6 | 46 |
| M7 | 44 |
| M8 | 19 |
| M9 | 41 |
| M10 | 26 |

---

## 6. Normative requirements

### 6.1 Project governance and scope control

**Primary source:** Foundation §§1–10, 25–26, 35–37; MTA §§1–4, 47–49

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-GOV-001` | Voxelia shall be maintained as a standalone open-source scientific image processing, spatial computing and visualisation toolkit. | P0 | I,R | M0 |
| `VOX-GOV-002` | The DICOM Workstation shall be treated as the first demanding reference application without making Voxelia dependent on that application. | P0 | I,R | M0 |
| `VOX-GOV-003` | The project shall preserve an explicit boundary between reusable toolkit capabilities and host-application policy, workflow and deployment responsibilities. | P0 | I,R | M0 |
| `VOX-GOV-004` | Material changes to project mission, licence, platform policy, diagnostic-grade commitments or scope shall require an approved revision of the Project Foundation. | P0 | I,R | M0 |
| `VOX-GOV-005` | Material architectural changes shall be recorded through an Architecture Decision Record before implementation is merged. | P1 | I,R | M0 |
| `VOX-GOV-006` | Significant public API, data-model, execution-model, storage-contract or diagnostic-behaviour changes shall use the project request-for-comments process. | P1 | I,R | M0 |
| `VOX-GOV-007` | Voxelia shall not implement PACS, VNA, reporting, hanging protocols, user authentication, browser user interfaces or hospital workflow as core toolkit functions. | P0 | I,R | M0 |
| `VOX-GOV-008` | Voxelia shall not claim to be a drop-in class-for-class or binary replacement for VTK or ITK. | P0 | I,R | M0 |
| `VOX-GOV-009` | The project shall maintain a documented register of deferred, excluded and application-owned capabilities. | P1 | I | M0 |
| `VOX-GOV-010` | Every release shall identify experimental, preview, validated, diagnostic-ready and deprecated capabilities without ambiguous status terminology. | P0 | I,R | M10 |

### 6.2 Licensing and contribution provenance

**Primary source:** Foundation §§23–26; MTA §§7, 37

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-LIC-001` | Voxelia source code shall be distributed under the MIT Licence. | P0 | I,R | M0 |
| `VOX-LIC-002` | The repository shall contain the complete MIT licence text in a root-level `LICENSE` file. | P0 | I | M0 |
| `VOX-LIC-003` | Source files should carry `SPDX-License-Identifier: MIT` where technically appropriate. | P1 | I | M0 |
| `VOX-LIC-004` | The repository shall maintain `THIRD_PARTY_NOTICES.md` for bundled and optional dependencies. | P0 | I,R | M0 |
| `VOX-LIC-005` | Each release shall include a machine-readable software bill of materials or an equivalent dependency inventory. | P0 | I,R | M10 |
| `VOX-LIC-006` | Contributors shall certify contribution provenance using the Developer Certificate of Origin or an approved equivalent. | P0 | I,R | M0 |
| `VOX-LIC-007` | Core distribution targets shall not depend on strong-copyleft libraries. | P0 | I,R | M0 |
| `VOX-LIC-008` | Weak-copyleft or otherwise restrictive dependencies shall be isolated in optional modules and shall require documented legal and architectural review. | P0 | I,R | M0 |
| `VOX-LIC-009` | Dependency licences shall be checked for compatibility with static linking, proprietary integration and Apple platform distribution. | P0 | I,R | M0 |

### 6.3 Supported platforms and toolchain

**Primary source:** Foundation §11; MTA §6, §42–43

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-PLT-001` | Voxelia shall support macOS 15 or later. | P0 | I,T | M3 |
| `VOX-PLT-002` | Voxelia shall support iOS 18 or later. | P0 | I,T | M9 |
| `VOX-PLT-003` | Voxelia shall support iPadOS 18 or later through the iOS platform declaration and platform-specific validation. | P0 | I,T | M9 |
| `VOX-PLT-004` | Voxelia shall support visionOS 2 or later. | P0 | I,T | M9 |
| `VOX-PLT-005` | Voxelia shall support tvOS 18 or later. | P0 | I,T | M9 |
| `VOX-PLT-006` | Apple Silicon macOS shall be the required development, continuous-integration, benchmark, diagnostic-workstation, headless-rendering, distributed-worker and release-preparation platform. | P0 | I,R | M0 |
| `VOX-PLT-007` | Voxelia shall target Apple Silicon ARM64 exclusively; Intel, x86/x64, non-Apple operating systems and non-Apple-hosted Swift toolchains shall be unsupported and excluded from build, validation, benchmark, release and compatibility claims. | P0 | I,T,R | M0 |
| `VOX-PLT-008` | The Swift tools version shall be 6.2 or later. | P0 | I,T | M0 |
| `VOX-PLT-009` | All Swift targets shall compile in Swift 6 language mode with strict concurrency checking enabled. | P0 | I,T | M0 |
| `VOX-PLT-010` | Swift Package Manager shall be the primary package and distribution mechanism. | P0 | I,D | M0 |
| `VOX-PLT-011` | Metal Shading Language shall be used for Voxelia-owned GPU kernels and render shaders. | P0 | I,T | M3 |
| `VOX-PLT-012` | The codebase shall use Swift Testing as the default test framework while permitting XCTest where required by platform tooling or integrations. | P1 | I,T | M0 |
| `VOX-PLT-013` | The public API shall not require callers to select a named Metal generation or commercial device model. | P0 | I,T | M3 |
| `VOX-PLT-014` | Device-specific behaviour shall be selected through capability detection rather than device-name checks. | P0 | I,T | M3 |

### 6.4 Repository and package distribution

**Primary source:** Foundation §§27, 31; MTA §§7–8, 43

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-REP-001` | Voxelia shall initially use a single public monorepo for core modules, optional modules, documentation, tests, benchmarks, validation assets, examples and tools. | P0 | I | M0 |
| `VOX-REP-002` | The root repository shall contain `README.md`, `LICENSE`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CODEOWNERS` and `THIRD_PARTY_NOTICES.md`. | P0 | I | M0 |
| `VOX-REP-003` | The repository shall contain dedicated `Sources`, `Tests`, `Benchmarks`, `Validation`, `Examples`, `Tools` and `docs` directories. | P0 | I | M0 |
| `VOX-REP-004` | Architecture decisions shall be stored under `docs/architecture/decisions/` with stable identifiers. | P0 | I | M0 |
| `VOX-REP-005` | Requirements, algorithms, shaders, validation and benchmark documentation shall have dedicated version-controlled locations. | P1 | I | M0 |
| `VOX-REP-006` | The Swift package shall expose focused products so adopters are not required to import every optional integration. | P0 | I,T | M0 |
| `VOX-REP-007` | An umbrella `Voxelia` product shall re-export stable general-purpose modules but shall not automatically re-export all optional integrations. | P1 | I,T | M10 |
| `VOX-REP-008` | Shader resources shall be owned by the module that compiles and executes them. | P0 | I,T | M3 |
| `VOX-REP-009` | External package dependencies shall be attached only to targets that require them. | P0 | I,T | M0 |
| `VOX-REP-010` | The package graph shall be automatically checked for prohibited cycles. | P1 | T | M0 |

### 6.5 Module and dependency architecture

**Primary source:** MTA §§5, 8, 43

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-ARC-001` | Dependencies shall flow from specialised modules towards stable foundational modules and shall not form cycles. | P0 | I,T | M0 |
| `VOX-ARC-002` | `VoxeliaSpatial` shall own coordinate spaces, units, transforms, planes, rays, bounds and spatial geometry. | P0 | I,R | M1 |
| `VOX-ARC-003` | `VoxeliaCore` shall own canonical descriptors, scalar formats, data handles, regions, metadata, provenance, identities and common errors. | P0 | I,R | M1 |
| `VOX-ARC-004` | `VoxeliaStorage` shall own concrete contiguous, mapped, tiled, bricked, compressed, callback-backed and cached storage implementations. | P0 | I,R | M1 |
| `VOX-ARC-005` | `VoxeliaExecution` shall own operations, execution sessions, scheduling, cancellation, progress, generation tracking, backend selection and result caching. | P0 | I,R | M2 |
| `VOX-ARC-006` | `VoxeliaImaging` shall define image-processing semantics without owning the Metal command lifecycle. | P0 | I,R | M2 |
| `VOX-ARC-007` | `VoxeliaGeometry` shall own point, line, curve, mesh, acceleration and geometry-operation abstractions. | P0 | I,R | M1 |
| `VOX-ARC-008` | `VoxeliaRendering` shall own backend-neutral scene, camera, viewport, layer, transfer-function, quality, request and result models. | P0 | I,R | M3 |
| `VOX-ARC-009` | `VoxeliaInteraction` shall own UI-framework-neutral interaction state and commands. | P0 | I,R | M4 |
| `VOX-ARC-010` | `VoxeliaCPU` shall own deterministic reference kernels and CPU backend registration. | P0 | I,R | M2 |
| `VOX-ARC-011` | `VoxeliaMetal` shall own Metal contexts, kernels, residency, render-graph execution, shader libraries, pipeline caches and GPU telemetry. | P0 | I,R | M3 |
| `VOX-ARC-012` | DICOMKit, codec, RealityKit, Model I/O, Core Image, headless, distributed and interoperability support shall be isolated in optional modules. | P0 | I,R | M0 |

### 6.6 Public API and type-system requirements

**Primary source:** Foundation §§7, 28–29; MTA §§9, 35, 40

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-API-001` | Public APIs shall describe required behaviour and semantics rather than expose backend command lifecycles. | P0 | I,R,T | M1 |
| `VOX-API-002` | Canonical public data types shall not expose `MTLTexture`, `MTLBuffer`, RealityKit entity types, Model I/O objects, Core Image objects, DICOMKit dataset types, VTK types or ITK types. | P0 | I,T | M1 |
| `VOX-API-003` | Public value types shall conform to `Sendable` where their semantics permit safe cross-concurrency transfer. | P0 | I,T | M1 |
| `VOX-API-004` | Public immutable descriptor types should conform to `Hashable` and `Codable` where stable serialisation is intended. | P1 | I,T | M1 |
| `VOX-API-005` | Public API names shall use domain terminology rather than internal GPU terminology unless the API is explicitly Metal-specific. | P0 | I,R | M1 |
| `VOX-API-006` | Operations shall use strongly typed inputs and outputs before type erasure is introduced for graph storage. | P0 | I,T | M2 |
| `VOX-API-007` | Type erasure shall preserve runtime type safety and shall fail with a typed error on incompatible inputs or outputs. | P0 | T | M2 |
| `VOX-API-008` | Public APIs shall not require an interactive window, SwiftUI view or AppKit view. | P0 | I,T,D | M3 |
| `VOX-API-009` | Public APIs shall permit off-screen and headless use. | P0 | T,D | M9 |
| `VOX-API-010` | API documentation shall state thread-safety, actor isolation, mutability, ownership, error and performance semantics for public types. | P0 | I,R | M10 |
| `VOX-API-011` | Pre-1.0 breaking API changes shall be documented in the changelog. | P1 | I | M0 |
| `VOX-API-012` | After 1.0, incompatible public API changes shall require a major semantic version. | P0 | I,R | M10 |

### 6.7 Canonical image and volume data model

**Primary source:** Foundation §§7–8; MTA §§9, 11–12

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-DAT-001` | Voxelia shall provide a dynamic-rank canonical image model. | P0 | I,T | M1 |
| `VOX-DAT-002` | The canonical shape type shall represent extents using a variable-length collection of positive integers. | P0 | I,T | M1 |
| `VOX-DAT-003` | Shape construction shall reject zero and negative extents. | P0 | T | M1 |
| `VOX-DAT-004` | Element-count calculation shall detect integer overflow and shall not wrap silently. | P0 | T,A | M1 |
| `VOX-DAT-005` | Core data types shall not impose a small fixed maximum image rank. | P0 | I,T | M1 |
| `VOX-DAT-006` | Each operation shall declare supported rank and axis semantics. | P0 | I,T | M2 |
| `VOX-DAT-007` | Optimised initial paths shall support rank-two and rank-three spatial data. | P0 | T | M2 |
| `VOX-DAT-008` | The data model shall permit additional time, phase, channel or component axes. | P1 | I,T | M7 |
| `VOX-DAT-009` | Scalar formats shall explicitly represent signed integers, unsigned integers and floating-point values required by supported operations. | P0 | I,T | M1 |
| `VOX-DAT-010` | Scalar format metadata shall include byte width, signedness and floating-point classification. | P0 | I,T | M1 |
| `VOX-DAT-011` | Component count and component semantics shall be represented independently from scalar format. | P0 | I,T | M1 |
| `VOX-DAT-012` | Image semantics shall distinguish scalar images, colour images, label maps, masks, vector fields and other supported domain meanings. | P0 | I,T | M1 |
| `VOX-DAT-013` | Image descriptors shall bind shape, scalar format, component information, spatial geometry and units without binding storage. | P0 | I,T | M1 |
| `VOX-DAT-014` | Image data handles shall bind a descriptor to storage, identity, metadata and provenance. | P0 | I,T | M1 |
| `VOX-DAT-015` | Authoritative quantitative data shall remain distinct from presentation buffers and reduced-quality render intermediates. | P0 | I,T,R | M2 |

### 6.8 Spatial model and coordinate systems

**Primary source:** Foundation §§7, 19; MTA §10

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-SPA-001` | Voxelia shall represent spatial coordinate systems explicitly. | P0 | I,T | M1 |
| `VOX-SPA-002` | The spatial model shall support index-to-physical affine geometry for regular images and volumes. | P0 | I,T | M1 |
| `VOX-SPA-003` | Authoritative spatial transforms and measurements shall use double precision. | P0 | I,T,A | M1 |
| `VOX-SPA-004` | Voxelia shall permit rendering-specific float transforms only after the associated error bounds are verified. | P0 | A,T | M3 |
| `VOX-SPA-005` | Coordinate-space identifiers shall distinguish index, voxel, image, patient, world, display and application-defined spaces where applicable. | P0 | I,T | M1 |
| `VOX-SPA-006` | DICOM patient coordinates shall be supported as a canonical clinical spatial convention through the DICOMKit adapter. | P0 | T | M4 |
| `VOX-SPA-007` | Coordinate-convention conversion shall be explicit and shall not rely on undocumented axis flipping. | P0 | I,T | M1 |
| `VOX-SPA-008` | Affine transforms shall support composition, inversion and point, vector and normal transformation. | P0 | T | M1 |
| `VOX-SPA-009` | Singular or non-invertible transforms shall produce typed errors. | P0 | T | M1 |
| `VOX-SPA-010` | Spatial bounds shall be computable in index and physical coordinates. | P0 | T | M1 |
| `VOX-SPA-011` | The spatial model shall represent planes, rays, oriented bounds and intersections required by rendering and interaction. | P0 | I,T | M1 |
| `VOX-SPA-012` | The architecture shall permit rectilinear geometry and irregular frame-set geometry without forcing them into a false regular affine volume. | P1 | I,T | M7 |
| `VOX-SPA-013` | Frame-of-reference identities shall be preserved through transformations and derived data. | P0 | T | M4 |
| `VOX-SPA-014` | Distance, angle, area and volume measurements shall be evaluated in the appropriate physical coordinate space. | P0 | T,A | M4 |

### 6.9 Regions, views and data identity

**Primary source:** MTA §11

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-RGN-001` | Voxelia shall represent N-dimensional regions using origins and extents. | P0 | I,T | M1 |
| `VOX-RGN-002` | Region construction shall validate rank compatibility, bounds and overflow. | P0 | T | M1 |
| `VOX-RGN-003` | Storage implementations shall support region reads where their capabilities permit. | P0 | I,T | M1 |
| `VOX-RGN-004` | Voxelia shall support zero-copy or copy-avoiding views when the source storage layout permits them. | P1 | T,A | M1 |
| `VOX-RGN-005` | A view shall preserve or derive correct spatial geometry for the selected region, slice, component or temporal frame. | P0 | T | M1 |
| `VOX-RGN-006` | Views shall not mutate their source data unless the storage contract explicitly permits controlled mutable access. | P0 | I,T | M1 |
| `VOX-RGN-007` | Every immutable data object shall have a stable content or derivation identity suitable for caching and provenance. | P0 | I,T | M2 |
| `VOX-RGN-008` | Content identity generation shall include data bytes or trusted source identity, descriptor semantics and relevant transform metadata. | P0 | A,T | M2 |
| `VOX-RGN-009` | Identity algorithms shall detect accidental mismatch through checksums or equivalent integrity mechanisms. | P1 | T | M5 |

### 6.10 Metadata and provenance

**Primary source:** Foundation §§7, 19, 27; MTA §12

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-META-001` | Voxelia shall distinguish structured core metadata from format-specific metadata. | P0 | I,T | M1 |
| `VOX-META-002` | Format-specific metadata shall be preserved through adapters without contaminating the core type system. | P0 | I,T | M4 |
| `VOX-META-003` | Derived data shall carry provenance linking it to source identities. | P0 | T | M2 |
| `VOX-META-004` | Operation provenance shall record operation identifier, semantic version, implementation identifier and implementation version. | P0 | T | M2 |
| `VOX-META-005` | Operation provenance shall record parameters that affect output. | P0 | T | M2 |
| `VOX-META-006` | Operation provenance shall record backend, quality profile and precision policy. | P0 | T | M2 |
| `VOX-META-007` | Metal-derived output provenance shall record shader or compiled-library identity where applicable. | P0 | T | M3 |
| `VOX-META-008` | Render provenance shall record scene identity, camera, viewport, transfer functions, quality settings and renderer version. | P0 | T | M3 |
| `VOX-META-009` | Photorealistic Rendering provenance shall record random seed, sample budget or convergence criterion, accumulation state and denoising use. | P0 | T | M8 |
| `VOX-META-010` | Provenance records shall be serialisable for validation, audit and distributed execution. | P0 | T | M9 |
| `VOX-META-011` | Provenance generation shall not include patient-identifying metadata unless the host application explicitly supplies and permits it. | P0 | I,T | M4 |

### 6.11 Geometry model

**Primary source:** Foundation §8; MTA §13, §28

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-GEO-001` | Voxelia shall provide canonical point-set, line, polyline, curve, triangle-mesh and polygon-mesh representations. | P0 | I,T | M1 |
| `VOX-GEO-002` | Geometry positions shall declare their coordinate space. | P0 | I,T | M1 |
| `VOX-GEO-003` | Mesh topology and vertex attributes shall be represented independently. | P0 | I,T | M1 |
| `VOX-GEO-004` | Geometry attributes shall support normals, colours, scalar fields, labels and texture coordinates where applicable. | P1 | I,T | M6 |
| `VOX-GEO-005` | Index buffers shall validate bounds before use. | P0 | T | M1 |
| `VOX-GEO-006` | Geometry operations shall preserve or explicitly update coordinate-space and provenance information. | P0 | T | M6 |
| `VOX-GEO-007` | Voxelia shall define surface extraction operations for labelled and scalar volume data. | P0 | I,T | M6 |
| `VOX-GEO-008` | The initial surface extraction capability shall include a validated marching-cubes-class algorithm. | P0 | T | M6 |
| `VOX-GEO-009` | Surface normal generation shall provide deterministic reference behaviour. | P0 | T | M6 |
| `VOX-GEO-010` | Geometry measurement shall use authoritative geometry rather than rasterised presentation output. | P0 | T | M6 |
| `VOX-GEO-011` | The geometry architecture shall permit acceleration structures without making a particular Metal or RealityKit structure canonical. | P1 | I,R | M6 |

### 6.12 Segmentation model and operations

**Primary source:** Foundation §8; MTA §14

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-SEG-001` | Voxelia shall represent binary masks and multi-segment datasets. | P0 | I,T | M7 |
| `VOX-SEG-002` | The segmentation model shall support overlapping segments without forcing all segments into one mutually exclusive label value. | P0 | I,T | M7 |
| `VOX-SEG-003` | Segment descriptors shall support stable segment identifiers, labels, colours and algorithm provenance. | P0 | I,T | M7 |
| `VOX-SEG-004` | Segmentation geometry shall declare its relationship to source image geometry and frame of reference. | P0 | I,T | M7 |
| `VOX-SEG-005` | Binary and multi-label resampling shall default to nearest-neighbour interpolation unless explicitly overridden by a validated operation. | P0 | T | M7 |
| `VOX-SEG-006` | Voxelia shall provide thresholding, masking, connected-component and morphology foundations. | P0 | T | M7 |
| `VOX-SEG-007` | Region-growing operations shall record seeds, thresholds, connectivity and implementation version. | P1 | T | M7 |
| `VOX-SEG-008` | Segmentation editing operations shall be explicit, undoable by the host where operation history is retained, and provenance-producing. | P1 | I,T | M7 |
| `VOX-SEG-009` | Segmentation statistics shall be computed from authoritative image and segment data. | P0 | T | M7 |
| `VOX-SEG-010` | AI inference shall be integrated through optional adapters and shall not be embedded into the foundational segmentation model. | P0 | I,R | M7 |

### 6.13 Registration model and operations

**Primary source:** Foundation §8; MTA §14

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-REG-001` | Voxelia shall represent rigid, affine and deformable transforms as distinct transform categories. | P0 | I,T | M7 |
| `VOX-REG-002` | Registration results shall identify fixed data, moving data, metric, optimiser, multi-resolution schedule and convergence status. | P0 | T | M7 |
| `VOX-REG-003` | Registration transforms shall identify their source and destination coordinate spaces. | P0 | I,T | M7 |
| `VOX-REG-004` | Transform composition shall validate coordinate-space compatibility. | P0 | T | M7 |
| `VOX-REG-005` | The initial registration portfolio shall include landmark, rigid and affine registration. | P0 | T | M7 |
| `VOX-REG-006` | The registration architecture shall support multi-resolution image pyramids. | P0 | I,T | M7 |
| `VOX-REG-007` | The architecture shall support mean-square and mutual-information-class metrics. | P1 | I,T | M7 |
| `VOX-REG-008` | Registration failure or non-convergence shall be reported explicitly and shall not be presented as a successful transform. | P0 | T | M7 |
| `VOX-REG-009` | Registration quality metrics shall be available to the host application. | P1 | T | M7 |
| `VOX-REG-010` | Reference registration implementations shall be available before Metal acceleration is accepted into a diagnostic profile. | P0 | T,R | M7 |

### 6.14 Storage abstractions and integrity

**Primary source:** Foundation §§12, 14; MTA §§15–16

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-STO-001` | The canonical image model shall be independent of physical storage representation. | P0 | I,T | M1 |
| `VOX-STO-002` | Voxelia shall define a storage capability contract covering readable regions, mutability, mapping, locality, compression and residency characteristics. | P0 | I,T | M1 |
| `VOX-STO-003` | The initial storage implementations shall include contiguous in-memory storage. | P0 | T | M1 |
| `VOX-STO-004` | The initial storage implementations shall include memory-mapped storage. | P0 | T | M1 |
| `VOX-STO-005` | Voxelia shall support tiled or bricked storage for large images and volumes. | P0 | T | M5 |
| `VOX-STO-006` | Voxelia shall support callback-backed or remote-backed storage through an asynchronous region or brick provider. | P1 | I,T | M9 |
| `VOX-STO-007` | Storage reads shall validate requested regions against descriptor bounds. | P0 | T | M1 |
| `VOX-STO-008` | Storage allocations shall detect integer overflow and unreasonable size requests before allocation. | P0 | T,A | M1 |
| `VOX-STO-009` | Storage implementations shall expose integrity checks where source checksums are available. | P1 | T | M5 |
| `VOX-STO-010` | Mutable storage, where provided, shall define exclusivity and concurrency semantics explicitly. | P0 | I,T | M1 |
| `VOX-STO-011` | Storage views shall preserve lifetime ownership of their backing storage. | P0 | T | M1 |
| `VOX-STO-012` | The storage layer shall allow independent eviction of compressed data, decoded bricks and GPU-resident resources. | P0 | T,A | M5 |

### 6.15 Bricked and multi-resolution volume storage

**Primary source:** Foundation §14; MTA §16

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-BRK-001` | Large volumes shall be processable without requiring one complete three-dimensional texture to be resident. | P0 | T,D | M5 |
| `VOX-BRK-002` | A bricked volume shall identify brick coordinates, voxel regions, overlap or halo, resolution level and data identity. | P0 | I,T | M5 |
| `VOX-BRK-003` | Brick dimensions shall be selected through capability and workload policy rather than hard-coded into the public data model. | P0 | I,A,T | M5 |
| `VOX-BRK-004` | The storage system shall support boundary bricks whose extents differ from nominal brick size. | P0 | T | M5 |
| `VOX-BRK-005` | Multi-resolution representations shall preserve the spatial relationship between levels. | P0 | T | M5 |
| `VOX-BRK-006` | Brick requests shall be cancellable. | P0 | T | M5 |
| `VOX-BRK-007` | Concurrent requests for the same brick and representation shall be deduplicated where safe. | P1 | T | M5 |
| `VOX-BRK-008` | Brick-cache eviction shall consider recency, cost, size, visibility and active operation references. | P1 | A,T | M5 |
| `VOX-BRK-009` | Interactive rendering shall be able to use a lower-resolution level while higher-resolution bricks are loading. | P0 | T,D | M6 |
| `VOX-BRK-010` | Refinement shall not publish a brick belonging to an obsolete render or operation generation. | P0 | T | M5 |
| `VOX-BRK-011` | Per-brick statistics or occupancy metadata shall be supported for empty-space skipping and prioritisation. | P1 | I,T | M6 |

### 6.16 Compression and codec integration

**Primary source:** Foundation §§13–14; MTA §17, §31

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-CMP-001` | Voxelia shall reuse approved Raster-Lab codec libraries rather than reimplement their codecs internally. | P0 | I,R | M5 |
| `VOX-CMP-002` | Codec integration shall be isolated in `VoxeliaCompression` and format adapters. | P0 | I,T | M5 |
| `VOX-CMP-003` | Voxelia shall support original compressed sources, compressed slices, compressed slabs and compressed three-dimensional bricks. | P0 | I,T | M5 |
| `VOX-CMP-004` | Lossless JPEG 2000 Part 10 three-dimensional compression shall be evaluated as an internal volume-cache representation. | P0 | A,T | M5 |
| `VOX-CMP-005` | HTJ2K shall be evaluated for high-throughput lossless decoding and encoding. | P0 | A,T | M5 |
| `VOX-CMP-006` | JP3D and HTJ2K combinations shall be used only when the actual Raster-Lab codec output and interoperability status are documented. | P0 | I,T,R | M5 |
| `VOX-CMP-007` | Compressed data shall not be treated as directly sampleable Metal texture data. | P0 | I,T | M5 |
| `VOX-CMP-008` | The decode path shall support caller-provided or reusable destination storage where the codec API permits it. | P1 | T,A | M5 |
| `VOX-CMP-009` | Codec adapters shall support cancellation and shall not publish partial data as complete output. | P0 | T | M5 |
| `VOX-CMP-010` | Codec adapters shall validate dimensions, component formats and decoded byte counts. | P0 | T | M5 |
| `VOX-CMP-011` | Malformed or adversarial codestreams shall produce bounded failure without uncontrolled allocation or unsafe memory access. | P0 | T,A | M5 |
| `VOX-CMP-012` | Original DICOM instances shall be preserved when JP3D or other toolkit-native cache formats are generated. | P0 | T,R | M5 |
| `VOX-CMP-013` | Toolkit-native JP3D representations shall not be represented as standard DICOM transfer syntaxes. | P0 | I,T | M5 |
| `VOX-CMP-014` | Compression benchmarks shall report ratio, encode time, decode time, random-access cost, memory use and output equality. | P1 | T,A | M5 |

### 6.17 Operation and execution model

**Primary source:** Foundation §§7, 19–21; MTA §§19, 21

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-EXE-001` | Voxelia operations shall be immutable descriptions of typed transformations or render requests. | P0 | I,T | M2 |
| `VOX-EXE-002` | Each operation shall have a stable operation identifier and semantic version. | P0 | I,T | M2 |
| `VOX-EXE-003` | Each implementation shall have an implementation identifier and version distinct from operation semantics. | P0 | I,T | M2 |
| `VOX-EXE-004` | Operation identity shall include inputs, parameters, precision policy, quality profile and implementation-affecting options. | P0 | T | M2 |
| `VOX-EXE-005` | Execution shall support lazy evaluation of dependencies. | P0 | T | M2 |
| `VOX-EXE-006` | Execution shall support multiple inputs and outputs where the operation definition requires them. | P1 | I,T | M2 |
| `VOX-EXE-007` | Execution shall support cancellation propagation from a parent operation to dependent work. | P0 | T | M2 |
| `VOX-EXE-008` | Execution shall support progress reporting as an asynchronous stream or equivalent non-blocking mechanism. | P0 | T | M2 |
| `VOX-EXE-009` | Execution shall assign generations or revisions so obsolete asynchronous results cannot replace newer results. | P0 | T | M2 |
| `VOX-EXE-010` | Execution shall deduplicate identical in-flight operations where safe. | P1 | T | M2 |
| `VOX-EXE-011` | Execution shall support explicit reference, diagnostic, interactive and preview policies. | P0 | I,T | M2 |
| `VOX-EXE-012` | Reference policy shall favour deterministic and highest-assurance implementations. | P0 | T,R | M2 |
| `VOX-EXE-013` | Diagnostic policy shall select only validated implementations with documented error bounds. | P0 | T,R | M2 |
| `VOX-EXE-014` | Interactive policy may use validated adaptive quality but shall converge towards the requested final quality. | P0 | T,D | M3 |
| `VOX-EXE-015` | Preview policy shall be identifiable to the host and shall not be used for authoritative measurements. | P0 | T,D | M3 |
| `VOX-EXE-016` | Execution errors shall retain the operation and implementation context required for diagnosis. | P0 | T | M2 |

### 6.18 Concurrency and task lifecycle

**Primary source:** Foundation §28; MTA §20

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-CON-001` | Shared mutable execution state shall be isolated by actors or an equivalently safe concurrency mechanism. | P0 | I,T | M2 |
| `VOX-CON-002` | The primary execution engine shall be actor-isolated. | P0 | I,T | M2 |
| `VOX-CON-003` | Storage and data descriptors shall be safe to transfer across tasks according to their declared `Sendable` semantics. | P0 | I,T | M1 |
| `VOX-CON-004` | Metal command encoders shall remain within their valid command-buffer and pass lifetimes and shall not be returned as operation results. | P0 | I,T | M3 |
| `VOX-CON-005` | Interactive draw callbacks shall not launch overlapping unstructured work that can publish frames out of order. | P0 | T | M3 |
| `VOX-CON-006` | Long-running CPU and GPU work shall periodically observe cancellation where technically possible. | P0 | T | M2 |
| `VOX-CON-007` | Cancellation shall not corrupt caches or leave data identities pointing to incomplete results. | P0 | T | M2 |
| `VOX-CON-008` | Priority shall be propagated so interactive work can pre-empt or outrank background cache generation. | P1 | T,D | M3 |
| `VOX-CON-009` | Concurrency tests shall include race detection, cancellation storms, repeated generation changes and memory-pressure scenarios. | P0 | T | M4 |
| `VOX-CON-010` | Any use of `@unchecked Sendable` shall be documented and independently reviewed. | P0 | I,R | M1 |

### 6.19 Planning, backend selection and caching

**Primary source:** MTA §21

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-CCH-001` | The execution planner shall select an implementation based on operation support, quality policy, determinism, device capability, data locality, latency and memory cost. | P0 | A,T | M3 |
| `VOX-CCH-002` | The host shall be able to request reference, CPU-preferred, GPU-preferred or automatic backend policy without selecting a specific device generation. | P1 | I,T | M3 |
| `VOX-CCH-003` | A diagnostic request shall fail rather than silently use an unvalidated implementation. | P0 | T | M3 |
| `VOX-CCH-004` | Operation cache keys shall include operation version, implementation version, input identity, parameters, precision, backend and shader identity where applicable. | P0 | T | M2 |
| `VOX-CCH-005` | Cache entries shall not be reused across incompatible quality or precision policies. | P0 | T | M2 |
| `VOX-CCH-006` | Result caches shall support bounded memory and explicit eviction. | P0 | T,A | M2 |
| `VOX-CCH-007` | Persistent cache formats shall carry independent format versions. | P0 | I,T | M5 |
| `VOX-CCH-008` | Cache corruption shall be detected and shall not result in publication of unverified data. | P0 | T | M5 |
| `VOX-CCH-009` | Cache instrumentation shall report hit, miss, eviction, decode and recomputation events. | P1 | T,D | M5 |

### 6.20 CPU backend

**Primary source:** Foundation §§19–21; MTA §22

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-CPU-001` | Voxelia shall provide CPU reference implementations for safety-critical or diagnostic GPU operations where practical. | P0 | I,T | M2 |
| `VOX-CPU-002` | Reference implementations shall favour clarity, determinism and numerical traceability over maximum speed. | P0 | I,R,T | M2 |
| `VOX-CPU-003` | Optimised CPU implementations shall remain distinguishable from reference implementations. | P0 | I,T | M2 |
| `VOX-CPU-004` | The CPU backend shall permit Accelerate and vImage implementations only behind Voxelia operation semantics whose behaviour and precision are validated. | P1 | I,T | M2 |
| `VOX-CPU-005` | CPU reductions used for reference statistics shall be deterministic under the documented execution policy. | P0 | T | M2 |
| `VOX-CPU-006` | CPU kernels shall support cancellation at suitable partition boundaries. | P0 | T | M2 |
| `VOX-CPU-007` | CPU kernels shall validate strides, bounds, alignment assumptions and scalar formats. | P0 | T | M2 |
| `VOX-CPU-008` | CPU benchmark results shall distinguish scalar reference, SIMD-optimised and Accelerate-backed implementations. | P1 | T,A | M2 |
| `VOX-CPU-009` | A CPU-only build of backend-neutral modules shall remain possible on supported Apple platforms. | P1 | I,T | M2 |

### 6.21 Metal backend and unified memory

**Primary source:** Foundation §12; MTA §§18, 23

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-MTL-001` | Metal shall be the primary GPU compute and diagnostic rendering backend. | P0 | I,T | M3 |
| `VOX-MTL-002` | Voxelia shall create an internal device-capability model covering GPU family, memory model, sparse-resource support, ray-tracing support, texture limits and recommended concurrency. | P0 | I,T | M3 |
| `VOX-MTL-003` | The public API shall not expose capability checks that require callers to understand Metal family numbering. | P0 | I,T | M3 |
| `VOX-MTL-004` | The Metal backend shall own command queues, command buffers, encoders, events and in-flight resources. | P0 | I,T | M3 |
| `VOX-MTL-005` | Shader libraries and pipeline states shall be cached by stable shader and configuration identities. | P0 | T | M3 |
| `VOX-MTL-006` | The backend shall support reusable frame contexts and bounded in-flight frame counts. | P0 | T | M3 |
| `VOX-MTL-007` | The backend shall support shared CPU/GPU resources when this reduces copies without unacceptable sampling cost. | P0 | A,T | M3 |
| `VOX-MTL-008` | The backend shall support private GPU resources for repeatedly sampled or rendered data when justified by measured performance. | P0 | A,T | M3 |
| `VOX-MTL-009` | The backend shall minimise full-volume CPU-to-GPU duplication. | P0 | A,T,D | M4 |
| `VOX-MTL-010` | The backend shall support reusable staging and decode destination buffers. | P1 | T,A | M5 |
| `VOX-MTL-011` | Metal heaps shall be used where they provide measurable allocation or residency benefit. | P1 | A,T | M5 |
| `VOX-MTL-012` | Sparse resources shall be capability-gated and shall have a bricked fallback. | P0 | I,T | M5 |
| `VOX-MTL-013` | GPU resource residency shall respond to memory pressure and active workload priority. | P0 | T,D | M5 |
| `VOX-MTL-014` | GPU completion errors and device failures shall be surfaced as typed Voxelia errors. | P0 | T | M3 |
| `VOX-MTL-015` | The Metal backend shall record kernel time, command-buffer latency, upload time, frame time and residency changes. | P1 | T,D | M3 |
| `VOX-MTL-016` | Every diagnostic Metal kernel shall have an analytical oracle, CPU reference or approved independent reference. | P0 | T,R | M3 |

### 6.22 Image-processing operations

**Primary source:** Foundation §8; MTA §9, §22, §25–26

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-IMG-001` | Voxelia shall provide explicit scalar conversion operations with defined rounding, clipping and overflow behaviour. | P0 | T | M2 |
| `VOX-IMG-002` | Voxelia shall provide modality or value transformation operations independent of display windowing. | P0 | T | M2 |
| `VOX-IMG-003` | Voxelia shall provide nearest-neighbour interpolation. | P0 | T | M2 |
| `VOX-IMG-004` | Voxelia shall provide linear interpolation for supported scalar and component formats. | P0 | T | M2 |
| `VOX-IMG-005` | Voxelia should provide cubic interpolation with documented kernel and boundary behaviour. | P1 | T | M6 |
| `VOX-IMG-006` | Interpolation operations shall define boundary handling explicitly. | P0 | I,T | M2 |
| `VOX-IMG-007` | Label maps and masks shall use nearest-neighbour interpolation by default. | P0 | T | M7 |
| `VOX-IMG-008` | Voxelia shall provide image resampling between explicit source and destination geometries. | P0 | T | M2 |
| `VOX-IMG-009` | Voxelia shall provide histogram calculation with documented binning, range and treatment of invalid or padded values. | P0 | T | M2 |
| `VOX-IMG-010` | Voxelia shall provide threshold, mask and image-arithmetic foundations. | P0 | T | M7 |
| `VOX-IMG-011` | Voxelia shall provide convolution and Gaussian-filter foundations with explicit boundary conditions. | P1 | T | M7 |
| `VOX-IMG-012` | Voxelia shall provide morphology foundations including erosion and dilation. | P0 | T | M7 |
| `VOX-IMG-013` | Voxelia shall provide connected-component analysis. | P0 | T | M7 |
| `VOX-IMG-014` | Voxelia should provide distance transforms. | P1 | T | M7 |
| `VOX-IMG-015` | Quantitative operations shall exclude presentation-only approximations from authoritative results. | P0 | T,R | M2 |

### 6.23 Diagnostic two-dimensional presentation

**Primary source:** Foundation §15; MTA §25

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-R2D-001` | Voxelia shall provide a canonical diagnostic two-dimensional presentation pipeline. | P0 | I,T | M3 |
| `VOX-R2D-002` | The pipeline shall preserve stored values separately from modality-transformed and displayed values. | P0 | T | M3 |
| `VOX-R2D-003` | The pipeline shall support signed and unsigned integer input values required by supported modalities. | P0 | T | M4 |
| `VOX-R2D-004` | The pipeline shall support floating-point input where the descriptor and operation permit it. | P1 | T | M7 |
| `VOX-R2D-005` | The pipeline shall support MONOCHROME1 and MONOCHROME2 presentation semantics. | P0 | T | M4 |
| `VOX-R2D-006` | The pipeline shall support linear window centre and width behaviour with defined edge cases. | P0 | T | M4 |
| `VOX-R2D-007` | The pipeline shall support VOI LUT application. | P1 | T | M6 |
| `VOX-R2D-008` | The pipeline shall support presentation inversion independently of source-value transformation. | P0 | T | M4 |
| `VOX-R2D-009` | The pipeline shall support pixel-padding exclusion where supplied by the source adapter. | P0 | T | M4 |
| `VOX-R2D-010` | The pipeline shall support palette-colour and RGB presentation through explicit colour transforms. | P1 | T | M6 |
| `VOX-R2D-011` | The pipeline shall support segmentation, mask and image overlays with defined alpha-compositing semantics. | P0 | T | M6 |
| `VOX-R2D-012` | The pipeline shall preserve quantitative pixel inspection before display transformations. | P0 | T,D | M4 |
| `VOX-R2D-013` | The pipeline shall support explicit nearest-neighbour, linear and no-interpolation display policies where applicable. | P0 | T | M4 |
| `VOX-R2D-014` | Off-screen and interactive output shall use the same presentation semantics. | P0 | T | M4 |
| `VOX-R2D-015` | Display colour transformation and output colour space shall be explicit in render requests and provenance. | P1 | I,T | M6 |

### 6.24 Multiplanar, projection and curved reconstruction

**Primary source:** Foundation §15; MTA §26

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-MPR-001` | Voxelia shall support axial, coronal and sagittal reconstruction from regular volumes. | P0 | T,D | M4 |
| `VOX-MPR-002` | Voxelia shall support arbitrary oblique reconstruction. | P0 | T,D | M6 |
| `VOX-MPR-003` | MPR shall use physical spacing and orientation rather than assuming isotropic or axis-aligned input. | P0 | T | M4 |
| `VOX-MPR-004` | MPR output geometry shall be explicit and reproducible. | P0 | I,T | M4 |
| `VOX-MPR-005` | Voxelia shall support linked orthogonal views with a shared patient-space crosshair. | P0 | T,D | M4 |
| `VOX-MPR-006` | Voxelia shall support single-slice and thick-slab reconstruction. | P0 | T | M6 |
| `VOX-MPR-007` | Voxelia shall support maximum-intensity projection. | P0 | T | M6 |
| `VOX-MPR-008` | Voxelia shall support minimum-intensity projection. | P0 | T | M6 |
| `VOX-MPR-009` | Voxelia shall support average-intensity projection. | P0 | T | M6 |
| `VOX-MPR-010` | Projection operations shall define treatment of padding, missing samples and out-of-bounds regions. | P0 | I,T | M6 |
| `VOX-MPR-011` | Voxelia shall support multi-volume fusion for spatially registered inputs. | P1 | T,D | M6 |
| `VOX-MPR-012` | Curved planar reconstruction shall accept an explicit centreline in physical coordinates. | P1 | I,T | M7 |
| `VOX-MPR-013` | Curved planar reconstruction shall map output positions back to source patient coordinates. | P1 | T | M7 |
| `VOX-MPR-014` | Measurements made in reconstructed views shall use authoritative physical geometry. | P0 | T | M4 |

### 6.25 Conventional volume rendering

**Primary source:** Foundation §15; MTA §27

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-DVR-001` | Voxelia shall provide conventional direct volume rendering. | P0 | T,D | M6 |
| `VOX-DVR-002` | The volume renderer shall intersect view rays with the actual volume bounds. | P0 | T | M6 |
| `VOX-DVR-003` | Sampling intervals shall derive from physical spacing, quality policy and view geometry rather than a fixed normalised constant. | P0 | A,T | M6 |
| `VOX-DVR-004` | The renderer shall support front-to-back compositing with early ray termination. | P0 | T | M6 |
| `VOX-DVR-005` | The renderer shall support one-dimensional transfer functions. | P0 | T,D | M6 |
| `VOX-DVR-006` | The renderer should support multi-dimensional transfer functions using intensity, gradient or material information. | P1 | T,D | M8 |
| `VOX-DVR-007` | Transfer-function indexing shall be clamped and shall define out-of-range behaviour. | P0 | T | M6 |
| `VOX-DVR-008` | The renderer shall support gradient estimation and lighting. | P0 | T,D | M6 |
| `VOX-DVR-009` | The renderer shall support clipping planes and cropping regions. | P0 | T,D | M6 |
| `VOX-DVR-010` | The renderer shall support segmentation masks and multi-volume compositing. | P1 | T,D | M6 |
| `VOX-DVR-011` | The renderer shall support bricked and multi-resolution volumes. | P0 | T,D | M6 |
| `VOX-DVR-012` | The renderer shall support empty-space skipping or an equivalent acceleration path where occupancy metadata is available. | P1 | T,A | M6 |
| `VOX-DVR-013` | Interactive quality shall refine towards requested diagnostic quality after interaction stops. | P0 | T,D | M6 |
| `VOX-DVR-014` | The renderer shall support deterministic off-screen rendering for a fixed scene, implementation and quality profile within declared tolerances. | P0 | T | M6 |
| `VOX-DVR-015` | Volume-rendered pixels shall not be used as the source of authoritative quantitative measurements. | P0 | T,R | M6 |

### 6.26 Photorealistic Rendering

**Primary source:** Foundation §16; MTA §29

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-PRR-001` | Photorealistic Rendering shall be delivered as an optional module. | P0 | I,T | M8 |
| `VOX-PRR-002` | Applications shall be able to disable Photorealistic Rendering without disabling conventional diagnostic rendering. | P0 | T,D | M8 |
| `VOX-PRR-003` | The module shall support interactive, progressive and reference quality modes. | P0 | I,T | M8 |
| `VOX-PRR-004` | The module shall support physically based volumetric illumination. | P0 | T,D | M8 |
| `VOX-PRR-005` | The module shall support volumetric shadows. | P0 | T,D | M8 |
| `VOX-PRR-006` | The module shall support area and environment lighting. | P1 | T,D | M8 |
| `VOX-PRR-007` | The progressive and reference modes shall support multiple-scattering or an explicitly documented physically based approximation. | P1 | A,T,D | M8 |
| `VOX-PRR-008` | The module shall support transparency and transillumination presentations. | P0 | T,D | M8 |
| `VOX-PRR-009` | The module should support material-separated presentation for clinically significant material classes. | P1 | T,D | M8 |
| `VOX-PRR-010` | The reference mode shall support deterministic random seeds. | P0 | T | M8 |
| `VOX-PRR-011` | The progressive mode shall expose convergence or variance information. | P1 | T,D | M8 |
| `VOX-PRR-012` | Temporal accumulation shall be reset or reprojected safely when scene, camera, transfer function or source data changes. | P0 | T | M8 |
| `VOX-PRR-013` | Denoising shall be explicit, versioned and recorded in provenance. | P0 | T | M8 |
| `VOX-PRR-014` | Generative reconstruction shall not be applied implicitly to Photorealistic Rendering output. | P0 | I,T,R | M8 |
| `VOX-PRR-015` | The module shall support side-by-side comparison with conventional rendering using the same authoritative scene state. | P0 | T,D | M8 |
| `VOX-PRR-016` | The module shall support partitioning by tile or sample range for distributed accumulation. | P0 | T,D | M9 |
| `VOX-PRR-017` | Photorealistic presets shall be tested for preservation of specified thin structures and high-value intensity ranges. | P0 | T,R | M8 |

### 6.27 Surface and geometry rendering

**Primary source:** MTA §28

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-SUR-001` | Voxelia shall render triangle meshes with explicit coordinate-space transforms. | P0 | T,D | M6 |
| `VOX-SUR-002` | Surface rendering shall support depth testing and hidden-surface removal. | P0 | T,D | M6 |
| `VOX-SUR-003` | Surface rendering shall support per-object opacity. | P0 | T,D | M6 |
| `VOX-SUR-004` | Surface rendering shall support vertex normals and physically based or validated diagnostic materials. | P1 | T,D | M6 |
| `VOX-SUR-005` | Surface rendering shall support scalar colour maps where geometry carries scalar attributes. | P1 | T,D | M6 |
| `VOX-SUR-006` | Surface rendering shall support clipping and section views. | P0 | T,D | M6 |
| `VOX-SUR-007` | Surface picking shall return authoritative geometry identifiers and physical coordinates. | P0 | T | M6 |
| `VOX-SUR-008` | Depth-aware annotations shall remain correctly registered during camera movement. | P1 | T,D | M6 |
| `VOX-SUR-009` | Geometry generated by Metal compute shall be representable without making GPU buffers the canonical geometry model. | P1 | I,T | M6 |

### 6.28 Interaction and viewport synchronisation

**Primary source:** Foundation §15; MTA §30

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-INT-001` | Interaction state shall be independent of SwiftUI, AppKit, UIKit and RealityKit event types. | P0 | I,T | M4 |
| `VOX-INT-002` | Voxelia shall define commands for window and level, pan, zoom, scroll, rotate, crosshair, picking, clipping, cropping and measurement construction. | P0 | I,T | M4 |
| `VOX-INT-003` | Camera state shall be serialisable or snapshot-able for off-screen and distributed rendering. | P0 | I,T | M9 |
| `VOX-INT-004` | Crosshair state shall be represented in a shared physical coordinate space. | P0 | T | M4 |
| `VOX-INT-005` | Viewport synchronisation shall validate frame-of-reference compatibility. | P0 | T | M4 |
| `VOX-INT-006` | Picking shall identify the rendered layer, source data and physical position. | P0 | T | M4 |
| `VOX-INT-007` | Interaction updates shall increment render generations so stale frames are not presented. | P0 | T | M4 |
| `VOX-INT-008` | Interactive manipulation shall remain responsive while background processing continues. | P0 | T,D | M4 |
| `VOX-INT-009` | Measurement construction shall preserve the original input points and derived physical result. | P0 | T | M4 |
| `VOX-INT-010` | Host applications shall be able to define input mappings without modifying Voxelia interaction semantics. | P1 | I,D | M4 |

### 6.29 DICOMKit integration

**Primary source:** Foundation §13; MTA §31, §44

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-DCM-001` | Voxelia shall use DICOMKit rather than implementing a second general DICOM parser. | P0 | I,R | M4 |
| `VOX-DCM-002` | DICOMKit integration shall be provided by an optional `VoxeliaDICOMKit` module. | P0 | I,T | M4 |
| `VOX-DCM-003` | The adapter shall translate DICOMKit output into canonical Voxelia data, spatial, metadata and provenance types. | P0 | T | M4 |
| `VOX-DCM-004` | The adapter shall assemble regular image series using spatial position and orientation rather than filename or instance number alone. | P0 | T | M4 |
| `VOX-DCM-005` | The adapter shall support signed and unsigned 16-bit CT samples for the first vertical slice. | P0 | T | M4 |
| `VOX-DCM-006` | The adapter shall preserve rescale slope and intercept as explicit value-transformation metadata or operations. | P0 | T | M4 |
| `VOX-DCM-007` | The adapter shall preserve Image Position, Image Orientation, Pixel Spacing and frame-of-reference information. | P0 | T | M4 |
| `VOX-DCM-008` | The adapter shall preserve MONOCHROME1, MONOCHROME2 and pixel-padding presentation information required by the first vertical slice. | P0 | T | M4 |
| `VOX-DCM-009` | The adapter shall detect missing, duplicated, irregular or contradictory geometry and shall not silently coerce it into a regular volume. | P0 | T | M4 |
| `VOX-DCM-010` | The adapter shall preserve source SOP Instance and frame provenance. | P0 | T | M4 |
| `VOX-DCM-011` | Enhanced multi-frame and irregular frame-set support shall be introduced through explicit geometry models rather than hidden regularisation. | P1 | I,T | M7 |
| `VOX-DCM-012` | DICOM segmentation, parametric map, surface and registration integrations shall map to canonical Voxelia models through optional adapter capabilities. | P1 | I,T | M7 |
| `VOX-DCM-013` | DICOM parsing or decoding errors shall retain source-object context without logging patient-identifying content by default. | P0 | T | M4 |

### 6.30 Apple framework and interoperability adapters

**Primary source:** Foundation §§7, 15; MTA §§32, 40–42

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-ADP-001` | RealityKit integration shall be optional and shall not define the canonical scene, camera, geometry or measurement model. | P0 | I,T | M9 |
| `VOX-ADP-002` | The RealityKit adapter shall support spatial presentation of Voxelia surface and annotation data where platform capability permits. | P1 | T,D | M9 |
| `VOX-ADP-003` | Model I/O integration shall be optional and shall be used for asset interchange and mesh preparation rather than as the canonical scientific data model. | P0 | I,T | M6 |
| `VOX-ADP-004` | Core Image integration shall be optional and shall be limited to suitable two-dimensional compositing, export, thumbnail or media workflows. | P0 | I,T | M9 |
| `VOX-ADP-005` | Core Image shall not be used as the canonical N-dimensional processing engine. | P0 | I,R | M0 |
| `VOX-ADP-006` | Voxelia shall permit Metal Performance Shaders only behind validated Voxelia operations without leaking MPS types into general APIs. | P1 | I,T | M3 |
| `VOX-ADP-007` | VTK and ITK interoperability shall be optional and shall not become a core runtime dependency. | P0 | I,T | M7 |
| `VOX-ADP-008` | VTK interoperability should support exchange of image and polygonal data required for migration and validation. | P1 | T | M7 |
| `VOX-ADP-009` | ITK interoperability should support exchange of images and transforms required for algorithm comparison. | P1 | T | M7 |
| `VOX-ADP-010` | Interoperability conversions shall preserve or explicitly document spatial convention changes. | P0 | T | M7 |

### 6.31 Headless, off-screen and media output

**Primary source:** Foundation §17; MTA §33

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-HLS-001` | Voxelia shall support off-screen rendering without an application window. | P0 | T,D | M4 |
| `VOX-HLS-002` | Voxelia shall support headless rendering on Apple Silicon macOS. | P0 | T,D | M9 |
| `VOX-HLS-003` | Headless and interactive rendering shall consume the same scene and presentation descriptions. | P0 | T | M9 |
| `VOX-HLS-004` | Headless rendering shall produce raw pixel data. | P0 | T | M9 |
| `VOX-HLS-005` | Headless rendering should support `CVPixelBuffer` or an equivalent Apple media buffer through an optional adapter. | P1 | T | M9 |
| `VOX-HLS-006` | Headless rendering shall support explicit SDR or HDR output descriptors where the backend supports them. | P1 | I,T | M9 |
| `VOX-HLS-007` | Headless rendering shall support optional depth and object-identifier outputs. | P1 | T | M9 |
| `VOX-HLS-008` | Progressive renderers shall be able to publish intermediate frames with generation and convergence metadata. | P1 | T,D | M9 |
| `VOX-HLS-009` | Render requests shall be cancellable and shall not publish stale final output. | P0 | T | M9 |
| `VOX-HLS-010` | Media encoding shall be isolated from core rendering in an optional module. | P0 | I,T | M9 |
| `VOX-HLS-011` | Voxelia shall not embed an HTTP server, WebSocket server, WebRTC signalling service or browser client. | P0 | I,R | M0 |

### 6.32 Distributed execution contracts

**Primary source:** Foundation §18; MTA §34

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-DST-001` | Voxelia shall define transport-neutral serialisable descriptions for distributable operations and render jobs. | P0 | I,T | M9 |
| `VOX-DST-002` | Distributed job descriptions shall include operation or scene identity, algorithm versions, parameters and required input identities. | P0 | T | M9 |
| `VOX-DST-003` | Distributed job descriptions shall include compatibility requirements for scalar formats, geometry, quality and device capabilities. | P0 | T | M9 |
| `VOX-DST-004` | Distributed work shall support partitioning by image tile, frame range, brick set or path-tracing sample range as appropriate. | P0 | T | M9 |
| `VOX-DST-005` | Distributed work descriptions shall support deterministic random seeds where stochastic rendering is used. | P0 | T | M9 |
| `VOX-DST-006` | Partial results shall include checksums, provenance and partition identity. | P0 | T | M9 |
| `VOX-DST-007` | Merge operations shall detect missing, duplicated or incompatible partitions. | P0 | T | M9 |
| `VOX-DST-008` | Path-tracing accumulators shall be mergeable without requiring original sample ordering. | P1 | T,A | M9 |
| `VOX-DST-009` | Distributed quantitative reductions shall declare numerical and ordering semantics. | P1 | I,T | M9 |
| `VOX-DST-010` | Voxelia shall not implement worker discovery, cluster membership, node identity, enterprise scheduling or peer enrolment. | P0 | I,R | M0 |
| `VOX-DST-011` | External compute-fabric services shall be able to pre-empt and cancel Voxelia worker tasks. | P1 | T,D | M9 |
| `VOX-DST-012` | Distributed workers shall reject jobs whose algorithm, shader, format or capability requirements are incompatible. | P0 | T | M9 |

### 6.33 Extensibility and plug-in boundaries

**Primary source:** Foundation §§6–7, 25; MTA §40

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-EXT-001` | The primary extension mechanism shall be source-level Swift packages depending on public Voxelia modules. | P0 | I,D | M7 |
| `VOX-EXT-002` | Third-party modules shall be able to define operations and register implementations without modifying unrelated core modules. | P0 | I,T,D | M7 |
| `VOX-EXT-003` | Implementation registration shall declare operation ID, implementation ID, versions, supported ranks, formats, geometry, quality profiles and capability requirements. | P0 | I,T | M7 |
| `VOX-EXT-004` | Registration shall reject duplicate incompatible implementation identities. | P0 | T | M7 |
| `VOX-EXT-005` | Third-party implementations shall provide provenance metadata. | P0 | T | M7 |
| `VOX-EXT-006` | Third-party implementations shall not be selected for diagnostic policy unless explicitly approved by the host or validated distribution. | P0 | T,R | M7 |
| `VOX-EXT-007` | Runtime binary plug-ins, if introduced, shall use a versioned stable boundary rather than assuming Swift compiler ABI compatibility. | P1 | I,R | M9 |
| `VOX-EXT-008` | Runtime plug-in capability negotiation shall be explicit. | P1 | I,T | M9 |
| `VOX-EXT-009` | Untrusted runtime plug-ins should be executable out of process where the host platform permits it. | P2 | I,D | M9 |

### 6.34 Errors, diagnostics and observability

**Primary source:** Foundation §§7, 19, 21; MTA §36, §39

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-ERR-001` | Voxelia shall use typed errors for invalid data, unsupported capability, allocation failure, cancellation, backend failure, shader failure and convergence failure. | P0 | I,T | M1 |
| `VOX-ERR-002` | Errors shall identify the operation, implementation and relevant data identity where safe. | P0 | T | M2 |
| `VOX-ERR-003` | Cancellation shall be distinguishable from failure. | P0 | T | M2 |
| `VOX-ERR-004` | Unsupported diagnostic behaviour shall fail explicitly rather than silently select preview behaviour. | P0 | T | M3 |
| `VOX-ERR-005` | Warnings shall be structured and machine-readable where they may affect interpretation. | P0 | I,T | M4 |
| `VOX-ERR-006` | The host shall be able to observe cache hit, cache miss, decode time, upload time, kernel time, command-buffer latency, frame time, brick faults, memory budget and refinement progress. | P1 | T,D | M5 |
| `VOX-ERR-007` | Diagnostic logging shall be configurable and shall avoid image data and patient information by default. | P0 | T,R | M4 |
| `VOX-ERR-008` | Instrumentation shall be removable or sufficiently low overhead for production use. | P1 | A,T | M10 |
| `VOX-ERR-009` | Known limitations shall be published by operation, format and platform. | P0 | I,R | M10 |

### 6.35 Security and privacy

**Primary source:** Foundation §22; MTA §37

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-SEC-001` | All external dimensions, extents, strides, offsets and allocation sizes shall be validated before memory access or allocation. | P0 | T,A | M1 |
| `VOX-SEC-002` | Unsafe Swift code shall be minimised, documented and reviewed. | P0 | I,R | M1 |
| `VOX-SEC-003` | Codec and file-format adapters shall defend against malformed, truncated and adversarial input. | P0 | T,A | M5 |
| `VOX-SEC-004` | Voxelia shall not embed credentials or unauthenticated network services. | P0 | I,T | M0 |
| `VOX-SEC-005` | Temporary-file creation shall be explicit, documented and configurable. | P1 | I,T | M5 |
| `VOX-SEC-006` | Logs and telemetry shall exclude patient-identifying metadata by default. | P0 | T,R | M4 |
| `VOX-SEC-007` | The repository shall publish a security vulnerability reporting process. | P0 | I | M0 |
| `VOX-SEC-008` | Dependencies shall be monitored for known vulnerabilities. | P0 | I,R | M10 |
| `VOX-SEC-009` | Release artefacts shall include dependency and version information sufficient for vulnerability assessment. | P0 | I,R | M10 |
| `VOX-SEC-010` | Distributed contracts shall not assume transport security; external services shall be responsible for authentication, encryption and authorisation. | P0 | I,R | M9 |
| `VOX-SEC-011` | Untrusted workloads shall be cancellable and subject to host-defined resource limits. | P1 | T,D | M9 |

### 6.36 Verification and validation

**Primary source:** Foundation §§19–20; MTA §38, §46

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-VAL-001` | Voxelia shall maintain automated unit, kernel, operation, pipeline, integration and system-reference test levels. | P0 | I,T | M0 |
| `VOX-VAL-002` | Validation shall use analytical test cases where closed-form expected results exist. | P0 | T | M2 |
| `VOX-VAL-003` | Validation shall use synthetic phantoms for spatial, intensity and measurement verification. | P0 | T | M4 |
| `VOX-VAL-004` | Golden results shall include source, licence, generator, versions, checksums and tolerance definitions. | P0 | I,R,T | M4 |
| `VOX-VAL-005` | A golden image alone shall not be considered sufficient evidence for quantitative operations. | P0 | R | M4 |
| `VOX-VAL-006` | Diagnostic Metal kernels shall be compared against analytical, CPU or approved independent references. | P0 | T,R | M3 |
| `VOX-VAL-007` | Validation shall distinguish exact byte equality, exact numeric equality, bounded numeric equality, spatial tolerance, topology equivalence, perceptual similarity and statistical equivalence. | P0 | I,R | M2 |
| `VOX-VAL-008` | Validation shall include cross-device testing by capability class. | P0 | T | M9 |
| `VOX-VAL-009` | The cross-device matrix shall include representative mobile, tablet, spatial-computing, workstation and high-memory worker classes. | P1 | T | M9 |
| `VOX-VAL-010` | Validation reports shall identify source and compiled shader fingerprints for GPU-tested behaviour. | P0 | I,R | M3 |
| `VOX-VAL-011` | Validation shall cover cancellation, stale-result rejection, memory pressure and fault injection. | P0 | T | M4 |
| `VOX-VAL-012` | DICOM-derived spatial geometry shall be validated with known datasets and phantoms. | P0 | T | M4 |
| `VOX-VAL-013` | Compression validation shall include lossless equality and random-access correctness. | P0 | T | M5 |
| `VOX-VAL-014` | Registration validation shall include transform accuracy, convergence and failure cases. | P0 | T | M7 |
| `VOX-VAL-015` | Photorealistic Rendering validation shall include statistical convergence, reproducibility and diagnostic-feature preservation. | P0 | T,R | M8 |
| `VOX-VAL-016` | Validation evidence shall be versioned and traceable to requirements, implementations and releases. | P0 | I,R | M10 |

### 6.37 Performance, memory and responsiveness

**Primary source:** Foundation §§6, 12, 21; MTA §39

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-PER-001` | Performance requirements shall be evaluated only on output that has passed the applicable correctness validation. | P0 | R,T | M2 |
| `VOX-PER-002` | Routine two-dimensional scrolling and windowing should sustain the active display refresh rate on the reference workstation hardware. | P1 | T,D | M4 |
| `VOX-PER-003` | Common MPR interaction shall target 60 frames per second on reference workstation hardware. | P1 | T,D | M4 |
| `VOX-PER-004` | Conventional 512³ volume rendering shall target 30–60 frames per second depending on quality profile and reference hardware capability. | P1 | T,D | M6 |
| `VOX-PER-005` | Crosshair, camera and windowing interaction shall target visible response within 50 milliseconds on reference workstation hardware. | P1 | T,D | M4 |
| `VOX-PER-006` | The first useful image shall be available before full study cache generation completes. | P0 | T,D | M4 |
| `VOX-PER-007` | Cancellation shall prevent publication of stale output and should stop or supersede work promptly. | P0 | T | M4 |
| `VOX-PER-008` | Steady-state execution of the first vertical slice shall not retain an unnecessary complete CPU-to-GPU duplicate of the source volume. | P0 | A,T | M4 |
| `VOX-PER-009` | Large-volume tests shall demonstrate bounded decoded-brick and GPU-residency working sets. | P0 | T,A | M5 |
| `VOX-PER-010` | Benchmark reports shall include cold-start, warm-cache, steady-state, memory-pressure, cancellation, contention, headless-batch and distributed modes as applicable. | P0 | T,A | M10 |
| `VOX-PER-011` | Benchmarks shall record hardware, operating system, compiler, Voxelia version, operation version, shader identity, dataset, storage form, cache state, quality, latency, throughput, memory and validation status. | P0 | I,T | M10 |
| `VOX-PER-012` | Performance regressions beyond approved thresholds shall fail continuous integration or require explicit review. | P1 | T,R | M10 |
| `VOX-PER-013` | Energy use should be measured for representative sustained mobile and workstation workloads where practical. | P2 | A,T | M9 |

### 6.38 Documentation and traceability

**Primary source:** Foundation §27; MTA §§2, 38, 49

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-DOC-001` | Project documentation shall be stored with source and version controlled. | P0 | I | M0 |
| `VOX-DOC-002` | Project documentation shall use Markdown and DocC as the primary formats. | P0 | I | M0 |
| `VOX-DOC-003` | Project documentation shall use British English except where external standards or programming identifiers require otherwise. | P0 | I,R | M0 |
| `VOX-DOC-004` | Every public module shall have an overview describing purpose, dependencies, supported platforms and diagnostic status. | P0 | I | M10 |
| `VOX-DOC-005` | Every public API shall have DocC documentation sufficient for safe integration. | P0 | I,R | M10 |
| `VOX-DOC-006` | Every algorithm shall have a specification describing inputs, outputs, parameters, supported formats, numerical behaviour, boundary behaviour and validation. | P0 | I,R | M10 |
| `VOX-DOC-007` | Every Metal kernel family shall have a shader specification and version identity. | P0 | I,R | M3 |
| `VOX-DOC-008` | Requirements shall be traceable to architecture, implementation, tests, validation evidence and releases. | P0 | I,R | M10 |
| `VOX-DOC-009` | Architecture deviations shall be linked to approved ADRs. | P0 | I,R | M0 |
| `VOX-DOC-010` | Known limitations and unsupported cases shall be documented. | P0 | I,R | M10 |
| `VOX-DOC-011` | Examples shall not bypass canonical validation or safety semantics for convenience. | P0 | I,R | M4 |
| `VOX-DOC-012` | Release notes shall identify diagnostic-output-affecting changes explicitly. | P0 | I,R | M10 |

### 6.39 Versioning, release and compatibility

**Primary source:** Foundation §§29–30, 33; MTA §7, §48

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-REL-001` | Voxelia shall use Semantic Versioning. | P0 | I | M0 |
| `VOX-REL-002` | During 0.x development, breaking public API changes shall be documented. | P0 | I | M0 |
| `VOX-REL-003` | After 1.0, deprecation shall precede removal of public API except for urgent security or correctness reasons. | P0 | I,R | M10 |
| `VOX-REL-004` | Diagnostic-output-affecting behavioural changes shall require release notes and updated validation evidence. | P0 | I,R | M10 |
| `VOX-REL-005` | Serialised job, cache and provenance formats shall carry independent format versions. | P0 | I,T | M9 |
| `VOX-REL-006` | Stable releases shall publish a supported-platform matrix. | P0 | I,R | M10 |
| `VOX-REL-007` | Stable releases shall publish test, benchmark and validation status. | P0 | I,R | M10 |
| `VOX-REL-008` | Stable releases shall publish known limitations and dependency inventory. | P0 | I,R | M10 |
| `VOX-REL-009` | Release artefacts should be reproducible where practical and shall record the toolchain used. | P1 | I,R | M10 |
| `VOX-REL-010` | Source-package compatibility shall be prioritised before a Voxelia-specific binary ABI commitment is made. | P0 | I,R | M10 |

### 6.40 First DICOM CT vertical slice

**Primary source:** MTA §44–46

| ID | Requirement | Priority | Verification | Target |
|---|---|:---:|:---:|:---:|
| `VOX-VS1-001` | The first vertical slice shall ingest a supported CT series through DICOMKit. | P0 | T,D | M4 |
| `VOX-VS1-002` | The first vertical slice shall assemble frames using spatial metadata. | P0 | T | M4 |
| `VOX-VS1-003` | The first vertical slice shall reject or clearly warn on irregular geometry that it cannot represent correctly. | P0 | T | M4 |
| `VOX-VS1-004` | The first vertical slice shall create a Voxelia affine volume with patient-space geometry. | P0 | T | M4 |
| `VOX-VS1-005` | The first vertical slice shall support signed and unsigned 16-bit samples. | P0 | T | M4 |
| `VOX-VS1-006` | The first vertical slice shall apply rescale slope and intercept correctly. | P0 | T | M4 |
| `VOX-VS1-007` | The first vertical slice shall support MONOCHROME1 and MONOCHROME2. | P0 | T | M4 |
| `VOX-VS1-008` | The first vertical slice shall handle pixel padding where present. | P0 | T | M4 |
| `VOX-VS1-009` | The first vertical slice shall provide CPU reference axial, coronal and sagittal reconstruction. | P0 | T | M4 |
| `VOX-VS1-010` | The first vertical slice shall provide Metal axial, coronal and sagittal rendering. | P0 | T,D | M4 |
| `VOX-VS1-011` | The first vertical slice shall provide nearest-neighbour and linear interpolation. | P0 | T | M4 |
| `VOX-VS1-012` | The first vertical slice shall provide window centre and width interaction. | P0 | T,D | M4 |
| `VOX-VS1-013` | The first vertical slice shall provide linked patient-space crosshairs. | P0 | T,D | M4 |
| `VOX-VS1-014` | The first vertical slice shall provide quantitative pixel inspection. | P0 | T,D | M4 |
| `VOX-VS1-015` | The first vertical slice shall provide patient-space distance measurement. | P0 | T,D | M4 |
| `VOX-VS1-016` | The first vertical slice shall provide off-screen output using the same presentation semantics as the interactive viewport. | P0 | T | M4 |
| `VOX-VS1-017` | The first vertical slice shall demonstrate that cancellation prevents stale result publication. | P0 | T | M4 |
| `VOX-VS1-018` | The first vertical slice shall demonstrate no unnecessary full-volume CPU-to-GPU duplicate after steady state. | P0 | A,T | M4 |
| `VOX-VS1-019` | The first vertical slice shall record provenance for source frames, transforms, operations, implementations and backend. | P0 | T | M4 |
| `VOX-VS1-020` | The first vertical slice shall compile and pass tests under Swift 6 strict concurrency on macOS 15. | P0 | T | M4 |
| `VOX-VS1-021` | The first vertical slice shall produce a validation and benchmark report. | P0 | I,R,T | M4 |

---

## 7. Requirement allocation principles

### 7.1 Core versus optional allocation

A requirement allocated to an optional module remains normative for that module when the module is included. Optional allocation means the module is not required by every adopter; it does not mean the module may ignore its requirements.

### 7.2 Toolkit versus application allocation

Voxelia shall provide reusable data, operation, rendering and execution contracts. The host application or deployment service remains responsible for workflow, authentication, authorisation, network security, clinical policy, storage policy and user-interface composition.

### 7.3 Diagnostic allocation

A capability is not diagnostic merely because it exists in Voxelia. The implementation, quality policy, supported input domain, device class and validation evidence shall all be included in the applicable diagnostic claim made by a downstream product.

### 7.4 Performance allocation

Performance targets apply to defined reference hardware, data and quality profiles. They shall not be interpreted as unconditional guarantees across all supported devices and inputs.

---

## 8. Traceability model

The project shall maintain bidirectional traceability using the following relationship:

```text
Project Foundation
        ↓
Master Technical Architecture
        ↓
Requirements Baseline
        ↓
Module / API / Algorithm / Shader Specification
        ↓
Implementation
        ↓
Verification Test or Analysis
        ↓
Validation Evidence
        ↓
Release
```

Each implemented P0 requirement shall be linked to at least one verification artefact before the associated milestone is accepted.

Each diagnostic-output-affecting implementation shall additionally link to:

- the applicable algorithm or presentation specification;
- numerical or spatial tolerance;
- reference implementation or analytical oracle;
- validated device capability classes; and
- release provenance.

---

## 9. Milestone acceptance gates

### 9.1 M0 — Foundation, architecture and repository

M0 is accepted when:

- governing documents are approved;
- the repository and package skeleton exist;
- licensing, contribution and security files exist;
- strict concurrency is enabled;
- the test, validation and benchmark structures exist; and
- architecture and requirements change-control mechanisms are operational.

### 9.2 M1 — Core data, spatial and geometry foundations

M1 is accepted when:

- canonical shapes, scalar formats, descriptors and data handles exist;
- affine spatial geometry and coordinate spaces are validated;
- regions, views, storage ownership and identities are validated;
- overflow, bounds and unsafe-memory tests pass; and
- public types pass concurrency review.

### 9.3 M2 — CPU reference processing

M2 is accepted when:

- the operation and execution model is functional;
- cancellation, progress and generation tests pass;
- CPU reference value transformation, windowing, resampling, histograms and measurements are validated; and
- provenance and cache identity are demonstrated.

### 9.4 M3 — Metal and Apple Silicon foundation

M3 is accepted when:

- device capability detection is implemented;
- command and resource lifecycles are validated;
- diagnostic Metal kernels have reference comparisons;
- shared and private resource policies are benchmarked;
- shader identities are recorded; and
- strict concurrency and GPU error tests pass.

### 9.5 M4 — First DICOM CT vertical slice

M4 is accepted only when all `VOX-VS1-*` requirements pass and the resulting validation and benchmark reports are reviewed.

### 9.6 M5 — Compression and large-volume storage

M5 is accepted when:

- bricked and multi-resolution storage is operational;
- codec adapters are validated;
- JP3D and HTJ2K evaluation evidence is available;
- demand decoding and eviction are demonstrated under memory pressure; and
- compressed and decoded integrity tests pass.

### 9.7 M6 — Diagnostic three-dimensional visualisation

M6 is accepted when:

- projection, conventional volume and surface rendering requirements pass;
- bricked rendering and refinement are demonstrated;
- diagnostic presentation and geometry preservation tests pass; and
- reference-device performance evidence is available.

### 9.8 M7 — Advanced processing

M7 is accepted when:

- segmentation and registration models are validated;
- required operations have reference implementations;
- failure and convergence behaviour is demonstrated; and
- VTK or ITK comparison evidence is available where used.

### 9.9 M8 — Photorealistic Rendering

M8 is accepted when:

- interactive, progressive and reference modes operate;
- provenance, reproducibility and accumulation behaviour pass;
- feature-preservation tests pass;
- conventional-render comparison is available; and
- the module remains optional.

### 9.10 M9 — Platform, headless and distributed expansion

M9 is accepted when:

- supported platform builds and representative tests pass;
- headless rendering and media-buffer outputs are demonstrated;
- distributed partition, validation and merge behaviour passes; and
- external orchestration remains outside the library.

### 9.11 M10 — Voxelia 1.0

M10 is accepted when:

- all P0 requirements allocated to Voxelia 1.0 or included optional 1.0 modules are verified;
- unresolved P1 requirements are formally dispositioned;
- public API and compatibility policies are approved;
- validation and benchmark reports are published;
- the supported-platform matrix, SBOM and known limitations are complete; and
- release artefacts are reproducible to the documented extent.

---

## 10. Baseline maintenance

### 10.1 Requirement changes

Requirement additions, modifications, retirement or reprioritisation shall include:

- change rationale;
- affected architecture;
- affected modules and APIs;
- validation impact;
- compatibility impact;
- milestone impact; and
- approval record.

### 10.2 Requirement retirement

A retired identifier shall remain in the historical record and shall not be assigned to another requirement.

### 10.3 Derived requirements

Module, algorithm, shader, performance and validation specifications may introduce derived requirements. Derived requirements shall trace back to one or more requirements in this baseline or shall identify the approved change that introduced them.

### 10.4 Open issues

Any requirement that cannot be made objectively verifiable shall be refined before its milestone acceptance review.

---

## Appendix A — Category code register

| Code | Domain |
|---|---|
| `GOV` | Project governance and scope control |
| `LIC` | Licensing and contribution provenance |
| `PLT` | Supported platforms and toolchain |
| `REP` | Repository and package distribution |
| `ARC` | Module and dependency architecture |
| `API` | Public API and type-system requirements |
| `DAT` | Canonical image and volume data model |
| `SPA` | Spatial model and coordinate systems |
| `RGN` | Regions, views and data identity |
| `META` | Metadata and provenance |
| `GEO` | Geometry model |
| `SEG` | Segmentation model and operations |
| `REG` | Registration model and operations |
| `STO` | Storage abstractions and integrity |
| `BRK` | Bricked and multi-resolution volume storage |
| `CMP` | Compression and codec integration |
| `EXE` | Operation and execution model |
| `CON` | Concurrency and task lifecycle |
| `CCH` | Planning, backend selection and caching |
| `CPU` | CPU backend |
| `MTL` | Metal backend and unified memory |
| `IMG` | Image-processing operations |
| `R2D` | Diagnostic two-dimensional presentation |
| `MPR` | Multiplanar, projection and curved reconstruction |
| `DVR` | Conventional volume rendering |
| `PRR` | Photorealistic Rendering |
| `SUR` | Surface and geometry rendering |
| `INT` | Interaction and viewport synchronisation |
| `DCM` | DICOMKit integration |
| `ADP` | Apple framework and interoperability adapters |
| `HLS` | Headless, off-screen and media output |
| `DST` | Distributed execution contracts |
| `EXT` | Extensibility and plug-in boundaries |
| `ERR` | Errors, diagnostics and observability |
| `SEC` | Security and privacy |
| `VAL` | Verification and validation |
| `PER` | Performance, memory and responsiveness |
| `DOC` | Documentation and traceability |
| `REL` | Versioning, release and compatibility |
| `VS1` | First DICOM CT vertical slice |

---

## Appendix B — Verification evidence classes

Examples of acceptable evidence include:

- source and package inspection reports;
- architecture and code review records;
- static-analysis results;
- mathematical derivations and numerical error analyses;
- automated test reports;
- property-based test results;
- golden-data manifests;
- CPU-versus-Metal differential reports;
- cross-device validation matrices;
- performance and memory benchmark reports;
- security and malformed-input test reports;
- demonstration recordings or reproducible example applications;
- licence and dependency review records; and
- release traceability matrices.

---

## Appendix C — Initial out-of-scope allocation

The following capabilities are intentionally outside the Voxelia library baseline:

- PACS and VNA persistence;
- DICOM association and routing policy beyond DICOMKit adapter use;
- enterprise user and role management;
- reporting;
- hanging protocols;
- browser user-interface implementation;
- HTTP, WebSocket and WebRTC services;
- render-farm schedulers;
- peer discovery and enrolment;
- node trust and certificate management;
- hospital audit policy;
- tenant management;
- product licence enforcement; and
- downstream medical-device regulatory approval.

The presence of transport-neutral contracts or headless outputs shall not be interpreted as ownership of these application and deployment responsibilities.

---

## Appendix D — Foundation statement

This requirements baseline establishes a verifiable path for Voxelia to become:

> **A standalone, MIT-licensed, Apple-native scientific image processing, spatial computing and visualisation toolkit that provides modern diagnostic-grade processing and rendering capabilities, exploits Apple Silicon efficiently, integrates with DICOMKit and Raster-Lab codecs, supports conventional and optional Photorealistic Rendering, and remains reusable outside the DICOM Workstation.**
