---
document_id: "ADR-0127"
title: "Bilinear geometry widening"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-003"
  - "VOX-EXE-002"
  - "VOX-ERR-001"
---

# ADR-0127 - Bilinear geometry widening

## Context

`ADR-0126` registered the rescale rules and widened the
nearest-neighbour operation; the bilinear operation still rejected
calibrated inputs, so the linear display policy lost calibration
where the nearest policy kept it. This record was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

1. **The same rules, one authority.** `VOXELIA-ALG-0015` revision 1.1
   adopts the `VOXELIA-ALG-0008` revision 1.1 rescale rules verbatim,
   and both resampling operations now evaluate them through one
   shared internal implementation per the shared-authority precedent
   — two copies of one registered rule could drift silently — with
   the nearest operation refactored onto it byte-identically.
2. **The widened operation.** `ResampleLinearOperation` admits
   regular sampling and affine geometry at the 1.1.0 versions,
   rebuilds sampling and geometry through the shared authority, keeps
   irregular and categorical payloads typed rejections, and drops its
   now-dead geometry rejection per the dead-case precedent.

## Alternatives considered

Duplicating the rescale arithmetic per operation was rejected under
the shared-authority rule. A distinct rescale convention for the
linear policy was rejected: physical position does not depend on the
interpolation of values.

## Consequences

Both display policies preserve calibration; `VOX-MPR-003` is
discharged for both, and the physical-picking decision follows.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Admission widening under the established version bump; geometry-free
behaviour byte-identical; one dead case removed.

## Security impact

Unchanged budgets; typed payload-free rejections.

## Performance and memory impact

Constant-time descriptor rebuilds per execution.

## Validation impact

Tests must reproduce the registered rescale fixtures through the
linear operation with the widened version, keep geometry-free outputs
byte-identical, and keep irregular payloads rejected typed.

## Migration

Implemented in this increment.

## Supersession

Revises `VOXELIA-ALG-0015` to 1.1 and widens `ADR-0123`; those
records otherwise stand.

## References

- [ADR-0126 - Geometry-bearing resampling](ADR-0126-geometry-bearing-resampling.md)
- [VOXELIA-ALG-0015 - Bilinear resampling binary64-v1](../../algorithms/VOXELIA-ALG-0015-bilinear-resampling.md)
