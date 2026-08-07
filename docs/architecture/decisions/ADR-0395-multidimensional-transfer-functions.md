---
document_id: "ADR-0395"
title: "Multi-dimensional transfer functions"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-006"
---

# ADR-0395 - Multi-dimensional transfer functions

## Context

`VOX-DVR-006` (P1, `T,D`, M8): the renderer should support
multi-dimensional transfer functions using intensity, gradient or
material information. The row belongs to conventional volume rendering,
so the model lives in `VoxeliaRendering` beside the existing transfer
vocabulary — not in the photorealistic module, which consumes admitted
per-sample colour like any other caller.

## Decision

1. **A declared two-dimensional table over intensity and gradient
   magnitude** (`VOXELIA-ALG-0082`): caller-declared bin counts and
   ranges — defaultless, the `ADR-0370` discipline, because an assumed
   range is a silent rescale — with the metric bin rule and verbatim
   entry lookup. An out-of-range sample **refuses typed rather than
   clamping**: a silently clamped colour is a fabricated
   classification.
2. **Material conditioning is one table per declared material class**,
   selected by exact index, sharing the `VOXELIA-ALG-0081` declared-
   material vocabulary: intensity, gradient *and* material — the row's
   three information sources, all declared.
3. **No interpolation in v1.** Interpolated lookup is a different model
   with its own rounding story; the vocabulary does not preclude it,
   and a future row can add it as a new frozen model.

## Alternatives considered

### Extending the one-dimensional transfer type in place

Rejected. The existing vocabulary has consumers with pinned semantics;
a parallel model keeps both exact.

### Clamping out-of-range samples to edge bins

Rejected — decision 1.

## Consequences

Conventional rendering can classify on intensity-gradient signatures
(vessel walls, bone interfaces) with material conditioning; the
photorealistic arcs consume the result as data.

## Affected modules

`VoxeliaRendering` gains the model.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(1)` per lookup; `O(bins²)` storage per table.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0395-multidimensional-transfer-oracle.py
swift test --filter MultiDimensionalTransferTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0082`, the model, the fixture suite and
   the register updates, in the same increment.
2. **Next**: the validation arc's engineering halves.

## Supersession

This record supersedes nothing; the existing transfer vocabulary is
unchanged.

## References

- [VOXELIA-ALG-0082 - Multi-dimensional transfer function](../../algorithms/VOXELIA-ALG-0082-multidimensional-transfer.md)
- [ADR-0392 - Material-separated presentation](ADR-0392-material-separated-presentation.md)
