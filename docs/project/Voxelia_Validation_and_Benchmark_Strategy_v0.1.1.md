---
document_id: VOXELIA-VBS
title: "Voxelia Validation and Benchmark Strategy"
version: "0.1.1"
status: "Corrective Release"
document_type: "Validation and Benchmark Strategy"
project: "Voxelia"
platform_policy: "Apple Silicon ARM64 and Apple operating systems only"
licence: "MIT"
language: "en-GB"
date: "2026-08-02"
owner: "Voxelia Project"
governing_documents:
  - "Voxelia Project Foundation v0.1.1"
  - "Voxelia Master Technical Architecture v0.1.1"
  - "Voxelia Requirements Baseline v0.1.1"
repository: "To be established"
supersedes: "Voxelia Validation and Benchmark Strategy v0.1"
superseded_by: null
classification: "Public"
---

# Voxelia Validation and Benchmark Strategy v0.1.1

> **Platform applicability:** Voxelia exclusively targets Apple Silicon ARM64 hardware and Apple operating systems. References to operation across more than one platform mean only macOS, iOS/iPadOS, visionOS and tvOS within the Apple ecosystem. No alternate processor architecture, operating system, hosted Swift toolchain, renderer or compatibility target is within scope.

## Document control

| Field | Value |
|---|---|
| Document | Voxelia Validation and Benchmark Strategy |
| Document identifier | `VOXELIA-VBS` |
| Version | 0.1.1 |
| Status | Corrective Release |
| Date | 2 August 2026 |
| Project | Voxelia |
| Governing documents | Voxelia Project Foundation v0.1.1; Voxelia Master Technical Architecture v0.1.1; Voxelia Requirements Baseline v0.1.1 |
| Licence | MIT |
| Language | British English |
| Intended audience | Project maintainers, systems engineers, architects, implementation teams, verification and validation engineers, benchmark engineers, clinical engineering reviewers, integrators and downstream product teams |

### Revision history

| Version | Date | Summary |
|---|---:|---|
| 0.1 | 2026-08-02 | Initial strategy defining validation levels, evidence classes, dataset governance, tolerance management, CPU–Metal differential testing, cross-device validation, benchmark methodology, milestone gates and release evidence. |

### Approval record

This version is a draft for technical and quality review. Formal approval roles, signatories, repository commit and release association shall be added when project governance is established.

---

## 1. Purpose

This document defines how Voxelia shall demonstrate:

- functional correctness;
- numerical correctness;
- spatial correctness;
- deterministic behaviour where required;
- diagnostic presentation fidelity;
- geometry and topology correctness;
- concurrency and cancellation safety;
- compressed-data integrity;
- cross-backend equivalence;
- cross-device consistency;
- performance;
- memory efficiency;
- responsiveness;
- scalability;
- robustness; and
- release readiness.

It establishes the common validation and benchmark framework that shall be applied across Voxelia modules and milestones.

The strategy is intended to prevent three recurring engineering failures:

1. treating a visually plausible output as proof of numerical correctness;
2. reporting performance results for unvalidated output; and
3. accepting a GPU optimisation without proving that its behaviour remains within the authorised diagnostic or scientific error budget.

This document does not define every algorithm-specific tolerance or test vector. Those shall be supplied by lower-level algorithm, shader, integration and milestone validation specifications derived from this strategy.

---

## 2. Authority and precedence

The **Voxelia Project Foundation v0.1.1** establishes the project’s quality, validation and performance principles.

The **Voxelia Master Technical Architecture v0.1.1** establishes the validation module, test levels, comparison classes, cross-device matrix, benchmark harness and architecture verification plan.

The **Voxelia Requirements Baseline v0.1.1** establishes the normative requirements to be verified.

Where this strategy conflicts with the Project Foundation, the Foundation takes precedence. Where it conflicts with the Requirements Baseline or Master Technical Architecture, the discrepancy shall be resolved through requirements review, architecture revision or an approved Architecture Decision Record.

No benchmark result shall be used to justify behaviour that violates a P0 correctness, diagnostic, security, traceability or architecture-integrity requirement.

---

## 3. Strategy objectives

The Voxelia validation and benchmark programme shall:

1. produce objective evidence for each implemented P0 requirement;
2. provide reusable test and report infrastructure rather than one-off demonstrations;
3. validate operation semantics independently from backend implementation;
4. maintain independent CPU, analytical or approved external references for diagnostic Metal kernels;
5. define explicit comparison and tolerance classes;
6. validate data geometry and physical-space behaviour, not only pixel output;
7. validate cross-Apple-platform and cross-device behaviour by capability class;
8. verify that compressed and bricked storage preserves authoritative values;
9. detect stale-result publication, race conditions and unsafe cancellation;
10. quantify Apple Silicon unified-memory, resource-residency and copy behaviour;
11. measure performance under cold, warm, steady-state, pressured and contended conditions;
12. preserve complete environment and implementation provenance for every report;
13. make benchmark results reproducible;
14. prevent unsuitable golden images from becoming the sole authority for quantitative behaviour;
15. create milestone acceptance packages suitable for downstream regulated-product evidence; and
16. publish clear limitations where complete equivalence or coverage has not yet been demonstrated.

---

## 4. Scope

### 4.1 Included

This strategy applies to:

- `VoxeliaSpatial`;
- `VoxeliaCore`;
- `VoxeliaStorage`;
- `VoxeliaExecution`;
- `VoxeliaImaging`;
- `VoxeliaGeometry`;
- `VoxeliaRendering`;
- `VoxeliaInteraction`;
- `VoxeliaCPU`;
- `VoxeliaMetal`;
- `VoxeliaCompression`;
- `VoxeliaDICOMKit`;
- `VoxeliaSegmentation`;
- `VoxeliaRegistration`;
- `VoxeliaPhotorealisticRendering`;
- `VoxeliaHeadless`;
- `VoxeliaDistributed`;
- optional Apple-framework adapters;
- VTK and ITK interoperability used for comparison;
- public APIs;
- Metal kernels and shader libraries;
- cache and serialised formats;
- supported Apple platforms;
- example applications where they demonstrate normative behaviour; and
- release artefacts.

### 4.2 Excluded

This strategy does not validate:

- downstream product workflow;
- PACS or VNA services;
- reporting;
- hanging protocols;
- user authentication;
- hospital authorisation policy;
- browser user-interface implementation;
- render-farm scheduling services;
- peer discovery or enrolment;
- hospital network security;
- downstream clinical claims; or
- regulatory approval of a host product.

A downstream product shall create its own product-level verification and validation plan that incorporates the relevant Voxelia evidence.

---

## 5. Validation principles

### 5.1 Correctness before performance

A performance result is acceptable only when the associated output has passed the relevant correctness criteria.

A faster result that is incorrect, spatially misregistered, non-deterministic outside the authorised policy or produced using undocumented approximation shall be recorded as a failed implementation, not as a benchmark improvement.

### 5.2 Authoritative data before presentation data

Quantitative validation shall use authoritative values and geometry.

Presentation buffers, screenshots, reduced-resolution interactive frames and photorealistic images shall not be used as the sole source for validating:

- voxel values;
- measurements;
- segmentation statistics;
- registration transforms;
- geometric distances;
- surface topology; or
- codec losslessness.

### 5.3 Independent reference

Every diagnostic Metal kernel shall have at least one of:

- an independent CPU reference implementation;
- an analytical oracle; or
- a formally approved external reference implementation.

The reference shall not merely call the same kernel through a different wrapper.

### 5.4 Explicit tolerances

Every non-exact comparison shall state:

- the measured quantity;
- units;
- absolute tolerance;
- relative tolerance where applicable;
- spatial tolerance where applicable;
- aggregation method;
- treatment of invalid or padded values;
- permitted outlier count;
- rationale; and
- approving reviewer.

### 5.5 Reproducibility

Every validation or benchmark run shall capture enough information to recreate:

- source input;
- operation graph;
- parameters;
- implementation;
- compiled shader identity;
- hardware class;
- operating system;
- toolchain;
- cache state;
- quality policy; and
- result comparison.

### 5.6 No silent substitutions

A missing capability, resource failure or unsupported diagnostic implementation shall fail explicitly. Test infrastructure shall verify that an unvalidated preview path is not silently substituted for a diagnostic request.

### 5.7 Capability-class coverage

Validation shall be organised by capability class rather than only by individual commercial device name. Device names may be recorded in evidence, but the validated claim shall identify the hardware capabilities on which it depends.

### 5.8 Evidence proportionality

The strength of evidence shall be proportional to:

- clinical or scientific impact;
- algorithm complexity;
- numerical sensitivity;
- concurrency risk;
- memory-safety exposure;
- stochastic behaviour;
- use of approximation;
- platform variation; and
- distribution across machines.

---

## 6. Terminology

| Term | Meaning |
|---|---|
| Acceptance criterion | A measurable condition that an implementation or milestone must satisfy |
| Analytical oracle | A closed-form or mathematically derived expected result |
| Authoritative result | A result produced from validated source data and operation semantics, independent of presentation approximations |
| Benchmark baseline | An approved reference distribution of performance measurements |
| Capability class | A group of devices sharing relevant compute, memory, Metal and platform capabilities |
| Comparison class | The type of equivalence being evaluated, such as exact, bounded numerical, spatial, topological, perceptual or statistical |
| Differential test | A test that executes equivalent semantics through independent implementations and compares outputs |
| Golden data | Controlled expected output, metadata and provenance used for repeatable comparison |
| Kernel validation | Validation of one implementation of an operation |
| Operation validation | Validation of complete public operation semantics over its supported domain |
| Phantom | A synthetic dataset with analytically or procedurally known properties |
| Reference implementation | A deliberately independent implementation prioritising clarity and traceability |
| Repetition | One complete measurement execution within a benchmark run |
| Run | A controlled set of repetitions under one captured environment and scenario |
| Statistical equivalence | Equivalence assessed over distributions or convergence behaviour rather than per-sample identity |
| Tolerance profile | A versioned collection of authorised comparison thresholds |
| Validation package | The complete set of manifests, inputs, results, comparisons, logs, provenance and approval records for a claim |

