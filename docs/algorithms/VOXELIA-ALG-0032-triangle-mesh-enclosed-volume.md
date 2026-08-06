---
document_id: "VOXELIA-ALG-0032"
title: "Triangle-mesh certified enclosed volume binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Triangle-mesh certified enclosed volume binary64-v1

## Purpose

This specification defines `triangle-mesh-enclosed-volume/binary64-v1`, the
deterministic CPU reference selected by accepted
[`ADR-0195`](../architecture/decisions/ADR-0195-triangle-mesh-enclosed-volume-design.md).
It first **certifies** that the admitted `TriangleMesh` is a closed,
edge-manifold, consistently oriented surface, and only then reduces it to one
non-negative scalar: the volume of the region that surface bounds.

Unlike total facet area, this quantity is meaningless for an arbitrary mesh.
The certification is therefore a hard admission gate, not a warning, and no
arithmetic runs until the whole surface has passed it.

## What is certified, and what is not

The predicate **certifies**, over the exact admitted topology:

- **no index-degenerate facet** — no triangle repeats a vertex index;
- **closure** — every directed edge's reverse is also present, so the surface
  has no boundary edge;
- **edge-manifoldness** — every directed edge occurs exactly once, so every
  undirected edge carries exactly two incident triangles; and
- **orientation consistency** — the two triangles on each edge traverse it in
  opposite directions.

Together these are exactly the hypotheses the divergence identity needs for
the facet sum below to be the bounded region's volume.

The predicate deliberately **does not certify**:

- **vertex manifoldness.** A pinch-point vertex, whose link is two or more
  disjoint cycles, is admitted. The divergence identity does not require a
  single-cycle link: each shell still contributes exactly its own volume, and
  the registered pinch-point fixture proves it. Requiring a single cycle would
  reject a mesh whose published volume is exactly correct.
- **non-self-intersection.** Deciding whether a closed surface intersects
  itself needs exact or adaptive geometric predicates, which no accepted
  record supplies and which this record does not invent. For a
  self-intersecting closed oriented surface the facet sum is the
  winding-number-weighted signed volume, not the enclosed volume. This
  limitation is not prose only: `self-intersection-rule = not-certified` is an
  entry in the operation's parameter document, so it is inside the digest that
  identifies every published result.

## Input domain and admission

The numerical input is one already validated `TriangleMesh` with finite
binary64 `(x, y, z)` positions, complete in-bounds independent-triangle
topology and zero or more exact vertex attributes. Vertex attributes are never
read.

The operation additionally receives structurally matching source `DataIdentity`
and `ProvenanceRecord` claims and three explicit positive `UInt64` ceilings:

- maximum vertex count;
- maximum triangle count; and
- maximum additional logical byte count.

The source provenance subject must be the source identity's object. Source
vertex and triangle counts are checked before any traversal.

Unlike
[`VOXELIA-ALG-0031`](VOXELIA-ALG-0031-triangle-mesh-total-facet-area.md), this
operation owns real payload: certification holds one directed-edge record per
facet corner, each an ordered pair of 64-bit vertex indices. The exact
additional logical byte requirement is:

```text
directedEdgeCount = triangleCount * 3
additionalLogicalByteCount = directedEdgeCount * 16
```

Every multiplication and the final comparison use checked `UInt64` arithmetic
before the edge collection is allocated. The ceiling excludes the already-owned
source payload, immutable result shells, allocator bookkeeping and hash-table
load factor. An empty mesh requires zero additional logical bytes and succeeds
when the three declared ceilings are themselves positive. The registered
one-past boundary is `384307168202282325` triangles.

## Unit

The published measurement carries the source coordinate space's exact
`MeasurementUnit` raised to the power **three**, using the same
`PoweredLengthUnit` representation `ADR-0194` froze for area. The base unit's
`scaleToCanonical` and `offsetToCanonical` are not raised, combined or
otherwise reinterpreted, and the value grants no conversion authority.

## Reference origin

The facet term below is anchored at the **source coordinate space's own
origin**. Positions are used exactly as published; there is no recentering,
centroid shift or first-vertex rebasing.

