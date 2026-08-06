#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Independent oracle for VOXELIA-ALG-0048: CT series geometry validation.

Computed from the algorithm specification's prose alone, in IEEE-754 binary64,
with the frozen expression order and no fused multiply-add.

The separation this oracle exists to protect: every quantity below is an EXACT
measurement -- a subtraction, a product-sum, or a comparison against zero. No
threshold appears in the arithmetic. Thresholds are a separate policy input, so
that the numbers a series is judged by are reproducible independently of the
judgement applied to them.
"""

from __future__ import annotations

import math
from dataclasses import dataclass


@dataclass(frozen=True)
class Member:
    ident: str
    rows: int
    columns: int
    scalar: str
    row: tuple[float, float, float]
    column: tuple[float, float, float]
    row_spacing: float
    column_spacing: float
    projection: float
    rescale_slope: float = 1.0
    rescale_intercept: float = -1024.0
    photometric: str = "monochrome2"


# --------------------------------------------------------------------------
# Measurements. Each is exact; none consults a threshold.
# --------------------------------------------------------------------------


def slice_spacings(members: list[Member]) -> list[float]:
    """Consecutive differences of projections, in member order."""
    return [
        members[i + 1].projection - members[i].projection for i in range(len(members) - 1)
    ]


def spacing_spread(spacings: list[float]) -> float | None:
    """maximum - minimum. Anchor-free, division-free, order-independent.

    Choosing a nominal spacing and measuring deviations from it would require
    picking the anchor (arbitrary) or a mean (a division and a summation order)
    or a median (a sort and an even-count tie rule). The spread needs none of
    those and answers the question directly: by how much do the spacings vary?
    """
    if not spacings:
        return None
    return max(spacings) - min(spacings)


def orientation_deviation(members: list[Member], anchor: Member) -> float:
    """Maximum absolute componentwise difference from the anchor's directions.

    Componentwise, never a norm: a norm would square and then need a square
    root, adding overflow and a second boundary for no gain.
    """
    worst = 0.0
    for member in members:
        for index in range(3):
            worst = max(worst, abs(member.row[index] - anchor.row[index]))
            worst = max(worst, abs(member.column[index] - anchor.column[index]))
    return worst


def in_plane_deviation(members: list[Member], anchor: Member) -> float:
    worst = 0.0
    for member in members:
        worst = max(worst, abs(member.row_spacing - anchor.row_spacing))
        worst = max(worst, abs(member.column_spacing - anchor.column_spacing))
    return worst


def dot(a: tuple[float, float, float], b: tuple[float, float, float]) -> float:
    """Frozen expression order, no FMA."""
    return ((a[0] * b[0]) + (a[1] * b[1])) + (a[2] * b[2])


def magnitude_residual(v: tuple[float, float, float]) -> float:
    """(v . v) - 1, in frozen order. No square root."""
    return dot(v, v) - 1.0


def has_duplicate_projections(members: list[Member]) -> bool:
    """Exact equality only. IEEE comparison, so +0 and -0 count as equal."""
    for i in range(len(members) - 1):
        if members[i].projection == members[i + 1].projection:
            return True
    return False


def uniform_grid(members: list[Member]) -> bool:
    first = members[0]
    return all(
        m.rows == first.rows and m.columns == first.columns and m.scalar == first.scalar
        for m in members
    )


def presentation_agrees(members: list[Member]) -> bool:
    first = members[0]
    return all(
        m.rescale_slope == first.rescale_slope
        and m.rescale_intercept == first.rescale_intercept
        and m.photometric == first.photometric
        for m in members
    )


# --------------------------------------------------------------------------
# The verdict. Thresholds enter ONLY here, and only as supplied policy.
# --------------------------------------------------------------------------

# The exact tolerance: every threshold zero. ADR-0229 defines no other value,
# because a permissive threshold is a clinical safety parameter this project has
# no evidence to set.
EXACT = {
    "orientation": 0.0,
    "in_plane": 0.0,
    "slice_spacing": 0.0,
    "orthonormality": 0.0,
}

REJECTING = {
    "nonUniformGrid",
    "degenerateReferenceNormal",
    "nonFiniteReferenceNormal",
    "nonFiniteProjection",
    "duplicateProjections",
    "orientationDisagreement",
    "inPlaneSpacingDisagreement",
    "sliceSpacingIrregular",
    "nonOrthogonalDirections",
    "nonUnitDirections",
}

WARNING = {"singleMemberSeries", "presentationDisagreement"}


def assess(
    members: list[Member],
    tolerance: dict,
    ordered_by_projection: bool = True,
    series_observations: set[str] | None = None,
) -> tuple[dict, set[str], str]:
    observations = series_observations or set()
    anchor = min(members, key=lambda m: m.ident)

    spacings = slice_spacings(members) if ordered_by_projection else []
    spread = spacing_spread(spacings)

    measurement = {
        "memberCount": len(members),
        "minimumSliceSpacing": min(spacings) if spacings else None,
        "maximumSliceSpacing": max(spacings) if spacings else None,
        "sliceSpacingSpread": spread,
        "maximumOrientationDeviation": orientation_deviation(members, anchor),
        "maximumInPlaneSpacingDeviation": in_plane_deviation(members, anchor),
        "rowColumnDotProduct": dot(anchor.row, anchor.column),
        "rowMagnitudeResidual": magnitude_residual(anchor.row),
        "columnMagnitudeResidual": magnitude_residual(anchor.column),
        "hasDuplicateProjections": has_duplicate_projections(members)
        if ordered_by_projection
        else False,
        "hasUniformGrid": uniform_grid(members),
    }

    findings: set[str] = set()

    # Facts inherited from assembly, never recomputed here.
    findings |= observations

    if not measurement["hasUniformGrid"]:
        findings.add("nonUniformGrid")
    if measurement["hasDuplicateProjections"]:
        findings.add("duplicateProjections")
    if len(members) == 1:
        findings.add("singleMemberSeries")
    if measurement["maximumOrientationDeviation"] > tolerance["orientation"]:
        findings.add("orientationDisagreement")
    if measurement["maximumInPlaneSpacingDeviation"] > tolerance["in_plane"]:
        findings.add("inPlaneSpacingDisagreement")
    if spread is not None and spread > tolerance["slice_spacing"]:
        findings.add("sliceSpacingIrregular")
    if abs(measurement["rowColumnDotProduct"]) > tolerance["orthonormality"]:
        findings.add("nonOrthogonalDirections")
    if (
        abs(measurement["rowMagnitudeResidual"]) > tolerance["orthonormality"]
        or abs(measurement["columnMagnitudeResidual"]) > tolerance["orthonormality"]
    ):
        findings.add("nonUnitDirections")
    if not presentation_agrees(members):
        findings.add("presentationDisagreement")

    if findings & REJECTING:
        verdict = "rejected"
    elif findings & WARNING:
        verdict = "representableWithWarnings"
    else:
        verdict = "representable"

    return measurement, findings, verdict


# --------------------------------------------------------------------------
# Fixtures.
# --------------------------------------------------------------------------

AXIAL_ROW = (1.0, 0.0, 0.0)
AXIAL_COLUMN = (0.0, 1.0, 0.0)


def member(
    ident: str,
    projection: float,
    rows: int = 512,
    columns: int = 512,
    scalar: str = "int16",
    row=AXIAL_ROW,
    column=AXIAL_COLUMN,
    row_spacing: float = 0.7,
    column_spacing: float = 0.7,
    rescale_slope: float = 1.0,
    photometric: str = "monochrome2",
) -> Member:
    return Member(
        ident=ident,
        rows=rows,
        columns=columns,
        scalar=scalar,
        row=row,
        column=column,
        row_spacing=row_spacing,
        column_spacing=column_spacing,
        projection=projection,
        rescale_slope=rescale_slope,
        photometric=photometric,
    )


FIXTURES: list[tuple[str, list[Member], dict, bool, set[str]]] = [
    (
        "G1 a perfectly regular three-slice axial series",
        [member("g1", 0.0), member("g2", 2.5), member("g3", 5.0)],
        EXACT,
        True,
        set(),
    ),
    (
        "G2 one spacing short by 1e-4 mm",
        [member("g1", 0.0), member("g2", 2.5), member("g3", 4.9999)],
        EXACT,
        True,
        set(),
    ),
    (
        "G3 a missing slice doubles one gap",
        [member("g1", 0.0), member("g2", 2.5), member("g3", 7.5)],
        EXACT,
        True,
        set(),
    ),
    (
        "G4 two co-located slices duplicate a position",
        [member("g1", 0.0), member("g2", 2.5), member("g3", 2.5)],
        EXACT,
        True,
        set(),
    ),
    (
        "G5 a mixed grid cannot be one array",
        [member("g1", 0.0), member("g2", 2.5, rows=256)],
        EXACT,
        True,
        set(),
    ),
    (
        "G6 orientation disagreeing by one ULP",
        [
            member("g1", 0.0),
            member("g2", 2.5, row=(1.0, 0.0, 0.0)),
            member("g3", 5.0, row=(math.nextafter(1.0, 2.0), 0.0, 0.0)),
        ],
        EXACT,
        True,
        set(),
    ),
    (
        "G7 non-orthogonal anchor directions",
        [
            member("g1", 0.0, column=(0.5, 0.5, 0.0)),
            member("g2", 2.5, column=(0.5, 0.5, 0.0)),
        ],
        EXACT,
        True,
        set(),
    ),
    (
        "G8 a non-unit row direction",
        [member("g1", 0.0, row=(3.0, 0.0, 0.0)), member("g2", 2.5, row=(3.0, 0.0, 0.0))],
        EXACT,
        True,
        set(),
    ),
    (
        "G9 a single-member series warns rather than rejecting",
        [member("g1", 0.0)],
        EXACT,
        True,
        set(),
    ),
    (
        "G10 an assembly observation is inherited, not recomputed",
        [member("g1", 0.0), member("g2", 0.0)],
        EXACT,
        False,
        {"degenerateReferenceNormal"},
    ),
    (
        "G11 in-plane spacing disagreement",
        [member("g1", 0.0), member("g2", 2.5, row_spacing=0.71)],
        EXACT,
        True,
        set(),
    ),
    (
        "G12 contradictory rescale is a warning, not a geometry rejection",
        [member("g1", 0.0), member("g2", 2.5, rescale_slope=2.0)],
        EXACT,
        True,
        set(),
    ),
    (
        "G13 two decimal spellings that round to one double are accepted",
        # 0.7071067811865476 and 0.70710678118654757 are different decimal
        # strings naming the same binary64 value, so the deviation is EXACTLY
        # zero and the exact tolerance admits them. Exact tolerance forgives
        # re-spelling; it refuses only values that land on different doubles,
        # which is fixture G6.
        # Kept axial so the claim is isolated: orthonormality is trivially
        # satisfied and the only thing under test is the re-spelling.
        [
            member("g1", 0.0, row=(1.0, 0.0, 0.0)),
            member("g2", 2.5, row=(0.99999999999999999, 0.0, 0.0)),
        ],
        EXACT,
        True,
        set(),
    ),
]


def show(value) -> str:
    if value is None:
        return "absent"
    if isinstance(value, bool):
        return str(value)
    if isinstance(value, int):
        return str(value)
    return f"{value!r} ({value.hex()})"


def main() -> None:
    print("VOXELIA-ALG-0048 oracle - CT series geometry validation")
    print("=" * 78)
    for title, members, tolerance, ordered, observations in FIXTURES:
        measurement, findings, verdict = assess(
            members, tolerance, ordered, observations
        )
        print()
        print(title)
        print(f"  verdict: {verdict}")
        print(f"  findings: {sorted(findings) if findings else 'none'}")
        for name in (
            "memberCount",
            "minimumSliceSpacing",
            "maximumSliceSpacing",
            "sliceSpacingSpread",
            "maximumOrientationDeviation",
            "maximumInPlaneSpacingDeviation",
            "rowColumnDotProduct",
            "rowMagnitudeResidual",
            "columnMagnitudeResidual",
            "hasDuplicateProjections",
            "hasUniformGrid",
        ):
            print(f"    {name}: {show(measurement[name])}")


if __name__ == "__main__":
    main()
