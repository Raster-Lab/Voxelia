---
document_id: "ADR-0377"
title: "Explicit frame geometry models"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DCM-011"
  - "VOX-SPA-012"
---

# ADR-0377 - Explicit frame geometry models

## Context

`VOX-DCM-011` (P1, `I,T`, M7): enhanced multi-frame and irregular
frame-set support shall be introduced through explicit geometry models
rather than hidden regularisation. `VOX-SPA-012` (P1, `I,T`, M7): the
architecture shall permit rectilinear and irregular frame-set geometry
without forcing them into a false regular affine volume. The two rows
are one vocabulary: `SpatialGeometry` today has exactly the `affine`
case, so anything irregular either lies (regularised into affine) or
cannot enter. `ADR-0027` already fixed the anchor-index boundary these
models sit behind.

## Decision

1. **`SpatialGeometry` gains two cases**:
   `rectilinear(RectilinearGridGeometry)` and
   `frameSet(FrameSetGeometry)`. The vocabulary widens; nothing is
   coerced.

2. **`RectilinearGridGeometry`** — shared orientation, explicit slice
   positions: an origin, row/column/normal directions, positive finite
   in-plane spacings, and a **strictly monotone** list of finite slice
   offsets along the normal. Exactly equal adjacent positions refuse:
   averaging or deduplicating them is precisely the hidden
   regularisation the row prohibits.

3. **`FrameSetGeometry`** — fully irregular: a declared frame axis and
   one `FramePlaneGeometry` per frame (origin, row/column directions,
   spacings), each admitted independently in the one declared space. No
   relationship between frames is asserted or checked, because none is
   promised.

4. **No conversion to affine exists.** Neither model offers a "best
   affine approximation" — that is the false regular volume `VOX-SPA-012`
   prohibits, and its absence is the inspection half of both rows. A
   consumer that needs a regular grid must resample explicitly through
   an operation that records what it did.

5. **Descriptor admission checks the new axis references**: a
   rectilinear geometry's spatial axes and a frame set's frame axis must
   reference axes inside the image's rank, mirroring the affine check.

6. **Codable round-trips revalidate**, in the standing
   `SpatialGeometryCoding` strict externally-tagged style — decoded
   values pass through the same throwing admissions.

## Alternatives considered

### Regularising near-regular frame sets into affine at import

Rejected. That is the named prohibition of both rows.

### A tolerance-based regularity classifier

Rejected. Every tolerance is an arbitrary knob; classification is a
consumer decision over explicit data.

## Consequences

Enhanced multi-frame DICOM and irregular frame sets have an honest
target vocabulary; the adapter-capabilities row builds on it next.

## Affected modules

`VoxeliaSpatial` gains the two models and their error family;
`VoxeliaCore`'s descriptor admission checks the new axis references.

## Compatibility impact

Additive cases on a public enum: exhaustive switches in consumers gain
cases (all in-tree consumers use `if case .affine`, which compiles
unchanged and refuses the new cases through their existing fallbacks).

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(frames)` at admission.

## Validation impact

```text
swift test --filter FrameGeometryTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the models, the coding, the descriptor check, the
   fixture suite and the register updates, in the same increment.
2. **Next**: the DICOM adapter-capabilities row.

## Supersession

This record supersedes nothing; it completes what `ADR-0027` bounded.

## References

- [ADR-0027 - Frame geometry anchor-index boundary](ADR-0027-frame-geometry-anchor-index-boundary.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
