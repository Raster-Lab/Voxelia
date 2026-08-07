#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0082 multidimensional-transfer/v1.

Bin lookup over a declared two-dimensional table: the arithmetic is the
MI-metric bin rule (one width rounding, floor, exact top edge into the
last bin) and the returned values are the stored table entries verbatim,
so the fixture is exact by construction.
"""

import math


def bin_index(value, lower, width, bins):
    index = math.floor((value - lower) / width)
    if index == bins and value == lower + width * bins:
        return bins - 1
    return index


def lookup(table, intensity, gradient,
           i_range, i_bins, g_range, g_bins):
    i_width = (i_range[1] - i_range[0]) / i_bins
    g_width = (g_range[1] - g_range[0]) / g_bins
    i = bin_index(intensity, i_range[0], i_width, i_bins)
    g = bin_index(gradient, g_range[0], g_width, g_bins)
    if i < 0 or i >= i_bins or g < 0 or g >= g_bins:
        return None
    return table[i][g]


TABLE = [
    [(0.1, 0.1, 0.1, 0.05), (0.9, 0.1, 0.1, 0.8)],
    [(0.1, 0.9, 0.1, 0.3), (0.1, 0.1, 0.9, 1.0)],
]

print("A:", lookup(TABLE, 10.0, 1.0, (0.0, 100.0), 2, (0.0, 4.0), 2))
print("B:", lookup(TABLE, 50.0, 4.0, (0.0, 100.0), 2, (0.0, 4.0), 2))
print("C:", lookup(TABLE, 100.0, 0.0, (0.0, 100.0), 2, (0.0, 4.0), 2))
print("D (out of range):", lookup(TABLE, 150.0, 0.0, (0.0, 100.0), 2, (0.0, 4.0), 2))
