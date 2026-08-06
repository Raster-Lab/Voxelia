---
document_id: "ADR-0197"
title: "Surface rendering arc"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SUR-001"
  - "VOX-SUR-002"
  - "VOX-SUR-003"
  - "VOX-SUR-004"
  - "VOX-SUR-005"
  - "VOX-SUR-006"
  - "VOX-SUR-007"
  - "VOX-SUR-008"
  - "VOX-SUR-009"
---

# ADR-0197 - Surface rendering arc

## Context

`ADR-0183` decision 6 held surface rendering out of the geometry arc: "`VOX-SUR-*`
work becomes assessable only after a valid mesh can be published; it is not
folded into this arc." That precondition is now met. `ADR-0196` closed the
geometry arc, and a canonical `TriangleMesh` with validated topology, an
explicit coordinate space, deterministic vertex normals and authoritative
measurement can be published today.

The requirement range was checked against the v0.1.1 baseline table directly
rather than against any summary, because an opening record's own decomposition
has silently skipped a requirement before (`VOX-DVR-011`). The `VOX-SUR` block
is exactly nine contiguous rows, `VOX-SUR-001` through `VOX-SUR-009`, with no
gap and nothing above 009. The whole ledger was also swept for each of the nine
identifiers: none has ever been assessed. The only occurrences are in the
next-action line written when `ADR-0196` closed the geometry arc.

This arc is larger than its predecessors and touches areas where nothing exists
yet. An honest inventory of what it can stand on, and what it cannot:

**Directly composable, already accepted.** `RenderCamera` and `ViewportSize`
(`ADR-0082`); `TransferFunction1D` (`ADR-0083`, `ADR-0166`/`ADR-0167`), which
is the natural authority for `VOX-SUR-005`'s scalar colour maps;
`VolumeClipBounds` and `VoxeliaInteraction.ClipBox` (`ADR-0178`/`ADR-0179`),
which already freeze world-space slab clipping for `VOX-SUR-006`; the
publication, identity and provenance boundaries every accepted operation uses;
and the `ExactVolumeRenderer` precedent of a synchronous, deterministic,
off-screen renderer whose output is exact bytes.

**Precedent for shape, not reusable implementation.**
`VoxeliaInteraction.PickResolver` (`ADR-0125`/`ADR-0129`) resolves a presented
*pixel* back to a source *image* index and physical position, and returns no
position rather than fabricating one when the presentation is uncalibrated.
`VOX-SUR-007` needs something different in kind — a ray against authoritative
mesh geometry returning a geometry identifier — but the honesty rule it
established binds the new work.

**Genuinely absent.** There is no depth buffer, depth test or
hidden-surface-removal machinery anywhere in `VoxeliaRendering` or
`VoxeliaMetal`; the only occurrences of "depth" in either module are `MTLSize`
dimension arguments. There is no surface layer, material or mesh-bearing scene
model: `RenderLayer` is image-object-specific and cannot carry a mesh. There is
no perspective ray generator — `CameraProjection` declares both
`.orthographic(planeHeight:)` and `.perspective(verticalFieldOfViewRadians:)`,
but `OrthographicRayGenerator` rejects perspective with
`unsupportedProjection`, and `ADR-0173` calls perspective "the deferred
perspective case". A surface arc that renders meshes has to settle that
deferral rather than inherit it silently.

This record opens the arc with its decomposition and binding rules only. It
selects no projection model, rasterisation strategy, depth representation,
tie-breaking rule, material model, colour-map application, section-cap
semantics, intersection predicate or public API. Each of those requires a
separately frozen contract with independent fixtures. It was authored and
accepted on 2026-08-06 under the project owner's standing autonomous mandate.

## Decision

1. **Rendered surface pixels are presentation, never authoritative
   measurement.** This restates the binding rule the volume arc carried
   (`VOX-DVR-015`) and `ADR-0183` decision 1 made arc-wide for geometry: no
   rasterised output is ever an input to geometry measurement. A surface
   renderer consumes the canonical mesh; nothing flows back. Any quantity a
   consumer needs comes from the accepted measurement operations, not from
   pixels.
