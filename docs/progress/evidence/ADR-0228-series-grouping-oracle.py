#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Independent oracle for VOXELIA-ALG-0047: CT series grouping and slice ordering.

Computed from the algorithm specification's prose alone, in IEEE-754 binary64,
with the frozen expression order and no fused multiply-add. Python's float is
binary64 and CPython emits no FMA for these expressions, so each printed value
is the bit-exact result Swift must reproduce.

This oracle deliberately reimplements the rules rather than importing anything
from the Swift sources: it is evidence only if it is independent.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field


# --------------------------------------------------------------------------
# Stage 1: the grouping key.
#
# The key is exactly (seriesIdentity, coordinateSpace, frameOfReference).
# Nothing scanner-supplied and approximate takes part: orientation, spacing,
# position, grid shape, scalar format and the presentation terms are all
# excluded so that a series which nearly agrees reaches the geometry validator
# as ONE group to be judged, rather than being silently split into several
# volumes.
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class SourceIdentity:
    namespace: str
    identifier: str
    version: str | None = None

    def sort_key(self) -> tuple:
        # Exact UTF-8 byte ordering, with an absent version ordered before
        # every present one, matching the accepted SourceIdentity semantics.
        return (
            self.namespace.encode("utf-8"),
            self.identifier.encode("utf-8"),
            (1, self.version.encode("utf-8")) if self.version is not None else (0, b""),
        )


@dataclass(frozen=True)
class FrameReference:
    namespace: str
    identifier: str

    def sort_key(self) -> tuple:
        return (self.namespace.encode("utf-8"), self.identifier.encode("utf-8"))


@dataclass(frozen=True)
class Frame:
    source: SourceIdentity
    series: SourceIdentity
    space: str
    reference: FrameReference | None
    row: tuple[float, float, float]
    column: tuple[float, float, float]
    position: tuple[float, float, float]


def grouping_key(frame: Frame) -> tuple:
    """The exact grouping key. Absent frame-of-reference is distinct from present."""
    return (
        frame.series.sort_key(),
        frame.space.encode("utf-8"),
        (1,) + frame.reference.sort_key() if frame.reference is not None else (0, b"", b""),
    )


# --------------------------------------------------------------------------
# Stage 3: the reference normal, in frozen expression order.
# --------------------------------------------------------------------------


def cross(r: tuple[float, float, float], c: tuple[float, float, float]):
    rx, ry, rz = r
    cx, cy, cz = c
    nx = (ry * cz) - (rz * cy)
    ny = (rz * cx) - (rx * cz)
    nz = (rx * cy) - (ry * cx)
    return (nx, ny, nz)


# --------------------------------------------------------------------------
# Stage 4: the projection, in frozen expression order.
# --------------------------------------------------------------------------


def project(p: tuple[float, float, float], n: tuple[float, float, float]) -> float:
    px, py, pz = p
    nx, ny, nz = n
    return ((px * nx) + (py * ny)) + (pz * nz)


# --------------------------------------------------------------------------
# Stages 2 and 5: deterministic ordering.
# --------------------------------------------------------------------------


@dataclass
class GroupResult:
    key: tuple
    normal: tuple[float, float, float]
    degenerate_normal: bool
    non_finite_normal: bool
    non_finite_projection: bool
    ordered: list[tuple[str, float]] = field(default_factory=list)


