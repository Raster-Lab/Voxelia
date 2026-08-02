---
document_id: VOXELIA-FOUNDATION
title: "Voxelia Project Foundation"
version: "0.1.1"
status: "Corrective Release"
document_type: "Project Foundation"
project: "Voxelia"
platform_policy: "Apple Silicon ARM64 and Apple operating systems only"
licence: "MIT"
language: "en-GB"
date: "2026-08-02"
owner: "Voxelia Project"
repository: "To be established"
supersedes: "Voxelia Project Foundation v0.1"
superseded_by: null
classification: "Public"
---

# Voxelia Project Foundation v0.1.1

> **Platform applicability:** Voxelia exclusively targets Apple Silicon ARM64 hardware and Apple operating systems. References to operation across more than one platform mean only macOS, iOS/iPadOS, visionOS and tvOS within the Apple ecosystem. No alternate processor architecture, operating system, hosted Swift toolchain, renderer or compatibility target is within scope.

## Document control

| Field | Value |
|---|---|
| Document | Voxelia Project Foundation |
| Document identifier | `VOXELIA-FOUNDATION` |
| Version | 0.1.1 |
| Status | Corrective Release |
| Date | 2 August 2026 |
| Project | Voxelia |
| Licence | MIT |
| Language | British English |
| Intended audience | Project maintainers, contributors, integrators, clinical engineering teams, research users and downstream product teams |

### Revision history

| Version | Date | Summary |
|---|---:|---|
| 0.1 | 2026-08-01 | Initial project foundation establishing mission, scope, principles, governance, quality expectations, licensing, dependency policy, platform commitments and programme direction. |
| 0.1.1 | 2026-08-02 | Corrective platform revision establishing Apple Silicon ARM64 and Apple operating systems as the exclusive Voxelia execution, development, validation and release environment. |

### Approval record

This version is a project foundation draft. Formal approval, sign-off roles and repository references shall be added when the project governance structure is established.

---

## 1. Purpose

This document establishes the governing foundation for **Voxelia**, an open-source scientific image processing, spatial computing and visualisation toolkit designed primarily for Apple platforms and Apple Silicon.

It defines:

- the project mission and long-term vision;
- the scope of the toolkit and its explicit exclusions;
- the intended relationship between Voxelia and the DICOM Workstation;
- the project’s architectural and engineering principles;
- the supported platforms and technology baseline;
- the use of DICOMKit and the existing Raster-Lab compression libraries;
- diagnostic-grade quality and validation expectations;
- the licensing and contribution model;
- open-source governance;
- versioning, compatibility and release principles;
- security, privacy and dependency policies;
- the high-level programme roadmap; and
- the criteria for declaring Voxelia 1.0 complete.

This document is intentionally more stable and less implementation-specific than the future **Voxelia Master Technical Architecture**. Detailed package structures, public protocols, data structures, execution graphs, shader organisation and render pipelines shall be defined in the architecture and design documents derived from this foundation.

---

## 2. Authority and precedence

The Voxelia Project Foundation is the highest-level project-specific governing document for Voxelia.

All subsequent Voxelia artefacts shall conform to it, including:

- requirements specifications;
- the Master Technical Architecture;
- public API specifications;
- implementation designs;
- algorithm specifications;
- validation plans;
- benchmark plans;
- contribution guidance;
- release procedures;
- security policies;
- documentation;
- examples; and
- downstream integration guidance.

Where a lower-level document conflicts with this foundation, the foundation shall take precedence unless the foundation is formally revised.

Project decisions that materially alter mission, scope, licence, platform policy, diagnostic-grade commitments or governance shall require a revision to this document.

---

## 3. Project identity

### 3.1 Name

The project name is:

> **Voxelia**

Voxelia is a neutral name that does not restrict the toolkit to medical imaging, DICOM, one rendering technology or one application category.

### 3.2 Project description

Voxelia is:

> **An Apple-native, open-source scientific image processing, spatial computing and visualisation toolkit designed for high performance, memory efficiency, deterministic processing and validation-ready use in diagnostic-grade applications.**

### 3.3 Project type

Voxelia shall be:

- a standalone open-source library;
- distributed primarily as Swift Package Manager packages;
- suitable for integration into open-source and proprietary software;
- usable independently of the DICOM Workstation;
- modular rather than monolithic;
- capable of interactive, off-screen and headless operation; and
- designed to support both local and distributed execution.

### 3.4 Reference application

The proposed **DICOM Workstation** is the first demanding reference application for Voxelia.

The DICOM Workstation shall exercise Voxelia in areas including:

- diagnostic two-dimensional image presentation;
- multiplanar reconstruction;
- projection imaging;
- volume rendering;
- geometry and surface rendering;
- segmentation;
- registration;
- quantitative measurements;
- large-volume processing;
- Photorealistic Rendering;
- off-screen rendering; and
- distributed computation.

Voxelia shall not be architecturally restricted to the DICOM Workstation. The library shall remain suitable for other medical imaging, scientific visualisation, microscopy, industrial imaging, research, education and spatial-computing applications.

---

## 4. Mission

Voxelia’s mission is:

> **To provide a modern, efficient and trustworthy alternative to the medical imaging and scientific visualisation capabilities commonly supplied by VTK and ITK, while exploiting Apple-native technologies and the unified architecture of Apple Silicon.**

The mission is not to reproduce the complete historical class structure of VTK or ITK. Voxelia shall instead implement a coherent, modern capability set driven by current scientific imaging and diagnostic workstation needs.

---

## 5. Vision

Voxelia shall become a reusable foundation for high-performance image processing and visualisation across Apple platforms.

The long-term vision includes:

