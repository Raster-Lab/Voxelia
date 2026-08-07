---
document_id: "ADR-0369"
title: "Landmark rigid registration"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-005"
---

# ADR-0369 - Landmark rigid registration

## Context

`VOX-REG-005` continues: `ADR-0368` built the landmark affine member and
deferred the rigid member's design decision — deterministic frame
alignment versus a quaternion eigen-solver. This record makes that
decision and builds the member.

## Decision

1. **Horn's quaternion method, deterministically realised**
   (`VOXELIA-ALG-0071`, `landmark-rigid/binary64-v1`): the rotation is
   the leading eigenvector of Horn's symmetric 4×4 matrix, computed by
   **cyclic Jacobi with exactly 30 sweeps** in a frozen pair order — no
   convergence threshold, so the sweep count is part of the model and
   repeated estimation is bit-identical. The eigenvector re-admits
   through `VOXELIA-ALG-0068` admission, so the estimate is a canonical
   `RigidMotion` — rigid by construction, least-squares in exact
   arithmetic, and every landmark contributes.

2. **Frame alignment was rejected**: it uses only three landmarks and
   discards the rest, which is not landmark registration so much as a
   triad fit; it would have needed replacing the moment anyone supplied
   a fourth point.

3. **Exact collinearity refuses, on both sets, with no epsilon**: a
   degenerate set leaves the rotation about the landmark line
   unconstrained, and a silently arbitrary rotation is exactly the kind
   of fabrication this project refuses. The check is exact cross-product
   zero — near-degenerate sets remain the caller's responsibility, the
   same contract as pivot admission elsewhere.

4. **The face mirrors the affine member**: `LandmarkRigidRegistration`
   in `VoxeliaCore` validates landmark spaces and returns a
   `RegistrationTransform` in the rigid category.

## Alternatives considered

### Deterministic frame alignment

Rejected — decision 2.

### A closed-form quartic characteristic-polynomial eigensolver

Rejected. Ferrari's formula is numerically fragile near repeated roots —
precisely the near-degenerate sets that matter — while fixed-sweep
Jacobi degrades gracefully and stays frozen.

### Detecting near-collinearity with a tolerance

Rejected. Every tolerance is an arbitrary knob; exact refusal plus a
recorded caller responsibility is the project's standing contract.

## Consequences

The portfolio row has two of its members. It remains **open** for the
intensity-driven rigid/affine members, which need the metric rows.

## Affected modules

`VoxeliaSpatial` gains `LandmarkRigidEstimation`; `VoxeliaCore` gains
`LandmarkRigidRegistration`.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(N)` assembly plus a constant 30-sweep 4×4 Jacobi.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0369-landmark-rigid-oracle.py
swift test --filter LandmarkRigidTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0071`, both types, the fixture suites and
   the register updates, in the same increment.
2. **Next**: the metric rows, which the intensity-driven portfolio
   members and the pyramid row compose.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0071 - Landmark rigid estimation](../../algorithms/VOXELIA-ALG-0071-landmark-rigid.md)
- [ADR-0368 - Landmark affine registration](ADR-0368-landmark-affine-registration.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
