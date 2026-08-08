---
document_id: "VOXELIA-CT-VIEWER-POC-SRS"
title: "Voxelia CT Viewer POC Software Requirements Specification"
version: "0.1"
status: "Draft"
document_type: "Software Requirements Specification"
project: "Voxelia"
application: "Voxelia CT Viewer POC"
platform_policy: "Apple Silicon ARM64 and Apple operating systems only"
licence: "MIT"
language: "en-GB"
date: "2026-08-08"
owner: "Voxelia Project"
classification: "Public"
---

# Voxelia CT Viewer POC Software Requirements Specification v0.1

## Document control

| Field | Value |
|---|---|
| Document identifier | `VOXELIA-CT-VIEWER-POC-SRS` |
| Version | 0.1 |
| Status | Draft |
| Date | 8 August 2026 |
| Proposed implementation | `Examples/VoxeliaCTReference` |
| Intended audience | Project owner, application developer, reviewer and POC evaluator |

### Revision history

| Version | Date | Summary |
|---|---:|---|
| 0.1 | 2026-08-08 | Initial SRS for a bounded, local CT viewing proof of concept using Voxelia and the owner-supplied DICOM corpus. |

### Approval record

This document is a draft for project-owner review. It specifies an example
application only. It does not revise the Voxelia library baseline, approve a
diagnostic product or authorise a regulatory claim.

## 1. Purpose

This SRS defines a small macOS proof-of-concept application that demonstrates
how a host application can use Voxelia to:

1. catalogue a caller-supplied local DICOM corpus with DICOMKit;
2. select one supported conventional CT series;
3. import it through the accepted Voxelia DICOM boundary;
4. display full-resolution axial, coronal and sagittal reconstructions;
5. provide linked navigation and CT window controls; and
6. fail clearly, cancellably and without disclosing patient-identifying data.

The POC is an engineering demonstration. It is not a clinical workstation,
diagnostic viewer, PACS client or source of regulatory evidence.

## 2. Authority and precedence

This SRS is subordinate to the following project records:

- [Voxelia Project Foundation v0.1.1](../project/Voxelia_Project_Foundation_v0.1.1.md);
- [Voxelia Master Technical Architecture v0.1.1](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md);
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md);
- [Voxelia Validation and Benchmark Strategy v0.1.1](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md);
- [Voxelia First Vertical Slice Plan v0.1.1](../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md);
- [ADR-0310 — Documented example safety](../architecture/decisions/ADR-0310-documented-example-safety.md);
- [ADR-0347 — The reference application](../architecture/decisions/ADR-0347-the-reference-application.md); and
- [ADR-0349 — Study import wiring](../architecture/decisions/ADR-0349-study-import-wiring.md).

If this SRS conflicts with an accepted higher-authority record, that record
takes precedence. A library API, numerical model, tolerance or architecture
change requires its own approved project process and is not implied by this
SRS.

## 3. Product definition

### 3.1 Product name

The product/display name is **Voxelia CT Viewer POC**. The intended first
implementation vehicle retains the existing SwiftPM package and executable
identifier `VoxeliaCTReference` under `Examples/VoxeliaCTReference`.

### 3.2 Intended user

The primary user is a Voxelia developer or evaluator working locally on an
Apple Silicon Mac. The user is expected to understand that the source corpus
may contain sensitive clinical data and that the application is not approved
for patient care.

### 3.3 POC success statement

The POC succeeds when an evaluator can select the proven compatible CT series
from the supplied corpus, import it under the accepted exact geometry policy,
see synchronised full-resolution axial, coronal and sagittal views, adjust CT
window centre and width, cancel or replace work without stale publication, and
observe no patient identifier in the application catalogue, diagnostics, logs
or retained evidence.

## 4. Scope

### 4.1 In scope

- Apple Silicon ARM64 and macOS 15 or later.
- A Swift 6.2-or-later SwiftPM executable using SwiftUI for host UI.
- Caller-selected local directory input, with
  `/Users/ranjith/telerad-dicom-input` as the initial acceptance corpus.
