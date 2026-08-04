# CCR-0017 - Controlled correction for ADR-0043 spatial descriptor admission

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0017` |
| Authority | Accepted [`ADR-0043`](../decisions/ADR-0043-spatial-descriptor-admission-boundary.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0043`.
The `v0.1.1` baseline files remain immutable and unedited; wherever a
statement quoted below conflicts with this record, this record is
authoritative for implementation, traceability and review.

## Corrections

### CCR-0017-A - CDMS section 21.5/21.6 unit policy

The invariant "coordinate unit shall have length dimension for ordinary
physical spaces" is bound to the accepted version-one rule: the
descriptor unit must carry `UnitDimension.length`; missing, non-length
or `custom`-dimension units are rejected with a typed payload-free
error, and non-physical space classifications require a future reviewed
decision rather than silent admission. The remaining 21.6 invariants
bind as written with exact namespace/identifier reference uniqueness and
handedness/convention consistency.

### CCR-0017-B - CDMS section 22 affine admission

Affine construction admits only matrices with finite entries, the exact
homogeneous bottom row `(0, 0, 0, 1)` and an upper-left 3x3 determinant
magnitude of at least `Double.leastNormalMagnitude`; subnormal, zero and
non-finite determinants are singular and rejected. No epsilon tolerance
parameter exists in version one.

### CCR-0017-C - Rectilinear and frame-set admission rules

Rectilinear geometries bind one strictly increasing finite coordinate
array per bound axis with element count equal to that axis's extent;
frame-set geometries map every `FrameAnchorIndex` of the bound frame
axis to exactly one per-frame transform with complete coverage and no
duplicates. Both implementations remain deferred to their recorded
milestone windows under these frozen rules.

### CCR-0017-D - CDMS section 19.2 descriptor admission

`ImageDescriptor` validates the 19.2 invariants at construction with
typed payload-free errors, never accesses storage, and its version-one
`SpatialGeometry` surface admits the affine case, with rectilinear and
frame-set cases joining at their milestones without reopening this
boundary.

## Scope and limits

- No non-length space classification, conditioning tolerance,
  rectilinear or frame-set source is authorised.
- This record grants no authority beyond the corrections above.

## References

- [ADR-0043 - Spatial descriptor admission boundary](../decisions/ADR-0043-spatial-descriptor-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 19, 21 and 22](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
