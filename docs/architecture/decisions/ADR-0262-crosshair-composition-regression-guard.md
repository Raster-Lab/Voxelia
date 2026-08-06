---
document_id: "ADR-0262"
title: "Crosshair composition regression guard"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-005"
  - "VOX-VS1-013"
---

# ADR-0262 - Crosshair composition regression guard

## Context

`ADR-0248` discharged `VOX-VS1-013` by verifying the three-plane crosshair round trip
against the owner's real 899-slice series, and recorded a migration step it did not
take: a synthetic-affine composition test, "so the composition is guarded in CI as
well as demonstrated on real data".

**No repository test may read the owner's patient data**, so the real-data run cannot
be a regression guard. Until now nothing in CI would have caught a regression in the
composition `ADR-0248` verified — only the unit tests of each half, which pass
independently of whether the halves still meet.

## Decision

1. **The composition is now guarded by a synthetic-affine test suite** that composes
   `MPRSliceCoordinator`'s world-point slice mapping with `ViewportSyncGroup`'s
   crosshair broadcast, exactly as the real-data run did: publish a volume, resolve
   the slice index per plane, extract those slices, build a presentation from each
   slice's own claimed geometry, broadcast, and check the pixels.
2. **The volume is anisotropic — `4x3x5` — and its affine has three distinct
   spacings**, `world = (10 + 2i, 20 + 3j, 30 + 5k)`. Equal extents would let a
   transposed or duplicated plane pass; equal spacings would let a swapped axis in
   the world mapping pass; a zero origin would let a dropped origin term pass. Each
   choice removes a way the test could succeed while the code was wrong.
3. **The expected pixels are all distinct**: axial `(2, 1)`, coronal `(2, 3)`,
   sagittal `(1, 3)`, in viewports `4x3`, `4x5` and `3x5`. This exercises
   `ADR-0244`'s axis renumbering after the singleton drop, which is what turns the
   slice axis into a view's `y`.
4. **`ADR-0248`'s composition contract is guarded, not merely restated.** A second
   test places the crosshair outside the volume on the column axis and asserts the
   asymmetric outcome that record found: axial and coronal report `outsideViewport`
   because both present the column, while the **sagittal view still reports a pixel**
   because it presents row and slice and an out-of-range column cannot move its
   in-plane projection — and the slice-index call refuses with
   `crosshairOutsideVolume`. A regression in either half now breaks a test.
5. **The refusal path is guarded too**: an `.indexOnly` descriptor with an affine
   must refuse the `.regular`-only axis-value overload, which is why `ADR-0138` added
   the world-point overload at all.
6. **No algorithm specification and no oracle.** Nothing new is frozen; every rule
   composed here is already accepted.

## The assertions were negative-tested, not assumed

A passing test proves nothing about whether it *can* fail. The coronal expectation
was deliberately transposed — `(column, slice)` swapped to `(slice, column)` — and the
suite failed on both axes:

```text
Expectation failed: (target.viewportX → 2) == (item.x → 3)
Expectation failed: (target.viewportY → 3) == (item.y → 2)
```

Then restored, and green again. This follows the habit `ADR-0249` stage three
established: after a test goes green, establish that the violation it exists to catch
actually breaks it.

## Alternatives considered

### Rely on `ADR-0248`'s real-data run as the guard

Rejected, and it is the reason this record exists. That run is evidence the
composition *worked once*; it cannot run in CI, so it guards nothing against
regression.

### Rely on the two halves' existing unit tests

Rejected. `MPRSliceCoordinatorTests` and `ViewportSyncGroupTests` each pass without
the other, so an axis-renumbering change that broke only the *composition* would
leave both green. That is precisely the gap `ADR-0248` found by composing them for
the first time.

### Use an isotropic cube for simplicity

Rejected; see decision 2. A cube is the classic fixture that cannot detect a
transposed plane.

### Put the suite in `VoxeliaImagingTests` next to the slice coordinator

Rejected. `ViewportSyncGroup` lives in `VoxeliaInteraction`, which sits above
`VoxeliaImaging`, so the composition can only be expressed from the upper module's
tests. `ADR-0248`'s migration step named `VoxeliaInteractionTests` for this reason.

## Consequences

The crosshair composition is guarded in CI as well as demonstrated on real data, and
`ADR-0248`'s open migration step is closed.

`VOX-VS1-013` remains discharged by `ADR-0248`; **this record adds a guard and
re-discharges nothing.**

## Affected modules

None. `VoxeliaInteractionTests` gains one suite; no source changed.

## Compatibility impact

None.

## Security impact

None. The suite is entirely synthetic and reads no patient data.

## Performance and memory impact

None. The fixture is a 60-byte volume.

## Validation impact

```text
swift test --filter "CrosshairComposition"
swift test
swift format lint --strict Tests/VoxeliaInteractionTests/CrosshairCompositionTests.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1067 tests in 198 suites pass, and the deliberate-transposition run above failed as
it should.

## Migration

1. This record. `ADR-0248`'s migration step 5 is complete.
2. **Remaining unblocked candidate**: plan §59.3's `512x512x1024` stress volume as
   its own benchmark scenario.
3. **Owner decisions, unchanged**: the six from `ADR-0254` and the two from
   `ADR-0255`.

## Supersession

This record supersedes nothing.

## References

- [ADR-0138 - World-to-index mapping](ADR-0138-world-to-index-mapping.md)
- [ADR-0244 - Affine axis drop](ADR-0244-affine-axis-drop.md)
- [ADR-0248 - Linked crosshair verification](ADR-0248-linked-crosshair-verification.md)
- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
