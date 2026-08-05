---
document_id: "ADR-0181"
title: "Bricked and multi-resolution volume assessment"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-011"
---

# ADR-0181 - Bricked and multi-resolution volume assessment

## Context

`VOX-DVR-011` — the renderer shall support bricked and
multi-resolution volumes — was never named in accepted `ADR-0165`'s
decomposition of the volume-rendering arc; its requirement list runs
`VOX-DVR-001` through `010`, skips straight to `012`, and never
returns. This record closes that gap: a documentation-only assessment
under the `ADR-0114`, `ADR-0121` and `ADR-0145` precedent for the half
already discharged by composition, plus one proving test. It was
authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **Bricked-volume rendering is discharged by composition, proven
   not merely asserted.** `BrickedImageStorage` (accepted `ADR-0154`/
   `ADR-0155`) conforms to the same `ImageStorageContract` as
   `ContiguousImageStorage` and erases into the same `AnyImageStorage`
   box; `StorageReadCoordinator.read(from:region:)` and the
   `RegionReadTransaction` admission gate it composes are
   representation-agnostic — they distinguish only `.opaque` from the
   two decoded representations, never bricked from contiguous.
   Accepted `ADR-0156` already states brickedness is "invisible
   through the whole pipeline," proven there for
   `RegionExtractionOperation`. `ExactVolumeRenderer.render()`'s own
   descriptor guards (scalar type, component count, semantic, affine
   geometry) and its one full-region read are equally
   representation-independent — nothing in the renderer inspects the
   storage's concrete type. This record adds the renderer-specific
   proof: a bricked-backed volume renders byte-identically to the
   same volume contiguous-backed, with no renderer code change.
2. **Multi-resolution volumes are not built, and are explicitly
   deferred.** No storage-level multi-level container exists —
   `BrickResolutionLevel` (`ADR-0147`) is an unused index-plus-factors
   pair with a pure extents formula, never used to produce or store
   actual downsampled data, with zero consumers anywhere in the
   package. `BrickRequestBroker` and `BrickResultCache`, the
   subsystem a streaming or on-demand multi-resolution consumer would
   need, are themselves unwired — no production path constructs
   either. The master architecture document's own sketch (section
   16.4) is a materially larger surface than anything accepted so
   far: every level independently defines an image descriptor, a
   downsampling method, a relationship to the source geometry, a
   brick grid and its own provenance. Freezing that shape now, with
   no consumer forcing the downsampling method or the level-selection
   policy, would guess requirements a real consumer must supply — the
   same reasoning that deferred oriented clip planes and multi-volume
   compositing.
3. **`VOX-DVR-011` therefore holds in two different senses**: its
   bricked half by proven composition, recorded here; its
   multi-resolution half by an explicit, bound deferral, not by
   silent omission. `ADR-0165`'s decomposition gap is corrected going
   forward by this record rather than by editing the frozen record
   itself.

## Alternatives considered

Silently treating `VOX-DVR-011` as satisfied because bricked storage
already exists was rejected: an unrecorded, untested inference is not
evidence, and `ADR-0165`'s own omission shows how an assumption can go
unclaimed. Building a minimal multi-resolution container now — for
example a single fixed extra level with no selection policy — was
rejected: even a "minimal" pyramid still requires inventing a
downsampling execution path and a multi-level storage shape with no
consumer to validate the choice against, the same speculative-surface
risk `ADR-0145` already declined to take for logging.

## Consequences

`VOX-DVR-011`'s bricked half is closed with a passing proof; its
multi-resolution half remains open, explicitly gated on a consumer
arc, tracked here rather than silently absent.

## Affected modules

`VoxeliaMetal` test target only — one proving test; no `Sources/`
change in any module.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None; the proving test exercises the existing read path unchanged.

## Validation impact

`ExactVolumeRendererTests` gains a test rendering the same volume
contiguous-backed and bricked-backed, asserting byte-identical output.

## Migration

None.

## Supersession

No record is superseded; corrects `ADR-0165`'s decomposition by
addition, not by edit.

## References

- [ADR-0114 - Clinical pipeline assessments](ADR-0114-clinical-pipeline-assessments.md)
- [ADR-0121 - Window edge-case assessment](ADR-0121-window-edge-case-assessment.md)
- [ADR-0145 - Diagnostics and logging assessment](ADR-0145-diagnostics-assessment.md)
- [ADR-0147 - Brick vocabulary design](ADR-0147-brick-vocabulary-design.md)
- [ADR-0154 - Bricked storage design](ADR-0154-bricked-storage-design.md)
- [ADR-0155 - Bricked image storage](ADR-0155-bricked-image-storage.md)
- [ADR-0156 - Bricked image aggregate](ADR-0156-bricked-image-aggregate.md)
- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
