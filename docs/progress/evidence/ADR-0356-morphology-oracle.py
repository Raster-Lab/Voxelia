#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0061 binary morphology.

Mirrors the frozen rules: dilation is ANY over the structuring element's
covered in-image taps, erosion is ALL over the covered taps with the explicit
boundary deciding what an out-of-image tap contributes — replicate reads the
clamped edge sample, zero contributes background — so border-touching
foreground erodes under zero and survives under replicate.
"""


def morph(values, extents, se, se_extents, boundary, operator):
    rank = len(extents)
    strides = [1] * rank
    for a in range(1, rank):
        strides[a] = strides[a - 1] * extents[a - 1]
    radii = [e // 2 for e in se_extents]
    count = 1
    for e in extents:
        count *= e
    out = []
    index = [0] * rank
    for _ in range(count):
        hits = []
        for k in range(len(se)):
            if se[k] == 0:
                continue
            remainder = k
            offset = [0] * rank
            for a in range(rank):
                offset[a] = remainder % se_extents[a] - radii[a]
                remainder //= se_extents[a]
            sample = None
            linear = 0
            for a in range(rank):
                source = index[a] + offset[a]
                if source < 0 or source >= extents[a]:
                    if boundary == "replicate":
                        source = min(max(source, 0), extents[a] - 1)
                    else:
                        sample = 0
                linear += min(max(source, 0), extents[a] - 1) * strides[a]
            if sample is None:
                sample = values[linear]
            hits.append(sample)
        out.append(
            (1 if any(hits) else 0)
            if operator == "dilate"
            else (1 if all(hits) else 0)
        )
        a = 0
        while a < rank:
            index[a] += 1
            if index[a] < extents[a]:
                break
            index[a] = 0
            a += 1
    return out


SE3 = [1, 1, 1]
print("dilate-impulse:", morph([0, 0, 1, 0, 0], [5, 1], SE3, [3, 1], "zero", "dilate"))
print("erode-bar:", morph([0, 1, 1, 1, 0], [5, 1], SE3, [3, 1], "zero", "erode"))
print("erode-full-replicate:", morph([1] * 5, [5, 1], SE3, [3, 1], "replicate", "erode"))
print("erode-full-zero:", morph([1] * 5, [5, 1], SE3, [3, 1], "zero", "erode"))
print("dilate-border-zero:", morph([1, 0, 0, 0, 0], [5, 1], SE3, [3, 1], "zero", "dilate"))

# 2-D cross structuring element on a single centre pixel.
cross = [0, 1, 0, 1, 1, 1, 0, 1, 0]
plane = [0] * 9
plane[4] = 1
print("dilate-cross-2d:", morph(plane, [3, 3], cross, [3, 3], "zero", "dilate"))
print("erode-cross-2d-full:", morph([1] * 9, [3, 3], cross, [3, 3], "zero", "erode"))
