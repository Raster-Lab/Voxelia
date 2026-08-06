---
document_id: "VOXELIA-ALG-0031"
title: "Triangle-mesh total facet area binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Triangle-mesh total facet area binary64-v1

## Purpose

This specification defines `triangle-mesh-total-facet-area/binary64-v1`, the
deterministic CPU reference selected by accepted
[`ADR-0194`](../architecture/decisions/ADR-0194-triangle-mesh-total-facet-area-design.md).
It reduces the authoritative positions and topology of an immutable
`TriangleMesh` to one unsigned scalar quantity: the serial sum, in exact
topology order, of every admitted facet's own area.

It deliberately does not compute a union area, a closed-surface area, an
enclosed volume, a per-component or per-shell area, a projected area or a
sampled approximation. It does not deduplicate coincident facets, merge
coplanar neighbours, subtract overlaps, repair topology, classify manifoldness,
test orientation consistency, detect self-intersections, generate normals or
define a renderer.

## Quantity

For a mesh whose topology holds `t` ordered triangles, the published quantity
is

```text
totalFacetArea = fl( ... fl(fl(0 + a[0]) + a[1]) ... + a[t-1])
```

where `a[k]` is the unsigned area of the `k`-th triangle evaluated exactly as
defined below, and every displayed addition is one separate correctly rounded
binary64 operation applied in increasing `k`.

The quantity counts facet area with multiplicity: two triangles occupying the
same three positions contribute twice. Every admitted facet is included exactly
once per topology entry, irrespective of winding, connectivity, adjacency or
whether it lies inside another part of the same mesh. This is a property of the
supplied facet list, not of any surface the facet list may or may not bound.

## Input domain and admission

The numerical input is one already validated `TriangleMesh` with finite
binary64 `(x, y, z)` positions, complete in-bounds independent-triangle
topology and zero or more exact vertex attributes. Vertex attributes are never
read; the quantity depends only on positions and topology.

The operation additionally receives structurally matching source `DataIdentity`
and `ProvenanceRecord` claims and two explicit positive `UInt64` ceilings:

- maximum vertex count; and
- maximum triangle count.

The source provenance subject must be the source identity's object. Source
vertex and triangle counts must not exceed their ceilings; both are checked
before any traversal.

There is deliberately no additional-logical-byte ceiling and no existing-
attribute ceiling. The reference allocates no per-vertex or per-facet buffer:
it reduces the already-owned immutable positions into one binary64 accumulator
and publishes one scalar. Declaring a payload ceiling for a constant-space
reduction, or an attribute ceiling for a scan that never happens, would
misrepresent the operation's resource contract. An admitted source topology
already owns `triangleCount * 3` host indices, so the traversal offset cannot
overflow the 64-bit Apple `Int` domain; the registered boundary
`3074457345618258602` records that reasoning explicitly.

## Unit

The published measurement carries the source coordinate space's exact
`MeasurementUnit` raised to the power two. Both the base unit and the exponent
are published as separate immutable fields rather than a derived code string, a
new unit registry entry or a silently squared conversion factor.

The base unit's `scaleToCanonical` and `offsetToCanonical` are **not** raised,
combined or otherwise reinterpreted. A powered unit grants no conversion
authority: a consumer that needs a canonical area must derive its own
conversion from the declared base and exponent under its own accepted rule.
Because `CoordinateSpaceDescriptor` already rejects a non-length unit, the
published base always carries `UnitDimension.length` and the published exponent
is always two for this operation.

## Facet area

Triangles are visited in existing topology order. For one ordered triangle
`(i0, i1, i2)`, load `p0`, `p1` and `p2` from those exact vertex indices and
evaluate the oriented doubled-area vector using the same frozen expression
order as
[`VOXELIA-ALG-0030`](VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md):

```text
e10.x = p1.x - p0.x
e10.y = p1.y - p0.y
e10.z = p1.z - p0.z

e20.x = p2.x - p0.x
e20.y = p2.y - p0.y
e20.z = p2.z - p0.z

face.x = (e10.y * e20.z) - (e10.z * e20.y)
face.y = (e10.z * e20.x) - (e10.x * e20.z)
face.z = (e10.x * e20.y) - (e10.y * e20.x)
```

Then take the unsigned magnitude and halve it:

```text
scale = max(abs(face.x), abs(face.y), abs(face.z))
```

