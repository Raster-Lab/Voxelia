#!/usr/bin/env python3
"""Independent binary64 oracle for ADR-0205 and VOXELIA-ALG-0039."""

from __future__ import annotations

import hashlib
import struct


EXPECTED_FIXTURE_SHA256 = (
    "b5ff409fd3621af9730f9e43b94e68ac5aabe42b8f2799cce72e94993dac13b2"
)
EXPECTED_POSITION_SHA256 = (
    "036c7042a75859dc6effb1cdd47b50cec74cca6cb9d727a964bcfdd53503be96"
)


class PickFailure(Exception):
    """One payload-free oracle classification."""


def bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def candidate(depth, layer, facet, world, retained, indices):
    """One covering fragment already judged by the clip predicate."""
    return {
        "depth": depth,
        "layer": layer,
        "facet": facet,
        "world": world,
        "retained": retained,
        "indices": indices,
    }


def pick(candidates, pixel, viewport):
    """The frozen pick rule.

    Clipping is applied BEFORE the nearest-surface decision. A clipped-away
    fragment must not occlude what is behind it, so it is removed from
    consideration rather than picked and then rejected.

    The surviving order is the same strict total order the visibility and
    compositing records use, so what is picked is exactly what is seen.
    """
    column, row = pixel
    width, height = viewport
    if not (0 <= column < width and 0 <= row < height):
        raise PickFailure("pixelOutOfBounds")

    surviving = [entry for entry in candidates if entry["retained"]]
    if not surviving:
        # Nothing covered this pixel, or everything covering it was clipped
        # away. There is no hit — a position is never fabricated.
        return None
    surviving.sort(key=lambda e: (e["depth"], e["layer"], e["facet"]))
    return surviving[0]


def record(name: str, case) -> tuple[str, bytes]:
    try:
        hit = pick(*case)
    except PickFailure as error:
        return f"{name}|error={error}", b""
    if hit is None:
        return f"{name}|hit=none", b""
    payload = bytearray()
    for component in hit["world"]:
        payload.extend(struct.pack("<Q", bits(component)))
    return (
        f"{name}|layer={hit['layer']}|facet={hit['facet']}"
        f"|indices={','.join(str(i) for i in hit['indices'])}"
        f"|world={','.join(f'{bits(c):016x}' for c in hit['world'])}",
        bytes(payload),
    )


VIEWPORT = (4, 4)
PIXEL = (1, 2)


def main() -> None:
    near = candidate(1.0, 0, 3, (0.1, 0.2, 0.3), True, (7, 8, 9))
    far = candidate(5.0, 1, 0, (0.4, 0.5, 0.6), True, (1, 2, 3))

    # 1. The nearest retained fragment is picked, with its own facet's vertex
    #    indices in the mesh's ORIGINAL topology order — canonicalisation is a
    #    coverage detail and never reaches an identifier.
    simple = ([near, far], PIXEL, VIEWPORT)
    assert pick(*simple)["layer"] == 0
    assert pick(*simple)["indices"] == (7, 8, 9)

    # 2. Supply order does not matter: the pick uses the same strict total
    #    order the visibility and compositing records use.
    reversed_supply = ([far, near], PIXEL, VIEWPORT)
    assert pick(*reversed_supply) == pick(*simple)

    # 3. THE ordering obligation. A clipped-away fragment must NOT occlude
    #    what is behind it, so clipping precedes the nearest decision. Here
    #    the nearer fragment is clipped and the farther one is picked.
    clipped_near = candidate(1.0, 0, 3, (9.0, 9.0, 9.0), False, (7, 8, 9))
    occlusion = ([clipped_near, far], PIXEL, VIEWPORT)
    assert pick(*occlusion)["layer"] == 1
    assert pick(*occlusion)["world"] == (0.4, 0.5, 0.6)

    # 4. An uncovered pixel yields no hit. A position is never fabricated,
    #    following the accepted `PickResolver` honesty rule.
    uncovered = ([], PIXEL, VIEWPORT)
    assert pick(*uncovered) is None

    # 5. A pixel where everything is clipped away also yields no hit, which is
    #    the same outcome by the same rule rather than a special case.
    all_clipped = (
        [clipped_near, candidate(5.0, 1, 0, (8.0, 8.0, 8.0), False, (1, 2, 3))],
        PIXEL,
        VIEWPORT,
    )
    assert pick(*all_clipped) is None

    # 6. Equal depth keeps the earlier layer, then the earlier facet — the
    #    tie-break is inherited, not restated, so a pick can never disagree
    #    with what the renderer drew.
    tie_layer = (
        [
            candidate(2.0, 1, 0, (1.0, 0.0, 0.0), True, (4, 5, 6)),
            candidate(2.0, 0, 0, (2.0, 0.0, 0.0), True, (1, 2, 3)),
        ],
        PIXEL,
        VIEWPORT,
    )
    assert pick(*tie_layer)["layer"] == 0
    tie_facet = (
        [
            candidate(2.0, 0, 9, (1.0, 0.0, 0.0), True, (4, 5, 6)),
            candidate(2.0, 0, 2, (2.0, 0.0, 0.0), True, (1, 2, 3)),
        ],
        PIXEL,
        VIEWPORT,
    )
    assert pick(*tie_facet)["facet"] == 2

    # 7. A negative depth is pickable: there is no near plane, so a fragment
    #    behind the camera is still authoritative geometry if it is visible.
    behind = (
        [candidate(-3.0, 0, 0, (0.0, 1.0, 2.0), True, (0, 1, 2)), far],
        PIXEL,
        VIEWPORT,
    )
    assert pick(*behind)["depth"] == -3.0

    # 8. An out-of-viewport pixel is rejected rather than reported as empty:
    #    "nothing there" and "you asked wrongly" are different answers.
    for bad in [(-1, 0), (4, 0), (0, -1), (0, 4)]:
        try:
            pick([near], bad, VIEWPORT)
        except PickFailure as error:
            assert str(error) == "pixelOutOfBounds"
        else:
            raise AssertionError("An out-of-bounds pixel must be rejected.")

    # 9. The extreme in-bounds pixels are accepted, so the bound is inclusive
    #    at zero and exclusive at the dimension.
    assert pick([near], (0, 0), VIEWPORT) is not None
    assert pick([near], (3, 3), VIEWPORT) is not None

    fixtures = (
        ("nearest-retained", simple),
        ("reverse-supplied", reversed_supply),
        ("clipped-does-not-occlude", occlusion),
        ("uncovered", uncovered),
        ("all-clipped", all_clipped),
        ("tie-by-layer", tie_layer),
        ("tie-by-facet", tie_facet),
        ("negative-depth", behind),
        ("first-pixel", ([near], (0, 0), VIEWPORT)),
        ("last-pixel", ([near], (3, 3), VIEWPORT)),
        ("out-of-bounds", ([near], (4, 0), VIEWPORT)),
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
    position_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert position_digest == EXPECTED_POSITION_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"positionSHA256={position_digest}")
    print(f"fixtures={len(fixtures)} successful=10 failures=1")
    print("order=clip-then-nearest identity=layer,facet,original-indices")
    print("noHit=never-fabricated tieBreak=inherited outOfBounds=rejected")


if __name__ == "__main__":
    main()
