#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0054 sample-centre physical bounds binary64-v1.

Implements the frozen rules directly in Python binary64 (IEEE 754, same arithmetic
as Swift Double for +, * without FMA) and prints every conformance fixture with
exact repr() values. ADR-0339 embeds these values; the Swift tests assert them
exactly.

Frozen rules restated (the specification is authoritative):
  * admission: 1 <= n_s <= 2**53 per slot, else typed rejection;
  * corners: ordinal c in 0..7, slot 0 varies fastest: bit s of c selects
    continuous index 0.0 or float(n_s - 1) for slot s;
  * point rule per world axis r with row-major M (elements[4r + c]):
      w_r = (((M[4r+0]*i0 + M[4r+1]*i1) + M[4r+2]*i2) + M[4r+3])
    left-associative, no fused multiply-add;
  * each w_r must be finite, else cornerNotRepresentable(ordinal, axis) at the
    first failing corner in ascending ordinal order, axes checked 0, 1, 2;
  * hull: sequential fold in ascending ordinal order, minima then maxima.
"""

import math

TWO_53 = 2**53


def corner_indices(counts, c):
    return tuple(
        0.0 if ((c >> s) & 1) == 0 else float(counts[s] - 1) for s in range(3)
    )


def transform(matrix, i):
    out = []
    for r in range(3):
        m = matrix[4 * r : 4 * r + 4]
        w = ((m[0] * i[0] + m[1] * i[1]) + m[2] * i[2]) + m[3]
        out.append(w)
    return out


def sample_centre_bounds(counts, matrix):
    for slot, count in enumerate(counts):
        if count < 1:
            return ("nonPositiveSampleCount", slot, count)
        if count > TWO_53:
            return ("sampleCountNotExactlyRepresentable", slot, count)
    minimum = [None] * 3
    maximum = [None] * 3
    for c in range(8):
        w = transform(matrix, corner_indices(counts, c))
        for r in range(3):
            if not math.isfinite(w[r]):
                return ("cornerNotRepresentable", c, r)
        if c == 0:
            minimum = list(w)
            maximum = list(w)
        else:
            for r in range(3):
                minimum[r] = min(minimum[r], w[r])
            for r in range(3):
                maximum[r] = max(maximum[r], w[r])
    return ("bounds", minimum, maximum)


def show(name, counts, matrix):
    result = sample_centre_bounds(counts, matrix)
    print(f"{name}: {result!r}")
    return result


IDENTITY = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]

# 1 - identity: bounds are the outermost sample centres themselves.
show("fixture-1", (3, 4, 5), IDENTITY)

# 2 - anisotropic spacing, non-zero origin (distinct spacings so a transposed
# axis cannot hide; exact binary fractions so every value is exact).
M2 = [0.5, 0.0, 0.0, 10.5,
      0.0, 0.25, 0.0, -20.25,
      0.0, 0.0, 2.0, 0.125,
      0.0, 0.0, 0.0, 1.0]
show("fixture-2", (16, 8, 4), M2)

# 3 - flipped z axis: the naive transformed-extreme-corner pair inverts, the
# fold does not.
M3 = [0.5, 0.0, 0.0, 10.5,
      0.0, 0.25, 0.0, -20.25,
      0.0, 0.0, -2.0, 0.125,
      0.0, 0.0, 0.0, 1.0]
show("fixture-3", (16, 8, 4), M3)

# 4 - exact 90-degree rotation about z with anisotropic scale: each world axis
# still depends on one slot, so this exercises rotation without yet needing
# the full hull.
M4 = [0.0, -0.25, 0.0, 1.0,
      0.5, 0.0, 0.0, 2.0,
      0.0, 0.0, 2.0, 3.0,
      0.0, 0.0, 0.0, 1.0]
show("fixture-4", (3, 5, 2), M4)

# 5 - the ADR-0323 hazard witness: world x mixes two slots with opposite
# signs, so the true hull needs corners the two-corner shortcut never visits.
M5 = [1.0, -1.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0]
show("fixture-5", (4, 3, 1), M5)
naive = [transform(M5, corner_indices((4, 3, 1), c)) for c in (0, 7)]
print(f"fixture-5-two-corner-x: {naive[0][0]!r} .. {naive[1][0]!r} (registered wrong)")

# 6 - single-sample volume: point bounds, zero width on every axis.
show("fixture-6", (1, 1, 1), M2)

# 7 - admission rejections, attribution checked per slot.
show("fixture-7a", (4, 0, 4), IDENTITY)
show("fixture-7b", (-3, 4, 4), IDENTITY)
show("fixture-7c", (4, 4, TWO_53 + 1), IDENTITY)
print(f"fixture-7-ceiling: {TWO_53} admitted exactly, "
      f"largest corner index {float(TWO_53 - 1)!r}")

# 8 - representability: a single product overflows at the first corner whose
# slot-0 index is large (ordinal 1), axis 0.
M8 = [1e300, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0]
show("fixture-8", (TWO_53, 2, 2), M8)

# 9 - representability: every product is finite and the accumulation overflows
# at the first corner combining both large terms (ordinal 3), axis 0.
M9 = [1e308, 1e308, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0]
show("fixture-9", (2, 2, 1), M9)

# Negative-zero unreachability witness: a corner component can be -0.0 before
# translation, and the final addition with a normalised (never -0.0)
# translation makes the published value +0.0. IEEE 754 round-to-nearest
# addition only returns -0.0 when both addends are -0.0.
before = (-2.0 * 0.0 + -3.0 * 0.0) + -1.0 * 0.0
after = before + 0.0
print(f"negative-zero: before-translation {math.copysign(1, before):+.0f}, "
      f"after {math.copysign(1, after):+.0f}")
