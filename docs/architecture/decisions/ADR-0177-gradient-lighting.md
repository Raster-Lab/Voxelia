---
document_id: "ADR-0177"
title: "Gradient lighting"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-008"
  - "VOX-ERR-001"
---

# ADR-0177 - Gradient lighting

## Context

Accepted `ADR-0176` froze the gradient-lighting model. This record
implements it; everything it shades is presentation, never a source
of authoritative quantitative measurement, per the arc's binding
rule. It was authored and accepted on 2026-08-05 under the project
owner's recorded broadened autonomous delegation.

## Decision

1. **`VolumeLightingModel` joins `VoxeliaRendering`** as the closed
   none-and-headlight vocabulary, and the volume request gains the
   explicit lighting member — no permissive default, every call site
   stating its mode.
2. **The renderer shades per sample through composed authorities**:
   six extra trilinear samples through the one public sampling
   authority form the central differences, the world gradient is the
   accepted inverse's transpose, and the frozen factor modulates the
   colour components before the accepted compositing conversion —
   through a shaded compositor entry whose factor sequence aligns
   with the samples, while the unshaded mode calls the accepted
   compositor unchanged, so byte identity is structural rather than
   asserted. Opacity is never modulated. The lighting token joins
   the digested parameters.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

The renderer lights surfaces honestly; the clipping, mask and
acceleration increments remain.

## Affected modules

`VoxeliaRendering`, `VoxeliaMetal`.

## Compatibility impact

The request gains the explicit lighting member; call sites state it.

## Security impact

None.

## Performance and memory impact

Six additional trilinear samples per shaded sample; none in the
unshaded mode.

## Validation impact

The suites reproduce every specification fixture exactly — the
head-on, grazing and forty-five-degree factors, the
calibration-invariant normal, the zero-gradient identity — prove the
unshaded mode byte-identical through the untouched path, prove
opacity untouched under shading, and prove bit-identical repetition.

## Migration

Call sites add the explicit lighting member.

## Supersession

Implements accepted `ADR-0176`; no record is superseded.

## References

- [ADR-0176 - Gradient lighting design](ADR-0176-gradient-lighting-design.md)
- [VOXELIA-ALG-0025 - Gradient lighting binary64-v1](../../algorithms/VOXELIA-ALG-0025-gradient-lighting.md)
