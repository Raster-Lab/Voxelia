---
document_id: "ADR-0058"
title: "Provenance record aggregate"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-META-003"
  - "VOX-META-004"
  - "VOX-META-006"
  - "VOX-META-008"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0058 - Provenance record aggregate

## Context

Accepted `ADR-0038` closed the provenance record target — subject
binding, explicit activity state, ordered role-bearing inputs — and
every leaf it names is now accepted: identifiers (`ADR-0044`), the
instant (`ADR-0028`), the subject reference (`ADR-0053`), the
execution claim (`ADR-0051`), the warning (`ADR-0052`) and the
software, operation, input and validation leaves (`ADR-0057`). This
record was authored and accepted on 2026-08-04 under the project
owner's recorded autonomous delegation; `CCR-0024` records the
controlled correction.

## Decision

`VoxeliaCore` gains the closed record aggregate:

1. **`ProvenanceActivity`.** Exactly `origin` and
   `operation(OperationProvenance, ExecutionProvenanceClaim)`, so an
   execution claim without an operation claim — and an origin
   silently carrying an execution — are structurally impossible.
2. **`ProvenanceRecord`.** The nine accepted fields: `id`, `kind`,
   `createdAt` as `CanonicalInstant`, `subject` as
   `DataIdentityReference`, `software`, `activity`, ordered `inputs`,
   ordered `warnings` and `validationClaim`.
3. **Kind coherence.** `kind == .source` exactly when the activity is
   `origin`; every other kind requires an operation activity.
   Violation is a typed rejection in both directions.
4. **Input rules.** An origin record carries no inputs. An operation
   record's inputs are non-empty unless the constructing site
   explicitly declares a zero-input generator, and declaring one with
   inputs present is a typed rejection; the declaration is not stored
   because it is derivable. Repeated `(role, occurrence)` pairs are
   typed rejections; accepted input order is preserved and
   participates in identity.
5. **Warning aggregation.** Within one record, repeated
   `(code, schema version, severity)` warnings are typed rejections —
   repetition belongs in the occurrence count per `ADR-0052`.
6. **Claims only.** Successful construction proves structural validity
   only: no verification, trust, graph completeness or cache
   suitability is encoded or implied, and a cached-kind record cannot
   acquire a different validation authority by construction.
7. **No wire, no graph.** The stable coding is owned by the future
   canonical provenance-record projection; the bounded transactional
   graph admission contract is the next separate decision.

## Alternatives considered

Optional operation and execution fields on the record (the displayed
CDMS bag) were rejected: the tagged activity makes the invalid
combinations unrepresentable. Storing the zero-input declaration was
rejected as a derivable second source of truth, matching `ADR-0055`.
Silently aggregating repeated warnings was rejected — the constructor
is not an aggregator, and silent mutation of claims is banned.

## Consequences

The `ADR-0038` record target is complete as a validated value; graph
admission and the canonical projection are the only remaining
provenance decisions, and the structural `ImageData` aggregate's last
Core dependency now exists.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface; no wire exists yet.

## Security impact

All fields are already-bounded validated claims; typed payload-free
rejections; no free text anywhere in the record; provenance remains
sensitive-derived and must not be logged or exported by default.

## Performance and memory impact

Validation is one linear pass over inputs and warnings with exact-key
tables; values compose existing immutable records.

## Validation impact

Tests must prove both kind-coherence directions, the origin no-input
rule, both zero-input declaration rules, duplicate
`(role, occurrence)` and duplicate warning rejection, input order
participating in identity, structural impossibility of execution
without operation, and payload-free diagnostics.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0038` record-shape deferral and
supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0057 - Provenance claim leaf shapes](ADR-0057-provenance-claim-leaf-shapes.md)
- [CCR-0024 - Controlled correction for ADR-0058](../corrections/CCR-0024-adr-0058-provenance-record.md)
