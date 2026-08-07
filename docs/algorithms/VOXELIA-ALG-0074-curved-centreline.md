---
document_id: "VOXELIA-ALG-0074"
title: "Curved centreline binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Curved centreline binary64-v1

## Purpose

`VOX-MPR-012` — the explicit centreline curved planar reconstruction
accepts: an ordered polyline in declared physical coordinates with a
frozen arc-length parameterisation. The model is
`curved-centreline/binary64-v1`; `ADR-0375` records the design.

## The rule

Over an admitted centreline of `N ≥ 2` points in one declared space,
consecutive points distinct:

- **Segment lengths are frozen Euclidean distances**: differences, the
  fold `(dx·dx + dy·dy) + dz·dz`, one correctly rounded square root
  each.
- **Cumulative marks fold in segment order**: `c₀ = 0`,
  `cᵢ₊₁ = cᵢ + lᵢ`, the last mark being the total arc length.
- **Position at arc length `s`**, admitted for `0 ≤ s ≤ total`:
  - `s` exactly the total returns the **last point verbatim** — the far
    endpoint is exact by rule, not by luck of the rounding.
  - Otherwise the segment is the largest `i` with `cᵢ ≤ s`; the local
    parameter is `t = (s − cᵢ)/lᵢ`; each coordinate evaluates the
    frozen form `aᵢ + t·(bᵢ − aᵢ)`, negative zero normalised. A mark
    hit (`s = cᵢ`) makes `t` exactly zero, so interior vertices are
    exact too.

## Determinism and failure classification

Every expression order is fixed; repeated evaluation is bit-identical.
Failure cases are admission-only: fewer than two points, a point outside
the declared space, exactly coincident consecutive points (a zero-length
segment cannot parameterise), or an arc length outside `[0, total]` —
NaN included, since NaN admits no ordering.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0375-curved-centreline-oracle.py`.

- The integer elbow `(0,0,0) → (3,0,0) → (3,4,0)`: lengths `(3, 4)`,
  total `7`; positions at `1.5`, `3` (vertex), `5.5` and `7` (endpoint)
  are exactly `(1.5,0,0)`, `(3,0,0)`, `(3,2.5,0)` and `(3,4,0)`.
- The diagonal `(0,0,0) → (1,1,0)`: total `0x1.6a09e667f3bcdp+0`
  (`√2`); position at `1` is `(0x1.6a09e667f3bccp-1,
  0x1.6a09e667f3bccp-1, 0)` — one ulp inside the endpoint, pinned.

## Validation obligations

The implementing increment must reproduce every fixture bit-exactly and
verify the admission rejections typed.

## References

- [VOXELIA-ALG-0073 - Registration quality](VOXELIA-ALG-0073-registration-quality.md)
- [ADR-0375 - The explicit centreline](../architecture/decisions/ADR-0375-the-explicit-centreline.md)
