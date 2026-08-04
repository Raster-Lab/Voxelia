# CCR-0002 - Controlled correction for ADR-0022 coordinate convention shape

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0002` |
| Authority | Accepted [`ADR-0022`](../decisions/ADR-0022-coordinate-convention-shape.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0022`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0002-A - Master Technical Architecture section 10.2 convention enum

Target: `docs/project/Voxelia_Master_Technical_Architecture_v0.1.1.md`,
section 10.2 coordinate-space sketch.

The baseline sketch reads:

> ```swift
> public enum CoordinateConvention: Sendable, Hashable, Codable {
>     case cartesianRightHanded
>     case dicomPatientLPS
>     case neuroimagingRAS
>     case custom(name: String)
> }
> ```

The corrected sketch reads:

> ```swift
> public enum CoordinateConvention: Sendable, Hashable, Codable {
>     case cartesianRightHanded
>     case cartesianLeftHanded
>     case dicomPatientLPS
>     case neuroimagingRAS
>     case imageDisplay
>     case custom(namespace: String, name: String)
> }
> ```

The corrected shape matches Core Data Model Specification section 21.3:
left-handed Cartesian and image-display conventions are explicit cases, and
the extension case is namespaced to avoid collisions.

## Scope and limits

- Built-in cases encode as the exact strings `cartesianRightHanded`,
  `cartesianLeftHanded`, `dicomPatientLPS`, `neuroimagingRAS` and
  `imageDisplay`; the custom case encodes as
  `{"custom":{"namespace":...,"name":...}}` with strict rejection of unknown
  tags, wrong shapes, missing fields and distinct extra fields.
- Custom namespace and name values are opaque case-sensitive declaration
  vocabulary compared and hashed by exact UTF-8 bytes; no nonblank rule is
  invented for the directly constructible case.
- A convention identifies an axis-orientation convention only; no unit,
  transform, external frame or handedness is inferred for `imageDisplay` or
  `custom`, and convention conversion always requires an explicit transform.
- The separate `CoordinateSpaceDescriptor` unit policy remains an open
  approval; this record does not unblock it.
- This record grants no authority beyond the correction above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0022` migration steps.

## References

- [ADR-0022 - Coordinate convention public shape](../decisions/ADR-0022-coordinate-convention-shape.md)
- [Voxelia Master Technical Architecture v0.1.1, section 10.2](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, section 21](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
