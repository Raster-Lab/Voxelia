---
document_id: "VOXELIA-ALG-0053"
title: "Physical-coordinate ramp binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Physical-coordinate ramp binary64-v1

## Purpose

Plan §55.2 specifies an analytical phantom whose value is a function of the **patient**
coordinate rather than the sample index:

```text
value(patientX, patientY, patientZ) = patientX + 2patientY - 0.5patientZ
```

Its named purposes are affine geometry, oblique stack and patient-plane reconstruction, so
the phantom is sampled through an arbitrary — including oblique — index-to-patient affine.

`ADR-0293` numeric boundary 2 required this specification, and it is the one boundary in the
analytical phantom arc where a specification is genuinely needed. `VOXELIA-ALG-0050`'s
sample layout and the §55.1 and §55.4 phantoms are exact integer constructions with nothing
to freeze; this one is a binary64 sum whose association is observable in the published
output, and it must then be quantised into a stored integer.

It is the model `physical-coordinate-ramp/binary64-v1`.

## Conventions inherited, not restated

`Matrix4x4Double` stores sixteen elements in row-major order, so row `r` column `c` is
`elements[4r + c]`. Voxelia multiplies homogeneous **column** vectors, so translation
occupies indices `3`, `7` and `11`.

Affine admission is `VOXELIA-ALG-0052`'s: elements `12`, `13`, `14` exactly zero and element
`15` exactly one, by exact equality and not by a tolerance.

Rounding is `VOXELIA-ALG-0002`'s: IEEE-754 `roundTiesToEven` to an integral binary64,
`FloatingPoint.rounded(.toNearestOrEven)`.

## Step one: index to patient

The index triple `(i, j, k)` maps to a patient coordinate under **`ADR-0138`'s frozen
forward evaluation**, the same one the pick resolver applies: the translation first, then the
products in ascending slot order, accumulated left to right, with no fused multiply-add.

```text
p[r] = elements[4r + 3]
p[r] = p[r] + elements[4r + 0] * i
p[r] = p[r] + elements[4r + 1] * j
p[r] = p[r] + elements[4r + 2] * k
```

for `r` in `0, 1, 2`. Slot `s` takes index axis `s`, which is the identity-axis-mapping case
of the rule the pick resolver applies through a geometry's own mapping.

This step is **composed, not restated**. Voxelia has two frozen affine accumulations that
differ in where the translation lands — `ADR-0138`'s forward evaluation adds it **first**,
and `VOXELIA-ALG-0052`'s composition adds it **last** — so naming which one applies is part
of the specification rather than a detail.

## Step two: the ramp

```text
scaledY = 2.0 * p[1]
scaledZ = 0.5 * p[2]
r       = (p[0] + scaledY) - scaledZ
```

The two additions are **left-associative in the order the plan writes the formula**, and
there is **no fused multiply-add**.

Both scalings are exact for every finite operand whose product neither overflows nor becomes
subnormal, because two and one half are powers of two. So under normal operation the only
rounding in the ramp itself is in the two additions, and every other difference an
implementation could show comes from step one.

**The association is observable in the published output, not merely in the bits.** Fixture D
below contains two samples where a right-associated `p[0] + (scaledY - scaledZ)` and a
reordered `(p[0] - scaledZ) + scaledY` produce a different **integer** after rounding. That
is why this specification exists.

## Step three: quantisation

```text
q = r.rounded(.toNearestOrEven)
```

The sample is then admitted only if `-32768 <= q <= 32767`, and a sample outside that range
is **refused**.

**This departs from `VOXELIA-ALG-0002`, which clamps, and the departure is deliberate.**
That model clamps because a display value beyond the window is legitimately saturated —
saturation is what the window and level model means. Here a value outside `int16` means the
supplied geometry produced a sample the volume cannot hold, and clamping would publish an
expected value that is not the ramp's value. A phantom that misreports its own contents is
worse than one that refuses to exist, and it is the same reasoning `ADR-0294` applied to the
§55.1 ramp's range.

## Determinism and failure classification

Every sample is a pure function of the sixteen matrix elements and the index triple, so
repeated evaluation is bit-identical on every conforming IEEE-754 binary64 implementation.

A non-affine matrix and an unrepresentable sample are typed refusals, not clamps and not
sentinel values.

## Conformance fixtures

Independently computed in binary64 with half-to-even rounding. Every sequence is in
`VOXELIA-ALG-0050` order: slice-major, then row-major within a slice, column varying fastest.