---

## 7. Evidence hierarchy

Evidence strength shall generally increase in the following order:

1. informal demonstration;
2. source inspection;
3. static analysis;
4. unit test;
5. property-based test;
6. analytical comparison;
7. independent reference comparison;
8. integration test;
9. cross-device or cross-Apple-platform validation;
10. stress or fault-injection test;
11. system-reference workflow validation;
12. reviewed milestone validation package.

A demonstration alone is not sufficient evidence for a P0 numerical or diagnostic requirement unless the requirement explicitly concerns demonstrability rather than correctness.

---

## 8. Validation levels

`VoxeliaValidation` shall support the following levels.

| Level | Purpose | Typical subjects |
|---|---|---|
| Unit | Verify small value types and local invariants | Shapes, extents, bounds, transforms, identifiers, errors |
| Kernel | Verify one implementation against an oracle or reference | CPU SIMD kernel, Metal resampler, histogram reduction |
| Operation | Verify public semantics across supported domains | Resampling, windowing, MPR, registration |
| Pipeline | Verify composed processing and rendering stages | DICOM values → MPR → presentation → overlays |
| Integration | Verify external adapters and platform boundaries | DICOMKit, codecs, RealityKit, headless media |
| System reference | Verify an end-to-end representative workflow | First DICOM CT vertical slice |
| Cross-device | Verify consistency across capability classes | CPU–GPU equivalence, rendering, residency |
| Stress and robustness | Verify behaviour under pressure or malformed input | Memory pressure, cancellation storms, corrupt codestreams |
| Release regression | Verify that an approved release does not regress | Full supported matrix and published baselines |

Each test shall identify its validation level.

---

## 9. Verification methods

The Requirements Baseline defines the following methods:

| Code | Method | Strategy use |
|---|---|---|
| `I` | Inspection | Source, package graph, manifest, API, documentation and configuration review |
| `A` | Analysis | Mathematical proof, numerical analysis, memory analysis, security analysis and architectural reasoning |
| `T` | Test | Automated or controlled comparison against an acceptance criterion |
| `D` | Demonstration | Reproducible use in a representative application, device or service |
| `R` | Review | Formal review and approval of evidence, provenance, design or process records |

A requirement with multiple methods shall not be considered verified until every mandated method has acceptable evidence.

---

## 10. Comparison classes

### 10.1 Exact byte equality

Use for:

- lossless codec round trips;
- serialisation where canonical bytes are required;
- immutable cache integrity;
- checksums;
- identity-critical binary output.

Acceptance requires equal length and equal byte sequence.

### 10.2 Exact numeric equality

Use where deterministic arithmetic and data type permit exact equality.

Examples include:

- integer transforms without overflow;
- nearest-neighbour sampling;
- label copying;
- index arithmetic;
- mask logic.

Floating-point exact equality shall be used only when justified.

### 10.3 Bounded numerical equality

Use for floating-point processing, interpolation, transforms, reductions and rendering intermediates.

The comparison shall define:

- absolute error;
- relative error;
- ULP error where useful;
- mean error;
- root-mean-square error;
- percentile error;
- maximum error;
- permitted exceptional values; and
- invalid-value handling.

### 10.4 Spatial equality

Use for:

- physical coordinates;
- plane intersections;
- MPR geometry;
- measurement points;
- registration transforms;
- surface vertices;
- picking.

The comparison shall use physical units, normally millimetres for medical data.

### 10.5 Topology equivalence

Use for:

- connected components;
- segmentation regions;
- mesh extraction;
- surface processing.

Possible measures include:

- connected-component count;
- Euler characteristic;
- boundary count;
- genus;
- manifold status;
- label adjacency;
- edge consistency; and
- self-intersection count.

### 10.6 Segmentation agreement

Possible measures include:

- Dice coefficient;
- Jaccard index;
- Hausdorff distance;
- percentile Hausdorff distance;
- average symmetric surface distance;
- volume difference;
- sensitivity;
- specificity; and
- label-confusion matrix.

The selected measure shall match the operation’s intended semantics.

### 10.7 Perceptual image comparison

Perceptual measures may be used for display or rendering regression where exact pixel equality is inappropriate.

They shall not be the sole acceptance criterion for quantitative operations.

Possible measures include:

- structural similarity;
- perceptual colour difference;
- edge preservation;
- region-of-interest comparison;
- feature-specific detectability; and
- expert visual review.

### 10.8 Diagnostic feature preservation

Use where rendering or optimisation could suppress clinically significant structures.

The test shall define the feature before execution, such as:

- thin vessel;
- calcification;
- low-contrast lesion;
- device wire;
- cortical bone boundary;
- segmentation boundary;
- small high-density object; or
- specified intensity range.

The feature shall be measured in authoritative source data and evaluated in the rendered result using a documented criterion.

### 10.9 Statistical equivalence

Use for:

- stochastic Photorealistic Rendering;
- Monte Carlo accumulation;
- non-deterministic scheduling with deterministic semantics;
- distributed sample merging.

The comparison shall define:

- random seed policy;
- sample count;
- confidence level;
- expected mean;
- expected variance;
- convergence metric; and
- acceptable distributional difference.

### 10.10 Performance-only acceptance

A performance-only test may demonstrate speed, throughput, memory or energy but shall not provide correctness evidence unless paired with an applicable comparison test.

---

## 11. Tolerance governance

### 11.1 Tolerance ownership

Each operation family shall have a versioned tolerance specification owned by its module maintainer and reviewed by validation engineering.

### 11.2 Tolerance sources

Tolerances may be derived from:

- exact mathematical limits;
- scalar-format quantisation;
- condition-number analysis;
- floating-point error propagation;
- interpolation theory;
- clinical or scientific requirements;
- independent reference distributions;
- platform variation studies; and
- established standards or published methods.

### 11.3 Prohibited tolerance selection

Tolerances shall not be selected solely because they allow a current implementation to pass.

### 11.4 Tolerance profiles

Initial profiles shall include:

- `reference`;
- `diagnostic`;
- `interactive`;
- `preview`; and
- `cross-device`.

A profile may contain operation-specific limits. Profiles shall be versioned independently from the operation.

### 11.5 Boundary and special-value policy

Every numeric test shall define treatment of:

- NaN;
- positive and negative infinity;
- signed zero;
- integer overflow;
- denormal values;
- out-of-range input;
- missing data;
- padded pixels;
- empty regions;
- singular transforms; and
- zero-width or degenerate geometry.

### 11.6 Tolerance changes

Changing a tolerance requires:

- rationale;
- impact analysis;
- comparison against existing evidence;
- review approval;
- updated version; and
- re-execution of affected validation packages.

A tolerance shall not be relaxed silently.

---

## 12. Reference implementations and analytical oracles

### 12.1 Reference implementation properties

A reference implementation should be:

- independent from the optimised implementation;
- straightforward to inspect;
- deterministic where required;
- numerically explicit;
- free from hidden approximations;
- suitable for small and medium test data;
- instrumented for intermediate-state comparison; and
- versioned.

### 12.2 Analytical oracles

Analytical oracles shall be preferred where practical.

Examples include:

- identity transforms;
- constant and linear scalar fields;
- impulse responses;
- known Gaussian functions;
- geometric planes, spheres and cylinders;
- known line lengths and angles;
- affine transform compositions;
- analytic ray–box intersections;
- homogeneous-volume rendering;
- known histogram distributions; and
- deterministic synthetic registration pairs.

### 12.3 External references

VTK, ITK or other established implementations may be used as comparison references where:

- the exact algorithm and version are documented;
- input and spatial conventions are reconciled explicitly;
- output differences are analysed;
- the external implementation is not treated as infallible; and
- Voxelia retains an independent acceptance rationale.

### 12.4 Reference limits

A reference implementation that shares the same source code, generated shader or lookup tables as the candidate implementation shall not be considered independent without additional analysis.

---

## 13. Dataset governance

### 13.1 Dataset classes

Validation data shall be classified as:

1. analytical phantom;
2. procedural synthetic dataset;
3. generated geometry;
4. public scientific dataset;
5. public medical imaging dataset;
6. de-identified internal dataset;
7. adversarial or malformed dataset;
8. benchmark-only dataset; or
9. confidential downstream-product dataset.

### 13.2 Dataset requirements

Every controlled dataset shall have:

- stable identifier;
- version;
- description;
- source;
- licence or usage permission;
- confidentiality classification;
- checksum;
- format;
- dimensions;
- scalar and component types;
- spatial geometry;
- modality or semantic class;
- expected special cases;
- permitted redistribution;
- retention policy; and
- owning maintainer.

### 13.3 Patient information

Public Voxelia repositories and validation packages shall not contain patient-identifying information.

Medical datasets shall be:

- demonstrably de-identified;
- licensed or authorised for the intended use;
- reviewed before publication; and
- stored with their provenance and de-identification status.

### 13.4 Dataset immutability

A published dataset version shall be immutable. Changes require a new version and checksum.

