---
document_id: "ADR-0388"
title: "Lighting and transillumination"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-006"
  - "VOX-PRR-008"
---

# ADR-0388 - Lighting and transillumination

## Context

`VOX-PRR-006` (P1, `T,D`, M8): area and environment lighting.
`VOX-PRR-008` (P0, `T,D`, M8): transparency and transillumination
presentations. Both are compositions over the arc's pinned foundation,
and they share one specification because they share one discipline:
declared inputs, frozen folds, no sampling inside the model.

## Decision

1. **Lights are declared sample sets** (`VOXELIA-ALG-0078`): an area
   light is the samples the caller drew over its surface, an
   environment light its directional samples — each with radiance,
   weight and an admitted shadow transmittance. The accumulator folds
   `w·T`-weighted radiance in declared order and does not sample,
   exactly as the integrator does not. This makes area and environment
   lighting one mechanism differing only in what the caller declares —
   which is the honest physics: a light is where radiance comes from,
   not a special case per shape.

2. **Transillumination is radiance over background**: the
   `ADR-0386` result's remaining transparency `1 − A` admits the
   background exactly once, per channel, frozen. Transparency
   presentation and transillumination are the same composition read in
   two clinical directions; an exactly opaque foreground admits exactly
   nothing.

3. **Shadow attenuation arrives as data**: the lighting accumulator
   takes transmittances, produced by `VOXELIA-ALG-0077` walks or by
   the caller's own occlusion model — the seam stays declared.

## Alternatives considered

### Distinct area-light and environment-light types

Rejected — decision 1. Two types with one fold would imply two
physics.

### Building transillumination into the integrator

Rejected. The integrator answers "what does the volume emit and
absorb"; what lies behind it is presentation, and fusing them would
make the empty-ray and saturation rules ambiguous.

## Consequences

The physics arc's compositional surface is complete enough for the
scattering row's documented approximation.

## Affected modules

`VoxeliaPhotorealistic` gains the accumulator and the composition.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(lights)` per accumulation; `O(1)` per composition.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0388-lighting-transillumination-oracle.py
swift test --filter LightingTransilluminationTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0078`, both types, the fixture suite and
   the register updates, in the same increment.
2. **Next**: the multiple-scattering row's documented approximation.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0078 - Lighting and transillumination](../../algorithms/VOXELIA-ALG-0078-lighting-transillumination.md)
- [ADR-0387 - Volumetric shadows](ADR-0387-volumetric-shadows.md)
