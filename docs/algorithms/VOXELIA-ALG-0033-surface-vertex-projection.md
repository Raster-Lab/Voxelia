---
document_id: "VOXELIA-ALG-0033"
title: "Surface vertex orthographic projection binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Surface vertex orthographic projection binary64-v1

## Purpose

This specification defines `surface-vertex-orthographic-projection/binary64-v1`,
the deterministic CPU reference selected by accepted
[`ADR-0199`](../architecture/decisions/ADR-0199-surface-vertex-projection-design.md).
It maps every vertex of a `SurfaceLayer`'s mesh from the mesh's own coordinate
space to continuous viewport coordinates and a view depth.

It is an intermediate model, not a published artefact: it produces no image, no
identity and no provenance. Visibility, compositing, shading and the pixel
contract are separate accepted contracts.

## Projection support

Version one supports **orthographic projection only**. A camera declaring
`CameraProjection.perspective` is rejected with `unsupportedProjection`.

This is the recorded settlement of the deferral `ADR-0173` left open, as
`ADR-0197` decision 4(b) required. It is a typed, tested rejection with a
stated reason rather than silence: `ADR-0199` records exactly what a
perspective version must additionally settle — the eye-plane straddling case,
near-plane clipping, the homogeneous divide and behind-camera vertices — none
of which any accepted record supplies.

## Input domain and admission

The numerical inputs are one `SurfaceLayer` and one `SurfaceRenderRequest`,
both already admitted. Their accepted admissions are **composed, not
restated**:

- `Matrix4x4Double` guarantees sixteen finite row-major elements.
- `SurfaceLayer` guarantees a bottom row of exactly `(0, 0, 0, 1)`, so the
  transform is affine and the homogeneous `w` of every transformed point is
  exactly one. No divide by `w` occurs anywhere in this model.
- `RenderCamera` guarantees a non-degenerate view direction, a view-up cross
  product whose magnitude is at least `Double.leastNormalMagnitude`, and — for
  the orthographic case — a finite `planeHeight` strictly greater than zero.
- `ViewportSize` guarantees `width` and `height` in `1...16384`.
- `TriangleMesh` guarantees finite positions.
- `SurfaceRenderRequest` guarantees the scene's world space is the camera's
  declared space.

Because those admissions already hold, this model performs no re-validation.
Its only failure classes are the projection rejection and arithmetic
representability.

## Camera basis

The basis is computed once per request, before any vertex is touched:

```text
forwardRaw = target - position          (three ordered subtractions)
forward    = normalise(forwardRaw)
right      = normalise(forward x up)
trueUp     = normalise(right x forward)
```

The cross product uses the same ordered expression frozen by
[`VOXELIA-ALG-0030`](VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md):

```text
c.x = (a.y * b.z) - (a.z * b.y)
c.y = (a.z * b.x) - (a.x * b.z)
c.z = (a.x * b.y) - (a.y * b.x)
```

`normalise` is the maximum-component-scaled Euclidean normalisation frozen by
the same record: divide each component by the largest absolute component, sum
the squares as `(s0 + s1) + s2`, take the correctly rounded square root, divide
each scaled component by it, and write positive zero for any component
comparing equal to zero.

`trueUp` is normalised even though `right` and `forward` are unit and
orthogonal in exact arithmetic. In binary64 their cross product is only near
unit length, and normalising is cheaper than an unstated "close enough" claim.

## Object to world

For one vertex `(x, y, z)` and the row-major affine matrix `m`, each world
component is:

```text
w[row] = ((m[4*row+0] * x + m[4*row+1] * y) + m[4*row+2] * z) + m[4*row+3]
```

Every displayed multiplication and addition is one separate correctly rounded
binary64 operation in exactly that order. The `((a + b) + c) + d` grouping is
part of the algorithm identity: the registered grouping-sensitive fixture uses
a row whose first two terms cancel exactly, so the frozen order yields one
where `a + ((b + c) + d)` yields zero.

No fused multiply-add, reassociation, matrix pre-multiplication into a single
combined object-to-view matrix, or SIMD horizontal reduction is permitted. In
particular, folding the object-to-world and world-to-view transforms into one
matrix before applying it would change the published bits and is a different
algorithm.

## World to view

```text
d = world - position                    (three ordered subtractions)

viewX = ((d.x * right.x   + d.y * right.y)   + d.z * right.z)
viewY = ((d.x * trueUp.x  + d.y * trueUp.y)  + d.z * trueUp.z)
depth = ((d.x * forward.x + d.y * forward.y) + d.z * forward.z)
```

Each dot product uses the frozen `((a + b) + c)` grouping and is evaluated in
the order `viewX`, `viewY`, `depth`.

**Depth is measured along `forward`**, increasing away from the camera. It is
not a negated `Z` and it is not normalised into any clip range. A vertex behind
the camera yields a negative depth and is **admitted**: an orthographic
projection has no eye point, so "behind" carries no arithmetic hazard. What
visibility does with a negative depth is the visibility contract's decision.

## View to viewport

```text
worldPerPixel = planeHeight / height
halfWidth     = width  / 2
halfHeight    = height / 2

column = halfWidth  + (viewX / worldPerPixel)
row    = halfHeight - (viewY / worldPerPixel)
```

`width` and `height` are converted to `Double` exactly, being integers in
`1...16384`. `halfWidth` and `halfHeight` are exact.

