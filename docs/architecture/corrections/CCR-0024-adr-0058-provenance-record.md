# CCR-0024 - Controlled correction for ADR-0058 provenance record

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0024` |
| Authority | Accepted [`ADR-0058`](../decisions/ADR-0058-provenance-record-aggregate.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0024-A - Provenance record contract

Target: the CDMS `ProvenanceRecord` sketch (section 36.1) as read
through the accepted `ADR-0038` target.

The corrected record replaces the displayed open bag with the accepted
closed aggregate: `id`, `kind`, `createdAt` as `CanonicalInstant`
(replacing the raw string), a required `subject`
`DataIdentityReference`, `software`, a tagged `ProvenanceActivity`
(`origin`, or `operation` carrying both the operation claim and the
execution claim, replacing the separate optional `operation` and
`execution` fields and the undeclared `ProvenanceReference` sources
array), ordered role-bearing `ProvenanceInput` values, ordered
aggregated warnings and a `validationClaim`. Kind coherence binds
`kind == .source` exactly to the origin activity; origin records carry
no inputs; operation inputs are non-empty unless a zero-input
generator is explicitly declared at the construction site; repeated
`(role, occurrence)` pairs and repeated
`(code, schema version, severity)` warnings are typed rejections.
Successful construction proves structural validity only. The stable
coding and the graph admission contract remain bound to their own
decisions.

## Scope and limits

- No graph builder, canonical projection, digest, signature, resolver
  or validation-evidence implementation is authorised by this record.
- Provenance values remain sensitive-derived; retention grants no
  permission to log, export or deduplicate across privacy domains.

## References

- [ADR-0058 - Provenance record aggregate](../decisions/ADR-0058-provenance-record-aggregate.md)
- [ADR-0038 - Closed provenance record and graph admission boundary](../decisions/ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, section 36](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
