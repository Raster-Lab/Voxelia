---
document_id: "ADR-0167"
title: "Transfer function"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-005"
  - "VOX-DVR-007"
  - "VOX-ERR-001"
---

# ADR-0167 - Transfer function

## Context

Accepted `ADR-0166` froze the transfer-function design. This record
implements it; per the arc's binding rule, everything this
vocabulary feeds is presentation, never a source of authoritative
quantitative measurement. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **`TransferFunctionEntry` and `TransferFunction1D` join
   `VoxeliaRendering`** exactly as designed: four structurally valid
   eight-bit components per entry, a table admitting exactly two
   hundred fifty-six entries with the one typed size rejection, and
   `entry(at:)` applying the declared clamp to any integer index.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

The compositing increment has its input vocabulary live.

## Affected modules

`VoxeliaRendering`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

Constant-time lookup; one array of two hundred fifty-six entries.

## Validation impact

New suite `TransferFunctionTests` proves the ramp identity lookup,
both clamp directions, the typed size rejection and bit-identical
repetition.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0166`; no record is superseded.

## References

- [ADR-0166 - Transfer function design](ADR-0166-transfer-function-design.md)
