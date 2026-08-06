#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0203 and VOXELIA-ALG-0037."""

from __future__ import annotations

import hashlib
import math
import struct


EXPECTED_FIXTURE_SHA256 = (
    "1c6b807ea1bc930d00398946db2342476258c799732aeb81492fbd00fe62a63f"
)
EXPECTED_COLOUR_SHA256 = (
    "0337dbc24117ac54e875c838ef2703d7813917eefc43ff24f59edaacfd72d506"
)


class ColourMapFailure(Exception):
    """One payload-free oracle classification."""


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


def div(a: float, b: float) -> float:
    return f64(f64(a) / f64(b))


def round_half_away(value: float) -> int:
    """The accepted `VOXELIA-ALG-0026` rounding rule, reused not reinvented."""
    if value >= 0.0:
        return math.floor(f64(value + 0.5))
    return math.ceil(f64(value - 0.5))


def interpolate(scalars, weights):
    """The frozen `((a * b + c * d) + e * f)` grouping shared with ALG-0036."""
    return add(
        add(mul(weights[0], scalars[0]), mul(weights[1], scalars[1])),
        mul(weights[2], scalars[2]),
    )


def select(value: float, domain, entry_count: int) -> int:
    """Maps one scalar to a table index by nearest entry, clamped."""
    minimum, maximum = domain
    if not (math.isfinite(minimum) and math.isfinite(maximum)):
        raise ColourMapFailure("invalidDomain")
    if not minimum < maximum:
        raise ColourMapFailure("invalidDomain")
    if entry_count < 1:
        raise ColourMapFailure("invalidTable")
    if not math.isfinite(value):
        raise ColourMapFailure("scalarNotRepresentable")

    span = sub(maximum, minimum)
    normalised = div(sub(value, minimum), span)
    scaled = mul(normalised, float(entry_count - 1))
    index = round_half_away(scaled)
    # Out-of-domain scalars clamp to the end entries. Clamping is what makes
    # the rule total; there is no separate out-of-domain branch.
    if index < 0:
        return 0
    if index > entry_count - 1:
        return entry_count - 1
    return index


def modulate(entry, intensity: float):
    """Shading modulates colour and NEVER opacity.

    This composes the accepted `VOXELIA-ALG-0023` shaded rule verbatim:
    `(component * factor) / 255`, with opacity carried through untouched.
    """
    red, green, blue, opacity = entry
    return (
        div(mul(float(red), intensity), 255.0),
        div(mul(float(green), intensity), 255.0),
        div(mul(float(blue), intensity), 255.0),
        div(float(opacity), 255.0),
    )


def effective_opacity(layer_opacity: float, entry_opacity: float) -> float:
    """Per-object and per-value opacity compose by multiplication."""
    return mul(layer_opacity, entry_opacity)


def evaluate(scalars, weights, domain, table, intensity, layer_opacity):
    value = interpolate(scalars, weights)
    index = select(value, domain, len(table))
    red, green, blue, entry_alpha = modulate(table[index], intensity)
    return (
        index,
        red,
        green,
        blue,
        effective_opacity(layer_opacity, entry_alpha),
    )


def record(name: str, case) -> tuple[str, bytes]:
    try:
        index, red, green, blue, alpha = evaluate(*case)
    except ColourMapFailure as error:
        return f"{name}|error={error}", b""
    payload = bytearray()
    for component in (red, green, blue, alpha):
        payload.extend(struct.pack("<Q", bits(component)))
    return (
        f"{name}|index={index}"
        f"|rgba={bits(red):016x},{bits(green):016x},"
        f"{bits(blue):016x},{bits(alpha):016x}",
        bytes(payload),
    )


GREY_RAMP = tuple((v, v, v, 255) for v in (0, 85, 170, 255))
THIRDS = (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)


