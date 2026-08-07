---
document_id: "ADR-0331"
title: "Shrink the untagged test backlog"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-001"
---

# ADR-0331 - Shrink the untagged test backlog

## Context

`ADR-0330` exhausted `ADR-0319`'s queue: **0 of 356 entered-milestone rows are unclaimed.**
What remains needs no requirement row — the two ratchets this arc created carry real backlogs,
and neither waits on an owner decision.

`ADR-0301` recorded 219 tests carrying no level tag, across 27 files, and said the backlog
"shrinks opportunistically, whenever one of those 27 files is touched for another reason".
This does it deliberately instead, because opportunistic shrinking of a 219-item debt is
another way of saying it stays.

## The measurement

The 219 fell into two clear groups:

- **206 in the DICOM ingest suites** — `CTFrameDescription`, `CTValueInterpreter`,
  `CTSeriesAssembler`, `CTGeometryValidator`, `CTVolumeLayout`, the volume builders, the sample
  inspector and normaliser, and the two `VoxeliaDICOMKit` adapters.
- **13 module-linkage assertions**, one or two per target, of the form "VoxeliaCore M0 target is
  linked".

Both groups are unit-level: each exercises one type's construction, validation or refusals.
The registered operations are elsewhere and were already tagged `[Operation]` by `ADR-0301`.

## Decision

1. **198 tests are tagged `[Unit]`**, and the baseline is regenerated downward from 219 to 21.
2. **`CTVolumeBridgeCompositionTests` is deliberately skipped**, all 7 of its tests. Its name
   says *composition*, which is what `[Integration]` describes, and a pass whose job is to
   remove ambiguity should not resolve one by guessing. It stays in the baseline for a
   considered look.
3. **The remaining 14 are multi-line `@Test(` forms** the prefixing did not reach. They are left
   rather than hand-edited at the end of a pass, and the ratchet holds them at their current
   count.
4. **`[Unit]` is the conservative choice, not a shrug.** Reclassifying any of the 198 to
   `Kernel`, `Operation` or `Pipeline` later is a strict improvement the ratchet permits; the
   tag being *absent* was the defect, because it made a level's coverage unmeasurable.
5. **No test's behaviour changes.** Only display strings, and the suite is unchanged at 1238 in
   219.

## Alternatives considered

### Tag all 219 including the bridge-composition suite

Rejected; see decision 2. Seven tests tagged on a guess would put a level's name on evidence
nobody read, which is the defect `ADR-0300` and `ADR-0324` each had to avoid.

### Leave the backlog to opportunistic shrinking

Rejected. `ADR-0301` wrote that in good faith and it is how a 219-item debt becomes permanent:
the 27 files are stable ingest suites, so "whenever touched for another reason" may be never.

### Reclassify while tagging

Rejected as two jobs. Adding a missing tag is mechanical and reviewable; deciding whether a
volume builder is a unit or an operation is a judgement per file, and bundling them would make
198 mechanical edits indistinguishable from 15 judgements.

## Consequences

The untagged backlog falls from **219 to 21** — a 90 per cent reduction — and the 21 that remain
are two named, specific cases rather than an undifferentiated pile.

`Unit` rises from 843 to 1041, and the level counts are now a fair picture of the suite rather
than one with 219 tests missing from it.

## Affected modules

None. Level tags on 198 existing tests and a tightened baseline. No source file changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test
swift format lint --strict --recursive Tests/
python3 Tools/Scripts/check_test_levels.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged. Zero line-length findings across `Tests/`.

## Migration

1. This record and the retagging.
2. **Next**: the 21 remaining — 7 needing a level judgement, 14 needing multi-line handling —
   and the 121-spelling ratchet, which is the same shape of debt.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **discharges most of the debt** `ADR-0301` recorded.

## References

- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0321 - British English ratchet](ADR-0321-british-english-ratchet.md)
- [ADR-0330 - Frame rate target needs its hardware](ADR-0330-frame-rate-target-needs-its-hardware.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
