---
document_id: "ADR-0218"
title: "Execution and CPU traceability"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-008"
  - "VOX-EXE-001"
  - "VOX-EXE-005"
  - "VOX-EXE-008"
  - "VOX-EXE-010"
  - "VOX-CON-002"
  - "VOX-CCH-006"
  - "VOX-CPU-002"
  - "VOX-CPU-003"
  - "VOX-CPU-004"
  - "VOX-CPU-005"
  - "VOX-CPU-007"
  - "VOX-CPU-008"
  - "VOX-CPU-009"
---

# ADR-0218 - Execution and CPU traceability

## Context

`ADR-0217` paid down the first block of the traceability debt `ADR-0216`
measured, taking it from 75 rows to 66, and established that **traced is not
discharged**: the list measures visibility, because invisibility is what hid
`VOX-MPR-011`.

The next tractable block is the thirteen execution, concurrency, cache and CPU
rows: `VOX-EXE-001`, `005`, `008`, `010`; `VOX-CON-002`; `VOX-CCH-006`; and
`VOX-CPU-002`, `003`, `004`, `005`, `007`, `008`, `009`. `ADR-0217`'s ledger
entry predicted some would come back unbuilt. Four did.

## Findings, per row

### Satisfied and now traced

- **`VOX-EXE-001`** (operations are immutable descriptions of typed
  transformations or render requests, **I,T**). Both halves exist as immutable
  values: `RegisteredImplementation` under `ADR-0134` is a `Sendable, Hashable`
  description carrying the operation token, version, backend, precision policy,
  approximation status and validation evidence; `RenderRequest` and
  `VolumeRenderRequest` under `ADR-0085` and `ADR-0174` are the immutable
  render-request half.
- **`VOX-EXE-010`** (deduplicate identical in-flight operations where safe,
  **T**). Satisfied by `BrickRequestBroker`, which keys in-flight work and
  shares one computation among identical requests. "Where safe" is honoured by
  the scope: the broker coalesces brick requests, and no operation is coalesced
  merely for looking alike.
- **`VOX-CON-002`** (the primary execution engine is actor-isolated, **I,T**).
  Every coordinating type in `VoxeliaExecution` is a `public actor`:
  `PublicationCoordinator`, `StorageReadCoordinator`, `ContentResultCache`,
  `BrickResultCache`, `BrickRequestBroker` and `MetadataIdentityCoordinator`.
- **`VOX-CCH-006`** (bounded memory and explicit eviction, **T,A**).
  `ContentResultCache` admits a `maximumEntryCount` and a
  `maximumTotalByteCount` and performs **no implicit eviction** — removal is a
  caller's explicit act, which is stronger than the requirement asks and is the
  right default for a cache whose entries are diagnostic results. Only the
  **Test** half is claimed; the Analysis half needs a measurement workload,
  which is a standing gated item.
- **`VOX-CPU-002`** (clarity, determinism and numerical traceability over
  speed, **I,R,T**). This is the project's central discipline rather than one
  file: every CPU reference kernel has a frozen expression order, an accepted
  algorithm specification and an independent Python oracle whose digests it
  reproduces bit-exactly. Only **Inspection** and **Test** are claimed; the
  **Review** half is an owner act, not something a record can self-certify.
- **`VOX-CPU-003`** (optimised implementations remain distinguishable from
  reference ones, **I,T**). `RegisteredImplementation` carries `backend`,
  `precisionPolicy` and `approximationStatus` as separate claims, and every
  registered identifier names its backend — `org.voxelia.impl.*.cpu` beside the
  Metal entries. A caller can tell them apart without reading source.
- **`VOX-CPU-005`** (deterministic reductions under the documented policy,
  **T**). Satisfied by the accepted reduction models — `VOXELIA-ALG-0031`,
  `VOXELIA-ALG-0032` and their kin — each with a frozen accumulation order, no
  fused multiply-add, and registered digests.
- **`VOX-CPU-007`** (validate strides, bounds, alignment assumptions and scalar
  formats, **T**). Every accepted operation admits its input explicitly before
  reading it: extents, rank, scalar type, component count and interpretation
  are all checked and rejected typed, with `ObliqueSliceOperation` and
  `CompositeLayersOperation` as representative evidence.
- **`VOX-CPU-009`** (a CPU-only build of backend-neutral modules remains
  possible, **I,T**). Verified by building the target in isolation:
  `swift build --target VoxeliaCPU` succeeds, and `VoxeliaCPU`'s
  prohibited-import set already forbids `Metal` and `MetalKit`, so the property
  is mechanically enforced rather than incidental.

### Not satisfied

- **`VOX-EXE-005`** (lazy evaluation of dependencies, **T**). **Unbuilt.**
  There is no deferred-evaluation mechanism anywhere in `VoxeliaExecution`;
  every operation is an eager `async` call whose inputs the caller has already
  produced.
- **`VOX-EXE-008`** (progress reporting as an asynchronous stream or equivalent,
  **T**). **Unbuilt.** No progress API exists in any module. The only matches
  for the word are `CompressedRegionAccess.progressiveResolution`, which is a
  storage access mode and unrelated.