- a strongly typed Swift-native data model;
- high-performance CPU and Metal execution backends;
- deterministic reference implementations;
- diagnostic two-dimensional and three-dimensional rendering;
- modern image processing, segmentation and registration;
- compressed, bricked and multi-resolution volume storage;
- efficient use of Apple Silicon unified memory;
- optional Photorealistic Rendering;
- support for interactive and progressive quality modes;
- first-class headless and off-screen rendering;
- distributed work partitioning and result composition;
- interoperability with established scientific and medical imaging ecosystems;
- comprehensive validation and benchmarking; and
- a healthy open-source contributor community.

---

## 6. Objectives

Voxelia shall pursue the following primary objectives.

### 6.1 Diagnostic correctness

The toolkit shall provide processing and rendering behaviour that can be validated for use in diagnostic-grade applications.

Correctness shall take priority over:

- visual novelty;
- benchmark scores;
- frame rate;
- code compactness; and
- convenience abstractions.

### 6.2 Performance

The toolkit shall exploit:

- Apple Silicon;
- unified memory;
- Metal compute;
- Metal rendering;
- Accelerate;
- vImage;
- SIMD;
- asynchronous execution;
- bricked storage;
- multi-resolution representations;
- streaming; and
- workload distribution.

Performance shall be measured using representative datasets and published benchmark methods.

### 6.3 Efficiency

Voxelia shall minimise:

- redundant copies;
- full-volume expansion where avoidable;
- CPU/GPU synchronisation;
- unnecessary command submission;
- duplicate decoding;
- oversized working sets;
- repeated computation; and
- avoidable dependency overhead.

### 6.4 Reusability

The toolkit shall remain independent of:

- one application;
- one imaging modality;
- one file format;
- one workflow;
- one user interface framework;
- one scene-management framework; and
- one data transport mechanism.

### 6.5 Extensibility

New capabilities shall be addable through modular packages and well-defined extension points.

### 6.6 Transparency

Voxelia shall avoid hidden image processing. Any transformation that can affect interpretation shall be explicit, versioned and recorded in provenance.

### 6.7 Open-source adoption

The project shall use a permissive licence and low-friction integration model suitable for commercial, academic and community use.

---

## 7. Guiding principles

### 7.1 Scientific and medical semantics before graphics abstractions

Images and volumes shall not be represented merely as textures.

The canonical data model shall preserve, where applicable:

- dimensionality;
- scalar representation;
- component semantics;
- spacing;
- origin;
- orientation;
- coordinate system;
- physical units;
- frame of reference;
- value transformation;
- valid data ranges;
- temporal dimensions;
- segment identities;
- provenance; and
- source relationships.

GPU resources shall be execution representations derived from the canonical model.

### 7.2 Independent core model

The core public data model shall not depend on public types from:

- Metal;
- RealityKit;
- Model I/O;
- Core Image;
- DICOMKit;
- VTK;
- ITK; or
- a specific codec implementation.

Adapters shall connect these systems to Voxelia without making them the foundation of the public model.

### 7.3 Explicit execution

Processing operations shall be explicit about:

- inputs;
- outputs;
- parameters;
- precision;
- quality profile;
- backend;
- version;
- cancellation;
- progress; and
- provenance.

### 7.4 Immutable-by-default data flow

Processing inputs and outputs should be immutable wherever practical.

Mutable state shall be confined to controlled services such as:

- schedulers;
- caches;
- residency managers;
- streaming controllers;
- interactive renderer state; and
- resource pools.

### 7.5 Capability-driven acceleration

The public API shall describe required behaviour rather than one hardware implementation.

Voxelia shall select the most appropriate validated execution path according to:

- device capability;
- data type;
- operation;
- workload size;
- memory pressure;
- requested quality;
- determinism requirements; and
- supported platform features.

### 7.6 Progressive refinement

Interactive operations may initially produce a reduced-cost result where allowed by the selected execution profile, but shall converge towards the requested final quality.

### 7.7 Safe failure

When data, resources or capabilities are insufficient, Voxelia shall fail clearly rather than silently substitute incorrect behaviour.

### 7.8 Validation from the beginning

Validation shall be designed into the architecture, not added after feature development.

### 7.9 Application boundaries

Voxelia shall provide reusable computation and rendering capabilities. Application policy, user management and deployment orchestration shall remain outside the toolkit.

### 7.10 Open design

Significant architectural decisions shall be documented through public design records or requests for comments.

---

## 8. Scope

### 8.1 Core scope

Voxelia shall include or be designed to include:

- N-dimensional image representation;
- three-dimensional scalar and multi-component volumes;
- label maps;
- masks;
- vector fields;
- point sets;
- curves and centre lines;
- polygonal geometry;
- triangle meshes;
- spatial transforms;
- deformation fields;
- coordinate systems;
- regions and views;
- image processing;
- resampling;
- interpolation;
- projections;
- quantitative measurements;
- segmentation;
- registration;
- geometry extraction;
- geometry processing;
- diagnostic two-dimensional rendering;
- multiplanar reconstruction;
- curved planar reconstruction;
- direct volume rendering;
- projection rendering;
- surface rendering;
- image fusion;
- segmentation overlays;
- annotations and picking;
- off-screen and headless rendering;
- CPU execution;
- Metal execution;
- bricked and tiled storage;
- compressed volume storage;
- multi-resolution storage;
- streaming;
- provenance;
- reproducibility;
- validation utilities;
- benchmark utilities;
- distributed operation descriptions;
- work partitioning; and
- mergeable distributed results.

### 8.2 Optional modules

The following shall be optional modules rather than mandatory dependencies of the core:

- DICOMKit integration;
- codec integrations;
- RealityKit integration;
- Model I/O integration;
- Core Image integration;
- Photorealistic Rendering;
- media encoding;
- headless render service adapters;
- VTK interoperability;
- ITK interoperability;
- scientific file-format adapters;
- distributed execution contracts; and
- platform-specific user-interface adapters.

