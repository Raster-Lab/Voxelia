---
document_id: "VOXELIA-ALG-0034"
title: "Surface visibility resolution binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Surface visibility resolution binary64-v1

## Purpose

This specification defines `surface-visibility-resolution/binary64-v1`, the
deterministic CPU reference selected by accepted
[`ADR-0200`](../architecture/decisions/ADR-0200-surface-visibility-design.md).
It consumes the projected vertices
[`VOXELIA-ALG-0033`](VOXELIA-ALG-0033-surface-vertex-projection.md) produces and
resolves, for every viewport pixel, which facet of which layer is nearest and
with what barycentric weights.

It produces no colour and no image. Shading, colour maps, opacity compositing
and publication are separate contracts.

## Sample rule

A pixel is covered when its **centre** lies inside the projected facet. Pixel
`(i, j)`'s centre is `(i + 0.5, j + 0.5)`, matching the continuous top-left
convention `ALG-0033` froze. Area coverage, multi-sampling and analytic
antialiasing are not version one.

## Orientation canonicalisation

For projected vertices `p0`, `p1`, `p2` the doubled signed area is:

```text
area = ((p1.column - p0.column) * (p2.row - p0.row))
     - ((p1.row - p0.row) * (p2.column - p0.column))
```

If `area` is exactly zero the facet covers nothing and is skipped. It is not an
error: a facet seen edge-on, or collapsed by a singular placement the
vocabulary admits, legitimately projects to zero area.

If `area` is negative the facet is evaluated with `p1` and `p2` **swapped**,
and `area` recomputed by the same expression. A projection may mirror a facet,
so screen winding is not mesh winding, and every subsequent rule assumes a
positive area.

**Back-facing facets are not culled.** The swap canonicalises orientation for
the fill rule; it does not discard anything. Extraction can publish open
surfaces whose interior faces a diagnostic reader needs to see, so culling
would hide legitimate geometry. The registered fixture proves a facet wound
both ways covers exactly the same pixels at the same depths.

## Edge functions and the fill rule

For the directed edge `a -> b` and a sample `(sc, sr)`:

```text
E(a, b) = ((b.column - a.column) * (sr - a.row))
        - ((b.row - a.row) * (sc - a.column))
```

Every displayed subtraction and multiplication is one separate correctly
rounded binary64 operation in exactly that order.

The three edge values are evaluated as `e0 = E(p1, p2)`, `e1 = E(p2, p0)`,
`e2 = E(p0, p1)`, in that order.

A sample is covered when, for each `k`, either `e[k] > 0`, or `e[k] == 0` and
that edge is a **top-or-left** edge. On the positive-area winding, with rows
increasing downward, edge `a -> b` is top-or-left exactly when:

```text
if a.row == b.row:  b.column < a.column
else:               b.row > a.row
```

This fill rule is not an optimisation. Without it a sample lying exactly on an
edge shared by two facets would be claimed by both — producing a
double-composited seam — or by neither, producing a crack. The registered
`shared-edge-quad` fixture tiles a four-by-four viewport with two facets
sharing a diagonal and proves every one of the sixteen pixels is claimed
**exactly once**.

## Barycentric weights and interpolated depth

For a covered sample:

```text
w0 = e0 / area
w1 = e1 / area
w2 = e2 / area

depth = ((w0 * p0.depth) + (w1 * p1.depth)) + (w2 * p2.depth)
```

The weights correspond to the **canonicalised** vertex order, so after a swap
`w1` belongs to the original `p2`. Consumers receive the weights alongside the
facet ordinal and must apply the same correspondence.

The `((a + b) + c)` grouping is part of the algorithm identity, as it is in
`ALG-0030`, `ALG-0033` and the measurement records.

## Traversal order and the bounding box

Facets are visited in layer order, then topology order. Within one facet,
samples are visited in row-major order over the integer bounding box:

```text
firstColumn = max(0, floor(min column))
lastColumn  = min(width - 1, ceil(max column))
firstRow    = max(0, floor(min row))
lastRow     = min(height - 1, ceil(max row))
```

The box is clamped to the viewport, so a facet entirely outside covers nothing
and a straddling facet contributes only its in-viewport samples. Clamping is
not clipping: no geometry is cut and no vertex is moved.

## Nearest-surface resolution and the tie-break

Each pixel holds at most one hit. A candidate replaces the incumbent **only
when its depth is strictly less**:

