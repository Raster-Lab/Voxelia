---
document_id: "ADR-0220"
title: "Remaining traceability paydown"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-008"
  - "VOX-ARC-006"
  - "VOX-DAT-007"
  - "VOX-IMG-006"
  - "VOX-MTL-010"
  - "VOX-MTL-012"
  - "VOX-PER-001"
  - "VOX-PER-003"
  - "VOX-PER-005"
  - "VOX-RGN-005"
  - "VOX-VAL-004"
  - "VOX-VAL-005"
---

# ADR-0220 - Remaining traceability paydown

## Context

Three increments took the traceability debt from 83 rows to 29: `ADR-0217`
(vertical slice), `ADR-0218` (execution and CPU) and `ADR-0219` (governance and
licence). Eighteen of the 29 are the owner-gated `VOX-CMP` and `VOX-DCM` rows.

This record inspects the remaining eleven and finishes the paydown. It is the
least comfortable of the four: **six of the eleven come back not satisfied**,
and several of those are gated on hardware or on evidence nobody has produced.

## Findings, per row

### Satisfied and now traced

- **`VOX-ARC-006`** (`VoxeliaImaging` defines image-processing semantics
  without owning the Metal command lifecycle, **I,R**). Satisfied and
  **mechanically enforced**: no file in `VoxeliaImaging` imports `Metal`, and
  the module's prohibited-import set forbids it. Only **Inspection** is claimed;
  the **Review** half is an owner act a record cannot self-certify.
- **`VOX-DAT-007`** (optimised initial paths support rank-two and rank-three
  spatial data, **T**). Satisfied: the accepted operations admit their rank
  explicitly, with six distinct rank-two or rank-three admissions across
  `VoxeliaExecution`, each rejected typed when the rank is wrong.
- **`VOX-IMG-006`** (interpolation operations define boundary handling
  explicitly, **I,T**). Satisfied by all three accepted interpolation models,
  each stating the rule in its own text rather than leaving it to the
  implementation: `VOXELIA-ALG-0008` freezes
  `index = clamp(floor(position), 0, nIn - 1)`; `VOXELIA-ALG-0015` clamps both
  taps and computes the weight from the *unclamped* floor so an edge position
  replicates the border sample; `VOXELIA-ALG-0021` states its own boundary
  behaviour.
- **`VOX-MTL-012`** (sparse resources capability-gated with a bricked fallback,
  **I,T**). Satisfied, and the honest reading is narrower than it looks:
  `MetalExecutionContext` carries a `supportsSparseTextures` capability flag,
  and **no code consumes it, because no sparse resource is used anywhere**. The
  bricked path is therefore not a fallback but the only implementation. The
  requirement's substance — never depend on sparse resources without a gate and
  a non-sparse path — holds completely, and it holds because the project has
  not reached for sparse resources at all.
- **`VOX-RGN-005`** (a view preserves or derives correct spatial geometry for
  the selected region, slice, component or temporal frame, **T**). Satisfied by
  `RegionExtractionOperation`, which derives the region's geometry rather than
  copying it: a regular axis has its origin shifted by
  `origin + lower * spacing`, and the affine case is handled explicitly under
  `VOXELIA-ALG-0006`, because cropping under affine geometry shifts origins.

### Not satisfied

- **`VOX-MTL-010`** (reusable staging and decode destination buffers, **T,A**).
  **Unbuilt.** No staging-buffer reuse exists in `VoxeliaMetal`; the residency
  manager has no such concept. Its Analysis half additionally needs a
  measurement workload, which is a standing gated item.
- **`VOX-VAL-004`** (golden results include source, licence, generator,
  versions, checksums and tolerance definitions, **I,R,T**). **Not satisfied,
  because there are no golden results.** The *scaffolding* exists —
  `Validation/Datasets/Manifests`, `Validation/Tolerances`,
  `Validation/Schemas` — and the one manifest present declares itself an M0
  scaffold that "validates structure only; it contains no sample data", with an
  empty `files` list. A schema for metadata is not the metadata.
- **`VOX-PER-001`** (performance evaluated only on output that passed the
  applicable correctness validation, **R,T**). **Not satisfied.** The
  `Benchmarks` package exists with baselines, reports and schemas, but the
  measurement workloads that would produce a performance evaluation are a
  standing gated item, so there is no evaluation to have applied the policy to.
  The Review half is an owner act regardless.
- **`VOX-PER-003`** (60 frames per second for common MPR interaction) and
  **`VOX-PER-005`** (visible response within 50 milliseconds), both **T,D** on
  **reference workstation hardware**. **Gated**, on exactly the grounds
  `VOX-PER-004` already is: the project has no reference hardware and no
  interactive draw loop, and producing either number without them would be
  fabrication.
