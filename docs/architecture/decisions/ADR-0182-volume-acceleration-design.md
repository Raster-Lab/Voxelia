---
document_id: "ADR-0182"
title: "Volume acceleration design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-012"
---

# ADR-0182 - Volume acceleration design

## Context

`VOX-DVR-012` — empty-space skipping or an equivalent acceleration
path where occupancy metadata is available — is accepted `ADR-0165`'s
sixth and final queued volume-rendering increment. Its prerequisite,
per-brick occupancy statistics, is already built: accepted `ADR-0162`
implemented `BrickStatistics` for `VOX-BRK-011` specifically so
"empty-space skipping in the volume renderer" could consume it later
without a gated consumer arriving early. With `VOX-DVR-010`'s
multi-volume-compositing half still deferred pending a consumer (no
blend rule motivated since `ADR-0180`) and `VOX-DVR-011`'s bricked
half now proven (`ADR-0181`), this record opens the arc's remaining
increment using its already-prepared prerequisite. Per the plan-first
discipline this record freezes the rules before implementation; per
the arc's binding rule, acceleration must never change the rendered
image, only the work spent producing it. It was authored and accepted
on 2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **Acceleration is a caller-supplied logical brick grid, decoupled
   from physical storage.** `VolumeRenderRequest` gains the explicit
   optional `acceleration: BrickGridDescriptor?`, absence stated at
   every call site. The grid's `volumeExtents` must match the
   volume's own extents, rejected typed otherwise — a mismatched grid
   would classify the wrong voxels. The grid need not match how the
   volume happens to be stored: `VOX-DVR-011` already proved storage
   representation is invisible to the renderer, and occupancy
   classification is an independent, purely logical overlay.
2. **Skippability is computed once per render, from bytes already in
   memory, never fabricated ahead of the transfer function.** For
   every brick in the grid, the accepted `VOX-BRK-011`
   `BrickStatistics` (no sentinel) reduces its core payload to an
   included value range; a brick is skippable exactly when every
   transfer-table entry in that range has zero opacity. `ADR-0162`
   deliberately left this verdict to the consumer, since it depends
   on the transfer function supplied with this specific render, not
   on the data alone — this is where that verdict is made.
3. **Skipping is realised entirely through the accepted masked
   compositor entries — no new compositor code.** A sample whose
   nearest voxel's containing brick is skippable is never
   interpolated, the actual performance saving, and is marked
   excluded exactly as a masked-out sample already is; the "excluded
   is indistinguishable from absent" proof `ADR-0180` already
   established for masking is inherited, not re-derived. When a mask
   selection is also declared, inclusion is the conjunction of the
   mask's visibility and the brick's non-skippability — one shared
   inclusion sequence, whichever features supplied it.
4. **A sample's containing brick composes the accepted nearest-
   neighbour voxel rule, never restates it.** `VOXELIA-ALG-0026`'s
   rounding-and-clamping rule locates the nearest voxel; floor-
   dividing by the grid's nominal brick extents locates its brick.
   The halo is not consulted — core regions alone define both the
   statistics and the classification, since nothing here fetches
   haloed context.
5. **`VolumeRaySampler` is untouched.** Acceleration decides what is
   computed, never where the ray travels — the same separation
   clipping and masks already established between geometric
   restriction and compositing decisions.
6. **Implementation follows separately**, extending
   `VolumeRenderRequest` and `ExactVolumeRenderer` with the
   acceleration path — absence explicit at every call site.

## Alternatives considered

Publishing brick statistics ahead of time, alongside the volume, was
rejected: `BrickStatistics`'s own contract computes on demand from
bytes so statistics and bytes can never disagree, and the renderer
already holds the full byte array in memory before the per-pixel
loop, so on-demand computation costs one linear pass with no extra
publication or storage plumbing. A dedicated acceleration compositor
entry was rejected in favour of reusing the masked entries: an
excluded sample is excluded for the compositor's purposes regardless
of why it was excluded, and a fourth axis of overloads would only
duplicate already-accepted arithmetic. Classifying occupancy from a
brick's midpoint sample alone, rather than its full statistics range,
was rejected: a single sample cannot prove an entire brick is
uniformly zero-opacity, and a wrong skip would silently drop real
image content — the full included range is the only sound basis for
the verdict.

## Consequences

The classification and skip-compositing rules are frozen with an
exact fixture: a `[4, 3, 3]` volume in two `[2, 3, 3]` bricks along
`x`, the first uniformly valued at a table index with zero opacity
and the second at a nonzero one; the standard axis ray's eight
samples split four skippable and four not; compositing all eight
through the accepted entry and compositing only the four un-skipped
through the masked entry give byte-identical colour, alpha and
consumed count.

## Affected modules

Documentation only in this increment; `VoxeliaRendering` and
`VoxeliaMetal` in the implementing increment.

## Compatibility impact

The request and renderer signatures gain the explicit optional
acceleration member and its typed rejection; call sites state
absence.

## Security impact

None.

## Performance and memory impact

Intended to reduce interpolation work when supplied, by skipping
samples in bricks proven zero-opacity for the current transfer
function; one linear pass over the volume bytes to build the
skippability map when declared, none when absent.

## Validation impact

The implementing increment must reproduce the fixture exactly, prove
the unaccelerated request unchanged byte-for-byte through the
untouched accepted compositor entries, prove bit-identical
repetition, prove a brick whose range straddles a zero and a nonzero
opacity entry is never skipped, and reject a grid whose extents do
not match the volume's, typed.

## Migration

None; implementation follows as its own increment.

## Supersession

Executes `VOX-DVR-012`, the volume-rendering arc's remaining queued
increment from accepted `ADR-0165`; no record is superseded.

## References

- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
- [ADR-0161 - Brick statistics design](ADR-0161-brick-statistics-design.md)
- [ADR-0162 - Brick statistics](ADR-0162-brick-statistics.md)
- [ADR-0180 - Segmentation masks design](ADR-0180-segmentation-masks-design.md)
- [ADR-0181 - Bricked and multi-resolution volume assessment](ADR-0181-bricked-multires-assessment.md)
- [VOXELIA-ALG-0026 - Segmentation mask sampling binary64-v1](../../algorithms/VOXELIA-ALG-0026-segmentation-mask-sampling.md)
- [VOXELIA-ALG-0027 - Empty-space skipping binary64-v1](../../algorithms/VOXELIA-ALG-0027-empty-space-skipping.md)
