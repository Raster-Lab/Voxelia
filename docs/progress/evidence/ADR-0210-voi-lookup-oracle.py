#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0210 and VOXELIA-ALG-0042."""

from __future__ import annotations

import hashlib
import math
import struct


EXPECTED_FIXTURE_SHA256 = (
    "a88c27632f2f73645243ca5dda7b365665a8e80f79c9877a50304664d48d34c7"
)
EXPECTED_OUTPUT_SHA256 = (
    "e8f03a49b1f9fdc024827f77ebbc489628f453acd11168de60ea7de3d35781f8"
)

INT64_MIN = -(2**63)
INT64_MAX = 2**63 - 1


class VOILookupFailure(Exception):
    """One payload-free oracle classification."""


def round_half_away(value: float) -> int:
    """The `VOXELIA-ALG-0026` rule, reused verbatim and saturating.

    This is inherited exactly as accepted, INCLUDING its behaviour on the
    double just below one half: `0.49999999999999994 + 0.5` rounds to `1.0` in
    binary64, so the rule yields one rather than zero. Correcting that here
    would create a second, divergent rounding rule in the project, which is a
    worse outcome than an inherited quirk that is registered and known.
    """
    shifted = value + 0.5 if value >= 0 else value - 0.5
    if math.isfinite(shifted):
        shifted = math.floor(shifted) if value >= 0 else math.ceil(shifted)
    # The saturation is the host's: an infinite or huge shifted value is not a
    # failure here, it simply lies beyond the signed-integer range and pins to
    # that end, exactly as the accepted rule's own guard does.
    if shifted <= float(INT64_MIN):
        return INT64_MIN
    if shifted >= float(INT64_MAX):
        return INT64_MAX
    return int(shifted)


def apply_voi(value: float, first_mapped: int, values: list) -> int:
    """The frozen VOI lookup rule.

    Two different jobs use two different accepted rounding rules, and that is
    deliberate: selecting a table index is the job `ALG-0026` froze
    round-half-away-from-zero for, and quantising a display output is the job
    `ALG-0002` froze round-ties-to-even for. Each stage uses the rule already
    accepted for what it is doing, rather than one rule chosen for tidiness.
    """
    if not values:
        raise VOILookupFailure("emptyTable")
    # An infinite value is NOT a failure: it compares beyond an end of the
    # table and clamps there, which is total. Only NaN is undecidable, because
    # it compares false against everything.
    if value != value:
        raise VOILookupFailure("valueNotRepresentable")

    # Index selection. The subtraction follows `ALG-0004`'s frozen
    # out-of-range reasoning: clamping at both ends is the DICOM-derived rule,
    # and an overflowing difference lies beyond the representable range on the
    # side opposite the origin's sign, so it clamps to that same end.
    rounded = round_half_away(value)
    index = rounded - first_mapped
    index = max(0, min(len(values) - 1, index))

    # Output quantisation, the `ALG-0002` rule verbatim: round ties to even,
    # then clamp to the eight-bit display range. The table's outputs are
    # display values, not physical ones, so no unit travels with them.
    output = values[index]
    if output != output:
        raise VOILookupFailure("valueNotRepresentable")
    if output == math.inf:
        return 255
    if output == -math.inf:
        return 0
    quantised = round_ties_even(output)
    return max(0, min(255, quantised))


def round_ties_even(value: float) -> int:
    """IEEE-754 roundTiesToEven to an integral value, as `ALG-0002` uses."""
    floor_value = math.floor(value)
    difference = value - floor_value
    if difference > 0.5:
        return floor_value + 1
    if difference < 0.5:
        return floor_value
    return floor_value if floor_value % 2 == 0 else floor_value + 1


def record(name: str, case) -> tuple[str, bytes]:
    try:
        output = apply_voi(*case)
    except VOILookupFailure as error:
        return f"{name}|error={error}", b""
    return f"{name}|output={output}", bytes([output])


