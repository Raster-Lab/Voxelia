---
document_id: "VOXELIA-ALG-0039"
title: "Authoritative surface picking binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Authoritative surface picking binary64-v1

## Purpose

This specification defines `surface-picking/binary64-v1`, the deterministic CPU
reference selected by accepted
[`ADR-0205`](../architecture/decisions/ADR-0205-surface-picking-design.md). For
one viewport pixel it returns the authoritative geometry the user picked and
its physical position, or reports that nothing was picked.

## Picking composes coverage; it does not re-intersect

There is **no ray-versus-mesh intersection** in this model. The coverage rules
[`VOXELIA-ALG-0034`](VOXELIA-ALG-0034-surface-visibility-resolution.md) froze
already decide exactly which facet covers a pixel and where, and the projection
already published each vertex's world position.

Re-intersecting with an independent ray cast would introduce a second
geometric predicate that could disagree with the one that drew the image. A
pick that disagrees with what the user is looking at is worse than no pick at
all, so agreement is made **structural** rather than tested for.

## The frozen rule

The candidates are the covering fragments at the requested pixel, each already
judged by the clip predicate
[`VOXELIA-ALG-0038`](VOXELIA-ALG-0038-surface-clipping.md) froze.

```text
1. reject a pixel outside the viewport
2. discard every candidate the clip predicate did not retain
3. if none survive, report no hit
4. order the survivors by (depth, layerIndex, facetOrdinal)
5. report the first
```

**Step 2 precedes step 4, and that ordering is the model's central
obligation.** A clipped-away fragment must not occlude what is behind it. If
the nearest fragment were chosen first and then tested against the clip, a
clipped surface would swallow the pick and the caller would be told nothing was
there — while the renderer, which discards clipped fragments during coverage,
would be drawing the surface behind it. The registered
`clipped-does-not-occlude` fixture pins this: the nearer fragment is clipped and
the farther one is picked.

Step 4's order is the same strict total order the visibility and compositing
records use. It is **inherited, not restated**, so a pick can never disagree
with what the renderer drew. The registered `tie-by-layer` and `tie-by-facet`
fixtures confirm both levels.

## What is returned

- **The geometry identity**: the layer index, the facet ordinal, and the
  facet's three vertex indices in the mesh's **original** topology order. The
  coverage rule's canonicalisation swap is a coverage detail and never reaches
  an identifier.
- **The physical position**: the interpolated world position the clip stage
  already computed, in the scene's world coordinate space.

The position is physical by construction. `SurfaceLayer` carries a full
`CoordinateSpaceDescriptor`, and `CoordinateSpaceDescriptor` admits only a
`UnitDimension.length` unit, so a surface scene always has a length-bearing
world space. The `PickResolver` honesty rule — never fabricate a position — is
therefore honoured **structurally** here rather than by a runtime branch, and
this model deliberately carries no optional-position case, because it could
never fire.

What can genuinely be absent is a hit: a pixel nothing covered, or a pixel
where everything covering it was clipped away. Both report no hit by the same
rule, not by two special cases.

## Depth range

A negative depth is pickable. `ALG-0033` admits behind-camera vertices under
orthographic projection and `ALG-0034` imposes no near plane, so a fragment
behind the camera is still authoritative geometry if it is visible.

## Admission and failure

```text
pixelOutOfBounds
```

A pixel outside `0..<width` by `0..<height` is rejected rather than reported as
empty. "Nothing is there" and "you asked wrongly" are different answers, and
conflating them would let a caller silently mis-index a viewport forever. The
bound is inclusive at zero and exclusive at the dimension; the registered
`first-pixel` and `last-pixel` fixtures pin both ends.

There is no representability failure: every value returned was already computed
and admitted by an earlier accepted stage. There is no cancellation checkpoint:
a pick is a bounded lookup over one pixel's candidates, not a traversal.

## Determinism and accelerated conformance

The reference is stateless and depends only on the supplied candidates. An
accelerated implementation must return the identical facet and position; a GPU
pick performed by rendering identifiers into a buffer conforms only if its
coverage, clipping and tie-breaking are the accepted ones.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0205-surface-picking-oracle.py`](../progress/evidence/ADR-0205-surface-picking-oracle.py).
It records eleven fixtures: the nearest retained fragment with its original
vertex indices; the same result from reversed supply order; a clipped nearer
fragment failing to occlude a farther one; an uncovered pixel; a pixel where
everything is clipped away; ties resolved by layer and by facet; a pickable
negative depth; the first and last in-bounds pixels; and an out-of-bounds
pixel rejected.

The registered output is:

```text
fixtureSHA256=b5ff409fd3621af9730f9e43b94e68ac5aabe42b8f2799cce72e94993dac13b2
positionSHA256=036c7042a75859dc6effb1cdd47b50cec74cca6cb9d727a964bcfdd53503be96
fixtures=11 successful=10 failures=1
order=clip-then-nearest identity=layer,facet,original-indices
noHit=never-fabricated tieBreak=inherited outOfBounds=rejected
```

## Complexity and exclusions

`O(k log k)` in the number of fragments covering the requested pixel.

Rectangle and lasso selection, picking through transparency, picking a vertex
or edge rather than a facet, hover feedback, durable object identity beyond the
supplied scene, and any published artefact remain separate contracts.

## References

- [ADR-0125 - Pick resolution](../architecture/decisions/ADR-0125-pick-resolution.md)
- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](../architecture/decisions/ADR-0198-surface-scene-vocabulary.md)
- [ADR-0205 - Surface picking design](../architecture/decisions/ADR-0205-surface-picking-design.md)
- [VOXELIA-ALG-0033 - Surface vertex orthographic projection](VOXELIA-ALG-0033-surface-vertex-projection.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [VOXELIA-ALG-0038 - Surface world-box clipping](VOXELIA-ALG-0038-surface-clipping.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
