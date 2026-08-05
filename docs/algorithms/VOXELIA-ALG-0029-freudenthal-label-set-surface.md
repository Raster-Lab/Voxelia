---
document_id: "VOXELIA-ALG-0029"
title: "Freudenthal label-set surface binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Freudenthal label-set surface binary64-v1

## Purpose

This specification defines
`freudenthal-label-set-surface/binary64-v1`, the categorical surface reference
selected by accepted [`ADR-0192`](../architecture/decisions/ADR-0192-labelled-surface-extraction-design.md).
It extracts the boundary of one exact requested label union from a mutually
exclusive integer label image into the accepted coordinate-bearing
`TriangleMesh`. It does not interpolate label magnitudes, identify segments,
close the source boundary or define presentation geometry.

## Input domain and admission

The numerical model consumes:

- exactly three positive image extents and one `.scalar` component;
- exactly one signed or unsigned integer label at every logical image index in
  axis-zero-fastest order;
- a nonempty, strictly increasing and unique requested set in the same signed
  or unsigned domain;
- one affine spatial geometry whose mapping is a permutation of image axes
  zero through two; and
- explicit positive maximum requested-label, vertex and triangle counts.

The v1 requested-set hard maximum is 65,536. Source formats are all eight
native integer containers from 8 through 64 bits in native, little-endian or
big-endian order. Float containers, narrower `validBitCount`, non-label
semantics, non-scalar components, sample units and transforms other than absent
or exact identity reject before this model. Integer decoding is exact; no
label is converted through binary64. An extent smaller than two on any axis has
no complete cell and returns the valid empty mesh after admission.

Every maximum image index must be exactly representable as binary64. The affine
determinant evaluated in the specified expression must be finite and non-zero.
No source value, requested label, coordinate, identifier or limit is placed in
a diagnostic payload.

## Membership and boundary semantics

For a decoded label `L` and requested set `R`, membership is the Boolean
predicate `L in R`, evaluated by exact same-domain integer equality. A value
outside the source container's narrower numerical range is still a valid
requested value and never matches that source. Signed and unsigned equality
are distinct domains.

The result is the piecewise-linear boundary between selected and unselected
membership. Selected-selected and unselected-unselected adjacency emit no
surface, regardless of whether endpoint label identifiers differ. There is no
distinguished zero/background label, per-label precedence, tolerance, range or
numeric ordering beyond the requested set's canonical binary-search order.

Cells are the intervals between adjacent sample centres. Only complete cells
whose lower index is in `0..<(extent[axis] - 1)` on all axes are visited. No
ghost layer, virtual exterior, padding extrapolation or cap is created. A
surface that meets the source boundary remains open there. The simplicial
boundary is not a 6-, 18- or 26-connected component classification.

## Cell and corner model

Within a cell with lower index `(x, y, z)`, corners are:

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

Every cell uses these six ordered tetrahedra:

```text
(0, 1, 3, 7)
(0, 5, 1, 7)
(0, 3, 2, 7)
(0, 2, 6, 7)
(0, 4, 5, 7)
(0, 6, 4, 7)
```

Each tuple has positive unit determinant in image-axis coordinates. This is
the same global Freudenthal subdivision as the scalar reference, so adjacent
cells induce one conforming shared-face diagonal. The fixed directional bias
is part of the algorithm identity.

## Tetrahedron cases

Local edges are:

```text
0 = (v0, v1)
1 = (v1, v2)
2 = (v2, v0)
3 = (v0, v3)
4 = (v1, v3)
5 = (v2, v3)
```

Bit `i` of the case number is one exactly when `vi` is selected. Consecutive
edge triples are one triangle. Right-hand-rule normals point from selected
toward unselected membership in image-axis coordinates.

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

No table row, triangle or edge triple may be reordered or replaced by a
geometrically similar triangulation.

## Midpoints and vertex keys

Every table edge has opposite endpoint membership. Sort its two global sample
ordinals ascending and use the ordered ordinal pair as its vertex key. If the
corresponding image indices are `p0` and `p1`, the exact image position is:

```text
p[axis] = (p0[axis] + p1[axis]) / 2
```

