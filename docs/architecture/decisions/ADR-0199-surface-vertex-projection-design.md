---
document_id: "ADR-0199"
title: "Surface vertex projection design"
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
  - "VOX-GEO-002"
  - "VOX-NUM-001"
  - "VOX-SPA-004"
  - "VOX-SUR-001"
---

# ADR-0199 - Surface vertex projection design

## Context

`ADR-0197` decision 4(b) makes the coordinate-space transform and projection
the surface arc's second increment, governed by `VOX-SUR-001`: "Voxelia shall
render triangle meshes with explicit coordinate-space transforms." `ADR-0198`
froze the vocabulary those transforms act on.

`ADR-0197` also placed a specific obligation on this increment: it must settle
the perspective case `ADR-0173` deferred, "either by freezing a perspective
model or by recording explicitly that surface rendering stays orthographic in
version one", and may not leave `CameraProjection.perspective` declared but
unhonoured by any accepted renderer.

The accepted values this increment stands on already validate a great deal.
`Matrix4x4Double` guarantees sixteen finite elements; `SurfaceLayer` guarantees
an affine bottom row; `RenderCamera` guarantees a non-degenerate view direction,
a view-up cross product at or above `Double.leastNormalMagnitude`, and a finite
positive `planeHeight`; `ViewportSize` bounds both dimensions to `1...16384`;
`SurfaceRenderRequest` guarantees the scene's world space is the camera's.
This record composes those admissions rather than restating them.

## Decision

1. **Version one is orthographic only, and the deferral is settled by explicit
   typed rejection.** A camera declaring `CameraProjection.perspective` is
   rejected with `unsupportedProjection`. This is the second option
   `ADR-0197` decision 4(b) sanctioned, taken deliberately: the enum case is
   no longer merely unhonoured, it has an accepted record stating what happens,
   a named error and a registered fixture.
2. **What a perspective version must additionally settle is recorded now**, so
   the deferral is bounded rather than open-ended: the behaviour of a triangle
   straddling the eye plane; whether near-plane clipping happens before or
   after projection and what it does to topology; the homogeneous divide and
   its behaviour as `w` approaches zero; and what a behind-camera vertex means
   when division by depth is involved. None of those is supplied by any
   accepted record, and each changes output bits. A perspective model is a new
   algorithm identity, not a parameter of this one.
3. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0033` defines
   `surface-vertex-orthographic-projection/binary64-v1`: the camera basis
   construction, the object-to-world application, the world-to-view dot
   products, the view-to-viewport scaling, every expression order and every
   representability failure.
4. **The basis reuses accepted expressions rather than inventing new ones.**
   The cross product is the exact ordered expression `VOXELIA-ALG-0030` froze,
   and normalisation is that record's maximum-component-scaled Euclidean rule.
   Reusing them keeps the surface arc bit-consistent with geometry about the
   same primitives, and is the reason `ALG-0033` cites `ALG-0030` rather than
   restating its arithmetic.
5. **`trueUp` is normalised despite being unit in exact arithmetic.** `right`
   and `forward` are unit and orthogonal mathematically, so their cross product
   has unit length — but not exactly, in binary64. Normalising costs one
   operation and replaces an unstated "close enough" assumption with a stated
   rule.
6. **Depth is measured along `forward`, increasing away from the camera.** It
   is not a negated `Z`, not normalised into a clip range, and not clamped. A
   behind-camera vertex yields a negative depth and is **admitted**: an
   orthographic projection has no eye point, so "behind" carries no arithmetic
   hazard, and inventing a rejection would claim an authority this stage does
   not have. What visibility does with a negative depth is the visibility
   contract's decision.
7. **Pixels are square by construction, and the aspect ratio is not a
   parameter.** The scale comes from `planeHeight / height` alone; the plane
   width is whatever that scale and the pixel width imply. A non-square
   viewport therefore cannot silently stretch geometry, and there is no second
   knob that could contradict the first.
8. **Viewport coordinates are continuous with a top-left origin**, `column`
   increasing right and `row` increasing down, matching the presented-image
   convention the accepted 2D path already uses. Pixel `(i, j)` covers
   `[i, i+1) x [j, j+1)` with centre `(i + 0.5, j + 0.5)`. No rounding,
   flooring or clamping happens here; mapping a continuous coordinate to a
   covered pixel is the visibility contract's job.
9. **No matrix pre-multiplication.** Folding object-to-world and world-to-view
   into one combined matrix is the conventional optimisation and is
   **forbidden**, because it changes the published bits. `ALG-0033` says so
   explicitly so that a future implementer cannot introduce it as a
   performance improvement without registering a new algorithm version.
10. **The failure family is exactly three cases** — `unsupportedProjection`,
    `positionNotRepresentable` and `cancelled` — payload-free, `Sendable` and
    `Equatable`.
11. **There is deliberately no limits value and no resource-ceiling case.**
    This model allocates one projected record per vertex over a mesh the caller
    already owns, whose vertex count `TriangleMesh` already bounds to the host
    domain, and it is an intermediate rather than a published artefact. A
    ceiling belongs to the renderer that owns the whole pipeline's budget, not
    to one stage of it. Declaring one here would imply this stage governs a
    budget it does not.
12. **This stage publishes nothing.** It produces projected coordinates and
    depths, not an image, an identity or a provenance record. Publication is
    the renderer increment's boundary, exactly as it was for the volume arc.
    Consequently there is no parameter document and no digest in this
    increment; the renderer's own parameter document will name this algorithm.
13. **Cancellation follows the accepted per-vertex cadence**: before vertex
    zero and every vertex ordinal divisible by 4,096, matching `ADR-0193`.
    The projection-support check precedes the basis construction so a
    perspective camera costs no arithmetic.
14. **Independent analytical evidence is registered now.** The
    standard-library Python oracle forces every displayed binary64 operation
    and proves the exact viewport centre, translated depth, height-derived
    square pixels, an admitted behind-camera vertex, a collapsed placement, an
    oblique basis, grouping sensitivity, contraction sensitivity, the empty
    mesh, an overflow and the perspective rejection. Its two SHA-256 fixtures
    are frozen in `ALG-0033`.

## Alternatives considered

### Freeze a perspective model now

Rejected for version one. It requires settling eye-plane straddling,
near-plane clipping and its topology effects, the homogeneous divide, and
behind-camera semantics under division — a clipping contract in its own right,
overlapping `VOX-SUR-006`, which is a later increment. Taking it now would
either pre-empt that increment or ship an under-specified divide. The
alternative chosen — explicit typed rejection plus a recorded list of what a
perspective version must settle — discharges `ADR-0197`'s obligation without
inventing a contract.

### Leave perspective unhandled or undefined

Rejected, and forbidden by `ADR-0197` decision 4(b).

### Negate depth so it decreases into the screen

Rejected. A negated axis is a convention with no advantage here and one real
cost: every downstream comparison would have to remember the inversion.
Measuring along `forward` makes "greater depth is farther" true without a sign
rule.

### Reject behind-camera vertices

Rejected. Orthographic projection has no eye point, so a negative depth is
arithmetically ordinary. Rejecting it would import a perspective-only hazard
into a model that does not have it, and would make a legitimate scene — a
camera inside a mesh — fail for no reason.

### Take the aspect ratio as an explicit parameter

Rejected. Two independent scale sources can disagree, and the disagreement
would show up as silently stretched geometry. Deriving the scale from the plane
height and the pixel height alone makes square pixels structural rather than a
caller obligation.

### Pre-multiply the transforms into one matrix

Rejected; see decision 9. It is faster and it changes the bits.

### Round or clamp to pixel indices here

Rejected. Which pixels a projected triangle covers, and what happens at a tie,
is the visibility contract's decision. Rounding here would pre-empt it and
would discard sub-pixel information that contract needs.

### Give this stage its own resource ceiling

Rejected; see decision 11.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about projection support, basis
construction, expression order, depth convention, pixel convention or failure.

The deliberate limitations are that perspective is unavailable in version one,
that no image is produced, and that no pixel coverage is decided. Each is
recorded with its trigger.

`ADR-0197` increment (c), visibility and hidden-surface removal, is next and
consumes exactly what this stage produces.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds one internal deterministic projector to `VoxeliaRendering`,
composing the accepted camera, viewport, layer and mesh values. No dependency
edge changes.

## Compatibility impact

None in this design-only increment. Adding perspective later is a new
algorithm identity and its own compatibility assessment.

## Security impact

All admissions are already discharged by the composed accepted values;
traversal is cancellable; errors are payload-free and disclose no coordinates,
transforms, camera parameters or counts. No unsafe memory and no backend type
enters the design.

## Performance and memory impact

`O(1)` basis construction and `O(vertexCount)` projection, holding one
three-component record per vertex. The forbidden matrix pre-multiplication is
the one optimisation a reader might expect and is excluded on correctness
grounds, not oversight. No benchmark or throughput claim is made.

## Validation impact

The oracle registers:

```text
fixtureSHA256=cbb73b21b0a3789aa46c08f3195893e7329b376b0c9639fa06ec60459cb39a38
projectionBytesSHA256=6171752e014b1a05774b15739faf44e5222764f18ebda7f4de6749674127e017
fixtures=12 successful=10 failures=2
```

Migration must reproduce all twelve fixtures bit-exactly, prove the
cancellation cadence and the projection-check precedence, and prove repeated
determinism. This design increment requires oracle reproduction, documentation,
register, index, link, manifest and release-integrity checks; product builds
and tests are intentionally not evidence for a documentation-only change. It
discharges the **Test** half of `VOX-SUR-001`'s verification methods only; no
demonstration is claimed.

## Migration

1. Add the internal deterministic projector to `VoxeliaRendering` with every
   arithmetic, failure and cancellation fixture from `ALG-0033`.
2. `ADR-0197` increment (c) freezes visibility and hidden-surface removal over
   the projected coordinates and depths.

## Supersession

This record executes `ADR-0197` decision 4(b) and settles the perspective
deferral `ADR-0173` recorded. It supersedes no accepted record; `ADR-0173`
remains correct for the volume ray generator it governs.

## References

- [ADR-0082 - Rendering camera and viewport models](ADR-0082-rendering-camera-and-viewport.md)
- [ADR-0173 - Orthographic ray generator](ADR-0173-orthographic-ray-generator.md)
- [ADR-0193 - Deterministic triangle-mesh vertex normals design](ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](ADR-0198-surface-scene-vocabulary.md)
- [VOXELIA-ALG-0030 - Triangle area-weighted vertex normals](../../algorithms/VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md)
- [VOXELIA-ALG-0033 - Surface vertex orthographic projection](../../algorithms/VOXELIA-ALG-0033-surface-vertex-projection.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
