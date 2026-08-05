---
document_id: "ADR-0160"
title: "Project intensity operation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-MPR-007"
  - "VOX-MPR-008"
  - "VOX-MPR-009"
  - "VOX-MPR-010"
  - "VOX-ERR-001"
---

# ADR-0160 - Project intensity operation

## Context

Accepted `ADR-0159` froze the `intensity-projection/exact-v1` model.
This record implements it as the tenth registered operation. It was
authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **`ProjectIntensityOperation` joins `VoxeliaExecution`** under the
   accepted assembly pattern with the closed `ProjectionMode`
   vocabulary — maximum, minimum, average — digested beside the axis
   and the optional padding sentinel; `org.voxelia.op.project-intensity`
   opens at 1.0.0 and claims the exact precision policy, because no
   floating-point step exists anywhere in the model.
2. **Admission is typed and payload-free**: the version-one value
   domain, an out-of-range axis, a geometry-bearing input — the
   squeeze precedent, because projecting away an axis's calibration
   silently would misreport it — and an unrepresentable sentinel.
3. **The output follows the squeeze convention**: the projected axis
   is removed, the remaining input axis descriptors are preserved in
   order, and the output claims no geometry.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

Maximum, minimum and average projection exist as one registered,
provenance-complete exact operation; thick-slab reconstruction
composes with the accepted extraction.

## Affected modules

`VoxeliaExecution`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One full-volume coordinated read and one exact streaming pass per
output sample's ray.

## Validation impact

New suite `ProjectIntensityOperationTests` reproduces every
specification fixture including all three axes over the primary
volume, the half-even boundary set, the sentinel set and the
depth-one identity, proves bit-identical repetition, and rejects
every typed admission.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0159`; no record is superseded.

## References

- [ADR-0159 - Intensity projection design](ADR-0159-intensity-projection-design.md)
- [VOXELIA-ALG-0020 - Intensity projection exact-v1](../../algorithms/VOXELIA-ALG-0020-intensity-projection.md)
