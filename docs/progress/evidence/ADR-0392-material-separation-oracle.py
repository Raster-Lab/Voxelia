#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0081 material-separation/binary64-v1.

Python floats are IEEE-754 binary64; the fold below is written in the
specification's frozen order, so the printed values are the exact bit
patterns the Swift implementation must reproduce.
"""


def integrate(samples, material_count):
    per = [[0.0, 0.0, 0.0] for _ in range(material_count)]
    a = 0.0
    for material, er, eg, eb, alpha in samples:
        weight = (1 - a) * alpha
        per[material][0] = per[material][0] + weight * er
        per[material][1] = per[material][1] + weight * eg
        per[material][2] = per[material][2] + weight * eb
        a = a + weight
        if a == 1:
            break
    return per, a


def report(label, samples, count):
    per, a = integrate(samples, count)
    print(f"{label}: opacity={a} ({a.hex()})")
    for index, channels in enumerate(per):
        print(f"  material {index}: {channels}")
        print(f"    hex = {[v.hex() for v in channels]}")


# Fixture A: two materials interleaved along one ray, dyadic values —
# the shared opacity walk attenuates the second material's samples by
# everything in front of them, whatever material that was.
report("A", [
    (0, 1.0, 0.5, 0.25, 0.5),
    (1, 0.5, 1.0, 0.0, 0.5),
    (0, 0.25, 0.25, 1.0, 0.5),
], 2)

# Fixture B: an opaque foreign material occludes a later material
# entirely.
report("B", [
    (1, 0.5, 0.5, 0.5, 1.0),
    (0, 9.0, 9.0, 9.0, 1.0),
], 2)
