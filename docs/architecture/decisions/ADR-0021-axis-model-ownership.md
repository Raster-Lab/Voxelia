---
document_id: "ADR-0021"
title: "Axis model ownership"
status: "Proposed"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ARC-001"
  - "VOX-ARC-002"
  - "VOX-ARC-003"
  - "VOX-DAT-006"
  - "VOX-DAT-008"
  - "VOX-DAT-013"
---

# ADR-0021 - Axis model ownership

## Context

The governing documents assign the canonical axis model to different modules.

The Master Technical Architecture section 8.2 assigns axis descriptors,
physical units and spatial conversion utilities to `VoxeliaSpatial`; section
10.6 also defines axis descriptors inside its spatial model. The Core Data
Model Specification section 6 instead assigns axes to `VoxeliaCore`, and its
section 14 and type-allocation appendix place `AxisDescriptor` there. The First
Vertical Slice Plan also assigns shapes and axes to Core.

The active package graph gives `VoxeliaSpatial` no target dependency and makes
`VoxeliaCore` depend on `VoxeliaSpatial`. Existing foundational types follow
that graph: `AxisID` and `MeasurementUnit`, both referenced by the canonical
`AxisDescriptor` shape, are already owned by `VoxeliaSpatial`.

The Core Data Model Specification requires this discrepancy to be corrected or
resolved by an approved ADR before implementation. This proposal records a
resolution for review; its Proposed status does not authorize code or
controlled-document changes.

## Decision

If this ADR is accepted, `VoxeliaSpatial` will own:

- `AxisID`;
- `AxisSemantic`;
- `AxisSampling`; and
- `AxisDescriptor`.

`VoxeliaCore.ImageDescriptor` will reference those public Spatial values.
Validation that binds an axis collection to an image shape—including rank,
unique identifiers, coordinate counts and descriptor-level semantic
and spatial-axis consistency—will remain in `VoxeliaCore` because it requires
the complete image descriptor.

Acceptance will require a controlled correction to the Core Data Model
Specification's module-ownership table and type-allocation appendix. No
implementation may rely on this proposal while its status remains Proposed.

## Alternatives considered

### Own the complete axis model in VoxeliaCore

This follows the current Core Data Model Specification text and keeps
image-descriptor validation close to its inputs. It is not recommended because
it conflicts with the Master Technical Architecture, separates axis
descriptors from their Spatial-owned identifiers and units, and prevents
lower-level spatial geometry from using the canonical axis model without a
forbidden dependency on `VoxeliaCore`.

### Split axis values between Spatial and Core

Keeping semantic and sampling values in Spatial while placing
`AxisDescriptor` in Core avoids a new target. It is not recommended because it
creates a fragmented public model, still prevents Spatial from using the
canonical descriptor, and makes ownership harder to explain and validate.

### Introduce another shared foundational target

A new target could own units and axis values for both modules. It is not
recommended for M1 because the approved scaffold already establishes
`VoxeliaSpatial` as the dependency-free foundation and adding a target would
expand the package graph and release surface without a demonstrated need.

## Consequences

- Axis meaning, sampling and units remain available to spatial geometry without
  a dependency cycle.
- Spatial will also own foundational non-spatial axis vocabulary such as time,
  phase, channel and component semantics; those values describe coordinate
  dimensions and do not turn their data into physical spatial geometry.
- Core retains responsibility for image-descriptor-wide invariants rather than
  moving image shapes or descriptors into Spatial.
- `VoxeliaCore` continues to depend on `VoxeliaSpatial`; no reverse dependency
  is introduced.
- The Core Data Model Specification requires a controlled correction if this
  proposal is accepted.
- Re-export policy remains a separate open decision; this ADR does not require
  `VoxeliaCore` to redeclare or type-alias Spatial types.

## Compatibility impact

No public `AxisDescriptor`, `AxisSemantic` or `AxisSampling` implementation
exists, so accepting this proposal would not move a released symbol. Before
1.0, any later ownership change would still require changelog and migration
documentation.

## Security impact

Module ownership does not weaken input validation. Coordinate arrays, external
identifiers and units remain untrusted descriptor input and must be validated
before use in offset, allocation or transform calculations.

## Performance and memory impact

The decision adds no runtime abstraction or storage. It permits immutable axis
values to be consumed directly by both Spatial and Core without adapter copies.

## Validation impact

After acceptance and implementation, focused evidence must cover:

- strict-concurrency builds of `VoxeliaSpatial`, `VoxeliaCore` and direct
  consumers;
- exact axis vocabulary and invariant-preserving Codable behavior;
- regular, irregular and categorical sampling validation;
- image-rank and unique-identifier validation in `ImageDescriptor`; and
- a static package-graph check proving that Spatial does not depend on Core.

## Migration

After acceptance:

1. correct the conflicting Core Data Model Specification and First Vertical
   Slice Plan ownership statements;
2. implement the four axis values in `VoxeliaSpatial`;
3. expose descriptor-binding validation from `VoxeliaCore`;
4. add focused Spatial and Core tests; and
5. update traceability and release-integrity evidence.

No migration step may begin while this ADR remains Proposed.

## References

- [Voxelia Master Technical Architecture v0.1.1, section 8.2](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 2, 6 and 14](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1, section 14](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1, Appendix B](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.5 and 6.7](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
