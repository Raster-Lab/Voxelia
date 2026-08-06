---
document_id: "ADR-0198"
title: "Surface scene vocabulary"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-GEO-002"
  - "VOX-SUR-001"
  - "VOX-SUR-003"
  - "VOX-SUR-004"
---

# ADR-0198 - Surface scene vocabulary

## Context

`ADR-0197` decision 4(a) makes the surface scene vocabulary the arc's first
executable increment: a surface layer carrying one mesh, its object-to-world
transform, opacity and material selection; a surface scene snapshot; and a
surface render request.

`VoxeliaRendering` already declares `VoxeliaGeometry` as a dependency, so a
layer can hold a canonical `TriangleMesh` value directly rather than an
identifier it would later have to resolve. `RenderCamera` already validates
that its position, target and up share one coordinate space, so a camera
already declares the space it looks into.

This increment freezes declaration values only. It contains no projection,
transform arithmetic, visibility rule, shading model or pixel contract; those
belong to `ADR-0197` increments (b) through (e).

## Decision

1. **`SurfaceLayer` is the closed per-object declaration**, joining
   `VoxeliaRendering`: one canonical `TriangleMesh`, one `Matrix4x4Double`
   object-to-world transform, one `CoordinateSpaceDescriptor` naming the space
   that transform maps *into*, one opacity and one material selection.
2. **The transform is explicit at both ends.** The source space is the mesh's
   own declared `coordinateSpace`; the target space is the layer's declared
   `worldSpace`. Naming both is what `VOX-SUR-001` asks for, and it carries
   `ADR-0183` decision 4's rule — record the source and target spaces rather
   than relabelling coordinates — into rendering. A layer that mapped into an
   unnamed space would make "explicit coordinate-space transforms" a
   documentation claim rather than a typed one.
3. **The object-to-world transform must be affine.** Its homogeneous bottom row
   must be exactly `(0, 0, 0, 1)`, composing the accepted `ADR-0043` admission
   rule verbatim rather than restating a threshold. A projective bottom row
   would change what the declared world space means and is rejected typed.
4. **A singular affine transform is admitted, deliberately.** `ADR-0043`
   additionally rejects a determinant magnitude below
   `Double.leastNormalMagnitude` because a grid geometry must be invertible to
   map samples back. A surface placement has no such obligation: a transform
   that collapses a mesh to a plane or a point is a legitimate, if useless,
   caller choice, and what a zero-area projected facet contributes is the
   visibility increment's decision, not this value's. Rejecting it here would
   claim an authority this vocabulary does not have.
5. **Opacity is an inclusive unit interval.** A finite `Double` in `[0, 1]`,
   rejecting NaN, infinities and out-of-range values typed. Negative zero is
   admitted and is exactly zero. No default exists; every layer states its
   opacity. How opacity composes between overlapping objects is `ADR-0197`
   increment (d)'s to freeze, and nothing here presumes it.
6. **`SurfaceMaterialSelection` is a closed token, one case in version one.**
   It names which material a layer selects; it does not model shading. The
   single `diagnostic` case exists so the shading increment widens a token
   rather than changing `SurfaceLayer`'s shape, and no exhaustive switch over
   it exists anywhere, so widening is purely additive — the `ADR-0174`
   decision 2 precedent. The material's actual model is `ADR-0197` increment
   (e)'s to freeze.
7. **`SurfaceSceneSnapshot` holds ordered layers and one world space.** Every
   layer must declare the same `worldSpace`, rejected typed otherwise: a scene
   has exactly one world. Layer order is preserved exactly and is not a draw
   order — any ordering the compositing increment needs is that increment's to
   freeze. Repeated meshes and repeated object-to-world transforms are
   admitted; the same mesh placed twice is a legitimate scene.
8. **An empty scene is admitted.** It declares no world space and renders no
   surface. This follows the accepted pattern that an empty mesh is a valid
   mesh and an empty measurement is positive zero; rejecting emptiness would
   need a justification this vocabulary does not have.
9. **`SurfaceRenderRequest` binds a scene to a camera and viewport**, and is
   the only place the world space and the camera meet: a non-empty scene's
   world space must equal the camera's own declared coordinate space, rejected
   typed otherwise. An empty scene imposes no camera constraint because it
   declares no space.

   The comparison is by coordinate-space *identifier*, and the asymmetry is
   deliberate: `Point3D` carries a `CoordinateSpaceID`, while a layer carries
   the full `CoordinateSpaceDescriptor` its mesh geometry needs for
   convention, handedness and unit. The identifier is the shared name. This
   request does not invent a rule obliging a camera to restate properties it
   does not model, and it does not silently widen `Point3D`.
