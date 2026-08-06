#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0206 and VOXELIA-ALG-0040."""

from __future__ import annotations

import hashlib
import math
import struct


EXPECTED_FIXTURE_SHA256 = (
    "8950824148a6fd801296f2114328d198bf613c8c10dcb95422e23f82d0b97615"
)
EXPECTED_REGISTRATION_SHA256 = (
    "53ee6d24ef61d5b57f2c13d1ac4f8f647d83907b1b88534718ba9dc0f0a1ea93"
)


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def buffer(width: int, height: int, entries: dict) -> list:
    """The nearest RETAINED occluder depth at each pixel, row-major.

    Retained means the clip predicate already kept it. A clipped-away fragment
    must not occlude an annotation any more than it may occlude a pick, so the
    clip runs before this stage exactly as `ALG-0039` froze.
    """
    return [entries.get((column, row)) for row in range(height)
            for column in range(width)]


def register(anchor, viewport, occluders):
    """The frozen registration rule.

    The anchor arrives already projected by `ALG-0033`, so this stage adds no
    second projection that could disagree with the one that drew the image.

    Statelessness is the whole registration claim: the outcome is a pure
    function of the anchor, the pose and the buffer, with nothing carried
    between poses. Any hysteresis or smoothing would make the answer depend on
    the path the camera took rather than on where it now is.
    """
    column, row, depth = anchor
    width, height = viewport

    # 1. The bound is tested on the CONTINUOUS coordinate, before any integer
    #    conversion. That ordering is what makes the conversion total: a
    #    coordinate admitted here is already inside the viewport, so its floor
    #    is representable. An off-viewport anchor is NOT clamped to the edge —
    #    a marker drawn at the rim would claim a physical place it does not
    #    occupy.
    if not (0 <= column < width and 0 <= row < height):
        return None

    # 2. The pixel containing the anchor is its FLOOR, not its rounding.
    #    `ALG-0033` publishes continuous top-left coordinates and `ALG-0034`
    #    samples at pixel centres, so pixel k covers [k, k+1). Rounding would
    #    move every anchor past the half-pixel to its neighbour.
    pixel_column = math.floor(column)
    pixel_row = math.floor(row)

    # 3. The SAME pixel rule serves the placement and the occlusion lookup, so
    #    the two cannot disagree about which pixel is being asked about.
    occluder = occluders[pixel_row * width + pixel_column]

    # 4. Occlusion is STRICT: only geometry strictly nearer than the anchor
    #    hides it. An exactly equal depth leaves the annotation visible, which
    #    is the same strict-less comparison `ALG-0034` uses for its own
    #    tie-break. There is no depth bias and no epsilon: a bias is a magic
    #    number no accepted record supplies, and its effect would change with
    #    the scene's scale.
    occluded = occluder is not None and occluder < depth
    return (pixel_column, pixel_row, depth, occluded)


def record(name: str, case) -> tuple[str, bytes]:
    outcome = register(*case)
    if outcome is None:
        return f"{name}|registration=off-viewport", b""
    column, row, depth, occluded = outcome
    payload = struct.pack("<qq", column, row)
    payload += struct.pack("<Q", bits(depth))
    payload += struct.pack("<B", 1 if occluded else 0)
    return (
        f"{name}|column={column}|row={row}"
        f"|depth={bits(depth):016x}|occluded={1 if occluded else 0}",
        payload,
    )


VIEWPORT = (4, 4)
EMPTY = buffer(4, 4, {})


