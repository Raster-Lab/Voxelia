---
document_id: "ADR-0188"
title: "Coordinate-bearing triangle mesh design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-010"
  - "VOX-ERR-001"
  - "VOX-SEC-001"
  - "VOX-SEC-002"
  - "VOX-GEO-001"
  - "VOX-GEO-002"
  - "VOX-GEO-003"
  - "VOX-GEO-004"
  - "VOX-GEO-005"
  - "VOX-GEO-006"
---

# ADR-0188 - Coordinate-bearing triangle mesh design

## Context

Accepted `ADR-0183` makes a canonical validated triangle mesh the first
dependency of the geometry-extraction arc. Accepted `ADR-0184` and implemented
`ADR-0185` supply complete in-bounds independent-triangle topology. Accepted
`ADR-0187` and `CCR-0027` then make Geometry's public dependency on the
Spatial-owned `CoordinateSpaceDescriptor` explicit without duplicating or
re-exporting it.

The remaining boundary must own authoritative three-dimensional `Double`
positions, bind topology and vertex attributes to exactly that vertex domain,
preserve the declared coordinate descriptor, and reject malformed or
overflowing representations before publication. It must not prematurely
select marching-cubes interpolation, normal generation, a durable geometry
wire, content identity, provenance records that are not yet admitted, or a
backend storage protocol. The project owner explicitly approved autonomous
continuation and the resulting governed implementation work on 2026-08-05.

## Decision

1. **The first canonical value is an owned triangle-mesh payload.**
   `TriangleMesh` is an immutable, `Sendable`, backend-neutral value composed
   of one `TriangleMeshPositionDomain`, one `TriangleMeshTopology` and an
   ordered collection of zero or more `TriangleMeshVertexAttribute` values.
   It contains no Metal, RealityKit, Model I/O, DICOMKit, mapping or mutable
   residency handle. It is the geometry payload used by later operations, not
   the unresolved provenance/identity-bearing `MeshData` publication wrapper.
2. **The position domain owns exact finite binary64 triples and its space.**
   `TriangleMeshPositionDomain` stores a
   `ContiguousArray<Double>` in flattened `(x, y, z)` order and the exact
   Spatial-owned `CoordinateSpaceDescriptor` applying to every triple.
   `vertexCount` is the exact component count divided by three. Empty
   positions are valid. Construction first rejects an incomplete triple, then
   rejects the first NaN or infinity in input order. It does not transform,
   clamp, quantise or canonicalise values; in particular, the sign bit of zero
   is preserved.
3. **Topology and vertex attributes remain independent domains.**
   `TriangleMesh` requires `topology.vertexCount == positions.vertexCount` but
   stores the two values independently. The mandatory position domain is not
   duplicated as a generic attribute. This specialises the baseline's required
   position attribute into the authoritative binary64 position value while
   retaining general non-position vertex attributes separately.
4. **A vertex attribute owns one descriptor and exact logical scalar bytes.**
   `TriangleMeshVertexAttribute` combines an existing
   `GeometryAttributeDescriptor` with a `ContiguousArray<UInt8>`. The
   `.position` semantic is reserved for the position domain and rejects.
   `.interleaved` bytes are ordered element-major then component-major;
   `.planar` bytes are component-major then element-major. Each scalar uses
   the descriptor's declared `ScalarFormat.byteOrder`. `.storageDefined`
   rejects because an immutable logical payload cannot leave ordering
   ambiguous. Valid-bit metadata and every supplied byte are preserved; this
   boundary performs no scalar conversion and does not infer whether arbitrary
   non-position floating values are scientifically missing or invalid.
5. **Attribute byte requirements are exact and overflow checked.** The required
   byte count is
   `elementCount * components.count * scalarFormat.type.byteCount`, evaluated
   with checked `Int` multiplication. Overflow rejects before comparing the
   supplied byte count. An ordinary count mismatch then rejects. Zero elements
   require zero bytes. The owning operation remains responsible for applying a
   host resource budget before allocating these already-materialised arrays;
   this value introduces no arbitrary global memory ceiling or hidden fallback.
6. **Mesh binding has deterministic fail-closed precedence.** Construction
   checks the topology/position vertex count first, attribute element counts in
   input order second, and exact duplicate semantics in input order third. All
   attributes in this first payload are vertex-domain attributes, so every
   descriptor's `elementCount` must equal `positions.vertexCount`. Built-in
   semantics and custom namespace/name pairs use the existing exact semantic
   equality. Attribute order, bytes and semantics are preserved; no sorting,
   deduplication or implicit interpolation occurs.
7. **Admission errors are typed, public and payload-free.** Position failures
   are `TriangleMeshPositionDomainError.incompleteVertex` and
   `.nonFinitePosition`. Attribute failures are
   `TriangleMeshVertexAttributeError.positionSemanticReserved`,
   `.undefinedComponentLayout`, `.byteCountOverflow` and
   `.byteCountMismatch`. Mesh failures are
   `TriangleMeshError.vertexCountMismatch`, `.attributeCountMismatch` and
   `.duplicateAttributeSemantic`. Diagnostics therefore disclose no
   coordinates, counts, indices, semantic names or byte contents.
