---
document_id: "ADR-0206"
title: "Annotation registration design"
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
  - "VOX-SUR-002"
  - "VOX-SUR-008"
---

# ADR-0206 - Annotation registration design

## Context

`ADR-0197` decision 4(i) makes depth-aware annotation registration the arc's
ninth increment, governed by `VOX-SUR-008`: "Depth-aware annotations shall
remain correctly registered during camera movement."

`ADR-0197` decision 6 already split that row. The **correctness** half — an
annotation anchored to a geometry position projects to the right pixel and is
correctly occluded, at any given camera pose — is deterministically testable
off-screen. The **continuous-motion** half needs a real interactive draw loop
and the timing signal a synchronous off-screen renderer does not have, and the
draw loop is a standing owner-gated item. This record governs the correctness
half only.

No annotation vocabulary exists anywhere in the product yet. This increment
therefore has to decide what an anchored annotation *is* before it can decide
where it lands.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0040` defines `annotation-registration/binary64-v1`.
2. **An annotation is an anchor, and nothing else.** Version one models it as a
   world position in the scene's world space. No text, no glyph, no style, no
   size, no identifier. Those are presentation concerns with no consumer yet,
   and inventing them here would bind future callers to unmade claims — the
   same restraint `ADR-0205` applied when it declined to invent a durable
   object identifier.
3. **Registration is achieved by statelessness, and that is the whole claim.**
   The outcome is a pure function of the anchor, the pose and the visibility
   buffer, with nothing carried between poses. Smoothing, hysteresis or a
   cached previous pixel would make the answer depend on the path the camera
   travelled rather than on where it now is, which is exactly the drift
   `VOX-SUR-008` forbids. Two poses evaluated in either order give bit-identical
   answers.
4. **Registration composes the accepted projection; it does not re-project.**
   The anchor arrives already projected by `ALG-0033`. A second transform could
   disagree with the one that drew the image, for the same reason `ADR-0205`
   refused a second intersection.
5. **The occluder is the nearest *retained* depth, so the clip ordering is
   inherited.** A clipped-away surface cannot hide an annotation any more than
   it may swallow a pick. `ADR-0205` decision 3 already pinned clip-before-
   nearest; this record consumes that ordering rather than restating it.
6. **The pixel containing an anchor is its floor, not its rounding.**
   `ALG-0033` publishes continuous top-left coordinates and `ALG-0034` samples
   at pixel centres, so pixel `k` covers `[k, k+1)`. Rounding would move every
   anchor past the half-pixel into its neighbour and would place an anchor at a
   pixel centre exactly on the rounding boundary. Three registered fixtures pin
   the rule and both sides of an exact integer.
7. **The viewport bound is tested on the continuous coordinate, before any
   integer conversion, and that ordering is what makes the model total.** A
   coordinate that survives the test is inside the viewport, so its floor is
   representable. Testing after conversion would first have to convert an
   arbitrary finite double to an integer — the operation that traps.
8. **This stage therefore carries no failure family at all.** There is no
   representability failure by decision 7, no unsupported-projection case
   because `ALG-0033` already rejected one, and no cancellation checkpoint
   because registering one annotation is `O(1)` rather than a traversal.
   Carrying any of them would be an error with no possible evidence.
9. **Occlusion is strict, and the tie is resolved in the annotation's favour.**
   Only geometry strictly nearer than the anchor hides it; an exactly equal
   depth leaves it visible. This is the same strict-less comparison `ALG-0034`
   uses for its own tie-break, and an anchor placed on the surface it annotates
   must not be hidden by that surface.
10. **There is no depth bias, epsilon or polygon offset.** A bias is a magic
    number no accepted record supplies, and its effect changes with the scene's
    scale, so the same annotation would be judged differently on a millimetre
    mesh and a metre mesh. The honest consequence is recorded rather than
    hidden: the occluder's depth is sampled at the pixel centre while the anchor
    sits wherever it sits inside that pixel, so an anchor lying exactly on a
    steeply inclined facet can be judged occluded by its own facet. That is the
    correct answer to the question actually asked — is there retained geometry
    nearer than this position at this pixel — and forcing a surface-anchored
    annotation visible regardless is a presentation policy, not a geometric
    fact.
11. **An off-viewport anchor is reported, not thrown and not clamped.**
    Ordinary panning moves anchors off screen constantly, so a model that threw
    would make normal camera movement an error. Clamping to the rim would draw a
    marker at a physical place the anchor does not occupy, which is the
    fabrication `PickResolver` and `ADR-0205` both refuse. The bound is
    inclusive at zero and exclusive at the dimension on both axes, and negative
    zero needs no special case.
12. **A negative depth registers.** `ALG-0033` admits behind-camera vertices and
    `ALG-0034` imposes no near plane. The comparison is on the signed depth axis
    rather than on magnitude, so a more negative occluder still occludes.
13. **This stage publishes nothing** — no image, no overlay, no provenance. It
    answers a question about a pose.
14. **The motion half stays gated and is recorded as an outstanding
    demonstration dependency.** `VOX-SUR-008` declares `T,D`. This record and
    its migration discharge the **Test** half only. The demonstration half
    depends on the owner-gated interactive draw loop, exactly as `VOX-DVR-013`
    does, and must not be claimed by an off-screen render.
15. **Independent analytical evidence is registered now**: nineteen fixtures,
    fifteen registered and four off-viewport, with two SHA-256 digests frozen in
    `ALG-0040`.

## Alternatives considered

### Model a full annotation type now (text, style, size, identifier)

Rejected; see decision 2. No consumer exists, and a presentation vocabulary
invented without one becomes canonical by default.

### Re-project the anchor inside this stage

Rejected; see decision 4. It is the second-predicate mistake `ADR-0205` already
rejected for picking, in a different costume.

### Round the continuous coordinate to the nearest pixel

Rejected; see decision 6. It contradicts the half-open pixel extent `ALG-0033`
and `ALG-0034` jointly imply, and puts a pixel-centre anchor on the rounding
boundary.

### Add a depth bias so surface-anchored annotations never self-occlude

Rejected; see decision 10. The bias is unsupplied, scale-dependent, and would
replace an exact rule with a tuned one. The residual behaviour is recorded
instead of being papered over.

### Throw on an off-viewport anchor, or clamp it to the viewport edge

Rejected; see decision 11. Throwing makes panning an error; clamping fabricates
a position.

### Carry the previous pose's pixel to stabilise the annotation

Rejected; see decision 3. Hysteresis is precisely the thing that makes an
annotation *incorrectly* registered — it would make the same pose give different
answers depending on how the camera arrived.

### Claim the demonstration half from a two-pose off-screen render

Rejected; see decision 14. Two static poses are not continuous motion, and
`ADR-0197` decision 8 already binds this arc to record the demonstration half as
a dependency rather than silently claiming it.

## Consequences

The next migration can implement one bounded, stateless, exact, non-throwing
reference with no remaining choice about the pixel rule, the bound, the
comparison, the bias or the off-viewport outcome. The **Test** half of
`VOX-SUR-008` becomes dischargeable; the demonstration half remains an
explicitly recorded gate.

The deliberate limitations are a position-only anchor, one annotation at a time,
no label layout or collision avoidance, and no continuous-motion claim.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the registration reference to `VoxeliaRendering`. No dependency
edge changes.

## Compatibility impact

None in this design-only increment.

## Security impact

No allocation beyond one result; the stage is non-throwing and discloses no
positions, depths or scene contents.

## Performance and memory impact

`O(1)` per annotation per pose.

## Validation impact

The oracle registers:

```text
fixtureSHA256=8950824148a6fd801296f2114328d198bf613c8c10dcb95422e23f82d0b97615
registrationSHA256=53ee6d24ef61d5b57f2c13d1ac4f8f647d83907b1b88534718ba9dc0f0a1ea93
fixtures=19 registered=15 offViewport=4
```

Migration must reproduce all nineteen fixtures bit-exactly, prove the floor rule
on both sides of an exact integer, prove all four viewport edges, prove the
strict comparison including the exactly-equal case, and prove the two-pose
claim **against the accepted projector rather than against hand-written
coordinates** — an anchor fixed in world space, projected at two camera poses,
landing in the pixel each pose implies. This design increment requires oracle
reproduction, documentation, register, index, link, manifest and
release-integrity checks.

## Migration

1. Add the registration reference to `VoxeliaRendering` with every fixture from
   `ALG-0040`, plus the two-pose test driven by `SurfaceVertexProjector`.
2. `ADR-0197` increment (j) assesses `VOX-SUR-009`, which declares **I,T** and
   therefore carries a test obligation.

## Supersession

This record executes `ADR-0197` decision 4(i) and supersedes no accepted record.

## References

- [ADR-0125 - Pick resolution](ADR-0125-pick-resolution.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](ADR-0198-surface-scene-vocabulary.md)
- [ADR-0199 - Surface vertex projection design](ADR-0199-surface-vertex-projection-design.md)
- [ADR-0205 - Surface picking design](ADR-0205-surface-picking-design.md)
- [VOXELIA-ALG-0033 - Surface vertex orthographic projection](../../algorithms/VOXELIA-ALG-0033-surface-vertex-projection.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](../../algorithms/VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [VOXELIA-ALG-0040 - Depth-aware annotation registration](../../algorithms/VOXELIA-ALG-0040-annotation-registration.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
