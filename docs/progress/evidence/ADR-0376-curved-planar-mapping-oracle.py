#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0075 curved-planar-mapping/binary64-v1.

Python floats are IEEE-754 binary64; every expression below is written
in the specification's frozen order, so the printed values are the exact
bit patterns the Swift implementation must reproduce. The centreline
lookup replicates the ALG-0074 oracle.
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


def segment_index(marks, n_points, arc_length, total):
    if arc_length == total:
        return n_points - 2
    index = 0
    for i in range(n_points - 1):
        if marks[i] <= arc_length:
            index = i
    return index


def patient_position(points, reference, arc_length, offset):
    segment_lengths = lengths(points)
    marks = cumulative(segment_lengths)
    total = marks[-1]
    assert 0 <= arc_length <= total
    index = segment_index(marks, len(points), arc_length, total)
    a = points[index]
    b = points[index + 1]
    length = segment_lengths[index]
    tangent = [(b[c] - a[c]) / length for c in range(3)]
    # Centre: the ALG-0074 rule (total -> last point verbatim).
    if arc_length == total:
        centre = [float(v) for v in points[-1]]
    else:
        t = (arc_length - marks[index]) / length
        centre = [normalised_zero(a[c] + t * (b[c] - a[c])) for c in range(3)]
    dot = ((reference[0] * tangent[0] + reference[1] * tangent[1])
           + reference[2] * tangent[2])
    w = [reference[c] - dot * tangent[c] for c in range(3)]
    norm = ((w[0] * w[0] + w[1] * w[1]) + w[2] * w[2]) ** 0.5
    lateral = [w[c] / norm for c in range(3)]
    return [normalised_zero(centre[c] + offset * lateral[c]) for c in range(3)]


def report(label, points, reference, arc_length, offset):
    p = patient_position(points, reference, arc_length, offset)
    print(f"{label}: s={arc_length}, u={offset} -> {p}")
    print(f"  hex = {[v.hex() for v in p]}")


elbow = [(0, 0, 0), (3, 0, 0), (3, 4, 0)]
report("A1", elbow, (0, 0, 1), 1.5, 2.0)
report("A2", elbow, (0, 0, 1), 5.5, -1.0)
report("A3", elbow, (0, 0, 1), 7.0, 0.5)

diagonal = [(0, 0, 0), (1, 1, 0)]
report("C", diagonal, (1, 0, 0), 1.0, 1.0)
