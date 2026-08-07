---
document_id: "VOXELIA-ALG-0028"
title: "Freudenthal scalar-surface extraction binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Freudenthal scalar-surface extraction binary64-v1

## Purpose

This specification defines the versioned marching-cubes-class reference
`freudenthal-surface-extraction/binary64-v1` selected by accepted
[`ADR-0190`](../architecture/decisions/ADR-0190-scalar-surface-extraction-design.md).
It extracts one isosurface from a complete finite authoritative scalar lattice
into the accepted coordinate-bearing `TriangleMesh` payload. It is a
correctness reference, not an acceleration or presentation model.

## Input domain and admission

The numerical model consumes:

- exactly three positive image extents and exactly one scalar component;
- one finite authoritative binary64 sample at every logical image index in
  axis-zero-fastest order;
- one finite binary64 isovalue interpreted in the source descriptor's
  authoritative sample unit;
- one affine spatial geometry whose mapping is a permutation of image axes
  `0`, `1`, and `2`; and
- host-supplied maximum output vertex and triangle counts, each at least one.

Storage decoding and the accepted `VOXELIA-ALG-0003` through `0005` value-
transform chain occur before this model. Stored padding, missing samples and a
transform failure do not become scalar values: version one rejects such input
unless an upstream operation has produced a complete finite authoritative
lattice. Label membership is not interpolation and remains a separate
algorithm. An extent smaller than two on any axis contains no complete cell and
returns the valid empty mesh after admission.

Every maximum image index must be exactly representable as binary64, so each
`extent - 1` is at most `2^53`. The affine three-by-three determinant evaluated
in the order below must be finite and non-zero in addition to the source
geometry's own admission. No coordinate, sample, identifier or limit is placed
in a diagnostic payload.

## Cell and corner model

Cells are the closed intervals between adjacent sample centres. Only cells
whose lower corner is in
`0..<(extent[axis] - 1)` on every axis are visited. There is no ghost layer,
implicit exterior value, padding extrapolation or boundary cap; a surface that
reaches the source boundary is open there.

Within a cell with lower index `(x, y, z)`, the corner numbers and offsets are:

| Corner | Offset |
|---:|---|
| 0 | `(0, 0, 0)` |
| 1 | `(1, 0, 0)` |
| 2 | `(0, 1, 0)` |
| 3 | `(1, 1, 0)` |
| 4 | `(0, 0, 1)` |
| 5 | `(1, 0, 1)` |
| 6 | `(0, 1, 1)` |
| 7 | `(1, 1, 1)` |

The cell is decomposed into these six ordered tetrahedra:

```text
(0, 1, 3, 7)
(0, 5, 1, 7)
(0, 3, 2, 7)
(0, 2, 6, 7)
(0, 4, 5, 7)
(0, 6, 4, 7)
```

Every tuple has positive unit determinant in image-axis coordinates. This is
the global Freudenthal (Kuhn) triangulation: adjacent cells induce the same
diagonal on their shared face, so the method contains no data-dependent face or
interior ambiguity. The fixed body/face diagonals introduce a documented
directional bias; alternating diagonals or an asymptotic decider would be a
different algorithm version.

## Tetrahedron table

Local tetrahedron edges are:

```text
0 = (v0, v1)
1 = (v1, v2)
2 = (v2, v0)
3 = (v0, v3)
4 = (v1, v3)
5 = (v2, v3)
```

A local vertex is inside exactly when `sample >= isovalue`. Bit `i` of the
case number is one when `vi` is inside. Equality is exact binary64 comparison;
there is no epsilon or symbolic perturbation. Each consecutive edge triple in
the following table is one triangle. The right-hand-rule normal points from
inside toward outside in image-axis coordinates.

| Case | Triangle edge triples |
|---:|---|
| 0 | — |
| 1 | `(0, 2, 3)` |
| 2 | `(0, 4, 1)` |
| 3 | `(1, 2, 4)`, `(2, 3, 4)` |
| 4 | `(1, 5, 2)` |
| 5 | `(0, 5, 3)`, `(0, 1, 5)` |
| 6 | `(0, 5, 2)`, `(0, 4, 5)` |
| 7 | `(5, 3, 4)` |
| 8 | `(3, 5, 4)` |
| 9 | `(4, 0, 5)`, `(5, 0, 2)` |
| 10 | `(1, 0, 5)`, `(5, 0, 3)` |
| 11 | `(5, 1, 2)` |
| 12 | `(3, 2, 4)`, `(2, 1, 4)` |
| 13 | `(4, 0, 1)` |
| 14 | `(2, 0, 3)` |
| 15 | — |

The complement cases have opposite winding. No table entry may be reordered,
merged or replaced by a geometrically similar triangulation.

## Interpolation and vertex keys

