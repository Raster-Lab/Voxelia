---
document_id: "ADR-0367"
title: "Registration transform composition"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-004"
---

# ADR-0367 - Registration transform composition

## Context

`VOX-REG-004` (P0, `T`, M7): transform composition shall validate
coordinate-space compatibility. The `ADR-0365` categories exist; what is
missing is the one place where two registration transforms become one —
and the space check that makes chaining them honest.

## Decision

1. **Compatibility is full-descriptor equality at the seam**: composing
   `outer` after `inner` requires `inner.destinationSpace ==
   outer.sourceSpace` as complete `CoordinateSpaceDescriptor` values —
   identifier, convention, handedness, unit and references. Two spaces
   sharing an identifier but disagreeing about convention are a lie, not
   a match. The refusal is typed and payload-free.

2. **The result spans the chain**: source is the inner's source,
   destination is the outer's destination.

3. **Rigid stays rigid** (`VOXELIA-ALG-0069`,
   `rigid-composition/binary64-v1`): the Hamilton product with frozen
   folds, re-admitted through `VOXELIA-ALG-0068` admission so the stored
   form stays canonical; the translation is the outer rotation applied to
   the inner translation plus the outer translation. Lowering rigid pairs
   to matrices would surrender the by-construction rigidity the category
   exists for.

4. **Mixed rigid/affine pairs compose as affine** through the existing
   `VOXELIA-ALG-0052` `compose(_:after:)` — a rigid operand lowers to its
   derived homogeneous matrix, and the result re-admits through
   `AffineRegistrationTransform` (exact bottom row, invertibility). The
   category honestly widens: rigid-times-affine is not rigid.

5. **Deformable composition is refused typed.** Displacement-field
   evaluation does not exist yet, and a "composed" deformable transform
   built without evaluating fields would be fabrication. The refusal is
   `unsupportedComposition`; the capability belongs to the row that
   builds field evaluation.

## Alternatives considered

### Identifier-only space compatibility

Rejected. The descriptor's other fields exist because they change what
coordinates mean; matching on the identifier alone would compose across a
convention mismatch silently.

### Lowering every pair to matrix composition

Rejected. Rigid∘rigid would come back merely approximately orthonormal
and the category would be lost — decision 3 keeps it.

### Synthesising deformable composition by field resampling

Rejected as fabrication before field evaluation exists.

## Consequences

Chained registrations (subject → atlas → template) validate their seams;
the remaining arc rows compose transforms without re-deciding any of
this.

## Affected modules

`VoxeliaSpatial` gains the rigid composition; `VoxeliaCore` gains
`RegistrationTransformComposition`.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

Negligible: a fixed number of binary64 operations.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0367-rigid-composition-oracle.py
swift test --filter RigidMotionCompositionTests
swift test --filter RegistrationCompositionTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0069`, both compositions, the fixture
   suites and the register updates, in the same increment.
2. **Next**: the remaining registration rows per the `ADR-0351` order.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0069 - Rigid composition](../../algorithms/VOXELIA-ALG-0069-rigid-composition.md)
- [ADR-0365 - The registration transform categories](ADR-0365-the-registration-transform-categories.md)
- [ADR-0366 - The registration result record](ADR-0366-the-registration-result-record.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
