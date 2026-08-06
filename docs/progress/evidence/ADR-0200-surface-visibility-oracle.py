#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0200 and VOXELIA-ALG-0034."""

from __future__ import annotations

import hashlib
import math
import struct


EXPECTED_FIXTURE_SHA256 = (
    "f4f92219f39a9adaf634b1f60c5316a3b731c8c5722c67e45fb898f055ba2d43"
)
EXPECTED_BUFFER_SHA256 = (
    "35f0ccfd0811b51ba75150fee53b92a57f30f92b5a147381d52f7b009bd90725"
)


class VisibilityFailure(Exception):
    """One payload-free oracle classification."""


def f64(value: float) -> float:
    return struct.unpack(">d", struct.pack(">d", value))[0]


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def checked(value: float) -> float:
    rounded = f64(value)
    if not math.isfinite(rounded):
        raise VisibilityFailure("coverageNotRepresentable")
    return rounded


def sub(a: float, b: float) -> float:
    return checked(f64(a) - f64(b))


def add(a: float, b: float) -> float:
    return checked(f64(a) + f64(b))


def mul(a: float, b: float) -> float:
    return checked(f64(a) * f64(b))


def div(a: float, b: float) -> float:
    return checked(f64(a) / f64(b))


def edge(a, b, column: float, row: float) -> float:
    """The frozen ordered edge function for the directed edge `a -> b`."""
    return sub(
        mul(sub(b[0], a[0]), sub(row, a[1])),
        mul(sub(b[1], a[1]), sub(column, a[0])),
    )


def is_top_left(a, b) -> bool:
    """The frozen fill rule, evaluated on a positive-area winding.

    Viewport rows increase downward. An edge belongs to its triangle when it
    is horizontal with the interior below it, or when it descends. Exactly one
    of two triangles sharing an edge therefore claims a sample lying on it.
    """
    if a[1] == b[1]:
        return b[0] < a[0]
    return b[1] > a[1]


def orient(p0, p1, p2):
    """Canonicalise to positive projected area, returning the ordered trio.

    A projection may mirror a triangle, so the winding on screen is not the
    mesh winding. Swapping the last two vertices is the frozen
    canonicalisation; back-facing triangles are NOT culled.
    """
    area = sub(
        mul(sub(p1[0], p0[0]), sub(p2[1], p0[1])),
        mul(sub(p1[1], p0[1]), sub(p2[0], p0[0])),
    )
    if area == 0.0:
        return None
    if area < 0.0:
        p1, p2 = p2, p1
        area = sub(
            mul(sub(p1[0], p0[0]), sub(p2[1], p0[1])),
            mul(sub(p1[1], p0[1]), sub(p2[0], p0[0])),
        )
    return p0, p1, p2, area


def rasterise(p0, p1, p2, width: int, height: int):
    """Yield `(pixel, depth, weights)` for every covered sample."""
    oriented = orient(p0, p1, p2)
    if oriented is None:
        return
    p0, p1, p2, area = oriented

    columns = [p0[0], p1[0], p2[0]]
    rows = [p0[1], p1[1], p2[1]]
    first_column = max(0, math.floor(min(columns)))
    last_column = min(width - 1, math.ceil(max(columns)))
    first_row = max(0, math.floor(min(rows)))
    last_row = min(height - 1, math.ceil(max(rows)))

    top_left = (is_top_left(p1, p2), is_top_left(p2, p0), is_top_left(p0, p1))
    for row_index in range(first_row, last_row + 1):
        for column_index in range(first_column, last_column + 1):
            sample_column = add(float(column_index), 0.5)
            sample_row = add(float(row_index), 0.5)
            e0 = edge(p1, p2, sample_column, sample_row)
            e1 = edge(p2, p0, sample_column, sample_row)
            e2 = edge(p0, p1, sample_column, sample_row)
            covered = True
            for value, claims in zip((e0, e1, e2), top_left):
                if value > 0.0:
                    continue
                if value == 0.0 and claims:
                    continue
                covered = False
                break
            if not covered:
                continue
            w0 = div(e0, area)
            w1 = div(e1, area)
            w2 = div(e2, area)
            depth = add(
                add(mul(w0, p0[2]), mul(w1, p1[2])), mul(w2, p2[2])
            )
            yield (column_index, row_index), depth, (w0, w1, w2)