For each table edge, its two global sample ordinals are sorted ascending before
arithmetic. Let their samples and image indices be `(s0, p0)` and `(s1, p1)`.
The classification differs by construction.

1. If `s0 == isovalue`, the position is exactly `p0` and its vertex key is the
   sample ordinal `s0Ordinal`.
2. Otherwise, if `s1 == isovalue`, the position is exactly `p1` and its key is
   `s1Ordinal`.
3. Otherwise evaluate, in this exact order:

   ```text
   numerator   = isovalue - s0
   denominator = s1 - s0
   t           = numerator / denominator
   p[axis]     = Double(p0[axis])
                 + t * Double(p1[axis] - p0[axis])
   ```

   The key is the ordered pair of global sample ordinals.

The numerator, denominator, `t`, and every image-coordinate result must be
finite; `t` must be strictly between zero and one in branch 3. Overflow,
underflow to an endpoint, NaN, infinity or an out-of-range result rejects as an
unrepresentable interpolation. The implementation does not clamp, rescale,
choose an algebraically equivalent formula or silently snap a failed result.

All exact-isovalue intersections at one sample therefore share the sample key,
even when reached through different edges. After resolving one table triangle,
the triangle is omitted when any two of its three keys are identical. Keys and
positions for an omitted triangle are not published. Other geometric
degeneracy is preserved for the later normal/measurement contract; no area
tolerance is applied.

## Deterministic ownership and output order

Cells are traversed with axis two outermost, axis one next and axis zero
innermost. Within a cell, tetrahedra use the six-row order above; within a
tetrahedron, table triangles and their three edges use table order. A vertex is
appended on its first reference by a non-omitted triangle and thereafter reused
by its exact key. A triangle is appended immediately after resolving its three
indices. This fixes vertex order, triangle order, diagonal selection,
multiplicity and the complete `UInt64` topology sequence.

The resulting topology declares exactly the appended position count. No unused
position is published, and no vertex welding by coordinates or tolerance is
permitted.

## Coordinate mapping and physical winding

The image-coordinate position is converted to spatial slots by the source
`SpatialAxisMapping`: slot `i` receives the coordinate of
`spatialAxes.imageAxes[i]`. Each world component is then evaluated from the
row-major affine matrix, without fused operations or reassociation:

```text
q0 = m[4*r + 0] * spatial[0]
q1 = m[4*r + 1] * spatial[1]
q2 = m[4*r + 2] * spatial[2]
world[r] = ((q0 + q1) + q2) + m[4*r + 3]
```

Every intermediate and final world component must be finite. The mesh binds
the source geometry's exact `CoordinateSpaceDescriptor`; identifier equality
does not substitute for that descriptor.

The affine determinant is evaluated exactly as:

```text
det = m[0] * (m[5] * m[10] - m[6] * m[9])
      - m[1] * (m[4] * m[10] - m[6] * m[8])
      + m[2] * (m[4] * m[9] - m[5] * m[8])
```

The effective image-to-world orientation is the determinant sign multiplied by
the exact parity of the image-axis permutation. When it is negative, swap the
second and third index of every triangle. This preserves the table's
inside-to-outside physical winding through reflected or permuted geometry.

## Precision, failures and cancellation

`binary64-v1` requires IEEE-754 binary64, round-to-nearest-ties-to-even,
gradual subnormal handling, no flush-to-zero, no fast math, no fused multiply-
add substitution and no reassociation. The public failure family implemented
with the CPU reference must be typed, `Sendable`, `Equatable` and payload-free,
with these semantic categories:

```text
invalidLimits
unsupportedSource
nonFiniteIsovalue
nonFiniteSample
resourceLimitExceeded
interpolationNotRepresentable
positionNotRepresentable
sourceReadFailed
cancelled
publicationFailed
```

Admission precedence is cancellation, limits, source/geometry, isovalue,
source read/transform, then the first non-finite sample in axis-zero-fastest
order. Traversal failures then follow cell order: cancellation, interpolation,
position mapping and resource limits. A final cancellation check occurs before
the one atomic mesh/identity/provenance publication. The source adapter
correction frozen by `ADR-0191` polls cancellation before sample zero and every
4,096 axis-zero-fastest samples during its finite-value validation pass;
cancellation at a boundary precedes decoding that sample.

Cell count and every output count/addition/product are checked before reserve or
append. Host-supplied positive vertex and triangle limits have no implicit default and
are checked before admitting the next non-omitted triangle. The edge/sample-key
map contains at most one entry per published vertex, so retained intermediate
state is bounded by the vertex limit. Cancellation is checked before cell zero,
before every cell whose canonical ordinal is a multiple of 64, and immediately
before publication. Cancellation or any failure publishes no partial mesh,
identity or provenance.

