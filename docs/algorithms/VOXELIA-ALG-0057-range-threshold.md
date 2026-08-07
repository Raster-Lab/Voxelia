---
document_id: "VOXELIA-ALG-0057"
title: "Range threshold binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Range threshold binary64-v1

## Purpose

`VOX-IMG-010` requires threshold, mask and image-arithmetic foundations; this
specification freezes the first of them, and with it the value domain the arc's
operations share. It is the model `range-threshold/binary64-v1`. `ADR-0352`
opens the arc and records the domain decision.

## The value domain, and why it is wider than the display path's

Admitted stored types: **`uint8`, `int16`, `uint16`, `float32`**, single-channel
scalar, `intensity` or `parametric` semantic. The M0-M6 samplers bound
themselves to the display-policy `uint8` domain; processing operates on the
study's stored values — CT's signed sixteen-bit reality — and `VOX-R2D-004`
requires floating-point input where the descriptor and operation permit it.
This operation permits it, which **advances `VOX-R2D-004`** (its discharge
arrives when the arc's operations admit the domain uniformly).

Every admitted type widens to binary64 **exactly**: eight- and sixteen-bit
integers are below the 2^53 exactness bound, and binary32 embeds in binary64
losslessly. Comparisons therefore introduce no rounding anywhere.

## The rule

Parameters: a lower and upper bound, both finite binary64, `lower <= upper`;
an optional padding sentinel, finite binary64, compared exactly.

Per sample, in canonical storage order:

1. **Padding first**: a sample exactly equal to the declared sentinel produces
   mask `0` before any range comparison — a padded sample is not data and may
   not enter the mask even when the sentinel lies inside the range (fixture 3
   is the proof).
2. **NaN is never included and always counted**: a `float32` NaN produces mask
   `0` and increments the non-finite count; infinities are ordered values and
   compare normally (they fall outside any finite range).
3. **The inclusive range**: mask `1` exactly when `lower <= s <= upper`,
   binary64 comparison of the exactly widened sample.

The output is a **mask image**: `uint8` samples exactly `0` and `1`, `mask`
semantic, the input's geometry claimed verbatim, fresh index-only axes. `1` and
not `255`, because a mask is a label a later presentation stage may map — not a
display image — and `VOX-IMG-007`'s nearest-neighbour default binds its
resampling.

When the non-finite count is at least one, the provenance record carries the
aggregated warning `org.voxelia.warn.threshold-non-finite`, schema `1.0`,
severity `qualityAffecting`, with the count as occurrence count; a zero count
carries no entry, per the padding-entry precedent.

## Determinism and failure classification

One pass in canonical order; no floating-point arithmetic beyond exact widening
and comparison; repeated evaluation is bit-identical.

Failure cases are admission-only: `unsupportedLayerFormat` (type, channel,
semantic or rank outside the domain), `invalidThresholdRange` (non-finite or
inverted bounds), `invalidPaddingValue` (non-finite sentinel).

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0352-threshold-oracle.py`; all exact.

1. **uint8** `0, 5, 10, 15, 20, 255` in `[5, 20]` → `0, 1, 1, 1, 1, 0`.
2. **int16 with an out-of-range sentinel**: `-1024, -500, 0, 40, 400, 3071`
   in `[-500, 400]`, padding `-1024` → `0, 1, 1, 1, 1, 0`.
3. **int16 with the sentinel inside the range**: same values and range,
   padding `0` → `0, 1, 0, 1, 1, 0` — padding excludes before comparison.
4. **uint16** `0, 100, 4095, 65535` in `[100, 4095]` → `0, 1, 1, 0`.
5. **float32 with non-finite samples**: `0.5, 1.5, NaN, +inf, -inf, 2.5` in
   `[1.0, 2.5]` → `0, 1, 0, 0, 0, 1`, non-finite count `1` (the NaN alone),
   the inclusive upper edge included.

## Validation obligations

The implementing increment must reproduce all five fixtures exactly from the
oracle's little-endian byte encodings, must verify the warning appears with
count `1` for fixture 5 and is absent for fixture 1, and must verify the three
admission rejections typed.

## References

- [VOXELIA-ALG-0002 - Window level linear](VOXELIA-ALG-0002-window-level-linear.md)
- [ADR-0352 - Open the processing foundations arc](../architecture/decisions/ADR-0352-open-the-processing-foundations-arc.md)
- [ADR-0351 - The M7 queue](../architecture/decisions/ADR-0351-the-m7-queue.md)
