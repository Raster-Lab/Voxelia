---
document_id: "ADR-0344"
title: "Interactive level render path"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-BRK-009"
---

# ADR-0344 - Interactive level render path

## Context

Arc step 2 of `ADR-0343`: `VOX-BRK-009` requires interactive rendering to be able
to use a lower-resolution level while higher-resolution bricks are loading. The
level representation exists (`LevelSelectOperation`), the loading state exists
(`ADR-0341`'s generation stage with its completion), and the render path exists
(`MultiplanarRenderCoordinator` composing the accepted extraction and renderer).
What is missing is the decision layer connecting them.

## Decision

1. **`InteractiveLevelRenderCoordinator` in `VoxeliaRendering` is the degraded
   path's decision layer.** Its selection rule is total and frozen:
   a `.full` request renders the full-resolution volume **always** — a
   diagnostic request never renders the level, loading or not; an
   `.interactive` request renders the **level** while study-cache generation is
   incomplete, and the **full** volume once it completes. The third case is the
   seed of arc step 3: refinement is a representation upgrade.

2. **The representation degrades; the execution never does — and that is the
   arc's shape.** The renderer runs its accepted full-precision math over
   whichever volume the coordinator selects, so every stage claim stays exactly
   what it says. The interactive fact is recorded **structurally**: the
   published render's ancestry reaches the level volume, whose own derivation
   names `org.voxelia.op.level-select` and its factors — the same
   "not restated in the presentation claim" discipline `ADR-0221` records for
   the plane. This **refines `ADR-0343` step 2's wording** ("claiming
   `org.voxelia.quality.interactive`"): a quality token on an execution claim
   describes execution, and stamping a full-math execution "interactive" would
   be less honest than the ancestry already is. `ADR-0343` is not edited; if a
   future increment ever degrades **execution**, that increment mints the
   per-quality claims and replaces the `ADR-0103` guard, per arc step 4 — which
   this increment therefore leaves untouched, guard and all.

3. **The slice index maps by floor division**:
   `levelSliceIndex = fullSliceIndex / factor(plane.fixedAxis)` — the level
   slice containing the sample the level kept at or below the requested
   position. `MPRPlane.fixedAxis` becomes public so the mapping composes the
   extraction's own axis authority instead of mirroring it.

4. **Everything else is forwarded, never chosen** — transfer function, camera,
   viewport, interpolation, colour claims, naming, publisher — the
   `MultiplanarRenderCoordinator` forwarding discipline, composed verbatim as
   the render backend.

5. **`VOX-BRK-009`'s `T` is discharged by the end-to-end evidence**: with a
   gated generation mid-load, an interactive request renders the level (the
   extract stage's provenance input is the level volume), a full request
   renders the full volume, and after completion the interactive request
   renders the full volume. The level admission requires three factors
   (`invalidLevelRank`) since `BrickResolutionLevel` is rank-agnostic. The `D`
   half joins the release demonstrations.

## Alternatives considered

### Stamp the stage claims with an interactive quality token

Rejected; see decision 2. It would rewrite honest execution claims to carry a
routing fact the ancestry already records, and it would touch every stage
operation for a fact none of them decided.

### Select inside the renderer

Rejected. The renderer renders requests; which volume a request references is
scene composition, and putting policy inside the renderer would fork its frozen
single-pass contract — the exact divergence arc step 4 reserves.

## Consequences

Interactive rendering can use the level while bricks load, provably, with
`ADR-0103`'s guard intact. Arc step 3 (refinement after interaction stops)
composes the same selection rule's completion case.

## Affected modules

`VoxeliaRendering` gains the coordinator; `VoxeliaImaging` makes
`MPRPlane.fixedAxis` public.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One comparison per render; the composed path is unchanged.

## Validation impact

```text
swift test --filter InteractiveLevelRenderTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The end-to-end witness is gate-driven. The full suite must show the literal
pass line before push.

## Migration

1. This record.
2. The coordinator, the `fixedAxis` visibility change and the suite, in the
   same increment.
3. **Next**: arc step 3 — refinement after interaction stops (`VOX-DVR-013`).
4. **Owner**: the `D` half joins the release demonstrations.

## Supersession

This record supersedes nothing. It composes `ADR-0341`, `ADR-0343` step 1 and
`ADR-0221`'s render path unchanged, and leaves `ADR-0103`'s guard in force.

## References

- [ADR-0103 - Interactive quality equivalence](ADR-0103-interactive-quality-equivalence.md)
- [ADR-0221 - Multiplanar render path](ADR-0221-multiplanar-render-path.md)
- [ADR-0341 - Study cache generation and priority](ADR-0341-study-cache-generation-and-priority.md)
- [ADR-0343 - Open the progressive refinement arc](ADR-0343-open-the-progressive-refinement-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
