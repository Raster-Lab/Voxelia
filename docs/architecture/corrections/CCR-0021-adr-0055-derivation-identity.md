# CCR-0021 - Controlled correction for ADR-0055 derivation identity

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0021` |
| Authority | Accepted [`ADR-0055`](../decisions/ADR-0055-derivation-identity-record.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0021-A - Derivation identity contract

Target: the CDMS `DerivationIdentity` sketch (sections 32 and 33) as
corrected by `CCR-0014`.

The corrected record replaces the open sketch with the accepted closed
contract: a bounded reverse-domain operation token with exact semantic
operation version; an optional implementation reference whose version
may carry build metadata; a positional role-bearing input sequence of
`DataIdentityReference` values with accepted order and exact repeats
preserved; and a `parameterDigest` bound to the registered
`org.voxelia.operation-parameters` projection, with every other tuple
a typed rejection. An empty input sequence is admissible only under an
explicit zero-input generator declaration at the construction site.
Equality and hashing compare every stored field exactly, including
`SemanticVersion.buildMetadata` through an explicit exact-version
comparison. The stable coding, input-count ceiling and
`DerivationRecordID` remain bound to the future canonical
derivation-record projection decision.

## Scope and limits

- A derivation identity is a semantic recipe claim, not an execution
  cache key; determinism and input assurance remain runtime evidence
  under `ADR-0037`.
- No `DataIdentity` aggregate or provenance record source is
  authorised by this record.

## References

- [ADR-0055 - Derivation identity record](../decisions/ADR-0055-derivation-identity-record.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](../decisions/ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 32 and 33](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
