#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0083 welford-merge/binary64-v1.

Chan's parallel combination of Welford states in the specification's
frozen order. Python floats are IEEE-754 binary64, so the printed
values are the exact bit patterns the Swift implementation must
reproduce — including the comparison of the two merge orders, which
the analysis half of VOX-DST-008 records.
"""


def welford(values):
    count = 0
    mean = 0.0
    m2 = 0.0
    for x in values:
        count += 1
        delta = x - mean
        mean = mean + delta / count
        delta2 = x - mean
        m2 = m2 + delta * delta2
    return count, mean, m2


def merge(a, b):
    count_a, mean_a, m2_a = a
    count_b, mean_b, m2_b = b
    count = count_a + count_b
    delta = mean_b - mean_a
    mean = mean_a + delta * (count_b / count)
    m2 = (m2_a + m2_b) + (delta * delta) * (count_a * count_b / count)
    return count, mean, m2


a = welford([1.0, 2.0, 3.0])
b = welford([10.0, 20.0])
print("A:", a, [v.hex() for v in a[1:]])
print("B:", b, [v.hex() for v in b[1:]])
ab = merge(a, b)
ba = merge(b, a)
seq = welford([1.0, 2.0, 3.0, 10.0, 20.0])
print("merge(A,B):", ab, [v.hex() for v in ab[1:]])
print("merge(B,A):", ba, [v.hex() for v in ba[1:]])
print("sequential:", seq, [v.hex() for v in seq[1:]])
print("orders bit-equal:", ab == ba)
print("merge equals sequential:", ab == seq)

# The irrational fixture pins the frozen rounding.
c = welford([0.1, 0.7, 0.2])
d = welford([0.9, 0.4])
cd = merge(c, d)
print("merge(C,D):", cd, [v.hex() for v in cd[1:]])
