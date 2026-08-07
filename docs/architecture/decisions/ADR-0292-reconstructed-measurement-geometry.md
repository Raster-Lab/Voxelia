---
document_id: "ADR-0292"
title: "Reconstructed measurement geometry"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-014"
  - "VOX-INT-006"
---

# ADR-0292 - Reconstructed measurement geometry

## Context

`VOX-MPR-014` requires that "measurements made in reconstructed views shall use
authoritative physical geometry". P0, `T` alone, milestone M4, and one of the rows
`ADR-0290`'s sweep found untouched.

The plan states the hazard outright in §33.5 — "screen distance shall never be used as the
authoritative physical distance" — and §33.3 adds view independence: a measurement created
in one viewport stays spatially correct in another compatible one.

## The chain under test

Pixel → `PickResolver` → `Point3D` → `MeasurementConstruction`.

`PickResolver` maps a viewport index through the **presented geometry's own**
`indexToWorld`, so the physical position is the view's claim rather than anything derived
from pixel counts. `MeasurementConstruction` then takes `Point3D` values — which carry a
coordinate space — and never sees a viewport at all.

So screen-pixel measurement is not merely discouraged; there is no constructor that accepts
pixels. What needed testing was that the physical position genuinely tracks the geometry.

## The defect this found

Writing the suite **crashed the test process**: `Fatal error: Index out of range`.

`PickResolver` builds its index array from exactly two values, the viewport's x and y, and
then reads `indices[imageAxis]` for every axis in the presented geometry's mapping.
`SpatialAxisMapping` admits **one to three** axes. A claim naming a third axis — or naming
axis two directly, as `[2, 0]` does — has no index to read, and the resolver **read out of
range and trapped**.

Every value in that combination is constructible through public API:
`SpatialAxisMapping(imageAxes: [0, 1, 2])` is admitted, `AffineGridGeometry` accepts it,
`PresentationProvenance` carries it, and `PickResolver.resolve` is public. So this was
reachable rather than theoretical.

A trap is the one outcome this project's typed-refusal discipline exists to prevent, and it
is the same shape `ADR-0273` found in a dependency — except this one is Voxelia's own.

## Decision

1. **`PickResolver` refuses a non-planar geometry claim** with a new
   `InteractionError.presentationGeometryNotPlanar`, rather than reading out of range.
2. **The refusal is a distinct case, not a reuse of `presentationNotCalibrated`.** That
   case means *no* claim; this means a claim that a two-dimensional pick cannot consume.
   Collapsing them would lose the difference between "nothing was declared" and "what was
   declared cannot be used here", which is the same conflation `ADR-0272` refused when it
   chose a three-way verdict over a `Bool`.
3. **The refusal is not `nil`.** Returning no world position would have been simpler and
   would have quietly treated a malformed claim as an absent one — and the uncalibrated
   case already means exactly that.
4. **A positive control asserts single- and two-axis claims still resolve**, including the
   transposed `[1, 0]`. The guard must discriminate on whether an index exists, not reject
   every mapping.
5. **`VOX-MPR-014` is discharged** by eight tests.
6. **`ADR-0125` and `ADR-0129` are not edited.** The correction is recorded here, in the
   implementing commit and in the ledger, per the standing discipline.

## The tests

- **Screen distance falsified directly**: identical pixels, two reconstructions whose
  in-plane spacing differs by a factor of four, giving `40.0` mm and `10.0` mm. A pipeline
  measuring screen distance returns the same number for both.
- **The length is spacing times index separation**, asserted exactly at four
  spacings — including a three-four-five diagonal so the square root is exact and no
  tolerance appears anywhere in the suite.
- **An uncalibrated view yields no physical position**, while the pick still succeeds and
  still reports its source index — so the absence is specific to the physical claim rather
  than a general failure.
- **View independence**: pixel 8 at 2 mm and pixel 32 at 0.5 mm produce the *same*
  `Point3D`, and measuring from the origin to each gives the same length.
- **A measurement spanning coordinate spaces is refused**, because mixing spaces fabricates
  a calibration between them — the pixel hazard wearing different clothes.
- **Input points are preserved** beside the derived length, so a measurement can be
  re-derived against a corrected geometry.

## Alternatives considered

### Return `nil` for a non-planar claim

Rejected; see decision 3. It is the smaller change and it discards information a caller
needs to distinguish a missing claim from an unusable one.

### Constrain `SpatialAxisMapping` to two axes for presentation claims

Rejected. The type is shared with volume geometry, where three axes are correct and
required. The constraint belongs to the consumer that can only supply two indices.

### Widen `PickResolver` to accept a third index

Rejected as inventing a capability. A viewport pick has two coordinates; a third would have
to be fabricated, which is precisely what this row forbids.

### Treat the trap as out of scope for a measurement row

Rejected. It was found by the row's own tests, it sits directly on the chain the row
governs, and leaving a reachable trap in place while discharging a measurement requirement
would be discharging it on evidence that omits the worst case.

## Consequences

`VOX-MPR-014` is discharged, and a reachable trap on the pick path is closed with a typed
refusal and a positive control.

**20 entered-milestone rows remain** from `ADR-0290`'s sweep.

`InteractionError` gains one case. It is additive, and no existing caller changes.

## Affected modules

`VoxeliaInteraction` gains `InteractionError.presentationGeometryNotPlanar` and a bounds
guard in `PickResolver`. No other module changes.

## Compatibility impact

Additive to the error family. A call that previously trapped now throws, which is a
behaviour change only for inputs that previously crashed the process.

## Security impact

Positive. An out-of-range read reachable from a public API is closed.

## Performance and memory impact

One bounds predicate over at most three axes per pick.

## Validation impact

```text
swift build && swift test
swift test --filter "ReconstructedMeasurementGeometry"
swift format lint --strict Sources/VoxeliaInteraction/Public/PickResolver.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
Tools/Scripts/test-repository-scripts.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1172 tests in 210 suites pass, up from 1164 in 209.

## Migration

1. This record, the bounds refusal and eight tests.
2. **Next**: the derived queue's remaining 20 rows.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **corrects a reachable trap** in `ADR-0125`-era pick
resolution without editing that record.

## References

- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
- [ADR-0272 - Codec output and interoperability status](ADR-0272-codec-output-and-interoperability-status.md)
- [ADR-0273 - Bounded failure on adversarial codestreams](ADR-0273-bounded-failure-on-adversarial-codestreams.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
