---
document_id: "VOXELIA-ALG-0030"
title: "Triangle area-weighted vertex normals binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-05"
owner: "Voxelia Project"
---

# Triangle area-weighted vertex normals binary64-v1

## Purpose

This specification defines
`triangle-area-weighted-vertex-normals/binary64-v1`, the deterministic CPU
reference selected by accepted
[`ADR-0193`](../architecture/decisions/ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md).
It derives one smooth vertex-domain normal from the accepted winding and
authoritative positions of an immutable `TriangleMesh`. It does not modify
positions or topology, infer creases or smoothing groups, repair malformed
geometry, generate face normals, measure a surface or define a renderer.

## Input domain and admission

The numerical input is one already validated `TriangleMesh` with finite
binary64 `(x, y, z)` positions, complete in-bounds independent-triangle
topology and zero or more exact vertex attributes. The operation additionally
receives structurally matching source `DataIdentity` and `ProvenanceRecord`
claims and four explicit positive `UInt64` ceilings:

- maximum vertex count;
- maximum triangle count;
- maximum existing vertex-attribute count; and
- maximum additional logical byte count.

The source provenance subject must be the source identity's object. The
operation rejects an existing built-in `.normal` attribute rather than
overwriting, preserving or silently validating it. Custom attributes whose
namespace or name contains the word normal have no built-in-normal semantics
and remain untouched.

The source vertex, triangle and existing-attribute counts must not exceed their
ceilings. Normal generation requires two logical buffers of three binary64
components per vertex: one accumulator and one final little-endian attribute.
The exact additional logical byte requirement is therefore:

```text
componentCount = vertexCount * 3
oneBufferByteCount = componentCount * 8
additionalLogicalByteCount = oneBufferByteCount * 2
```

Every multiplication and the final comparison use checked `UInt64`
arithmetic before either buffer is allocated. The ceiling excludes the
already-owned source payload, immutable result shells, allocator bookkeeping
and copy-on-write metadata. Empty meshes require zero additional logical bytes
and succeed when the four declared ceilings themselves are positive.
The registered one-past boundary also proves each accepted 24-byte-per-vertex
buffer count fits the 64-bit Apple `Int` allocation domain.

## Output attribute and mesh preservation

The output positions, topology and every existing vertex attribute remain in
exact source order. Position components preserve their binary64 bit patterns,
including signed zero; topology indices and attribute descriptor/byte payloads
are unchanged. One normal attribute is appended last with this exact
descriptor:

```text
semantic = normal
scalar type = float64
valid bit count = absent
byte order = littleEndian
component count = 3
component interpretation = vector
component layout = interleaved
component names = absent
element count = source vertex count
```

For each vertex the output byte order is `x`, `y`, then `z`; each component is
the eight little-endian bytes of the exact output binary64 bit pattern. The
normal is dimensionless and expressed in the same coordinate basis as the
source positions. The complete source `CoordinateSpaceDescriptor` is retained.

## Triangle orientation and weighting

Triangles are visited in existing topology order. For one ordered triangle
`(i0, i1, i2)`, load `p0`, `p1` and `p2` from those exact vertex indices and
evaluate:

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

Every displayed subtraction, multiplication and final subtraction is one
separate correctly rounded binary64 operation in exactly that order. No fused
multiply-subtract, reassociation, scaled cross-product replacement or exact-
rational recovery is permitted. `face` is the oriented doubled-area vector;
using it directly gives area-weighted smoothing without an intermediate face
normal or division.

The right-hand direction follows the source triangle winding. Consequently,
the accepted scalar extraction's inside-to-outside winding and labelled
extraction's selected-to-unselected winding remain their respective normal
directions. Reversing a triangle reverses its contribution. Reflection has no
special branch because extraction already fixed physical winding in the
published positions and indices.

## Serial accumulation

The accumulator begins with positive binary64 zero for every component. After
computing one face vector, add it to triangle corners in `i0`, `i1`, `i2`
order, and within each corner in `x`, `y`, `z` order:

```text
accumulator[index].component =
    accumulator[index].component + face.component
```

