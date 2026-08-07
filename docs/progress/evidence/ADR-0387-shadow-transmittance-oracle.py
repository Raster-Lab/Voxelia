#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0077 shadow-transmittance/binary64-v1.

Python floats are IEEE-754 binary64; the fold below is written in the
specification's frozen order, so the printed values are the exact bit
patterns the Swift implementation must reproduce.
"""


def transmittance(opacities):
    t = 1.0
    for alpha in opacities:
        t = t * (1 - alpha)
        if t == 0:
            break
    return t


def report(label, opacities):
    t = transmittance(opacities)
    print(f"{label}: T={t} ({t.hex()})")


report("A", [0.5, 0.5])
report("B", [1.0, 0.25])
report("C", [])
report("D", [0.1, 0.7, 0.9])
