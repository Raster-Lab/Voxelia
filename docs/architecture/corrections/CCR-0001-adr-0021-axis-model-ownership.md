# CCR-0001 - Controlled correction for ADR-0021 axis-model ownership

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0001` |
| Authority | Accepted [`ADR-0021`](../decisions/ADR-0021-axis-model-ownership.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0021`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected rows verbatim.

## Corrections

### CCR-0001-A - Core Data Model Specification section 6 module ownership

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 6 module-ownership table.

Baseline rows read:

> | Coordinate spaces, units, matrices, planes, rays, bounds and transforms | `VoxeliaSpatial` |
> | Shapes, axes, scalar formats, components, image descriptors, identities, metadata and provenance | `VoxeliaCore` |

Corrected rows read:

> | Coordinate spaces, units, matrices, planes, rays, bounds, transforms and the axis model (`AxisID`, `AxisSemantic`, `AxisSampling`, `AxisDescriptor`) | `VoxeliaSpatial` |
> | Shapes, scalar formats, components, image descriptors (including axis-collection binding validation), identities, metadata and provenance | `VoxeliaCore` |

### CCR-0001-B - Core Data Model Specification Appendix A type inventory

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
Appendix A Core type inventory.

The baseline row reads:

> | `AxisDescriptor` | `VoxeliaCore` | M1 |

The corrected row reads:

> | `AxisDescriptor` | `VoxeliaSpatial` | M1 |

The corrected inventory additionally records `AxisSemantic` and
`AxisSampling` as `VoxeliaSpatial` M1 types alongside the already-allocated
`AxisID`.

### CCR-0001-C - First Vertical Slice Plan section 14 module participation

Target: `docs/project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md`,
section 14 module-participation table.

Baseline rows read:

> | `VoxeliaSpatial` | Patient coordinate space, matrix, affine geometry, planes, points, bounds and measurements |
> | `VoxeliaCore` | Shapes, axes, scalar formats, descriptor, metadata, identity and provenance |

Corrected rows read:

> | `VoxeliaSpatial` | Patient coordinate space, matrix, affine geometry, planes, points, bounds, measurements and axis descriptors |
> | `VoxeliaCore` | Shapes, scalar formats, descriptor and axis-binding validation, metadata, identity and provenance |

## Scope and limits

- The canonical `AxisDescriptor`, `AxisSemantic` and `AxisSampling` shapes
  and invariants of Core Data Model Specification section 14 are unchanged
  by this record; only their owning module changes.
- Image-descriptor binding validation (rank equality, unique axis
  identifiers, per-axis coordinate and label counts, and descriptor-level
  semantic and spatial-axis consistency) remains owned by `VoxeliaCore`.
- The package dependency direction `VoxeliaCore -> VoxeliaSpatial` is
  unchanged; no dependency edge is added or removed.
- Re-export policy remains a separate open decision; `VoxeliaCore` is not
  required to redeclare or type-alias Spatial types.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0021` migration steps.

## References

- [ADR-0021 - Axis model ownership](../decisions/ADR-0021-axis-model-ownership.md)
- [Voxelia Master Technical Architecture v0.1.1, section 8.2](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 6 and 14](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1, section 14](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
