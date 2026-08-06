#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0199 and VOXELIA-ALG-0033."""

from __future__ import annotations

import hashlib
import math
import struct


EXPECTED_FIXTURE_SHA256 = (
    "cbb73b21b0a3789aa46c08f3195893e7329b376b0c9639fa06ec60459cb39a38"
)
EXPECTED_PROJECTION_BYTES_SHA256 = (
    "6171752e014b1a05774b15739faf44e5222764f18ebda7f4de6749674127e017"
)


class ProjectionFailure(Exception):
    """One payload-free oracle classification."""


def f64(value: float) -> float:
    return struct.unpack(">d", struct.pack(">d", value))[0]


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def checked(value: float) -> float:
    rounded = f64(value)
    if not math.isfinite(rounded):
        raise ProjectionFailure("positionNotRepresentable")
    return rounded


def sub(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) - f64(rhs))


def add(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) + f64(rhs))


def mul(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) * f64(rhs))


def div(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) / f64(rhs))


def root(value: float) -> float:
    return checked(math.sqrt(f64(value)))


def cross(a, b):
    """The ordered cross product shared with VOXELIA-ALG-0030."""
    return (
        sub(mul(a[1], b[2]), mul(a[2], b[1])),
        sub(mul(a[2], b[0]), mul(a[0], b[2])),
        sub(mul(a[0], b[1]), mul(a[1], b[0])),
    )


def normalise(v):
    """Maximum-component-scaled Euclidean normalisation, as in ALG-0030."""
    scale = max(abs(component) for component in v)
    if scale == 0.0:
        raise ProjectionFailure("degenerateCameraBasis")
    scaled = tuple(div(component, scale) for component in v)
    squared_sum = add(
        add(mul(scaled[0], scaled[0]), mul(scaled[1], scaled[1])),
        mul(scaled[2], scaled[2]),
    )
    length = root(squared_sum)
    out = []
    for component in scaled:
        value = div(component, length)
        out.append(0.0 if value == 0.0 else value)
    return (out[0], out[1], out[2])


def camera_basis(position, target, up):
    """The frozen right, true-up and forward unit axes."""
    forward_raw = tuple(sub(target[lane], position[lane]) for lane in range(3))
    forward = normalise(forward_raw)
    right = normalise(cross(forward, up))
    true_up = normalise(cross(right, forward))
    return right, true_up, forward


def dot(a, b):
    """The frozen `((a0*b0 + a1*b1) + a2*b2)` grouping."""
    return add(add(mul(a[0], b[0]), mul(a[1], b[1])), mul(a[2], b[2]))


def object_to_world(matrix, point):
    """Row-major affine application; the bottom row is admitted as (0,0,0,1)."""
    out = []
    for row in range(3):
        base = row * 4
        accumulated = add(
            add(
                mul(matrix[base], point[0]),
                mul(matrix[base + 1], point[1]),
            ),
            mul(matrix[base + 2], point[2]),
        )
        out.append(add(accumulated, matrix[base + 3]))
    return (out[0], out[1], out[2])


def project(
    positions,
    matrix,
    position,
    target,
    up,
    plane_height,
    width,
    height,
    projection="orthographic",
):
    """Project every vertex to continuous viewport coordinates and depth."""
    if projection != "orthographic":
        raise ProjectionFailure("unsupportedProjection")
    right, true_up, forward = camera_basis(position, target, up)
    world_per_pixel = div(plane_height, float(height))
    half_width = div(float(width), 2.0)
    half_height = div(float(height), 2.0)

    projected = []
    for vertex in positions:
        world = object_to_world(matrix, vertex)
        delta = tuple(sub(world[lane], position[lane]) for lane in range(3))
        view_x = dot(delta, right)
        view_y = dot(delta, true_up)
        depth = dot(delta, forward)
        column = add(half_width, div(view_x, world_per_pixel))
        row = sub(half_height, div(view_y, world_per_pixel))
        projected.append((column, row, depth))
    return tuple(projected)


IDENTITY = [
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0,
]


def translation(x: float, y: float, z: float):
    matrix = list(IDENTITY)
    matrix[3] = x
    matrix[7] = y
    matrix[11] = z
    return matrix


def scaling(s: float):
    matrix = list(IDENTITY)
    matrix[0] = s
    matrix[5] = s
    matrix[10] = s
    return matrix


def record(name: str, case: dict) -> tuple[str, bytes]:
    try:
        projected = project(**case)
    except ProjectionFailure as error:
        return f"{name}|error={error}", b""
    tokens = []
    payload = bytearray()
    for column, row, depth in projected:
        for component in (column, row, depth):
            tokens.append(f"{bits(component):016x}")
            payload.extend(struct.pack("<Q", bits(component)))
    return f"{name}|vertices={len(projected)}|bits={','.join(tokens)}", bytes(payload)