def main() -> None:
    # One occluder at the anchor's pixel (1, 2), nearer than the anchor.
    nearer = buffer(4, 4, {(1, 2): 1.0})
    farther = buffer(4, 4, {(1, 2): 9.0})
    equal = buffer(4, 4, {(1, 2): 2.0})
    elsewhere = buffer(4, 4, {(0, 0): -100.0, (3, 3): -100.0})

    anchor = (1.5, 2.5, 2.0)

    # 1. An unoccluded anchor registers at the pixel containing it.
    assert register(anchor, VIEWPORT, EMPTY) == (1, 2, 2.0, False)

    # 2. Strictly nearer geometry occludes; farther geometry does not.
    assert register(anchor, VIEWPORT, nearer)[3] is True
    assert register(anchor, VIEWPORT, farther)[3] is False

    # 3. THE tie decision. An exactly equal depth leaves the annotation
    #    visible: an anchor placed on the surface it annotates must not be
    #    hidden by that surface, and the rule is the strict comparison itself
    #    rather than a bias term.
    assert register(anchor, VIEWPORT, equal)[3] is False

    # 4. The pixel is the FLOOR of the continuous coordinate. Rounding would
    #    put this anchor in pixel 3.
    assert register((2.6, 0.5, 1.0), VIEWPORT, EMPTY)[0] == 2
    #    An exact integer belongs to the pixel it opens, not the one it closes.
    assert register((3.0, 0.5, 1.0), VIEWPORT, EMPTY)[0] == 3
    assert register((math.nextafter(3.0, 0.0), 0.5, 1.0), VIEWPORT,
                    EMPTY)[0] == 2

    # 5. The bound is inclusive at zero and exclusive at the dimension, on
    #    both axes, and an outside anchor is reported off-viewport rather than
    #    clamped.
    assert register((0.0, 0.0, 1.0), VIEWPORT, EMPTY)[:2] == (0, 0)
    assert register((math.nextafter(4.0, 0.0), 3.5, 1.0), VIEWPORT,
                    EMPTY)[0] == 3
    for outside in [(4.0, 0.5), (0.5, 4.0), (-1e-7, 0.5), (0.5, -1e-7)]:
        assert register((outside[0], outside[1], 1.0), VIEWPORT,
                        EMPTY) is None

    # 6. Negative zero is inside the viewport: it compares equal to zero and
    #    floors to zero, so it needs no special case.
    assert register((-0.0, -0.0, 1.0), VIEWPORT, EMPTY)[:2] == (0, 0)

    # 7. A behind-camera anchor registers: `ALG-0033` admits negative depth
    #    under orthographic projection and no near plane exists. The
    #    comparison is on the signed depth axis, not on magnitude, so a more
    #    negative occluder still occludes.
    assert register((1.5, 2.5, -3.0), VIEWPORT, EMPTY)[3] is False
    behind_occluder = buffer(4, 4, {(1, 2): -5.0})
    assert register((1.5, 2.5, -3.0), VIEWPORT, behind_occluder)[3] is True

    # 8. The occlusion lookup uses the ANNOTATION's pixel: geometry at other
    #    pixels, however near, leaves it visible.
    assert register(anchor, VIEWPORT, elsewhere)[3] is False

    # 9. Two poses of one fixed anchor. The registration claim is exactly that
    #    each pose is recomputed from the anchor and the pose alone: the pixel
    #    moves and the occlusion flips, with nothing carried between them.
    pose_a = ((0.5, 0.5, 4.0), VIEWPORT, buffer(4, 4, {(0, 0): 9.0}))
    pose_b = ((3.5, 3.5, 4.0), VIEWPORT, buffer(4, 4, {(3, 3): 1.0}))
    assert register(*pose_a) == (0, 0, 4.0, False)
    assert register(*pose_b) == (3, 3, 4.0, True)

    fixtures = (
        ("inside-unoccluded", (anchor, VIEWPORT, EMPTY)),
        ("nearer-occludes", (anchor, VIEWPORT, nearer)),
        ("farther-does-not-occlude", (anchor, VIEWPORT, farther)),
        ("equal-depth-visible", (anchor, VIEWPORT, equal)),
        ("floor-not-round", ((2.6, 0.5, 1.0), VIEWPORT, EMPTY)),
        ("integer-boundary", ((3.0, 0.5, 1.0), VIEWPORT, EMPTY)),
        (
            "just-below-boundary",
            ((math.nextafter(3.0, 0.0), 0.5, 1.0), VIEWPORT, EMPTY),
        ),
        ("first-pixel", ((0.0, 0.0, 1.0), VIEWPORT, EMPTY)),
        (
            "last-pixel",
            (
                (math.nextafter(4.0, 0.0), math.nextafter(4.0, 0.0), 1.0),
                VIEWPORT,
                EMPTY,
            ),
        ),
        ("column-at-width-off", ((4.0, 0.5, 1.0), VIEWPORT, EMPTY)),
        ("row-at-height-off", ((0.5, 4.0, 1.0), VIEWPORT, EMPTY)),
        ("negative-column-off", ((-1e-7, 0.5, 1.0), VIEWPORT, EMPTY)),
        ("negative-row-off", ((0.5, -1e-7, 1.0), VIEWPORT, EMPTY)),
        ("negative-zero", ((-0.0, -0.0, 1.0), VIEWPORT, EMPTY)),
        ("behind-camera-visible", ((1.5, 2.5, -3.0), VIEWPORT, EMPTY)),
        (
            "behind-camera-occluded",
            ((1.5, 2.5, -3.0), VIEWPORT, behind_occluder),
        ),
        ("occluder-elsewhere", (anchor, VIEWPORT, elsewhere)),
        ("pose-a", pose_a),
        ("pose-b", pose_b),
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
    registration_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert registration_digest == EXPECTED_REGISTRATION_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"registrationSHA256={registration_digest}")
    print(f"fixtures={len(fixtures)} registered=15 offViewport=4")
    print("pixel=floor occlusion=strict-nearer bias=none")
    print("offViewport=reported-not-clamped state=none")


if __name__ == "__main__":
    main()
