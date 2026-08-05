---
document_id: "VOXELIA-ALG-0026"
title: "Segmentation mask sampling binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Segmentation mask sampling binary64-v1

## Purpose

This specification defines the versioned reference model
`segmentation-mask-sampling/binary64-v1` selected by accepted
[`ADR-0180`](../architecture/decisions/ADR-0180-segmentation-masks-design.md)
— nearest-neighbour label lookup and masked compositing for direct
volume rendering, per `VOX-DVR-010`. Everything this model composites
is presentation, never a source of authoritative quantitative
measurement, per the arc's binding rule.

## Model

**Nearest-neighbour label lookup.** At a sample's index position `c`
— the same continuous index-space position the accepted
`VOXELIA-ALG-0017` trilinear sampler consumes — the label volume's
voxel index per axis is the round-half-away-from-zero of the
coordinate, clamped to the volume's extent:

```text
i_k = clamp(round(c[k]), 0, extent[k] - 1)
```

restated rather than composed with `VOXELIA-ALG-0017`'s trilinear tap
rule or `VOXELIA-ALG-0008`'s shifted-floor rule: interpolating label
identifiers is meaningless — averaging label one and label two
produces neither — and `VOXELIA-ALG-0008`'s rule assumes a
continuous-output-pixel-space grid, a different convention from the
centres-at-integers index space every volume sample already uses. A
position outside every axis's `[-0.5, extent - 0.5]` support returns
label zero, mirroring `VOXELIA-ALG-0017`'s out-of-support sentinel and
flat-indexing form.

**Masked compositing.** The accepted `VOXELIA-ALG-0023` front-to-back
accumulation is extended with a per-sample inclusion flag, aligned to
the samples exactly as the accepted shading factors are: an excluded
sample's colour and opacity never reach the accumulation — `red`,
`green`, `blue` and `accumulated` are left unchanged for that step —
while the consumed-sample count and the early-termination check
proceed exactly as before, unconditionally:

```text
for (sample, included) in samples:
    if included:
        alpha  = table.entry(sample).opacity / 255
        weight = (1 - accumulated) * alpha
        red   += weight * (table.entry(sample).red   / 255)
        green += weight * (table.entry(sample).green / 255)
        blue  += weight * (table.entry(sample).blue  / 255)
        accumulated += weight
    consumed += 1
    if accumulated >= 255/256: break
```

An excluded sample is indistinguishable from an absent one for every
accumulated channel — the ray still visited that position, so it is
still consumed, but it contributes nothing. The rule composes
independently with the accepted shading-factor modulation: when both
are declared, the colour multiplication and the inclusion gate apply
to the same step, in the declared order — inclusion gates whether the
(already shading-modulated) contribution happens at all. The accepted
unmasked entries are untouched; masking is realised as two additional
sibling entries, never a modification of the accepted ones.

**Visible-label admission.** A `VolumeMaskSelection` pairs one mask
volume identity with a non-empty set of visible label values; an
empty set is rejected typed at construction — a mask that hides every
label is almost certainly a caller error, and the empty-render case
is already reachable by omitting the mask entirely. The set is
unordered by type; wherever it is digested into a stable byte
sequence, the ascending-sorted label values are the canonical form.

## Determinism and failure classification

The masked composite is a pure function of the samples, the inclusion
flags and the table: repeated evaluation is bit-identical. The label
lookup is a pure function of the position, the extents and the mask
bytes. Admission belongs to the consuming surfaces (`VolumeMaskSelection`'s
non-empty set, the renderer's extent and format checks); no branch of
the model itself can fail for admitted inputs.

## Conformance fixtures

Independently computed over the frozen six-sample axis-ray fixture
(`VOXELIA-ALG-0022`'s ray `(-2, 1, 1)` through identity geometry,
extents `[3, 3, 3]`, index-`x` positions `-0.25, 0.25, 0.75, 1.25,
1.75, 2.25`):

- The nearest-neighbour voxel-`x` indices are exactly `0, 0, 1, 1, 2,
  2`.
- Samples `[10, 10, 200, 200, 250, 250]` masked to include only the
  two `200` samples (table entries: `10 → (0,255,0,255)`, `200 →
  (255,0,0,128)`, `250 → (0,0,255,255)`) composite to output bytes
  `(192, 0, 0, 192)` with `consumedSampleCount` `6`; compositing the
  filtered pair `[200, 200]` alone through the accepted unmasked
  entry gives the identical colour and alpha bytes with
  `consumedSampleCount` `2` — the two differ only in how many
  positions were visited, never in what they accumulated.
- The same masked selection composited with shading factors `[1, 1,
  0.6, 0.9, 1, 1]` gives output bytes `(134, 0, 0, 192)` with
  `consumedSampleCount` `6`, identical colour and alpha to the
  accepted shaded entry over the filtered pair `[200, 200]` with
  factors `[0.6, 0.9]` alone (`consumedSampleCount` `2`).
- Including every label reproduces the accepted unmasked entry's full
  result — colour, alpha and `consumedSampleCount` all equal —
  because nothing is skipped and none of the surrounding bookkeeping
  differs.
- Excluding every label composites to fully transparent black, bytes
  `(0, 0, 0, 0)`, with every sample still consumed.

## Validation obligations

The implementing increment must reproduce every fixture exactly,
prove bit-identical repetition, prove the unmasked entries are
untouched (structural, not merely asserted), prove the all-included
case equals the unmasked entry as a complete tuple including the
consumed count, and reject the empty visible-label set, the
extent-mismatched mask volume and an unsupported mask scalar format,
each typed.

## References

- [ADR-0180 - Segmentation masks design](../architecture/decisions/ADR-0180-segmentation-masks-design.md)
- [VOXELIA-ALG-0008 - Nearest-neighbour resampling binary64-v1](VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling binary64-v1](VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [VOXELIA-ALG-0022 - Volume ray sampling binary64-v1](VOXELIA-ALG-0022-ray-sampling.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing binary64-v1](VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0025 - Gradient lighting binary64-v1](VOXELIA-ALG-0025-gradient-lighting.md)
