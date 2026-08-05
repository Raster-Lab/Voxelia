#!/usr/bin/env python3
# SPDX-License-Identifier: MIT

"""Independent exact-rational fixtures for ADR-0190 / ALG-0028."""

from fractions import Fraction
import hashlib
import json
import struct


CORNERS = (
    (0, 0, 0),
    (1, 0, 0),
    (0, 1, 0),
    (1, 1, 0),
    (0, 0, 1),
    (1, 0, 1),
    (0, 1, 1),
    (1, 1, 1),
)

# Every local tetrahedron has positive determinant in image-axis coordinates.
TETRAHEDRA = (
    (0, 1, 3, 7),
    (0, 5, 1, 7),
    (0, 3, 2, 7),
    (0, 2, 6, 7),
    (0, 4, 5, 7),
    (0, 6, 4, 7),
)

TETRAHEDRON_EDGES = (
    (0, 1),
    (1, 2),
    (2, 0),
    (0, 3),
    (1, 3),
    (2, 3),
)

# Edge triples use right-hand-rule winding from inside (sample >= isovalue)
# toward outside. Each consecutive triple is one triangle.
TRIANGLE_TABLE = (
    (),
    (0, 2, 3),
    (0, 4, 1),
    (1, 2, 4, 2, 3, 4),
    (1, 5, 2),
    (0, 5, 3, 0, 1, 5),
    (0, 5, 2, 0, 4, 5),
    (5, 3, 4),
    (3, 5, 4),
    (4, 0, 5, 5, 0, 2),
    (1, 0, 5, 5, 0, 3),
    (5, 1, 2),
    (3, 2, 4, 2, 1, 4),
    (4, 0, 1),
    (2, 0, 3),
    (),
)


def subtract(lhs, rhs):
    return tuple(lhs[axis] - rhs[axis] for axis in range(3))


def cross(lhs, rhs):
    return (
        lhs[1] * rhs[2] - lhs[2] * rhs[1],
        lhs[2] * rhs[0] - lhs[0] * rhs[2],
        lhs[0] * rhs[1] - lhs[1] * rhs[0],
    )


def dot(lhs, rhs):
    return sum(lhs[axis] * rhs[axis] for axis in range(3))


def determinant(tetrahedron):
    origin, b, c, d = (CORNERS[index] for index in tetrahedron)
    return dot(subtract(b, origin), cross(subtract(c, origin), subtract(d, origin)))


def average(points):
    count = Fraction(len(points))
    return tuple(sum(point[axis] for point in points) / count for axis in range(3))


def ordinal(coordinate, extents):
    x, y, z = coordinate
    return x + extents[0] * (y + extents[1] * z)


def fraction_text(value):
    return f"{value.numerator}/{value.denominator}"


def binary64_text(value):
    return struct.pack(">d", float(value)).hex()


def binary64_record(vertices, triangles, mask=None):
    record = {
        "triangles": triangles,
        "vertexBits": [
            [binary64_text(component) for component in vertex]
            for vertex in vertices
        ],
    }
    if mask is not None:
        record["mask"] = mask
    return record


def record_digest(record):
    encoded = json.dumps(record, separators=(",", ":"), sort_keys=True).encode()
    return hashlib.sha256(encoded).hexdigest()


