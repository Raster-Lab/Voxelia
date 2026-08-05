#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0193 and VOXELIA-ALG-0030."""

from __future__ import annotations

import hashlib
import math
import struct


UINT64_MAX = (1 << 64) - 1
INT64_MAX = (1 << 63) - 1
POSITIVE_ZERO_BITS = 0
POSITIVE_ONE_BITS = 0x3FF0000000000000
NEGATIVE_ONE_BITS = 0xBFF0000000000000
WEIGHTED_Y_BITS = 0x3FEC9F25C5BFEDD9
WEIGHTED_Z_BITS = 0x3FDC9F25C5BFEDD9
ORDERED_YZ_BITS = 0x3FE6A09E667F3BCC
CONTRACTION_X_BITS = 0x3FE6A09E651531E6
CONTRACTION_Y_BITS = 0xBFE6A09E67E945B3
CONTRACTION_Z_BITS = 0x3E46A09E651531E6
EXPECTED_FIXTURE_SHA256 = (
    "1306df51656d104cfacc9cafc5f2fd7910bbe0104e10a435326310d94d6c94fc"
)
EXPECTED_ATTRIBUTE_SHA256 = (
    "076b11f527589e716986a14a99ff86590b592b95f948ca6b6309627baff96d17"
)


class NormalFailure(Exception):
    """One payload-free oracle classification."""


def f64(value: float) -> float:
    return struct.unpack(">d", struct.pack(">d", value))[0]


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def checked(value: float) -> float:
    rounded = f64(value)
    if not math.isfinite(rounded):
        raise NormalFailure("normalNotRepresentable")
    return rounded


def sub(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) - f64(rhs))


def mul(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) * f64(rhs))


def add(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) + f64(rhs))


def cross(
    p0: tuple[float, float, float],
    p1: tuple[float, float, float],
    p2: tuple[float, float, float],
) -> tuple[float, float, float]:
    e10 = tuple(sub(p1[lane], p0[lane]) for lane in range(3))
    e20 = tuple(sub(p2[lane], p0[lane]) for lane in range(3))
    return (
        sub(mul(e10[1], e20[2]), mul(e10[2], e20[1])),
        sub(mul(e10[2], e20[0]), mul(e10[0], e20[2])),
        sub(mul(e10[0], e20[1]), mul(e10[1], e20[0])),
    )


def normalise(vector: tuple[float, float, float]) -> tuple[float, float, float]:
    scale = max(abs(component) for component in vector)
    if scale == 0.0:
        raise NormalFailure("undefinedNormal")
    scaled = tuple(checked(component / scale) for component in vector)
    squared0 = mul(scaled[0], scaled[0])
    squared1 = mul(scaled[1], scaled[1])
    squared2 = mul(scaled[2], scaled[2])
    squared_sum = add(add(squared0, squared1), squared2)
    norm = checked(math.sqrt(squared_sum))
    output = []
    for component in scaled:
        value = checked(component / norm)
        output.append(0.0 if value == 0.0 else value)
    return (output[0], output[1], output[2])


def generate(
    positions: tuple[tuple[float, float, float], ...],
    triangles: tuple[tuple[int, int, int], ...],
) -> tuple[tuple[float, float, float], ...]:
    accumulators = [[0.0, 0.0, 0.0] for _ in positions]
    for triangle in triangles:
        face = cross(
            positions[triangle[0]],
            positions[triangle[1]],
            positions[triangle[2]],
        )
        for vertex in triangle:
            for lane in range(3):
                accumulators[vertex][lane] = add(
                    accumulators[vertex][lane], face[lane]
                )
    return tuple(normalise(tuple(value)) for value in accumulators)


def record(
    name: str,
    positions: tuple[tuple[float, float, float], ...],
    triangles: tuple[tuple[int, int, int], ...],
) -> tuple[str, bytes]:
    try:
        normals = generate(positions, triangles)
    except NormalFailure as error:
        return f"{name}|error={error}", b""
    bit_tokens = [f"{bits(component):016x}" for normal in normals for component in normal]
    little_endian = b"".join(
        struct.pack("<Q", bits(component))
        for normal in normals
        for component in normal
    )
    return f"{name}|bits={','.join(bit_tokens)}", little_endian