If `scale` is exactly zero, the facet area is positive binary64 zero and no
further arithmetic is performed for that facet. This covers a repeated vertex,
three collinear positions and any facet whose ordered cross product evaluated
to exact zero. It is not a failure: a zero-area facet is an admitted facet
contributing zero, and topology is never altered.

For a non-zero `scale` evaluate, in this order:

```text
sx = face.x / scale
sy = face.y / scale
sz = face.z / scale

s0 = sx * sx
s1 = sy * sy
s2 = sz * sz
sum = (s0 + s1) + s2
scaledNorm = sqrt(sum)

doubledArea = scale * scaledNorm
facetArea = doubledArea * 0.5
```

Every displayed subtraction, multiplication, division and addition is one
separate correctly rounded binary64 operation in exactly that order. `sqrt` is
the platform's correctly rounded IEEE-754 square root. No fused multiply-add,
reassociation, `hypot`, exact-rational recovery, compensated summation or
alternative magnitude formulation is permitted.

Because one scaled component has magnitude exactly one, `sum` lies in `[1, 3]`
and the scaled norm never forms an overflowing unscaled sum of squares. The
final `scale * scaledNorm` can still overflow for an extreme but finite mesh;
that is a representability failure, not a value to rescale.

`facetArea` is unsigned and therefore independent of winding. Reversing a
triangle's vertex order negates `face` but leaves every `abs`, the scale, the
scaled norm and the halved magnitude bit-identical.

## Serial accumulation

The accumulator begins at positive binary64 zero. After each facet area is
computed it is added:

```text
total = total + facetArea
```

Each addition is one separate correctly rounded binary64 operation in
increasing triangle order. No parallel reduction, sorting by magnitude,
pairwise summation, Kahan or Neumaier compensation, or higher-precision
accumulator may change the reference bits. Reduction order is part of the
algorithm identity: the registered order-sensitive fixture sums the same three
facets forwards and backwards and obtains different binary64 totals.

An empty mesh, and a mesh whose facets are all degenerate, both total positive
zero. Negative zero is never published, and no facet can contribute a negative
value.

## Precision and representability

The reference uses IEEE-754 binary64, round-to-nearest-ties-to-even, gradual
subnormals, no fast math, no flush-to-zero, no contraction, no reassociation
and no higher-precision accumulator. After every edge subtraction, cross-
product multiplication and subtraction, scaled division, squared product, sum,
square root, scaled magnitude, halving and accumulator addition, the result
must be finite. A NaN or infinity fails the whole operation as
`areaNotRepresentable`; it is never clamped, saturated or recovered by an
alternate formulation.

Underflow is not a failure. A facet whose doubled area is the least subnormal
halves to positive zero under ties-to-even, and that zero is the published
contribution. The frozen model does not infer geometric nondegeneracy outside
its own arithmetic; the registered subnormal fixture makes this explicit.

This deliberately rejects some finite input meshes whose mathematically
representable total area overflows the frozen ordered expression. Changing to a
scaled accumulation, compensated summation, sorted reduction or a different
magnitude formulation is a new algorithm identity.

## Failure precedence and cancellation

The public payload-free failure family is:

```text
invalidLimits
invalidSource
resourceLimitExceeded
areaNotRepresentable
cancelled
publicationFailed
```

Admission order is: task cancellation; two positive ceilings; structural source
identity/provenance correspondence; then source counts against their ceilings.

Triangle traversal checks cancellation before triangle zero and every triangle
ordinal divisible by 64. Cancellation at a poll precedes the facet at that
ordinal. Within one facet, the exact numerical and failure order is the one
displayed above: edge subtraction, then cross product, then zero
classification, then scaled normalisation, then the halving, then the
accumulator addition. A final cancellation check occurs after the complete
total exists and before any measurement, identity or provenance is
constructed.

Every failure returns no measurement aggregate and no partial total.

Invalid ceilings map to `invalidLimits`; a mismatched source claim subject maps
to `invalidSource`; a count above its ceiling or a source count outside the
host domain maps to `resourceLimitExceeded`. Non-finite ordered arithmetic maps
to `areaNotRepresentable`; observed task or injected checkpoint cancellation
maps to `cancelled`. Unit, measurement, parameter, identity, provenance or
result-binding construction failure after numerical completion maps to
`publicationFailed`.

