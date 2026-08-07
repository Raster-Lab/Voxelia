#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0071 landmark-rigid/binary64-v1.

Python floats are IEEE-754 binary64; the centring, cross-covariance,
Horn matrix, fixed-sweep cyclic Jacobi and translation below are written
in the specification's frozen order, so the printed values are the exact
bit patterns the Swift implementation must reproduce. The quaternion
canonicalisation and rotation derivation replicate the ALG-0068 oracle.
"""

SWEEPS = 30
PAIRS = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]


def normalised_zero(value):
    return 0.0 if value == 0 else value


def canonical_unit(w, x, y, z):
    norm_squared = ((w * w + x * x) + y * y) + z * z
    assert norm_squared > 0
    norm = norm_squared**0.5
    q = [w / norm, x / norm, y / norm, z / norm]
    for component in q:
        if component != 0:
            if component < 0:
                q = [-c for c in q]
            break
    return [normalised_zero(c) for c in q]


def rotation(w, x, y, z):
    elements = [
        1 - 2 * ((y * y) + (z * z)),
        2 * ((x * y) - (w * z)),
        2 * ((x * z) + (w * y)),
        2 * ((x * y) + (w * z)),
        1 - 2 * ((x * x) + (z * z)),
        2 * ((y * z) - (w * x)),
        2 * ((x * z) - (w * y)),
        2 * ((y * z) + (w * x)),
        1 - 2 * ((x * x) + (y * y)),
    ]
    return [normalised_zero(e) for e in elements]


def centred(points):
    count = float(len(points))
    mean = [0.0, 0.0, 0.0]
    for p in points:
        for c in range(3):
            mean[c] = mean[c] + p[c]
    mean = [m / count for m in mean]
    return [[p[c] - mean[c] for c in range(3)] for p in points], mean


def exactly_collinear(centred_points):
    first = None
    for p in centred_points:
        if p != [0.0, 0.0, 0.0]:
            first = p
            break
    if first is None:
        return True
    ux, uy, uz = first
    for px, py, pz in centred_points:
        cross = (uy * pz - uz * py, uz * px - ux * pz, ux * py - uy * px)
        if cross != (0.0, 0.0, 0.0):
            return False
    return True


def estimate(moving, fixed):
    assert len(moving) == len(fixed) and len(moving) >= 3
    cm, mean_m = centred(moving)
    cf, mean_f = centred(fixed)
    if exactly_collinear(cm) or exactly_collinear(cf):
        return None
    s = [[0.0] * 3 for _ in range(3)]
    for m, f in zip(cm, cf):
        for r in range(3):
            for c in range(3):
                s[r][c] = s[r][c] + m[r] * f[c]
    trace = (s[0][0] + s[1][1]) + s[2][2]
    n = [
        [trace, s[1][2] - s[2][1], s[2][0] - s[0][2], s[0][1] - s[1][0]],
        [s[1][2] - s[2][1], (s[0][0] - s[1][1]) - s[2][2],
         s[0][1] + s[1][0], s[2][0] + s[0][2]],
        [s[2][0] - s[0][2], s[0][1] + s[1][0],
         (s[1][1] - s[0][0]) - s[2][2], s[1][2] + s[2][1]],
        [s[0][1] - s[1][0], s[2][0] + s[0][2],
         s[1][2] + s[2][1], (s[2][2] - s[0][0]) - s[1][1]],
    ]
    a = [row[:] for row in n]
    v = [[1.0 if r == c else 0.0 for c in range(4)] for r in range(4)]
    for _ in range(SWEEPS):
        for p, q in PAIRS:
            apq = a[p][q]
            if apq == 0:
                continue
            theta = (a[q][q] - a[p][p]) / (2 * apq)
            sign = 1.0 if theta >= 0 else -1.0
            t = sign / (abs(theta) + (theta * theta + 1) ** 0.5)
            c = 1 / (t * t + 1) ** 0.5
            sn = t * c
            for k in range(4):
                akp = a[k][p]
                akq = a[k][q]
                a[k][p] = akp * c - akq * sn
                a[k][q] = akp * sn + akq * c
            for k in range(4):
                apk = a[p][k]
                aqk = a[q][k]
                a[p][k] = apk * c - aqk * sn
                a[q][k] = apk * sn + aqk * c
            for k in range(4):
                vkp = v[k][p]
                vkq = v[k][q]
                v[k][p] = vkp * c - vkq * sn
                v[k][q] = vkp * sn + vkq * c
    best = 0
    for i in range(1, 4):
        if a[i][i] > a[best][best]:
            best = i
    q = canonical_unit(v[0][best], v[1][best], v[2][best], v[3][best])
    r = rotation(*q)
    translation = [
        normalised_zero(
            mean_f[i]
            - (((r[3 * i + 0] * mean_m[0] + r[3 * i + 1] * mean_m[1])
                + r[3 * i + 2] * mean_m[2]))
        )
        for i in range(3)
    ]
    return q, translation


def report(label, moving, fixed):
    result = estimate(moving, fixed)
    print(f"{label}:")
    if result is None:
        print("  degenerate")
        return
    q, t = result
    print(f"  q = {q}")
    print(f"  q hex = {[c.hex() for c in q]}")
    print(f"  t = {t}")
    print(f"  t hex = {[c.hex() for c in t]}")


# Fixture A: an exact rigid motion — permutation rotation plus
# translation (1, 2, 3) over a non-collinear integer set.
moving_a = [[0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 2]]
fixed_a = [[1, 2, 3], [1, 3, 3], [1, 2, 4], [3, 2, 3]]
report("A", moving_a, fixed_a)

# Fixture B: exactly collinear moving landmarks — refused.
report("B", [[0, 0, 0], [1, 1, 1], [2, 2, 2]],
       [[0, 0, 0], [1, 0, 0], [0, 1, 0]])

# Fixture C: an inconsistent fixed set — the least-squares rotation
# under the frozen Jacobi, bit-pinned.
moving_c = [[0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 2]]
fixed_c = [[1, 2, 3], [1, 3, 3], [1, 2, 4], [3, 2, 3.5]]
report("C", moving_c, fixed_c)
