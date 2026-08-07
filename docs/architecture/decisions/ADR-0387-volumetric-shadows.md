---
document_id: "ADR-0387"
title: "Volumetric shadows"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-005"
---

# ADR-0387 - Volumetric shadows

## Context

`VOX-PRR-005` (P0, `T,D`, M8): the module shall support volumetric
shadows. The physics arc's foundation (`ADR-0386`) established the
discipline: the numerical core is frozen and oracle-pinned, sampling
is the caller's seam.

## Decision

1. **A shadow is a transmittance walk** (`VOXELIA-ALG-0077`,
   `shadow-transmittance/binary64-v1`): the multiplicative Beer-Lambert
   fold `T = T·(1 − α)` along a ray toward the light, exact extinction
   the only early exit, the empty ray transmitting exactly one. This is
   the same physics as the `ADR-0386` integrator's opacity
   accumulation, restated for the light path — the two compose without
   a seam because they share the absorption model.

2. **`VolumetricShadowWalk.transmittance` is the one entry point**, and
   the resulting transmittance feeds the lighting accumulator as an
   admitted `[0, 1]` value — shadows attenuate lights; they do not
   paint darkness.

3. **The `D` half is the specification**, named in the module note, as
   with every optical model in this arc.

## Alternatives considered

### Shadow maps or precomputed occlusion structures

Rejected for the model layer. Acceleration is a renderer decision the
determinism arc must be able to reason about; the model must stay the
pinned physics.

## Consequences

The lighting row composes attenuated lights immediately; the scattering
row's documented approximation has both of its ingredients.

## Affected modules

`VoxeliaPhotorealistic` gains the walk.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(samples)` per shadow ray.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0387-shadow-transmittance-oracle.py
swift test --filter VolumetricShadowTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0077`, the walk, the fixture suite and
   the register updates, in the same increment.
2. **Next**: area and environment lighting with transillumination.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0077 - Shadow transmittance](../../algorithms/VOXELIA-ALG-0077-shadow-transmittance.md)
- [ADR-0386 - Volumetric illumination](ADR-0386-volumetric-illumination.md)
