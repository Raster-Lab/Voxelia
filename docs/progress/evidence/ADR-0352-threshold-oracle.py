#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0057 range threshold binary64-v1.

Mirrors the frozen rules: exact widening of each admitted stored type to
binary64, inclusive range comparison, NaN never included and counted, the
declared padding sentinel excluded before comparison, mask bytes exactly 0
and 1. Prints every fixture's mask and non-finite count for the Swift tests.
"""

import math
import struct


def threshold(values, lower, upper, padding=None):
    mask = []
    non_finite = 0
    for value in values:
        if padding is not None and value == padding:
            mask.append(0)
            continue
        if isinstance(value, float) and math.isnan(value):
            non_finite += 1
            mask.append(0)
            continue
        mask.append(1 if lower <= value <= upper else 0)
    return mask, non_finite


NAN = float("nan")
INF = float("inf")

fixtures = [
    ("uint8", [0, 5, 10, 15, 20, 255], 5.0, 20.0, None),
    ("int16-padding", [-1024, -500, 0, 40, 400, 3071], -500.0, 400.0, -1024.0),
    ("int16-padding-inside", [-1024, -500, 0, 40, 400, 3071], -500.0, 400.0, 0.0),
    ("uint16", [0, 100, 4095, 65535], 100.0, 4095.0, None),
    ("float32", [0.5, 1.5, NAN, INF, -INF, 2.5], 1.0, 2.5, None),
]
for name, values, lower, upper, padding in fixtures:
    mask, non_finite = threshold(values, lower, upper, padding)
    print(f"{name}: mask={mask} nonFinite={non_finite}")

# Little-endian encodings for the Swift fixtures.
print("int16-bytes:", list(struct.pack("<6h", -1024, -500, 0, 40, 400, 3071)))
print("uint16-bytes:", list(struct.pack("<4H", 0, 100, 4095, 65535)))
print("float32-bytes:", list(struct.pack("<6f", 0.5, 1.5, NAN, INF, -INF, 2.5)))
