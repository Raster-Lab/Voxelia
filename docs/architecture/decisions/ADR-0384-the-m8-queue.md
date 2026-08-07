---
document_id: "ADR-0384"
title: "The M8 queue"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-001"
  - "VOX-PRR-002"
  - "VOX-PRR-003"
  - "VOX-PRR-004"
  - "VOX-PRR-005"
  - "VOX-PRR-006"
  - "VOX-PRR-007"
  - "VOX-PRR-008"
  - "VOX-PRR-009"
  - "VOX-PRR-010"
  - "VOX-PRR-011"
  - "VOX-PRR-012"
  - "VOX-PRR-013"
  - "VOX-PRR-014"
  - "VOX-PRR-015"
  - "VOX-PRR-017"
  - "VOX-DVR-006"
  - "VOX-VAL-015"
---

# ADR-0384 - The M8 queue

## Context

M7's engineering is complete (`ADR-0383`). M8 is the photorealistic
rendering milestone: seventeen `VOX-PRR` rows (one of them, tile/sample
partitioning, is itself M9), the multi-dimensional transfer-function
row and the photorealistic validation row. As with `ADR-0351`, the
queue is derived once, in dependency order, so every later increment
takes its row from a recorded plan rather than re-deriving scope.

## Decision

The M8 rows order into five arcs:

1. **Module foundation** — the optional module row, the
   disable-independence row and the quality-mode vocabulary row
   (interactive / progressive / reference). Everything else registers
   into this module; nothing else can go first.

2. **Physics core** — physically based volumetric illumination,
   volumetric shadows, area and environment lighting, transparency and
   transillumination, and the multiple-scattering (or documented
   approximation) row. The frozen-model discipline continues: each
   optical model gets an ALG with an independent oracle.

3. **Determinism and progression** — deterministic reference-mode
   seeds, progressive convergence/variance exposure, and safe temporal
   accumulation reset on scene/camera/transfer-function/data change.

4. **Presentation and integrity** — material-separated presentation,
   explicit versioned denoising in provenance, the no-implicit-
   generative-reconstruction guard, side-by-side comparison over the
   same authoritative scene state, and the multi-dimensional
   transfer-function row.

5. **Validation** — statistical convergence, reproducibility and
   diagnostic-feature preservation, plus the thin-structure preset row.
   Both rows carry `R` halves for the owner's session.

Two standing notes: the M9 partitioning row waits for its milestone
even though this queue's design should not preclude it; and if any M8
row turns out to need measured performance targets, the reference-
hardware question goes to the owner batch rather than being guessed —
`ADR-0338`'s reference hardware answer covers correctness fixtures,
not photorealistic throughput promises.

## Alternatives considered

### Building photorealistic features into `VoxeliaRendering`

Rejected. The first row says optional module; the disable row makes
separation structural, not stylistic.

## Consequences

The loop takes arc 1 first: the optional module with its quality-mode
vocabulary.

## Affected modules

Planning only; the arcs name their own modules.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

Each arc's increments carry their own verification; every row keeps
its baseline verification methods.

## Migration

1. This record, then arc 1's first increment.

## Supersession

This record extends `ADR-0351`'s queue into M8.

## References

- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [ADR-0383 - The initial portfolio is complete](ADR-0383-the-initial-portfolio-is-complete.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