def assemble(frames: list[Frame]) -> list[GroupResult]:
    groups: dict[tuple, list[Frame]] = {}
    for frame in frames:
        groups.setdefault(grouping_key(frame), []).append(frame)

    results: list[GroupResult] = []
    for key in sorted(groups):
        members = groups[key]

        # The reference normal comes from the frame first in exact source
        # identity byte order, so the result is a pure function of the SET of
        # frames rather than of their arrival sequence.
        anchor = min(members, key=lambda f: f.source.sort_key())
        normal = cross(anchor.row, anchor.column)

        degenerate = normal[0] == 0.0 and normal[1] == 0.0 and normal[2] == 0.0
        non_finite_normal = not all(math.isfinite(component) for component in normal)

        projections = [project(frame.position, normal) for frame in members]
        non_finite_projection = not all(math.isfinite(t) for t in projections)

        if degenerate or non_finite_normal or non_finite_projection:
            # Ordering by projection has no defined meaning, so it falls back to
            # pure identity order and the group is flagged. Judging it is the
            # geometry validator's job, not this stage's.
            ordered_frames = sorted(members, key=lambda f: f.source.sort_key())
            ordered = [
                (f.source.identifier, project(f.position, normal)) for f in ordered_frames
            ]
        else:
            paired = list(zip(members, projections))
            # Ascending projection, ties broken by exact identity byte order.
            paired.sort(key=lambda pair: (pair[1], pair[0].source.sort_key()))
            ordered = [(frame.source.identifier, t) for frame, t in paired]

        results.append(
            GroupResult(
                key=key,
                normal=normal,
                degenerate_normal=degenerate,
                non_finite_normal=non_finite_normal,
                non_finite_projection=non_finite_projection,
                ordered=ordered,
            )
        )
    return results


# --------------------------------------------------------------------------
# Fixtures.
# --------------------------------------------------------------------------

SERIES_A = SourceIdentity("dicom", "1.2.840.series.A")
SERIES_B = SourceIdentity("dicom", "1.2.840.series.B")
REFERENCE = FrameReference("dicom", "1.2.840.frame.1")

PATIENT = "patient"

AXIAL_ROW = (1.0, 0.0, 0.0)
AXIAL_COLUMN = (0.0, 1.0, 0.0)


def frame(
    ident: str,
    series: SourceIdentity = SERIES_A,
    space: str = PATIENT,
    reference: FrameReference | None = REFERENCE,
    row=AXIAL_ROW,
    column=AXIAL_COLUMN,
    position=(0.0, 0.0, 0.0),
) -> Frame:
    return Frame(
        source=SourceIdentity("dicom", ident),
        series=series,
        space=space,
        reference=reference,
        row=row,
        column=column,
        position=position,
    )


