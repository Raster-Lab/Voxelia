---
document_id: "VOXELIA-ALG-0049"
title: "CT affine volume construction binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# CT affine volume construction binary64-v1

## Purpose

This specification defines `ct-affine-volume/binary64-v1`, the deterministic
construction of an `AffineGridGeometry` from an assembled and assessed CT
series, selected by accepted
[`ADR-0230`](../architecture/decisions/ADR-0230-ct-affine-volume-construction.md).

It serves `VOX-VS1-004` and `VOX-DCM-007`.

## The slice step is a vector, never a spacing

The obvious construction needs a unit normal and a scalar slice spacing. This
specification uses **neither**.

`VOXELIA-ALG-0047` deliberately left the reference normal unnormalised, because
normalising needs a square root and a zero-magnitude threshold.
`VOXELIA-ALG-0048` deliberately computed only a spacing *spread*, never a
nominal spacing, because choosing a nominal value needs an arbitrary anchor, a
mean's division, or a median's sort.

Both refusals hold here, because the affine does not need either quantity. The
displacement per slice index is a **vector difference of two stated positions**:

```text
kStep = position[1] - position[0]        componentwise
```

That is the geometry the source actually stated, it needs no square root and no
division, and it makes `ADR-0229`'s deferred "where does the nominal spacing come
from" question dissolve rather than requiring an answer.

## The matrix

The anchor is `position[0]`'s frame — the first member in the order
`VOXELIA-ALG-0047` produced.

Index 0 is the **column** index, index 1 the **row** index, index 2 the slice
index. The in-plane steps follow the `ADR-0227` axis convention exactly:

```text
iStep = columnSpacingMillimetres * rowDirection      (componentwise)
jStep = rowSpacingMillimetres    * columnDirection   (componentwise)
kStep = position[1] - position[0]                    (componentwise)
origin = position[0]
```

Note the crossing: the **column** index advances along `rowDirection` by
`columnSpacing`. Getting it backwards transposes the volume silently, which is
why every fixture uses **distinct** in-plane spacings — a swap changes the
matrix and fails the test.

The row-major `indexToWorld` is then:

```text
[ iStep.x  jStep.x  kStep.x  origin.x ]
[ iStep.y  jStep.y  kStep.y  origin.y ]
[ iStep.z  jStep.z  kStep.z  origin.z ]
[ 0        0        0        1        ]
```

`AffineGridGeometry` applies its own accepted `ADR-0043` admission to this
matrix: the exact bottom row, and an upper-left determinant magnitude of at
least `Double.leastNormalMagnitude`. This specification does not restate that
rule and does not pre-empt it.

## The fidelity residual

A single affine maps every slice index onto one uniform lattice. Whether that
lattice reproduces the positions the source stated is a **fact to be measured,
not an assumption**:

```text
computed[k][axis]  = origin[axis] + (Double(k) * kStep[axis])
fidelityResidual   = max over k, over axis, of abs(computed - stated)
```

**The residual is not always zero, even for a series the `exact` tolerance
admits.** Fixture D5 is a series whose consecutive gaps are bit-identical — so
`VOXELIA-ALG-0048` reports a spacing spread of exactly zero and the series is
`representable` — and whose residual is nevertheless `0x1.0p-49`. It was found
by searching plausible scanner geometry rather than constructed by hand,
because the point is that it arises naturally: a position list built by repeated
addition has uniform *differences* without lying on a uniform *lattice*.

The residual is reported and **not judged**. Judging it would need a threshold,
and that is the same owner gate `ADR-0229` decision 3 named.

## Numeric rules

- IEEE-754 binary64 throughout, in the frozen expression order above.
- No fused multiply-add, no reassociation.
- No square root, no division, no normalisation, no epsilon.

## Frozen fixtures

Computed by the independent oracle at
`docs/progress/evidence/ADR-0230-affine-volume-oracle.py`. Every fixture uses
`rowSpacing = 0.7` and `columnSpacing = 0.8`.

### D1 regular axial, three slices at spacing 2.5

| Element | Value |
|---|---|
| `iStep.x` | `0x1.999999999999ap-1` (0.8) |
| `jStep.y` | `0x1.6666666666666p-1` (0.7) |
| `kStep.z` | `0x1.4000000000000p+1` (2.5) |
| `origin.x`, `origin.y` | `-0x1.5f00000000000p+7` (-175.5) |
| determinant | `0x1.6666666666667p+0` |
| fidelity residual | `0x0.0p+0` |

`iStep.x` is 0.8 and `jStep.y` is 0.7 — the crossing. An implementation that
paired `rowSpacing` with `rowDirection` produces 0.7 and 0.8 transposed here.

### D2 oblique, `rowDirection = (0,1,0)`, `columnDirection = (0,0,1)`

| Element | Value |
|---|---|
| `iStep.y` | `0x1.999999999999ap-1` |
| `jStep.z` | `0x1.6666666666666p-1` |
| `kStep.x` | `0x1.8000000000000p+1` (3.0) |
| origin | `(1.0, 2.0, 3.0)` |
| determinant | `0x1.ae147ae147ae0p+0` |
| fidelity residual | `0x0.0p+0` |

### D3 in-plane spacings of `1e-160`

The determinant is `0x0.00000000007e8p-1022` — subnormal, and below
`Double.leastNormalMagnitude` — so `AffineGridGeometry` **rejects** it as
singular.

This is the specification's most surprising fixture. `VOXELIA-ALG-0048` admits
the series completely: the spacings are positive and finite, uniform, and the
directions are exactly orthonormal. The construction still fails, because the
determinant **underflows**. A validated series is therefore not a guarantee of a
constructible volume, and the failure comes from the accepted spatial type rather
than from this algorithm.

### D4 a single member

The slice step is undefined: there is no second position to subtract. The
construction fails, and no spacing is invented to rescue it.

### D5 an exactly regular series that still drifts

| Element | Value |
|---|---|
| z positions | `-21.779939649890252`, `-15.460854058197997`, `-9.141768466505741`, `-2.822682874813486` |
| z-gap spread | `0x0.0p+0` — exactly regular |
| `kStep.z` | `0x1.946be5f93c5aep+2` |
| `origin.z` | `-0x1.5c7aa1ff921e0p+4` |
| determinant | `0x1.c4f3b9e3f1ad7p+1` |
| **fidelity residual** | **`0x1.0p-49`** |

### D6 a dyadic spacing reproduces every position exactly

Four slices at spacing 2.5 from the origin: determinant
`0x1.6666666666667p+0`, fidelity residual `0x0.0p+0`. Retained as D5's control —
the residual depends on the values, not on the algorithm.

## Conformance

An implementation conforms when, for every fixture, it reproduces all sixteen
matrix elements bit-for-bit, the fidelity residual bit-for-bit, and the
outcome — constructed, singular, or slice-step-undefined.

## References

- [ADR-0043 - Spatial descriptor admission boundary](../architecture/decisions/ADR-0043-spatial-descriptor-admission-boundary.md)
- [ADR-0227 - Neutral CT frame description](../architecture/decisions/ADR-0227-neutral-ct-frame-description.md)
- [ADR-0229 - CT series geometry validation](../architecture/decisions/ADR-0229-ct-series-geometry-validation.md)
- [ADR-0230 - CT affine volume construction](../architecture/decisions/ADR-0230-ct-affine-volume-construction.md)
- [VOXELIA-ALG-0047 - CT series grouping and slice ordering](VOXELIA-ALG-0047-series-grouping-and-ordering.md)
- [VOXELIA-ALG-0048 - CT series geometry validation](VOXELIA-ALG-0048-series-geometry-validation.md)
