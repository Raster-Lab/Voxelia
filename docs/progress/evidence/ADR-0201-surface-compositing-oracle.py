#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0201 and VOXELIA-ALG-0035."""

from __future__ import annotations

import hashlib
import math
import struct


EXPECTED_FIXTURE_SHA256 = (
    "43c71d094dcf0cb932d9789c6f5f8fafa254bb715ccf73d65111ef1c58611dc5"
)
EXPECTED_WEIGHT_SHA256 = (
    "860a28e69c4b797acaad62fb311a7ad60df96973eb8aa8a1773fd7fcd56a91d0"
)


def f64(value: float) -> float:
    return struct.unpack(">d", struct.pack(">d", value))[0]


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def sub(a: float, b: float) -> float:
    return f64(f64(a) - f64(b))


def add(a: float, b: float) -> float:
    return f64(f64(a) + f64(b))


def mul(a: float, b: float) -> float:
    return f64(f64(a) * f64(b))


def order_key(fragment):
    """The frozen strict total order over one pixel's fragments.

    `(layer, facet)` is unique per pixel because one facet covers a pixel at
    most once, so this triple never ties and no arbitrary winner can arise.
    """
    depth, layer, facet, _opacity = fragment
    return (depth, layer, facet)


def composite(fragments):
    """Front-to-back per-object opacity weights and the accumulated alpha.

    Colour never appears: the contribution weight of a fragment is fixed by
    opacity and order alone, so shading and colour mapping multiply into these
    weights later without changing them.
    """
    ordered = sorted(fragments, key=order_key)
    accumulated = 0.0
    contributions = []
    for depth, layer, facet, opacity in ordered:
        remaining = sub(1.0, accumulated)
        contribution = mul(opacity, remaining)
        accumulated = add(accumulated, contribution)
        contributions.append((depth, layer, facet, contribution))
    return contributions, accumulated


def fragment(depth: float, layer: int, facet: int, opacity: float):
    return (depth, layer, facet, opacity)


def record(name: str, fragments) -> tuple[str, bytes]:
    contributions, accumulated = composite(fragments)
    tokens = []
    payload = bytearray()
    for depth, layer, facet, contribution in contributions:
        tokens.append(f"{layer}:{facet}:{bits(contribution):016x}")
        payload.extend(struct.pack("<Q", bits(contribution)))
    payload.extend(struct.pack("<Q", bits(accumulated)))
    return (
        f"{name}|count={len(contributions)}"
        f"|alpha={bits(accumulated):016x}|{','.join(tokens)}",
        bytes(payload),
    )


