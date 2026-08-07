---
document_id: "ADR-0371"
title: "The registration pyramid"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-006"
---

# ADR-0371 - The registration pyramid

## Context

`VOX-REG-006` (P0, `I,T`, M7): the registration architecture shall
support multi-resolution image pyramids. The parts already exist frozen:
the `ADR-0366` schedule vocabulary says *what* a pyramid is (shrink
factor plus smoothing sigma per level, coarsest first), the
`VOXELIA-ALG-0060` separable Gaussian says *how* smoothing computes, and
the `VOXELIA-ALG-0056` level selection says *how* downsampling computes
and how geometry scales. What the row needs is the composition — built
once, inspected, and witnessed by integration.

## Decision

1. **`RegistrationPyramid` composes, it does not compute**: per schedule
   level, an optional `GaussianFilterOperation` pass (isotropic sigma)
   followed by an optional `LevelSelectOperation` pass (isotropic shrink
   factor as a `BrickResolutionLevel`). **No new algorithm exists** —
   every number the pyramid produces is already specified by
   `VOXELIA-ALG-0060` or `VOXELIA-ALG-0056`, so this record carries no
   ALG and the tests are composition witnesses.

2. **A zero sigma skips smoothing; a unit factor skips selection**: the
   Gaussian's own admission refuses `σ = 0`, and a factor-one selection
   would be an identity copy with a new object identity — fabricated
   derivation. A level with both zero sigma and unit factor passes the
   input through unchanged, identity intact.

3. **Boundary is `replicate`**: zero padding would darken every border
   at every level, and the pyramid's consumers compare intensities
   across levels. Recorded here once so no caller re-decides it.

4. **Identity is supplied, never fabricated**: the caller passes one
   `RegistrationPyramidLevelIdentity` (smoothed and downsampled object
   and provenance identifiers) per schedule level; a count mismatch is a
   typed refusal. Unused identifiers on skipped passes stay unused.

5. **Version-one bounds are the operations' own**: the pyramid inherits
   `LevelSelectOperation`'s rank-three calibrated `uint8` admission and
   the Gaussian's sigma ceiling; it adds no admission of its own beyond
   the identity count. Widening the operations widens the pyramid.

## Alternatives considered

### A dedicated pyramid algorithm with its own resampler

Rejected. It would duplicate two frozen specifications and give the
project a second answer to a question it has already answered.

### Factor-one levels as explicit identity copies

Rejected as fabricated derivation — a new object identity with no new
content.

## Consequences

The intensity-driven portfolio members iterate coarse-to-fine over real
pyramid levels; the schedule recorded in an `ADR-0366` result names
exactly what was built.

## Affected modules

`VoxeliaExecution` gains `RegistrationPyramid` and its level-identity
vocabulary.

## Compatibility impact

Additive only.

## Security impact

None beyond the composed operations' own admissions.

## Performance and memory impact

The composed operations' own; the pyramid adds one array of results.

## Validation impact

```text
swift test --filter RegistrationPyramidTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the composition, the witness suite and the register
   updates, in the same increment.
2. **Next**: the remaining registration rows per the `ADR-0351` order.

## Supersession

This record supersedes nothing.

## References

- [ADR-0366 - The registration result record](ADR-0366-the-registration-result-record.md)
- [VOXELIA-ALG-0056 - Level selection downsampling](../../algorithms/VOXELIA-ALG-0056-level-selection-downsampling.md)
- [VOXELIA-ALG-0060 - Separable Gaussian](../../algorithms/VOXELIA-ALG-0060-separable-gaussian.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
