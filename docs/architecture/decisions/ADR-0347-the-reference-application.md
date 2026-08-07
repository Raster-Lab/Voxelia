---
document_id: "ADR-0347"
title: "The reference application"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-VS1-010"
  - "VOX-VS1-012"
  - "VOX-VS1-013"
  - "VOX-MPR-011"
---

# ADR-0347 - The reference application

## Context

`ADR-0338` decision 5 placed the reference application in this repository under
`Examples`, and the outstanding owner-witnessed Demonstrations — the draw-loop
halves of the vertical-slice rows among them — need a vehicle to run in. The
`Examples/VoxeliaCTReference` scaffold has stood empty since M0 with its
contract already written: the application owns lifecycle, controls and layout,
and duplicates no processing logic. This record builds the first version.

## Decision

1. **`VoxeliaCTReference` is a SwiftPM executable package** under
   `Examples/VoxeliaCTReference`, depending on the parent package by path (the
   `Benchmarks` pattern) — a SwiftUI macOS application launched with
   `swift run`. Windowing frameworks live **only here**: the library targets'
   prohibition is untouched, which is exactly what makes the app the right
   home for the draw loop the library refused to own.

2. **The app composes published API and nothing else**: it publishes a
   synthetic study volume, derives the level-one representation with
   `LevelSelectOperation`, starts `StudyCacheGenerator` in a `.utility` task,
   and renders planes through `InteractiveLevelRenderCoordinator` with the
   `MetalSliceRenderer` backend. Scrolling drives `InteractionPhase.active`;
   a host-side debounce — the clock `ADR-0345` assigned to the host — flips to
   `.idle` and issues the refinement render. Every behaviour the release
   Demonstrations must show is therefore driven by the same accepted
   coordinators the suite already proves.

3. **The demonstration set this vehicle serves**: the interactive plane
   demonstrations (`VOX-VS1-010`, `VOX-VS1-012`, `VOX-VS1-013`,
   `VOX-MPR-011`), the level-while-loading and refinement demonstrations
   (`VOX-BRK-009`, `VOX-DVR-013`), priority (`VOX-CON-008`) and first useful
   image (`VOX-PER-006`). **No `T` and no `D` is discharged by this record** —
   building the stage is not witnessing the play; the owner witnesses at
   release.

4. **Version-one bounds are recorded, not hidden**: the volume is synthetic
   (a banded radial phantom, so planes are visually distinct); DICOM directory
   import through `CTImportSession` wires in at release assembly; the
   publication store grows for the session's lifetime (each render publishes
   its stages), sized generously and acceptable for a demonstration vehicle,
   never for a product claim.

## Alternatives considered

### An Xcode project instead of a SwiftPM executable

Rejected. A checked-in project file adds a second build system the gates do
not cover; `swift run` builds from the same manifest discipline as everything
else in the repository.

### Wire DICOM import now

Deferred to release assembly, not refused. The interactive machinery is the
part demonstrations depend on and the part this increment can verify by
composition; the import session is accepted API with its own evidence, and
wiring it is a bounded follow-up.

## Consequences

The demonstration vehicle exists and every remaining `D` has a stage. Release
assembly is the last engineering increment.

## Affected modules

None in the library. The `Examples/VoxeliaCTReference` package is new.

## Compatibility impact

None.

## Security impact

None. The app reads nothing external in this version.

## Performance and memory impact

Interactive rendering uses the slice path; the session store grows as
recorded in decision 4.

## Validation impact

```text
cd Examples/VoxeliaCTReference && swift build
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The app builds clean; its behaviour is the coordinators', already under test.
The full suite must show the literal pass line before push.

## Migration

1. This record with the application.
2. **Next**: release assembly — DICOM import wiring, version, changelog, tag.
3. **Owner**: the Demonstrations run here at release.

## Supersession

This record supersedes nothing. It fills the scaffold the repository baseline
reserved, under `ADR-0338` decision 5's location.

## References

- [ADR-0338 - The owner decision batch](ADR-0338-the-owner-decision-batch.md)
- [ADR-0344 - Interactive level render path](ADR-0344-interactive-level-render-path.md)
- [ADR-0345 - Refinement after interaction stops](ADR-0345-refinement-after-interaction-stops.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