### 13.5 Dataset representativeness

The catalogue shall include variation in:

- dimensions;
- anisotropy;
- orientation;
- signedness;
- scalar width;
- intensity range;
- noise;
- missing data;
- irregular geometry;
- segmentation overlap;
- mesh complexity;
- compression ratio;
- brick access pattern;
- temporal dimensions; and
- memory footprint.

---

## 14. Dataset manifest

A machine-readable dataset manifest shall accompany each controlled dataset.

Recommended location:

```text
Validation/Datasets/<dataset-id>/dataset.yaml
```

Minimum fields:

```yaml
schema_version: "1.0"
dataset_id: "voxelia.phantom.ramp3d"
version: "1.0.0"
title: "Three-dimensional linear ramp phantom"
class: "analytical_phantom"
description: "Scalar value equals 2x + 3y - z + 100."
source:
  organisation: "Voxelia Project"
  uri: null
licence: "MIT"
confidentiality: "public"
redistribution: true
files:
  - path: "ramp-128x96x64-int16.raw"
    sha256: "<digest>"
format:
  container: "raw"
  scalar_format: "int16"
  components: 1
shape: [128, 96, 64]
spatial_geometry:
  coordinate_system: "world"
  spacing: [0.7, 0.8, 1.5]
  origin: [-20.0, 10.0, 5.0]
  direction:
    - [1.0, 0.0, 0.0]
    - [0.0, 1.0, 0.0]
    - [0.0, 0.0, 1.0]
expected_properties:
  formula: "2*x + 3*y - z + 100"
  minimum: 37
  maximum: 573
maintainer: "Voxelia Validation"
```

The exact schema shall be versioned and validated automatically.

---

## 15. Synthetic phantom programme

### 15.1 Purpose

Synthetic phantoms shall provide known truth for geometry, intensity, interpolation, measurement and rendering.

### 15.2 Foundational phantoms

The initial catalogue should include:

- constant scalar field;
- linear ramp;
- multi-axis ramp;
- impulse;
- checkerboard;
- step edge;
- sphere;
- ellipsoid;
- cylinder;
- hollow shell;
- thin line;
- thin plate;
- multiple labelled objects;
- overlapping segment masks;
- vector field with known divergence;
- affine transform grid;
- anisotropic volume;
- rotated volume;
- irregular frame stack;
- missing-slice stack;
- duplicate-slice stack;
- gantry-tilt-like oblique stack;
- known histogram distribution;
- low-contrast object field;
- high-density micro-object field; and
- temporal moving object.

### 15.3 Phantom generator requirements

A phantom generator shall record:

- generator version;
- random seed where used;
- exact formula;
- spatial geometry;
- scalar quantisation;
- expected measurements;
- expected topology; and
- checksum.

### 15.4 Rendering phantoms

Rendering validation shall include phantoms that isolate:

- ray setup;
- volume bounds;
- interpolation;
- opacity accumulation;
- sample-spacing correction;
- gradient direction;
- lighting;
- clipping;
- transfer functions;
- empty-space skipping;
- brick boundaries;
- multi-volume fusion; and
- feature preservation.

---

## 16. Golden data and expected results

### 16.1 Golden package

A golden package shall include:

- input dataset manifest;
- expected-result manifest;
- expected output;
- generator implementation and version;
- operation and parameters;
- quality profile;
- reference environment;
- checksum;
- comparison class;
- tolerance profile;
- expected provenance; and
- reviewer approval.

### 16.2 Golden image limitations

A golden image shall not be the sole evidence for:

- scalar conversion;
- modality transformation;
- MPR geometry;
- measurements;
- registration;
- segmentation statistics;
- codec losslessness;
- geometry extraction; or
- distributed reduction.

### 16.3 Golden update process

Updating a golden result requires:

1. a documented reason;
2. comparison with the previous golden result;
3. confirmation that a defect is not being normalised;
4. updated checksums and provenance;
5. review approval; and
6. re-execution of affected tests.

---

## 17. Test-data confidentiality and storage

Validation assets shall be stored according to classification.

| Classification | Permitted location |
|---|---|
| Public | Public repository or public object store |
| Restricted redistributable | Controlled project storage with access terms |
| De-identified internal | Approved internal storage |
| Confidential downstream | Downstream product-controlled environment |
| Adversarial input | Public or controlled storage according to origin and licence |

Large assets should be content-addressed and referenced by manifests rather than committed directly where repository size would become unreasonable.

---

## 18. CPU–Metal differential validation

### 18.1 Applicability

Differential testing shall be mandatory for diagnostic Metal kernels unless an approved analytical or independent external oracle is stronger.

### 18.2 Test dimensions

The matrix shall include:

- smallest valid input;
- degenerate dimensions;
- odd and even dimensions;
- non-power-of-two dimensions;
- large dimensions;
- signed and unsigned values;
- floating-point values where supported;
- extreme scalar ranges;
- anisotropic spacing;
- rotated geometry;
- boundary samples;
- out-of-bounds requests;
- empty regions;
- cancellation; and
- repeated execution.

### 18.3 Intermediate comparison

Where final-output comparison is insufficient, the test shall compare intermediate stages such as:

- transformed coordinates;
- interpolation weights;
- partial reductions;
- gradients;
- opacity accumulation;
- ray entry and exit;
- brick selection;
- histogram bins; and
- transfer-function samples.

### 18.4 Backend provenance

The report shall record:

- CPU implementation ID and version;
- Metal implementation ID and version;
- shader source fingerprint;
- compiled library fingerprint;
- device capability class;
- scalar format;
- precision mode;
- threadgroup configuration; and
- compiler options that affect floating-point behaviour.

### 18.5 Differential failure analysis

A failure shall classify the cause as one or more of:

- semantic mismatch;
- coordinate-convention mismatch;
- boundary-policy mismatch;
- precision loss;
- order-of-operations difference;
- race;
- stale data;
- shader compiler variation;
- device-specific defect;
- test-oracle defect; or
- authorised approximation exceeding or remaining within profile limits.

---

## 19. cross-Apple-platform and cross-device validation

### 19.1 Platform matrix

The supported platform matrix shall include:

- macOS;
- iOS;
- iPadOS;
- visionOS; and
- tvOS.

Not every platform requires every optional capability, but the supported module matrix shall be explicit.

### 19.2 Capability classes

The initial validation classes shall be:

| Class | Representative purpose |
|---|---|
| `A-MOBILE` | iPhone-class Apple GPU and constrained thermal envelope |
| `A-TABLET` | iPad-class GPU and larger mobile memory envelope |
| `A-SPATIAL` | visionOS spatial-computing device |
| `A-TV` | tvOS device for display and lightweight rendering |
| `A-WORKSTATION` | Apple Silicon Mac used for interactive diagnostic workstation workloads |
| `A-WORKER` | High-memory Apple Silicon Mac used for headless or distributed rendering |

Specific reference devices shall be recorded separately and may change without changing the class.

### 19.3 Cross-device claims

A validation claim shall state whether it applies to:

- one exact device;
- one capability class;
- multiple capability classes; or
- all supported classes.

### 19.4 Cross-device comparisons

Cross-device tests shall evaluate:

- numerical differences;
- rendered image differences;
- resource-limit behaviour;
- quality fallback;
- deterministic reference output;
- shader compatibility;
- memory pressure;
- thermal stability; and
- cancellation behaviour.

### 19.5 Operating-system updates

Major operating-system or GPU-driver changes shall trigger targeted revalidation of:

- shader output;
- resource allocation;
- sparse-resource behaviour;
- synchronisation;
- colour management;
- headless rendering; and
- performance baselines.

---

## 20. Shader and Metal library validation

### 20.1 Shader identity

Every validated shader family shall have:

- stable family identifier;
- semantic version;
- source checksum;
- generated-code checksum where applicable;
- compilation options;
- target platform;
- compiled library fingerprint; and
- associated operation implementations.

### 20.2 Shader review

Diagnostic shaders shall receive review for:

- bounds safety;
- texture-coordinate conventions;
- scalar conversion;
- sampler selection;
- precision qualifiers;
- threadgroup assumptions;
- barriers;
- atomics;
- race conditions;
- out-of-range transfer-function access;
- loop termination;
- cancellation or generation checks where applicable; and
- handling of invalid data.

### 20.3 Compiler variation

Where the same shader source produces materially different output across toolchains or operating-system releases, the validation record shall identify the affected environments and either:

- approve a bounded difference;
- select a different implementation; or
- mark the environment unsupported for that diagnostic path.

### 20.4 Pipeline-state validation

Pipeline creation shall be tested for:

- supported formats;
- unsupported formats;
- invalid function names;
- missing resources;
- function constants;
- render target formats;
- depth formats; and
- shader-library mismatch.

---

## 21. Unified-memory and copy-efficiency validation

### 21.1 Purpose

The validation programme shall demonstrate that Voxelia exploits Apple Silicon unified memory without assuming that shared storage is always optimal.

### 21.2 Copy accounting

Tests shall account for:

- source read;
- decode destination;
- CPU processing copy;
- staging copy;
- buffer-to-texture copy;
- private-resource migration;
- cache duplication;
- brick overlap; and
- output readback.

### 21.3 Evidence

Evidence shall include, where available:

- allocation traces;
- Metal System Trace;
- signposts;
- resource-storage modes;
- residency transitions;
- bytes copied;
- peak resident memory;
- decoded working set;
- compressed cache size;
- GPU working set; and
- time spent copying.

### 21.4 Acceptance

