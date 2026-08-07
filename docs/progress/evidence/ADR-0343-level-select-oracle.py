#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0056 level selection downsampling.

Pure integer selection plus one frozen matrix scaling: level sample j selects
the level-zero stored value at index j*f per axis, level extents are
ceil(e / f), and the level geometry scales the index-step columns by the
factors while translation and the bottom row travel verbatim.

Fixture volume: extents (5, 4, 3), stored value i0 + 5*i1 + 20*i2 — the
first-useful-image fixture, distinct axis strides.
"""

VOLUME = (5, 4, 3)
VALUE = lambda i0, i1, i2: i0 + 5 * i1 + 20 * i2  # noqa: E731


def level_extents(factors):
    return tuple((VOLUME[a] + factors[a] - 1) // factors[a] for a in range(3))


def select(factors):
    extents = level_extents(factors)
    out = []
    for j2 in range(extents[2]):
        for j1 in range(extents[1]):
            for j0 in range(extents[0]):
                out.append(VALUE(j0 * factors[0], j1 * factors[1], j2 * factors[2]))
    return extents, out


for factors in [(2, 2, 2), (1, 2, 1), (4, 4, 4), (8, 8, 8)]:
    extents, bytes_ = select(factors)
    print(f"select{factors}: extents={extents} bytes={bytes_}")

# The frozen geometry scaling: scaled[4r+c] = m[4r+c] * factor[c] for the
# three index-step columns; translation column and bottom row verbatim.
M = [0.5, 0.0, 0.0, 10.5,
     0.0, 0.25, 0.0, -20.25,
     0.0, 0.0, 2.0, 0.125,
     0.0, 0.0, 0.0, 1.0]


def scale(matrix, factors):
    out = list(matrix)
    for r in range(3):
        for c in range(3):
            out[4 * r + c] = matrix[4 * r + c] * float(factors[c])
    return out


print(f"scaled-diag(2,2,2): {scale(M, (2, 2, 2))!r}")

# Exactness witness for power-of-two factors: the scaled-matrix route and the
# scaled-index route agree bit-exactly, because element * 2^k is exact.
R = [0.0, -0.25, 0.0, 1.0,
     0.5, 0.0, 0.0, 2.0,
     0.0, 0.0, 2.0, 3.0,
     0.0, 0.0, 0.0, 1.0]
S = scale(R, (2, 2, 2))
for j in [(0.0, 0.0, 0.0), (1.0, 2.0, 1.0)]:
    via_scaled = [
        (((S[4 * r + 3] + S[4 * r] * j[0]) + S[4 * r + 1] * j[1]) + S[4 * r + 2] * j[2])
        for r in range(3)
    ]
    doubled = tuple(2.0 * v for v in j)
    via_indices = [
        (((R[4 * r + 3] + R[4 * r] * doubled[0]) + R[4 * r + 1] * doubled[1])
         + R[4 * r + 2] * doubled[2])
        for r in range(3)
    ]
    assert via_scaled == via_indices, (via_scaled, via_indices)
print("power-of-two-equivalence: exact")
