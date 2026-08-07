---
document_id: "ADR-0363"
title: "Segment statistics"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SEG-009"
---

# ADR-0363 - Segment statistics

## Context

`VOX-SEG-009` requires segmentation statistics computed from authoritative
image and segment data. `VOXELIA-ALG-0067` freezes the rule; this record
designs the surface and settles where the numbers come from and where they
do not.

## Decision

1. **`SegmentStatisticsComputer.compute`** in `VoxeliaExecution` reads the
   stored image and the mask through the budgeted coordinated boundary and
   returns a `SegmentStatistics` value: mask count, included count, the
   padded and non-finite exclusion counts as **visible numbers**, sum,
   mean, minimum and maximum over exactly widened stored values in the
   frozen fold order, and the calibrated cell and physical volumes
   composing the `VOXELIA-ALG-0016` determinant authority directly — the
   same authority `VOXELIA-ALG-0019`'s measurement wraps, reached from
   below because the layering runs the other way.

2. **No registry entry and no published object**: the computer publishes
   nothing, so minting a derivation would fabricate provenance for an
   object that does not exist. A consumer persisting statistics composes
   the accepted measurement-publication pattern (the mesh measurements'
   precedent) in its own record.

3. **Padding excludes intensity, not extent**: a padded voxel leaves the
   mean but stays in the physical volume, because the mask claims its
   space — both counts are published so the reader sees exactly what each
   number is over.

4. **`VOX-SEG-009` is discharged by this increment.**

## Alternatives considered

### A registered operation publishing a statistics object

Rejected for now; see decision 2.

### Excluding padded voxels from the physical volume

Rejected; see decision 3. The mask is the authority on extent; padding is
the authority on intensity validity.

## Consequences

`VOX-SEG-009` is discharged; the arc's last row is the AI-adapter boundary
(`VOX-SEG-010`).

## Affected modules

`VoxeliaExecution` gains the computer and its value type.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One pass over both reads.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0363-segment-statistics-oracle.py
swift test --filter SegmentStatisticsTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0067` and the oracle.
2. The computer, its value type and the fixture tests, in the same
   increment.
3. **Next**: the AI-adapter boundary (`VOX-SEG-010`), closing the arc's
   engineering half.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0067 - Segment statistics](../../algorithms/VOXELIA-ALG-0067-segment-statistics.md)
- [ADR-0362 - Mask editing](ADR-0362-mask-editing.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
