#!/usr/bin/env python3
"""Independent oracle for ADR-0211 and VOXELIA-ALG-0043."""

from __future__ import annotations

import hashlib
import math


EXPECTED_FIXTURE_SHA256 = (
    "76d9f8943c52f28b7156ab69c2dd9000e7dc137d526f597ba87a9756fa6a2e65"
)
EXPECTED_CHANNEL_SHA256 = (
    "98d9464166ab8c01ac5c266b4d29ea56684e1b2b7d38504d9c073de715105160"
)

INT64_MIN = -(2**63)
INT64_MAX = 2**63 - 1


class PaletteFailure(Exception):
    """One payload-free oracle classification."""


def round_ties_even(value: float) -> int:
    """IEEE-754 roundTiesToEven, the rule `ALG-0002` froze for display output."""
    floor_value = math.floor(value)
    difference = value - floor_value
    if difference > 0.5:
        return floor_value + 1
    if difference < 0.5:
        return floor_value
    return floor_value if floor_value % 2 == 0 else floor_value + 1


def channel(value: float) -> int:
    """One palette entry quantised to the eight-bit display range."""
    return max(0, min(255, round_ties_even(value)))


def apply_palette(stored, red, green, blue):
    """The frozen palette-colour rule.

    Note what is ABSENT: there is no rounding rule here at all. A palette
    indexes a STORED INTEGER, so the index derivation is `ALG-0004`'s clamped
    subtraction verbatim, and this model introduces no new numeric rule of its
    own for it.

    Each table is `(firstMappedValue, values)`.
    """
    for table in (red, green, blue):
        if not table[1]:
            raise PaletteFailure("emptyTable")
    # Three differently shaped tables would mean three different index
    # derivations for one pixel, so a red channel could come from a different
    # stored value than its own green. The three must agree.
    if not (red[0] == green[0] == blue[0]):
        raise PaletteFailure("paletteShapeMismatch")
    if not (len(red[1]) == len(green[1]) == len(blue[1])):
        raise PaletteFailure("paletteShapeMismatch")

    first, count = red[0], len(red[1])
    # `ALG-0004`'s frozen out-of-range reasoning, inherited unchanged: an
    # overflowing difference lies beyond the representable range on the side
    # opposite the origin's sign and clamps to that same end.
    difference = stored - first
    index = max(0, min(count - 1, difference))

    # Alpha is exactly opaque. A palette-colour image is an image, not an
    # overlay; per-object opacity is a different accepted contract, and
    # inventing a transparency here would give the palette a second meaning.
    return (
        channel(red[1][index]),
        channel(green[1][index]),
        channel(blue[1][index]),
        255,
    )


def record(name: str, case) -> tuple[str, bytes]:
    try:
        pixel = apply_palette(*case)
    except PaletteFailure as error:
        return f"{name}|error={error}", b""
    return (
        f"{name}|rgba={pixel[0]},{pixel[1]},{pixel[2]},{pixel[3]}",
        bytes(pixel),
    )