### 8.3 Application responsibilities outside Voxelia

The following shall not form part of the Voxelia core library:

- PACS or VNA functionality;
- DICOM networking services beyond adapter boundaries;
- DICOMweb servers;
- user authentication;
- authorisation policy;
- hospital identity integration;
- study worklists;
- reporting;
- hanging protocols;
- browser user interfaces;
- HTTP servers;
- WebSocket servers;
- WebRTC signalling;
- render-farm orchestration;
- worker discovery;
- peer-to-peer enrolment;
- enterprise job queues;
- tenant management;
- audit policy;
- deployment management;
- licensing enforcement for host products; and
- medical-device regulatory approval of downstream products.

Separate projects may use Voxelia to provide these functions.

---

## 9. Explicit exclusions

The initial project shall not attempt to:

- recreate every VTK class;
- recreate every ITK algorithm;
- reproduce legacy VTK or ITK APIs;
- become a drop-in binary replacement for VTK or ITK;
- implement a general-purpose game engine;
- implement a complete finite-element visualisation platform;
- implement a PACS;
- implement a complete DICOM stack already provided by DICOMKit;
- duplicate codecs available in Raster-Lab libraries;
- embed an application-specific database;
- embed hospital-specific workflow policy;
- provide a public cloud service as part of the core repository; or
- claim independent regulatory certification.

These exclusions may be revisited through the formal project change process.

---

## 10. Users and use cases

### 10.1 Primary user groups

Voxelia is intended for:

- developers of diagnostic workstations;
- medical imaging software developers;
- scientific visualisation developers;
- research software engineers;
- academic users;
- surgical-planning developers;
- microscopy and industrial-imaging developers;
- developers of spatial-computing applications;
- server-side rendering developers; and
- contributors implementing algorithms, formats and integrations.

### 10.2 Reference use cases

Reference use cases include:

- CT and MR image viewing;
- multiplanar reconstruction;
- thick-slab projection;
- PET/CT or other multi-volume fusion;
- three-dimensional volume rendering;
- surface extraction;
- segmentation visualisation;
- rigid and affine registration;
- quantitative measurement;
- large-study streaming;
- off-screen image production;
- remote rendering;
- progressive high-quality rendering;
- Photorealistic Rendering;
- distributed rendering;
- scientific image processing; and
- spatial presentation on visionOS.

---

## 11. Platform policy

### 11.1 Supported Apple platforms

Voxelia shall target:

- macOS;
- iOS;
- iPadOS;
- visionOS; and
- tvOS.

### 11.2 Primary development platform

The primary development and performance reference platform shall be:

> **Apple Silicon macOS**

This platform is the primary target for the diagnostic DICOM Workstation, headless rendering and distributed render workers.

### 11.3 Architecture

Production Apple-platform support shall prioritise:

- ARM64;
- Apple Silicon;
- unified memory;
- modern Metal feature sets; and
- current Swift concurrency.

Apple Silicon ARM64 is the exclusive supported processor architecture. Intel, x86 and x64 targets are unsupported and excluded.

### 11.4 Toolchain

The initial baseline shall be:

- Swift 6.2 or later;
- strict concurrency checking;
- Swift Package Manager;
- Metal Shading Language;
- Apple-native build and profiling tools; and
- automated testing on supported platforms.

The exact minimum operating-system versions shall be defined by the Master Technical Architecture and release support policy.

### 11.5 Exclusive Apple platform scope

Voxelia is an Apple ecosystem toolkit. Development, continuous integration, validation, benchmarking, release preparation, diagnostic-reference execution, headless rendering and distributed workers shall use Apple Silicon hardware and Apple operating systems.

The following are explicitly excluded:

- Intel, x86 and x64 processor targets;
- non-Apple operating systems;
- non-Apple-hosted Swift toolchains;
- alternate GPU backends; and
- portability commitments derived from platform-neutral internal abstractions.

Any proposal to change this scope requires a formal revision of this Project Foundation.

---

## 12. Apple Silicon and unified memory

Efficient use of Apple Silicon unified memory is a foundational requirement.

Voxelia shall be designed to:

- reduce CPU-to-GPU copies;
- permit shared CPU/GPU access where advantageous;
- decode into reusable storage;
- support memory-mapped inputs;
- distinguish shared and GPU-optimised resource policies;
- use private GPU resources where sampling performance justifies them;
- employ resource heaps where beneficial;
- support sparse resources where appropriate;
- manage decompressed working sets independently of compressed caches;
- respond to memory pressure;
- stream regions and bricks;
- avoid requiring full-volume residency;
- support progressive and multi-resolution presentation; and
- expose memory and residency diagnostics to developers.

Unified memory shall not be treated as an excuse to hold every representation simultaneously. Voxelia shall make storage and residency decisions according to workload and device capability.

---

## 13. Existing Raster-Lab libraries

### 13.1 Reuse policy

Voxelia shall reuse existing Raster-Lab libraries rather than reimplement equivalent functionality.

Preferred integrations include:

- **DICOMKit** for DICOM parsing, metadata, datasets, networking and DICOMweb-related capabilities;
- **J2KSwift** for JPEG 2000, HTJ2K, JP3D and related functionality;
- **JLSwift** for JPEG-LS;
- **JLISwift** for JPEG-related functionality;
- **JXLSwift** for JPEG XL;
- **CompressionFamily** where appropriate; and
- future Raster-Lab codecs and data libraries.

### 13.2 Dependency direction

Voxelia core modules shall not require DICOMKit.

Integration shall use an adapter model:

