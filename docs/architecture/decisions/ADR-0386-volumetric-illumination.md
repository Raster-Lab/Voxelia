---
document_id: "ADR-0386"
title: "Volumetric illumination"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-004"
---

# ADR-0386 - Volumetric illumination

## Context

The `ADR-0384` physics arc opens. `VOX-PRR-004` (P0, `T,D`, M8): the
module shall support physically based volumetric illumination. The
arc's discipline is the project's: each optical model is a frozen ALG
with an independent oracle, built smallest-first so the later rows
(shadows, lighting, scattering) extend a pinned foundation instead of
a renderer's entrails.

## Decision

1. **The founding model is emission-absorption radiative transfer**
   (`VOXELIA-ALG-0076`, `emission-absorption/binary64-v1`): per-sample
   emission attenuated by accumulated Beer-Lambert absorption,
   composited front to back with frozen folds and exact saturation.
   Emission-absorption is the recognised physically based baseline of
   volume rendering — not a stylistic approximation — and the shadows
   and scattering rows extend it rather than replace it.

2. **`VolumetricIlluminationIntegrator` is the numerical core, not a
   renderer**: it integrates an ordered ray of admitted samples.
   Sampling — volume interpolation, transfer functions, step sizes —
   is the caller's seam, exactly as the registration metrics kept
   sampling out of the metric. That is what makes the fixtures exact
   and the later renderer's correctness decomposable.

3. **The documentation half is the specification itself**: the ALG is
   the published physically based model, named in the module note —
   `T` by fixtures, `D` by record, no marketing prose in between.

## Alternatives considered

### Starting with single-scattering illumination

Rejected as the founding model. Scattering has its own row with an
explicit documented-approximation clause; the foundation must be the
model everything else composes.

### An integrator with early-out thresholds

Rejected. A visibility epsilon is an arbitrary knob; saturation at
exactly one is the only early exit.

## Consequences

Shadows (opacity-only rays toward a light) and the lighting rows can
compose this integrator; the determinism arc gets a pinned kernel to
seed and accumulate around.

## Affected modules

`VoxeliaPhotorealistic` gains the integrator.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(samples)` per ray.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0386-emission-absorption-oracle.py
swift test --filter VolumetricIlluminationTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0076`, the integrator, the fixture suite
   and the register updates, in the same increment.
2. **Next**: the volumetric shadows row, composing this integrator's
   opacity walk.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0076 - Emission-absorption integration](../../algorithms/VOXELIA-ALG-0076-emission-absorption.md)
- [ADR-0385 - The optional photorealistic module](ADR-0385-the-optional-photorealistic-module.md)
- [ADR-0384 - The M8 queue](ADR-0384-the-m8-queue.md)
