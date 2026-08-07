#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0074 curved-centreline/binary64-v1.

Python floats are IEEE-754 binary64; every expression below is written
in the specification's frozen order, so the printed values are the exact
bit patterns the Swift implementation must reproduce.
"""


def normalised_zero(value):
    return 0.0 if value == 0 else value


def lengths(points):
    out = []
    for a, b in zip(points, points[1:]):
        dx = b[0] - a[0]
        dy = b[1] - a[1]
        dz = b[2] - a[2]
        out.append(((dx * dx + dy * dy) + dz * dz) ** 0.5)
    return out


def cumulative(segment_lengths):
    out = [0.0]
    for length in segment_lengths:
        out.append(out[-1] + length)
    return out


def position(points, arc_length):
    segment_lengths = lengths(points)
    marks = cumulative(segment_lengths)
    total = marks[-1]
    assert 0 <= arc_length <= total
    if arc_length == total:
        return [float(v) for v in points[-1]]
    index = 0
    for i in range(len(points) - 1):
        if marks[i] <= arc_length:
            index = i
    t = (arc_length - marks[index]) / segment_lengths[index]
    a = points[index]
    b = points[index + 1]
    return [
        normalised_zero(a[c] + t * (b[c] - a[c])) for c in range(3)
    ]


def report(label, points, arc_length):
    p = position(points, arc_length)
    print(f"{label}: s={arc_length} -> {p}")
    print(f"  hex = {[v.hex() for v in p]}")


elbow = [(0, 0, 0), (3, 0, 0), (3, 4, 0)]
print("elbow lengths:", lengths(elbow), "cumulative:", cumulative(lengths(elbow)))
report("A1", elbow, 1.5)
report("A2", elbow, 3.0)
report("A3", elbow, 5.5)
report("A4", elbow, 7.0)

diagonal = [(0, 0, 0), (1, 1, 0)]
print("diagonal total:", cumulative(lengths(diagonal))[-1].hex())
report("C", diagonal, 1.0)
