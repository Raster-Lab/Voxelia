# CCR-0027 - Controlled correction for ADR-0187 Geometry-Spatial dependency

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0027` |
| Authority | Accepted [`ADR-0187`](../decisions/ADR-0187-geometry-coordinate-space-dependency.md) |
| Approved by | Project owner |
| Approval date | 2026-08-05 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled graph correction required by accepted
`ADR-0187`. The v0.1.1 baseline files remain immutable; this record is
authoritative wherever the exact dependency rows below conflict with them.

## Corrections

### CCR-0027-A - MTA section 8 dependency graph

The MTA section 8.1 edge:

> `Geometry --> Core`

is supplemented by:

> `Geometry --> Spatial`

`VoxeliaGeometry` therefore directly depends on both `VoxeliaCore` and
`VoxeliaSpatial`. The edge direction remains specialised-to-foundational and
introduces no cycle. Section 8.2 ownership remains unchanged: Spatial solely
owns coordinate-space descriptors, and Geometry solely owns meshes and
geometry operations.

### CCR-0027-B - RPSS section 13 and package sketch

The RPSS section 13.1 graph and section 14 package sketch are corrected so the
Geometry target declares both dependencies:

> `.target(name: "VoxeliaGeometry", dependencies: ["VoxeliaCore", "VoxeliaSpatial"])`

All other production edges remain unchanged.

### CCR-0027-C - RPSS Appendix B matrix

The baseline row:

> | `VoxeliaGeometry` | `VoxeliaCore` |

is corrected to:

> | `VoxeliaGeometry` | `VoxeliaCore`, `VoxeliaSpatial` |

The exact dynamic and static graph checkers enforce this corrected row and
continue to reject every unexpected edge and cycle.

## Scope and limits

- No type moves between modules, and Core does not redeclare or re-export a
  Spatial type.
- Geometry consumes the exact Spatial-owned `CoordinateSpaceDescriptor`; no
  string, alias, wrapper or duplicate identifier is authorised.
- This correction does not freeze or implement the complete mesh aggregate,
  storage, wire, identity, provenance or extraction numeric model.
- Historical `docs/releases/v0.1.1/` graph evidence remains an immutable record
  of that release. A later release candidate must record the corrected edge.
- No other dependency, product, external package or platform policy changes.

## References

- [ADR-0187 - Geometry coordinate-space dependency](../decisions/ADR-0187-geometry-coordinate-space-dependency.md)
- [Voxelia Master Technical Architecture v0.1.1, section 8](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1, sections 13-14 and Appendix B](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
