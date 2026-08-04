# CCR-0026 - Controlled correction for ADR-0077 retention and enrichment

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0026` |
| Authority | Accepted [`ADR-0077`](../decisions/ADR-0077-retention-and-enrichment-lifecycle.md) |
| Approved by | Project owner (recorded broadened autonomous delegation of 2026-08-05) |
| Approval date | 2026-08-05 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0026-A - Object identity lifecycle

Target: the CDMS object-identity clause (section 33.4).

The corrected clause binds the accepted lifecycle: a `DataObjectID`
binds to at most one published immutable bundle forever, publication
is the binding event, reuse is rejected even for equal values, and no
future deletion decision legitimises rebinding. Enrichment before
publication is ordinary value construction; enrichment after
publication publishes a new immutable bundle under new object and
provenance identifiers whose shared verified content identity is the
cross-bundle linkage claim. The existing prohibition on using
`objectID` as a substitute for content equality is unchanged.

### CCR-0026-B - Version-one retention

Target: the CDMS cache and persistence readings as corrected by
`CCR-0014`.

Version-one retention across the published registry and the canonical
document store is append-only: nothing is evicted, overwritten,
renamed or deleted, and ceiling exhaustion is a typed transactional
failure. A future deletion or retirement decision must define audit
obligations and preserve the never-rebind rule.

## Scope and limits

- No deletion, retirement, or lease mechanism is authorised by this
  record.

## References

- [ADR-0077 - Retention and enrichment lifecycle](../decisions/ADR-0077-retention-and-enrichment-lifecycle.md)
- [Voxelia Core Data Model Specification v0.1.1, section 33](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