This expression denotes a dyadic rational, not overflowing integer addition.
The binary64 implementation converts the exactly representable integer
endpoints and evaluates `Double(p0[axis]) + 0.5 *
Double(p1[axis] - p0[axis])` without fusion or reassociation. The result must
equal the specified dyadic value exactly. A rounded endpoint, NaN or infinity
fails `positionNotRepresentable`; the implementation does not clamp or snap.

The table guarantees three distinct opposite-membership edge keys in every
triangle. Implementations still validate that invariant before publication and
must fail closed rather than publish a repeated index. No coordinate-tolerance
welding, area filtering or post-hoc topology normalisation is permitted.

## Deterministic output order

Cells are traversed with axis two outermost, axis one next and axis zero
innermost. Tetrahedra, table triangles and triangle edges retain the listed
order. A vertex is appended on first reference and reused by exact edge key;
each triangle is appended immediately after its three indices are resolved.
This fixes vertex order, triangle order, multiplicity and the complete
`UInt64` topology sequence. The mesh declares exactly the appended position
count and contains no unused position.

## Coordinate mapping and winding

The image position is permuted into spatial slots by the source
`SpatialAxisMapping`. Each world component is then evaluated in this exact
row-major affine order:

```text
q0 = m[4*r + 0] * spatial[0]
q1 = m[4*r + 1] * spatial[1]
q2 = m[4*r + 2] * spatial[2]
world[r] = ((q0 + q1) + q2) + m[4*r + 3]
```

Every intermediate and final component must be finite. The output binds the
source's complete `CoordinateSpaceDescriptor`, not identifier equality alone.
The determinant is evaluated exactly as:

```text
det = m[0] * (m[5] * m[10] - m[6] * m[9])
      - m[1] * (m[4] * m[10] - m[6] * m[8])
      + m[2] * (m[4] * m[9] - m[5] * m[8])
```

The effective orientation is the determinant sign times image-axis permutation
parity. If negative, swap the second and third index of every triangle. The
physical normal therefore remains selected-to-unselected.

## Precision, limits, failures and cancellation

Output mapping uses IEEE-754 binary64, round-to-nearest-ties-to-even, gradual
subnormals, no fast math, no flush-to-zero, no fused substitution and no
reassociation. Label decoding and membership remain exact integer operations.
The public payload-free failure categories are:

```text
invalidLimits
invalidLabelSet
unsupportedSource
resourceLimitExceeded
positionNotRepresentable
sourceReadFailed
cancelled
publicationFailed
```

Admission precedence is task cancellation; positive limits and the 65,536 hard
set ceiling; nonempty set; requested count ceiling; strict ordering/uniqueness;
source/geometry; one source read; then integer decoding. Requested-set and
sample validation poll cancellation before ordinal zero and every 4,096
ordinals. At a poll boundary cancellation precedes examining that item.

Cell and all output arithmetic is checked. Before each cell whose canonical
ordinal is divisible by 64, cancellation is checked. Within a cell,
midpoint/mapping and prospective resource checks follow table order. The
operation checks the caller ceilings before appending the next triangle or any
of its new vertices. A final cancellation check precedes the single immutable
mesh/identity/provenance publication. Any failure publishes no partial result.

Source admission failures, including descriptor sample-count overflow, map to
`unsupportedSource`. Cell-count, canonical-ordinal and output arithmetic
overflow or exceeding a valid caller ceiling maps to
`resourceLimitExceeded`. Full-region construction, expected packed-byte
overflow or mismatch, decoder bounds,
retention release and every non-cancellation coordinator provider, contract or
budget failure map to `sourceReadFailed`; coordinator or observed task
cancellation maps to `cancelled`. A non-exact image midpoint or non-finite
ordered affine intermediate/result maps to `positionNotRepresentable`.
Impossible repeated table keys, mesh construction and every post-traversal
parameter, identity, provenance or result-binding failure map to
`publicationFailed`.

## Conformance fixtures