```text
VoxeliaDICOMKit
├── Voxelia core modules
└── DICOMKit
```

This preserves Voxelia’s format neutrality and avoids circular dependencies.

### 13.3 Dependency gaps

The project shall assume that required platform or API gaps in Raster-Lab dependencies can be addressed by the responsible library teams.

When an actual dependency constraint is encountered:

1. the Voxelia team shall record the requirement;
2. the issue shall be raised against the responsible library;
3. the impact on Voxelia shall be documented;
4. a temporary adapter or conditional path may be used where justified; and
5. functionality shall not be silently reimplemented inside Voxelia without an explicit architectural decision.

---

## 14. Compression-aware storage

### 14.1 Purpose

Compression shall be used to reduce:

- persistent cache size;
- memory-mapped storage footprint;
- network transfer;
- render-farm data transfer;
- duplicate decoded representations; and
- time to first useful image.

### 14.2 Supported storage concepts

Voxelia shall support:

- original compressed source objects;
- compressed slices;
- compressed slabs;
- compressed three-dimensional bricks;
- multi-resolution compressed representations;
- memory-mapped compressed stores;
- decompressed brick caches; and
- content-addressed compressed assets.

### 14.3 JP3D and HTJ2K

Lossless JPEG 2000 Part 10 three-dimensional compression and high-throughput JPEG 2000 shall be considered first-class internal storage technologies where they provide measurable benefit.

Voxelia shall support evaluation of:

- JP3D volume coding;
- HTJ2K coding;
- JP3D/HTJ2K combinations supported by the Raster-Lab codec implementation;
- independent three-dimensional compressed bricks;
- partial-resolution decoding;
- region-of-interest decoding;
- parallel decoding;
- progressive loading; and
- distributed brick transport.

### 14.4 Runtime model

Compressed data shall not be treated as directly sampleable GPU texture data.

The expected model is:

```text
Compressed source or cache
        ↓
Demand decode
        ↓
Reusable decompressed brick
        ↓
CPU and/or Metal residency
        ↓
Processing or rendering
```

Compression reduces storage and working-set requirements only when paired with controlled demand decoding and eviction.

### 14.5 DICOM boundary

JP3D may be used as a toolkit-native internal cache or derived representation.

Original DICOM objects shall be preserved, and non-standard compressed representations shall not be presented as standard DICOM transfer syntaxes.

---

## 15. Rendering scope

### 15.1 Diagnostic rendering

Diagnostic rendering shall be a core Voxelia capability.

It shall include:

- two-dimensional image presentation;
- modality transformations;
- window and level;
- LUT application;
- colour and palette handling;
- segmentation overlays;
- image fusion;
- MPR;
- thick-slab rendering;
- MIP;
- MinIP;
- AIP;
- direct volume rendering;
- surface rendering;
- measurements;
- picking;
- annotations;
- clipping;
- cropping; and
- off-screen export.

### 15.2 Rendering backends

Metal shall be the primary rendering and compute backend.

RealityKit may be used through an optional adapter for:

- visionOS spatial presentation;
- scene composition;
- surface models;
- spatial interaction; and
- contextual rendering.

RealityKit shall not define the authoritative scientific data model or diagnostic presentation pipeline.

### 15.3 Quality profiles

Voxelia shall define explicit execution and rendering profiles, including:

- **reference**;
- **diagnostic**;
- **interactive**; and
- **preview**.

The Master Technical Architecture shall define the exact guarantees of each profile.

---

## 16. Photorealistic Rendering

### 16.1 Status

**Photorealistic Rendering** shall be an optional Voxelia capability.

It shall not replace conventional diagnostic rendering and shall not be required for all applications or devices.

### 16.2 Goals

Photorealistic Rendering shall support:

- physically based illumination;
- volumetric shadows;
- global illumination;
- multiple scattering where supported;
- area lighting;
- environment lighting;
- transparency;
- transillumination;
- material-separated presentation;
- progressive refinement;
- temporal stability;
- deterministic reference rendering;
- high-resolution export; and
- distributed sample accumulation.

### 16.3 Performance control

Applications shall be able to:

- disable Photorealistic Rendering;
- select lower-cost interactive modes;
- request progressive quality;
- request deterministic reference output;
- limit memory use;
- limit sample count; and
- fall back to conventional volume rendering.

### 16.4 Diagnostic safeguards

Photorealistic output shall:

- preserve access to authoritative source values;
- keep measurements independent of rendered pixels;
- record rendering parameters;
- record renderer and shader versions;
- identify denoising or temporal accumulation;
- avoid hidden generative reconstruction;
- expose reproducible random seeds where applicable; and
- support side-by-side verification with conventional rendering.

---

## 17. Headless and remote rendering

### 17.1 Library responsibilities

Voxelia shall support:

- off-screen rendering;
- headless rendering on supported Apple systems;
- raw pixel output;
- image output;
- video-frame output;
- depth output;
- object or segment identifier output;
- progressive frame delivery;
- cancellable render requests; and
- deterministic render descriptions.

### 17.2 External responsibilities

The following are outside Voxelia:

- web-server implementation;
- WebSocket implementation;
- WebRTC signalling;
- authentication;
- session management;
- user authorisation;
- browser user-interface implementation;
- hospital deployment policy;
- PACS access policy; and
- network-facing audit policy.

Separate services may use Voxelia’s headless rendering API to provide browser-accessible rendering.

---

## 18. Distributed execution

### 18.1 Library responsibilities

Voxelia shall define transport-neutral descriptions for distributable work.

These may include:

- serialisable operation descriptions;
- render-job descriptions;
- content-addressed inputs;
- input checksums;
- algorithm versions;
- shader versions;
- device capability declarations;
- tile partitions;
- frame partitions;
- brick partitions;
- path-tracing sample ranges;
- deterministic random seeds;
- mergeable accumulators;
- partial-result descriptions;
- progress states; and
- result validation metadata.

