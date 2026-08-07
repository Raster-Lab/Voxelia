#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0059 explicit-boundary convolution.

Mirrors the frozen rules: exact binary64 widening, kernel offsets iterated in
ascending lexicographic order (axis zero fastest) with left-associative
accumulation from zero, the two explicit boundary conditions, and ALG-0058's
output rule composed (integer ties-to-even then saturate counted; float32
narrowing with non-finite counted). Prints every fixture exactly.
"""

import struct


def convolve_1d(values, kernel, boundary, scalar_type):
    radius = len(kernel) // 2
    n = len(values)
    out = []
    saturated = 0
    for index in range(n):
        acc = 0.0
        for k in range(len(kernel)):
            offset = k - radius
            source = index + offset
            if 0 <= source < n:
                sample = float(values[source])
            elif boundary == "replicate":
                sample = float(values[0] if source < 0 else values[n - 1])
            else:  # zero
                sample = 0.0
            acc = acc + kernel[k] * sample
        if scalar_type == "float32":
            out.append(struct.unpack("<f", struct.pack("<f", acc))[0])
        else:
            lo, hi = {"uint8": (0, 255), "int16": (-32768, 32767),
                      "uint16": (0, 65535)}[scalar_type]
            rounded = round(acc)
            if rounded < lo:
                out.append(lo)
                saturated += 1
            elif rounded > hi:
                out.append(hi)
                saturated += 1
            else:
                out.append(rounded)
    return out, saturated


# 1 - uint8 smoothing [1, 2, 1] under both boundaries.
values = [10, 20, 30, 40, 50]
for boundary in ("replicate", "zero"):
    out, sat = convolve_1d(values, [1.0, 2.0, 1.0], boundary, "uint8")
    print(f"uint8-smooth-{boundary}: {out} saturated={sat}")

# 2 - int16 central difference [-1, 0, 1]: negatives representable, and the
# boundary choice changes the edges.
edge = [100, 200, 400, 800, 1600]
for boundary in ("replicate", "zero"):
    out, sat = convolve_1d(edge, [-1.0, 0.0, 1.0], boundary, "int16")
    print(f"int16-diff-{boundary}: {out} saturated={sat}")
print("int16-edge-bytes:", list(struct.pack("<5h", *edge)))

# 3 - uint8 saturation: the smoothing kernel overflows a bright ramp.
bright = [100, 200, 250, 200, 100]
out, sat = convolve_1d(bright, [1.0, 2.0, 1.0], "zero", "uint8")
print(f"uint8-saturate-zero: {out} saturated={sat}")

# 4 - float32 with a fractional kernel, exact binary fractions.
f = [1.0, 2.0, 4.0, 8.0]
out, sat = convolve_1d(f, [0.25, 0.5, 0.25], "replicate", "float32")
print(f"float32-quarter-replicate: {out}")
print("float32-f-bytes:", list(struct.pack("<4f", *f)))
print("float32-out-bytes:", list(struct.pack("<4f", *out)))
