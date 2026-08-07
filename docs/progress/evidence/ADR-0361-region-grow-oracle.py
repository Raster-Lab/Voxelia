#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0065 region growing.

Mirrors the frozen rules: a sample is included exactly when it is in the
inclusive threshold range (padding excluded first, NaN never in range) and
connected to an in-range seed through in-range samples under the chosen
connectivity. An out-of-range seed founds nothing, deliberately not an error.
"""

from collections import deque
from itertools import product


def offsets(rank, connectivity):
    out = []
    for delta in product((-1, 0, 1), repeat=rank):
        if all(d == 0 for d in delta):
            continue
        manhattan = sum(abs(d) for d in delta)
        if connectivity == "faces" and manhattan != 1:
            continue
        if connectivity == "facesAndEdges" and manhattan > 2:
            continue
        out.append(delta)
    return out


def grow(values, extents, seeds, lower, upper, connectivity, padding=None):
    rank = len(extents)
    strides = [1] * rank
    for a in range(1, rank):
        strides[a] = strides[a - 1] * extents[a - 1]

    def linear(point):
        return sum(point[a] * strides[a] for a in range(rank))

    def in_range(point):
        v = values[linear(point)]
        if padding is not None and v == padding:
            return False
        if isinstance(v, float) and v != v:
            return False
        return lower <= v <= upper

    mask = [0] * len(values)
    queue = deque()
    for seed in seeds:
        if in_range(seed) and mask[linear(seed)] == 0:
            mask[linear(seed)] = 1
            queue.append(seed)
    neigh = offsets(rank, connectivity)
    while queue:
        current = queue.popleft()
        for delta in neigh:
            candidate = tuple(current[a] + delta[a] for a in range(rank))
            if any(c < 0 or c >= extents[a] for a, c in enumerate(candidate)):
                continue
            if mask[linear(candidate)] == 0 and in_range(candidate):
                mask[linear(candidate)] = 1
                queue.append(candidate)
    return mask


# 1 - two plateaus separated by an out-of-range gap: the seed's plateau only.
bar = [100, 110, -1000, 120, 130, 140]
print("bar-seeded-left:", grow(bar, [6, 1], [(1, 0)], 50, 200, "faces"))
print("bar-seeded-right:", grow(bar, [6, 1], [(4, 0)], 50, 200, "faces"))

# 2 - an out-of-range seed founds nothing.
print("seed-out-of-range:", grow(bar, [6, 1], [(2, 0)], 50, 200, "faces"))

# 3 - the diagonal bridge crosses only under vertex connectivity.
plane = [100, -1000, -1000,
         -1000, 100, -1000,
         -1000, -1000, 100]
print("diag-faces:", grow(plane, [3, 3], [(0, 0)], 50, 200, "faces"))
print("diag-vertices:", grow(plane, [3, 3], [(0, 0)], 50, 200,
                             "facesEdgesAndVertices"))

# 4 - a padding sentinel inside the range still blocks growth.
padded = [100, 0, 110, 120]
print("padding-blocks:", grow(padded, [4, 1], [(0, 0)], -10, 200, "faces",
                              padding=0))
print("no-padding-flows:", grow(padded, [4, 1], [(0, 0)], -10, 200, "faces"))