def extract(extents, samples, isovalue, reverse_winding=False):
    vertices = []
    triangles = []
    triangle_cells = []
    vertex_indices = {}

    for z in range(extents[2] - 1):
        for y in range(extents[1] - 1):
            for x in range(extents[0] - 1):
                cell_corners = tuple(
                    (x + corner[0], y + corner[1], z + corner[2])
                    for corner in CORNERS
                )
                cell_ordinals = tuple(
                    ordinal(coordinate, extents) for coordinate in cell_corners
                )

                for tetrahedron in TETRAHEDRA:
                    case = 0
                    for local_vertex, corner in enumerate(tetrahedron):
                        if samples[cell_ordinals[corner]] >= isovalue:
                            case |= 1 << local_vertex

                    edges = TRIANGLE_TABLE[case]
                    for offset in range(0, len(edges), 3):
                        triangle_keys = []
                        triangle_positions = []
                        for edge_id in edges[offset : offset + 3]:
                            local_a, local_b = TETRAHEDRON_EDGES[edge_id]
                            corner_a = tetrahedron[local_a]
                            corner_b = tetrahedron[local_b]
                            ordinal_a = cell_ordinals[corner_a]
                            ordinal_b = cell_ordinals[corner_b]
                            coordinate_a = cell_corners[corner_a]
                            coordinate_b = cell_corners[corner_b]
                            if ordinal_b < ordinal_a:
                                ordinal_a, ordinal_b = ordinal_b, ordinal_a
                                coordinate_a, coordinate_b = coordinate_b, coordinate_a
                            sample_a = samples[ordinal_a]
                            sample_b = samples[ordinal_b]

                            if sample_a == isovalue:
                                key = ("sample", ordinal_a)
                                position = tuple(Fraction(value) for value in coordinate_a)
                            elif sample_b == isovalue:
                                key = ("sample", ordinal_b)
                                position = tuple(Fraction(value) for value in coordinate_b)
                            else:
                                key = ("edge", ordinal_a, ordinal_b)
                                t = (isovalue - sample_a) / (sample_b - sample_a)
                                position = tuple(
                                    Fraction(coordinate_a[axis])
                                    + t
                                    * Fraction(coordinate_b[axis] - coordinate_a[axis])
                                    for axis in range(3)
                                )
                            triangle_keys.append(key)
                            triangle_positions.append(position)

                        if len(set(triangle_keys)) != 3:
                            continue

                        indices = []
                        for key, position in zip(triangle_keys, triangle_positions):
                            if key not in vertex_indices:
                                vertex_indices[key] = len(vertices)
                                vertices.append(position)
                            indices.append(vertex_indices[key])
                        if reverse_winding:
                            indices[1], indices[2] = indices[2], indices[1]
                        triangles.append(tuple(indices))
                        triangle_cells.append((x, y, z))

    return vertices, triangles, triangle_cells


def validate_tetrahedron_table():
    assert all(determinant(tetrahedron) == 1 for tetrahedron in TETRAHEDRA)
    assert tuple(len(edges) // 3 for edges in TRIANGLE_TABLE) == (
        0,
        1,
        1,
        2,
        1,
        2,
        2,
        1,
        1,
        2,
        2,
        1,
        2,
        1,
        1,
        0,
    )

    tetrahedron = TETRAHEDRA[0]
    points = [tuple(Fraction(value) for value in CORNERS[index]) for index in tetrahedron]
    for case in range(1, 15):
        inside = [points[index] for index in range(4) if case & (1 << index)]
        outside = [points[index] for index in range(4) if not case & (1 << index)]
        outward = subtract(average(outside), average(inside))
        intersections = []
        for edge_id in TRIANGLE_TABLE[case]:
            a, b = TETRAHEDRON_EDGES[edge_id]
            intersections.append(
                tuple((points[a][axis] + points[b][axis]) / 2 for axis in range(3))
            )
        for offset in range(0, len(intersections), 3):
            a, b, c = intersections[offset : offset + 3]
            normal = cross(subtract(b, a), subtract(c, a))
            assert dot(normal, outward) > 0