The first vertical slice shall demonstrate that steady-state rendering does not retain an unnecessary complete CPU-to-GPU duplicate of the source volume.

Large-volume milestones shall demonstrate bounded:

- compressed cache;
- decoded-brick cache;
- GPU-resident brick set; and
- scratch-resource budget.

### 21.5 Shared versus private comparison

Representative operations shall compare shared and private resource strategies for:

- latency;
- throughput;
- memory footprint;
- CPU access;
- GPU sampling;
- upload cost;
- energy; and
- thermal behaviour.

The selected default shall be evidence-based and may vary by operation and capability class.

---

## 22. Storage, bricking and residency validation

### 22.1 Storage implementations

Each storage implementation shall be validated for:

- region bounds;
- stride correctness;
- lifetime ownership;
- mutability semantics;
- concurrency;
- cancellation;
- integrity;
- partial reads;
- empty regions;
- overflow; and
- error propagation.

### 22.2 Brick correctness

Brick tests shall verify:

- mapping from brick coordinate to voxel region;
- boundary-brick dimensions;
- halo or overlap;
- multi-resolution geometry;
- checksums;
- decompression;
- eviction;
- reloading;
- concurrency deduplication; and
- stale-generation rejection.

### 22.3 Seam testing

Rendering and processing shall be tested across brick boundaries using:

- ramps;
- gradients;
- edges;
- surfaces;
- label boundaries;
- transfer-function transitions; and
- anisotropic data.

No visible or numeric seam outside the authorised tolerance shall be accepted.

### 22.4 Memory-pressure testing

Memory-pressure scenarios shall include:

- controlled reduction of cache budget;
- rapid viewport movement;
- simultaneous MPR and volume rendering;
- background cache generation;
- cancellation during decode;
- eviction during progressive rendering; and
- recovery after pressure is relieved.

### 22.5 Sparse-resource validation

Sparse-resource paths shall verify:

- mapping and unmapping;
- absent-page behaviour;
- fallback to lower resolution;
- residency synchronisation;
- error recovery; and
- equivalence with bricked fallback.

---

## 23. Codec, JP3D and HTJ2K validation

### 23.1 Codec reuse

Voxelia shall validate integration with the approved Raster-Lab codec implementation rather than revalidate the entire codec standard independently where that library already owns conformance.

Voxelia remains responsible for validating:

- adapter parameter mapping;
- destination layout;
- dimension and stride handling;
- cancellation;
- partial decode;
- error propagation;
- storage identity;
- cache metadata; and
- downstream equality.

### 23.2 Lossless equality

Lossless codec tests shall require exact byte or exact scalar equality after decode, subject only to explicitly documented container normalisation that does not alter sample values.

### 23.3 JP3D tests

JP3D evaluation shall include:

- complete-volume round trip;
- independent brick round trip;
- partial-resolution decode;
- three-dimensional region-of-interest decode;
- random brick access;
- parallel decode;
- cancellation;
- malformed codestream;
- truncated codestream;
- checksum failure;
- memory budget; and
- interoperability status.

### 23.4 HTJ2K tests

HTJ2K evaluation shall include:

- lossless equality;
- encode throughput;
- decode throughput;
- multi-threaded scaling;
- Metal-assisted paths where available;
- random access;
- small and large frame behaviour;
- high bit-depth data;
- signed-data mapping where supported; and
- malformed input.

### 23.5 Codec benchmarks

Codec benchmark reports shall include:

- input size;
- compressed size;
- compression ratio;
- encode latency;
- decode latency;
- throughput;
- peak memory;
- destination storage type;
- region-of-interest cost;
- partial-resolution cost;
- cancellation latency;
- equality status; and
- energy where practical.

### 23.6 DICOM boundary

Tests shall verify that toolkit-native JP3D cache representations:

- preserve original DICOM source identity;
- remain distinct from standard DICOM transfer syntaxes;
- cannot be accidentally exported as a standard DICOM transfer syntax; and
- carry sufficient metadata to reconstruct the canonical Voxelia volume.

---

## 24. DICOMKit integration and geometry validation

### 24.1 Responsibility boundary

DICOMKit owns DICOM parsing and dataset semantics. Voxelia validation shall focus on correct translation into Voxelia’s canonical model.

### 24.2 Series assembly cases

The test catalogue shall include:

- normal axial CT series;
- descending acquisition order;
- non-sequential instance numbers;
- duplicate instance number with distinct geometry;
- missing slice;
- duplicate slice;
- inconsistent orientation;
- inconsistent spacing;
- non-uniform spacing;
- oblique stack;
- gantry-tilt-like geometry;
- mixed frame of reference;
- incompatible dimensions;
- signed and unsigned pixel representation;
- MONOCHROME1;
- MONOCHROME2;
- pixel padding;
- rescale slope and intercept; and
- malformed metadata.

### 24.3 Geometry acceptance

For a regular volume, tests shall verify:

- frame ordering by physical projection;
- voxel-centre convention;
- index-to-patient transform;
- patient-to-index inverse;
- slice spacing;
- row and column spacing;
- orientation;
- origin;
- bounds;
- crosshair mapping; and
- physical measurements.

### 24.4 Irregular geometry

Irregular data shall be validated as an irregular frame set unless an explicit resampling operation creates a regular volume.

Tests shall fail if the adapter silently represents irregular data using an incorrect regular affine geometry.

### 24.5 Value transformation

Tests shall distinguish:

- stored value;
- modality-transformed value;
- displayed value;
- padded value; and
- colour or palette value.

### 24.6 Provenance

Derived Voxelia data shall be traceable to source SOP Instance and frame identities without exposing patient identifiers by default.

---

## 25. Core data, spatial and transform validation

### 25.1 Shapes and extents

Tests shall cover:

- valid dynamic rank;
- zero and negative extents;
- integer overflow;
- maximum practical extents;
- rank mismatch; and
- element-count calculation.

### 25.2 Regions and views

Tests shall cover:

- valid subregions;
- out-of-bounds regions;
- empty regions;
- slices;
- components;
- temporal views;
- view lifetime;
- geometry derivation; and
- zero-copy behaviour where promised.

### 25.3 Affine transforms

Tests shall cover:

- identity;
- translation;
- scale;
- rotation;
- reflection where permitted;
- composition;
- inversion;
- singular transform;
- near-singular transform;
- point transformation;
- vector transformation;
- normal transformation; and
- round trip.

### 25.4 Coordinate conventions

Tests shall make axis and handedness conventions explicit and shall detect accidental DICOM LPS/RAS or image/display convention reversal.

### 25.5 Precision

Authoritative transform and measurement tests shall use double precision. Float-derived rendering transforms shall be compared against double-precision results over representative field-of-view sizes.

---

## 26. Image-processing validation

### 26.1 Scalar conversion

Tests shall cover:

- widening;
- narrowing;
- signed-to-unsigned;
- unsigned-to-signed;
- integer-to-float;
- float-to-integer;
- clipping;
- rounding modes;
- overflow; and
- special floating-point values.

### 26.2 Interpolation

Nearest-neighbour and linear interpolation shall be validated using:

- constant fields;
- linear ramps;
- impulses;
- edges;
- anisotropic geometry;
- rotated geometry;
- boundary samples; and
- out-of-bounds policies.

Cubic interpolation, when introduced, shall document and validate its exact kernel.

### 26.3 Resampling

Resampling tests shall verify:

- destination geometry;
- coordinate mapping;
- interpolation;
- boundary handling;
- scalar conversion;
- padding;
- mask behaviour;
- label-map nearest-neighbour default; and
- CPU–Metal equivalence.

### 26.4 Histograms

Histogram tests shall cover:

- exact bin populations;
- signed values;
- floating-point ranges;
- empty data;
- padded values;
- large counts;
- parallel reduction; and
- deterministic reference output.

### 26.5 Filtering and morphology

Convolution, Gaussian filtering, erosion, dilation and distance transforms shall be tested using analytical or procedural phantoms with explicit boundary conditions.

---

## 27. Diagnostic two-dimensional presentation validation

### 27.1 Presentation chain

The validation shall independently test:

1. stored-value interpretation;
2. modality transformation;
3. VOI or windowing;
4. presentation inversion;
5. palette or colour transformation;
6. overlays;
7. shutters or masks where supported;
8. output colour transformation; and
9. final compositing.

### 27.2 Windowing

Window centre and width tests shall include:

- integer and half-integer centre;
- narrow and wide windows;
- negative values;
- values below and above range;
- width edge cases;
- MONOCHROME1 inversion; and
- CPU–Metal equality.

### 27.3 Pixel inspection

The host-visible pixel inspection result shall be tested to ensure that it reports authoritative stored and transformed values rather than display pixels.

### 27.4 Interpolation policy

Display tests shall verify:

- nearest neighbour;
- linear;
- no interpolation where meaningful; and
- consistency between interactive and off-screen output.

### 27.5 Colour

Colour and palette tests shall include:

- channel order;
- colour space;
- alpha;
- premultiplication;
- palette boundaries;
- output transfer function; and
- SDR/HDR descriptor behaviour where supported.

---

## 28. MPR, projection and measurement validation

### 28.1 Orthogonal MPR

Axial, coronal and sagittal MPR shall be validated against analytical ramp and geometric phantoms.

### 28.2 Oblique MPR

Oblique planes shall be tested for:

- plane origin;
- axes;
- pixel spacing;
- orientation;
- field of view;
- source intersection;
- boundary handling; and
- interpolation.

### 28.3 Thick-slab projection

MIP, MinIP and AIP shall be validated using volumes with known slab distributions.

Tests shall define:

