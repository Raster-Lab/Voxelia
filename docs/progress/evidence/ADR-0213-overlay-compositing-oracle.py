#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0213 and VOXELIA-ALG-0045."""

from __future__ import annotations

import hashlib
import math


EXPECTED_FIXTURE_SHA256 = (
    "f91aaecff517a77019e9ec4201555cbdd16784b30f68c447f9d8087d919d3a0b"
)
EXPECTED_PIXEL_SHA256 = (
    "36c48cd8d48defdc25039dffea2936cdcad64a6963de89319aecdabd9e964171"
)


class OverlayFailure(Exception):
    """One payload-free oracle classification."""


def round_ties_even(value: float) -> int:
    """IEEE-754 roundTiesToEven, the rule `ALG-0002` and `ALG-0009` use."""
    floor_value = math.floor(value)
    difference = value - floor_value
    if difference > 0.5:
        return floor_value + 1
    if difference < 0.5:
        return floor_value
    return floor_value if floor_value % 2 == 0 else floor_value + 1


def labelled(label: int, table: list):
    """A LABELLED overlay contribution: mask and segmentation are one kind.

    A mask is a segmentation with two labels. Carrying a separate mask model
    would be two places for one rule, and they would drift.

    A label with no table entry is REJECTED rather than clamped. Clamping — the
    right rule for a palette, where an out-of-range value is a display
    artefact — would here paint an unassigned label the last colour in the
    table, which is a silently wrong overlay on diagnostic imagery.
    """
    if label < 0 or label >= len(table):
        raise OverlayFailure("unmappedLabel")
    return table[label]


def contribution(entry, opacity: float) -> tuple:
    """One resolved overlay contribution: a colour and an effective alpha."""
    if not (0.0 <= opacity <= 1.0):
        raise OverlayFailure("invalidOpacity")
    # The entry's alpha is normalised by /255.0, the accepted rule `ALG-0023`
    # uses, then multiplied by the layer opacity. One correctly rounded
    # multiplication; no fused multiply-add.
    alpha = (entry[3] / 255.0) * opacity
    return ((entry[0], entry[1], entry[2]), alpha)


def composite(base: tuple, contributions: list) -> tuple:
    """The frozen overlay compositing rule.

    The per-channel arithmetic is `ALG-0009`'s frozen sequence VERBATIM. What
    differs is where alpha comes from — per pixel, not per layer — and what the
    background is: the base image, not black. The operator is inherited; the
    layer model is not.

    The accumulator stays binary64 across every overlay and is rounded ONCE at
    the end. Rounding between overlays would drift, and the registered
    `single-rounding` fixture pins a case where it visibly would.
    """
    accumulators = [float(component) for component in base]
    for colour, alpha in contributions:
        for lane in range(3):
            t = 1 - alpha
            p = accumulators[lane] * t
            q = colour[lane] * alpha
            accumulators[lane] = p + q
    # The base is an opaque display image, so the result is opaque and no
    # alpha accumulation is needed.
    return tuple(
        max(0, min(255, round_ties_even(value))) for value in accumulators
    ) + (255,)


def resolve(overlay) -> tuple:
    """Resolves one overlay of either kind to a `(colour, alpha)` pair.

    Both kinds reduce to the same pair, which is the model's central finding:
    the three overlays the requirement names differ only in how they PRODUCE a
    colour and an alpha, never in how that pair is composited.
    """
    kind, payload, opacity = overlay
    if kind == "label":
        label, table = payload
        return contribution(labelled(label, table), opacity)
    return contribution(payload, opacity)


def record(name: str, case) -> tuple[str, bytes]:
    base, overlays = case
    try:
        pixel = composite(base, [resolve(overlay) for overlay in overlays])
    except OverlayFailure as error:
        return f"{name}|error={error}", b""
    return (
        f"{name}|rgba={pixel[0]},{pixel[1]},{pixel[2]},{pixel[3]}",
        bytes(pixel),
    )


