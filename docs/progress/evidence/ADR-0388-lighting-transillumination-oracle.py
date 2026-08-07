#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0078 lighting-transillumination/binary64-v1.

Python floats are IEEE-754 binary64; every fold below is written in the
specification's frozen order, so the printed values are the exact bit
patterns the Swift implementation must reproduce.
"""


def accumulate(lights):
    r = 0.0
    g = 0.0
    b = 0.0
    for lr, lg, lb, weight, transmittance in lights:
        factor = weight * transmittance
        r = r + factor * lr
        g = g + factor * lg
        b = b + factor * lb
    return r, g, b


def transilluminate(radiance, background):
    cr, cg, cb, a = radiance
    br, bg, bb = background
    remaining = 1 - a
    return (
        cr + remaining * br,
        cg + remaining * bg,
        cb + remaining * bb,
    )


def report(label, values):
    print(f"{label}: {values}")
    print(f"  hex = {[v.hex() for v in values]}")


# Lighting fixture A: two dyadic light samples.
report("L-A", accumulate([
    (1.0, 0.5, 0.25, 0.5, 0.5),
    (0.25, 1.0, 0.0, 0.25, 1.0),
]))

# Lighting fixture B: a fully shadowed light contributes nothing.
report("L-B", accumulate([(9.0, 9.0, 9.0, 1.0, 0.0)]))

# Lighting fixture C: irrational weights pin the rounding.
report("L-C", accumulate([
    (0.1, 0.2, 0.3, 0.7, 0.9),
    (0.4, 0.5, 0.6, 0.3, 0.2),
]))

# Transillumination fixture A: dyadic foreground over a background.
report("T-A", transilluminate((0.25, 0.5, 0.125, 0.75), (1.0, 0.5, 0.25)))

# Transillumination fixture B: an opaque foreground admits nothing.
report("T-B", transilluminate((0.1, 0.2, 0.3, 1.0), (9.0, 9.0, 9.0)))

# Transillumination fixture C: irrational values pin the rounding.
report("T-C", transilluminate((0.1, 0.2, 0.3, 0.7), (0.9, 0.8, 0.7)))
