# CCR-0022 - Controlled correction for ADR-0056 data identity aggregate

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0022` |
| Authority | Accepted [`ADR-0056`](../decisions/ADR-0056-data-identity-aggregate.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0022-A - Data identity aggregate contract

Target: the CDMS `DataIdentity` sketch (sections 32 and 33) as
corrected by `CCR-0014`.

The corrected record replaces the open sketch with the accepted closed
contract: required `DataObjectID`; optional top-level `ContentID`
claim that must not carry the operation-parameters projection; ordered
`SourceIdentity` array with exact repeats and conflicting
same-locator claims both typed rejections detected through the exact
accepted UTF-8 locator key without normalisation; and optional
`DerivationIdentity`. Construction rejects exactly the object-only
state per the accepted `ADR-0037` state model; every other
content/source/derivation combination is structurally valid, and
validity implies no verification, trust, determinism or cache
assurance. The stable coding and the source-count ceiling remain bound
to the future canonical data-identity projection decision.

## Scope and limits

- Cache admission, provenance integration, lazy enrichment and
  `objectID` lifecycle remain governed by their own `ADR-0037` gate
  items and future decisions.
- No provenance record or `ImageData` aggregate source is authorised
  by this record.

## References

- [ADR-0056 - Data identity aggregate](../decisions/ADR-0056-data-identity-aggregate.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](../decisions/ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 32 and 33](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
