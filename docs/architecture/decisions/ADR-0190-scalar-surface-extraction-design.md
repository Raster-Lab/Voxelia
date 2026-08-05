---
document_id: "ADR-0190"
title: "Scalar surface extraction design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-010"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-CPU-006"
  - "VOX-ERR-001"
  - "VOX-SEC-001"
  - "VOX-SEC-002"
  - "VOX-SEC-011"
  - "VOX-META-003"
  - "VOX-META-004"
  - "VOX-META-005"
  - "VOX-META-006"
  - "VOX-GEO-006"
  - "VOX-GEO-007"
  - "VOX-GEO-008"
  - "VOX-GEO-011"
---

# ADR-0190 - Scalar surface extraction design

## Context

Accepted `ADR-0183` requires the geometry arc to select an exact marching-
cubes-class reference before implementation. Accepted `ADR-0188` and
implemented `ADR-0189` now provide the immutable finite binary64 position,
checked topology, attribute and coordinate-space payload that the reference
will publish. The remaining numerical choices are observable: equality at the
isovalue, cube ambiguity, boundary treatment, interpolation arithmetic, vertex
welding, output order, spatial winding, limits and cancellation all change the
mesh or its failure classification.

A conventional 256-case cube table alone does not settle face/interior
ambiguity. MC33 or an asymptotic decider would settle it but would introduce a
substantially larger first reference, more data-dependent branches and a table
provenance burden before the project has one extraction implementation.
Accepted `ADR-0183` explicitly identified marching tetrahedra as a possible
marching-cubes-class method whose diagonal and topology still required this
separate specification. The project owner has authorised continued autonomous
governance and verified pushes; this record was authored and accepted under
that authority on 2026-08-05.

## Decision

1. **The first reference is the global Freudenthal marching-tetrahedra
   decomposition.** `VOXELIA-ALG-0028` freezes six positively oriented
   tetrahedra per sample-centre cube and one exhaustive 16-case table. Adjacent
   cubes share the same face diagonals, so face and interior ambiguity is
   resolved structurally, without an asymptotic decider or data-dependent
   diagonal. This is the initial validated marching-cubes-class capability for
   `VOX-GEO-008`; classic 256-case marching cubes, MC33 and flying edges remain
   future implementations rather than aliases for this identity.
2. **The model consumes authoritative scalar values.** The numerical kernel
   sees one complete finite binary64 scalar per rank-three, one-component image
   index after storage decoding and the accepted value-transform chain. The
   finite isovalue is interpreted in that authoritative source unit. Stored
   padding, missing values, label membership, presentation windows and transfer
   functions never enter interpolation. Unsupported or failed upstream
   conversion rejects rather than treating a sentinel or display value as
   scientific input.
3. **Classification and boundaries are exact.** A vertex is inside iff
   `sample >= isovalue`; equality uses exact binary64 comparison and no epsilon.
   Only complete cells between sample centres are visited. There is no ghost
   exterior, extrapolation or automatic cap, so a source-boundary surface stays
   open. Any axis extent below two returns the valid empty mesh.
4. **Interpolation has one versioned arithmetic sequence.** Edge endpoints are
   ordered by global axis-zero-fastest sample ordinal. Exact-isovalue endpoints
   snap to one sample key. All other crossings use direct binary64 subtraction,
   division and component interpolation in the exact `ALG-0028` order.
   Non-finite intermediates, endpoint underflow or out-of-range `t` reject
   payload-free; there is no clamp, algebraic fallback or rescaling. This makes
   extreme-range failure reproducible rather than platform-dependent.
5. **Vertex and topology identity is deterministic.** Cells traverse axis zero
   fastest, then the six tetrahedra and case-table triples in frozen order.
   Exact sample/edge keys deduplicate across tetrahedra and adjacent cells.
   Repeated-key triangles caused by equality snapping are omitted before any
   vertex is published; other degeneracy is retained for the later normal and
   measurement contracts. First non-omitted reference fixes vertex order, and
   table order fixes every `UInt64` index.
6. **World positions preserve source space and physical winding.** Image
   coordinates map through the exact source `SpatialAxisMapping` and affine
   row evaluation in binary64. Every intermediate/result must be finite. The
   source's complete `CoordinateSpaceDescriptor` is retained. The table winds
   from inside toward outside; triangle order flips exactly when the affine
   determinant sign composed with mapping-permutation parity is negative, so a
   reflected/permuted geometry preserves physical winding.
7. **Limits and cancellation are part of the reference contract.** The host
   supplies explicit positive maximum vertex and triangle counts with no hidden default.
   Cell/output arithmetic is checked before allocation or append; the key map
   contains at most one entry per admitted vertex. Cancellation is observed at
   admission, before every canonical block of 64 cells and immediately before
   atomic publication. Limit, numerical, read, cancellation or publication
   failure publishes no partial mesh, identity or provenance.
8. **Errors and precision are closed.** The implementing public error family
   has the ten payload-free semantic cases frozen in `ALG-0028`, including
   distinct source, numerical, resource, cancellation and publication
   categories. The arithmetic is IEEE-754 binary64 round-to-nearest-ties-to-
   even with gradual subnormals and without fast math, reassociation, FMA
   substitution or flush-to-zero.
