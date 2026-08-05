---
document_id: "VOXELIA-ALG-0020"
title: "Intensity projection exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Intensity projection exact-v1

## Purpose

This specification defines the versioned reference operation
`intensity-projection/exact-v1` selected by accepted
[`ADR-0159`](../architecture/decisions/ADR-0159-intensity-projection-design.md)
— maximum, minimum and average projection along one axis of a
rank-three slab, the model behind `VOX-MPR-007/008/009` with the
`VOX-MPR-010` treatments declared.

## Model

For a rank-three eight-bit volume and a projection axis `k`, every
output sample corresponds to one ray: the stored samples along axis
`k` at fixed remaining coordinates, taken in ascending index order.
The closed mode vocabulary is `maximum`, `minimum` and `average`,
and the whole model is exact integer arithmetic — no floating-point
step exists:

- `maximum` and `minimum` are the exact integer extremes of the
  ray's included samples.
- `average` accumulates the included samples in ascending index
  order into an exact integer sum and rounds the exact rational
  `sum / count` half to even:

```text
q = sum / count          (integer division)
r = sum mod count
2r < count  ->  q
2r > count  ->  q + 1
2r = count  ->  q when q is even, otherwise q + 1
```

**Padding.** With a declared padding sentinel, a stored sample
exactly equal to the sentinel is excluded from the ray before any
step — the accepted `ADR-0113` exclusion rule — and the average's
count counts only included samples. A ray whose samples are all
excluded outputs exactly zero for every mode, consistent with the
accepted rule that excluded samples display black. An absent
sentinel includes every sample.

**Missing samples and out-of-bounds regions.** The admitted domain
has no missing samples: storage serves complete region reads, and
missingness arriving with adapters is represented as padding
sentinels under the rule above. Slab selection happens in the
accepted extraction operation whose region admission is typed;
projection admits whole inputs, so an out-of-bounds slab is a typed
extraction rejection, never a silent clamp here.

The output is rank two: the projected axis is removed and the
remaining axes keep their order, the accepted squeeze convention.

## Determinism and failure classification

The projection is a pure exact function of the samples, the axis,
the mode and the sentinel: repeated evaluation is bit-identical.
Rank, format, axis and sentinel admission is the receiver's typed
surface; no branch of the model itself can fail for admitted inputs.

## Conformance fixtures

Independently computed. Over the `(2, 2, 3)` volume with rays along
axis two — `(10, 30, 20)`, `(1, 2, 2)`, `(0, 1, 0)`, `(3, 4, 0)` in
axis-zero-fastest ray order:

- maximum `[30, 2, 1, 4]`, minimum `[10, 1, 0, 0]`,
  average `[20, 2, 0, 2]` — the second ray's five-thirds rounding up
  and the fourth's seven-thirds rounding down.

Over the depth-two volume with rays `(1, 2)`, `(2, 3)`, `(0, 1)`,
`(255, 254)`, the average half-even boundary in every direction:
`[2, 2, 0, 254]`.

With sentinel `7` over rays `(7, 5, 7)`, `(7, 7, 7)`, `(6, 7, 9)`:
maximum `[5, 0, 9]`, minimum `[5, 0, 6]`, average `[5, 0, 8]` — the
partially excluded ray reduces to its one sample, the all-excluded
ray outputs exactly zero, and the mixed ray averages fifteen halves
to eight.

A depth-one volume is the identity for every mode.

## Validation obligations

The implementing increment must reproduce every fixture for all
three modes across all three axes' admission, prove the depth-one
identity, prove bit-identical repetition, and reject the typed
admissions — rank, format, axis and unrepresentable sentinel —
without coercion.

## References

- [ADR-0159 - Intensity projection design](../architecture/decisions/ADR-0159-intensity-projection-design.md)
- [ADR-0113 - Pixel padding exclusion](../architecture/decisions/ADR-0113-pixel-padding-exclusion.md)
- [VOXELIA-ALG-0013 - Singleton axis squeeze](VOXELIA-ALG-0013-singleton-axis-squeeze.md)
