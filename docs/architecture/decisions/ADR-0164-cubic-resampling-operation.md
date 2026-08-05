---
document_id: "ADR-0164"
title: "Cubic resampling operation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-005"
  - "VOX-ERR-001"
---

# ADR-0164 - Cubic resampling operation

## Context

Accepted `ADR-0163` froze the `cubic-resampling/binary64-v1` model.
This record implements it as the eleventh registered operation. It
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **`ResampleCubicOperation` joins `VoxeliaExecution`** mirroring
   the accepted linear operation's structure: the identical
   rank-two value-domain admission and output-extent ceiling, one
   budgeted coordinated read, the four-tap helper with the frozen
   Catmull-Rom weight order and clamped taps, the separable
   rows-inside-columns reduction, and the modelled output clamp.
   `org.voxelia.op.resample-cubic` opens at 1.0.0.
2. **Geometry rescales through the one shared authority**, exactly
   as the linear operation adopted the accepted rules — regular
   sampling and affine geometry under the pixel-centre convention,
   with irregular and categorical payloads outside the admitted
   domain.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

The display-policy family has its cubic operation; renderer-side
policy selection follows as the consumer increment.

## Affected modules

`VoxeliaExecution`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

Sixteen taps and the frozen weight evaluation per output sample.

## Validation impact

New suite `ResampleCubicOperationTests` reproduces every
specification fixture including the overshoot and undershoot rays
and the exact identity, proves bit-identical repetition, and rejects
the typed admissions.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0163`; no record is superseded.

## References

- [ADR-0163 - Cubic resampling design](ADR-0163-cubic-resampling-design.md)
- [VOXELIA-ALG-0021 - Cubic resampling binary64-v1](../../algorithms/VOXELIA-ALG-0021-cubic-resampling.md)