- Read-only DICOMKit catalogue discovery of conventional, single-frame,
  MONOCHROME2 CT series with no declared pixel padding.
- Selection and import of exactly one CT series at a time.
- DICOM parsing through DICOMKit and the optional `VoxeliaDICOMKit` module.
- Voxelia canonical volume construction, geometry assessment, provenance,
  multiplanar reconstruction and rendering.
- Full-resolution axial, coronal and sagittal viewing.
- Linked crosshair and bounded slice navigation.
- CT window centre and width controls, including named host-side demonstration
  defaults for HU-admitted series.
- Progress, cancellation, typed refusal and privacy-safe status reporting.
- Focused automated verification and one owner-witnessed local demonstration.

### 4.2 Out of scope

- MR, CR, DX, PX, SR, US, XA, mammography or any other non-CT display path.
- MONOCHROME1, any declared pixel padding, enhanced multi-frame, irregular
  frame-set or colour CT presentation. The current render coordinators do not
  carry the imported padding declaration into their window stage, so the POC
  refuses rather than displays those inputs incorrectly.
- Automatic geometry regularisation or a tolerance looser than `.exact`.
- Interactive three-dimensional volume rendering of the supplied 16-bit CT.
- Segmentation, registration, fusion, processing galleries or photorealistic
  rendering as POC completion criteria.
- PACS/VNA access, DICOM networking, query/retrieve or routing.
- Patient worklists, reporting, hanging protocols or clinical workflow.
- Authentication, accounts, permissions or audit infrastructure.
- Browser services, remote services, cloud storage or deployment orchestration.
- Database persistence, annotation persistence, export, printing or sharing.
- Diagnostic-use, clinical-performance, safety or regulatory claims.
- Copying any supplied DICOM object into the repository or release artefacts.

## 5. Operating environment and dependencies

| Item | Requirement |
|---|---|
| Hardware | Apple Silicon ARM64 Mac |
| Operating system | macOS 15 or later |
| Toolchain | Swift 6.2 or later, Swift 6 language mode and strict concurrency |
| Packaging | Swift Package Manager executable depending on the parent Voxelia package by path |
| Host UI | SwiftUI and AppKit only within the example application |
| DICOM parsing | DICOMKit directly in the host for bounded catalogue-tag reads, then `VoxeliaDICOMKit` for canonical translation; no second general DICOM parser |
| Required data path | DICOMKit catalogue read → one verified URL set → `DICOMFrameSource` → `CTImportSession` → canonical `ImageData` → published MPR/render coordinators |
| Runtime connectivity | The built application opens no network connection or listener; dependency resolution during development is outside this runtime rule. |

## 6. Acceptance corpus

### 6.1 Source and handling

The initial acceptance corpus is the owner-supplied directory:

```text
/Users/ranjith/telerad-dicom-input
```

The location is a local acceptance input, not a compiled runtime dependency.
An evaluator shall be able to choose another root. The corpus shall remain
outside source control and shall be accessed read-only.

### 6.2 PHI-safe technical inventory

The following 8 August 2026 inventory is informative and may be refreshed
without changing the product requirements:

| Property | Observed value |
|---|---:|
| Total files | 30,348 |
| DICOM instances | 30,329 |
| Logical studies in the supplied manifest | 51 |
| Distinct series in the supplied manifest | 766 |
| CT instances by DICOM `Modality` | 20,868 |
| Other DICOM modalities present | MR, XA, US, CR, SR, DX and PX |
| Proven compatible CT witness | 899 single-frame MONOCHROME2 slices, no declared pixel padding, 512 × 512, unsigned 16-bit, 471,334,912 bytes |

Folder names are not authoritative: the observed folder categories and DICOM
`Modality` values differ. Discovery and selection shall therefore use bounded
DICOMKit reads of the identity, pixel-format, presentation and value-transform
fields enumerated by `VOX-POC-003`. The supplied manifest is permitted only as
a non-authoritative, sensitive candidate-path accelerator. It shall not be
copied, persisted, displayed or logged, and every path resolved from it shall
be proven to remain within the selected root. Direct DICOMKit catalogue
verification and subsequent Voxelia validation remain authoritative for the
selected series.

