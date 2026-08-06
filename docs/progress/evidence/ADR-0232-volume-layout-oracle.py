#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Independent oracle for VOXELIA-ALG-0050: CT volume sample layout.

This is integer arithmetic, and that changes what the oracle is for. There is no
rounding and no expression-order hazard: for strictly positive factors, any
association of a product overflows exactly when the product overflows, because
every intermediate is bounded by the total. So the oracle's job here is to fix
the layout's ORDER (which index is outermost), its OFFSET formula, and its
OVERFLOW boundaries -- not to pin a rounding mode.

Python integers are unbounded, so the 64-bit boundaries are checked explicitly
against Int64's range rather than inherited from the language.
"""

from __future__ import annotations

INT_MAX = 2**63 - 1
INT_MIN = -(2**63)


def fits(value: int) -> bool:
    return INT_MIN <= value <= INT_MAX


# --------------------------------------------------------------------------
# Admission.
# --------------------------------------------------------------------------


def admit(rows: int, columns: int, slice_count: int, bytes_per_sample: int):
    """Returns (ok, reason, sampleCount, byteCount).

    The rules, in fixed order:
      1. every extent is at least one;
      2. rows * columns * sliceCount is representable;
      3. that product times bytesPerSample is representable.

    Rule 3 is the one an implementation forgets. A sample count can be
    comfortably representable while its byte count is not.
    """
    if rows < 1:
        return (False, "nonPositiveRowCount", None, None)
    if columns < 1:
        return (False, "nonPositiveColumnCount", None, None)
    if slice_count < 1:
        return (False, "nonPositiveSliceCount", None, None)

    sample_count = rows * columns * slice_count
    if not fits(sample_count):
        return (False, "sampleCountOverflow", None, None)

    byte_count = sample_count * bytes_per_sample
    if not fits(byte_count):
        return (False, "byteCountOverflow", sample_count, None)

    return (True, None, sample_count, byte_count)


# --------------------------------------------------------------------------
# The offset.
# --------------------------------------------------------------------------


def offset(rows: int, columns: int, slice_index: int, row: int, column: int) -> int:
    """Slice-major, then row-major within a slice.

    Frozen as:
        samplesPerSlice = rows * columns
        offset = ((sliceIndex * samplesPerSlice) + (row * columns)) + column

    Note `row * columns`, not `row * rows`. Fixture L7 exists because those two
    agree for every square frame and disagree for every other one.
    """
    samples_per_slice = rows * columns
    return ((slice_index * samples_per_slice) + (row * columns)) + column


def in_bounds(rows, columns, slice_count, slice_index, row, column) -> bool:
    return (
        0 <= slice_index < slice_count and 0 <= row < rows and 0 <= column < columns
    )


# --------------------------------------------------------------------------
# Fixtures.
# --------------------------------------------------------------------------

FIXTURES = [
    ("L1 a typical CT volume, 512 x 512 x 200, int16", 512, 512, 200, 2),
    ("L2 the smallest possible volume", 1, 1, 1, 2),
    ("L3 the sample count overflows", INT_MAX, 2, 1, 2),
    ("L4 the sample count fits and the BYTE count overflows", INT_MAX, 1, 1, 2),
    ("L5 a non-square frame, 3 rows x 5 columns x 2 slices", 3, 5, 2, 2),
    ("L6 a single-byte format at the byte-count boundary", INT_MAX, 1, 1, 1),
]


def main() -> None:
    print("VOXELIA-ALG-0050 oracle - CT volume sample layout")
    print("=" * 78)
    for title, rows, columns, slices, bps in FIXTURES:
        ok, reason, sample_count, byte_count = admit(rows, columns, slices, bps)
        print()
        print(title)
        print(f"  rows={rows} columns={columns} slices={slices} bytesPerSample={bps}")
        if not ok:
            print(f"  REJECTED: {reason}")
            if sample_count is not None:
                print(f"    sampleCount would be: {sample_count}")
            continue
        print(f"  sampleCount: {sample_count}")
        print(f"  byteCount:   {byte_count}")
        last = offset(rows, columns, slices - 1, rows - 1, columns - 1)
        print(f"  last offset: {last}  (sampleCount - 1 = {sample_count - 1})")
        assert last == sample_count - 1, "the layout must exactly cover the volume"
        if rows <= 8 and columns <= 8 and slices <= 4:
            for k in range(slices):
                for j in range(rows):
                    line = " ".join(
                        f"{offset(rows, columns, k, j, i):3d}" for i in range(columns)
                    )
                    print(f"    slice {k} row {j}: {line}")

    print()
    print("L7 row/column transposition check on a non-square frame")
    rows, columns = 3, 5
    print(f"  rows={rows} columns={columns}")
    print(f"  offset(slice 0, row 1, column 0) = {offset(rows, columns, 0, 1, 0)}")
    print("    correct is 5 (row * columns). An implementation using row * rows")
    print(f"    would give {1 * rows}, and both agree only when rows == columns.")

    print()
    print("L8 bounds admission")
    rows, columns, slices = 3, 5, 2
    for label, k, j, i in [
        ("in bounds, last element", slices - 1, rows - 1, columns - 1),
        ("slice index too large", slices, 0, 0),
        ("row too large", 0, rows, 0),
        ("column too large", 0, 0, columns),
        ("negative slice index", -1, 0, 0),
    ]:
        ok = in_bounds(rows, columns, slices, k, j, i)
        print(f"  {label:24s} (k={k}, j={j}, i={i}): {'admitted' if ok else 'rejected'}")


if __name__ == "__main__":
    main()