- slab thickness;
- sample spacing;
- inclusion rules;
- missing-data handling;
- padding handling; and
- aggregation precision.

### 28.4 Crosshair

Linked-view tests shall verify that one physical crosshair point maps consistently into every compatible viewport.

### 28.5 Measurements

Distance, angle, area and volume tests shall use phantoms with known physical dimensions.

Measurement acceptance shall use physical-space tolerance, not screen-pixel tolerance.

### 28.6 Curved planar reconstruction

When introduced, CPR validation shall include:

- known centreline;
- straight and curved phantoms;
- mapping back to source coordinates;
- cross-sectional orientation;
- arc length; and
- slab behaviour.

---

## 29. Segmentation validation

### 29.1 Representation

Tests shall verify:

- binary masks;
- mutually exclusive labels;
- overlapping segments;
- stable segment identifiers;
- colour and metadata;
- source geometry;
- frame of reference; and
- provenance.

### 29.2 Resampling

Segmentation resampling shall default to nearest neighbour and shall be tested for label preservation and absence of invented labels.

### 29.3 Operations

Thresholding, connected components, morphology and region growing shall be validated using known synthetic objects and noise patterns.

### 29.4 Statistics

Segment statistics shall be checked against authoritative voxel sets for:

- count;
- physical volume;
- minimum;
- maximum;
- mean;
- standard deviation; and
- source-value transformation.

### 29.5 Agreement measures

Where Voxelia is compared with an independent segmentation implementation, the report shall select appropriate Dice, Jaccard and surface-distance measures rather than relying on visual similarity alone.

---

## 30. Registration validation

### 30.1 Synthetic transform tests

Registration shall be validated using image pairs generated by known:

- translation;
- rotation;
- scale;
- shear;
- rigid transform;
- affine transform; and
- deformation field where supported.

### 30.2 Metrics and optimisers

Tests shall record:

- fixed and moving datasets;
- metric;
- optimiser;
- initial transform;
- multi-resolution schedule;
- convergence condition;
- final metric;
- iteration count;
- final transform; and
- failure reason.

### 30.3 Accuracy

Transform accuracy shall be assessed using:

- parameter error;
- landmark target-registration error;
- image similarity;
- inverse-consistency where applicable; and
- resampled-image comparison.

### 30.4 Failure cases

Tests shall include:

- no overlap;
- insufficient texture;
- poor initialisation;
- singular affine solution;
- premature cancellation;
- iteration limit;
- divergent optimiser; and
- incompatible coordinate spaces.

A non-converged registration shall not be reported as successful.

### 30.5 CPU and Metal

Metal-accelerated metrics or resampling shall be compared against reference implementations before use in a diagnostic profile.

---

## 31. Geometry and surface validation

### 31.1 Surface extraction

Marching-cubes-class extraction shall be tested using:

- sphere;
- cylinder;
- plane;
- multiple objects;
- boundary-touching object;
- single-voxel object;
- anisotropic spacing;
- labelled volume; and
- brick boundary.

### 31.2 Geometry measures

Tests shall compare:

- vertex position;
- surface area;
- enclosed volume;
- component count;
- topology;
- normal direction; and
- manifold status.

### 31.3 Mesh operations

Smoothing, decimation, clipping and intersection shall have operation-specific error budgets and topology-preservation criteria.

### 31.4 Picking

Picking shall be tested for:

- primitive identity;
- layer identity;
- physical position;
- source data position;
- depth ordering;
- transparent surfaces; and
- off-screen equivalence.

---

## 32. Conventional volume-rendering validation

### 32.1 Ray geometry

Tests shall verify:

- camera-ray generation;
- volume-bound intersection;
- entry and exit points;
- index-space transformation;
- clipping;
- anisotropic voxels; and
- termination.

### 32.2 Sampling

Tests shall verify:

- sample-spacing selection;
- opacity correction;
- interpolation;
- step-size changes;
- early ray termination;
- empty-space skipping;
- brick transitions; and
- multi-resolution refinement.

### 32.3 Transfer functions

Tests shall include:

- constant opacity;
- linear ramp;
- narrow peaks;
- discontinuities;
- out-of-range values;
- gradient opacity;
- multiple materials; and
- serialisation round trip.

### 32.4 Gradients and lighting

Gradient direction and magnitude shall be tested against analytic scalar fields.

Lighting shall be tested separately from compositing using controlled surfaces and volumes.

### 32.5 Multi-volume rendering

Tests shall verify:

- shared physical sampling;
- independent value transforms;
- independent transfer functions;
- compositing order;
- missing-data policy; and
- registration transforms.

### 32.6 Diagnostic feature preservation

Preservation tests shall include small high-density objects, thin structures and low-contrast features under representative transfer functions and quality profiles.

---

## 33. Photorealistic Rendering validation

### 33.1 Separation from conventional rendering

Photorealistic Rendering shall remain optional and shall consume the same authoritative scene model as conventional rendering.

Tests shall verify that disabling the module does not impair conventional diagnostic rendering.

### 33.2 Deterministic reference mode

Reference mode shall be tested for:

- fixed random seed;
- fixed sample budget or convergence criterion;
- no unrecorded temporal history;
- no implicit denoising;
- identical scene identity;
- complete provenance; and
- repeatability within the declared tolerance.

### 33.3 Convergence

Progressive rendering shall report convergence evidence such as:

- sample count;
- luminance variance;
- per-pixel variance;
- image-difference trend;
- confidence interval; and
- elapsed time.

The report shall show that additional samples converge rather than drift.

### 33.4 Light transport

Separate tests shall isolate:

- absorption;
- emission;
- single scattering;
- multiple scattering;
- volumetric shadow;
- area light;
- environment light;
- phase function;
- transparency;
- transillumination; and
- surface–volume interaction.

### 33.5 Temporal behaviour

Interactive and progressive temporal accumulation shall be tested for:

- camera motion;
- transfer-function change;
- light movement;
- clipping change;
- brick refinement;
- source replacement; and
- viewport resize.

Stale accumulation shall not contaminate the new scene.

### 33.6 Denoising

Any denoiser shall be validated independently for:

- bias;
- edge preservation;
- small-structure preservation;
- temporal stability;
- reproducibility;
- provenance; and
- failure behaviour.

### 33.7 Feature preservation

Photorealistic presets shall be tested against specified features such as:

- calcification;
- thin vessel;
- bone edge;
- implant;
- catheter or wire;
- segmentation boundary; and
- low-contrast structure.

### 33.8 Distributed accumulation

Distributed sample partitions shall be tested for:

- complete coverage;
- no duplicate samples;
- deterministic sample-range identity;
- merge-order independence within tolerance;
- checksum;
- variance merging; and
- failed-partition recovery at the orchestration boundary.

---

## 34. Interaction, cancellation and stale-result validation

### 34.1 Interaction

Tests shall verify:

- window and level;
- pan;
- zoom;
- scroll;
- rotate;
- crosshair;
- picking;
- clipping;
- cropping;
- measurement placement; and
- viewport synchronisation.

### 34.2 Generation handling

Rapidly changing interactive state shall create repeated generations. Tests shall verify that:

- obsolete CPU results are discarded;
- obsolete GPU frames are not presented;
- obsolete brick loads do not replace current data;
- progress belongs to the correct generation; and
- cancellation does not corrupt shared caches.

### 34.3 Cancellation scenarios

Scenarios shall include cancellation during:

- file read;
- DICOM assembly;
- codec decode;
- CPU processing;
- Metal command preparation;
- in-flight GPU work;
- brick loading;
- progressive rendering;
- registration; and
- distributed partition execution.

### 34.4 Responsiveness

Tests shall measure input-to-visible-response latency independently from final-quality convergence.

---

## 35. Concurrency validation

### 35.1 Compile-time checks

All supported targets shall compile with Swift 6 strict concurrency checking.

### 35.2 Runtime tests

Runtime concurrency tests shall include:

- concurrent identical requests;
- concurrent different regions;
- cancellation storms;
- rapid cache eviction;
- actor re-entrancy;
- priority inversion;
- repeated device-context use;
- cross-task storage access;
- progress stream termination;
- task failure; and
- application shutdown.

### 35.3 Unsafe declarations

Every `@unchecked Sendable` declaration shall have:

- documented invariant;
- owner;
- review record;
- stress test; and
- justification for why checked conformance is not available.

### 35.4 Race detection

Available platform race-detection and sanitiser tooling shall be used in development validation where compatible with the tested code path.

---

## 36. Headless and media-output validation

Headless rendering shall be tested for:

- no interactive window dependency;
- deterministic scene setup;
- raw pixel output;
- colour-space metadata;
- alpha semantics;
- HDR/SDR descriptor;
- `CVPixelBuffer` adapter where implemented;
- depth output;
- object-ID output;
- progressive intermediate output;
- cancellation;
- batch throughput;
- memory release; and
- equivalence with interactive presentation semantics.

Media encoding shall be validated separately from core rendering.

---

## 37. Distributed-contract validation

Distributed contract tests shall verify:

- canonical serialisation;
- schema version;
- content identity;
- operation or scene version;
- input checksum;
- capability requirements;
- partition identity;
- deterministic seed;
- result checksum;
- provenance;
- missing partition detection;
- duplicate partition detection;
- incompatible partition rejection;
- merge behaviour;
- cancellation; and
- forward and backward compatibility policy.

Network transport, node identity, authentication and farm scheduling remain outside Voxelia and shall not be represented as validated Voxelia behaviour.

---

## 38. Robustness, fault injection and security testing

