---
document_id: "ADR-0134"
title: "Implementation registration"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-010"
  - "VOX-CCH-001"
  - "VOX-ERR-001"
---

# ADR-0134 - Implementation registration

## Context

`VOX-ARC-010` charters `VoxeliaCPU` for deterministic reference
kernels and CPU backend registration, but the target was an empty
scaffold: implementations exist as the operations' own code with no
registry naming them, their claims and their evidence, and the
`ADR-0104` planner selects renderers rather than consulting
registered implementations. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **Registration is data, not dispatch.** `VoxeliaExecution` gains
   the `RegisteredImplementation` value — operation token and
   contract version, implementation reference, backend and precision
   tokens, approximation status, and one `ValidationEvidenceID`
   naming the recorded evidence — plus `ImplementationRegistry`, a
   validated collection with unique operation-and-implementation
   pairs, typed `duplicateImplementation` rejection, and per-operation
   lookup. The type lives in `VoxeliaExecution` because every backend
   registers into one vocabulary; dispatch stays with planners, which
   may consult the registry through their own future revisions per
   `VOX-CCH-001`.
2. **`VoxeliaCPU` opens with the CPU registrations.**
   `CPUBackendRegistrations.standard` registers all eight CPU
   implementations with their live operation tokens taken from the
   operations' own public constants — token drift is structurally
   impossible — their current contract versions, their claimed
   precision policies and statuses, and evidence identifiers naming
   the accepting decision records.
3. **Other backends register alongside.** The metal implementations
   join through their own registration increment in their own module;
   the registry type is deliberately backend-neutral.

## Alternatives considered

Free-text evidence was rejected: the validated evidence identifier is
the accepted vocabulary. A dispatching registry holding closures was
rejected: registration states what exists and what it claims;
execution stays with the typed operation surfaces.

## Consequences

`VOX-ARC-010` is discharged: the CPU backend's implementations are
registered data with claims and evidence, ready for planner
consultation.

## Affected modules

`VoxeliaExecution` and `VoxeliaCPU`; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Registrations carry tokens, versions and evidence identifiers only.

## Performance and memory impact

Negligible.

## Validation impact

Tests must construct and query the registry with duplicates rejected
typed, and verify the standard CPU registrations cover all eight
operations with tokens structurally equal to the operations' own
constants and the pinned current contract versions.

## Migration

Implemented in this increment.

## Supersession

Opens `VoxeliaCPU`; no record is superseded.

## References

- [ADR-0104 - Backend policy planning](ADR-0104-backend-policy-planning.md)
- [ADR-0057 - Provenance claim leaf shapes](ADR-0057-provenance-claim-leaf-shapes.md)
