---
document_id: "ADR-0200"
title: "Surface visibility design"
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
  - "VOX-SEC-001"
  - "VOX-SUR-002"
---

# ADR-0200 - Surface visibility design

## Context

`ADR-0197` decision 4(c) makes visibility and hidden-surface removal the
surface arc's third increment, governed by `VOX-SUR-002`: "Surface rendering
shall support depth testing and hidden-surface removal."

`ADR-0199` and `VOXELIA-ALG-0033` produce, per vertex, a continuous viewport
coordinate and a view depth, and deliberately left two things to this contract:
how a continuous coordinate maps to covered pixels, and what a negative depth
means. Nothing else exists to build on — the arc-opening survey confirmed there
is no depth buffer or hidden-surface machinery anywhere in the project.

`ADR-0197` named the hardest obligation up front: "the exact tie-breaking rule
when two surfaces are equidistant at a pixel — a determinism obligation, not a
detail". Coplanar geometry is common in extracted surfaces, and a renderer that
resolves such ties by iteration or completion order is not reproducible.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0034` defines `surface-visibility-resolution/binary64-v1`: the
   sample rule, orientation canonicalisation, edge functions, fill rule,
   barycentric weights, interpolated depth, traversal order, bounding box,
   nearest-surface resolution and every representability failure.
2. **Samples are pixel centres.** A pixel is covered when `(i + 0.5, j + 0.5)`
   lies inside the projected facet, matching the continuous top-left
   convention `ALG-0033` froze. Area coverage, multi-sampling and analytic
   antialiasing are not version one; each changes output bits and needs its own
   record.
3. **Orientation is canonicalised, not culled.** A negative projected area
   causes `p1` and `p2` to swap so every later rule sees a positive area. A
   projection may mirror a facet, so screen winding is not mesh winding.
   **Back-facing facets are explicitly not culled**: extraction can publish
   open surfaces whose interior faces a diagnostic reader needs, and culling
   would silently hide legitimate geometry. The registered fixture proves both
   windings cover identical pixels at identical depths.
4. **A facet projecting to exactly zero area covers nothing and is not an
   error.** A facet seen edge-on, or collapsed by the singular placement
   `ADR-0198` deliberately admits, legitimately has zero projected area.
   Rejecting it would contradict that admission.
5. **The top-left fill rule is mandatory, not an optimisation.** A sample lying
   exactly on an edge shared by two facets must be claimed by exactly one.
   Without the rule it is claimed by both — a double-composited seam — or by
   neither — a crack. `ALG-0034` freezes the rule and the oracle proves a
   two-facet quad claims all sixteen pixels exactly once.
6. **The tie-break is structural: a candidate replaces the incumbent only when
   its depth is strictly less.** Two surfaces at exactly equal depth therefore
   leave the earlier `(layer, facet)` in place, because a non-strict
   comparison never fires. This is the whole determinism obligation
   `ADR-0197` flagged, discharged by one comparison operator rather than a
   special case — there is no separate tie-breaking branch to get wrong, and
   no arbitrary winner. Traversal order (layer order, then topology order) is
   consequently part of the contract, and `ALG-0034` states it.
7. **Barycentric weights are published alongside the winner.** Shading and
   colour mapping both need them, and recomputing them downstream would risk
   drift from the weights the depth was interpolated with. They correspond to
   the **canonicalised** vertex order, and `ALG-0034` says so explicitly
   because a consumer that ignored the swap would mis-attribute attributes.
8. **There is no near plane, no far plane and no depth clamping.** Negative
   depths are admitted, because `ALG-0033` admits behind-camera vertices under
   orthographic projection and nothing here divides by depth. A depth range is
   a clipping concern and belongs to `ADR-0197` increment (g).
9. **The bounding box is clamped, and clamping is not clipping.** A facet
   entirely outside the viewport covers nothing; a straddling facet
   contributes only its in-viewport samples. No geometry is cut and no vertex
   is moved, so nothing here pre-empts the clipping increment.
10. **The failure family is exactly two cases** — `coverageNotRepresentable`
    and `cancelled` — payload-free, `Sendable` and `Equatable`. There is
    deliberately no unsupported-projection case: this stage never sees a
    camera, and `ALG-0033` already rejected an unsupported projection before
    any vertex was projected. Restating it would carry an unreachable branch.
11. **The representability failure is reachable and is proven so.**
    `ALG-0033` admits finite projected coordinates of any magnitude and the
    edge function multiplies two differences, so an extreme facet overflows.
    The registered fixture spans `1e200`. This increment does not carry an
    error case it cannot demonstrate.
12. **This stage owns real payload and will declare a ceiling at migration.**
    Unlike the projector, visibility holds one hit record per pixel, and
    `ViewportSize` alone admits up to 16,384 by 16,384. The migration
    increment declares an explicit checked ceiling over that buffer; the
    projector's reasoning — that a budget belongs to the renderer — does not
    transfer, because this allocation scales with the viewport rather than
    with a mesh the caller already owns.
13. **Cancellation is checked before facet zero and every facet ordinal
    divisible by 64**, matching the facet cadence the measurement records use.
14. **This stage publishes nothing** — no colour, no image, no identity, no
    provenance. It resolves which facet is visible where.
15. **Independent analytical evidence is registered now.** The standard-library
    Python oracle records thirteen fixtures whose two SHA-256 digests are
    frozen in `ALG-0034`.

## Alternatives considered

### Break ties by layer order explicitly

Rejected as redundant. Using a strict-less comparison already yields
"earlier wins" with no extra rule, and an explicit tie-breaking branch would be
a second place for the same decision to live — and to drift.

### Break ties by an epsilon depth bias

Rejected. A bias is an epsilon by another name, it is scene-scale dependent,
and it makes the winner depend on a magnitude rather than on a stated order.
The project's no-epsilon discipline applies.

### Cull back-facing facets

Rejected for version one; see decision 3. Culling is a legitimate later option
for closed, certified surfaces — the enclosed-volume record already defines
what "certified closed" means — but applying it by default to arbitrary
extracted meshes would hide geometry a diagnostic reader needs.

### Use area coverage or multi-sampling

Rejected for version one. Both change output bits and need their own frozen
contract; centre sampling is the simplest rule that is exactly specifiable and
testable. Antialiasing remains available as a later record.

### Skip the fill rule and accept double coverage

Rejected. It produces visible seams on every shared edge and makes the covered
set depend on facet order in a way no downstream contract could compensate for.

### Clip geometry to the viewport instead of clamping the box

Rejected here. Clipping cuts geometry and creates new vertices, which is the
clipping increment's contract, and doing it now would pre-empt `VOX-SUR-006`
and duplicate its topology rules.

### Recompute barycentric weights downstream

Rejected; see decision 7.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about sampling, orientation, fill,
interpolation, ordering, tie-breaking or failure.

The deliberate limitations are no antialiasing, no backface culling, no depth
range and no transparency — the visible surface is the single nearest one, and
per-object opacity compositing is increment (d)'s contract, which will consume
this buffer rather than replace it.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds one internal deterministic resolver to `VoxeliaRendering`. No
dependency edge changes.

## Compatibility impact

None in this design-only increment. Antialiasing, culling or a depth range
would each be a new algorithm identity.

## Security impact

The buffer allocation is bounded by an explicit checked ceiling at migration;
traversal is cancellable; errors are payload-free and disclose no coordinates,
depths, counts or scene contents.

## Performance and memory impact

`O(sum of facet bounding-box areas)` time and one hit record per pixel. The
conventional optimisations — hierarchical tiling, early-Z, backface culling —
are all excluded from version one on correctness or contract grounds rather
than oversight, and any of them may be added later only if it reproduces this
reference bit-for-bit.

## Validation impact

The oracle registers:

```text
fixtureSHA256=f4f92219f39a9adaf634b1f60c5316a3b731c8c5722c67e45fb898f055ba2d43
bufferSHA256=35f0ccfd0811b51ba75150fee53b92a57f30f92b5a147381d52f7b009bd90725
fixtures=13 successful=12 failures=1
```

Migration must reproduce all thirteen fixtures bit-exactly, prove the
exactly-once shared-edge property, the strict-less tie-break by both layer and
facet, the uncalled backface behaviour, the cancellation cadence and the
checked buffer ceiling. This design increment requires oracle reproduction,
documentation, register, index, link, manifest and release-integrity checks;
product builds and tests are intentionally not evidence for a
documentation-only change. It discharges the **Test** half of `VOX-SUR-002`'s
verification methods only; no demonstration is claimed.

## Migration

1. Add the internal deterministic visibility resolver to `VoxeliaRendering`
   with an explicit checked buffer ceiling and every fixture from `ALG-0034`.
2. `ADR-0197` increment (d) freezes per-object opacity and the compositing
   order over this buffer.

## Supersession

This record executes `ADR-0197` decision 4(c) and supersedes no accepted
record.

## References

- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](ADR-0198-surface-scene-vocabulary.md)
- [ADR-0199 - Surface vertex projection design](ADR-0199-surface-vertex-projection-design.md)
- [VOXELIA-ALG-0033 - Surface vertex orthographic projection](../../algorithms/VOXELIA-ALG-0033-surface-vertex-projection.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](../../algorithms/VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