def main() -> None:
    table = [0.0, 64.0, 128.0, 192.0, 255.0]
    first = 10

    # 1. An exact hit selects its own entry.
    assert apply_voi(12.0, first, table) == 128

    # 2. Both ends clamp, which is the DICOM-derived out-of-range rule
    #    `ALG-0004` already froze for the modality table form.
    assert apply_voi(-1000.0, first, table) == 0
    assert apply_voi(1000.0, first, table) == 255
    assert apply_voi(10.0, first, table) == 0
    assert apply_voi(14.0, first, table) == 255

    # 3. Index selection rounds half AWAY FROM ZERO, so 12.5 selects entry 13
    #    where round-ties-to-even would have selected 12. The registered
    #    fixture pins the choice.
    assert apply_voi(12.5, first, table) == 192
    assert apply_voi(11.5, first, table) == 128

    # 4. The inherited `ALG-0026` quirk, registered rather than corrected: the
    #    double just below one half rounds up, because the sum is exactly
    #    representable as one. It is only observable at an origin of zero: at
    #    magnitude ten the neighbouring doubles are too far apart to express
    #    the difference at all.
    assert round_half_away(0.49999999999999994) == 1
    assert apply_voi(0.49999999999999994, 0, table) == 64

    # 5. A negative origin rounds away from zero on the negative side too.
    negative_first = -3
    assert apply_voi(-2.5, negative_first, table) == 0
    assert apply_voi(-1.5, negative_first, table) == 64

    # 6. Infinity clamps rather than failing; only NaN is undecidable.
    assert apply_voi(math.inf, first, table) == 255
    assert apply_voi(-math.inf, first, table) == 0
    assert apply_voi(1e300, first, table) == 255
    try:
        apply_voi(math.nan, first, table)
    except VOILookupFailure as error:
        assert str(error) == "valueNotRepresentable"
    else:
        raise AssertionError("NaN must be rejected.")

    # 7. An origin at the signed-integer extreme cannot overflow the index:
    #    the difference lies beyond the representable range on the side
    #    opposite the origin's sign and clamps to that end.
    assert apply_voi(0.0, INT64_MIN, table) == 255
    assert apply_voi(0.0, INT64_MAX, table) == 0

    # 8. Table outputs are DISPLAY values and are clamped and quantised, not
    #    normalised: an out-of-range entry saturates.
    assert apply_voi(10.0, first, [-5.0]) == 0
    assert apply_voi(10.0, first, [300.0]) == 255

    # 9. Output quantisation rounds TIES TO EVEN, the `ALG-0002` rule, so 0.5
    #    goes to zero and 1.5 goes to two.
    assert apply_voi(10.0, first, [0.5]) == 0
    assert apply_voi(10.0, first, [1.5]) == 2
    assert apply_voi(10.0, first, [2.5]) == 2

    # 10. A single-entry table maps everything to that entry, and an empty
    #     table is a typed admission failure exactly as `ALG-0004` requires.
    assert apply_voi(-99.0, first, [42.0]) == 42
    try:
        apply_voi(0.0, first, [])
    except VOILookupFailure as error:
        assert str(error) == "emptyTable"
    else:
        raise AssertionError("An empty table must be rejected.")

    fixtures = (
        ("exact-hit", (12.0, first, table)),
        ("below-table", (-1000.0, first, table)),
        ("above-table", (1000.0, first, table)),
        ("at-first-entry", (10.0, first, table)),
        ("at-last-entry", (14.0, first, table)),
        ("index-half-away-up", (12.5, first, table)),
        ("index-half-away-lower", (11.5, first, table)),
        ("index-just-below-half", (0.49999999999999994, 0, table)),
        ("negative-origin-half-away", (-2.5, negative_first, table)),
        ("negative-origin-interior", (-1.5, negative_first, table)),
        ("positive-infinity", (math.inf, first, table)),
        ("negative-infinity", (-math.inf, first, table)),
        ("huge-finite", (1e300, first, table)),
        ("not-a-number", (math.nan, first, table)),
        ("origin-at-int64-min", (0.0, INT64_MIN, table)),
        ("origin-at-int64-max", (0.0, INT64_MAX, table)),
        ("output-clamp-low", (10.0, first, [-5.0])),
        ("output-clamp-high", (10.0, first, [300.0])),
        ("output-ties-even-down", (10.0, first, [0.5])),
        ("output-ties-even-up", (10.0, first, [1.5])),
        ("output-ties-even-stay", (10.0, first, [2.5])),
        ("single-entry", (-99.0, first, [42.0])),
        ("empty-table", (0.0, first, [])),
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
    output_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert output_digest == EXPECTED_OUTPUT_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"outputSHA256={output_digest}")
    print(f"fixtures={len(fixtures)} mapped=21 rejected=2")
    print("index=half-away-from-zero output=ties-to-even range=0..255")
    print("outOfRange=clamped infinite=clamped nan=rejected")


if __name__ == "__main__":
    main()
