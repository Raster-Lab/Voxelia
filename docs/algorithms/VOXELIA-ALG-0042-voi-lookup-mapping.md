---
document_id: "VOXELIA-ALG-0042"
title: "VOI lookup display mapping binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# VOI lookup display mapping binary64-v1

## Purpose

This specification defines `voi-lookup-mapping/binary64-v1`, the deterministic
reference selected by accepted
[`ADR-0210`](../architecture/decisions/ADR-0210-voi-lookup-design.md). It maps
one value-of-interest input to the eight-bit display range through a lookup
table, as the tabular alternative to the linear window
[`VOXELIA-ALG-0002`](VOXELIA-ALG-0002-window-level-linear.md) froze.

## This is the VOI stage, not the modality stage

[`VOXELIA-ALG-0004`](VOXELIA-ALG-0004-lookup-table-value-transform.md) already
defines a table mapping, and it is **not** this one. That model is explicitly
"the DICOM-derived table form of the **modality** mapping": it maps a stored
integer to a *real* value in an optional measurement unit, and its output then
feeds the window. This model sits where the window sits, one stage later: its
input is the value the modality stage produced, and its output is a *display*
value with no unit and no physical meaning.

The two also differ in their input domain. `ALG-0004` indexes on a stored
integer. This model indexes on a binary64 value, because the modality stage can
produce a fractional one — which is exactly why an index-derivation rule has to
be frozen here and could not simply be inherited.

## The frozen rule

```text
1. reject an empty table
2. reject a NaN input
3. rounded = roundHalfAwayFromZero(value)          [saturating]
4. index   = clamp(rounded - firstMappedValue, 0, n - 1)
5. output  = clamp(roundTiesToEven(values[index]), 0, 255)
```

## Two jobs, two accepted rounding rules — deliberately

Step 3 rounds **half away from zero**; step 5 rounds **ties to even**. That is
not an inconsistency, it is each stage using the rule the project already
accepted *for that job*:

- Selecting a table index is the job
  [`VOXELIA-ALG-0026`](VOXELIA-ALG-0026-segmentation-mask-sampling.md) froze
  round-half-away-from-zero for, and
  [`VOXELIA-ALG-0037`](VOXELIA-ALG-0037-surface-scalar-colour-map.md) already
  reused it for exactly this — choosing an entry in a colour table.
- Quantising a display output is the job `ALG-0002` froze round-ties-to-even
  for, in the very stage this model replaces.

Choosing one rule for both would have meant overruling an accepted rule in one
of the two jobs. The registered `index-half-away-up` fixture pins a case where
the two rules disagree: an input of `12.5` against an origin of `10` selects
entry `3`, where ties-to-even would have selected entry `2`.

### An inherited quirk, registered rather than corrected

The accepted round-half-away rule is `floor(x + 0.5)` for a non-negative `x`.
For the double immediately below one half, `0.49999999999999994 + 0.5` is
exactly representable as `1.0` in binary64, so the rule yields one rather than
zero. This model inherits that behaviour **verbatim** and registers it in the
`index-just-below-half` fixture. Correcting it here would create a second,
divergent rounding rule in the project, which is worse than a known quirk that
is written down. It is observable only near zero: at magnitude ten the
neighbouring doubles are too far apart to express the difference at all.

## Out of range clamps at both ends

Values below the first mapped value take the first entry and values beyond the
table take the last, which is the DICOM-derived rule `ALG-0004` already froze.
The subtraction in step 4 follows that record's overflow reasoning unchanged:
an overflowing difference lies beyond the representable range on the side
opposite the origin's sign, so it clamps to that same end. The registered
`origin-at-int64-min` and `origin-at-int64-max` fixtures exercise both.

## Infinity clamps; only NaN is rejected

An infinite input is **not** a failure. It compares beyond an end of the table
and clamps there, which is total and needs no branch of its own. Only NaN is
undecidable, because it compares false against everything, and a non-finite
input is genuinely reachable: a linear modality transform with a finite scale
and a finite stored value can still overflow to infinity.

## Table outputs are display values

The table's entries are display values, not physical ones, so no measurement
unit travels with them and nothing is normalised. An entry outside `0...255`
saturates, and the registered `output-clamp-low` and `output-clamp-high`
fixtures pin both ends. The `output-ties-even-down`, `output-ties-even-up` and
`output-ties-even-stay` fixtures pin the quantisation rule at `0.5`, `1.5` and
`2.5`.

## Determinism and failure classification

The mapping is a pure function of the input and the table: repeated evaluation
is bit-identical. The failure family is exactly two payload-free cases,
`emptyTable` and `valueNotRepresentable`. There is no cancellation checkpoint:
one lookup is `O(1)`.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0210-voi-lookup-oracle.py`](../progress/evidence/ADR-0210-voi-lookup-oracle.py).
It records twenty-three fixtures: an exact hit; both out-of-range ends; both
table extremes; the index rule where it disagrees with ties-to-even; the
inherited just-below-half quirk; a negative origin at and inside a half step;
both infinities; a huge finite value; NaN; both signed-integer origin extremes;
both output clamps; three output-quantisation ties; a single-entry table; and
an empty table.

The registered output is:

```text
fixtureSHA256=a88c27632f2f73645243ca5dda7b365665a8e80f79c9877a50304664d48d34c7
outputSHA256=e8f03a49b1f9fdc024827f77ebbc489628f453acd11168de60ea7de3d35781f8
fixtures=23 mapped=21 rejected=2
index=half-away-from-zero output=ties-to-even range=0..255
outOfRange=clamped infinite=clamped nan=rejected
```

## Complexity and exclusions

`O(1)` per sample.

Interpolated VOI lookup between entries, multiple VOI LUT sequences and their
selection, the presentation LUT stage after VOI, sigmoid and other non-linear
VOI functions, output bit depths other than eight, and any published artefact
remain separate contracts.

## References

- [ADR-0065 - Window-level operation](../architecture/decisions/ADR-0065-window-level-operation.md)
- [ADR-0069 - Lookup-table composition](../architecture/decisions/ADR-0069-lookup-table-composition.md)
- [ADR-0208 - Colour and overlay arc](../architecture/decisions/ADR-0208-colour-and-overlay-arc.md)
- [ADR-0210 - VOI lookup design](../architecture/decisions/ADR-0210-voi-lookup-design.md)
- [VOXELIA-ALG-0002 - Window-level linear mapping](VOXELIA-ALG-0002-window-level-linear.md)
- [VOXELIA-ALG-0004 - Lookup-table stored-to-real value mapping](VOXELIA-ALG-0004-lookup-table-value-transform.md)
- [VOXELIA-ALG-0026 - Segmentation mask sampling](VOXELIA-ALG-0026-segmentation-mask-sampling.md)
- [VOXELIA-ALG-0037 - Surface scalar colour map](VOXELIA-ALG-0037-surface-scalar-colour-map.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
