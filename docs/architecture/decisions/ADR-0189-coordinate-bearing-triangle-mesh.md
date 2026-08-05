---
document_id: "ADR-0189"
title: "Coordinate-bearing triangle mesh"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
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
---

# ADR-0189 - Coordinate-bearing triangle mesh

## Context

Accepted `ADR-0188` froze the first complete canonical triangle-mesh payload
after the Geometry-to-Spatial dependency was made explicit. This record
implements that payload without selecting scalar extraction, provenance
publication, stable geometry bytes or a backend representation. It was
authored and accepted on 2026-08-05 under the project owner's explicit broad
approval to continue the governed roadmap and push verified increments.

## Decision

1. **`TriangleMeshPositionDomain` owns exact finite position triples and their
   space.** It stores one Spatial-owned `CoordinateSpaceDescriptor` and one
   flattened `ContiguousArray<Double>` in `(x, y, z)` order. Empty domains are
   valid. Incomplete triples reject before non-finite components, and admitted
   binary64 bits, including signed zero, are preserved without normalization.
2. **`TriangleMeshVertexAttribute` owns exact descriptor-sized bytes.** The
   generic position semantic and `storageDefined` layout reject before checked
   byte arithmetic. Element/component and scalar-byte products use
   `multipliedReportingOverflow`; exact count mismatch rejects only after both
   products fit. Interleaved and planar ordering and declared scalar byte order
   are the only admitted layouts, with no scalar conversion.
3. **`TriangleMesh` binds independently owned domains.** Topology and position
   vertex counts must agree; every generic attribute must then match that
   vertex count; exact duplicate semantics reject last. Positions, topology,
   attribute order and bytes remain unchanged. `coordinateSpace` projects the
   exact position-domain descriptor rather than a copied identifier.
4. **All new state is immutable and compiler-verified `Sendable`.** The three
   error enums are also `Sendable`, `Equatable` and payload-free. No unchecked
   conformance, unsafe memory access, lock, actor or mutable service is added.
5. **The identity boundary stays closed.** The three new values deliberately
   omit `Hashable` and `Codable`; they claim neither canonical bytes nor content
   identity. The public documentation states ownership, validation precedence,
   concurrency behavior, exact numeric preservation, performance and deferred
   provenance/storage boundaries.
6. **Tests import Spatial explicitly.** `VoxeliaGeometryTests` declares its
   direct `VoxeliaSpatial` dependency to construct coordinate descriptors; no
   module re-export is introduced.

## Alternatives considered

The alternatives and rejection reasons are frozen in `ADR-0188`; implementation
exposed no new product choice. A symbol-graph attempt using a nonexistent
per-target `swift package dump-symbol-graph --target` option failed before
work, so the supported package-wide public symbol-graph command was used and
completed successfully instead of inventing a custom extractor invocation.

## Consequences

Later scalar and labelled extraction specifications now have a complete,
backend-neutral mesh payload to publish once their numerical and provenance
contracts are accepted. Consumers can rely on finite coordinate-bearing
positions, complete in-bounds topology and exact vertex-attribute
cardinality/byte size before seeing a mesh.

The implementation does not itself prove extraction correctness, define
semantic-specific attribute values, admit non-vertex interpolation domains or
satisfy the future provenance-bearing `MeshData` aggregate.

## Affected modules

`VoxeliaGeometry` gains the three public values and their errors.
`VoxeliaGeometryTests` gains an explicit dependency on `VoxeliaSpatial`.
Rendering, CPU and the umbrella remain source-compatible direct consumers.

## Compatibility impact

Additive public API before 1.0. Existing geometry types and their encoding or
identity remain unchanged.

## Security impact

Both attribute-size multiplications are overflow checked, malformed domains
fail before publication, and errors contain no coordinates, counts, indices,
semantics or bytes. No unsafe memory operation or logging is added.

## Performance and memory impact

Position construction is one linear finite-value scan. Attribute construction
uses constant-time checked arithmetic. Mesh construction is two linear passes
over attributes, with one semantic set for duplicate detection. Supplied arrays
are retained under Swift copy-on-write value semantics; the implementation
performs no deliberate payload copy or scalar-conversion allocation.

## Validation impact

The strict focused `TriangleMeshTests` suite executes seven tests covering
empty and ordinary domains, signed-zero bit preservation, incomplete-before-
finite precedence, NaN and both infinities, interleaved/planar and empty
attributes, reserved position/layout precedence, both multiplication-overflow
stages, exact byte mismatch, ordinary and empty mesh binding, all mesh error
precedence and an actual detached-task transfer. The complete strict
`VoxeliaGeometryTests` selection executes 30 tests across four suites with zero
failures, retaining all topology, descriptor and taxonomy evidence.

Strict-memory-safety and warnings-as-errors builds pass for Geometry, Rendering,
CPU and the umbrella in both debug and release. Dynamic/static package-graph,
prohibited-import, raw Swift-safety, strict format, diff and package-wide public
symbol-graph generation checks pass. The repository-wide semantic compilation
gate and complete suite are not rerun because the focused module and direct-
dependant gates cover this additive boundary; their last recorded green status
is not promoted to new evidence.

The authorised independent reviewer inspected the implementation/API/docs
diff and issued final approval with no blocking finding. Their separate strict
`TriangleMesh` filter executed all 14 new mesh and existing topology tests with
zero failures; their dynamic/static graph, prohibited-import, documentation,
raw safety and diff checks also passed. A separate compiler probe confirmed
that importing Geometry does not re-export the Spatial-owned coordinate type,
while the public mesh remains consumable.

## Migration

Complete in this record. No caller migration is required because the API is
additive.

## Supersession

Implements accepted `ADR-0188`; no record is superseded.

## References

- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0184 - Triangle mesh topology design](ADR-0184-triangle-mesh-topology-design.md)
- [ADR-0185 - Triangle mesh topology](ADR-0185-triangle-mesh-topology.md)
- [ADR-0187 - Geometry coordinate-space dependency](ADR-0187-geometry-coordinate-space-dependency.md)
- [ADR-0188 - Coordinate-bearing triangle mesh design](ADR-0188-coordinate-bearing-triangle-mesh-design.md)