The independent oracle is
[`ADR-0192-labelled-surface-extraction-oracle.py`](../progress/evidence/ADR-0192-labelled-surface-extraction-oracle.py).
It contains its own categorical extractor and never calls scalar interpolation.
It proves positive tetrahedron orientation and selected-to-unselected table
winding, then records:

```text
cubeMembershipSHA256=4bed958ac7d25a4539de8a0cea28524271a89303c3e9e3fb0de0d311e5c6931d
cubeBinary64SHA256=154f1d57f1fe6491f9fe6267109fa46074ffba860d16f7284736388a434536aa
ternaryUnionSHA256=b4bfe7adc07d80b0231bff3be93e82adb42a3c7c8d0d72684899d7aa7ac6ef95
sharedFaceSHA256=d656b3f812750fd97813431fb9168d26e8f87ea1148f326cf6e2a83ef0a831e9
integerContainerSHA256=3bf3a336dfd94d366f4981ce0431e2ea42f126f48647e0ab39d3b6c3e6f54253
ternaryCases=45927 maximumVertices=13 maximumTriangles=12
singleCorner=7v/6t unionBoundary=9v/8t
selectedInterface=suppressed sharedFace=conforming
winding=selected-to-unselected
```

The binary digests deliberately equal the accepted scalar binary-mask digests:
the two algorithms share a frozen topology only when scalar samples are binary,
the scalar isovalue is one half and categorical membership matches the high
sample. That agreement is a cross-oracle, not permission to implement labelled
extraction by scalar conversion.

For the identity `2 x 2 x 2` fixture whose corner zero has label `7`, all other
corners label `-4`, and requested set is `{7}`, positions are:

```text
(0.5, 0.0, 0.0)
(0.5, 0.5, 0.0)
(0.5, 0.5, 0.5)
(0.5, 0.0, 0.5)
(0.0, 0.5, 0.0)
(0.0, 0.5, 0.5)
(0.0, 0.0, 0.5)
```

and triangles are:

```text
(0, 1, 2)
(3, 0, 2)
(1, 4, 2)
(4, 5, 2)
(6, 3, 2)
(5, 6, 2)
```

The ternary corpus covers all assignments of three raw label identifiers to
eight cube corners and all seven nonempty requested subsets. The shared-face
corpus covers every binary assignment across two adjacent cubes. Integer
fixtures cover minima, zero and maxima of all eight containers in both
explicit byte orders. Swift conformance is bit-exact for representable
positions and exact for topology and failure classification; no tolerance
applies.

## Provenance fields

A successful operation records:

- operation token `org.voxelia.op.labelled-surface-extraction`;
- algorithm identifier `freudenthal-label-set-surface/binary64-v1`;
- exact signed/unsigned requested labels in canonical increasing order;
- membership rule `exact-decoded-label-in-requested-set`;
- adjacency rule `freudenthal-piecewise-linear`;
- boundary rule `interior-cells-only`; and
- one source input with role `source-volume`, occurrence one and exact source
  identity, plus accepted implementation/software/execution claims.

The parameter collection and 4,194,304-byte VCMJ-1 ceiling are exact in
`ADR-0192`. Limits and cancellation cadence do not affect a successful mesh
and are excluded from result identity. Labels enter only the parameter digest;
logs and diagnostics never reveal them.

## Complexity and exclusions

The reference costs
`O(sampleCount log selectedLabelCount + emittedTriangles)` and retains source
bytes, the immutable requested array and an edge map bounded by the vertex
limit. It makes no throughput guarantee. Masks, fractional or overlapping
segments, per-label batch results, connected components, normals, measurement,
rendering, acceleration, brick seams and streaming extraction remain separate
contracts.

## References

- [ADR-0183 - Geometry extraction arc](../architecture/decisions/ADR-0183-geometry-arc.md)
- [ADR-0190 - Scalar surface extraction design](../architecture/decisions/ADR-0190-scalar-surface-extraction-design.md)
- [ADR-0192 - Labelled surface extraction design](../architecture/decisions/ADR-0192-labelled-surface-extraction-design.md)
- [VOXELIA-ALG-0028 - Freudenthal scalar-surface extraction](VOXELIA-ALG-0028-freudenthal-surface-extraction.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