## Conformance fixtures

The independent exact-rational oracle is
[`ADR-0190-scalar-surface-extraction-oracle.py`](../progress/evidence/ADR-0190-scalar-surface-extraction-oracle.py).
It proves all six tetrahedra have positive unit determinant, all fourteen
nonempty tetrahedron cases have outward winding, all 256 binary cube masks are
complete and in bounds, shared-face triangulation conforms, reflected winding
reverses, and exact-isovalue key collapse omits repeated-index triangles. It
also serializes the independently derived dyadic positions as fixed-width
binary64 bit patterns for the complete mask corpus and the two-cell shared-seam
fixture, so the Swift differential cannot normalise signed zero or omit either
cell unnoticed.

Its registered output is:

```text
cubeMaskSHA256=4bed958ac7d25a4539de8a0cea28524271a89303c3e9e3fb0de0d311e5c6931d cubeMaskBinary64SHA256=154f1d57f1fe6491f9fe6267109fa46074ffba860d16f7284736388a434536aa sharedSeamBinary64SHA256=348948097129d59454615bae09372c8ff16b5564ac0db7f95433b168cb05f86e maximumVertices=13 maximumTriangles=12 singleCorner=7v/6t equality=0v/0t sharedFace=conforming winding=outward
```

For the `2 × 2 × 2` identity-geometry fixture with corner zero equal to `1`,
all other corners `0`, and isovalue `0.5`, exact position order is:

```text
(0.5, 0.0, 0.0)
(0.5, 0.5, 0.0)
(0.5, 0.5, 0.5)
(0.5, 0.0, 0.5)
(0.0, 0.5, 0.0)
(0.0, 0.5, 0.5)
(0.0, 0.0, 0.5)
```

and exact triangles are:

```text
(0, 1, 2)
(3, 0, 2)
(1, 4, 2)
(4, 5, 2)
(6, 3, 2)
(5, 6, 2)
```

Replacing corner zero with exact `0.5` and leaving all others zero produces the
empty mesh after sample-key collapse. A reflected X affine preserves the seven
world positions under reflection and reverses every triangle's second and third
index. Finite endpoints `-Double.greatestFiniteMagnitude` and
`Double.greatestFiniteMagnitude` at isovalue zero produce an infinite direct
denominator and must fail `interpolationNotRepresentable`, never emit `t = 0.5`
through an unversioned alternate formula.

Conformance is bit-exact for binary64 positions and exact for topology and
failure classification; no tolerance applies. Accelerated or alternate CPU
implementations must compare every output position bit pattern and the complete
index sequence to the reference, plus match cancellation/no-publication and
resource-limit behaviour.

## Provenance fields

A successful operation records:

- Core operation token `org.voxelia.op.scalar-surface-extraction`;
- algorithm identifier `freudenthal-surface-extraction/binary64-v1`;
- the finite isovalue through the accepted metadata floating-point value;
- inside rule `sample-greater-than-or-equal`;
- boundary rule `interior-cells-only`;
- one ordered input with role `source-volume`, occurrence one and the exact
  source identity reference, using the Core-compatible correction frozen by
  `ADR-0191`; and
- the implementation/software/execution claims required by the accepted Core
  provenance model.

Limits and cancellation cadence are execution policy, not successful-result
identity: changing them cannot change a successful mesh. The parameter digest
must nevertheless bind every caller-visible numerical parameter; a later
algorithm change requires a new identifier/version rather than a provenance
warning or silent substitution. Logs and typed errors contain none of the
source identity, isovalue, coordinates or patient-derived metadata.

## Benchmarks and limitations

The reference is `O(cellCount + emittedTriangles)` with a key map bounded by
the emitted vertex limit. It is not claimed to minimise triangle count: the
fixed simplicial subdivision may emit up to twelve triangles and thirteen
vertices for one binary cube mask, as the exhaustive oracle proves. Classic
256-case marching cubes, MC33/asymptotic-decider topology, flying edges,
streaming brick seams, labelled extraction, normals and acceleration remain
separate implementations/contracts and may not substitute for this reference
without explicit identity and differential evidence.

## References

- [ADR-0183 - Geometry extraction arc](../architecture/decisions/ADR-0183-geometry-arc.md)
- [ADR-0190 - Scalar surface extraction design](../architecture/decisions/ADR-0190-scalar-surface-extraction-design.md)
- [VOXELIA-ALG-0003 - Linear value transform](VOXELIA-ALG-0003-linear-value-transform.md)
- [VOXELIA-ALG-0004 - Lookup-table value transform](VOXELIA-ALG-0004-lookup-table-value-transform.md)
- [VOXELIA-ALG-0005 - Composed value transform](VOXELIA-ALG-0005-composed-value-transform-chain.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
