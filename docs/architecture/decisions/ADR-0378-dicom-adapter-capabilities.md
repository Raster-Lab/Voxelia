---
document_id: "ADR-0378"
title: "DICOM adapter capabilities"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DCM-012"
---

# ADR-0378 - DICOM adapter capabilities

## Context

`VOX-DCM-012` (P1, `I,T`, M7): DICOM segmentation, parametric map,
surface and registration integrations shall map to canonical Voxelia
models through **optional adapter capabilities**. The canonical models
all exist now — `Segmentation` (`ADR-0359`), parametric `ImageData`,
`TriangleMesh`, `RegistrationTransform` (`ADR-0365`) — and the owner's
`ADR-0351` batch still holds the fix-what-surfaces question about
DICOMKit's own SEG reading. The row's shape is `VOX-SEG-010`'s again:
the boundary is buildable now; implementations are not presumed.

## Decision

1. **Four optional capability protocols in `VoxeliaDICOMKit`**, one per
   named integration: `DICOMSegmentationCapability`,
   `DICOMParametricMapCapability`, `DICOMSurfaceCapability` and
   `DICOMRegistrationCapability`. Each takes a parsed `DataSet` and
   returns the corresponding **canonical** model, and each declares an
   `adapterIdentity` for provenance. Optional means exactly that:
   nothing in the base import path requires any of them, and the frame
   pipeline is untouched.

2. **The mapping direction is one-way into canonical vocabulary.** A
   capability produces admitted canonical values through the models'
   own throwing admissions — the section 52.11 invariants, the mesh's
   fixed validation precedence, the transform categories. An adapter
   cannot hand a host anything the canonical door would refuse.

3. **The inspection half is the existing prohibition**: canonical
   modules cannot import `DICOMKit` (`check_prohibited_imports.py`
   already forbids it per target), so the canonical models stay
   DICOM-free and the capabilities live only at the boundary module.
   No new gate is added — the row is served by one that exists
   (`ADR-0338` d10).

4. **`VoxeliaDICOMKit` gains the in-repo `VoxeliaGeometry` dependency**
   so the surface capability can name `TriangleMesh`. The graph stays
   acyclic and no external dependency is touched — the supply chain
   stays owner-reserved.

5. **No reference adapter implementations are built.** DICOMKit's SEG
   and parametric reading sit behind the owner's fix-what-surfaces
   batch answer; conforming implementations follow it. The suite's
   stub conformances prove each capability implementable and its output
   admitted.

## Alternatives considered

### Implementing a SEG reader now

Rejected. It would pre-empt the owner's outstanding batch answer about
DICOMKit surface work.

### Capabilities in `VoxeliaCore` with opaque inputs

Rejected. A capability that cannot name `DataSet` degenerates to a
function type; the boundary module is where both vocabularies are
legitimately visible, and Core stays DICOM-free by gate.

## Consequences

The curved-planar/DICOM-tails arc's engineering closes. The extension
mechanism arc is next per `ADR-0351`.

## Affected modules

`VoxeliaDICOMKit` gains the protocols and the `VoxeliaGeometry`
dependency.

## Compatibility impact

Additive only.

## Security impact

None beyond the canonical admissions the capabilities route through.

## Performance and memory impact

None; protocols only.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
swift test --filter DICOMAdapterCapabilityTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the protocols, the dependency, the stub-conformance
   suite and the register updates, in the same increment.
2. **Next**: open the extension-mechanism arc.
3. **Owner**: conforming adapter implementations follow the
   fix-what-surfaces batch answer.

## Supersession

This record supersedes nothing.

## References

- [ADR-0364 - The AI adapter boundary](ADR-0364-the-ai-adapter-boundary.md)
- [ADR-0377 - Explicit frame geometry models](ADR-0377-explicit-frame-geometry-models.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
