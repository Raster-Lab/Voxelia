---
document_id: "ADR-0365"
title: "The registration transform categories"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-001"
  - "VOX-REG-003"
---

# ADR-0365 - The registration transform categories

## Context

The registration arc opens. `VOX-REG-001` (P0, `I,T`, M7) requires rigid,
affine and deformable transforms represented as **distinct categories**;
`VOX-REG-003` (P0, `I,T`, M7) requires every registration transform to
identify its source and destination coordinate spaces. The two rows are one
model: the categories are the payload vocabulary and the spaces are the
aggregate's frame, so splitting them would build the same type twice.

## Decision

1. **Categories are distinct by type, not by declaration**: a closed,
   defaultless three-case vocabulary — `rigid(RigidMotion)`,
   `affine(AffineRegistrationTransform)`,
   `deformable(DeformableRegistrationTransform)`. Nothing infers a
   category from a matrix's numerical shape.

2. **Rigid is rigid by construction** (`VOXELIA-ALG-0068`,
   `rigid-motion/binary64-v1`): a canonical unit quaternion plus a
   translation. The parameterisation cannot express shear or scale, so the
   category carries **no orthonormality tolerance** — the knob every
   matrix-validated design would have needed. Existing spatial substance is
   composed, not duplicated: the derived homogeneous matrix admits through
   `Matrix4x4Double` and interoperates with `VOXELIA-ALG-0052` algebra.

3. **Affine admission is exact and existing**: the matrix must satisfy
   `AffineTransformAlgebra.isAffine` (exact bottom row, `ADR-0283`) and be
   invertible, proven by `AffineSpatialInverse` (`VOXELIA-ALG-0016`, the
   determinant authority) rather than a new determinant.

4. **Deformable is a displacement-field reference, structurally admitted**:
   an `ImageData` whose components are `float32` `.vector` with count
   three, whose semantic is the existing `deformationField`, and whose
   descriptor declares a spatial geometry — a field that does not know
   where it lives cannot displace anything. Field *evaluation*
   (interpolation of displacements) is deliberately not built here; it
   belongs to the row that consumes it.

5. **The aggregate discharges `VOX-REG-003`**: `RegistrationTransform`
   carries `sourceSpace` and `destinationSpace` as full
   `CoordinateSpaceDescriptor` values beside the category. Identity
   registrations within one space are legitimate, so equal spaces are not
   refused.

6. **Layering**: `RigidMotion` lives in `VoxeliaSpatial` beside the algebra
   it composes; the aggregate lives in `VoxeliaCore` because the deformable
   category references `ImageData`.

## Alternatives considered

### One matrix type with a declared category label

Rejected. A label on a matrix lets a sheared matrix call itself rigid; the
row asks for distinct representation, and types are the honest distinction.

### Matrix-validated rigidity with an orthonormality tolerance

Rejected. Every tolerance is an arbitrary knob the project style refuses;
the quaternion parameterisation makes the invariant free.

### Deferring source/destination spaces to `VOX-REG-003`'s own increment

Rejected. The aggregate would be rebuilt to add two properties; the rows
are one model.

## Consequences

The registration arc has its foundation vocabulary; the result record
(fixed/moving/metric/optimiser/schedule/convergence) and the remaining
rows compose it per the `ADR-0351` order.

## Affected modules

`VoxeliaSpatial` gains `RigidMotion`; `VoxeliaCore` gains the
`RegistrationTransform` aggregate and its category vocabulary.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

Negligible: a fixed number of binary64 operations at admission.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0365-rigid-motion-oracle.py
swift test --filter RigidMotionTests
swift test --filter RegistrationTransformTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0068`, both types, the fixture suites and the
   register updates, in the same increment.
2. **Next**: the registration result record, then the remaining arc rows
   per the `ADR-0351` order.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0068 - Rigid motion](../../algorithms/VOXELIA-ALG-0068-rigid-motion.md)
- [ADR-0283 - Affine composition and direction design](ADR-0283-affine-composition-and-direction-design.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
