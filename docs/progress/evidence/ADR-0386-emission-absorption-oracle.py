#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0076 emission-absorption/binary64-v1.

Python floats are IEEE-754 binary64; every expression below is written
in the specification's frozen order, so the printed values are the exact
bit patterns the Swift implementation must reproduce.
"""


def integrate(samples):
    r = 0.0
    g = 0.0
    b = 0.0
    a = 0.0
    for er, eg, eb, alpha in samples:
        weight = (1 - a) * alpha
        r = r + weight * er
        g = g + weight * eg
        b = b + weight * eb
        a = a + weight
        if a == 1:
            break
    return r, g, b, a


def report(label, samples):
    r, g, b, a = integrate(samples)
    print(f"{label}: r={r} g={g} b={b} a={a}")
    print(f"  hex = {[v.hex() for v in (r, g, b, a)]}")


# Fixture A: two half-opaque dyadic samples — exact arithmetic.
report("A", [(1.0, 0.5, 0.25, 0.5), (0.5, 1.0, 0.0, 0.5)])

# Fixture B: an exactly opaque first sample occludes everything after.
report("B", [(0.25, 0.5, 0.75, 1.0), (9.0, 9.0, 9.0, 1.0)])

# Fixture C: an empty ray is exactly transparent.
report("C", [])

# Fixture D: irrational weights pin the frozen rounding.
report("D", [(0.1, 0.2, 0.3, 0.1), (0.4, 0.5, 0.6, 0.7), (0.7, 0.8, 0.9, 0.9)])
