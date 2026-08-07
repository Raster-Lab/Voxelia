#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0064 nearest label resampling.

Mirrors the frozen chain: the ALG-0055 target forward order, identity source
geometry so the inverse contributes exactly, then the ALG-0026
round-half-away-from-zero nearest selection per axis with out-of-image
positions publishing background zero. No interpolation exists anywhere: a
label value in the output is always a label value from the input.
"""

import math


def round_half_away(value):
    return int(math.floor(value + 0.5)) if value >= 0 else int(math.ceil(value - 0.5))


def resample(values, extents, target_extents, matrix):
    rank = len(extents)
    strides = [1] * rank
    for a in range(1, rank):
        strides[a] = strides[a - 1] * extents[a - 1]
    out = []
    padded = 0
    coords = [
        (j0, j1) for j1 in range(target_extents[1]) for j0 in range(target_extents[0])
    ]
    for j0, j1 in coords:
        world = []
        for r in range(2):
            m = matrix[4 * r : 4 * r + 4]
            world.append(((m[3] + m[0] * float(j0)) + m[1] * float(j1)) + 0.0)
        nearest = [round_half_away(w) for w in world]
        if all(0 <= nearest[a] < extents[a] for a in range(rank)):
            out.append(values[nearest[0] + nearest[1] * strides[1]])
        else:
            out.append(0)
            padded += 1
    return out, padded


I = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]

# 1 - identity on labels.
labels = [1, 2, 3, 4, 5, 6]
out, padded = resample(labels, [3, 2], [3, 2], I)
print(f"identity: {out} padded={padded}")

# 2 - upscale by half spacing: round-half-away picks the away sample at ties.
M2 = [0.5, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0]
out, padded = resample(labels, [3, 2], [6, 2], M2)
print(f"upscale-half: {out} padded={padded}")

# 3 - out-of-image positions publish background zero, counted.
M3 = [1.0, 0.0, 0.0, -1.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0]
out, padded = resample(labels, [3, 2], [3, 2], M3)
print(f"shift-left: {out} padded={padded}")

# 4 - the -0.5 tie rounds away from zero to -1: outside, background.
M4 = [1.0, 0.0, 0.0, -0.5,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0]
out, padded = resample(labels, [3, 2], [3, 2], M4)
print(f"tie-at-edge: {out} padded={padded}")
