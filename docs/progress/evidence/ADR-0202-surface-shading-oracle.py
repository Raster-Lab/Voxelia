#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0202 and VOXELIA-ALG-0036."""

from __future__ import annotations

import hashlib
import math
import struct


EXPECTED_FIXTURE_SHA256 = (
    "a1f8fd3ff7933c12bcd269b94c05d2919fb78801bf99fabf15dc29b7f0514330"
)
EXPECTED_INTENSITY_SHA256 = (
    "c9dfc8df1e26cf1c4ebff61561fbc9c030290ecd426d79e72193fdb54c22cd37"
)


def f64(value: float) -> float:
    return struct.unpack(">d", struct.pack(">d", value))[0]


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def add(a: float, b: float) -> float:
    return f64(f64(a) + f64(b))


def mul(a: float, b: float) -> float:
    return f64(f64(a) * f64(b))


def div(a: float, b: float) -> float:
    return f64(f64(a) / f64(b))


def interpolate(normals, weights):
    """Barycentric interpolation in the frozen `((a + b) + c)` grouping.

    The weights are supplied in the mesh's ORIGINAL vertex order. The coverage
    rule canonicalises winding internally and must publish which way round it
    ended up, or a consumer cannot map a weight to the vertex it belongs to.
    """
    out = []
    for lane in range(3):
        out.append(
            add(
                add(
                    mul(weights[0], normals[0][lane]),
                    mul(weights[1], normals[1][lane]),
                ),
                mul(weights[2], normals[2][lane]),
            )
        )
    return tuple(out)


def shade(normals, weights, forward):
    """Two-sided Lambert headlight intensity in `[0, 1]`."""
    interpolated = interpolate(normals, weights)
    scale = max(abs(component) for component in interpolated)
    if scale == 0.0:
        # The interpolated direction is genuinely undefined. Shading is
        # presentation, not measurement, so this yields positive zero rather
        # than failing an entire render.
        return 0.0
    scaled = tuple(div(component, scale) for component in interpolated)
    squared_sum = add(
        add(mul(scaled[0], scaled[0]), mul(scaled[1], scaled[1])),
        mul(scaled[2], scaled[2]),
    )
    length = f64(math.sqrt(squared_sum))
    unit = tuple(div(component, length) for component in scaled)
    projection = add(
        add(mul(unit[0], forward[0]), mul(unit[1], forward[1])),
        mul(unit[2], forward[2]),
    )
    magnitude = abs(projection)
    # An exact clamp, not an epsilon: rounding in the normalisation and the
    # dot product can carry the magnitude just above one.
    return magnitude if magnitude < 1.0 else 1.0


def record(name: str, case) -> tuple[str, bytes]:
    intensity = shade(*case)
    return (
        f"{name}|intensity={bits(intensity):016x}",
        struct.pack("<Q", bits(intensity)),
    )


FORWARD_Z = (0.0, 0.0, 1.0)
EQUAL_THIRDS = (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)


def uniform(normal):
    return (normal, normal, normal)


