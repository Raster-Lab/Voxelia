#!/usr/bin/env python3
"""Independent oracle for ADR-0207 and VOXELIA-ALG-0041."""

from __future__ import annotations

import hashlib
import struct


EXPECTED_FIXTURE_SHA256 = (
    "055eddda7b501f397741194f7ca2dbc038e0191c87c9e8634f298561d4ae079c"
)
EXPECTED_VALUE_SHA256 = (
    "fc52599c92900bc37cbea6dc206f481a4ee419347628634a67cf5da476ab04c4"
)

# The host signed-integer ceiling the checked products are taken against.
INT_MAX = 2**63 - 1

POSITION_STRIDE = 12
TRIANGLE_STRIDE = 12


class DecodeFailure(Exception):
    """One payload-free oracle classification."""


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def float32(word: int) -> bytes:
    """Exactly four little-endian bytes of one binary32 bit pattern."""
    return struct.pack("<I", word)


def positions(*words: int) -> bytes:
    return b"".join(float32(word) for word in words)


def indices(*values: int) -> bytes:
    return b"".join(struct.pack("<I", value) for value in values)


def decode(vertex_count, triangle_count, position_bytes, index_bytes):
    """The frozen GPU-geometry byte-layout decode.

    Counts arrive OUT OF BAND, from the dispatch that produced the bytes. A
    length-bearing header would let the payload decide its own allocation, and
    the caller already knows what it dispatched.

    The coordinate space is likewise never carried in the payload: a buffer
    cannot declare one, and letting bytes name a space would be exactly the
    relabelling `ADR-0183` decision 4 forbids.
    """
    if vertex_count < 0 or triangle_count < 0:
        raise DecodeFailure("negativeCount")
    if (vertex_count > INT_MAX // POSITION_STRIDE
            or triangle_count > INT_MAX // TRIANGLE_STRIDE):
        raise DecodeFailure("countNotRepresentable")
    if len(position_bytes) != vertex_count * POSITION_STRIDE:
        raise DecodeFailure("positionByteCountMismatch")
    if len(index_bytes) != triangle_count * TRIANGLE_STRIDE:
        raise DecodeFailure("indexByteCountMismatch")

    # Positions are tightly PACKED three-component binary32, little-endian,
    # with no padding and no interleaved attributes. A producer using MSL's
    # 16-byte-aligned `float3` must pack before writing; `packed_float3` is
    # already this layout.
    components = [
        struct.unpack("<f", position_bytes[offset:offset + 4])[0]
        for offset in range(0, len(position_bytes), 4)
    ]
    triangle_indices = [
        struct.unpack("<I", index_bytes[offset:offset + 4])[0]
        for offset in range(0, len(index_bytes), 4)
    ]

    # Everything below is the CANONICAL value's own admission, restated here
    # only so the oracle can classify the outcome. The decoder itself carries
    # no geometric rule: the canonical gate is what admits, which is precisely
    # why the buffer is not canonical.
    for component in components:
        if component != component or component in (
            float("inf"), float("-inf")
        ):
            raise DecodeFailure("nonFinitePosition")
    for index in triangle_indices:
        if index >= vertex_count:
            raise DecodeFailure("indexOutOfBounds")
    return components, triangle_indices


def record(name: str, case) -> tuple[str, bytes]:
    try:
        components, triangle_indices = decode(*case)
    except DecodeFailure as error:
        return f"{name}|error={error}", b""
    payload = bytearray()
    for component in components:
        payload.extend(struct.pack("<Q", bits(component)))
    for index in triangle_indices:
        payload.extend(struct.pack("<Q", index))
    return (
        f"{name}|components="
        + ",".join(f"{bits(c):016x}" for c in components)
        + "|indices="
        + ",".join(str(i) for i in triangle_indices),
        bytes(payload),
    )


def main() -> None:
    # 0x3f800000 is 1.0; the byte order is what makes it so.
    unit = positions(0x3F800000, 0, 0, 0, 0x3F800000, 0, 0, 0, 0x3F800000)
    one_triangle = (3, 1, unit, indices(0, 1, 2))

    # 1. A whole triangle decodes to the canonical components and indices.
    components, triangle_indices = decode(*one_triangle)
    assert components == [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]
    assert triangle_indices == [0, 1, 2]

    # 2. Little-endian is load-bearing: the same four bytes read big-endian
    #    would be 4.6006e-41, not 1.0.
    assert struct.unpack("<f", b"\x00\x00\x80\x3f")[0] == 1.0
    assert struct.unpack(">f", b"\x00\x00\x80\x3f")[0] != 1.0

    # 3. Widening binary32 to binary64 is EXACT, and the decoder therefore
    #    invents no precision it was not given. Decimal 0.1 written as a
    #    binary32 is 0.10000000149011612 as a binary64, and that is the honest
    #    value — not 0.1.
    tenth = decode(1, 0, positions(0x3DCCCCCD, 0, 0), b"")[0]
    assert tenth[0] == 0.10000000149011612

    # 4. The extremes of binary32 widen exactly too: the least subnormal, the
    #    least normal and the greatest finite value.
    extremes = decode(
        1, 0, positions(0x00000001, 0x00800000, 0x7F7FFFFF), b""
    )[0]
    assert extremes[0] == float.fromhex("0x1p-149")
    assert extremes[1] == float.fromhex("0x1p-126")
    assert extremes[2] == float.fromhex("0x1.fffffep+127")

    # 5. Negative zero survives as negative zero. It compares equal to positive
    #    zero, so only the bit pattern shows the difference.
    signed_zero = decode(1, 0, positions(0x80000000, 0, 0), b"")[0]
    assert signed_zero[0] == 0.0
    assert bits(signed_zero[0]) == 0x8000000000000000

    # 6. An empty buffer is an empty mesh, not a failure, and vertices without
    #    triangles decode as well — the layout does not require topology.
    assert decode(0, 0, b"", b"") == ([], [])
    assert decode(1, 0, positions(1, 2, 3), b"")[1] == []

    # 7. Non-finite positions and out-of-range indices are rejected by the
    #    CANONICAL admission, not by a rule the decoder restates.
    for word, name in [(0x7F800000, "infinity"), (0x7FC00000, "nan")]:
        try:
            decode(1, 0, positions(word, 0, 0), b"")
        except DecodeFailure as error:
            assert str(error) == "nonFinitePosition"
        else:
            raise AssertionError("A non-finite position must be rejected.")
    try:
        decode(3, 1, unit, indices(0, 1, 3))
    except DecodeFailure as error:
        assert str(error) == "indexOutOfBounds"
    else:
        raise AssertionError("An out-of-range index must be rejected.")

    # 8. The byte-count checks are the decoder's OWN failures, and they are
    #    strictly stronger than the canonical incomplete-vertex and
    #    incomplete-triangle cases: a payload whose length matches the count
    #    exactly can never be a partial vertex or a partial triangle. Those two
    #    canonical cases are therefore unreachable through this path.
    for case, expected in [
        ((3, 1, unit[:-1], indices(0, 1, 2)), "positionByteCountMismatch"),
        ((3, 1, unit + b"\x00", indices(0, 1, 2)), "positionByteCountMismatch"),
        ((3, 1, unit, indices(0, 1)), "indexByteCountMismatch"),
        ((-1, 0, b"", b""), "negativeCount"),
        ((0, -1, b"", b""), "negativeCount"),
        ((2**62, 0, b"", b""), "countNotRepresentable"),
    ]:
        try:
            decode(*case)
        except DecodeFailure as error:
            assert str(error) == expected
        else:
            raise AssertionError(f"{expected} must be raised.")

    fixtures = (
        ("single-triangle", one_triangle),
        ("byte-order", (1, 0, positions(0x3F800000, 0, 0), b"")),
        ("exact-widening", (1, 0, positions(0x3DCCCCCD, 0, 0), b"")),
        (
            "binary32-extremes",
            (1, 0, positions(0x00000001, 0x00800000, 0x7F7FFFFF), b""),
        ),
        ("negative-zero", (1, 0, positions(0x80000000, 0, 0), b"")),
        ("empty", (0, 0, b"", b"")),
        ("vertices-without-triangles", (1, 0, positions(1, 2, 3), b"")),
        (
            "two-triangles",
            (
                4,
                2,
                unit + positions(0xBF800000, 0, 0),
                indices(0, 1, 2, 2, 1, 3),
            ),
        ),
        ("infinite-position", (1, 0, positions(0x7F800000, 0, 0), b"")),
        ("nan-position", (1, 0, positions(0x7FC00000, 0, 0), b"")),
        ("index-out-of-bounds", (3, 1, unit, indices(0, 1, 3))),
        ("position-bytes-short", (3, 1, unit[:-1], indices(0, 1, 2))),
        ("position-bytes-long", (3, 1, unit + b"\x00", indices(0, 1, 2))),
        ("index-bytes-short", (3, 1, unit, indices(0, 1))),
        ("index-bytes-long", (3, 1, unit, indices(0, 1, 2, 0))),
        ("negative-vertex-count", (-1, 0, b"", b"")),
        ("negative-triangle-count", (0, -1, b"", b"")),
        ("count-not-representable", (2**62, 0, b"", b"")),
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
    value_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert value_digest == EXPECTED_VALUE_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"valueSHA256={value_digest}")
    print(f"fixtures={len(fixtures)} decoded=8 rejected=10")
    print("layout=packed-binary32-le counts=out-of-band space=caller-supplied")
    print("widening=exact geometricAdmission=canonical")


if __name__ == "__main__":
    main()