def main() -> None:
    base = (10, 20, 30)
    red = (255, 0, 0, 255)
    # A two-label table IS a mask: entry zero is not drawn, entry one is.
    mask_table = [(0, 0, 0, 0), (0, 255, 0, 255)]
    segmentation_table = [
        (0, 0, 0, 0),
        (255, 0, 0, 255),
        (0, 0, 255, 255),
    ]

    # 1. A fully opaque overlay replaces the base exactly, because
    #    `acc * 0 + x * 1` is exact in binary64.
    assert composite(base, [contribution(red, 1.0)]) == (255, 0, 0, 255)

    # 2. A fully transparent overlay leaves the base exactly.
    assert composite(base, [contribution(red, 0.0)]) == (10, 20, 30, 255)

    # 3. A half-opaque overlay is the exact midpoint.
    assert composite(base, [contribution(red, 0.5)]) == (132, 10, 15, 255)

    # 4. Order matters, and the registered pair proves it.
    green = (0, 255, 0, 255)
    first = composite(
        base, [contribution(red, 0.5), contribution(green, 0.5)]
    )
    second = composite(
        base, [contribution(green, 0.5), contribution(red, 0.5)]
    )
    assert first != second

    # 5. A mask is a segmentation with two labels: entry zero contributes
    #    nothing at all, entry one contributes its colour.
    absent = contribution(labelled(0, mask_table), 1.0)
    present = contribution(labelled(1, mask_table), 1.0)
    assert composite(base, [absent]) == (10, 20, 30, 255)
    assert composite(base, [present]) == (0, 255, 0, 255)

    # 6. A segmentation selects its label's own colour.
    assert composite(
        base, [contribution(labelled(2, segmentation_table), 1.0)]
    ) == (0, 0, 255, 255)

    # 7. An unassigned label is REJECTED, not clamped to the last colour.
    try:
        labelled(3, segmentation_table)
    except OverlayFailure as error:
        assert str(error) == "unmappedLabel"
    else:
        raise AssertionError("An unmapped label must be rejected.")
    try:
        labelled(-1, segmentation_table)
    except OverlayFailure as error:
        assert str(error) == "unmappedLabel"
    else:
        raise AssertionError("A negative label must be rejected.")

    # 8. An image overlay's per-pixel alpha multiplies the layer opacity.
    translucent = (0, 0, 255, 128)
    assert contribution(translucent, 0.5)[1] == (128 / 255.0) * 0.5

    # 9. An opacity outside the unit interval, or not a number, is rejected.
    for bad in (-0.0000001, 1.0000001, float("nan"), float("inf")):
        try:
            contribution(red, bad)
        except OverlayFailure as error:
            assert str(error) == "invalidOpacity"
        else:
            raise AssertionError("An invalid opacity must be rejected.")

    fixtures = (
        ("opaque-overlay", (base, [("entry", red, 1.0)])),
        ("transparent-overlay", (base, [("entry", red, 0.0)])),
        ("half-alpha", (base, [("entry", red, 0.5)])),
        (
            "order-red-then-green",
            (base, [("entry", red, 0.5), ("entry", green, 0.5)]),
        ),
        (
            "order-green-then-red",
            (base, [("entry", green, 0.5), ("entry", red, 0.5)]),
        ),
        (
            "single-rounding",
            (base, [("entry", red, 0.3), ("entry", green, 0.3)]),
        ),
        ("mask-absent", (base, [("label", (0, mask_table), 1.0)])),
        ("mask-present", (base, [("label", (1, mask_table), 1.0)])),
        (
            "segmentation-second-label",
            (base, [("label", (2, segmentation_table), 1.0)]),
        ),
        (
            "segmentation-background",
            (base, [("label", (0, segmentation_table), 1.0)]),
        ),
        ("image-overlay-translucent", (base, [("entry", translucent, 0.5)])),
        ("image-overlay-full", (base, [("entry", translucent, 1.0)])),
        (
            "clamp-at-white",
            ((255, 255, 255), [("entry", (255, 255, 255, 255), 1.0)]),
        ),
        ("clamp-at-black", ((0, 0, 0), [("entry", (0, 0, 0, 255), 1.0)])),
        ("unmapped-label", (base, [("label", (3, segmentation_table), 1.0)])),
        (
            "negative-label",
            (base, [("label", (-1, segmentation_table), 1.0)]),
        ),
        ("opacity-above-one", (base, [("entry", red, 1.0000001)])),
        ("opacity-not-a-number", (base, [("entry", red, float("nan"))])),
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
    pixel_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert pixel_digest == EXPECTED_PIXEL_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"pixelSHA256={pixel_digest}")
    print(f"fixtures={len(fixtures)} composited=14 rejected=4")
    print("operator=alg-0009-verbatim background=base-image alpha=straight")
    print("mask=two-label-segmentation unmappedLabel=rejected rounding=once")


if __name__ == "__main__":
    main()