2. **Determinism is structural.** Every model in this arc is a pure frozen
   function of its declared inputs. Identical mesh bits, camera, viewport,
   materials and options produce identical output bytes on every run. No
   arc increment may introduce a wall-clock, a GPU-order dependency, a hash
   iteration order or an epsilon into a published result. Where a rendering
   technique is conventionally order-dependent — transparent-object
   compositing above all — the ordering rule becomes part of the frozen
   contract rather than an implementation accident.
3. **The CPU reference is the oracle; the GPU path must match or declare.**
   Mirroring the accepted `ADR-0194`/`ADR-0195` discipline, any Metal surface
   path must reproduce the CPU reference bit-for-bit or register a separately
   accepted approximation. `ADR-0196` just discharged `VOX-GEO-011` on the
   basis that no backend structure is canonical; this arc must not quietly
   reverse that by making a GPU pipeline the only definition of correct
   output.
4. **The arc advances in dependency order, design-first at every numeric or
   lifetime boundary:**
   - **(a) Surface scene vocabulary.** A surface layer carrying one mesh
     reference, its object-to-world transform, opacity and material selection;
     a surface scene snapshot; and a surface render request and result. This is
     new vocabulary, not an extension of `RenderLayer`, which is
     image-object-specific.
   - **(b) Coordinate-space transform and projection** (`VOX-SUR-001`). The
     explicit, validated chain from mesh coordinate space through world and
     camera to viewport, rejecting a foreign or mismatched space typed rather
     than relabelling coordinates. This increment must settle the deferred
     perspective case from `ADR-0173` — either by freezing a perspective model
     or by recording explicitly that surface rendering stays orthographic in
     version one — and must not leave `CameraProjection` declaring a case no
     accepted renderer honours.
   - **(c) Visibility: depth and hidden-surface removal** (`VOX-SUR-002`). The
     nearest-surface rule, the depth quantity and its precision, the exact
     tie-breaking rule when two surfaces are equidistant at a pixel — a
     determinism obligation, not a detail — and the backface policy. Nothing
     exists to build on here.
   - **(d) Per-object opacity and surface compositing** (`VOX-SUR-003`). The
     per-object opacity domain and the compositing order for overlapping
     transparent objects. The volume arc's front-to-back rule
     (`VOXELIA-ALG-0023`) is per-sample along one ray and does not settle
     ordering between distinct objects; that ordering must be frozen
     explicitly.
   - **(e) Vertex normals and diagnostic materials** (`VOX-SUR-004`). Shading
     from the accepted deterministic vertex normals. A validated diagnostic
     material is in scope; a physically based material model is a separate
     decision this arc does not pre-commit, and the requirement's "physically
     based **or** validated diagnostic" wording permits the diagnostic path
     alone.
   - **(f) Scalar colour maps** (`VOX-SUR-005`). Applying the accepted
     `TransferFunction1D` authority to a mesh scalar attribute, freezing the
     attribute selection rule, the domain mapping and the out-of-domain
     policy. Composition, not a new colour model.
   - **(g) Clipping and section views** (`VOX-SUR-006`). Composing the accepted
     `VolumeClipBounds` world-space slab rule. Section views additionally
     require deciding whether a clipped solid shows an open boundary or a
     capped cross-section; capping is a constructive-geometry obligation and
     must be settled explicitly, not assumed.
   - **(h) Authoritative surface picking** (`VOX-SUR-007`). A ray against
     authoritative mesh geometry returning the geometry identifier and physical
     coordinates. It must state which intersection predicate it uses, how it
     breaks ties between coincident hits, and — following `PickResolver`'s
     established honesty rule — must return no position rather than a
     fabricated one when the required claim is absent.
   - **(i) Depth-aware annotation registration** (`VOX-SUR-008`) and
     **(j) Metal-generated geometry representability** (`VOX-SUR-009`), each
     assessed on its own terms; see decisions 6 and 7.