### 6.3 Sensitive-data restrictions

No patient attribute, individual instance or series path, description or DICOM
identifier copied from the supplied corpus or any other real dataset shall
appear in the POC catalogue, status line, error text, logs, screenshots, test
fixtures, commits or public evidence. Screenshots and recordings of real-corpus
image panes are prohibited because identifying text may be burned into pixels;
public visual evidence shall use synthetic data. Deliberately synthetic values
are permitted only in privacy and grouping tests. The designated corpus root
above is configuration rather than a DICOM identifier; screenshots and logs
should still omit it. The UI shall use session-local neutral labels such as
`CT Series 1` and technical, non-identifying properties such as frame count and
scalar format.

## 7. User workflow

### 7.1 Primary flow

1. The evaluator launches the application and chooses the local input root.
2. The application discovers candidate series and presents neutral technical
   labels.
3. Non-CT and unsupported candidates remain visibly unavailable based on the
   host's bounded DICOMKit catalogue read.
4. The evaluator chooses one CT series.
5. The application reports discovery, metadata read, validation, assembly and
   rendering progress and exposes cancellation.
6. Voxelia admits or refuses the series. The application never silently
   repairs or substitutes it.
7. On admission, the application displays synchronised axial, coronal and
   sagittal views at full resolution.
8. The evaluator navigates slices or the linked crosshair and adjusts window
   centre and width.
9. The evaluator may select another series; earlier work is cancelled and can
   no longer publish into the UI.

### 7.2 Failure flow

On unsupported input, ambiguous series membership, rejected geometry,
unavailable frame samples, cancellation or resource refusal, the application
shall show a stable payload-free error category and recovery action. It shall
not publish a partial volume, fall back to a different series, loosen the
geometry tolerance or retain the previous image as though it represented the
failed selection.

## 8. Software requirements

Verification codes are: `I` inspection, `T` automated test, `D` demonstration,
`A` analysis and `R` review.

### 8.1 Input and discovery

| ID | Requirement | Priority | Verification | Traces to |
|---|---|:---:|:---:|---|
| `VOX-POC-001` | The application shall accept a local input root from a launch argument or folder chooser. The supplied corpus path may be a local convenience default but shall not be required or embedded in a release artefact. | P0 | I,T,D | `VOX-GOV-003`, `VOX-PLT-001` |
| `VOX-POC-002` | The application shall access the input root read-only and shall create, modify, rename, move or delete no object within it. | P0 | I,T,D | `VOX-GOV-003` |
| `VOX-POC-003` | The host shall use DICOMKit directly for a bounded discovery read of Modality, SOP Class UID, Series Instance UID, Samples per Pixel, photometric interpretation, Bits Allocated, Bits Stored, High Bit, Pixel Representation, Pixel Padding Value/Range Limit presence, Rescale Slope, Rescale Intercept and Rescale Type. It shall group candidates by verified Series Instance UID rather than folder name, filename or Instance Number. | P0 | I,T | `VOX-DCM-001`, `VOX-DCM-004`–`VOX-DCM-009` |
| `VOX-POC-004` | A supplied manifest may accelerate candidate-path discovery, but it shall be treated as sensitive input: it shall not be copied, persisted, displayed or logged; every resolved path shall remain within the selected root; and DICOMKit shall re-read the bounded catalogue fields before a source is admitted to a selected group. Voxelia admission remains authoritative for canonical CT translation, geometry and content. | P0 | I,T | `VOX-DCM-001`–`VOX-DCM-004`, `VOX-SEC-003`, `VOX-DOC-011` |
| `VOX-POC-005` | The catalogue shall expose only session-local neutral labels, modality, frame count and support status; it shall not expose patient attributes, individual instance or series paths, descriptions or DICOM identifiers. | P0 | I,T,R | `VOX-SEC-006` |
| `VOX-POC-006` | A candidate shall be selectable only when every resolved instance declares the conventional single-frame CT Image Storage class, Modality `CT`, Samples per Pixel `1`, MONOCHROME2, Bits Allocated `16`, Bits Stored in `1...16`, High Bit equal to Bits Stored minus one, Pixel Representation `0` or `1`, no pixel-padding attribute, a finite non-zero Rescale Slope, a finite Rescale Intercept and Rescale Type `HU`. Pixel format, resolved slope/intercept and Rescale Type shall agree exactly across the series. Every other value domain or presentation form shall be labelled unsupported and shall not reach `CTImportSession`. | P0 | I,T,D | `VOX-DCM-001`, `VOX-DCM-005`–`VOX-DCM-009`, [known limitations](../releases/known-limitations.md) |

