#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0194 and VOXELIA-ALG-0031."""

from __future__ import annotations

import hashlib
import math
import struct


UINT64_MAX = (1 << 64) - 1
INT64_MAX = (1 << 63) - 1
POSITIVE_ZERO_BITS = 0
THREE_BITS = 0x4008000000000000
NINE_BITS = 0x4022000000000000
HALF_ROOT_TWO_BITS = 0x3FE6A09E667F3BCD
POWER_FIFTY_THREE_BITS = 0x4340000000000000
POWER_FIFTY_THREE_PLUS_TWO_BITS = 0x4340000000000001
CONTRACTION_SEPARATED_BITS = 0x3E40000000000000
EXPECTED_FIXTURE_SHA256 = (
    "38bad8cfd458b0dca99df2522e34124d51fe607f7fa428fa9f7a586c661d6feb"
)
EXPECTED_TOTAL_BYTES_SHA256 = (
    "8a8af5729b9008d759b9886eb757b31a85cf6dab22d07696b06062f3df668605"
)


class AreaFailure(Exception):
    """One payload-free oracle classification."""


def f64(value: float) -> float:
    return struct.unpack(">d", struct.pack(">d", value))[0]


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def checked(value: float) -> float:
    rounded = f64(value)
    if not math.isfinite(rounded):
        raise AreaFailure("areaNotRepresentable")
    return rounded


def sub(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) - f64(rhs))


def mul(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) * f64(rhs))


def add(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) + f64(rhs))


def div(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) / f64(rhs))


def root(value: float) -> float:
    return checked(math.sqrt(f64(value)))


def cross(
    p0: tuple[float, float, float],
    p1: tuple[float, float, float],
    p2: tuple[float, float, float],
) -> tuple[float, float, float]:
    """The exact ordered doubled-area vector shared with VOXELIA-ALG-0030."""
    e10 = tuple(sub(p1[lane], p0[lane]) for lane in range(3))
    e20 = tuple(sub(p2[lane], p0[lane]) for lane in range(3))
    return (
        sub(mul(e10[1], e20[2]), mul(e10[2], e20[1])),
        sub(mul(e10[2], e20[0]), mul(e10[0], e20[2])),
        sub(mul(e10[0], e20[1]), mul(e10[1], e20[0])),
    )


def facet_area(
    p0: tuple[float, float, float],
    p1: tuple[float, float, float],
    p2: tuple[float, float, float],
) -> float:
    """One unsigned facet area from the maximum-component-scaled magnitude."""
    face = cross(p0, p1, p2)
    scale = max(abs(component) for component in face)
    if scale == 0.0:
        return 0.0
    scaled = tuple(div(component, scale) for component in face)
    squared0 = mul(scaled[0], scaled[0])
    squared1 = mul(scaled[1], scaled[1])
    squared2 = mul(scaled[2], scaled[2])
    squared_sum = add(add(squared0, squared1), squared2)
    scaled_norm = root(squared_sum)
    doubled = mul(scale, scaled_norm)
    return mul(doubled, 0.5)


def total_facet_area(
    positions: tuple[tuple[float, float, float], ...],
    triangles: tuple[tuple[int, int, int], ...],
) -> float:
    """The frozen serial topology-order reduction over unsigned facet areas."""
    total = 0.0
    for triangle in triangles:
        area = facet_area(
            positions[triangle[0]],
            positions[triangle[1]],
            positions[triangle[2]],
        )
        total = add(total, area)
    return total


def record(
    name: str,
    positions: tuple[tuple[float, float, float], ...],
    triangles: tuple[tuple[int, int, int], ...],
) -> tuple[str, bytes]:
    try:
        total = total_facet_area(positions, triangles)
    except AreaFailure as error:
        return f"{name}|error={error}", b""
    return (
        f"{name}|facets={len(triangles)}|bits={bits(total):016x}",
        struct.pack("<Q", bits(total)),
    )


