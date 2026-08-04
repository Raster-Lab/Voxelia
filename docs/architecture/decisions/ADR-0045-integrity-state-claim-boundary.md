---
document_id: "ADR-0045"
title: "Integrity state claim boundary"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-004"
  - "VOX-CON-006"
  - "VOX-ERR-001"
  - "VOX-SEC-006"
---

# ADR-0045 - Integrity state claim boundary

## Context

CDMS section 59 sketches a single `DataIntegrityState` enum whose
`failed(reason: String)` case can retain paths, source identifiers or
patient information, whose `checksumVerified`/`contentVerified` cases
carry `ContentID` values that decode as unverified claims, and whose flat
shape invites an unwarranted total ordering. Accepted `ADR-0037`
recorded this conflict and blocked any aggregate until a separate
correction selects the exact shape. This record was authored and
accepted on 2026-08-04 under the project owner's recorded autonomous
delegation.

## Decision

The corrected integrity-state target is a closed claim vocabulary:

1. `failed(reason: String)` is replaced by a payload-free `failed` case;
   privileged failure detail belongs to host-governed channels, never to
   the serialisable state.
2. `checksumVerified(ContentID)` and `contentVerified(ContentID)` are
   documented as **claims**: a decoded case proves neither that bytes
   were read nor that the embedded tuple matches the object. Assurance
   is runtime evidence under the `ADR-0037` vocabulary, bound to an
   exact pinned snapshot and policy context, held outside the value.
3. No total or partial order, `isAtLeast` comparison or automatic
   upgrade/downgrade exists between the cases; scope tuples are never
   interchangeable across content scopes.
4. No `DataIntegrityState` source is authorised until an owning
   aggregate decision (storage representation integrity or `ImageData`
   publication) needs it; this record fixes the shape so that decision
   cannot improvise one.

## Alternatives considered

Keeping the reason string was rejected as a privacy hazard and unstable
identity. A bounded reason-code enum was deferred until a real consumer
enumerates its codes. Treating decoded verified cases as proof was
rejected per the claim/assurance separation.

## Consequences

The `ADR-0037`-recorded CDMS section 59 conflict is resolved on paper;
the integrity aggregate remains source-blocked until owned.

## Affected modules

`VoxeliaCore` will own the future value; Storage and Execution own the
evidence that could accompany it.

## Compatibility impact

No `DataIntegrityState` exists in source; `CCR-0019` records the
correction.

## Security impact

Payload-free failure and claim semantics prevent path/identifier
leakage and decoded-proof confusion.

## Performance and memory impact

None; documentation only.

## Validation impact

The documentation gate covers this increment; the future implementing
decision owes construction, wire and redaction tests.

## Migration

Documentation only: `CCR-0019` lands with this record.

## Supersession

This ADR supersedes no accepted decision; it completes the correction
`ADR-0037` explicitly left open.

## References

- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, section 59](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
