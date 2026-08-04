# CCR-0020 - Controlled correction for ADR-0053 source identity and reference

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0020` |
| Authority | Accepted [`ADR-0053`](../decisions/ADR-0053-source-identity-and-data-identity-reference.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0020-A - Source identity field profile

Target: the CDMS `SourceIdentity` sketch (section 32) as corrected by
`CCR-0014`.

The corrected record binds the field profile required by `ADR-0037`
rule 1: `namespace`, `identifier` and a present `version` are each at
most 255 UTF-8 bytes inclusive, checked before content rules; contain
no control scalar (U+0000 through U+001F, U+007F, U+0080 through
U+009F); and are non-blank under the frozen identity whitespace oracle.
Accepted spelling is preserved exactly, and equality and hashing use
the exact accepted UTF-8 tuple with an absent version distinct from
every present version, including the optional source-content claim.
This authorises the public throwing initializer that `ADR-0037`
withheld.

### CCR-0020-B - Data identity reference declaration

Target: the CDMS data-identity sketches (sections 32 and 33) as
corrected by `CCR-0014`.

`DataIdentityReference` is declared with exactly the cases
`object(DataObjectID)`, `content(ContentID)` and
`source(SourceIdentity)`, encoded as exactly one tagged wire member
with strict exact-key nested records and explicit nulls. The
`derivation` case remains deferred until `DerivationRecordID` and its
registered canonical projection exist. Duplicate-locator rejection,
source ordering and aggregate limits remain bound to the future
`DataIdentity` decision.

## Scope and limits

- No `DataIdentity`, `DerivationIdentity` or provenance aggregate
  source is authorised by this record.
- Case-specific resolution, trust and cache-admission rules remain
  governed by `ADR-0037` and host policy.

## References

- [ADR-0053 - Source identity profile and data identity reference](../decisions/ADR-0053-source-identity-and-data-identity-reference.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](../decisions/ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 32 and 33](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
