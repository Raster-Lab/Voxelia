#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0195 and VOXELIA-ALG-0032."""

from __future__ import annotations

import hashlib
import math
import struct


UINT64_MAX = (1 << 64) - 1
POSITIVE_ZERO_BITS = 0
ONE_BITS = 0x3FF0000000000000
EIGHT_BITS = 0x4020000000000000
EXPECTED_FIXTURE_SHA256 = (
    "7f3c73ceb34815bc3bb4af7d5bc3e957c992d9670a7a9841c105a945992ab90e"
)
EXPECTED_VOLUME_BYTES_SHA256 = (
    "c313f1c0b8e59fa267541313abfc0d314df0bb7cb5711a4f29616f604296ae71"
)


class VolumeFailure(Exception):
    """One payload-free oracle classification."""


def f64(value: float) -> float:
    return struct.unpack(">d", struct.pack(">d", value))[0]


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def checked(value: float) -> float:
    rounded = f64(value)
    if not math.isfinite(rounded):
        raise VolumeFailure("volumeNotRepresentable")
    return rounded


def mul(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) * f64(rhs))


def sub(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) - f64(rhs))


def add(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) + f64(rhs))


def div(lhs: float, rhs: float) -> float:
    return checked(f64(lhs) / f64(rhs))


def certify(
    triangles: tuple[tuple[int, int, int], ...],
) -> None:
    """The frozen closure, edge-manifoldness and orientation predicate.

    Vertex manifoldness is deliberately NOT required: a pinch-point vertex
    still yields the exact sum of its shells under the divergence identity.
    Self-intersection is deliberately NOT certified; that needs exact
    geometric predicates no accepted record supplies.
    """
    seen: set[tuple[int, int]] = set()
    for triangle in triangles:
        if len(set(triangle)) != 3:
            raise VolumeFailure("degenerateFacet")
        for lane in range(3):
            edge = (triangle[lane], triangle[(lane + 1) % 3])
            if edge in seen:
                raise VolumeFailure("nonManifoldOrientation")
            seen.add(edge)
    for tail, head in seen:
        if (head, tail) not in seen:
            raise VolumeFailure("openSurface")


def facet_six_volume(
    p0: tuple[float, float, float],
    p1: tuple[float, float, float],
    p2: tuple[float, float, float],
) -> float:
    """The origin-anchored scalar triple product `p0 . (p1 x p2)`."""
    cross_x = sub(mul(p1[1], p2[2]), mul(p1[2], p2[1]))
    cross_y = sub(mul(p1[2], p2[0]), mul(p1[0], p2[2]))
    cross_z = sub(mul(p1[0], p2[1]), mul(p1[1], p2[0]))
    term0 = mul(p0[0], cross_x)
    term1 = mul(p0[1], cross_y)
    term2 = mul(p0[2], cross_z)
    return add(add(term0, term1), term2)


def enclosed_volume(
    positions: tuple[tuple[float, float, float], ...],
    triangles: tuple[tuple[int, int, int], ...],
) -> float:
    """Certification precedes every arithmetic operation."""
    certify(triangles)
    total = 0.0
    for triangle in triangles:
        total = add(
            total,
            facet_six_volume(
                positions[triangle[0]],
                positions[triangle[1]],
                positions[triangle[2]],
            ),
        )
    if total < 0.0:
        raise VolumeFailure("invertedOrientation")
    volume = div(total, 6.0)
    return 0.0 if volume == 0.0 else volume


def record(
    name: str,
    positions: tuple[tuple[float, float, float], ...],
    triangles: tuple[tuple[int, int, int], ...],
) -> tuple[str, bytes]:
    try:
        volume = enclosed_volume(positions, triangles)
    except VolumeFailure as error:
        return f"{name}|error={error}", b""
    return (
        f"{name}|facets={len(triangles)}|bits={bits(volume):016x}",
        struct.pack("<Q", bits(volume)),
    )


