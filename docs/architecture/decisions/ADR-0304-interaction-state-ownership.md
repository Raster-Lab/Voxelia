---
document_id: "ADR-0304"
title: "Interaction state ownership"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-009"
---

# ADR-0304 - Interaction state ownership

## Context

`VOX-ARC-009` requires that "`VoxeliaInteraction` shall own UI-framework-neutral interaction
state and commands". P0, **`I,R`**, milestone M4, from `ADR-0290`'s sweep.

## The measurement

`VoxeliaInteraction` publishes twenty-four types across five files, and they are exactly the
row's subject:

| Kind | Types |
|---|---|
| Commands | `InteractionCommand`, `MeasurementCommand` |
| Interaction state | `CrosshairState`, `ViewportSyncGroup`, `SyncedViewport`, `ClipBox`, `ZoomFactor`, `PanDelta`, `RotationAngle`, `RenderGeneration` |
| Resolution and presentation | `PickTarget`, `PickResolver`, `PickResolution`, `FramePresenter`, `StampedFrame`, `PresentationOutcome`, `RenderGenerationCounter`, `CrosshairSyncOutcome`, `CrosshairSyncResolution` |
| Measurement values | `MeasurementConstruction`, `AngleMeasurement`, `PolygonAreaMeasurement`, `VoxelVolumeMeasurement` |
| Failures | `InteractionError` |

**Nothing outside the module holds interaction state.** The only candidate the scan surfaced
was `MPRSliceCoordinator` in `VoxeliaImaging`, which uses the word *crosshair* while mapping a
world point to a slice index. That is geometry: it imports `VoxeliaCore`, `VoxeliaExecution`
and `VoxeliaSpatial`, holds no state and never names an interaction type.

## The finding

The row's `I` was **delivered** — by `ADR-0111`'s command vocabulary and the records after it —
and no record ever claimed the row. This is the same shape as `VOX-VAL-006`: the evidence
existed and the record trail did not point at it.

## Decision

1. **`VOX-ARC-009`'s `I` is discharged** on the surface above.
2. **The two properties the row names are already enforced, by gates that exist.** No new gate
   is added, because a third one checking the same facts would be ceremony:
   - *UI-framework-neutral* — `check_prohibited_imports.py` refuses `AppKit`, `UIKit`,
     `SwiftUI` and `MetalKit` in `VoxeliaInteraction`, and since `ADR-0303` in every other
     target too.
   - *Owns* — `check_package_graph.py` pins the graph exactly: `VoxeliaInteraction` depends
     only on `VoxeliaRendering`, and only the umbrella `Voxelia` depends on it. No other module
     can consume interaction state, so none can grow a second copy that callers would reach
     instead.
3. **The `R` is not claimed.** Review is an owner judgement. It joins `VOX-VAL-006`'s `R` and
   `VOX-HLS-001`'s `D` on the outstanding list.

Concretely, what the owner is being asked to review is whether *"interaction state"* is the
right boundary — in particular whether the four measurement value types belong in an
interaction module or in a spatial one. They are constructed by interaction commands and
consumed by presentation, which is why they sit here; that is a defensible placement and not
the only one.

## Alternatives considered

### Add a gate asserting no interaction type appears outside the module

Rejected; see decision 2. The dependency graph already makes it unreachable, and a gate whose
condition another gate guarantees is a gate that will be deleted the first time it is
inconvenient.

### Move the measurement types to `VoxeliaSpatial`

Not decided here, and deliberately so. It is exactly the judgement the row's `R` exists for,
and making it unilaterally would spend the owner's decision for them.

### Claim the `R` because the `I` is evident

Refused, consistently with `ADR-0300` and `ADR-0303`.

## Consequences

`VOX-ARC-009`'s implementation obligation is discharged and its enforcement is named rather
than re-implemented.

**11 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. This record adds no code and changes no gate.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
python3 Tools/Scripts/check_package_graph.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1229 tests in 217 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the derived queue's remaining 11 rows.
3. **Owner**: **one new item** — whether the measurement value types belong in
   `VoxeliaInteraction` or `VoxeliaSpatial`, which is this row's `R`.

## Supersession

This record supersedes nothing. It **claims** a row whose implementation `ADR-0111` and its
successors had already delivered.

## References

- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0300 - CPU Metal differential references](ADR-0300-cpu-metal-differential-references.md)
- [ADR-0303 - Headless rendering enforced](ADR-0303-headless-rendering-enforced.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
