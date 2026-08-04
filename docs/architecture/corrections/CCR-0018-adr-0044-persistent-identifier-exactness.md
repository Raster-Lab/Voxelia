# CCR-0018 - Controlled correction for ADR-0044 persistent identifier exactness

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0018` |
| Authority | Accepted [`ADR-0044`](../decisions/ADR-0044-persistent-identifier-exactness-boundary.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0018-A - Persistent identifier domains

Target: the CDMS identifier sketches for `DataObjectID` (section 32) and
`ProvenanceID` (section 36).

The corrected domains bind both leaves to the accepted exactness rule:
raw values are non-blank and at most 255 UTF-8 bytes inclusive; equality
and hashing compare the exact accepted UTF-8 bytes so canonically
equivalent but byte-distinct spellings are distinct identifiers; the
keyed `{"rawValue": ...}` wire and shared strict value-redacted decoder
are unchanged, with over-ceiling values surfacing as the redacted
concrete-type rejection. This discharges `ADR-0037` source-gate item 4
for `DataObjectID` and the corresponding `ADR-0038` bounded-identifier
prerequisite; the remaining gate items stay open.

## Scope and limits

- Other `VoxeliaStringIdentifier` conformances keep their current
  semantics until their own persistence decisions.
- No identity or provenance aggregate source is authorised by this
  record.

## References

- [ADR-0044 - Persistent identifier exactness boundary](../decisions/ADR-0044-persistent-identifier-exactness-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 32 and 36](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
