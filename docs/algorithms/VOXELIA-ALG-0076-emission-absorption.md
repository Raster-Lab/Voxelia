---
document_id: "VOXELIA-ALG-0076"
title: "Emission-absorption integration binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Emission-absorption integration binary64-v1

## Purpose

`VOX-PRR-004` — physically based volumetric illumination, founded on
the emission-absorption solution of the radiative transfer equation:
per-sample emission attenuated by accumulated Beer-Lambert absorption,
composited front to back. The model is
`emission-absorption/binary64-v1`; `ADR-0386` records the design.

## The rule

Over an ordered ray of samples, each an emission triple and an opacity
in `[0, 1]`, all finite, emissions non-negative:

- **Front-to-back accumulation is frozen**: per sample, one weight
  `w = (1 − A)·α` rounded once, then per channel `C = C + w·e` in
  r, g, b order, then `A = A + w`. Left-to-right, no fused
  multiply-add, no reassociation.
- **Exact saturation stops the walk**: when the accumulated opacity is
  exactly `1`, later samples are occluded and skipped. The comparison
  is exact — no epsilon threshold decides visibility.
- **An empty ray is exactly transparent**: `(0, 0, 0, 0)`, honest
  absence rather than a refusal, because a ray that intersects nothing
  is a legitimate answer.
- **Sampling is the caller's seam**: how samples arise from a volume,
  a transfer function and a step size belongs to the arcs that build
  the renderer — the integrator is the numerical core, exactly
  testable, the same seam discipline as the registration metrics.

## Determinism and failure classification

Every expression order is fixed; repeated integration over the same
admitted ray is bit-identical. Failure cases are admission-only: a
non-finite component, a negative emission, or an opacity outside
`[0, 1]`.

## Conformance fixtures

Computed by
`docs/progress/evidence/ADR-0386-emission-absorption-oracle.py`.

- Two half-opaque dyadic samples: exactly
  `(0.625, 0.5, 0.125, 0.75)`.
- An exactly opaque first sample: the second sample is occluded and
  the result is the first sample's emission exactly.
- The empty ray: exactly `(0, 0, 0, 0)`.
- Three irrational samples: `(0x1.ba786c226809ep-2,
  0x1.0f0d844d013aap-1, 0x1.40ded288ce704p-1, 0x1.f22d0e5604189p-1)`.

## Validation obligations

The implementing increment must reproduce every fixture bit-exactly and
verify the admission rejections typed.

## References

- [VOXELIA-ALG-0072 - Registration metrics](VOXELIA-ALG-0072-registration-metrics.md)
- [ADR-0386 - Volumetric illumination](../architecture/decisions/ADR-0386-volumetric-illumination.md)