def main() -> None:
    # 1. The domain minimum selects the first entry, the maximum the last.
    at_min = ((0.0, 0.0, 0.0), THIRDS, (0.0, 1.0), GREY_RAMP, 1.0, 1.0)
    at_max = ((1.0, 1.0, 1.0), THIRDS, (0.0, 1.0), GREY_RAMP, 1.0, 1.0)
    assert evaluate(*at_min)[0] == 0
    assert evaluate(*at_max)[0] == 3

    # 2. Nearest-entry selection: a value one sixth along a four-entry ramp
    #    is exactly halfway between entries zero and one and rounds away.
    halfway = ((1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0), THIRDS, (0.0, 1.0), GREY_RAMP, 1.0, 1.0)
    assert evaluate(*halfway)[0] == 1

    # 3. Out-of-domain scalars clamp rather than failing: clamping is what
    #    makes the mapping total, so there is no out-of-domain branch.
    below = ((-5.0, -5.0, -5.0), THIRDS, (0.0, 1.0), GREY_RAMP, 1.0, 1.0)
    above = ((5.0, 5.0, 5.0), THIRDS, (0.0, 1.0), GREY_RAMP, 1.0, 1.0)
    assert evaluate(*below)[0] == 0
    assert evaluate(*above)[0] == 3

    # 4. A single-entry table selects that entry for every scalar.
    single = ((0.7, 0.7, 0.7), THIRDS, (0.0, 1.0), (((10, 20, 30, 40)),), 1.0, 1.0)
    assert evaluate(*single)[0] == 0

    # 5. Shading modulates colour and NEVER opacity — the accepted ALG-0023
    #    shaded rule, composed rather than restated.
    lit = ((1.0, 1.0, 1.0), THIRDS, (0.0, 1.0), ((200, 100, 50, 128),), 1.0, 1.0)
    dim = ((1.0, 1.0, 1.0), THIRDS, (0.0, 1.0), ((200, 100, 50, 128),), 0.5, 1.0)
    lit_result = evaluate(*lit)
    dim_result = evaluate(*dim)
    assert dim_result[1] == div(mul(200.0, 0.5), 255.0)
    assert dim_result[4] == lit_result[4]

    # 6. Zero intensity darkens the colour to zero but leaves opacity intact,
    #    so a fully shadowed surface still occludes what is behind it.
    dark = ((1.0, 1.0, 1.0), THIRDS, (0.0, 1.0), ((200, 100, 50, 128),), 0.0, 1.0)
    dark_result = evaluate(*dark)
    assert dark_result[1] == 0.0
    assert dark_result[4] == div(128.0, 255.0)

    # 7. Per-object and per-value opacity compose by multiplication, in that
    #    order. A half-opaque object over a half-opaque entry is one quarter.
    layered = ((1.0, 1.0, 1.0), THIRDS, (0.0, 1.0), ((255, 255, 255, 128),), 1.0, 0.5)
    assert evaluate(*layered)[4] == mul(0.5, div(128.0, 255.0))

    # 8. Interpolation across differing vertex scalars selects an interior
    #    entry, and unequal weights move the selection.
    varying = ((0.0, 1.0, 0.0), THIRDS, (0.0, 1.0), GREY_RAMP, 1.0, 1.0)
    skewed = ((0.0, 1.0, 0.0), (0.0, 1.0, 0.0), (0.0, 1.0), GREY_RAMP, 1.0, 1.0)
    assert evaluate(*varying)[0] == 1
    assert evaluate(*skewed)[0] == 3

    # 9. A negative domain works: the mapping is affine, not sign-dependent.
    negative = ((-500.0, -500.0, -500.0), THIRDS, (-1000.0, 0.0), GREY_RAMP, 1.0, 1.0)
    assert evaluate(*negative)[0] == 2

    # 10. A degenerate domain is rejected rather than dividing by zero.
    degenerate = ((0.5, 0.5, 0.5), THIRDS, (1.0, 1.0), GREY_RAMP, 1.0, 1.0)
    try:
        evaluate(*degenerate)
    except ColourMapFailure as error:
        assert str(error) == "invalidDomain"
    else:
        raise AssertionError("A degenerate domain must be rejected.")

    # 11. A non-finite scalar is rejected. Vertex attributes are raw bytes, so
    #     unlike positions this is not already guaranteed finite.
    not_representable = (
        (float("nan"), 0.0, 0.0),
        (1.0, 0.0, 0.0),
        (0.0, 1.0),
        GREY_RAMP,
        1.0,
        1.0,
    )
    try:
        evaluate(*not_representable)
    except ColourMapFailure as error:
        assert str(error) == "scalarNotRepresentable"
    else:
        raise AssertionError("A non-finite scalar must be rejected.")

    # 12. An empty table is rejected.
    empty_table = ((0.5, 0.5, 0.5), THIRDS, (0.0, 1.0), (), 1.0, 1.0)
    try:
        evaluate(*empty_table)
    except ColourMapFailure as error:
        assert str(error) == "invalidTable"
    else:
        raise AssertionError("An empty table must be rejected.")

    fixtures = (
        ("at-domain-minimum", at_min),
        ("at-domain-maximum", at_max),
        ("halfway-rounds-away", halfway),
        ("below-domain-clamps", below),
        ("above-domain-clamps", above),
        ("single-entry-table", single),
        ("fully-lit", lit),
        ("half-lit", dim),
        ("zero-intensity-keeps-opacity", dark),
        ("layer-and-entry-opacity", layered),
        ("interpolated-scalar", varying),
        ("skewed-weights", skewed),
        ("negative-domain", negative),
        ("degenerate-domain", degenerate),
        ("non-finite-scalar", not_representable),
        ("empty-table", empty_table),
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
    colour_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert colour_digest == EXPECTED_COLOUR_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"colourSHA256={colour_digest}")
    print(f"fixtures={len(fixtures)} successful=13 failures=3")
    print("colour=8-bit-straight-rgba normalisation=divide-by-255")
    print("selection=nearest-entry-round-half-away outOfDomain=clamped")
    print("shading=modulates-colour-never-opacity opacity=layer-times-entry")


if __name__ == "__main__":
    main()
