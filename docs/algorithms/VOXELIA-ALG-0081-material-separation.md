---
document_id: "VOXELIA-ALG-0081"
title: "Material separation binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Material separation binary64-v1

## Purpose

`VOX-PRR-009` — material-separated presentation: one ray integrated
once, its radiance partitioned by declared material class. The model is
`material-separation/binary64-v1`; `ADR-0392` records the design.

## The rule

Over an ordered ray of `VOXELIA-ALG-0076` samples, each tagged with a
declared material index below a declared material count:

- **The opacity walk is shared and identical to `VOXELIA-ALG-0076`**:
  one weight `w = (1 − A)·α` per sample, one global accumulation, the
  same exact saturation. A later material's samples are attenuated by
  everything in front of them, whatever material that was — separation
  changes where radiance is *recorded*, never how light *travels*.
- **Each sample's weighted emission accumulates into its own
  material's channels**, in ray order, frozen folds per channel.
- The result is one radiance triple per declared material plus the
  shared opacity. No combined image is computed here — the combined
  presentation is the plain `VOXELIA-ALG-0076` integration of the same
  ray, and summing per-material triples would round in a different
  order than that integration; the model refuses to pretend the two
  are bit-equal.

## Determinism and failure classification

Every fold order is fixed; repeated integration is bit-identical.
Failure cases are admission-only: a material index at or above the
declared count, a non-positive material count, or the
`VOXELIA-ALG-0076` sample admissions.

## Conformance fixtures

Computed by
`docs/progress/evidence/ADR-0392-material-separation-oracle.py`.

- Two materials interleaved (dyadic): opacity exactly `0.875`;
  material 0 exactly `(0.53125, 0.28125, 0.25)`; material 1 exactly
  `(0.125, 0.25, 0)`.
- An opaque foreign material occludes a later material entirely: the
  occluded material's channels are exactly zero.

## Validation obligations

The implementing increment must reproduce both fixtures bit-exactly
and verify the admission rejections typed.

## References

- [VOXELIA-ALG-0076 - Emission-absorption integration](VOXELIA-ALG-0076-emission-absorption.md)
- [ADR-0392 - Material-separated presentation](../architecture/decisions/ADR-0392-material-separated-presentation.md)