### 8.2 Import, validation and publication

| ID | Requirement | Priority | Verification | Traces to |
|---|---|:---:|:---:|---|
| `VOX-POC-007` | A selected series shall be imported through `DICOMFrameSource` and `CTImportSession` using `.exact` geometry tolerance, DICOM patient LPS convention and millimetres. | P0 | I,T,D | `VOX-VS1-001`–`VOX-VS1-004`, `ADR-0349` |
| `VOX-POC-008` | For an admitted MONOCHROME2/no-padding series, import shall preserve signed or unsigned 16-bit sample semantics, the verified uniform non-zero rescale slope/intercept, spatial geometry, frame of reference and source-frame provenance through published Voxelia values. The host shall retain the verified `HU` catalogue declaration only to label interpreted controls; it shall not invent or attach a scientific unit to the canonical volume. This POC does not claim the excluded MONOCHROME1 or padding presentation requirements. | P0 | T,D | `VOX-DCM-003`–`VOX-DCM-007`, `VOX-DCM-010`, `VOX-VS1-004`–`VOX-VS1-006`, `VOX-VS1-019` |
| `VOX-POC-009` | Geometry or content that Voxelia cannot represent correctly shall be refused with no automatic regularisation, tolerance change, interpolation change or alternate-series selection. | P0 | T,D,R | `VOX-DCM-009`, `VOX-VS1-003`, `VOX-DOC-011` |
| `VOX-POC-010` | Import shall expose bounded progress and a cancellation action. Cancellation shall return no publishable aggregate and shall leave no partial result visible. | P0 | T,D | `VOX-VS1-017`, `VOX-CON-005`–`VOX-CON-009` |
| `VOX-POC-011` | Every selection shall own a generation identifier. Completion from an older selection or render request shall be discarded and shall not replace a newer state. | P0 | T,D | `VOX-VS1-017`, `VOX-EXE-007`–`VOX-EXE-009` |
| `VOX-POC-012` | A volume shall be published to the viewer only after complete import and validation. The returned series-member count and `DICOMFrameSource` described-frame count shall both equal the verified selected-source count; any mismatch is an incomplete import and shall be refused before publication. A failed replacement shall clear or visibly mark the prior view as unrelated to the failed selection. | P0 | T,D | `VOX-VS1-003`, `VOX-ERR-004`, `VOX-ERR-009` |

### 8.3 Viewing and interaction