FIXTURES: list[tuple[str, list[Frame]]] = [
    (
        "F1 axial series, arrival order already ascending",
        [
            frame("f1", position=(-175.5, -175.5, 0.0)),
            frame("f2", position=(-175.5, -175.5, 2.5)),
            frame("f3", position=(-175.5, -175.5, 5.0)),
        ],
    ),
    (
        "F2 same set, arrival order shuffled - must give the identical result",
        [
            frame("f3", position=(-175.5, -175.5, 5.0)),
            frame("f1", position=(-175.5, -175.5, 0.0)),
            frame("f2", position=(-175.5, -175.5, 2.5)),
        ],
    ),
    (
        "F3 flipped column direction reverses the ordering axis",
        [
            frame("f1", column=(0.0, -1.0, 0.0), position=(0.0, 0.0, 0.0)),
            frame("f2", column=(0.0, -1.0, 0.0), position=(0.0, 0.0, 2.5)),
            frame("f3", column=(0.0, -1.0, 0.0), position=(0.0, 0.0, 5.0)),
        ],
    ),
    (
        "F4 oblique orientation, unnormalised normal",
        [
            frame(
                "f1",
                row=(0.7071067811865476, 0.7071067811865475, 0.0),
                column=(0.0, 0.0, 1.0),
                position=(1.0, 2.0, 3.0),
            ),
            frame(
                "f2",
                row=(0.7071067811865476, 0.7071067811865475, 0.0),
                column=(0.0, 0.0, 1.0),
                position=(4.0, 5.0, 6.0),
            ),
        ],
    ),
    (
        "F5 non-orthogonal but non-degenerate directions are ordered, not judged",
        [
            frame("f1", column=(0.5, 0.5, 0.0), position=(0.0, 0.0, 4.0)),
            frame("f2", column=(0.5, 0.5, 0.0), position=(0.0, 0.0, 1.0)),
        ],
    ),
    (
        "F6 parallel directions give an exactly zero normal",
        [
            frame("f1", column=(2.0, 0.0, 0.0), position=(0.0, 0.0, 1.0)),
            frame("f2", column=(2.0, 0.0, 0.0), position=(0.0, 0.0, 9.0)),
        ],
    ),
    (
        "F7 overflow in the cross product yields a non-finite normal",
        [
            frame("f1", row=(1e200, 0.0, 0.0), column=(0.0, 1e200, 0.0), position=(0.0, 0.0, 1.0)),
            frame("f2", row=(1e200, 0.0, 0.0), column=(0.0, 1e200, 0.0), position=(0.0, 0.0, 2.0)),
        ],
    ),
    (
        "F8 a finite normal with an overflowing projection",
        [
            frame("f1", row=(1e100, 0.0, 0.0), column=(0.0, 1e100, 0.0), position=(0.0, 0.0, 1.0)),
            frame(
                "f2",
                row=(1e100, 0.0, 0.0),
                column=(0.0, 1e100, 0.0),
                position=(0.0, 0.0, 1e200),
            ),
        ],
    ),
    (
        "F9 co-located frames tie and break by identity",
        [
            frame("fb", position=(0.0, 0.0, 3.0)),
            frame("fa", position=(0.0, 0.0, 3.0)),
        ],
    ),
    (
        "F10 near-cancelling cross product keeps a tiny exact normal",
        [
            frame("f1", row=(1.0, 1e-16, 0.0), column=(1.0, 0.0, 0.0), position=(0.0, 0.0, 1.0)),
            frame("f2", row=(1.0, 1e-16, 0.0), column=(1.0, 0.0, 0.0), position=(0.0, 0.0, 2.0)),
        ],
    ),
    (
        "F11 two series in one frame of reference stay separate",
        [
            frame("f1", series=SERIES_A, position=(0.0, 0.0, 1.0)),
            frame("f2", series=SERIES_B, position=(0.0, 0.0, 2.0)),
        ],
    ),
    (
        "F12 absent frame of reference never joins a present one",
        [
            frame("f1", reference=None, position=(0.0, 0.0, 1.0)),
            frame("f2", reference=REFERENCE, position=(0.0, 0.0, 2.0)),
        ],
    ),
    (
        "F13 differing coordinate space separates a series",
        [
            frame("f1", space="patient", position=(0.0, 0.0, 1.0)),
            frame("f2", space="table", position=(0.0, 0.0, 2.0)),
        ],
    ),
    (
        "F14 disagreeing orientation stays in ONE group for the validator to reject",
        [
            frame("f1", row=AXIAL_ROW, column=AXIAL_COLUMN, position=(0.0, 0.0, 1.0)),
            frame("f2", row=AXIAL_COLUMN, column=AXIAL_ROW, position=(0.0, 0.0, 2.0)),
        ],
    ),
    (
        "F15 signed zero projections tie rather than order",
        [
            frame("fb", position=(0.0, 0.0, -0.0)),
            frame("fa", position=(0.0, 0.0, 0.0)),
        ],
    ),
]


def show(value: float) -> str:
    return f"{value!r} ({value.hex()})"


def main() -> None:
    print("VOXELIA-ALG-0047 oracle - CT series grouping and slice ordering")
    print("=" * 78)
    for title, frames in FIXTURES:
        print()
        print(title)
        results = assemble(frames)
        print(f"  groups: {len(results)}")
        for index, group in enumerate(results):
            flags = []
            if group.degenerate_normal:
                flags.append("degenerateNormal")
            if group.non_finite_normal:
                flags.append("nonFiniteNormal")
            if group.non_finite_projection:
                flags.append("nonFiniteProjection")
            print(f"  group {index}:")
            print(
                "    normal: "
                + ", ".join(show(component) for component in group.normal)
            )
            print(f"    observations: {flags if flags else 'none'}")
            for position, (ident, t) in enumerate(group.ordered):
                print(f"    [{position}] {ident} t = {show(t)}")


if __name__ == "__main__":
    main()