def main() -> None:
    # 1. One fully opaque fragment contributes everything.
    single_opaque = [fragment(1.0, 0, 0, 1.0)]
    contributions, alpha = composite(single_opaque)
    assert contributions[0][3] == 1.0
    assert alpha == 1.0

    # 2. One half-opaque fragment contributes exactly half.
    single_half = [fragment(1.0, 0, 0, 0.5)]
    contributions, alpha = composite(single_half)
    assert contributions[0][3] == 0.5
    assert alpha == 0.5

    # 3. Two half-opaque fragments: the farther one sees the remaining half.
    two_half = [fragment(1.0, 0, 0, 0.5), fragment(2.0, 1, 0, 0.5)]
    contributions, alpha = composite(two_half)
    assert [c[3] for c in contributions] == [0.5, 0.25]
    assert alpha == 0.75

    # 4. A nearer opaque fragment leaves the farther one exactly zero weight,
    #    which is occlusion falling out of the accumulation rather than a
    #    special case.
    occluded = [fragment(1.0, 0, 0, 1.0), fragment(5.0, 1, 0, 0.75)]
    contributions, alpha = composite(occluded)
    assert [c[3] for c in contributions] == [1.0, 0.0]
    assert alpha == 1.0

    # 5. Supply order does not matter: fragments sort by depth first.
    reverse_supplied = [fragment(5.0, 1, 0, 0.5), fragment(1.0, 0, 0, 0.5)]
    forward_supplied = [fragment(1.0, 0, 0, 0.5), fragment(5.0, 1, 0, 0.5)]
    assert composite(reverse_supplied) == composite(forward_supplied)

    # 6. THE ordering obligation, part one: equal depth resolves by layer.
    equal_layer = [fragment(3.0, 1, 0, 1.0), fragment(3.0, 0, 0, 0.25)]
    contributions, _ = composite(equal_layer)
    assert contributions[0][1] == 0
    assert contributions[0][3] == 0.25

    # 7. THE ordering obligation, part two: equal depth and layer resolve by
    #    facet ordinal. The triple is a strict total order, so no pair of
    #    fragments at one pixel can tie.
    equal_facet = [fragment(3.0, 0, 7, 1.0), fragment(3.0, 0, 2, 0.25)]
    contributions, _ = composite(equal_facet)
    assert contributions[0][2] == 2
    assert contributions[0][3] == 0.25

    # 8. A zero-opacity fragment is retained and weighs exactly zero. Dropping
    #    it would make the fragment list depend on a presentation parameter.
    with_transparent = [
        fragment(1.0, 0, 0, 0.0),
        fragment(2.0, 1, 0, 0.5),
    ]
    contributions, alpha = composite(with_transparent)
    assert len(contributions) == 2
    assert contributions[0][3] == 0.0
    assert contributions[1][3] == 0.5
    assert alpha == 0.5

    # 9. Accumulated alpha never exceeds one, and never decreases, over a long
    #    chain. This is why the arithmetic needs no representability failure.
    many = [fragment(float(index), index, 0, 0.5) for index in range(24)]
    contributions, alpha = composite(many)
    running = 0.0
    for _, _, _, contribution in contributions:
        assert contribution >= 0.0
        running = add(running, contribution)
        assert running <= 1.0
    assert alpha <= 1.0
    assert alpha == running
    assert all(math.isfinite(c[3]) for c in contributions)

    # 10. Once alpha reaches exactly one, every later weight is exactly zero,
    #     so stopping early is bit-identical to continuing.
    saturating = [fragment(1.0, 0, 0, 1.0)] + [
        fragment(float(index + 2), index + 1, 0, 0.9) for index in range(5)
    ]
    contributions, alpha = composite(saturating)
    assert contributions[0][3] == 1.0
    assert all(c[3] == 0.0 for c in contributions[1:])
    assert alpha == 1.0

    # 11. An uncovered pixel composites to nothing at zero alpha.
    empty: list = []
    contributions, alpha = composite(empty)
    assert contributions == []
    assert alpha == 0.0

    # 12. A repeating non-representable opacity exercises ordinary rounding.
    thirds = [fragment(float(index), index, 0, 1.0 / 3.0) for index in range(4)]
    contributions, alpha = composite(thirds)
    assert alpha < 1.0
    assert all(0.0 < c[3] < 1.0 for c in contributions)

    fixtures = (
        ("single-opaque", single_opaque),
        ("single-half", single_half),
        ("two-half", two_half),
        ("opaque-occludes", occluded),
        ("reverse-supplied", reverse_supplied),
        ("equal-depth-layer-order", equal_layer),
        ("equal-depth-facet-order", equal_facet),
        ("zero-opacity-retained", with_transparent),
        ("long-chain", many),
        ("saturating", saturating),
        ("empty", empty),
        ("repeating-thirds", thirds),
    )
    records = []
    payload = bytearray()
    for name, fragments in fixtures:
        fixture_record, output_bytes = record(name, fragments)
        records.append(fixture_record)
        payload.extend(output_bytes)

    fixture_digest = hashlib.sha256(
        "\n".join(records).encode("ascii")
    ).hexdigest()
    weight_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert weight_digest == EXPECTED_WEIGHT_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"weightSHA256={weight_digest}")
    print(f"fixtures={len(fixtures)} successful={len(fixtures)} failures=0")
    print("order=depth,layer,facet blend=front-to-back opacity=per-object")
    print("zeroOpacity=retained alphaBound=one colour=absent")


if __name__ == "__main__":
    main()
