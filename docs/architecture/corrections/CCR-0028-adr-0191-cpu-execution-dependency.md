# CCR-0028 - Controlled correction for ADR-0191 CPU-Execution dependency

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0028` |
| Authority | Accepted [`ADR-0191`](../decisions/ADR-0191-scalar-surface-operation-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-05 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled graph correction required by accepted
`ADR-0191`. The v0.1.1 baseline files remain immutable; this record is
authoritative wherever the exact dependency rows below conflict with them.

## Corrections

### CCR-0028-A - MTA section 8 dependency graph

The MTA section 8.1 path:

> `CPU --> Imaging --> Execution`

is supplemented by the explicit public-API dependency:

> `CPU --> Execution`

`VoxeliaCPU` therefore directly depends on `VoxeliaImaging`,
`VoxeliaGeometry` and `VoxeliaExecution`. The explicit redundant edge records
CPU public APIs that consume Execution-owned operation coordination and
registration values. It introduces no cycle because Execution has no path to
CPU. Section 8.2 ownership remains unchanged: Execution solely owns scheduling,
bounded read coordination and registration, while CPU solely owns reference
kernels and CPU backend registration.

### CCR-0028-B - RPSS section 13 and package sketch

The RPSS section 13.1 graph and section 14 package sketch are corrected so the
CPU target declares all three dependencies:

> `.target(name: "VoxeliaCPU", dependencies: ["VoxeliaImaging", "VoxeliaGeometry", "VoxeliaExecution"])`

All other production edges remain unchanged.

### CCR-0028-C - RPSS Appendix B matrix

The baseline row:

> | `VoxeliaCPU` | `VoxeliaImaging`, `VoxeliaGeometry` |

is corrected to:

> | `VoxeliaCPU` | `VoxeliaImaging`, `VoxeliaGeometry`, `VoxeliaExecution` |

The exact dynamic and static graph checkers enforce this corrected row and
continue to reject every unexpected edge and cycle.

## Scope and limits

- No operation, coordinator, registry or kernel type moves between modules.
- CPU may consume the exact Execution-owned `StorageReadCoordinator` and
  implementation-registration values; it does not re-export, duplicate or
  mutate their semantics.
- This correction does not add the scalar-surface request, reader, kernel,
  publication result or CPU registration source.
- Historical `docs/releases/v0.1.1/` graph evidence remains an immutable record
  of that release. A later release candidate must record the corrected edge.
- No other dependency, product, external package or platform policy changes.

## References

- [ADR-0191 - Scalar surface operation and publication boundary](../decisions/ADR-0191-scalar-surface-operation-boundary.md)
- [Voxelia Master Technical Architecture v0.1.1, section 8](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1, sections 13-14 and Appendix B](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
