---
document_id: "VOXELIA-ALG-0040"
title: "Depth-aware annotation registration binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Depth-aware annotation registration binary64-v1

## Purpose

This specification defines `annotation-registration/binary64-v1`, the
deterministic CPU reference selected by accepted
[`ADR-0206`](../architecture/decisions/ADR-0206-annotation-registration-design.md).
For one annotation anchored at a world position it decides which viewport pixel
the anchor occupies under a given camera pose, and whether surface geometry
hides it.

## Registration is statelessness

An annotation is "correctly registered" when its screen position follows the
geometry it is anchored to. This model achieves that by carrying **no state
whatever** between camera poses: the outcome is a pure function of the anchor,
the pose and the visibility buffer.

That is the whole claim. Any smoothing, hysteresis or cached previous pixel
would make the answer depend on the path the camera travelled rather than on
where it now is — which is exactly the drift the requirement forbids. Two poses
evaluated in either order, or one pose evaluated twice, give bit-identical
answers.

## Registration composes; it does not re-project

The anchor arrives **already projected** by
[`VOXELIA-ALG-0033`](VOXELIA-ALG-0033-surface-vertex-projection.md), as a
continuous column, a continuous row and a depth along the camera's forward
direction. This stage adds no second projection, for the same reason
[`VOXELIA-ALG-0039`](VOXELIA-ALG-0039-surface-picking.md) adds no second
intersection: a second transform could disagree with the one that drew the
image, and an annotation that disagrees with what the user is looking at is
worse than no annotation at all.

The occluder likewise arrives as the nearest **retained** depth per pixel — the
clip predicate has already run, so a clipped-away surface cannot hide an
annotation any more than it may swallow a pick.

## The frozen rule

```text
1. if the continuous column is outside 0..<width, or the continuous row is
   outside 0..<height, report off-viewport
2. column = floor(continuous column), row = floor(continuous row)
3. look up the nearest retained occluder depth at that same pixel
4. occluded = an occluder exists and its depth < the anchor's depth
5. report the pixel, the anchor's depth and the occlusion
```

**Step 1 precedes step 2, and that ordering is what makes the model total.** The
bound is tested on the *continuous* coordinate, before any integer conversion,
so a coordinate that reaches step 2 is already inside the viewport and its floor
is representable. Testing after conversion would have to convert an arbitrary
finite double to an integer first, which is exactly the operation that traps.
This stage therefore carries **no representability failure and no failure family
at all**.

**Step 2 is a floor, not a rounding.** `ALG-0033` publishes continuous top-left
coordinates and `ALG-0034` samples at pixel centres, so pixel `k` covers
`[k, k+1)`. Rounding would move every anchor past the half-pixel into its
neighbour, and an anchor at a pixel centre would sit on the rounding boundary.
The registered `floor-not-round`, `integer-boundary` and `just-below-boundary`
fixtures pin the rule and both sides of an exact integer.

**Step 3 reuses the pixel step 2 decided.** One pixel rule serves the placement
and the occlusion lookup, so the two cannot disagree about which pixel is being
asked about. The registered `occluder-elsewhere` fixture confirms that geometry
at other pixels, however near, leaves the annotation visible.

**Step 4 is strict.** Only geometry strictly nearer than the anchor hides it; an
exactly equal depth leaves the annotation visible. This is the same strict-less
comparison `ALG-0034` uses for its own tie-break, and it resolves the tie in the
annotation's favour because an anchor placed on the surface it annotates must
not be hidden by that surface. The registered `equal-depth-visible` fixture pins
it.

## There is no depth bias

No epsilon, no offset, no polygon-offset term. A bias is a magic number no
accepted record supplies, and its effect changes with the scene's scale, so the
same annotation would be judged differently on a millimetre mesh and a metre
mesh. The comparison is exact and the tie is decided by the operator itself.

The honest consequence is recorded rather than hidden: the occluder's depth is
sampled at the pixel centre while the anchor sits wherever it sits inside that
pixel, so an anchor lying exactly on a steeply inclined facet can be judged
occluded by its own facet. That is the correct answer to the question actually
asked — *is there retained geometry nearer than this position at this pixel* —
and whether a surface-anchored annotation should be forced visible regardless is
a presentation policy, not a geometric fact.

## Off-viewport is reported, never clamped and never a failure

An anchor outside the viewport is reported as off-viewport. It is **not** a
typed failure: ordinary panning moves anchors off screen constantly, and a model
that threw would make normal camera movement an error. It is **not** clamped to
the viewport rim either, because a marker drawn at the edge claims a physical
place it does not occupy — the same honesty rule `PickResolver` and `ALG-0039`
follow.

The bound is inclusive at zero and exclusive at the dimension, on both axes. The
registered `first-pixel`, `last-pixel`, `column-at-width-off`,
`row-at-height-off`, `negative-column-off` and `negative-row-off` fixtures pin
all four edges. Negative zero needs no special case: it compares equal to zero
and floors to zero, which the `negative-zero` fixture records.

## Depth range

A negative depth registers. `ALG-0033` admits behind-camera vertices under
orthographic projection and `ALG-0034` imposes no near plane, so an anchor
behind the camera is still placed. The comparison is on the signed depth axis
rather than on magnitude, so a more negative occluder still occludes — the
`behind-camera-visible` and `behind-camera-occluded` fixtures record both.

## Determinism and accelerated conformance

The reference is stateless and depends only on its inputs. An accelerated
implementation must place the annotation in the identical pixel and reach the
identical occlusion verdict; a GPU depth test conforms only if its comparison is
strict, unbiased and performed against the same retained-nearest depth.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0206-annotation-registration-oracle.py`](../progress/evidence/ADR-0206-annotation-registration-oracle.py).
It records nineteen fixtures: an unoccluded anchor; strictly nearer, farther and
exactly equal occluders; the floor rule with both sides of an exact integer;
both extreme in-bounds pixels; all four out-of-viewport directions; negative
zero; a behind-camera anchor visible and occluded; an occluder at another pixel;
and one fixed anchor under two camera poses whose pixel moves and whose
occlusion flips.

The registered output is:

```text
fixtureSHA256=8950824148a6fd801296f2114328d198bf613c8c10dcb95422e23f82d0b97615
registrationSHA256=53ee6d24ef61d5b57f2c13d1ac4f8f647d83907b1b88534718ba9dc0f0a1ea93
fixtures=19 registered=15 offViewport=4
pixel=floor occlusion=strict-nearer bias=none
offViewport=reported-not-clamped state=none
```

## Complexity and exclusions

`O(1)` per annotation per pose.

Continuous-motion behaviour during an interactive draw loop, label layout,
collision avoidance between annotations, leader lines, annotation persistence,
anchoring to anything other than a world position, and any published artefact
remain separate contracts.

## References

- [ADR-0125 - Pick resolution](../architecture/decisions/ADR-0125-pick-resolution.md)
- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0206 - Annotation registration design](../architecture/decisions/ADR-0206-annotation-registration-design.md)
- [VOXELIA-ALG-0033 - Surface vertex orthographic projection](VOXELIA-ALG-0033-surface-vertex-projection.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [VOXELIA-ALG-0039 - Authoritative surface picking](VOXELIA-ALG-0039-surface-picking.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
