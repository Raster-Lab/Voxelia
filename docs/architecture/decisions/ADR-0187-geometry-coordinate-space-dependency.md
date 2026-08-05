---
document_id: "ADR-0187"
title: "Geometry coordinate-space dependency"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-REP-006"
  - "VOX-REP-010"
  - "VOX-ARC-001"
  - "VOX-ARC-002"
  - "VOX-ARC-007"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-GEO-001"
  - "VOX-GEO-002"
  - "VOX-GEO-006"
---

# ADR-0187 - Geometry coordinate-space dependency

## Context

Accepted `ADR-0183` requires the canonical triangle mesh to publish `Double`
positions in an explicit coordinate space. The Requirements Baseline assigns
coordinate spaces to `VoxeliaSpatial` (`VOX-ARC-002`) and meshes to
`VoxeliaGeometry` (`VOX-ARC-007`); `VOX-GEO-002` requires every geometry
position domain to declare its space. The MTA and CDMS mesh sketches bind a
`CoordinateSpaceDescriptor`, not an unvalidated string or presentation label.
Accepted `ADR-0043` implements that descriptor in `VoxeliaSpatial` with exact
length-unit, convention, handedness and external-reference admission.

The approved M0 package graph gives `VoxeliaGeometry` one direct dependency,
`VoxeliaCore`, while `VoxeliaCore` directly depends on `VoxeliaSpatial`.
Geometry already needs Core-owned scalar/component descriptors and later needs
Core-owned metadata, identity and provenance. Core deliberately does not
redeclare or re-export Spatial types under accepted `ADR-0021`. Relying on the
transitive implementation path to import `VoxeliaSpatial` would hide a public
API dependency that the manifest, module documentation and fail-closed graph
checkers all claim does not exist.

Accepted `ADR-0184` therefore separated the independently valid logical
topology, implemented by `ADR-0185`, and blocked the coordinate-bearing mesh on
this explicit graph decision. The remaining conflict cannot be resolved by an
incidental import, a duplicate identifier, a Core type alias or a weakened
string field. The project owner explicitly approved this smallest acyclic graph
correction on 2026-08-05 and authorised the governed implementation work.

## Decision

1. **Geometry gains one explicit foundational edge.** The production target
   will depend directly on both `VoxeliaCore` and `VoxeliaSpatial`:

   ```text
   VoxeliaGeometry -> VoxeliaCore
   VoxeliaGeometry -> VoxeliaSpatial
   VoxeliaCore     -> VoxeliaSpatial
   ```

   This is an intentional redundant reachability edge: Core remains necessary
   for geometry attribute, metadata, identity and provenance values, while the
   direct Spatial edge makes the public coordinate-space dependency explicit.
   It introduces no cycle, package, product or external dependency.
2. **Spatial ownership remains singular.** Canonical Geometry APIs will use the
   exact public `VoxeliaSpatial.CoordinateSpaceDescriptor`. Geometry will not
   duplicate `CoordinateSpaceID`, store an unvalidated string, define a wrapper
   with parallel invariants, add a type alias in Core or Geometry, or treat
   identifier equality as transform equivalence. The descriptor's accepted
   unit, convention, handedness and external-reference semantics remain
   authoritative.
3. **Geometry ownership remains singular.** Mesh aggregates, position domains,
   topology, attributes, geometry operations and measurements remain owned by
   `VoxeliaGeometry`. Nothing moves into Spatial or Core. The position domain
   uses finite `Double` components and binds one descriptor for all positions;
   any later coordinate transform publishes a distinct mesh with an explicit
   source/target relationship rather than relabelling coordinates.
4. **This record fixes only dependency and ownership.** It does not freeze the
   complete mesh aggregate, attribute-domain binding, storage, wire, content
   projection, provenance aggregate, resource ceilings or extraction numeric
   model. Those remain separate design-first increments downstream of
   `ADR-0183` and the implemented `TriangleMeshTopology`.
5. **The graph correction is controlled and fail closed.** `CCR-0027` corrects
   the MTA section 8 graph and the RPSS section
   13 graph, package sketch and Appendix B matrix without editing immutable
   v0.1.1 files. The root manifest, dynamic/static graph checkers, Geometry
   module documentation and current progress evidence change in one migration
   increment. The historical v0.1.1 release graph remains unchanged; the next
   release candidate will record the corrected edge. A test target that
   directly imports Spatial to construct Geometry values will declare that test
   dependency explicitly.
6. **No re-export policy changes.** The focused `VoxeliaGeometry` product still
   exposes Geometry only; adding a target dependency does not re-export Spatial
   declarations or change the umbrella module policy. Consumers construct
   Spatial values through the focused Spatial module as they already do for
   Core image descriptors.

## Alternatives considered

### Import Spatial only through the transitive Core path

