---
document_id: "ADR-0375"
title: "The explicit centreline"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-MPR-012"
---

# ADR-0375 - The explicit centreline

## Context

The curved-planar/DICOM-tails arc opens. `VOX-MPR-012` (P1, `I,T`, M7):
curved planar reconstruction shall accept an **explicit centreline in
physical coordinates**. The row is the input model — a CPR that invents
or resamples its own centreline has hidden the clinically decisive
input; this row makes it a declared, admitted value.

## Decision

1. **`CurvedCentreline` is an ordered polyline in one declared space**
   (`VOXELIA-ALG-0074`, `curved-centreline/binary64-v1`): a
   `CoordinateSpaceDescriptor` plus `N ≥ 2` `Point3D`s, every point
   validated to live in the declared space, consecutive coincident
   points refused — a zero-length segment cannot parameterise, and
   silently dropping it would edit the clinician's input.

2. **Arc length is the parameterisation, frozen at admission**: segment
   lengths, cumulative marks and the total are computed once with
   frozen folds and stored. `position(atArcLength:)` is the one lookup:
   interior vertices and the far endpoint are exact **by rule** (mark
   hits give `t = 0`; the total returns the last point verbatim), so
   the downstream rows can anchor to vertices without rounding
   anxieties.

3. **A polyline, not a spline.** Smoothing or spline interpolation of
   the centreline is a *processing* decision that changes where the
   reconstruction looks; if a consumer wants a smoothed path, it
   supplies the smoothed polyline explicitly. The model does not bend
   the input.

4. **This is the arc's foundation increment**: the back-mapping row
   (output positions to source patient coordinates) composes this
   lookup next, and the CPR sampling itself follows.

## Alternatives considered

### A spline centreline model

Rejected — decision 3. A spline is a different input, not a nicer
representation of the same one.

### Index-space centrelines

Rejected. The row says physical coordinates; index-space paths would
bind the centreline to one volume's grid and break under resampling.

## Consequences

CPR rows compose an admitted, exactly parameterised input; nothing
downstream re-derives geometry.

## Affected modules

`VoxeliaSpatial` gains `CurvedCentreline` and its error family.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(N)` at admission, `O(N)` per lookup.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0375-curved-centreline-oracle.py
swift test --filter CurvedCentrelineTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0074`, the type, the fixture suite and the
   register updates, in the same increment.
2. **Next**: the back-mapping row, composing this lookup.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0074 - Curved centreline](../../algorithms/VOXELIA-ALG-0074-curved-centreline.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