### 18.2 External orchestration

Voxelia shall not itself implement:

- worker discovery;
- job-queue services;
- cluster membership;
- peer enrolment;
- peer trust;
- node identity;
- load balancing;
- enterprise scheduling;
- retry policy;
- hospital network policy;
- billing or resource accounting; or
- peer-to-peer idle-resource lending.

These belong in separate compute-fabric or deployment projects.

### 18.3 Peer resource sharing

Peer-to-peer use of idle workstations may be supported by a future external compute fabric using Voxelia job contracts.

Such a system should be:

- disabled by default;
- explicitly enrolled;
- administrator-controlled;
- authenticated;
- encrypted;
- auditable;
- pre-emptible;
- resource-limited;
- version-aware; and
- compliant with the host organisation’s data policy.

---

## 19. Diagnostic-grade quality

### 19.1 Position

Voxelia shall be engineered to support validation within regulated diagnostic products.

Voxelia itself shall not claim that integration automatically confers regulatory approval.

### 19.2 Quality attributes

The project shall prioritise:

- correctness;
- reproducibility;
- numerical stability;
- deterministic reference behaviour;
- clear error handling;
- traceability;
- provenance;
- testability;
- observability;
- secure coding;
- maintainability; and
- documented limitations.

### 19.3 No hidden processing

Voxelia shall not silently apply:

- smoothing;
- sharpening;
- denoising;
- tone mapping;
- upscaling;
- interpolation changes;
- colour enhancement;
- temporal accumulation;
- reconstruction; or
- AI-based enhancement.

Any such processing shall be explicit and attributable.

### 19.4 Reference implementations

Important GPU operations shall have independent reference implementations where practical.

Reference implementations may use:

- Swift;
- Accelerate;
- vImage;
- established mathematical libraries; or
- independently validated external implementations used only for comparison.

### 19.5 Error budgets

Algorithms shall define appropriate error tolerances for:

- scalar values;
- spatial coordinates;
- interpolation;
- registration transforms;
- measurements;
- geometry;
- image presentation; and
- rendering.

### 19.6 Failure behaviour

Voxelia shall fail clearly when:

- data geometry is invalid;
- input formats are unsupported;
- required metadata is absent;
- memory cannot be allocated;
- a GPU feature is unavailable;
- a shader fails;
- a transform is singular;
- registration fails to converge;
- an operation is cancelled; or
- the requested quality cannot be met.

Silent substitution of incorrect behaviour is prohibited.

---

## 20. Validation strategy

Validation shall include, as applicable:

- unit tests;
- integration tests;
- property-based tests;
- analytical test cases;
- synthetic phantoms;
- golden images;
- differential CPU/GPU testing;
- cross-device comparisons;
- cross-Apple-platform comparisons;
- codec conformance testing;
- DICOM-derived geometry tests;
- public dataset testing;
- VTK comparison;
- ITK comparison;
- performance regression tests;
- memory regression tests;
- stress tests;
- cancellation tests;
- fault-injection tests; and
- reproducibility tests.

Tests shall distinguish:

- exact equivalence;
- bounded numerical equivalence;
- perceptual equivalence;
- diagnostic equivalence; and
- performance-only acceptance.

---

## 21. Performance and efficiency policy

### 21.1 Performance is a requirement

Performance shall be defined through explicit requirements and benchmarks rather than informal expectations.

### 21.2 Measurement

Benchmarks shall record:

- hardware;
- operating system;
- toolkit version;
- algorithm version;
- compiler version;
- shader version;
- dataset;
- dimensions;
- scalar type;
- storage form;
- quality profile;
- memory use;
- latency;
- throughput;
- frame rate;
- energy use where practical; and
- output validation status.

### 21.3 No unvalidated optimisation

An optimisation that changes numerical or presentation behaviour shall not be accepted into a diagnostic path without validation.

### 21.4 Interactive convergence

Interactive rendering may use reduced-cost intermediate results only where the active profile permits it.

When interaction ceases, output shall converge towards the requested final quality.

Measurements and pixel inspection shall use authoritative data, not presentation approximations.

---

## 22. Security and privacy

### 22.1 Toolkit role

Voxelia is a library and shall not implement a complete application security model.

It shall nevertheless follow secure-library principles.

### 22.2 Requirements

Voxelia shall:

- validate external input boundaries;
- avoid unsafe memory access where possible;
- document unavoidable unsafe code;
- avoid logging image data or patient information by default;
- make diagnostic logging configurable;
- avoid embedding credentials;
- avoid unauthenticated network services;
- validate dimensions and allocation sizes;
- resist malformed compressed data;
- handle decoder failures safely;
- document temporary-file behaviour;
- support cancellation of untrusted workloads;
- provide a vulnerability-reporting process; and
- maintain dependency and SBOM information.

### 22.3 Host responsibilities

The host application remains responsible for:

- authentication;
- authorisation;
- secure transport;
- patient privacy;
- data retention;
- access auditing;
- tenancy;
- network policy; and
- regulatory security controls.

---

## 23. Licensing

### 23.1 Project licence

Voxelia shall be released under the:

> **MIT Licence**

### 23.2 Objectives

The MIT Licence is selected to:

- remain consistent with other Raster-Lab open-source projects;
- permit commercial use;
- permit proprietary integration;
- permit static linking;
- permit App Store distribution;
- minimise legal friction;
- encourage academic and community adoption; and
- allow broad reuse.

### 23.3 Copyright notices

Source files should carry an SPDX identifier where practical:

```text
SPDX-License-Identifier: MIT
```

The repository shall contain:

