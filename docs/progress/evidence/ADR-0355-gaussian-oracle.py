#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0060 separable Gaussian binary64-v1.

Mirrors the frozen rules: sampled weights exp(-o^2 / (2 sigma^2)) over the
truncation radius ceil(3 sigma), left-to-right summation and per-weight
division for normalisation, axis-ascending separable passes carried in
binary64 with ALG-0059's boundary and accumulation rules, and one final store
under the ALG-0058 output rule.
"""

import math
import struct


def weights(sigma):
    radius = math.ceil(3.0 * sigma)
    raw = [math.exp(-(float(o) * float(o)) / (2.0 * sigma * sigma))
           for o in range(-radius, radius + 1)]
    total = 0.0
    for w in raw:
        total = total + w
    return [w / total for w in raw], radius


def convolve_axis(values, extents, axis, kernel, radius, boundary):
    rank = len(extents)
    strides = [1] * rank
    for a in range(1, rank):
        strides[a] = strides[a - 1] * extents[a - 1]
    count = 1
    for e in extents:
        count *= e
    out = [0.0] * count
    index = [0] * rank
    for linear in range(count):
        acc = 0.0
        for k, w in enumerate(kernel):
            offset = k - radius
            source = index[axis] + offset
            contributes = True
            if source < 0 or source >= extents[axis]:
                if boundary == "replicate":
                    source = min(max(source, 0), extents[axis] - 1)
                else:
                    contributes = False
            if contributes:
                src_linear = linear + (source - index[axis]) * strides[axis]
                acc = acc + w * values[src_linear]
        out[linear] = acc
        a = 0
        while a < rank:
            index[a] += 1
            if index[a] < extents[a]:
                break
            index[a] = 0
            a += 1
    return out


def gaussian(values, extents, sigmas, boundary, scalar_type):
    current = [float(v) for v in values]
    for axis in range(len(extents)):
        kernel, radius = weights(sigmas[axis])
        current = convolve_axis(current, extents, axis, kernel, radius, boundary)
    out = []
    for value in current:
        if scalar_type == "float32":
            out.append(struct.unpack("<f", struct.pack("<f", value))[0])
        else:
            hi = {"uint8": 255, "int16": 32767, "uint16": 65535}[scalar_type]
            out.append(min(hi, max(0, round(value))))
    return out


# 1 - impulse response, sigma 1.0, replicate: the sampled normalised bell.
impulse = [0, 0, 255, 0, 0, 0, 0]
out = gaussian(impulse, [7, 1], [1.0, 1.0], "replicate", "uint8")
print(f"impulse-sigma1: {out}")

# 2 - sigma 0.5 concentrates: radius ceil(1.5) = 2.
out = gaussian(impulse, [7, 1], [0.5, 0.5], "replicate", "uint8")
print(f"impulse-sigma0.5: {out}")

# 3 - a 3x3 float32 impulse, separable product structure.
plane = [0.0] * 9
plane[4] = 16.0
out = gaussian(plane, [3, 3], [1.0, 1.0], "zero", "float32")
print(f"plane-sigma1-zero: {[round(v, 6) for v in out]}")
print("plane-out-bytes:", list(b"".join(struct.pack("<f", v) for v in out)))

# 4 - the constant image is a fixed point under replicate (weights sum to 1
# in binary64 up to the frozen order's rounding; the stored uint8 result is
# exactly the constant).
constant = [200] * 5
out = gaussian(constant, [5, 1], [2.0, 1.0], "replicate", "uint8")
print(f"constant-replicate: {out}")

# Admissible sigma ceiling: extent 2*ceil(3 sigma)+1 <= 31 -> sigma <= 5.
for sigma in (5.0, 5.1):
    radius = math.ceil(3.0 * sigma)
    print(f"sigma={sigma}: radius={radius} extent={2 * radius + 1}")
