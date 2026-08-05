---
document_id: "ADR-0162"
title: "Brick statistics"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-BRK-011"
  - "VOX-DVR-012"
  - "VOX-ERR-001"
---

# ADR-0162 - Brick statistics

## Context

Accepted `ADR-0161` froze the per-brick statistics design. This
record implements it. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **`BrickStatistics` joins `VoxeliaStorage`** beside the brick
   vocabulary, obtainable only through the pure computing
   initializer over a core payload and optional sentinel — one
   ascending pass producing the total and included counts, the
   included extremes absent rather than fabricated when every sample
   is excluded, and the non-zero included occupancy count.
2. **The one typed case** rejects an empty payload; every field is
   otherwise structurally valid by construction.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

The acceleration arcs have their fact vocabulary; skipping verdicts
stay with consumers.

## Affected modules

`VoxeliaStorage`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One ascending pass per computation; no allocation.

## Validation impact

New suite `BrickStatisticsTests` reproduces the design fixtures —
partially excluded, all-excluded with absent extremes, all-zero with
zero occupancy and unpadded mixed payloads — and rejects the typed
empty payload.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0161`; no record is superseded.

## References

- [ADR-0161 - Brick statistics design](ADR-0161-brick-statistics-design.md)
