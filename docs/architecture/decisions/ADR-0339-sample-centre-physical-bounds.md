---
document_id: "ADR-0339"
title: "Sample-centre physical bounds"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SPA-010"
---

# ADR-0339 - Sample-centre physical bounds

## Context

`VOX-SPA-010` — "spatial bounds shall be computable in index and physical coordinates",
P0, `T`, M1 — was measured half-built by `ADR-0323`: `ImageRegion` serves the index
half, `AxisAlignedBounds3D` exists, and no function anywhere produces physical bounds
from a volume's description. That record froze the implementation hazard (the
two-corner transform is wrong under rotation) and named the modelling question
(centres or extents). `ADR-0338` decision 7 answered it: **sample centres**, matching
DICOM. This record designs the producer; `VOXELIA-ALG-0054` freezes its arithmetic;
the same increment implements both.

## Decision

1. **The producer is a method on the admitted geometry**:
   `AffineGridGeometry.sampleCentreBounds(slot0SampleCount:slot1SampleCount:slot2SampleCount:)`
   returning `AxisAlignedBounds3D` in the geometry's coordinate space. The geometry
   already carries the transform and the space, so a separate namespace type would
   add a name without adding information. The three counts are labelled parameters
   in slot order — the same slot order `indexToWorld` consumes.

2. **The bounds enclose the outermost sample centres** — the corner set is the
   continuous indices `0` and `n_s - 1` per slot, per `ADR-0338` decision 7. The
   half-voxel extents variant is a different, unbuilt policy; nothing here
   pre-empts a future record adding it beside this one.

3. **The construction is the eight-corner hull `ADR-0323` demanded**, with
   traversal, expression and fold order frozen in `VOXELIA-ALG-0054`, and the
   two-corner shortcut's wrong answer registered as a conformance fixture so the
   predicted defect stays permanently visible in the evidence.

4. **The failure family is three cases with attribution**, payload-carrying in the
   module's own style (`SpatialBoundsError` precedent):
   `nonPositiveSampleCount(slot:count:)`,
   `sampleCountNotExactlyRepresentable(slot:count:)` and
   `cornerNotRepresentable(cornerOrdinal:axis:)`. The representability check runs
   before point construction so the failure names the corner computation, not the
   point type that never saw the value — the attribution rule `ADR-0258`'s
   lying-codec case established.

5. **Sample counts carry an explicit inclusive ceiling of `2^53`** so every corner
   coordinate is exactly representable and "the outermost sample centre" is the
   published value, not a rounded neighbour. A count above the ceiling is a typed
   rejection, not a silent rounding.

6. **`invertedBounds` and `nonFiniteComponent` are made unreachable, not handled.**
   The fold's minima never exceed its maxima, and the finiteness check precedes
   `Point3D` construction, so the bounds and point admissions cannot fail
   downstream of this producer. The implementation asserts this by construction
   rather than carrying dead error paths (`ADR-0071`/`ADR-0173` precedent).

7. **A published component is never negative zero, and the proof is recorded** in
   `VOXELIA-ALG-0054` rather than left as folklore: the final addition is with a
   translation element `Matrix4x4Double` normalised on admission, and IEEE 754
   round-to-nearest addition returns `-0.0` only when both addends are `-0.0`.
   `Point3D`'s canonicalisation is therefore provably inert here.

8. **`VOX-SPA-010` is discharged by this increment** — the index half was already in
   place, the physical half now has a producer, and the row's `T` verification is
   met by the oracle-fixture tests. No demonstration half exists on this row.

## Alternatives considered

### Transform the two extreme index corners

Rejected before it was written — `ADR-0323` decision 2 records it as the defect that
passes a hurried author's tests. Fixture 5 registers its wrong answer beside the
correct hull.

### A free function or namespace enum instead of a method

Rejected. `AffineTransformAlgebra` is a namespace because its operations take two
matrices with no owning value; here the geometry owns both the transform and the
coordinate space, and a method keeps the space from being passed twice.

### Host the producer in `VoxeliaCore` beside `ImageShape`

Rejected for the primitive. `VoxeliaCore` depends on `VoxeliaSpatial`, so Spatial
cannot see `ImageShape`; the arithmetic belongs with the geometry vocabulary that
owns it. A Core convenience taking an `ImageShape` remains open to a consumer-driven
increment and would compose this method unchanged.

### Let `Point3D` reject the non-finite component

Rejected. The rejection would arrive as `nonFiniteComponent(index:)` with no corner
attribution, telling the caller a point was bad rather than which corner of which
volume overflowed — the exact fault-attribution gap decision 4 exists to close.

## Consequences

`VOX-SPA-010` is discharged. Every M1 requirement row is accounted for, and the
producer is available to later consumers (a Core `ImageShape` convenience, viewport
fitting, acceleration-structure sizing) without further numeric decisions.

## Affected modules

`VoxeliaSpatial` gains one public method and one public error enum. No existing type
changes shape; no registered digest is touched.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

Eight point transforms and a fold; no allocation beyond the result.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0339-sample-centre-bounds-oracle.py
swift test --filter SampleCentreBoundsTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The oracle prints every fixture the tests assert. The full suite must show the
literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0054` and the oracle.
2. `AffineGridGeometry.sampleCentreBounds` with `SampleCentreBoundsError` and the
   fixture tests, in the same increment.
3. **Next**: the remaining unblocked rows per `ADR-0338`'s migration order.

## Supersession

This record supersedes nothing. It completes the work `ADR-0323` measured and left
open, under the modelling answer `ADR-0338` decision 7 supplied.

## References

- [VOXELIA-ALG-0054 - Sample-centre physical bounds](../../algorithms/VOXELIA-ALG-0054-sample-centre-physical-bounds.md)
- [ADR-0323 - Spatial bounds half built](ADR-0323-spatial-bounds-half-built.md)
- [ADR-0338 - The owner decision batch](ADR-0338-the-owner-decision-batch.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
