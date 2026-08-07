#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0072 registration-metrics/binary64-v1.

Python floats are IEEE-754 binary64 and math.log is the platform libm's
natural logarithm — the same library the Swift implementation calls on
the reference hardware — so the printed values are the exact bit
patterns the implementation must reproduce.
"""

import math


def mean_squares(fixed, moving):
    total = 0.0
    count = 0
    excluded = 0
    for f, m in zip(fixed, moving):
        if not (math.isfinite(f) and math.isfinite(m)):
            excluded += 1
            continue
        d = m - f
        total = total + d * d
        count += 1
    value = total / count if count > 0 else None
    return value, count, excluded


def bin_index(value, lower, width, bins):
    index = math.floor((value - lower) / width)
    if index == bins and value == lower + width * bins:
        return bins - 1
    return index


def mutual_information(fixed, moving, bins, f_range, m_range):
    f_width = (f_range[1] - f_range[0]) / bins
    m_width = (m_range[1] - m_range[0]) / bins
    joint = [[0] * bins for _ in range(bins)]
    count = 0
    excluded = 0
    for f, m in zip(fixed, moving):
        if not (math.isfinite(f) and math.isfinite(m)):
            excluded += 1
            continue
        fi = bin_index(f, f_range[0], f_width, bins)
        mi = bin_index(m, m_range[0], m_width, bins)
        if fi < 0 or fi >= bins or mi < 0 or mi >= bins:
            excluded += 1
            continue
        joint[fi][mi] += 1
        count += 1
    if count == 0:
        return None, count, excluded
    row = [sum(joint[i][j] for j in range(bins)) for i in range(bins)]
    col = [sum(joint[i][j] for i in range(bins)) for j in range(bins)]
    total = float(count)
    value = 0.0
    for i in range(bins):
        for j in range(bins):
            n = joint[i][j]
            if n == 0:
                continue
            p = n / total
            pi = row[i] / total
            qj = col[j] / total
            value = value + p * math.log(p / (pi * qj))
    return value, count, excluded


def show(label, result):
    value, count, excluded = result
    if value is None:
        print(f"{label}: absent, contributing {count}, excluded {excluded}")
    else:
        print(f"{label}: {value} ({value.hex()}), contributing {count}, "
              f"excluded {excluded}")


# Mean squares: exact dyadic fixture, then a NaN exclusion.
show("MS-A", mean_squares([0, 1, 2, 3], [1, 1, 4, 3]))
show("MS-B", mean_squares([0, 1, float("nan")], [1, 1, 0]))

# Mutual information over 2 bins on [0, 16): perfectly correlated gives
# exactly log 2; independent gives exactly zero; an out-of-range sample
# is excluded and counted.
show("MI-A", mutual_information([0, 0, 10, 10], [0, 0, 10, 10], 2,
                                (0.0, 16.0), (0.0, 16.0)))
show("MI-B", mutual_information([0, 0, 10, 10], [0, 10, 0, 10], 2,
                                (0.0, 16.0), (0.0, 16.0)))
show("MI-C", mutual_information([0, 0, 10, 10, 20], [0, 0, 10, 10, 5], 2,
                                (0.0, 16.0), (0.0, 16.0)))
print("log2 hex check:", math.log(2.0).hex())