5. **Coordinate spaces are explicit and never relabelled.** Every transform in
   this arc declares its source and target space. A mesh whose coordinate space
   does not match the scene's is rejected with a typed error, never
   reinterpreted. This is the accepted geometry rule (`ADR-0183` decision 4)
   carried into rendering, and it is what `VOX-SUR-001` actually asks for.
6. **`VOX-SUR-008` splits, and only half is gated.** "Depth-aware annotations
   shall remain correctly registered during camera movement" has a
   *correctness* half — an annotation anchored to a geometry position projects
   to the right pixel and is correctly occluded, at any given camera pose —
   which is deterministically testable off-screen by rendering at two poses and
   asserting both. It also has a *continuous-motion* half, which needs a real
   interactive draw loop and the timing signal a synchronous off-screen
   renderer does not have. The draw loop is already a standing owner-gated
   item. The correctness half is in scope for this arc; the motion half is
   honestly gated to the draw-loop arc, exactly as `VOX-DVR-013` was.
7. **`VOX-SUR-009` is expected to be an assessment, and it must not be
   pre-judged here.** "Geometry generated by Metal compute shall be
   representable without making GPU buffers the canonical geometry model" is
   the GPU-producer mirror of the GPU-consumer question `ADR-0196` just
   discharged for `VOX-GEO-011`. Its verification methods are Inspection and
   Test, so unlike `VOX-GEO-011` it carries a test obligation and may need a
   real transfer path — plausibly composing `ADR-0186`'s governed Metal
   shared-buffer boundary. Whether that is a documentation assessment or a
   built path is that increment's finding, not this record's assumption.
8. **The demonstration half of the verification methods is recorded as a
   dependency, not silently claimed.** Seven of the nine rows declare `T,D` —
   Test and Demonstration. This arc can fully discharge the Test half through
   deterministic off-screen reference renders with exact byte output, following
   the `ExactVolumeRenderer` precedent. The Demonstration half generally
   implies interactive or visual evidence tied to the draw loop and to
   destinations the project does not currently have. Every increment must state
   which half its evidence covers. No increment may present an off-screen byte
   comparison as though it discharged a demonstration obligation.
9. **Resource ceilings, cancellation and payload-free diagnostics bind every
   increment.** Explicit caller ceilings on vertex, triangle, object and pixel
   counts; all products and byte requirements overflow-checked before
   allocation; cancellation checked on a declared cadence; payload-free typed
   error families that disclose no coordinates, identifiers, counts or scene
   contents. These are the accepted house rules and no rendering increment is
   exempt from them.
10. **Nothing in this arc becomes a measurement, a segmentation or a stored
    clinical artefact.** Surface rendering output is presentation. Any
    persistence, export or interchange of rendered output is outside this arc
    and needs its own record.

## Alternatives considered

### Fold surface rendering into the geometry arc

Rejected, and already rejected by `ADR-0183` decision 6. Nine rows spanning
transforms, visibility, opacity, materials, colour maps, clipping, picking,
annotation registration and GPU-produced geometry constitute an arc, not a
stage. Folding them in would have made the geometry arc unreviewable and would
have blocked its closure behind unrelated rendering decisions.

### Start with a Metal surface pipeline

Rejected. It would make a GPU pipeline the definition of correct output and
reverse `ADR-0196`'s just-recorded discharge of `VOX-GEO-011`. The accepted
pattern across this project is a deterministic CPU reference first, with any
accelerated path required to match it bit-for-bit. It also would not be
testable on the destinations available today.

### Extend `RenderLayer` to carry meshes

Rejected. `RenderLayer` is bound to an image object identifier and a
window-level transfer function; widening it to mean "image or mesh" would make
an accepted, evidenced type ambiguous and would ripple through the accepted 2D
slice path for no benefit. Surface scene vocabulary is new and separate, and
composes the shared `RenderCamera` and `ViewportSize` rather than duplicating
them.