- `LICENSE`;
- `THIRD_PARTY_NOTICES.md`;
- dependency licence records; and
- release SBOMs.

### 23.4 Contributions

Contributors shall certify contribution provenance through the Developer Certificate of Origin or an equivalent project-approved mechanism.

A contributor licence agreement shall not be required unless later approved through project governance.

---

## 24. Dependency policy

### 24.1 General rule

Core dependencies shall be:

- technically justified;
- actively maintained or controlled by the project;
- compatible with commercial use;
- licence-compatible;
- security-reviewed;
- version-pinned or bounded appropriately; and
- recorded in the SBOM.

### 24.2 Preferred licences

Preferred dependency licences include:

- MIT;
- BSD-2-Clause;
- BSD-3-Clause;
- Apache-2.0; and
- similarly permissive licences approved through review.

### 24.3 Copyleft dependencies

Strong copyleft dependencies shall not be included in the core distribution.

Weak copyleft or other restrictive dependencies may be considered only when:

- isolated in an optional module;
- legally reviewed;
- clearly documented;
- excluded from default builds where appropriate; and
- compatible with intended distribution models.

### 24.4 Dependency duplication

Voxelia shall not add a second library for functionality already adequately supplied by an approved Raster-Lab dependency without a recorded decision.

---

## 25. Open-source governance

### 25.1 Governance model

The project shall use a maintainer-led open-source governance model.

Roles may include:

- **Project Lead** — accountable for project direction;
- **Maintainers** — approve changes and releases;
- **Module Maintainers** — own defined technical areas;
- **Committers** — have repository write access;
- **Contributors** — submit issues, designs, documentation and code;
- **Reviewers** — provide specialist review; and
- **Security Contacts** — handle vulnerability reports.

Named appointments shall be documented separately.

### 25.2 Decision principles

Decisions shall favour:

- technical merit;
- diagnostic correctness;
- maintainability;
- interoperability;
- performance evidence;
- documented trade-offs;
- open discussion; and
- long-term project health.

### 25.3 Significant changes

Significant changes shall use a request-for-comments process.

Examples include:

- public API redesign;
- new core dependencies;
- licence changes;
- platform changes;
- execution-model changes;
- data-model changes;
- diagnostic-behaviour changes;
- distributed-execution changes; and
- removal of supported capabilities.

### 25.4 Architecture decisions

Important implementation decisions shall be recorded as architecture decision records.

### 25.5 Conflict resolution

Maintainers should seek technical consensus.

Where consensus cannot be reached, the Project Lead or designated technical steering group shall make the final decision and document the rationale.

---

## 26. Contribution policy

Contributions may include:

- code;
- algorithms;
- tests;
- validation datasets;
- benchmark datasets;
- documentation;
- tutorials;
- examples;
- format adapters;
- bug reports;
- security reports;
- design proposals; and
- performance analysis.

Contributions shall meet applicable requirements for:

- licence provenance;
- coding style;
- documentation;
- tests;
- performance evidence;
- validation evidence;
- dependency disclosure; and
- security review.

Algorithms derived from publications shall cite their source and document implementation-specific choices.

Contributors shall not submit code they are not authorised to contribute.

---

## 27. Documentation and traceability

### 27.1 Documentation as code

Project documentation shall be:

- stored with the source;
- written primarily in Markdown and DocC;
- version controlled;
- reviewed through the same workflow as code;
- linked to releases; and
- suitable for automated validation.

### 27.2 Required documentation categories

The project shall maintain:

- Project Foundation;
- Master Technical Architecture;
- requirements;
- architecture decision records;
- requests for comments;
- public API documentation;
- algorithm specifications;
- shader specifications;
- validation plans;
- validation reports;
- benchmark specifications;
- benchmark reports;
- security documentation;
- release notes;
- migration guides;
- examples;
- tutorials; and
- known-limitations documentation.

### 27.3 Traceability

Important requirements shall be traceable to:

- architecture;
- implementation;
- tests;
- validation evidence; and
- releases.

### 27.4 Language

Project documentation shall use British English unless a programming-language identifier, external standard or quoted term requires otherwise.

---

## 28. Coding and implementation principles

Detailed coding standards shall be defined separately. At foundation level, the following principles apply:

- Swift strict concurrency shall be enabled;
- public types shall be intentionally designed for `Sendable` behaviour;
- actor isolation shall be used for shared mutable services;
- unsafe code shall be minimised and reviewed;
- GPU command ownership shall be explicit;
- command encoders shall not be cached as data products;
- public APIs shall not expose unnecessary backend details;
- resource lifetimes shall be explicit;
- cancellation shall be propagated;
- obsolete asynchronous results shall not replace newer results;
- algorithm and shader versions shall be recorded;
- reference and accelerated implementations shall remain distinguishable;
- errors shall be typed and actionable;
- source code shall be documented;
- warnings shall not be ignored without justification; and
- performance-sensitive code shall include benchmarks.

---

## 29. API compatibility and versioning

### 29.1 Semantic versioning

Voxelia shall use Semantic Versioning.

### 29.2 Pre-1.0 policy

During `0.x` development:

- public APIs may change;
- breaking changes shall be documented;
- migration guidance should be provided for significant changes;
- unnecessary churn shall still be avoided; and
- architectural stability shall be sought before 1.0.

### 29.3 Version 1.0 policy

After 1.0:

- source compatibility shall be treated as a formal commitment within the published support policy;
- deprecations shall precede removals;
- breaking changes shall require a major version;
- behavioural changes shall be documented;
- diagnostic output changes shall require explicit release notes and validation; and
- stable serialised job or cache formats shall carry independent format versions where needed.

### 29.4 ABI policy

Voxelia shall not commit to a stable Swift binary ABI for its own module boundaries before the technical architecture and distribution strategy establish that requirement.