def cube(
    origin: tuple[float, float, float],
    side: float,
    base: int = 0,
    outward: bool = True,
) -> tuple[
    tuple[tuple[float, float, float], ...],
    tuple[tuple[int, int, int], ...],
]:
    """One axis-aligned closed cube shell with a caller-chosen index base."""
    x, y, z = origin
    positions = (
        (x, y, z),
        (x + side, y, z),
        (x + side, y + side, z),
        (x, y + side, z),
        (x, y, z + side),
        (x + side, y, z + side),
        (x + side, y + side, z + side),
        (x, y + side, z + side),
    )
    outward_triangles = (
        (0, 3, 2), (0, 2, 1),
        (4, 5, 6), (4, 6, 7),
        (0, 1, 5), (0, 5, 4),
        (1, 2, 6), (1, 6, 5),
        (2, 3, 7), (2, 7, 6),
        (3, 0, 4), (3, 4, 7),
    )
    triangles = tuple(
        (
            (base + a, base + b, base + c)
            if outward
            else (base + a, base + c, base + b)
        )
        for a, b, c in outward_triangles
    )
    return positions, triangles


def tetrahedron(
    apexes: tuple[
        tuple[float, float, float],
        tuple[float, float, float],
        tuple[float, float, float],
        tuple[float, float, float],
    ],
    base: int = 0,
) -> tuple[
    tuple[tuple[float, float, float], ...],
    tuple[tuple[int, int, int], ...],
]:
    """One outward-oriented closed tetrahedron shell."""
    triangles = ((0, 2, 1), (0, 1, 3), (0, 3, 2), (1, 2, 3))
    return apexes, tuple(
        (base + a, base + b, base + c) for a, b, c in triangles
    )


def join(
    *shells: tuple[
        tuple[tuple[float, float, float], ...],
        tuple[tuple[int, int, int], ...],
    ],
) -> tuple[
    tuple[tuple[float, float, float], ...],
    tuple[tuple[int, int, int], ...],
]:
    positions: list[tuple[float, float, float]] = []
    triangles: list[tuple[int, int, int]] = []
    for shell_positions, shell_triangles in shells:
        positions.extend(shell_positions)
        triangles.extend(shell_triangles)
    return tuple(positions), tuple(triangles)