def resolve(layers, width: int, height: int):
    """The frozen nearest-surface resolution over every layer and facet.

    A candidate replaces the incumbent only when its depth is STRICTLY less,
    so an exactly equal depth leaves the earlier `(layer, facet)` in place.
    The tie-break is therefore structural rather than a special case.
    """
    buffer: dict[tuple[int, int], tuple[float, tuple[float, float, float], int, int]] = {}
    for layer_index, triangles in enumerate(layers):
        for facet_ordinal, (p0, p1, p2) in enumerate(triangles):
            for pixel, depth, weights in rasterise(p0, p1, p2, width, height):
                incumbent = buffer.get(pixel)
                if incumbent is None or depth < incumbent[0]:
                    buffer[pixel] = (depth, weights, layer_index, facet_ordinal)
    return buffer


def record(name: str, case: dict) -> tuple[str, bytes]:
    try:
        buffer = resolve(case["layers"], case["width"], case["height"])
    except VisibilityFailure as error:
        return f"{name}|error={error}", b""
    tokens = []
    payload = bytearray()
    for row_index in range(case["height"]):
        for column_index in range(case["width"]):
            hit = buffer.get((column_index, row_index))
            if hit is None:
                tokens.append("-")
                continue
            depth, weights, layer_index, facet_ordinal = hit
            tokens.append(
                f"{layer_index}:{facet_ordinal}:{bits(depth):016x}"
            )
            payload.extend(struct.pack("<Q", bits(depth)))
            for weight in weights:
                payload.extend(struct.pack("<Q", bits(weight)))
    return f"{name}|covered={len(buffer)}|{','.join(tokens)}", bytes(payload)


def triangle(a, b, c):
    return (a, b, c)


