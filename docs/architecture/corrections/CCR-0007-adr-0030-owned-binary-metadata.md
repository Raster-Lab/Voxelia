# CCR-0007 - Controlled correction for ADR-0030 owned binary metadata

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0007` |
| Authority | Accepted [`ADR-0030`](../decisions/ADR-0030-owned-binary-metadata-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0030`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0007-A - Core Data Model Specification section 34.3 metadata value

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.3 recursive metadata value sketch.

The baseline case reads:

> ```swift
> case binary(Data)
> ```

The corrected case reads:

> ```swift
> case binary(MetadataBinary)
> ```

### CCR-0007-B - Core Data Model Specification section 55.3 binary encoding

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 55.3 canonical JSON requirements.

The baseline requirement reads:

> base64 or hexadecimal binary encoding;

The corrected requirement selects the binary-leaf profile exactly:

> strict padded standard RFC 4648 Base64 binary encoding for the
> `MetadataBinary` semantic string: standard alphabet only, exact padding
> placement, zero unused bits in the last non-padding sextet, and no
> whitespace, line breaks or Base64URL characters, so one byte sequence has
> exactly one accepted string;

### CCR-0007-C - Core Data Model Specification section 72 open decision

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 72 open implementation decisions, item 3.

The baseline item reads:

> whether `Data` is permitted directly in core serialisable metadata;

The corrected item records the closure:

> resolved by accepted `ADR-0030`: `Data` is not permitted directly in core
> serialisable metadata; the owned `MetadataBinary` snapshot is the public
> binary leaf and Foundation `Data` is copied at that boundary;

### CCR-0007-D - Core Data Model Specification Appendix A type inventory

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
Appendix A Core type inventory.

The corrected inventory additionally records `MetadataBinary` as a
`VoxeliaCore` M1 type. No Foundation type is introduced at this metadata
boundary.

## Scope and limits

- `MetadataBinary` identity is the exact byte count followed by the exact
  ordered byte sequence; empty bytes are valid and differ from an absent
  entry; source storage class, allocation, bridging and textual encoding
  are not identity.
- The generic collection initialiser materialises one owned
  `ContiguousArray<UInt8>` snapshot and must not retain the source
  collection, a borrowed buffer or externally managed memory.
- There is no intrinsic byte-count maximum for the standalone leaf in
  version one; host and ingress policy own raw, token and decoded limits,
  and proposed `ADR-0031` separately bounds recursive embedding.
- Wrapper-originated malformed-Base64 failures are value-redacted
  `DecodingError.dataCorrupted` with no public error type; every
  programmatic byte input is valid.
- These corrections do not authorise the recursive `MetadataValue`
  (blocked by `ADR-0031`), entries, collections, privacy attachment,
  canonical document bytes (`ADR-0035`) or content identity.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0030` migration steps.

## References

- [ADR-0030 - Owned binary metadata boundary](../decisions/ADR-0030-owned-binary-metadata-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 34, 55, 72 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [RFC 4648 - The Base16, Base32, and Base64 Data Encodings](https://www.rfc-editor.org/rfc/rfc4648.html)