| ID | Requirement | Priority | Verification | Traces to |
|---|---|:---:|:---:|---|
| `VOX-POC-013` | An admitted CT volume shall be displayed as simultaneous full-resolution axial, coronal and sagittal views using published Voxelia MPR and render coordinators. The app shall not compute presentation pixels itself. | P0 | I,T,D | `VOX-VS1-009`, `VOX-VS1-010`, `ADR-0347`, `ADR-0349` |
| `VOX-POC-014` | The three views shall share a patient-space crosshair. A navigation action in any view shall update the other views through Voxelia spatial mappings and keep every index within the admitted image region. | P0 | T,D | `VOX-VS1-013`, `VOX-INT-001`–`VOX-INT-010` |
| `VOX-POC-015` | The evaluator shall be able to navigate each orthogonal axis by pointer/scroll input and a bounded slice control. Host event binding shall remain application policy. | P0 | I,T,D | `VOX-GOV-003`, `VOX-VS1-009`, `ADR-0347` |
| `VOX-POC-016` | The application shall provide admitted window centre and width controls labelled in HU only for the `HU`-admitted series. Values shall pass through the volume's declared finite, uniform, non-zero transform and Voxelia presentation path. The host may provide lung, bone, soft-tissue and brain values only as visibly labelled demonstration defaults; they are conveniences, not clinically reviewed or validated presets. | P0 | T,D | `VOX-VS1-006`, `VOX-VS1-012` |
| `VOX-POC-017` | The UI shall state the active plane positions, volume dimensions, scalar format, geometry verdict, render backend and demonstration-only status without displaying a source identifier. | P0 | I,T,D | `VOX-VS1-019`, `VOX-SEC-006` |
| `VOX-POC-018` | If quantitative pixel inspection is implemented, it shall use authoritative Voxelia values and geometry; a presentation pixel shall never be treated as a measurement source. This conditional feature is not required for POC completion. | P1 | I,T,D when present | `VOX-VS1-014`, `VOX-MPR-014` |
| `VOX-POC-019` | If a patient-space distance tool is implemented, it shall use authoritative Voxelia geometry and report millimetres with explicit endpoints and failure behaviour. This conditional feature is not required for POC completion. | P1 | I,T,D when present | `VOX-VS1-015`, `VOX-MPR-014` |

### 8.4 Architecture and implementation quality

| ID | Requirement | Priority | Verification | Traces to |
|---|---|:---:|:---:|---|
| `VOX-POC-020` | The application shall own lifecycle, source discovery, selection, controls, layout and host interaction timing. Its only direct DICOMKit work shall be the bounded catalogue fields in `VOX-POC-003`; it shall implement no DICOM decoder or canonical adapter and shall duplicate no series assembly, spatial transform, resampling, presentation, provenance or cancellation semantics supplied by Voxelia. | P0 | I,R | `VOX-GOV-003`, `VOX-API-001`, `VOX-DCM-001`, `VOX-DOC-011`, `ADR-0347` |
| `VOX-POC-021` | SwiftUI/AppKit types shall remain in the executable target and shall not enter Voxelia's canonical scientific APIs or library targets. | P0 | I,T | `VOX-API-002`, `VOX-API-008` |
| `VOX-POC-022` | The executable shall use Swift 6 language mode, strict concurrency and immutable `Sendable` values or actor-isolated mutable state as appropriate. | P0 | I,T | `VOX-API-003`, `VOX-PLT-008`, `VOX-PLT-009`, `VOX-VS1-020` |
| `VOX-POC-023` | Errors shown by the app shall map typed failures to stable payload-free categories and recovery guidance. The app shall not print raw errors that may contain identifiers, paths or source values. | P0 | I,T,R | `VOX-ERR-001`, `VOX-ERR-004`, `VOX-ERR-005`, `VOX-SEC-006` |

### 8.5 Privacy, security and resource behaviour

| ID | Requirement | Priority | Verification | Traces to |
|---|---|:---:|:---:|---|
| `VOX-POC-024` | The POC shall create no network listener or client, require no credential and transmit no data. | P0 | I,T | `VOX-GOV-007`, `VOX-SEC-004` |
| `VOX-POC-025` | Logs, telemetry and captured evidence shall exclude patient-identifying metadata, DICOM identifiers, source descriptions and individual instance or series paths. The POC shall provide no override. | P0 | T,R | `VOX-SEC-006` |
| `VOX-POC-026` | The main window shall continuously display `Demonstration only — not for diagnostic use`. No screen, README or evidence record shall imply clinical validation. | P0 | I,D,R | `VOXELIA-FOUNDATION`, `ADR-0347` |
| `VOX-POC-027` | External counts, extents, offsets and allocation sizes shall be admitted by Voxelia's checked boundaries before allocation or access. The app shall not add an unchecked bypass. | P0 | I,T | `VOX-SEC-001`, `VOX-DOC-011` |
| `VOX-POC-028` | The POC viewing workflow shall own one source volume in one bounded publication session. Derived render stages may accumulate within the active append-only `PublicationCoordinator` up to its documented fixed ceiling; the app shall not imply eviction. Replacing or closing a series shall cancel pending work, create a fresh session and release the prior session after its work quiesces. Optional modes outside this SRS are not assessed by this requirement. | P0 | T,A,D | `VOX-PER-007`, `VOX-PER-008`, `VOX-CON-005`–`VOX-CON-009`, `ADR-0347` |

