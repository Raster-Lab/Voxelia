---
document_id: "VOXELIA-ALG-0050"
title: "CT volume sample layout v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# CT volume sample layout v1

## Purpose

This specification defines `ct-volume-layout/v1`, the addressing contract that
makes direct-write frame transfer possible, selected by accepted
[`ADR-0232`](../architecture/decisions/ADR-0232-ct-volume-sample-layout.md).

`ADR-0230` decision 10 chose **direct-write into a caller-provided
destination**: the volume allocates once and each frame decodes straight into its
slice offset. A frame decoder can only do that if it knows exactly where its
slice begins and how a row advances. This specification is that knowledge, and
nothing else — it holds no samples and allocates nothing.

## What this specification is and is not for

This is **integer** arithmetic, which changes what needs freezing. There is no
rounding, and there is **no expression-order hazard**: for strictly positive
factors, any association of a product overflows exactly when the product
overflows, because every intermediate is bounded by the total. Restating a
floating-point-style "frozen order, no FMA" rule here would be boilerplate
claiming a risk that does not exist.

What does need freezing is the **order of the indices**, the **offset formula**,
and the **overflow boundaries**.

## The layout

A volume is `sliceCount` frames of `rows` by `columns` samples, all sharing one
scalar format. Addressing is **slice-major, then row-major within a slice**:

```text
samplesPerSlice = rows * columns
offset          = ((sliceIndex * samplesPerSlice) + (row * columns)) + column
```

Note `row * columns`, not `row * rows`. Those agree for every square frame and
differ for every other one, which is what fixture L7 exists to catch.

The byte offset of a sample is `offset * bytesPerSample`.

## Admission

Applied in this fixed order:

1. `rows` is at least one.
2. `columns` is at least one.
3. `sliceCount` is at least one.
4. `rows * columns * sliceCount` is representable as an `Int`.
5. That sample count times `bytesPerSample` is representable as an `Int`.

**Rule 5 is the one an implementation forgets.** A sample count can be
comfortably representable while its byte count is not; fixtures L4 and L6 are the
same extents differing only in the format's width, and one is admitted while the
other is not.

Index admission for an offset request:

```text
0 <= sliceIndex < sliceCount,  0 <= row < rows,  0 <= column < columns
```

**After admission, offset arithmetic cannot overflow**, and this is a discharge
rather than an assumption: the largest offset is
`((sliceCount - 1) * samplesPerSlice) + ((rows - 1) * columns) + (columns - 1)`,
which equals `sampleCount - 1`, and rule 4 already established that
`sampleCount` is representable. Every fixture asserts that identity, so a layout
that left gaps or overlapped slices would fail.

## Frozen fixtures

Computed by the independent oracle at
`docs/progress/evidence/ADR-0232-volume-layout-oracle.py`.

| Fixture | Extents | Bytes/sample | Result |
|---|---|---|---|
| L1 | 512 x 512 x 200 | 2 | `sampleCount` 52,428,800; `byteCount` 104,857,600 |
| L2 | 1 x 1 x 1 | 2 | `sampleCount` 1; `byteCount` 2; only offset 0 |
| L3 | `Int.max` x 2 x 1 | 2 | rejected: `sampleCountOverflow` |
| L4 | `Int.max` x 1 x 1 | 2 | rejected: `byteCountOverflow` |
| L5 | 3 x 5 x 2 | 2 | `sampleCount` 30; full offset table below |
| L6 | `Int.max` x 1 x 1 | 1 | **admitted**; `byteCount` = `Int.max` |

L5's complete offset table, which fixes the index order unambiguously:

```text
slice 0 row 0:   0   1   2   3   4
slice 0 row 1:   5   6   7   8   9
slice 0 row 2:  10  11  12  13  14
slice 1 row 0:  15  16  17  18  19
slice 1 row 1:  20  21  22  23  24
slice 1 row 2:  25  26  27  28  29
```

**L4 and L6 are the specification's sharpest pair.** They differ only in the
scalar format's width: at two bytes per sample the byte count overflows and the
layout is refused; at one byte it is exactly `Int.max` and admitted. An
implementation that checked only the sample count admits both.

**L7** is the transposition catcher: for a 3-row, 5-column frame,
`offset(slice 0, row 1, column 0)` is **5**. An implementation writing
`row * rows` yields 3, and the two agree only when `rows == columns` — so every
square fixture passes either way.

**L8** covers index admission: the last in-bounds element is admitted, and a
slice index, row or column at or above its extent is rejected, as is a negative
index.

## Conformance

An implementation conforms when it reproduces every admission decision and its
reason, every sample and byte count, L5's complete offset table, and the
`sampleCount - 1` identity for each admitted fixture.

## References

- [ADR-0227 - Neutral CT frame description](../architecture/decisions/ADR-0227-neutral-ct-frame-description.md)
- [ADR-0230 - CT affine volume construction](../architecture/decisions/ADR-0230-ct-affine-volume-construction.md)
- [ADR-0231 - DICOMKit supply-chain assessment](../architecture/decisions/ADR-0231-dicomkit-supply-chain-assessment.md)
- [ADR-0232 - CT volume sample layout](../architecture/decisions/ADR-0232-ct-volume-sample-layout.md)