### 38.1 Input robustness

Tests shall include:

- invalid dimensions;
- integer overflow;
- extreme strides;
- truncated files;
- corrupt compressed data;
- invalid metadata;
- unsupported scalar type;
- singular transforms;
- malformed serialised jobs;
- invalid checksums;
- missing resources; and
- incompatible versions.

### 38.2 Resource failures

Fault injection shall cover:

- allocation failure;
- GPU resource creation failure;
- shader lookup failure;
- pipeline compilation failure;
- command-buffer failure;
- storage read failure;
- decode failure;
- temporary-file failure;
- cancellation; and
- device capability absence.

### 38.3 Failure acceptance

A robustness test passes only when Voxelia:

- returns a typed error;
- does not access memory unsafely;
- does not publish incomplete data as complete;
- does not leave a corrupt cache entry;
- does not leak sensitive metadata;
- releases resources; and
- remains usable for subsequent valid work where recovery is expected.

### 38.4 Fuzzing

Format adapters, serialisers, parsers and unsafe memory boundaries should be subjected to fuzz testing.

---

## 39. Benchmark philosophy

### 39.1 Purpose

Benchmarks shall guide design, detect regression and characterise supported workloads. They shall not be treated as marketing claims without the corresponding dataset, quality and validation context.

### 39.2 Isolation

The benchmark harness shall run independently of example applications.

### 39.3 Controlled environment

Benchmark runs shall record and, where practical, control:

- power source;
- thermal state;
- background workload;
- display configuration;
- process priority;
- low-power mode;
- memory pressure;
- cache state;
- device temperature;
- operating-system version; and
- build configuration.

### 39.4 Release build

Performance claims shall use optimised release builds unless the purpose is to characterise debug or validation instrumentation overhead.

### 39.5 Correctness gate

A benchmark scenario shall reference a validation result or shall execute an embedded correctness check before its performance result is accepted.

---

## 40. Benchmark harness

The benchmark harness shall record:

- benchmark ID and version;
- scenario ID and version;
- hardware identity;
- capability class;
- total physical memory;
- operating system;
- Swift and compiler version;
- Xcode version where applicable;
- Voxelia commit and version;
- operation semantic version;
- implementation version;
- shader identity;
- input dataset manifest;
- storage form;
- compression;
- brick policy;
- cache state;
- quality profile;
- number of warm-up iterations;
- number of measured repetitions;
- latency distribution;
- throughput;
- frame rate;
- frame-time distribution;
- memory;
- allocations;
- bytes copied;
- brick faults;
- cache hit rate;
- energy where practical;
- thermal observations;
- validation status; and
- raw result location.

The harness shall emit machine-readable results and a human-readable report.

---

## 41. Benchmark modes

Every applicable workload shall define one or more of:

### 41.1 Cold start

Includes first-time initialisation, shader or pipeline setup, initial decode and empty caches.

### 41.2 Warm cache

Required data and pipeline state are cached, but the operation is executed from a clean request.

### 41.3 Steady state

Repeated interactive or batch execution after warm-up.

### 41.4 Memory pressure

Execution under reduced cache and residency budgets.

### 41.5 Interactive cancellation

Rapidly superseded requests with stale-result prevention.

### 41.6 Contention

Multiple concurrent operations competing for CPU, GPU, decoder, cache or memory resources.

### 41.7 Headless batch

Repeated off-screen rendering or processing without an interactive viewport.

### 41.8 Distributed partition and merge

Per-partition execution, transport-neutral serialisation cost and merge cost. Network time may be reported separately by an external system.

### 41.9 Thermal sustained load

A prolonged workload used to assess thermal throttling and stable throughput.

---

## 42. Benchmark metrics

### 42.1 Latency

Report at least:

- minimum;
- median;
- 90th percentile;
- 95th percentile;
- 99th percentile; and
- maximum.

### 42.2 Throughput

Examples include:

- voxels per second;
- pixels per second;
- frames per second;
- bricks per second;
- megabytes decoded per second;
- triangles per second;
- samples per second; and
- studies per hour.

### 42.3 Frame performance

Report:

- average frame rate;
- median frame time;
- 95th and 99th percentile frame time;
- missed-frame count;
- dropped-frame count;
- interaction latency; and
- time to final quality.

### 42.4 Memory

Report:

- peak process resident size;
- peak GPU-associated memory where measurable;
- compressed cache;
- decoded cache;
- GPU-resident bricks;
- scratch allocations;
- allocation count;
- bytes copied; and
- memory after workload completion.

### 42.5 Storage and compression

Report:

- compressed size;
- ratio;
- encode and decode throughput;
- random-access latency;
- partial-resolution latency;
- region-of-interest latency; and
- cache regeneration time.

### 42.6 Energy and thermals

Where practical report:

- average power;
- energy per operation;
- energy per rendered frame;
- thermal state;
- throttling onset; and
- sustained throughput.

---

## 43. Statistical benchmark methodology

### 43.1 Warm-up

Each scenario shall define warm-up criteria rather than relying on a fixed arbitrary count alone.

Warm-up may continue until:

- pipeline state is cached;
- memory allocation stabilises;
- frame time reaches steady distribution; or
- a declared maximum warm-up count is reached.

### 43.2 Repetitions

The number of repetitions shall be sufficient to characterise variance.

Fast microbenchmarks shall use more repetitions than long system scenarios.

### 43.3 Outliers

Outliers shall not be removed unless:

- the removal rule was declared before analysis;
- the raw values remain available;
- the reason is recorded; and
- results are also available without removal where practical.

### 43.4 Confidence

Performance comparisons should report confidence intervals or non-parametric distribution comparisons where variance is material.

### 43.5 Regression decision

A regression shall be judged using:

- magnitude;
- confidence;
- scenario importance;
- correctness impact;
- memory impact;
- energy impact; and
- hardware-class consistency.

A single best-case number shall not determine acceptance.

---

## 44. Reference hardware classes

Specific reference machines shall be recorded in a separate maintained inventory.

The inventory shall include at least:

| Class | Minimum reference coverage |
|---|---|
| `A-MOBILE` | One supported iPhone-class device |
| `A-TABLET` | One supported iPad-class device |
| `A-SPATIAL` | One supported visionOS device |
| `A-TV` | One supported Apple TV device |
| `A-WORKSTATION` | At least one base or mid-range Apple Silicon Mac and one higher-performance Mac |
| `A-WORKER` | One high-memory Apple Silicon Mac suitable for headless sustained workloads |

The inventory shall record:

- model identifier;
- SoC;
- CPU cores;
- GPU cores;
- Neural Engine where relevant;
- physical memory;
- storage;
- operating system;
- display or headless configuration;
- cooling class; and
- acquisition date.

---

## 45. Benchmark workload catalogue

The initial catalogue shall include:

### 45.1 Core and spatial

- transform composition;
- transform inversion;
- region slicing;
- data identity;
- view creation.

### 45.2 CPU processing

- scalar conversion;
- windowing;
- linear interpolation;
- resampling;
- histogram;
- morphology.

### 45.3 Metal processing

- windowing;
- MPR;
- gradient generation;
- histogram reduction;
- brick upload;
- transfer-function application.

### 45.4 DICOM vertical slice

- time to first frame;
- time to regular volume;
- first axial view;
- first coronal view;
- scrolling;
- windowing;
- crosshair update;
- measurement; and
- memory.

### 45.5 Compression

- JPEG 2000;
- HTJ2K;
- JP3D complete volume;
- JP3D bricks;
- region-of-interest decode;
- partial-resolution decode.

### 45.6 Large volumes

Representative uncompressed sizes should include:

- approximately 256 MiB;
- approximately 1 GiB;
- approximately 2 GiB;
- greater than available practical GPU-resident working set; and
- multi-resolution datasets.

### 45.7 Three-dimensional rendering

- MIP;
- MinIP;
- AIP;
- direct volume rendering;
- surface rendering;
- multi-volume fusion;
- clipping;
- progressive refinement.

### 45.8 Photorealistic Rendering

- interactive camera motion;
- convergence to target variance;
- high-resolution still;
- transillumination;
- multiple lights;
- distributed sample merge.

### 45.9 Headless and distributed

- off-screen batch;
- video-frame production;
- tile partition;
- sample partition;
- merge;
- cancellation.

---

## 46. Preliminary performance targets

The Requirements Baseline establishes preliminary targets.

| Capability | Preliminary target |
|---|---|
| Routine 2D scrolling and windowing | Sustain active display refresh rate on reference workstation hardware |
| Common MPR interaction | Target 60 frames per second on reference workstation hardware |
| Conventional 512³ volume rendering | Target 30–60 frames per second depending on quality and reference hardware |
| Crosshair, camera and window interaction | Visible response within 50 milliseconds on reference workstation hardware |
| First useful image | Available before full study cache generation completes |
| Cancellation | No stale result publication; superseded work stops or becomes non-publishable promptly |
| Large volume | Bounded decoded-brick and GPU-residency working sets |
| First vertical slice memory | No unnecessary complete CPU-to-GPU duplicate after steady state |

These are not unconditional guarantees for all inputs or devices. Each formal claim shall identify the dataset, quality profile, reference hardware and validated output.

---

## 47. Performance regression policy

### 47.1 Baseline creation

A benchmark baseline shall be approved only after:

- correctness passes;
- environment capture is complete;
- run variance is acceptable;
- the scenario is versioned; and
- raw results are retained.

### 47.2 Regression thresholds

Each scenario shall define:

- warning threshold;
- failure threshold;
- memory threshold;
- energy threshold where applicable; and
- permitted platform-specific variation.

