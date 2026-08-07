---
document_id: "VOXELIA-ALG-0078"
title: "Lighting and transillumination binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Lighting and transillumination binary64-v1

## Purpose

`VOX-PRR-006` and `VOX-PRR-008` — area and environment lighting as
declared light-sample accumulation, and transparency/transillumination
as radiance-over-background composition. The model is
`lighting-transillumination/binary64-v1`; `ADR-0388` records the
design.

## The rule

**Light accumulation**, over a declared ordered set of light samples —
each a non-negative finite radiance triple, a non-negative finite
weight and a transmittance in `[0, 1]`:

- Per sample, one factor `f = w·T` rounded once, then per channel
  `L = L + f·e` in r, g, b order. Left-to-right, no reassociation.
- **The light set is caller-declared and its geometry is the caller's
  seam**: an area light is represented by the samples the caller drew
  over its surface, an environment by its directional samples — the
  accumulator does not sample, exactly as the integrator does not.
- The empty set accumulates exactly zero.

**Transillumination**, over one integrated `VOXELIA-ALG-0076` radiance
and a non-negative finite background triple:

- One remaining-light factor `r = 1 − A` rounded once, then per channel
  `F = C + r·B` — the transparency presentation: what the volume did
  not absorb arrives from behind it.
- An exactly opaque foreground admits exactly nothing of the
  background.

## Determinism and failure classification

Every fold order is fixed; repeated evaluation is bit-identical.
Failure cases are admission-only: non-finite components, negative
radiance or weight, or a transmittance outside `[0, 1]`.

## Conformance fixtures

Computed by
`docs/progress/evidence/ADR-0388-lighting-transillumination-oracle.py`.

- Two dyadic light samples: exactly `(0.3125, 0.375, 0.0625)`.
- A fully shadowed light contributes exactly nothing.
- The irrational set pins `(0x1.645a1cac08312p-4, 0x1.3f7ced916872bp-3,
  0x1.ccccccccccccdp-3)`.
- Dyadic transillumination: exactly `(0.5, 0.625, 0.1875)`; an opaque
  foreground passes the foreground exactly; the irrational case pins
  `(0x1.7ae147ae147b0p-2, 0x1.c28f5c28f5c2ap-2, 0x1.051eb851eb852p-1)`.

## Validation obligations

The implementing increment must reproduce every fixture bit-exactly and
verify the admission rejections typed.

## References

- [VOXELIA-ALG-0076 - Emission-absorption integration](VOXELIA-ALG-0076-emission-absorption.md)
- [VOXELIA-ALG-0077 - Shadow transmittance](VOXELIA-ALG-0077-shadow-transmittance.md)
- [ADR-0388 - Lighting and transillumination](../architecture/decisions/ADR-0388-lighting-and-transillumination.md)