### Fixture A — axis-aligned, and ties in both directions

Spacing `(0.5, 0.5, 2.0)` with patient origin `(-1, 2, 4)`; extents `4 x 3 x 3`.

```text
rows: [0.5, 0, 0, -1]  [0, 0.5, 0, 2]  [0, 0, 2, 4]  [0, 0, 0, 1]
```

The ramp reduces exactly to `1 + 0.5i + j - k`, so half-integer values occur at every odd
`i` and the rounding rule is directly observable:

```text
[ 1,  2,  2,  2,   2,  2,  3,  4,   3,  4,  4,  4,
  0,  0,  1,  2,   1,  2,  2,  2,   2,  2,  3,  4,
 -1,  0,  0,  0,   0,  0,  1,  2,   1,  2,  2,  2]
```

The first row is `1.0, 1.5, 2.0, 2.5` before rounding and the second `2.0, 2.5, 3.0, 3.5`.
A ties-away-from-zero implementation would publish `1, 2, 2, 3` and `2, 3, 3, 4`.

### Fixture B — a dyadic oblique shear, exact throughout

```text
rows: [1, 0.5, 0, 0]  [0, 1, 0.5, 0]  [0.25, 0, 1, 0]  [0, 0, 0, 1]
```

Extents `3 x 3 x 3`. Every element is a dyadic rational, so the whole evaluation is exact and
reduces to `0.875i + 2.5j + 0.5k`:

```text
[ 0,  1,  2,   2,  3,  4,   5,  6,  7,
  0,  1,  2,   3,  4,  5,   6,  6,  7,
  1,  2,  3,   4,  4,  5,   6,  7,  8]
```

The off-diagonal slots are load-bearing here: the shear coefficients were chosen so no axis
cancels out of the reduced form, which an earlier choice of `0.25` in slot `[1][2]` did.

### Fixture C — a rotation, where the arithmetic is no longer exact

A rotation about the patient Z axis with three-four-five direction cosines:

```text
rows: [0.6, -0.8, 0, 0]  [0.8, 0.6, 0, 0]  [0, 0, 1.0, 0]  [0, 0, 0, 1]
```

Extents `3 x 3 x 3`. Neither `0.6` nor `0.8` is representable in binary64, so this fixture
measures determinism rather than exactness:

```text
[ 0,  2,  4,   0,  3,  5,   1,  3,  5,
  0,  2,  4,   0,  2,  4,   0,  2,  5,
 -1,  1,  3,  -1,  2,  4,   0,  2,  4]
```

Two samples land exactly on a half: `(0, 0, 1)` evaluates to `-0.5` and `(1, 2, 1)` to `2.5`,
and both round to an even integer. A ties-away implementation would publish `-1` and `3`.

### Fixture D — where the association changes the published integer

The same rotation with a non-dyadic slice spacing of `0.3`:

```text
rows: [0.6, -0.8, 0, 0]  [0.8, 0.6, 0, 0]  [0, 0, 0.3, 0]  [0, 0, 0, 1]
```

The `k = 2` plane of a `6 x 6 x 6` volume:

```text
[ 0,  2,  4,  6,  8, 11,
  0,  2,  5,  7,  9, 11,
  0,  3,  5,  7,  9, 12,
  1,  3,  5,  8, 10, 12,
  1,  4,  6,  8, 10, 12,
  2,  4,  6,  8, 10, 13]
```

Two samples in this plane discriminate the frozen association:

| Index | Frozen | Right-associated | Reordered |
|---|---|---|---|
| `(2, 1, 2)` | `4.500000000000001` → `5` | `4.5` → `4` | `4.5` → `4` |
| `(3, 3, 2)` | `7.5` → `8` | `7.499999999999999` → `7` | `7.5` → `8` |

A fused final term produced no bit difference on any of these four fixtures. That is a
measurement of these fixtures, not a claim about the operation, and the no-fused-multiply-add
rule stands as this project's standing discipline regardless.

## References

- [ADR-0138 - World to index mapping](../architecture/decisions/ADR-0138-world-to-index-mapping.md)
- [ADR-0293 - Open the analytical phantom arc](../architecture/decisions/ADR-0293-open-the-analytical-phantom-arc.md)
- [VOXELIA-ALG-0002 - Window level linear](VOXELIA-ALG-0002-window-level-linear.md)
- [VOXELIA-ALG-0050 - Volume sample layout](VOXELIA-ALG-0050-volume-sample-layout.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](VOXELIA-ALG-0052-affine-composition-and-directions.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