Source-package compatibility is the initial priority.

---

## 30. Release policy

### 30.1 Release types

The project may publish:

- development snapshots;
- alpha releases;
- beta releases;
- release candidates;
- stable releases;
- maintenance releases; and
- security releases.

### 30.2 Release contents

A stable release should include:

- tagged source;
- release notes;
- compatibility information;
- migration guidance where needed;
- test results;
- benchmark results;
- validation status;
- supported-platform matrix;
- known limitations;
- dependency inventory;
- SBOM;
- third-party notices; and
- reproducible build information where practical.

### 30.3 Diagnostic status

Documentation shall distinguish:

- experimental;
- preview;
- validated;
- diagnostic-ready for downstream validation; and
- deprecated capabilities.

The project shall avoid ambiguous labels.

---

## 31. Repository foundation

The initial repository should contain:

```text
Voxelia/
├── Package.swift
├── README.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── CODEOWNERS
├── THIRD_PARTY_NOTICES.md
├── Documentation.docc/
├── Sources/
├── Tests/
├── Benchmarks/
├── Validation/
├── Examples/
├── Tools/
└── docs/
```

The exact module graph shall be established in the Master Technical Architecture.

---

## 32. Programme roadmap

### Phase 0 — Foundation and architecture

Deliver:

- Project Foundation;
- Master Technical Architecture;
- requirements baseline;
- repository scaffold;
- contribution policy;
- validation strategy;
- benchmark strategy; and
- initial architecture decision records.

### Phase 1 — Core data and spatial model

Deliver:

- image descriptors;
- volume descriptors;
- storage abstractions;
- regions and views;
- spatial transforms;
- coordinate systems;
- geometry primitives;
- units;
- metadata; and
- provenance.

### Phase 2 — CPU reference processing

Deliver:

- scalar conversion;
- modality transformation;
- windowing;
- LUTs;
- interpolation;
- resampling;
- slice extraction;
- MPR;
- projection;
- histograms; and
- measurements.

### Phase 3 — Metal foundation

Deliver:

- device abstraction;
- capability detection;
- shader library management;
- compute scheduling;
- render scheduling;
- unified-memory strategies;
- resource residency;
- diagnostic slice rendering; and
- CPU/GPU comparison.

### Phase 4 — First DICOM vertical slice

Deliver:

- DICOMKit adapter;
- CT series assembly;
- patient-space geometry;
- axial rendering;
- coronal and sagittal MPR;
- crosshair interaction;
- distance measurement;
- off-screen output; and
- validation.

### Phase 5 — Compression and large-volume storage

Deliver:

- tiled and bricked storage;
- memory-mapped storage;
- compressed brick storage;
- codec adapters;
- JP3D and HTJ2K evaluation;
- multi-resolution pyramids;
- demand decoding;
- cache eviction; and
- memory-pressure handling.

### Phase 6 — Diagnostic 3D visualisation

Deliver:

- MIP;
- MinIP;
- AIP;
- direct volume rendering;
- transfer functions;
- gradients;
- clipping;
- cropping;
- segmentation overlays;
- surface extraction; and
- surface rendering.

### Phase 7 — Advanced processing

Deliver:

- morphology;
- connected components;
- segmentation;
- registration;
- deformation fields;
- geometry processing;
- curved planar reconstruction; and
- advanced measurements.

### Phase 8 — Photorealistic Rendering

Deliver:

- interactive mode;
- progressive mode;
- reference mode;
- global illumination;
- volumetric shadows;
- multiple scattering;
- transparency;
- transillumination;
- material separation;
- deterministic output; and
- distributed accumulation.

### Phase 9 — Platform and distributed expansion

Deliver:

- complete iOS and iPadOS integration;
- visionOS integration;
- tvOS integration;
- RealityKit adapter;
- headless rendering;
- media adapters;
- distributed job contracts;
- result merging; and
- interoperability modules.

### Phase 10 — Voxelia 1.0

Deliver:

- stable public API;
- documented compatibility policy;
- validated diagnostic workstation foundation;
- supported-platform matrix;
- complete introductory and developer documentation;
- public benchmark reports;
- public validation reports;
- migration and integration guides;
- release SBOM;
- MIT publication baseline; and
- long-term maintenance plan.

---

## 33. Voxelia 1.0 success criteria

Voxelia 1.0 shall be considered complete when the project provides:

### 33.1 Foundation

- approved project governance;
- stable licence and contribution model;
- documented scope;
- stable architecture; and
- maintained project documentation.

### 33.2 Data and processing

- stable scientific image and spatial models;
- CPU reference processing;
- Metal acceleration;
- deterministic execution;
- provenance;
- cancellation;
- progress;
- caching; and
- validated numerical behaviour.

### 33.3 Rendering

- diagnostic two-dimensional rendering;
- MPR;
- thick-slab projection;
- MIP, MinIP and AIP;
- direct volume rendering;
- surface rendering;
- segmentation overlays;
- fusion;
- measurements;
- picking;
- annotations; and
- off-screen rendering.

### 33.4 Storage

- contiguous storage;
- tiled or bricked storage;
- large-volume streaming;
- memory-pressure handling;
- compressed cache integration;
- Raster-Lab codec integration; and
- multi-resolution representations.

### 33.5 Integration

- DICOMKit adapter;
- supported Apple platforms;
- headless rendering;
- documented extension points;
- VTK or ITK comparison paths where required for validation; and
- distributable work descriptions.

### 33.6 Quality

- public validation strategy;
- representative validation reports;
- benchmark suite;
- performance baselines;
- dependency inventory;
- security policy;
- known-limitations documentation; and
- reproducible release artefacts where practical.