### 47.3 Default provisional thresholds

Until scenario-specific thresholds are approved:

- a median latency increase greater than 5% should trigger review;
- a median latency increase greater than 10% should fail the performance gate;
- a 95th percentile latency increase greater than 10% should trigger review;
- a peak memory increase greater than 10% should trigger review;
- a peak memory increase greater than 20% should fail unless explicitly approved; and
- any performance improvement accompanied by correctness regression shall fail.

These values are provisional governance defaults, not operation-specific acceptance criteria.

### 47.4 Baseline changes

A baseline may be replaced only with:

- reason;
- old and new result comparison;
- hardware and toolchain context;
- reviewer approval; and
- retained historical data.

---

## 48. Continuous integration strategy

### 48.1 Per-change checks

Every change should run:

- build and strict-concurrency compilation;
- formatting or style checks;
- unit tests;
- affected kernel tests;
- package-cycle checks;
- documentation checks; and
- licence and dependency checks.

### 48.2 Pull-request validation

Changes affecting algorithms, shaders or storage shall also run:

- relevant differential tests;
- affected phantoms;
- selected integration tests;
- small performance smoke tests; and
- provenance checks.

### 48.3 Scheduled validation

Nightly or scheduled jobs shall run:

- broad operation matrices;
- cross-device tests where infrastructure permits;
- memory-pressure tests;
- fuzzing;
- large-data tests;
- codec tests;
- performance suites; and
- long-duration stress tests.

### 48.4 Release-candidate validation

A release candidate shall run:

- complete supported-platform build matrix;
- all P0 requirement tests for included modules;
- cross-device diagnostic tests;
- benchmark suite;
- SBOM generation;
- dependency vulnerability review;
- documentation link and schema checks; and
- reproducibility checks.

---

## 49. Milestone validation gates

### 49.1 M0 — Foundation, architecture and repository

Evidence shall include:

- approved governing documents;
- repository structure;
- strict-concurrency build;
- test and benchmark harness skeleton;
- dataset and result schema drafts;
- requirements traceability tooling; and
- architecture verification report.

### 49.2 M1 — Core data, spatial and geometry foundations

Evidence shall include:

- shapes, regions and overflow tests;
- coordinate and transform oracle tests;
- storage ownership tests;
- zero-copy view tests;
- geometry invariant tests;
- concurrency review; and
- initial validation report.

### 49.3 M2 — CPU reference processing

Evidence shall include:

- operation lifecycle tests;
- cancellation and generation tests;
- reference scalar conversion;
- interpolation;
- resampling;
- histogram;
- measurement;
- provenance;
- cache identity; and
- CPU benchmark baseline.

### 49.4 M3 — Metal and Apple Silicon foundation

Evidence shall include:

- capability detection;
- shader and pipeline identity;
- CPU–Metal differential results;
- command-lifecycle tests;
- resource-strategy benchmarks;
- copy accounting;
- error injection; and
- Metal benchmark baseline.

### 49.5 M4 — First DICOM CT vertical slice

Evidence shall include all `VOX-VS1-*` requirements, including:

- DICOMKit ingestion;
- geometry;
- value transformation;
- axial, coronal and sagittal reconstruction;
- Metal presentation;
- windowing;
- crosshair;
- pixel inspection;
- measurement;
- off-screen output;
- stale-result prevention;
- unified-memory evidence;
- provenance; and
- benchmark report.

### 49.6 M5 — Compression and large-volume storage

Evidence shall include:

- bricked storage correctness;
- multi-resolution geometry;
- lossless codec equality;
- JP3D and HTJ2K evaluation;
- random-access tests;
- cancellation;
- malformed input;
- seam tests;
- memory-pressure tests;
- bounded working set; and
- codec benchmark report.

### 49.7 M6 — Diagnostic three-dimensional visualisation

Evidence shall include:

- MIP, MinIP and AIP;
- direct volume rendering;
- transfer functions;
- gradient and lighting;
- clipping and cropping;
- segmentation overlays;
- surface extraction and rendering;
- brick refinement;
- feature preservation; and
- performance report.

### 49.8 M7 — Advanced processing

Evidence shall include:

- segmentation representation and operations;
- registration accuracy and failure cases;
- geometry processing;
- CPR where included;
- independent reference comparisons; and
- documented unsupported domains.

### 49.9 M8 — Photorealistic Rendering

Evidence shall include:

- interactive, progressive and reference modes;
- convergence analysis;
- deterministic seeds;
- provenance;
- temporal reset;
- feature preservation;
- denoising status;
- conventional comparison; and
- optional-module isolation.

### 49.10 M9 — Platform, headless and distributed expansion

Evidence shall include:

- supported platform matrix;
- headless and media-output tests;
- distributed contract compatibility;
- partition and merge tests;
- cross-device results;
- sustained worker benchmarks; and
- confirmation that orchestration remains external.

### 49.11 M10 — Voxelia 1.0

Evidence shall include:

- complete P0 traceability;
- disposition of unresolved P1 requirements;
- public validation reports;
- public benchmark reports;
- supported-platform matrix;
- known limitations;
- release SBOM;
- dependency review;
- migration guidance;
- reproducibility record; and
- approval baseline.

---

## 50. Validation artefact structure

Recommended repository structure:

```text
Validation/
├── Schemas/
│   ├── dataset.schema.yaml
│   ├── expected-result.schema.yaml
│   ├── tolerance-profile.schema.yaml
│   ├── validation-run.schema.yaml
│   └── validation-report.schema.yaml
├── Datasets/
│   ├── Manifests/
│   ├── Phantoms/
│   └── Fetch/
├── Expected/
├── Tolerances/
├── Tests/
│   ├── Unit/
│   ├── Kernel/
│   ├── Operation/
│   ├── Pipeline/
│   ├── Integration/
│   ├── SystemReference/
│   ├── CrossDevice/
│   └── Robustness/
├── Reports/
└── Tools/

Benchmarks/
├── Schemas/
├── Scenarios/
├── Baselines/
├── Results/
├── Reports/
└── Tools/
```

Large generated outputs may be stored outside Git and referenced by content digest.

---

## 51. Validation run manifest

A validation run should produce a machine-readable manifest similar to:

```yaml
schema_version: "1.0"
run_id: "2026-08-02T00-00-00Z-mpr-linear-metal"
requirement_ids:
  - "VOX-MPR-001"
  - "VOX-MPR-003"
test_id: "voxelia.mpr.linear.oblique"
test_version: "1.0.0"
validation_level: "operation"
comparison_class: "bounded_numerical"
dataset:
  id: "voxelia.phantom.ramp3d"
  version: "1.0.0"
  sha256: "<digest>"
candidate:
  operation_id: "voxelia.resample.slice"
  operation_version: "0.1.0"
  implementation_id: "voxelia.metal.mpr.linear"
  implementation_version: "0.1.0"
  shader_source_sha256: "<digest>"
  metallib_sha256: "<digest>"
reference:
  implementation_id: "voxelia.cpu.reference.mpr.linear"
  implementation_version: "0.1.0"
environment:
  platform: "macOS"
  os_version: "15.x"
  architecture: "arm64"
  capability_class: "A-WORKSTATION"
  device_model: "<model>"
  soc: "<soc>"
  memory_bytes: 0
  swift_version: "6.2"
  compiler_version: "<version>"
parameters:
  interpolation: "linear"
  output_shape: [512, 512]
tolerance_profile:
  id: "voxelia.mpr.diagnostic"
  version: "1.0.0"
result:
  status: "pass"
  maximum_absolute_error: 0.0
  root_mean_square_error: 0.0
  maximum_spatial_error_mm: 0.0
artifacts:
  report: "Reports/<report>.md"
  raw_metrics: "Reports/<metrics>.json"
```

---

## 52. Benchmark scenario manifest

A benchmark scenario should include:

```yaml
schema_version: "1.0"
benchmark_id: "voxelia.mpr.interactive"
version: "1.0.0"
title: "Interactive orthogonal MPR"
requirement_ids:
  - "VOX-PER-003"
dataset:
  id: "voxelia.benchmark.ct.512"
  version: "1.0.0"
mode: "steady_state"
quality_profile: "interactive"
storage:
  representation: "bricked"
  brick_policy: "automatic"
cache_state: "warm"
warmup:
  minimum_iterations: 30
  stability_window: 20
measurement:
  repetitions: 300
  metrics:
    - "frame_time_ms"
    - "input_to_visible_latency_ms"
    - "peak_memory_bytes"
    - "bytes_copied"
correctness_gate:
  validation_test_id: "voxelia.mpr.linear.oblique"
  required_status: "pass"
```

---

## 53. Benchmark result requirements

Every published benchmark result shall include:

- a unique run identifier;
- scenario and version;
- raw repetitions;
- summary statistics;
- environment manifest;
- validation status;
- source commit;
- toolchain;
- dataset digest;
- operation and implementation versions;
- shader identity;
- quality profile;
- cache state;
- memory and copy metrics;
- comparison with the approved baseline;
- variance and confidence information; and
- known anomalies.

Charts may supplement but shall not replace the raw machine-readable result.

---

## 54. Traceability

Validation and benchmark artefacts shall maintain bidirectional traceability:

```text
Requirement
    ↓
Validation specification
    ↓
Dataset and tolerance profile
    ↓
Test implementation
    ↓
Validation run
    ↓
Evidence and report
    ↓
Milestone or release
```

Performance artefacts shall additionally trace:

