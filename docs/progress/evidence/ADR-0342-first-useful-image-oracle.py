#!/usr/bin/env python3
"""Independent oracle for ADR-0342 first-useful-image planning and assembly.

Pure integer arithmetic: the plane-brick selection, the plane-first sweep order,
and the plane assembly from decoded brick core bytes, all mirrored from the
frozen rules and printed exactly for the Swift fixtures.

Fixture volume: extents (5, 4, 3), nominal brick extents (2, 2, 2), no halo,
stored value v(i0, i1, i2) = i0 + 5*i1 + 20*i2 (distinct axis strides, edge
bricks smaller than nominal on every axis).
"""

VOLUME = (5, 4, 3)
BRICK = (2, 2, 2)
VALUE = lambda i0, i1, i2: i0 + 5 * i1 + 20 * i2  # noqa: E731

counts = tuple((VOLUME[a] + BRICK[a] - 1) // BRICK[a] for a in range(3))
print(f"brick-counts: {counts}")


def core_region(coordinate):
    lower = tuple(coordinate[a] * BRICK[a] for a in range(3))
    upper = tuple(min(lower[a] + BRICK[a], VOLUME[a]) for a in range(3))
    return lower, upper


def all_coordinates():
    return [
        (c0, c1, c2)
        for c2 in range(counts[2])
        for c1 in range(counts[1])
        for c0 in range(counts[0])
    ]


def plane_layer(axis, index):
    return index // BRICK[axis]


def plan(axis, index):
    layer = plane_layer(axis, index)
    plane = [c for c in all_coordinates() if c[axis] == layer]
    rest = [c for c in all_coordinates() if c[axis] != layer]
    return plane + rest, len(plane)


def brick_bytes(coordinate):
    lower, upper = core_region(coordinate)
    out = []
    for i2 in range(lower[2], upper[2]):
        for i1 in range(lower[1], upper[1]):
            for i0 in range(lower[0], upper[0]):
                out.append(VALUE(i0, i1, i2))
    return out


def assemble(axis, index):
    axes = [a for a in range(3) if a != axis]
    u_axis, v_axis = axes[0], axes[1]
    width = VOLUME[u_axis]
    height = VOLUME[v_axis]
    out = [None] * (width * height)
    layer = plane_layer(axis, index)
    for coordinate in all_coordinates():
        if coordinate[axis] != layer:
            continue
        lower, upper = core_region(coordinate)
        core = tuple(upper[a] - lower[a] for a in range(3))
        data = brick_bytes(coordinate)
        local = [0, 0, 0]
        local[axis] = index - lower[axis]
        for v in range(lower[v_axis], upper[v_axis]):
            for u in range(lower[u_axis], upper[u_axis]):
                local[u_axis] = u - lower[u_axis]
                local[v_axis] = v - lower[v_axis]
                offset = local[0] + core[0] * (local[1] + core[1] * local[2])
                out[u + width * v] = data[offset]
    assert all(value is not None for value in out)
    return (width, height), out


for axis, index in [(2, 1), (0, 3)]:
    order, plane_count = plan(axis, index)
    print(f"plan(axis={axis}, index={index}): plane-bricks={plane_count} "
          f"order={order}")
    extents, plane = assemble(axis, index)
    print(f"assemble(axis={axis}, index={index}): extents={extents} "
          f"bytes={plane}")

# The before-completion witness: the plane subset is proper, so the milestone
# count is strictly below the total brick count.
total = len(all_coordinates())
print(f"total-bricks: {total}")