- **`VOX-VAL-005`** (a golden image alone is not sufficient evidence for
  quantitative operations, **R**). **The practice conforms and the method is
  not ours to claim.** Every quantitative operation in this project is
  evidenced by an independent Python oracle reproducing frozen digests
  bit-exactly — never by a golden image — which is the requirement's substance
  observed rather than asserted. But its sole verification method is **Review**,
  an owner act. This record states the conformance and claims no discharge.

## Decision

1. **Five rows are discharged and traced**: `VOX-ARC-006` (Inspection half),
   `VOX-DAT-007`, `VOX-IMG-006`, `VOX-MTL-012` and `VOX-RGN-005`.
2. **Six rows are recorded as not satisfied**, each with its specific reason:
   one unbuilt (`VOX-MTL-010`), one lacking the artefacts it describes
   (`VOX-VAL-004`), one lacking the evaluation it governs (`VOX-PER-001`), two
   hardware-gated (`VOX-PER-003`, `VOX-PER-005`), and one whose practice
   conforms but whose method is an owner act (`VOX-VAL-005`).
3. **`VOX-MTL-012` is traced with the narrower reading**, not the flattering
   one. Saying "capability-gated with a bricked fallback" without saying that
   nothing uses sparse resources at all would imply a gate that has been
   exercised. It has not.
4. **`VOX-VAL-004` is not traced as satisfied because schemas exist.** A schema
   for golden-result metadata is not golden-result metadata, and the sole
   manifest says of itself that it contains no sample data.
5. **Review halves are never claimed.** `VOX-ARC-006`, `VOX-PER-001` and
   `VOX-VAL-005` all carry Review, and a record cannot review itself.
6. **All eleven rows leave the debt list**, taking it to **18** — exactly the
   owner-gated `VOX-CMP` and `VOX-DCM` set. The traceability debt in entered
   milestones is now, apart from the owner's two dependency questions, **paid
   off**.
7. **No product source changes.** Nothing here builds anything; it records what
   is and is not there.

## Alternatives considered

### Trace `VOX-VAL-004` against the validation scaffolding

Rejected; see decision 4.

### Claim `VOX-MTL-012` as fully satisfied on the capability flag alone

Rejected; see decision 3. A flag nothing reads is not a demonstrated gate, and
the honest sentence — no sparse resource is used anywhere — is both simpler and
more useful to a future reader deciding whether to introduce one.

### Build reusable staging buffers now to close `VOX-MTL-010`

Rejected. It is a performance-shaped change whose own verification method
includes Analysis, and the measurement workload that would justify and validate
it is gated. Building it now would produce an unmeasurable optimisation.

### Estimate the interaction targets from current off-screen timings

Rejected outright. Both rows name reference workstation hardware and
interaction; an off-screen timing on this machine is not that measurement, and
publishing it as though it were would be the clearest possible instance of
fabricated evidence.

## Consequences

The traceability debt in entered milestones falls to **18 rows, all owner-gated**
— the `VOX-CMP` codec block and the `VOX-DCM` DICOMKit block, both waiting on
dependency decisions reserved to the owner. Every other requirement in M0
through M6 is now either discharged or visible with a recorded reason.

Six capability and evidence gaps are explicit that were previously recorded
nowhere: staging-buffer reuse, golden-result metadata, the performance-evaluation
policy's unexercised state, two hardware-gated interaction targets, and the
outstanding Review of the quantitative-evidence rule.

## Affected modules

Documentation only. No product source changes.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

`check_requirement_traceability.py` reports 18 untraced rows, all owner-gated.

## Migration

1. Remove the eleven now-visible rows from the debt baseline.
2. The remaining eighteen stay until the owner answers the codec and DICOMKit
   questions.

## Supersession

This record supersedes nothing. It completes the sweep `ADR-0216` began.

## References

- [ADR-0216 - Requirement traceability sweep](ADR-0216-requirement-traceability-sweep.md)
- [ADR-0217 - Vertical slice traceability](ADR-0217-vertical-slice-traceability.md)
- [ADR-0218 - Execution and CPU traceability](ADR-0218-execution-and-cpu-traceability.md)
- [ADR-0219 - Governance and licence traceability](ADR-0219-governance-and-licence-traceability.md)
- [VOXELIA-ALG-0006 - Region origin shift](../../algorithms/VOXELIA-ALG-0006-region-origin-shift.md)
- [VOXELIA-ALG-0008 - Nearest-neighbour resampling](../../algorithms/VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
- [VOXELIA-ALG-0015 - Bilinear resampling](../../algorithms/VOXELIA-ALG-0015-bilinear-resampling.md)
- [VOXELIA-ALG-0021 - Cubic resampling](../../algorithms/VOXELIA-ALG-0021-cubic-resampling.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
