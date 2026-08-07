---
document_id: "ADR-0368"
title: "Landmark affine registration"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-005"
---

# ADR-0368 - Landmark affine registration

## Context

`VOX-REG-005` (P0, `T`, M7): the initial registration portfolio shall
include landmark, rigid and affine registration. The row spans more than
one increment by design. This increment builds the **landmark affine**
entry — the portfolio member with an exact closed-form answer under
frozen arithmetic; the landmark rigid entry and the iterative
intensity-driven rigid/affine members follow in their own increments,
and the row stays open until the portfolio is complete.

## Decision

1. **`landmark-affine/binary64-v1`** (`VOXELIA-ALG-0070`): least-squares
   estimation over `N ≥ 4` correspondences via frozen normal equations
   and frozen partial-pivot elimination, the degeneracy refusal on the
   `VOXELIA-ALG-0016` no-epsilon rule. The estimator lives in
   `VoxeliaSpatial` (`LandmarkAffineEstimation`) and returns a
   `Matrix4x4Double`.

2. **The registration face lives in `VoxeliaCore`**:
   `LandmarkAffineRegistration.register` takes `Point3D` landmarks and
   the two `CoordinateSpaceDescriptor`s, validates that every moving
   point's space identifier is the source's and every fixed point's the
   destination's (a landmark expressed elsewhere is a typed refusal, not
   a silent reinterpretation), estimates, and returns a
   `RegistrationTransform` whose affine category re-admits through
   `AffineRegistrationTransform` — the estimate proves its own
   invertibility at the door.

3. **Determinism is the promise, interpolation is not**: the fixtures pin
   the frozen elimination's bits, including its rounding on a consistent
   fixture, rather than pretending closed-form exactness the arithmetic
   does not have.

## Alternatives considered

### Building the whole portfolio in one increment

Rejected. Landmark rigid needs its own design decision (frame alignment
versus a quaternion eigen-solver, each with determinism consequences),
and the intensity members need the metric/optimiser rows; one increment
per member keeps each decision inspectable.

### Exactly-determined four-point interpolation only

Rejected. Real landmark sets are overdetermined; normal equations cover
both cases with one frozen path.

## Consequences

The portfolio row is **advanced, not discharged**: the landmark affine
member exists with pinned conformance fixtures; the row's remaining
members follow.

## Affected modules

`VoxeliaSpatial` gains `LandmarkAffineEstimation`; `VoxeliaCore` gains
`LandmarkAffineRegistration`.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(N)` assembly and a constant-size solve.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0368-landmark-affine-oracle.py
swift test --filter LandmarkAffineTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0070`, both types, the fixture suite and the
   register updates, in the same increment.
2. **Next**: the landmark rigid member, then the intensity-driven members
   with the metric/optimisation rows.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0070 - Landmark affine estimation](../../algorithms/VOXELIA-ALG-0070-landmark-affine.md)
- [ADR-0365 - The registration transform categories](ADR-0365-the-registration-transform-categories.md)
- [ADR-0367 - Registration transform composition](ADR-0367-registration-transform-composition.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