```text
Performance requirement
    ↓
Benchmark scenario
    ↓
Correctness gate
    ↓
Benchmark run
    ↓
Approved baseline
    ↓
Regression decision
```

Every implemented P0 requirement shall have at least one accepted verification artefact before its target milestone is approved.

---

## 55. Roles and responsibilities

| Role | Responsibilities |
|---|---|
| Project Lead | Approves strategy, milestone disposition and release evidence |
| Architecture Maintainer | Ensures validation aligns with architecture and records deviations |
| Module Maintainer | Defines operation domains, tolerances and required datasets |
| Validation Lead | Owns validation framework, evidence quality and reports |
| Benchmark Lead | Owns scenarios, measurement methodology and baselines |
| CPU Reference Maintainer | Maintains independent reference implementations |
| Metal Maintainer | Maintains shader identities, GPU instrumentation and differential evidence |
| Codec Maintainer | Owns codec integration evidence and upstream issue coordination |
| Security Reviewer | Reviews unsafe boundaries, malformed input and dependency risk |
| Clinical Engineering Reviewer | Reviews diagnostic feature-preservation and presentation evidence where applicable |
| Release Manager | Confirms traceability, supported matrix, SBOM and release package completeness |

One person may hold multiple roles during early development, but reviews of high-impact diagnostic changes should include an independent reviewer.

---

## 56. Validation report content

A formal validation report shall include:

1. document control;
2. purpose and scope;
3. requirements covered;
4. implementation versions;
5. datasets;
6. environment;
7. methods;
8. tolerance profiles;
9. test results;
10. failures and deviations;
11. statistical analysis;
12. performance results where applicable;
13. provenance;
14. limitations;
15. unresolved risks;
16. conclusion;
17. reviewer record; and
18. artefact checksums.

---

## 57. Benchmark report content

A formal benchmark report shall include:

1. benchmark objectives;
2. scenarios;
3. correctness-gate status;
4. hardware and capability classes;
5. operating system and toolchain;
6. build configuration;
7. datasets and storage forms;
8. quality profiles;
9. warm-up and repetition method;
10. raw metric location;
11. latency and throughput distributions;
12. memory and copy behaviour;
13. cache and residency behaviour;
14. thermal and energy observations;
15. comparison with baseline;
16. regressions;
17. interpretation;
18. limitations; and
19. approval record.

---

## 58. Deviations and waivers

A deviation from this strategy shall document:

- affected requirement;
- affected test or benchmark;
- reason;
- risk;
- compensating evidence;
- duration;
- owner;
- approval; and
- closure condition.

A waiver shall not be used to conceal a failed diagnostic or safety-critical requirement.

---

## 59. Strategy maintenance

This strategy shall be revised when:

- the Project Foundation changes;
- the Master Technical Architecture changes materially;
- the Requirements Baseline changes materially;
- a new comparison class is required;
- a new platform or backend is added;
- a significant validation weakness is discovered;
- a benchmark method is shown to be misleading; or
- release evidence demonstrates that the current process is inadequate.

Strategy revisions shall preserve historical evidence and schema compatibility or provide migration tools.

---

## 60. Immediate implementation actions

Following approval of this strategy, the project should create:

1. validation and benchmark repository directories;
2. schema version 1.0 drafts;
3. the initial analytical phantom generator;
4. the initial hardware capability inventory;
5. the first tolerance-profile templates;
6. the requirements-to-evidence traceability index;
7. the benchmark harness skeleton;
8. the CPU reference-test harness;
9. the Metal differential-test harness;
10. the DICOM geometry dataset catalogue;
11. the first vertical-slice validation specification; and
12. the first vertical-slice benchmark specification.

These activities may proceed in parallel with the **Voxelia Repository and Package Scaffold Specification v0.1.1**.

---

## 61. Acceptance criteria for this strategy

This strategy is ready to govern implementation when reviewers agree that it:

- conforms to the Project Foundation;
- conforms to the Master Technical Architecture;
- covers the validation and performance requirements in the Requirements Baseline;
- separates correctness from performance evidence;
- defines validation levels and comparison classes;
- establishes tolerance governance;
- defines dataset and golden-data governance;
- requires CPU, analytical or independent references for diagnostic Metal kernels;
- defines cross-device and cross-Apple-platform coverage;
- defines unified-memory, bricking and codec validation;
- defines diagnostic, volume and Photorealistic Rendering validation;
- defines concurrency, cancellation and stale-result testing;
- defines benchmark modes and metrics;
- defines milestone gates;
- defines evidence and report structures; and
- provides an implementable next-step plan.

---

# Appendix A — Initial requirement-to-strategy traceability

| Requirements domain | Principal strategy sections |
|---|---|
| `GOV`, `LIC`, `REP`, `DOC`, `REL` | 2, 7, 48, 54–59 |
| `PLT`, `ARC`, `API` | 19, 48–49 |
| `DAT`, `SPA`, `RGN`, `META` | 13–16, 25 |
| `GEO`, `SUR` | 31 |
| `SEG` | 29 |
| `REG` | 30 |
| `STO`, `BRK` | 21–22 |
| `CMP` | 23 |
| `EXE`, `CON`, `CCH` | 18, 34–35 |
| `CPU`, `MTL` | 18–20 |
| `IMG` | 26 |
| `R2D` | 27 |
| `MPR` | 28 |
| `DVR` | 32 |
| `PRR` | 33 |
| `INT` | 34 |
| `DCM` | 24 |
| `ADP` | 19, 36–37 |
| `HLS` | 36 |
| `DST` | 37 |
| `ERR`, `SEC` | 38 |
| `VAL` | 7–38, 48–58 |
| `PER` | 39–47 |
| `VS1` | 24, 27–28, 34, 49.5 |

---

# Appendix B — Initial comparison guidance

The following guidance is provisional and shall be replaced by operation-specific tolerance profiles.

| Subject | Primary comparison | Supplementary comparison |
|---|---|---|
| Lossless decode | Exact byte or scalar equality | Checksum and metadata |
| Integer nearest-neighbour | Exact numeric equality | Boundary-case inspection |
| Floating resampling | Bounded numerical equality | Spatial phantom comparison |
| Physical transform | Spatial tolerance | Round-trip and condition analysis |
| Histogram | Exact counts where feasible | Total-count conservation |
| Segmentation | Exact labels or overlap metrics | Surface distance and volume |
| Registration | Transform and landmark error | Similarity metric and convergence |
| Mesh extraction | Spatial and topology equivalence | Area and volume |
| Diagnostic 2D render | Stage-wise numeric comparison | Perceptual and feature comparison |
| Direct volume render | Controlled phantom comparison | Perceptual and feature preservation |
| Photorealistic render | Statistical convergence | Feature preservation and expert review |
| Distributed accumulation | Statistical or bounded numerical equality | Partition completeness |
| Performance | Distribution comparison | Memory, energy and correctness gate |

---

# Appendix C — Initial phantom catalogue

| Phantom ID | Purpose |
|---|---|
| `constant-2d` | Windowing, interpolation, filtering |
| `constant-3d` | Volume sampling and opacity |
| `ramp-xyz` | Coordinate and interpolation validation |
| `impulse-2d` | Convolution kernel validation |
| `impulse-3d` | Three-dimensional filtering |
| `checkerboard` | Resampling and aliasing |
| `step-edge` | Interpolation and edge preservation |
| `sphere-solid` | Surface extraction, volume and rendering |
| `sphere-shell` | Thin structure and topology |
| `cylinder-oblique` | Oblique MPR and CPR |
| `thin-line` | Feature preservation |
| `thin-plate` | Slice intersection and volume rendering |
| `multi-label` | Segmentation and overlays |
| `overlapping-segments` | Overlapping segmentation model |
| `affine-grid` | Transform and registration validation |
| `anisotropic-volume` | Physical sampling |
| `irregular-stack` | Frame-set handling |
| `missing-slice-stack` | DICOM assembly failure behaviour |
| `moving-sphere-4d` | Temporal stability |
| `low-contrast-lesion` | Diagnostic feature preservation |
| `micro-calcification` | High-value small-feature preservation |

---

# Appendix D — Benchmark environment checklist

Before a benchmark run, record:

- device identifier;
- capability class;
- operating-system version;
- power connection;
- low-power mode;
- thermal state;
- physical memory;
- free storage;
- display configuration;
- background tasks;
- build configuration;
- compiler version;
- Voxelia commit;
- cache state;
- dataset checksum;
- quality profile;
- instrumentation overhead; and
- correctness-gate result.

---

# Appendix E — Milestone evidence index template

```markdown
# Milestone M4 Evidence Index

## Baseline
- Foundation:
- Architecture:
- Requirements:
- Validation strategy:
- Source commit:

## Requirements
| Requirement | Evidence | Status |
|---|---|---|
| VOX-VS1-001 | VAL-M4-DICOM-001 | Pass |

## Validation reports
- VAL-M4-SPATIAL-001
- VAL-M4-CPU-METAL-001
- VAL-M4-PRESENTATION-001
- VAL-M4-CONCURRENCY-001

## Benchmark reports
- BEN-M4-FIRST-IMAGE-001
- BEN-M4-MPR-001
- BEN-M4-MEMORY-001

## Deviations
- None

## Conclusion
- Accepted / Rejected / Conditionally accepted
```

---

# Appendix F — Foundation statement

Voxelia validation and benchmarking shall operate under the following rule:

> **No implementation is considered fast enough until it is proven correct for its declared execution profile, and no implementation is considered diagnostic-ready until its numerical, spatial, presentation, provenance and failure behaviour have been validated on the declared capability classes.**