10. **The render result is deferred to the renderer increment.** A result must
    describe pixels, and the pixel and depth contract belongs to `ADR-0197`
    increments (b) and (c). This follows the volume arc exactly: `ADR-0174`
    froze `VolumeRenderRequest` as the vocabulary and `ADR-0175`'s renderer
    defined the result. `ADR-0197` decision 4(a) lists "request and result"
    together; defining a result now would mean inventing a pixel contract two
    increments early, so it is deliberately not done here and this deviation
    is recorded rather than silently taken.
11. **`SurfaceSceneError` is payload-free, `Sendable` and `Equatable`** with
    exactly `invalidOpacity`, `nonAffineObjectToWorld`, `worldSpaceMismatch`
    and `coordinateSpaceMismatch`. Diagnostics disclose no coordinates,
    transforms, mesh contents, counts or space identifiers. Every case is
    reachable and separately tested; there is no case whose condition another
    admission already discharges.
12. **These are declaration values, not published aggregates.** Every stored
    field is immutable and `Sendable`; none is `Codable`; none carries identity,
    provenance or a content digest. Publishing a rendered surface is the
    renderer increment's boundary, exactly as it was for the volume arc.

## Alternatives considered

### Hold a mesh object identifier instead of a mesh

Rejected. `RenderLayer` holds an `imageObjectID` because a published image is
resolved through the publication coordinator at render time. A canonical
`TriangleMesh` is an immutable `Sendable` value that `VoxeliaRendering` can
already name directly, and holding the value removes a resolution step, a
failure mode and a lifetime question for no loss.

### Extend `RenderLayer` to carry meshes

Rejected, and already rejected by `ADR-0197`. `RenderLayer` is bound to an
image object identifier and a window-level transfer function; widening it to
mean "image or mesh" would make an accepted, evidenced type ambiguous and
ripple through the accepted 2D slice path.

### Put the world space on the scene rather than on each layer

Rejected. Storing it once looks tidier but makes the layer's transform target
implicit, which is precisely what `VOX-SUR-001` asks not to be implicit. Each
layer declaring its own target space keeps the transform explicit at both ends
and turns a scene-level inconsistency into a typed rejection rather than an
unstated assumption.

### Reject a singular object-to-world transform

Rejected; see decision 4. It would import a threshold from a contract with a
different obligation.

### Omit `SurfaceMaterialSelection` until the shading increment

Rejected. Adding a stored member to a public struct later is a cross-module
layout change; adding a case to a token nothing exhaustively switches on is
additive. The one-case token is the cheaper and already-accepted shape.

### Define the render result now

Rejected; see decision 10.

## Consequences

The arc's first values exist, and increments (b) through (e) can attach a
transform model, a visibility rule, a compositing order and a shading model to
a scene that already states its meshes, placements, spaces, opacities and
material selections.

The deliberate limitations are that no result type exists yet, that the
material token has one case, and that nothing here renders anything.

## Affected modules

`VoxeliaRendering` only. No dependency edge changes; `VoxeliaGeometry` was
already a declared dependency. Core, Spatial, Storage, Execution, Geometry,
CPU and Metal ownership is unchanged.

## Compatibility impact

Additive before 1.0. Widening `SurfaceMaterialSelection` stays additive because
nothing switches over it exhaustively.

## Security impact

All admission is structural and bounded: one range check, one bottom-row check
and two space comparisons. Errors are payload-free and disclose no scene
contents. No unsafe memory and no backend type enters the vocabulary.

## Performance and memory impact

Construction is `O(layerCount)` for the world-space agreement check and `O(1)`
per layer; meshes are immutable values and are not copied or scanned. No
benchmark or throughput claim is made.

## Validation impact

Focused `VoxeliaRenderingTests` evidence for every admitted and rejected case,
exact preservation of layer order and mesh bits, detached `Sendable` transfer,
and the payload-free error family. This increment changes product source, so a
clean rebuild and the full unfiltered suite are evidence. It discharges the
**Test** half of its requirements' verification methods only; no demonstration
is claimed.

## Migration

1. Add the layer, material token, scene snapshot, request and closed error
   family to `VoxeliaRendering` with the evidence above.
2. `ADR-0197` increment (b) attaches the coordinate-space transform and
   projection model and settles the deferred perspective case.
3. The renderer increment defines the result.

## Supersession

This record executes `ADR-0197` decision 4(a) and supersedes no accepted
record.

## References

- [ADR-0043 - Spatial descriptor admission boundary](ADR-0043-spatial-descriptor-admission-boundary.md)
- [ADR-0082 - Rendering camera and viewport models](ADR-0082-rendering-camera-and-viewport.md)
- [ADR-0174 - Volume render vocabulary](ADR-0174-volume-render-vocabulary.md)
- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