In real arithmetic the sum is origin-independent for a closed surface. In
binary64 it is not: anchoring far from the mesh makes each facet term large
and relies on cancellation. The registered `translated-cube` fixture makes this
explicit — a unit cube at the origin encloses exactly `1.0`, while the same
cube translated by `(0.1, 0.2, 0.3)` encloses `1.0000000000000004`. Both are
the correct output of this frozen model. A caller who needs the
better-conditioned answer recenters its own mesh and publishes that as a
distinct derived object with its own provenance; recentering inside this
operation would require inventing a centroid rule, a second pass and its own
rounding contract, and would change the published bits without appearing in
the parameter digest.

## Facet term

Triangles are visited in existing topology order. For one ordered triangle
`(i0, i1, i2)`, load `p0`, `p1` and `p2` from those exact vertex indices and
evaluate the signed six-fold volume of the tetrahedron on the origin and those
three points:

```text
cross.x = (p1.y * p2.z) - (p1.z * p2.y)
cross.y = (p1.z * p2.x) - (p1.x * p2.z)
cross.z = (p1.x * p2.y) - (p1.y * p2.x)

term0 = p0.x * cross.x
term1 = p0.y * cross.y
term2 = p0.z * cross.z

facetSixVolume = (term0 + term1) + term2
```

Every displayed multiplication, subtraction and addition is one separate
correctly rounded binary64 operation in exactly that order. No fused
multiply-add, reassociation, determinant-expansion reordering, exact-rational
recovery or compensated evaluation is permitted.

Note that the cross product is taken over the **positions** `p1` and `p2`, not
over edge vectors. This is the origin-anchored form, and it is deliberately a
different expression from the edge-vector cross product frozen by
`VOXELIA-ALG-0030` and reused by `VOXELIA-ALG-0031`: those compute an
origin-independent doubled area, this computes an origin-dependent signed
determinant. The two must not be interchanged.

A facet whose three positions are collinear, or whose term is exactly zero,
contributes zero. It is not removed and not an error: its topology is still
required for closure.

## Serial accumulation and the single division

The accumulator begins at positive binary64 zero. After each facet term is
computed it is added:

```text
total = total + facetSixVolume
```

Each addition is one separate correctly rounded binary64 operation in
increasing triangle order. No parallel reduction, sorting by magnitude,
pairwise summation, Kahan or Neumaier compensation, or higher-precision
accumulator may change the reference bits. The registered order-sensitive
fixture sums the same three shells forwards and backwards and obtains
different binary64 volumes.

The division by six happens **exactly once, at the end**, over the accumulated
six-fold total:

```text
enclosedVolume = total / 6.0
```

Dividing per facet would introduce one rounding per triangle instead of one
rounding for the whole mesh, and would change the published bits. The six-fold
total is the accumulated quantity; the volume is its single quotient.

## Orientation sign

A consistently **outward** surface produces a non-negative total; a
consistently **inward** one produces a negative total. Both certify — inward
orientation is consistent, merely reversed.

If the accumulated total is strictly less than zero the operation fails with
`invertedOrientation`. The magnitude is not published in its place. An
inward-oriented mesh is a caller-side orientation error, and silently
absolutising it would hide the error while returning a plausible number; the
accepted scalar and labelled extraction operations both emit outward winding,
so a negative total means something upstream reversed it.

A total of exactly zero, or negative zero, is admitted and published as
positive zero. The registered `double-sided-facet` fixture — one triangle and
its reverse — certifies as a closed oriented surface bounding an empty region
and encloses exactly positive zero.

## Shells, cavities and disconnection

Connectivity is never examined. A mesh may hold any number of disjoint closed
shells; each contributes its own signed volume and the total is their sum.

Cavities are expressed by **orientation, not by nesting geometry**. An
inward-oriented shell nested inside an outward-oriented one subtracts, which is
exactly the divergence identity's own answer for a solid with a void. The
registered `nested-cavity` fixture is a side-four outward cube containing a
side-two inward cube and encloses exactly `56.0`. The operation performs no
containment test and does not verify that the inner shell is geometrically
inside the outer one; a caller who wires the orientations up wrongly gets the
arithmetic it asked for, which is why orientation is a published rule rather
than an inferred property.

