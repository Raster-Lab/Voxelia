---
document_id: "ADR-0148"
title: "Brick vocabulary"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-BRK-002"
  - "VOX-BRK-003"
  - "VOX-BRK-004"
  - "VOX-BRK-005"
  - "VOX-ERR-001"
---

# ADR-0148 - Brick vocabulary

## Context

Accepted `ADR-0147` froze the bricked-volume vocabulary with
python-verified layout fixtures. This record implements it. It was
authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **The three value models join `VoxeliaStorage`** exactly as
   designed: `BrickResolutionLevel`, `BrickGridDescriptor` as the
   one layout authority whose dimensions are caller-supplied policy
   inputs, and the minimal `BrickIdentity`. Every region derives
   from the grid's frozen integer arithmetic — ceiling-division
   counts, structural boundary bricks, clamped haloed regions and
   ceiling-division level extents — and nothing derived is stored.
2. **Admission is one payload-free `BrickVocabularyError`** with a
   case per frozen rule: non-positive volume and brick extents, a
   halo that is negative or reaches the nominal extent, a
   non-positive downsampling factor, a negative level index, a rank
   mismatch and a coordinate outside the grid.
3. **Derived regions are `ImageRegion` values**, reusing the
   accepted region admission rather than inventing a second bounds
   vocabulary.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

The brick request lifecycle design has its vocabulary; ad-hoc brick
arithmetic remains prohibited.

## Affected modules

`VoxeliaStorage`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

Constant-time integer derivations; no allocation beyond the derived
region values.

## Validation impact

New suite `BrickVocabularyTests` reproduces every design fixture,
rejects every typed admission and proves repeated derivation
identical.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0147`; no record is superseded.

## References

- [ADR-0147 - Brick vocabulary design](ADR-0147-brick-vocabulary-design.md)
