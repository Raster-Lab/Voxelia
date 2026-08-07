---
document_id: "VOXELIA-ALG-0077"
title: "Shadow transmittance binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Shadow transmittance binary64-v1

## Purpose

`VOX-PRR-005` — volumetric shadows: the fraction of light surviving a
walk through the volume toward a light. The model is
`shadow-transmittance/binary64-v1`; `ADR-0387` records the design.

## The rule

Over an ordered shadow ray of opacities, each finite in `[0, 1]`:

- **The transmittance folds multiplicatively**: `T = T·(1 − α)` in ray
  order, starting from exactly one, one rounding per step.
- **Exact extinction stops the walk**: when `T` is exactly zero, later
  samples cannot restore light and are skipped. Exact, no epsilon.
- **The empty ray transmits exactly one** — an unobstructed light is a
  legitimate answer, not a refusal.
- **Sampling is the caller's seam**, as everywhere in this arc: how
  shadow rays are marched belongs to the renderer arcs.

## Determinism and failure classification

Every fold order is fixed; repeated evaluation is bit-identical.
Failure cases are admission-only: a non-finite opacity or one outside
`[0, 1]` — the same admission the `VOXELIA-ALG-0076` samples carry.

## Conformance fixtures

Computed by
`docs/progress/evidence/ADR-0387-shadow-transmittance-oracle.py`.

- Two half opacities: exactly `0.25`.
- An opaque first sample: exactly `0` with the walk stopped.
- The empty ray: exactly `1`.
- `(0.1, 0.7, 0.9)`: `0x1.ba5e353f7ced9p-6`.

## Validation obligations

The implementing increment must reproduce every fixture bit-exactly and
verify the admission rejections typed.

## References

- [VOXELIA-ALG-0076 - Emission-absorption integration](VOXELIA-ALG-0076-emission-absorption.md)
- [ADR-0387 - Volumetric shadows](../architecture/decisions/ADR-0387-volumetric-shadows.md)
