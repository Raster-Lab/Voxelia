---
document_id: "ADR-0354"
title: "Explicit-boundary convolution"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-011"
  - "VOX-R2D-004"
---

# ADR-0354 - Explicit-boundary convolution

## Context

`VOX-IMG-011` requires convolution and Gaussian-filter foundations **with
explicit boundary conditions**. This record designs the convolution;
`VOXELIA-ALG-0059` freezes it; the Gaussian composes it in the next increment
rather than sharing this one — its discretisation rule (sampled versus
integrated, truncation radius, normalisation order) deserves its own frozen
record instead of a paragraph in this one.

## Decision

1. **The boundary is a closed, defaultless choice**: `replicate` or `zero`,
   an explicit parameter at every call site per the house rule — a defaulted
   boundary is an implicit one, which the row forbids by name. Mirror and
   periodic join later by their own records.

2. **`ConvolveOperation`** (`org.voxelia.op.convolve`, CPU twenty-second
   implementation) takes a caller-supplied binary64 kernel with odd per-axis
   extents (each at most `31`), applied in stated correlation orientation,
   accumulated in the frozen lexicographic left-associative order over the
   domain's exact widening.

3. **The output rule composes `VOXELIA-ALG-0058` verbatim** — ties-to-even
   then saturate for integers, verbatim non-finite for `float32` — with this
   operation's **own** warning codes, so provenance attributes the producing
   stage rather than pooling observations across operations.

4. **`VOX-IMG-011` is half-discharged**; `VOX-R2D-004` advances again. The
   Gaussian increment completes the row.

## Alternatives considered

### Separable-only convolution

Rejected for the foundation. Separability is the Gaussian's optimisation, not
convolution's definition; the general kernel is what thresholding this row's
future consumers (sharpening, gradients, morphological approximations) need.

### A default replicate boundary

Rejected; see decision 1.

## Consequences

Convolution exists with the row's explicitness honoured structurally; the
Gaussian composes next.

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it
(twenty-two implementations; the combined registry twenty-five).

## Compatibility impact

Additive only.

## Security impact

None. Kernel and image admission bound every input before the read.

## Performance and memory impact

Direct evaluation, one output allocation; kernel extents are ceilinged. A
device kernel is future work under the established claims discipline.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0354-convolution-oracle.py
swift test --filter "ConvolveOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0059` and the oracle.
2. The operation, registration and fixture tests, in the same increment.
3. **Next**: the Gaussian filter, completing `VOX-IMG-011`.

## Supersession

This record supersedes nothing. It continues the arc `ADR-0352` opened.

## References

- [VOXELIA-ALG-0059 - Explicit-boundary convolution](../../algorithms/VOXELIA-ALG-0059-explicit-boundary-convolution.md)
- [ADR-0352 - Open the processing foundations arc](ADR-0352-open-the-processing-foundations-arc.md)
- [ADR-0353 - Mask application and image arithmetic](ADR-0353-mask-application-and-arithmetic.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