def main() -> None:
    # 1. One facet covering the whole four-by-four viewport at depth five.
    full = triangle((-4.0, -4.0, 5.0), (12.0, -4.0, 5.0), (-4.0, 12.0, 5.0))
    full_case = {"layers": [[full]], "width": 4, "height": 4}
    buffer = resolve(**full_case)
    assert len(buffer) == 16
    assert all(depth == 5.0 for depth, _, _, _ in buffer.values())

    # 2. Pixel-centre sampling: a facet covering only the centre of pixel
    #    (0, 0) covers exactly that pixel and nothing else.
    tiny = triangle((0.4, 0.4, 1.0), (0.9, 0.4, 1.0), (0.4, 0.9, 1.0))
    tiny_case = {"layers": [[tiny]], "width": 4, "height": 4}
    tiny_buffer = resolve(**tiny_case)
    assert set(tiny_buffer) == {(0, 0)}

    # 3. THE fill-rule obligation: two facets sharing a diagonal tile a quad
    #    with every pixel covered EXACTLY once. Without a top-left rule a
    #    sample on the shared edge would be claimed twice or not at all.
    quad_a = triangle((0.0, 0.0, 1.0), (4.0, 0.0, 1.0), (0.0, 4.0, 1.0))
    quad_b = triangle((4.0, 0.0, 1.0), (4.0, 4.0, 1.0), (0.0, 4.0, 1.0))
    counts: dict[tuple[int, int], int] = {}
    for facet in (quad_a, quad_b):
        for pixel, _, _ in rasterise(*facet, 4, 4):
            counts[pixel] = counts.get(pixel, 0) + 1
    assert len(counts) == 16
    assert set(counts.values()) == {1}
    quad_case = {"layers": [[quad_a, quad_b]], "width": 4, "height": 4}

    # 4. Nearest wins: a nearer facet fully replaces a farther one.
    far = triangle((-4.0, -4.0, 9.0), (12.0, -4.0, 9.0), (-4.0, 12.0, 9.0))
    near = triangle((-4.0, -4.0, 2.0), (12.0, -4.0, 2.0), (-4.0, 12.0, 2.0))
    depth_case = {"layers": [[far], [near]], "width": 4, "height": 4}
    depth_buffer = resolve(**depth_case)
    assert all(layer == 1 for _, _, layer, _ in depth_buffer.values())
    assert all(depth == 2.0 for depth, _, _, _ in depth_buffer.values())

    # 5. THE tie-break obligation: two coplanar facets at exactly equal depth.
    #    The earlier (layer, facet) keeps the pixel, because a candidate must
    #    be STRICTLY nearer to replace an incumbent.
    tie_case = {"layers": [[full], [full]], "width": 4, "height": 4}
    tie_buffer = resolve(**tie_case)
    assert all(layer == 0 for _, _, layer, _ in tie_buffer.values())
    assert all(facet == 0 for _, _, _, facet in tie_buffer.values())
    # Within one layer the earlier FACET keeps the pixel for the same reason.
    same_layer_tie = resolve([[full, full]], 4, 4)
    assert all(facet == 0 for _, _, _, facet in same_layer_tie.values())

    # 6. Back-facing facets are NOT culled: the same facet wound both ways
    #    covers exactly the same pixels with the same depths.
    reversed_full = triangle(full[0], full[2], full[1])
    forward_buffer = resolve([[full]], 4, 4)
    backward_buffer = resolve([[reversed_full]], 4, 4)
    assert set(forward_buffer) == set(backward_buffer)
    assert all(
        forward_buffer[pixel][0] == backward_buffer[pixel][0]
        for pixel in forward_buffer
    )
    backface_case = {"layers": [[reversed_full]], "width": 4, "height": 4}

    # 7. A facet projecting to zero area covers nothing and is not an error.
    degenerate = triangle((0.0, 0.0, 1.0), (4.0, 4.0, 1.0), (2.0, 2.0, 1.0))
    degenerate_case = {"layers": [[degenerate]], "width": 4, "height": 4}
    assert resolve(**degenerate_case) == {}

    # 8. Negative depth is admitted: there is no near plane in version one.
    behind = triangle((-4.0, -4.0, -3.0), (12.0, -4.0, -3.0), (-4.0, 12.0, -3.0))
    behind_case = {"layers": [[behind], [full]], "width": 4, "height": 4}
    behind_buffer = resolve(**behind_case)
    assert all(depth == -3.0 for depth, _, _, _ in behind_buffer.values())

    # 9. A facet entirely outside the viewport covers nothing.
    outside = triangle((20.0, 20.0, 1.0), (24.0, 20.0, 1.0), (20.0, 24.0, 1.0))
    outside_case = {"layers": [[outside]], "width": 4, "height": 4}
    assert resolve(**outside_case) == {}

    # 10. A partially clipped facet covers only its in-viewport samples.
    straddling = triangle((-2.0, -2.0, 4.0), (6.0, -2.0, 4.0), (-2.0, 6.0, 4.0))
    straddling_case = {"layers": [[straddling]], "width": 4, "height": 4}
    straddling_buffer = resolve(**straddling_case)
    assert straddling_buffer
    assert all(
        0 <= column < 4 and 0 <= row < 4 for column, row in straddling_buffer
    )

    # 11. Interpolated depth varies across a tilted facet.
    tilted = triangle((-4.0, -4.0, 1.0), (12.0, -4.0, 9.0), (-4.0, 12.0, 1.0))
    tilted_case = {"layers": [[tilted]], "width": 4, "height": 4}
    tilted_buffer = resolve(**tilted_case)
    assert len({depth for depth, _, _, _ in tilted_buffer.values()}) > 1

    # 12. An empty scene covers nothing.
    empty_case = {"layers": [], "width": 4, "height": 4}
    assert resolve(**empty_case) == {}

    # 13. An extreme but finite projection overflows the edge function. The
    #     projector admits these coordinates, so this failure is reachable.
    overflowing = triangle(
        (0.0, 0.0, 1.0), (1e200, 0.0, 1.0), (0.0, 1e200, 1.0)
    )
    overflow_case = {"layers": [[overflowing]], "width": 4, "height": 4}
    try:
        resolve(**overflow_case)
    except VisibilityFailure as error:
        assert str(error) == "coverageNotRepresentable"
    else:
        raise AssertionError("An overflowing edge function must fail.")

    fixtures = (
        ("full-cover", full_case),
        ("pixel-centre", tiny_case),
        ("shared-edge-quad", quad_case),
        ("nearest-wins", depth_case),
        ("equal-depth-tie", tie_case),
        ("backface-not-culled", backface_case),
        ("degenerate-projection", degenerate_case),
        ("negative-depth", behind_case),
        ("outside-viewport", outside_case),
        ("straddling-viewport", straddling_case),
        ("tilted-depth", tilted_case),
        ("empty-scene", empty_case),
        ("edge-function-overflow", overflow_case),
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
    buffer_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert buffer_digest == EXPECTED_BUFFER_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"bufferSHA256={buffer_digest}")
    print(f"fixtures={len(fixtures)} successful={len(fixtures) - 1} failures=1")
    print("sampling=pixel-centre fillRule=top-left backfaces=not-culled")
    print("tieBreak=strictly-nearer-replaces depthRange=unbounded")


if __name__ == "__main__":
    main()
