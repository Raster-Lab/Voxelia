#!/usr/bin/env python3
# SPDX-License-Identifier: MIT

"""Independent exact fixtures for ADR-0192 / VOXELIA-ALG-0029.

The oracle intentionally models categorical membership directly. It never
converts a label to floating point and never invokes the scalar-surface
interpolation oracle.
"""

from collections import Counter
from fractions import Fraction
import hashlib
import itertools
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

# Consecutive triples wind from selected membership toward unselected
# membership in image-axis coordinates.
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


def matrix_determinant(matrix):
    return (
        matrix[0] * (matrix[4] * matrix[8] - matrix[5] * matrix[7])
        - matrix[1] * (matrix[3] * matrix[8] - matrix[5] * matrix[6])
        + matrix[2] * (matrix[3] * matrix[7] - matrix[4] * matrix[6])
    )


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


def canonical_bytes(value):
    return json.dumps(value, separators=(",", ":"), sort_keys=True).encode()


def digest(value):
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def extract(extents, labels, selected, reverse_winding=False, x_offset=0):
    selected_values = frozenset(selected)
    vertices = []
    triangles = []
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
                        if labels[cell_ordinals[corner]] in selected_values:
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

                            assert (
                                labels[ordinal_a] in selected_values
                            ) != (labels[ordinal_b] in selected_values)
                            key = (ordinal_a, ordinal_b)
                            position = tuple(
                                (
                                    Fraction(coordinate_a[axis])
                                    + Fraction(coordinate_b[axis])
                                )
                                / 2
                                for axis in range(3)
                            )
                            position = (
                                position[0] + x_offset,
                                position[1],
                                position[2],
                            )
                            triangle_keys.append(key)
                            triangle_positions.append(position)

                        assert len(set(triangle_keys)) == 3
                        indices = []
                        for key, position in zip(triangle_keys, triangle_positions):
                            if key not in vertex_indices:
                                vertex_indices[key] = len(vertices)
                                vertices.append(position)
                            indices.append(vertex_indices[key])
                        if reverse_winding:
                            indices[1], indices[2] = indices[2], indices[1]
                        triangles.append(tuple(indices))

    return vertices, triangles


def rational_record(vertices, triangles, **fields):
    return {
        **fields,
        "triangles": triangles,
        "vertices": [
            [fraction_text(component) for component in vertex]
            for vertex in vertices
        ],
    }


def binary64_record(vertices, triangles, **fields):
    return {
        **fields,
        "triangles": triangles,
        "vertexBits": [
            [binary64_text(component) for component in vertex]
            for vertex in vertices
        ],
    }


def validate_table():
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
        selected = [points[index] for index in range(4) if case & (1 << index)]
        unselected = [points[index] for index in range(4) if not case & (1 << index)]
        outward = subtract(average(unselected), average(selected))
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


def validate_single_corner():
    labels = [7] + [-4] * 7
    vertices, triangles = extract((2, 2, 2), labels, (7,))
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

    reflected_image_vertices, reflected_triangles = extract(
        (2, 2, 2), labels, (7,), reverse_winding=True
    )
    assert reflected_image_vertices == vertices
    reflection = (-1, 0, 0, 0, 1, 0, 0, 0, 1)
    assert matrix_determinant(reflection) == -1
    reflected_world_vertices = [
        (-vertex[0], vertex[1], vertex[2]) for vertex in reflected_image_vertices
    ]
    assert reflected_world_vertices == [
        (-vertex[0], vertex[1], vertex[2]) for vertex in expected_vertices
    ]
    assert reflected_triangles == [
        (triangle[0], triangle[2], triangle[1]) for triangle in triangles
    ]
    return vertices, triangles


def exhaustive_cube_records():
    rational = []
    binary64 = []
    maximum_vertices = 0
    maximum_triangles = 0
    for mask in range(256):
        labels = [11 if mask & (1 << corner) else 23 for corner in range(8)]
        vertices, triangles = extract((2, 2, 2), labels, (11,))
        maximum_vertices = max(maximum_vertices, len(vertices))
        maximum_triangles = max(maximum_triangles, len(triangles))
        rational.append(rational_record(vertices, triangles, mask=mask))
        binary64.append(binary64_record(vertices, triangles, mask=mask))
    return rational, binary64, maximum_vertices, maximum_triangles


def exhaustive_ternary_digest():
    raw_values = (-9, 4, 71)
    selections = tuple(
        subset
        for count in range(1, len(raw_values) + 1)
        for subset in itertools.combinations(raw_values, count)
    )
    hasher = hashlib.sha256()
    case_count = 0
    for labels in itertools.product(raw_values, repeat=8):
        for selected in selections:
            vertices, triangles = extract((2, 2, 2), labels, selected)
            record = rational_record(
                vertices,
                triangles,
                labels=labels,
                selected=selected,
            )
            hasher.update(canonical_bytes(record))
            hasher.update(b"\n")
            case_count += 1
    assert case_count == 45_927
    return hasher.hexdigest(), case_count


