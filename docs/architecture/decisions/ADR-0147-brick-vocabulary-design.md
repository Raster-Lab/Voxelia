---
document_id: "ADR-0147"
title: "Brick vocabulary design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-BRK-002"
  - "VOX-BRK-003"
  - "VOX-BRK-004"
  - "VOX-BRK-005"
---

# ADR-0147 - Brick vocabulary design

## Context

The M5 opening assessment queues the bricked-volume vocabulary first:
before any brick can be requested, cached or evicted, the value
models naming bricks must exist with validated admission. Per the
plan-first discipline this record freezes the vocabulary and its
integer derivations on paper. It was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **Three value models in `VoxeliaStorage`.**
   `BrickResolutionLevel` carries a nonnegative level index and
   per-axis integer downsampling factors of at least one.
   `BrickGridDescriptor` is the one layout authority for one volume
   at one level: validated volume extents, nominal brick extents and
   per-axis halo, all supplied by the caller — brick dimensions are
   capability-and-workload policy inputs and never constants of the
   public model, per `VOX-BRK-003`. `BrickIdentity` names one brick
   minimally — the volume's object identifier, the level index and
   the per-axis brick coordinate — and every region is derived from
   the grid authority rather than stored, so identity and layout can
   never disagree.
2. **The derivations are frozen integer arithmetic.** Per axis with
   volume extent `e`, nominal extent `n`, halo `h`, factor `f` and
   brick index `i`:
   - brick count `= (e + n - 1) / n` in integer division;
   - core region `lower = i * n`, `upper = min(lower + n, e)` — the
     final brick's smaller extent is structural, per `VOX-BRK-004`;
   - haloed region `lower = max(0, coreLower - h)`,
     `upper = min(e, coreUpper + h)` — the halo clamps at the volume
     boundary and never fabricates voxels that do not exist;
   - level extent `= (e + f - 1) / f`.
3. **Spatial relationships between levels are the accepted rescale.**
   A level's geometry is `VOXELIA-ALG-0008` revision 1.1 applied
   with the level's factors through the one shared rule
   implementation — referenced, never re-derived — satisfying
   `VOX-BRK-005` by authority rather than by a new rule.
4. **Admission is typed and payload-free**: non-positive volume or
   brick extents, a negative halo or one at least the nominal
   extent, a non-positive factor, a negative level index, a rank
   mismatch and a coordinate outside the grid each reject their own
   case.
5. **Implementation follows separately**, and no consumer may embed
   ad-hoc brick arithmetic meanwhile.

## Alternatives considered

Halo replication at the boundary was rejected: replicating edge
voxels into the halo fabricates data at the vocabulary level, and a
fetch-time consumer that needs replication must claim it explicitly.
Storing regions on the identity was rejected: derived values stored
beside their inputs drift. Hard-coded preferred brick sizes were
rejected by the baseline row itself.

## Consequences

The brick request lifecycle and cache designs have a frozen
vocabulary to build on; the queue's dependency order holds.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The implementing increment must reproduce the conformance fixtures:
volume `(100, 64, 30)` with nominal `(32, 32, 16)` and halo
`(2, 2, 2)` yields brick counts `(4, 2, 2)`; the boundary brick
`(3, 1, 1)` has core region `(96, 32, 16)` to `(100, 64, 30)` with
extents `(4, 32, 14)`; the haloed region of brick `(0, 0, 0)` is
`(0, 0, 0)` to `(34, 34, 18)` and of brick `(3, 1, 1)` is
`(94, 30, 14)` to `(100, 64, 30)`, both clamped; level factors
`(2, 2, 2)` and `(4, 4, 2)` yield level extents `(50, 32, 15)` and
`(25, 16, 15)`. Every typed admission must reject, and repeated
derivation must be identical.

## Migration

None; implementation follows as its own increment.

## Supersession

Opens the M5 bricked-volume arc; no record is superseded.

## References

- [VOXELIA-ALG-0008 - Nearest-neighbour resampling binary64-v1](../../algorithms/VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
- [ADR-0064 - Exact region extraction operation](ADR-0064-exact-region-extraction-operation.md)
