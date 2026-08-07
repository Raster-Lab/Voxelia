#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0063 squared Euclidean distance.

Deliberately BRUTE FORCE — for every sample, the minimum over all background
samples of the squared index-space offset — so the oracle shares no algorithm
with the implementation's separable parabola method. Exact integers
throughout.
"""

from itertools import product


def brute_force(mask, extents):
    rank = len(extents)
    coords = list(product(*[range(e) for e in reversed(extents)]))
    # coords are reversed-axis tuples; build linear index accessor.
    strides = [1] * rank
    for a in range(1, rank):
        strides[a] = strides[a - 1] * extents[a - 1]

    def linear(point):
        return sum(point[a] * strides[a] for a in range(rank))

    points = list(product(*[range(e) for e in extents]))
    background = [p for p in points if mask[linear(p)] == 0]
    if not background:
        return None
    out = [0] * len(mask)
    for p in points:
        if mask[linear(p)] == 0:
            out[linear(p)] = 0
        else:
            out[linear(p)] = min(
                sum((p[a] - b[a]) ** 2 for a in range(rank)) for b in background
            )
    return out


# 1 - the 1-D bar.
mask = [1, 1, 0, 1, 1, 1]
print("bar-1d:", brute_force(mask, [6, 1]))

# 2 - a 5x5 plane with one background sample at the centre.
plane = [1] * 25
plane[12] = 0
print("plane-centre:", brute_force(plane, [5, 5]))

# 3 - two background seeds compete.
two = [1] * 9
two[0] = 0
two[8] = 0
print("plane-corners:", brute_force(two, [3, 3]))

# 4 - a 3-D corner seed.
cube = [1] * 27
cube[0] = 0
print("cube-corner:", brute_force(cube, [3, 3, 3]))

# 5 - all background; and no background returns None (the typed rejection).
print("all-background:", brute_force([0, 0, 0, 0], [4, 1]))
print("no-background:", brute_force([1, 1, 1, 1], [4, 1]))