def main() -> None:
    # 1. One right triangle with legs two and three has exact area three.
    right_positions = ((0.0, 0.0, 0.0), (2.0, 0.0, 0.0), (0.0, 3.0, 0.0))
    right_triangles = ((0, 1, 2),)
    assert bits(total_facet_area(right_positions, right_triangles)) == THREE_BITS

    # 2. Reversing the winding cannot change an unsigned magnitude.
    reversed_triangles = ((0, 2, 1),)
    assert total_facet_area(right_positions, reversed_triangles) == total_facet_area(
        right_positions, right_triangles
    )

    # 3. A repeated facet retains its multiplicity; three copies total nine.
    duplicate_triangles = ((0, 1, 2),) * 3
    assert bits(total_facet_area(right_positions, duplicate_triangles)) == NINE_BITS

    # 4. A degenerate facet contributes exactly zero without removing itself.
    degenerate_triangles = ((0, 0, 1), (0, 1, 2))
    assert bits(
        total_facet_area(right_positions, degenerate_triangles)
    ) == THREE_BITS

    # 5. An empty mesh totals positive zero over zero facets.
    assert bits(total_facet_area((), ())) == POSITIVE_ZERO_BITS

    # 6. An all-degenerate mesh also totals positive, never negative, zero.
    all_degenerate = total_facet_area(right_positions, ((0, 0, 1), (2, 2, 2)))
    assert bits(all_degenerate) == POSITIVE_ZERO_BITS
    assert not math.copysign(1.0, all_degenerate) < 0.0

    # 7. An oblique facet exercises the scaled Euclidean magnitude.
    oblique_positions = ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 1.0))
    oblique = total_facet_area(oblique_positions, right_triangles)
    assert bits(oblique) == HALF_ROOT_TWO_BITS

    # 8. Serial topology order is part of the algorithm identity: the same
    #    three facets summed in the reverse order produce different bits.
    order_positions = (
        (0.0, 0.0, 0.0),
        (float.fromhex("0x1.0p+54"), 0.0, 0.0),
        (0.0, 1.0, 0.0),
        (1.5, 0.0, 0.0),
    )
    order_triangles = ((0, 1, 2), (0, 3, 2), (0, 3, 2))
    ordered = total_facet_area(order_positions, order_triangles)
    reordered = total_facet_area(order_positions, ((0, 3, 2), (0, 3, 2), (0, 1, 2)))
    assert bits(ordered) == POWER_FIFTY_THREE_BITS
    assert bits(reordered) == POWER_FIFTY_THREE_PLUS_TWO_BITS
    assert ordered != reordered

    # 9. Separated multiply-then-subtract is part of the identity: a fused
    #    cross-product component changes the published total.
    contraction_value = float.fromhex("0x1.0000002000000p+0")
    contraction_positions = (
        (0.0, 0.0, 0.0),
        (contraction_value, 1.0, 0.0),
        (1.0, contraction_value, 0.0),
    )
    contraction = total_facet_area(contraction_positions, right_triangles)
    separated_cross_z = cross(*contraction_positions)[2]
    contracted_cross_z = math.fma(contraction_value, contraction_value, -1.0)
    assert bits(separated_cross_z) == 0x3E50000000000000
    assert bits(contracted_cross_z) == 0x3E50000001000000
    assert bits(contraction) == CONTRACTION_SEPARATED_BITS
    # The whole doubled-area vector lies on one axis here, so a fused
    # multiply-subtract in the cross product reaches the published total.
    contracted_total = mul(abs(contracted_cross_z), 0.5)
    assert bits(contracted_total) != bits(contraction)

    # 10. A geometrically non-degenerate facet whose doubled area is the least
    #     subnormal halves to positive zero under ties-to-even. The frozen
    #     model publishes that zero rather than inferring nondegeneracy.
    least_subnormal = float.fromhex("0x0.0000000000001p-1022")
    subnormal_positions = (
        (0.0, 0.0, 0.0),
        (least_subnormal, 0.0, 0.0),
        (0.0, 1.0, 0.0),
    )
    subnormal = total_facet_area(subnormal_positions, right_triangles)
    assert bits(cross(*subnormal_positions)[2]) == 1
    assert bits(subnormal) == POSITIVE_ZERO_BITS

    # 11. Edge subtraction overflow fails before any geometric conclusion.
    greatest = float.fromhex("0x1.fffffffffffffp+1023")
    edge_overflow_positions = (
        (greatest, 0.0, 0.0),
        (-greatest, 0.0, 0.0),
        (0.0, 1.0, 0.0),
    )
    try:
        total_facet_area(edge_overflow_positions, right_triangles)
    except AreaFailure as error:
        assert str(error) == "areaNotRepresentable"
    else:
        raise AssertionError("Overflowing edge subtraction must fail.")

    # 12. A finite doubled-area vector whose scaled magnitude overflows fails
    #     rather than being rescaled by an alternative formulation.
    magnitude_positions = ((0.0, 0.0, 0.0), (1.5e200, 1.5e200, 0.0), (0.0, 0.0, 1e108))
    assert math.isfinite(f64(1.5e200 * 1e108))
    try:
        total_facet_area(magnitude_positions, right_triangles)
    except AreaFailure as error:
        assert str(error) == "areaNotRepresentable"
    else:
        raise AssertionError("Overflowing scaled magnitude must fail.")

    # 13. Serial accumulation overflow fails on the addition that produced it.
    accumulation_positions = (
        (0.0, 0.0, 0.0),
        (1.78e200, 0.0, 0.0),
        (0.0, 1e108, 0.0),
    )
    assert math.isfinite(facet_area(*accumulation_positions))
    try:
        total_facet_area(accumulation_positions, ((0, 1, 2),) * 3)
    except AreaFailure as error:
        assert str(error) == "areaNotRepresentable"
    else:
        raise AssertionError("Overflowing serial accumulation must fail.")

    fixtures = (
        ("right-triangle", right_positions, right_triangles),
        ("reversed-winding", right_positions, reversed_triangles),
        ("duplicate-multiplicity", right_positions, duplicate_triangles),
        ("degenerate-plus-valid", right_positions, degenerate_triangles),
        ("empty", (), ()),
        ("all-degenerate", right_positions, ((0, 0, 1), (2, 2, 2))),
        ("oblique-scaled", oblique_positions, right_triangles),
        ("accumulation-order-sensitive", order_positions, order_triangles),
        ("contraction-sensitive", contraction_positions, right_triangles),
        ("subnormal-underflow", subnormal_positions, right_triangles),
        ("edge-overflow", edge_overflow_positions, right_triangles),
        ("magnitude-overflow", magnitude_positions, right_triangles),
        ("accumulation-overflow", accumulation_positions, ((0, 1, 2),) * 3),
    )
    records = []
    total_bytes = bytearray()
    for name, positions, triangles in fixtures:
        fixture_record, output_bytes = record(name, positions, triangles)
        records.append(fixture_record)
        total_bytes.extend(output_bytes)

    fixture_payload = "\n".join(records).encode("ascii")
    fixture_digest = hashlib.sha256(fixture_payload).hexdigest()
    total_digest = hashlib.sha256(total_bytes).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert total_digest == EXPECTED_TOTAL_BYTES_SHA256

    # The operation owns no per-vertex or per-facet payload buffer: it reduces
    # already-owned immutable positions into one binary64 accumulator, so the
    # only checked admission is the two declared count ceilings. An admitted
    # source topology already owns `triangleCount * 3` host indices, so the
    # traversal offset cannot overflow the 64-bit Apple `Int` domain.
    maximum_triangle_count = INT64_MAX // 3
    assert maximum_triangle_count * 3 <= INT64_MAX
    assert (maximum_triangle_count + 1) * 3 > INT64_MAX
    assert maximum_triangle_count <= UINT64_MAX

    print(f"fixtureSHA256={fixture_digest}")
    print(f"totalBytesSHA256={total_digest}")
    print(f"fixtures={len(fixtures)} successful=10 failures=3")
    print("additionalLogicalByteCount=0 ceilings=vertexCount,triangleCount")
    print(f"maximumHostTriangleCount={maximum_triangle_count}")
    print("triangleCancellationOrdinals=0,64,128,...")
    print("orientation=unsigned-winding-independent emptyTotal=positive-zero")


if __name__ == "__main__":
    main()
