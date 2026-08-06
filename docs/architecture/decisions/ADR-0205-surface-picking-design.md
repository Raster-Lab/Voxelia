---
document_id: "ADR-0205"
title: "Surface picking design"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-GEO-002"
  - "VOX-NUM-001"
  - "VOX-SUR-006"
  - "VOX-SUR-007"
---

# ADR-0205 - Surface picking design

## Context

`ADR-0197` decision 4(h) makes authoritative surface picking the arc's eighth
increment, governed by `VOX-SUR-007`: "Surface picking shall return
authoritative geometry identifiers and physical coordinates."

`VOX-SUR-007` is the only row in the `VOX-SUR` block declaring **T** alone
rather than **T,D**. Its evidence obligation is therefore fully dischargeable
off-screen, and this arc can close it completely rather than half.

`ADR-0197` also carried forward the `PickResolver` honesty rule: return no
position rather than a fabricated one when the required claim is absent.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0039` defines `surface-picking/binary64-v1`.
2. **Picking composes the accepted coverage rules; it does not re-intersect.**
   There is no ray-versus-mesh intersection. `ALG-0034` already decides exactly
   which facet covers a pixel and where, and `ALG-0033` already published each
   vertex's world position. An independent ray cast would introduce a second
   geometric predicate that could disagree with the one that drew the image,
   and **a pick that disagrees with what the user is looking at is worse than
   no pick at all**. Composing makes agreement structural rather than something
   to test for.
3. **Clipping is applied before the nearest-surface decision, and this record
   states that ordering explicitly.** `ADR-0204` established clipping as a
   per-fragment predicate but did not pin where in the pipeline it runs.
   Picking makes the answer unavoidable: if the nearest fragment were chosen
   first and then tested against the clip, a clipped-away surface would swallow
   the pick and the caller would be told nothing was there — while the
   renderer, which discards clipped fragments during coverage, would be drawing
   the surface behind it. Clipping therefore precedes both the visibility
   decision and the pick. The registered `clipped-does-not-occlude` fixture
   pins it. This is a clarification of an ordering `ADR-0204` left implicit,
   recorded here rather than by editing that accepted record.
4. **The tie-break is inherited, not restated.** Survivors are ordered by
   `(depth, layerIndex, facetOrdinal)` — the same strict total order `ALG-0034`
   and `ALG-0035` use. Restating it would create a second place for the same
   decision to live and drift.
5. **The geometry identity is the layer index, the facet ordinal and the
   facet's three vertex indices in the mesh's original topology order.** The
   coverage rule's canonicalisation swap is a coverage detail and never reaches
   an identifier.
6. **No durable object identifier is invented.** `ADR-0198` deliberately had
   `SurfaceLayer` hold a `TriangleMesh` value rather than an object identifier,
   with a recorded reason. The identity above locates the geometry exactly
   within the scene the caller itself constructed, so the caller can map a
   layer index to its own object identity. Adding an identifier field
   speculatively, for a consumer that does not exist, is the expansion this
   project avoids; a future record may add one when a consumer needs it.
7. **The physical position is physical by construction, so the honesty rule
   needs no branch.** `SurfaceLayer` carries a full `CoordinateSpaceDescriptor`
   and that type admits only a `UnitDimension.length` unit, so a surface scene
   always has a length-bearing world space. Unlike `PickResolver`'s 2D case,
   where an uncalibrated presentation genuinely has no physical position, there
   is no uncalibrated case here. This record therefore carries **no**
   optional-position case, because it could never fire — the honesty rule is
   honoured structurally.
8. **What can genuinely be absent is a hit**, and both ways of having none —
   a pixel nothing covered, and a pixel where everything covering it was
   clipped away — report no hit by the same rule rather than by two special
   cases.
9. **A negative depth is pickable.** `ALG-0033` admits behind-camera vertices
   and `ALG-0034` imposes no near plane, so a visible fragment behind the
   camera is still authoritative geometry.
10. **An out-of-viewport pixel is rejected typed**, not reported as empty.
    "Nothing is there" and "you asked wrongly" are different answers, and
    conflating them would let a caller silently mis-index a viewport forever.
    The failure family is exactly `pixelOutOfBounds`.
11. **There is no representability failure and no cancellation checkpoint.**
    Every value returned was already computed and admitted by an earlier
    accepted stage, and a pick is a bounded lookup over one pixel's candidates
    rather than a traversal. Carrying either would be an unevidenceable case.
12. **This stage publishes nothing** — no image, no identity record, no
    provenance. A pick is a query.
13. **Independent analytical evidence is registered now**: eleven fixtures,
    ten successful and one failure, with two SHA-256 digests frozen in
    `ALG-0039`.

## Alternatives considered

### Cast an independent ray against the mesh

Rejected; see decision 2. It is the conventional approach and it is wrong here:
a second predicate can disagree with the one that produced the image, and the
disagreement would surface as a pick landing on geometry the user cannot see.

### Test the clip after choosing the nearest fragment

Rejected; see decision 3. It makes clipped geometry occlude what is behind it,
so a section view would become unpickable exactly where it is most useful.

### Restate the tie-break rule for picking

Rejected; see decision 4.

### Add an object identifier to `SurfaceLayer`

Rejected for version one; see decision 6. `ADR-0198` made the opposite choice
deliberately, and no consumer needs a durable identifier yet.

### Return an optional position for symmetry with `PickResolver`

Rejected; see decision 7. The case cannot fire, and an error or optional a test
can never exercise is exactly what this project does not carry.

### Report an out-of-viewport pixel as no hit

Rejected; see decision 10.

## Consequences

The next migration can implement one bounded, stateless, exact reference with
no remaining choice about the predicate, the ordering, the identity, the
position or the failure. `VOX-SUR-007` becomes fully dischargeable, including
its verification method, because it declares Test alone.

The deliberate limitations are single-pixel picking only, no rectangle or lasso
selection, no picking through transparency, and no durable object identity
beyond the supplied scene.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the pick reference to `VoxeliaRendering`. No dependency edge
changes.

## Compatibility impact

None in this design-only increment.

## Security impact

No allocation beyond one result; errors are payload-free and disclose no
positions, identities or scene contents.

## Performance and memory impact

`O(k log k)` in the number of fragments covering the requested pixel.

## Validation impact

The oracle registers:

```text
fixtureSHA256=b5ff409fd3621af9730f9e43b94e68ac5aabe42b8f2799cce72e94993dac13b2
positionSHA256=036c7042a75859dc6effb1cdd47b50cec74cca6cb9d727a964bcfdd53503be96
fixtures=11 successful=10 failures=1
```

Migration must reproduce all eleven fixtures bit-exactly, prove that a clipped
nearer fragment does not occlude a farther one, prove both no-hit paths, prove
the inherited tie-break at both levels, and prove the inclusive-at-zero,
exclusive-at-dimension pixel bound. This design increment requires oracle
reproduction, documentation, register, index, link, manifest and
release-integrity checks. Unlike every other row in this arc, `VOX-SUR-007`
declares **T only**, so a green migration discharges its verification method
**completely** — no demonstration is outstanding for this requirement.

## Migration

1. Add the pick reference to `VoxeliaRendering` with every fixture from
   `ALG-0039`.
2. `ADR-0197` increments (i) and (j) assess `VOX-SUR-008` and `VOX-SUR-009`.

## Supersession

This record executes `ADR-0197` decision 4(h) and supersedes no accepted
record. It clarifies, without editing, an ordering `ADR-0204` left implicit.

## References

- [ADR-0125 - Pick resolution](ADR-0125-pick-resolution.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](ADR-0198-surface-scene-vocabulary.md)
- [ADR-0204 - Surface clipping design](ADR-0204-surface-clipping-design.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](../../algorithms/VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [VOXELIA-ALG-0038 - Surface world-box clipping](../../algorithms/VOXELIA-ALG-0038-surface-clipping.md)
- [VOXELIA-ALG-0039 - Authoritative surface picking](../../algorithms/VOXELIA-ALG-0039-surface-picking.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
