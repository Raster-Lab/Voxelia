#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0068 rigid-motion/binary64-v1.

Python floats are IEEE-754 binary64; every expression below is written in
the specification's frozen order, so the printed values are the exact bit
patterns the Swift implementation must reproduce.
"""


def normalised_zero(value):
    # Negative zero is normalised to positive zero, exactly as
    # Matrix4x4Double admission does.
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


def report(label, components):
    q = canonical_unit(*components)
    r = rotation(*q)
    print(f"{label}: input {components}")
    print(f"  canonical q = {q}")
    print(f"  canonical q hex = {[c.hex() for c in q]}")
    print(f"  rotation = {r}")
    print(f"  rotation hex = {[c.hex() for c in r]}")


# Fixture A: equal components — norm is exactly 2, the rotation is the
# exact cyclic permutation matrix.
report("A", (1.0, 1.0, 1.0, 1.0))

# Fixture B: pure-z with a negative sign and non-unit magnitude — exercises
# normalisation and the canonical sign flip; the rotation is diag(-1,-1,1).
report("B", (0.0, 0.0, 0.0, -2.0))

# Fixture C: irrational norm (sqrt 5) — exercises the frozen rounding.
report("C", (2.0, 1.0, 0.0, 0.0))