There is deliberately no `undefinedArea` case. Zero is a legitimate total, and
no admitted mesh can produce an undefined unsigned magnitude that is not
already a representability failure.

## Determinism and accelerated conformance

The CPU reference is serial and stateless. Repeated execution over the same
input bits and claims produces the same output total bits and fixed claims. An
accelerated implementation may schedule work differently only if it reproduces
the CPU total bit-for-bit and the same failure class; ordinary floating-point
tolerance is insufficient because reduction order is part of the algorithm. No
backend buffer, Metal acceleration structure or rendered pixel becomes an
authoritative measurement.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0194-total-facet-area-oracle.py`](../progress/evidence/ADR-0194-total-facet-area-oracle.py).
It forces each displayed operation through binary64 and records thirteen
fixtures:

- a right triangle with legs two and three totalling exactly three;
- the same triangle wound in reverse, proving winding independence;
- three copies of that triangle totalling exactly nine, proving multiplicity;
- a degenerate facet followed by a valid facet, totalling exactly three;
- an empty mesh totalling positive zero over zero facets;
- an all-degenerate mesh totalling positive, never negative, zero;
- an oblique facet exercising the maximum-component-scaled magnitude;
- three facets whose forward and reverse serial sums differ in binary64,
  proving the frozen reduction order;
- a facet whose doubled-area vector lies on one axis, where a fused
  multiply-subtract in the cross product changes the published total;
- a facet whose doubled area is the least subnormal and whose halved area is
  therefore positive zero;
- edge-subtraction overflow;
- scaled-magnitude overflow from a finite doubled-area vector; and
- serial accumulated-area overflow.

The registered output is:

```text
fixtureSHA256=38bad8cfd458b0dca99df2522e34124d51fe607f7fa428fa9f7a586c661d6feb
totalBytesSHA256=8a8af5729b9008d759b9886eb757b31a85cf6dab22d07696b06062f3df668605
fixtures=13 successful=10 failures=3
additionalLogicalByteCount=0 ceilings=vertexCount,triangleCount
maximumHostTriangleCount=3074457345618258602
triangleCancellationOrdinals=0,64,128,...
orientation=unsigned-winding-independent emptyTotal=positive-zero
```

Swift conformance is bit-exact for the total, and exact for errors, facet
count, unit publication, parameter digest, claims and checkpoint order. No
numeric tolerance applies. The oracle does not validate Swift allocation
lifetime, copy-on-write behaviour, concurrency, cancellation machinery or
provenance construction.

## Provenance fields

A successful CPU operation records:

- operation token `org.voxelia.op.triangle-mesh-total-facet-area`;
- implementation token
  `org.voxelia.impl.triangle-mesh-total-facet-area.cpu`;
- algorithm `triangle-mesh-total-facet-area/binary64-v1`;
- the fixed quantity, facet-area, degeneracy, accumulation, orientation,
  topology-claim and unit rules from `ADR-0194`; and
- exactly one input with role `source-mesh`, occurrence one, source object
  identity and source provenance parent.

Limits and cancellation cadence are execution policy and do not enter the
parameter digest. Output authority and software identity are separately
caller-supplied. No coordinate, source identifier, area value, facet count,
mesh size, topology or attribute enters diagnostics or logs.

## Complexity and exclusions

The numerical reference is `O(triangleCount)` and uses constant additional
space: one binary64 accumulator and one facet-local working vector. It reads
positions already owned by the immutable source and copies no payload buffer.
It does not promise a wall-clock throughput or physical allocator-byte bound.

Enclosed volume, watertightness certification, manifold and orientation
classification, self-intersection detection, union or projected area, per-shell
or per-component decomposition, curvature, mesh simplification, rendering and
backend acceleration remain separate contracts.

## References

- [ADR-0143 - Area and volume measurement design](../architecture/decisions/ADR-0143-area-volume-measurement-design.md)
- [ADR-0183 - Geometry extraction arc](../architecture/decisions/ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](../architecture/decisions/ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0193 - Deterministic triangle-mesh vertex normals design](../architecture/decisions/ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [ADR-0194 - Triangle-mesh total facet area design](../architecture/decisions/ADR-0194-triangle-mesh-total-facet-area-design.md)
- [VOXELIA-ALG-0018 - Planar polygon area](VOXELIA-ALG-0018-planar-polygon-area.md)
- [VOXELIA-ALG-0030 - Triangle area-weighted vertex normals](VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
