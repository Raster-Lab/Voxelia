#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0055 grid resampling binary64-v1.

Mirrors the frozen chain in Python binary64: the target forward evaluation
(the VOXELIA-ALG-0017 request order extended by the third slot term), the
source inverse fixed to the identity so the ADR-0138 composition contributes
exactly, and the VOXELIA-ALG-0017 sampling authority — support test, clamped
taps, trilinear reduction, ties-to-even rounding, exact zero padding.

The source volume for every fixture is the oblique specification volume:
extents (3, 3, 3), stored value 2*i0 + 6*i1 + 18*i2, identity geometry.
Distinct axis coefficients make a transposed axis visible.
"""

import math

EXTENTS = (3, 3, 3)
BYTES = [0] * 27
for i2 in range(3):
    for i1 in range(3):
        for i0 in range(3):
            BYTES[i0 + 3 * (i1 + 3 * i2)] = 2 * i0 + 6 * i1 + 18 * i2


def supports(continuous):
    for axis in range(3):
        upper = float(EXTENTS[axis]) - 0.5
        if not (continuous[axis] >= -0.5 and continuous[axis] <= upper):
            return False
    return True


def axis_taps(continuous, count):
    floored = math.floor(continuous)
    weight = continuous - floored
    index = int(floored)
    lower = min(count - 1, max(0, index))
    upper = min(count - 1, max(0, index + 1))
    return lower, upper, weight


def sample(continuous):
    if not supports(continuous):
        return 0
    a = axis_taps(continuous[0], EXTENTS[0])
    b = axis_taps(continuous[1], EXTENTS[1])
    d = axis_taps(continuous[2], EXTENTS[2])

    def value(x, y, z):
        return float(BYTES[x + 3 * (y + 3 * z)])

    def across_x(y, z):
        return (value(a[0], y, z) * (1.0 - a[2])) + (value(a[1], y, z) * a[2])

    def across_xy(z):
        return (across_x(b[0], z) * (1.0 - b[2])) + (across_x(b[1], z) * b[2])

    sampled = (across_xy(d[0]) * (1.0 - d[2])) + (across_xy(d[1]) * d[2])
    # Ties-to-even, then the display clamp.
    rounded = round(sampled)  # Python 3 round is ties-to-even on floats.
    return int(min(255, max(0, rounded)))


def forward(matrix, j):
    out = []
    for r in range(3):
        m = matrix[4 * r : 4 * r + 4]
        w = ((m[3] + m[0] * j[0]) + m[1] * j[1]) + m[2] * j[2]
        out.append(w)
    return out


def resample(target_extents, matrix):
    output = []
    padded = 0
    for j2 in range(target_extents[2]):
        for j1 in range(target_extents[1]):
            for j0 in range(target_extents[0]):
                # Identity source geometry: continuous == world exactly.
                continuous = forward(matrix, (float(j0), float(j1), float(j2)))
                if not supports(continuous):
                    padded += 1
                output.append(sample(continuous))
    return output, padded


def show(name, target_extents, matrix):
    output, padded = resample(target_extents, matrix)
    print(f"{name}: padded={padded} bytes={output}")


I = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]

# 1 - identity target grid: the resample is the identity on the bytes.
show("fixture-1", (3, 3, 3), I)

# 2 - coarser target grid: spacing 2, origin at (0.5, 0.5, 0.5). The upper
# target centres sit exactly on the inclusive support edge 2.5 and replicate
# the border through the clamped taps.
M2 = [2.0, 0.0, 0.0, 0.5,
      0.0, 2.0, 0.0, 0.5,
      0.0, 0.0, 2.0, 0.5,
      0.0, 0.0, 0.0, 1.0]
show("fixture-2", (2, 2, 2), M2)

# 3 - axis-swapping target (x and z exchanged): the output is the transposed
# volume, visible because the ramp coefficients differ per axis.
M3 = [0.0, 0.0, 1.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0]
show("fixture-3", (3, 3, 3), M3)

# 4 - padding: the first target sample maps outside the support and pads
# with exact zero; the second replicates the lower border; the third rounds
# 25.5 to 26 under ties-to-even.
M4 = [1.0, 0.0, 0.0, -1.25,
      0.0, 1.0, 0.0, 1.0,
      0.0, 0.0, 1.0, 1.0,
      0.0, 0.0, 0.0, 1.0]
show("fixture-4", (3, 1, 1), M4)

# 5 - the support edge is inclusive at exactly 2.5 and exclusive just above.
M5a = [1.0, 0.0, 0.0, 2.5,
       0.0, 1.0, 0.0, 1.0,
       0.0, 0.0, 1.0, 1.0,
       0.0, 0.0, 0.0, 1.0]
show("fixture-5a", (1, 1, 1), M5a)
M5b = [1.0, 0.0, 0.0, 2.5000000000000004,
       0.0, 1.0, 0.0, 1.0,
       0.0, 0.0, 1.0, 1.0,
       0.0, 0.0, 0.0, 1.0]
show("fixture-5b", (1, 1, 1), M5b)

# 6 - quantisation ties resolve to even in both directions: 0.5 -> 0 and
# 1.5 -> 2.
M6 = [0.5, 0.0, 0.0, 0.25,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0]
show("fixture-6", (2, 1, 1), M6)

# Budget arithmetic recorded for the admission fixtures: the total-sample
# ceiling is exactly 1024 cubed, which 16384 x 16384 x 4 meets exactly and
# 16384 x 16384 x 5 exceeds.
print(f"budget: ceiling={1024**3} at-ceiling={16384 * 16384 * 4} "
      f"over={16384 * 16384 * 5}")
