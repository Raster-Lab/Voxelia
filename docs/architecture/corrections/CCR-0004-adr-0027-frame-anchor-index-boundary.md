# CCR-0004 - Controlled correction for ADR-0027 frame anchor-index boundary

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0004` |
| Authority | Accepted [`ADR-0027`](../decisions/ADR-0027-frame-geometry-anchor-index-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0027`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0004-A - Core Data Model Specification section 26.2 frame descriptor

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 26.2 frame descriptor.

The baseline sketch reads:

> ```swift
> public struct FrameGeometry: Sendable, Hashable, Codable {
>     public let frameIndex: ImageIndex
>     public let frameAxes: SpatialAxisMapping
>     public let indexToWorld: Matrix4x4Double
>     public let coordinateSpace: CoordinateSpaceDescriptor
>     public let frameIdentity: String?
> }
> ```

The corrected sketch replaces and renames only the conflicting field:

> ```swift
> public struct FrameGeometry: Sendable, Hashable, Codable {
>     public let frameAnchorIndex: FrameAnchorIndex
>     public let frameAxes: SpatialAxisMapping
>     public let indexToWorld: Matrix4x4Double
>     public let coordinateSpace: CoordinateSpaceDescriptor
>     public let frameIdentity: String?
> }
> ```

`FrameAnchorIndex` is the Spatial-owned, full-rank validated anchor value
defined by accepted `ADR-0027`. The Core-owned general `ImageIndex` cannot
appear in a Spatial-owned declaration because the approved package direction
is `VoxeliaCore -> VoxeliaSpatial` with no reverse edge.

### CCR-0004-B - Core Data Model Specification Appendix A type inventory

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
Appendix A Core type inventory.

The corrected inventory additionally records `FrameAnchorIndex` and
`FrameAnchorIndexError` as `VoxeliaSpatial` M1 types. The existing
`ImageIndex` row is unchanged: `ImageIndex` remains a `VoxeliaCore` M1 type
and no alias, implicit conversion or ownership change is introduced.

## Scope and limits

- A `FrameAnchorIndex` is one full logical parent-image coordinate at the
  origin of a positioned full frame's local index coordinates; it is not a
  frame ordinal, a DICOM or source frame number, provenance identity, a
  physical point, a storage offset or a substitute for Core's general
  `ImageIndex`.
- The validated initializer rejects an empty component collection and any
  component outside `0..<Int.max`; the strict one-key
  `{"components":[...]}` wire revalidates on decode and does not encode the
  derived rank.
- The canonical anchor rule (mapped image axes anchored at exactly zero) is
  future `FrameGeometry`-binding validation and is not implemented by this
  correction.
- `FrameGeometry`, `FrameSetGeometry`, `SpatialGeometry`, frame-set
  ordering, sparse/enhanced coverage, coordinate-space compatibility and
  Core descriptor binding remain blocked by their own unresolved contracts.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0027` migration steps.

## References

- [ADR-0027 - Frame geometry anchor-index boundary](../decisions/ADR-0027-frame-geometry-anchor-index-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 26 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 8.1 and 8.2](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
