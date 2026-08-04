# CCR-0025 - Controlled correction for ADR-0063 image data aggregate

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0025` |
| Authority | Accepted [`ADR-0063`](../decisions/ADR-0063-image-data-aggregate.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0025-A - Image data binding validation

Target: the CDMS `ImageData` sketch and validation list (sections 37.1
and 37.2).

The corrected contract closes the open validation list into exact
typed rules: the descriptor's shape, scalar type and component count
must equal the storage snapshot's admitted logical binding; the
snapshot representation must be decoded-strided with a byte order
equal to the descriptor's scalar byte order; the provenance subject
must be exactly the object reference of the aggregate's own
`DataIdentity`; an origin-activity record requires the identity to
carry no derivation recipe and at least one source identity; and
repeated metadata keys are rejected, repeat-bearing collections
belonging to contexts with explicit multiplicity policies. Geometry
and axis compatibility remain owned by the accepted `ImageDescriptor`
construction rules.

### CCR-0025-B - Immutability and equality

Target: CDMS sections 37.3 and 37.4.

The immutability rule is confirmed as declared. The equality rule is
implemented by omission: the aggregate conforms to `Sendable` only,
and comparison composes explicitly from the exposed exact claims
(object identity, content claims, source lineage, descriptor,
provenance) rather than through a blanket conformance that would
compare storage references or force byte reads.

## Scope and limits

- The atomic staging and publication coordinator that produces
  aggregates from live execution remains an Execution/host decision
  per `ADR-0038`; no lazy enrichment, caching or wire is authorised.
- Construction proves structural coherence only, never verification,
  trust or cache suitability.

## References

- [ADR-0063 - Image data aggregate](../decisions/ADR-0063-image-data-aggregate.md)
- [ADR-0038 - Closed provenance record and graph admission boundary](../decisions/ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, section 37](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
