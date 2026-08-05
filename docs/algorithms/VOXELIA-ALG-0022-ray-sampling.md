---
document_id: "VOXELIA-ALG-0022"
title: "Volume ray sampling binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Volume ray sampling binary64-v1

## Purpose

This specification defines the versioned reference model
`volume-ray-sampling/binary64-v1` selected by accepted
[`ADR-0168`](../architecture/decisions/ADR-0168-ray-sampling-design.md)
— rays intersecting the actual volume bounds with sampling intervals
derived from physical spacing and the quality policy, per
`VOX-DVR-002/003`. Everything this model feeds is presentation,
never a source of authoritative quantitative measurement, per the
arc's binding rule.

## Model

**Direction and parameter.** The world ray direction is normalised
by its `VOXELIA-ALG-0010`-form norm with one correctly rounded
division per component, so the ray parameter `t` is world distance.

**Index-space mapping.** The ray maps through the accepted
`VOXELIA-ALG-0016` composition: the origin as a world point, the
direction through the inverse without the translation. Because the
map is linear, the index-space ray preserves the parameter — `t`
remains world distance.

**Bounds.** The volume's actual bounds are the pixel-centre support
of the accepted sampling model: the closed index-space box
`[-0.5, n_k - 0.5]` per axis. The intersection applies the accepted
`VOXELIA-ALG-0001` slab rule in index space over these intervals —
the rule is the authority; restating its domain does not fork it.
The entry parameter clamps at zero — a camera inside the volume
starts at the camera — and a ray whose exit does not exceed its
clamped entry, or which misses any slab, yields the declared empty
sample sequence: a value, never an error.

**Interval.** The sampling interval derives from physical spacing
and the quality policy — never a fixed normalised constant:

```text
spacing  = min over axes of ||column_k||     (ALG-0010 norm form)
interval = qualityFactor * spacing
```

with the version-one quality mapping declared as
`org.voxelia.quality.full -> 1/2` — half the minimum voxel spacing —
the one registered quality token today; further tokens arrive with
the interactive arc and must extend this table in their own records.

**Positions.** The frozen midpoint sequence:

```text
count = floor((exit - entry) / interval)
t_k   = entry + (k + 0.5) * interval      for k in 0 ..< count
```

each operation correctly rounded, no fused multiply-add; the sample
positions in index space are the mapped ray evaluated at `t_k`,
consumed directly by the accepted trilinear model.

## Determinism and failure classification

The plan is a pure function of the geometry, ray and quality token:
repeated evaluation is bit-identical. Calibration, coordinate-space
and direction admission is the receiver's typed surface — a
zero-length direction rejects typed before normalisation.

## Conformance fixtures

Independently computed, all values exact dyadics:

- Identity geometry, extents `(3, 3, 3)`, ray origin `(-2, 1, 1)`
  direction `(1, 0, 0)`: entry `1.5`, exit `4.5`, interval `0.5`,
  six samples at `t = 1.75, 2.25, 2.75, 3.25, 3.75, 4.25`.
- The same ray displaced to `y = 5` misses: the empty sequence.
- Diagonal spacing-two geometry, world ray origin `(-3, 1, 1)`
  direction `(1, 0, 0)`: spacing `2`, interval `1`, entry `2`, exit
  `8`, six samples at `t = 2.5` through `7.5`.
- Camera inside the identity volume at `(1, 1, 1)` direction
  `(1, 0, 0)`: entry clamps to `0`, three samples at
  `t = 0.25, 0.75, 1.25`.

## Validation obligations

The implementing increment must reproduce all fixtures exactly,
prove bit-identical repetition, and reject the typed admissions — an
uncalibrated volume, a foreign-space ray and a zero-length
direction — without coercion.

## References

- [ADR-0168 - Ray sampling design](../architecture/decisions/ADR-0168-ray-sampling-design.md)
- [VOXELIA-ALG-0001 - Ray axis-aligned bounds intersection](VOXELIA-ALG-0001-ray-axis-aligned-bounds-intersection.md)
- [VOXELIA-ALG-0016 - Affine spatial inverse binary64-v1](VOXELIA-ALG-0016-affine-inverse.md)