Each addition is one separate correctly rounded binary64 operation. A repeated
index therefore receives the same face contribution more than once. When the
ordered edge and cross-product evaluation remains representable, a triangle
with fewer than three distinct positions has an exactly zero face vector.
Representability is checked before that geometric conclusion; repeated finite
positions do not excuse an earlier non-finite subtraction, product or cross
component. Duplicate triangles contribute with their full multiplicity.
Non-manifold vertices and disconnected incident fans are not rejected; every
incident triangle contributes in global topology order. No parallel reduction,
sorting, pairwise summation, compensation or normalisation between additions
may change the reference bits.

An exactly zero face vector contributes zero and is otherwise ignored. The
operation does not remove the triangle or change topology. Underflowed finite
components, including gradual subnormals and rounded zeros, are the values
used by later additions; geometric nondegeneracy outside this frozen
binary64 model is not inferred.

## Vertex normalisation

Vertices are normalised in increasing vertex-index order after all triangle
accumulation. For accumulator `a = (x, y, z)` evaluate:

```text
scale = max(abs(x), abs(y), abs(z))
```

If `scale` is exactly zero, the vertex normal is undefined and the complete
operation fails. This covers isolated vertices, vertices incident only to
zero-vector faces and exact cancellation of oppositely oriented contributions.
There is no arbitrary fallback axis, neighbour copy, face deletion, epsilon or
regularisation.

For a non-zero accumulator evaluate, in this order:

```text
sx = x / scale
sy = y / scale
sz = z / scale

s0 = sx * sx
s1 = sy * sy
s2 = sz * sz
sum = (s0 + s1) + s2
length = sqrt(sum)

nx = sx / length
ny = sy / length
nz = sz / length
```

Every division, multiplication and addition is a separate correctly rounded
binary64 operation. `sqrt` is the platform's correctly rounded IEEE-754 square
root. Because one scaled magnitude is exactly one, `sum` lies in `[1, 3]` and
the normalisation does not form an overflowing unscaled norm. After division,
every component comparing equal to zero is explicitly written as positive
zero. Non-zero subnormal components are preserved. The output is the exact
result of this definition; no subsequent unit-length tolerance correction is
applied.

## Precision and representability

The reference uses IEEE-754 binary64, round-to-nearest-ties-to-even, gradual
subnormals, no fast math, no flush-to-zero, no contraction, no reassociation
and no higher-precision accumulator. After every edge subtraction, cross
product, accumulator addition, scaled division, squared product, sum, square
root and final division, the result must be finite. A NaN or infinity fails the
whole operation as `normalNotRepresentable`; it is never clamped, rescaled by
an alternate algorithm or replaced.

This deliberately rejects some finite input meshes whose mathematically
normalisable area vectors overflow the frozen ordered binary64 expression.
Changing to a scaled cross product, compensated accumulation, angle weighting
or a different reduction is a new algorithm identity.

## Failure precedence and cancellation

The public payload-free failure family is:

```text
invalidLimits
invalidSource
normalAlreadyPresent
resourceLimitExceeded
normalNotRepresentable
undefinedNormal
cancelled
publicationFailed
```

Admission order is: task cancellation; four positive ceilings; structural
source identity/provenance correspondence; source counts against their
ceilings; existing-attribute scan; checked additional-byte calculation and
ceiling; then allocation. The attribute scan checks cancellation before
attribute zero and every attribute ordinal divisible by 4,096; cancellation at
a poll precedes discovering a built-in normal at that ordinal.

Triangle traversal checks cancellation before triangle zero and every triangle
ordinal divisible by 64. At one triangle, edge/cross representability precedes
its corner/component accumulator additions. Vertex traversal checks
cancellation before vertex zero and every vertex ordinal divisible by 4,096;
at one vertex, zero-vector classification precedes normalisation
representability and serialisation. A final cancellation check occurs after
the complete mesh exists and before any result identity or provenance is
constructed. Every failure returns no result aggregate or partial normal
attribute; local working allocations may have existed and are discarded.

Invalid ceilings map to `invalidLimits`; mismatched source claim subject maps
to `invalidSource`; a built-in normal maps to `normalAlreadyPresent`; count,
checked-byte overflow or a valid host ceiling maps to
`resourceLimitExceeded`. Non-finite ordered arithmetic maps to
`normalNotRepresentable`; a zero accumulated vector maps to
`undefinedNormal`; observed task or injected checkpoint cancellation maps to
`cancelled`. Descriptor, attribute, mesh, parameter, identity, provenance or
result-binding construction failure after numerical completion maps to
`publicationFailed`.

