# CCR-0009 - Controlled correction for ADR-0032 required entry privacy attachment

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0009` |
| Authority | Accepted [`ADR-0032`](../decisions/ADR-0032-required-metadata-entry-privacy-attachment.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0032`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0009-A - Core Data Model Specification section 34.4 metadata entry

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.4 metadata entry sketch.

The baseline entry reads:

> ```swift
> public struct MetadataEntry: Sendable, Hashable, Codable {
>     public let key: AnyMetadataKey
>     public let value: MetadataValue
> }
> ```

The corrected entry reads:

> ```swift
> public struct MetadataEntry: Sendable, Hashable, Codable {
>     public let key: AnyMetadataKey
>     public let value: MetadataValue
>     public let privacyClass: MetadataPrivacyClass
>
>     public init(
>         key: AnyMetadataKey,
>         value: MetadataValue,
>         privacyClass: MetadataPrivacyClass
>     )
> }
> ```

The initializer is nonthrowing because its three inputs are already
validated values. It has no default argument, two-argument overload or
optional classification. There is no valid unclassified `MetadataEntry`, in
source or on the wire.

### CCR-0009-B - Core Data Model Specification section 34.6 invariants

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.6 invariants, as already corrected by `CCR-0008`.

The corrected section additionally records the required-attachment
invariants:

> every general metadata entry shall carry exactly one explicit privacy
> classification; missing, null, unknown or wrong-shaped classification
> input shall be rejected with a value-redacted typed error and never
> defaulted or coerced to another case; entry equality and hashing shall
> include the exact declared classification together with exact key
> identity and semantic value identity; and no implicit conversion shall be
> published between the general entry and the privacy-neutral recursive
> object member.

### CCR-0009-C - Core Data Model Specification section 34.8 classification

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.8 privacy classification.

The baseline phrase reads:

> Metadata may carry a classification:

The corrected phrase reads:

> Every general metadata entry carries exactly one explicit classification:

The five-case raw-string vocabulary is unchanged. The corrected section
additionally records the fail-closed handling rules: the declared class is
an immutable caller assertion, not disclosure authority, and wire-supplied
labels are data, not trusted authority; the enum gains no `Comparable`
conformance, severity ordinal, total or partial order, `max` or `join`
helper, or Boolean disclosure property; library-owned one-to-one
transformations preserve the exact stored class, and generic multi-input
aggregation preserves inputs as separate entries, requires an explicit
trusted-host output class, or fails with a typed payload-free error;
`hostDefined` remains unresolved without the trusted originating policy and
fails closed, and unknown wire strings are rejected rather than coerced to
`hostDefined`; and the one declared class governs the complete entry record
- both key fields and the entire recursive value subtree - while nested
object members remain privacy-neutral and store no override.

### CCR-0009-D - Core Data Model Specification section 64.6 validation

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 64.6 metadata and provenance validation ("privacy classification").

The corrected item expands to the accepted evidence obligations: required
attachment with no default, optional or two-argument construction path;
class-sensitive entry equality, hashing and set behaviour for equal
key/value pairs under every distinct class; exact class preservation by
library-owned one-to-one transformations with explicit-host or typed
failure for multi-input aggregation; `hostDefined` round-tripping without
generic resolution; whole-entry scope across key text, arrays, nested
object members and code/unit presentation strings; strict three-field wire
round trips for all five classes with rejection of missing, null, extra,
unknown and wrong-shaped fields; and value-redacted entry errors whose
model-relative coding paths name only the fixed fields.

### CCR-0009-E - Core Data Model Specification Appendix A type inventory

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
Appendix A Core type inventory.

The corrected inventory additionally records `MetadataEntry` as a
`VoxeliaCore` M1 type with the required three-field shape. The existing
`MetadataCollection` row remains governed by Proposed `ADR-0033` and is not
authorised by this record.

## Scope and limits

- The declared class is an assertion evaluated by trusted host policy; this
  record does not validate caller classification choices, authenticate wire
  labels or replace host authentication, authorisation, declassification,
  consent, retention or audit responsibilities.
- No resolver protocol, logging conformance, `isLoggable`/`canExport`
  helper or OSLog-privacy mapping enters `VoxeliaCore`; type-level Codable
  remains storage representation, never export authorisation.
- Host resolver output, policy version and operation-local effective
  classes are not stored in the entry and never enter entry identity.
- These corrections do not authorise `MetadataCollection`, multiplicity
  policy, typed access, canonical byte ingress or persistent digest
  identity, which remain governed by `ADR-0033` through `ADR-0036`.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0032` migration steps.

## References

- [ADR-0032 - Required metadata-entry privacy attachment](../decisions/ADR-0032-required-metadata-entry-privacy-attachment.md)
- [ADR-0031 - Bounded recursive metadata value boundary](../decisions/ADR-0031-bounded-recursive-metadata-value-boundary.md)
- [CCR-0008 - Bounded recursive metadata value correction](CCR-0008-adr-0031-bounded-recursive-metadata-value.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 34, 64.6 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
