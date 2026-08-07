#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0067 segment statistics.

Frozen rules: samples under the mask contribute unless padded (excluded
first) or NaN; the sum folds left-to-right in canonical order; the mean is
sum divided by included count; min and max are exact selections; the cell
volume is the magnitude of the spatial determinant and the physical volume
is mask count times cell volume.
"""

import math

values = [100.0, 0.0, 300.0, float("nan"), 500.0, 250.0]
mask = [1, 1, 1, 1, 1, 0]
padding = 0.0

included = []
padded = 0
non_finite = 0
for v, m in zip(values, mask):
    if m == 0:
        continue
    if v == padding:
        padded += 1
        continue
    if math.isnan(v):
        non_finite += 1
        continue
    included.append(v)

total = 0.0
for v in included:
    total = total + v
print(f"maskCount={sum(mask)} included={len(included)} padded={padded} "
      f"nonFinite={non_finite}")
print(f"sum={total} mean={total / len(included)} "
      f"min={min(included)} max={max(included)}")

# diag(0.5, 0.25, 2): determinant 0.25; five mask samples -> 1.25.
det = 0.5 * 0.25 * 2.0
print(f"cellVolume={det} physicalVolume={sum(mask) * det}")