def validate_single_corner_fixture():
    samples = [Fraction(1)] + [Fraction(0)] * 7
    vertices, triangles, _ = extract((2, 2, 2), samples, Fraction(1, 2))
    expected_vertices = [
        (Fraction(1, 2), Fraction(0), Fraction(0)),
        (Fraction(1, 2), Fraction(1, 2), Fraction(0)),
        (Fraction(1, 2), Fraction(1, 2), Fraction(1, 2)),
        (Fraction(1, 2), Fraction(0), Fraction(1, 2)),
        (Fraction(0), Fraction(1, 2), Fraction(0)),
        (Fraction(0), Fraction(1, 2), Fraction(1, 2)),
        (Fraction(0), Fraction(0), Fraction(1, 2)),
    ]
    expected_triangles = [
        (0, 1, 2),
        (3, 0, 2),
        (1, 4, 2),
        (4, 5, 2),
        (6, 3, 2),
        (5, 6, 2),
    ]
    assert vertices == expected_vertices
    assert triangles == expected_triangles

    reflected_vertices = [(-vertex[0], vertex[1], vertex[2]) for vertex in vertices]
    _, reflected_triangles, _ = extract(
        (2, 2, 2), samples, Fraction(1, 2), reverse_winding=True
    )
    assert reflected_vertices[0] == (Fraction(-1, 2), Fraction(0), Fraction(0))
    assert reflected_triangles == [
        (triangle[0], triangle[2], triangle[1]) for triangle in triangles
    ]


def validate_equality_and_seam_fixtures():
    equality_samples = [Fraction(1, 2)] + [Fraction(0)] * 7
    vertices, triangles, _ = extract(
        (2, 2, 2), equality_samples, Fraction(1, 2)
    )
    assert vertices == []
    assert triangles == []

    extents = (3, 2, 2)
    seam_samples = []
    for z in range(extents[2]):
        for y in range(extents[1]):
            for _x in range(extents[0]):
                seam_samples.append(Fraction(y + 2 * z))
    vertices, triangles, triangle_cells = extract(
        extents, seam_samples, Fraction(3, 4)
    )
    seam_indices = {
        index for index, vertex in enumerate(vertices) if vertex[0] == Fraction(1)
    }
    assert seam_indices
    for seam_index in seam_indices:
        using_cells = {
            triangle_cells[index][0]
            for index, triangle in enumerate(triangles)
            if seam_index in triangle
        }
        assert using_cells == {0, 1}
    return record_digest(binary64_record(vertices, triangles))


def cube_mask_digest():
    records = []
    binary64_records = []
    maximum_vertices = 0
    maximum_triangles = 0
    for mask in range(256):
        samples = [
            Fraction(1) if mask & (1 << corner) else Fraction(0)
            for corner in range(8)
        ]
        vertices, triangles, _ = extract((2, 2, 2), samples, Fraction(1, 2))
        maximum_vertices = max(maximum_vertices, len(vertices))
        maximum_triangles = max(maximum_triangles, len(triangles))
        assert all(len(set(triangle)) == 3 for triangle in triangles)
        assert all(index < len(vertices) for triangle in triangles for index in triangle)
        records.append(
            {
                "mask": mask,
                "vertices": [
                    [fraction_text(component) for component in vertex]
                    for vertex in vertices
                ],
                "triangles": triangles,
            }
        )
        binary64_records.append(binary64_record(vertices, triangles, mask))
    encoded = json.dumps(records, separators=(",", ":"), sort_keys=True).encode()
    binary64_encoded = json.dumps(
        binary64_records, separators=(",", ":"), sort_keys=True
    ).encode()
    return (
        hashlib.sha256(encoded).hexdigest(),
        hashlib.sha256(binary64_encoded).hexdigest(),
        maximum_vertices,
        maximum_triangles,
    )


def main():
    validate_tetrahedron_table()
    validate_single_corner_fixture()
    seam_digest = validate_equality_and_seam_fixtures()
    digest, binary64_digest, maximum_vertices, maximum_triangles = cube_mask_digest()
    print(
        " ".join(
            (
                f"cubeMaskSHA256={digest}",
                f"cubeMaskBinary64SHA256={binary64_digest}",
                f"sharedSeamBinary64SHA256={seam_digest}",
                f"maximumVertices={maximum_vertices}",
                f"maximumTriangles={maximum_triangles}",
                "singleCorner=7v/6t",
                "equality=0v/0t",
                "sharedFace=conforming",
                "winding=outward",
            )
        )
    )


if __name__ == "__main__":
    main()
