#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0069 rigid-composition/binary64-v1.

Python floats are IEEE-754 binary64; every expression below is written in
the specification's frozen order, so the printed values are the exact bit
patterns the Swift implementation must reproduce. The canonicalisation and
rotation derivation replicate the ALG-0068 oracle.
"""


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


def hamilton(q1, q2):
    w1, x1, y1, z1 = q1
    w2, x2, y2, z2 = q2
    return [
        ((w1 * w2 - x1 * x2) - y1 * y2) - z1 * z2,
        ((w1 * x2 + x1 * w2) + y1 * z2) - z1 * y2,
        ((w1 * y2 - x1 * z2) + y1 * w2) + z1 * x2,
        ((w1 * z2 + x1 * y2) - y1 * x2) + z1 * w2,
    ]


def compose(outer_q, outer_t, inner_q, inner_t):
    product = hamilton(outer_q, inner_q)
    q = canonical_unit(*product)
    r = rotation(*outer_q)
    t = [
        normalised_zero(
            ((r[3 * i + 0] * inner_t[0] + r[3 * i + 1] * inner_t[1])
             + r[3 * i + 2] * inner_t[2])
            + outer_t[i]
        )
        for i in range(3)
    ]
    return q, t


def report(label, outer_q, outer_t, inner_q, inner_t):
    q, t = compose(
        canonical_unit(*outer_q), outer_t, canonical_unit(*inner_q), inner_t
    )
    print(f"{label}: q = {q}")
    print(f"  q hex = {[c.hex() for c in q]}")
    print(f"  t = {t}")
    print(f"  t hex = {[c.hex() for c in t]}")


# Fixture A: permutation outer, identity inner rotation — the composed
# translation is the outer-rotated inner translation plus the outer's.
report("A", (1, 1, 1, 1), [10, 20, 30], (1, 0, 0, 0), [1, 2, 3])

# Fixture B: the permutation composed with itself — the Hamilton product
# lands at (-0.5, 0.5, 0.5, 0.5) and the canonical sign flips it.
report("B", (1, 1, 1, 1), [0, 0, 0], (1, 1, 1, 1), [0, 0, 0])

# Fixture C: irrational operands — exercises the frozen rounding.
report("C", (2, 1, 0, 0), [1, 0, 0], (1, 1, 1, 1), [0, 1, 0])
