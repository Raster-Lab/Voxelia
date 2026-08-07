---
document_id: "ADR-0360"
title: "Nearest label resampling and the operation set"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SEG-005"
  - "VOX-SEG-006"
---

# ADR-0360 - Nearest label resampling and the operation set

## Context

`VOX-SEG-005` demands the nearest-neighbour default for binary and
multi-label resampling; `VOX-SEG-006` demands thresholding, masking,
connected-component and morphology foundations. The foundations exist from
the closed `ADR-0352` arc; what remains is the mask-honest resampler and the
proof that the pieces compose.

## Decision

1. **`LabelResampleOperation`** (`org.voxelia.op.label-resample`, CPU
   twenty-seventh implementation) resamples `mask` and `label` images to an
   explicit target grid under `VOXELIA-ALG-0064`: the `VOXELIA-ALG-0055`
   forward chain with `VOXELIA-ALG-0026`'s round-half-away nearest
   selection, and **background zero — never a clamp — outside the source**,
   because a clamped grid resample would replicate edge labels into space
   the source never covered. Padding is counted into this operation's own
   aggregated warning.

2. **The default is structural, not parametric** (`VOX-SEG-005`
   discharged): mask and label semantics are refused by the intensity
   resampler and admitted only here, so nothing can interpolate a label by
   accident; an interpolating override would be a future validated
   operation with its own record.

3. **`VOX-SEG-006` is discharged by the foundations plus the composition
   witness**: an `[Integration]` test drives threshold → erode → connected
   components → the `Segmentation` aggregate end to end, because unit
   evidence of the halves does not prove they meet — the standing
   composition discipline.

## Alternatives considered

### Widen the intensity resampler with a nearest mode

Rejected. One operation with two value-semantics regimes and two padding
vocabularies would carry a mode flag whose wrong setting silently
interpolates labels — the exact accident the row exists to prevent. Two
doors, each honest, is the structural answer.

### Clamp at the boundary, following ALG-0026 verbatim

Rejected; see `VOXELIA-ALG-0064`. The clamp is correct for in-support
sampling and fabricates anatomy in a grid resample.

## Consequences

`VOX-SEG-005` and `VOX-SEG-006` are discharged; the arc continues with
region growing (`VOX-SEG-007`).

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it
(twenty-seven implementations; the combined registry thirty).

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One selection pass; the intensity resampler's ceilings are shared.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0360-label-resample-oracle.py
swift test --filter "LabelResampleOperationTests|SegmentationCompositionTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0064` and the oracle.
2. The operation, registration, fixture tests and the composition witness,
   in the same increment.
3. **Next**: region growing with recorded seeds (`VOX-SEG-007`).

## Supersession

This record supersedes nothing. It composes the closed foundations arc into
the segmentation arc.

## References

- [VOXELIA-ALG-0064 - Nearest label resampling](../../algorithms/VOXELIA-ALG-0064-nearest-label-resampling.md)
- [ADR-0359 - Open the segmentation arc](ADR-0359-open-the-segmentation-arc.md)
- [ADR-0352 - Open the processing foundations arc](ADR-0352-open-the-processing-foundations-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
