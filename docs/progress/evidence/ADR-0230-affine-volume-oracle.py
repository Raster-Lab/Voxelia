#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Independent oracle for VOXELIA-ALG-0049: CT affine volume construction.

Computed from the algorithm specification's prose alone, in IEEE-754 binary64,
with the frozen expression order and no fused multiply-add.

The construction deliberately never normalises a direction and never divides.
The slice step is taken as a VECTOR difference of two stated positions, so the
unit normal -- and therefore a square root -- is never needed.
"""

from __future__ import annotations

from dataclasses import dataclass

LEAST_NORMAL = 2.2250738585072014e-308  # Double.leastNormalMagnitude


@dataclass(frozen=True)
class Member:
    ident: str
    row: tuple[float, float, float]
    column: tuple[float, float, float]
    row_spacing: float
    column_spacing: float
    position: tuple[float, float, float]


def scaled(scalar: float, vector: tuple[float, float, float]):
    """Componentwise scaling in frozen order."""
    return (scalar * vector[0], scalar * vector[1], scalar * vector[2])


def difference(a: tuple[float, float, float], b: tuple[float, float, float]):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def index_to_world(members: list[Member]) -> list[float]:
    """The row-major index-to-world matrix.

    Index 0 is the COLUMN index, index 1 the ROW index, index 2 the slice.
    The steps follow the ADR-0227 axis convention exactly:
      - the column index advances along rowDirection by columnSpacing;
      - the row index advances along columnDirection by rowSpacing.
    Using distinct spacings in the fixtures is what makes a swap detectable.
    """
    anchor = members[0]
    i_step = scaled(anchor.column_spacing, anchor.row)
    j_step = scaled(anchor.row_spacing, anchor.column)
    k_step = difference(members[1].position, members[0].position)
    origin = members[0].position

    return [
        i_step[0], j_step[0], k_step[0], origin[0],
        i_step[1], j_step[1], k_step[1], origin[1],
        i_step[2], j_step[2], k_step[2], origin[2],
        0.0, 0.0, 0.0, 1.0,
    ]


def determinant(m: list[float]) -> float:
    """The upper-left three-by-three determinant, in AffineGridGeometry's own
    frozen expression order, because that is the value its admission test
    applies."""
    return (
        m[0] * (m[5] * m[10] - m[6] * m[9])
        - m[1] * (m[4] * m[10] - m[6] * m[8])
        + m[2] * (m[4] * m[9] - m[5] * m[8])
    )


def fidelity_residual(members: list[Member], m: list[float]) -> float:
    """The largest absolute difference between the position the affine computes
    for a slice index and the position the source actually stated.

    This is the construction's honesty check: a uniform affine cannot reproduce
    a non-uniform series, and even a uniform one accumulates rounding, so the
    residual is reported rather than assumed to be zero.
    """
    origin = (m[3], m[7], m[11])
    k_step = (m[2], m[6], m[10])
    worst = 0.0
    for k, member in enumerate(members):
        for axis in range(3):
            computed = origin[axis] + (float(k) * k_step[axis])
            worst = max(worst, abs(computed - member.position[axis]))
    return worst


def construct(members: list[Member]) -> dict:
    if len(members) < 2:
        return {"outcome": "sliceStepUndefined"}
    m = index_to_world(members)
    det = determinant(m)
    if abs(det) < LEAST_NORMAL:
        return {"outcome": "singularTransform", "determinant": det, "matrix": m}
    return {
        "outcome": "constructed",
        "matrix": m,
        "determinant": det,
        "fidelityResidual": fidelity_residual(members, m),
    }


# --------------------------------------------------------------------------
# Fixtures.
# --------------------------------------------------------------------------

AXIAL_ROW = (1.0, 0.0, 0.0)
AXIAL_COLUMN = (0.0, 1.0, 0.0)


def member(
    ident: str,
    position: tuple[float, float, float],
    row=AXIAL_ROW,
    column=AXIAL_COLUMN,
    row_spacing: float = 0.7,
    column_spacing: float = 0.8,
) -> Member:
    return Member(ident, row, column, row_spacing, column_spacing, position)


FIXTURES: list[tuple[str, list[Member]]] = [
    (
        "D1 regular axial, distinct in-plane spacings so a swap is detectable",
        [
            member("d1", (-175.5, -175.5, 0.0)),
            member("d2", (-175.5, -175.5, 2.5)),
            member("d3", (-175.5, -175.5, 5.0)),
        ],
    ),
    (
        "D2 oblique orientation",
        [
            member(
                "d1",
                (1.0, 2.0, 3.0),
                row=(0.0, 1.0, 0.0),
                column=(0.0, 0.0, 1.0),
            ),
            member(
                "d2",
                (4.0, 2.0, 3.0),
                row=(0.0, 1.0, 0.0),
                column=(0.0, 0.0, 1.0),
            ),
        ],
    ),
    (
        "D3 tiny in-plane spacings underflow the determinant to subnormal",
        [
            member("d1", (0.0, 0.0, 0.0), row_spacing=1e-160, column_spacing=1e-160),
            member("d2", (0.0, 0.0, 1.0), row_spacing=1e-160, column_spacing=1e-160),
        ],
    ),
    (
        "D4 a single member leaves the slice step undefined",
        [member("d1", (0.0, 0.0, 0.0))],
    ),
    (
        "D5 an EXACTLY regular series still drifts: nonzero fidelity residual",
        # Every consecutive gap is bit-identical, so the exact tolerance admits
        # this series -- and the uniform affine still fails to reproduce the
        # stated positions. Found by search over plausible scanner geometry, not
        # constructed by hand, because the point is that it occurs naturally.
        [
            member("d1", (0.0, 0.0, -21.779939649890252)),
            member("d2", (0.0, 0.0, -15.460854058197997)),
            member("d3", (0.0, 0.0, -9.141768466505741)),
            member("d4", (0.0, 0.0, -2.822682874813486)),
        ],
    ),
    (
        "D6 a dyadic spacing reproduces every position exactly",
        [
            member("d1", (0.0, 0.0, 0.0)),
            member("d2", (0.0, 0.0, 2.5)),
            member("d3", (0.0, 0.0, 5.0)),
            member("d4", (0.0, 0.0, 7.5)),
        ],
    ),
]


def show(value: float) -> str:
    return f"{value!r} ({value.hex()})"


def main() -> None:
    print("VOXELIA-ALG-0049 oracle - CT affine volume construction")
    print("=" * 78)
    for title, members in FIXTURES:
        result = construct(members)
        print()
        print(title)
        print(f"  outcome: {result['outcome']}")
        if "matrix" in result:
            m = result["matrix"]
            for row in range(4):
                cells = ", ".join(show(m[row * 4 + column]) for column in range(4))
                print(f"    row {row}: {cells}")
        if "determinant" in result:
            print(f"  determinant: {show(result['determinant'])}")
        if "fidelityResidual" in result:
            print(f"  fidelityResidual: {show(result['fidelityResidual'])}")
        # Report the consecutive differences so a fixture's regularity under the
        # exact tolerance is visible rather than assumed.
        if len(members) >= 2:
            gaps = [
                members[i + 1].position[2] - members[i].position[2]
                for i in range(len(members) - 1)
            ]
            spread = max(gaps) - min(gaps)
            print(f"  z-gap spread: {show(spread)}")


if __name__ == "__main__":
    main()
