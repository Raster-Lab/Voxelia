# CCR-0006 - Controlled correction for ADR-0029 finite floating-point metadata

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0006` |
| Authority | Accepted [`ADR-0029`](../decisions/ADR-0029-finite-floating-point-metadata-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0029`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0006-A - Core Data Model Specification section 34.3 metadata value

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.3 recursive metadata value sketch.

The baseline case reads:

> ```swift
> case floatingPoint(Double)
> ```

The corrected case reads:

> ```swift
> case floatingPoint(MetadataFloatingPoint)
> ```

### CCR-0006-B - Core Data Model Specification section 34.6 invariants

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.6 invariants.

The baseline invariant reads:

> floating-point metadata shall define whether non-finite values are
> permitted;

The corrected invariant resolves that open definition exactly:

> floating-point metadata shall be finite IEEE 754 binary64 only: NaN of any
> sign or payload and both infinities are rejected with a value-redacted
> typed error, either signed zero is stored as positive zero, and every
> other finite bit pattern is preserved exactly;

### CCR-0006-C - Core Data Model Specification Appendix A type inventory

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
Appendix A Core type inventory.

The corrected inventory additionally records `MetadataFloatingPoint` and
`MetadataFloatingPointError` as `VoxeliaCore` M1 types.

## Scope and limits

- Equality and hashing use exact stored canonical binary64 identity and
  never a tolerance; source decimal spelling is not part of identity.
- Version one defines no named NaN, infinity, missing or unavailable
  member; sources requiring special values must preserve them at an
  explicitly specified adapter boundary until an approved namespaced
  schema defines meaning and wire representation.
- The wrapper's strict single-number Codable is not the canonical JSON
  contract: shortest-round-trip spelling, raw duplicate-key rejection,
  token/document limits and envelope rules remain with unaccepted
  `ADR-0035`.
- These corrections do not authorise the recursive `MetadataValue`
  (blocked by `ADR-0031`), metadata entries, collections, privacy
  attachment or canonical byte ingress.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0029` migration steps.

## References

- [ADR-0029 - Finite floating-point metadata boundary](../decisions/ADR-0029-finite-floating-point-metadata-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 34 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [RFC 8259, section 6 - JSON numbers](https://www.rfc-editor.org/rfc/rfc8259.html#section-6)
