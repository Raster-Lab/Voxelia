---
document_id: "ADR-0059"
title: "Complete provenance graph admission"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-META-004"
  - "VOX-META-006"
  - "VOX-META-009"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
  - "VOX-PER-007"
---

# ADR-0059 - Complete provenance graph admission

## Context

Accepted `ADR-0038` specified the bounded transactional fourteen-step
graph admission over one immutable candidate node table. The record
aggregate now exists (`ADR-0058`), and version one of
`ProvenanceParentReference` holds only the in-graph case, so every
external-reference step is structurally vacuous and compact mode
cannot yet arise. This record was authored and accepted on 2026-08-04
under the project owner's recorded autonomous delegation.

## Decision

`VoxeliaCore` gains value-semantic complete-mode graph admission:

1. **Limits profile.** `ProvenanceGraphLimits` requires explicit
   inclusive record-count, parent-edge-count and ancestry-depth
   ceilings, each at least one, with no permissive defaults and
   checked arithmetic throughout.
2. **Admission.** One static transactional function validates the
   candidate table and declared roots and returns an immutable
   `ProvenanceGraph` snapshot or throws — there is no partial
   publication. It enforces, in order: the ceilings; unique record
   identifiers, with two nodes sharing one identifier rejected even
   when their values are equal; a non-empty, unique, known root set;
   per-edge self-reference rejection; resolution of every `graphNode`
   parent in the table; the parent-subject rule — each resolved
   parent's subject must equal the exact data identity on the input
   edge; the exact-closure rule — the table must equal the resolved
   ancestry closure of the declared roots, rejecting unreachable
   records; visit-once iterative cycle detection over every resolved
   edge, catching two- and multi-node cycles; and maximum resolved
   ancestry depth computed without recursion or exponential diamond
   re-traversal.
3. **Result.** The snapshot exposes lookup by identifier, the record
   count, the declared roots and the computed maximum resolved
   ancestry depth as evidence. Admission proves structural acyclicity
   under the exact admitted snapshot and limits only; scientific and
   authenticity assurance remain separate.
4. **Deferrals.** External-record verification, repeated-unresolved
   consistency, compact-mode retention, the owner's retained-record
   registry with its replacement rule, production hard ceilings and
   any mutable actor-isolated graph service stay bound to the
   registered provenance-record projection, supported-device evidence
   and their own decisions.

## Alternatives considered

An actor-isolated mutable graph owner was rejected for version one:
value-semantic one-shot admission is transactional by construction,
and the owner service's replacement registry needs retention
governance that does not exist. Implementing compact mode against a
structurally absent external case was rejected as untestable dead
policy. Recursive depth computation was rejected by the accepted
iterative rule.

## Consequences

The `ADR-0038` provenance chain closes end to end as values: records
can be admitted into verified-acyclic complete snapshots, and
Execution's future capture and publication can build on a pure
validated core.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface.

## Security impact

Explicit ceilings with checked arithmetic bound every traversal;
typed payload-free rejections; admission grants no trust, evidence or
cache authority.

## Performance and memory impact

Admission is linear in records plus edges — each node and edge is
visited once, diamonds are not re-traversed — with bounded auxiliary
tables.

## Validation impact

Tests must prove chain and diamond admission with exact depth
evidence, duplicate-identifier rejection even for equal values, root
rules (empty, duplicate, unknown), self-reference, unresolved-parent,
parent-subject-mismatch, unreachable-record and two-node-cycle
rejection, every ceiling, zero-limit rejection and payload-free
diagnostics.

## Migration

Implemented in this increment.

## Supersession

This ADR implements the complete-mode slice of the accepted
`ADR-0038` admission and supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0058 - Provenance record aggregate](ADR-0058-provenance-record-aggregate.md)
