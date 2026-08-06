#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0204 and VOXELIA-ALG-0038."""

from __future__ import annotations

import hashlib
import struct


EXPECTED_FIXTURE_SHA256 = (
    "8dd30ec41bd27c11bebb15501739a46398294d86ff6e9956fd7aa1be2976e604"
)
EXPECTED_POSITION_SHA256 = (
    "0f0ee1270ffda5115052a0c370ecaae427ba5e2fbc26bb9e8b47e84b53521335"
)


def f64(value: float) -> float:
    return struct.unpack(">d", struct.pack(">d", value))[0]


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def add(a: float, b: float) -> float:
    return f64(f64(a) + f64(b))


def mul(a: float, b: float) -> float:
    return f64(f64(a) * f64(b))


def interpolate(positions, weights, swapped: bool):
    """Barycentric world position, in the frozen `((a + b) + c)` grouping.

    The weights arrive in the coverage rule's canonicalised order, so the
    swap flag maps them back exactly as it does for shading and colour.
    """
    original_b = weights[2] if swapped else weights[1]
    original_c = weights[1] if swapped else weights[2]
    out = []
    for lane in range(3):
        out.append(
            add(
                add(
                    mul(weights[0], positions[0][lane]),
                    mul(original_b, positions[1][lane]),
                ),
                mul(original_c, positions[2][lane]),
            )
        )
    return tuple(out)


def retained(position, bounds) -> bool:
    """The frozen inclusive axis-aligned world-box test.

    Inclusive on every face: the box is a closed region, and excluding its
    boundary would discard a zero-measure set for no reason while making the
    test disagree with the accepted `VolumeClipBounds` admission, which uses
    strict inequalities only to reject a degenerate box.
    """
    if bounds is None:
        return True
    minimum, maximum = bounds
    for lane in range(3):
        if position[lane] < minimum[lane]:
            return False
        if position[lane] > maximum[lane]:
            return False
    return True


def evaluate(positions, weights, swapped, bounds):
    world = interpolate(positions, weights, swapped)
    return world, retained(world, bounds)


def record(name: str, case) -> tuple[str, bytes]:
    world, kept = evaluate(*case)
    payload = bytearray()
    for component in world:
        payload.extend(struct.pack("<Q", bits(component)))
    return (
        f"{name}|kept={int(kept)}|world="
        + ",".join(f"{bits(c):016x}" for c in world),
        bytes(payload),
    )


UNIT_BOX = ((0.0, 0.0, 0.0), (1.0, 1.0, 1.0))
THIRDS = (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)


def uniform(point):
    return (point, point, point)


def main() -> None:
    # 1. A fragment strictly inside the box is retained.
    inside = (uniform((0.5, 0.5, 0.5)), THIRDS, False, UNIT_BOX)
    assert evaluate(*inside)[1]

    # 2. A fragment outside on each of the six faces is discarded. Clipping
    #    is a per-fragment predicate, so no geometry is cut or synthesised.
    outside_cases = []
    for lane in range(3):
        for offset in (-1.0, 2.0):
            point = [0.5, 0.5, 0.5]
            point[lane] = offset
            case = (uniform(tuple(point)), THIRDS, False, UNIT_BOX)
            assert not evaluate(*case)[1]
            outside_cases.append(case)

    # 3. THE boundary rule: a fragment exactly on a face is RETAINED. The box
    #    is a closed region, so its boundary belongs to it.
    on_face = (uniform((0.0, 0.5, 0.5)), THIRDS, False, UNIT_BOX)
    on_far_face = (uniform((0.5, 1.0, 0.5)), THIRDS, False, UNIT_BOX)
    assert evaluate(*on_face)[1]
    assert evaluate(*on_far_face)[1]

    # 4. A fragment exactly on a corner is retained on all three axes at once.
    on_corner = (uniform((0.0, 0.0, 0.0)), THIRDS, False, UNIT_BOX)
    on_far_corner = (uniform((1.0, 1.0, 1.0)), THIRDS, False, UNIT_BOX)
    assert evaluate(*on_corner)[1]
    assert evaluate(*on_far_corner)[1]

    # 5. A straddling facet keeps some fragments and discards others, which is
    #    what makes an uncapped cut legible: no facet is all-or-nothing.
    straddling = ((-1.0, 0.5, 0.5), (0.5, 0.5, 0.5), (2.0, 0.5, 0.5))
    near_first = (straddling, (1.0, 0.0, 0.0), False, UNIT_BOX)
    near_second = (straddling, (0.0, 1.0, 0.0), False, UNIT_BOX)
    near_third = (straddling, (0.0, 0.0, 1.0), False, UNIT_BOX)
    assert not evaluate(*near_first)[1]
    assert evaluate(*near_second)[1]
    assert not evaluate(*near_third)[1]

    # 6. The swap flag maps weights back to original vertex order, so a
    #    consumer ignoring it would clip the wrong fragments on mirrored
    #    facets.
    # Equal second and third weights make the swap a no-op, which isolates
    # the mapping from the arithmetic.
    skewed = (straddling, (0.5, 0.25, 0.25), False, UNIT_BOX)
    swapped = (straddling, (0.5, 0.25, 0.25), True, UNIT_BOX)
    assert evaluate(*skewed)[0] == evaluate(*swapped)[0]
    asymmetric = ((0.0, 0.0, 0.0), (4.0, 0.0, 0.0), (0.0, 4.0, 0.0))
    skew_weights = (0.5, 0.25, 0.125)
    plain = (asymmetric, skew_weights, False, UNIT_BOX)
    mapped = (asymmetric, skew_weights, True, UNIT_BOX)
    assert evaluate(*plain)[0] != evaluate(*mapped)[0]

    # 7. An absent clip retains everything, so the unclipped path is the same
    #    code with no special case.
    unclipped = (uniform((99.0, 99.0, 99.0)), THIRDS, False, None)
    assert evaluate(*unclipped)[1]

    # 8. A negative box works: the test is a comparison, not a sign rule.
    negative_box = ((-2.0, -2.0, -2.0), (-1.0, -1.0, -1.0))
    in_negative = (uniform((-1.5, -1.5, -1.5)), THIRDS, False, negative_box)
    out_negative = (uniform((0.0, 0.0, 0.0)), THIRDS, False, negative_box)
    assert evaluate(*in_negative)[1]
    assert not evaluate(*out_negative)[1]

    fixtures = [
        ("inside", inside),
        ("on-near-face", on_face),
        ("on-far-face", on_far_face),
        ("on-near-corner", on_corner),
        ("on-far-corner", on_far_corner),
        ("straddling-first", near_first),
        ("straddling-second", near_second),
        ("straddling-third", near_third),
        ("skewed-weights", skewed),
        ("swapped-weights", mapped),
        ("no-clip", unclipped),
        ("inside-negative-box", in_negative),
        ("outside-negative-box", out_negative),
    ]
    for index, case in enumerate(outside_cases):
        fixtures.append((f"outside-{index}", case))

    records = []
    payload = bytearray()
    for name, case in fixtures:
        fixture_record, output_bytes = record(name, case)
        records.append(fixture_record)
        payload.extend(output_bytes)

    fixture_digest = hashlib.sha256(
        "\n".join(records).encode("ascii")
    ).hexdigest()
    position_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert position_digest == EXPECTED_POSITION_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"positionSHA256={position_digest}")
    print(f"fixtures={len(fixtures)} successful={len(fixtures)} failures=0")
    print("clip=per-fragment-world-box boundary=inclusive capping=absent")
    print("geometry=never-cut absentClip=retains-everything")


if __name__ == "__main__":
    main()