## Determinism and accelerated conformance

The CPU reference is serial and stateless. Repeated execution over the same
input bits and claims produces the same output normal bytes and fixed claims.
An accelerated implementation may schedule work differently only if it
reproduces every CPU output component bit-for-bit and the same failure class;
ordinary floating-point tolerance is insufficient because reduction order is
part of the algorithm. No backend buffer, Metal acceleration structure or
rendering normal becomes canonical.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0193-deterministic-vertex-normal-oracle.py`](../progress/evidence/ADR-0193-deterministic-vertex-normal-oracle.py).
It forces each displayed operation through binary64 and records twelve
fixtures:

- a `2 x 3` right-hand triangle producing exact positive Z normals;
- unequal-area positive Z and positive Y faces producing the shared
  normalised sum `(0, 2, 1)`;
- a shared vertex whose ordered Z contributions are `1e16`, `-1e16`, then `1`
  alongside Y `1`, distinguishing the frozen serial topology order from a
  reordered or pairwise reduction;
- a cross product whose separated multiply/subtract result and normalised
  output bits differ from a contracted fused multiply-add;
- reversed winding producing exact negative Z;
- a zero-vector face followed by a valid face;
- a least-subnormal doubled-area component that still normalises to positive Z;
- a YZ triangle proving positive-zero output components;
- opposite-wound cancellation and an isolated vertex, both undefined;
- edge-subtraction overflow; and
- serial accumulated-area overflow.

The registered output is:

```text
fixtureSHA256=1306df51656d104cfacc9cafc5f2fd7910bbe0104e10a435326310d94d6c94fc
normalAttributeBytesSHA256=076b11f527589e716986a14a99ff86590b592b95f948ca6b6309627baff96d17
fixtures=12 successful=8 failures=4
maximumAdditionalByteVertexCount=384307168202282325
triangleCancellationOrdinals=0,64,128,... vertexCancellationOrdinals=0,4096,8192,...
orientation=right-hand-area-weighted zeroComponents=positive
```

Swift conformance is bit-exact for every normal byte and exact for errors,
mesh preservation, parameter digest, claims and checkpoint order. No numeric
tolerance applies. The oracle does not validate Swift allocation lifetime,
copy-on-write behaviour, concurrency, cancellation machinery or provenance
construction.

## Provenance fields

A successful CPU operation records:

- operation token `org.voxelia.op.triangle-mesh-vertex-normal-generation`;
- implementation token
  `org.voxelia.impl.triangle-mesh-vertex-normal-generation.cpu`;
- algorithm `triangle-area-weighted-vertex-normals/binary64-v1`;
- the fixed weighting, degeneracy, accumulation, normalisation, zero-component,
  output-attribute and existing-normal rules from `ADR-0193`; and
- exactly one input with role `source-mesh`, occurrence one, source object
  identity and source provenance parent.

Limits and cancellation cadence are execution policy and do not enter the
parameter digest. Output authority and software identity are separately
caller-supplied. No coordinate, source identifier, normal component, mesh
size, topology or existing attribute enters diagnostics or logs.

## Complexity and exclusions

The numerical reference is
`O(triangleCount + vertexCount + attributeCount)` and uses exactly one
three-binary64 accumulator and one 24-byte output record per vertex as its
governed logical payload. Public result binding may additionally scan the
already-owned existing attribute bytes to prove exact preservation; the
operation reuses those immutable values and does not deliberately copy their
payload buffers. It does not promise a wall-clock throughput or physical
allocator-byte bound.

Face-domain normals, flat-shading vertex duplication, tangent frames, crease
angles, smoothing groups, angle or uniform weighting, topology repair,
manifold classification, orientation repair, mesh measurement, rendering,
Model I/O preparation and backend acceleration remain separate contracts.

## References

- [ADR-0183 - Geometry extraction arc](../architecture/decisions/ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](../architecture/decisions/ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0190 - Scalar surface extraction design](../architecture/decisions/ADR-0190-scalar-surface-extraction-design.md)
- [ADR-0192 - Labelled surface extraction design](../architecture/decisions/ADR-0192-labelled-surface-extraction-design.md)
- [ADR-0193 - Deterministic triangle-mesh vertex normals design](../architecture/decisions/ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
