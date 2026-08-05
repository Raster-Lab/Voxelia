---
document_id: "ADR-0184"
title: "Triangle mesh topology design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-GEO-003"
  - "VOX-GEO-005"
---

# ADR-0184 - Triangle mesh topology design

## Context

Accepted `ADR-0183` makes the canonical triangle mesh the geometry arc's first
dependency. Auditing that boundary exposed a pre-existing graph conflict: the
MTA and CDMS require mesh positions to declare a Spatial-owned coordinate
space, while the approved package graph permits only `VoxeliaGeometry ->
VoxeliaCore` and Core does not re-export `VoxeliaSpatial` types. Adding an
undeclared direct import, duplicating the coordinate type or weakening it to a
string would violate the accepted boundary. The full mesh aggregate therefore
needs its own dependency-resolution decision.

The topology half is independent and unblocked. `VOX-GEO-003` requires topology
to remain separate from vertex attributes, and `VOX-GEO-005` requires every
index to be validated before use. This record freezes that value before
implementation. It was authored and accepted on 2026-08-05 under the project
owner's continuation mandate.

## Decision

1. **`TriangleMeshTopology` is the immutable logical topology value.** It owns
   a nonnegative `vertexCount` and one `ContiguousArray<UInt64>` of flattened
   independent-triangle indices. Every consecutive triple is one triangle;
   `triangleCount` is the exact `indices.count / 3` projection. The logical
   `UInt64` domain is independent of the `IndexType` chosen later for a physical
   buffer, so representation width never changes topology identity.
2. **Admission is fail-closed with fixed precedence.** A negative vertex count
   rejects first, an index count not divisible by three rejects second, then
   the first index greater than or equal to `vertexCount` rejects. The public
   `TriangleMeshTopologyError` has the corresponding payload-free cases
   `negativeVertexCount`, `incompleteTriangle` and `indexOutOfBounds`; errors
   never disclose counts or indices.
3. **The empty topology is valid.** Zero vertices and zero indices represent a
   legitimate no-surface extraction result. A nonempty index sequence against
   zero vertices fails bounds admission normally.
4. **Admission validates structure, not geometry.** Repeated indices,
   degenerate triangles, duplicate triangles, winding and manifoldness are not
   silently rewritten or rejected. Their meaning depends on the separately
   frozen extraction and normal models. This value preserves exact input order
   and multiplicity.
5. **No stable wire is claimed.** The value is `Sendable` and `Hashable`, but
   not `Codable`; canonical mesh bytes, content projection and durable geometry
   storage remain future contracts. Construction stores the supplied immutable
   `ContiguousArray` value after one linear validation pass and performs no
   hidden allocation or canonicalisation.
6. **Implementation follows separately** in `VoxeliaGeometry` with focused
   boundary, precedence, identity and concurrency tests. The full mesh binding
   remains blocked until the coordinate-space dependency is resolved without
   violating the package graph.

## Alternatives considered

Using `Int` indices was rejected because logical topology would then vary with
the host integer width and could not represent the already-declared `uint64`
index domain. Storing three indices in a `Triangle` element was rejected because
it would add one more public collection shape without improving validation or
iteration. Rejecting degenerate triples was rejected because topology validity
and geometric degeneracy are different decisions; the normal model must state
how it handles them. Adding the Spatial dependency in this record was rejected
because a module-boundary revision requires explicit graph governance and
downstream validation, not an incidental implementation convenience.

## Consequences

The geometry arc gains its checked, representation-neutral topology primitive
without crossing the unresolved module boundary. A marching-cubes-class
implementation can rely on complete in-bounds triples once the full mesh
binding is authorised.

## Affected modules

Documentation only in this increment; `VoxeliaGeometry` in the implementing
increment.

## Compatibility impact

None in this increment. The implementing value is additive before 1.0.

## Security impact

Failures are payload-free. Every index is inspected before publication, so an
adapter never receives unchecked topology from this value.

## Performance and memory impact

Construction is one linear pass over indices with constant auxiliary storage.
The caller-supplied array is retained as an immutable value; no duplicate
topology buffer is allocated by the initializer.

## Validation impact

The implementation must prove empty and nonempty admission, all three error
cases and their precedence, the `UInt64` upper boundary, preservation of input
order and degenerate triples, exact equality/hashing and `Sendable` conformance.

## Migration

None; implementation follows as `ADR-0185`.

## Supersession

Executes the independently unblocked topology prerequisite of `ADR-0183`; no
record is superseded.

## References

- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
