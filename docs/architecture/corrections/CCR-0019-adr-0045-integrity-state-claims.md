# CCR-0019 - Controlled correction for ADR-0045 integrity state claims

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0019` |
| Authority | Accepted [`ADR-0045`](../decisions/ADR-0045-integrity-state-claim-boundary.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0019-A - CDMS section 59 corrected state vocabulary

The baseline case reads:

> ```swift
> case failed(reason: String)
> ```

The corrected case is a payload-free `failed`; privileged failure detail
belongs to host-governed channels and never to the serialisable state.
The corrected section additionally records that
`checksumVerified(ContentID)` and `contentVerified(ContentID)` are claims
whose decoded presence proves nothing — assurance is separately held
runtime evidence under the accepted `ADR-0037` vocabulary — and that no
ordering, comparison helper or automatic upgrade exists between the
cases. No `DataIntegrityState` source is authorised until an owning
aggregate decision needs it.

## Scope and limits

- This record resolves the `ADR-0037`-recorded section 59 conflict on
  paper only and grants no source authority.

## References

- [ADR-0045 - Integrity state claim boundary](../decisions/ADR-0045-integrity-state-claim-boundary.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](../decisions/ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, section 59](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