### 8.6 POC performance targets

| ID | Requirement | Priority | Verification | Traces to |
|---|---|:---:|:---:|---|
| `VOX-POC-029` | On the recorded acceptance Mac, the proven 899-slice CT witness shall produce all three initial views within 30 seconds of selection. The exact hardware, OS, toolchain, Voxelia version, cold/warm state and elapsed time shall be recorded. | P1 | A,D | `ADR-0349` |
| `VOX-POC-030` | After one warm-up per view and from each control's midpoint, the fixed sequential script shall perform five `+1` then five `−1` slice moves in each plane, five `+10` then five `−10` HU window-centre changes, and five `+10` then five `−10` HU window-width changes. Timing runs from committed host input state to presentation of the matching generation; at least 48 of the 50 actions shall complete within 1 second on the recorded acceptance Mac. This POC ceiling does not discharge the baseline's separate 50-millisecond interaction target. | P1 | A,D | `VOX-PER-007` |
| `VOX-POC-031` | Peak resident memory while loading and viewing the proven 449 MiB witness shall remain at or below 2.5 GiB, with no second complete source volume retained after a replacement session reaches steady state. | P1 | A,D | `VOX-VS1-018`, `VOX-PER-008` |

These are POC targets, not general Voxelia benchmarks or diagnostic performance
claims. Failure of a P1 target shall be recorded honestly and shall not be
hidden by reducing image fidelity, skipping validation or using a different
series. `VOX-POC-029` does not discharge `VOX-PER-006`'s separate
first-useful-image-before-cache-completion requirement, and `VOX-POC-030` does
not discharge `VOX-PER-005`'s 50-millisecond target. ADR-0349's 16-bit CT study
mode is full-resolution and does not use the phantom's level-generation path.

## 9. User-interface requirements

The single application window shall contain:

- a source-root chooser and refresh action;
- a neutral series catalogue with support state and frame count;
- an import progress indicator, current stage and cancel action;
- three labelled image panes: Axial, Coronal and Sagittal;
- a linked crosshair and bounded navigation control for each view;
- window centre and width controls plus four visibly non-clinical demonstration
  defaults;
- a privacy-safe status area containing admitted technical properties and any
  stable refusal category; and
- a persistent demonstration-only disclaimer.

The UI shall remain responsive while discovery, import and rendering execute.
An empty, loading, cancelled, refused and ready state shall be visually
distinct. A prior image shall not remain presented as if it belonged to a new
loading or refused selection.

## 10. Error categories

At minimum, the host shall map typed underlying failures to the following
payload-free user categories:

| Category | User guidance |
|---|---|
| Input unavailable | Choose an accessible local directory. |
| No supported CT series | Choose a directory containing a supported conventional CT series. |
| Presentation form unsupported | Choose a MONOCHROME2 CT series with no declared pixel padding. |
| Source changed after catalogue | Refresh the catalogue; the re-read source set no longer describes the admitted series. |
| Geometry refused | Choose another series; the POC does not regularise geometry. |
| Frame samples unavailable | Choose another series or verify local source integrity. |
| Resource limit reached | Close the active series and retry on supported hardware. |
| Cancelled | Select a series to start again. |
| Rendering unavailable | Verify supported Apple Silicon/Metal capability; no fallback is implied. |

The mapping shall not include filenames, paths, UIDs, free-text DICOM values,
pixel values or volume extents in error strings.

## 11. Acceptance plan