def main() -> None:
    # 1. A surface facing the camera is fully lit.
    facing = (uniform((0.0, 0.0, -1.0)), EQUAL_THIRDS, FORWARD_Z)
    assert shade(*facing) == 1.0

    # 2. THE two-sided rule: a surface facing away is lit identically. A
    #    one-sided Lambert would render open extracted surfaces black inside.
    away = (uniform((0.0, 0.0, 1.0)), EQUAL_THIRDS, FORWARD_Z)
    assert shade(*away) == 1.0
    assert shade(*away) == shade(*facing)

    # 3. A surface edge-on to the camera is unlit.
    edge_on = (uniform((1.0, 0.0, 0.0)), EQUAL_THIRDS, FORWARD_Z)
    assert shade(*edge_on) == 0.0

    # 4. Forty-five degrees gives the scaled rule's own root of one half.
    #    Note this is `1 / sqrt(2)` under the frozen scaled normalisation, not
    #    `sqrt(0.5)`: the two differ in the last place, which is exactly why
    #    the normalisation expression is part of the algorithm identity.
    diagonal = (uniform((0.0, 1.0, 1.0)), EQUAL_THIRDS, FORWARD_Z)
    assert shade(*diagonal) == div(1.0, f64(math.sqrt(2.0)))

    # 5. A weight of one at a vertex reproduces that vertex's own shading.
    mixed = ((0.0, 0.0, -1.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0))
    at_vertex = (mixed, (1.0, 0.0, 0.0), FORWARD_Z)
    assert shade(*at_vertex) == 1.0
    at_second = (mixed, (0.0, 1.0, 0.0), FORWARD_Z)
    assert shade(*at_second) == 0.0

    # 6. Interpolation across differing normals lands strictly between.
    interpolated = (mixed, EQUAL_THIRDS, FORWARD_Z)
    assert 0.0 < shade(*interpolated) < 1.0

    # 7. Exactly cancelling normals leave an undefined direction, which yields
    #    positive zero rather than failing the render. This deliberately
    #    differs from ADR-0193, which rejects an undefined PUBLISHED normal.
    cancelling = (
        ((0.0, 0.0, 1.0), (0.0, 0.0, -1.0), (1.0, 0.0, 0.0)),
        (0.5, 0.5, 0.0),
        FORWARD_Z,
    )
    assert bits(shade(*cancelling)) == bits(0.0)

    # 8. THE clamp obligation: rounding alone can carry the magnitude above
    #    one, so the exact clamp is reachable rather than defensive.
    steep = (
        float.fromhex("-0x1.c49bee0b8ed14p-1"),
        float.fromhex("0x1.e74ee6deceb80p-7"),
        float.fromhex("-0x1.d99abcf4ffae6p-1"),
    )
    scale = max(abs(component) for component in steep)
    scaled = tuple(div(component, scale) for component in steep)
    squared_sum = add(
        add(mul(scaled[0], scaled[0]), mul(scaled[1], scaled[1])),
        mul(scaled[2], scaled[2]),
    )
    unit = tuple(
        div(component, f64(math.sqrt(squared_sum))) for component in scaled
    )
    raw = add(
        add(mul(unit[0], unit[0]), mul(unit[1], unit[1])),
        mul(unit[2], unit[2]),
    )
    assert raw > 1.0
    clamped = (uniform(steep), EQUAL_THIRDS, unit)
    assert shade(*clamped) == 1.0

    # 9. A least-subnormal normal weighted by one third UNDERFLOWS to an
    #    exactly zero direction, so the interpolation — not the normalisation
    #    — is what loses it. The frozen model publishes the resulting positive
    #    zero rather than inferring the direction the inputs implied.
    tiny = float.fromhex("0x0.0000000000001p-1022")
    subnormal = (uniform((0.0, 0.0, -tiny)), EQUAL_THIRDS, FORWARD_Z)
    assert mul(EQUAL_THIRDS[0], tiny) == 0.0
    assert bits(shade(*subnormal)) == bits(0.0)

    # 9b. The same subnormal normal at full weight survives, because the
    #     scaled normalisation never forms an underflowing sum of squares.
    subnormal_at_vertex = (
        uniform((0.0, 0.0, -tiny)),
        (1.0, 0.0, 0.0),
        FORWARD_Z,
    )
    assert shade(*subnormal_at_vertex) == 1.0

    # 10. An oblique forward axis exercises the full dot product.
    oblique_forward = tuple(
        div(component, f64(math.sqrt(3.0))) for component in (1.0, 1.0, 1.0)
    )
    oblique = (uniform((0.0, 0.0, -1.0)), EQUAL_THIRDS, oblique_forward)
    assert 0.0 < shade(*oblique) < 1.0

    # 11. Unequal weights are honoured in their supplied order, so a consumer
    #     that mixed up the canonicalised swap would get a different answer.
    skew_normals = ((1.0, 0.0, 0.0), (0.0, 0.0, -1.0), (0.0, 0.6, -0.8))
    skew_weights = (0.5, 0.25, 0.125)
    skewed = (skew_normals, skew_weights, FORWARD_Z)
    mis_mapped = (
        (skew_normals[0], skew_normals[2], skew_normals[1]),
        skew_weights,
        FORWARD_Z,
    )
    assert shade(*skewed) != shade(*mis_mapped)

    fixtures = (
        ("facing-camera", facing),
        ("facing-away", away),
        ("edge-on", edge_on),
        ("forty-five", diagonal),
        ("weight-at-first-vertex", at_vertex),
        ("weight-at-second-vertex", at_second),
        ("interpolated", interpolated),
        ("cancelling-normals", cancelling),
        ("rounding-clamped", clamped),
        ("subnormal-underflows", subnormal),
        ("subnormal-at-vertex", subnormal_at_vertex),
        ("oblique-forward", oblique),
        ("skewed-weights", skewed),
        ("mis-mapped-weights", mis_mapped),
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
    intensity_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert intensity_digest == EXPECTED_INTENSITY_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"intensitySHA256={intensity_digest}")
    print(f"fixtures={len(fixtures)} successful={len(fixtures)} failures=0")
    print("material=two-sided-lambert-headlight intensity=[0,1] clamp=exact")
    print("undefinedNormal=positive-zero colour=absent")


if __name__ == "__main__":
    main()
