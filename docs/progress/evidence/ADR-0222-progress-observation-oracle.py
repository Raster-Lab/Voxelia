#!/usr/bin/env python3
"""Independent oracle for ADR-0222 and VOXELIA-ALG-0046."""

from __future__ import annotations

import hashlib


EXPECTED_FIXTURE_SHA256 = (
    "cbe6f376b55cdb20b2b9791d8dcfbd638096d034a3fd1d20c4094359a1c27e39"
)
EXPECTED_SEQUENCE_SHA256 = (
    "521642346b28883ab7813dbb316ac845fc488ad7ef166c9dc71c776c846850db"
)


class ProgressFailure(Exception):
    """One payload-free oracle classification."""


def observations(total: int, cadence: int) -> list:
    """The frozen progress-observation sequence for one bounded traversal.

    Progress is reported as COUNTS, never a fraction. A fraction would force a
    division and a rounding decision at every checkpoint and would lose
    information when the total is unknown; counts compose, and a caller that
    wants a percentage divides with its own rounding.

    The cadence is the accepted cancellation-checkpoint cadence, reused
    verbatim. Inventing a second cadence would mean two places for one decision
    to drift.
    """
    if total < 0:
        raise ProgressFailure("negativeTotal")
    if cadence < 1:
        raise ProgressFailure("invalidCadence")

    sequence = []
    for completed in range(0, total, cadence):
        sequence.append((completed, total))
    # A FINAL observation always closes the sequence, so a consumer never has
    # to infer completion and a progress display always terminates. A
    # zero-work operation reports exactly this one observation.
    sequence.append((total, total))
    return sequence


def verify(sequence: list, total: int) -> None:
    """The four guarantees the model freezes."""
    previous = -1
    for completed, reported_total in sequence:
        if reported_total != total:
            raise ProgressFailure("totalChanged")
        if completed < previous:
            raise ProgressFailure("notMonotone")
        if completed > reported_total:
            raise ProgressFailure("completedExceedsTotal")
        previous = completed
    if not sequence or sequence[-1] != (total, total):
        raise ProgressFailure("missingFinalObservation")


def record(name: str, case) -> tuple[str, bytes]:
    total, cadence = case
    try:
        sequence = observations(total, cadence)
        verify(sequence, total)
    except ProgressFailure as error:
        return f"{name}|error={error}", b""
    payload = bytearray()
    for completed, reported_total in sequence:
        payload.extend(completed.to_bytes(8, "little"))
        payload.extend(reported_total.to_bytes(8, "little"))
    return (
        f"{name}|count={len(sequence)}"
        + "|sequence="
        + ";".join(f"{c}/{t}" for c, t in sequence),
        bytes(payload),
    )


def main() -> None:
    # 1. A zero-work operation reports exactly ONE observation, so a consumer
    #    never special-cases "nothing happened".
    assert observations(0, 64) == [(0, 0)]

    # 2. Work smaller than one cadence step reports the opening zero and the
    #    final total: two observations, never a silent single jump.
    assert observations(10, 64) == [(0, 10), (10, 10)]

    # 3. An exact multiple of the cadence does NOT duplicate the final
    #    observation at the same count: the loop stops before the total and the
    #    final observation closes it.
    assert observations(128, 64) == [(0, 128), (64, 128), (128, 128)]

    # 4. A partial last step is reported at its true count, not rounded to a
    #    cadence boundary.
    assert observations(130, 64) == [
        (0, 130), (64, 130), (128, 130), (130, 130)
    ]

    # 5. The four guarantees hold for every admitted case: the total never
    #    changes, completed never decreases, completed never exceeds the total,
    #    and the last observation is exactly (total, total).
    for total in [0, 1, 63, 64, 65, 4096, 4097]:
        for cadence in [1, 64, 4096]:
            verify(observations(total, cadence), total)

    # 6. A cadence of one reports every unit, which is the densest legal
    #    sequence and still terminates exactly once at the total.
    assert observations(3, 1) == [(0, 3), (1, 3), (2, 3), (3, 3)]

    # 7. Admission: a negative total and a non-positive cadence are rejected
    #    typed. There is no other failure, because the sequence is generated
    #    rather than supplied.
    for case, expected in [
        ((-1, 64), "negativeTotal"),
        ((10, 0), "invalidCadence"),
        ((10, -1), "invalidCadence"),
    ]:
        try:
            observations(*case)
        except ProgressFailure as error:
            assert str(error) == expected
        else:
            raise AssertionError(f"{expected} must be raised.")

    fixtures = (
        ("zero-work", (0, 64)),
        ("below-one-step", (10, 64)),
        ("exact-multiple", (128, 64)),
        ("partial-last-step", (130, 64)),
        ("single-unit", (1, 64)),
        ("cadence-boundary-minus-one", (63, 64)),
        ("cadence-boundary", (64, 64)),
        ("cadence-boundary-plus-one", (65, 64)),
        ("dense-cadence", (3, 1)),
        ("vertex-cadence", (4097, 4096)),
        ("negative-total", (-1, 64)),
        ("zero-cadence", (10, 0)),
        ("negative-cadence", (10, -1)),
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
    sequence_digest = hashlib.sha256(bytes(payload)).hexdigest()
    assert fixture_digest == EXPECTED_FIXTURE_SHA256
    assert sequence_digest == EXPECTED_SEQUENCE_SHA256

    print(f"fixtureSHA256={fixture_digest}")
    print(f"sequenceSHA256={sequence_digest}")
    print(f"fixtures={len(fixtures)} reported=10 rejected=3")
    print("units=counts fraction=never cadence=accepted-checkpoint")
    print("monotone=guaranteed final=always totalChanges=never")


if __name__ == "__main__":
    main()