9. **Successful publication binds reproducibility claims.** The Core-compatible
   operation token, corrected by `ADR-0191`, is
   `org.voxelia.op.scalar-surface-extraction`; algorithm identity is
   `freudenthal-surface-extraction/binary64-v1`. The parameter digest binds the
   finite isovalue and fixed algorithm/rule tokens, and provenance contains one
   ordered `source-volume` input at Core's first valid occurrence (`1`) plus
   exact implementation/software/execution claims. Resource limits and
   cancellation cadence are execution policy and cannot alter a successful
   mesh. Logs and errors exclude isovalues, coordinates, identities and source
   metadata.
10. **This increment is design and independent oracle only.** It adds no public
    extraction type, source reader, operation, cache integration or publisher.
    The CPU reference follows separately and must reproduce every registered
    position bit pattern, index and failure class before any accelerated
    implementation can be admitted.

## Alternatives considered

### Conventional 256-case marching cubes

The compact table is familiar and usually emits fewer triangles, but the table
does not resolve ambiguous faces/interiors or define equality, vertex welding
and output order. Selecting a particular external table without a complete
provenance/licence and ambiguity contract would produce plausible but
non-reproducible topology.

### MC33 or asymptotic-decider marching cubes

These methods address topology more directly and remain candidates for a
future implementation. They require additional subcase tables, decider
evaluation order and degenerate saddle fixtures. The simpler global simplicial
reference gives the project a fully enumerable oracle first; an MC33
implementation can then differential-test geometry/field equivalence while
retaining its distinct topology identity.

### Alternating tetrahedral diagonals

Alternation can reduce directional bias but needs a parity rule that becomes
part of seams, case identity and provenance. One global Freudenthal
triangulation is simpler, shared-face conforming and exhaustively enumerable.
Its bias is documented rather than hidden.

### Numerically rescale an overflowing interpolation

An alternate expression could recover some extreme finite crossings, but it
would change the versioned binary64 result and failure domain. Version one
rejects direct-expression overflow honestly. A robustly scaled model would
need a new algorithm identity and independent error analysis.

### Cap the volume boundary automatically

Inventing exterior scalar values would create geometry not present in the
source and make volume/area measurements depend on a hidden policy. Version one
extracts only complete source cells; an explicit capping operation can be
specified later.

## Consequences

The project has a complete, table-sized numerical authority for the initial
scalar surface reference. Every binary cube mask, ambiguous configuration,
equality point, shared-face seam, reflected mapping and output ordering rule is
deterministic. The trade-off is a fixed diagonal bias and potentially more
triangles than classic marching cubes; neither is concealed as an optimisation.

The numeric kernel is independent of storage layout and backend, but the CPU
implementation still has to freeze its exact source-format/value-transform
adapter and atomic identity/provenance publication composition. Labelled
extraction remains separate because integer membership has no scalar
interpolation.

## Affected modules

Documentation and an independent Python exact-rational oracle only in this
increment. The implementing increment affects `VoxeliaGeometry` for the public
operation contract and `VoxeliaCPU` for the reference implementation, composing
Core/Storage/Execution publication boundaries without introducing a reverse
dependency.

## Compatibility impact

None in this increment. The later operation API is additive before 1.0. A
different diagonal, table, arithmetic sequence or equality rule requires a new
algorithm version and may not silently replace `binary64-v1`.

## Security impact

The design requires checked cell/output arithmetic, explicit host limits,
bounded key state, periodic cancellation, no partial publication and ten
payload-free failures. No executable product source, unsafe Swift or external
dependency is added here.

## Performance and memory impact

The reference is linear in cell count plus emitted triangles. Per-cell work is
bounded by six tetrahedra and at most twelve triangles; exhaustive binary masks
reach at most thirteen vertices for one cube. The retained key map is bounded
by the caller's vertex limit. No performance guarantee or benchmark result is
claimed before the CPU reference exists.

## Validation impact

The independent exact-rational oracle validates positive tetrahedron
orientation, the complete 16-case table and outward winding; exhausts all 256
binary cube masks; verifies every triangle index; proves shared-face conformity,
sample-key equality collapse and reflected winding; and pins the exact
single-corner positions/topology. Its canonical 256-mask fixture digest is
`4bed958ac7d25a4539de8a0cea28524271a89303c3e9e3fb0de0d311e5c6931d`.
The oracle is evidence for the frozen topology/rational fixtures only, not a
Swift implementation, storage adapter, binary64 differential suite or
publication/cancellation proof.

The CPU increment must add bit-exact dyadic and extreme-range tests, all source
admission and error precedence, limit edges, cancellation at every cadence
boundary, stale/no-partial publication, source coordinate mapping and complete
oracle differential coverage. Accelerated implementations require full
differential evidence against that CPU reference.

## Migration

1. Add the immutable request/limit/error/result contract in Geometry without a
   backend type or public mutable state.
2. Add the CPU reference over the accepted bounded storage read/value-transform
   path with atomic mesh/identity/provenance publication.
3. Reproduce the independent fixtures and all 256 masks bit-exactly, then add
   malformed input, overflow, cancellation, memory-limit and repetition tests.
4. Register the exact operation/implementation/parameter schema only after the
   result publication evidence is green.
5. Resume separately frozen labelled extraction, deterministic normals,
   authoritative measurement and derived acceleration.

## Supersession

This record executes the scalar-reference design step of `ADR-0183` and composes
`ADR-0188`/`ADR-0189`; it supersedes no accepted record.

## References

- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0188 - Coordinate-bearing triangle mesh design](ADR-0188-coordinate-bearing-triangle-mesh-design.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [VOXELIA-ALG-0028 - Freudenthal scalar-surface extraction binary64-v1](../../algorithms/VOXELIA-ALG-0028-freudenthal-surface-extraction.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
