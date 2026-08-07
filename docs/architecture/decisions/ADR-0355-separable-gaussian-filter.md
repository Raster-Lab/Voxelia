---
document_id: "ADR-0355"
title: "Separable Gaussian filter"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-011"
  - "VOX-R2D-004"
---

# ADR-0355 - Separable Gaussian filter

## Context

`ADR-0354` built the convolution half of `VOX-IMG-011` and deferred the
Gaussian to its own record; `VOXELIA-ALG-0060` freezes its four decisions:
sampled discretisation, `ceil(3 sigma)` truncation, left-to-right
normalisation, and axis-ascending binary64 passes narrowed exactly once.

## Decision

1. **`GaussianFilterOperation`** (`org.voxelia.op.gaussian-filter`, CPU
   twenty-third implementation) takes one finite positive deviation per axis
   and the explicit `ConvolutionBoundary`, derives the frozen kernels, and
   runs the separable passes in binary64 — the intermediate narrowing a
   per-pass store would add is the exact rounding this design exists to
   avoid.

2. **The convolution core is extracted, not restated**: the frozen
   accumulation loop moves into an internal `convolvedValues` both
   operations call, and the `VOXELIA-ALG-0059` fixtures re-run unchanged as
   the proof — the `SurfaceCoverage` extraction discipline.

3. **Sampled, not integrated**: the sampled Gaussian is the foundations
   choice; the integrated (error-function) variant is recorded as a possible
   future record for small-deviation accuracy, not silently folded in.

4. **`VOX-IMG-011` is discharged** — convolution and Gaussian both exist
   with explicit boundaries — and `VOX-R2D-004` advances again.

## Alternatives considered

### Publish each separable pass as its own object

Rejected. Three published intermediates per filter would triple provenance
for values no consumer sees, and per-pass storage would round per axis; one
object with the deviations in its parameter document is the honest recipe.

### An integrated-Gaussian default

Rejected; see decision 3.

## Consequences

`VOX-IMG-011` is discharged; the arc continues with morphology
(`VOX-IMG-012`).

## Affected modules

`VoxeliaExecution` gains the operation and the shared internal core;
`VoxeliaCPU` registers it (twenty-three implementations; the combined
registry twenty-six).

## Compatibility impact

Additive; `ConvolveOperation`'s behaviour is unchanged and its fixtures
prove it.

## Security impact

None.

## Performance and memory impact

Separable passes cost rank kernel-width multiplies per sample instead of the
full product; one binary64 working buffer per pass.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0355-gaussian-oracle.py
swift test --filter "GaussianFilterOperationTests|ConvolveOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0060` and the oracle.
2. The extraction, the operation, registration and fixture tests, in the
   same increment.
3. **Next**: morphology foundations (`VOX-IMG-012`).

## Supersession

This record supersedes nothing. It completes `VOX-IMG-011` under
`ADR-0352`'s domain.

## References

- [VOXELIA-ALG-0060 - Separable Gaussian filter](../../algorithms/VOXELIA-ALG-0060-separable-gaussian.md)
- [ADR-0354 - Explicit-boundary convolution](ADR-0354-explicit-boundary-convolution.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
