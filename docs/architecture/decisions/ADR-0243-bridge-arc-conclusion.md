---
document_id: "ADR-0243"
title: "Bridge arc conclusion"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-004"
  - "VOX-VS1-009"
  - "VOX-VS1-019"
---

# ADR-0243 - Bridge arc conclusion

## Context

`ADR-0238` increment (f): publish an ingested CT volume and reconstruct it in the
axial, coronal and sagittal planes, which is what `VOX-VS1-009` asks for.

This is the first time the ingest arc's output met code written in milestones M2 to
M6. The meeting found a blocker, and the blocker is not in the bridge.

## What works, verified

| Stage | Result |
|---|---|
| Publication of a geometry-bearing ingested volume | **works** |
| Slab extraction, one slice thick | **works**, and translates the affine origin |
| Squeeze from a one-thick slab to a 2D slice | **refused** |
| The same pipeline with `spatialGeometry: nil` | all three planes reconstruct |

Each row was established by a test, not by reading. The last two together isolate
the cause: the blocker is the **geometry**, not the ingested volume's shape,
storage, identity or provenance.

## The finding: MPR cannot process any volume that carries a spatial geometry

`SqueezeAxesOperation` guards:

```swift
guard input.descriptor.spatialGeometry == nil else {
    throw SqueezeError.unsupportedGeometry
}
```

`MPRSliceCoordinator` uses squeeze as its second stage — extract a one-thick slab,
then drop the singleton axis — so **no volume with a spatial geometry can be
reconstructed through it**.

**This puts two P0 requirements in tension.** `VOX-VS1-004` requires an affine
volume *with patient-space geometry*; `VOX-VS1-009` requires axial, coronal and
sagittal reconstruction. As implemented, a volume can satisfy either but not both.

**The refusal is correct conservatism, not a bug.** Dropping an axis from an affine
geometry means deciding what the remaining two-dimensional geometry *is*: the 4×4
index-to-world matrix loses a column, the dropped axis's contribution has to be
folded into the origin, and the surviving `SpatialAxisMapping` has to be
renumbered. That is real design work with real arithmetic, and the operation
declined to guess. Every existing MPR test passes because its synthetic volumes
carry no geometry — so nothing was wrong, and nothing had ever been composed.

**Neither half of the project was at fault, and no test could have caught it**,
because each half was only ever exercised alone. This is the same shape as the
`ADR-0196` family the project keeps rediscovering: not an assertion that went
unenforced, but two capabilities that were never composed.

## Decision

1. **The arc closes here, with the blocker recorded rather than worked around.**
   The bridge is complete and correct: an ingested volume publishes, and every
   accepted admission accepts it. What it cannot yet do is pass through squeeze.
2. **The blocker is pinned by a test.** A test asserts that squeeze **refuses** a
   geometry-bearing slab. When the axis-drop rule is decided and implemented that
   test fails, so lifting the limitation is a noticed act rather than a silent
   behaviour change.
3. **A second test isolates the cause** by running the identical pipeline with
   `spatialGeometry: nil` and reconstructing all three planes. Without it, the
   refusal could be blamed on the bridge.
4. **`VOX-VS1-009` is not claimed.** The reconstruction works for geometry-free
   volumes and does not work for the volumes this project actually ingests, and
   reporting that as satisfied would be the clearest kind of false claim.
5. **Deciding the axis-drop rule is its own increment, needing a record, an
   algorithm specification and an oracle.** It changes an accepted, tested
   operation and it fixes a numeric boundary — folding a dropped axis's
   contribution into the origin is arithmetic with a frozen expression order. It is
   not a bridge detail.
6. **No workaround is applied.** Stripping the geometry before squeeze would make
   MPR work by discarding exactly what `VOX-VS1-004` and `VOX-DCM-007` exist to
   preserve, and it would produce slices that silently do not know where they are.

## A secondary finding: a stale doc comment contradicts its own code

`RegionExtractionOperation`'s header says version one "admits only geometry-free
descriptors with index-only axis sampling, because cropping under affine geometry
or regular sampling shifts origins, which is arithmetic deferred to its own
decision."

**The code does handle affine geometry**, translating the origin by the region's
lower bounds — and a test in this increment proves that branch executes and is
correct. So the deferral described in the comment was taken up by a later record and
the header was never updated. The comment is corrected, because a comment that
contradicts its own code is worse than no comment: it tells a reader the opposite
of the truth.

## Alternatives considered

### Decide the axis-drop rule now, in this increment

Rejected; see decision 5. It changes accepted, tested code and fixes a numeric
boundary, and doing it as the tail of a bridge increment is how boundaries get
frozen without oracles.

### Strip the geometry before squeezing

Rejected; see decision 6. It converts a visible blocker into a silent loss of the
thing the arc was built to carry.

### Report `VOX-VS1-009` as satisfied because the reconstruction code works

Rejected; see decision 4. It works on volumes this project does not produce.

### Leave the failing tests failing to mark the blocker

Rejected. A red suite trains everyone to ignore it. Pinning the *actual* behaviour
keeps the suite honest and green while still failing the moment the behaviour
changes.

## Consequences

The bridge arc is complete: a real CT series becomes a published `ImageData`
carrying patient-space geometry, a rescale transform, 899 source locators and an
origin provenance record.

**Eleven first-vertical-slice requirements remain unreachable**, and now for one
identified reason rather than an unexamined gap. `VOX-VS1-009` and everything
downstream of a 2D slice — window-level interaction, crosshairs, pixel inspection,
measurement, off-screen output — waits on one decision about dropping an axis from
an affine geometry.

That is a much better position than the arc started in, and it is not the position
the arc set out to reach. Saying so is the point of this record.

## Affected modules

Test sources in `VoxeliaImagingTests`, and one corrected doc comment in
`VoxeliaExecution`. **No behaviour changes.**

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift build && swift test
swift test --filter CTVolumeBridgeComposition
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record closes the `ADR-0238` arc.
2. **Next, and blocking eleven requirements**: the axis-drop rule for an affine
   geometry — a record, an algorithm specification with a frozen expression order,
   an oracle, and a change to `SqueezeAxesOperation`.
3. Then `VOX-VS1-009` onward becomes reachable.

## Supersession

This record supersedes nothing. It performs `ADR-0238` increment (f) and closes
that arc, reporting honestly that its goal was not reached and why.

## References

- [ADR-0117 - MPR slice coordinator](ADR-0117-mpr-slice-coordinator.md)
- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0238 - Published volume bridge arc](ADR-0238-published-volume-bridge-arc.md)
- [ADR-0242 - CT volume identity and provenance](ADR-0242-ct-volume-identity-and-provenance.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