| Acceptance ID | Required evidence | Requirements covered |
|---|---|---|
| `POC-AC-01` | Build the example on Apple Silicon macOS with Swift 6 strict concurrency; run the focused example/integration test target without warnings or unsafe example shortcuts; inspect that UI types remain in the executable, direct DICOMKit use is confined to the catalogue fields enumerated by `VOX-POC-003`, and scientific behaviour is composed from published Voxelia APIs. | `VOX-POC-001`, `020`–`023` |
| `POC-AC-02` | Run discovery under a file-system write audit and against a write-denied fixture. Prove grouping follows DICOM attributes despite folder-category differences. Test manifest paths containing `..`, an absolute path outside the selected root and a symlink escaping the root; each shall be refused before DICOM read. Prove the manifest is neither copied nor persisted. For the real root, record only aggregate before/after file count, total bytes and latest modification time and observe no write syscall under the root. | `VOX-POC-002`–`006` |
| `POC-AC-03` | Import the proven 899-slice witness under `.exact`; record 899 verified sources, 899 described frames, 899 series members, complete transfer, 512 × 512 × 899, Samples per Pixel 1, MONOCHROME2, Bits Allocated/Stored 16, High Bit 15, unsigned Pixel Representation, uniform slope 1/intercept −8192/type HU and a representable geometry verdict. Assert the published descriptor uses DICOM patient LPS in millimetres with the expected linear transform, preserves the frame-of-reference external reference and carries 899 source-frame provenance locators. | `VOX-POC-007`–`012` |
| `POC-AC-04` | Produce axial 512 × 512, coronal 512 × 899 and sagittal 512 × 899 views; exercise bounded navigation and linked patient-space crosshair updates. | `VOX-POC-013`–`015` |
| `POC-AC-05` | Re-run `VOXELIA-ALG-0002` v1.2's exact CPU fixtures: int16 samples at centre 40/width 400 shall produce `[0,0,38,102,115,128,141,153,179,230,255,255]`, and uint16 samples at centre 32,000/width 64,000 shall produce `[0,0,2,4,8,16,32,64,128,191,239,255]`. The Metal result shall differ from the CPU reference by at most one display level per sample and match exactly for at least 99% of the seeded 4,096-sample differential corpus in `MetalWindowLevelKernelTests`. Re-run the exact `CrosshairCompositionTests` 4 × 3 × 5 fixture: voxel `(2,1,3)` maps to world `(14,23,45)` and to axial `(2,1)`, coronal `(2,3)` and sagittal `(1,3)` with exact integer equality. Add an application-wiring test proving those centre/width and crosshair values reach the matching published generation. Screenshots are not numerical evidence. | `VOX-POC-014`, `016` |
| `POC-AC-06` | Exercise unsupported non-CT input, non-16-bit or multi-sample input, MONOCHROME1, declared padding, zero or inconsistent rescale terms, non-HU Rescale Type, duplicate-position CT monitoring frames, missing-image-attribute raw objects, rejected geometry and a source set changed after catalogue so its re-read UIDs disagree. Confirm explicit refusal and no partial publication. A valid mixed root and a manifest-proposed group spanning multiple verified UIDs shall instead produce separate DICOMKit-derived catalogue entries. | `VOX-POC-003`, `006`, `009`, `012`, `023` |
| `POC-AC-07` | Cancel import at deterministic checkpoints and change selection during import/render. Prove that no cancelled or older generation reaches the ready UI, the replacement owns a new bounded publication session and the prior session is released after its tasks quiesce. Do not assert eviction from an active `PublicationCoordinator`. | `VOX-POC-010`, `011`, `028` |
| `POC-AC-08` | Inject synthetic patient-like values into test input and inspect UI state, captured logs and evidence for absence of those values, paths and identifiers. No real patient value shall be copied into a fixture, and no image pane rendered from the real corpus shall be captured. Assert the neutral technical fields and persistent disclaimer explicitly. | `VOX-POC-005`, `017`, `023`, `025`, `026` |
| `POC-AC-09` | Record first-view latency, the exact 50-action script and peak resident memory on the named acceptance Mac without changing fidelity or validation policy. Record explicitly that these results do not discharge `VOX-PER-005` or `VOX-PER-006`. | `VOX-POC-029`–`031` |
| `POC-AC-10` | Inspect executable dependencies and sources for network/credential code, run the application under a local network-activity monitor, and review/test that all external sizes and allocations enter through checked Voxelia boundaries. | `VOX-POC-024`, `027` |
| `POC-AC-11` | Owner witnesses the primary workflow and confirms the visible disclaimer and known limitations. Real-corpus panes are viewed locally and are not captured. | All P0 requirements |

