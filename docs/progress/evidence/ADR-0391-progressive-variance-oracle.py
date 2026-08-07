#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0080 progressive-variance/binary64-v1.

Welford's running mean and variance in the specification's frozen
order; Python floats are IEEE-754 binary64, so the printed values are
the exact bit patterns the Swift implementation must reproduce.
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
    variance = m2 / (count - 1) if count >= 2 else None
    return count, mean, variance


def report(label, values):
    count, mean, variance = welford(values)
    print(f"{label}: n={count} mean={mean} ({mean.hex()})")
    if variance is None:
        print("  variance absent")
    else:
        print(f"  variance={variance} ({variance.hex()})")


report("A", [1.0, 2.0, 3.0, 4.0])
report("B", [0.5])
report("C", [0.1, 0.7, 0.2, 0.9, 0.4])