def main() -> None:
    # 1. An outward unit tetrahedron on the axes encloses exactly one sixth.
    tetra_positions, tetra_triangles = tetrahedron(
        ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0))
    )
    tetra = enclosed_volume(tetra_positions, tetra_triangles)
    assert tetra == 1.0 / 6.0

    # 2. The origin-anchored unit cube encloses exactly one.
    cube_positions, cube_triangles = cube((0.0, 0.0, 0.0), 1.0)
    assert bits(enclosed_volume(cube_positions, cube_triangles)) == ONE_BITS

    # 3. The reference origin is part of the identity: the same cube
    #    translated off the origin does not reproduce the same bits, because
    #    the origin-anchored terms grow and cancel.
    translated_positions, translated_triangles = cube((0.1, 0.2, 0.3), 1.0)
    translated = enclosed_volume(translated_positions, translated_triangles)
    assert translated != 1.0

    # 4. Doubling every length multiplies the volume by exactly eight.
    scaled_positions, scaled_triangles = cube((0.0, 0.0, 0.0), 2.0)
    assert bits(enclosed_volume(scaled_positions, scaled_triangles)) == EIGHT_BITS

    # 5. Two disjoint shells sum. Disconnection is admitted, not rejected.
    disjoint_positions, disjoint_triangles = join(
        cube((0.0, 0.0, 0.0), 1.0, base=0),
        cube((4.0, 0.0, 0.0), 2.0, base=8),
    )
    disjoint = enclosed_volume(disjoint_positions, disjoint_triangles)
    assert disjoint == 9.0

    # 6. Cavity semantics: an inward-oriented shell nested inside an outward
    #    one subtracts. This is the whole reason orientation, not nesting
    #    geometry, defines the enclosed region.
    cavity_positions, cavity_triangles = join(
        cube((0.0, 0.0, 0.0), 4.0, base=0),
        cube((1.0, 1.0, 1.0), 2.0, base=8, outward=False),
    )
    cavity = enclosed_volume(cavity_positions, cavity_triangles)
    assert cavity == 56.0

    # 7. A genuine pinch point: two closed tetrahedra sharing exactly one
    #    vertex INDEX. The shared vertex's link is two disjoint cycles, so the
    #    mesh is edge-manifold but not vertex-manifold. It certifies, and the
    #    divergence identity still gives the exact sum of the two shells.
    #    The second shell is the first rotated by (x, y) -> (-x, -y), which
    #    preserves handedness, so the same index pattern stays outward.
    pinch_positions = (
        (0.0, 0.0, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, 1.0, 0.0),
        (0.0, 0.0, 1.0),
        (-1.0, 0.0, 0.0),
        (0.0, -1.0, 0.0),
        (0.0, 0.0, 1.0),
    )
    pinch_triangles = (
        (0, 2, 1), (0, 1, 3), (0, 3, 2), (1, 2, 3),
        (0, 5, 4), (0, 4, 6), (0, 6, 5), (4, 5, 6),
    )
    pinch = enclosed_volume(pinch_positions, pinch_triangles)
    assert pinch == 2.0 / 6.0

    # 8. A double-sided facet certifies and encloses exactly positive zero.
    double_sided_positions = (
        (0.0, 0.0, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, 1.0, 1.0),
    )
    double_sided_triangles = ((0, 1, 2), (0, 2, 1))
    double_sided = enclosed_volume(
        double_sided_positions, double_sided_triangles
    )
    assert bits(double_sided) == POSITIVE_ZERO_BITS

    # 9. Serial topology order is part of the algorithm identity: the same
    #    three shells summed in the reverse order produce different bits.
    order_positions, order_triangles = join(
        tetrahedron(
            (
                (0.0, 0.0, 0.0),
                (float.fromhex("0x1p+53"), 0.0, 0.0),
                (0.0, 1.0, 0.0),
                (0.0, 0.0, 1.0),
            )
        ),
        tetrahedron(
            (
                (0.0, 0.0, 0.0),
                (0.75, 0.0, 0.0),
                (0.0, 1.0, 0.0),
                (0.0, 0.0, 1.0),
            ),
            base=4,
        ),
        tetrahedron(
            (
                (0.0, 0.0, 0.0),
                (1.0, 0.0, 0.0),
                (0.0, 0.75, 0.0),
                (0.0, 0.0, 1.0),
            ),
            base=8,
        ),
    )
    ordered = enclosed_volume(order_positions, order_triangles)
    reordered = enclosed_volume(
        order_positions,
        order_triangles[4:] + order_triangles[:4],
    )
    assert ordered != reordered

    # 10. A cube missing one facet has two boundary edges and is open.
    open_positions, open_triangles = cube((0.0, 0.0, 0.0), 1.0)
    open_triangles = open_triangles[1:]
    try:
        enclosed_volume(open_positions, open_triangles)
    except VolumeFailure as error:
        assert str(error) == "openSurface"
    else:
        raise AssertionError("An open surface must not publish a volume.")

    # 11. A repeated facet traverses its directed edges twice.
    duplicate_positions, duplicate_base = cube((0.0, 0.0, 0.0), 1.0)
    duplicate_triangles = duplicate_base + (duplicate_base[0],)
    try:
        enclosed_volume(duplicate_positions, duplicate_triangles)
    except VolumeFailure as error:
        assert str(error) == "nonManifoldOrientation"
    else:
        raise AssertionError("A duplicate facet must not certify.")

    # 12. Two facets traversing one edge the same way are non-manifold.
    same_direction_positions = (
        (0.0, 0.0, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, 1.0, 0.0),
        (0.0, 0.0, 1.0),
    )
    same_direction_triangles = ((0, 1, 2), (0, 1, 3))
    try:
        enclosed_volume(same_direction_positions, same_direction_triangles)
    except VolumeFailure as error:
        assert str(error) == "nonManifoldOrientation"
    else:
        raise AssertionError("A same-direction shared edge must not certify.")

    # 13. An index-degenerate facet is rejected before any edge bookkeeping.
    degenerate_positions = same_direction_positions
    degenerate_triangles = ((0, 0, 1), (0, 1, 2))
    try:
        enclosed_volume(degenerate_positions, degenerate_triangles)
    except VolumeFailure as error:
        assert str(error) == "degenerateFacet"
    else:
        raise AssertionError("A repeated index must not certify.")

    # 14. A consistently inward cube certifies but encloses a negative
    #     algebraic volume, which is named rather than silently absolutised.
    inverted_positions, inverted_triangles = cube(
        (0.0, 0.0, 0.0), 1.0, outward=False
    )
    try:
        enclosed_volume(inverted_positions, inverted_triangles)
    except VolumeFailure as error:
        assert str(error) == "invertedOrientation"
    else:
        raise AssertionError("An inward surface must not publish a volume.")

    # 15. An extreme but finite mesh overflows the frozen ordered expression.
    overflow_positions, overflow_triangles = tetrahedron(
        (
            (0.0, 0.0, 0.0),
            (1e200, 0.0, 0.0),
            (0.0, 1e200, 0.0),
            (0.0, 0.0, 1e200),
        )
    )
    try:
        enclosed_volume(overflow_positions, overflow_triangles)
    except VolumeFailure as error:
        assert str(error) == "volumeNotRepresentable"
    else:
        raise AssertionError("An overflowing triple product must fail.")

    # The empty mesh is vacuously closed and encloses positive zero.
    assert bits(enclosed_volume((), ())) == POSITIVE_ZERO_BITS

    fixtures = (
        ("unit-tetrahedron", tetra_positions, tetra_triangles),
        ("unit-cube", cube_positions, cube_triangles),
        ("translated-cube", translated_positions, translated_triangles),
        ("scaled-cube", scaled_positions, scaled_triangles),
        ("empty", (), ()),
        ("disjoint-shells", disjoint_positions, disjoint_triangles),
        ("nested-cavity", cavity_positions, cavity_triangles),
        ("pinch-point-vertex", pinch_positions, pinch_triangles),
        ("double-sided-facet", double_sided_positions, double_sided_triangles),
        ("accumulation-order-sensitive", order_positions, order_triangles),
        ("open-surface", open_positions, open_triangles),
        ("duplicate-facet", duplicate_positions, duplicate_triangles),
        (
            "same-direction-shared-edge",
            same_direction_positions,
            same_direction_triangles,
        ),
        ("index-degenerate-facet", degenerate_positions, degenerate_triangles),
        ("inverted-orientation", inverted_positions, inverted_triangles),
        ("triple-product-overflow", overflow_positions, overflow_triangles),
    )
    records = []
    volume_bytes = bytearray()
    for name, positions, triangles in fixtures:
        fixture_record, output_bytes = record(name, positions, triangles)
        records.append(fixture_record)
        volume_bytes.extend(output_bytes)

    fixture_payload = "\n".join(records).encode("ascii")
    fixture_digest = hashlib.sha256(fixture_payload).hexdigest()
    volume_digest = hashlib.sha256(volume_bytes).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert volume_digest == EXPECTED_VOLUME_BYTES_SHA256

    # Unlike total facet area, certification owns real payload: one directed
    # edge record per facet corner, each a pair of 64-bit vertex indices.
    maximum_triangle_count = UINT64_MAX // 48
    assert checked_additional_bytes(maximum_triangle_count) <= UINT64_MAX
    try:
        checked_additional_bytes(maximum_triangle_count + 1)
    except VolumeFailure as error:
        assert str(error) == "resourceLimitExceeded"
    else:
        raise AssertionError("One-past logical byte arithmetic must fail.")

    print(f"fixtureSHA256={fixture_digest}")
    print(f"volumeBytesSHA256={volume_digest}")
    print(f"fixtures={len(fixtures)} successful=10 failures=6")
    print(f"maximumAdditionalByteTriangleCount={maximum_triangle_count}")
    print(
        "certificationCancellationOrdinals=0,64,128,... "
        "volumeCancellationOrdinals=0,64,128,..."
    )
    print(
        "certified=closed,edge-manifold,consistently-oriented "
        "notCertified=vertex-manifold,non-self-intersecting"
    )
    print("referenceOrigin=source-coordinate-space emptyVolume=positive-zero")


def checked_additional_bytes(triangle_count: int) -> int:
    if triangle_count < 0:
        raise VolumeFailure("resourceLimitExceeded")
    directed_edge_count = triangle_count * 3
    if directed_edge_count > UINT64_MAX:
        raise VolumeFailure("resourceLimitExceeded")
    byte_count = directed_edge_count * 16
    if byte_count > UINT64_MAX:
        raise VolumeFailure("resourceLimitExceeded")
    return byte_count


if __name__ == "__main__":
    main()