Real-data demonstration is evidence of integration and representability only.
Correctness of spatial, numerical and presentation behaviour remains grounded
in the repository's independent CPU, analytical and frozen reference tests.

## 12. Completion criteria

The POC is complete when:

1. every P0 requirement in this SRS has passing evidence;
2. `POC-AC-01` through `POC-AC-11` have recorded results;
3. every P1 target is evidenced or explicitly recorded as deferred, while the
   conditional constraints `VOX-POC-018` and `VOX-POC-019` apply only if their
   feature is present;
4. no supplied DICOM object or patient-identifying value is present in the
   repository, logs or public evidence;
5. limitations and failed/unsupported cases are visible to the evaluator; and
6. the project owner accepts the demonstration as a POC only.

Completion does not establish diagnostic readiness, regulatory evidence,
multi-modality support or production suitability.

## 13. Known limitations and assumptions

- The current supported DICOM ingress is conventional CT. Adapter seams for
  other DICOM object classes do not imply shipped readers.
- The current renderer boundary does not carry a CT frame's padding declaration
  into its window stage and requires the host to select polarity. The POC
  therefore admits only MONOCHROME2 series with no declared pixel padding and
  does not claim `VOX-VS1-007` or `VOX-VS1-008`.
- `.exact` geometry tolerance is intentionally conservative and may reject
  physically usable reformats whose recorded spacing differs by very small
  amounts. The POC shall report the refusal and shall not change the tolerance.
- The supplied corpus includes folder categories that do not match the actual
  DICOM Modality, so folder structure cannot determine support.
- The current interactive level-selection and volume-operation path is limited
  to calibrated rank-three `uint8`; the supplied CT witness is 16-bit. Study
  mode therefore uses full-resolution MPR and does not require interactive 3D
  rendering.
- Metal implementations are non-diagnostic by default. The POC makes no
  diagnostic-backend selection claim.
- The source corpus is locally available to the evaluator, remains confidential
  and is not distributed with Voxelia.
- POC memory and latency targets apply only to the named witness and recorded
  Apple Silicon environment.

## 14. Traceability summary

| POC concern | Governing Voxelia requirements/records |
|---|---|
| Host/library boundary | `VOX-GOV-002`, `VOX-GOV-003`, `VOX-GOV-007`, `VOX-API-008`, ADR-0347 |
| Apple-only platform | `VOX-PLT-001`, `VOX-PLT-006`–`VOX-PLT-009` |
| DICOM CT import | `VOX-DCM-001`–`VOX-DCM-007`, `VOX-DCM-009`, `VOX-DCM-010`, `VOX-VS1-001`–`VOX-VS1-006`, `ADR-0349`; `VOX-VS1-007` and `VOX-VS1-008` explicitly not claimed |
| MPR and windowing | `VOX-VS1-009`, `VOX-VS1-010`, `VOX-VS1-012`, `VOX-VS1-013`; `VOX-VS1-014` and `VOX-VS1-015` conditional only |
| Cancellation and stale work | `VOX-VS1-017`, `VOX-EXE-007`–`VOX-EXE-009`, `VOX-CON-005`–`VOX-CON-009` |
| Provenance and privacy | `VOX-VS1-019`, `VOX-SEC-006` |
| Example safety and honesty | `VOX-DOC-010`, `VOX-DOC-011`, ADR-0310 |
| Validation | `VOX-VAL-001`–`VOX-VAL-007`, `VOX-VAL-011`, `VOX-VAL-012`, `VOX-VAL-016` |

## 15. References

- [Current known limitations](../releases/known-limitations.md)
- [Voxelia v1.0.0 release record](../releases/v1.0.0/README.md)
- [Real CT ingest demonstration evidence](../progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md)
- [Voxelia CT reference application README](../../Examples/VoxeliaCTReference/README.md)
