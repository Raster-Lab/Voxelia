# CCR-0003 - Controlled correction for ADR-0023 value transform shape

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0003` |
| Authority | Accepted [`ADR-0023`](../decisions/ADR-0023-value-transform-shape.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0023`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0003-A - Master Technical Architecture section 9.9 transform enum

Target: `docs/project/Voxelia_Master_Technical_Architecture_v0.1.1.md`,
section 9.9 value-transform sketch.

The baseline sketch reads:

> ```swift
> public enum ValueTransform: Sendable, Codable, Hashable {
>     case identity
>     case linear(scale: Double, offset: Double)
>     case lookupTable(LookupTableDescriptor)
>     case composed([ValueTransform])
> }
> ```

The corrected sketch reads:

> ```swift
> public enum ValueTransform: Sendable, Hashable, Codable {
>     case identity
>     case linear(LinearValueTransformDescriptor)
>     case lookupTable(LookupTableDescriptor)
>     case composed(ValueTransformComposition)
> }
> ```

`LinearValueTransformDescriptor` validates finite scale and offset by
construction; `ValueTransformComposition` materializes one immutable
nonempty `ContiguousArray<ValueTransform>` with documented first-to-last
application order.

### CCR-0003-B - Core Data Model Specification section 18.2 canonical type

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 18.2 canonical type.

The baseline sketch reads:

> ```swift
> public enum ValueTransform: Sendable, Hashable, Codable {
>     case identity
>     case linear(scale: Double, offset: Double)
>     case lookupTable(LookupTableDescriptor)
>     case piecewiseLinear(PiecewiseLinearDescriptor)
>     case composed(ContiguousArray<ValueTransform>)
> }
> ```

The corrected sketch is identical to the `CCR-0003-A` corrected sketch. The
`piecewiseLinear` case is deferred: `PiecewiseLinearDescriptor` is undefined
in every governing document, and no case is added until an approved
descriptor and evaluation contract define its knots, ordering,
duplicate-input behaviour, continuity, endpoint inclusion, extrapolation,
units, identity and wire format.

### CCR-0003-C - Core Data Model Specification section 18.4 composition rule

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 18.4 composition.

The baseline rule reads:

> Empty composition shall be rejected or canonicalised to `.identity`.

The corrected rule selects the rejection branch exactly:

> Empty composition shall be rejected with
> `DataModelError.invalidValueTransform`. No canonicalisation to
> `.identity`, flattening of nested compositions, removal of identity
> members or collapse of a one-element composition occurs without a
> separately approved canonicalization rule.

## Scope and limits

- The four case tags encode as `"identity"`,
  `{"linear":{"scale":...,"offset":...}}`,
  `{"lookupTable":{...}}` and `{"composed":{"transforms":[...]}}` with
  strict rejection of unknown tags, wrong shapes, missing fields and
  distinct extra fields, and decode-time revalidation of every invariant.
- Zero scale is valid because neither governing source requires
  invertibility; signed zero canonicalizes to positive zero for one shared
  equality, hashing and encoding representation.
- The lookup-table case preserves the existing validated
  `LookupTableDescriptor` contract including its currently permitted empty
  table; lookup application, missing-entry behaviour, interpolation and
  extrapolation remain undefined and unclaimed.
- Display windows, VOI LUTs, transfer functions and colour maps remain
  presentation-stage values and must not enter `ValueTransform`.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0023` migration steps.

## References

- [ADR-0023 - Value transform public shape](../decisions/ADR-0023-value-transform-shape.md)
- [Voxelia Master Technical Architecture v0.1.1, section 9.9](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, section 18](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