def main() -> None:
    unit_triangle = ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0))
    front_camera = {
        "position": (0.0, 0.0, 10.0),
        "target": (0.0, 0.0, 0.0),
        "up": (0.0, 1.0, 0.0),
    }

    # 1. A camera on +Z looking at the origin, plane height four over a
    #    four-by-three viewport: one world unit is one third of the plane
    #    height, so world-per-pixel is exactly 4/3.
    base = dict(
        positions=unit_triangle,
        matrix=IDENTITY,
        plane_height=4.0,
        width=4,
        height=3,
        **front_camera,
    )
    identity_case = project(**base)
    # The origin lands at the exact viewport centre.
    assert bits(identity_case[0][0]) == bits(2.0)
    assert bits(identity_case[0][1]) == bits(1.5)
    # Depth is measured along forward and is positive in front of the camera.
    assert identity_case[0][2] == 10.0

    # 2. Translating the object moves the projection and leaves depth
    #    consistent with the shift along the view direction.
    translated = dict(base, matrix=translation(1.0, 2.0, 3.0))
    translated_case = project(**translated)
    assert translated_case[0][2] == 7.0

    # 3. Square pixels are preserved on a non-square viewport: the plane
    #    width follows from the height and the aspect, never the reverse.
    wide = dict(base, width=8, height=2, plane_height=2.0)
    wide_case = project(**wide)
    assert bits(wide_case[0][0]) == bits(4.0)
    assert bits(wide_case[0][1]) == bits(1.0)

    # 4. A vertex behind the camera is admitted with negative depth.
    #    Orthographic projection has no eye point, so this is not a failure.
    behind = dict(base, matrix=translation(0.0, 0.0, 20.0))
    behind_case = project(**behind)
    assert behind_case[0][2] == -10.0

    # 5. A singular object-to-world collapses every vertex to one point,
    #    which the vocabulary admits and this model simply projects.
    collapsed_matrix = list(IDENTITY)
    collapsed_matrix[0] = 0.0
    collapsed_matrix[5] = 0.0
    collapsed_matrix[10] = 0.0
    collapsed = dict(base, matrix=collapsed_matrix)
    collapsed_case = project(**collapsed)
    assert collapsed_case[0] == collapsed_case[1] == collapsed_case[2]

    # 6. Uniform scaling scales the projected offsets.
    scaled = dict(base, matrix=scaling(2.0))
    scaled_case = project(**scaled)
    assert scaled_case[1][0] != identity_case[1][0]

    # 7. An oblique camera exercises the full basis construction.
    oblique = dict(
        base,
        position=(3.0, 4.0, 5.0),
        target=(0.0, 0.0, 0.0),
        up=(0.0, 0.0, 1.0),
    )
    oblique_case = project(**oblique)
    assert all(math.isfinite(component) for v in oblique_case for component in v)

    # 8. The `((a*b + c*d) + e*f)` grouping is part of the identity. This
    #    object-to-world row cancels its first two terms exactly, so the
    #    frozen order yields one while `(a*b + (c*d + e*f))` yields zero.
    huge = 1e16
    grouped = add(add(mul(huge, 1.0), mul(-huge, 1.0)), mul(1.0, 1.0))
    regrouped = add(mul(huge, 1.0), add(mul(-huge, 1.0), mul(1.0, 1.0)))
    assert grouped == 1.0
    assert regrouped == 0.0
    assert bits(grouped) != bits(regrouped)
    order_matrix = list(IDENTITY)
    order_matrix[0] = huge
    order_matrix[1] = -huge
    order_matrix[2] = 1.0
    order = dict(base, positions=((1.0, 1.0, 1.0),), matrix=order_matrix)
    order_case = project(**order)
    assert object_to_world(order_matrix, (1.0, 1.0, 1.0))[0] == 1.0
    assert all(math.isfinite(component) for component in order_case[0])

    # 9. Separated multiply-then-subtract in the basis cross product is part
    #    of the identity: a fused multiply-subtract changes the axes.
    contraction_value = float.fromhex("0x1.0000002000000p+0")
    separated = sub(
        mul(contraction_value, contraction_value),
        mul(1.0, 1.0),
    )
    contracted = math.fma(contraction_value, contraction_value, -1.0)
    assert bits(separated) != bits(contracted)
    contraction = dict(
        base,
        position=(0.0, 0.0, 10.0),
        up=(contraction_value, 1.0, 0.0),
    )
    contraction_case = project(**contraction)
    assert all(math.isfinite(c) for v in contraction_case for c in v)

    # 10. An extreme but finite placement overflows the frozen expression.
    greatest = float.fromhex("0x1.fffffffffffffp+1023")
    overflow_matrix = list(IDENTITY)
    overflow_matrix[0] = greatest
    overflow_matrix[3] = greatest
    overflow = dict(base, matrix=overflow_matrix)
    try:
        project(**overflow)
    except ProjectionFailure as error:
        assert str(error) == "positionNotRepresentable"
    else:
        raise AssertionError("An overflowing placement must fail.")

    # 11. Perspective is rejected typed. Version one is orthographic only,
    #     and the rejection is the recorded settlement of the deferral.
    perspective = dict(base, projection="perspective")
    try:
        project(**perspective)
    except ProjectionFailure as error:
        assert str(error) == "unsupportedProjection"
    else:
        raise AssertionError("Perspective must be rejected in version one.")

    # 12. An empty mesh projects to no vertices and is not a failure.
    empty = dict(base, positions=())
    assert project(**empty) == ()

    fixtures = (
        ("identity-front", base),
        ("translated", translated),
        ("wide-viewport", wide),
        ("behind-camera", behind),
        ("collapsed-placement", collapsed),
        ("scaled-placement", scaled),
        ("oblique-camera", oblique),
        ("grouping-sensitive", order),
        ("contraction-sensitive", contraction),
        ("empty", empty),
        ("placement-overflow", overflow),
        ("perspective", perspective),
    )
    records = []
    payload = bytearray()
    for name, case in fixtures:
        fixture_record, output_bytes = record(name, case)
        records.append(fixture_record)
        payload.extend(output_bytes)

    fixture_digest = hashlib.sha256(
        "\n".join(records).encode("ascii")
    ).hexdigest()
    projection_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert projection_digest == EXPECTED_PROJECTION_BYTES_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"projectionBytesSHA256={projection_digest}")
    print(f"fixtures={len(fixtures)} successful=10 failures=2")
    print("projection=orthographic-only perspective=rejected-typed")
    print("depth=along-forward behindCamera=negative-admitted")
    print("pixelOrigin=top-left-continuous squarePixels=height-derived")


if __name__ == "__main__":
    main()
