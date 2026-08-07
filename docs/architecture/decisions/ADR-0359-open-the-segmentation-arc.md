---
document_id: "ADR-0359"
title: "Open the segmentation arc"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SEG-001"
  - "VOX-SEG-002"
  - "VOX-SEG-003"
  - "VOX-SEG-004"
---

# ADR-0359 - Open the segmentation arc

## Context

The foundations arc closed with every operation segmentation composes. The
arc opens where the CDMS already decided it should: **section 52 specifies
the segmentation model in full** — identifiers, algorithm descriptors,
display recommendations, segment descriptors, the two representations, the
aggregate and its eleven invariants — initially hosted in the Core model per
CDMS section 15. This record activates that specification; nothing here is
invented.

## Decision

1. **CDMS section 52 is implemented verbatim in `VoxeliaCore`** with
   validated construction: `SegmentID`, `SegmentAlgorithmDescriptor`,
   `SegmentAlgorithmType`, `SegmentDisplayRecommendation`,
   `SegmentDescriptor`, the `SegmentationRepresentation` two-case
   vocabulary (`labelImage`, `segmentCollection`), their payloads, and the
   `Segmentation` aggregate. Where the specification declares stored
   properties, admission enforces section 52.11's invariants — unique
   segment identifiers, unique label values, representation references
   resolving to declared segments, explicit fractional domains, geometry
   compatibility — as typed rejections, never documentation.

2. **The overlap requirement is discharged structurally** (`VOX-SEG-002`):
   the segment collection holds one mask or fractional field per segment
   and admits overlapping fields by construction; the label image **cannot**
   express overlap, and having both representations — with conversion
   explicit, never silent — is exactly how the model refuses to collapse
   overlap while still offering the exclusive form.

3. **Descriptors carry what `VOX-SEG-003` names**: stable `SegmentID`,
   label, coded category and type, algorithm descriptor (type, name,
   version, model identity), display recommendation (explicitly
   non-authoritative), tracking identity and metadata.

4. **Geometry binding is declared, not implied** (`VOX-SEG-004`): the
   aggregate carries its source space and its own `SpatialGeometry`;
   admission requires every field and label image to share one shape and,
   where a field declares its own geometry, to match the aggregate's — a
   segmentation that disagrees with itself about where it lives is refused
   at the door.

5. **`VOX-SEG-001` through `VOX-SEG-004` are discharged** at `I` (this
   record activating the CDMS specification) and `T` (the invariant suite,
   including the structural overlap witness). The arc continues with
   nearest-neighbour resampling defaults (`VOX-SEG-005` with the discharged
   `VOX-IMG-007` rule), the operation set over the foundations
   (`VOX-SEG-006`), and onward.

## Alternatives considered

### A new VoxeliaSegmentation module now

Rejected. CDMS section 15 hosts the model in Core initially and names the
module as a future activation; creating a target before any
segmentation-only behaviour exists would be a package for a namespace.

### A single label-map model with an overlap workaround

Rejected before design by `VOX-SEG-002`'s own words; the two-representation
vocabulary is the CDMS answer.

## Consequences

The segmentation model exists with its invariants enforced; the arc's
remaining rows compose it and the foundations operations.

## Affected modules

`VoxeliaCore` gains the section-52 types. No existing type changes shape.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

Admission-time validation only.

## Validation impact

```text
swift test --filter SegmentationModelTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record.
2. The model, its admission and the invariant suite, in the same increment.
3. **Next**: `VOX-SEG-005` and `VOX-SEG-006` over the foundations.

## Supersession

This record supersedes nothing. It activates CDMS section 52 as written.

## References

- [ADR-0352 - Open the processing foundations arc](ADR-0352-open-the-processing-foundations-arc.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