### Settle projection later, inheriting `ADR-0173`'s deferred perspective

Rejected as a silent inheritance. `CameraProjection` already declares a
`.perspective` case that no accepted generator honours; a surface arc that
renders meshes and leaves that unresolved would leave a public enum case
permanently unhonoured across two arcs. Increment (b) must either freeze a
perspective model or record explicitly that version one is orthographic —
either is acceptable, silence is not.

### Adopt a physically based material model now

Rejected for this arc's opening. `VOX-SUR-004` says "physically based **or**
validated diagnostic materials"; the diagnostic path satisfies it and is
specifiable with exact fixtures. A physically based model brings a BRDF, an
illumination model, tone mapping and colour-space obligations, none of which
any accepted record supplies, and none of which a diagnostic viewer needs to
be correct.

### Claim the demonstration half of `T,D` through off-screen renders

Rejected. Byte-exact off-screen comparison is strong Test evidence and is not
Demonstration evidence. Conflating them would overstate what was verified,
which is the failure mode this project's whole evidence discipline exists to
prevent.

## Consequences

The surface queue now has an ordered, reviewable path whose first executable
increment is the surface scene vocabulary. The arc-wide authority,
determinism, coordinate-space, resource and evidence rules bind every following
record without guessing any unresolved model.

The deliberate limitations recorded up front are that version one targets a
deterministic off-screen reference renderer, that the demonstration half of
seven rows depends on the gated draw loop and destinations the project does not
have, that `VOX-SUR-008`'s continuous-motion half is gated with it, and that a
physically based material model is not pre-committed.

The colour/overlay arc (`VOX-R2D-010/011/015` plus VOI verification) remains
the other M6 queue item.

## Affected modules

Documentation only in this increment. Later increments will primarily affect
`VoxeliaRendering` and `VoxeliaCPU`, composing the accepted Core, Spatial,
Geometry and Execution boundaries, with an optional derived Metal path in
`VoxeliaMetal`. No module ownership or dependency edge changes here, and
`VoxeliaGeometry`'s prohibited-import boundary — tightened by `ADR-0196` —
stays as it is.

## Compatibility impact

None in this increment. Later public values are additive before 1.0 and each
requires its own compatibility assessment. Settling the deferred perspective
case in increment (b) may change what `CameraProjection.perspective` means to
a caller and must be assessed there.

## Security impact

The arc requires payload-free typed diagnostics and checked admission for
hostile counts, indices, pixel dimensions and object counts. No source is added
here.

## Performance and memory impact

None in this increment. Each implementing increment must establish checked
resource ceilings, bounded intermediate storage and a cancellation cadence
before implementation. No benchmark or throughput claim is made anywhere in
this arc without measured evidence on a named destination.

## Validation impact

This documentation increment requires front-matter, decision-register,
requirement-reference, manifest and release-integrity validation. Each
implementing increment carries its own focused numerical, visibility,
concurrency, cancellation and publication evidence, plus independently
generated fixtures for every frozen numeric model, and must state explicitly
which verification method its evidence covers.

## Migration

None for product source in this increment. The arc's first executable step is
increment (a), the surface scene vocabulary. Increments (b) through (h) follow
in the recorded dependency order, each design-first at its numeric boundaries;
(i) and (j) are assessed on their own terms under decisions 6 and 7.

## Supersession

This record opens the arc `ADR-0183` decision 6 deferred. It supersedes no
accepted record and reopens none.

## References

- [ADR-0082 - Rendering camera and viewport models](ADR-0082-rendering-camera-and-viewport.md)
- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
- [ADR-0173 - Orthographic ray generator](ADR-0173-orthographic-ray-generator.md)
- [ADR-0179 - Volume clipping](ADR-0179-volume-clipping.md)
- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0186 - Governed Metal shared-buffer transfer boundary](ADR-0186-governed-metal-buffer-transfer.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0193 - Deterministic triangle-mesh vertex normals design](ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
