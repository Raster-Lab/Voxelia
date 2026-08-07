---
document_id: "ADR-0392"
title: "Material-separated presentation"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-009"
---

# ADR-0392 - Material-separated presentation

## Context

The `ADR-0384` presentation arc opens. `VOX-PRR-009` (P1, `T,D`, M8):
material-separated presentation for clinically significant material
classes.

## Decision

1. **Separation partitions radiance, never transport**
   (`VOXELIA-ALG-0081`): one shared opacity walk identical to the
   `ADR-0386` integrator, with each sample's weighted emission recorded
   into its declared material's channels. A bone window in front of a
   vessel still shadows the vessel — separating what is *displayed*
   must not rewrite what light *did*.

2. **Material classes are declared indices**, assigned by the caller's
   classification (transfer function, segmentation, or the host's own
   model) — the module does not classify tissue, exactly as it does
   not sample.

3. **No combined image is computed by the separator**: summing
   per-material triples rounds in a different order than the plain
   integration, and the model refuses to pretend the two are bit-equal.
   The combined presentation is the `VOXELIA-ALG-0076` integration of
   the same ray.

## Alternatives considered

### Per-material independent opacity walks

Rejected — a material would stop shadowing the others, which is
physically wrong and clinically misleading.

## Consequences

Hosts can present vessels, bone and soft tissue as separable layers
with shared, honest occlusion.

## Affected modules

`VoxeliaPhotorealistic` gains the separated integrator.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(samples + materials)` per ray.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0392-material-separation-oracle.py
swift test --filter MaterialSeparationTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0081`, the integrator, the fixture suite
   and the register updates, in the same increment.
2. **Next**: the post-processing declaration vocabulary.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0081 - Material separation](../../algorithms/VOXELIA-ALG-0081-material-separation.md)
- [ADR-0386 - Volumetric illumination](ADR-0386-volumetric-illumination.md)
