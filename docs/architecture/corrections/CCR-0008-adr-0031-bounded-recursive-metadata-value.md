# CCR-0008 - Controlled correction for ADR-0031 bounded recursive metadata value

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0008` |
| Authority | Accepted [`ADR-0031`](../decisions/ADR-0031-bounded-recursive-metadata-value-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0031`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0008-A - Core Data Model Specification section 34.3 recursive cases

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.3 recursive metadata value sketch, as already corrected for its
leaf payloads by `CCR-0005` through `CCR-0007`.

The baseline recursive cases read:

> ```swift
> case array(ContiguousArray<MetadataValue>)
> case object(ContiguousArray<MetadataEntry>)
> ```

The corrected cases read:

> ```swift
> case array(MetadataArray)
> case object(MetadataObject)
> ```

`MetadataArray` and `MetadataObject` are validated immutable containers with
throwing initialisers. `MetadataObject.Member` is a privacy-neutral
structural key/value pair distinct from the general `MetadataEntry`, whose
privacy attachment remains governed by Proposed `ADR-0032`.

### CCR-0008-B - Core Data Model Specification section 34.6 invariants

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.6 invariants.

The baseline invariant reads:

> object keys shall be unique;

The corrected invariant binds uniqueness and order to construction exactly:

> object keys shall be unique by exact `AnyMetadataKey` identity, enforced
> at container construction with a value-redacted typed error; object
> members are canonically sorted by unsigned UTF-8 lexicographic order of
> key namespace then key name, caller order is not semantic, and array
> order remains semantic and preserved exactly;

The corrected section additionally records the three hard version-one
ceilings as representation-safety contracts with exact accounting:

> container depth at most 64 (a leaf is depth zero, an empty container
> depth one); logical structural elements at most 1,048,576, counting every
> `MetadataValue` and `MetadataObject.Member` occurrence including repeated
> copy-on-write-shared subtrees; and recursive-container logical variable
> payload at most 67,108,864 bytes, counting every occurrence of stored
> string, instant, binary, key, code and unit variable bytes. A standalone
> leaf retains its uncapped leaf domain; hosts may impose lower admission
> limits but may not construct a value above the hard ceilings.

### CCR-0008-C - Core Data Model Specification section 55.3 enum tags

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 55.3 canonical JSON requirements ("explicit enum tags").

The corrected requirement selects the exact type-level tag vocabulary for
the metadata value: `boolean`, `signedInteger`, `unsignedInteger`,
`floatingPoint`, `string`, `binary`, `instant`, `unit`, `code`, `array` and
`object`, encoded as an externally tagged object with exactly one member;
object members encode exactly `key` and `value` in canonical member order
and never as dynamic JSON member names. This selects type-level tags only;
canonical document bytes remain governed by Proposed `ADR-0035`.

### CCR-0008-D - Core Data Model Specification Appendix A type inventory

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
Appendix A Core type inventory.

The corrected inventory additionally records `MetadataValue`,
`MetadataValueError`, `MetadataArray` and `MetadataObject` (with its nested
`Member`) as `VoxeliaCore` M1 types.

## Scope and limits

- The raw string case retains `String` with exact UTF-8 byte identity for
  aggregate equality and hashing, approving the isolated string audit's
  candidate for this aggregate only.
- Equality and hashing are iterative with bounded auxiliary state; cached
  container metrics and the numeric ceilings never participate in equality,
  hashing or encoding, and process-randomised hashes are never a digest.
- Model-originated failures are value-redacted; their contexts never copy a
  caller-supplied coding path or contain metadata keys, values or raw
  fragments.
- The ceiling values are accepted on local Apple Silicon boundary evidence;
  measured low-resource supported-device evidence remains an explicit open
  gap recorded in the progress ledger.
- These corrections do not authorise the general `MetadataEntry`,
  `MetadataCollection`, multiplicity, typed access, privacy attachment,
  canonical byte ingress or persistent digest identity, which remain
  governed by `ADR-0032` through `ADR-0036`.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0031` migration steps.

## References

- [ADR-0031 - Bounded recursive metadata value boundary](../decisions/ADR-0031-bounded-recursive-metadata-value-boundary.md)
- [CCR-0005 - Canonical instant correction](CCR-0005-adr-0028-canonical-instant-boundary.md)
- [CCR-0006 - Finite floating-point correction](CCR-0006-adr-0029-finite-floating-point-metadata.md)
- [CCR-0007 - Owned binary correction](CCR-0007-adr-0030-owned-binary-metadata.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 34, 55 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