def main() -> None:
    reds = (10, [0.0, 255.0, 0.0, 0.0])
    greens = (10, [0.0, 0.0, 255.0, 0.0])
    blues = (10, [0.0, 0.0, 0.0, 255.0])
    ramp = (reds, greens, blues)

    # 1. Each channel is indexed independently from its own table, so a
    #    swapped pair would change the pixel.
    assert apply_palette(11, *ramp) == (255, 0, 0, 255)
    assert apply_palette(12, *ramp) == (0, 255, 0, 255)
    assert apply_palette(13, *ramp) == (0, 0, 255, 255)

    # 2. Alpha is always exactly opaque, even where every colour channel is
    #    zero: a palette-colour image is an image, not an overlay.
    assert apply_palette(10, *ramp) == (0, 0, 0, 255)

    # 3. Both ends clamp, which is the DICOM-derived rule `ALG-0004` froze.
    assert apply_palette(-1000, *ramp) == (0, 0, 0, 255)
    assert apply_palette(1000, *ramp) == (0, 0, 255, 255)

    # 4. The signed-integer origin extremes cannot overflow the index.
    assert apply_palette(0, (INT64_MIN, [1.0, 2.0]), (INT64_MIN, [3.0, 4.0]),
                         (INT64_MIN, [5.0, 6.0])) == (2, 4, 6, 255)
    assert apply_palette(0, (INT64_MAX, [1.0, 2.0]), (INT64_MAX, [3.0, 4.0]),
                         (INT64_MAX, [5.0, 6.0])) == (1, 3, 5, 255)

    # 5. Entries are display values: out of range saturates, and quantisation
    #    rounds ties to even — the same output rule `ALG-0002` and `ALG-0042`
    #    use, because it is the same job.
    def single(value):
        return (0, [value])

    assert apply_palette(0, single(-5.0), single(300.0), single(0.5)) == (
        0, 255, 0, 255
    )
    assert apply_palette(0, single(1.5), single(2.5), single(3.5)) == (
        2, 2, 4, 255
    )

    # 6. Three differently shaped tables are rejected rather than reconciled.
    try:
        apply_palette(0, (0, [1.0, 2.0]), (0, [1.0]), (0, [1.0, 2.0]))
    except PaletteFailure as error:
        assert str(error) == "paletteShapeMismatch"
    else:
        raise AssertionError("A count mismatch must be rejected.")
    try:
        apply_palette(0, (0, [1.0]), (1, [1.0]), (0, [1.0]))
    except PaletteFailure as error:
        assert str(error) == "paletteShapeMismatch"
    else:
        raise AssertionError("An origin mismatch must be rejected.")
    try:
        apply_palette(0, (0, []), (0, []), (0, []))
    except PaletteFailure as error:
        assert str(error) == "emptyTable"
    else:
        raise AssertionError("An empty table must be rejected.")

    fixtures = (
        ("first-entry", (10, *ramp)),
        ("red-entry", (11, *ramp)),
        ("green-entry", (12, *ramp)),
        ("blue-entry", (13, *ramp)),
        ("below-range", (-1000, *ramp)),
        ("above-range", (1000, *ramp)),
        (
            "origin-at-int64-min",
            (
                0,
                (INT64_MIN, [1.0, 2.0]),
                (INT64_MIN, [3.0, 4.0]),
                (INT64_MIN, [5.0, 6.0]),
            ),
        ),
        (
            "origin-at-int64-max",
            (
                0,
                (INT64_MAX, [1.0, 2.0]),
                (INT64_MAX, [3.0, 4.0]),
                (INT64_MAX, [5.0, 6.0]),
            ),
        ),
        (
            "negative-origin",
            (-2, (-3, [7.0, 8.0]), (-3, [9.0, 10.0]), (-3, [11.0, 12.0])),
        ),
        (
            "output-clamp-and-tie-down",
            (0, single(-5.0), single(300.0), single(0.5)),
        ),
        ("output-ties-even", (0, single(1.5), single(2.5), single(3.5))),
        ("single-entry", (999, single(42.0), single(43.0), single(44.0))),
        (
            "count-mismatch",
            (0, (0, [1.0, 2.0]), (0, [1.0]), (0, [1.0, 2.0])),
        ),
        ("origin-mismatch", (0, (0, [1.0]), (1, [1.0]), (0, [1.0]))),
        ("empty-table", (0, (0, []), (0, []), (0, []))),
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
    channel_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert channel_digest == EXPECTED_CHANNEL_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"channelSHA256={channel_digest}")
    print(f"fixtures={len(fixtures)} mapped=12 rejected=3")
    print("index=alg-0004-clamped output=ties-to-even alpha=always-opaque")
    print("shape=three-tables-must-agree newRoundingRule=none")


if __name__ == "__main__":
    main()
