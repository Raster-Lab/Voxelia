# CCR-0005 - Controlled correction for ADR-0028 canonical instant boundary

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0005` |
| Authority | Accepted [`ADR-0028`](../decisions/ADR-0028-canonical-instant-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0028`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0005-A - Core Data Model Specification section 7.7 dates

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 7.7 dates.

The baseline section reads:

> Provenance times shall use an absolute instant representation.
>
> Serialised JSON shall use a canonical UTC representation.

The corrected section additionally binds both requirements to the exact
version-one profile of accepted `ADR-0028`:

> Provenance times shall use an absolute instant representation through the
> Core-owned `CanonicalInstant`. Serialised JSON shall use that value's one
> canonical zero-offset UTC spelling: `full-date "T" clock-time [fraction]
> "Z"` with uppercase `T` and `Z`, ASCII digits, years 0001-9999 on the
> proleptic Gregorian calendar, mandatory seconds, no offsets, no leap
> second 60 and an optional one-to-nine-digit fraction whose last digit is
> non-zero, occupying at most 30 UTF-8 bytes.

### CCR-0005-B - Core Data Model Specification section 34 metadata instant

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34 recursive metadata value sketch.

The baseline case reads:

> ```swift
> case instant(String)
> ```

The corrected case reads:

> ```swift
> case instant(CanonicalInstant)
> ```

### CCR-0005-C - Core Data Model Specification section 36 provenance field

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 36 provenance record sketch.

The baseline field reads:

> ```swift
> public let createdAt: String
> ```

The corrected field reads:

> ```swift
> public let createdAt: CanonicalInstant
> ```

### CCR-0005-D - Core Data Model Specification Appendix A type inventory

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
Appendix A Core type inventory.

The corrected inventory additionally records `CanonicalInstant` and
`CanonicalInstantError` as `VoxeliaCore` M1 types.

## Scope and limits

- These corrections make the same invalid instant states unrepresentable at
  both public boundaries; they do not independently authorise the recursive
  `MetadataValue` (blocked by `ADR-0031`) or `ProvenanceRecord` (blocked by
  `ADR-0038`), canonical JSON bytes (`ADR-0035`), clock acquisition, date
  arithmetic, ordering or external timestamp normalisation.
- Version one is a leap-unaware proleptic civil-time grid with exactly
  86,400 labelled seconds per day; explicit second 60 is rejected and no
  leap-aware UTC claim is made.
- Validation errors never contain the supplied timestamp.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0028` migration steps.

## References

- [ADR-0028 - Canonical instant boundary](../decisions/ADR-0028-canonical-instant-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 7.7, 34, 36 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [RFC 3339 - Date and Time on the Internet: Timestamps](https://www.rfc-editor.org/rfc/rfc3339.html)