8. **Identity and persistence are deliberately not claimed.** The three new
   values are `Sendable` but not `Hashable` or `Codable`. Their arrays preserve
   admitted in-memory representation exactly, but signed-zero treatment,
   canonical byte projection, metadata, provenance, durable geometry storage
   and content identity require separately accepted contracts. The computed
   `TriangleMesh.coordinateSpace` is only the exact position-domain descriptor;
   identifier equality never implies transform equivalence.
9. **Implementation and extraction semantics remain separate.** The following
   increment adds only these values, documentation and focused tests. It does
   not select a case table, equality convention, ambiguity rule, interpolation
   formula, extraction order, normal policy, measurement algorithm or
   acceleration representation. A later coordinate transform must publish a
   new position domain and mesh; this API provides no relabelling operation.

## Alternatives considered

### Store positions as a generic raw-byte attribute

This would make the authoritative extraction precision and finite-value rule
dependent on a descriptor/storage pairing and would permit a mesh without an
immediately usable binary64 position domain. A specialised owned position value
keeps the scientific invariant explicit while general attributes retain their
declared scalar representation.

### Store every attribute in typed Swift arrays

An enum covering each scalar type would still need to reconcile source byte
order, valid-bit metadata and planar layout, and would encourage silent
conversion into host-native values. Exact owned bytes plus the existing
descriptor preserve representation without exposing a backend buffer.

### Permit `storageDefined` attributes

The case is useful for external or backend storage descriptors, but an owned
canonical logical payload needs a deterministic component order. Accepting it
here would make identical bytes ambiguous and would defer malformed-input
detection to consumers.

### Add metadata, provenance and content identity now

The baseline sketches those fields, but their prerequisite Core contracts
remain separately governed. Placeholder strings or provisional digests would
create a false publication claim and block later atomic provenance design.

### Canonicalise signed zero or claim `Hashable` identity

Canonicalising would rewrite admitted authoritative input, while ordinary
`Double` hashing treats signed zeros as equal even though their exact bits are
preserved. This boundary therefore makes no hash/content identity claim.

## Consequences

Geometry gains one complete, coordinate-bearing, immutable triangle payload
that later scalar and labelled extraction can construct without backend types.
Every topology reference is already checked by `TriangleMeshTopology`; every
position is finite; every non-position attribute has exact size and vertex
cardinality; and one validated Spatial descriptor applies to all positions.

General point/line/polygon models, non-vertex interpolation domains and the
provenance-bearing mesh publication aggregate remain future work. Attribute
semantic-specific numeric rules also remain with the operation that produces
or consumes each attribute rather than being guessed by this container.

## Affected modules

`VoxeliaGeometry` consumes public descriptor values from `VoxeliaCore` and
`VoxeliaSpatial`. Its focused test target gains an explicit Spatial dependency
to construct coordinate descriptors without relying on re-export.

## Compatibility impact

Additive public API before 1.0. Existing topology and attribute descriptors are
unchanged. No symbol is moved or re-exported.

## Security impact

All derived byte products are overflow checked, structural failures occur
before publication, and every new public error is payload-free. The values do
not log, serialize or expose patient-identifying context.

## Performance and memory impact

Position admission is one linear finite-value scan. Attribute admission uses
constant-time checked arithmetic and a byte-count comparison. Mesh admission is
one linear pass over attributes with a set of semantics for duplicate
detection. Supplied `ContiguousArray` values are retained under Swift value
semantics; no deliberate duplicate or hidden conversion buffer is allocated.

## Validation impact

The implementation must prove empty and ordinary position admission, fixed
position error precedence, NaN/infinity rejection, signed-zero preservation,
both defined component layouts, exact byte-size and overflow rejection,
reserved-position rejection, empty attributes, all mesh-binding precedence,
exact attribute order/bytes, coordinate descriptor preservation, and
`Sendable` transfer. The owning target and its direct dependants must compile
under strict memory safety and warnings-as-errors.

## Migration

1. Add the three values and their payload-free error enums exactly as frozen.
2. Give `VoxeliaGeometryTests` an explicit `VoxeliaSpatial` dependency.
3. Add focused numerical, malformed-input, overflow, binding and concurrency
   tests plus public API documentation.
4. Validate Geometry and direct dependants, update integrity evidence, then
   resume the separately frozen scalar-extraction numeric model.

## Supersession

This record implements no prior type directly and supersedes no accepted
record. It composes `ADR-0183` through `ADR-0187` and supplies the complete mesh
payload boundary required before scalar extraction can be specified.

## References

- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0184 - Triangle mesh topology design](ADR-0184-triangle-mesh-topology-design.md)
- [ADR-0185 - Triangle mesh topology](ADR-0185-triangle-mesh-topology.md)
- [ADR-0187 - Geometry coordinate-space dependency](ADR-0187-geometry-coordinate-space-dependency.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
