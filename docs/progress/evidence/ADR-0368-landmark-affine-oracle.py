#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0070 landmark-affine/binary64-v1.

Python floats are IEEE-754 binary64; the normal-equation assembly and the
partial-pivot elimination below are written in the specification's frozen
order, so the printed values are the exact bit patterns the Swift
implementation must reproduce.
"""

LEAST_NORMAL = 2.2250738585072014e-308


def normalised_zero(value):
    return 0.0 if value == 0 else value


def estimate(moving, fixed):
    assert len(moving) == len(fixed) and len(moving) >= 4
    # M = sum of P PT, rhs columns = sum of P * fixed coordinate, both
    # accumulated in ascending landmark order, element order row-major.
    m = [[0.0] * 4 for _ in range(4)]
    rhs = [[0.0] * 3 for _ in range(4)]
    for (mx, my, mz), (fx, fy, fz) in zip(moving, fixed):
        p = [mx, my, mz, 1.0]
        for r in range(4):
            for c in range(4):
                m[r][c] = m[r][c] + p[r] * p[c]
            for c, f in enumerate((fx, fy, fz)):
                rhs[r][c] = rhs[r][c] + p[r] * f
    # Augmented 4x7 forward elimination with partial pivoting: at column
    # c pick the largest |pivot| in rows c..3 (ties to the lowest row),
    # refuse when the winner is below the least normal magnitude.
    a = [m[r] + rhs[r] for r in range(4)]
    for c in range(4):
        pivot_row = c
        for r in range(c + 1, 4):
            if abs(a[r][c]) > abs(a[pivot_row][c]):
                pivot_row = r
        if abs(a[pivot_row][c]) < LEAST_NORMAL:
            return None
        if pivot_row != c:
            a[c], a[pivot_row] = a[pivot_row], a[c]
        for r in range(c + 1, 4):
            factor = a[r][c] / a[c][c]
            for k in range(c, 7):
                a[r][k] = a[r][k] - factor * a[c][k]
    # Back substitution per rhs column: the subtraction folds
    # left-associative in ascending j.
    rows = [[0.0] * 4 for _ in range(3)]
    for col in range(3):
        x = [0.0] * 4
        for i in range(3, -1, -1):
            accumulated = a[i][4 + col]
            for j in range(i + 1, 4):
                accumulated = accumulated - a[i][j] * x[j]
            x[i] = accumulated / a[i][i]
        rows[col] = [normalised_zero(v) for v in x]
    return rows


def report(label, moving, fixed):
    rows = estimate(moving, fixed)
    print(f"{label}:")
    if rows is None:
        print("  degenerate")
        return
    for name, row in zip("xyz", rows):
        print(f"  {name}: {row}")
        print(f"  {name} hex = {[v.hex() for v in row]}")


# Fixture A: five consistent correspondences under
# diag(2,3,4) + t(1,2,3) — integer arithmetic throughout, the exact
# transform is recovered.
moving_a = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 1)]
fixed_a = [(1, 2, 3), (3, 2, 3), (1, 5, 3), (1, 2, 7), (3, 5, 7)]
report("A", moving_a, fixed_a)

# Fixture B: coplanar landmarks (all z = 0) — the normal matrix is
# singular and the estimate refuses.
moving_b = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 0)]
fixed_b = [(0, 0, 0), (2, 0, 0), (0, 2, 0), (2, 2, 0)]
report("B", moving_b, fixed_b)

# Fixture C: an inconsistent fifth point — the least-squares solution
# under the frozen elimination, not an interpolation.
moving_c = [(0, 0, 0), (2, 0, 0), (0, 2, 0), (0, 0, 2), (2, 2, 2)]
fixed_c = [(0, 0, 0), (2, 0, 0), (0, 2, 0), (0, 0, 2), (3, 2, 2)]
report("C", moving_c, fixed_c)