This compiles in the current package layout but makes a public API dependency
invisible to the manifest and exact graph checkers. A future Core refactor could
then break Geometry despite no declared edge. Hidden transitive coupling is
rejected in favour of one explicit direct dependency.

### Duplicate or weaken the coordinate-space value in Geometry

A Geometry-owned identifier, string, wrapper or descriptor would split
canonical identity and validation from the Spatial model. An identifier alone
also omits unit, convention, handedness and external references. This violates
`VOX-ARC-002`, `VOX-GEO-002` and the accepted `ADR-0043` boundary.

### Re-export or type-alias Spatial through Core

Core could expose aliases for Spatial values, but accepted `ADR-0021`
deliberately leaves re-export policy separate and forbids redeclaration as an
ownership workaround. It would also hide rather than remove Geometry's actual
dependency on Spatial semantics.

### Move meshes to Core or coordinate spaces to Geometry

Either move contradicts the explicit `VOX-ARC-002` and `VOX-ARC-007` ownership
rows and would expand migration across established public modules. No cycle or
runtime constraint requires such a move.

### Add another shared foundational target

A new target could own identifiers used by Spatial and Geometry, but the full
descriptor still belongs to Spatial and Geometry still needs it. The extra
product and migration surface solve no demonstrated problem.

## Consequences

The package graph gains one visible shortcut from a specialised module to its
foundational spatial model and remains acyclic. Geometry can publish one
canonical coordinate-bearing mesh without duplicated semantics. Because
Spatial is already reachable through Geometry's Core dependency, downstream
package resolution and shipped module set do not grow; only dependency intent
and rebuild invalidation become explicit.

The correction makes Spatial API changes direct compile-time concerns for
Geometry, which is accurate. It also requires coordinated updates to both graph
checkers and governed documentation so no checker is relaxed opportunistically.

## Affected modules

`VoxeliaGeometry` gains the direct dependency and later consumes the
Spatial-owned descriptor. `VoxeliaSpatial` remains unchanged as the owner.
`VoxeliaCore` remains a Geometry dependency and does not re-export Spatial.
Rendering, CPU, validation and the umbrella remain downstream consumers; no
edge from a foundational module to a specialised module is introduced.

## Compatibility impact

The graph change is additive before 1.0 and moves no existing symbol. The
focused Geometry product already brings Spatial transitively through Core, so
the set of package targets resolved by consumers is unchanged. The later mesh
API will expose a Spatial-owned descriptor by design and receives its own
compatibility review before source is added.

## Security impact

No executable code changes in this decision. Retaining the validated descriptor
prevents geometry from silently accepting blank identifiers, non-length units,
contradictory handedness or duplicate external references. Future errors remain
typed and payload-free; coordinate values and external references must not enter
diagnostics by default.

## Performance and memory impact

No runtime or allocation change follows from the dependency decision. The
direct edge may cause Geometry to rebuild when Spatial changes, which reflects
its real public semantic dependency and is already transitively required.

## Validation impact

The acceptance increment requires the ADR/documentation, current dynamic/static
package-graph, prohibited-import, manifest and release-integrity checks only.
It does not claim that the edge or mesh API has been compiled until the separate
graph migration executes.

After acceptance, the graph migration must prove the exact two-dependency
Geometry edge in both graph checkers, cycle freedom, prohibited-import policy,
strict debug/release compilation of Geometry and its direct dependants, and the
unchanged focused-product/umbrella boundary. The later mesh design and
implementation carry coordinate descriptor, finite `Double`, topology,
attribute, overflow, `Sendable`, identity and payload-redaction tests.

## Migration

1. Record the project owner's explicit acceptance of this record (complete).
2. Add `CCR-0027` with the exact MTA/RPSS graph corrections.
3. In one graph-only increment, update `Package.swift`, both package-graph
   checkers, Geometry module documentation, affected test dependency declarations
   and release graph evidence; run the graph and direct-dependant build gates.
4. Design and accept the complete coordinate-bearing canonical triangle mesh
   without yet selecting the extraction numeric model.
5. Implement that mesh and its focused ownership, spatial, numerical, memory
   and concurrency evidence before resuming the scalar extraction contract.

## Supersession

This record supersedes no accepted record. It composes
`ADR-0021`, `ADR-0043`, `ADR-0183`, `ADR-0184` and `ADR-0185` and corrects only
the exact package-graph statements that prevent those ownership decisions from
coexisting.

## References

- [ADR-0021 - Axis model ownership](ADR-0021-axis-model-ownership.md)
- [ADR-0043 - Spatial descriptor admission boundary](ADR-0043-spatial-descriptor-admission-boundary.md)
- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0184 - Triangle mesh topology design](ADR-0184-triangle-mesh-topology-design.md)
- [ADR-0185 - Triangle mesh topology](ADR-0185-triangle-mesh-topology.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
