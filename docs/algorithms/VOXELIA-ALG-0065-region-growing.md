---
document_id: "VOXELIA-ALG-0065"
title: "Region growing exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Region growing exact-v1

## Purpose

`VOX-SEG-007` — region growing with recorded seeds, thresholds, connectivity
and implementation version. The model is `region-grow/exact-v1`; the
recording is the row's emphasis and lands in the operation's parameter
document and provenance. `ADR-0361` records the design.

## The rule

Over `ADR-0352`'s stored-value domain, a sample is included exactly when it
is **in range** and **connected to an in-range seed through in-range
samples** under the chosen `VOXELIA-ALG-0062` connectivity.

In-range composes `VOXELIA-ALG-0057` verbatim: the declared padding sentinel
excludes **first** (a sentinel inside the range still blocks growth —
fixture 4 is the witness), a `float32` NaN is never in range, and the
inclusive bounds compare exactly widened binary64 values. NaN is not counted
here — the threshold operation is the instrument for that observation, and
growth merely never crosses one.

**An out-of-range seed founds nothing, deliberately not an error**:
interactive seeding must not throw on a miss, and an empty mask is a visible
result where an exception would be a modal interruption. Duplicate and
coincident seeds are harmless: growth is a set union.

The output is a **mask image** (`uint8` `0`/`1`, `mask` semantic, geometry
verbatim). The fill's visit order is not observable and not part of the
contract — membership is order-independent, as `VOXELIA-ALG-0062` recorded.

## The recording

The parameter document carries every seed coordinate in order, the two
bounds, the sentinel only when declared (the padding-entry precedent), and
the connectivity token. The implementation version is structural: the
operation pattern's derivation and provenance already bind
`operationVersion` and `implementationVersion`, which is what the row's
fourth noun asks for.

## Determinism and failure classification

Pure selection; no warnings can arise. Failure cases are admission-only:
`unsupportedLayerFormat`, `invalidThresholdRange`, `invalidPaddingValue`,
`invalidSeed` (empty seed list, rank mismatch, out-of-bounds coordinate),
`invalidConnectivity` (the rank rule of `VOXELIA-ALG-0062`).

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0361-region-grow-oracle.py`; exact.

1. **Two plateaus split by a gap**: seeding the left grows only the left
   (`1, 1, 0, 0, 0, 0`); seeding the right grows only the right.
2. **An out-of-range seed** grows nothing.
3. **The diagonal bridge** crosses only under vertex connectivity: `faces`
   keeps the seed alone; `facesEdgesAndVertices` claims the diagonal.
4. **A sentinel inside the range blocks growth** (`1, 0, 0, 0`); without
   the declaration the same bytes flow (`1, 1, 1, 1`).

## Validation obligations

The implementing increment must reproduce all four fixtures exactly, must
verify the parameter document carries seeds, bounds, sentinel-when-present
and connectivity by digest comparison, and must verify the admission
rejections typed — including an out-of-bounds seed and the two-dimensional
`facesAndEdges` refusal.

## References

- [VOXELIA-ALG-0057 - Range threshold](VOXELIA-ALG-0057-range-threshold.md)
- [VOXELIA-ALG-0062 - Connected components](VOXELIA-ALG-0062-connected-components.md)
- [ADR-0361 - Region growing](../architecture/decisions/ADR-0361-region-growing.md)
