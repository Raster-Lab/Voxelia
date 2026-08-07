#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0062 connected components.

Mirrors the frozen rules: canonical scan (axis zero fastest) assigns labels in
first-encounter order starting at one, background stays zero, and the closed
connectivity vocabulary decides adjacency — faces; faces and edges (rank three
only); faces, edges and vertices.
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


def label(values, extents, connectivity):
    rank = len(extents)
    strides = [1] * rank
    for a in range(1, rank):
        strides[a] = strides[a - 1] * extents[a - 1]
    count = 1
    for e in extents:
        count *= e
    labels = [0] * count
    next_label = 1
    neigh = offsets(rank, connectivity)

    def coords(linear):
        out = []
        rem = linear
        for a in range(rank):
            out.append(rem % extents[a])
            rem //= extents[a]
        return out

    for linear in range(count):
        if values[linear] == 1 and labels[linear] == 0:
            labels[linear] = next_label
            queue = deque([linear])
            while queue:
                current = queue.popleft()
                base = coords(current)
                for delta in neigh:
                    ok = True
                    target = 0
                    for a in range(rank):
                        c = base[a] + delta[a]
                        if c < 0 or c >= extents[a]:
                            ok = False
                            break
                        target += c * strides[a]
                    if ok and values[target] == 1 and labels[target] == 0:
                        labels[target] = next_label
                        queue.append(target)
            next_label += 1
    return labels, next_label - 1


# 1 - the diagonal pair: the connectivity witness.
diag = [1, 0, 0, 1]
for conn in ("faces", "facesEdgesAndVertices"):
    labels, n = label(diag, [2, 2], conn)
    print(f"diagonal-{conn}: labels={labels} count={n}")

# 2 - first-encounter order: two bars, scan order fixes labels 1 and 2.
bars = [1, 1, 0, 0, 0,
        0, 0, 0, 1, 1]
labels, n = label(bars, [5, 2], "faces")
print(f"bars-faces: labels={labels} count={n}")

# 3 - three dimensions: an edge-touching pair separates under faces,
# joins under facesAndEdges.
cube = [0] * 8
cube[0] = 1  # (0,0,0)
cube[6] = 1  # (0,1,1) - shares an edge direction with (0,0,0)? offsets (0,1,1)
for conn in ("faces", "facesAndEdges", "facesEdgesAndVertices"):
    labels, n = label(cube, [2, 2, 2], conn)
    print(f"cube-{conn}: labels={labels} count={n}")

# 4 - the L shape is one component under faces.
ell = [1, 0, 0,
       1, 0, 0,
       1, 1, 1]
labels, n = label(ell, [3, 3], "faces")
print(f"ell-faces: labels={labels} count={n}")
