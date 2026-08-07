---
document_id: "ADR-0376"
title: "Curved planar back-mapping"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-MPR-013"
---

# ADR-0376 - Curved planar back-mapping

## Context

`VOX-MPR-013` (P1, `T`, M7): curved planar reconstruction shall map
output positions back to source patient coordinates. A CPR image whose
pixels cannot say where in the patient they came from is a picture, not
a measurement surface — the back-mapping is what makes CPR annotations,
distances and cursor read-outs mean anything.

## Decision

1. **The output parameterisation is arc length by lateral offset**, and
   `CurvedPlanarMapping.patientPosition(atArcLength:lateralOffset:)`
   (`VOXELIA-ALG-0075`, `curved-planar-mapping/binary64-v1`) is the one
   inverse: centre from the `ADR-0375` lookup, lateral direction as the
   normalised rejection of a declared reference direction from the
   segment tangent — the stretched-CPR convention — and
   `centre + offset·lateral`, all frozen.

2. **The reference direction is caller-declared and defaultless**: it
   decides which way "up" is in the reconstruction, which is a clinical
   choice, not a library guess. Admission refuses a zero reference, a
   reference in the wrong space, and a reference exactly parallel to
   any segment — where the lateral direction would be undefined — by
   exact cross-product zero, the standing no-epsilon contract.

3. **The frame is per-segment and piecewise constant.** Rotation-
   minimising frames were rejected for v1: they smuggle an integration
   scheme (and its step-size knob) into what this row needs to be an
   exactly testable mapping. The piecewise frame is discontinuous at
   vertices exactly where the polyline's tangent is, which is honest to
   the declared input; a consumer needing a smoother frame supplies a
   finer polyline.

4. **Sampling is not built here.** This row is the coordinate mapping;
   the CPR image itself (sampling the volume along the mapped
   positions) composes this mapping with the existing interpolation
   machinery in its own increment if a row demands it.

## Alternatives considered

### A rotation-minimising (parallel-transport) frame

Rejected for v1 — decision 3.

### Deriving the reference direction from the dominant patient axis

Rejected. A library guess about "up" is exactly the hidden decision the
arc's rows keep refusing.

## Consequences

CPR output positions are measurable: hosts map any `(s, u)` back to
patient space with pinned determinism.

## Affected modules

`VoxeliaSpatial` gains `CurvedPlanarMapping`.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(N)` per lookup.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0376-curved-planar-mapping-oracle.py
swift test --filter CurvedPlanarMappingTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0075`, the type, the fixture suite and the
   register updates, in the same increment.
2. **Next**: the DICOM tail rows of this arc.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0075 - Curved planar mapping](../../algorithms/VOXELIA-ALG-0075-curved-planar-mapping.md)
- [ADR-0375 - The explicit centreline](ADR-0375-the-explicit-centreline.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