- **`VOX-CPU-008`** (benchmarks distinguish scalar reference, SIMD-optimised and
  Accelerate-backed implementations, **T,A**). **Not satisfiable yet, and the
  reason is precise**: no SIMD or Accelerate implementation exists, so there is
  nothing for a benchmark to distinguish. The row becomes actionable the moment
  the first optimised implementation lands, and not before.
- **`VOX-CPU-004`** (Accelerate and vImage permitted only behind validated
  Voxelia operation semantics, **I,T**). No source imports `Accelerate`,
  `vImage` or `simd`, so the permission is unexercised — but see the
  enforcement finding below, which this record acts on.

## The enforcement finding

`VOX-CPU-004` permits Accelerate and vImage **only** behind validated operation
semantics. Until now **no module's prohibited-import set mentioned either**, so
the first `import Accelerate` into `VoxeliaCore` or `VoxeliaRendering` would
have passed every check in the repository. The constraint was asserted in the
baseline and enforced nowhere.

This is exactly the shape `ADR-0196` recorded for Model I/O, and it gets the
same treatment: `Accelerate` and `vImage` are added to the prohibited-import
set of the seven **backend-neutral** modules — `VoxeliaSpatial`, `VoxeliaCore`,
`VoxeliaStorage`, `VoxeliaExecution`, `VoxeliaImaging`, `VoxeliaGeometry` and
`VoxeliaRendering` — where they have no business at all.

**`VoxeliaCPU` is deliberately excluded from that addition.** `VOX-CPU-004`
*permits* Accelerate there behind validated semantics, so prohibiting it would
overrule the requirement rather than enforce it. When an Accelerate-backed
implementation is proposed, it arrives with its own record, its validated
precision claim and its `approximationStatus`, and `VoxeliaCPU` is where it
belongs.

The check passes unchanged, confirming no existing violation.

## Decision

1. **Nine rows are traced to their evidence**: `VOX-EXE-001`, `VOX-EXE-010`,
   `VOX-CON-002`, `VOX-CCH-006`, `VOX-CPU-002`, `003`, `005`, `007` and `009`.
2. **Partial verification methods are claimed as such, never rounded up.**
   `VOX-CCH-006`'s Analysis half needs a gated measurement workload;
   `VOX-CPU-002`'s Review half is an owner act. Both are stated rather than
   quietly folded into a green tick.
3. **`VOX-CPU-009` is verified by actually building it**, not by reading the
   package manifest. `swift build --target VoxeliaCPU` succeeds.
4. **Four rows are recorded as not satisfied**, with specifics:
   `VOX-EXE-005` and `VOX-EXE-008` are unbuilt; `VOX-CPU-008` is not satisfiable
   until an optimised implementation exists; `VOX-CPU-004`'s permission is
   unexercised.
5. **The enforcement gap `VOX-CPU-004` exposed is closed now**, because it is a
   one-line policy change that prevents a real future error, and leaving it for
   a later increment would be leaving a door open having just noticed it.
6. **All thirteen rows leave the debt list**, taking it from 66 to 53. Traced is
   not discharged: the four unsatisfied rows are now visible with recorded
   reasons, and their outstanding status lives in the ledger.
7. **No product source is written.** Every trace points at work that already
   passes its tests; the only change is a tooling policy set.

## Alternatives considered

### Prohibit Accelerate everywhere, including `VoxeliaCPU`

Rejected; see the enforcement finding. It would overrule `VOX-CPU-004`'s
explicit permission rather than enforce its condition.

### Leave the Accelerate enforcement gap for its own increment

Rejected; see decision 5.

### Claim `VOX-CPU-008` as satisfied because benchmarks exist

Rejected. Benchmarks exist, but the row asks them to *distinguish* three
implementation classes and only one class exists. Claiming it would be reporting
a distinction nobody can make.

### Claim `VOX-CPU-002`'s Review half

Rejected; see decision 2. A record cannot review itself.

## Consequences

The traceability debt falls from 66 to 53 rows. Four new capability gaps are
explicit and visible: lazy evaluation, progress reporting, benchmark
classification, and the unexercised Accelerate permission — none of which was
previously written down anywhere.

The first `import Accelerate` into a backend-neutral module now fails a check.

## Affected modules

Tooling only: `Tools/Scripts/check_prohibited_imports.py`. No product source
changes.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

`check_prohibited_imports.py` passes with the widened policy, confirming no
existing violation. `swift build --target VoxeliaCPU` succeeds.
`check_requirement_traceability.py` reports the reduced debt.

## Migration

1. Remove the thirteen now-visible rows from the debt baseline.
2. Lazy evaluation and progress reporting need their own records when a
   consumer requires them; neither has one today.

## Supersession

This record supersedes nothing. It labels existing work and closes an
enforcement gap in the same shape `ADR-0196` closed for Model I/O.

## References

- [ADR-0085 - Render request, result and protocol](ADR-0085-render-request-result-and-protocol.md)
- [ADR-0134 - Implementation registration](ADR-0134-implementation-registration.md)
- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0216 - Requirement traceability sweep](ADR-0216-requirement-traceability-sweep.md)
- [ADR-0217 - Vertical slice traceability](ADR-0217-vertical-slice-traceability.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