**Pixels are square by construction.** The scale is derived from the plane
height and the pixel height alone; the plane width is whatever that scale and
the pixel width imply. The aspect ratio is therefore never an independent
parameter and a non-square viewport cannot silently stretch geometry. The
registered wide-viewport fixture is an eight-by-two viewport proving it.

**Viewport coordinates are continuous, origin top-left**, with `column`
increasing right and `row` increasing down, matching the presented-image
convention the accepted 2D path already uses. Pixel `(i, j)` covers
`[i, i+1) x [j, j+1)` and its centre is `(i + 0.5, j + 0.5)`. No rounding,
flooring or clamping happens here: converting a continuous coordinate to a
covered pixel belongs to the visibility contract.

## Precision and representability

The reference uses IEEE-754 binary64, round-to-nearest-ties-to-even, gradual
subnormals, no fast math, no flush-to-zero, no contraction, no reassociation
and no higher-precision accumulator. After every subtraction, multiplication,
addition, division and square root, the result must be finite; a NaN or
infinity fails as `positionNotRepresentable`.

The separated multiply-then-subtract in the cross product is part of the
identity. The registered contraction-sensitive fixture shows that a fused
multiply-subtract produces a different basis, and therefore different
projected bits.

This deliberately rejects some finite scenes whose mathematically
representable projection overflows the frozen expression — a placement whose
translation and scale together exceed the binary64 range, for instance.

## Failure precedence and cancellation

The public payload-free failure family is:

```text
unsupportedProjection
positionNotRepresentable
cancelled
```

Order is: task cancellation; the projection-support check; the camera basis;
then per-vertex work. The projection check precedes the basis so a perspective
camera is rejected without any arithmetic.

Vertex traversal checks cancellation before vertex zero and every vertex
ordinal divisible by 4,096, matching the cadence `ADR-0193` froze for
per-vertex work. Cancellation at a poll precedes the vertex at that ordinal.

There is deliberately no resource-ceiling failure and no limits value. This
model allocates one projected record per vertex over a mesh the caller already
owns and whose vertex count `TriangleMesh` already bounds to the host domain,
and it is an intermediate rather than a published artefact. A ceiling belongs
to the renderer that owns the whole pipeline's budget, not to one stage of it.

An empty mesh projects to no vertices and is not a failure.

## Determinism and accelerated conformance

The reference is serial and stateless. Repeated execution over the same layer,
camera and viewport bits produces the same projected bits. An accelerated
implementation must reproduce every component bit-for-bit and the same failure
class; ordinary floating-point tolerance is insufficient because the basis
construction, the grouping and the separated cross product are all part of the
algorithm.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0199-surface-vertex-projection-oracle.py`](../progress/evidence/ADR-0199-surface-vertex-projection-oracle.py).
It forces each displayed operation through binary64 and records twelve
fixtures:

- a camera on `+Z` looking at the origin over a four-by-three viewport, where
  the origin lands at the exact viewport centre `(2.0, 1.5)` at depth `10.0`;
- a translated placement whose depth becomes exactly `7.0`;
- an eight-by-two viewport proving square pixels are height-derived;
- a vertex behind the camera at depth exactly `-10.0`, admitted;
- a singular placement collapsing all three vertices to one projected point;
- a uniformly scaled placement;
- an oblique camera exercising the full basis construction;
- a grouping-sensitive object-to-world row whose frozen order yields one where
  the regrouped order yields zero;
- a contraction-sensitive up vector where a fused multiply-subtract changes the
  basis;
- an empty mesh projecting to no vertices;
- a placement whose combined scale and translation overflow, rejected
  `positionNotRepresentable`; and
- a perspective camera, rejected `unsupportedProjection`.

The registered output is:

```text
fixtureSHA256=cbb73b21b0a3789aa46c08f3195893e7329b376b0c9639fa06ec60459cb39a38
projectionBytesSHA256=6171752e014b1a05774b15739faf44e5222764f18ebda7f4de6749674127e017
fixtures=12 successful=10 failures=2
projection=orthographic-only perspective=rejected-typed
depth=along-forward behindCamera=negative-admitted
pixelOrigin=top-left-continuous squarePixels=height-derived
```

Swift conformance is bit-exact for every projected component and exact for
failure classes and checkpoint order. No numeric tolerance applies. The oracle
does not validate Swift allocation lifetime, concurrency or cancellation
machinery.

## Complexity and exclusions

The reference is `O(vertexCount)` after an `O(1)` basis construction, and holds
one three-component record per vertex. No wall-clock throughput bound is
promised.

Perspective projection, near and far planes, clip-space normalisation,
frustum culling, backface culling, rasterisation, depth testing, compositing,
shading, colour mapping, clipping, picking and any published image remain
separate contracts.

## References

- [ADR-0082 - Rendering camera and viewport models](../architecture/decisions/ADR-0082-rendering-camera-and-viewport.md)
- [ADR-0173 - Orthographic ray generator](../architecture/decisions/ADR-0173-orthographic-ray-generator.md)
- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](../architecture/decisions/ADR-0198-surface-scene-vocabulary.md)
- [ADR-0199 - Surface vertex projection design](../architecture/decisions/ADR-0199-surface-vertex-projection-design.md)
- [VOXELIA-ALG-0030 - Triangle area-weighted vertex normals](VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