Photorealistic Rendering may reach stable 1.0 status with the main toolkit or remain an explicitly versioned optional module if its validation and performance programme requires additional time. Its status shall not compromise the release quality of conventional diagnostic rendering.

---

## 34. Initial project risks

| Risk | Consequence | Foundation response |
|---|---|---|
| Attempting to recreate all of VTK and ITK | Unbounded scope and delayed delivery | Focus on modern scientific imaging and diagnostic workstation needs |
| Coupling public APIs to Metal or RealityKit | Reduced portability and unstable abstractions | Maintain an independent core data model |
| Excessive full-volume memory use | Poor performance and device instability | Bricking, streaming, compression and residency management |
| GPU numerical divergence | Diagnostic inconsistency | CPU references, error budgets and differential tests |
| Hidden image enhancement | Clinical interpretation risk | Explicit operations and provenance |
| Overly broad server responsibilities | Toolkit becomes a platform product | Keep network services and orchestration outside the library |
| Peer compute complexity | Security and operational risk | Provide job contracts only; externalise peer fabric |
| Codec duplication | Maintenance and consistency problems | Reuse Raster-Lab codec libraries |
| Swift concurrency defects | Races and stale results | Immutable operations and actor-isolated services |
| Photorealistic output obscures pathology | Diagnostic risk | Conventional comparison, material-preserving presets and validation |
| Public API churn | Adoption friction | Architecture-first development and staged stabilisation |
| Dependency licence conflict | Distribution restrictions | Permissive dependency policy and SBOM review |
| Inadequate validation | Unsuitable for diagnostic products | Validation infrastructure from project inception |

---

## 35. Open decisions for the Master Technical Architecture

The following shall be resolved in the next architecture phase:

1. exact Swift package and module graph;
2. minimum supported operating-system versions;
3. canonical image rank and dimensionality representation;
4. scalar and component type model;
5. coordinate-system conventions and conversion APIs;
6. storage protocol hierarchy;
7. zero-copy view semantics;
8. bricked volume dimensions and tuning strategy;
9. compressed brick format and metadata;
10. operation identity and cache-key model;
11. scheduler and actor boundaries;
12. cancellation and generation semantics;
13. progress reporting;
14. backend selection;
15. CPU reference implementation boundaries;
16. Metal resource policy;
17. shader versioning;
18. render graph;
19. viewport and camera model;
20. diagnostic presentation pipeline;
21. Photorealistic Rendering architecture;
22. headless output model;
23. distributed-job serialisation;
24. plug-in and extension model;
25. validation evidence structure;
26. benchmark hardware classes;
27. error and diagnostic model;
28. DICOMKit adapter boundaries;
29. codec adapter interfaces; and
30. initial vertical-slice acceptance criteria.

---

## 36. Next authorised artefacts

Following approval of this foundation, the project should create the following artefacts in order:

1. **Voxelia Master Technical Architecture v0.1.1**
2. **Voxelia Requirements Baseline v0.1.1**
3. **Voxelia Validation and Benchmark Strategy v0.1.1**
4. **Voxelia Repository and Package Scaffold**
5. **Voxelia Core Data Model Specification v0.1.1**
6. **Voxelia First Vertical Slice Plan v0.1.1**

No substantial production implementation should begin before the Master Technical Architecture and initial requirements baseline have been reviewed.

---

## 37. Foundation statement

Voxelia is established as:

> **A standalone, MIT-licensed, Apple-native scientific image processing, spatial computing and visualisation toolkit. It shall provide a modern alternative to the medical imaging and visualisation capabilities commonly associated with VTK and ITK, while prioritising diagnostic correctness, Apple Silicon efficiency, explicit processing, extensibility, validation and broad reuse.**

The DICOM Workstation is Voxelia’s first demanding reference application, but Voxelia shall remain neutral, modular and independently useful.

Its defining technical direction is:

- an independent scientific and spatial data model;
- explicit and typed processing;
- CPU reference implementations;
- Metal acceleration;
- unified-memory-aware storage;
- bricked and compressed volume handling;
- conventional diagnostic rendering;
- optional Photorealistic Rendering;
- headless rendering;
- distributable work contracts;
- DICOMKit and Raster-Lab codec integration; and
- validation-ready engineering from the start.

---

## Appendix A — Normative language

The terms **shall**, **should** and **may** are used as follows:

- **shall** indicates a mandatory project requirement;
- **should** indicates a recommended approach that may be departed from with justification; and
- **may** indicates a permitted option.

---

## Appendix B — Initial terminology

| Term | Meaning within Voxelia |
|---|---|
| Authoritative data | The source or validated processed data used for quantitative interpretation, independent of presentation approximations |
| Backend | An implementation that executes Voxelia operations, such as CPU or Metal |
| Brick | A bounded three-dimensional subregion of a larger volume used for storage, streaming, decoding or residency |
| Diagnostic profile | An execution profile restricted to validated behaviour and documented error bounds |
| Headless rendering | Rendering without an interactive application window |
| Interactive profile | A profile permitting validated adaptive quality during interaction |
| Photorealistic Rendering | Optional physically based volume rendering intended to improve depth, lighting and material perception |
| Preview profile | A non-diagnostic profile that may use approximations and must be identified as such |
| Provenance | Structured information describing the origin, transformations, parameters and implementation versions associated with data or output |
| Reference profile | A deterministic or highest-assurance profile used for verification and reproducibility |
| Residency | The current placement of data in CPU-accessible, shared or GPU-optimised memory |
| Spatial geometry | The mapping between discrete image indices and a physical coordinate system |
| Vertical slice | A complete, narrow implementation path proving several architectural layers together |
| Voxelia operation | A typed, versioned transformation or rendering request with explicit inputs, parameters and output |
