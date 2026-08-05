---
document_id: "VOXELIA-ALG-0027"
title: "Empty-space skipping binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Empty-space skipping binary64-v1

## Purpose

This specification defines the versioned reference model
`empty-space-skipping/binary64-v1` selected by accepted
[`ADR-0182`](../architecture/decisions/ADR-0182-volume-acceleration-design.md)
— brick-level occupancy classification and skip-aware compositing for
direct volume rendering, per `VOX-DVR-012`. Everything this model
composites is presentation, never a source of authoritative
quantitative measurement, per the arc's binding rule; acceleration
must never change the rendered image, only the work spent producing
it.

## Model

**Brick classification.** For a caller-supplied `BrickGridDescriptor`
matching the volume's own extents, every brick's core payload is
reduced to the accepted `VOX-BRK-011` `BrickStatistics` (no sentinel),
computed once from the bytes already resident for the render. A brick
is skippable exactly when every transfer-table entry in its inclusive
`includedMinimum...includedMaximum` range has zero opacity:

```text
skippable(brick) = includedMinimum == nil   (vacuous: no samples)
                  or ∀ i in includedMinimum...includedMaximum:
                       table.entry(i).opacity == 0
```

No emptiness verdict exists ahead of this computation — accepted
`ADR-0162` leaves that decision to the consumer, and this
classification is where it belongs, since it depends on the transfer
function supplied with this render, not on the data alone.

**Brick lookup.** A sample's containing brick reuses the accepted
`VOXELIA-ALG-0026` nearest-neighbour voxel rule unchanged, then
floor-divides by the grid's nominal brick extents per axis:

```text
brick[k] = nearestVoxelIndex(c[k], extent[k]) / nominalBrickExtents[k]
```

The halo is not consulted: core regions alone define both the
statistics and the classification, since this model only classifies
occupancy, never fetches haloed context.

**Skip-aware compositing.** A sample whose brick is skippable is never
interpolated — the realised saving — and is marked excluded; a sample
whose brick is not skippable is interpolated and marked included. The
per-sample inclusion sequence is handed to the accepted masked
compositor entries of `VOXELIA-ALG-0026` unchanged; no new
accumulation rule exists for acceleration. When a mask selection is
also declared, inclusion is the conjunction of the mask's visibility
and the brick's non-skippability.

## Determinism and failure classification

The classification and the compositing are pure functions of the
volume bytes, the grid and the table: repeated evaluation is
bit-identical. The only failure this model declares is a grid whose
`volumeExtents` does not match the volume's own extents, surfaced
through the renderer's own typed admission — a caller-input mismatch,
not a fact about the model's arithmetic.

## Conformance fixtures

Independently computed:

- A `[4, 3, 3]` volume divided into two `[2, 3, 3]` bricks along `x`,
  the first brick uniformly `0` and the second uniformly `200`,
  composited through a table with `entry(i).opacity == i`: the first
  brick's included range is `[0, 0]` with opacity `0`, skippable; the
  second's is `[200, 200]` with opacity `200`, not skippable.
- The standard `VOXELIA-ALG-0022` axis ray's eight samples resolve to
  the brick sequence `0, 0, 0, 0, 1, 1, 1, 1` — the first four
  skippable, the last four not.
- Compositing all eight samples through the accepted unmasked entry
  and compositing only the four un-skipped samples through the masked
  entry (the first four excluded) give byte-identical colour
  `(200, 200, 200)`, alpha `254`, and consumed count `8` for both.
- A brick whose included range straddles a zero-opacity and a
  nonzero-opacity entry is never classified skippable, regardless of
  how few of its samples carry the nonzero value.

## Validation obligations

The implementing increment must reproduce every fixture exactly,
prove bit-identical repetition, prove the unaccelerated path is
unchanged — structural, through the untouched accepted compositor
entries, not merely asserted — prove the straddling-brick case is
never skipped, and reject a grid whose extents do not match the
volume's, typed.

## References

- [ADR-0182 - Volume acceleration design](../architecture/decisions/ADR-0182-volume-acceleration-design.md)
- [ADR-0162 - Brick statistics](../architecture/decisions/ADR-0162-brick-statistics.md)
- [VOXELIA-ALG-0022 - Volume ray sampling binary64-v1](VOXELIA-ALG-0022-ray-sampling.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing binary64-v1](VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0026 - Segmentation mask sampling binary64-v1](VOXELIA-ALG-0026-segmentation-mask-sampling.md)
