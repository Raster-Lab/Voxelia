---
document_id: "ADR-0043"
title: "Spatial descriptor admission boundary"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-SPA-001"
  - "VOX-SPA-002"
  - "VOX-SPA-003"
  - "VOX-IMG-001"
  - "VOX-ERR-001"
  - "VOX-SEC-006"
  - "VOX-VAL-007"
---

# ADR-0043 - Spatial descriptor admission boundary

## Context

The `ImageDescriptor` aggregate has been blocked on four undecided spatial
contracts recorded in the progress ledger: the `CoordinateSpaceDescriptor`
unit policy and classification, the affine construction tolerance, the
rectilinear binding rule and the frame-set collection contracts. The CDMS
sketches the coordinate-space record (section 21.5) and its invariants
(21.6) but does not say which unit dimensions are admissible, how
singular affine transforms are detected under floating point, how
rectilinear coordinate arrays bind to image axes, or how per-frame
transforms cover a frame axis. This record was authored and accepted on
2026-08-04 under the project owner's recorded autonomous delegation,
selecting the conservative fail-closed option for each item.

## Decision

### Unit policy and classification

Version one admits exactly the ordinary physical coordinate space: the
`CoordinateSpaceDescriptor.unit` must carry `UnitDimension.length`. A
missing, non-length or `custom`-dimension unit is rejected with a typed
payload-free error. Parametric, index-only and other non-physical space
classifications require a future reviewed decision introducing an
explicit closed classification; absence of a classification field never
silently admits a non-length unit. The remaining 21.6 invariants bind as
written: non-blank identifier, external references unique by exact
namespace/identifier pair, declared handedness never contradicting a
built-in convention's implied handedness, and identifier equality never
implying transform equivalence.

### Affine construction tolerance

The version-one affine admission rule is exact and toolchain-stable:
every matrix entry must be finite; the transform must preserve the
homogeneous bottom row `(0, 0, 0, 1)`; and the upper-left 3x3
determinant's magnitude must be at least `Double.leastNormalMagnitude`
(subnormal, zero, non-finite or sign-ambiguous-at-zero determinants are
singular and rejected). No epsilon tolerance parameter exists in version
one: a host-selectable conditioning policy is a future decision, and a
looser tolerance can only widen, never narrow, the admitted set.

### Rectilinear binding

A rectilinear geometry binds one explicit strictly increasing finite
coordinate array per bound spatial axis, whose element count equals that
axis's shape extent exactly. Non-monotonic, non-finite, empty or
miscounted arrays are rejected. Implementation is deferred to its
recorded M1/M7 milestone window; this admission rule is frozen now so
`ImageDescriptor` validation can name it without reopening review.

### Frame-set contracts

A frame-set geometry maps every `FrameAnchorIndex` of the bound frame
axis to exactly one per-frame rigid or affine transform: complete
coverage, no duplicates, no extras. Collection implementation is
deferred to its recorded M1/M4 milestone window under the same
freeze-without-source rule.

### Descriptor admission

`VoxeliaSpatial` owns `CoordinateSpaceDescriptor` and the geometry
records; `VoxeliaCore` owns `ImageDescriptor`, which validates the 19.2
invariants at construction with typed payload-free errors and never
accesses storage. The version-one `SpatialGeometry` surface admits the
affine case; rectilinear and frame-set cases join when their milestone
implementations land, without changing this admission boundary.

## Alternatives considered

Admitting any unit dimension was rejected as silently unphysical.
An epsilon-parameter affine tolerance was rejected because no measured
evidence supports a specific epsilon and a frozen exact rule cannot
over-admit. Implementing rectilinear and frame-set collections now was
rejected as milestone-inappropriate speculation. Deferring all four
decisions again was rejected because it blocks `ImageDescriptor`
indefinitely.

## Consequences

- `ImageDescriptor` and the affine spatial path are unblocked for M1.
- Non-length spaces, conditioning tolerances, rectilinear and frame-set
  implementations remain explicitly recorded future work.

## Affected modules

`VoxeliaSpatial` (coordinate space, affine geometry) and `VoxeliaCore`
(`ImageDescriptor`). No dependency edge changes.

## Compatibility impact

No affected aggregate exists in source; the admission rules become
pre-1.0 contracts on first implementation. `CCR-0017` records the
controlled CDMS corrections for sections 19.2 and 21.5/21.6.

## Security impact

Fail-closed admission and payload-free errors follow every accepted
boundary; identifiers and references stay out of diagnostics.

## Performance and memory impact

Admission is O(rank + references + matrix) with checked arithmetic; no
tolerance search or iterative conditioning exists.

## Validation impact

Focused owning-module tests must cover unit-dimension rejection,
handedness contradiction, external-reference duplicates, bottom-row and
determinant boundaries including `leastNormalMagnitude`, and the
`ImageDescriptor` 19.2 invariants, with redaction proofs.

## Migration

1. `CCR-0017` records the corrections (this increment).
2. Implement `CoordinateSpaceDescriptor`, the affine geometry, the
   version-one `SpatialGeometry` surface and `ImageDescriptor` with the
   focused tests (next increments).
3. Rectilinear and frame-set implementations land in their milestone
   windows under the frozen rules.

## Supersession

This ADR supersedes no accepted decision. It composes downstream of
`ADR-0021`, `ADR-0022`, `ADR-0025`, `ADR-0027` and the accepted metadata
and storage chains.

## References

- [Voxelia Core Data Model Specification v0.1.1, sections 19, 21 and 22](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [ADR-0022 - Coordinate convention public shape](ADR-0022-coordinate-convention-shape.md)
- [ADR-0027 - Frame geometry anchor-index boundary](ADR-0027-frame-geometry-anchor-index-boundary.md)