## Precision and representability

The reference uses IEEE-754 binary64, round-to-nearest-ties-to-even, gradual
subnormals, no fast math, no flush-to-zero, no contraction, no reassociation
and no higher-precision accumulator. After every cross-product multiplication
and subtraction, every term multiplication, every term sum, every accumulator
addition and the final division, the result must be finite. A NaN or infinity
fails the whole operation as `volumeNotRepresentable`; it is never clamped,
saturated or recovered by an alternate formulation.

This deliberately rejects some finite input meshes whose mathematically
representable volume overflows the frozen ordered expression. Changing to a
recentred anchor, a scaled accumulation, compensated summation or a different
determinant expansion is a new algorithm identity.

## Failure precedence and cancellation

The public payload-free failure family is:

```text
invalidLimits
invalidSource
resourceLimitExceeded
degenerateFacet
openSurface
nonManifoldOrientation
invertedOrientation
volumeNotRepresentable
cancelled
publicationFailed
```

Admission order is: task cancellation; three positive ceilings; structural
source identity/provenance correspondence; source counts against their
ceilings; the checked additional-byte calculation and ceiling; then allocation.

The operation then runs **two complete passes**, never interleaved:

1. **Certification.** Cancellation is checked before facet zero and every facet
   ordinal divisible by 64. Within one facet, index degeneracy is checked
   before any directed edge is recorded, and a repeated directed edge is
   detected at the corner that repeats it. Only after every facet has been
   recorded is the reverse-partner scan run, in ascending insertion order.
2. **Volume.** Cancellation is checked before facet zero and every facet
   ordinal divisible by 64. Within one facet, the exact numerical and failure
   order is the one displayed above.

Separating the passes is a decision, not an implementation detail: no
arithmetic runs for an uncertified surface, so `volumeNotRepresentable` can
never mask an `openSurface`, and a partially-summed uncertified mesh never
exists.

The orientation-sign check follows complete accumulation and precedes the
division. A final cancellation check occurs after the volume exists and before
any measurement, identity or provenance is constructed. Every failure returns
no measurement aggregate and no partial total.

Invalid ceilings map to `invalidLimits`; a mismatched source claim subject maps
to `invalidSource`; a count above its ceiling, checked-byte overflow or a valid
host ceiling maps to `resourceLimitExceeded`. A repeated vertex index maps to
`degenerateFacet`; a repeated directed edge maps to `nonManifoldOrientation`; a
directed edge with no reverse partner maps to `openSurface`; a negative total
maps to `invertedOrientation`. Non-finite ordered arithmetic maps to
`volumeNotRepresentable`; observed task or injected checkpoint cancellation
maps to `cancelled`. Unit, measurement, parameter, identity, provenance or
result-binding construction failure after numerical completion maps to
`publicationFailed`.

There is deliberately no separate duplicate-facet case. A repeated facet
traverses each of its directed edges a second time and is already
`nonManifoldOrientation`; the registered `duplicate-facet` fixture proves the
discharge.

## Determinism and accelerated conformance

