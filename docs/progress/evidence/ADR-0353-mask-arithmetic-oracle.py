#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0058 mask application and arithmetic.

Mirrors the frozen rules: mask application keeps a sample verbatim under mask
one and substitutes the exactly-representable fill under mask zero; arithmetic
computes in binary64, rounds integer results ties-to-even, saturates to the
type range counting each saturation, and stores float32 non-finite results
verbatim counting each. Prints every fixture with its counts and the
little-endian encodings for the Swift tests.
"""

import math
import struct

TYPE_RANGES = {
    "uint8": (0, 255),
    "int16": (-32768, 32767),
    "uint16": (0, 65535),
}


def round_ties_even(value):
    return int(math.remainder(value, 1.0).__abs__() * 0 + round(value / 1.0))  # noqa


def mask_apply(values, mask, fill):
    return [v if m == 1 else fill for v, m in zip(values, mask)]


def arithmetic(kind, left, right, scalar_type, operator):
    out = []
    saturated = 0
    non_finite = 0
    for a, b in zip(left, right):
        if operator == "add":
            r = float(a) + float(b)
        elif operator == "subtract":
            r = float(a) - float(b)
        else:
            r = float(a) * float(b)
        if scalar_type == "float32":
            try:
                packed = struct.unpack("<f", struct.pack("<f", r))[0]
            except OverflowError:
                # Rounding a too-large binary64 to binary32 yields the
                # signed infinity; Python's pack refuses instead.
                packed = math.copysign(math.inf, r)
            if not math.isfinite(packed):
                non_finite += 1
            out.append(packed)
        else:
            lo, hi = TYPE_RANGES[scalar_type]
            # Python round() is ties-to-even on floats.
            rounded = round(r)
            if rounded < lo:
                out.append(lo)
                saturated += 1
            elif rounded > hi:
                out.append(hi)
                saturated += 1
            else:
                out.append(rounded)
    return out, saturated, non_finite


# 1 - mask application on int16, fill -1024.
values = [-500, 0, 40, 400, 3071, 100]
mask = [1, 0, 1, 0, 1, 0]
print("mask-apply:", mask_apply(values, mask, -1024))
print("mask-values-bytes:", list(struct.pack("<6h", *values)))
print("mask-bytes:", mask)

# 2 - int16 add with saturation both ways.
a = [30000, -30000, 100, 0]
b = [10000, -10000, 28, 0]
out, sat, nf = arithmetic("ii", a, b, "int16", "add")
print(f"int16-add: {out} saturated={sat}")
print("int16-a-bytes:", list(struct.pack("<4h", *a)))
print("int16-b-bytes:", list(struct.pack("<4h", *b)))

# 3 - uint8 multiply saturates high.
a8 = [20, 3, 0, 15]
b8 = [20, 4, 9, 17]
out, sat, nf = arithmetic("ii", a8, b8, "uint8", "multiply")
print(f"uint8-multiply: {out} saturated={sat}")

# 4 - int16 scalar add with a fractional scalar: ties-to-even then range.
s = [10, 11, 32767, -5]
out, sat, nf = arithmetic("is", s, [100.5] * 4, "int16", "add")
print(f"int16-scalar-add-100.5: {out} saturated={sat}")
print("int16-scalar-bytes:", list(struct.pack("<4h", *s)))

# 5 - float32 add producing +inf, counted, stored verbatim.
f = [3e38, 1.5, -2.5, 0.0]
g = [3e38, 2.5, 0.5, 0.0]
out, sat, nf = arithmetic("ff", f, g, "float32", "add")
print(f"float32-add: {out} nonFinite={nf}")
print("float32-f-bytes:", list(struct.pack("<4f", *f)))
print("float32-g-bytes:", list(struct.pack("<4f", *g)))
print("float32-out-bytes:", list(b"".join(
    struct.pack("<f", v) if math.isfinite(v)
    else (b"\x00\x00\x80\x7f" if v > 0 else b"\x00\x00\x80\xff")
    for v in out
)))
