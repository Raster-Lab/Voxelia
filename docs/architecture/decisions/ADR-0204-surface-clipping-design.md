---
document_id: "ADR-0204"
title: "Surface clipping design"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-ERR-001"
  - "VOX-NUM-001"
  - "VOX-GEO-002"
  - "VOX-SUR-006"
---

# ADR-0204 - Surface clipping design

## Context

`ADR-0197` decision 4(g) makes clipping and section views the arc's seventh
increment, governed by `VOX-SUR-006`: "Surface rendering shall support clipping
and section views." That decision named the real question up front: section
views "require deciding whether a clipped solid shows an open boundary or a
capped cross-section; capping is a constructive-geometry obligation and must be
settled explicitly, not assumed."

`ADR-0179`'s `VolumeClipBounds` already freezes an axis-aligned world-space box
with finite corners, strict per-axis inequalities and coordinate-space
agreement. It is directly reusable.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0038` defines `surface-world-box-clipping/binary64-v1`.
2. **Clipping is a per-fragment predicate. No geometry is cut, no vertex is
   created and no topology is changed.** Geometric clipping would have to split
   facets, synthesise vertices, decide those vertices' attribute values and
   re-establish winding — a constructive-geometry subsystem this arc does not
   need, because the visibility and fragment stages already evaluate
   per-fragment data and discarding a fragment is exact.
3. **Section views are uncapped in version one, and the cut is legible by
   construction.** A clipped solid shows its own far side through the cut. This
   is only acceptable because `ADR-0202` already made the diagnostic material
   **two-sided** — a decision taken for a different reason, that open extracted
   surfaces must not render black inside — and that same property makes the
   revealed interior lit rather than a void. The two decisions compose; neither
   was made for the other.
4. **What a capped variant must settle is recorded now, and bounded.** Capping
   needs the plane-mesh intersection polygon, its triangulation for non-convex
   and multi-loop cross-sections, the cap's orientation, nested-loop and
   cavity semantics, and a policy for meshes where no interior exists. The
   accepted `VOXELIA-ALG-0032` certification is the natural precondition,
   because a cap is only well defined for a surface already proven closed and
   consistently oriented. A capped variant is a separate record with that
   precondition, not a parameter of this one.
5. **The clip region is the accepted `VolumeClipBounds`, composed unchanged.**
   It already admits a finite non-degenerate box with corners in one coordinate
   space. This record adds exactly one admission the surface path needs and the
   volume path did not: the clip's space must be the scene's world space.
6. **The boundary is inclusive.** A fragment exactly on a face, edge or corner
   is retained. The box is a closed region; excluding its boundary would
   discard a zero-measure set for no benefit, and `VolumeClipBounds` uses
   strict inequalities only to reject a degenerate box, not to describe an open
   region. Four registered fixtures pin the faces and corners.
7. **The world position is published rather than reconstructed.** `ALG-0033`
   already computes each vertex's world position as an intermediate; this
   record publishes it on `ProjectedVertex`. That is additive and changes no
   registered `ALG-0033` digest, because that record's fixture entries and byte
   payload cover only column, row and depth — the same reasoning that made
   `ADR-0202`'s swap flag safe. Inverting the projection to recover a world
   position would introduce a second rounding path for a value the pipeline
   already had.
8. **An absent clip retains every fragment**, so the unclipped path is the same
   code with no special case and no branch to diverge.
9. **The failure family is exactly two cases** — `coordinateSpaceMismatch` and
   `cancelled` — payload-free, `Sendable` and `Equatable`. There is **no
   representability failure**: a covered sample's weights are non-negative and
   sum to the projected area, so the interpolated position is a convex
   combination of three finite world positions and is bounded by them, and the
   comparisons cannot overflow. As with `ADR-0201`, an unreachable case is not
   carried.
10. **Cancellation is checked before fragment zero and every fragment ordinal
    divisible by 4,096**, matching `ALG-0036` and `ALG-0037`.
11. **This stage publishes nothing** — no image, no identity, no provenance.
12. **Independent analytical evidence is registered now**: nineteen fixtures
    with two SHA-256 digests frozen in `ALG-0038`.

## Alternatives considered

### Cap the cross-section in version one

Rejected; see decision 4. It is a constructive-geometry subsystem — intersection
polygon, triangulation of non-convex and multi-loop sections, orientation,
nested loops and cavities — and it is undefined for the open surfaces
extraction legitimately publishes. Building it speculatively, without the
closure certification that makes it meaningful, would be exactly the
speculative expansion this project avoids.

### Clip geometrically by cutting facets

Rejected; see decision 2. It changes topology, creates vertices whose
attributes must be invented, and would duplicate work the fragment stages
already do exactly.

### Make the boundary exclusive

Rejected; see decision 6. It would discard a zero-measure set for no benefit
and would read `VolumeClipBounds`'s strict admission inequalities as describing
an open region, which they do not.

### Reconstruct the world position by inverting the projection

Rejected; see decision 7. The value already exists as an `ALG-0033`
intermediate, and inverting would add a second rounding path for the same
quantity.

### Support oriented (non-axis-aligned) clip planes now

Rejected for version one. `VolumeClipBounds` is axis-aligned, the volume arc
deferred oriented planes for the same reason, and adding them here would
introduce a plane vocabulary no accepted record supplies. A later record may
add them.

### Give clipping its own clip-region vocabulary

Rejected. Reusing `VolumeClipBounds` keeps one clip meaning across the volume
and surface paths; a second vocabulary would let the two drift.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about the predicate, the boundary, the
position source, the absent-clip path or failure. `VOX-SUR-006`'s clipping half
becomes dischargeable and its section-view half is answered as uncapped, with
the capped variant recorded as a bounded future record.

The deliberate limitations are no capping, axis-aligned regions only, one
region at a time and no boolean combinations.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration publishes the world position on `ProjectedVertex` and adds the clip
predicate to `VoxeliaRendering`. No dependency edge changes.

## Compatibility impact

The published world position is additive and changes no registered digest.
Capping or oriented planes would each be a new algorithm identity.

## Security impact

No allocation beyond one position per fragment; traversal is cancellable;
errors are payload-free and disclose no positions, bounds or scene contents.

## Performance and memory impact

`O(1)` per fragment. Publishing the world position adds three binary64 values
per projected vertex, which is bounded by the vertex count the caller already
owns.

## Validation impact

The oracle registers:

```text
fixtureSHA256=8dd30ec41bd27c11bebb15501739a46398294d86ff6e9956fd7aa1be2976e604
positionSHA256=0f0ee1270ffda5115052a0c370ecaae427ba5e2fbc26bb9e8b47e84b53521335
fixtures=19 successful=19 failures=0
```

Migration must reproduce all nineteen fixtures bit-exactly, prove the inclusive
boundary on faces and corners, prove a straddling facet keeps only its interior
fragments, prove the swap flag changes which fragments are clipped, prove the
absent-clip path, and — as with `ADR-0202` — **re-run the `ALG-0033` oracle
immediately after publishing the world position to prove its digests are
unchanged**. This design increment requires oracle reproduction, documentation,
register, index, link, manifest and release-integrity checks. It discharges the
**Test** half of `VOX-SUR-006`'s verification methods only; no demonstration is
claimed.

## Migration

1. Publish the world position on `ProjectedVertex`, re-running the `ALG-0033`
   oracle test to prove its digests are unchanged.
2. Add the clip predicate to `VoxeliaRendering` with every fixture from
   `ALG-0038`.
3. `ADR-0197` increment (h) freezes authoritative surface picking.

## Supersession

This record executes `ADR-0197` decision 4(g) and supersedes no accepted
record. It reuses `ADR-0179`'s clip vocabulary unchanged.

## References

- [ADR-0179 - Volume clipping](ADR-0179-volume-clipping.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0199 - Surface vertex projection design](ADR-0199-surface-vertex-projection-design.md)
- [ADR-0202 - Surface shading design](ADR-0202-surface-shading-design.md)
- [VOXELIA-ALG-0032 - Triangle-mesh certified enclosed volume](../../algorithms/VOXELIA-ALG-0032-triangle-mesh-enclosed-volume.md)
- [VOXELIA-ALG-0033 - Surface vertex orthographic projection](../../algorithms/VOXELIA-ALG-0033-surface-vertex-projection.md)
- [VOXELIA-ALG-0038 - Surface world-box clipping](../../algorithms/VOXELIA-ALG-0038-surface-clipping.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