The CPU reference is serial and stateless. Repeated execution over the same
input bits and claims produces the same volume bits, the same certification
verdict and the same fixed claims. An accelerated implementation may schedule
work differently only if it reproduces the CPU volume bit-for-bit and the same
failure class; ordinary floating-point tolerance is insufficient because both
the reference origin and the reduction order are part of the algorithm. No
backend buffer, Metal acceleration structure or rendered pixel becomes an
authoritative measurement.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0195-enclosed-volume-oracle.py`](../progress/evidence/ADR-0195-enclosed-volume-oracle.py).
It forces each displayed operation through binary64 and records sixteen
fixtures:

- an outward unit tetrahedron on the axes enclosing exactly one sixth;
- an origin-anchored unit cube enclosing exactly one;
- the same cube translated by `(0.1, 0.2, 0.3)` enclosing
  `1.0000000000000004`, proving the reference origin is part of the identity;
- a side-two cube enclosing exactly eight;
- an empty mesh, vacuously closed, enclosing positive zero;
- two disjoint shells of side one and side two enclosing exactly nine;
- a side-four outward cube containing a side-two inward cube enclosing exactly
  fifty-six, fixing cavity semantics;
- two tetrahedra sharing one vertex index — a pinch point, edge-manifold but
  not vertex-manifold — enclosing exactly two sixths;
- one triangle and its reverse, certifying and enclosing positive zero;
- three shells whose forward and reverse serial sums differ in binary64;
- a cube missing one facet, rejected `openSurface`;
- a cube with one facet repeated, rejected `nonManifoldOrientation`;
- two facets traversing one edge in the same direction, rejected
  `nonManifoldOrientation`;
- a facet with a repeated vertex index, rejected `degenerateFacet`;
- a consistently inward cube, rejected `invertedOrientation`; and
- a tetrahedron with `1e200` extents, rejected `volumeNotRepresentable`.

The registered output is:

```text
fixtureSHA256=7f3c73ceb34815bc3bb4af7d5bc3e957c992d9670a7a9841c105a945992ab90e
volumeBytesSHA256=c313f1c0b8e59fa267541313abfc0d314df0bb7cb5711a4f29616f604296ae71
fixtures=16 successful=10 failures=6
maximumAdditionalByteTriangleCount=384307168202282325
certificationCancellationOrdinals=0,64,128,... volumeCancellationOrdinals=0,64,128,...
certified=closed,edge-manifold,consistently-oriented
notCertified=vertex-manifold,non-self-intersecting
referenceOrigin=source-coordinate-space emptyVolume=positive-zero
```

Swift conformance is bit-exact for the volume, and exact for errors, facet
count, unit publication, parameter digest, claims and checkpoint order. No
numeric tolerance applies. The oracle does not validate Swift allocation
lifetime, copy-on-write behaviour, concurrency, cancellation machinery or
provenance construction.

## Provenance fields

A successful CPU operation records:

- operation token `org.voxelia.op.triangle-mesh-enclosed-volume`;
- implementation token
  `org.voxelia.impl.triangle-mesh-enclosed-volume.cpu`;
- algorithm `triangle-mesh-enclosed-volume/binary64-v1`;
- the fixed certification, vertex-manifold, self-intersection, degeneracy,
  facet-term, reference-origin, accumulation, orientation and unit rules from
  `ADR-0195`; and
- exactly one input with role `source-mesh`, occurrence one, source object
  identity and source provenance parent.

Limits and cancellation cadence are execution policy and do not enter the
parameter digest. Output authority and software identity are separately
caller-supplied. No coordinate, source identifier, volume value, facet count,
mesh size, topology or attribute enters diagnostics or logs.

## Complexity and exclusions

Certification is `O(triangleCount)` expected time over a hashed directed-edge
collection and `O(triangleCount)` governed logical payload. Volume reduction is
`O(triangleCount)` time and constant additional space. Public result binding is
`O(1)`. No wall-clock throughput or physical allocator-byte bound is promised.

Self-intersection certification, containment and nesting verification,
vertex-manifold classification, orientation repair, hole filling, surface
reconstruction, union or intersection volumes, moment and inertia tensors,
centroid publication, mesh simplification, rendering and backend acceleration
remain separate contracts.

## References

- [ADR-0143 - Area and volume measurement design](../architecture/decisions/ADR-0143-area-volume-measurement-design.md)
- [ADR-0183 - Geometry extraction arc](../architecture/decisions/ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](../architecture/decisions/ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0194 - Triangle-mesh total facet area design](../architecture/decisions/ADR-0194-triangle-mesh-total-facet-area-design.md)
- [ADR-0195 - Triangle-mesh certified enclosed volume design](../architecture/decisions/ADR-0195-triangle-mesh-enclosed-volume-design.md)
- [VOXELIA-ALG-0019 - Calibrated voxel volume](VOXELIA-ALG-0019-voxel-volume.md)
- [VOXELIA-ALG-0031 - Triangle-mesh total facet area](VOXELIA-ALG-0031-triangle-mesh-total-facet-area.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