```text
if incumbent is absent or candidate.depth < incumbent.depth: replace
```

That single rule is also the tie-break. Two surfaces at *exactly* equal depth
leave the incumbent — the earlier `(layer, facet)` — in place, because a
non-strict comparison never fires. The determinism obligation is therefore
discharged structurally rather than by a special case, and coplanar geometry
resolves to a stable, reproducible winner instead of an arbitrary one.

The registered `equal-depth-tie` fixture proves the earlier layer wins, and
that within one layer the earlier facet wins for the same reason.

## Depth range

There is no near plane, no far plane and no depth clamping in version one.
Negative depths are admitted, because `ALG-0033` admits behind-camera vertices
under orthographic projection and nothing here introduces a division by depth.
A depth range is a clipping concern and belongs to the clipping contract.

## Precision and representability

IEEE-754 binary64, round-to-nearest-ties-to-even, gradual subnormals, no fast
math, no flush-to-zero, no contraction, no reassociation. After every
subtraction, multiplication, division and addition the result must be finite; a
NaN or infinity fails as `coverageNotRepresentable`.

That failure is reachable, not theoretical: `ALG-0033` admits finite projected
coordinates of any magnitude, and the edge function multiplies two differences.
The registered overflow fixture uses a facet spanning `1e200`.

## Failure precedence and cancellation

```text
coverageNotRepresentable
cancelled
```

Cancellation is checked before facet zero and every facet ordinal divisible by
64, matching the facet cadence the measurement records use. Cancellation at a
poll precedes the facet at that ordinal.

There is deliberately no unsupported-projection case: this stage never sees a
camera. `ALG-0033` already rejected an unsupported projection before any
vertex was projected, so restating it here would carry an unreachable branch.

## Determinism and accelerated conformance

The reference is serial and stateless. Identical projected inputs produce an
identical buffer. An accelerated implementation must reproduce every depth and
weight bit-for-bit, the same coverage set and the same winner at every pixel.
Tolerance is insufficient: the fill rule, the strict-less tie-break and the
traversal order are all part of the algorithm, and a GPU rasteriser that
resolves ties by completion order does **not** conform.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0200-surface-visibility-oracle.py`](../progress/evidence/ADR-0200-surface-visibility-oracle.py).
It records thirteen fixtures:

- a facet covering the whole viewport at uniform depth;
- a sub-pixel facet covering exactly one pixel, proving centre sampling;
- two facets sharing a diagonal, every pixel claimed exactly once;
- a nearer facet fully replacing a farther one;
- two facets at exactly equal depth, the earlier winning by layer and by
  facet;
- a facet wound both ways covering identical pixels at identical depths;
- a facet projecting to zero area covering nothing;
- a negative-depth facet winning over a positive-depth one;
- a facet entirely outside the viewport;
- a facet straddling the viewport edge;
- a tilted facet whose interpolated depth varies across the buffer;
- an empty scene; and
- an edge function overflowing at `1e200`, rejected
  `coverageNotRepresentable`.

The registered output is:

```text
fixtureSHA256=f4f92219f39a9adaf634b1f60c5316a3b731c8c5722c67e45fb898f055ba2d43
bufferSHA256=35f0ccfd0811b51ba75150fee53b92a57f30f92b5a147381d52f7b009bd90725
fixtures=13 successful=12 failures=1
sampling=pixel-centre fillRule=top-left backfaces=not-culled
tieBreak=strictly-nearer-replaces depthRange=unbounded
```

Swift conformance is bit-exact for every depth and weight and exact for
coverage, winners, failure classes and checkpoint order. No numeric tolerance
applies.

## Complexity and exclusions

`O(sum over facets of bounding-box area)` time and one hit record per pixel of
governed payload. No wall-clock throughput bound is promised.

Antialiasing, multi-sampling, area coverage, backface culling, near and far
planes, transparency, shading, colour maps, clipping, picking and any published
image remain separate contracts.

## References

- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](../architecture/decisions/ADR-0198-surface-scene-vocabulary.md)
- [ADR-0199 - Surface vertex projection design](../architecture/decisions/ADR-0199-surface-vertex-projection-design.md)
- [ADR-0200 - Surface visibility design](../architecture/decisions/ADR-0200-surface-visibility-design.md)
- [VOXELIA-ALG-0033 - Surface vertex orthographic projection](VOXELIA-ALG-0033-surface-vertex-projection.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