def seam_segments(vertices, triangles, plane_x):
    segments = Counter()
    for triangle in triangles:
        points = [vertices[index] for index in triangle]
        for first, second in ((0, 1), (1, 2), (2, 0)):
            if points[first][0] == plane_x and points[second][0] == plane_x:
                edge = tuple(sorted((points[first], points[second])))
                segments[edge] += 1
    return segments


def validate_shared_face():
    digest_records = []
    for mask in range(1 << 12):
        labels = [1 if mask & (1 << index) else 0 for index in range(12)]
        left = [
            labels[ordinal((x, y, z), (3, 2, 2))]
            for z in range(2)
            for y in range(2)
            for x in range(2)
        ]
        right = [
            labels[ordinal((x, y, z), (3, 2, 2))]
            for z in range(2)
            for y in range(2)
            for x in range(1, 3)
        ]
        left_vertices, left_triangles = extract((2, 2, 2), left, (1,))
        right_vertices, right_triangles = extract(
            (2, 2, 2), right, (1,), x_offset=1
        )
        left_segments = seam_segments(left_vertices, left_triangles, Fraction(1))
        right_segments = seam_segments(right_vertices, right_triangles, Fraction(1))
        assert left_segments == right_segments
        digest_records.append(
            {
                "mask": mask,
                "segments": [
                    [
                        [fraction_text(value) for value in endpoint]
                        for endpoint in edge
                    ]
                    for edge in sorted(left_segments.elements())
                ],
            }
        )
    return digest(digest_records)


def validate_union_boundary():
    # x=0 has selected label 1, x=1 selected label 2 and x=2 unselected
    # label 0. The selected-selected x=0.5 interface must disappear; the only
    # surface is the selected-unselected plane at x=1.5.
    labels = []
    for z in range(2):
        for y in range(2):
            labels.extend((1, 2, 0))
    vertices, triangles = extract((3, 2, 2), labels, (1, 2))
    assert vertices
    assert triangles
    assert all(vertex[0] == Fraction(3, 2) for vertex in vertices)
    all_selected_vertices, all_selected_triangles = extract(
        (3, 2, 2), labels, (0, 1, 2)
    )
    assert all_selected_vertices == []
    assert all_selected_triangles == []
    none_selected_vertices, none_selected_triangles = extract(
        (3, 2, 2), labels, (99,)
    )
    assert none_selected_vertices == []
    assert none_selected_triangles == []
    return vertices, triangles


def validate_integer_containers():
    formats = (
        (1, True, -(1 << 7), (1 << 7) - 1),
        (1, False, 0, (1 << 8) - 1),
        (2, True, -(1 << 15), (1 << 15) - 1),
        (2, False, 0, (1 << 16) - 1),
        (4, True, -(1 << 31), (1 << 31) - 1),
        (4, False, 0, (1 << 32) - 1),
        (8, True, -(1 << 63), (1 << 63) - 1),
        (8, False, 0, (1 << 64) - 1),
    )
    records = []
    for byte_count, signed, minimum, maximum in formats:
        for byte_order in ("little", "big"):
            for value in (minimum, 0, maximum):
                encoded = value.to_bytes(byte_count, byte_order, signed=signed)
                decoded = int.from_bytes(encoded, byte_order, signed=signed)
                assert decoded == value
                records.append(
                    {
                        "bits": byte_count * 8,
                        "bytes": encoded.hex(),
                        "domain": "signed" if signed else "unsigned",
                        "order": byte_order,
                        "value": str(value),
                    }
                )
    assert len(records) == 48
    return digest(records)


def main():
    validate_table()
    single_vertices, single_triangles = validate_single_corner()
    cube_rational, cube_binary64, maximum_vertices, maximum_triangles = (
        exhaustive_cube_records()
    )
    ternary_digest, ternary_cases = exhaustive_ternary_digest()
    seam_digest = validate_shared_face()
    union_vertices, union_triangles = validate_union_boundary()
    container_digest = validate_integer_containers()

    print(
        " ".join(
            (
                f"cubeMembershipSHA256={digest(cube_rational)}",
                f"cubeBinary64SHA256={digest(cube_binary64)}",
                f"ternaryUnionSHA256={ternary_digest}",
                f"sharedFaceSHA256={seam_digest}",
                f"integerContainerSHA256={container_digest}",
                f"ternaryCases={ternary_cases}",
                f"maximumVertices={maximum_vertices}",
                f"maximumTriangles={maximum_triangles}",
                f"singleCorner={len(single_vertices)}v/{len(single_triangles)}t",
                f"unionBoundary={len(union_vertices)}v/{len(union_triangles)}t",
                "selectedInterface=suppressed",
                "sharedFace=conforming",
                "winding=selected-to-unselected",
            )
        )
    )


if __name__ == "__main__":
    main()