def checked_additional_bytes(vertex_count: int) -> int:
    if vertex_count < 0:
        raise NormalFailure("resourceLimitExceeded")
    component_count = vertex_count * 3
    if component_count > UINT64_MAX:
        raise NormalFailure("resourceLimitExceeded")
    one_buffer = component_count * 8
    if one_buffer > UINT64_MAX:
        raise NormalFailure("resourceLimitExceeded")
    both_buffers = one_buffer * 2
    if both_buffers > UINT64_MAX:
        raise NormalFailure("resourceLimitExceeded")
    return both_buffers


def main() -> None:
    simple_positions = ((0.0, 0.0, 0.0), (2.0, 0.0, 0.0), (0.0, 3.0, 0.0))
    simple_triangles = ((0, 1, 2),)
    simple = generate(simple_positions, simple_triangles)
    assert all(
        tuple(bits(component) for component in normal)
        == (POSITIVE_ZERO_BITS, POSITIVE_ZERO_BITS, POSITIVE_ONE_BITS)
        for normal in simple
    )

    weighted_positions = (
        (0.0, 0.0, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, 1.0, 0.0),
        (0.0, 0.0, 2.0),
    )
    weighted_triangles = ((0, 1, 2), (0, 3, 1))
    weighted = generate(weighted_positions, weighted_triangles)
    expected_shared_bits = (
        POSITIVE_ZERO_BITS,
        WEIGHTED_Y_BITS,
        WEIGHTED_Z_BITS,
    )
    assert tuple(bits(value) for value in weighted[0]) == expected_shared_bits
    assert tuple(bits(value) for value in weighted[1]) == expected_shared_bits
    assert tuple(bits(value) for value in weighted[2]) == (
        POSITIVE_ZERO_BITS,
        POSITIVE_ZERO_BITS,
        POSITIVE_ONE_BITS,
    )
    assert tuple(bits(value) for value in weighted[3]) == (
        POSITIVE_ZERO_BITS,
        POSITIVE_ONE_BITS,
        POSITIVE_ZERO_BITS,
    )

    topology_large = float.fromhex("0x1.1c37937e08000p+53")
    topology_order_positions = (
        (0.0, 0.0, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, topology_large, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, -topology_large, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, 1.0, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, 0.0, -1.0),
    )
    topology_order_triangles = ((0, 1, 2), (0, 3, 4), (0, 5, 6), (0, 7, 8))
    topology_order = generate(topology_order_positions, topology_order_triangles)
    assert tuple(bits(value) for value in topology_order[0]) == (
        POSITIVE_ZERO_BITS,
        ORDERED_YZ_BITS,
        ORDERED_YZ_BITS,
    )
    reordered = generate(
        topology_order_positions,
        ((0, 1, 2), (0, 5, 6), (0, 3, 4), (0, 7, 8)),
    )
    assert tuple(bits(value) for value in reordered[0]) == (
        POSITIVE_ZERO_BITS,
        POSITIVE_ONE_BITS,
        POSITIVE_ZERO_BITS,
    )

    contraction_value = float.fromhex("0x1.0000002000000p+0")
    contraction_positions = (
        (0.0, 0.0, 0.0),
        (contraction_value, 1.0, 0.0),
        (1.0, contraction_value, 1.0),
    )
    contraction = generate(contraction_positions, simple_triangles)
    contraction_bits = (
        CONTRACTION_X_BITS,
        CONTRACTION_Y_BITS,
        CONTRACTION_Z_BITS,
    )
    assert all(
        tuple(bits(component) for component in normal) == contraction_bits
        for normal in contraction
    )
    separated_cross_z = cross(*contraction_positions)[2]
    contracted_cross_z = math.fma(
        contraction_value,
        contraction_value,
        -1.0,
    )
    assert bits(separated_cross_z) == 0x3E50000000000000
    assert bits(contracted_cross_z) == 0x3E50000001000000
    assert bits(normalise((1.0, -contraction_value, contracted_cross_z))[2]) \
        != CONTRACTION_Z_BITS

    reverse = generate(simple_positions, ((0, 2, 1),))
    assert all(bits(normal[2]) == NEGATIVE_ONE_BITS for normal in reverse)

    degenerate = generate(simple_positions, ((0, 0, 1), (0, 1, 2)))
    assert degenerate == simple

    least_subnormal = float.fromhex("0x0.0000000000001p-1022")
    subnormal_positions = (
        (0.0, 0.0, 0.0),
        (least_subnormal, 0.0, 0.0),
        (0.0, 1.0, 0.0),
    )
    subnormal = generate(subnormal_positions, simple_triangles)
    assert subnormal == simple

    yz_positions = ((0.0, 0.0, 0.0), (0.0, 2.0, 0.0), (0.0, 0.0, 3.0))
    yz = generate(yz_positions, simple_triangles)
    assert all(
        tuple(bits(component) for component in normal)
        == (POSITIVE_ONE_BITS, POSITIVE_ZERO_BITS, POSITIVE_ZERO_BITS)
        for normal in yz
    )

    cancellation_positions = simple_positions
    cancellation_triangles = ((0, 1, 2), (0, 2, 1))
    try:
        generate(cancellation_positions, cancellation_triangles)
    except NormalFailure as error:
        assert str(error) == "undefinedNormal"
    else:
        raise AssertionError("Opposite faces must cancel to undefined normals.")

    isolated_positions = simple_positions + ((4.0, 4.0, 4.0),)
    try:
        generate(isolated_positions, simple_triangles)
    except NormalFailure as error:
        assert str(error) == "undefinedNormal"
    else:
        raise AssertionError("An isolated vertex must have no defined normal.")

    greatest = float.fromhex("0x1.fffffffffffffp+1023")
    try:
        generate(((greatest, 0.0, 0.0), (-greatest, 0.0, 0.0), (0.0, 1.0, 0.0)), simple_triangles)
    except NormalFailure as error:
        assert str(error) == "normalNotRepresentable"
    else:
        raise AssertionError("Overflowing subtraction must fail.")

    edge = math.sqrt(8.0e307)
    accumulation_positions = ((0.0, 0.0, 0.0), (edge, 0.0, 0.0), (0.0, edge, 0.0))
    try:
        generate(accumulation_positions, ((0, 1, 2),) * 3)
    except NormalFailure as error:
        assert str(error) == "normalNotRepresentable"
    else:
        raise AssertionError("Overflowing serial accumulation must fail.")

    fixtures = (
        ("simple", simple_positions, simple_triangles),
        ("weighted", weighted_positions, weighted_triangles),
        ("topology-order-sensitive", topology_order_positions, topology_order_triangles),
        ("contraction-sensitive", contraction_positions, simple_triangles),
        ("reverse", simple_positions, ((0, 2, 1),)),
        ("degenerate-plus-valid", simple_positions, ((0, 0, 1), (0, 1, 2))),
        ("subnormal", subnormal_positions, simple_triangles),
        ("positive-zero", yz_positions, simple_triangles),
        ("opposite-cancellation", cancellation_positions, cancellation_triangles),
        ("isolated", isolated_positions, simple_triangles),
        (
            "difference-overflow",
            ((greatest, 0.0, 0.0), (-greatest, 0.0, 0.0), (0.0, 1.0, 0.0)),
            simple_triangles,
        ),
        (
            "accumulation-overflow",
            accumulation_positions,
            ((0, 1, 2),) * 3,
        ),
    )
    records = []
    attribute_bytes = bytearray()
    for name, positions, triangles in fixtures:
        fixture_record, output_bytes = record(name, positions, triangles)
        records.append(fixture_record)
        attribute_bytes.extend(output_bytes)

    fixture_payload = "\n".join(records).encode("ascii")
    fixture_digest = hashlib.sha256(fixture_payload).hexdigest()
    attribute_digest = hashlib.sha256(attribute_bytes).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert attribute_digest == EXPECTED_ATTRIBUTE_SHA256
    maximum_vertex_count = UINT64_MAX // 48
    assert checked_additional_bytes(maximum_vertex_count) <= UINT64_MAX
    assert maximum_vertex_count * 24 <= INT64_MAX
    assert (maximum_vertex_count + 1) * 24 > INT64_MAX
    try:
        checked_additional_bytes(maximum_vertex_count + 1)
    except NormalFailure as error:
        assert str(error) == "resourceLimitExceeded"
    else:
        raise AssertionError("One-past logical byte arithmetic must fail.")

    print(f"fixtureSHA256={fixture_digest}")
    print(f"normalAttributeBytesSHA256={attribute_digest}")
    print(f"fixtures={len(fixtures)} successful=8 failures=4")
    print(f"maximumAdditionalByteVertexCount={maximum_vertex_count}")
    print("triangleCancellationOrdinals=0,64,128,... vertexCancellationOrdinals=0,4096,8192,...")
    print("orientation=right-hand-area-weighted zeroComponents=positive")


if __name__ == "__main__":
    main()
