#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0073 registration-quality/binary64-v1.

Python floats are IEEE-754 binary64; every expression below is written
in the specification's frozen order, so the printed values are the exact
bit patterns the Swift implementation must reproduce.
"""


def normalised_zero(value):
    return 0.0 if value == 0 else value


def residuals(matrix, moving, fixed):
    per = []
    total = 0.0
    for (mx, my, mz), (fx, fy, fz) in zip(moving, fixed):
        px = ((matrix[0] * mx + matrix[1] * my) + matrix[2] * mz) + matrix[3]
        py = ((matrix[4] * mx + matrix[5] * my) + matrix[6] * mz) + matrix[7]
        pz = ((matrix[8] * mx + matrix[9] * my) + matrix[10] * mz) + matrix[11]
        dx = fx - px
        dy = fy - py
        dz = fz - pz
        squared = ((dx * dx + dy * dy)) + dz * dz
        residual = squared**0.5
        per.append(normalised_zero(residual))
        total = total + squared
    rms = normalised_zero((total / len(per)) ** 0.5)
    maximum = per[0]
    for r in per[1:]:
        if r > maximum:
            maximum = r
    return per, rms, maximum


def report(label, matrix, moving, fixed):
    per, rms, maximum = residuals(matrix, moving, fixed)
    print(f"{label}: residuals = {per}")
    print(f"  hex = {[r.hex() for r in per]}")
    print(f"  rms = {rms} ({rms.hex()}), max = {maximum} ({maximum.hex()})")


# Fixture A: the exact affine diag(2,3,4) + t(1,2,3) over consistent
# correspondences — every residual is exactly zero.
affine = [2, 0, 0, 1, 0, 3, 0, 2, 0, 0, 4, 3]
report("A", affine,
       [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 1)],
       [(1, 2, 3), (3, 2, 3), (1, 5, 3), (3, 5, 7)])

# Fixture B: the permutation rigid motion plus t(1,2,3) with perturbed
# fixed points — residuals, RMS and maximum bit-pinned.
rigid = [0, 0, 1, 1, 1, 0, 0, 2, 0, 1, 0, 3]
report("B", rigid,
       [(0, 0, 0), (1, 0, 0), (0, 1, 0)],
       [(1, 2, 3), (1.5, 3, 3), (1, 2, 4.25)])
