#!/usr/bin/env python3
"""Independent oracle for ADR-0212 and VOXELIA-ALG-0044."""

from __future__ import annotations

import hashlib


EXPECTED_FIXTURE_SHA256 = (
    "6115cfd287cc8bd9c7cbebb79d697d198bb8d64306b1375ccbfdca003e9cb0f2"
)
EXPECTED_CHANNEL_SHA256 = (
    "9a039575cea559af60aba8c8cdc87891205e6d04b50ab0a17df371594b9d46a4"
)


class RGBSourceFailure(Exception):
    """One payload-free oracle classification."""


def present(interpretation: str, sample_type: str, channels: list):
    """The frozen RGB source presentation rule.

    There is deliberately NO arithmetic here. An eight-bit RGB source is
    already display values in the output representation, so presenting it is a
    byte pass-through and the only real content is the admission, the channel
    order and the alpha rule. Manufacturing a numeric step would invent a
    transform the source never asked for.

    The photometric relabelling question is discharged one level up:
    `ImageDescriptor` already binds `.rgb`/`.rgba` to the `.colour` semantic and
    rejects the mismatch in both directions, so a monochrome source cannot
    arrive here claiming to be colour.
    """
    if interpretation not in ("rgb", "rgba"):
        raise RGBSourceFailure("unsupportedInterpretation")
    # Eight bits only. Reducing a wider channel to eight is a real choice
    # between taking the high byte and scaling, with no consumer to settle it —
    # the same reason `ALG-0043` excludes sixteen-bit palette entries.
    if sample_type != "uint8":
        raise RGBSourceFailure("unsupportedSampleType")
    expected = 3 if interpretation == "rgb" else 4
    if len(channels) != expected:
        raise RGBSourceFailure("channelCountMismatch")

    if interpretation == "rgb":
        # A source with no alpha channel is opaque. This matches `ALG-0043`'s
        # palette rule for the same reason: an image is not an overlay.
        return (channels[0], channels[1], channels[2], 255)
    # An alpha channel passes through UNCHANGED — including a transparent one.
    # It is interpreted as STRAIGHT, not premultiplied, which is the accepted
    # representation `ALG-0023` uses. A premultiplied source must be converted
    # by its adapter.
    return (channels[0], channels[1], channels[2], channels[3])


def record(name: str, case) -> tuple[str, bytes]:
    try:
        pixel = present(*case)
    except RGBSourceFailure as error:
        return f"{name}|error={error}", b""
    return (
        f"{name}|rgba={pixel[0]},{pixel[1]},{pixel[2]},{pixel[3]}",
        bytes(pixel),
    )


def main() -> None:
    # 1. Channels pass through in order, and a source with no alpha is opaque.
    assert present("rgb", "uint8", [10, 20, 30]) == (10, 20, 30, 255)

    # 2. An alpha channel passes through unchanged, including a fully
    #    transparent one — the difference from the palette rule, where alpha is
    #    always opaque because a palette source has none to carry.
    assert present("rgba", "uint8", [10, 20, 30, 40]) == (10, 20, 30, 40)
    assert present("rgba", "uint8", [10, 20, 30, 0]) == (10, 20, 30, 0)

    # 3. The channel order is load-bearing: a swap would change this.
    assert present("rgb", "uint8", [1, 2, 3]) == (1, 2, 3, 255)

    # 4. A non-colour interpretation is rejected rather than reinterpreted.
    for interpretation in ("scalar", "vector", "labelProbability"):
        try:
            present(interpretation, "uint8", [1, 2, 3])
        except RGBSourceFailure as error:
            assert str(error) == "unsupportedInterpretation"
        else:
            raise AssertionError("A non-colour source must be rejected.")

    # 5. A wider channel is rejected rather than silently reduced.
    try:
        present("rgb", "uint16", [1, 2, 3])
    except RGBSourceFailure as error:
        assert str(error) == "unsupportedSampleType"
    else:
        raise AssertionError("A wider sample type must be rejected.")

    # 6. The channel count must match the interpretation exactly, both ways.
    for case in [
        ("rgb", "uint8", [1, 2]),
        ("rgb", "uint8", [1, 2, 3, 4]),
        ("rgba", "uint8", [1, 2, 3]),
    ]:
        try:
            present(*case)
        except RGBSourceFailure as error:
            assert str(error) == "channelCountMismatch"
        else:
            raise AssertionError("A channel count mismatch must be rejected.")

    fixtures = (
        ("rgb-passthrough", ("rgb", "uint8", [10, 20, 30])),
        ("rgba-passthrough", ("rgba", "uint8", [10, 20, 30, 40])),
        ("rgba-transparent", ("rgba", "uint8", [10, 20, 30, 0])),
        ("channel-order", ("rgb", "uint8", [1, 2, 3])),
        ("rgb-extremes", ("rgb", "uint8", [0, 255, 0])),
        ("rgba-opaque-maximum", ("rgba", "uint8", [255, 255, 255, 255])),
        ("scalar-source", ("scalar", "uint8", [1, 2, 3])),
        ("vector-source", ("vector", "uint8", [1, 2, 3])),
        ("wide-sample-type", ("rgb", "uint16", [1, 2, 3])),
        ("rgb-too-few-channels", ("rgb", "uint8", [1, 2])),
        ("rgb-too-many-channels", ("rgb", "uint8", [1, 2, 3, 4])),
        ("rgba-too-few-channels", ("rgba", "uint8", [1, 2, 3])),
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
    print(f"fixtures={len(fixtures)} presented=6 rejected=6")
    print("transform=byte-pass-through arithmetic=none alpha=straight")
    print("rgbAlpha=opaque rgbaAlpha=preserved sampleType=uint8-only")


if __name__ == "__main__":
    main()
